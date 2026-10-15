# ADR 0001: Versioned save and progression contract

- Status: Proposed for owner approval
- Date: 2026-09-07
- Scope: `SaveManager`, `QuestManager`, menu New Game/Continue flow

## Context

The project previously mixed `user://save.json` and `user://quest.json`, stored numeric progress without the completed level identities that prevent replay credit, and allowed menu transitions to save the currently loaded menu scene. New Game reset several systems through separate call paths, so state could leak from Continue. A save written during a cutscene also needed a deterministic resume destination.

## Decision

`user://save.json` is the authoritative progression document. New writes use schema version `2` and contain:

- `scene_path` (validated `res://` scene, with `res://games/main.tscn` as the safe fallback)
- `last_spawn`, normalized quest records, and shown-feedback keys
- `density_progress` plus `density_completed_levels`
- `states_progress` plus `states_completed_levels`

Reads normalize legacy/missing fields in memory. Invalid JSON or an invalid scene path follows the controlled fallback path and never becomes a scene-load target. Completed level IDs are bounded, deduplicated, sorted, and used as the replay guard; numeric progress is capped at the known level count.

Writes use a temporary file and replacement, with a backup/restore path for replacement errors. `save_game()` coalesces requests for 250 ms; `save_now(destination)` flushes synchronously for scene transitions and quit. An explicit destination is preserved rather than inferred from `current_scene`.

`SaveManager.reset_for_new_game()` is the single reset entry point. It clears quest completion, density/states progress and identities, feedback, spawn, challenge state, scoring, and lesson/Level 3 session history, then writes the initial cutscene destination. Guide/tutorial completion remains profile-level until the owner explicitly chooses otherwise; this avoids deleting accessibility/onboarding preferences during a restart.

`user://quest.json` remains readable for compatibility with the existing QuestManager loader, but the reset and save contract no longer treats it as an independent progression source.

## Consequences

The contract is testable without touching the developer's real user data: the persistence suite snapshots and restores save, quest, lesson, and Level 3 files. Existing legacy saves continue to load, while new saves have an explicit schema and identity arrays. A future schema change must add a migration step and a focused fixture before changing the version constant.

The cutscene resume location and guide-history policy are explicit owner decisions; changing either requires updating this ADR and the contract tests.
