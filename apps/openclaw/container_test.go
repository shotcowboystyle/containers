package main

import (
	"testing"

	"github.com/shotcowboystyle/containers/testhelpers"
)

func Test(t *testing.T) {
	image := testhelpers.GetTestImage("ghcr.io/shotcowboystyle/openclaw:rolling")
	testhelpers.TestCommandSucceeds(t, image, nil, "/usr/local/bin/freeride", "--version")
}
