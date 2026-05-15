# Dashboard Artifact Storage Plan

## Purpose

Record where dashboard closeout snapshots live, what metadata they preserve, and
which historical notice text must remain visible when artifacts are captured.

## Required paths

- Iteration closeout: `specs/<feature>/iterations/<NNN>/dashboard.md`
- Feature closeout: `specs/<feature>/closeout-dashboard.md`

## Storage rules

1. Live `specrew where` renders do **not** overwrite historical artifacts.
2. Closeout scaffolds may create missing artifacts, but `--preserve-existing-artifact`
   keeps an existing historical file untouched.
3. Stored dashboard artifacts preserve the same semantic section order as the live renderer.

## Example artifact metadata

```markdown
# Velocity Dashboard Snapshot

- Schema: v1
- Capture Kind: iteration-closeout
- Captured At: 2026-05-15T02:15:00Z
- Feature: 017-velocity-dashboard
- Iteration: 001

> Historical snapshot captured during iteration closeout.
> This file records closeout-time state and may differ from a later live rerun.
```

## Historical notice text

- Iteration closeout: `Historical snapshot captured during iteration closeout. This file records closeout-time state and may differ from a later live rerun.`
- Feature closeout: `Historical snapshot captured during feature closeout. This file records final closeout-time state and must remain immutable.`

## Implementation landing

- Renderer + artifact content: `scripts/specrew-where.ps1`
- Iteration artifact generation: `extensions/specrew-speckit/scripts/scaffold-reviewer-artifacts.ps1`
- Feature artifact generation: `extensions/specrew-speckit/scripts/scaffold-feature-closeout-dashboard.ps1`
