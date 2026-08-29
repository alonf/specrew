# Hardening Gate: Iteration 002

**Schema**: v1
**Gate ID**: `pre-implementation-hardening`
**Feature Ref**: `specs/199-beta3-stabilization/spec.md`
**Iteration Ref**: `specs/199-beta3-stabilization/iterations/002`
**Requested Review Class**: `strongest-available`
**Effective Review Class**: `(pending hardening review)`
**Overall Verdict**: `ready`
**Approval Ref**: `—`
**Reviewed By**: Implementer (planning-time analysis; the human's hardening sign-off is owed at the before-implement boundary)
**Reviewed At**: 2026-08-29T12:23:32Z

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
| `security-surface` | `security` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | Authority cannot be forged: a crossing is minted only when the stage it leaves has its owed artifacts on disk, at all three minting mechanisms (T014); the verdict marker carries the crossing identity and the capture verifies it (T014, T023); the crossing records its owning session and the boundary demand fires only there (T023); no recognizer is widened (T019, T024); `verdict-commit-durable` keeps `origin/<branch>` at HEAD wherever an origin exists (T016); every touched refusal names what failed, the instance and one action, with no machinery nouns (all). | `true` | The trust boundary is between the human's typed authority and the machinery's captures of it: only a hook-captured human phrase, bound to a crossing that has something to approve, may mint authority. Sensitive flows in this iteration: crossing mint, verdict capture, packet render, owner scoping, the closeout seal. The privilege model is unchanged - the human authorizes, the machinery records - and every control here narrows what the machinery can record without the human, never widens it. | `—` |
| `error-handling-expectations` | `robustness` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | One transition per failure mode, each with a positive and a negative test: owed artifacts absent -> no mint, packet withheld, the owed path named (fail closed; T014, T015); a verdict-shaped turn the classifier rejects -> one disclosure line naming the classification and the leading text (fail loud; T024); crossing owner unknown -> today's demand plus the named diagnosis gap (fail open, out loud, method rule 12; T023); an unparseable lens record -> one parse error naming the representation, answers preserved, no backstop lines (T017); a mirror ahead of the store -> refused, not rewritten (T021); the seal cannot mismatch its dashboard because it is the last write (T022). | `true` | Failure semantics follow the retro's rule: a control that cannot determine its input fails open on the diagnosis and says so; a control that can determine an authority defect fails closed and names the action. Incomplete state is never silently repaired: the sync re-mirrors only forward and only the copies; every refusal preserves the human's answers and says so. | `—` |
| `retry-idempotency-requirements` | `resilience` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | Identity-keyed idempotence: a re-sync of the same boundary derives the same crossing identity from commit and tree and preserves `recorded_at` (existing); the Stop re-fire after a prompt-submit capture does not double-append (existing test, `verdict-capture-blocks` Part B); the seal is a plain overwrite; the sync's re-mirror at start is idempotent; `confirm-workshop-lens` on an already-closed lens refuses through the existing "already moved on" receipt guard (T018). | `true` | Flipped from the scaffold's not-applicable: this iteration is made of retried writes - captures re-fire, syncs re-run, seals re-write, mirrors re-mirror - and each must converge on the same record rather than append. The transactional state is the authority store's verdict history (append-only, identity-keyed) and the three mirrors it owns. | `—` |
| `test-integrity-targets` | `verification` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | FR-to-test mapping is the task table: every task names the mutation that turns its own case red and the observable state it asserts (never call existence, per the `if ($false)` lesson); negative paths are the mutations themselves - the ladder replays, the stale marker captures, the second session is asked, the JSON record closes the lens, the mirror advances by hand, the seal mismatches - each red when its control is disabled; evidence lands in `tests/unit/**` and `tests/integration/**` suites named per task, the class-guard lane, and `quality/mechanical-findings.json`. | `true` | Smoke-only is disallowed for every FR here because every FR is a failure-mode requirement: the defect is what happens when a control is absent, so the test must observe the absence. The covering round over the delta since `1b50ae60` is the independent check on this table (SC-018). | `—` |
| `operational-resilience-concerns` | `operability` | `not-applicable` | `not-applicable` | `not-needed` | `—` | `false` | This iteration ships no server, SLO, telemetry pipeline, oncall surface or operational dependency: it is a PowerShell engine driven by host hooks and CLI invocations. Its only operational surface is the mirrored deployment (`extensions/` and `.specify/extensions/`, three skill copies), which the deployed-extension-integrity suite already guards and T025 sweeps. | `—` |

## Lens Activation (Planning Baseline)

| Lens Ref | Activation | Planned Evidence Path |
| --- | --- | --- |
| `security-baseline@v1.0.0` | required | `specs/199-beta3-stabilization/iterations/002/quality/lenses/security-baseline.md` |
| `robustness-baseline@v1.0.0` | required | `specs/199-beta3-stabilization/iterations/002/quality/lenses/robustness-baseline.md` |
| `test-integrity@v1.0.0` | required | `specs/199-beta3-stabilization/iterations/002/quality/lenses/test-integrity.md` |

## Notes

- Every concern row is filled with iteration-specific planning-time analysis; the metadata verdict
  is `ready` because every row is addressed or not-applicable. The human's hardening sign-off is
  owed at the `before-implement` boundary and is not implied by this verdict.
- Runtime evidence (lens execution, test counts, mechanical-findings results) is collected after
  implementation lands; the gate is a PLANNING-time artifact and that deferral is intentional.
