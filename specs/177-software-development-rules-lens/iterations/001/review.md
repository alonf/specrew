# Review: Iteration 001

**Schema**: v1
**Reviewed**: 2026-06-10
**Overall Verdict**: accepted

## Summary

Iteration 001 (i1 — capture substrate) delivers the data + validation half of the code-implementation
lens: the canonical catalog, the per-feature manifest schema, the lens md, registration, and the
PowerShell writer/validator, all unit-tested. There is **no agent-facing runtime surface in i1** (the
workshop conduct turn + the `specrew-code-rules` guidance skill + the SC-004/SC-007/SC-008 **dogfood** are
iteration 002), so i1 is reviewed against unit/static evidence; the deployed runtime dogfood is i2's gate
(maintainer principle: the deployed dogfood is the gate, not unit-green).

## Task Verdicts

| Task | Requirement | Verdict | Notes |
| ---- | ----------- | ------- | ----- |
| T001 | FR-002 | pass | `code-rules.yml`: 60 unique ids, the 3 F-177 additions + per-stack + groups + scopes present; verified by T007 + YAML parse. |
| T002 | FR-004 | pass | Manifest schema shipped in the catalog; accepts null on optional fields (ConvertTo-Json padding); verified by T008. |
| T003 | FR-001 | pass | `code-implementation.md` carries the required lens-schema sections + conduct; verified by T009 + lens-conduct-delivery. |
| T004 | FR-001 | pass | Registered in index.yml + `$lensIds`; conduct-driven (drift D-001), NOT in the deterministic map; selector + registration tests green. |
| T005 | FR-004 | pass | Writer/validator: constrained-YAML round-trip, JSON-projection schema validation, fail-open, UTF-8 no-BOM; PSScriptAnalyzer Errors=0. |
| T006 | FR-013 | pass | `dependency_policy` capture (default-first stance + 12 fields); verified by T008. |
| T007 | FR-002 | pass | Catalog-integrity test green (16 assertions). |
| T008 | FR-004 | pass | Manifest schema + overlay test green (positive/negative + overlay-never-drops + provenance). |
| T009 | FR-001 | pass | Registration test green (index.yml + lens-md sections + conduct-driven-not-in-map). |

## Review Dimensions

- **Functional correctness**: the writer produces a schema-valid reference-by-ID manifest; the validator
  catches unknown ids, bad provenance pairing, and invalid context_scope; the overlay merge never drops a
  shipped rule. All exercised by the unit suite (38 assertions, PASS).
- **NFR / quality drivers**: maintainability — one source of truth (the catalog, stable ids), no rule
  text duplicated; the writer mirrors the proven product-domain constrained-YAML pattern (no
  powershell-yaml dependency). Multi-host parity + the rule-volume UX are i2.
- **Code quality**: PSScriptAnalyzer Errors = 0 (the New-/plural-noun warnings are the repo-tolerated
  Warning class, CI is Error-only); ASCII-clean; markdownlint clean.
- **Test coverage + integrity**: behavior-proving (round-trip, positive + negative validation, overlay
  semantics, registration), not file-presence; see coverage-evidence.md.
- **System safety / ops**: no auth/secrets/PII/network in i1; fail-open everywhere; mechanical-checks
  findings = 0.

## Gap Ledger

- No requirement (FR/SC) gaps in iteration-001 scope: catalog, schema, lens md, registration, writer/validator, and the i1 unit tests are all verified: fixed-now.

## Notes

- **Drift D-001** (registration mechanism — conduct-driven, not the deterministic applicability-map) is
  recorded in drift-log.md and resolved; surface it at the feature-level review per Proposal 174.
- **Carried to iteration 002 (by design, not an i1 gap)**: the workshop conduct turn (FR-003/FR-009/
  FR-010/FR-011 interactive behavior), the `specrew-code-rules` guidance skill (FR-005/FR-006/FR-008), and
  the **deployed runtime dogfood** proving SC-004 (agent guided), SC-007 (no rule wall), and SC-008
  (dependency stance honored) — installed-module layout, fresh `specrew init`, not the dev tree.
- Mechanical-checks: 0 findings. Validator: PASSES iterations/001.
- **code-map.md form-vs-meaning WARNING reviewed + benign**: it reports 9 completed tasks vs 11 changed
  files (since the before-implement baseline). The heuristic expects a 1:1 task-to-file mapping, which does
  not hold here — T001 + T006 both edit `code-rules.yml`; T002 edits the schema in two locations (shipped
  catalog + the contracts copy); T007/T008/T009 share `code-implementation-lens.tests.ps1`; plus the
  state.md / plan.md status syncs. Every changed file maps to a task in the code-map Files-Touched table;
  there is no untracked or unexplained change. (The prior "0 completed vs 28 files" was a real state-truth
  gap — task statuses were `planned`; fixed by setting them to `done` + the before-implement baseline.)
