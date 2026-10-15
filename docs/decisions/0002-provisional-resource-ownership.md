# ADR 0002: Provisional feature-tree ownership

- Status: Proposed for owner approval
- Date: 2026-09-07
- Scope: density, states/matter-maze, and glossary resource trees

## Context

The dependency recon found parallel feature trees, exact duplicate resources, nested legacy copies, and dynamic resource paths that cannot be resolved by a literal-reference scan alone. Moving files before the graph is understood would break scene/script references and imported-resource UIDs.

## Decision

Until the owner approves the canonical locations, the refactor uses these provisional owners:

| Feature | Provisional owner | Treatment of legacy/nested copies |
| --- | --- | --- |
| Density | `games/chapter_one/hometown/building_two/Level2-1/` | Keep in place; migrate only exact-hash matches in bounded batches |
| States / matter maze | `games/chapter_one/hometown/building_two/level2-2/mattermaze/` | Keep direct scenes/scripts; treat nested copies as migration candidates |
| Glossary | `games/glossary/` | Keep root `glossary/` readable until all consumers are redirected |
| Shared systems | `games/global/` | Shared by features; do not duplicate into feature folders |

`tasks/manifests/*` is the source of truth for the current dependency closure, SHA-256, parent references, missing static paths, dynamic path patterns, and duplicate candidates. A migration may delete a source only after its references are redirected, its hash is verified, and the critical scene matrix passes.

## Consequences

The project remains behaviorally safe while ownership is reviewed. The duplicate trees are intentionally not removed in this phase. The owner must approve the three feature owners before Phase 4 deletion/retirement work can be marked complete.
