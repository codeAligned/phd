package server

import "github.com/docker/distribution/context"

func withAppMiddleware(parent context.Context, am appMiddleware) context.Context {
	return context.WithValue(parent, appMiddlewareKey, am)
}
