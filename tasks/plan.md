# ChemQuest2 Refactor and Asset Organization Plan

## Status

- Plan status: Implemented through Phase 8 verification; owner approval checkpoints remain before duplicate-tree retirement and release sign-off.
- Prepared from the repository recon on 2026-09-07 and updated during execution on 2026-09-08.
- Target engine: Godot 4.6 or newer.
- Execution checklist: `tasks/todo.md`.
- Current branch: `master` tracking `origin/master`.

## Objective

Refactor ChemQuest2 into a predictable, testable Godot project without changing intended gameplay. The work will first protect save data and repair known correctness defects, then disentangle duplicated scenes and assets, resolve UID collisions, consolidate shared resources, and simplify feature code. Every phase must leave the project runnable and independently reversible.

## Non-goals

- Do not redesign gameplay, rewrite lesson content, or introduce new game mechanics.
- Do not change visual direction unless an asset is proven duplicated, broken, or unused.
- Do not delete a resource based only on filename, directory location, or lack of a literal path reference.
- Do not combine broad code refactoring with broad scene or asset movement in one change.
- Do not overwrite or absorb unrelated local changes.

## Current Baseline

The recon found approximately:

| Area | Current state |
| --- | --- |
| Repository | 7,965 files; about 91.2 MB outside `.git` and `.godot` |
| Godot source | 200 GDScript files, 100 scenes, 4 `.tres` resources |
| Data | 369 JSON files; all parsed successfully during recon |
| Assets | 3,478 importable source assets and 3,436 `.import` sidecars |
| Global state | 15 autoloads |
| Automated tests | None detected |
| Debug output | 292 direct `print()` calls |
| Duplicate data | About 9.2 MB of exact duplicate non-generated files |
| UID integrity | 59 duplicate UID groups across 118 real scene/script resources; substantially more when copied imported assets are included |
| Tracked artifacts | 124 `.tmp`, 12 `.DS_Store`, and 2 ZIP files |
| Longest observed path | 246 characters |

### Existing uncommitted work

The following state existed before this plan and must be preserved:

- Deleted `.kimchi/docs/FIX_REPORT.md`
- Deleted `.kimchi/docs/QA_REPORT.md`
- Deleted `.kimchi/docs/RUNTIME_QA_REPORT.md`
- Modified `.serena/project.yml`
- Modified `project.godot`
- Untracked `addons/auvrynt_bridge/`

Before implementation, the owner must decide whether these changes are intentional, should be committed separately, or should remain outside the refactor. The refactor must never silently restore, discard, or include them.

## Confirmed Problems to Address

### Correctness and persistence

1. New Game does not reset density, states, guides, feedback, scoring, or all feature-manager state.
2. `games/main.gd` maintains `user://quest.json` while `SaveManager` maintains `user://save.json`.
3. The quest reset expression marks every quest except `find_wiz` completed, contrary to its name and message.
4. Density and states numeric progress is saved, but completed-level ID arrays are not; replayed levels can receive duplicate credit after relaunch.
5. Initial New Game saving is timing-dependent because the deferred save can capture the menu scene instead of the intended first gameplay destination.
6. Continue does not validate a saved scene path before attempting a transition.
7. Save writes are not atomic and have no schema version or migration boundary.
8. Continue and New Game route button clicks through the music API, potentially replacing background music with a looping WAV.
9. Precision/Accuracy Home points to the nonexistent `res://scenes/levels/level_map/level_map.tscn`.

### Structure and resource integrity

1. Active density scenes under `Level2-1/Scenes` consume scripts and assets from `Level2-1/Level2-1`.
2. Active matter-maze scenes consume resources from both the direct and nested matter-maze copies.
3. Duplicate scene, script, and imported-asset UIDs make path moves and dependency repair ambiguous.
4. `games/glossary` scenes consume scripts/assets from both `games/glossary` and root `glossary`.
5. Several Precision/Accuracy target scenes reference an obsolete `res://scenes/levels/mini_levels/...` tree and appear to have no incoming references.
6. Two unreferenced 2.5 MB scenes embed WAV data directly as `PackedByteArray`.
7. `icon.svg` is about 2.4 MB because it represents pixels as individual SVG rectangles.
8. Naming conventions vary by case, spacing, numbering, and spelling.

### Verification and operational gaps

1. No automated test suite currently protects save migrations or progression invariants.
2. The latest available runtime log is historical and does not prove the current working tree is clean.
3. Android and Web export presets use `export_filter="all_resources"`, increasing the cost of duplicate or orphan resources.
4. Licensing/attribution files are incomplete or not colocated with every third-party asset pack and font.

## Refactor Principles

1. **Correctness before movement.** Repair persistence and navigation while paths are still stable.
2. **One canonical resource per concept.** A scene, script, image, font, or audio track should have one authoritative location and UID.
3. **Move through Godot-aware tooling.** Prefer the Godot FileSystem dock or a verified UID-aware script; never bulk-move active resources blindly in Explorer.
4. **Dependency closure before deletion.** A candidate may be deleted only after literal paths, UID references, dynamic loads, scripts, export behavior, and runtime smoke tests agree it is unused.
5. **Small reversible changes.** Code changes should normally touch no more than five files. Asset moves must be generated from a reviewed manifest and committed in narrow dependency clusters.
6. **Preserve save compatibility.** Existing `user://save.json`, `guides.cfg`, and legacy quest IDs require explicit migration behavior.
7. **Separate source art from runtime assets.** Editable `.aseprite` and archive sources should not be mixed with imported runtime resources.
8. **Measure before and after.** Record parse errors, runtime errors, export sizes, file counts, and duplicate counts at every major checkpoint.

## Proposed Target Structure

The exact names may be adjusted before Phase 3, but ownership boundaries should converge on this shape:

```text
addons/                         Editor integrations only
assets/
  shared/
    audio/
      music/
      sfx/
    fonts/
    ui/
  third_party/
    pixel_adventure/
    pixel_crawler/
    treasure_hunters/
    LICENSES.md
  source_art/                   Non-runtime editable sources; excluded from export
data/
  dialogue/
  elements/
  progression/
games/
  core/
    persistence/
    transitions/
    audio/
  menu/
  achievements/
  glossary/
  chapter_one/
    hometown/
    lessons/
      elements/
      compounds/
      mixtures/
      separation/
      precision_accuracy/
      density/
      states_of_matter/
tests/
  unit/
  integration/
  smoke/
tasks/
```

The target is an ownership guide, not authorization for a single mass rename. Each feature moves only after its dependency manifest and runtime baseline are approved.

## Dependency Graph

```text
Clean implementation baseline
  -> Runtime smoke-test harness
      -> Save schema and New Game contract
          -> Quest/progression persistence repairs
              -> Canonical density tree selection
                  -> Density dependency migration
                      -> Canonical matter-maze tree selection
                          -> Matter-maze dependency migration
                              -> Duplicate UID removal
                                  -> Shared asset consolidation
                                      -> Orphan cleanup
                                          -> Export and regression verification
```

Glossary consolidation may begin after the runtime harness and save contract are stable, but it must not overlap with the density or matter-maze migration in the same commit.

## Definition of Done

The refactor is complete only when all of the following are true:

- Project import and script parsing complete without errors.
- Main flow works: intro -> menu -> New Game -> cutscene -> hometown.
- Continue restores the exact scene, spawn, quests, feedback, density progress, states progress, and completed-level identities.
- Replaying a completed density or states level after relaunch does not add progress.
- All menu, back, restart, reward, glossary, density, states, and Precision/Accuracy transitions resolve.
- Every real scene/script resource has a unique UID.
- Active scenes no longer reference deprecated duplicate directory trees.
- No tracked `.tmp` or `.DS_Store` files remain.
- Duplicate asset removal is supported by a reviewed manifest and runtime evidence.
- Android and Web exports succeed, with sizes recorded before and after.
- Debug output is intentional and release-safe.
- Third-party assets and fonts have traceable licensing/attribution metadata.
- The README reflects the final layout and verification commands.

## Phase 0: Establish a Protected Baseline

### Task 0.1: Resolve pre-existing worktree ownership

**Description:** Decide how the existing modified, deleted, and untracked files relate to the refactor. Create a clean implementation branch or worktree without changing the meaning of those files.

**Acceptance criteria:**

- [ ] Every pre-existing path is classified as keep, commit separately, or intentionally leave uncommitted.
- [ ] The refactor has a named branch and a recoverable baseline commit/tag.
- [ ] `git status` contains no unexplained changes.

**Verification:**

- [ ] Capture `git status --short --branch` and `git diff --stat`.
- [ ] Confirm no user-owned change was discarded.

**Dependencies:** None.

**Files likely touched:** Git metadata only unless the owner explicitly approves otherwise.

**Estimated scope:** Small.

### Task 0.2: Capture structural and export baselines

**Description:** Record source counts, duplicate hashes, UID collisions, longest paths, broken literal resource references, import errors, and current Android/Web artifact sizes.

**Acceptance criteria:**

- [ ] A machine-readable inventory and a human summary exist.
- [ ] UID collision and duplicate-file reports are reproducible.
- [ ] Current export sizes are recorded, or inability to export is documented.

**Verification:**

- [ ] Re-run the inventory and obtain identical counts on an unchanged tree.
- [ ] Compare the generated summary with the figures in this plan.

**Dependencies:** Task 0.1.

**Files likely touched:** `tasks/baseline-inventory.md`, `tasks/manifests/baseline-resources.csv`.

**Estimated scope:** Small.

### Task 0.3: Establish Godot runtime access

**Description:** Make Godot 4.6.x available through the CLI or the existing local MCP bridge. Treat the bridge as privileged because it can mutate scenes and inject input.

**Acceptance criteria:**

- [ ] Exact Godot version is recorded.
- [ ] The project can be launched and stopped non-interactively.
- [ ] Runtime stdout/stderr can be captured per scene.

**Verification:**

- [ ] Boot `intro.tscn` and exit cleanly.
- [ ] Run one explicit scene and capture its output.

**Dependencies:** Task 0.1.

**Files likely touched:** `tasks/runtime-baseline.md`; optionally local tool configuration that must not be committed.

**Estimated scope:** Small.

### Checkpoint A: Baseline approved

- [ ] Human approves worktree handling.
- [ ] Inventory and runtime commands are reproducible.
- [ ] Baseline Android/Web export result is recorded.
- [ ] No gameplay files have been changed.

## Phase 1: Add Safety Nets

### Task 1.1: Create a headless smoke-test harness

**Description:** Add a minimal Godot test runner that loads a supplied scene, waits for readiness, captures errors, and exits with a meaningful status. Avoid a new dependency unless the built-in runner is insufficient.

**Acceptance criteria:**

- [ ] A scene can be tested by path from the command line.
- [ ] Missing resources or script parse failures cause a nonzero result.
- [ ] Timeout behavior prevents hanging tests.

**Verification:**

- [ ] Passing test: `intro.tscn`.
- [ ] Controlled failing test: nonexistent scene path.

**Dependencies:** Task 0.3.

**Files likely touched:** `tests/smoke/scene_smoke_runner.gd`, `tests/smoke/scene_smoke_runner.tscn`, `tests/README.md`.

**Estimated scope:** Medium.

### Task 1.2: Define the critical scene matrix

**Description:** Enumerate every player-reachable entry, menu, hub, lesson, results, pause, reward, glossary, density, and states scene. Record expected load result and important transitions.

**Acceptance criteria:**

- [ ] Every literal transition path is represented.
- [ ] Dynamically selected density/states destinations are represented.
- [ ] Orphan candidates are explicitly separated from active scenes.

**Verification:**

- [ ] Run every matrix entry through the smoke-test harness.
- [ ] Save baseline error/warning counts.

**Dependencies:** Task 1.1.

**Files likely touched:** `tests/smoke/scenes.json`, `tasks/runtime-baseline.md`.

**Estimated scope:** Small.

### Task 1.3: Add persistence contract tests

**Description:** Test save round-trips, legacy missing fields, corrupt JSON, completed-level identity, empty scene paths, and New Game reset behavior.

**Acceptance criteria:**

- [ ] Tests demonstrate the current missing-array and reset defects before fixes.
- [ ] Tests isolate `user://` data from the developer's real save.
- [ ] Tests assert behavior rather than internal implementation.

**Verification:**

- [ ] Focused persistence suite runs headlessly.
- [ ] Known defects fail for the intended reasons.

**Dependencies:** Task 1.1.

**Files likely touched:** `tests/unit/test_save_manager.gd`, `tests/unit/test_quest_progress.gd`, `tests/fixtures/legacy_save.json`, `tests/fixtures/corrupt_save.json`.

**Estimated scope:** Medium.

### Checkpoint B: Safety net operational

- [ ] Critical scene matrix has a recorded baseline.
- [ ] Persistence tests reproduce known defects.
- [ ] No production behavior has changed.

## Phase 2: Repair Correctness Before Moving Files

### Task 2.1: Define and version one save schema

**Description:** Make `user://save.json` the authoritative save file. Add a schema version, validation, defaults, and legacy-field migration. Keep migration logic separate from ordinary serialization.

**Acceptance criteria:**

- [ ] Save documents contain `schema_version`.
- [ ] Missing legacy fields migrate without losing quests or position.
- [ ] Invalid scene paths fall back to a documented safe scene.

**Verification:**

- [ ] Persistence contract tests pass for current and legacy fixtures.
- [ ] Corrupt input produces a controlled recovery path and clear error.

**Dependencies:** Task 1.3.

**Files likely touched:** `games/global/SaveManager.gd`, `tests/unit/test_save_manager.gd`, `tests/fixtures/legacy_save.json`.

**Estimated scope:** Medium.

### Task 2.2: Persist completed-level identities

**Description:** Serialize and restore `density_completed_levels` and the canonical states completed-level array. Remove or migrate the unused duplicate states array.

**Acceptance criteria:**

- [ ] Numeric progress and completed identities round-trip together.
- [ ] Replaying a completed level after reload adds no credit.
- [ ] Impossible or duplicate level values are normalized.

**Verification:**

- [ ] Density replay regression test passes.
- [ ] States replay regression test passes.

**Dependencies:** Task 2.1.

**Files likely touched:** `games/global/SaveManager.gd`, `games/global/QuestManager.gd`, `tests/unit/test_quest_progress.gd`.

**Estimated scope:** Medium.

### Task 2.3: Implement one authoritative New Game reset

**Description:** Replace the split reset flow with a single operation that resets quests, progression, feedback, guides, scoring, spawn state, and feature-manager session state. Decide explicitly whether guides reset for every New Game or remain profile-level preferences.

**Acceptance criteria:**

- [ ] New Game starts with only the intended quest state.
- [ ] Density/states/scoring/feedback state cannot leak from Continue.
- [ ] `user://quest.json` is migrated or retired without deleting unknown user data silently.

**Verification:**

- [ ] Start from a fully progressed fixture, invoke New Game, and assert every reset field.
- [ ] Relaunch and confirm the reset state persists.

**Dependencies:** Tasks 2.1 and 2.2.

**Files likely touched:** `games/main.gd`, `games/global/SaveManager.gd`, `games/global/QuestManager.gd`, `games/global/PlayerFeedbackManager.gd`, `tests/unit/test_new_game.gd`.

**Estimated scope:** Medium.

### Task 2.4: Make initial saving deterministic

**Description:** Separate the intended destination from the currently loaded scene so the first New Game save cannot accidentally capture `games/main.tscn`. Define when saves flush before quit or transition.

**Acceptance criteria:**

- [ ] Starting New Game immediately writes a valid initial save.
- [ ] Closing during the cutscene resumes at the documented location.
- [ ] The save coalescing interval matches its code and documentation.

**Verification:**

- [ ] Interrupt New Game at menu, cutscene, and hometown checkpoints and test Continue.

**Dependencies:** Task 2.3.

**Files likely touched:** `games/main.gd`, `games/global/SaveManager.gd`, `games/global/FadeManager.gd`, `tests/unit/test_new_game.gd`.

**Estimated scope:** Medium.

### Task 2.5: Correct audio routing

**Description:** Route button clicks through the SFX API, preserve background music, and document or create the expected Music/SFX buses.

**Acceptance criteria:**

- [ ] Continue and New Game clicks do not replace current music.
- [ ] Button WAV does not loop.
- [ ] Missing custom audio buses have a consistent fallback.

**Verification:**

- [ ] Runtime check menu music before and after each button click.
- [ ] Smoke test reports no missing-bus errors.

**Dependencies:** Task 1.2.

**Files likely touched:** `games/main.gd`, `games/global/MusicManager.gd`, optionally `default_bus_layout.tres`, `tests/integration/test_menu_audio.gd`.

**Estimated scope:** Medium.

### Task 2.6: Repair active navigation paths

**Description:** Replace the Precision/Accuracy Home destination with the correct current scene and validate every transition in the critical matrix.

**Acceptance criteria:**

- [ ] Precision/Accuracy Home resolves and returns to the intended UI.
- [ ] No active literal transition points to a missing resource.
- [ ] Dynamic paths are validated before use.

**Verification:**

- [ ] Run every transition in the critical matrix.

**Dependencies:** Task 1.2.

**Files likely touched:** `games/chapter_one/hometown/building_one/Level4/PrecisionAccuracy/pa_manager.gd`, relevant smoke fixtures.

**Estimated scope:** Small.

### Checkpoint C: Gameplay correctness stable

- [ ] Persistence and New Game suites pass.
- [ ] Critical scene matrix has no missing-resource failures.
- [ ] Manual New Game and Continue flows pass.
- [ ] Android save behavior is tested on a device or representative build.

## Phase 3: Build Dependency Manifests

### Task 3.1: Manifest the density resource graph

**Description:** Starting from the three density entry scenes, resolve literal paths, UIDs, nested PackedScenes, scripts, textures, fonts, audio, and dynamic transitions. Classify each resource as canonical, duplicate-identical, duplicate-diverged, or unknown.

**Acceptance criteria:**

- [ ] Every dependency reachable from the three density entries has one classification.
- [ ] Direct and nested copies are hash-compared.
- [ ] Diverged copies have an explicit keep/merge decision.

**Verification:**

- [ ] The manifest reproduces the complete dependency closure from a clean checkout.

**Dependencies:** Checkpoint C.

**Files likely touched:** `tasks/manifests/density-resources.csv`, `tasks/manifests/density-decisions.md`.

**Estimated scope:** Medium.

### Task 3.2: Manifest the states/matter-maze resource graph

**Description:** Repeat the dependency classification for the three states-of-matter scenes and their direct/nested matter-maze copies.

**Acceptance criteria:**

- [ ] Every states dependency has one classification.
- [ ] Cross-references into density and shared mobile controls are identified.
- [ ] Source-art files are separated from runtime dependencies.

**Verification:**

- [ ] The manifest reproduces the complete dependency closure.

**Dependencies:** Checkpoint C.

**Files likely touched:** `tasks/manifests/states-resources.csv`, `tasks/manifests/states-decisions.md`.

**Estimated scope:** Medium.

### Task 3.3: Manifest glossary ownership

**Description:** Determine which root and `games/glossary` scripts, scenes, data, and assets are authoritative. Document the currently intentional cross-tree bindings.

**Acceptance criteria:**

- [ ] Main, element-info, and about flows each have a canonical scene/script/data set.
- [ ] Duplicate assets and genuinely distinct assets are distinguished by hash.
- [ ] Achievement dependencies on glossary assets are included.

**Verification:**

- [ ] Glossary and achievements smoke tests cover every retained dependency.

**Dependencies:** Checkpoint C.

**Files likely touched:** `tasks/manifests/glossary-resources.csv`, `tasks/manifests/glossary-decisions.md`.

**Estimated scope:** Medium.

### Checkpoint D: Canonical ownership approved

- [ ] Human approves density, states, and glossary canonical locations.
- [ ] No files have been deleted.
- [ ] Diverged copies have explicit merge decisions.

## Phase 4: Untangle Feature Trees

### Task 4.1: Migrate density dependencies in bounded batches

**Description:** Move or redirect density resources toward the approved canonical tree. Generate one subtask per dependency cluster, with at most five logical source resources plus their Godot sidecars per batch.

**Acceptance criteria:**

- [ ] Each batch removes a documented cross-tree edge.
- [ ] Moved resources retain or deliberately regenerate unique UIDs.
- [ ] All three density scenes pass after every batch.

**Verification:**

- [ ] Run density smoke tests and UID scan after every batch.
- [ ] Compare resource hashes against the manifest.

**Dependencies:** Task 3.1.

**Files likely touched:** Determined by each manifest-generated subtask.

**Estimated scope:** Multiple small/medium batches.

### Task 4.2: Migrate states/matter-maze dependencies in bounded batches

**Description:** Move or redirect matter-maze resources toward the approved canonical tree using the same batch and UID rules as density.

**Acceptance criteria:**

- [ ] Each batch removes a documented cross-tree edge.
- [ ] All three states scenes pass after every batch.
- [ ] Shared controls/assets have one owner.

**Verification:**

- [ ] Run states smoke tests and UID scan after every batch.

**Dependencies:** Task 3.2 and completion of any shared dependency decisions from Task 4.1.

**Files likely touched:** Determined by each manifest-generated subtask.

**Estimated scope:** Multiple small/medium batches.

### Task 4.3: Consolidate glossary in bounded batches

**Description:** Place glossary scenes, scripts, data, and feature-specific assets under one approved feature boundary. Move shared fonts/UI only after Phase 5 destinations exist.

**Acceptance criteria:**

- [ ] Glossary scenes no longer cross between root `glossary` and `games/glossary` for feature-owned files.
- [ ] Element and compound data loads correctly.
- [ ] Achievements retain their required visuals/fonts.

**Verification:**

- [ ] Glossary loads all expected entries.
- [ ] Search, selection, element details, back navigation, and achievements pass.

**Dependencies:** Task 3.3.

**Files likely touched:** Determined by the glossary manifest.

**Estimated scope:** Multiple small/medium batches.

### Checkpoint E: Cross-tree references eliminated

- [ ] Canonical density, states, and glossary scenes pass.
- [ ] No active reference targets a deprecated duplicate tree.
- [ ] UID collision count has materially decreased and no new collisions exist.

## Phase 5: Consolidate Shared and Third-party Assets

### Task 5.1: Establish shared font and UI ownership

**Description:** Choose canonical copies for repeated fonts and shared UI images. Redirect consumers in small batches before removing duplicates.

**Acceptance criteria:**

- [ ] Each shared font/image has one canonical runtime path.
- [ ] UI appearance remains unchanged in baseline screenshots.
- [ ] Import settings remain appropriate for mobile/web.

**Verification:**

- [ ] Screenshot comparison for menu, glossary, achievements, hometown, and lesson panels.
- [ ] Hash and reference scan finds no active references to retired copies.

**Dependencies:** Checkpoint E.

**Files likely touched:** `assets/shared/fonts/*`, `assets/shared/ui/*`, consumer scenes in bounded batches.

**Estimated scope:** Multiple small batches.

### Task 5.2: Establish shared audio ownership

**Description:** Consolidate music and SFX under separate directories, replace embedded WAV subresources with normal audio resources where needed, and identify the two large orphan audio scenes.

**Acceptance criteria:**

- [ ] Music and SFX have clear canonical paths and bus behavior.
- [ ] No runtime scene contains a multi-megabyte embedded audio byte array unless explicitly justified.
- [ ] Orphan audio scenes are proven unused before deletion.

**Verification:**

- [ ] Audio smoke checks pass for menu and every lesson family.
- [ ] Before/after resource and export sizes are recorded.

**Dependencies:** Task 2.5 and Checkpoint E.

**Files likely touched:** `assets/shared/audio/*`, `games/global/MusicManager.gd`, affected scenes in bounded batches.

**Estimated scope:** Multiple small/medium batches.

### Task 5.3: Normalize third-party asset packs and licensing

**Description:** Place third-party packs under stable vendor directories and add attribution/licensing metadata. Keep editable sources separate from runtime resources.

**Acceptance criteria:**

- [ ] Every third-party pack/font has source, author, license, and usage notes or an explicit unresolved-license record.
- [ ] `.aseprite` and ZIP sources are excluded from runtime exports unless required.
- [ ] Runtime assets have one canonical imported copy.

**Verification:**

- [ ] License inventory has no unexplained asset family.
- [ ] Android/Web exports contain no unintended source archives.

**Dependencies:** Tasks 3.1-3.3 and Checkpoint E.

**Files likely touched:** `assets/third_party/LICENSES.md`, `assets/source_art/*`, asset folders in manifest-sized batches.

**Estimated scope:** Multiple small/medium batches.

### Task 5.4: Optimize the project icon

**Description:** Replace the 2.4 MB rectangle-per-pixel SVG with a visually equivalent compact SVG or PNG while retaining required export sizes.

**Acceptance criteria:**

- [ ] Icon appearance is visually equivalent at supported sizes.
- [ ] Source size is materially smaller.
- [ ] Android, Web, and editor icons import correctly.

**Verification:**

- [ ] Compare rendered icons at 16, 32, 64, 128, and 200 pixels.
- [ ] Run Android/Web export validation.

**Dependencies:** Task 0.2.

**Files likely touched:** `icon.svg` or a replacement icon asset, `project.godot`, `export_presets.cfg` only if required.

**Estimated scope:** Small.

### Checkpoint F: Asset model stable

- [ ] Duplicate-byte waste and project size are remeasured.
- [ ] Runtime screenshots and audio checks match the baseline.
- [ ] Licensing inventory is complete or has explicit blockers.

## Phase 6: Remove Proven Dead and Generated Content

### Task 6.1: Remove tracked editor artifacts

**Description:** Untrack confirmed `.tmp` and `.DS_Store` files and verify ignore rules prevent recurrence. Keep this change separate from functional edits.

**Acceptance criteria:**

- [ ] No tracked `.tmp` or `.DS_Store` files remain.
- [ ] A fresh Godot editing session does not add them to Git status.
- [ ] No real `.tscn` file is removed with its temporary copies.

**Verification:**

- [ ] `git ls-files '*.tmp' '*.DS_Store'` returns nothing.
- [ ] Full scene matrix still passes.

**Dependencies:** Checkpoint E.

**Files likely touched:** `.gitignore` if necessary and tracked artifact removals.

**Estimated scope:** Mechanical cleanup; review by manifest.

### Task 6.2: Remove orphan Precision/Accuracy resources

**Description:** Validate and remove or repair the orphan target, rotating-target, and hitmark scenes that reference the obsolete `res://scenes/...` layout.

**Acceptance criteria:**

- [ ] Runtime instrumentation and reference scans show no active consumer before deletion.
- [ ] No broken literal `res://scenes/levels/mini_levels/...` references remain.
- [ ] Current Precision/Accuracy gameplay remains unchanged.

**Verification:**

- [ ] Precision/Accuracy smoke and interaction tests pass.
- [ ] Missing-resource scan returns no active legacy paths.

**Dependencies:** Task 2.6 and Checkpoint E.

**Files likely touched:** Up to five orphan resources per cleanup subtask.

**Estimated scope:** Multiple small batches.

### Task 6.3: Remove retired duplicate trees

**Description:** Delete a deprecated tree only after all manifest entries have moved, all active references are gone, and UIDs are unique. Density, matter-maze, and glossary removals must be separate changes.

**Acceptance criteria:**

- [ ] Deleted paths have zero active path/UID/dynamic references.
- [ ] Canonical copies contain every retained divergent change.
- [ ] Runtime and exports succeed after each tree removal.

**Verification:**

- [ ] Full scene matrix, UID scan, missing-resource scan, and exports pass.
- [ ] Compare manifest hashes and file counts before deletion.

**Dependencies:** Checkpoints E and F; Tasks 6.1 and 6.2 where applicable.

**Files likely touched:** One approved deprecated tree per change.

**Estimated scope:** Large mechanical deletion, split by feature.

### Checkpoint G: Resource cleanup complete

- [ ] Every real scene/script UID is unique.
- [ ] No active missing resource references remain.
- [ ] Deprecated duplicate trees are absent.
- [ ] Project and export sizes are recorded.

## Phase 7: Simplify Code and Scene Architecture

### Task 7.1: Reduce autoload scope

**Description:** Classify autoloads as truly application-wide or feature-owned. Move feature-only state toward owning scenes/resources without changing saved behavior.

**Acceptance criteria:**

- [ ] Every autoload has documented lifetime and owner.
- [ ] Feature-only managers no longer create invisible cross-feature dependencies.
- [ ] SaveManager talks to explicit persistence models rather than reading arbitrary globals.

**Verification:**

- [ ] Persistence suite and full scene matrix pass after each manager migration.

**Dependencies:** Checkpoint G.

**Files likely touched:** One manager and up to four consumers per subtask.

**Estimated scope:** Multiple medium batches.

### Task 7.2: Consolidate duplicate gameplay scripts

**Description:** Replace identical or near-identical target, checker, barrel, bottle, item, gate, and player scripts with shared behavior only where the abstraction removes real duplication.

**Acceptance criteria:**

- [ ] Each extraction has at least two verified consumers.
- [ ] Feature differences are data/configuration, not scattered conditionals.
- [ ] Empty scripts are removed only after confirming no intentional placeholder role.

**Verification:**

- [ ] Focused lesson tests pass after each extraction.
- [ ] Exact duplicate script count decreases without increasing branching complexity.

**Dependencies:** Checkpoint G.

**Files likely touched:** One shared script and up to four consumers per subtask.

**Estimated scope:** Multiple medium batches.

### Task 7.3: Decompose oversized scenes

**Description:** Extract coherent reusable panels, maps, overlays, and feature sections from the hometown, glossary, and large lesson scenes. Preserve unique node names and signal contracts.

**Acceptance criteria:**

- [ ] Each extracted scene has one clear responsibility.
- [ ] Existing `%UniqueName` and signal dependencies remain valid or are explicitly migrated.
- [ ] Main scene files materially decrease in size and conceptual load.

**Verification:**

- [ ] Screenshot/interaction comparisons pass before and after each extraction.
- [ ] Scene smoke tests report no missing nodes or signals.

**Dependencies:** Checkpoint G.

**Files likely touched:** One parent scene, one extracted scene, and up to three scripts per subtask.

**Estimated scope:** Multiple medium batches.

### Task 7.4: Introduce release-safe logging

**Description:** Replace noisy direct prints with a small logging policy or debug flag. Preserve actionable errors and warnings.

**Acceptance criteria:**

- [ ] Routine release gameplay does not emit per-frame/per-spawn noise.
- [ ] Failures retain context-rich warnings/errors.
- [ ] No gameplay logic depends on logging side effects.

**Verification:**

- [ ] Full smoke run log is reviewed and compared with baseline.
- [ ] Release export runs without unexpected debug spam.

**Dependencies:** Checkpoint G.

**Files likely touched:** One logging helper and up to four consumers per subtask.

**Estimated scope:** Multiple small batches.

### Checkpoint H: Architecture simplified

- [ ] Autoload ownership is documented.
- [ ] Duplicate-script and direct-print counts are remeasured.
- [ ] Large-scene decomposition preserves screenshots and interactions.

## Phase 8: Final Verification and Documentation

### Task 8.1: Run complete regression matrix

**Description:** Execute automated and manual flows across desktop, Android, and Web targets where supported.

**Acceptance criteria:**

- [ ] Intro, menu, New Game, Continue, hometown, both buildings, every lesson, glossary, achievements, reward, pause/restart, and back navigation pass.
- [ ] Save migration is tested from a real pre-refactor save copy.
- [ ] No new errors, warnings, orphan nodes, or missing resources appear.

**Verification:**

- [ ] Archive command outputs, logs, screenshots, and platform results in `tasks/final-verification.md`.

**Dependencies:** Checkpoint H.

**Files likely touched:** `tasks/final-verification.md` and test fixtures only.

**Estimated scope:** Medium.

### Task 8.2: Audit final repository and exports

**Description:** Re-run structural, dependency, duplicate, UID, license, path-length, and artifact scans; compare against the Phase 0 baseline.

**Acceptance criteria:**

- [ ] Zero real scene/script UID collisions.
- [ ] Zero active missing-resource references.
- [ ] Zero tracked editor artifacts.
- [ ] Size changes and remaining intentional duplicates are documented.

**Verification:**

- [ ] Android and Web exports succeed.
- [ ] Export sizes and contents are compared with baseline.

**Dependencies:** Task 8.1.

**Files likely touched:** `tasks/final-verification.md`, `tasks/manifests/final-resources.csv`.

**Estimated scope:** Small.

### Task 8.3: Update developer documentation

**Description:** Update project structure, run/test/export commands, save migration behavior, asset ownership, naming conventions, and third-party attribution.

**Acceptance criteria:**

- [ ] A new contributor can find every major system and run verification from the README.
- [ ] Known architectural decisions and retained exceptions explain why they exist.
- [ ] Documentation matches the actual final tree.

**Verification:**

- [ ] Follow the documented setup and commands from a clean checkout.

**Dependencies:** Task 8.2.

**Files likely touched:** `README.md`, `assets/third_party/LICENSES.md`, optionally `docs/decisions/*.md`.

**Estimated scope:** Medium.

### Final Checkpoint

- [ ] Definition of Done is fully satisfied.
- [ ] Human approves gameplay and visual comparisons.
- [ ] Every deferred issue has an owner and rationale.
- [ ] Refactor changes are split into reviewable commits with documented verification.

## Naming Conventions to Adopt

- Directories and files: lowercase `snake_case` unless a third-party pack must preserve upstream names.
- Scripts and scenes: matching stems when they form a pair, such as `density_gate.gd` and `density_gate.tscn`.
- Feature levels: semantic names where possible; otherwise `level_01`, `level_02`, `level_03`.
- Autoload names: PascalCase; implementation files use `snake_case.gd` after migration.
- Resource IDs and quest IDs: lowercase `snake_case`, with migrations for persisted legacy spellings.
- Avoid spaces, parentheses, duplicate folder names, and ambiguous names such as `main`, `data`, `meme`, `level`, or `imgs` outside a tightly scoped feature.
- Preserve third-party filenames only inside `assets/third_party`; wrap them with stable project-owned resource paths when needed.

## Commit Strategy

Each commit should represent one independently verifiable change. Recommended sequence:

1. Baseline/test infrastructure.
2. Save schema and migrations.
3. New Game reset.
4. Audio routing.
5. Navigation repair.
6. Density dependency batches.
7. States dependency batches.
8. Glossary dependency batches.
9. Shared asset batches.
10. Generated/orphan cleanup.
11. Code/scene simplification batches.
12. Documentation and final reports.

Do not combine a resource move, behavioral fix, and cleanup deletion in the same commit. Mechanical deletions may be large but must be backed by the approved manifest and isolated from logic changes.

## Runtime Verification Matrix

At minimum, every checkpoint must exercise:

| Flow | Required checks |
| --- | --- |
| Project boot | Autoload initialization, script parsing, intro rendering |
| Main menu | Music, Continue fallback, New Game, glossary, about, exit |
| New Game | Full reset, initial save, cutscene transition, hometown spawn |
| Continue | Valid save, legacy save, corrupt save, missing scene path |
| Hometown | Default and named spawns, quest panel, building entrances, reward redirect |
| Building One | Element, compound, mixture, separation, Precision/Accuracy lessons |
| Building Two | Three density levels and three states levels |
| Glossary | Data load, search, element details, back navigation |
| Achievements | Locked/unlocked labels, reward navigation |
| Persistence | Restart after each progression milestone; replay completed levels |
| Platforms | Desktop, Android, Web imports and exports |

## Metrics to Track

Capture these at Baseline, Checkpoints E/G/H, and Final:

- Total tracked files and bytes.
- Scene/script/data/asset counts.
- Duplicate hash groups and wasted bytes.
- Duplicate UID groups, split by scenes, scripts, and imported assets.
- Broken literal resource paths.
- Maximum path length.
- Number of autoloads.
- Exact duplicate and empty scripts.
- Direct `print()` count.
- Android APK and Web export sizes.
- Smoke-test passes, warnings, errors, and timeouts.
- Import time and peak runtime memory for representative scenes.

## Risks and Mitigations

| Risk | Impact | Mitigation |
| --- | --- | --- |
| Deleting a visually duplicated but actively referenced asset | Critical | Dependency closure, UID scan, runtime matrix, deletion in a separate commit |
| Duplicate UID redirects a scene to the wrong copy after a move | Critical | Resolve collisions feature-by-feature before deleting either path |
| Save migration loses player progress | Critical | Versioned schema, fixture copies, atomic write, backup/recovery test |
| New Game retains old global state | High | One reset contract with progressed-state regression fixture |
| Godot updates paths differently from manual filesystem moves | High | Use Godot-aware moves and verify diffs immediately |
| Long Windows paths break tooling | High | Shorten canonical paths early in each approved feature migration |
| Dynamic `load()` path is missed by static scanning | High | Runtime instrumentation and scene matrix before deletion |
| Large scene edits generate noisy diffs or corrupt ownership | High | Extract one coherent child scene at a time and verify saved output |
| Export includes source art or archives | Medium | Explicit export exclusions and artifact-content audit |
| Third-party asset licensing is unclear | High | Block redistribution decisions until attribution/license is recorded |
| MCP bridge unintentionally mutates scenes | Medium | Use read-only methods during recon; isolate and review every mutation |
| Existing dirty work is mixed into refactor commits | High | Resolve Task 0.1 before any implementation |

## Open Decisions Requiring Owner Approval

1. Should New Game reset tutorial/guide history, or should guides remain profile-level preferences?
2. Should the first Continue after interruption resume the cutscene or enter hometown directly?
3. Which density tree contains the authoritative divergent scene edits?
4. Which matter-maze tree contains the authoritative divergent scene edits?
5. Should editable `.aseprite` sources remain in this repository under `assets/source_art`, or move to a separate art repository?
6. Should source ZIP archives be removed after extraction or retained outside export paths?
7. Are Android and Web both release targets, or is Web only for testing?
8. Should the local Auvrynt MCP bridge remain committed, remain local-only, or be removed after refactoring?
9. Is preserving existing local saves a release requirement or best-effort compatibility?

## Stop Conditions

Pause implementation and request owner direction if:

- Two diverged duplicate resources both contain behavior that appears intentional.
- A UID resolves differently between static analysis and Godot runtime.
- A save migration cannot distinguish legacy meanings without guessing.
- Third-party licensing cannot be established for an asset intended for distribution.
- A planned deletion remains reachable through a dynamic path or runtime-only dependency.
- The current worktree changes overlap a planned file and ownership is unresolved.

## Recommended First Implementation Slice

After owner approval, begin only with Tasks 0.1 through 1.3. That slice creates a protected baseline and tests without moving gameplay resources. The first behavioral change should then be Task 2.1, the versioned save contract, followed by the completed-level and New Game fixes. Asset movement should not begin until Checkpoint C is green and the canonical resource manifests are approved.
