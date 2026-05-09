ARG OPENCLAW_IMAGE=ghcr.io/openclaw/openclaw:2026.5.7-slim@sha256:1af3f457a2d5a1d210f4d95634fa5da6e23f9c0ac7b52ef4bc38e2ecf09704fd

FROM node:24 AS tools-builder
ARG TARGETARCH
WORKDIR /workspace
RUN apt-get update && apt-get install -y --no-install-recommends curl ca-certificates tar xz-utils && rm -rf /var/lib/apt/lists/*
RUN mkdir -p /home/node/.local/bin /home/node/.npm-global
COPY packages.json /workspace/packages.json
COPY scripts/install-tools.sh /workspace/install-tools.sh
COPY scripts/install-npm-packages.sh /workspace/install-npm-packages.sh
RUN chmod +x /workspace/install-tools.sh /workspace/install-npm-packages.sh
RUN TARGETARCH=${TARGETARCH} PACKAGES_FILE=/workspace/packages.json OUT_BIN_DIR=/home/node/.local/bin /workspace/install-tools.sh
RUN PACKAGES_FILE=/workspace/packages.json OUT_PREFIX=/home/node/.npm-global OUT_BIN_DIR=/home/node/.local/bin /workspace/install-npm-packages.sh

FROM golang:1.26.3-alpine AS go-builder
WORKDIR /workspace
RUN apk add --no-cache nodejs
RUN mkdir -p /home/node/go
COPY packages.json /workspace/packages.json
COPY scripts/install-go-packages.sh /workspace/install-go-packages.sh
RUN chmod +x /workspace/install-go-packages.sh
RUN PACKAGES_FILE=/workspace/packages.json OUT_BIN_DIR=/home/node/go /workspace/install-go-packages.sh

FROM node:24 AS qmd-builder
WORKDIR /workspace
RUN apt-get update && apt-get install -y --no-install-recommends curl ca-certificates git cmake python3 make g++ && rm -rf /var/lib/apt/lists/*
RUN mkdir -p /home/node/qmd /home/node/qmd-bin
COPY packages.json /workspace/packages.json
COPY scripts/install-qmd.sh /workspace/install-qmd.sh
RUN chmod +x /workspace/install-qmd.sh
RUN PACKAGES_FILE=/workspace/packages.json OUT_QMD_PREFIX=/home/node/qmd OUT_QMD_DIR=/home/node/qmd-bin /workspace/install-qmd.sh

FROM ghcr.io/astral-sh/uv:latest AS uv-bin

FROM python:3.13-slim AS uv-builder
WORKDIR /workspace
RUN apt-get update && apt-get install -y --no-install-recommends nodejs npm && rm -rf /var/lib/apt/lists/*
COPY --from=uv-bin /uv /home/node/.local/bin/uv
RUN mkdir -p /home/node/.uv-global /home/node/.local/bin
COPY packages.json /workspace/packages.json
COPY scripts/install-uv-packages.sh /workspace/install-uv-packages.sh
RUN chmod +x /workspace/install-uv-packages.sh
RUN PACKAGES_FILE=/workspace/packages.json OUT_PREFIX=/home/node/.uv-global OUT_BIN_DIR=/home/node/.local/bin /workspace/install-uv-packages.sh

FROM rust:1.95.0-slim AS rust-builder
WORKDIR /workspace
RUN apt-get update && apt-get install -y --no-install-recommends nodejs npm pkg-config libssl-dev && rm -rf /var/lib/apt/lists/*
RUN mkdir -p /home/node/.cargo
COPY packages.json /workspace/packages.json
COPY scripts/install-rust-packages.sh /workspace/install-rust-packages.sh
RUN chmod +x /workspace/install-rust-packages.sh
RUN PACKAGES_FILE=/workspace/packages.json OUT_BIN_DIR=/home/node/.cargo/bin /workspace/install-rust-packages.sh

FROM ${OPENCLAW_IMAGE}
USER root

COPY packages.json /home/node/packages.json
COPY scripts/install-skills-sh.sh /home/node/.local/bin/install-skills-sh.sh
RUN chmod +x /home/node/.local/bin/install-skills-sh.sh && /home/node/.local/bin/install-skills-sh.sh
RUN npm install --prefix /home/node/.local/deps json5@2.2.3 --no-save --no-audit --no-fund

COPY --from=tools-builder /home/node/.local/bin /home/node/.local/bin
COPY --from=tools-builder /home/node/.npm-global /home/node/.npm-global
COPY --from=go-builder /home/node/go /home/node/go
COPY --from=qmd-builder /home/node/qmd /home/node/qmd
COPY --from=qmd-builder /home/node/qmd-bin /home/node/qmd-bin
COPY --from=uv-builder /home/node/.uv-global /home/node/.uv-global
COPY --from=uv-builder /home/node/.local/bin /home/node/.local/bin
COPY --from=rust-builder /home/node/.cargo /home/node/.cargo

COPY scripts/bootstrap.sh /home/node/.local/bin/bootstrap.sh
COPY scripts/merge-json5.js /home/node/.local/bin/merge-json5.js
COPY scripts/render-skills-config.js /home/node/.local/bin/render-skills-config.js
COPY charts/kubeclaw/skillstacks /home/node/.local/skillstacks

RUN chmod 0555 /home/node/.local/bin/bootstrap.sh /home/node/.local/bin/merge-json5.js /home/node/.local/bin/render-skills-config.js

ENV PATH="/home/node/.npm-global/bin:/home/node/.cargo/bin:/home/node/go/bin:/home/node/.uv-global/bin:/home/node/qmd-bin:/home/node/.local/bin:${PATH}"

USER 1000
