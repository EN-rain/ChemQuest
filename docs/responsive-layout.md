# Responsive layout guide

ChemQuest2 is authored at 1280x720 and supports landscape resizing from
854x480 through ultrawide desktop and modern wide-phone aspect ratios. The
project uses Godot's `viewport` stretch mode with `expand` aspect behavior, so
the authored design remains stable while the logical viewport grows.

## Runtime service

`ResponsiveLayout` is a project autoload. Read its `viewport_size`, `safe_rect`,
and `is_landscape` properties from a scene, and connect to
`layout_changed(viewport_size, safe_rect)` when a scene has custom layout work.
The service converts the platform display safe area into logical project
coordinates and falls back to 24 pixels per edge. On Web and desktop, portrait
windows are covered by a blocking rotate-device overlay. Android is configured
landscape-only.

## Choosing a layout strategy

Use ordinary `Control` anchors and Godot containers for menus, panels, text,
navigation, and HUD elements. Put those controls under `ResponsiveSafeArea`
when they should avoid cutouts and the minimum edge margin. Use
`FixedAspectSurface` only when relative positions are part of the authored
content—for example the periodic table, lesson diagrams, or tightly coupled
drag/drop art. It uniformly scales and centers the first child; it is not a
replacement for responsive containers.

Decorative backgrounds should be full-rect `TextureRect` nodes with a
keep-aspect-covered stretch mode. Scientific or instructional images should use
keep-aspect-centered behavior so labels and diagrams are never cropped. Use
`NinePatchRect` or themed `PanelContainer` for frames that need to expand.

## HUD, cameras, and touch

`ResponsiveHudLayout` is a small adapter for legacy scene shells. It preserves
serialized names and signals while placing back/menu controls at the safe
top-left, quest/map/music controls at the safe top-right, and dialogue or
feedback panels across the safe bottom. New scenes should prefer containers
instead of adding more positional adapters.

World cameras may use `ResponsiveCameraBounds` with an authored map rectangle.
Keep player and collision coordinates unchanged; reveal extra world only when
the authored bounds contain valid art and collision.

`ResponsiveTouchLayout` preserves the existing `left`, `right`, `jump`,
`pickup`, and `drop` input actions. Movement buttons are grouped at the
bottom-left and actions at the bottom-right. Normal textures must produce at
least 72x72 design pixels, and groups must remain inside `safe_rect`.

## Supported verification sizes

The automated matrix covers 854x480, 1024x768, 1280x720, 1280x800, 1920x1080,
2400x1080, 2560x1080, and 720x1280. The last size verifies only the portrait
guard and safe service state; gameplay remains landscape-only.

Run the full matrix with:

```powershell
powershell -ExecutionPolicy Bypass -File tests/smoke/run_responsive_matrix.ps1
```

The shared touch contract can be run independently:

```powershell
powershell -ExecutionPolicy Bypass -File tests/unit/run_responsive_touch.ps1 -Width 854 -Height 480
```

Reference captures for all 24 active scenes can be regenerated with
`tests/smoke/capture_responsive_reference.ps1`. The PNGs stay under ignored
`tasks/builds/responsive-screenshots/`; their dimensions and hashes are
recorded in `tasks/responsive-screenshot-baseline.md`.

Future scenes should add a manifest entry with critical NodePaths, keep normal
interface text at least 18 design pixels, preserve existing signal/unique-name
contracts, and add a focused test before changing authored coordinates.
