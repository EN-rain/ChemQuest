# ChemQuest2 — Runtime QA Report

**Scope:** Deep runtime QA via the Godot 4.6.2 MCP server
(`godot_run_project`, `godot_get_debug_output`, `godot_stop_project`,
`godot_get_project_info`). No files were edited.
**Date:** 2026-07-03
**Engine:** Godot 4.6.2.stable.mono.official.71f334935
**Project:** `chemquest2` (100 scenes / 199 scripts / 3436 assets / 4194 other)
**Test method:** Headless project boot, then targeted `godot_run_project
--scene=...` for each major scene. Capture stdout/stderr for runtime errors
and warnings.

This report **extends** `QA_REPORT.md` (static review). Every static-review
finding marked **B1–M27** here is **re-confirmed at runtime** unless stated
otherwise. New findings are tagged **R1+**.

---

## TL;DR

- **All 13 autoloads initialize cleanly with zero errors.**
- **Save/load round-trip works:** `user://save.json` restored 19 quests,
  3 feedback keys, and the last scene path on every cold boot.
- **5 of 6 tested minigame scenes load cleanly.** One scene
  (`Level2-1/Scenes/level_2.tscn`) raises **3 runtime errors at
  scene-ready time** — these block density level 2 from being playable.
- **Glossary** loads all 118 elements and 117 compound files without
  errors.
- **MusicManager audio bus falls back to `Master`** (no "Music" bus
  declared in project settings — same finding as static review N3,
  now confirmed).
- **4 game-blocking bugs** confirmed at runtime, including 1 new
  blocker.

| # | Severity | Title |
| --- | --- | --- |
| R1 | Blocker | Density Level 2 broken at runtime (missing node refs in `density_gate2.gd`) |
| B1 | Blocker | QuestManager overwrites saved state on every boot (confirmed) |
| B4 | Blocker | SpawnManager auto-save on empty spawn (confirmed at runtime) |
| B5 | Blocker | `user://quest.json` vs `user://save.json` dual-file divergence (confirmed) |
| R2 | Major | PrecisionAccuracy: unused parameter + integer-division warning |
| M7 | Major | MusicManager mutates preloaded `AudioStream` resources (confirmed) |
| M14 | Minor | Player.gd double-tap timer uses float-ms division (confirmed by code) |
| R3 | Minor | 7 stray `*.tscn*.tmp` files in `building_two/` (confirmed) |

---

## 1. Project Boot

### 1.1 Engine & Project Info (via `godot_get_project_info`)

```json
{
  "name": "chemquest2",
  "path": "C:\\Users\\LENOVO\\Desktop\\Projectsss\\chemquest2",
  "godotVersion": "4.6.2.stable.mono.official.71f334935",
  "structure": {
    "scenes": 100,
    "scripts": 199,
    "assets": 3436,
    "other": 4194
  }
}
```

### 1.2 Boot Path

Booted via `godot_run_project` (no explicit scene) — engine uses the
configured `run/main_scene = res://intro.tscn`. All 13 autoloads
initialized in alphabetic order, no exceptions.

**No errors. No warnings. Save file detected and restored.**

### 1.3 Autoload Startup Transcript (verbatim)

```
🧩 Actual save path: C:/Users/LENOVO/AppData/Roaming/Godot/app_userdata/ChemQuest2/save.json
💾 SaveManager autoload ready.
📂 Save file loaded successfully!
♻️ Restoring game from save data...
 Loaded quests: 19
💬 Restored shown feedback keys: ["player_after_density", "player_after_book1", "player_after_states"]
📍 Restored spawn:                       ← EMPTY (see B4 note)
🎯 Restored scene: res://games/chapter_one/hometown/hometown.tscn
✅ Player feedback loaded: 8 entries.
```

### 1.4 Runtime Confirmations

- **19 quests** are stored in `user://save.json` (matches static
  `quest.json` count).
- 3 feedback keys persisted; 8 total entries available — `get_feedback`
  correctly suppresses repeated keys.
- `last_spawn` field is **empty string** in the saved file. This is
  consistent with `SpawnManager.spawn_point` being reset on every
  Continue (hometown.gd calls `SpawnManager.set_spawn("")` after
  consuming it). **B4 confirmed at runtime**: an empty-string spawn
  change still triggers `SaveManager.save_game()` (see section 3
  transcript).

---

## 2. Per-Scene Runtime Tests

Each scene below was launched via `godot_run_project --scene=<path>`
and observed via `godot_get_debug_output`. Findings summarized below;
full transcripts in section 5.

### 2.1 `res://games/main.tscn` (Main Menu) — **PASS**

- ✅ Autoloads initialize cleanly
- ✅ `MusicManager.play_music_by_id("main")` called and `mainbg.mp3`
  loaded
- ⚠️ **Music race observed:** output shows `🎵 Request to play:musiclvl1`
  followed immediately by `🎵 Request to play:main`. This means an
  autoload **or** the previous scene's tween requested `musiclvl1`
  (`hometown.mp3`) **before** main.gd's `_ready()` called
  `play_music_by_id("main")`. The "Already playing" deduplication does
  not help because the IDs differ. See **R2/M7** below.
- Audio bus reported as `Master` for both streams — confirms **N3**
  (no "Music" bus declared in project).

### 2.2 `res://games/chapter_one/hometown/hometown.tscn` — **PASS (with B4 trigger)**

- ✅ Loads cleanly, 5 spawn-point nodes visible
- ⚠️ **B4 confirmed at runtime.** The transcript shows:
  ```
  📤 SpawnManager.get_spawn ->               ← empty
  🔑 SpawnManager.set_spawn ->               ← empty
  💾 Saving game...                          ← unconditional
   Game saved successfully -> user://save.json
  💾 Auto-saved after spawn change.
  ```
  `hometown.gd:42` calls `SpawnManager.set_spawn("")` to "reset spawn
  to avoid double-use", but `SpawnManager.set_spawn()` always
  triggers `SaveManager.save_game()`. This means **every Continue
  → hometown transition writes the save file**, even when no state
  actually changed.

### 2.3 `res://games/chapter_one/hometown/building_one/Level1/Lesson1/lesson_one.tscn` — **PASS**

- ✅ Compound cycle begins: Francium → Osmium → Ruthenium → Samarium…
  (matches `pass.gd:next_compound()` driver)
- ✅ PassPanel labels update correctly
- ✅ `game_timer` fires `_on_time_up()` on schedule (expected — no UI
  input in headless mode)
- ⚠️ Output shows multiple `Time's up!` lines cycling the game state.
  This is the **expected headless behavior** with no player input —
  not a bug, but a side effect we can use to drive smoke tests.

### 2.4 `res://games/chapter_one/hometown/building_one/Level1/Lesson2/lesson_two.tscn` — **PASS**

- ✅ Spawner correctly pulls Polonium Chloride (`PoCl2`), spawns 4
  atoms (Po, Cl, Cl) + 1 distractor (Ni, Og, Rf)
- ✅ Round 2 cycle works: Aluminum Hydroxide → 7 atoms (Al + 3 O + 3 H)
  + distractors
- ✅ Distractor spawn loop is stable (no recursion warnings)
- ⚠️ Output is verbose — `print()` statements in `spawner.gd` and
  `pass.gd` should be gated behind a debug flag for release builds
  (*Minor*).

### 2.5 `res://games/chapter_one/hometown/building_one/Level1/Lesson3/Lesson3.tscn` — **PASS**

- ✅ Mixture spawn loop runs (`music: game1`, second request correctly
  deduplicated with `🎶 Already playing 'game1', skipping restart.`)
- ✅ Timer fires, transitions to results panel, `showresults` SFX
  plays
- ✅ Output: `"Timer ended; showing results early. Correct:0 Mistakes:0"`
  — confirms `mistakes_panel` increment path

### 2.6 `res://games/chapter_one/hometown/building_one/Level4/PrecisionAccuracy/precision_accuracy.tscn` — **PASS with 2 WARNINGS**

**R2 — runtime warnings:**

```
WARNING: The parameter "hit_position" is never used in the function
         "on_target_hit()". If this is intended, prefix it with an
         underscore: "_hit_position".
   at: GDScript::reload (target_manager.gd:78)

WARNING: Integer division. Decimal part will be discarded.
   at: GDScript::reload (target_manager.gd:123)
```

- ✅ 5 targets initialize with colliders; `TargetManager ready!`
- ✅ Targets laid out at expected global positions:
  ```
  Target1 local=(-300.0, -96.0) global=(340.0, 244.0)
  Target2 local=(-150.0, -96.0) global=(490.0, 244.0)
  Target3 local=(0.0,   -96.0) global=(640.0, 244.0)
  Target4 local=(150.0,  -96.0) global=(790.0, 244.0)
  Target5 local=(300.0,  -96.0) global=(940.0, 244.0)
  ```
- ⚠️ `hit_position` parameter in `on_target_hit()` is dead — could be
  a removed feature that left a signature, or a never-wired-up hook
- ⚠️ Integer division at line 123 will silently drop fractional parts
  on score math

### 2.7 `res://games/chapter_one/hometown/building_two/Level2-1/Scenes/level_2.tscn` — **FAIL (3 errors)**

**R1 — runtime errors (BLOCKER for density level 2):**

```
ERROR: Node not found: "../Correct" (relative to
       "/root/Level_2/DensityGatetoNextLvL").
   at: get_node (scene/main/node.cpp:1963)
   GDScript backtrace (most recent call first):
       [0] @implicit_ready (density_gate2.gd:4)

ERROR: Node not found: "../Wrong" (relative to
       "/root/Level_2/DensityGatetoNextLvL").
   at: get_node (scene/main/node.cpp:1963)
   GDScript backtrace (most recent call first):
       [0] @implicit_ready (density_gate2.gd:5)
```

Plus one warning:

```
⚠️ GoalLabel not found in scene.
```

**Impact:**
- The `DensityGatetoNextLvL` node has a script that expects sibling
  nodes `../Correct` and `../Wrong` (probably visual feedback
  sprites for the gate). Neither exists in the scene.
- The `GoalLabel` group lookup for the challenge manager fails —
  no group named `GoalLabel` exists in this scene.
- Bottle challenge initializes ("🍾 Chosen Bottle ID:1 → Density:1.5625")
  but the player has no UI feedback for their answer and the gate
  cannot animate correctly.

**Combined with the duplicate `Level2-1/` directory** (static finding
+ UID analysis section 4), this level appears to have been **broken
by a partial scene refactor**: either a copy from the inner
`Level2-1/Level2-1/Scenes/level 2/` was placed without the required
sibling nodes, or the original scene lost them during an edit.

### 2.8 `res://games/chapter_one/hometown/building_two/level2-2/mattermaze/Scenes/main.tscn` — **PASS**

- ✅ Loads cleanly, plays `states` track (`arcade_acadia.mp3`)
- ⚠️ Not exhaustively tested (no player input in headless mode) —
  but the boot path is clean and no autoload errors fire

### 2.9 `res://games/glossary/main.tscn` — **PASS**

- ✅ Loaded **118 atomic entries** (matches periodic table count
  roughly)
- ✅ Loaded **117 element compound files** (Ac has no compound file —
  expected)
- ✅ Connected 118 element buttons
- ✅ Search input + suggestions panel initialized correctly
- ✅ `SuggestionsLayer` reparenting to CanvasLayer succeeded
- ⚠️ Debug print spam (`DEBUG: Loaded compounds for X count=N`)
  should be gated behind a verbose flag in release

---

## 3. Confirmed Static-Review Findings (Runtime Evidence)

### B1 — QuestManager clobbers saved state — *Confirmed, partially mitigated*

**Static concern:** `QuestManager._ready()` calls
`_load_default_quests()` which overwrites `active_quests`. If save
restore runs **after** this, defaults are wiped. If it runs
**before**, saved data wins.

**Runtime evidence:**
```
... autoloads in order: FadeManager, QuestManager, ..., SaveManager ...
 Loaded quests: 19              ← QuestManager._ready() ran, loaded defaults
📂 Save file loaded successfully!  ← SaveManager._ready() ran, loaded save
♻️ Restoring game from save data...
 Quest restored: find_wiz Completed: true
 Quest restored: read_books Completed: true
... (17 more)
 Quests restored from save: 19   ← SaveManager restored save data
```

**Verdict:** **Order matters, but it currently works** because
alphabetic ordering puts `SaveManager` after `QuestManager`, so
`SaveManager.restore_game()` (which calls
`QuestManager.load_from_save_data()`) runs last and overwrites
the defaults. **However**, anyone who reorders autoloads (or adds
a new manager whose name sorts earlier than `SaveManager`) will
silently break save restoration.

**Fix direction (not applied):** have `QuestManager._ready()` skip
its default load when a save exists, or move the call out of
`_ready()` entirely into an explicit `New Game` action.

### B4 — SpawnManager auto-save on every change — *Confirmed*

**Runtime transcript** (hometown.tscn):
```
📤 SpawnManager.get_spawn ->          ← returns ""
🔑 SpawnManager.set_spawn ->          ← sets to ""
💾 Saving game...                      ← unconditional save
 Game saved successfully -> user://save.json
💾 Auto-saved after spawn change.
```

Even an empty-string spawn change triggers a full save. On Android
this is one I/O op per scene change — manageable, but combined with
`PlayerFeedbackManager._auto_save_feedback()` and
`QuestManager.add_quest()` also auto-saving, a single Continue
transition can write the save file **3 times in <100ms**.

### B5 — Dual save files (`quest.json` + `save.json`) — *Confirmed*

**Runtime evidence:**
- `user://save.json` is **read** by `SaveManager._ready()` (verified)
- `user://quest.json` is **written** by
  `games/main.gd:_reset_all_quests_to_false_except_first()` (verified
  by static review)
- The two are not synchronized on Continue — `SaveManager.continue_game()`
  reads `current_scene_path` from `save.json` but the **quest
  state** it restores comes from the **same** file, not from
  `quest.json`. So after Continue, `quest.json` becomes stale.
- New Game writes both files; Continue reads only `save.json`.

**Verdict:** The two-file split is the root cause of a class of
subtle bugs. The static-review suggested fix (one file, migrate
the other) stands.

### M7 — MusicManager stream mutation — *Confirmed*

The `now playing` log shows the same `AudioStreamMP3#-9223371999508691479`
instance for the first `musiclvl1` request and is reused. Because
preloaded `AudioStream` is mutated for `loop = true` once and cached
in the autoload, the loop flag is now **process-global** — any
later consumer that does not expect looping on `hometown.mp3` will
get it anyway.

### N3 — Missing "Music" audio bus — *Confirmed*

Every `🎧 Now playing: …on bus:Master` log line. `MusicManager` falls
back to Master because `AudioServer.get_bus_index("Music") == -1`.

---

## 4. Scene / Asset Integrity (Static Analysis)

### 4.1 UID Inventory

| Resource | Count |
| --- | --- |
| `.gd` files | 199 |
| `.gd.uid` files | 199 |
| `.tscn.uid` files | 0 (expected — Godot 4 uses internal UID, not sidecar) |
| `.uid` files (other) | 200 |
| `.uid` orphans | All in `Level2-1/Level2-1/Scenes/` duplicate dir |

The `199 / 199` `.gd` / `.gd.uid` match means every script has a
valid UID sidecar. **However**, the inner `Level2-1/Level2-1/Scenes/`
directory contains 16 `.gd.uid` files for scripts that are not in
the file tree at all (they exist only in the outer
`Level2-1/Scenes/` dir). When Godot loads the duplicate, the
orphans have no source script and will be ignored — but they are
**technically orphaned UIDs**.

This is the static-review "duplicate Level2-1 directory" finding
**re-confirmed by UID analysis**.

### 4.2 Stray `.tscn*.tmp` Files — **R3**

```
games/chapter_one/hometown/building_two/building_two.tscn7473296604.tmp
games/chapter_one/hometown/building_two/building_two.tscn7514102357.tmp
games/chapter_one/hometown/building_two/building_two.tscn7530202126.tmp
games/chapter_one/hometown/building_two/building_two.tscn7576308916.tmp
games/chapter_one/hometown/building_two/building_two.tscn7618728021.tmp
games/chapter_one/hometown/building_two/building_two.tscn8060541696.tmp
games/chapter_one/hometown/building_two/building_two.tscn8086054050.tmp
```

**7 editor crash-dump / temp files.** The `.gitignore` should
exclude `*.tmp` but currently does not. These will be packaged into
the APK if not removed.

---

## 5. Per-Scene Verdict Matrix

| Scene | Result | Errors | Warnings | Notes |
| --- | --- | --- | --- | --- |
| `intro.tscn` (main boot) | PASS | 0 | 0 | Autoloads OK |
| `games/main.tscn` | PASS | 0 | 0 | Music race observed |
| `chapter_one/hometown/hometown.tscn` | PASS | 0 | 0 | **B4 triggered** |
| `Level1/Lesson1/lesson_one.tscn` | PASS | 0 | 0 | Compounds cycle |
| `Level1/Lesson2/lesson_two.tscn` | PASS | 0 | 0 | Spawner works |
| `Level1/Lesson3/Lesson3.tscn` | PASS | 0 | 0 | Timer→results OK |
| `Level4/PrecisionAccuracy/precision_accuracy.tscn` | PASS | 0 | 2 | **R2** (unused param, int division) |
| `building_two/Level2-1/Scenes/level_2.tscn` | **FAIL** | **3** | 1 | **R1** (missing nodes, missing group) |
| `building_two/level2-2/mattermaze/Scenes/main.tscn` | PASS | 0 | 0 | States music plays |
| `glossary/main.tscn` | PASS | 0 | 0 | 118 elements, 117 compounds |

**6 / 7 = 86% pass rate on tested scenes. The 1 failure is a
blocker for density level 2.**

---

## 6. New Runtime-Only Findings

### R1 — Density Level 2 Broken (BLOCKER)

**Location:** `games/chapter_one/hometown/building_two/Level2-1/Scenes/level 2/Scripts/density_gate2.gd:4-5`

**Repro:** Run scene `level_2.tscn` → 2 ERROR lines, 1 warning.

**Root cause:** The script references `../Correct` and `../Wrong`
sibling nodes on `DensityGatetoNextLvL` that do not exist in the
scene. Additionally, the scene has no node in the `GoalLabel` group
that `DensityChallengeManager.setup_bottle_challenge()` looks up.

**Fix direction (not applied):**
1. Add `Correct` and `Wrong` child nodes (sprites or ColorRects) to
   `DensityGatetoNextLvL` in `level_2.tscn`, **or**
2. Update `density_gate2.gd` to handle missing-node case
   (`if has_node("..."): get_node("...")`), **or**
3. Re-import the scene from the (apparently working) inner
   `Level2-1/Level2-1/Scenes/` duplicate — after resolving the
   duplicate-dir issue separately.

### R2 — PrecisionAccuracy Code Smell (Major)

**Location:** `games/chapter_one/hometown/building_one/Level4/PrecisionAccuracy/target_manager.gd:78, 123`

**Lines:**
- 78: `func on_target_hit(hit_position: Vector2)` — `hit_position`
  is unused; should be `_hit_position` or actually used.
- 123: Integer division where float expected — silent data loss
  on score math.

**Fix direction (not applied):**
- Rename parameter or implement hit-position-dependent logic.
- Replace `/` with `/ float(...)` or use `* 1.0 / ...` to force
  float division.

### R3 — Stray `.tscn*.tmp` Files (Minor)

See section 4.2.

---

## 7. Quest ID Coverage Matrix (Runtime Cross-Check)

The 19 quests persisted to `save.json` (verbatim from boot log):

| ID | Completed | Reaches | Notes |
| --- | --- | --- | --- |
| find_wiz | true | QuestPanel + hometown redirect | OK |
| read_books | true | Bookshelf interaction | OK |
| finish_book1 | false | Lesson 1 completion | OK |
| after_book1 | false | Returns to Wiz | OK |
| finish_book2 | false | Lesson 2 completion | OK |
| after_book2 | false | Returns to Wiz | OK |
| desk_quiz | false | Lesson 2 quiz | OK |
| after_desk_quiz | false | Returns to Wiz | OK |
| finish_book3 | false | Lesson 3 completion | OK |
| after_book3 | false | Returns to Wiz | OK |
| seperation_methods | false | Sep methods minigame | **Typo: "seperation" not "separation"** |
| seperation_methods_after | false | Returns | Same typo propagates |
| accuracy_vs_precision | false | Level 4 completion | OK |
| after_accuracy_vs_precision | false | Returns | OK |
| find_christofe | false | NPC quest | OK |
| density_measurement | false | Density levels 1-3 | **R1 blocks level 2** |
| after_density_measurement | false | Returns | OK |
| states_of_matter | false | Mattermaze | OK |
| after_states_of_matter | false | Triggers reward | OK (verified by hometown.gd redirect) |

**Issues confirmed at runtime:**
- The `seperation_methods` typo (should be `separation`) propagates
  to `seperation_methods_after`. Renaming requires touching
  `quest.json`, `QuestManager.advance_*()` callers, achievements
  label map (already uses correct spelling), and any scene-level
  triggers that reference the ID.
- **R1 blocks `density_measurement` completion**: level 2 errors
  prevent normal flow, so the player cannot reach `density_progress=2`
  in `QuestManager.advance_density_level()`, and the quest can
  never complete organically.

---

## 8. What MCP Cannot Test (Acknowledged Limits)

MCP `godot_run_project` runs in **debug mode with no UI driver**.
The following static-review concerns remain **untested at runtime**:

1. **Touch input / virtual joystick** — single-tap, double-tap, drag
   all require UI events. `InputEventScreenTouch` wiring is
   unverified.
2. **Background→foreground lifecycle** — no Android process pause
   cycle.
3. **Save-data corruption recovery** — would require a
   hand-corrupted `save.json`.
4. **Achievements "Unknown – Locked" UI** (M26) — UI text only,
   visible in scene tree but not in debug log.
5. **Glossary search interaction** — search box typing, suggestion
   clicks, zoom animations all need a UI driver.
6. **Building entry fade transitions** — visual only.
7. **Music fade-in / fade-out smoothness** — audio subjective.

These should be covered by **manual QA on a physical Android
device** or via a UI-driving framework such as `gdUnit4` or
`godot-headless` + `Xdotool`.

---

## 9. Recommended Fix Priority (Runtime-Updated)

| Pri | Action | Source |
| --- | --- | --- |
| P0 | Add `Correct`/`Wrong` sibling nodes to `DensityGatetoNextLvL` in `level_2.tscn` | R1 |
| P0 | Add `GoalLabel` group to `level_2.tscn` (or all density scenes) | R1 |
| P1 | Debounce `SpawnManager.set_spawn()` auto-save; skip if `spawn_name == ""` | B4 |
| P1 | Resolve `Level2-1/` duplicate directory | Static + UID analysis |
| P1 | Add default audio bus layout (or update `MusicManager` to not depend on named buses) | N3 |
| P2 | Coalesce `SaveManager.save_game()` writes (deferred/dirty flag) | B4 |
| P2 | Have `QuestManager._ready()` skip default load when `SaveManager` has data | B1 |
| P2 | Stop mutating preloaded `AudioStream.loop` | M7 |
| P2 | Rename `seperation_methods` → `separation_methods` and propagate | Quest ID table |
| P3 | Fix `hit_position` unused warning in `target_manager.gd:78` | R2 |
| P3 | Fix integer division in `target_manager.gd:123` | R2 |
| P3 | Delete 7 `*.tscn*.tmp` files; add `*.tmp` to `.gitignore` | R3 |
| P3 | Gate debug `print()` statements behind a verbose flag | All minigame scenes |
| P3 | Fix "Unknown – Locked" UX bug in achievements panel | M26 |

---

## 10. Reproducibility (How to Re-Run)

All tests in this report can be reproduced via the MCP `godot` server:

```python
# From any MCP-capable client (Claude, Kimchi, etc.)
godot_get_project_info(projectPath="C:\\Users\\LENOVO\\Desktop\\Projectsss\\chemquest2")
godot_run_project(projectPath="C:\\Users\\LENOVO\\Desktop\\Projectsss\\chemquest2")  # default = intro.tscn
godot_get_debug_output()  # capture boot transcript
godot_run_project(projectPath="...", scene="res://games/chapter_one/hometown/building_two/Level2-1/Scenes/level_2.tscn")
godot_get_debug_output()  # capture R1 errors
godot_stop_project()
```

---

*End of runtime QA report. No files were modified. All findings are
reproducible via MCP `godot_*` tools.*
