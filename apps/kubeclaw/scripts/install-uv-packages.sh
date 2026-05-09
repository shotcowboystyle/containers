#!/bin/sh
set -eu

PACKAGES_FILE="${PACKAGES_FILE:-/workspace/packages.json}"
OUT_PREFIX="${OUT_PREFIX:-/out/opt/kubeclaw/uv-global}"
OUT_BIN_DIR="${OUT_BIN_DIR:-/out/opt/kubeclaw/bin}"

count="$(node -e 'const fs=require("fs"); const p=JSON.parse(fs.readFileSync(process.argv[1],"utf8")); process.stdout.write(String((p.uvPackages||[]).length));' "$PACKAGES_FILE")"
if [ "$count" = "0" ]; then
  exit 0
fi

mkdir -p "$OUT_PREFIX" "$OUT_BIN_DIR"

uv venv "$OUT_PREFIX"

node -e '
  const fs = require("fs");
  const p = JSON.parse(fs.readFileSync(process.argv[1], "utf8"));
  for (const item of (p.uvPackages || [])) {
    process.stdout.write(item + "\n");
  }
' "$PACKAGES_FILE" | while IFS= read -r pkg; do
  [ -n "$pkg" ] || continue
  uv pip install --python "$OUT_PREFIX/bin/python" "$pkg"
done

for bin in "$OUT_PREFIX"/bin/*; do
  [ -f "$bin" ] || continue
  name="$(basename "$bin")"
  case "$name" in
    python*|pip*|activate*) continue ;;
  esac
  ln -sf "$bin" "$OUT_BIN_DIR/$name"
done
