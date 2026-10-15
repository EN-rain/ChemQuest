# Precision/Accuracy orphan cleanup (2026-09-07)

The active scene is `res://games/chapter_one/hometown/building_one/Level4/PrecisionAccuracy/precision_accuracy.tscn`. A repository-wide path scan found no incoming references to the seven scene files below. Each orphan also contains one or more broken `res://scenes/levels/mini_levels/PrecisionAccuracy/...` references, a layout that does not exist in this project. The live scene uses the sibling `target.gd` and `score_1.gd`–`score_5.gd` scripts directly; it does not instantiate these scenes.

| Retired scene | Bytes | SHA-256 |
| --- | ---: | --- |
| `games/chapter_one/hometown/building_one/Level4/PrecisionAccuracy/hitmark.tscn` | 363 | `6FFC1A7D69D2AE38923360662307BF35DD38F41D530E99492E2B63A8E8B66B29` |
| `games/chapter_one/hometown/building_one/Level4/PrecisionAccuracy/rotating_targets.tscn` | 2,150 | `507149045CA5AE9A284977432F7CCD20546059747C52B2FB909448E045CED577` |
| `games/chapter_one/hometown/building_one/Level4/PrecisionAccuracy/target_1.tscn` | 1,979 | `DB1778630F73C2F0422CA49C51FFF019654AA0EE8F8FF4CCDB3C87B4BA7248EE` |
| `games/chapter_one/hometown/building_one/Level4/PrecisionAccuracy/target_2.tscn` | 2,031 | `33E125B95818CCD4AEAF8F6D90A7616D33B435B5A06ABA2610AC15DB00DE8D74` |
| `games/chapter_one/hometown/building_one/Level4/PrecisionAccuracy/target_3.tscn` | 2,031 | `5DBB83F33697C39B6A805D17D8ED6B98CB2D675EA91C53C83F8B837820DDC776` |
| `games/chapter_one/hometown/building_one/Level4/PrecisionAccuracy/target_4.tscn` | 2,032 | `C95570FB9DCB018B2545E00E650D92EAA091C743A5FA142B447425B25434B70C` |
| `games/chapter_one/hometown/building_one/Level4/PrecisionAccuracy/target_5.tscn` | 2,032 | `F1CB7AF78CE56FB7A2F883827283DAF176DFCEA4CE997509E9C78D7673119E29` |

The five matching `target_1.gd`–`target_5.gd` scripts (397 bytes each, identical SHA-256 `F6FD5C3B90911ED4A3E573798199DAA49A99C1BACA497753601E6BC1A8E066BA`) and their `.uid` sidecars were also unreferenced after the scene removal and were retired with the scenes. Deletion is limited to these proven orphans; the active Precision/Accuracy scene and its referenced scripts/assets are retained and smoke-tested separately.
