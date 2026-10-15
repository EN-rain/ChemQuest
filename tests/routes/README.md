# ChemQuest2 route QA

`routes.json` is the canonical Chapter One route manifest. It describes the
scene edge, quest/progress precondition, spawn value, driver, expected result,
and supported input devices for every player-facing route.

The checks are deliberately split into layers:

1. `run_route_contract.ps1` performs static validation. It verifies all 24
   active scenes, route endpoints, incoming/outgoing coverage, signal targets,
   quest ordering, spawn aliases, and that active scenes do not load the
   quarantined duplicate trees.
2. `run_route_interaction.ps1` runs deterministic headless checks against the
   real FadeManager, SpawnManager, QuestManager, Lesson 3 results panel,
   canonical States scenes, and touch buttons. Passes are isolated with the
   `--route-test` flag; SaveManager keeps an in-memory snapshot and never
   writes the developer profile.
3. The rendered journey layer is driven by the same manifest from the existing
   smoke/responsive runners. Use the viewport matrix for screenshots and real
   keyboard/mouse/touch journeys.

Run from the project root:

```powershell
powershell -ExecutionPolicy Bypass -File tests/routes/run_route_contract.ps1
powershell -ExecutionPolicy Bypass -File tests/routes/run_route_interaction.ps1
powershell -ExecutionPolicy Bypass -File tests/routes/run_camera_spawn.ps1
```

For release QA, run both route suites before the existing persistence, menu /
audio, 24-scene smoke, responsive viewport, import, Android export, and Web
export gates. A route is not considered covered by scene instantiation alone:
the rendered pass must also prove movement, interaction, completion, save /
reload, and equivalent keyboard/touch input.
