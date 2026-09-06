target "docker-metadata-action" {}

variable "APP" {
  default = "openclaw"
}

# renovate: datasource=docker depName=ghcr.io/openclaw/openclaw
variable "VERSION" {
  default = "2026.9.2"
}

variable "BASE_DIGEST" {
  default = "sha256:a8604855b76cd613cbaa45d6db093dc017b09a2faea5dc9cee023fb7ac262250"
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
