# Contract: Dashboard Artifacts

## Purpose

Define the durable dashboard artifacts generated during closeout workflows.

## Required Artifact Paths

### Iteration closeout

```text
specs/<feature>/iterations/<NNN>/dashboard.md
```

### Feature closeout

```text
specs/<feature>/closeout-dashboard.md
```

## Artifact Semantics

- Both artifacts store a historical dashboard snapshot captured at closeout time.
- Stored artifacts must never be silently regenerated in place by later ad hoc dashboard runs.
- A fresh ad hoc render is a new live view, not a rewrite of the historical artifact.

## Required Metadata

Each artifact must include or imply:

- capture timestamp
- feature / iteration context
- snapshot/historical notice
- enough provenance to explain that the file represents closeout-time state

## Validation Rules

- Post-feature iteration closeouts after rollout must produce `dashboard.md`.
- Historical iterations that predate the feature are grandfathered.
- Missing required artifacts should surface as bounded governance warnings.
- Artifacts must remain co-located with their owning feature/iteration records.

## Rendering Rules

- Iteration closeout may use compact rendering if that is the approved closeout presentation.
- Feature closeout may use the fuller dashboard presentation.
- Both artifacts must preserve the same semantic section ordering as the live renderer.
