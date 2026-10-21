# Runtime regression snapshot

Generated: 2026-10-22T02:14:01.2685798+08:00
Godot: C:\Users\LENOVO\Desktop\GodotGDScript\Godot_v4.6.1-stable_win64.exe
Matrix entries: 24; pass: 24; fail: 0

| ID | Role | Result | Duration (ms) | Path | Failure signal | Warning signal |
|---|---|---:|---:|---|---|---|
| intro | entry | PASS | 894 | `res://intro.tscn` |  |  |
| main_menu | menu | PASS | 769 | `res://games/main.tscn` |  |  |
| chapter_one_cutscene | transition | PASS | 615 | `res://games/chapter_one/visual_one.tscn` |  |  |
| hometown | hub | PASS | 1051 | `res://games/chapter_one/hometown/hometown.tscn` |  |  |
| building_one | hub | PASS | 980 | `res://games/chapter_one/hometown/building_one/building_one.tscn` |  |  |
| building_two | hub | PASS | 853 | `res://games/chapter_one/hometown/building_two/building_two.tscn` |  |  |
| lesson_one | lesson | PASS | 753 | `res://games/chapter_one/hometown/building_one/Level1/Lesson1/lesson_one.tscn` |  |  |
| lesson_two | lesson | PASS | 764 | `res://games/chapter_one/hometown/building_one/Level1/Lesson2/lesson_two.tscn` |  |  |
| lesson_three | lesson | PASS | 670 | `res://games/chapter_one/hometown/building_one/Level1/Lesson3/Lesson3.tscn` |  |  |
| level_two | lesson | PASS | 908 | `res://games/chapter_one/hometown/building_one/Level2/Level2.tscn` |  |  |
| level_three | lesson | PASS | 942 | `res://games/chapter_one/hometown/building_one/Level3/level_3.tscn` |  |  |
| precision_accuracy | lesson | PASS | 885 | `res://games/chapter_one/hometown/building_one/Level4/PrecisionAccuracy/precision_accuracy.tscn` |  |  |
| density_level_one | density | PASS | 786 | `res://games/chapter_one/hometown/building_two/Level2-1/Level2-1/Scenes/level 1/level_1.tscn` |  |  |
| density_level_two | density | PASS | 679 | `res://games/chapter_one/hometown/building_two/Level2-1/Scenes/level_2.tscn` |  | SMOKE_WARNING shutdown resource-leak signal (does not fail scene readiness) |
| density_level_three | density | PASS | 691 | `res://games/chapter_one/hometown/building_two/Level2-1/Scenes/level_3.tscn` |  |  |
| states_main | states | PASS | 1021 | `res://games/chapter_one/hometown/building_two/level2-2/mattermaze/Scenes/main.tscn` |  |  |
| states_level_one | states | PASS | 963 | `res://games/chapter_one/hometown/building_two/level2-2/mattermaze/Scenes/level_1.tscn` |  |  |
| states_level_two | states | PASS | 973 | `res://games/chapter_one/hometown/building_two/level2-2/mattermaze/Scenes/level_2.tscn` |  |  |
| states_level_three | states | PASS | 816 | `res://games/chapter_one/hometown/building_two/level2-2/mattermaze/Scenes/level_3.tscn` |  |  |
| glossary | glossary | PASS | 695 | `res://games/glossary/main.tscn` |  |  |
| glossary_element_info | glossary | PASS | 713 | `res://games/glossary/element_info.tscn` |  |  |
| glossary_about | about | PASS | 680 | `res://games/glossary/about.tscn` |  |  |
| achievements | achievements | PASS | 664 | `res://games/achievements/achievements.tscn` |  |  |
| reward | reward | PASS | 1023 | `res://games/achievements/reward/Reward.tscn` |  |  |

Orphan candidates are listed separately in `tests/smoke/scenes.json` and are not included in the active baseline.

The smoke wrapper requires `SMOKE_PASS` and rejects script/parse/startup errors. A known shutdown resource-leak signature is reported as a warning for the affected density scene and does not hide scene-readiness failures.
