package main

import (
	"context"
	"testing"

	"github.com/shotcowboystyle/containers/testhelpers"
)

func Test(t *testing.T) {
	ctx := context.Background()
	image := testhelpers.GetTestImage("ghcr.io/shotcowboystyle/paperclip:rolling")
	testhelpers.TestHTTPEndpoint(t, ctx, image, testhelpers.HTTPTestConfig{
		Port: "3100",
		StatusCode: 400,
	}, nil)
}
