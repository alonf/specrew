# Data Model: Validator Hardening

**Date**: 2026-05-12
**Spec**: [spec.md](spec.md)
**Plan**: [plan.md](plan.md)

## Entities

### Canonical Iteration State Schema

The normative set of eight metadata fields required in every newly created or materially updated iteration `state.md` after feature 013 rollout.

**Location**: `specs/<feature>/iterations/<NNN>/state.md`

**Contract reference**: `specs/013-validator-hardening/contracts/iteration-state-schema.md`

| Field | Canonical Pattern | Description |
| --- | --- | --- |
| `Schema` | `**Schema**:` | Version or identifier of the schema governing this state file |
| `Last Completed Task` | `**Last Completed Task**:` | Most recently completed task identifier or label |
| `Tasks Remaining` | `**Tasks Remaining**:` | Count or list of tasks not yet completed |
| `In Progress` | `**In Progress**:` | Task(s) currently being worked on, or `(none)` |
| `Baseline Ref` | `**Baseline Ref**:` | Git commit hash or tag that marks the iteration baseline |
| `Updated` | `**Updated**:` | ISO date of the most recent update to this file |
| `Current Phase` | `**Current Phase**:` | Lifecycle phase identifier (e.g., `planning`, `executing`) |
| `Iteration Status` | `**Iteration Status**:` | Free-form status description; inspected for closure keywords |

**Validation rules**:
- Each field must appear as `**<FieldName>**:` (bold label + colon) on its own line.
- Pending/placeholder values are valid as long as the canonical field name is present.
- Additional narrative sections beyond the canonical fields are allowed and must not cause false positives.
- Iterations that existed before feature 013 rollout are grandfathered unless materially reopened or rewritten.

---

### Canonical Hardening-Gate Concerns

The five required concern rows that must appear as the first five rows of the `Concern Review` table in every `quality/hardening-gate.md`.

**Location**: `specs/<feature>/iterations/<NNN>/quality/hardening-gate.md`

**Contract reference**: `specs/013-validator-hardening/contracts/hardening-gate-concerns.md`

| Position | Concern ID | Category |
| --- | --- | --- |
| 1 | `security-surface` | `security` |
| 2 | `error-handling-expectations` | `error-handling` |
| 3 | `retry-idempotency-requirements` | `retry-idempotency` |
| 4 | `test-integrity-targets` | `test-integrity` |
| 5 | `operational-resilience-concerns` | `operational` |

**Validation rules**:
- The validator checks that concern identifiers in positions 1–5 match this list exactly, in order.
- Feature-specific additional concerns may follow after position 5.
- Missing or reordered canonical concerns produce a structured FAIL naming the missing concern and expected position.

---

### Implementation Approval Evidence Quote

A normalized text excerpt from the `Implementation Approval` block in `plan.md` or `state.md` that records human authorization for an iteration to proceed.

**Location**: `specs/<feature>/iterations/<NNN>/plan.md` or `state.md` — `Implementation Approval` section

| Field | Type | Description |
| --- | --- | --- |
| `raw_text` | string | Original approval quote as written |
| `normalized_text` | string | Whitespace-collapsed, Markdown-emphasis-stripped version used for comparison |
| `source_iteration_path` | path | Relative path to the artifact containing this quote |
| `blanket_scope_declared` | boolean | Whether the artifact contains an explicit blanket multi-iteration authorization declaration |

**Validation rules**:
- Two quotes are considered duplicated when their `normalized_text` values are identical after whitespace collapse and stripping of `*` and `_` emphasis markers.
- Duplication is a FAIL condition unless `blanket_scope_declared` is true for at least one of the matching artifacts.
- `blanket_scope_declared` is detected by a line containing both `blanket` and `multi-iteration authorization` (case-insensitive) within the approval block.

---

### Iteration Closeout Evidence Set

The required set of artifacts and conditions that must all be satisfied before an iteration may claim a closed status.

**Location**: `specs/<feature>/iterations/<NNN>/`

| Evidence Element | Required Condition | FAIL Trigger |
| --- | --- | --- |
| `review.md` | Must exist and have an accepted overall verdict | Missing or non-accepted review |
| `retro.md` | Must exist | Missing retro |
| `quality/hardening-gate.md` | Post-implementation evidence must be recorded for all required concerns | Concerns still in pre-implementation pending state |
| Working tree cleanliness | No uncommitted changes to files inside the iteration directory's canonical artifact set | Uncommitted iteration-directory changes |

**Validation rules**:
- The `Iteration Status` field is inspected for closure-oriented keywords (e.g., `closed`, `closeout complete`).
- Dirty-tree check uses `git status --porcelain` and filters to paths under the iteration directory.
- Repo-level governance traces such as `.squad/decisions.md` and `.squad/identity/now.md` are excluded from the dirty-tree failure condition.

---

### Copilot Instructions Change Classification

The result of classifying a diff or before/after pair of `.github/copilot-instructions.md` content.

| Field | Type | Description |
| --- | --- | --- |
| `classification` | enum (`bookkeeping` / `behavior`) | Outcome of the classifier |
| `changed_sections` | string[] | List of sections that changed in the diff |
| `bookkeeping_sections` | string[] | Sections considered bookkeeping-only: `## Active Technologies`, `## Recent Changes`, and timestamp lines |
| `requires_restart` | boolean | `true` when `classification == behavior` |

**Validation rules**:
- A change is `bookkeeping` when all changed content falls within the timestamp line, `## Active Technologies` section, or `## Recent Changes` section.
- Any change outside those sections makes the classification `behavior`.
- When bookkeeping-only edits are mixed with behavior edits in a single change set, the more conservative `behavior` classification wins.

---

### Structured Validator FAIL Output

The normalized error record emitted for every validator failure, replacing raw PowerShell exceptions.

| Field | Type | Description |
| --- | --- | --- |
| `file_path` | string | Relative path to the artifact, or `(none)` when no specific file applies |
| `line_number` | int? | Line number within the file where the violation was detected, when applicable |
| `category` | string | Short category label identifying the rule (e.g., `canonical-schema`, `concern-order`, `approval-reuse`, `over-claim`, `parse-failure`) |
| `message` | string | Human-readable description of the violation |
| `remediation_hint` | string | Actionable guidance for fixing the violation |

**Validation rules**:
- Every new and existing check function must produce output conforming to this structure.
- The validator must complete the full validation pass even when individual checks fail; errors are accumulated and reported together.
- The validator must exit with a non-zero exit code when any FAIL is emitted.

## Relationships

- `Canonical Iteration State Schema` is the normative reference for the FR-001 validation rule; the contract document at `specs/013-validator-hardening/contracts/iteration-state-schema.md` is the authoritative published form.
- `Canonical Hardening-Gate Concerns` is the normative reference for the FR-002 validation rule; the contract document at `specs/013-validator-hardening/contracts/hardening-gate-concerns.md` is the authoritative published form.
- `Implementation Approval Evidence Quote` is compared across sibling `Iteration Closeout Evidence Set` artifacts in FR-003 reuse detection.
- `Iteration Closeout Evidence Set` is the compound check entity used by FR-004 over-claim enforcement; it references the `Canonical Hardening-Gate Concerns` to determine whether post-implementation evidence is present.
- `Structured Validator FAIL Output` is the output contract for every entity above; it applies uniformly to all six new rules and to all existing checks (FR-005 / FR-010).
- `Copilot Instructions Change Classification` is produced by the standalone helper consumed by `specrew-start.ps1` and optionally validated by `validate-governance.ps1` (FR-006).
