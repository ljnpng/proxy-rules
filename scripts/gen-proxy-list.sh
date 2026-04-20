#!/usr/bin/env bash
# Generate proxy.list by merging gfw.list + Global.list,
# removing duplicates that exist in other rule lists, then sorting.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
RULES_DIR="$REPO_ROOT/rules"
OUTPUT="$RULES_DIR/proxy.list"

# Source lists to merge
SOURCES=("$RULES_DIR/gfw.list" "$RULES_DIR/Global.list")

# Other lists to deduplicate against (everything except gfw, Global, and proxy itself)
EXCLUDE_LISTS=()
for f in "$RULES_DIR"/*.list; do
  base="$(basename "$f")"
  case "$base" in
    gfw.list|Global.list|proxy.list) continue ;;
    *) EXCLUDE_LISTS+=("$f") ;;
  esac
done

# Collect all rules from exclude lists into a set (skip comments and blank lines)
EXCLUDE_TMP=$(mktemp)
for f in "${EXCLUDE_LISTS[@]}"; do
  grep -v '^\s*#' "$f" | grep -v '^\s*$' >> "$EXCLUDE_TMP" || true
done
sort -u -o "$EXCLUDE_TMP" "$EXCLUDE_TMP"

# Merge source lists (skip comments and blank lines), sort, deduplicate
MERGED_TMP=$(mktemp)
for f in "${SOURCES[@]}"; do
  grep -v '^\s*#' "$f" | grep -v '^\s*$' >> "$MERGED_TMP" || true
done
sort -u -o "$MERGED_TMP" "$MERGED_TMP"

# Remove entries that exist in other lists
RESULT_TMP=$(mktemp)
comm -23 "$MERGED_TMP" "$EXCLUDE_TMP" > "$RESULT_TMP"

# Count
TOTAL=$(wc -l < "$RESULT_TMP")

# Write output with header
cat > "$OUTPUT" <<EOF
# NAME: Proxy
# DESCRIPTION: Merged from gfw.list + Global.list, deduplicated against other rule sets
# TOTAL: $TOTAL
EOF
cat "$RESULT_TMP" >> "$OUTPUT"

# Cleanup
rm -f "$EXCLUDE_TMP" "$MERGED_TMP" "$RESULT_TMP"

echo "Generated $OUTPUT with $TOTAL rules"
