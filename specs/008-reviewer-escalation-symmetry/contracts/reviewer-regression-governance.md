# Contract: Reviewer Regression Governance Artifacts

**Contract Version**: 1.0.0  
**Effective**: Planned implementation slice for feature 008  
**Spec**: [../spec.md](../spec.md)

## Overview

This contract defines the artifact and script boundaries for reviewer-regression handling. The feature adds a reviewer-side governance path that is parallel to, but distinct from, implementer-side FR-027 repair escalation.

## Artifact Roles

| Artifact | Role |
| --- | --- |
| `.specrew/reviewer-regression-log.md` | Append-only feature-scoped source of truth for reviewer regression events |
| `specs/<feature>/iterations/<NNN>/state.md` | Active iteration mirror of the currently unresolved reviewer-regression chain |
| `.squad/config.json` | Runtime-facing projection of the effective reviewer-regression routing state |
| `.squad/decisions.md` | Structured approval/override records for lockout-cap activations, lower-tier overrides, and withdrawals |

## Reviewer Regression Ledger Contract

### Location

`.specrew/reviewer-regression-log.md`

### Record Shape

Each record must include:

- event ID
- feature
- iteration
- slice/artifact
- prior reviewer verdict
- prior reviewer class
- prior reviewer owner
- defect description
- defect source location
- escalation action taken
- current status (`active`, `resolved`, `withdrawn`)
- soft-warning classification
- carry-forward target when applicable
- candidate-trap status
- de-escalation outcome when applicable
- timestamps

### Rules

1. The ledger is append-only.
2. Distinct findings append new entries; duplicates for the same approved slice and defect attach to the active chain rather than opening a second chain.
3. Closed-iteration reports append immediately and never modify the closed iteration's historical artifacts.

## Iteration State Mirror Contract

### Managed Block

The active iteration `state.md` gains:

```markdown
<!-- >>> specrew-managed reviewer-regression-state >>> -->
## Reviewer Regression State

- **Status**: inactive | active | held | resolved
- **Feature**: specs/008-reviewer-escalation-symmetry | (none)
- **Active Event IDs**: RRE-001, RRE-002 | (none)
- **Prior Reviewer Class**: copilot | claude | (none)
- **Current Reviewer Class**: codex | claude | (none)
- **Current Reviewer Owner**: Reviewer | Human Reviewer | (none)
- **Lockout Chain Length**: 0..N
- **Lockout Cap**: 2
- **Cap Active**: true | false
- **Locked Out Agents**: Agent A, Agent B | (none)
- **Carry Forward From Iteration**: 003 | (none)
- **Last Event**: 2026-05-09T12:34:56Z | (none)
- **Notes**: free-form routing summary | (none)
<!-- <<< specrew-managed reviewer-regression-state <<< -->
```

### Rules

1. This block is a runtime mirror, not the source of truth.
2. It is seeded from the ledger when an iteration becomes active.
3. It must never replace or mutate the existing `escalation-state` managed block.

## Runtime Config Sync Contract

`.squad/config.json` gains a peer object beside `activeEscalation`:

```json
{
  "reviewerRegressionState": {
    "status": "inactive",
    "feature": null,
    "currentReviewerClass": null,
    "currentReviewerOwner": null,
    "lockoutChainLength": 0,
    "capActive": false,
    "updatedAt": null
  }
}
```

### Rules

1. Runtime sync uses the active iteration's `reviewer-regression-state` mirror.
2. Sync updates only the reviewer-regression peer object; it must not rewrite FR-027 `activeEscalation`.
3. When the chain resolves or is withdrawn, the runtime mirror returns to an inactive state.

## Decisions Ledger Contract

Structured entries in `.squad/decisions.md` are required for:

- reviewer-regression routing evidence when reviewer class or owner changes materially
- lockout-cap activation after the configured implementer cap is reached
- explicit alternate-owner approval after cap activation
- reviewer-regression withdrawal records
- lower-tier override approval if strongest-class routing is intentionally bypassed

### Required Fields

- decision ID
- type
- affected requirement(s)
- affected feature/iteration
- approving human when required
- rationale
- next action

### Type Expectations

Planned structured types:

- `reviewer-regression`
- `lockout-cap`
- `reviewer-regression-withdrawal`
- existing `routing-evidence` for routed reviewer changes

## Script Interface Contract

### Planned Entry Point

`extensions/specrew-speckit/scripts/manage-reviewer-regression.ps1`

### Required Modes

- `report` — record a new reviewer regression event and compute routing outcome
- `resolve` — apply clean-pass de-escalation
- `withdraw` — mark a misreport and reverse only still-pending state
- `project` — seed/update the active iteration mirror and runtime config
- `get` — return the current unresolved chain for a feature

### Input Requirements

- feature path
- iteration directory or closed-iteration reference
- prior reviewer verdict/class/owner
- defect description and source location
- current roster/runtime config for routing lookup

### Output Requirements

- current chain status
- effective reviewer class/owner
- whether a human-direction hold is active
- lockout-chain summary
- ledger references written

## Conditional Known-Traps Contract

When `.specrew/quality/known-traps.md` exists and the project has the corpus enabled:

1. reviewer regression produces a candidate trap proposal
2. human approval is required before append
3. approved entries are handled by the existing corpus workflow

When the corpus is absent or disabled:

1. no trap file is created by this feature
2. the event records `skipped-corpus-disabled`
3. the rest of reviewer-regression handling proceeds normally

## Validation Rules

1. Reviewer Regression Events are soft-warning records unless the event activates an explicit hold path.
2. Same-class fallback requires a reviewer identity different from the owner that produced the prior verdict.
3. Post-cap implementer routing requires either a human owner or an explicitly approved alternate owner in `.squad/decisions.md`.
4. Withdrawal reverses only still-pending state and preserves completed history.
5. Carry-forward after a closed iteration seeds the next active iteration; it never reopens the closed one implicitly.
