# ADR 0003: Runtime/source asset boundary

- Status: Proposed (owner approval required for third-party provenance and duplicate-tree retirement)
- Date: 2026-09-08

## Decision

Runtime consumers use one shared font set under `assets/`, shared music/SFX under `games/global/music/`, and the canonical glossary/matter-maze trees recorded in the dependency manifests. Editable `.aseprite` and ZIP sources remain versioned for provenance but are excluded from Android/Web exports. Feature-specific novelty audio remains local to the density feature until the owner approves a broader audio move.

## Rationale

The repository contained exact duplicate fonts and nested feature copies, plus source archives that should not ship. Repointing consumers before deletion preserves UIDs and makes the runtime boundary explicit. Exact duplicate font source/import pairs were removed only after a zero-reference scan; divergent art and feature trees remain available for review.

## Consequences

- Runtime exports are smaller and contain no editable source archives.
- Third-party provenance is visible in `docs/THIRD_PARTY_NOTICES.md`; unresolved licenses remain a release gate.
- Legacy glossary and nested matter-maze/density trees still produce duplicate UID warnings until owner-approved migration/removal is complete.
