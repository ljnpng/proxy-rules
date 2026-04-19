#!/usr/bin/env bash
# Fetch gfwlist (base64-encoded AutoProxy format) and convert to Surge rule set.
# Usage: bash scripts/sync-gfwlist.sh [output_file]
#   default output: rules/gfw.list
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUTPUT="${1:-$REPO_ROOT/rules/gfw.list}"
URL="https://raw.githubusercontent.com/gfwlist/gfwlist/master/gfwlist.txt"

raw=$(curl -fsSL "$URL" | base64 -d)

# Parse AutoProxy format → unique domain list
domains=$(echo "$raw" | awk '
  # skip comments, header, empty lines, whitelist (@@), regex (/.../)
  /^[[:space:]]*$/   { next }
  /^[!\[]/            { next }
  /^@@/               { next }
  /^\/.*\/$/          { next }

  {
    s = $0

    # strip AutoProxy markers: || or |
    sub(/^\|\|/, "", s)
    sub(/^\|/,  "", s)

    # strip leading dot
    sub(/^\./, "", s)

    # strip protocol
    sub(/^https?:\/\//, "", s)

    # strip wildcard prefix (*.example.com → example.com)
    sub(/^\*\.?/, "", s)

    # take domain part only (before path / query / port)
    split(s, parts, /[\/:%?&#]/)
    d = parts[1]

    # trim trailing dots
    sub(/\.+$/, "", d)

    # basic validation: must contain a dot, no spaces, not pure IP
    if (d == "" || index(d, ".") == 0) next
    if (d ~ /[ @=]/) next
    if (d ~ /^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$/) next

    # lowercase and deduplicate
    print tolower(d)
  }
' | sort -u)

count=$(echo "$domains" | wc -l | tr -d ' ')

{
  echo "# GFW List - Auto-synced from github.com/gfwlist/gfwlist"
  echo "# Format: Surge rule set"
  echo "# Domains: $count"
  echo ""
  echo "$domains" | sed 's/^/DOMAIN-SUFFIX,/'
} > "$OUTPUT"

echo "gfw.list: $count domains → $OUTPUT"
