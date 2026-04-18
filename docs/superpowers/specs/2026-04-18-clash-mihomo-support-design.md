# Clash Mihomo Rule Support

## Overview

Add Clash Mihomo compatibility to the existing Surge proxy rule sets. A conversion script generates Mihomo-compatible rule files from the Surge source files, output to `clash/` directory. Mihomo references these via raw GitHub URLs with `behavior: classical` and `format: text`.

## Conversion Logic

Shell script `scripts/convert-clash.sh`:
- Iterates all `rules/*.list` files
- For each file: strips `,no-resolve` from IP rule lines
- Writes output to `clash/<Name>.list`
- All other syntax (DOMAIN, DOMAIN-SUFFIX, DOMAIN-KEYWORD, IP-CIDR, IP-ASN) is identical between Surge and Mihomo classical format — no changes needed.

## CI Integration

Modify `.github/workflows/sync-rules.yml`:
- After community rule sync step, run `scripts/convert-clash.sh`
- Add push trigger: when `rules/*.list` changes on `main`, run the conversion

## Local Script

`scripts/convert-clash.sh` is also runnable locally for manual conversion before pushing.

## Directory Structure

```
proxy-rules/
├── rules/              # Surge format (source of truth)
├── clash/              # Clash format (auto-generated, do not edit)
├── scripts/
│   └── convert-clash.sh
├── .github/workflows/
│   └── sync-rules.yml  # updated with conversion step + push trigger
└── ...
```

## Mihomo Reference Example

```yaml
rule-providers:
  AI:
    type: http
    behavior: classical
    format: text
    url: "https://raw.githubusercontent.com/ljnpng/proxy-rules/main/clash/AI.list"
    interval: 86400
```

## Scope

- One shell script (~15 lines)
- One workflow update (add conversion step + push trigger)
- One new directory (`clash/`)
- Update CLAUDE.md with clash/ documentation
