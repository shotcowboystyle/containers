# syntax=docker/dockerfile:1
ARG BASE_REGISTRY=ghcr.io \
    BASE_OWNER=openclaw \
    BASE_REPO=openclaw \
    BASE_TAG=latest
ARG BASE_REF=${BASE_REGISTRY}/${BASE_OWNER}/${BASE_REPO}:${BASE_TAG}

FROM ${BASE_REF}

ARG EXTRA_APT_PKGS="" \
    EXTRA_NPM_LOCAL_PKGS="" \
    EXTRA_NPM_GLOBAL_PKGS="" \
    EXTRA_PIP_PKGS="" \
    UV_VERSION=0.7.5

SHELL ["/bin/bash", "-euo", "pipefail", "-c"]

USER root

WORKDIR /app

ENV PLAYWRIGHT_BROWSERS_PATH=/home/node/.cache/ms-playwright \
    TERM=xterm-256color \
    PYTHONUSERBASE=/home/node/.local \
    NPM_CONFIG_PREFIX=/home/node/.npm-global \
    GOPATH=/home/node/go \
    RUSTUP_HOME=/home/node/.rustup \
    CARGO_HOME=/home/node/.cargo \
    PATH="/home/node/.local/bin:/home/node/.npm-global/bin:/home/node/go/bin:/home/node/.cargo/bin:${PATH}"

# apt install
RUN --mount=type=cache,target=/var/lib/apt,id=apt-lib \
    --mount=type=cache,target=/var/cache/apt,id=apt-cache \
    rm -f /etc/apt/apt.conf.d/docker-clean \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
        sqlite3 \
        python3 python3-pip python-is-python3 \
        build-essential cmake pkg-config \
        golang \
        rustc cargo \
        xvfb \
        xauth \
        ffmpeg \
        libglu1-mesa \
        gnupg \
        git curl wget jq xz-utils unzip zip \
        libffi-dev libssl-dev zlib1g-dev \
        imagemagick \
        ripgrep \
        rsync \
        tmux \
        vim \
        yq \
        yt-dlp \
        tesseract-ocr \
        ${EXTRA_APT_PKGS}

# npm global install
RUN --mount=type=cache,target=/home/node/.npm,id=npm-cache \
    npm i -g clawhub mcporter @playwright/mcp@0.0.68 @steipete/summarize @googleworkspace/cli ${EXTRA_NPM_GLOBAL_PKGS} \
    && if [[ -n "${EXTRA_NPM_LOCAL_PKGS}" ]]; then \
        npm i ${EXTRA_NPM_LOCAL_PKGS}; \
    fi \
    && chown -R node:node /home/node/.npm-global

# install uv (pinned version, direct to /usr/local/bin)
RUN --mount=type=cache,target=/home/node/.cache/uv,id=uv-cache,sharing=locked \
    curl -LsSf "https://astral.sh/uv/${UV_VERSION}/install.sh" | UV_INSTALL_DIR=/usr/local/bin sh

# install python deps into a venv owned by node
RUN --mount=type=cache,target=/home/node/.cache/uv,id=uv-cache,sharing=locked \
    PIP_USER=0 uv venv /home/node/.venv \
    && PIP_USER=0 uv pip install --python /home/node/.venv/bin/python nano-pdf lancedb ${EXTRA_PIP_PKGS} \
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
