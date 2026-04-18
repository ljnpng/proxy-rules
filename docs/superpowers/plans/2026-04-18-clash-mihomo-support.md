# Clash Mihomo Support Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Auto-generate Clash Mihomo-compatible rule files from existing Surge rule sets.

**Architecture:** A shell script strips `,no-resolve` from IP rules in `rules/*.list` and writes output to `clash/`. CI runs this after sync and on push. CLAUDE.md updated for agent discoverability.

**Tech Stack:** Bash, sed, GitHub Actions

---

### Task 1: Create conversion script

**Files:**
- Create: `scripts/convert-clash.sh`

- [ ] **Step 1: Create the script**

```bash
#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SRC_DIR="$REPO_ROOT/rules"
OUT_DIR="$REPO_ROOT/clash"

mkdir -p "$OUT_DIR"

for src in "$SRC_DIR"/*.list; do
  name="$(basename "$src")"
  sed 's/,no-resolve$//' "$src" > "$OUT_DIR/$name"
done

echo "Converted $(ls "$OUT_DIR"/*.list | wc -l | tr -d ' ') files to $OUT_DIR/"
```

- [ ] **Step 2: Make it executable**

Run: `chmod +x scripts/convert-clash.sh`

- [ ] **Step 3: Run the script and verify output**

Run: `./scripts/convert-clash.sh`
Expected: "Converted 10 files to /Users/neoliao/lab/proxy-rules/clash/"

- [ ] **Step 4: Verify no-resolve was stripped**

Run: `grep -c 'no-resolve' clash/*.list | grep -v ':0$'`
Expected: No output (all counts are 0).

Run: `diff <(grep -c 'no-resolve' rules/*.list) <(grep -c 'no-resolve' clash/*.list)`
Expected: Shows differences — rules/ files have counts > 0, clash/ files all show 0.

- [ ] **Step 5: Verify non-IP rules are unchanged**

Run: `diff <(grep '^DOMAIN' rules/AI.list) <(grep '^DOMAIN' clash/AI.list)`
Expected: No differences — DOMAIN rules are identical.

- [ ] **Step 6: Commit**

```bash
git add scripts/convert-clash.sh clash/
git commit -m "feat: add Clash Mihomo conversion script and generated rules"
```

---

### Task 2: Add .gitignore note for clash/ directory

**Files:**
- Create: `clash/.gitkeep` (not needed — files will exist)
- Create: `clash/README` (one-line warning)

- [ ] **Step 1: Add a do-not-edit notice**

Create `clash/README`:
```
Auto-generated from rules/ by scripts/convert-clash.sh — do not edit manually.
```

- [ ] **Step 2: Commit**

```bash
git add clash/README
git commit -m "docs: add auto-generated notice to clash directory"
```

---

### Task 3: Update CI workflow

**Files:**
- Modify: `.github/workflows/sync-rules.yml`

- [ ] **Step 1: Add push trigger and conversion step**

The updated workflow should be:

```yaml
name: Sync community rules

on:
  schedule:
    - cron: '30 2 * * *'  # daily 10:30 CST (02:30 UTC)
  workflow_dispatch:
  push:
    branches: [main]
    paths: ['rules/*.list']

jobs:
  sync:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Clone blackmatrix7 (sparse)
        if: github.event_name != 'push'
        run: |
          git clone --depth 1 --filter=blob:none --sparse \
            https://github.com/blackmatrix7/ios_rule_script.git /tmp/src
          cd /tmp/src
          git sparse-checkout set \
            rule/Surge/YouTube \
            rule/Surge/Google \
            rule/Surge/Telegram \
            rule/Surge/Steam \
            rule/Surge/Spotify \
            rule/Surge/GitHub \
            rule/Surge/Bahamut \
            rule/Surge/Global

      - name: Copy rule sets
        if: github.event_name != 'push'
        run: |
          for service in YouTube Google Telegram Steam Spotify GitHub Bahamut; do
            cp "/tmp/src/rule/Surge/$service/$service.list" "rules/$service.list"
          done
          cp /tmp/src/rule/Surge/Global/Global.list rules/Global.list

      - name: Convert to Clash format
        run: bash scripts/convert-clash.sh

      - name: Commit and push if changed
        run: |
          git config user.name "github-actions[bot]"
          git config user.email "github-actions[bot]@users.noreply.github.com"
          git add rules/ clash/
          if git diff --cached --quiet; then
            echo "No changes"
          else
            git commit -m "sync: update community rules from blackmatrix7"
            git push
          fi
```

Note: The `if: github.event_name != 'push'` conditions skip the blackmatrix7 clone/copy steps on push events — those only need the conversion step.

- [ ] **Step 2: Verify YAML syntax**

Run: `python3 -c "import yaml; yaml.safe_load(open('.github/workflows/sync-rules.yml'))"`
Expected: No errors.

- [ ] **Step 3: Commit**

```bash
git add .github/workflows/sync-rules.yml
git commit -m "ci: run Clash conversion after sync and on rules push"
```

---

### Task 4: Update CLAUDE.md

**Files:**
- Modify: `CLAUDE.md`

- [ ] **Step 1: Update CLAUDE.md with Clash documentation**

Add/update the following sections. The goal is agent-discoverability — an agent reading CLAUDE.md should immediately understand the dual-format setup.

Update "What This Repo Is" to mention both Surge and Clash:

```markdown
## What This Repo Is

Personal proxy rule sets for whitelist-mode routing, serving both Surge and Clash Mihomo.
- Surge references: `https://raw.githubusercontent.com/ljnpng/proxy-rules/main/rules/<Name>.list`
- Clash Mihomo references: `https://raw.githubusercontent.com/ljnpng/proxy-rules/main/clash/<Name>.list` (behavior: classical, format: text)
```

Add after File Ownership section:

```markdown
## Clash Mihomo Support

`clash/` contains auto-generated Mihomo-compatible rule files. **Do not edit files in `clash/` directly.**

- Source of truth: `rules/*.list` (Surge format)
- Conversion: `scripts/convert-clash.sh` strips `,no-resolve` from IP rules (Mihomo handles no-resolve at config level, not in rule-provider files)
- CI auto-converts on: daily sync, manual dispatch, and push to `rules/*.list`
- Local usage: run `./scripts/convert-clash.sh` after editing rules, before pushing
```

Update "Adding Rules" to mention Clash:

```markdown
## Adding Rules

Use the `add-rule` skill. Key points:
- Always grep across `rules/` for duplicates before adding
- Append custom entries under `# --- Custom` section if present
- Commit message format: `add <domain> to <RuleSet>.list`
- Push after commit — Surge pulls from GitHub raw URLs
- Clash files in `clash/` are auto-generated by CI on push; no manual conversion needed
```

- [ ] **Step 2: Commit**

```bash
git add CLAUDE.md
git commit -m "docs: update CLAUDE.md with Clash Mihomo support info"
```
