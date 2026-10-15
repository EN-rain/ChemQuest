# Embedded audio cleanup (2026-09-07)

## Evidence

Two tracked scenes contained the same embedded `AudioStreamWAV` payload:

| Path | Bytes | SHA-256 | Incoming textual references |
| --- | ---: | --- | --- |
| `games/chapter_one/hometown/building_two/Level2-1/Scenes/level 2/audio_stream_player_2d.tscn` | 2,647,367 | `318D8F06C8209234B3FA8C88EB9D95A80EEBFBAD444F66322461C832264D7763` | none |
| `games/chapter_one/hometown/building_two/Level2-1/Level2-1/Scenes/level 2/audio_stream_player_2d.tscn` | 2,647,367 | `318D8F06C8209234B3FA8C88EB9D95A80EEBFBAD444F66322461C832264D7763` | none |

The repository-wide reference scan covered tracked text resources and excluded only `.git`, `.godot`, and temporary editor files. Neither scene is referenced by an active scene, script, resource, or data file. The pair is therefore retired as orphaned embedded-audio debt. Active audio remains routed through `games/global/MusicManager.gd` and the canonical files under `games/global/music/`.

Deletion is intentionally limited to these two exact duplicate paths; no active audio asset is removed.
