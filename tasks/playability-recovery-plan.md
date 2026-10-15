# ChemQuest2 playability recovery

Status: implementation complete for the desktop/headless recovery gates;
physical Android and browser journey sign-off remains a release follow-up.

This plan records the route-level fixes that sit on top of the earlier refactor
and responsive-layout work. It intentionally leaves `.godot/`, the Auvrynt
bridge, legacy duplicate trees, and unrelated worktree changes untouched.

## Failure model

- The Hometown camera used a guessed rectangle. Its bottom limit clipped the
  default player and its side limits hid the Building One return spawn.
- Scene-local fade rectangles were freed during Density and States changes, so
  a later transition could stall or change scenes without a fade.
- Lesson 3 awarded the wrong quest (`after_book2` / `desk_quiz`) instead of
  `finish_book3` followed by `after_book3`.
- Building One had the misspelled `seperation_spawn` marker while callers used
  `separation_spawn`.
- Canonical States resources loaded player/gate scripts from the nested legacy
  tree, and the intended tutorial scene had no route from the States panel.
- Existing smoke tests only proved that scenes could instantiate; they did not
  prove movement, interaction, completion, scene transitions, or persistence.

## Recovery decisions

### Persistent transitions

`FadeManager` owns a `CanvasLayer` and full-rect overlay for the entire process.
`fade_and_change()` rejects missing paths and concurrent requests, emits
`transition_started` / `transition_finished`, waits one rendered frame after a
successful scene change, and flushes a destination save before the change.
`setup()` remains a compatibility no-op so older scenes do not retain a freed
scene-local reference. `--route-test` enables zero-duration fades and in-memory
save snapshots.

### Spawn contract

`SpawnManager` canonicalizes `seperation_spawn` to `separation_spawn`, validates
pending markers against a destination hub, and falls back to that hub's
`default` marker with a warning. Hub scripts resolve a pending spawn first,
then a saved resume spawn, clear the one-shot value, and persist the resolved
marker. This prevents invalid aliases from being replayed indefinitely.

### Progression contract

Chapter One follows this ordered quest chain:

```text
find_wiz → read_books → finish_book1 → after_book1 → finish_book2
→ after_book2 → desk_quiz → after_desk_quiz → finish_book3 → after_book3
→ separation_methods → separation_methods_after → accuracy_vs_precision
→ after_accuracy_vs_precision → find_christofe → density_measurement
→ after_density_measurement → states_of_matter → after_states_of_matter → reward
```

Density and States record level identities, ignore replays, and complete their
quest only after level 3. Lesson 3 now completes `finish_book3` and exposes
`after_book3`. Save writes are flushed by the transition service before leaving
a completion scene.

### States route

The playable States route is:

```text
Building Two States panel → States tutorial (`main.tscn`)
→ States level 1 → States level 2 → States level 3 → Building Two
```

Canonical player, gate, and final-gate resources no longer depend on the nested
duplicate scripts. `StateTouchControls` exposes left, right, jump, Solid,
Liquid, and Gas buttons and presses the existing input actions, preserving
keyboard behavior and multi-touch semantics.

## Implementation checklist

- [x] Capture failing contracts for camera bounds, fade ownership, Lesson 3,
  spawn spelling, and canonical States resources.
- [x] Set verified Hometown world limits to `(-2724, -2704)-(2459, 2795)`.
- [x] Add persistent fade ownership, transition guards/signals, and test mode.
- [x] Normalize and validate spawn aliases; repair hub fallback persistence.
- [x] Correct Lesson 3 quest output and null-safe optional QuestPanel update.
- [x] Move Density completion to level 3 and make gate transitions persistent.
- [x] Make States level 1 enter through the tutorial and add touch controls.
- [x] Remove active-route direct scene changes that bypass `FadeManager`.
- [x] Add static and headless route contracts under `tests/routes/`.
- [x] Add the runtime Hometown camera/spawn visibility matrix (32 viewport /
  spawn combinations).
- [x] Complete the active scene and responsive viewport matrices (24/24 and
  192/192), plus persistence/menu/audio/layout/touch contracts.
- [x] Re-export Android/Web after the automated route gates are green.
- [ ] Complete rendered keyboard/mouse/touch journey runs on desktop, Web, and
  a physical Android landscape device.

## Verification commands

```powershell
powershell -ExecutionPolicy Bypass -File tests/unit/run_playability_contract.ps1
powershell -ExecutionPolicy Bypass -File tests/routes/run_route_contract.ps1
powershell -ExecutionPolicy Bypass -File tests/routes/run_route_interaction.ps1
powershell -ExecutionPolicy Bypass -File tests/routes/run_camera_spawn.ps1
powershell -ExecutionPolicy Bypass -File tests/unit/run_persistence_contract.ps1
powershell -ExecutionPolicy Bypass -File tests/unit/run_menu_audio.ps1
powershell -ExecutionPolicy Bypass -File tests/unit/run_responsive_layout.ps1
powershell -ExecutionPolicy Bypass -File tests/unit/run_responsive_touch.ps1
powershell -ExecutionPolicy Bypass -File tests/smoke/run_scene_matrix.ps1
powershell -ExecutionPolicy Bypass -File tests/smoke/run_responsive_matrix.ps1
```

The route runners use `--route-test`; they never overwrite the developer's
`user://save.json`.
