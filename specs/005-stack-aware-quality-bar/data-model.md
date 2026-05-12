# Data Model: Stack-Aware Quality Bar (Hardening Evidence Boundary Repair)

**Date**: 2026-05-09
**Spec**: [spec.md](spec.md)  
**Plan**: [plan.md](plan.md)

## Entities

### Hardening Gate Review

Single lifecycle-visible review packet for the bounded hardening-evidence repair.

**Location**: `specs/<feature>/iterations/<NNN>/quality/hardening-gate.md`

| Field | Type | Description |
| --- | --- | --- |
| `gate_id` | string | Stable identifier, e.g. `pre-implementation-hardening` |
| `feature_ref` | path | Governing feature path |
| `iteration_ref` | string | Active iteration identifier |
| `review_phase` | enum | `pre-implementation`, `post-implementation`, or `closure` |
| `requested_review_class` | string | Requested reasoning/review tier (`strongest-available` by default) |
| `effective_review_class` | string | Actual tier used for the review |
| `concern_rows[]` | `Hardening Concern`[] | Explicit concern rows kept across lifecycle phases |
| `overall_verdict` | enum | `ready`, `blocked`, or `deferred-with-approval` for the current phase |
| `approval_ref` | string? | Human approval reference when deferred blocking concerns are carried forward |
| `reviewed_by` | string | Reviewer or role |
| `reviewed_at` | ISO datetime | Review timestamp |

**Validation**:

- The same artifact persists across phases; later runtime proof updates the existing concern rows rather than replacing them silently.
- `ready` at pre-implementation means planning-ready, not runtime-closed.

---

### Hardening Concern

One reviewed concern inside the hardening gate.

| Field | Type | Description |
| --- | --- | --- |
| `concern_id` | string | Stable key such as `security-surface` |
| `category` | enum | `security`, `error-handling`, `retry-idempotency`, `test-integrity`, `operational` |
| `status` | enum | `addressed`, `not-applicable`, `tbd`, `deferred-with-approval` |
| `evidence_basis` | enum | `planning-time-analysis`, `runtime-evidence`, or `not-applicable` |
| `runtime_evidence_status` | enum | `not-needed`, `pending-post-implementation`, or `recorded` |
| `expected_controls` | string? | Controls or behaviors expected once implementation exists |
| `rationale` | string | Why the current status is valid |
| `blocking` | boolean | Whether unresolved state blocks implementation readiness |
| `approval_ref` | string? | Human approval reference for deferred blocking concerns |

**Validation**:

- Pre-implementation rows may use `planning-time-analysis`; they must not require `runtime-evidence` unless implementation already exists.
- `deferred-with-approval` is valid only when `evidence_basis = planning-time-analysis` and `runtime_evidence_status = pending-post-implementation`.
- Missing planning-time analysis keeps the row blocking (`status = tbd` or equivalent unresolved state).
- A row cannot be treated as fully closed until required runtime evidence is recorded.

---

### Repair Iteration Slice

Bounded iteration-local planning package for this bugfix.

**Location**: `specs/<feature>/iterations/<NNN>/plan.md`

| Field | Type | Description |
| --- | --- | --- |
| `iteration_id` | string | New repair iteration identifier |
| `scope` | string | Bounded bugfix scope for the hardening evidence boundary |
| `affected_surfaces[]` | string[] | Governance scripts, fixtures, review artifacts, and docs to be changed later |
| `validation_commands[]` | string[] | Deterministic commands required to prove the repair |
| `history_guard` | string | Statement preserving completed Iteration `003` |

## Relationships

- `Hardening Gate Review` owns the lifecycle-visible evidence record.
- Each `Hardening Concern` states whether the current evidence is planning-time analysis or recorded runtime proof.
- `Repair Iteration Slice` binds the bugfix to explicit affected surfaces and validation commands without reopening completed history.
