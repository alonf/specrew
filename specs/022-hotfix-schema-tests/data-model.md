# Phase 1 Design: Data Model

**Feature**: 022-hotfix-schema-tests  
**Branch**: `022-hotfix-schema-tests`  
**Date**: 2026-05-18

## Overview

Feature 022 remains file-based. Its design model centers on three runtime entities and one planning entity:

1. **Closeout Identity State**
2. **Boundary Sync Event**
3. **Restart Recovery Session**
4. **Iteration Work Package**

## Entity Definitions

### Entity 1: Closeout Identity State

**Purpose**: Represent the feature-closeout identity artifact stored at `.squad/identity/now.md`, preserving both human-readable summary content and machine-readable restart metadata.

| Attribute | Type | Description | Required | Constraints |
| --- | --- | --- | --- | --- |
| `updated_at` | timestamp | Last write time of the identity artifact | ✓ | ISO-8601 UTC |
| `focus_area` | string | Human-readable closeout focus summary | ✓ | Must remain understandable without reading machine fields |
| `active_issues` | list[string] | Human-readable issue snapshot | ✓ | Empty list allowed |
| `session_state_active` | boolean-like string | Machine-readable active flag | ✓ | `true` or `false` |
| `session_state_boundary` | string | Lifecycle boundary recorded at closeout | ✓ | Must be one of the seven supported boundaries; `feature-closeout` at closeout |
| `session_state_feature` | string | Feature ref slug | conditional | `(none)` when inactive after feature closeout |
| `session_state_feature_path` | string | Canonical feature path | conditional | `(none)` when inactive after feature closeout |
| `session_state_iteration` | string | Iteration number | conditional | Optional for feature-closeout state |
| `session_state_task` | string | Task identifier | conditional | `(none)` at closeout |
| `session_state_auth_commit` | string | Governing authorization/boundary commit | conditional | May be `(none)` when unavailable |
| `session_state_recorded_at` | timestamp | Machine-readable recording timestamp | ✓ | ISO-8601 UTC |
| `body_markdown` | markdown | Human-readable narrative below frontmatter | ✓ | Must not collapse into machine-only text |

**Validation Rules**:

- The artifact must contain both the human-readable fields and the `session_state_*` fields.
- `body_markdown` must remain non-empty.
- Restart parsing must succeed even when the human-readable fields expand.

### Entity 2: Boundary Sync Event

**Purpose**: Represent one ordered lifecycle synchronization event appended to `.squad/decisions.md`.

| Attribute | Type | Description | Required | Constraints |
| --- | --- | --- | --- | --- |
| `boundary_type` | enum | Lifecycle boundary that was reached | ✓ | `specify`, `clarify`, `plan`, `tasks`, `review-signoff`, `iteration-closeout`, `feature-closeout` |
| `feature_ref` | string/null | Feature slug tied to the event | ✓ | Null only after feature-closeout deactivation |
| `iteration_number` | string/null | Iteration in scope | ✗ | Required for iteration-closeout |
| `task_id` | string/null | Task-level reference | ✗ | Null for this hotfix planning scope |
| `auth_commit_hash` | string/null | Commit hash persisted with the boundary | ✗ | Must never remain the literal string `HEAD` after persistence |
| `recorded_at` | timestamp | Ordered ledger timestamp | ✓ | ISO-8601 UTC |
| `state_surface_alignment` | object | Agreement snapshot across prompt/context/identity/ledger | ✓ | Must remain observable when mismatched |

**Validation Rules**:

- A full lifecycle run must yield exactly seven ordered `Boundary sync:` entries.
- The final boundary must agree across the state surfaces.
- A missed or malformed event must remain visible to stale-state validation.

### Entity 3: Restart Recovery Session

**Purpose**: Represent the operator-facing flow entered after stale-state detection or by explicit `--recover`.

| Attribute | Type | Description | Required | Constraints |
| --- | --- | --- | --- | --- |
| `entry_mode` | enum | How recovery was entered | ✓ | `detected-stale-state` or `explicit-recover-flag` |
| `stale_reasons` | list[string] | Reasons restart entered recovery | ✓ | At least one human-readable reason |
| `choice_set` | enum set | Allowed operator choices | ✓ | Must include `A`, `B`, `C` for interactive mode |
| `selected_choice` | string/null | Operator selection | ✗ | Null before a choice is made |
| `bypass_gate` | boolean | Whether stale-state blocking was bypassed | ✓ | True only for `--recover` |
| `approval_mode_changed` | boolean | Whether recovery changed approval behavior | ✓ | Must remain `false` for Feature 022 |
| `next_action_message` | string | Operator guidance after entry/selection | ✓ | Must explain what happens next |

**Validation Rules**:

- `--recover` must set `bypass_gate = true` while leaving `approval_mode_changed = false`.
- Interactive stale-state detection must expose A/B/C before exit decisions occur.
- Recovery must explain why it was entered and what the next step is.

### Entity 4: Iteration Work Package

**Purpose**: Represent one grouped planning work package in `iterations/001/plan.md`.

| Attribute | Type | Description | Required | Constraints |
| --- | --- | --- | --- | --- |
| `work_package_id` | string | Stable grouped package identifier | ✓ | `I1-W###` style |
| `title` | string | Human-readable work package name | ✓ | Non-empty |
| `requirement_refs` | list[string] | Requirements covered | ✓ | Must trace to approved FR/SC refs |
| `story_refs` | list[string] | User stories covered | ✓ | Must stay within US1-US3 |
| `effort_sp` | number | Planned story-point allocation | ✓ | Total planned work + reserve <= 10 |
| `owner_role` | string | Baseline Squad role owner | ✓ | Spec Steward, Implementer, or Reviewer only for this slice |
| `status` | enum | Planning status | ✓ | `planned` at plan completion |

## Relationships

- One **Closeout Identity State** is validated against one or more **Restart Recovery Sessions**.
- One **Boundary Sync Event** is generated at each lifecycle boundary and cross-checks the **Closeout Identity State** and other state surfaces.
- One **Iteration Work Package** may implement or verify one or more **Boundary Sync Events** and **Restart Recovery Session** behaviors.

## State Transitions

### Boundary Sync Event

```text
planned
  -> emitted
  -> recorded
  -> validated
```

### Restart Recovery Session

```text
entry-detected
  -> explained
  -> choice-presented
  -> action-selected
  -> resumed | re-anchored | exited
```

### Closeout Identity State

```text
runtime-active
  -> feature-closeout-written
  -> parser-validated
  -> inactive-but-readable
```

## Design Notes

- The hotfix keeps the model file-based and bounded to existing Specrew state surfaces.
- No unresolved data-model clarifications remain after Phase 1.
