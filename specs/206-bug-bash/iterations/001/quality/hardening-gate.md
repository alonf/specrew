# Hardening Gate: Iteration 001

**Schema**: v1
**Gate ID**: `pre-implementation-hardening`
**Feature Ref**: `specs/206-bug-bash/spec.md`
**Iteration Ref**: `specs/206-bug-bash/iterations/001`
**Requested Review Class**: `strongest-available`
**Effective Review Class**: `(pending hardening review)`
**Overall Verdict**: `ready`
**Approval Ref**: `—`
**Reviewed By**: Reviewer (pending)
**Reviewed At**: 2026-11-10T02:46:53Z

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
| `security-surface` | `security` | `addressed` | `runtime-evidence` | `recorded` | `tracking-issue text limited to iteration ids, rule names, severities, run id and commit, asserted by test (T012); issues: write granted to the notifier job only, workflow default contents: read; home hook files hashed before and after every test run (T018); any script that calls specrew-update.ps1 or the hook deployment is not run (T014), the 16 test files of feature 203's census (bug list item 8) never run here, and anything else reaching specrew init, start, update or the hook deployer runs only after it is read and confirmed unable to write hook files, and no inherited verification lane runs; no file under scripts/internal/continuous-co-review or scripts/internal/bootstrap touched (T018 diff check)` Post-implementation evidence: `tests/unit/nightly-tracking-issue.tests.ps1` (red 13/14 at `ae9a3c9d`, green at `ff0e78b9`; default-branch rule red at `85d275bb`, green at `867d4752`) asserts that the title, body and comments carry no path, user name or machine name, that a failure is written as iteration id, rule and severity or only as a hash, that the workflow default stays `contents: read`, and that the notifier job alone holds `issues: write`. Home hook files were hashed before and after every run and never changed, through the closeout (T018, `55c3bb8d`). T014 read the 36 held scripts and ran none that call specrew-update or the hook deployment (`fd8c6d28`). `git diff --name-only d3e33550 900b21b7` lists no file under `scripts/internal/continuous-co-review/`, `scripts/internal/bootstrap/` or the conformance provider. Open and deferred with approval: the notifier adopts any open issue carrying its label (round 1). | `true` | `the one new outward surface is a GitHub issue written by CI: public text that must carry no local paths, user or machine names; the other trust boundary is the developer's real home folder, which tests must never write` | `f206-i001-gap-ledger-deferrals` |
| `error-handling-expectations` | `robustness` | `addressed` | `runtime-evidence` | `recorded` | `no-console stale state returns a plain refusal and a non-zero exit, never a prompt (T001); an interactive console gets at most three invalid answers; a missing or unbalanced specrew-managed marker makes the classifier compare the whole file (T003); the notifier fails the job, not silently, when gh fails (T012)` Post-implementation evidence: `tests/unit/recovery-choice-no-console.tests.ps1` (red 5/7 at `56f452f3`, green at `837b4f09`) asserts no choice and no loop with empty redirected stdin and in a -NonInteractive host, a stop after three invalid answers, and that `specrew start` prints the refusal and exits non-zero. `tests/unit/instruction-classifier-managed-blocks.tests.ps1` (red 8/8 at `d008e382`, green at `0621a076`) asserts that a missing or unbalanced marker compares the whole file; round 2 finding 1 (`f1cdd95e`, `0c3968ee`) added the managed-only file. The notifier throws when gh exits non-zero (`.github/scripts/nightly-tracking-issue.ps1`, `ff0e78b9`); no test asserts that throw. Open and deferred with approval: a malformed `>>> ... <<<` opener is treated as balanced (round 4 finding 3), and an unexpected validator exception writes no message hash (round 4 finding 4). | `true` | `each failure is resolved toward the safe side: refuse rather than loop, pause rather than miss a user change, report rather than swallow a notifier error` | `f206-i001-defer-fr003-malformed-marker`, `f206-i001-defer-fr009-notifier-gaps` |
| `retry-idempotency-requirements` | `resilience` | `addressed` | `runtime-evidence` | `recorded` | `the notifier acts once per failure-set change: same fingerprint means no call, asserted with recorded gh calls (T012); the frozen list is applied once and guarded (T008)` Post-implementation evidence: `tests/unit/nightly-tracking-issue.tests.ps1` asserts with recorded gh calls that a red night with the same failures sends nothing, a changed failure set comments once, a green night closes the issue, the fingerprint does not depend on finding order, and a replaced or added failure in one category is a change (round 2 finding 4, `d5738276`, `d3839db1`). `tests/unit/legacy-frozen-judged-by-nothing.tests.ps1` (red 5/6 at `ad11f315`, green at `ad31b2d5`) guards the frozen list against an added key. Open and deferred with approval: overlapping notifier runs can open two issues, because the workflow has no `concurrency:` group (round 4 finding 5). | `true` | `the nightly runs every day; the tracking issue must stay quiet on a repeated failure set and act exactly once when it changes or turns green` | `f206-i001-defer-fr009-notifier-gaps` |
| `test-integrity-targets` | `verification` | `addressed` | `runtime-evidence` | `recorded` | `FR to failing-test mapping in plan.md (every fix RED first, one bug per commit); negative paths per FR listed there; the census guard proves itself with a probe script of any name (SC-004); the frozen guard fails on an added key (SC-005); evidence in iterations/001/quality/quality-evidence.md` Post-implementation evidence: every fix commit in the iteration follows a test commit with its red count (for example T001 5/7, T003 8/8, T008 5/6, T012 13/14, T013 10/26, and the round 2 and round 3 findings, `e2e89489` to `924d14bb`). The census guard proved itself with an unregistered script not named `*tests.ps1` (red 10/26 at `dd57e075`, green at `798ded31`, SC-004). The frozen guard fails on an added key (`ad11f315`, SC-005). All three workflows were green on `825b186f`. quality-evidence.md was not updated after implementation; its gate matrix still reads `planned`, so the evidence is these commits and CI, not that file. SC-001 and SC-002 are not met in this iteration and are deferred to iteration 002. | `true` | `bug-bash conduct: each defect is first reproduced by a failing test; smoke-only evidence is not accepted for the refusal, marker and notifier paths` | `f206-i001-gap-ledger-deferrals` |
| `operational-resilience-concerns` | `operability` | `addressed` | `runtime-evidence` | `recorded` | `the nightly gains a person-facing signal (tracking issue opened on the first red night, commented on change, closed on green); the local CI-mode replay is run before push (T010)` Post-implementation evidence: the nightly workflow gained the notifier job (`ff0e78b9`), which opens one tracking issue on the first red night, comments on a change and closes on green, and acts only for the scheduled run and a manual run on main (`867d4752`). This is asserted with an injected gh in `tests/unit/nightly-tracking-issue.tests.ps1`. It has not run live: the job acts only on main, and this branch is not merged. The local CI-mode replay ran on `9de20285` with exit 0 and no new finding (T010, `f06eb83b`). | `true` | `the nightly was red for 94 nights unseen; making that signal reach a person is the operational fix of this iteration` | — |

## Lens Activation (Planning Baseline)

| Lens Ref | Activation | Planned Evidence Path |
| --- | --- | --- |
| `security-baseline@v1.0.0` | required | `specs/206-bug-bash/iterations/001/quality/lenses/security-baseline.md` |
| `robustness-baseline@v1.0.0` | required | `specs/206-bug-bash/iterations/001/quality/lenses/robustness-baseline.md` |
| `test-integrity@v1.0.0` | required | `specs/206-bug-bash/iterations/001/quality/lenses/test-integrity.md` |

## Notes

- Replace every `<placeholder>` and every angle-bracketed instruction with iteration-specific content before crossing the `before-implement` boundary.
- After every row in the table is filled in with a canonical Status, flip the metadata `Overall Verdict` to `ready` (if every concern is `addressed` / `not-applicable` / `deferred-with-approval`) or keep `blocked`.
- Runtime evidence (lens execution, test counts, mechanical-findings results) is collected after implementation lands; the gate is a PLANNING-time artifact and that deferral is intentional.
