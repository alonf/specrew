# Hardening Gate: Iteration 001

**Feature**: 139-boundary-authorization-prompt-truth
**Iteration**: 001
**Date**: 2026-06-01
**Overall Verdict**: ready

## Concern Review

| Concern | Status | Requirement Refs | Planned Controls | Evidence Target | Rationale | Owner | Review Lens | Notes |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Boundary policy truth | addressed | FR-001, FR-002, FR-004, FR-020 | Resolve policy from `.specrew/config.yml`; emit `boundary_enforcement.policy_classes`; test generated prompt and state snapshot. | T004-T006, T028 | The release blocker is prompt/state truth drift. | Implementer | Functional correctness | Default `clarify -> plan` stop must be explicit. |
| Beta2 prompt regression | addressed | FR-001, FR-003, FR-007 | Remove four-gate-only and auto-chain wording; add negative fixtures for beta2-bad phrases. | T007-T010, T028 | Prevents repeat beta2 smoke bypass. | Implementer | Test integrity | Failing fixture required. |
| Human re-entry packet shape | addressed | FR-008-FR-019, FR-023-FR-028 | Implement six-section packet, no required legacy duplication, grouped prompts, `discuss prompt #N`, explicit approval semantics, and bare `file:///` targets. | T011-T021, T028 | Boundary stops must be human re-entry points, not thin approval prompts. | Implementer | Human factors | `Status: Approved` and beta3 smoke are release-blocking review callouts. |
| Status approval contradiction | addressed | FR-005, FR-021 | Add narrow check for `Status: Approved` without matching verdict evidence plus positive/negative tests. | T025-T026, T028 | Prevents agent-authored readiness from masquerading as approval. | Implementer | System safety | Broad historical Proposal 151 migration remains out of scope. |
| Smoke evidence | addressed | FR-022 | Update committed beta3 smoke evidence artifact with version, fresh project, stop boundary, pre-approval plan state, packet excerpt, approval state, PASS/FAIL. | T027 | Release promotion requires observable downstream proof. | Implementer | System safety | Separate task, not review prose only. |
| Branch/state hygiene | addressed | TG-004, TG-005 | Classify dirty files before implementation; exclude unrelated session/runtime files unless explicitly classified. | T002, drift log | Prevents mixing runtime/session state into feature commits. | Implementer | Branch hygiene | Current dirty files are excluded by default. |
| Scope containment | addressed | TG-005 | Keep full Proposal 150, hook enforcement, broad historical Proposal 151 migration, and lifecycle redesign out of scope. | T030 | Keeps release-blocking fix tight. | Reviewer | Scope safety | Any scope-risk finding must be fixed or sent back. |
| Review gap ledger | addressed | TG-006 | Review must classify behavior as implemented/enforced/observable/documented and fix or send back gaps. | T029 | Proposal 145 lens must be visible at review without implementing Proposal 145. | Reviewer | Output synthesis | Required before release promotion. |
| Runtime concurrency | not-applicable | n/a | No concurrent runtime behavior is introduced. | n/a | Prompt/state generation and validation are deterministic file operations in this slice. | Reviewer | Non-functional | No lock or race semantics added. |
| Hook enforcement | not-applicable | n/a | Do not implement hook-based runtime enforcement. | n/a | Explicitly out of scope. | Reviewer | Scope safety | Keep out of implementation. |

## Required Pre-Implementation Controls

- T001-T003 must run before code edits to load context, classify dirty state, and select focused tests.
- T004-T021 must preserve the generated prompt as the behavioral authority for future agents.
- T022-T026 must make non-compliance mechanically visible through fixtures/tests.
- T027-T030 must produce smoke evidence, validation evidence, and the review gap ledger.

## Release-Blocking Items

- `Status: Approved` without verdict evidence check.
- Committed beta3 smoke evidence.
- Negative prompt tests for beta2-bad phrases.
- Non-compliant handoff fixtures for missing `Why I stopped`, approve-only prompts, and context-free targeted prompts.
- Review gap ledger covering implemented/enforced/observable/documented.
