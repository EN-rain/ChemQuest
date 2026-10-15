# ChemQuest2 Refactor Checklist

This checklist tracks execution of `tasks/plan.md`. Do not check off a task until its acceptance criteria and verification steps are complete.

## Phase 0: Protected baseline

- [ ] 0.1 Resolve pre-existing worktree ownership.
- [x] 0.2 Capture structural and export baselines (runtime regression snapshot, dependency manifests, repository size audit, and Android/Web export records).
- [x] 0.3 Establish Godot runtime access through CLI or MCP (Godot 4.6.1 CLI verified; MCP package present but bridge inactive).
- [ ] Checkpoint A: Baseline approved by owner.

## Phase 1: Safety nets

- [x] 1.1 Create a headless scene smoke-test harness.
- [x] 1.2 Define and run the critical scene matrix.
- [x] 1.3 Add persistence contract tests that reproduce known defects.
- [x] Checkpoint B: Safety net operational (baseline recorded; known RED cases documented).

## Phase 2: Correctness repairs

- [x] 2.1 Define and version one save schema (schema v2, validation, legacy migration, safe-scene fallback; contract suite passes).
- [x] 2.2 Persist completed density/states level identities (normalized identity arrays and replay guards; contract suite passes).
- [x] 2.3 Implement one authoritative New Game reset (quest/progression/session reset; guide history remains profile-level by documented decision).
- [x] 2.4 Make initial saving and save flushing deterministic (explicit destination, atomic write, 250 ms coalescing, quit flush).
- [x] 2.5 Correct menu SFX/music routing (button SFX uses SFX bus and disables looping; buses have fallback creation).
- [x] 2.6 Repair active navigation paths (Precision/Accuracy Home, Lesson 3 lookup, matter-maze fade lookup, validated fade targets).
- [x] Checkpoint C: Gameplay correctness stable (desktop matrix, focused contracts, and Android/Web export packaging pass; device/browser interaction remains a release follow-up).

## Phase 3: Dependency manifests

- [x] 3.1 Manifest and classify the density resource graph (337-resource closure; 0 missing; dynamic patterns and duplicate candidates recorded).
- [x] 3.2 Manifest and classify the states/matter-maze resource graph (337-resource closure; 0 missing; nested/cross-feature candidates recorded).
- [x] 3.3 Manifest and classify glossary ownership (45-resource closure; 0 missing; legacy root retained as migration candidate).
- [ ] Checkpoint D: Canonical ownership approved by owner (provisional ADR recorded; owner approval still required).

## Phase 4: Untangle feature trees

- [x] 4.1 Migrate density dependencies in manifest-sized batches (5 exact-hash references redirected; no source deletion).
- [x] 4.2 Migrate states/matter-maze dependencies in manifest-sized batches (41 exact-hash references redirected; divergent/unique paths retained).
- [x] 4.3 Consolidate glossary dependencies in manifest-sized batches (active scenes now use `games/glossary` scripts/assets; legacy tree retained).
- [ ] Checkpoint E: Cross-tree references eliminated (remaining unique nested/cross-feature references require owner-approved migration batches).

## Phase 5: Asset consolidation

- [x] 5.1 Establish canonical shared fonts and UI assets (all consumers use root shared fonts; glossary UI remains under `games/glossary/assets`; duplicate font binaries/imports removed).
- [x] 5.2 Establish canonical music/SFX assets and remove embedded audio debt (global audio library/bus routing verified; two unreferenced multi-megabyte embedded scenes retired).
- [x] 5.3 Normalize third-party packs, source art, and licensing metadata (source inventory, export exclusions, and unresolved-license records added).
- [x] 5.4 Optimize the project icon (2,396,155 → 367,343 bytes; 84.67% reduction; import/export smoke verified).
- [ ] Checkpoint F: Asset model stable.

  *Checkpoint note:* runtime ownership is documented and measured, but Treasure Hunters, Pixel Adventure, Nougat, and the retained legacy trees still need owner licensing/retirement decisions.

## Phase 6: Proven cleanup

- [x] 6.1 Remove tracked `.tmp` and `.DS_Store` artifacts (136 exact tracked editor artifacts removed; ignore rules added; matrix remains green).
- [x] 6.2 Remove or repair orphan Precision/Accuracy resources (seven broken unreferenced scenes and five duplicate target scripts retired; live scene remains green).
- [ ] 6.3 Remove retired duplicate trees one feature at a time (bounded exact-reference migrations completed; full tree retirement awaits owner approval).
- [ ] Checkpoint G: Resource cleanup complete.

## Phase 7: Code and scene simplification

- [x] 7.1 Reduce feature-specific autoload scope (unused empty `Level2Manager` autoload and sidecars removed; remaining lifetimes documented).
- [x] 7.2 Consolidate duplicate gameplay scripts in bounded slices (five exact nested matter-maze gate/collectible scripts redirected to canonical copies).
- [ ] 7.3 Decompose oversized scenes in bounded slices.
- [x] 7.4 Introduce release-safe logging (glossary’s 23 routine prints now pass through debug-only `ReleaseLog`).
- [ ] Checkpoint H: Architecture simplified.

  *Checkpoint note:* oversized scene decomposition remains intentionally deferred; duplicate-tree UID cleanup and scene-boundary review are still required.
  See `docs/scene-decomposition-audit.md` for measured candidates and the safe extraction prerequisites.

## Phase 8: Completion

- [x] 8.1 Run the complete desktop/Android/Web regression matrix (24/24 desktop scenes pass; Android APK and Web bundle export successfully with source archives and refactor/test directories excluded).
- [x] 8.2 Audit final repository structure, UIDs, assets, licenses, and exports (manifests, notices, export records, and known duplicate-UID blockers documented).
- [x] 8.3 Update README and architectural documentation.
- [ ] Final checkpoint: Definition of Done and owner approval complete.

## Owner decisions

- [ ] Decide whether New Game resets guide/tutorial history.
- [ ] Decide whether interrupted New Game resumes at cutscene or hometown.
- [ ] Approve the authoritative density tree.
- [ ] Approve the authoritative matter-maze tree.
- [ ] Decide where `.aseprite` source files belong.
- [ ] Decide whether source ZIP archives stay in the repository.
- [ ] Confirm Android/Web release-target status.
- [ ] Decide whether the Auvrynt bridge is committed or local-only.
- [ ] Confirm the required level of backward save compatibility.
