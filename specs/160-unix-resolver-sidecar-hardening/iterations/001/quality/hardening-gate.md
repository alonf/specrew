# Hardening Gate: Iteration 001

**Schema**: v1
**Gate ID**: `pre-implementation-hardening`
**Feature Ref**: `specs/160-unix-resolver-sidecar-hardening/spec.md`
**Iteration Ref**: `specs/160-unix-resolver-sidecar-hardening/iterations/001`
**Requested Review Class**: `strongest-available`
**Effective Review Class**: `strongest-available`
**Overall Verdict**: `ready`
**Approval Ref**: `tasks->before-implement verdict (Alon Fliess, approve as-is)`
**Reviewed By**: Reviewer (claude)
**Reviewed At**: 2026-06-03T15:54:59Z

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
| `security-surface` | `security` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | `Treat a valid .specrew-managed marker as the sole authority to refresh-from-canonical; never overwrite a file lacking a valid managed marker; fixtures assert user-edited/unmanaged files are preserved; run all fixtures in temp scratch directories only (never in .squad/.codex/.cursor/.claude/.agents/.specrew); no destructive deletes of unrelated files; no push.` | `true` | `Managed-refresh deployment writes agent/runtime files that may be user-owned. The .specrew-managed marker is the trust boundary deciding refresh vs preserve; mishandling overwrites user edits or leaves canonical files stale. The resolver decides whether stale installed-module code runs in place of the dev tree, which is itself a trust/integrity surface.` | `tasks->before-implement verdict` |
| `error-handling-expectations` | `robustness` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | `Each investigation records exactly one disposition (confirmed / not-confirmed / environment-blocked); resolver probe exercises both dev-tree and installed-module branches; sidecar fixture asserts negative paths (missing marker -> preserve, divergent mirror -> named before any fix); environment-blocked is recorded explicitly instead of guessing when no real Unix host is available.` | `true` | `Resolver fallback to installed modules and preserve notices must not silently hide stale behavior. Failure and fallback semantics around path resolution and marker recognition must be explicit and observable in evidence, including the environment-blocked path when Unix repro cannot be run on this Windows host.` | `tasks->before-implement verdict` |
| `retry-idempotency-requirements` | `resilience` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | `Managed-refresh fixture runs the deploy/refresh logic at least twice and asserts a stable end-state; marker creation is idempotent; the refresh-vs-preserve decision is identical across repeated runs; no duplicated or accreting marker artifacts on rerun.` | `true` | `Managed refresh executes on repeated init/update/start and deploy runs. The behavior must be safe and idempotent so re-running does not overwrite user edits, double-write markers, or change the preserve decision. Idempotency is a first-class concern for this slice, not incidental.` | `tasks->before-implement verdict` |
| `test-integrity-targets` | `verification` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | `Repro/probe tests (T004/T005 resolver, T007/T008 sidecar) are authored and run BEFORE any source change (T010/T012); FR-002 -> resolver path-semantics test, FR-006 -> marker create/recognize assertions, FR-008 -> refresh + preserve assertions; negative paths required (preserve-on-missing-marker, not-confirmed disposition); smoke-only/after-the-fact tests that only prove the final implementation are disallowed.` | `true` | `The feature's core value is proof-before-fix. Tests must reproduce the suspected failure first; a test written after a fix that only confirms the fix violates the repro-first contract (FR-001/SC-002). Coverage must include positive and negative paths per confirmed FR.` | `tasks->before-implement verdict` |
| `operational-resilience-concerns` | `operability` | `not-applicable` | `not-applicable` | `not-needed` | `—` | `false` | `This iteration ships no server, SLO, telemetry pipeline, oncall surface, or operational dependency. The deliverable is local investigation fixtures plus conditional PowerShell resolver/marker fixes run via pwsh with no network or package-manager access, so operational-resilience primitives have no surface here.` | `—` |

## Lens Activation (Planning Baseline)

| Lens Ref | Activation | Planned Evidence Path |
| --- | --- | --- |
| `security-baseline@v1.0.0` | required | `specs/160-unix-resolver-sidecar-hardening/iterations/001/quality/lenses/security-baseline.md` |
| `robustness-baseline@v1.0.0` | required | `specs/160-unix-resolver-sidecar-hardening/iterations/001/quality/lenses/robustness-baseline.md` |
| `test-integrity@v1.0.0` | required | `specs/160-unix-resolver-sidecar-hardening/iterations/001/quality/lenses/test-integrity.md` |

## Notes

- All `<placeholder>` instructions replaced with iteration-specific content before crossing the `before-implement` boundary.
- Overall Verdict is `ready`: every concern is `addressed` or `not-applicable`.
- Runtime evidence (lens execution, test counts, mechanical-findings results) is collected after implementation lands; the gate is a PLANNING-time artifact and that deferral is intentional.
- `retry-idempotency-requirements` was intentionally flipped from the scaffold default of `not-applicable` to `addressed` because the managed-refresh slice exercises repeated deploy/refresh runs.
