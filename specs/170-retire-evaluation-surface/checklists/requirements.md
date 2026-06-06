# Requirements Quality Checklist: Retire Top-Level Evaluation Surface

**Feature**: file:///C:/Dev/Specrew/specs/170-retire-evaluation-surface/spec.md
**Created**: 2026-06-06
**Purpose**: Validate that the specify-phase requirements from Proposal 169 are complete enough to enter clarification, given that the implementation was adopted ahead of governance (commit `3b6a3e0d`) and this feature verifies and finishes it.

## Content Quality

- [x] User value and risk are clear: the repository must stop advertising a phantom public evaluation harness while CI keeps its lifecycle-quality regression net.
- [x] Requirements are testable and independently reviewable (FR-001..FR-008 each map to a deterministic check).
- [x] Success criteria are measurable: tracked-file listing, test exit codes, reference scan, and index/status evidence (SC-001..SC-005).
- [x] Scope exclusions are explicit: no outcome-quality scorer design, no historical-artifact rewrites, no CI job-name or test-semantics changes, no new product-facing evaluation command.
- [x] The adoption-before-governance conflict is declared with a reconciliation path (TG-004).

## Requirement Completeness

- [x] Functional requirements cover surface removal, scorer relocation + classification, all three test-continuity obligations, docs truthfulness, audit trail, and history preservation.
- [x] Acceptance scenarios cover tracked-file absence, docs wording, both integration-test runs, smoke-test parse + path assertion, audit-trail readability, and historical-artifact immutability.
- [x] Edge cases cover non-root invocation, missing scratch directory, and Windows/Linux path-separator behavior.
- [x] Key entities are defined for the scorer (test-support library) and the generated report (transient untracked output).
- [x] Requirements have owner roles (TG-002) and a delivery window (TG-003, single iteration).

## Governance Readiness

- [x] The spec remains in `Draft` status and does not claim human approval.
- [x] Human oversight points enumerate all configured human-judgment boundaries.
- [x] Drift signals identify the validator, per-iteration drift log, and the SC-004 reference scan.
- [x] The lens workshop ran at intake: one light architecture-core lens (human-confirmed), eight recorded skips (`lens-applicability.json`).

## Clarification Resolution

- [x] QC-001: Clean break confirmed — no stub or pointer remains for a future evaluation surface; retirement-explanation wording in docs is the only permitted mention (workshop, human-confirmed).
- [x] QC-002: `tests/support/` confirmed as the long-term home for shared test infrastructure (workshop, human-confirmed).
- [x] QC-003: Frozen 015 fixtures keep their `evaluation/` mentions as historical test inputs (FR-008 assumption, from proposal out-of-scope list).
