# Hardening Gate: Iteration 001

**Schema**: v1
**Gate ID**: `pre-implementation-hardening`
**Feature Ref**: `specs/045-v0271-bugfix-bundle/spec.md`
**Iteration Ref**: `specs/045-v0271-bugfix-bundle/iterations/001`
**Requested Review Class**: `strongest-available`
**Effective Review Class**: `strongest-available`
**Overall Verdict**: `ready`
**Approval Ref**: `-`
**Reviewed By**: `Codex as Specrew Crew coordinator`
**Reviewed At**: `2026-05-25T14:31:02Z`
**Post-Implementation Verification**: `pending`
**Verified At**: `pending`

## Concern Review

| Concern | Category | Status | Evidence Basis | Runtime Evidence Status | Expected Controls | Blocking | Rationale | Approval |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `security-surface` | `security` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | Skill-catalog repair and deployable-gap detection must operate only on project-local managed paths. The patch must not add credential handling, network calls, privilege escalation, or broad filesystem mutation outside Specrew runtime surfaces. | `true` | Iteration 001 is limited to CLI entry points, shared local state helpers, and targeted integration tests. Security-sensitive brownfield classification remains scoped for iteration 002, with FR-008 mirror integrity still active here. | `-` |
| `error-handling-expectations` | `error-handling` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | Version warning output must appear only for true unknown-version states. Missing skill-catalog roots must route to repair or deployment continuation instead of false success or misleading failure. | `true` | T007-T013 explicitly separate version parsing, warning suppression, start repair, and init deployable-gap behavior so each failure mode can be verified independently. | `-` |
| `retry-idempotency-requirements` | `retry-idempotency` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | Re-running start or init after repair must not duplicate runtime state or keep reporting missing roots. Directory repair must converge on the required catalog layout. | `true` | T003 centralizes missing-root and deployable-gap semantics in a shared helper, reducing drift between start and init and making rerun behavior deterministic. | `-` |
| `test-integrity-targets` | `test-integrity` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | Version aliases, false-warning suppression, missing-catalog repair, and init force/non-force deployable-gap paths must be covered by regression tests before claiming SC-001, SC-002, SC-003, or SC-006. | `true` | T007 and T008 are test-first tasks, and T015 records the required command evidence in quality-evidence.md. SC-006 is defined as zero failing P0/P1 patch regression tests. | `-` |
| `operational-resilience-concerns` | `operational` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | Users must recover from partial skill-catalog deployment gaps through normal start/init flows without manual directory creation and without losing existing runtime state. | `true` | The iteration plan isolates shared state detection before entry-point wiring, then verifies project and non-project command behavior through integration suites. | `-` |
| `governance-mirror-integrity` | `governance` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | Any helper import/bootstrap changes must preserve expected governance mirror behavior and avoid active-feature pointer drift. | `true` | T006 is a dedicated reviewer task for mirror parity across affected loaders; validator evidence remains required before iteration review. | `-` |
| `scope-discipline` | `scope` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | Iteration 001 must close only setup, foundational, and US1 work: T001 plus T003-T015. US2, US3, and feature polish stay deferred to iteration 002. | `true` | The iteration plan records a 20/20 story-point scope and keeps brownfield/docs work out of iteration 001 except for ledger context and contract updates tied to US1. | `-` |
| `concurrency-correctness` | `concurrency` | `not-applicable` | `not-applicable` | `not-needed` | No concurrent execution, locking, async processing, or shared mutable worker model is added by this iteration. | `false` | The patch changes synchronous PowerShell command paths and file-based tests only. | `not needed` |

## Planned Runtime Evidence

- `pwsh -NoProfile -File tests/integration/validate-versions-cli-behavior.ps1`
- `pwsh -NoProfile -File tests/integration/start-recovery-flow.tests.ps1`
- `pwsh -NoProfile -File .specify/extensions/specrew-speckit/scripts/run-mechanical-checks.ps1 -ProjectPath . -IterationPath specs/045-v0271-bugfix-bundle/iterations/001`
- `pwsh -NoProfile -File .specify/extensions/specrew-speckit/scripts/validate-governance.ps1 -ProjectPath .`

## Pre-Implementation Sign-Off

**Authority**: `Alon Fliess`
**Recorded At**: `2026-05-25T14:45:09Z`
**Authorization Text**: `APPROVE for implementation execution — iteration 001 ONLY. Execute T001 first, T003-T006 in order, T007-T008 before T009-T013, then T014-T015. Stop at iter-001 review boundary. Do not auto-advance into retro or closeout.`
**Implementation Start Condition**: Human approval received for T001 and T003-T015 only, with tests-first ordering preserved for US1 and review-boundary stop required after T015.

## Scope and Deferred Items

- Iteration 001 covers T001 and T003-T015 only.
- T002, T016-T030 remain deferred to iteration 002 per the two-iteration plan.
- Brownfield `.squad/agents/` canonical-source implementation and operator documentation updates are intentionally excluded from iteration 001 implementation work.
- No lifecycle command expansion, new boundary type, or non-bug feature work is approved by this gate.

## Recommended Next Step

Request the human before-implement verdict. If approved, run the before-implement boundary authorization and begin T001, then T003-T015 in dependency order.
