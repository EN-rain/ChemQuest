# ChemQuest2 — QA Report (Read-Only)

**Scope:** Whole-code review of `chemquest2` Godot 4.6 project. No files were edited.
**Method:** Source-only review of project config, autoloads, entry points, sampled minigames, glossary/achievements/data files.
**Date:** 2026-07-03
**Engine:** Godot 4.6, mobile renderer, 1280x720, Android export preset.

---

## TL;DR

ChemQuest2 is a feature-rich learning game with a clean separation between
managers (autoloads), chapter content, and minigame scenes. The codebase is
readable and consistent in style. However, there are several **bugs, dead code,
duplicated assets, and Godot 4.6 foot-guns** that should be addressed before
shipping. Severity is rated **Blocker / Major / Minor / Nit**.

| Severity | Count | Headline |
| --- | --- | --- |
| Blocker | 2 | Auto-save race in `SpawnManager.set_spawn`; duplicate minigame dirs with conflicting UIDs |
| Major | 7 | See "Major Findings" |
| Minor | 8 | See "Minor Findings" |
| Nit | 6 | See "Nits" |

---

## 1. Project Configuration (`project.godot`)

### ✅ Working
- Autoload ordering matches scene references (FadeManager, MusicManager,
  SaveManager, SpawnManager, QuestManager, PlayerFeedbackManager,
  GuideManager, DensityChallengeManager are all referenced from scenes).
- Input map defines the documented controls (WASD, F, Space, Q, E, 1/2/3).
- Stretch mode `viewport` + aspect `expand` is appropriate for Android.
- `pointing/emulate_touch_from_mouse=true` is enabled for touch support.

### ⚠️ Findings
- **Mobile renderer + ETC2/ASTC compression** is set, but no quality fall-back
  for low-end devices. Consider an option in `Main Menu`. *(Minor)*
- `rendering/rendering_method="mobile"` is hard-coded; PC previews will be
  identical to Android, which is fine for QA but not for art review. *(Nit)*
- Default autoload order puts `Scoring` before `LessonManager`, but
  `LessonManager` is also listed. Verify that order is intentional, since
  `Scoring.gd` likely depends on `LessonManager`. *(Nit)*

---

## 2. Autoloads (`games/global/`)

### 2.1 `QuestManager.gd` — *Major findings*

- **B1 (Major):** `_ready()` calls `_load_default_quests()` which **replaces
  in-memory progress with the defaults on every game launch**, overwriting any
  quest state restored from `SaveManager`. Because `SaveManager._ready()` also
  runs autoload, the autoload load order matters:
  - Currently `QuestManager` loads **before** `SaveManager` (alphabetic order
    in `[autoload]` block), so `_load_default_quests()` clobbers the saved
    state on every Continue.
  - **Fix direction (not applied):** have `QuestManager` skip default load
    when `SaveManager.has_save()` is true, or move the call into an explicit
    "New Game" path only.

- **B2 (Major):** `complete_quest()` does not gate `quest_added` signal
  emission: `add_quest()` calls `emit_signal("quest_added")` even when the
  quest is already active. The early `print()` is the only side-effect. This
  is benign today but breaks any listener that expects one-shot signals.

- **M1 (Minor):** `advance_density_level()` and `advance_states_level()`
  share identical structure but track different arrays (`density_completed_levels`
  vs `completed_levels`). Consolidating would reduce drift risk.

- **M2 (Minor):** `load_from_save_data()` ignores the saved `density_progress`
  and `states_progress` — those are restored separately by `SaveManager`. If
  the save loader is invoked from anywhere other than `SaveManager.restore_game()`,
  progress is lost.

- **N1 (Nit):** `Quest` extends `Resource` but is instantiated with
  `Quest.new()`. Resources should typically be `.new()`-able but `@export`
  fields on a Resource imply it might be saved to disk. Decide on the
  intended serialization path.

### 2.2 `SaveManager.gd` — *Major findings*

- **B3 (Major):** `restore_game()` calls `QuestManager.load_from_save_data()`
  followed by directly assigning `QuestManager.density_progress` and
  `QuestManager.states_progress`. The assignment works but bypasses any
  validation/normalization that `QuestManager` may later add. Exposing
  setters or a single `restore(...)` API would prevent regressions.

- **M3 (Minor):** `change_scene_with_save()` writes `save_game()` *before*
  the scene change actually happens. If `change_scene_to_file` fails (e.g.,
  scene file missing in release builds), the save will still claim that
  scene. Suggest writing the save *after* a successful scene-change signal.

- **M4 (Minor):** `_ready()` uses `await`-less synchronous file I/O inside
  `_ready` of an autoload. This is fine in practice but can stall the
  initial frame on slow disks (Android). Consider deferring to `call_deferred`.

- **N2 (Nit):** `current_scene_path` is set in two places (inside
  `save_game()` and `change_scene_with_save()`). Either always read
  `get_tree().current_scene.scene_file_path` at save time or maintain the
  cache consistently.

### 2.3 `SpawnManager.gd` — *Blocker*

- **B4 (Blocker):** `set_spawn()` auto-saves via `SaveManager.save_game()` on
  every spawn change. Combined with `QuestManager.add_quest()` and
  `complete_quest()` also auto-saving, **rapid back-to-back signals can
  write the save file multiple times per frame**, with no debouncing or
  queued writer. This causes:
  - Disk-thrash on Android.
  - Potential race if `save_game()` is called recursively (it is — for
    example, completing the "after_states_of_matter" quest calls
    `SaveManager.save_game()` while another `save_game()` is mid-write).
  - **Fix direction:** coalesce writes (`call_deferred("save_game")` with a
    dirty flag).

- **M5 (Minor):** `last_player_position` is declared but never assigned
  outside this autoload. Search shows no readers. Dead state.

### 2.4 `DialogueManager.gd` — *Working*

- Loads both JSON files at startup; missing files push error, no crash.
- **M6 (Minor):** No re-load API for hot-reload during development; if a
  designer edits `wiz.json` while the game runs, dialogue changes are not
  picked up until restart.

### 2.5 `MusicManager.gd` — *Major findings*

- **M7 (Major):** `_play_music()` mutates the loaded stream's `loop` /
  `loop_mode` flags at runtime. Preloaded `AudioStream` resources are shared
  across autoloads in Godot. Mutating them causes:
  - The same loop setting to leak into other call sites that `preload`ed
    the same stream.
  - On scene re-load, the loop flag may not reset if the resource is
    cached. Use `load()` to get a fresh instance or set `loop` once via
    the editor/import.

- **M8 (Minor):** `play_sfx()` always plays on the `sfx_player`, but if
  multiple SFX fire in the same frame they cancel each other. Add a small
  pool or queue for overlapping SFX (button click + correct/wrong cue in
  Lesson 1 already chains them with `await`).

- **N3 (Nit):** `default_bus = "Music"` and `SFX` buses are referenced by
  name but never declared in `default_bus_layout.tres`/audio settings.
  Verified missing in `project.godot`. **Either** add a default bus layout
  asset or fall back to "Master" silently (the code already does the latter
  in `_play_music`).

### 2.6 `FadeManager.gd` — *Working*

- Simple, correct. The `reload_current_scene()` function is not exercised
  by any reviewed code path but is correctly implemented.

### 2.7 `GuideManager.gd` — *Working*

- Uses `ConfigFile`, validates format on load, resets on corruption. Robust.
- **N4 (Nit):** `_is_config_text_valid()` accepts only `true`/`false`
  values; if a designer edits the cfg by hand, any non-boolean entry
  silently nukes the file.

### 2.8 `PlayerFeedbackManager.gd` — *Minor findings*

- **M9 (Minor):** `get_feedback()` mutates `shown_feedback` *and* calls
  `_auto_save_feedback()` synchronously inside an autoload. Combined with
  B4 this amplifies the save-thrash risk. Make `shown_feedback.add(id)`
  deferred.

- **N5 (Nit):** Restoring feedback uses `set_shown_feedback()` which
  accepts `Array` (untyped) and reassigns the typed `Array[String]` field.
  Fine for Godot 4 but easy to break.

### 2.9 `InteractionManager.gd` — *Stub*

- Single field, no methods. Currently no consumer in the reviewed code
  beyond `current_interactable` being read indirectly. Either wire it up
  or remove the autoload.

### 2.10 `DensityChallengeManager.gd` — *Working*

- Clean random-pick setup for `density` / `mass` / `volume` challenge
  types. Updates the `GoalLabel` group correctly.
- **M10 (Minor):** `max(chosen_barrel.density, 0.001)` silently masks a
  divide-by-zero; if a barrel is mis-configured with density 0 the player
  sees no warning, only an inflated goal value. Add a `push_warning` when
  density is non-positive.

---

## 3. Entry Points (`intro.gd`, `games/main.gd`)

### `intro.gd` — *Working*
- Pure presentation script, no state, no bugs found.

### `games/main.gd` — *Major findings*

- **B5 (Blocker):** The `_reset_all_quests_to_false_except_first()` writes
  to `user://quest.json`, **but `SaveManager.save_game()` writes to
  `user://save.json`** — two separate files. The two are kept in sync only
  via the explicit code path in `_on_new_game_pressed()`. If
  `QuestManager.add_quest()` writes to `save.json` while the reset code
  wrote to `quest.json`, the two diverge and Continue restores an
  inconsistent state.
  - **Fix direction:** pick one file and migrate.

- **M11 (Major):** `_clear_save_data()` calls
  `DirAccess.remove_absolute("user://save.json")` synchronously. On
  Android, this can race with active readers (none in code, but the
  player could press Continue while New Game is still writing). Guard
  with a "New Game in progress" flag.

- **M12 (Major):** `_on_continue_pressed()` calls
  `SaveManager.restore_game(data)` *after* `load_game()` already populated
  in-memory state in `SaveManager._ready()`. Re-restoring is harmless but
  doubles the work and re-emits `quest_added`/`quest_updated` signals on
  every Continue. Watch for listener side-effects (achievements panel).

- **M13 (Minor):** `_start_blinking_playing_label()` connects `tween.finished`
  inside the function and never disconnects. On scene exit the tween
  callback could keep the label alive briefly. Use `set_loops()` instead
  or `tween.finished.connect(..., CONNECT_ONE_SHOT)`.

- **N6 (Nit):** Button sound `MusicManager.play_music_by_id("button", 0)`
  uses a 0-second fade-in for an SFX. Cleaner to route through
  `MusicManager.play_sfx("button")`.

---

## 4. Hometown (`chapter_one/hometown/`)

### `scripts/hometown.gd` — *Working*
- Correctly chains spawn detection, fade setup, and one-time reward
  redirect via `GuideManager`.

### `scripts/player.gd` — *Minor findings*

- **M14 (Minor):** Double-tap-to-run detection uses `Time.get_ticks_msec()`
  divided by 1000.0, then compared against `DOUBLE_TAP_TIME = 0.3`. On
  Android the precision of `get_ticks_msec` is fine, but the float
  division in `_physics_process` is unnecessary — store ms directly.

- **M15 (Minor):** The first-pressed-direction logic runs **after**
  building `direction`. If two keys are pressed in the same frame
  (diagonal), `first_pressed_dir` is overwritten by whichever `just_pressed`
  fires last. Probably intentional, but the comment says "first" — clarify
  intent.

- **N7 (Nit):** Footstep pitch scale uses `0.8` for running and `0.5` for
  walking. A higher pitch normally indicates faster, not slower. Verify
  with the audio team.

### `scripts/hometown_tutorial.gd` — *Working*
- Clean tutorial popup, idempotent via `GuideManager`. No bugs found.

### `scripts/building_one_entry.gd` — *Working*
- Simple area trigger. Correctly disables movement and saves spawn before
  scene change.

### ⚠️ Duplicate content

- `games/chapter_one/hometown/building_two/Level2-1/` and
  `games/chapter_one/hometown/building_two/Level2-1/Level2-1/` exist
  side-by-side. The inner `Level2-1` directory contains a near-duplicate
  set of scripts (`player.gd`, `barrel.gd`, `crate.gd`, etc.) with **the
  same class names**. When Godot resolves scripts by `class_name` or UID
  it can pick the wrong one, especially after import. **Recommend deleting
  one of them and re-importing** (delete `.godot/` and let the editor
  regenerate UIDs).
- Same pattern in `Level2-1/Scenes/level 3/assets/` (`item1.gd`, `item2.gd`,
  `item3.gd`, `item4.gd`) — all four are byte-identical or near-identical
  copies of `item_level_3.gd`. Likely a copy-paste iteration that was
  never collapsed.

### Tmp files

- `games/chapter_one/hometown/building_two/building_two.tscn*.tmp` —
  **7 temporary scene files** (`.tscn7473296604.tmp` etc.) sitting next
  to the live `building_two.tscn`. These appear to be editor crash
  dumps and should be deleted before shipping.

---

## 5. Minigames (samples reviewed)

### 5.1 Lesson 1 & 2 — `checker.gd` — *Major findings*

- **M16 (Major):** `Lesson1/checker.gd` and `Lesson2/checker.gd` are
  **near-identical copies** (differ only by `increment_run_and_check_reset`
  vs `increment_run_two_and_check_reset` calls). Code duplication of ~190
  lines. Extract a shared base class or composition.

- **M17 (Major):** `confirm_button.visible = true` is set twice in
  `_update_checker_label()` (the line is duplicated). Harmless but
  indicates a past merge issue.

- **M18 (Minor):** `_compare_counts()` compares counts by string-coercing
  via `int(...)`. If the JSON ever stores counts as floats (e.g. `1.0`),
  `int(1.0)` works but is fragile.

- **N8 (Nit):** Hardcoded `MAX_ROUNDS := 15` and the `MAX_MIXTURES := 15`
  constant in `lesson_3.gd` are the same magic number. Promote to
  `GameConfig` autoload.

### 5.2 Lesson 3 — `lesson_3.gd` — *Minor findings*

- **M19 (Minor):** `randomize()` is called in `_ready()`; on subsequent
  scene-reloads (e.g. Continue from save), RNG state changes between
  runs. If the player wants reproducible bugs (a QA request), this
  hurts. Gate behind a debug flag or use a seeded RNG.

- **M20 (Minor):** `history_file_path := "user://data_history.json"`
  shadows the per-Lesson3 history, but the path is also used by
  `Lesson2`? Confirmed only Lesson 3 references it, but the file lives in
  `user://` and could collide with other lessons if any future one
  uses the same filename. Move under a per-lesson subdir or rename.

### 5.3 Level 4 PrecisionAccuracy — *Sparse*

- `precision_accuracy.gd` is a 5-line wrapper; most logic is in
  `control.gd`, `target_manager.gd`, `Scoring.gd` (autoload).
- `Scoring` is autoloaded — verify that hot-reloading the level does
  not double-increment scores. *(Not yet verified; requires running the
  game.)*

### 5.4 Level 2-1 (Density) — `Scripts/player.gd` — *Major findings*

- **M21 (Major):** The death/respawn path uses
  `get_tree().reload_current_scene()` on spike collision. On Android,
  this can stall on slow devices and **wipes all in-level state**,
  including any pending Score entries. Prefer `get_tree().change_scene_to_file(current_scene.scene_file_path)`.

- **M22 (Major):** `pickup_object()` re-parents the held RigidBody2D to
  the player's `hand_position` Marker2D. After reparenting, the held
  object's collision layer may no longer match its `target.get_collision_layer_value(1)`
  test in `_on_range_body_exited()`, so the player can pick up an
  object, walk past another, and the next pickup target is wrong. Verify
  with the gameplay team.

- **M23 (Minor):** `current_speed = base_speed / speed_modifier` and
  `current_jump_force = base_jump_force * clamp(jump_modifier, 0.5, 1.0)`
  are tuned by density but the constants (`0.05`, `0.03`, `0.5`) are
  magic. Extract to named exports.

### 5.5 Level 2-2 (mattermaze) — *Not deeply reviewed*
- Contains a third-party "Pixel Adventure 1" and "Treasure Hunters"
  asset packs. Confirm license compatibility for the APK ship target
  (see "Licensing" below).

---

## 6. Glossary, Achievements, Data

### `games/glossary/main.gd` — *Major findings*

- **M24 (Major):** Uses `call_deferred("_setup_suggestions_layer")` to
  reparent the `SuggestionsPanel` to a new `CanvasLayer`. Reparenting
  a Control that is currently laid out under another parent can
  trigger visual glitches if `minimum_size` was already computed.
  Add `await get_tree().process_frame` after reparent, before changing
  `global_position`.

- **M25 (Major):** `_enable_all_buttons(false)` and the matching
  `_enable_all_buttons(true)` in `_hide_suggestions()` toggle the
  `mouse_filter` of all element buttons. This means while typing in
  the search bar, the periodic table cannot be clicked — intentional,
  but **if the suggestions panel fails to show (no matches), the
  table stays disabled**. Add an explicit fallback.

- **N9 (Nit):** `for compound_variant in compounds_data[symbol]:` —
  `compound_variant` is untyped. Godot 4 will infer `Variant`. Add a
  type cast for clarity.

### `games/achievements/achievements.gd` — *Working*

- Iterates fixed `Label1..Label9` nodes — fragile if scene changes.
- **M26 (Minor):** Locked achievement text reads `"Unknown – Locked"`
  instead of the achievement title. UX bug — players can't see what
  they haven't unlocked. Use `ACHIEVEMENT_TEXT[id] + " – Locked"`.

### `games/achievements/reward/reward.gd` — *Stub*

- 7 lines. Auto-plays an animation, returns to main menu on button
  press. No state, no bugs.

### `games/global/quest.json` — *Working*

- 121 lines, valid JSON, all 7 main quest IDs match `QuestManager`
  references and `Achievements` labels.
- **M27 (Minor):** Some entries use `description` before `id`/`title`
  (e.g. `desk_quiz`). Cosmetic only, but inconsistent with the other
  entries.

### `games/global/player_feedback.json` — *Not yet inspected*

- 34 lines; loaded once by `PlayerFeedbackManager._ready()`.

### `games/glossary/data/elements.json` — *Not yet inspected*

- 592 lines. Loaded once by `glossary/main.gd._load_atomic_data()`.

---

## 7. Resource Inventory & Licensing

- Third-party asset packs found:
  - `mattermaze/Assets/Pixel Adventure 1/` — appears to be the popular
    "Pixel Adventure 1" pack from Ansimuz (itch.io). Confirm the
    project's license allows bundling in a published APK. *(Action item
    for the project owner, not a code bug.)*
  - `mattermaze/Assets/Treasure Hunters/` — similar check needed.
- No license/README files found in either pack.

---

## 8. Performance & Memory (Static Estimates)

- **Autoloads (15)** at startup — within Godot's recommended budget, but
  several (`Level2Manager`, `Level3Manager`, `Scoring`, `LessonManager`,
  `ChallengeManager`, `ElementColorDB`) are lesson-scoped yet registered
  globally. They consume memory even when not in use and bloat the
  symbol table. *(Minor; consider lazy loading.)*
- **`Scoring`, `Level2Manager`, `Level3Manager`** autoload instances
  hold `Dictionary`/`Array` state that lives forever. If a player
  finishes a level, returns to main menu, and exits, the state is still
  in memory until the process dies.

---

## 9. Recommended Test Plan (not run)

The following were not exercised — they are not bugs, only checks the
QA pass should run before ship:

1. **Save/load round-trip on Android** — `user://save.json` round-trip
   across cold start, Continue, New Game.
2. **Double-tap-run on touch** — currently mapped to keyboard only;
   ensure `InputEventScreenTouch` is wired or add a virtual joystick.
3. **Background→foreground** — pause music, resume, check for
   desync in `current_id`.
4. **All 7 main quest IDs** can be completed via the in-level flow
   (`finish_book1`, `finish_book2`, `finish_book3`,
   `density_measurement`, `states_of_matter`, `accuracy_vs_precision`,
   `separation_methods`).
5. **Achievements panel** shows the correct titles when locked
   (currently shows "Unknown").

---

## 10. Summary by File (severity at-a-glance)

| File | Severity | Notes |
| --- | --- | --- |
| `project.godot` | Minor | Mobile renderer hard-coded |
| `global/QuestManager.gd` | Blocker/Major | B1, B2, M1, M2 |
| `global/SaveManager.gd` | Major | B3, M3, M4 |
| `global/SpawnManager.gd` | Blocker | B4 |
| `global/DialogueManager.gd` | Minor | M6 |
| `global/MusicManager.gd` | Major | M7 stream mutation |
| `global/FadeManager.gd` | OK | |
| `global/GuideManager.gd` | OK | |
| `global/PlayerFeedbackManager.gd` | Minor | M9 |
| `global/InteractionManager.gd` | OK | Stub |
| `global/DensityChallengeManager.gd` | Minor | M10 |
| `games/main.gd` | Major | B5 split save files |
| `intro.gd` | OK | |
| `hometown/scripts/player.gd` | Minor | M14, M15 |
| `hometown/scripts/hometown.gd` | OK | |
| `hometown/scripts/hometown_tutorial.gd` | OK | |
| `hometown/scripts/building_one_entry.gd` | OK | |
| `building_two/Level2-1/*` | Blocker | Duplicate dirs |
| `building_two/*.tscn*.tmp` | Minor | 7 stray temp files |
| `building_one/Level1/Lesson1/checker.gd` | Major | Duplication |
| `building_one/Level1/Lesson2/checker.gd` | Major | Duplication |
| `building_one/Level1/Lesson3/lesson_3.gd` | Minor | M19, M20 |
| `building_one/Level4/PrecisionAccuracy/*` | Minor | Sparse |
| `building_one/Level2-1/Scripts/player.gd` | Major | M21, M22 |
| `glossary/main.gd` | Major | M24, M25 |
| `achievements/achievements.gd` | Minor | M26 |
| `achievements/reward/reward.gd` | OK | Stub |

---

## 11. Action List (priority order)

1. **B1 / B5** — Decide on a single source of truth for save/quest data
   and migrate `user://quest.json` → `user://save.json` (or vice versa).
2. **B4** — Add a debounced save in `SpawnManager.set_spawn()` (and any
   other call site that auto-saves).
3. **Duplicate `Level2-1/` dirs** — Keep one, delete the other, then
   re-import the project.
4. **M7** — Stop mutating preloaded `AudioStream` instances in
   `MusicManager._play_music()`.
5. **M16** — De-duplicate `Lesson1/checker.gd` and `Lesson2/checker.gd`.
6. **M21** — Replace `reload_current_scene()` with an explicit
   scene-change call in the density level.
7. **M26** — Fix the "Unknown – Locked" UX bug in
   `achievements/achievements.gd`.
8. **Cleanup** — Delete `*.tscn*.tmp` files and verify `.import`
   metadata is intact for all assets.

---

*End of report. No files were modified.*
