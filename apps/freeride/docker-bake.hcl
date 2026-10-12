target "docker-metadata-action" {}

variable "APP" {
  default = "freeride"
}

variable "VERSION" {
  // renovate: datasource=pypi depName=freeride-gateway
  default = "0.4.0a24"
}

variable "SOURCE" {
  default = "https://github.com/Shaivpidadi/FreeRideV3"
}

group "default" {
  targets = ["image-local"]
}

target "image" {
  inherits = ["docker-metadata-action"]
  args = {
    VERSION = "${VERSION}"
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
