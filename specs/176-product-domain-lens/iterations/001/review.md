# Review: Iteration 001

**Schema**: v1
**Reviewed**: 2026-06-10
**Overall Verdict**: accepted

## Task Verdicts

| Task | Requirement | Verdict | Notes |
| ---- | ----------- | ------- | ----- |
| T001 | FR-002, FR-003, FR-004, FR-012, FR-014 | pass | product-domain.md lens: 8 decision areas, depth model, evidence vocab, run cadence, no-batch/reframe conduct. |
| T002 | FR-001 | pass | index.yml first-stage `default_phase: intake-product-domain` (selector stays pure); diagram-vocabulary context map. |
| T003 | FR-004, FR-007, FR-008, FR-014, SC-008, SC-009 | pass | product-domain.schema.json with the product_id/product_context_ref/context_scope hooks + conditional load_bearing; Test-Json validated. |
| T004 | FR-002, FR-005, FR-006, FR-011, SC-002, SC-004, SC-006 | pass | product-domain-lens.ps1: depth selector, dual-artifact writer (idempotent), validator, summary renderer, research-block. Constrained-YAML round-trip tested. |
| T005 | FR-001, FR-006, FR-012, SC-001 | pass | first-stage phase conduct added to the design-workshop SKILL source. |
| T006 | FR-001, SC-001 | pass | test: product-domain registered first-stage + NOT in the question-gated map (runs before the questionnaire). |
| T007 | FR-002, SC-002 | pass | test: depth selection across Light/Standard/Deep + safe-middle default. |
| T008 | FR-004, FR-011, SC-003, SC-006 | pass | test: evidence tags, untagged/invalid rejected, conditional load-bearing research-block + the FR-011 plan-block wiring. |
| T009 | FR-005, SC-004 | pass | test: both .yml + .md persisted; idempotent re-write. |
| T010 | FR-009, FR-010, SC-004, SC-005 | pass | Test-SpecrewProductDomainGate wired into the specify lens gate; fail-closed, no silent skip. |
| T011 | FR-009, SC-005 | pass | test: a batch confirmation_scope is rejected; honest delegation accepted. |
| T012 | FR-013, SC-007 | pass | conduct deployed verbatim to all 4 host surfaces (source + mirror + 4 hosts identical). |
| T013 | FR-007, FR-008, FR-014, SC-008, SC-009 | pass | test: schema hooks present + enum-constrained; feature_standalone in V1. |
| T014 | FR-013, SC-007 | pass | integration test: host-skill parity holds; injected drift detected. |
| T015 | FR-010, FR-013 | pass | test: absent record fails the gate CLOSED (no silent skip); absent catalog gracefully skips; valid record passes. |

## Critical Review (requirement classification)

Each in-scope FR classified as implemented / enforced / observable / documented:

- **FR-001 / FR-002 / FR-004 / FR-005 / FR-009 / FR-010 / FR-013 / FR-014**: implemented + enforced
  (gate/tests) + observable (record on disk, gate WARN/throw) + documented (lens md, spec, plan).
- **FR-007 / FR-008**: implemented as forward-compatible shape (schema hooks) + tested; runtime wiring
  to Proposals 156/162 correctly deferred (drift D-001/D-002).
- **FR-011**: implemented (`Test-SpecrewProductDomainResearchBlock`) AND now enforced — review found
  the helper was unit-tested but not wired to block plan; fixed by wiring
  `Test-SpecrewProductDomainPlanBlock` into the pre-plan gate (fail-closed on a load-bearing gap).
- **FR-003 (capture) / FR-006 (spec.md summary) / FR-012 (reframe)**: the code provides the structure
  (schema + areas), the `Format-SpecrewProductDomainSummary` renderer, and the conduct (lens md +
  skill). The actual in-conversation capture, the spec.md summary write, and the solution-first
  reframing are agent **conduct** — proven by the on-host runtime dogfood (the maintainer's beta
  validation, the approved release path), not by unit tests. This is the documented form-vs-runtime
  boundary; the unit suite cannot and does not claim to prove conduct.

## Gap Ledger

- FR-011 plan-boundary enforcement was implemented-but-unwired (helper + test existed; nothing blocked plan): wired into the pre-plan gate with 2 new tests: fixed-now.
- Pre-existing Feature-141 PSScriptAnalyzer Error in design-analysis-gate.ps1:670 (`foreach ($error ...)` automatic-variable assignment) was in a file this feature ships: renamed to `$err`, my files are now PSScriptAnalyzer Error-clean: fixed-now.
- The 4 design-workshop host SKILL.md copies were untracked pre-existing F-141 deploy-debt (source committed, host copies never were, unlike all 78 other tracked host-skill files): committed with the feature to match the convention + make the parity test reproducible: fixed-now.

## Notes

- Verification (maintainer-required, all green): unit suite (product-domain-lens.tests.ps1) 26 asserts; integration host-parity (product-domain-multihost.tests.ps1); regression — lens-applicability-selector, lens-conduct-delivery, design-analysis-gate, design-gate-runtime-hardening all pass; PSScriptAnalyzer Error-clean for the new/edited files; run-mechanical-checks: no findings; governance validator PASS for iteration 001.
- Residual PSScriptAnalyzer WARNINGS (not blocking, repo-consistent): `New-` ShouldProcess style (same as the existing `New-SpecrewLensApplicabilityTemplate`); pre-existing `Normalize-`/`PSUseSingularNouns` warnings in design-analysis-gate.ps1 (Feature-141 code, out of FR scope).
- Runtime-conduct proof for FR-003/FR-006/FR-012 is the on-host beta dogfood (release path the maintainer approved at before-implement): exercise a real intake on the Claude host, confirm the product-domain phase runs first, the record persists, and the specify gate enforces it.
- Drift D-001/D-002 (156/162 deferral) + D-003 (stack correction) recorded in drift-log.md; no new drift this iteration.
- No same-specialty parallelism used; single Implementer/Reviewer flow.
