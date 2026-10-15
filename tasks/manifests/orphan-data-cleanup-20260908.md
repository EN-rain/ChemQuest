# Orphan data cleanup

The tracked `games/data/cristofe_idle.tres` resource was removed after a repository-wide dependency scan found no incoming literal or UID references. Its only external texture reference pointed to the missing `res://assets/Pixel Crawler - Free Pack/Entities/Npc's/Rogue/Idle/Idle-Sheet.png` file. The live Cristofe NPC uses `games/data/wiz_idle.tres` and the existing `assets/standard/npc/cristofe/idle.png` texture instead.

| Removed resource | Bytes | SHA-256 | Incoming references | Missing dependency |
| --- | ---: | --- | ---: | --- |
| `games/data/cristofe_idle.tres` | 1,145 | `229D73100C5AB6E4FD12CFA90887CF9A8ECB35CF0BDF0922CE44A79962DB4DF3` | 0 | `res://assets/Pixel Crawler - Free Pack/Entities/Npc's/Rogue/Idle/Idle-Sheet.png` |

The live entry-point scenes and the 24-scene smoke matrix do not depend on this orphan resource.
