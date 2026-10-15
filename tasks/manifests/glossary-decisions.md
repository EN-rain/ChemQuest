# glossary dependency decisions

Generated: 2026-09-08T00:36:24.2876850+08:00
Closure resources: 45; missing: 0; dynamic path patterns: 3; nested-copy candidates: 0; exact duplicate members: 6; cross-feature members: 0

## Provisional ownership
- Canonical feature boundary: `games/glossary/`; root `glossary/` is retained as a legacy candidate until all consumers are migrated.
- Shared `games/global/` resources remain shared and are not moved by this manifest.

## Review signals
- Dynamic path pattern (not a missing file): res://games/glossary/assets/elements/%s.png (from res://games/glossary/element_info.gd).
- Dynamic path pattern (not a missing file): res://games/glossary/data/elements/ (from res://games/glossary/main.gd).
- Dynamic path pattern (not a missing file): res://games/glossary/data/elements/*.json (from res://games/glossary/main.gd).
- Exact duplicate groups are hash-backed in the CSV; no deletion is authorized by this generated report alone.
- Divergent same-purpose files require visual/runtime review before migration.
