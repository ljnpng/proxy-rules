---
name: add-rule
description: Use when adding, removing, or updating Surge proxy rules in this repo. Triggers on "add rule", "add domain", "新增规则", "添加域名", or any request to route a domain/IP through a specific proxy policy.
---

# Add Surge Proxy Rule

Manage custom Surge proxy rules in `rules/*.list`. These files are referenced by Surge config via raw GitHub URLs.

## File Ownership

| File | Owner | Editable? |
|------|-------|-----------|
| AI.list | Self-maintained | Yes — add custom AI services here |
| Any new `*.list` | Self-maintained | Yes — create as needed |
| YouTube.list, Google.list, Telegram.list, Steam.list, Spotify.list, GitHub.list, Bahamut.list, Global.list | Community (blackmatrix7) | No — overwritten daily by GitHub Actions |

Never edit community files. If you need to override a community rule, add it to the appropriate self-maintained file or create a new one.

## Surge Rule Syntax

```
DOMAIN-SUFFIX,example.com          # example.com and all subdomains
DOMAIN,specific.example.com        # exact domain only
DOMAIN-KEYWORD,example             # any domain containing "example"
IP-CIDR,1.2.3.0/24,no-resolve     # IP range
IP-ASN,12345,no-resolve            # entire ASN
```

## Workflow

1. Determine target file — existing self-maintained `.list` or create new one
2. Check for duplicates — grep the rule across all `.list` files first
3. Append rule to the appropriate section (custom entries go under `# --- Custom` if present)
4. Commit with message: `add <domain> to <RuleSet>.list`
5. Push to origin

## Creating a New Rule Set

When a new category is needed (e.g., `Streaming.list`):

1. Create `rules/<Name>.list` with a `# <Name>` header
2. Add rules
3. Commit and push
4. Remind user to d corresponding `RULE-SET` and policy group in their Surge config

## Quick Add Example

User: "把 newai.com 加到 AI 规则里"

```bash
# 1. Check duplicate
grep -r "newai.com" rules/
# 2. Append
echo "DOMAIN-SUFFIX,newai.com" >> rules/AI.list
# 3. Commit & push
git add rules/AI.list
git commit -m "add newai.com to AI.list"
git push
```
