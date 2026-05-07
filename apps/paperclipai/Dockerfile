# ── Stage 1: base ─────────────────────────────────────────────
FROM node:24-trixie-slim AS base

RUN apt-get update \
  && apt-get install -y --no-install-recommends \
    build-essential \
    ca-certificates \
    gosu \
    curl \
    gh \
    git \
    nano \
    tini \
    wget \
    ripgrep \
    rustc \
    python3 \
  && mkdir -p -m 755 /etc/apt/keyrings \
  && export keyring_path="/etc/apt/keyrings/githubcli-archive-keyring.gpg" \
  && wget -qO- https://cli.github.com/packages/githubcli-archive-keyring.gpg | tee "$keyring_path" > /dev/null \
    && chmod go+r "$keyring_path" \
  && echo "deb [arch=$(dpkg --print-architecture) signed-by=$keyring_path] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
  && apt-get update \
  && apt-get install -y --no-install-recommends gh \
  && rm -rf /var/lib/apt/lists/* \
  && corepack enable

# ── Stage 2: deps ─────────────────────────────────────────────
# Install all dependencies (dev + prod) using lockfile.
# This layer is cached unless a package.json or lockfile changes.
FROM base AS deps
ARG VERSION

WORKDIR /app
RUN wget -qO- "https://github.com/paperclipai/paperclip/archive/refs/tags/${VERSION}.tar.gz" | tar xzf - --strip-components=1

RUN pnpm install --frozen-lockfile

# ── Stage 3: build ────────────────────────────────────────────
FROM base AS build
WORKDIR /app

COPY defaults/home/ /home/node/.config/

COPY --from=deps /app /app
COPY . .
RUN pnpm -r build \
  && test -f server/dist/index.js || (echo "ERROR: server build output missing" && exit 1)

# ── Stage 4: agent CLIs ──────────────────────────────────────
# Separate stage so agent CLI install is cached independently.
# Bump the versions here to update (avoids @latest cache-busting).
FROM base AS agent-clis

RUN npm install --global --omit=dev \
    @anthropic-ai/claude-code@2.1.132 \
    @google/gemini-cli@0.41.2 \
    @openai/codex@0.128.0 \
    opencode-ai@1.14.40 \
    @mariozechner/pi-coding-agent@0.73.0 \
  && curl https://cursor.com/install -fsS | bash \
  && npm cache clean --force \
  && rm -rf /tmp/*

# ── Stage 5: production ──────────────────────────────────────
FROM node:24-trixie-slim AS production

# LABEL org.opencontainers.image.source="https://github.com/shotcowboystyle/containers-paperclip"
# LABEL org.opencontainers.image.description="Paperclip - AI company orchestration platform"
# LABEL org.opencontainers.image.vendor="Shotcowboystyle Containers"
# LABEL org.opencontainers.image.licenses="MIT"

ARG USER_UID=1000
ARG USER_GID=1000

RUN apt-get update \
  && apt-get install -y --no-install-recommends \
    build-essential \
    ca-certificates \
    gosu \
    curl \
    gh \
    git \
    nano \
    tini \
    wget \
    ripgrep \
    rustc \
    python3 \
    openssh-client \
    jq \
  && rm -rf /var/lib/apt/lists/*

RUN corepack enable

# Copy pre-built agent CLIs from separate cached stage
COPY --from=agent-clis /usr/local/lib/node_modules /usr/local/lib/node_modules
COPY --from=agent-clis /usr/local/bin/ /usr/local/bin/

RUN mkdir -p /paperclip && chown node:node /paperclip

WORKDIR /app

COPY --chown=node:node --from=build /app /app

# COPY scripts/docker-entrypoint.sh /usr/local/bin/
# RUN chmod +x /usr/local/bin/docker-entrypoint.sh

ENV NODE_ENV=production \
  HOME=/paperclip \
  HOST=0.0.0.0 \
  PORT=3100 \
  SERVE_UI=true \
  PAPERCLIP_HOME=/paperclip \
  PAPERCLIP_INSTANCE_ID=default \
  USER_UID=${USER_UID} \
  USER_GID=${USER_GID} \
  PAPERCLIP_CONFIG=/paperclip/instances/default/config.json \
  PAPERCLIP_DEPLOYMENT_MODE=authenticated \
  PAPERCLIP_DEPLOYMENT_EXPOSURE=private \
  OPENCODE_ALLOW_ALL_MODELS=true

VOLUME ["/paperclip"]
EXPOSE 3100

HEALTHCHECK --interval=30s --timeout=5s --start-period=15s --retries=3 \
  CMD curl -fsS http://localhost:3100/api/health || exit 1

ENTRYPOINT ["tini", "--", "/entrypoint.sh"]
CMD ["node", "--conditions=production", "server/dist/index.js"]
