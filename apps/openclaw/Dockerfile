# syntax=docker/dockerfile:1.20

# renovate: datasource=docker depName=ghcr.io/astral-sh/uv
ARG UV_VERSION=0.7.5
# Upstream openclaw base — we always extend the `${VERSION}-slim` variant,
# pinned by digest for reproducibility.
# renovate: datasource=docker depName=ghcr.io/openclaw/openclaw
ARG VERSION=2026.5.19-beta.1
ARG BASE_DIGEST=sha256:5df2bb0d51612571ad7b78c748bbddb345c432c17ad53be737aca051a99ed241
ARG OPENCLAW_BASE=ghcr.io/openclaw/openclaw:${VERSION}-slim@${BASE_DIGEST}

FROM ghcr.io/astral-sh/uv:${UV_VERSION} AS uv-bin

FROM ${OPENCLAW_BASE}

LABEL org.opencontainers.image.description="OpenClaw slim — Python/uv venv, Go toolchain, Docker CLI, gh CLI, Playwright+Chromium, MCP tools"

SHELL ["/bin/bash", "-euo", "pipefail", "-c"]

ARG TARGETARCH
# renovate: datasource=github-releases depName=cli/cli
ARG GH_VERSION=2.61.0
# renovate: datasource=github-releases depName=golang/go
ARG GO_VERSION=1.26.3
ARG OPENCLAW_DOCKER_GPG_FINGERPRINT="9DC858229FC7DD38854AE2D88D81803C0EBFCD88"
ARG OPENCLAW_EXTENSIONS=""

ENV NODE_ENV=production \
    TERM=xterm-256color \
    OPENCLAW_DEBUG=1 \
    PLAYWRIGHT_BROWSERS_PATH=/home/node/.cache/ms-playwright \
    PNPM_HOME=/home/node/.npm-global \
    NPM_CONFIG_PREFIX=/home/node/.npm-global \
    GOROOT=/usr/local/go \
    GOPATH=/home/node/go \
    VIRTUAL_ENV=/home/node/.venv \
    PATH="/usr/local/go/bin:/home/node/.venv/bin:/home/node/.npm-global:/home/node/.npm-global/bin:/home/node/go/bin:/home/node/.local/bin:${PATH}"

USER root

# ── apt: essentials only ─────────────────────────────────────────────────────
RUN --mount=type=cache,target=/var/cache/apt,id=apt-cache,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,id=apt-lib,sharing=locked \
    rm -f /etc/apt/apt.conf.d/docker-clean \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        ffmpeg \
        gnupg \
        imagemagick \
        jq \
        ripgrep \
        rsync \
        sqlite3 \
        tesseract-ocr \
        tmux \
        vim \
        xvfb \
        xz-utils \
        yq \
        yt-dlp

# ── Docker CLI (mirrors upstream OPENCLAW_INSTALL_DOCKER_CLI hardening) ─────
RUN --mount=type=cache,target=/var/cache/apt,id=apt-cache,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,id=apt-lib,sharing=locked \
    install -m 0755 -d /etc/apt/keyrings \
    && curl -fsSL https://download.docker.com/linux/debian/gpg -o /tmp/docker.gpg.asc \
    && expected_fpr="$(printf '%s' "$OPENCLAW_DOCKER_GPG_FINGERPRINT" | tr '[:lower:]' '[:upper:]' | tr -d '[:space:]')" \
    && pub_count="$(gpg --batch --show-keys --with-colons /tmp/docker.gpg.asc | awk -F: '$1 == "pub" { c++ } END { print c+0 }')" \
    && if [ "$pub_count" != "1" ]; then echo "ERROR: Docker apt key must contain exactly one public key (found $pub_count)" >&2; exit 1; fi \
    && actual_fpr="$(gpg --batch --show-keys --with-colons /tmp/docker.gpg.asc | awk -F: '$1 == "fpr" { print toupper($10); exit }')" \
    && if [ -z "$actual_fpr" ] || [ "$actual_fpr" != "$expected_fpr" ]; then echo "ERROR: Docker GPG fingerprint mismatch (expected $expected_fpr, got ${actual_fpr:-<empty>})" >&2; exit 1; fi \
    && gpg --dearmor -o /etc/apt/keyrings/docker.gpg /tmp/docker.gpg.asc \
    && rm -f /tmp/docker.gpg.asc \
    && chmod a+r /etc/apt/keyrings/docker.gpg \
    && printf 'deb [arch=%s signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian bookworm stable\n' \
        "$(dpkg --print-architecture)" > /etc/apt/sources.list.d/docker.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends docker-ce-cli docker-compose-plugin

RUN rm -rf /var/lib/apt/lists/*

# ── gh CLI (TARGETARCH-aware tarball) ───────────────────────────────────────
RUN gh_arch="${TARGETARCH:?TARGETARCH must be set by buildx}" \
    && curl -fsSL "https://github.com/cli/cli/releases/download/v${GH_VERSION}/gh_${GH_VERSION}_linux_${gh_arch}.tar.gz" \
        -o /tmp/gh.tar.gz \
    && tar -xzf /tmp/gh.tar.gz -C /tmp \
    && install -m 0755 "/tmp/gh_${GH_VERSION}_linux_${gh_arch}/bin/gh" /usr/local/bin/gh \
    && rm -rf /tmp/gh.tar.gz "/tmp/gh_${GH_VERSION}_linux_${gh_arch}"

# ── Go toolchain (TARGETARCH-aware tarball) ─────────────────────────────────
RUN go_arch="${TARGETARCH:?TARGETARCH must be set by buildx}" \
    && curl -fsSL "https://go.dev/dl/go${GO_VERSION}.linux-${go_arch}.tar.gz" -o /tmp/go.tar.gz \
    && tar -xzf /tmp/go.tar.gz -C /usr/local \
    && rm -f /tmp/go.tar.gz

# ── uv binary + Python venv (node-owned) ────────────────────────────────────
COPY --from=uv-bin /uv /usr/local/bin/uv
RUN --mount=type=cache,target=/root/.cache/uv,id=uv-cache,sharing=locked \
    uv venv /home/node/.venv \
    && uv pip install --python /home/node/.venv/bin/python \
        nano-pdf \
        lancedb \
        faster-whisper \
    && chown -R node:node /home/node/.venv

# ── npm globals via pnpm ────────────────────────────────────────────────────
RUN --mount=type=cache,target=/root/.local/share/pnpm/store,id=pnpm-store,sharing=locked \
    mkdir -p "$PNPM_HOME" \
    && pnpm add -g \
        mcporter \
        @playwright/mcp@0.0.68 \
    && chown -R node:node "$PNPM_HOME"

# ── Playwright Chromium (replicates upstream OPENCLAW_INSTALL_BROWSER) ──────
RUN --mount=type=cache,target=/pw-cache,id=pw-browsers,sharing=locked \
    PLAYWRIGHT_BROWSERS_PATH=/pw-cache \
        /app/node_modules/.bin/playwright-core install --with-deps chromium \
    && mkdir -p "$PLAYWRIGHT_BROWSERS_PATH" \
    && rsync -a --delete /pw-cache/ "$PLAYWRIGHT_BROWSERS_PATH/" \
    && chown -R node:node "$PLAYWRIGHT_BROWSERS_PATH" \
    && find "$PLAYWRIGHT_BROWSERS_PATH" -type f -name chrome -print -quit > /tmp/chrome_binary_path \
    && test -s /tmp/chrome_binary_path

# ── mcporter playwright config ──────────────────────────────────────────────
RUN mkdir -p /app/config /home/node/.openclaw/config /home/node/.openclaw/extensions \
    && ln -sf /home/node/.openclaw/config/mcporter.json /app/config/mcporter.json \
    && chown -R node:node /home/node/.openclaw /app/config \
    && mcporter config add playwright \
        --command /usr/local/bin/playwright-mcp \
        --arg --executable-path \
        --arg "$(cat /tmp/chrome_binary_path)" \
        --arg --headless \
        --scope project \
    && rm -f /tmp/chrome_binary_path

# Optional baked extensions; runtime overlay at /home/node/.openclaw/extensions
# stays writable for Helm-mounted PVCs.
USER node
# RUN if [ -n "${OPENCLAW_EXTENSIONS}" ]; then \
#         openclaw extensions install ${OPENCLAW_EXTENSIONS} || \
#             { echo "ERROR: failed to install extensions: ${OPENCLAW_EXTENSIONS}" >&2; exit 1; }; \
#     fi
