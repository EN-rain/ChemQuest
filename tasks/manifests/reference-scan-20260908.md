# Repository reference scan (2026-09-08)

The final scan inspected literal `res://` references in tracked and untracked GDScript, scene, resource, and JSON files while excluding Godot caches, generated exports, manifests, and test fixtures. Dynamic path expressions were recorded separately rather than treated as missing files.

## Result

- Active dependency manifests: density `337`, states/matter-maze `337`, glossary `45`; each has `0` missing resources.
- Repository-wide literal references with unresolved paths: `0` in gameplay/content resources.
- Five expected scanner hits remain outside gameplay dependencies:

  - `tests/smoke/scene_smoke_runner.gd` embeds command-line examples (`res://intro.tscn --frames=3 --timeout_ms=5000` and `res://... argument`) in its usage/error text.
  - `tests/unit/test_persistence_contract.gd` intentionally supplies `res://does_not_exist.tscn` to verify safe-scene fallback.
  - `games/.../Level2-1/Level2-1/Scripts/density_gate1.gd` builds a dynamic level path; the scanner sees only the literal prefix.
  - `addons/auvrynt_bridge/auvrynt_bridge.gd` reads the editor-only `res://.godot/auvrynt_bridge.token` dynamically; the token is generated locally and excluded from source control.

The retained legacy glossary scenes now resolve their canonical script and UI asset paths. The orphan `games/data/cristofe_idle.tres`, whose texture dependency was genuinely missing and had no incoming references, is recorded in `orphan-data-cleanup-20260908.md` and removed.
