# syntax=docker/dockerfile:1.7

ARG NODE_VERSION=24-bookworm-slim

FROM node:${NODE_VERSION} AS build
WORKDIR /src

ENV COREPACK_ENABLE_DOWNLOAD_PROMPT=0
RUN corepack enable

COPY package.json pnpm-workspace.yaml ./
COPY packages ./packages
COPY server ./server
COPY ui ./ui
COPY adapters ./adapters
COPY scripts ./scripts
COPY tsconfig*.json ./
# COPY turbo.json ./
COPY patches ./patches
# include any other top-level files Paperclip needs, e.g. config/docs referenced by build
COPY . .

RUN pnpm install --frozen-lockfile || pnpm install
RUN pnpm build

FROM node:${NODE_VERSION} AS runtime

ENV NODE_ENV=production \
    HOST=0.0.0.0 \
    PORT=3100 \
    PAPERCLIP_HOME=/config

RUN groupadd --gid 65532 app && \
    useradd --uid 65532 --gid 65532 --home-dir /nonexistent --shell /usr/sbin/nologin app && \
    mkdir -p /app /config && \
    chown -R 65532:65532 /app /config

WORKDIR /app
ENV COREPACK_ENABLE_DOWNLOAD_PROMPT=0
RUN corepack enable

COPY --from=build --chown=65532:65532 /src ./

USER 65532:65532
EXPOSE 3100

VOLUME ["/config"]

CMD ["pnpm", "paperclipai", "run"]
