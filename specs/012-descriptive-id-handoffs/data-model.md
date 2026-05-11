# Data Model: Descriptive References in Handoffs

**Feature**: `012-descriptive-id-handoffs`  
**Phase**: Phase 1 – Design  
**Branch**: `012-keep-descriptive-refs`  
**Date**: 2026-05-11  
**Status**: Complete

---

## Scope Note

This feature does not introduce database tables or runtime domain storage. The "data model" for this feature is the content-and-validation model for authored handoff prose, readable numeric references, and the non-blocking governance findings that review those handoffs.

---

## Entity 1 — Authored Handoff Message

| Field | Value |
| --- | --- |
| **Entity name** | Authored Handoff Message |
| **Purpose** | The Squad-authored narration or stop message shown to a human reviewer |
| **Source surfaces** | Coordinator progress narration and final stop/handoff messages |
| **Key requirements** | FR-001 through FR-007, FR-010 |

### Fields

| Field | Type | Rules |
| --- | --- | --- |
| `messageSurface` | enum (`narration`, `stop-message`) | Must stay inside the approved user-facing scope |
| `sections` | ordered list | May be three-section or lightweight single-paragraph format |
| `authoredSegments` | list of prose blocks | Only these segments are eligible for descriptive-reference review |
| `excludedSegments` | list of verbatim/code/tool/quoted blocks | Must be ignored by the descriptive-reference rule |
| `existingHandoffState` | object | Carries feature 007 semantics such as progress status, next step, blocker disclosure, and file-review guidance |

### Validation Rules

- Must preserve feature 007 handoff semantics; descriptive references are additive, not a replacement.
- Must not treat verbatim quoted material, code blocks, raw tool output, or Copilot-rendered tool-call result blocks as authored segments.
- May remain lightweight if both the feature 007 handoff semantics and the descriptive-reference semantics stay explicit.

### State Transitions

`drafted` → `authored` → `soft-reviewed` → `delivered`

---

## Entity 2 — Numeric Reference

| Field | Value |
| --- | --- |
| **Entity name** | Numeric Reference |
| **Purpose** | A user-facing identifier that needs human-readable meaning |
| **Source surfaces** | Authored Handoff Message segments |
| **Key requirements** | FR-001 through FR-004, FR-006 |

### Fields

| Field | Type | Rules |
| --- | --- | --- |
| `referenceType` | enum (`feature`, `iteration`, `task`, `requirement`, `corpus`, `commit`) | Must match one of the approved identifier classes |
| `rawToken` | string | Stores the original reference token shown to the user |
| `segmentIndex` | integer | Tracks where the reference appeared in authored prose |
| `firstMentionInContext` | boolean | Later mentions may rely on the first nearby explanation within a short context |
| `descriptiveScopeMode` | enum (`inline`, `shared`, `carried-forward`, `missing`) | `missing` is only acceptable below the warning threshold |

### Validation Rules

- Every reference in authored prose should have descriptive scope nearby or be covered by a valid shared scope statement.
- Grouped lists or ranges may use `shared` scope only when the labeling phrase is in the same sentence or immediately adjacent text.
- Ordinary numeric prose that is not acting as an identifier must not be modeled as a Numeric Reference.

### State Transitions

`detected` → `classified` → `described` or `warned`

---

## Entity 3 — Descriptive Scope

| Field | Value |
| --- | --- |
| **Entity name** | Descriptive Scope |
| **Purpose** | The plain-language explanation that tells the reader what a numeric reference means |
| **Source surfaces** | Inline handoff prose or shared group labels |
| **Key requirements** | FR-001 through FR-005, FR-007 |

### Fields

| Field | Type | Rules |
| --- | --- | --- |
| `scopeText` | string | Must be plain-language and understandable on first read |
| `scopeMode` | enum (`inline`, `shared`) | `shared` covers a clearly bounded list or range only |
| `coveredReferences` | list of Numeric Reference IDs | One-to-many allowed for grouped lists or ranges |
| `adjacencyRule` | enum (`same-sentence`, `immediately-adjacent`) | Must satisfy the spec's proximity requirement |
| `exampleStatus` | enum (`acceptable`, `unacceptable`) | Used by worked examples and seeded fixtures |

### Validation Rules

- Scope must explain meaning, not merely repeat the numeric token.
- Shared scope must unambiguously cover the full group it claims to label.
- Worked examples must show both compliant and non-compliant patterns.

### State Transitions

`drafted` → `attached` → `reviewed`

---

## Entity 4 — Governance Review Finding

| Field | Value |
| --- | --- |
| **Entity name** | Governance Review Finding |
| **Purpose** | Non-blocking warning output from the descriptive-reference review rule |
| **Source surfaces** | Handoff-governance validator and checklist review |
| **Key requirements** | FR-008, FR-009, FR-010, SC-004 |

### Fields

| Field | Type | Rules |
| --- | --- | --- |
| `findingCode` | enum | Planned addition for opaque numeric references plus existing feature 007 soft-warning codes |
| `severity` | enum (`soft-warning`) | Must remain non-blocking |
| `triggerCount` | integer | The descriptive-reference warning threshold is 3 or more opaque numeric references |
| `findingSurface` | enum (`narration`, `stop-message`) | Must stay inside the approved authored-message scope |
| `excludedEvidence` | list | Records ignored verbatim segments when relevant to review/debugging |

### Validation Rules

- Must not change existing feature 007 warnings from soft to blocking.
- Must distinguish authored prose failures from excluded verbatim content.
- Should coexist with existing warnings such as jargon-first lead, missing next step, and missing review-file URI.

### State Transitions

`none` or `soft-warning-issued`

---

## Entity 5 — Replay Fixture / Corpus Seed

| Field | Value |
| --- | --- |
| **Entity name** | Replay Fixture / Corpus Seed |
| **Purpose** | Seeded examples that prove warn/pass behavior through the real replay and governance paths |
| **Source surfaces** | `tests/integration/fixtures/**`, `tests/integration/**`, `.specrew/quality/known-traps.md` |
| **Key requirements** | FR-007, FR-008, FR-009, SC-004, TG-006 |

### Fields

| Field | Type | Rules |
| --- | --- | --- |
| `fixtureId` | string | Stable identifier for replay and corpus evidence |
| `fixtureClass` | enum (`warn`, `pass`) | Must cover both failing and compliant examples |
| `replayPath` | string | Must exercise the real scaffold/replay path instead of state-file-only assertions |
| `expectedFinding` | list of finding codes | Warn fixtures must name the expected soft-warning; pass fixtures must expect none for this rule |
| `seedStatus` | enum (`planned`, `approved`, `seeded`, `executed`) | Planning phase leaves these as `planned` |

### Validation Rules

- Must verify authored-prose behavior, not just internal files.
- Must include examples for grouped/shared scope and excluded verbatim content.
- Must remain bounded to non-blocking governance review.

### State Transitions

`planned` → `approved` → `seeded` → `executed` → `reviewed`

---

## Relationships

| Relationship | Cardinality | Rule |
| --- | --- | --- |
| Authored Handoff Message → Numeric Reference | one-to-many | A message may contain zero or more modeled numeric references |
| Numeric Reference → Descriptive Scope | many-to-one or many-to-many via shared scope | Each modeled reference should have inline or shared scope unless it remains below the warning threshold |
| Authored Handoff Message → Governance Review Finding | one-to-many | A single message can emit multiple soft warnings from the combined handoff-governance rule set |
| Replay Fixture / Corpus Seed → Governance Review Finding | one-to-many | Fixtures encode expected warn/pass outcomes |

---

## Cross-Entity Consistency Obligations

| Obligation | Description |
| --- | --- |
| `C-001` | Descriptive-reference guidance must preserve the existing feature 007 handoff semantics inside the same message |
| `C-002` | The validator, checklist, template, and worked examples must use the same definition of `descriptive scope` |
| `C-003` | Excluded verbatim segments must be ignored consistently across validator logic, checklist guidance, and replay fixtures |
| `C-004` | The descriptive-reference finding must stay `soft-warning` only |
| `C-005` | Replay fixtures and corpus seeds must prove both warn and pass outcomes before closeout |

---

## Summary

| Entity | Role | Key Design Decision |
| --- | --- | --- |
| Authored Handoff Message | Delivery surface | Extend feature 007 surfaces instead of creating a new handoff format |
| Numeric Reference | Target token | Model only identifier-like numeric references in authored prose |
| Descriptive Scope | Human-readable meaning | Allow inline and tightly bounded shared scope |
| Governance Review Finding | Soft review output | Keep warnings non-blocking and compatible with feature 007 |
| Replay Fixture / Corpus Seed | Proof artifact | Add scaffold-replay-path coverage and corpus seeding in Iteration 002 |
