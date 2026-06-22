# containers

A monorepo of opinionated, reproducible OCI container images built and published to GHCR. Each app lives under `apps/<name>/` with its own `Dockerfile` and `docker-bake.hcl`, is built with Docker Buildx Bake, tested with Go + Testcontainers, and released by GitHub Actions on every push to `main` that touches its directory.

## Repository layout

```
.
├── apps/                        # One subdirectory per image
│   ├── agentmemory/             # Node-based memory service (iii engine, /agentmemory/livez)
│   ├── multi-agent-runtime/     # Claude Code / Codex / Gemini / Pi / OpenCode sandbox
│   ├── open-design/             # nexu-io/open-design daemon + web (multi-stage Node build)
│   ├── openclaw/                # OpenClaw slim — Python/uv, Go, Docker CLI, gh, Playwright, MCP
│   ├── openclaw-full/           # openclaw + gemini-cli, summarize, niche Go CLIs
│   └── paperclipai/             # paperclipai/paperclip + extra agent CLIs (gemini, pi, cursor)
├── include/                     # Files rsync'd into every app build context (e.g. .dockerignore)
├── testhelpers/                 # Shared Go test harness (testcontainers-go wrappers)
├── .github/
│   ├── workflows/               # release, app-builder, pull-request, codeql, renovate, …
│   ├── actions/                 # Reusable composite actions
│   ├── labels.yaml / labeler.yaml
│   └── CODEOWNERS, SECURITY.md, CONTRIBUTING.md
├── .justfile                    # Local build/test recipes
├── .mise.toml                   # Pinned toolchain (just, gh, lefthook, jq, yq, go)
├── .lefthook.toml               # Git hooks
├── .renovaterc.json5            # Renovate config (drives `# renovate:` comments in Dockerfiles)
└── go.mod / go.sum              # Module: github.com/shotcowboystyle/containers
```

## Apps

| App | Base | Purpose |
| --- | --- | --- |
| `agentmemory` | `node:24-slim` | Packages `@agentmemory/agentmemory` with the `iii` engine; persists to `/data`, exposes `/agentmemory/livez` on `:3111`. Patches upstream `.listen()` to bind `0.0.0.0`. |
| `multi-agent-runtime` | `node:24-trixie-slim` | Long-lived non-root sandbox (UID 1000, `sleep infinity`) with Claude Code, Codex, Gemini CLI, Pi, and OpenCode pre-installed for K8s `exec` from a Paperclip server. |
| `open-design` | `node:24-alpine` | Clones `nexu-io/open-design` at a renovate-tracked tag and builds the daemon + web app via pnpm in a multi-stage build. |
| `openclaw` | `ghcr.io/openclaw/openclaw:<ver>-slim` (pinned by digest) | Extends upstream slim with a Python/uv venv, Go toolchain, Docker CLI, `gh`, Playwright + Chromium, and a curated MCP extension set passed via `OPENCLAW_EXTENSIONS`. |
| `openclaw-full` | `ghcr.io/${VENDOR}/openclaw:${BASE_TAG}` | Layers gemini-cli, summarize, `xurl`, `gifgrep`, `goplaces`, `gogcli`, and `openhue` on top of `openclaw`. |
| `paperclipai` | `ghcr.io/paperclipai/paperclip:<ver>` | Adds nano/tini/vim plus gemini-cli, pi-coding-agent, and cursor's `agent` under `/opt/extras`; ships baseline `.gitconfig` and opencode config. |

Each app directory contains:

- **`Dockerfile`** — pinned base via digest where practical; build args annotated with `# renovate:` comments so Renovate keeps versions current.
- **`docker-bake.hcl`** — Buildx targets: `image` (CI), `image-local` (loads into local Docker), `image-all` (linux/amd64 + linux/arm64).
- **`container_test.go`** *(optional)* — Go integration test using `testhelpers` + Testcontainers (e.g. `agentmemory`, `paperclipai`). Runs against `$TEST_IMAGE` so the same test exercises both local and CI-built images.

## Building locally

Toolchain is managed by [mise](https://mise.jdx.dev/) (`just`, `gh`, `lefthook`, `jq`, `yq`, `go`).

```bash
mise install                  # install pinned tools
just                          # list recipes
just local-build openclaw     # rsync include/ → app/, buildx bake, then `go test` against the built image
just remote-build openclaw    # trigger the GHCR release workflow via gh CLI
```

`just local-build` writes into `.cache/`, loads `image-local` into the local Docker daemon, then runs the app's Go tests with `TEST_IMAGE` pointing at the freshly built tag.

## Testing

Tests live alongside each app as `container_test.go` and use `testhelpers` (a thin wrapper over [`testcontainers-go`](https://github.com/testcontainers/testcontainers-go)) for HTTP liveness probes, env injection, and image selection. Run a single app's tests with:

```bash
TEST_IMAGE=ghcr.io/<owner>/<app>:rolling go test ./apps/<app>/...
```

## CI / Release

GitHub Actions drives builds:

- **`release.yaml`** — on push to `main`, detects changed `apps/*` directories and fans out to a matrix build (max 4 in parallel). Manual `workflow_dispatch` accepts an `app` name and a `release` boolean.
- **`app-builder.yaml`** — the reusable build job invoked per app; handles buildx, attestations, SBOM, and GHCR push.
- **`pull-request.yaml`** — PR validation.
- **`codeql.yaml`**, **`vulnerability-scan.yaml`** — security scanning.
- **`renovate.yaml`**, **`label-sync.yaml`**, **`labeler.yaml`**, **`stale.yaml`**, **`deprecate-app.yaml`**, **`retry-release.yaml`**, **`test-version.yaml`**, **`go-mod-cache.yaml`** — repo maintenance.

Images are published to `ghcr.io/<owner>/<app>` with multi-arch manifests (linux/amd64, linux/arm64), OCI labels (`org.opencontainers.image.source`, `…description`), and build attestations.

## Adding a new app

1. Create `apps/<name>/` with a `Dockerfile` and a `docker-bake.hcl` exposing `image`, `image-local`, and `image-all` targets.
2. (Optional) Add a `container_test.go` using `testhelpers` for a health-check probe.
3. Run `just local-build <name>` to validate locally.
4. Run the private `just generate-label-config` recipe to register `app/<name>` labels and path-based labeler rules.
5. Open a PR — `release.yaml` will detect the new path and build it on merge.

## Conventions

- **Reproducibility:** prefer `FROM image@sha256:…` digest pins; let Renovate bump them.
- **Provenance:** every image sets `org.opencontainers.image.source` so GHCR links back to this repo.
- **Security:** run as non-root where the upstream allows it; strip SUID bits and build toolchains in final stages (see `multi-agent-runtime`).
- **No drift:** anything the build needs from the repo root goes through `include/` (rsync'd into the app context by `just local-build`) so the Dockerfile only references files it actually owns.

## Further reading

See `.github/CODE_OF_CONDUCT.md`, `.github/CONTRIBUTING.md`, and `.github/SECURITY.md`.
