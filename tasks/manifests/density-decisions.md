# density dependency decisions

Generated: 2026-09-08T00:36:22.7141874+08:00
Closure resources: 337; missing: 0; dynamic path patterns: 5; nested-copy candidates: 3; exact duplicate members: 8; cross-feature members: 61

## Provisional ownership
- Canonical entry/dependency boundary: `games/chapter_one/hometown/building_two/Level2-1/` (excluding its nested `Level2-1/Level2-1/` copy).
- Shared `games/global/` resources remain shared and are not moved by this manifest.

## Review signals
- Dynamic path pattern (not a missing file): res://assets/atom_colors/ (from res://games/chapter_one/hometown/building_one/Level1/atom.gd).
- Dynamic path pattern (not a missing file): res://assets/periodic_table_combo/ (from res://games/chapter_one/hometown/building_one/Level1/Lesson1/pass.gd;res://games/chapter_one/hometown/building_one/Level1/Lesson2/pass.gd).
- Dynamic path pattern (not a missing file): res://games/glossary/assets/elements/%s.png (from res://games/glossary/element_info.gd).
- Dynamic path pattern (not a missing file): res://games/glossary/data/elements/ (from res://games/glossary/main.gd).
- Dynamic path pattern (not a missing file): res://games/glossary/data/elements/*.json (from res://games/glossary/main.gd).
- Exact duplicate groups are hash-backed in the CSV; no deletion is authorized by this generated report alone.
- Divergent same-purpose files require visual/runtime review before migration.
