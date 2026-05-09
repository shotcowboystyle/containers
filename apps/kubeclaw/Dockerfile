ARG OPENCLAW_IMAGE=ghcr.io/openclaw/openclaw:2026.5.7-slim@sha256:1af3f457a2d5a1d210f4d95634fa5da6e23f9c0ac7b52ef4bc38e2ecf09704fd

FROM node:24 AS tools-builder
ARG TARGETARCH
WORKDIR /workspace
RUN apt-get update && apt-get install -y --no-install-recommends curl ca-certificates tar xz-utils && rm -rf /var/lib/apt/lists/*
RUN mkdir -p /out/opt/kubeclaw/bin /out/opt/kubeclaw/npm-global
COPY packages.json /workspace/packages.json
COPY scripts/install-tools.sh /workspace/install-tools.sh
COPY scripts/install-npm-packages.sh /workspace/install-npm-packages.sh
RUN chmod +x /workspace/install-tools.sh /workspace/install-npm-packages.sh
RUN TARGETARCH=${TARGETARCH} PACKAGES_FILE=/workspace/packages.json OUT_BIN_DIR=/out/opt/kubeclaw/bin /workspace/install-tools.sh
RUN PACKAGES_FILE=/workspace/packages.json OUT_PREFIX=/out/opt/kubeclaw/npm-global OUT_BIN_DIR=/out/opt/kubeclaw/bin /workspace/install-npm-packages.sh

# FROM golang:1.26.3-alpine AS go-builder
# WORKDIR /workspace
# RUN apk add --no-cache nodejs
# RUN mkdir -p /out/opt/kubeclaw/bin
# COPY packages.json /workspace/packages.json
# COPY scripts/install-go-packages.sh /workspace/install-go-packages.sh
# RUN chmod +x /workspace/install-go-packages.sh
# RUN PACKAGES_FILE=/workspace/packages.json OUT_BIN_DIR=/out/opt/kubeclaw/bin /workspace/install-go-packages.sh

FROM node:24 AS qmd-builder
WORKDIR /workspace
RUN apt-get update && apt-get install -y --no-install-recommends curl ca-certificates git cmake python3 make g++ && rm -rf /var/lib/apt/lists/*
RUN mkdir -p /out/opt/kubeclaw/qmd /out/opt/kubeclaw/qmd-bin
COPY packages.json /workspace/packages.json
COPY scripts/install-qmd.sh /workspace/install-qmd.sh
RUN chmod +x /workspace/install-qmd.sh
RUN PACKAGES_FILE=/workspace/packages.json OUT_QMD_PREFIX=/out/opt/kubeclaw/qmd OUT_QMD_DIR=/out/opt/kubeclaw/qmd-bin /workspace/install-qmd.sh

FROM ghcr.io/astral-sh/uv:latest AS uv-bin

FROM python:3.13-slim AS uv-builder
WORKDIR /workspace
RUN apt-get update && apt-get install -y --no-install-recommends nodejs npm && rm -rf /var/lib/apt/lists/*
COPY --from=uv-bin /uv /usr/local/bin/uv
RUN mkdir -p /out/opt/kubeclaw/uv-global /out/opt/kubeclaw/bin
COPY packages.json /workspace/packages.json
COPY scripts/install-uv-packages.sh /workspace/install-uv-packages.sh
RUN chmod +x /workspace/install-uv-packages.sh
RUN PACKAGES_FILE=/workspace/packages.json OUT_PREFIX=/out/opt/kubeclaw/uv-global OUT_BIN_DIR=/out/opt/kubeclaw/bin /workspace/install-uv-packages.sh

# FROM rust:1.95.0-slim AS rust-builder
# WORKDIR /workspace
# RUN apt-get update && apt-get install -y --no-install-recommends nodejs npm pkg-config libssl-dev && rm -rf /var/lib/apt/lists/*
# RUN mkdir -p /out/opt/kubeclaw/bin
# COPY packages.json /workspace/packages.json
# COPY scripts/install-rust-packages.sh /workspace/install-rust-packages.sh
# RUN chmod +x /workspace/install-rust-packages.sh
# RUN PACKAGES_FILE=/workspace/packages.json OUT_BIN_DIR=/out/opt/kubeclaw/bin /workspace/install-rust-packages.sh

FROM ${OPENCLAW_IMAGE}
USER root

COPY packages.json /opt/kubeclaw/packages.json
COPY scripts/install-linux-packages.sh /opt/kubeclaw/bin/install-linux-packages.sh
COPY scripts/install-skills-sh.sh /opt/kubeclaw/bin/install-skills-sh.sh
RUN chmod +x /opt/kubeclaw/bin/install-linux-packages.sh /opt/kubeclaw/bin/install-skills-sh.sh && /opt/kubeclaw/bin/install-linux-packages.sh && /opt/kubeclaw/bin/install-skills-sh.sh
RUN npm install --prefix /opt/kubeclaw/deps json5@2.2.3 --no-save --no-audit --no-fund

COPY --from=tools-builder /out/opt/kubeclaw/bin /opt/kubeclaw/bin
COPY --from=tools-builder /out/opt/kubeclaw/npm-global /opt/kubeclaw/npm-global
# COPY --from=go-builder /out/opt/kubeclaw/bin /opt/kubeclaw/bin
COPY --from=qmd-builder /out/opt/kubeclaw/qmd /opt/kubeclaw/qmd
COPY --from=qmd-builder /out/opt/kubeclaw/qmd-bin /opt/kubeclaw/qmd-bin
COPY --from=uv-builder /out/opt/kubeclaw/uv-global /opt/kubeclaw/uv-global
COPY --from=uv-builder /out/opt/kubeclaw/bin /opt/kubeclaw/bin
# COPY --from=rust-builder /out/opt/kubeclaw/bin /opt/kubeclaw/bin

COPY scripts/bootstrap.sh /opt/kubeclaw/bin/bootstrap.sh
COPY scripts/merge-json5.js /opt/kubeclaw/bin/merge-json5.js
COPY scripts/render-skills-config.js /opt/kubeclaw/bin/render-skills-config.js
COPY charts/kubeclaw/skillstacks /opt/kubeclaw/skillstacks

RUN chmod 0555 /opt/kubeclaw/bin/bootstrap.sh /opt/kubeclaw/bin/merge-json5.js /opt/kubeclaw/bin/render-skills-config.js

ENV PATH="/opt/kubeclaw/uv-global/bin:/opt/kubeclaw/qmd-bin:/opt/kubeclaw/bin:${PATH}"

USER 1000
