target "docker-metadata-action" {}

variable "APP" {
  default = "open-design"
}

# renovate: datasource=github-releases depName=nexu-io/open-design
variable "VERSION" {
  default = "0.10.0"
}

# renovate: datasource=docker depName=docker.io/library/node
variable "NODE_VERSION" {
  default = "24-alpine"
}

variable "NODE_DIGEST" {
  default = "sha256:d1b3b4da11eefd5941e7f0b9cf17783fc99d9c6fc34884a665f40a06dbdfc94f"
}

variable "SOURCE" {
  default = "https://github.com/nexu-io/open-design"
}

group "default" {
  targets = ["image-local"]
}

target "image" {
  inherits = ["docker-metadata-action"]
  args = {
    VERSION      = "${VERSION}"
    NODE_VERSION = "${NODE_VERSION}"
    NODE_DIGEST  = "${NODE_DIGEST}"
  }
  labels = {
    "org.opencontainers.image.source" = "${SOURCE}"
  }
}

target "image-local" {
  inherits = ["image"]
  output   = ["type=docker"]
  tags     = ["${APP}:${VERSION}"]
}

target "image-all" {
  inherits  = ["image"]
  platforms = [
    "linux/amd64",
    "linux/arm64"
  ]
}
