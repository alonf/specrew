# Coverage Evidence: Iteration 001

**Schema**: v1
**Reviewed**: 2026-06-10
**Overall Verdict**: accepted

## Form-vs-Meaning note (the scaffold heuristic)

The scaffolder flagged "15 tasks vs 30 files in the diff". This is expected and benign for a
methodology feature: a single task legitimately touches many files. For example T012 (deploy)
touches the source `design-workshop.md` + the `.specify` mirror + four host `SKILL.md` copies (6
files for one task); T001/T002 touch the lens md + `index.yml` + `diagram-vocabulary.json`; the
schema, two test files, and the iteration governance artifacts add the rest. The implementation IS
committed (`70802feb` + `f8e22576`); task statuses match disk truth. No evidence gap.

## Test Strategy

Behavior-proving tests, not file-presence. Unit assertions drive the real functions (depth
selection, the constrained-YAML round-trip, schema validation via `Test-Json`, the gate, the
research-block) and the gate denial paths (batch-approval rejection, missing-record fail-closed,
graceful skip). The integration test compares the four deployed host surfaces byte-for-byte and
proves injected drift is detected. Conduct requirements (capture / spec.md summary / reframe) are
NOT claimed as unit-proven — they are the on-host beta dogfood (the approved release path).

## Tests Run

| Command | Result | Notes |
| ------- | ------ | ----- |
| `pwsh -File tests/unit/product-domain-lens.tests.ps1` | pass | 28 assertions: depth L/S/D + default, dual-artifact + idempotent persistence, evidence tags (valid/untagged/invalid), conditional research-block, FR-011 plan-block wiring, batch-approval rejection, schema hooks + enum, gate fail-closed / graceful-skip / pass. |
| `pwsh -File tests/integration/product-domain-multihost.tests.ps1` | pass | 4 surfaces present + managed-marker + conduct present + byte-identical parity + drift detection. |
| `pwsh -File tests/unit/lens-applicability-selector.tests.ps1` | pass | regression: index.yml stays pure; selector unchanged. |
| `pwsh -File tests/unit/lens-conduct-delivery.tests.ps1` | pass | regression: design-workshop conduct delivery. |
| `pwsh -File tests/unit/design-analysis-gate.tests.ps1` | pass | regression: design-analysis + specify gate (after the FR-011 wiring + `$err` fix). |
| `pwsh -File tests/unit/design-gate-runtime-hardening.tests.ps1` | pass | regression: design-gate runtime hardening. |
| `Invoke-ScriptAnalyzer` (product-domain-lens.ps1, design-analysis-gate.ps1) | clean | 0 Errors; residual warnings are repo-consistent (`New-` ShouldProcess) or pre-existing F-141. |
| `run-mechanical-checks.ps1` | pass | no dead-field / anti-pattern / test-integrity findings. |
| `validate-governance.ps1` | pass | iteration 001 PASS (only pre-existing repo soft warnings). |

## Coverage Estimate

- Kind: qualitative; Label: behavior-and-denial-path (not file-presence); Confidence: high for
  code-side FRs, deferred-to-dogfood for conduct FRs (FR-003/FR-006/FR-012).

## Coverage-to-Requirements

| Requirement | Evidence (test -> behavior) |
| ----------- | --------------------------- |
| FR-001 / SC-001 | unit: product-domain registered first-stage + absent from the question-gated map (runs before the questionnaire). |
| FR-002 / SC-002 | unit: `Get-SpecrewProductDomainDepth` maps risk/novelty to Light/Standard/Deep + safe-middle default. |
| FR-003 | code structure (areas in schema + lens md) present; in-conversation capture is the runtime dogfood. |
| FR-004 / SC-003 | unit: every material statement evidence-tagged; untagged/invalid rejected by the validator. |
| FR-005 / SC-004 | unit: both `product-domain.yml` + `.md` persisted; idempotent re-write. |
| FR-006 | `Format-SpecrewProductDomainSummary` renders the spec.md summary; the write into spec.md is conduct (dogfood). |
| FR-007 / FR-008 / SC-008 / SC-009 | unit: schema hooks (`product_id`/`product_context_ref`/`context_scope`) present + enum-constrained; `feature_standalone` in V1; runtime wiring deferred to 156/162. |
| FR-009 / SC-005 | unit: a batch `confirmation_scope` is rejected; honest delegation accepted. |
| FR-010 / SC-004 | unit: `Test-SpecrewProductDomainGate` fail-closed on a missing/invalid record; passes on a valid one. |
| FR-011 / SC-006 | unit: load-bearing research-needed blocks (via `Test-SpecrewProductDomainPlanBlock` wired into the pre-plan gate); non-load-bearing does not. |
| FR-012 | reframe conduct in the lens md + skill; runtime dogfood. |
| FR-013 / SC-007 | integration: four host surfaces byte-identical; injected drift detected. |
| FR-014 | unit: `context_scope` enum + V1 `feature_standalone`; run-cadence rule in the lens md. |
