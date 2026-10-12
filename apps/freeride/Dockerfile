# syntax=docker/dockerfile:1

FROM docker.io/library/python:3.13-slim@sha256:70729b46c69b4f1e97c4822c1af3df53a1476cf5ddc6c087c0c10bc3a5678c2f
ARG VERSION

ENV PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1 \
    HOME=/home/freeride

RUN pip install "freeride-gateway==${VERSION}" \
    && useradd -m -u 1000 -d "${HOME}" freeride

USER freeride
WORKDIR /home/freeride
RUN freeride --version

# Provider keys come from env (any one is enough; _2/_3 suffixes rotate keys):
#   OPENROUTER_API_KEY GROQ_API_KEY NVIDIA_API_KEY HF_TOKEN CEREBRAS_API_KEY
#   CLOUDFLARE_API_TOKEN+CLOUDFLARE_ACCOUNT_ID OLLAMA_BASE_URL
# The gateway ignores inbound auth: restrict who can reach :11343 (e.g. NetworkPolicy).
EXPOSE 11343
ENTRYPOINT ["freeride"]
CMD ["serve", "--host", "0.0.0.0", "--port", "11343"]
