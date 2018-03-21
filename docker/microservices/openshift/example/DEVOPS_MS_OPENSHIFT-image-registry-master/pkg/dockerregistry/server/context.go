package server

import (
	"github.com/docker/distribution/context"

	"github.com/openshift/image-registry/pkg/dockerregistry/server/client"
)

type contextKey string

const (
	// appMiddlewareKey is for testing purposes.
	appMiddlewareKey contextKey = "appMiddleware"

	// remoteBlobAccessCheckEnabledKey is the key for the flag in Contexts
	// to allow blobDescriptorService to stat remote blobs.
	remoteBlobAccessCheckEnabledKey contextKey = "remoteBlobAccessCheckEnabled"

	// userClientKey is the key for a origin's client with the current user's
	// credentials in Contexts.
	userClientKey contextKey = "userClient"

	// authPerformedKey is the key to indicate that authentication was
	// performed in Contexts.
	authPerformedKey contextKey = "authPerformed"

	// deferredErrorsKey is the key for deferred errors in Contexts.
	deferredErrorsKey contextKey = "deferredErrors"
)

func appMiddlewareFrom(ctx context.Context) appMiddleware {
	am, _ := ctx.Value(appMiddlewareKey).(appMiddleware)
	return am
}

// withRemoteBlobAccessCheckEnabled returns a new Context that allows
// blobDescriptorService to stat remote blobs. It is useful only in case
// of manifest verification.
func withRemoteBlobAccessCheckEnabled(parent context.Context, enable bool) context.Context {
	return context.WithValue(parent, remoteBlobAccessCheckEnabledKey, enable)
}

// remoteBlobAccessCheckEnabledFrom reports whether ctx allows
// blobDescriptorService to stat remote blobs.
func remoteBlobAccessCheckEnabledFrom(ctx context.Context) bool {
	enabled, _ := ctx.Value(remoteBlobAccessCheckEnabledKey).(bool)
	return enabled
}

// withUserClient returns a new Context with the origin's client.
// This client should have the current user's credentials
func withUserClient(parent context.Context, userClient client.Interface) context.Context {
	return context.WithValue(parent, userClientKey, userClient)
}

// userClientFrom returns the origin's client stored in ctx, if any.
func userClientFrom(ctx context.Context) (client.Interface, bool) {
	userClient, ok := ctx.Value(userClientKey).(client.Interface)
	return userClient, ok
}

// withAuthPerformed returns a new Context with indication that authentication
// was performed.
func withAuthPerformed(parent context.Context) context.Context {
	return context.WithValue(parent, authPerformedKey, true)
}

// authPerformed reports whether ctx has indication that authentication was
// performed.
func authPerformed(ctx context.Context) bool {
	authPerformed, ok := ctx.Value(authPerformedKey).(bool)
	return ok && authPerformed
}

// withDeferredErrors returns a new Context that carries deferred errors.
func withDeferredErrors(parent context.Context, errs deferredErrors) context.Context {
	return context.WithValue(parent, deferredErrorsKey, errs)
}

// deferredErrorsFrom returns the deferred errors stored in ctx, if any.
func deferredErrorsFrom(ctx context.Context) (deferredErrors, bool) {
	errs, ok := ctx.Value(deferredErrorsKey).(deferredErrors)
	return errs, ok
}
