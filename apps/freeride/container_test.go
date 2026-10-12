package main

import (
	"testing"

	"github.com/shotcowboystyle/containers/testhelpers"
)

func Test(t *testing.T) {
	image := testhelpers.GetTestImage("ghcr.io/shotcowboystyle/freeride:rolling")
	testhelpers.TestHTTPEndpoint(t, image, testhelpers.HTTPTestConfig{Port: "11343", Path: "/health"}, nil)
}
