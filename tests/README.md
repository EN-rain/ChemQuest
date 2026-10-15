# ChemQuest2 test harness

The test harness is dependency-free and uses the Godot editor executable already installed on the machine.

## Scene smoke test

Run one scene by path:

```powershell
pwsh -File tests/smoke/run_scene_smoke.ps1 -ScenePath res://intro.tscn
```

The runner verifies that the resource exists, parses as a `PackedScene`, instantiates, and remains alive for a short readiness window. The wrapper returns a nonzero status for missing resources, parse/instantiation failures, timeouts, or Godot `ERROR` output.

Run the Phase 1 matrix and write the baseline report:

```powershell
pwsh -File tests/smoke/run_scene_matrix.ps1
```

Run the responsive viewport matrix after layout changes:

```powershell
pwsh -File tests/smoke/run_responsive_matrix.ps1
```

The responsive matrix covers 854x480, 4:3, 16:9, 16:10, Full HD, wide-phone,
ultrawide, and portrait-guard sizes. Its scene-critical node paths live in
`tests/smoke/responsive_scenes.json`.

Run the reusable mobile-control contract at a chosen viewport:

```powershell
pwsh -File tests/unit/run_responsive_touch.ps1 -Width 854 -Height 480
```

The touch contract checks the shared movement/action groups against the safe
rectangle, 72-pixel minimum target size, non-overlap, and portrait guard.

## Playability route contracts

The complete Chapter One route manifest and its static/headless checks live in
`tests/routes/`. Run these before treating scene smoke as a playable build:

```powershell
powershell -ExecutionPolicy Bypass -File tests/routes/run_route_contract.ps1
powershell -ExecutionPolicy Bypass -File tests/routes/run_route_interaction.ps1
powershell -ExecutionPolicy Bypass -File tests/routes/run_camera_spawn.ps1
```

The camera matrix covers all four Hometown spawns at every supported viewport
and verifies that the player's collision rectangle is inside the real camera
view. The interaction contract runs in `--route-test` mode and keeps save
snapshots in memory so the developer profile is not changed.

Capture the 1280x720 reference set (outputs are ignored under `tasks/builds/`):

```powershell
powershell -ExecutionPolicy Bypass -File tests/smoke/capture_responsive_reference.ps1
```

## Persistence contract tests

The focused persistence runner backs up any existing `user://save.json` and `user://quest.json`, runs its checks, and restores those files before exit:

```powershell
pwsh -File tests/unit/run_persistence_contract.ps1
```

The suite covers schema migration, invalid scene fallback, completed-level identity round-trips, replay protection, and the authoritative New Game reset.
