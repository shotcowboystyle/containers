#!/bin/sh
set -eu

PACKAGES_FILE="${PACKAGES_FILE:-/workspace/packages.json}"
OUT_PREFIX="${OUT_PREFIX:-/opt/kubeclaw/npm-global}"
OUT_BIN_DIR="${OUT_BIN_DIR:-/opt/kubeclaw/bin}"

count="$(node -e 'const fs=require("fs"); const p=JSON.parse(fs.readFileSync(process.argv[1],"utf8")); process.stdout.write(String((p.npmGlobalPackages||[]).length));' "$PACKAGES_FILE")"
if [ "$count" = "0" ]; then
  exit 0
fi

mkdir -p "$OUT_PREFIX" "$OUT_BIN_DIR"

node -e '
  const fs = require("fs");
  const p = JSON.parse(fs.readFileSync(process.argv[1], "utf8"));
  for (const item of (p.npmGlobalPackages || [])) {
    process.stdout.write(item + "\n");
  }
' "$PACKAGES_FILE" | while IFS= read -r pkg; do
  [ -n "$pkg" ] || continue
  npm install --prefix "$OUT_PREFIX" --cache /tmp/.npm "$pkg" --no-save --no-audit --no-fund >/dev/null
done

if [ -d "$OUT_PREFIX/node_modules/.bin" ]; then
  for bin in "$OUT_PREFIX"/node_modules/.bin/*; do
    [ -f "$bin" ] || continue
    target_name="$(basename "$bin")"
    ln -sf "../npm-global/node_modules/.bin/$target_name" "$OUT_BIN_DIR/$target_name"
  done
fi
