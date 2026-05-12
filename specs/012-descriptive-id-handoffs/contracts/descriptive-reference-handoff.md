# Descriptive Reference Handoff Contract

**Feature**: `012-descriptive-id-handoffs`  
**Contract type**: User-facing handoff readability contract  
**Version**: 1.0.0  
**Date**: 2026-05-11  
**Status**: Approved for implementation planning

---

## Purpose

This contract defines the minimum semantic obligations for descriptive numeric references inside Squad-authored user-facing narration and stop messages. It is additive to the feature 007 handoff contract: implementations must still make progress status and recommended next step explicit when those semantics apply.

This contract does not require exact wording. It defines what meaning must be present, where it must appear, which surfaces are excluded, and how the non-blocking governance review should behave.

---

## Surface 1 — In-Flight Narration

**FR traceability**: FR-001, FR-002, FR-003, FR-004, FR-005, FR-006, FR-007, FR-010  
**Delivery type**: Primary delivery target

### Required Elements

| Clause | Semantic Obligation | Placement |
| --- | --- | --- |
| `NAR-C1` | Every feature number mentioned in authored narration MUST include a brief description of the feature's purpose | Same sentence or immediately adjacent text |
| `NAR-C2` | Every iteration number mentioned in authored narration MUST include a brief description of the slice being delivered | Same sentence or immediately adjacent text |
| `NAR-C3` | Every task code, requirement code, corpus reference, or commit reference mentioned in authored narration MUST include plain-language context explaining what it represents | Same sentence or immediately adjacent text |
| `NAR-C4` | A grouped list or range of numeric references MAY use one shared scope statement only when that statement clearly labels the full group | Same sentence or immediately adjacent text |
| `NAR-C5` | Worked examples MUST include at least one acceptable and one unacceptable narration example for this rule | Prompt, template, checklist, or companion example sections |
| `NAR-C6` | Existing feature 007 handoff semantics remain required when narration also communicates progress state or next action | Same authored message |

### Forbidden Content

- MUST NOT rely on opaque numeric references alone when authored narration expects a human to understand the work.
- MUST NOT treat quoted content, code blocks, raw tool output, or Copilot-rendered tool-call result blocks as authored narration.
- MUST NOT weaken or remove existing feature 007 handoff expectations.

### Example (non-normative)

> I updated **feature 012, descriptive references in handoffs**, and aligned **iteration 001, the readable-reference rule rollout** across the validator and coordinator guidance.

---

## Surface 2 — Stop Messages and Handoffs

**FR traceability**: FR-001, FR-002, FR-003, FR-004, FR-006, FR-007, FR-010  
**Delivery type**: Primary delivery target

### Required Elements

| Clause | Semantic Obligation | Placement |
| --- | --- | --- |
| `STOP-C1` | Every numeric reference used in completed-work, blocked-work, or follow-up lists MUST include nearby descriptive scope or be covered by a valid shared scope statement | Same sentence or immediately adjacent text |
| `STOP-C2` | Commit references MUST include a short explanation of why the commit matters to the handoff | Same sentence or immediately adjacent text |
| `STOP-C3` | Blocked-item and requested-follow-up lists MUST explain what each numeric reference covers without requiring the reader to open another artifact | Same authored bullet or adjacent sentence |
| `STOP-C4` | The stop message MUST continue to satisfy existing feature 007 progress-status, blocker/risk, and recommended-next-step expectations | Same stop message |

### Forbidden Content

- MUST NOT replace the current progress status or recommended next step with numeric-reference commentary alone.
- MUST NOT defer meaning to a separate artifact when a short in-message description is practical.

### Example (non-normative)

> I finished the Iteration 001 guidance update for **feature 012, descriptive references in handoffs**, but I stopped before the Iteration 002 replay work. Next step: review the validator wording and examples before we seed the new replay fixtures.

---

## Surface 3 — Governance Review

**FR traceability**: FR-006, FR-008, FR-009, FR-010  
**Delivery type**: Governance and verification target

### Required Elements

| Clause | Semantic Obligation | Placement |
| --- | --- | --- |
| `GOV-C1` | The readability review for opaque numeric references MUST remain a `soft-warning` and MUST NOT block response delivery on its own | Validator, checklist, and validation-lane guidance |
| `GOV-C2` | The rule MUST warn when authored narration or stop-message prose contains three or more numeric references without descriptive scope | Validator and checklist behavior |
| `GOV-C3` | The rule MUST ignore numeric references that appear only inside excluded verbatim content | Validator, checklist, and replay fixtures |
| `GOV-C4` | Existing feature 007 soft warnings must continue to operate alongside the new descriptive-reference warning | Validator and checklist behavior |
| `GOV-C5` | Seeded warn/pass examples for this rule must be planned for replay-path coverage and corpus seeding | Integration tests, validation lane, and known-traps evidence |

### Forbidden Content

- MUST NOT escalate this rule to a blocking failure without a new approved spec change.
- MUST NOT count numeric prose from excluded verbatim surfaces toward the warning threshold.

### Example (non-normative)

Warn:
> Completed 012, 001, FR-008, FR-009, and abc1234. Next step: review.

Pass:
> Completed **feature 012, descriptive references in handoffs**, and finished **iteration 001, the validator-and-guidance rollout**. The follow-up review still needs **FR-008 and FR-009, the non-blocking governance review requirements**, before we seed replay fixtures.

---

## Cross-Surface Consistency Matrix

| Clause Family | Narration | Stop Message | Governance Review |
| --- | --- | --- | --- |
| Feature and iteration references are described | Required | Required | Verified |
| Task / requirement / corpus / commit references are described | Required | Required | Verified |
| Shared scope for grouped lists is tightly bounded | Required | Required | Verified |
| Excluded verbatim content is ignored | Required | Required | Required |
| Feature 007 progress / next-step semantics are preserved | Required | Required | Verified |
| Non-blocking warning behavior remains intact | N/A | N/A | Required |

---

## Acceptance Criteria Mapping

| Success Criterion | Contract Clauses That Cover It |
| --- | --- |
| SC-001 | `NAR-C1`, `NAR-C2`, `STOP-C1` |
| SC-002 | `NAR-C3`, `NAR-C4`, `STOP-C1`, `STOP-C2`, `STOP-C3` |
| SC-003 | `NAR-C1` through `NAR-C4`, `STOP-C1` through `STOP-C3` |
| SC-004 | `GOV-C1` through `GOV-C5` |
