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
| `security-surface` | `security` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | `tracking-issue text limited to iteration ids, rule names, severities, run id and commit, asserted by test (T012); issues: write granted to the notifier job only, workflow default contents: read; home hook files hashed before and after every test run (T018); any script that calls specrew-update.ps1 or the hook deployment is not run (T014), the 16 test files of feature 203's census (bug list item 8) never run here, and anything else reaching specrew init, start, update or the hook deployer runs only after it is read and confirmed unable to write hook files, and no inherited verification lane runs; no file under scripts/internal/continuous-co-review or scripts/internal/bootstrap touched (T018 diff check)` | `true` | `the one new outward surface is a GitHub issue written by CI: public text that must carry no local paths, user or machine names; the other trust boundary is the developer's real home folder, which tests must never write` | `—` |
| `error-handling-expectations` | `robustness` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | `no-console stale state returns a plain refusal and a non-zero exit, never a prompt (T001); an interactive console gets at most three invalid answers; a missing or unbalanced specrew-managed marker makes the classifier compare the whole file (T003); the notifier fails the job, not silently, when gh fails (T012)` | `true` | `each failure is resolved toward the safe side: refuse rather than loop, pause rather than miss a user change, report rather than swallow a notifier error` | `—` |
| `retry-idempotency-requirements` | `resilience` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | `the notifier acts once per failure-set change: same fingerprint means no call, asserted with recorded gh calls (T012); the frozen list is applied once and guarded (T008)` | `true` | `the nightly runs every day; the tracking issue must stay quiet on a repeated failure set and act exactly once when it changes or turns green` | `—` |
| `test-integrity-targets` | `verification` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | `FR to failing-test mapping in plan.md (every fix RED first, one bug per commit); negative paths per FR listed there; the census guard proves itself with a probe script of any name (SC-004); the frozen guard fails on an added key (SC-005); evidence in iterations/001/quality/quality-evidence.md` | `true` | `bug-bash conduct: each defect is first reproduced by a failing test; smoke-only evidence is not accepted for the refusal, marker and notifier paths` | `—` |
| `operational-resilience-concerns` | `operability` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | `the nightly gains a person-facing signal (tracking issue opened on the first red night, commented on change, closed on green); the local CI-mode replay is run before push (T010)` | `true` | `the nightly was red for 94 nights unseen; making that signal reach a person is the operational fix of this iteration` | `—` |

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
