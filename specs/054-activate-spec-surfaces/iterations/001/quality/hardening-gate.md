# Hardening Gate: Iteration 001

**Schema**: v1
**Gate ID**: `pre-implementation-hardening`
**Feature Ref**: `specs/054-activate-spec-surfaces/spec.md`
**Iteration Ref**: `specs/054-activate-spec-surfaces/iterations/001`
**Requested Review Class**: `strongest-available`
**Effective Review Class**: `planning-time-analysis`
**Overall Verdict**: `ready`
**Approval Ref**: `—`
**Reviewed By**: Reviewer
**Reviewed At**: 2026-05-31T08:37:41Z

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
| `security-surface` | `security` | `not-applicable` | `not-applicable` | `not-needed` | `—` | `false` | `This slice edits only user-facing documentation, command-guidance markdown, extension.yml command metadata, and PowerShell integration tests. It introduces no authentication, authorization, secret handling, untrusted-input processing, network calls, persistence, or executable runtime path. There is no trust boundary or privilege model to harden; the deliverable is discovery/positioning text plus regression coverage that asserts that text stays consistent.` | `—` |
| `error-handling-expectations` | `robustness` | `addressed` | `runtime-evidence` | `recorded` | `Lifecycle-boundary-sync test rejects premature analyze guidance before tasks.md exists (T003); coexistence test asserts the analyze prerequisite + redirect wording (T009); before-plan guidance preserves proportional checklist framing for low-risk slices (T005). Both positive surfacing and negative wrong-stage paths are asserted.` | `true` | `Incomplete-artifact state (FR-008) must redirect users back to before-implement instead of surfacing analyze, and lightweight slices must read checklist as optional rather than mandatory. No silent or smoke-only acceptance of these wrong-stage paths.` | `—` |
| `retry-idempotency-requirements` | `resilience` | `not-applicable` | `not-applicable` | `not-needed` | `—` | `false` | `This slice has no retries, idempotency keys, transactional state, queues, or shared mutable resources. It updates static documentation and metadata; re-running any task rewrites idempotent text, and the integration tests are read-only assertions over repository content.` | `—` |
| `test-integrity-targets` | `verification` | `addressed` | `runtime-evidence` | `recorded` | `Every FR maps to named regression coverage: FR-001..FR-004 -> slash-command-routing.tests.ps1 (T005); FR-005..FR-008 -> slash-command-coexistence.tests.ps1 (T009) + lifecycle-boundary-sync.tests.ps1 (T003); FR-009..FR-011 -> slash-command-discovery.tests.ps1 (T013) + validation-contract-lane.ps1 (T004). Negative paths (premature analyze, conflicting checklist stage, taskstoissues-as-default) are asserted, not just happy-path presence. Empirical results land in quality-evidence.md (T017) and mechanical-findings.json (T018).` | `true` | `Positive + negative coverage per FR; failure-mode FRs (FR-006/FR-008 stage gating, FR-010 deferment) require explicit negative assertions, so smoke-only presence checks are disallowed.` | `—` |
| `operational-resilience-concerns` | `operability` | `not-applicable` | `not-applicable` | `not-needed` | `—` | `false` | `This slice ships no server, SLO, telemetry pipeline, oncall surface, scheduled job, or operational dependency. It changes documentation, command metadata, and test coverage only; there is no runtime service whose availability or operability could regress.` | `—` |

## Lens Activation (Planning Baseline)

| Lens Ref | Activation | Planned Evidence Path |
| --- | --- | --- |
| `security-baseline@v1.0.0` | required | `specs/054-activate-spec-surfaces/iterations/001/quality/lenses/security-baseline.md` |
| `robustness-baseline@v1.0.0` | required | `specs/054-activate-spec-surfaces/iterations/001/quality/lenses/robustness-baseline.md` |
| `test-integrity@v1.0.0` | required | `specs/054-activate-spec-surfaces/iterations/001/quality/lenses/test-integrity.md` |

## Notes

- Replace every `<placeholder>` and every angle-bracketed instruction with iteration-specific content before crossing the `before-implement` boundary.
- After every row in the table is filled in with a canonical Status, flip the metadata `Overall Verdict` to `ready` (if every concern is `addressed` / `not-applicable` / `deferred-with-approval`) or keep `blocked`.
- Runtime evidence (lens execution, test counts, mechanical-findings results) is collected after implementation lands; the gate is a PLANNING-time artifact and that deferral is intentional.
