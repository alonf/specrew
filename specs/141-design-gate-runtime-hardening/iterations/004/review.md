# Review: Iteration 004

**Schema**: v1
**Reviewed**: 2026-06-03
**Overall Verdict**: accepted

## Summary

Iteration 004 delivered questionnaire-driven Applicable-Lenses selection (FR-009/FR-010/FR-025;
SC-006/SC-015; TG-006) per Amendment A1, **Option B decoupled**. A fixed applicability questionnaire
is recorded as `lens-applicability.json`; a pure, deterministic, LLM/network-free selector maps
answers to lenses (foundational always-on + specialized gated) via a **sibling map file** (the
Proposal 156 catalog `index.yml` stays pure); the "Applicable Lenses" section renders from the
selection with graceful degradation. All six tasks (T001-T006) are `done`, selector suite **27/0**,
design-analysis-gate suite 12/0 (no regression), validator **PASS** (5/5). The maintainer-requested
**dogfood render converged** (below). Verdict: **accepted**.

Reviewed against the Proposal 145 dimensions (state truth, branch hygiene, functional correctness,
test integrity, evidence integrity) plus the dogfood evidence.

## Review Dimensions (Proposal 145 framing)

### State truth

- Ledger consistent: file:///C:/Dev/Specrew-design-analysis/specs/141-design-gate-runtime-hardening/iterations/004/tasks-progress.yml (T001-T006 `done`) and the file:///C:/Dev/Specrew-design-analysis/specs/141-design-gate-runtime-hardening/iterations/004/plan.md task table agree.
- The spec was amended consciously (Amendment A1) to un-defer FR-009/FR-010 + add FR-025; all stale "pre-deferred" references reconciled — file:///C:/Dev/Specrew-design-analysis/specs/141-design-gate-runtime-hardening/spec.md.
- Design-analysis gate passed (Valid=true, Option B); decision commit distinct from draft.

### Branch hygiene

- Branch `141-design-gate-runtime-hardening`. Iteration-4 commits: spec amendment `cabb1655`; design-analysis `fb4b31e0`/`51b31aaf`/`e6f13299`; plan `6667e9d1`; tasks+hardening-gate `83e1c1e9`; implementation `6b6d7d72`/`bfb41cea`/`7a689ab6`; dogfood+fix `e5483005`.
- **No push / no PR** while the feature is in progress. The `index.yml` catalog was NOT modified (decoupled sibling map). Non-141 sync churn (Specrew.psd1) reverted.

### Functional correctness

- **FR-025 (questionnaire → JSON → deterministic selection):** file:///C:/Dev/Specrew-design-analysis/scripts/internal/lens-applicability.ps1 — `Get-SpecrewApplicableLenses` is a pure function (always-on ∪ gated-yes), `New-SpecrewLensApplicabilityTemplate` emits the questionnaire JSON, `Get-SpecrewLensSelection` records the per-lens audit. No network/LLM.
- **FR-010 (decoupled + scoped):** the gating map is the sibling file:///C:/Dev/Specrew-design-analysis/extensions/specrew-speckit/knowledge/design-lenses/applicability-map.json; `index.yml` stays pure (test-asserted). No overrides/schema-enforcement/command/rationale automation (deferred 156 stays out).
- **FR-009 (render):** `Format-SpecrewApplicableLensesSection` renders the section; the design-analysis template now carries it — file:///C:/Dev/Specrew-design-analysis/extensions/specrew-speckit/templates/design-analysis.template.md.

### Test integrity

- file:///C:/Dev/Specrew-design-analysis/tests/unit/lens-applicability-selector.tests.ps1 — **27 pass / 0 fail**: SC-015 determinism (identical answers → identical ordered set), gating correctness, never-hide-an-always-on-lens, string/bool truthiness, render scope + "none available" degradation (SC-006), questionnaire-artifact shape + no-overwrite, `index.yml` purity, and the MD049 emphasis guard. The selector is a pure function → deterministic unit tests, not file-presence.
- design-analysis-gate suite **12/0** (no regression from the template "Applicable Lenses" section). Validator **PASS**, all 5 iterations incl. 141/004.

### Evidence integrity

- Runtime-verified, not file-presence: the selector/render were exercised against real inputs; the `index.yml`-purity and determinism are test-asserted.
- No new dependencies (pure PowerShell + JSON) — file:///C:/Dev/Specrew-design-analysis/specs/141-design-gate-runtime-hardening/iterations/004/dependency-report.md. TG-006 gap ledger: file:///C:/Dev/Specrew-design-analysis/specs/141-design-gate-runtime-hardening/iterations/004/coverage-evidence.md.

### Dogfood evidence (maintainer-requested)

Iteration-4's own design-analysis "Applicable Lenses" section was **rendered through the implemented
path** — answers in file:///C:/Dev/Specrew-design-analysis/specs/141-design-gate-runtime-hardening/iterations/004/lens-applicability.json (`data=yes`: new JSON artifact + sibling map = data/state; all else no) → `Get-SpecrewApplicableLenses` → `Format-SpecrewApplicableLensesSection`. **Divergence check PASSED:** the rendered section lists exactly the recorded JSON `selected`, and converges with the original hand-judged set:

```text
selected (JSON) : architecture-core, component-design, requirements-nfr, data-storage
render listed   : architecture-core, component-design, requirements-nfr, data-storage
CONVERGE        : True
```

The rendered section now lives in file:///C:/Dev/Specrew-design-analysis/specs/141-design-gate-runtime-hardening/iterations/004/design-analysis.md; the gate re-validated `Valid=true` (Human Decision intact). No divergence → no send-back.

## Task Verdicts

| Task | Requirement | Verdict | Notes |
| ---- | ----------- | ------- | ----- |
| T001 | FR-025, FR-010 | pass | Sibling `applicability-map.json` (6 questions + always-on); `index.yml` pure. |
| T002 | FR-025 | pass | `lens-applicability.json` emit (no-overwrite); questionnaire shape. |
| T003 | FR-025, FR-010 | pass | Pure deterministic selector; no network/LLM. |
| T004 | FR-009, FR-010, SC-006 | pass | Render + graceful degradation; design-analysis template wired. |
| T005 | SC-006, SC-015 | pass | 27/0 incl. determinism + degradation + MD049 guard. |
| T006 | TG-006 | pass | quickstart Iteration-4 + gap ledger. |

## Gap Ledger

- No requirement (FR/SC) gaps: FR-009, FR-010, FR-025, SC-006, SC-015, TG-006 all verified: fixed-now.

## Follow-ups (not iteration-004 gaps)

- Deferred Proposal 156 deeper scope (overrides, schema-validation enforcement, broad automation, standalone `specrew lens` command, per-lens rationale) — recorded in Proposal 156 (main) as future; FR-010 keeps it out here.
- Optional: auto-wire the scaffold (`scaffold-iteration-artifacts.ps1`) to emit `lens-applicability.json` + render automatically (currently helper + template-guidance driven). Candidate refinement.

## Notes

- Reviewer artifacts: file:///C:/Dev/Specrew-design-analysis/specs/141-design-gate-runtime-hardening/iterations/004/reviewer-index.md, code-map.md, coverage-evidence.md, dependency-report.md, review-diagrams.md.
