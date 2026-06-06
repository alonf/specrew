# Hardening Gate: Iteration 001

**Schema**: v1
**Gate ID**: `pre-implementation-hardening`
**Feature Ref**: `specs/161-managed-skill-preserving-guard/spec.md`
**Iteration Ref**: `specs/161-managed-skill-preserving-guard/iterations/001`
**Requested Review Class**: `strongest-available`
**Effective Review Class**: `strongest-available`
**Overall Verdict**: `ready`
**Approval Ref**: `—`
**Reviewed By**: Reviewer (claude)
**Reviewed At**: 2026-06-06T11:40:00Z

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
| `security-surface` | `security` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | `The no-loss invariant is mandatory in every outcome branch: scenario S2 (genuinely user-authored legacy skill, no marker) must be reported preserved AND byte-identical after every deploy run, pre-fix, post-fix, and refuted-no-fix; the harness writes only inside its temp sandbox (never .squad/.copilot/.claude/.cursor/.github/.agents/.specrew of the working repo); no destructive deletes outside the sandbox; no push to main, no tag, no PR.` | `true` | `The managed/preserve classification is a trust boundary protecting user-authored skill content from deletion during legacy cleanup. A wrong fix could delete user data; a wrong probe could mask data loss. The human instruction at the tasks gate made byte-preservation of the user-authored path an explicit mandatory invariant.` | `—` |
| `error-handling-expectations` | `robustness` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | `Every scenario S1–S6 records an explicit observed outcome (deployment-action record + disk state), never an inferred one; the S4 probe records its raw outcome before any interpretation; the T005 verdict requires BOTH the probe outcome AND reachability evidence, and names the exact classification rule (file + function + rule); missing/empty SKILL.md and unmatched-definition paths are exercised or explicitly recorded as out of scenario scope.` | `true` | `The suspected failure mode is a silent one (a skill frozen with no warning). The investigation must make silence observable: each classification decision in the repro is captured from the deploy action record, and refutation requires positive evidence, not absence of failure.` | `—` |
| `retry-idempotency-requirements` | `resilience` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | `Scenario S5 runs the real deploy twice in immediate succession and asserts a stable end-state: managed active-root surfaces report preserved/no-change on the second run, no duplicate or accreting markers, and the legacy-cleanup decisions are identical across runs; SC-001 additionally requires the whole harness to produce identical outcomes across two consecutive executions.` | `true` | `deploy-squad-runtime.ps1 runs on every init/update/start for Squad-host projects, so repeated execution is the normal case, not the exception. The preserve/refresh decision must be stable under re-run or the investigation itself becomes nondeterministic.` | `—` |
| `test-integrity-targets` | `verification` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | `Repro-first ordering enforced by task dependencies: harness (T003) + reachability (T004) + verdict (T005) complete BEFORE any source change (T006/T007), and T006/T007 stay blocked unless T005 records CONFIRMED = misclassified AND reachable (misclassification alone is insufficient); S4 is authored as a neutral probe (captures the outcome) not a pre-asserted expectation; if a fix lands, S4 is promoted to a regression assertion with failing-before/passing-after evidence; the existing F-160 fixture (Cases A–D + mirror parity) must pass unchanged throughout; after-the-fact tests that only prove the final implementation are disallowed.` | `true` | `The feature's core value is proof-before-fix. The strongest historical failure class in this repo is form-without-runtime-compliance; the gate therefore demands genuine probe semantics and a verdict-gated fix budget rather than tests written to match the implementation.` | `—` |
| `operational-resilience-concerns` | `operability` | `not-applicable` | `not-applicable` | `not-needed` | `—` | `false` | `This iteration ships no server, SLO, telemetry pipeline, oncall surface, or operational dependency. The deliverable is a local PowerShell integration harness, evidence records, and at most a narrow classification fix in a deploy script run via pwsh with no network or package-manager access, so operational-resilience primitives have no surface here.` | `—` |

## Lens Activation (Planning Baseline)

| Lens Ref | Activation | Planned Evidence Path |
| --- | --- | --- |
| `security-baseline@v1.0.0` | required | `specs/161-managed-skill-preserving-guard/iterations/001/quality/lenses/security-baseline.md` |
| `robustness-baseline@v1.0.0` | required | `specs/161-managed-skill-preserving-guard/iterations/001/quality/lenses/robustness-baseline.md` |
| `test-integrity@v1.0.0` | required | `specs/161-managed-skill-preserving-guard/iterations/001/quality/lenses/test-integrity.md` |

## Notes

- Overall Verdict is `ready`: every concern is `addressed` or `not-applicable`.
- Runtime evidence (lens execution, harness logs, mechanical-findings results) is collected after
  implementation lands; the gate is a PLANNING-time artifact and that deferral is intentional.
- The conditional-fix budget (T006/T007) is additionally gated by the human instruction recorded at
  the tasks→before-implement approval: CONFIRMED requires misclassified AND reachable.
