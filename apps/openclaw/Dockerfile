# syntax=docker/dockerfile:1

# renovate: datasource=docker depName=ghcr.io/astral-sh/uv
FROM ghcr.io/astral-sh/uv:0.7.5 AS uv-bin

ARG BASE_REGISTRY=ghcr.io \
    BASE_OWNER=openclaw \
    BASE_REPO=openclaw \
    BASE_TAG=2026.5.7-slim \
    BASE_DIGEST=sha256:1af3f457a2d5a1d210f4d95634fa5da6e23f9c0ac7b52ef4bc38e2ecf09704fd
ARG BASE_REF=${BASE_REGISTRY}/${BASE_OWNER}/${BASE_REPO}:${BASE_TAG}@${BASE_DIGEST}

FROM ${BASE_REF}

LABEL org.opencontainers.image.description="OpenClaw with Python/uv, Go, Rust, Playwright+Chromium, and MCP tools"

ARG EXTRA_APT_PKGS="" \
    EXTRA_NPM_LOCAL_PKGS="" \
    EXTRA_NPM_GLOBAL_PKGS="" \
    EXTRA_PIP_PKGS=""

SHELL ["/bin/bash", "-euo", "pipefail", "-c"]

USER root

WORKDIR /app

ENV PLAYWRIGHT_BROWSERS_PATH=/home/node/.cache/ms-playwright \
    TERM=xterm-256color \
    NPM_CONFIG_PREFIX=/home/node/.npm-global \
    GOPATH=/home/node/go \
    RUSTUP_HOME=/home/node/.rustup \
    CARGO_HOME=/home/node/.cargo \
    VIRTUAL_ENV=/home/node/.venv \
    PATH="/home/node/.venv/bin:/home/node/.local/bin:/home/node/.npm-global/bin:/home/node/go/bin:/home/node/.cargo/bin:${PATH}"

# apt install
RUN --mount=type=cache,target=/var/lib/apt,id=apt-lib \
    --mount=type=cache,target=/var/cache/apt,id=apt-cache \
    rm -f /etc/apt/apt.conf.d/docker-clean \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
        sqlite3 \
        python3 python3-pip python-is-python3 \
        golang \
        rustc cargo \
        xvfb \
        xauth \
        ffmpeg \
        libglu1-mesa \
        gnupg \
        git curl wget jq xz-utils unzip zip \
        imagemagick \
        ripgrep \
        rsync \
        tmux \
        vim \
        yq \
        yt-dlp \
        tesseract-ocr \
        ${EXTRA_APT_PKGS}

COPY --from=uv-bin /uv /usr/local/bin/uv

# npm global install
# clawhub omitted — already present in the upstream openclaw base image
RUN --mount=type=cache,target=/root/.npm,id=npm-cache \
    npm i -g mcporter @playwright/mcp@0.0.68 @steipete/summarize @googleworkspace/cli ${EXTRA_NPM_GLOBAL_PKGS} \
    && if [[ -n "${EXTRA_NPM_LOCAL_PKGS}" ]]; then \
        npm i ${EXTRA_NPM_LOCAL_PKGS}; \
    fi \
    && chown -R node:node /home/node/.npm-global

# install python deps into a venv owned by node
RUN --mount=type=cache,target=/root/.cache/uv,id=uv-cache,sharing=locked \
    uv venv /home/node/.venv \
    && uv pip install --python /home/node/.venv/bin/python nano-pdf lancedb ${EXTRA_PIP_PKGS} \
    && chown -R node:node /home/node/.venv

# playwright-core browser install
RUN --mount=type=cache,target=/pw-cache,id=pw-browsers \
    PLAYWRIGHT_BROWSERS_PATH=/pw-cache \
    /app/node_modules/.bin/playwright-core install --with-deps chromium \
    && mkdir -p "$PLAYWRIGHT_BROWSERS_PATH" \
    && rsync -a --delete /pw-cache/ "$PLAYWRIGHT_BROWSERS_PATH/" \
    && chown -R node:node "$PLAYWRIGHT_BROWSERS_PATH" \
    && find "$PLAYWRIGHT_BROWSERS_PATH" -type f -name chrome -print -quit > /tmp/chrome_binary_path \
    && test -s /tmp/chrome_binary_path || { echo "ERROR: chrome binary not found in $PLAYWRIGHT_BROWSERS_PATH"; exit 1; }

# mcporter configuration
RUN mkdir -p /app/config /home/node/.openclaw/config \
    && ln -sf /home/node/.openclaw/config/mcporter.json /app/config/mcporter.json \
    && chown -R node:node /home/node/.openclaw /app/config \
    && mcporter config add playwright \
        --command /usr/local/bin/playwright-mcp \
        --arg --executable-path \
        --arg "$(cat /tmp/chrome_binary_path)" \
        --arg --headless \
        --scope project \
    && rm -f /tmp/chrome_binary_path

# switch to runtime user
USER node

ENV HOME=/home/node

RUN openclaw completion --write-state \
    && openclaw completion -i -s bash
