# Contract: `.specrew/roadmap.yml`

## Purpose

Define the v1 roadmap source consumed by the Velocity Dashboard.

## File Location

```text
.specrew/roadmap.yml
```

## Schema Shape

```yaml
phases:
  - id: phase-1-foundations
    name: "Phase 1: Planning & Foundations"
    description: "Bootstrap and governance foundations"
    planned_effort_sp: 48
    status: shipped
    feature_refs:
      - 011-specrew-start-conditional-pause
      - 013-validator-hardening
```

## Field Semantics

| Field | Required | Meaning |
| --- | --- | --- |
| `phases` | yes | Ordered list of roadmap phases |
| `id` | yes | Stable phase identifier |
| `name` | yes | User-facing phase label |
| `description` | yes | Short context shown in docs/dashboard reasoning |
| `planned_effort_sp` | yes | Human-maintained planned effort for the phase |
| `status` | yes | Maintainer-declared state: `queued`, `in-progress`, or `shipped` |
| `feature_refs` | yes | Ordered feature directory references used for aggregation |

## Derived Semantics

- Shipped progress is derived from canonical closed iteration history, not from user-entered shipped
  totals in the roadmap file.
- A phase may remain visually `in-progress` even when some listed features have partially shipped
  story points.
- Declared `status` is advisory but must be checked against derived shipped progress for drift.
- If derived shipped effort exceeds planned effort, the phase must surface a `drifted-over` effective status and a bounded warning.

## Validation Rules

- `planned_effort_sp` must be a non-negative integer.
- `feature_refs` must reference real feature directories under `specs/` once the phase is scoped; placeholder phases may temporarily leave the list empty with explicit TODO notes.
- Missing roadmap file is allowed; the dashboard must degrade gracefully and explain setup.
- Material mismatch between declared phase status and derived shipped progress must emit a bounded
  validator/dashboard warning.

## Forward-Compatibility Rules

- v1 is single-developer oriented.
- Future multi-developer expansion may add metadata, but must not replace phase/feature traceability
  or move shipped totals back to manual entry.
