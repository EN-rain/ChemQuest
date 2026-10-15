# ChemQuest2 complete route QA plan

The route manifest at [`tests/routes/routes.json`](../tests/routes/routes.json)
is the source of truth for the 24 active scenes and 78 player-facing edges.
Each edge declares its quest/progress precondition, pending spawn, input driver,
expected scene/spawn, quest/progress delta, and supported inputs.

## Test layers

### Static route contract

Run `tests/routes/run_route_contract.ps1`. It verifies:

- every active PackedScene exists and loads;
- every route endpoint is active and every non-terminal scene has an exit;
- every player-facing scene has an incoming route (except `intro`);
- every route has a driver, precondition, expected delta, and input set;
- spawn aliases normalize to the canonical names;
- connected scene signal targets and methods exist;
- `quest.json` matches the ordered Chapter One contract;
- active scenes do not load quarantined nested duplicate trees.

### Headless interaction contract

Run `tests/routes/run_route_interaction.ps1`. It calls the real service and
scene APIs to prove:

- legacy spawn aliases and invalid hub markers resolve deterministically;
- FadeManager owns a persistent overlay and rejects invalid transitions;
- Density and States complete exactly once at level 3, with replay protection;
- Lesson 3 pass output is `finish_book3` + `after_book3`;
- the six States touch controls press/release the existing actions and preserve
  the 72-design-pixel touch target;
- canonical States player/gate resources are independent of legacy scripts;
- SaveManager captures the resulting document in memory in route-test mode.

### Rendered journey tests

Use the manifest with the existing smoke/responsive runners and capture route
checkpoints. For each journey, send real keyboard, mouse, and touch events and
assert the resulting scene, spawn, quest delta, progress delta, and save file.
Scene instantiation alone is not route coverage.

The focused camera gate is `tests/routes/run_camera_spawn.ps1`; it runs every
Hometown spawn against all supported viewport sizes and verifies that the real
player collision rectangle is inside the camera's visible world rectangle.

## Journey matrix

### Entry and utilities

- Intro START, New Game reset, Chapter One selection, cutscene Next/Skip.
- Continue with no save, valid save, legacy spawn alias, corrupt JSON, and
  invalid scene fallback.
- Glossary details/search/no-result/zoom/back, About/back, Achievements/reward,
  and clean exit save flush.

### Hubs

- Hometown default, Building One return, Building Two return, and resumed-save
  spawns; movement in all directions on keyboard and touch.
- Building entries/exits, menu open/cancel/confirm, lock prompts, dialogue input
  lock/unlock, and one-shot reward redirect.
- Verify camera framing and player visibility at 854×480, 1024×768, 1280×720,
  1280×800, 1920×1080, 2400×1080, 2560×1080, and portrait guard 720×1280.

### Building One

- Wizard returns advance one quest at a time.
- Map gates lock/unlock at the declared quest boundaries.
- Lessons 1–3, Desk Quiz, Separation, and Precision/Accuracy each cover guide
  open/next/close, valid/invalid answer, 11-vs-12 threshold, timeout, retry,
  correction, cancel/back, continue, and return spawn.
- Precision/Accuracy additionally covers misses, every target, hit-marker
  alignment, score accumulation, final results, retry, and return.

### Building Two

- Christofe intro, Density return, and States return conversations each advance
  once and persist before leaving.
- Density levels cover movement, jump, pickup/carry/drop, wrong object, correct
  object, replay, automatic next level, and final return.
- States tutorial covers Solid/Liquid/Gas keyboard and touch switching without
  progress increment; levels cover invalid/valid state gates, hazards, level
  changes, replay, and final return.
- Force-close/relaunch after every hub and level boundary; verify no double
  progress or duplicate transition.

## Platform and responsive pass

Landscape runs must keep the player/objective visible, keep HUD/touch controls
off required interactables, align pointer coordinates with drag targets, and
keep cameras inside valid world bounds. At 720×1280, gameplay is blocked by the
rotation overlay; restoring a landscape size must restore input and focus.

## Release gates

Latest automated recovery run (2026-09-08) is green: static route contract
24/24 scenes and 78/78 edges, headless interaction contract 38/38 checks,
Hometown camera/spawn visibility 32/32 combinations, active scene smoke 24/24,
and responsive scene matrix 192/192. Export packaging also completed for the
Android and Web presets; the pre-existing duplicate-UID and local Auvrynt
listener warnings remain documented in `tasks/export-validation.md`.

Automated:

- static route contract 100%;
- headless interaction route contract 100%;
- persistence, menu/audio, 24-scene smoke, and responsive matrix green;
- headless import with no active-route script/resource failures;
- Android and Web exports contain all route dependencies.

Manual:

- one fresh desktop campaign to Reward;
- one physical Android landscape campaign, including simultaneous movement and
  action touches;
- Web Chrome run at minimum, reference, and wide-phone sizes;
- Continue after every quest/level boundary and force-close/relaunch checks.

The build is playable only when no player-facing edge dead-ends, no required
quest needs save editing, every entered scene has a working exit, the player is
visible/responds within two rendered frames after spawn, repeated input cannot
duplicate transitions/progress, and runtime logs contain no active-route
script, NodePath, transition, or resource errors.
