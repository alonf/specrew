# Hardening Gate: Iteration 002

**Schema**: v1
**Gate ID**: `pre-implementation-hardening`
**Feature Ref**: `specs/045-v0271-bugfix-bundle/spec.md`
**Iteration Ref**: `specs/045-v0271-bugfix-bundle/iterations/002`
**Requested Review Class**: `strongest-available`
**Effective Review Class**: `strongest-available`
**Overall Verdict**: `ready`
**Approval Ref**: `-`
**Reviewed By**: `Codex as Specrew Crew coordinator`
**Reviewed At**: `2026-05-25T17:05:00Z`
**Post-Implementation Verification**: `pending`
**Verified At**: `-`

## Concern Review

| Concern | Category | Status | Evidence Basis | Runtime Evidence Status | Expected Controls | Blocking | Rationale | Approval |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `security-surface` | `security` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | Brownfield ownership classification must only change conflict treatment for project-local `.squad/agents/` when the self-hosting `extensions/specrew-speckit/` signal is present. Update docs must explain publisher-check bypass risk without normalizing unsafe bypass use. | `true` | The plan limits runtime edits to brownfield classification plus mirror parity. Documentation tasks are explicit about safe boundaries for `-Force` and publisher-check bypass. | `-` |
| `error-handling-expectations` | `error-handling` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | Non-self-hosting projects must continue surfacing existing managed-path conflicts. Self-hosting projects must avoid false conflict reports for canonical `.squad/agents/`. Docs must distinguish normal update, force update, and redeploy triggers. | `true` | Tests-first T016 precedes T017-T018, and T021 creates a review rubric before docs are judged. | `-` |
| `retry-idempotency-requirements` | `retry-idempotency` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | Re-running init/brownfield checks after classification changes must not mutate unrelated files or hide real conflicts. Documentation must tell operators when rerunning init is required and when it is unnecessary. | `true` | The iteration does not add retry loops; it verifies idempotent classification outcomes through brownfield fixtures and final regression replay. | `-` |
| `test-integrity-targets` | `test-integrity` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | T016 brownfield tests must be in place before implementation. Final evidence must include brownfield, version, and start/init regression replay with 0 failing P0/P1 tests. | `true` | T016 is ordered before T017-T018, and T029 requires all three patch regression suites before closeout evidence is claimed. | `-` |
| `operational-resilience-concerns` | `operational` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | Maintainers must be able to choose an update path, understand forced update semantics, and identify redeploy/init triggers in under 3 minutes. | `true` | T021 defines the timing rubric, T022-T023 update operator docs, and T026 records guided review evidence for SC-005. | `-` |
| `governance-mirror-integrity` | `governance` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | Brownfield logic changes must be mirrored between `extensions/` and `.specify/extensions/`. Iteration 002 state must preserve active feature pointer and use iteration 002 evidence paths. | `true` | T018 is a dedicated mirror task, T027-T028 run mechanical/governance checks, and this gate keeps iteration 001 artifacts closed. | `-` |
| `scope-discipline` | `scope` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | Iteration 002 must execute only T002 and T016-T030. Proposal 119 implementation work, lifecycle command expansion, and non-bug features remain out of scope. | `true` | The plan totals exactly 20 SP and explicitly excludes Proposal 119 code changes while preserving its corrected reference as planning context. | `-` |
| `concurrency-correctness` | `concurrency` | `not-applicable` | `not-applicable` | `not-needed` | No concurrent execution, locking, async processing, or shared mutable worker model is added by this iteration. | `false` | Planned changes are deterministic PowerShell classification logic, docs, and markdown evidence artifacts. | `not needed` |

## Planned Runtime Evidence

- `pwsh -NoProfile -ExecutionPolicy Bypass -File tests/integration/brownfield-conflict-handling.ps1`
- `pwsh -NoProfile -ExecutionPolicy Bypass -File tests/integration/validate-versions-cli-behavior.ps1`
- `pwsh -NoProfile -ExecutionPolicy Bypass -File tests/integration/start-recovery-flow.tests.ps1`
- Guided operator documentation review recorded in `specs/045-v0271-bugfix-bundle/iterations/002/quality/update-guidance-review.md`
- `pwsh -NoProfile -ExecutionPolicy Bypass -File .specify/extensions/specrew-speckit/scripts/run-mechanical-checks.ps1 -ProjectPath . -IterationPath specs/045-v0271-bugfix-bundle/iterations/002`
- `pwsh -NoProfile -ExecutionPolicy Bypass -File .specify/extensions/specrew-speckit/scripts/validate-governance.ps1 -ProjectPath . -NoCacheRead`

## Pre-Implementation Sign-Off

**Authority**: `Alon Fliess`
**Recorded At**: `2026-05-25T17:10:00Z`
**Authorization Text**: `Verdict: Approve — proceed to implementation. Capacity 20/20 verified; tests-first ordering preserved with T016 before T017-T018; mirror parity task T018 confirmed; coverage map complete; hardening gate ready; Proposal 119 reference correct; proceed to T002.`
**Implementation Start Condition**: Human approval received; plan status may move to `executing` and T002 may start.

## Scope and Deferred Items

- Iteration 002 covers T002 and T016-T030 only.
- T002 traceability is first execution work.
- T016 must precede T017-T018.
- T021 must precede T022-T026.
- T027-T030 are final polish/evidence tasks after US2 and US3.
- Iteration 001 artifacts remain closed; new evidence goes under `iterations/002/`.
- Proposal 119 (`proposals/119-effort-convention-conversion-table.md`) is context only for this iteration, not implementation scope.

## Recommended Next Step

Request the human before-implement verdict. If approved, flip iteration 002 plan status from `planning` to `executing`, record the approval text, and begin T002.
