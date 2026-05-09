#!/bin/sh
set -eu

PACKAGES_FILE="${PACKAGES_FILE:-/workspace/packages.json}"
OUT_BIN_DIR="${OUT_BIN_DIR:-/opt/kubeclaw/bin}"

count="$(node -e 'const fs=require("fs"); const p=JSON.parse(fs.readFileSync(process.argv[1],"utf8")); process.stdout.write(String((p.cargoPackages||[]).length));' "$PACKAGES_FILE")"
if [ "$count" = "0" ]; then
  exit 0
fi

mkdir -p "$OUT_BIN_DIR"

node -e '
  const fs = require("fs");
  const p = JSON.parse(fs.readFileSync(process.argv[1], "utf8"));
  for (const item of (p.cargoPackages || [])) {
    process.stdout.write(item + "\n");
  }
' "$PACKAGES_FILE" | while IFS= read -r pkg; do
  [ -n "$pkg" ] || continue
  cargo install --root /tmp/cargo-out "$pkg"
done

if [ -d /tmp/cargo-out/bin ]; then
  for bin in /tmp/cargo-out/bin/*; do
    [ -f "$bin" ] || continue
    cp "$bin" "$OUT_BIN_DIR/$(basename "$bin")"
  done
fi
