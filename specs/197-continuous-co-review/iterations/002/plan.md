# Iteration Plan: 002

**Schema**: v1
**Spec**: [../../spec.md](../../spec.md)
**Status**: executing
**Capacity**: 8.00/20 story_points
**Started**: 2026-06-19
**Completed**:

<!--
  Validator schema (canonical, enforced by validate-governance.ps1):
  - Iteration Status MUST be one of:
      planning | executing | reviewing | retro | complete | abandoned
  - Capacity format MUST be `<consumed>/<cap> <effort_unit>` with NO trailing prose on that line.
  - Task Status MUST be one of:
      planned | in-progress | done | needs-rework | deferred | blocked
-->

## Scope Summary

| Requirement | Summary | Stories |
| ----------- | ------- | ------- |
| FR-017 | Canonical Specrew-owned reviewer instruction source. | Reviewer-definition repair |
| FR-018 | Runtime prompt injection is authoritative; native host copies are mirrors only. | Reviewer-definition repair |
| FR-019 | `ReviewRequest.v2` carries instruction, design-context, round, policy, and output-contract data. | Reviewer-definition repair |
| FR-020 | Reviewer execution is read-only where supported and mutation-invalidated everywhere. | Reviewer-definition repair |
| FR-021 | Deterministic tests inspect the actual outbound composed prompt. | Reviewer-definition repair |
| FR-022 | SC-012 manual validation uses the implemented injected-prompt path. | Reviewer-definition repair |
| FR-023 | Latest remote `main` is merged or rebased before implementation starts. | Reviewer-definition repair |

## Tasks

| Task | Title | Requirement | Story | Effort | Owner | Owner File Globs | Status | Agent | Actual | Verdict |
| ---- | ----- | ----------- | ----- | ------ | ----- | ---------------- | ------ | ----- | ------ | ------- |
| T051 | Merge/rebase latest remote `main` before runtime repair work and re-run protected-surface guard. | FR-023, IMPL-011, TG-013, SC-006, SC-011 | Reviewer-definition repair | 1.00 | Iteration Facilitator | `.git/**`; `specs/197-continuous-co-review/iterations/002/**` | done | Iteration Facilitator | Remote sync evidence at f31e0c74b53c4652bf7a6aff575dd90cf9a89c19; fresh status clean and HEAD equals origin/197-continuous-co-review; protected-surface changed-file list has no violations; project setup verification added Docker ignore coverage. | PASS |
| T052 | Add canonical reviewer instruction source and tests for Proposal 145 rubric, lens validation, policies, and round protocol. | FR-017, SEC-007, IMPL-008, SC-013, TG-013 | Reviewer-definition repair | 1.00 | Spec Steward | `scripts/internal/continuous-co-review/code-review-agent.md`; `tests/continuous-co-review/**` | done | Spec Steward | Added canonical code-review-agent.md plus reviewer-instruction marker fixture and Pester contract coverage for Proposal 145 rubric phases, workshop/trace/falsification/per-lens validation, visibility policy, do-policy, and round protocol. Tests: reviewer-instruction.Tests.ps1 passed 5/5. | PASS |
| T053 | Implement runtime `ReviewRequest.v2` support and prompt composer using the already-planned schema contract as authority. | FR-018, FR-019, INT-010, INT-013, OBS-010, IMPL-009, SC-014, SC-015, TG-013, TG-014 | Reviewer-definition repair | 2.00 | Architect | `scripts/internal/continuous-co-review/review-request-builder.ps1`; `scripts/internal/continuous-co-review/reviewer-contracts.ps1`; `scripts/internal/continuous-co-review/review-prompt-composer.ps1`; `tests/continuous-co-review/**` | planned |  |  |  |
| T054 | Enforce read-only host invocation where supported and invalidate reviewer runs on source/Git/Specrew-state mutation. | FR-020, SEC-008, SEC-009, OBS-012, SC-016, TG-013 | Reviewer-definition repair | 1.25 | Security Reviewer | `scripts/internal/continuous-co-review/workspace-mutation-guard.ps1`; `scripts/internal/continuous-co-review/execution-engine.ps1`; `scripts/internal/continuous-co-review/reviewer-host-adapter-*.ps1`; `tests/continuous-co-review/**` | planned |  |  |  |
| T055 | Implement best-effort host mirror support and reconcile docs/runbook only if implementation diverges from the planned transport-only contract. | FR-018, FR-022, INT-011, INT-012, SC-017, SC-018, TG-014 | Reviewer-definition repair | 0.75 | Implementer | `scripts/internal/continuous-co-review/host-agent-mirror.ps1`; `.claude/**`; `.github/**`; `.agents/**`; `specs/197-continuous-co-review/contracts/reviewer-spawn-contract.md`; `specs/197-continuous-co-review/quickstart.md`; `specs/197-continuous-co-review/iterations/001/manual-validation.md` | planned |  |  |  |
| T056 | Add deterministic prompt-composer and adapter-seam tests proving actual outbound prompt completeness and fixture-bypass failures. | FR-021, OBS-011, IMPL-010, SC-014, SC-017, SC-018, TG-013 | Reviewer-definition repair | 1.50 | Reviewer | `tests/continuous-co-review/**`; `specs/197-continuous-co-review/fixtures/**` | planned |  |  |  |
| T057 | Run Iteration 002 validation for schema, prompt-composer, mutation guard, protected surfaces, and traceability before review handoff. | FR-021, FR-023, INT-013, OBS-011, SC-006, SC-011, SC-014, SC-015, SC-016, TG-013 | Reviewer-definition repair | 0.50 | Reviewer | `tests/continuous-co-review/**`; `specs/197-continuous-co-review/iterations/002/**` | planned |  |  |  |

## Effort Model

| Setting | Value | Notes |
| ------- | ----- | ----- |
| Effort Unit | story_points | Unit used in task effort, capacity, and retro variance. |
| Capacity per Iteration | 20 | Maximum planned effort before overcommit guidance applies. |
| Iteration Bounding | scope | `scope` keeps requirements fixed; time varies. |
| Time Limit (hours) | n/a | Not used for this scope-bounded repair. |
| Overcommit Threshold | 1.0 | Planned effort must stay at or below 20 story_points. |
| Defer Strategy | manual | Any overcommit requires explicit human deferral. |
| Calibration Enabled | true | Retro should compare planned and actual effort. |

## Concurrency Rationale

- T051 is a hard dependency and must execute first because runtime repair must start from latest remote `main`.
- T052 and T053 can proceed after T051; T053 consumes the canonical instruction shape but does not require completed host mirrors.
- T054 depends on the execution-engine seam and should run after the prompt/request boundary is explicit.
- T055 is mostly edge/mirror documentation and can run after T053 confirms the composed-prompt contract.
- T056 follows T052-T055 because it proves the actual outbound prompt and adapter seam behavior.
- T057 is the closeout validation task and remains last.

## Phase Baseline

| Phase | Estimated Effort | Notes |
| ----- | ---------------- | ----- |
| Planning | 0.50 | Send-back workshop and artifact repair. |
| Discovery/Spikes | 1.00 | Remote-main sync and conflict discovery in T051. |
| Implementation | 4.00 | Canonical instruction, request/prompt composer, mutation guard, and host mirror support. |
| Review | 1.50 | Prompt-composer and adapter-seam deterministic tests. |
| Rework | 1.00 | Reserved for conflict repair or reviewer-definition correction within the 8.00 SP slice. |

## Traceability Summary

- Iteration 002 in-scope requirements: FR-017, FR-018, FR-019, FR-020, FR-021, FR-022, FR-023.
- Success criteria covered in this iteration: SC-013, SC-014, SC-015, SC-016, SC-017, SC-018, plus SC-006 and SC-011 guardrails.
- Every task references `specs/197-continuous-co-review/implementation-rules.yml` through the authoritative root `tasks.md`.
- Capacity status: PASS, 8.00/20 story_points.

## Notes

- The `ReviewRequest.v2` JSON schema, spawn contract, quickstart, and manual-validation runbook were updated during planning as design artifacts. Runtime implementation still starts at T051 only after human before-implement approval.
- T051 is intentionally first; if remote-main conflict repair exceeds this slice, stop and split synchronization into a human-approved preparatory step.
- Do not start rung 1, hook/PostToolUse triggers, Proposal 139 foundation, Proposal 196 provenance/audit, automated live CI, new dependencies, protected F-184 edits, `proposals/197-continuous-co-review.md`, or `.squad/agents/spec-steward/history.md`.
