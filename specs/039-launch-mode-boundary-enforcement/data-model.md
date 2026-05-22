# Data Model: Launch-Mode Boundary Enforcement

**Feature**: F-039  
**Date**: 2026-05-22  
**Status**: Phase 1 design complete

This model adopts Proposal 065 Pillar 3 as the persisted source of truth for boundary authorization. It intentionally replaces the earlier "counter-only" placeholder with a machine-readable authorization ledger that can survive restart, recovery, bypass, and future Proposal 038 policy lookup.

---

## 1. Canonical persisted shape

```json
{
  "schema": "v2",
  "feature_path": "C:\\Dev\\Specrew\\specs\\039-launch-mode-boundary-enforcement",
  "generated_at_utc": "2026-05-22T15:04:00Z",
  "session_state": {
    "active": true,
    "boundary_type": "plan",
    "feature_ref": "039-launch-mode-boundary-enforcement",
    "feature_path": "C:\\Dev\\Specrew\\specs\\039-launch-mode-boundary-enforcement",
    "iteration_number": null,
    "task_id": null,
    "auth_commit_hash": "97b70074307190a1e8edae8081882a8ee727f74f",
    "recorded_at": "2026-05-22T15:04:00Z"
  },
  "boundary_enforcement": {
    "enabled": true,
    "last_authorized_boundary": "plan",
    "pending_next_boundary": "tasks",
    "verdict_history": [
      {
        "from_boundary": "clarify",
        "to_boundary": "plan",
        "verdict_text": "approved for plan-boundary entry",
        "authorizing_human": "Alon Fliess",
        "recorded_at": "2026-05-22T11:42:18Z",
        "auth_commit_hash": "ad1a970a"
      }
    ],
    "bypass_history": []
  }
}
```

### Design notes

- Root `schema` advances from `v1` to `v2` when `boundary_enforcement` is introduced.
- `session_state` remains intact; F-039 composes with existing start/resume logic rather than replacing it.
- `boundary_enforcement` is the new authorization truth store.
- Dashboard-style counters remain **derived views**, not persisted source fields.

---

## 2. Canonical boundary vocabulary

Persisted boundary names:

- `specify`
- `clarify`
- `plan`
- `tasks`
- `before-implement`
- `review-signoff`
- `retro`
- `iteration-closeout`
- `feature-closeout`

### Alias handling

Human-facing or legacy aliases may still appear in prompts or existing governance helpers (`planning`, `review-boundary`, `implementation`, `retro-boundary`), but they are normalized before persistence. `start-context.json` stores only the nine canonical names above.

---

## 3. Entities

## Entity: BoundaryEnforcementState

Represents the per-session authorization state persisted in `.specrew\start-context.json`.

| Field | Type | Required | Rules | Notes |
| --- | --- | --- | --- | --- |
| `enabled` | boolean | yes | `true` after migration or normal start; `false` only for pre-migration legacy reads | Session-scoped enforcement master switch |
| `last_authorized_boundary` | canonical boundary or null | yes | null only before first explicit verdict | Records the highest approved boundary |
| `pending_next_boundary` | canonical boundary or null | yes | must be the next boundary being requested when the gate stops | Cleared after successful entry or session closeout |
| `verdict_history` | array of `BoundaryAuthorizationVerdict` | yes | append-only | Human approvals/refusals/parks are recorded here |
| `bypass_history` | array of `BoundaryBypassRecord` | yes | append-only | Session-scoped bypass invocations plus per-boundary bypass events |

### Invariants

1. `last_authorized_boundary` never moves backward unless a human explicitly resets state via recovery.
2. `pending_next_boundary` is null whenever no gate is currently awaiting authorization.
3. `verdict_history` and `bypass_history` are append-only and ordered by `recorded_at`.
4. A session with active bypass still keeps `enabled = true`; bypass suspends enforcement behavior, not the existence of the model.

---

## Entity: BoundaryAuthorizationVerdict

Represents one maintainer verdict parsed from explicit authorization text.

| Field | Type | Required | Rules |
| --- | --- | --- | --- |
| `from_boundary` | canonical boundary | yes | Must equal the current persisted boundary when verdict is recorded |
| `to_boundary` | canonical boundary | yes | Must be reachable via the canonical boundary order |
| `verdict_text` | string | yes | Stores the exact typed verdict |
| `authorizing_human` | string | yes | Human-readable identity, never blank |
| `recorded_at` | UTC timestamp | yes | Format `yyyy-MM-ddTHH:mm:ssZ` |
| `auth_commit_hash` | string or null | yes | Use `Resolve-SpecrewBoundaryAuthCommitHash`; may be null only when no concrete hash exists yet |

### Accepted verdict families

- `approved for <boundary>-boundary entry`
- `approved for <boundary>`
- `approved for review-boundary AND review-signoff`
- `rejected for <boundary>`
- `parked`

### Notes

- Ambiguous phrases such as `looks good`, `yep`, `continue`, `fine`, and `okay` do **not** become verdict rows; they parse to unauthorized and surface a directive.
- Compound verdicts may expand into two persisted verdict rows or one row plus an emitted secondary authorization object, but the stored history must still make both boundaries reconstructible.

---

## Entity: BoundaryBypassRecord

Represents a session-scoped emergency bypass and every boundary crossed while that bypass remains active.

| Field | Type | Required | Rules |
| --- | --- | --- | --- |
| `session_id` | string | yes | Stable identifier for the started session |
| `reason` | string | yes | Must come from `--reason`; never blank |
| `recorded_at` | UTC timestamp | yes | Format `yyyy-MM-ddTHH:mm:ssZ` |
| `boundary` | canonical boundary or null | yes | Null only for the initial launch-time activation row |
| `launch_mode` | string | yes | e.g. `same-window/autonomous`, `same-window/gate-respecting` |
| `agent_response_snippet` | string or null | yes | Max 200 chars when present |
| `auth_commit_hash` | string or null | yes | Captures the boundary's authorization anchor when available |

### Two record shapes

1. **Activation row**: records the moment bypass is turned on for the session (`boundary = null`).
2. **Usage row**: records each bypassed boundary (`boundary = <canonical boundary>`).

---

## 4. Derived views (not persisted source fields)

These values satisfy the earlier FR-008/FR-009 placeholder wording without bloating the persisted schema:

| Derived field | Computation |
| --- | --- |
| `enforcement_events_count` | Count of enforcement entries in `.squad\decisions.md` for the active feature/session |
| `bypass_attempts_count` | Count of enforcement events where `bypass_attempt_detected = true` |
| `last_enforcement_timestamp` | Most recent enforcement ledger timestamp |
| `emergency_bypass_active` | `true` when the latest bypass activation row has no later session reset |

Design decision: counts remain dashboard/query projections. Histories are the source of truth because they support reconciliation and migration better than ad hoc counters.

---

## 5. Relationships

```text
session_state (existing)
  1 ── 1 boundary_enforcement
          1 ── * verdict_history
          1 ── * bypass_history

.squad\decisions.md
  * enforcement ledger entries reference the same session/boundary state
```

---

## 6. Migration path

## Case A: pre-065 session (no `boundary_enforcement` section)

### Trigger

First `specrew start` after upgrade finds:

- root schema `v0` or `v1`, and
- no `boundary_enforcement` object.

### Required behavior

1. Surface a migration directive before continuing.
2. After explicit acknowledgment, rewrite the file as schema `v2`.
3. Preserve the existing `session_state` and any unrelated keys.
4. Create:

```json
"boundary_enforcement": {
  "enabled": true,
  "last_authorized_boundary": "<current session_state.boundary_type or null>",
  "pending_next_boundary": null,
  "verdict_history": [],
  "bypass_history": []
}
```

### Why this shape

- Proposal 065 requires `enabled = true` plus empty histories after migration.
- The design does **not** synthesize fake historical verdicts.
- Copying the current boundary into `last_authorized_boundary` preserves restart continuity without inventing approvals for future boundaries.

## Case B: malformed `boundary_enforcement` payload

If the section exists but is malformed, migration is **not** automatic. The session must fail closed, surface a recovery directive, and require repair or an explicit emergency bypass.

## Case C: mirror parity

The same schema must be read and written by both:

- `extensions\specrew-speckit\scripts\shared-governance.ps1`
- `.specify\extensions\specrew-speckit\scripts\shared-governance.ps1`

No branch-specific schema fork is allowed.

---

## 7. Validation rules

| Rule | Enforcement |
| --- | --- |
| Root schema must be `v2` once `boundary_enforcement` exists | `Test-SessionStateBoundaryCanonical` extension |
| All persisted boundaries must be canonical nine-boundary names | shared-governance canonical boundary validator |
| `verdict_history` / `bypass_history` must be arrays even when empty | start-context reader/writer contract |
| `reason` is mandatory for every bypass row | launcher validation + state validator |
| `agent_response_snippet` max 200 chars | ledger/state writers truncate deterministically |
| Missing or corrupt `boundary_enforcement` never implies permissive mode | fail-closed reader semantics |

---

## 8. Example state transitions

### Blocked boundary

- Current `session_state.boundary_type = plan`
- Requested next boundary = `tasks`
- No matching verdict in `verdict_history`
- Result: `pending_next_boundary = tasks`, no history mutation, directive emitted, enforcement ledger entry written as `blocked`

### Approved continuation

- Maintainer types `approved for tasks-boundary entry`
- Parser emits authorized verdict for `plan -> tasks`
- `verdict_history += row`
- `last_authorized_boundary = tasks`
- `pending_next_boundary = null`

### Emergency bypass

- Session starts with `--bypass-boundary-enforcement --reason "schema migration replay"`
- `bypass_history += activation row`
- Each bypassed boundary appends a usage row and a matching enforcement ledger entry
- Next normal `specrew start` session returns to enforced mode unless bypass is requested again
