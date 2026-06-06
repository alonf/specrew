# Coverage Evidence: Iteration 004

**Schema**: v1
**Prepared**: 2026-06-03
**Overall Verdict**: pending-review-signoff (producer-side; the Reviewer accepts at review-signoff)

> **Scope**: questionnaire-driven Applicable-Lenses selection — FR-009/FR-010/FR-025, SC-006/SC-015,
> TG-006 (Amendment A1; Option B decoupled).

## Test Strategy

- The selector is a pure function of (decoupled sibling map, recorded answers), so SC-015 determinism
  and SC-006 scope/degradation are deterministic unit tests, not file-presence checks.
- `index.yml` purity is asserted by test (the gating map is the decoupled sibling).

## Tests Run

| Command | Result | Pass | Fail | Exit | Notes |
| ------- | ------ | ---- | ---- | ---- | ----- |
| `pwsh -File tests/unit/lens-applicability-selector.tests.ps1` | pass | 26 | 0 | 0 | SC-015 determinism (same answers → identical ordered set); gating correctness; never-hide-an-always-on-lens; string/bool truthiness; render scope + "none available" degradation (SC-006); the questionnaire-artifact shape + no-overwrite; **`index.yml` stays pure**. |
| Governance validator (`extensions/specrew-speckit/scripts/validate-governance.ps1 -NoCacheRead`) | pass | — | — | 0 | Iteration 004 PASS (re-run post-implementation). |

## TG-006 Gap Ledger (implemented / enforced / observable / documented)

| Behavior | Implemented | Enforced (test) | Observable (runtime) | Documented |
| -------- | ----------- | --------------- | -------------------- | ---------- |
| FR-009 — "Applicable Lenses" section rendered from the questionnaire selection | `Format-SpecrewApplicableLensesSection` (`scripts/internal/lens-applicability.ps1`) + the section in `design-analysis.template.md` | selector tests (render: heading + selected + not-selected) | the rendered section in `design-analysis.md` | quickstart Iteration-4 + this ledger |
| FR-010 — decoupled + scoped; deep automation deferred | sibling `applicability-map.json` (`index.yml` UNTOUCHED); no overrides/schema-enforcement/command/automation | test asserts `index.yml` has no `gated_by`/`always_on` | the sibling map file beside the catalog | quickstart + design-analysis decision (Option B decoupled) |
| FR-025 — questionnaire → JSON → deterministic selection | `applicability-map.json` + `New-SpecrewLensApplicabilityTemplate` (JSON emit) + `Get-SpecrewApplicableLenses` (pure selector) | selector tests (determinism, gating, truthiness) | `lens-applicability.json` answers + the selected set | quickstart + the helper module |
| SC-006 — lists selected + degrades gracefully | render function | render tests (scope + "none available" on absent map/answers) | the section content | this ledger |
| SC-015 — deterministic + per-lens audit | pure selector + `Get-SpecrewLensSelection` audit | determinism test + audit (included/excluded reason) test | the JSON `included`/`excluded` rationale | this ledger |

## Notes

- No network/LLM in the JSON→selection step (the only judgment input is the recorded answers); the
  selector is a pure function. Truly-deep Proposal 156 automation stays deferred (FR-010); Proposal 156
  was updated (main) to record implemented-vs-future.
- Runtime evidence (the three `addressed` hardening-gate concerns) is promoted to `recorded` at review-signoff.
