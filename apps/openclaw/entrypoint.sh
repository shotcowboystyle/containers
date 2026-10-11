#!/bin/sh
set -e

FREERIDE_PORT="${FREERIDE_PORT:-11343}"

if [ "${FREERIDE_BIND_OPENCLAW:-0}" = "1" ]; then
    freeride bind openclaw --gateway-url "http://127.0.0.1:${FREERIDE_PORT}/v1"
fi

# Provider keys (OPENROUTER_API_KEY, GROQ_API_KEY, ...) are read from env by serve.
# Inbound auth is ignored, so keep it on loopback unless you know who can reach it.
# ponytail: no restart if freeride crashes; add a supervisor if that bites.
freeride serve --host "${FREERIDE_HOST:-127.0.0.1}" --port "${FREERIDE_PORT}" &

exec node /app/docker-entrypoint.mjs "$@"
