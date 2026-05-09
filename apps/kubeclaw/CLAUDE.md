# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

KubeClaw is a Docker image that extends the upstream [OpenClaw](https://github.com/openclaw/openclaw) image with curated runtime tooling and baked-in skillstacks. The image is published as `ghcr.io/imerica/kubeclaw`.

## Build commands

```sh
# Build locally (single arch, type=docker)
docker buildx bake

# Build for amd64 + arm64 (registry push)
docker buildx bake image-all
```

`docker-bake.hcl` defines three targets: `image-local` (default), `image`, and `image-all`. The `VERSION` variable tracks the upstream OpenClaw release and is managed by Renovate.

## Package manifest — `packages.json`

All packages are declared in `packages.json`. The install scripts read this file at build time; no other package management files exist.

| Key | Installer | Build stage |
|-----|-----------|-------------|
| `linuxPackages` | `apt-get` | Final image (base handles it via `install-linux-packages.sh`) |
| `goPackages` | `go install` → `/home/node/go` | `go-builder` |
| `npmGlobalPackages` | `npm install` → `/home/node/.npm-global` | `tools-builder` |
| `uvPackages` | `uv pip install` → `/home/node/.uv-global` | `uv-builder` |
| `cargoPackages` | `cargo install` → `/home/node/.cargo/bin` | `rust-builder` |
| `skillsSh` | verified `sh` download (requires `url` + `sha256`) | Final image |
| `cli` | per-tool installer with GitHub API digest check | `tools-builder` |
| `qmd` | npm tarball with npm integrity hash | `qmd-builder` |

**Security invariant**: every downloaded binary is checksum-verified before installation. For `skillsSh`, the URL must use `https://` and a `sha256` field is required. For `cli` tools, digests are fetched live from the GitHub Releases API. For `qmd`, the `integrity` field must match the npm registry's `dist.integrity`.

## PATH inside the container

```
/home/node/.npm-global/bin
/home/node/.cargo/bin
/home/node/go/bin
/home/node/.uv-global/bin
/home/node/qmd-bin
/home/node/.local/bin
```

## Adding a CLI tool

- **Go package**: add the `go install` spec to `goPackages`
- **npm package**: add `name@version` to `npmGlobalPackages`
- **Python tool**: add the package name to `uvPackages`
- **Rust crate**: add the crate name to `cargoPackages`
- **Curated CLI** (gh, jira, linear, asana, trello): set `enabled: true` and pin `version` in the `cli` object; the download URL template uses `{{version}}` and `{{arch}}` placeholders
- **External script**: add an object with `url` (https only) and `sha256` to `skillsSh`

## Skillstacks

Skillstacks live in `charts/kubeclaw/skillstacks/<domain>/<skill-name>/SKILL.md`. They are copied into the image at `/home/node/.local/skillstacks` and synced into `/home/node/.openclaw/skills` by `bootstrap.sh` at container start.

Current domains: `platform-engineering`, `devops`, `sre`, `swe`, `qa`, `marketing`.

To add a skill: create a new directory under the appropriate domain and add a `SKILL.md` with YAML frontmatter (`name`, `description`) followed by skill instructions.

## Runtime bootstrap (`scripts/bootstrap.sh`)

Runs as the container entrypoint wrapper. Controlled by environment variables:

| Env var | Default | Effect |
|---------|---------|--------|
| `KUBECLAW_CONFIG_MODE` | `merge` | `merge` (RFC 7396 patch) or `overwrite` of `/home/node/.openclaw/openclaw.json` |
| `KUBECLAW_SKILLSTACKS_ENABLED` | `true` | Disable to skip skillstack sync |
| `KUBECLAW_SKILLSTACK_<DOMAIN>_ENABLED` | `true` | Per-domain toggle (e.g. `KUBECLAW_SKILLSTACK_MARKETING_ENABLED=false`) |
| `KUBECLAW_SKILLS_WATCH` | `true` | Pass-through to OpenClaw skill watcher |
| `KUBECLAW_SKILLS_NODE_MANAGER` | `npm` | Pass-through to OpenClaw skill installer |
| `KUBECLAW_SKILLS_EXTRA_DIRS_JSON` | `[]` | JSON array of additional skill directories |

Config source is expected at `/config-src/openclaw.json` (mount a ConfigMap or volume there).

## Key scripts

- `scripts/merge-json5.js` — RFC 7396 JSON Merge Patch; accepts both strict JSON and JSON5 input. Setting a key to `null` in the patch deletes it.
- `scripts/render-skills-config.js` — scans `skills/` directory and generates the `skills.*` OpenClaw config fragment, then merges it into `openclaw.json`.
- `scripts/install-tools.sh` — installs curated CLI binaries; reads `cli.*` keys from `packages.json` and fetches SHA256 digests from GitHub API.
