# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Repo Is

Personal Surge proxy rule sets for whitelist-mode routing. Surge config references these files via raw GitHub URLs (`https://raw.githubusercontent.com/ljnpng/proxy-rules/main/rules/<Name>.list`).

## File Ownership

Community-synced files (auto-updated daily by GitHub Actions from `blackmatrix7/ios_rule_script`):
- YouTube.list, Google.list, Telegram.list, Steam.list, Spotify.list, GitHub.list, Bahamut.list, Global.list
- **Do not edit these** — changes will be overwritten.

Self-maintained files (safe to edit):
- AI.list — custom AI service rules, has `# --- Custom` section for personal additions
- Any new `.list` file you create

## Adding Rules

Use the `add-rule` skill. Key points:
- Always grep across `rules/` for duplicates before adding
- Append custom entries under `# --- Custom` section if present
- Commit message format: `add <domain> to <RuleSet>.list`
- Push after commit — Surge pulls from GitHub raw URLs

## Surge Rule Syntax

```
DOMAIN-SUFFIX,example.com
DOMAIN,specific.example.com
DOMAIN-KEYWORD,example
IP-CIDR,1.2.3.0/24,no-resolve
IP-ASN,12345,no-resolve
```

## Sync Workflow

`.github/workflows/sync-rules.yml` runs daily at 10:30 CST via sparse checkout of blackmatrix7's repo. Can also be triggered manually via `workflow_dispatch`.
