# Asset consolidation record (2026-09-07)

This record defines the runtime/source split used by the refactor. It deliberately distinguishes exact duplicate cleanup from assets whose visual or gameplay ownership still needs an owner decision.

## Canonical runtime ownership

| Asset family | Canonical location | Policy |
| --- | --- | --- |
| Shared fonts (`electrone`, `LilitaOne`, `Roboto-BoldCondensed`) | `assets/*.ttf` | All scene consumers now use these three root copies. Feature and legacy duplicate font binaries/import files were removed after a zero-reference scan. |
| Glossary UI textures and element art | `games/glossary/assets/` | Active glossary scenes use this tree. The legacy `glossary/` tree remains available for owner-approved feature migration. |
| Application music and SFX | `games/global/music/` | `MusicManager.gd` owns lookup and SFX bus routing. Common menu/game sounds use this library. |
| Density novelty audio | `games/chapter_one/hometown/building_two/Level2-1/Assets/` | Direct density scenes retain their existing MP3 content and references. The nested duplicate tree is not deleted until the density owner approves retirement. |
| Matter-maze runtime art | `games/chapter_one/hometown/building_two/level2-2/mattermaze/Assets/` | Active state scenes use this direct tree wherever hashes and behavior match. Remaining nested references are recorded in the dependency manifests. |

## Source/editable inventory

- 42 `.aseprite` files (1,790,330 bytes) are source art only. They are concentrated in two exact-copy Treasure Hunters trees; 21 duplicate pairs share identical SHA-256 hashes. No runtime scene references an Aseprite source file.
- `games/chapter_one/hometown/building_two/level/Assets/FONTS/Lilita_One.zip` (16,805 bytes) contains `LilitaOne-Regular.ttf` and `OFL.txt`.
- `games/chapter_one/hometown/building_two/level/Assets/FONTS/nougat.zip` (17,015 bytes) contains `Nougat-ExtraBlack.ttf` and no license file.
- Export presets explicitly exclude `*.aseprite` and `*.zip` from Android and Web exports. The archives remain in the repository only as editable/source provenance pending the owner decision on source ZIP retention.

## Duplicate cleanup completed

- Repointed all active and legacy scene references for the shared fonts to `res://assets/*.ttf`, preserving the root font UIDs.
- Removed nine duplicate font source/import pairs from the old `level`, density, glossary, and legacy glossary asset folders. Unique `monogram.ttf` and matter-maze-specific font files remain.
- Replaced the 2.4 MB rectangle-per-pixel `icon.svg` with an equivalent run-length SVG (367,343 bytes; 84.67% smaller). See `icon-optimization.md`.
- Removed two unreferenced, byte-identical multi-megabyte embedded-audio scenes. See `embedded-audio-cleanup-20260907.md`.

## Deferred owner approvals

The following are intentionally not mass-deleted: the legacy glossary tree, nested density/matter-maze trees, the 42 editable Aseprite sources, and the two ZIP archives. Their paths, hashes, and active-reference status are covered by the feature manifests and provisional ownership ADR.
