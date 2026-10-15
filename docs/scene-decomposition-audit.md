# Scene decomposition audit (2026-09-08)

The refactor intentionally did not split the large scene payloads in this pass. The largest files are data-heavy matter-maze levels (about 268–385 KB) and density levels (about 127–232 KB); their node paths, embedded tile data, and cross-tree UIDs are still under owner review. The hometown hub is about 198 KB and likewise mixes map, NPC, and panel contracts.

Before extracting a scene, capture a screenshot/interaction baseline and preserve `%UniqueName` lookups, signal connections, and scene-local resource ownership. The current 24-scene smoke harness verifies readiness but does not replace visual comparison, so scene decomposition remains the only unchecked Phase 7 task. Recommended next slices are an isolated hometown overlay panel and a matter-maze level data scene after duplicate-tree ownership is approved.
