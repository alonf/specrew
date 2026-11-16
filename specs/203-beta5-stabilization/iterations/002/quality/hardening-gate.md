# Hardening Gate: Iteration 002

**Schema**: v1
**Gate ID**: `pre-implementation-hardening`
**Feature Ref**: `specs/203-beta5-stabilization/spec.md`
**Iteration Ref**: `specs/203-beta5-stabilization/iterations/002`
**Requested Review Class**: `strongest-available`
**Effective Review Class**: `(pending hardening review)`
**Overall Verdict**: `ready`
**Approval Ref**: `—`
**Reviewed By**: Planner (Claude), planning-time analysis; the reviewer order codex, copilot, claude covers the lenses at implement
**Reviewed At**: 2026-11-16T09:55:13Z

<!--
  Concern Review schema (validator-enforced):
  - Status MUST be one of: `addressed` | `not-applicable` | `deferred-with-approval`. The validator
    rejects placeholder values like `tbd`. Pick a real status per concern before implementation.
  - When Status is `addressed`: EvidenceBasis = `planning-time-analysis`, RuntimeEvidenceStatus =
    `pending-post-implementation`, ExpectedControls = concrete controls you will enforce.
  - When Status is `not-applicable`: EvidenceBasis = `not-applicable`, RuntimeEvidenceStatus =
    `not-needed`, ExpectedControls = `—`. Rationale must explain WHY this concern does not apply.
  - When Status is `deferred-with-approval`: same evidence fields as `addressed`, AND the Approval
    column must reference an approval record (decision or defer) with a recorded human approval.
  - Overall Verdict is computed: `ready` when every concern is addressed/not-applicable/deferred-
    with-approval; `blocked` otherwise. Update the metadata above when you change the table.
-->

## Concern Review

| Concern | Category | Status | Evidence Basis | Runtime Evidence Status | Expected Controls | Blocking | Rationale | Approval |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `security-surface` | `security` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | T020: a valid approval is found by its exact turn identity across every window before any message-ID fallback, and a compaction summary under the same prompt ID is never taken as the cited turn; every refusal that exists today stays. T022: a records-only difference after a reviewed digest is covered only by a human-accepted disposition for that digest; product code no reviewer read and no test covers still needs a typed override with a reason. T023: the phase checks read the authority record's cursor and never a line an agent can write. T019 removes a tracked link into another machine's home folder. No new mint path and no script or `!` approval path. | `true` | The trust boundary stays between the human's typed turn and the authority stores (iteration 001). This iteration changes two places on it: the sender check that finds the cited turn (T020) and the sign-off gate that decides what a stop covers (T022). Both fail closed today; the fixes may only make a refusal more precise, never let more through. Measure (b) stays first. | `—` |
| `error-handling-expectations` | `robustness` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | T021: a review-stop answer lost on the recovery path is reported in the same turn with its reason, through the visible line; case 9b of `typed-act-writer` gains a stop-answer case. T015: a supervisor whose lease handoff failed is waited for after `Stop-Process`, and each deterministic suite runs under a time limit that names the suite and stops its process tree, with a step `timeout-minutes` below the job's so a hang keeps its log. T025: the hooks' shared snapshot and tail read fail open to today's per-provider reads, never to a skipped check. Each fix lands behind a test committed red with its count, positive and negative. | `true` | A failure is disclosed in the same turn and never consumes a human turn silently (iteration 001's rule). T015 and DRIFT-005 add one: a hang in CI must name what hung. | `—` |
| `retry-idempotency-requirements` | `resilience` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | T018: a second top-up with no round between grants no extra window, as a fixture through the shipped command that a mutation turns red (the control iteration 001 closed without a test, DRIFT-094). T022: a finding resolved once stays resolved, and a stop recorded once covers its digest once. T016 and T017 remove the timing dependence that makes two runs of the same test disagree. | `true` | Iteration 001 closed this row with one control untested on the maintainer's "retry row yes" (2026-11-16 02:13); T018 is that test. | `—` |
| `test-integrity-targets` | `verification` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | Named tests: T015 `co-review-service` (site 13 case), T016 `HookRenderDedupe` (I3a, I4b), T017 `empty-result-retry`, T018 the top-up fixture in `review-budget-loop` or its own suite, T020 `authorization-sender` and `typed-act-writer`, T021 `typed-act-writer` case 9b and `not-recorded-report`, T022 and T023 `signoff-gate-wiring`, `records-only-covers-what-deployment-writes` and the sync's gate suites, T025 the hook suites with a timing measurement before and after. Each fix is a test commit with its red count, then the fix (one bug per fix commit). T026 measures the t008 lane before any limit moves. T027 and T028 are live checks with records in the drift log. | `true` | Positive plus negative per fix. The flaky tests are fixed, not given wider limits: a test that passes on a rerun is a defect of the test or the code. | `—` |
| `operational-resilience-concerns` | `operability` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | The hooks and review rounds run from the pin at `da78b600` until the maintainer's typed `advance the pin`, placed after this iteration's review round, after a full sweep of the tip (DRIFT-057). T025's push carries T006's launcher redeploy, with the maintainer asked first. Home hook files are hashed before and after every sweep; a change stops the work. | `false` | 203 ships no server; its operability surface is which engine code the live hooks run and how long each turn's hooks take (about 19 s today, DRIFT-073). | `—` |

## Lens Activation (Planning Baseline)

| Lens Ref | Activation | Planned Evidence Path |
| --- | --- | --- |
| `security-baseline@v1.0.0` | required | `specs/203-beta5-stabilization/iterations/002/quality/lenses/security-baseline.md` |
| `robustness-baseline@v1.0.0` | required | `specs/203-beta5-stabilization/iterations/002/quality/lenses/robustness-baseline.md` |
| `test-integrity@v1.0.0` | required | `specs/203-beta5-stabilization/iterations/002/quality/lenses/test-integrity.md` |

## Notes

- Runtime evidence (lens execution, test counts, mechanical-findings results) is collected after implementation lands; the gate is a PLANNING-time artifact and that deferral is intentional.
