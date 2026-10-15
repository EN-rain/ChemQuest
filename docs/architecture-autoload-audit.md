# Autoload ownership audit (2026-09-07)

The autoload list is now intentionally split between application-wide services and progression managers. The audit uses the current source-reference scan; a manager is not removed merely because it has few consumers when it owns persisted state.

## Application-wide services

| Autoload | Lifetime/owner | Why it remains global |
| --- | --- | --- |
| `FadeManager` | Application transition service | Every hub, lesson, menu, and result panel can request a validated scene transition. |
| `DialogueManager` | Application dialogue session | Hometown interactions share one dialogue queue. |
| `SpawnManager` | Application navigation/session | Entry and return points across hubs and lessons use the same spawn contract. |
| `InteractionManager` | Application interaction registry | World interaction scripts register and unregister across scene changes. |
| `MusicManager` | Application audio session | Music continuity and the SFX bus must survive scene changes. |
| `SaveManager` | Application persistence boundary | It owns schema v2 normalization, atomic writes, migration, and reset orchestration. |
| `GuideManager` | Profile-level tutorial history | Guide completion intentionally survives New Game; see ADR 0001. |
| `PlayerFeedbackManager` | Profile/session feedback history | Shown feedback is persisted and is reset through the SaveManager contract. |

## Progression managers

| Autoload | Owning feature | Reason for current global lifetime |
| --- | --- | --- |
| `QuestManager` | Chapter quest/progression | Hubs, achievements, and lessons read/write the same quest state. |
| `ChallengeManager` | Density challenge progression | Density gates and SaveManager share completed-level identities. |
| `Scoring` | Precision/Accuracy plus matter-maze score bridge | The current matter-maze collectible path also reads it; keep until score ownership is split. |
| `LessonManager` | Lessons 1–2 | Results panels and spawners share persisted lesson history. |
| `ElementColorDB` | Lesson 2 element data | The lesson spawner consumes one shared immutable lookup table. |
| `Level3Manager` | Lesson 3 | Results and item history are persisted outside the scene lifetime. |

## Removed scope

`Level2Manager` was an empty, unreferenced autoload. Its registration and script/UID sidecars were removed after a repository-wide reference scan. This is the first bounded autoload reduction; no persisted behavior changed.

## Follow-up candidates

`Scoring`, `ElementColorDB`, and the lesson-specific managers can be injected by owning scenes after a save-model boundary is introduced. That migration is intentionally deferred until the Android/Web export matrix and owner decisions are complete; removing them now would create hidden save or cross-feature coupling risk.
