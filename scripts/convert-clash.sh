#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SRC_DIR="$REPO_ROOT/rules"
OUT_DIR="$REPO_ROOT/clash"

mkdir -p "$OUT_DIR"

for src in "$SRC_DIR"/*.list; do
  name="$(basename "$src")"
  sed '/^OR,/d; s/,no-resolve$//' "$src" > "$OUT_DIR/$name"
done

echo "Converted $(ls "$OUT_DIR"/*.list | wc -l | tr -d ' ') files to $OUT_DIR/"
