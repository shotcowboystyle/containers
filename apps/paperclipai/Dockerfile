# syntax=docker/dockerfile:1.20

# VERSION selects the renovate-tracked paperclip release and the base image tag.
ARG VERSION=latest

# ── Stage 1: extra agent CLIs ─────────────────────────────────────────────────
# Install only the CLIs absent from ghcr.io/paperclipai/paperclip.
# That image already provides: @anthropic-ai/claude-code, @openai/codex, opencode-ai
FROM node:lts-trixie-slim AS agent-clis

RUN apt-get update \
  && apt-get install -y --no-install-recommends curl \
  && rm -rf /var/lib/apt/lists/* \
  && npm install --global --prefix=/opt/extras --omit=dev \
    @google/gemini-cli@0.41.2 \
    @mariozechner/pi-coding-agent@0.73.0 \
  && npm cache clean --force

# Cursor is amd64-only; skip silently on other architectures.
# Note: curl-pipe-sh is the only supported install method upstream provides.
ARG TARGETARCH
RUN if [ "${TARGETARCH}" = "amd64" ]; then \
      curl https://cursor.com/install -fsS | bash \
      && mkdir -p /opt/extras/bin \
      && cp /root/.cursor/bin/cursor /opt/extras/bin/; \
    fi

# ── Stage 2: production ───────────────────────────────────────────────────────
FROM ghcr.io/paperclipai/paperclip:${VERSION} AS production

ARG USER_UID=1000
ARG USER_GID=1000

# Install tools absent from the paperclip base image.
# Base already provides: ca-certificates, gosu, curl, gh, git, wget,
#                        ripgrep, python3, openssh-client, jq, corepack
RUN apt-get update \
  && apt-get install -y --no-install-recommends \
    nano \
    tini \
    vim \
  && rm -rf /var/lib/apt/lists/*

# Extra CLIs in a dedicated prefix — avoids overwriting system binaries from the base image
COPY --from=agent-clis /opt/extras /opt/extras

# .gitconfig belongs at $HOME (/paperclip); the include path inside .gitconfig is
# hardcoded to /home/node/.config/git/gh-credential-helper.inc (absolute, outside the volume)
COPY --chown=node:node defaults/home/.gitconfig /paperclip/.gitconfig
COPY --chown=node:node defaults/home/git/ /home/node/.config/git/
COPY --chown=node:node defaults/home/opencode/ /paperclip/.config/opencode/

COPY --chmod=755 ./entrypoint.sh /entrypoint.sh

ENV PATH="/opt/extras/bin:${PATH}" \
    USER_UID=${USER_UID} \
    USER_GID=${USER_GID}

HEALTHCHECK --interval=30s --timeout=5s --start-period=15s --retries=3 \
  CMD curl -fsS http://localhost:3100/api/health || exit 1

ENTRYPOINT ["tini", "-s", "--", "/entrypoint.sh"]
CMD ["node", "--import", "./server/node_modules/tsx/dist/loader.mjs", "server/dist/index.js"]
