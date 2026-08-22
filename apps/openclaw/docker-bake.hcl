target "docker-metadata-action" {}

variable "APP" {
  default = "openclaw"
}

# renovate: datasource=docker depName=ghcr.io/openclaw/openclaw
variable "VERSION" {
  default = "2026.7.1-2"
}

variable "BASE_DIGEST" {
  default = "sha256:8789721d2e9b24b780a1504b56deb4c6bd5c7dbf96a1dd117e7c45c2ed72c8ac"
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
    BASE_DIGEST = "${BASE_DIGEST}"
    OPENCLAW_EXTENSIONS = "acpx anthropic brave browser canvas codex diffs discord document-extract duckduckgo exa file-transfer google litellm llm-task lobster memory-core memory-lancedb memory-wiki oc-path ollama openai openrouter openshell perplexity qa-channel qa-lab searxng sqlang skill-workshop tavily tokenjuice tts-local-cli vercel-ai-gateway vllm voice-call voyage web-readability webhooks xai zai @martian-engineering/lossless-claw @opik/opik-openclaw"
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
