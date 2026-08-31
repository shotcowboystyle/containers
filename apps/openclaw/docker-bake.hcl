target "docker-metadata-action" {}

variable "APP" {
  default = "openclaw"
}

# renovate: datasource=docker depName=ghcr.io/openclaw/openclaw
variable "VERSION" {
  default = "2026.8.1"
}

variable "BASE_DIGEST" {
  default = "sha256:e7849cb6c1ef1ead39ab4be7d85edb2df89611f486e283284c7cf35ce39a20d4"
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
