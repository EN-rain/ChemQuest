# Runtime regression snapshot

Generated: 2026-10-22T01:46:59.3403215+08:00
Godot: C:\Users\LENOVO\Desktop\GodotGDScript\Godot_v4.6.1-stable_win64.exe
Matrix entries: 24; pass: 24; fail: 0

| ID | Role | Result | Duration (ms) | Path | Failure signal | Warning signal |
|---|---|---:|---:|---|---|---|
| intro | entry | PASS | 727 | `res://intro.tscn` |  |  |
| main_menu | menu | PASS | 673 | `res://games/main.tscn` |  |  |
| chapter_one_cutscene | transition | PASS | 560 | `res://games/chapter_one/visual_one.tscn` |  |  |
| hometown | hub | PASS | 846 | `res://games/chapter_one/hometown/hometown.tscn` |  |  |
| building_one | hub | PASS | 845 | `res://games/chapter_one/hometown/building_one/building_one.tscn` |  |  |
| building_two | hub | PASS | 776 | `res://games/chapter_one/hometown/building_two/building_two.tscn` |  |  |
| lesson_one | lesson | PASS | 747 | `res://games/chapter_one/hometown/building_one/Level1/Lesson1/lesson_one.tscn` |  |  |
| lesson_two | lesson | PASS | 657 | `res://games/chapter_one/hometown/building_one/Level1/Lesson2/lesson_two.tscn` |  |  |
| lesson_three | lesson | PASS | 749 | `res://games/chapter_one/hometown/building_one/Level1/Lesson3/Lesson3.tscn` |  |  |
| level_two | lesson | PASS | 665 | `res://games/chapter_one/hometown/building_one/Level2/Level2.tscn` |  |  |
| level_three | lesson | PASS | 656 | `res://games/chapter_one/hometown/building_one/Level3/level_3.tscn` |  |  |
| precision_accuracy | lesson | PASS | 654 | `res://games/chapter_one/hometown/building_one/Level4/PrecisionAccuracy/precision_accuracy.tscn` |  |  |
| density_level_one | density | PASS | 578 | `res://games/chapter_one/hometown/building_two/Level2-1/Level2-1/Scenes/level 1/level_1.tscn` |  | SMOKE_WARNING shutdown resource-leak signal (does not fail scene readiness) |
| density_level_two | density | PASS | 656 | `res://games/chapter_one/hometown/building_two/Level2-1/Scenes/level_2.tscn` |  | SMOKE_WARNING shutdown resource-leak signal (does not fail scene readiness) |
| density_level_three | density | PASS | 651 | `res://games/chapter_one/hometown/building_two/Level2-1/Scenes/level_3.tscn` |  |  |
| states_main | states | PASS | 671 | `res://games/chapter_one/hometown/building_two/level2-2/mattermaze/Scenes/main.tscn` |  |  |
| states_level_one | states | PASS | 671 | `res://games/chapter_one/hometown/building_two/level2-2/mattermaze/Scenes/level_1.tscn` |  |  |
| states_level_two | states | PASS | 679 | `res://games/chapter_one/hometown/building_two/level2-2/mattermaze/Scenes/level_2.tscn` |  |  |
| states_level_three | states | PASS | 673 | `res://games/chapter_one/hometown/building_two/level2-2/mattermaze/Scenes/level_3.tscn` |  |  |
| glossary | glossary | PASS | 657 | `res://games/glossary/main.tscn` |  |  |
| glossary_element_info | glossary | PASS | 559 | `res://games/glossary/element_info.tscn` |  |  |
| glossary_about | about | PASS | 560 | `res://games/glossary/about.tscn` |  |  |
| achievements | achievements | PASS | 566 | `res://games/achievements/achievements.tscn` |  |  |
| reward | reward | PASS | 559 | `res://games/achievements/reward/Reward.tscn` |  |  |

Orphan candidates are listed separately in `tests/smoke/scenes.json` and are not included in the active baseline.

The smoke wrapper requires `SMOKE_PASS` and rejects script/parse/startup errors. A known shutdown resource-leak signature is reported as a warning for the affected density scene and does not hide scene-readiness failures.
