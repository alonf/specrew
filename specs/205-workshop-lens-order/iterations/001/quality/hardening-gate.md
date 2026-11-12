# Hardening Gate: Iteration 001

**Schema**: v1
**Gate ID**: `pre-implementation-hardening`
**Feature Ref**: `specs/205-workshop-lens-order/spec.md`
**Iteration Ref**: `specs/205-workshop-lens-order/iterations/001`
**Requested Review Class**: `strongest-available`
**Effective Review Class**: `(pending hardening review)`
**Overall Verdict**: `ready`
**Approval Ref**: `—`
**Reviewed By**: Reviewer (pending)
**Reviewed At**: 2026-11-09T23:55:59Z

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
| `security-surface` | `security` | `not-applicable` | `not-applicable` | `not-needed` | `—` | `false` | No identity, secret, sensitive data or new trust boundary: the iteration edits lens text and the index.yml catalog, adds one refusal branch that echoes only lens ids from the crew's own agenda JSON, and adds tests. The deploy scripts used for copies were verified project-only (no home-folder writes). | `—` |
| `error-handling-expectations` | `robustness` | `addressed` | `runtime-evidence` | `recorded` | Out-of-order new agenda: one terminating refusal via New-SpecrewWorkshopAgendaRefusal naming the out-of-order lenses, the index.yml order and one action, nothing written, never reordered (positive: in-order agenda accepted; negative: out-of-order refused, file unchanged). Parity test: collects every mismatch, prints file:line/expected/found/fix, exits 1 only after the full report (negative fixture with several seeded mismatches must report all). Confirmed agendas never re-checked (FR-013 fixture). Post-implementation evidence: the refusal is in `confirm-workshop-agenda.ps1` (`9040b34c`) and throws `New-SpecrewWorkshopAgendaRefusal` with one `-Action`; `tests/integration/workshop-agenda-confirmation.tests.ps1` (`854ed59d`, red first at T017, green at T012) asserts, at render and at confirm, that it is refused naming `architecture-core`, `requirements-nfr` and index.yml, that the state file is byte-identical, that an in-order agenda renders in the given order, and that an old-order confirmed agenda resumes, closes its lenses, completes and keeps its order (FR-013); `tests/unit/workshop-refusal-contract.tests.ps1` asserts every actionable refusal in the writer uses the helper, whose contract carries one concrete next action. The parity test's seeded scratch tree reports every mismatch in one run, and after review round 2 (`d5d1ae06`) an error in a computed case is a mismatch, not the end of the run. Both suites run in CI (F-198 registry and the named parity step), green on `262b5ac4` (Specrew CI 43259632665). | `true` | Failure semantics are fail-closed for new agendas and report-all for the test; an already-confirmed agenda is never touched, so no incomplete-state can arise from this feature. | `—` |
| `retry-idempotency-requirements` | `resilience` | `not-applicable` | `not-applicable` | `not-needed` | `—` | `false` | No retries, idempotency keys, transactional state or shared resources: the iteration edits lens text, the index.yml catalog, one refusal check in the agenda writer and tests. The agenda writer's existing write path is unchanged. | `—` |
| `test-integrity-targets` | `verification` | `addressed` | `runtime-evidence` | `recorded` | FR-001/FR-019 and FR-005/FR-015/FR-018 -> tests/unit/lens-order-parity.tests.ps1 (run red-first on the unchanged tree, output kept in quality-evidence.md, then green); FR-016/FR-013 -> tests/integration/workshop-agenda-confirmation.tests.ps1 (refusal + old-agenda resume); SC-002 per-lens counts asserted; FR-021 local run of every workshop test logged in quality-evidence.md; CI named steps. Post-implementation evidence (quality-evidence.md): the parity test failed first with 72 mismatches at `12837d26` (T003) and passed with 0 at T012 (`d011cd0c`), 22 of 22 self-tests; the agenda test was red in the T017 baseline (run at `854ed59d`) and green at T012; SC-002 counts match for all 11 lenses; T017 and T013 ran all 31 workshop tests (30 pass, the one break was an updated order expectation in `lens-applicability-selector`); `specrew-ci.yml` gained 10 named steps (T014, `8d870098`). Each of the three review fixes (`3ed79b33`, `c840aaed`, `d5d1ae06`) landed behind a self-test that failed first. All three workflows green on `262b5ac4`. | `true` | Every check has a positive and a negative case; the test is proven able to fail before it is trusted; no question is moved to make a check pass (FR-015). | `—` |
| `operational-resilience-concerns` | `operability` | `not-applicable` | `not-applicable` | `not-needed` | `—` | `false` | No server, SLO, telemetry pipeline or on-call surface: the iteration ships lens text, catalog data, one agenda-writer check and tests, delivered through the existing deploy scripts and CI. | `—` |

## Lens Activation (Planning Baseline)

| Lens Ref | Activation | Planned Evidence Path |
| --- | --- | --- |
| `security-baseline@v1.0.0` | not-applicable | `specs/205-workshop-lens-order/iterations/001/quality/lenses/security-baseline.md` |
| `robustness-baseline@v1.0.0` | required | `specs/205-workshop-lens-order/iterations/001/quality/lenses/robustness-baseline.md` |
| `test-integrity@v1.0.0` | required | `specs/205-workshop-lens-order/iterations/001/quality/lenses/test-integrity.md` |

## Notes

- Replace every `<placeholder>` and every angle-bracketed instruction with iteration-specific content before crossing the `before-implement` boundary.
- After every row in the table is filled in with a canonical Status, flip the metadata `Overall Verdict` to `ready` (if every concern is `addressed` / `not-applicable` / `deferred-with-approval`) or keep `blocked`.
- Runtime evidence (lens execution, test counts, mechanical-findings results) is collected after implementation lands; the gate is a PLANNING-time artifact and that deferral is intentional.
