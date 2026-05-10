target "docker-metadata-action" {}

variable "APP" {
  default = "openclaw"
}

variable "VERSION" {
  // renovate: datasource=github-releases depName=openclaw/openclaw
  default = "2026.5.9-beta.1-slim"
}

variable "BASE_DIGEST" {
  // renovate: datasource=docker depName=ghcr.io/openclaw/openclaw
  default = "sha256:1af3f457a2d5a1d210f4d95634fa5da6e23f9c0ac7b52ef4bc38e2ecf09704fd"
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
    VERSION     = "${VERSION}"
    BASE_TAG    = "${VERSION}"
    BASE_DIGEST = "${BASE_DIGEST}"
  }
  labels = {
    "org.opencontainers.image.source" = "${SOURCE}"
  }
}

target "image-local" {
  inherits = ["image"]
  output = ["type=docker"]
  tags = ["${APP}:${VERSION}"]
}

target "image-all" {
  inherits = ["image"]
  platforms = [
    "linux/amd64",
    "linux/arm64"
  ]
}
