# States asset cross-tree migration

Generated: 2026-09-08

The canonical states level-one scene referenced two Pixel Adventure textures through the nested density path. Both source and canonical matter-maze target files were present and had identical SHA-256 content, so only the scene references were redirected. No assets were deleted and no UIDs were changed.

| Source reference | Canonical reference | Verification |
| --- | --- | --- |
| `res://games/chapter_one/hometown/building_two/Level2-1/Level2-1/Assets/Pixel Adventure 1/Free/Terrain/Terrain (16x16).png` | `res://games/chapter_one/hometown/building_two/level2-2/mattermaze/Assets/Pixel Adventure 1/Free/Terrain/Terrain (16x16).png` | SHA-256 `3FB1A76C7CC102116562F9533D51386B8E63616AA0E228F359001DBB7479EAAB` on both files |
| `res://games/chapter_one/hometown/building_two/Level2-1/Level2-1/Assets/Pixel Adventure 1/Free/Background/Blue.png` | `res://games/chapter_one/hometown/building_two/level2-2/mattermaze/Assets/Pixel Adventure 1/Free/Background/Blue.png` | SHA-256 `A37AF35C2A8F30600B6831FCCF7B4853969E74F0C4F582CA12F9379798E67409` on both files |

The remaining nested references in the canonical matter-maze scenes point to divergent scripts (`player.gd`, `lvl_gate_end.gd`, and `lvl_gate_2.gd`). Those scripts are not redirected automatically because their behavior differs and require an owner-approved semantic merge before duplicate-tree retirement.
