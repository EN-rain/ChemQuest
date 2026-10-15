# Bounded gameplay-script consolidation (2026-09-07)

The nested matter-maze copy contained five byte-identical gameplay scripts whose UIDs already matched the canonical direct scripts. All nested scene consumers were repointed to the direct scripts before the duplicate source and `.uid` sidecars were removed.

| Script | Bytes | SHA-256 | Canonical path |
| --- | ---: | --- | --- |
| `collectible.gd` | 314 | `920966949777108D781148965F8F3D01A073F6295F42458FD6D0CC27AD982711` | `games/chapter_one/hometown/building_two/level2-2/mattermaze/Scripts/collectible.gd` |
| `gas_gate.gd` | 416 | `65BBF856DCCC763CAB83F5657788DD2FD68EA87FB99BE72C688E3C404564FA1C` | `games/chapter_one/hometown/building_two/level2-2/mattermaze/Scripts/gas_gate.gd` |
| `liquid_gate.gd` | 419 | `E732148C2A15DBF762850D9E078C116590FE155DB5A0F7B648289A4CE07D8A1C` | `games/chapter_one/hometown/building_two/level2-2/mattermaze/Scripts/liquid_gate.gd` |
| `lvl_gate.gd` | 1,243 | `8436370F6786E9B5CDC91E46A7AD64177573E883174FDBA06FD175F584B9D34B` | `games/chapter_one/hometown/building_two/level2-2/mattermaze/Scripts/lvl_gate.gd` |
| `matter_gate.gd` | 418 | `E41B4CCD68CCA61A71CA430333E7A787F84CC500448C50FFBB651561D2D56381` | `games/chapter_one/hometown/building_two/level2-2/mattermaze/Scripts/matter_gate.gd` |

This slice removes five exact duplicate implementations without introducing a new abstraction or changing behavior. Other duplicate script groups remain deferred where the trees have divergent scene dependencies or owner approval is still pending.
