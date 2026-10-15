# Responsive layout execution checklist

Use this checklist with `tasks/responsive-layout-plan.md`. Keep unrelated
worktree changes and the local Auvrynt bridge untouched.

- [x] Responsive service and orientation guard added.
- [x] Safe-area and fixed-aspect primitives added.
- [x] HUD, camera, and touch adapters added.
- [x] Project stretch/orientation/autoload settings updated.
- [x] 24-scene and eight-viewport manifests added.
- [x] Layout math and shared-touch unit contracts added.
- [x] Canonical menu, glossary, hub, lesson, density, and states scenes wired.
- [x] Canonical glossary UID collision and back-signal compatibility repaired.
- [x] Regenerate `tasks/responsive-runtime-baseline.md` with 192/192 passes.
- [x] Run persistence and menu/audio contracts after final scene edits.
- [x] Run headless resource import (`--import --quit`; editor layout warnings remain documented).
- [x] Run Android and Web exports and archive/resource validation.
- [x] Capture 24 reference screenshots at 1280x720 under ignored build output.
- [x] Perform final `git diff --check` and confirm no `.godot/` edits.
- [ ] Test a physical Android landscape device with a cutout.
- [ ] Test a resizable Web window in Chrome.
