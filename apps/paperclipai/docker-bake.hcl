target "docker-metadata-action" {}

variable "REGISTRY" {
  default = "ghcr.io/shotcowboystyle"
}

variable "IMAGE_NAME" {
  default = "paperclip"
}

variable "VERSION" {
  default = "v2026.428.0"
}

target "paperclip" {
  inherits   = ["docker-metadata-action"]
  context    = "."
  dockerfile = "Dockerfile"
  platforms = ["linux/amd64", "linux/arm64"]
}
