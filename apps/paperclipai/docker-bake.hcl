variable "REGISTRY" {
  default = "ghcr.io/shotcowboystyle"
}

variable "APP" {
  default = "paperclip"
}

variable "VERSION" {
  // renovate: datasource=github-releases depName=paperclipai/paperclip
  default = "v2026.428.0"
}

variable "SOURCE" {
  default = "https://github.com/paperclipai/paperclip"
}

group "default" {
  targets = ["image-local"]
}

target "paperclip" {
  context = "."
  dockerfile = "Dockerfile"
  platforms = ["linux/amd64", "linux/arm64"]
  tags = [
    "${REGISTRY}/${APP}:${VERSION}",
    "${REGISTRY}/${APP}:latest"
  ]
  labels = {
    "org.opencontainers.image.source" = "https://github.com/shotcowboystyle/containers-paperclip"
    "org.opencontainers.image.description" = "Paperclip container image"
  }
}
