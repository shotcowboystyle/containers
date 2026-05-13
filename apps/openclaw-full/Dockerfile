# syntax=docker/dockerfile:1.20

# Extends the published openclaw slim image with niche tools that aren't
# warranted in the production-baseline image. The base reference resolves to
# `ghcr.io/${VENDOR}/openclaw:${BASE_TAG}` so CI consumes the registry image,
# while local builds point at the locally-tagged `openclaw:${VERSION}`.
ARG VENDOR=local
ARG BASE_TAG=rolling
ARG OPENCLAW_BASE=ghcr.io/${VENDOR}/openclaw:${BASE_TAG}

FROM ${OPENCLAW_BASE}

LABEL org.opencontainers.image.description="OpenClaw full — slim plus gemini-cli, summarize, and Go-based niche CLIs"

SHELL ["/bin/bash", "-euo", "pipefail", "-c"]

ARG TARGETARCH
# renovate: datasource=github-releases depName=openhue/openhue-cli
ARG OPENHUE_VERSION=0.23
# renovate: datasource=github-releases depName=steipete/gogcli
ARG GOGCLI_VERSION=0.16.0

USER root

# ── npm-based niche tools ───────────────────────────────────────────────────
RUN --mount=type=cache,target=/root/.local/share/pnpm/store,id=pnpm-store,sharing=locked \
    pnpm add -g \
        @google/gemini-cli \
        @steipete/summarize \
    && chown -R node:node "$PNPM_HOME"

# ── Go-installed niche tools (one module per `go install`) ──────────────────
RUN --mount=type=cache,target=/root/.cache/go-build,id=go-build,sharing=locked \
    --mount=type=cache,target=/go/pkg/mod,id=go-mod,sharing=locked \
    export GOBIN=/usr/local/bin GOPATH=/go GOMODCACHE=/go/pkg/mod \
    && go install github.com/xdevplatform/xurl@latest \
    && go install github.com/steipete/gifgrep/cmd/gifgrep@latest \
    && go install github.com/steipete/goplaces/cmd/goplaces@latest \
    && chmod 0755 /usr/local/bin/xurl /usr/local/bin/gifgrep /usr/local/bin/goplaces

# ── Release-tarball niche tools (gogcli, openhue) ───────────────────────────
RUN case "${TARGETARCH}" in \
        amd64) gogcli_arch=amd64; openhue_arch=x86_64 ;; \
        arm64) gogcli_arch=arm64; openhue_arch=arm64   ;; \
        *) echo "unsupported arch: ${TARGETARCH}" >&2; exit 1 ;; \
    esac \
    && curl -fsSL "https://github.com/steipete/gogcli/releases/download/v${GOGCLI_VERSION}/gogcli_${GOGCLI_VERSION}_linux_${gogcli_arch}.tar.gz" \
        -o /tmp/gogcli.tar.gz \
    && tar -xzf /tmp/gogcli.tar.gz -C /tmp gog \
    && install -m 0755 /tmp/gog /usr/local/bin/gog \
    && ln -sf gog /usr/local/bin/gogcli \
    && ln -sf gog-agent-safe /usr/local/bin/gog-agent-safe \
    && ln -sf gog-readonly /usr/local/bin/gog-readonly \
    && curl -fsSL "https://github.com/openhue/openhue-cli/releases/download/${OPENHUE_VERSION}/openhue_Linux_${openhue_arch}.tar.gz" \
        -o /tmp/openhue.tar.gz \
    && tar -xzf /tmp/openhue.tar.gz -C /tmp openhue \
    && install -m 0755 /tmp/openhue /usr/local/bin/openhue \
    && rm -f /tmp/gogcli.tar.gz /tmp/gog /tmp/openhue.tar.gz /tmp/openhue

USER node
