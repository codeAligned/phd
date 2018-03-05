package server

import (
	"fmt"
	"sync"

	"github.com/docker/distribution"
	"github.com/docker/distribution/context"
	"github.com/docker/distribution/digest"
	"github.com/docker/distribution/manifest/schema2"
	"github.com/docker/distribution/registry/api/errcode"
	regapi "github.com/docker/distribution/registry/api/v2"

	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"

	imageapiv1 "github.com/openshift/api/image/v1"

	"github.com/openshift/image-registry/pkg/dockerregistry/server/cache"
	registrymanifest "github.com/openshift/image-registry/pkg/dockerregistry/server/manifest"
	"github.com/openshift/image-registry/pkg/dockerregistry/server/manifesthandler"
	"github.com/openshift/image-registry/pkg/imagestream"
	imageapi "github.com/openshift/image-registry/pkg/origin-common/image/apis/image"
)

var _ distribution.ManifestService = &manifestService{}

type manifestService struct {
	manifests distribution.ManifestService
	blobStore distribution.BlobStore

	serverAddr  string
	imageStream imagestream.ImageStream
	cache       cache.RepositoryDigest

	// acceptSchema2 allows to refuse the manifest schema version 2
	acceptSchema2 bool
}

// Exists returns true if the manifest specified by dgst exists.
func (m *manifestService) Exists(ctx context.Context, dgst digest.Digest) (bool, error) {
	context.GetLogger(ctx).Debugf("(*manifestService).Exists")

	image, err := m.imageStream.GetImageOfImageStream(ctx, dgst)
	if err != nil {
		return false, err
	}
	return image != nil, nil
}

// Get retrieves the manifest with digest `dgst`.
func (m *manifestService) Get(ctx context.Context, dgst digest.Digest, options ...distribution.ManifestServiceOption) (distribution.Manifest, error) {
	context.GetLogger(ctx).Debugf("(*manifestService).Get")

	image, err := m.imageStream.GetImageOfImageStream(ctx, dgst)
	if err != nil {
		return nil, err
	}

	// Reference without a registry part refers to repository containing locally managed images.
	// Such an entry is retrieved, checked and set by blobDescriptorService operating only on local blobs.
	ref := m.imageStream.Reference()
	if !imagestream.IsImageManaged(image) {
		// Repository with a registry points to remote repository. This is used by pullthrough middleware.
		// TODO(dmage): should ref contain image.DockerImageReferece if the image is not managed?
		ref = fmt.Sprintf("%s/%s", m.serverAddr, ref)
	}

	manifest, err := m.manifests.Get(ctx, dgst, options...)
	if err == nil {
		RememberLayersOfImage(ctx, m.cache, image, ref)
		m.migrateManifest(ctx, image, dgst, manifest, true)
		return manifest, nil
	} else if _, ok := err.(distribution.ErrManifestUnknownRevision); !ok {
		context.GetLogger(ctx).Errorf("unable to get manifest from storage: %v", err)
		return nil, err
	}

	manifest, err = registrymanifest.NewFromImage(image)
	if err == nil {
		RememberLayersOfImage(ctx, m.cache, image, ref)
		m.migrateManifest(ctx, image, dgst, manifest, false)
		return manifest, nil
	} else {
		context.GetLogger(ctx).Errorf("unable to get manifest from image object: %v", err)
	}

	return nil, distribution.ErrManifestUnknownRevision{
		Name:     m.imageStream.Reference(),
		Revision: dgst,
	}
}

// Put creates or updates the named manifest.
func (m *manifestService) Put(ctx context.Context, manifest distribution.Manifest, options ...distribution.ManifestServiceOption) (digest.Digest, error) {
	context.GetLogger(ctx).Debugf("(*manifestService).Put")

	mh, err := manifesthandler.NewManifestHandler(m.serverAddr, m.blobStore, manifest)
	if err != nil {
		return "", regapi.ErrorCodeManifestInvalid.WithDetail(err)
	}

	mediaType, payload, _, err := mh.Payload()
	if err != nil {
		return "", regapi.ErrorCodeManifestInvalid.WithDetail(err)
	}

	// this is fast to check, let's do it before verification
	if !m.acceptSchema2 && mediaType == schema2.MediaTypeManifest {
		return "", regapi.ErrorCodeManifestInvalid.WithDetail(fmt.Errorf("manifest V2 schema 2 not allowed"))
	}

	// in order to stat the referenced blobs, repository need to be set on the context
	if err := mh.Verify(ctx, false); err != nil {
		return "", err
	}

	_, err = m.manifests.Put(ctx, manifest, options...)
	if err != nil {
		return "", err
	}

	config, err := mh.Config(ctx)
	if err != nil {
		return "", err
	}

	dgst, err := mh.Digest()
	if err != nil {
		return "", err
	}

	layerOrder, layers, err := mh.Layers(ctx)
	if err != nil {
		return "", err
	}

	// Upload to openshift
	uclient, ok := userClientFrom(ctx)
	if !ok {
		errmsg := "error creating user client to auto provision image stream: user client to master API unavailable"
		context.GetLogger(ctx).Errorf(errmsg)
		return "", errcode.ErrorCodeUnknown.WithDetail(errmsg)
	}

	image := &imageapiv1.Image{
		ObjectMeta: metav1.ObjectMeta{
			Name: dgst.String(),
			Annotations: map[string]string{
				imageapi.ManagedByOpenShiftAnnotation:      "true",
				imageapi.ImageManifestBlobStoredAnnotation: "true",
				imageapi.DockerImageLayersOrderAnnotation:  layerOrder,
			},
		},
		DockerImageReference:         fmt.Sprintf("%s/%s@%s", m.serverAddr, m.imageStream.Reference(), dgst.String()),
		DockerImageManifest:          string(payload),
		DockerImageManifestMediaType: mediaType,
		DockerImageConfig:            string(config),
		DockerImageLayers:            layers,
	}

	tag := ""
	for _, option := range options {
		if opt, ok := option.(distribution.WithTagOption); ok {
			tag = opt.Tag
			break
		}
	}

	if err = m.imageStream.CreateImageStreamMapping(ctx, uclient, tag, image); err != nil {
		return "", err
	}

	return dgst, nil
}

// Delete deletes the manifest with digest `dgst`. Note: Image resources
// in OpenShift are deleted via 'oc adm prune images'. This function deletes
// the content related to the manifest in the registry's storage (signatures).
func (m *manifestService) Delete(ctx context.Context, dgst digest.Digest) error {
	context.GetLogger(ctx).Debugf("(*manifestService).Delete")
	return m.manifests.Delete(ctx, dgst)
}

// manifestInflight tracks currently downloading manifests
var manifestInflight = make(map[digest.Digest]struct{})

// manifestInflightSync protects manifestInflight
var manifestInflightSync sync.Mutex

func (m *manifestService) migrateManifest(ctx context.Context, image *imageapiv1.Image, dgst digest.Digest, manifest distribution.Manifest, isLocalStored bool) {
	// Everything in its place and nothing to do.
	if isLocalStored && len(image.DockerImageManifest) == 0 {
		return
	}
	manifestInflightSync.Lock()
	if _, ok := manifestInflight[dgst]; ok {
		manifestInflightSync.Unlock()
		return
	}
	manifestInflight[dgst] = struct{}{}
	manifestInflightSync.Unlock()

	go m.storeManifestLocally(ctx, image, dgst, manifest, isLocalStored)
}

func (m *manifestService) storeManifestLocally(ctx context.Context, image *imageapiv1.Image, dgst digest.Digest, manifest distribution.Manifest, isLocalStored bool) {
	defer func() {
		manifestInflightSync.Lock()
		delete(manifestInflight, dgst)
		manifestInflightSync.Unlock()
	}()

	if !isLocalStored {
		if _, err := m.manifests.Put(ctx, manifest); err != nil {
			context.GetLogger(ctx).Errorf("unable to put manifest to storage: %v", err)
			return
		}
	}

	if err := m.imageStream.ImageManifestBlobStored(ctx, image); err != nil {
		context.GetLogger(ctx).Errorf("error updating Image: %v", err)
	}
}
