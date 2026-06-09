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

## Proposal 145 Structured-Review Audit

Proposal 145 (host-neutral 7-phase reviewer) is a candidate (unshipped), so its
machine-readable artifacts are not validator-required; the discipline is applied here as prose.

- **Phase 0 (context load)**: spec / plan / tasks / drift-log / design-analysis / code-map / coverage loaded.
- **Phase 1 (branch hygiene)**: 16 boundary commits, clean cadence; all feature evidence files are committed (Shape-5 clean — no working-tree-only evidence). Branch is local-only (push deferred to feature-closeout per the SDLC — not a defect now). The 44 dirty working-tree entries are CLASSIFIED: pre-existing deploy churn (`.cursor` / `.copilot` / `.claude/agents` / etc. — not mine) plus per-boundary session-state (`.squad/decisions.md`, identity, version-cache — runtime, not feature source). FIXED: the 4 design-workshop `.specrew-managed` markers (were untracked) committed. **Closeout note**: the PR must carry ONLY feature-176 changes, not the pre-existing churn.
- **Phase 2 (functional)**: logic traced + tested (not auto-pass on green); fail-open / fail-closed and edge cases (empty / invalid / absent record + catalog) covered. Workshop/design conformance ledger below.
- **Phase 3 (NFR)**: security surface = evidence-integrity only (no auth / secrets / network); i18n proven (non-Latin / RTL / emoji round-trip test); fail-open WARN observability.
- **Phase 4 (code quality)**: PSScriptAnalyzer Error-clean; markdownlint clean. Anti-pattern dispositions: the broad `catch { return $null }` / `catch { $ok = $false }` in `product-domain-lens.ps1` are INTENTIONAL fail-open graceful degradation (`accepted_with_rationale` — the gate fails closed separately), not catch-and-ignore. No sleep-sync, no hidden global mutable state (script-scope vars are read-only constants), no unbounded retries, no test-only production behavior. Fixtures are REAL (real schema + temp features — no Shape-6 synthetic stand-in). **Dependency reality**: NO new dependencies — pure PowerShell + the built-in `Test-Json`; explicit no-new-dependency proof.
- **Phase 5 (test coverage + integrity)**: every code-side FR has a behavior test; FR-003/006/012 conduct deferred to the dogfood (honest). **Negative/falsification cases for the new gate are PRESENT (Shape-8)**: T011 (batch-approval FAILS) and T015 (missing-record FAILS) prove the gate fails for its target defect class, not just a passing happy path. Producer/consumer: the gate has consumer-side fail-closed demos. Gate-completeness reflection: the floor enforces presence + schema + non-batch provenance; semantic correspondence (the record matches THIS feature, not a stale copy) is the documented dogfood boundary.
- **Phase 6 (system safety + ops)**: failure modes catalogued + tested; backward-compatible (marker-gated + grandfather-safe — pre-176 features not retroactively failed); rollback = revert the commits; multi-dev collision surface (shared `design-analysis-gate.ps1` + `index.yml`) noted.
- **Phase 7 (synthesis + falsification)**: report-falsification applied — the review DOWNGRADED FR-003/006/012 from "tested" to "dogfood-proven", surfaced the host-copy debt and the focused-YAML-parser tradeoff, and found + fixed the FR-011 wiring gap. No over-strong claim survives.

### Workshop-decision conformance (145 ↔ 176 composition link)

| Decision (source) | Implementation | Evidence | Disposition |
| --- | --- | --- | --- |
| Option B first-stage phase (design-analysis) | `index.yml` `default_phase: intake-product-domain`; design-workshop conduct | T006 | satisfied |
| Enforcement = extend gate + SC-026 provenance (Q1) | `Test-SpecrewProductDomainGate` | T010, T011, T015 | satisfied |
| Conditional research-needed blocking (Q2) | `Test-SpecrewProductDomainResearchBlock` + pre-plan wiring | T008 (FR-011) | satisfied |
| Run-cadence rule + `context_scope` (design verdict) | lens md Run Cadence; FR-014; schema enum | T013 | satisfied |
| `product_id` / `product_context_ref` hooks (clarify verdict) | schema + record | T013 | satisfied |
| 5-host / 4-surface deploy (specify verdict) | conduct + deploy + wording | T012, T014 | satisfied |
| Intake component map (co-design) | lens md / writer / conduct / gate / tests | full suite | satisfied |
| FR-007 / FR-008 deferred to shape (design verdict) | schema hooks only; no runtime wiring | T013 + drift D-001/D-002 | n/a-with-reason (deferred) |
| Stack = PowerShell, concurrency n/a (DP3) | plan quality bar | hardening-gate + PSSA/Pester/mechanical/validator | satisfied |

## Notes

- Verification (maintainer-required, all green): unit suite (product-domain-lens.tests.ps1) 26 asserts; integration host-parity (product-domain-multihost.tests.ps1); regression — lens-applicability-selector, lens-conduct-delivery, design-analysis-gate, design-gate-runtime-hardening all pass; PSScriptAnalyzer Error-clean for the new/edited files; run-mechanical-checks: no findings; governance validator PASS for iteration 001.
- Residual PSScriptAnalyzer WARNINGS (not blocking, repo-consistent): `New-` ShouldProcess style (same as the existing `New-SpecrewLensApplicabilityTemplate`); pre-existing `Normalize-`/`PSUseSingularNouns` warnings in design-analysis-gate.ps1 (Feature-141 code, out of FR scope).
- Runtime-conduct proof for FR-003/FR-006/FR-012 is the on-host beta dogfood (release path the maintainer approved at before-implement): exercise a real intake on the Claude host, confirm the product-domain phase runs first, the record persists, and the specify gate enforces it.
- Drift D-001/D-002 (156/162 deferral) + D-003 (stack correction) recorded in drift-log.md; no new drift this iteration.
- No same-specialty parallelism used; single Implementer/Reviewer flow.
