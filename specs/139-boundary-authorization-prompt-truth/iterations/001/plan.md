# Iteration Plan: 001

**Schema**: v1
**Spec**: [../../spec.md](../../spec.md)
**Status**: planning
**Capacity**: 17.75/20 story_points
**Started**: 2026-06-01
**Completed**:

## Scope Summary

Iteration 001 implements the full Proposal 154 slice for generated prompt truth, boundary policy state, six-section human re-entry packets, prompt-regression fixtures, the narrow `Status: Approved` evidence check, and committed beta3 smoke evidence. It also carries the human-approved pre-implementation refinements: the future generated packet is the primary stop contract, bare `file:///` review targets are mandatory, release-blocking review items must be called out, discussion prompts are grouped, and `discuss prompt #N` enters a short discussion loop before renewed explicit boundary approval.

| Requirement | Summary | Stories |
| --- | --- | --- |
| FR-001-FR-004 | Derive generated boundary truth from policy and stop at `clarify -> plan`. | US1 |
| FR-005, FR-021 | Distinguish readiness from human approval and flag `Status: Approved` without verdict evidence. | US1, US3 |
| FR-006-FR-007 | Keep prompt/governance vocabulary aligned and reject beta2-bad prompt phrases. | US1, US3 |
| FR-008-FR-019 | Implement the six-section human re-entry packet, approval semantics, and contextual discussion prompt rules. | US2, US3 |
| FR-020 | Emit `boundary_enforcement.policy_classes` in generated `start-context.json`. | US1 |
| FR-022 | Produce committed beta3 smoke evidence. | US3 |
| FR-023-FR-028 | Apply primary-packet/no-legacy-duplication, bare `file:///`, release-blocking review callouts, grouped prompts, `discuss prompt #N`, and response-option refinements. | US2, US3 |
| TG-004-TG-006 | Record drift/reconciliation, preserve scope exclusions, and review implemented/enforced/observable/documented gaps. | US1, US2, US3 |

## Tasks

| Task | Title | Requirement | Story | Effort | Owner | Owner File Globs | Status | Agent | Actual | Verdict |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| T001 | Load Proposal 154, beta2 smoke, Feature 016, six-section packet, and Proposal 145 review lens context | FR-006, TG-005, TG-006 | US1/US2/US3 | 0.5 | Spec Steward | `proposals/**`, `specs/016-*/**`, `specs/139-*/**` | planned | codex |  |  |
| T002 | Classify dirty working-tree files and exclude unrelated session/runtime edits unless explicitly needed | FR-022, TG-004, TG-005 | US3 | 0.5 | Implementer | `.codex/**`, `.squad/**`, `.specrew/**`, `specs/051-*/**` | planned | codex |  |  |
| T003 | Discover or create exact focused test files and fixtures before implementation | FR-007, FR-021 | US3 | 0.5 | Implementer | `tests/**` | planned | codex |  |  |
| T004 | Resolve boundary policy from authoritative `.specrew/config.yml` in `specrew start` | FR-001, FR-002, FR-004 | US1 | 1.0 | Implementer | `scripts/specrew-start.ps1`, `scripts/internal/**` | planned | codex |  |  |
| T005 | Persist resolved `boundary_enforcement.policy_classes` in generated `start-context.json` | FR-002, FR-020 | US1 | 0.5 | Implementer | `scripts/specrew-start.ps1`, `.specrew/start-context.json` | planned | codex |  |  |
| T006 | Add positive tests for policy snapshot and configured human-judgment boundary rendering | FR-002, FR-020 | US1 | 0.5 | Implementer | `tests/**` | planned | codex |  |  |
| T007 | Remove beta2-bad four-gate-only generated wording | FR-001, FR-006 | US1 | 0.75 | Implementer | `scripts/specrew-start.ps1`, `extensions/**/specrew-governance.md`, `.github/agents/squad.agent.md` | planned | codex |  |  |
| T008 | Remove generated auto-chain guidance across clarify/plan/tasks when boundaries require human judgment | FR-003, FR-004, FR-006 | US1 | 0.75 | Implementer | `scripts/specrew-start.ps1`, `extensions/**/specrew-governance.md`, `.github/agents/squad.agent.md` | planned | codex |  |  |
| T009 | Render explicit `clarify -> plan` authorization and readiness-vs-approval guidance | FR-003, FR-004, FR-006 | US1 | 0.5 | Implementer | `scripts/specrew-start.ps1`, `extensions/**/specrew-governance.md` | planned | codex |  |  |
| T010 | Add negative beta2 phrase prompt-regression fixtures/tests | FR-007 | US3 | 0.5 | Implementer | `tests/**` | planned | codex |  |  |
| T011 | Replace approval-stop wording with six-section human re-entry packet contract | FR-008, FR-009 | US2 | 0.75 | Implementer | `scripts/specrew-start.ps1`, `extensions/**/specrew-governance.md` | planned | codex |  |  |
| T012 | Add generated guidance for meaningful `What I just did` and concrete `Why I stopped` | FR-010, FR-011 | US2 | 0.5 | Implementer | `scripts/specrew-start.ps1`, `extensions/**/specrew-governance.md` | planned | codex |  |  |
| T013 | Add generated guidance for targeted review surfaces and next-phase preview | FR-012, FR-013 | US2 | 0.75 | Implementer | `scripts/specrew-start.ps1`, `extensions/**/specrew-governance.md` | planned | codex |  |  |
| T014 | Add contextual, decision-reducing discussion prompt guidance | FR-014, FR-015, FR-018 | US2 | 0.75 | Implementer | `scripts/specrew-start.ps1`, `extensions/**/specrew-governance.md` | planned | codex |  |  |
| T015 | Add allowed response shapes and explicit approval semantics | FR-016, FR-017, FR-019 | US2 | 0.5 | Implementer | `scripts/specrew-start.ps1`, `extensions/**/specrew-governance.md` | planned | codex |  |  |
| T016 | Add positive six-section packet prompt tests | FR-009, FR-012, FR-014, FR-017 | US2/US3 | 0.5 | Implementer | `tests/**` | planned | codex |  |  |
| T017 | Make future packet primary stop contract without required legacy `=== SPECREW HANDOFF ===` duplication | FR-023 | US2 | 0.5 | Implementer | `scripts/specrew-start.ps1`, `extensions/**/specrew-governance.md` | planned | codex |  |  |
| T018 | Add bare `file:///` primary review targets and release-blocking review callouts | FR-024, FR-025 | US2 | 0.5 | Implementer | `scripts/specrew-start.ps1`, `extensions/**/specrew-governance.md` | planned | codex |  |  |
| T019 | Add grouped discussion prompts and `approve with defaults` / `discuss prompt #N` response option guidance | FR-026, FR-028 | US2 | 0.5 | Implementer | `scripts/specrew-start.ps1`, `extensions/**/specrew-governance.md` | planned | codex |  |  |
| T020 | Add prompt-specific discussion-loop guidance with renewed explicit boundary approval | FR-017, FR-027 | US2 | 0.5 | Implementer | `scripts/specrew-start.ps1`, `extensions/**/specrew-governance.md` | planned | codex |  |  |
| T021 | Add tests for no legacy duplication, bare links, release-blocking callouts, grouped prompts, and discussion loop | FR-023-FR-028 | US2/US3 | 1.0 | Implementer | `tests/**` | planned | codex |  |  |
| T022 | Add non-compliant handoff fixture missing `Why I stopped` | FR-009, FR-011 | US3 | 0.5 | Implementer | `tests/**/fixtures/**` | planned | codex |  |  |
| T023 | Add approve-only handoff fixture without discussion prompts | FR-014, FR-016, FR-018 | US3 | 0.5 | Implementer | `tests/**/fixtures/**` | planned | codex |  |  |
| T024 | Add context-free targeted prompt fixture and assertion | FR-014, FR-015 | US3 | 0.5 | Implementer | `tests/**/fixtures/**` | planned | codex |  |  |
| T025 | Implement narrow `Status: Approved` without human verdict evidence check | FR-005, FR-021, TG-005 | US1/US3 | 1.0 | Implementer | `extensions/**/validate-governance.ps1`, `.specify/**/validate-governance.ps1` | planned | codex |  |  |
| T026 | Add positive/negative tests for `Status: Approved` check | FR-005, FR-021 | US3 | 0.5 | Implementer | `tests/**` | planned | codex |  |  |
| T027 | Produce committed beta3 smoke evidence artifact | FR-022 | US3 | 0.75 | Implementer | `specs/139-boundary-authorization-prompt-truth/smoke/beta3-smoke-evidence.md` | planned | codex |  |  |
| T028 | Run focused tests and repo governance validation | FR-007, FR-021, FR-022, TG-006 | US1/US2/US3 | 0.5 | Implementer | `tests/**`, `.specify/**/validate-governance.ps1` | planned | codex |  |  |
| T029 | Prepare review evidence with implemented/enforced/observable/documented gap ledger | FR-022-FR-028, TG-006 | US1/US2/US3 | 0.5 | Reviewer | `specs/139-boundary-authorization-prompt-truth/iterations/001/**` | planned | codex |  |  |
| T030 | Confirm scope exclusions remain intact before release promotion | TG-005 | US1/US2/US3 | 0.25 | Reviewer | `specs/139-boundary-authorization-prompt-truth/iterations/001/**` | planned | codex |  |  |

## Effort Model

| Setting | Value | Notes |
| --- | --- | --- |
| Effort Unit | story_points | Unit used in task effort, capacity, and retro variance. |
| Capacity per Iteration | 20 | Maximum planned effort before overcommit guidance applies. |
| Iteration Bounding | scope | Requirements remain fixed for this iteration. |
| Time Limit (hours) | n/a | Not applicable. |
| Overcommit Threshold | 1.0 | Warn when planned effort exceeds 20 story_points. |
| Defer Strategy | manual | Defer only with explicit human approval. |
| Calibration Enabled | true | Retrospective should suggest future capacity adjustments. |

## Proposal 145 Review-Lens Coverage

| Lens Phase | Coverage in This Iteration |
| --- | --- |
| Context load | T001 |
| Branch hygiene | T002 |
| Functional correctness | T004-T021, T025-T026 |
| Non-functional requirements | T027 smoke evidence and PII/scope review in T029-T030 |
| Code quality | T003, T028, review of deterministic helper changes |
| Test coverage and integrity | T006, T010, T016, T021-T026, T028 |
| System safety and ops | T022-T030 |
| Output synthesis | T029 |

## Readiness Notes

- **Overall Verdict**: ready
- **Capacity**: 17.75/20 story_points
- **Release-blocking planned evidence**: `Status: Approved` check, beta3 smoke evidence, prompt bad-phrase tests, non-compliant handoff fixtures, and review gap ledger.
- **Dirty-state policy**: unrelated session/runtime files remain excluded unless explicitly classified in task notes or drift log before editing/staging.
- **Scope exclusions**: full Proposal 150, hook enforcement, broad historical Proposal 151 migration, and lifecycle redesign remain out of scope.
