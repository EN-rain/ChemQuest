# ChemQuest2 responsive layout implementation plan

## Scope and outcome

This plan makes the 24 canonical active scenes usable at landscape phone,
tablet, desktop, ultrawide, and Web window sizes without changing gameplay,
save data, input action names, or authored world coordinates. The project keeps
the 1280x720 design space and pixel-art look; ordinary menus use anchors and
containers, while tightly authored scientific interfaces use a uniformly scaled
surface.

The legacy root `glossary/` tree and nested duplicate density/matter-maze
feature trees are intentionally outside this pass. They remain available for
the separate ownership and retirement decisions recorded in `tasks/plan.md`.

## Contract

- Design viewport: 1280x720.
- Stretch: `viewport` mode with `expand` aspect policy.
- Supported landscape test floor: 854x480.
- Android: landscape orientation.
- Web/desktop portrait: a blocking “Please rotate your device to landscape”
  overlay is shown; no gameplay is made to fit portrait.
- Desktop minimum window: 854x480 when the platform exposes a resizable PC
  window.
- Safe-area fallback: 24 design pixels on each edge when platform cutout data
  is unavailable.
- Text: at least 18 design pixels for ordinary interface copy.
- Touch targets: at least 72x72 design pixels, with movement at bottom-left and
  actions at bottom-right.
- Decorative art may crop to cover; instructional/scientific art must preserve
  its complete content.
- `.godot/` is generated state and is never edited by this work.

## Architecture

### Shared service

`games/global/ResponsiveLayout.gd` is the `ResponsiveLayout` autoload. It
tracks logical viewport size, converted display safe rectangle, landscape state,
and emits `layout_changed(viewport_size, safe_rect)` after root-window resize.
It owns the high-layer orientation guard and applies the desktop minimum size.
The safe-area conversion uses `DisplayServer.get_display_safe_area()` when
available and a 24-pixel fallback otherwise.

### Reusable primitives

- `games/global/ResponsiveSafeArea.gd` (`ResponsiveSafeArea`) is a full-rect
  `MarginContainer` that mirrors the service safe rectangle.
- `games/ui/FixedAspectSurface.gd` (`FixedAspectSurface`) centers and uniformly
  scales one authored child using the limiting available axis.
- `games/global/ResponsiveHudLayout.gd` adapts shared shell controls (back,
  music/map, quest, dialogue, feedback, lesson controls, and result panels).
- `games/global/ResponsiveTouchLayout.gd` keeps shared and embedded touch
  buttons inside safe-area corners while retaining existing actions.
- `games/global/ResponsiveCameraBounds.gd` reapplies authored `Camera2D`
  limits on layout changes so wider windows do not reveal invalid world space.

## Phase checklist

### Phase 1 — Regression harness

- [x] Add the 24-scene manifest and eight-viewport manifest.
- [x] Add critical-control checks for existence, nonzero size, safe-rectangle
  containment, clipping, portrait guard, and touch target size.
- [x] Add layout math unit tests.
- [x] Add the shared mobile-control contract test.
- [x] Regenerate the final 24x8 report after all layout changes (192/192).

### Phase 2 — Project configuration

- [x] Keep 1280x720 viewport design size.
- [x] Keep `viewport` stretch and `expand` aspect settings.
- [x] Set explicit landscape handheld orientation.
- [x] Register `ResponsiveLayout` as an autoload.
- [x] Keep Android edge-to-edge disabled for this pass.
- [x] Leave generated `.godot/` files untouched.

### Phase 3 — Menus and information screens

- [x] Anchor intro, main menu, cutscene, achievements, and reward content to
  the safe area.
- [x] Make achievement/glossary content tolerate long copy.
- [x] Scale the canonical periodic table in an authored 1280x720 surface.
- [x] Keep search, suggestions, element details, and back controls independent
  of the table surface and inside the safe rectangle.
- [x] Preserve canonical glossary script ownership and legacy tree boundaries.

### Phase 4 — Hub HUDs and panels

- [x] Adapt hometown, Building One, and Building Two shell controls.
- [x] Keep dialogue/feedback panels bounded to the safe-area width and bottom.
- [x] Preserve interaction, quest, map, and level-panel NodePaths.
- [x] Add authored camera bounds for each hub world.

### Phase 5 — Lesson interfaces

- [x] Adapt Lessons 1–3, Level 2, Level 3, and Precision/Accuracy HUDs.
- [x] Preserve gameplay surfaces and drag/drop coordinate relationships.
- [x] Anchor timers, score, guide, correction, result, and navigation panels.
- [x] Keep Precision/Accuracy fire artwork and hit targets inside the safe area.

### Phase 6 — Density, states, cameras, and touch

- [x] Adapt the three density scenes and matter-maze entry HUD.
- [x] Add responsive shared mobile controls and preserve input actions.
- [x] Add camera limits for the hub and density worlds.
- [x] Keep fade overlays full-rect and leave physics/world coordinates intact.
- [x] Complete final keyboard and simulated-touch regression at all viewports.

### Phase 7 — Hardening and documentation

- [x] Document primitives, orientation policy, matrix, and future-scene rules.
- [x] Add reproducible unit, touch, scene, and matrix commands.
- [x] Run final import, exports, reference screenshots, and archive checks.
- [x] Review final diff for `.godot/` or unrelated-worktree changes.

## Verification matrix

| ID | Size | Coverage |
|---|---:|---|
| minimum | 854x480 | smallest supported landscape window |
| tablet | 1024x768 | 4:3 tablet |
| reference | 1280x720 | original authored layout |
| 16:10 | 1280x800 | desktop/tablet |
| full_hd | 1920x1080 | standard desktop |
| wide_phone | 2400x1080 | modern wide phone |
| ultrawide | 2560x1080 | ultrawide desktop |
| portrait_guard | 720x1280 | orientation overlay |

For every entry, verify safe-area containment, readable text, non-overlap,
uncropped instructional art, touch reachability, aligned scaled input,
bounded cameras, navigation, and persistence.

## Commands

```powershell
powershell -ExecutionPolicy Bypass -File tests/unit/run_responsive_layout.ps1
powershell -ExecutionPolicy Bypass -File tests/unit/run_responsive_touch.ps1 -Width 854 -Height 480
powershell -ExecutionPolicy Bypass -File tests/smoke/run_scene_matrix.ps1
powershell -ExecutionPolicy Bypass -File tests/smoke/run_responsive_matrix.ps1
```

Headless editor import and Android/Web export commands are documented in
`README.md`; generated packages belong under ignored `tasks/builds/` only.
