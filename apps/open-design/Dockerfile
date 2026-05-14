# syntax=docker/dockerfile:1.20

# renovate: datasource=docker depName=docker.io/library/node
ARG NODE_VERSION=24-alpine
ARG NODE_DIGEST=sha256:d1b3b4da11eefd5941e7f0b9cf17783fc99d9c6fc34884a665f40a06dbdfc94f
ARG NODE_IMAGE=docker.io/library/node:${NODE_VERSION}@${NODE_DIGEST}

# renovate: datasource=github-releases depName=nexu-io/open-design
ARG VERSION=0.7.0

# ── Stage 1: upstream source checkout ───────────────────────────────────────
FROM ${NODE_IMAGE} AS source
ARG VERSION
RUN apk add --no-cache git
WORKDIR /src
RUN git clone --depth 1 --branch open-design-v${VERSION} \
        https://github.com/nexu-io/open-design.git . \
    && rm -rf .git

# ── Stage 2: build daemon + web ─────────────────────────────────────────────
FROM ${NODE_IMAGE} AS build

ARG HTTP_PROXY
ARG HTTPS_PROXY
ARG http_proxy
ARG https_proxy
ARG no_proxy
ARG NO_PROXY

ENV HTTP_PROXY=${HTTP_PROXY} \
    HTTPS_PROXY=${HTTPS_PROXY} \
    http_proxy=${http_proxy} \
    https_proxy=${https_proxy} \
    no_proxy=${no_proxy} \
    NO_PROXY=${NO_PROXY} \
    CI=true

RUN apk add --no-cache python3 make g++ git curl

WORKDIR /app

# Install deps first so they cache independently of source churn.
COPY --from=source /src/package.json /src/pnpm-lock.yaml /src/pnpm-workspace.yaml ./
COPY --from=source /src/scripts/postinstall.mjs ./scripts/postinstall.mjs
COPY --from=source /src/packages ./packages
COPY --from=source /src/tools ./tools
COPY --from=source /src/apps/daemon/package.json ./apps/daemon/package.json
COPY --from=source /src/apps/web/package.json ./apps/web/package.json
COPY --from=source /src/e2e/package.json ./e2e/package.json

RUN --mount=type=cache,target=/root/.local/share/pnpm/store,id=pnpm-store,sharing=locked \
    corepack enable \
    && corepack prepare pnpm@10.33.2 --activate \
    && pnpm install --frozen-lockfile

COPY --from=source /src/apps ./apps

RUN pnpm --filter @open-design/daemon build \
    && pnpm --filter @open-design/web build \
    && pnpm --filter @open-design/daemon deploy --legacy --prod /app/deploy/daemon \
    && pnpm store prune \
    && rm -rf \
        /root/.cache \
        /root/.local/share/pnpm/store \
        /app/deploy/daemon/node_modules/.cache \
        /app/deploy/daemon/node_modules/@types \
        /app/deploy/daemon/node_modules/.pnpm/@types+* \
        /app/deploy/daemon/node_modules/.pnpm/better-sqlite3@*/node_modules/better-sqlite3/deps \
        /app/deploy/daemon/node_modules/.pnpm/better-sqlite3@*/node_modules/better-sqlite3/src \
    && find /app/deploy/daemon/node_modules -type d \( \
        -name test -o \
        -name tests -o \
        -name "__tests__" -o \
        -name docs -o \
        -name doc -o \
        -name example -o \
        -name examples -o \
        -name ".github" \
       \) -prune -exec rm -rf '{}' + \
    && find /app/deploy/daemon/node_modules -type f \( \
        -name "*.md" -o \
        -name "*.markdown" -o \
        -name "*.d.ts" -o \
        -name "*.d.cts" -o \
        -name "*.d.mts" -o \
        -name "*.map" -o \
        -name "*.tsbuildinfo" -o \
        -name "binding.gyp" \
       \) -delete

# ── Stage 3: runtime ────────────────────────────────────────────────────────
FROM ${NODE_IMAGE} AS runtime

LABEL org.opencontainers.image.description="Open Design daemon + static web"

RUN apk add --no-cache tini curl bash git \
    && addgroup -S -g 1001 open-design \
    && adduser -S -D -h /home/open-design -u 1001 -G open-design open-design \
    && mkdir -p /home/open-design \
    && chown open-design:open-design /home/open-design

ENV PNPM_HOME=/usr/local/share/pnpm \
    PATH=/usr/local/share/pnpm:/home/open-design/.local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

# Install gemini-cli globally via pnpm into a system-wide location.
RUN corepack enable \
    && corepack prepare pnpm@10.33.2 --activate \
    && mkdir -p "$PNPM_HOME" \
    && pnpm add -g @google/gemini-cli \
    && chmod -R a+rX "$PNPM_HOME"

# Install Claude Code and Cursor Agent into the open-design user's home.
RUN HOME=/home/open-design mkdir -p /home/open-design/.local/bin \
    && HOME=/home/open-design bash -c 'curl -fsSL https://claude.ai/install.sh | bash' \
    && HOME=/home/open-design bash -c 'curl -fsS https://cursor.com/install | bash' \
    && chown -R open-design:open-design /home/open-design

WORKDIR /app

COPY --from=build  --chown=open-design:open-design /app/deploy/daemon       ./apps/daemon
COPY --from=build  --chown=open-design:open-design /app/apps/web/out        ./apps/web/out
COPY --from=source --chown=open-design:open-design /src/skills              ./skills
COPY --from=source --chown=open-design:open-design /src/design-systems      ./design-systems
COPY --from=source --chown=open-design:open-design /src/craft               ./craft
COPY --from=source --chown=open-design:open-design /src/prompt-templates    ./prompt-templates
COPY --from=source --chown=open-design:open-design /src/assets/frames       ./assets/frames
COPY --from=source --chown=open-design:open-design /src/assets/community-pets ./assets/community-pets

RUN mkdir -p /app/.od && chown -R open-design:open-design /app

ENV NODE_ENV=production \
    NODE_OPTIONS=--max-old-space-size=192 \
    OD_BIND_HOST=0.0.0.0 \
    OD_PORT=7456 \
    HOME=/home/open-design

EXPOSE 7456

USER open-design

ENTRYPOINT ["/sbin/tini", "--"]
CMD ["node", "apps/daemon/dist/cli.js", "--no-open"]
