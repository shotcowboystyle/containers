package main

import (
	"os"
	"testing"

	"github.com/shotcowboystyle/containers/testhelpers"
)

func Test(t *testing.T) {
	image := testhelpers.GetTestImage("ghcr.io/shotcowboystyle/freeride:rolling")
	// Optional: lets `freeride auto` pick models at startup. Unset (e.g. fork PRs) still tests serve.
	config := &testhelpers.ContainerConfig{Env: map[string]string{}}
	if key := os.Getenv("OPENROUTER_API_KEY"); key != "" {
		config.Env["OPENROUTER_API_KEY"] = key
	}
	testhelpers.TestHTTPEndpoint(t, image, testhelpers.HTTPTestConfig{Port: "11343", Path: "/health"}, config)
}
