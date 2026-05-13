target "docker-metadata-action" {}

variable "APP" {
  default = "openclaw-full"
}

# Tracks the openclaw slim image version. Renovate updates this in lockstep
# with apps/openclaw/docker-bake.hcl so the full image is rebuilt from a
# matching slim base.
# renovate: datasource=docker depName=ghcr.io/openclaw/openclaw
variable "VERSION" {
  default = "2026.5.12-beta.4"
}

variable "SOURCE" {
  default = "https://github.com/openclaw/openclaw"
}

group "default" {
  targets = ["image-local"]
}

target "image" {
  inherits = ["docker-metadata-action"]
  args = {
    # CI provides VENDOR; BASE_TAG defaults to `rolling` so the published
    # slim image is consumed during release builds.
    BASE_TAG = "rolling"
  }
  labels = {
    "org.opencontainers.image.source" = "${SOURCE}"
  }
}

target "image-local" {
  inherits = ["image"]
  output   = ["type=docker"]
  tags     = ["${APP}:${VERSION}"]
  # Locally we extend the locally-tagged slim image (no registry prefix).
  args = {
    VENDOR   = "local"
    BASE_TAG = "${VERSION}"
  }
  contexts = {
    "ghcr.io/local/openclaw:${VERSION}" = "docker-image://openclaw:${VERSION}"
  }
}

target "image-all" {
  inherits  = ["image"]
  platforms = [
    "linux/amd64",
    "linux/arm64"
  ]
}
