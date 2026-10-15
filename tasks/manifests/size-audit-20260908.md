# Repository size audit (2026-09-08)

Measured after the font/audio/orphan cleanup and before any commit:

| Measurement | Bytes |
| --- | ---: |
| Git HEAD tracked tree | 95,714,833 |
| Current tracked files still present | 83,999,291 |
| Tracked-tree delta | -11,715,542 |
| Current source tree (excluding `.git`, `.godot`, and `tasks/builds`) | 84,429,603 |
| Editable `.aseprite` + ZIP sources retained | 1,824,150 |

The current tracked-tree delta includes the 136 editor artifacts, proven orphan scenes/scripts, duplicate font binaries/import files, and normal source edits. The editable source total is retained for provenance and is excluded from Android/Web packages. Icon-specific before/after sizes are recorded in `icon-optimization.md`; export package sizes are recorded in `tasks/export-validation.md`.
