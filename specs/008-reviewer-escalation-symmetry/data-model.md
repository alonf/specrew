# Data Model: Reviewer Escalation Symmetry and Lockout-Chain Cap

**Date**: 2026-05-09  
**Spec**: [spec.md](spec.md)  
**Plan**: [plan.md](plan.md)

## Entities

### Reviewer Regression Event

A single human-reported concrete defect in a slice that a Squad reviewer previously approved or marked ready.

**Primary Storage**: `.specrew/reviewer-regression-log.md`

| Field | Type | Description |
| --- | --- | --- |
| `event_id` | string | Stable identifier such as `RRE-001` |
| `feature_ref` | path | Affected feature directory |
| `iteration_ref` | string | Iteration active when reported, or the closed iteration reference |
| `slice_ref` | string | Approved slice or artifact that was later found defective |
| `prior_reviewer_verdict` | enum | `approved`, `ready`, or equivalent recorded reviewer outcome |
| `prior_reviewer_class` | string | Reviewer class/agent family used for the prior verdict |
| `prior_reviewer_owner` | string | Reviewer identity that produced the prior verdict |
| `defect_description` | string | Human-readable defect summary |
| `defect_source_location` | string | File/path/location cited by the report |
| `event_status` | enum | `active`, `resolved`, or `withdrawn` |
| `severity` | enum | `soft-warning` |
| `escalation_action` | enum | `stronger-class`, `same-class-independent-owner`, `human-direction-hold`, `none-yet` |
| `escalated_to_class` | string? | Effective reviewer class after escalation, if any |
| `same_class_fallback_owner` | string? | Independent reviewer owner chosen at the same class |
| `carry_forward_iteration` | string? | Next active iteration when the report lands after close |
| `candidate_trap_status` | enum | `not-applicable`, `offered`, `approved`, `skipped-corpus-disabled`, `removed-on-withdrawal` |
| `withdrawal_ref` | string? | Link to the withdrawal record when misreported |
| `de_escalation_outcome` | string? | Clean-pass outcome when the active chain is resolved |
| `recorded_at` | ISO datetime | When the event was logged |

**Validation**:

- `severity` is always `soft-warning`; the event itself does not imply a hard feature failure.
- `carry_forward_iteration` must be empty unless the report landed after the cited iteration was already closed.
- `same_class_fallback_owner` must differ from `prior_reviewer_owner`.
- `withdrawal_ref` is required when `event_status = withdrawn`.

---

### Active Reviewer Regression Chain

Feature-level unresolved reviewer-regression state used for routing and lockout decisions.

**Authoritative Source**: Latest unresolved entries in `.specrew/reviewer-regression-log.md`  
**Operational Mirror**: `specs/<feature>/iterations/<NNN>/state.md` managed block `reviewer-regression-state`

| Field | Type | Description |
| --- | --- | --- |
| `feature_ref` | path | Affected feature |
| `status` | enum | `inactive`, `active`, `held`, or `resolved` |
| `active_event_ids` | string[] | Unresolved event IDs in the current chain |
| `strongest_unresolved_action` | enum | Highest currently active routing outcome |
| `current_reviewer_class` | string | Effective reviewer class for the next review |
| `prior_reviewer_class` | string | Class before the chain escalated |
| `current_reviewer_owner` | string? | Planned reviewer owner for the next review |
| `clean_passes_required` | integer | Configurable de-escalation threshold |
| `clean_passes_observed` | integer | Accepted clean passes since the last active event |
| `carry_forward_from_iteration` | string? | Closed iteration that originated the carried state |
| `notes` | string? | Human-readable routing summary |

**Validation**:

- Only one active chain exists per feature at a time.
- Duplicate reports for the same approved slice and defect attach to the existing chain rather than creating a second chain.
- `held` requires an explicit hold reason in `notes`.

---

### Implementer Lockout Chain

The bounded list of implementer owners and rotations affected by an active reviewer-regression chain.

| Field | Type | Description |
| --- | --- | --- |
| `original_implementer` | string | First implementer in the chain |
| `rotation_count` | integer | Number of rotations beyond the original implementer |
| `cap_limit` | integer | Maximum allowed rotations beyond the original implementer |
| `locked_out_agents` | string[] | Implementer owners no longer eligible for the next revision |
| `cap_active` | boolean | Whether FR-009/FR-010 is currently active |
| `next_owner_type` | enum | `human`, `alternate-owner`, or `pending-human-direction` |
| `next_owner_ref` | string? | Human or alternate owner selected after cap activation |
| `alternate_owner_approval_ref` | string? | Reference in `.squad/decisions.md` when an alternate owner is allowed |
| `last_updated_at` | ISO datetime | When the lockout chain last changed |

**Validation**:

- `rotation_count` must never exceed `cap_limit` without an approved alternate-owner record.
- `next_owner_type = alternate-owner` requires `alternate_owner_approval_ref`.
- `cap_active = true` requires visibility in decisions ledger, iteration state, and user-facing handoff.

---

### Reviewer Regression Withdrawal

An auditable reversal record for a misreported reviewer regression.

**Storage**: `.specrew/reviewer-regression-log.md` plus structured support entry in `.squad/decisions.md`

| Field | Type | Description |
| --- | --- | --- |
| `withdrawal_id` | string | Stable identifier such as `RRW-001` |
| `original_event_id` | string | Event being withdrawn |
| `rationale` | string | Why the report was withdrawn or reclassified |
| `pending_states_reversed` | string[] | Routing or hold states rolled back |
| `completed_states_preserved` | string[] | Historical actions intentionally kept |
| `candidate_trap_actions` | string[] | Candidate-trap cleanup performed |
| `recorded_at` | ISO datetime | When the withdrawal was recorded |
| `recorded_by` | string | Human or authorized role recording the withdrawal |

**Validation**:

- `original_event_id` must reference an existing event.
- Completed ownership changes cannot appear in `pending_states_reversed`.
- Approved corpus entries are never auto-removed by this record.

---

### Candidate Trap Proposal

Conditional quality-memory output derived from a confirmed reviewer regression when the known-traps corpus is enabled.

| Field | Type | Description |
| --- | --- | --- |
| `proposal_id` | string | Stable candidate identifier |
| `source_event_id` | string | Reviewer regression event that generated the proposal |
| `corpus_path` | path | Expected known-traps corpus path |
| `proposal_status` | enum | `offered`, `approved`, `rejected`, `skipped-corpus-disabled`, `removed-on-withdrawal` |
| `proposed_entry` | markdown | Candidate known-trap text |
| `approval_ref` | string? | Human approval record when the proposal is accepted |

**Validation**:

- `proposal_status = approved` requires the corpus path to exist.
- `removed-on-withdrawal` is valid only for unapproved candidates.
- `skipped-corpus-disabled` is the expected degraded path when the corpus is absent or disabled.

## Relationships

- A `Reviewer Regression Event` belongs to exactly one feature and may participate in one `Active Reviewer Regression Chain`.
- An `Active Reviewer Regression Chain` owns one current `Implementer Lockout Chain`.
- A `Reviewer Regression Withdrawal` references one `Reviewer Regression Event` and may update the active chain.
- A `Candidate Trap Proposal` is optional and depends on both a confirmed regression event and an enabled known-traps corpus.

## State Transitions

```text
reported -> active -> resolved
reported -> active -> held
reported -> active -> withdrawn
held -> active        (after human direction)
active -> resolved    (after required clean review passes)
active -> withdrawn   (misreport confirmed)
resolved -> active    (new distinct regression event on same feature)
```

### Transition Rules

1. `reported -> active`: event is logged and the next reviewer routing action is computed.
2. `active -> held`: strongest class is already active and no independent same-class reviewer exists, or the implementer lockout cap requires human direction.
3. `active -> resolved`: required clean review passes are observed with no new reviewer regression event in that cycle.
4. `active -> withdrawn`: the report is corrected; only still-pending state is reversed.
5. `reported/active` after iteration close sets `carry_forward_iteration` and seeds the next active iteration's mirror state instead of reopening the closed iteration.
