# Review: Iteration 005

**Schema**: v1
**Reviewed**: 2026-06-03
**Overall Verdict**: accepted

## Summary

Iteration 005 delivered the complete, state-of-the-art lens package (Amendment A2, **Option B**):
the design analysis is now genuinely **informed by** the lens knowledge (FR-009 — each selected
lens's Design Decision Points feed the option comparison), and the pre-plan gate **enforces lens
coverage** (FR-026 — block `plan.md` when a selected lens is unaddressed, naming it; SC-016). The
load-bearing discipline, accepted by the maintainer at the design-analysis gate, is that **the value
lives in the analysis, not the gate**: FR-026 is a deterministic, LLM/network-free **anti-omission
backstop**, not a quality guarantee; genuine engagement is enforced by the human design-analysis gate
plus a **blocking delete-the-`Addressed:`-lines discriminator** at review-signoff. All six tasks
(T001-T006) are `done`; selector suite **38/0**, design-analysis-gate suite **38 assertions / 14
checkpoints, 0 fail** (no regression), three additional gate suites green, validator **PASS** (6/6).
The **dogfood converged and the discriminator passed** (below).

**Rework — first review-signoff was sent back.** The Proposal 145 Phase 5 gate-completeness review
caught that grandfathering was *inferred* from "the section has no `Addressed:` lines", so deleting
every `Addressed:` entry would silently no-op the gate even when `lens-applicability.json` recorded
selected lenses — contradicting FR-026/SC-016. **Fixed:** grandfathering is now an **explicit**
`fr026_grandfathered: true` marker in the questionnaire JSON; enforcement is the default, so absence
of `Addressed:` entries FAILS and names every selected lens. Iteration 4's questionnaire carries the
explicit marker (grandfather-safe, no retroactive failure). Bypass verified closed: stripping
iteration 5's `Addressed:` lines now FAILS 4/4. Re-reviewed: **accepted**.

**Post-signoff (maintainer manual end-to-end test — honest record).** A fresh greenfield run surfaced that the lens feature **missed its core intent**: the questionnaire is auto-answered by the agent at the design-analysis stop (post-clarify), whereas it should be an interactive, expertise-adapted human intake run *before clarify* that shapes requirements/clarify/design/plan. The Crew's dogfood verified the *mechanics* but never tested the *human experience* — that gap was caught only by the maintainer's manual run. The delivered mechanics (selector, sibling map, decision-point extractor, FR-026 gate) stand and are retained; the placement/interaction/sequencing are **re-scoped to Iteration 6 via Amendment A3** (FR-025/FR-027/FR-009/FR-028) — forward work, not a defect in Iteration 5's code. Iteration 5 closes on its delivered scope.

Reviewed against the Proposal 145 dimensions (state truth, branch hygiene, functional correctness,
test integrity, evidence integrity) plus the dogfood + discriminator evidence.

## Review Dimensions (Proposal 145 framing)

### State truth

- Ledger consistent: file:///C:/Dev/Specrew-design-analysis/specs/141-design-gate-runtime-hardening/iterations/005/tasks-progress.yml (T001-T006 `done`) and the file:///C:/Dev/Specrew-design-analysis/specs/141-design-gate-runtime-hardening/iterations/005/plan.md task table agree; `Status: executing`, Capacity 17/20.
- The spec was amended consciously (Amendment A2) to un-defer FR-026, expand FR-009, add SC-016 + the FR-026 map row — file:///C:/Dev/Specrew-design-analysis/specs/141-design-gate-runtime-hardening/spec.md.
- Design-analysis gate passed (Valid=true, Option B); decision commit `0e758032` distinct from draft `d83082e2`; durable packet persisted under file:///C:/Dev/Specrew-design-analysis/specs/141-design-gate-runtime-hardening/gates/.

### Branch hygiene

- Branch `141-design-gate-runtime-hardening`. Iteration-5 commits: spec amendment `5dc56482`; design-analysis draft/decision `d83082e2`/`0e758032`/`d2149aaa`; plan `c4b49a67`; tasks `94a8a3ea`; implementation `deef3ed9`.
- **No push / no PR** while the feature is in progress. The Proposal 156 catalog `index.yml` was NOT modified (decoupled sibling map only). No release / Unix / wrapper / bootstrap surfaces touched.

### Functional correctness

- **FR-009 (decision points feed the analysis):** file:///C:/Dev/Specrew-design-analysis/scripts/internal/lens-applicability.ps1 — `Get-SpecrewLensDecisionPoints` is a pure extractor of a lens file's `## Design Decision Points` (continuation lines folded; graceful `@()` when absent); `Format-SpecrewApplicableLensesSection -CatalogDir` renders each selected lens's decision points + an `Addressed:` pointer. No network/LLM.
- **FR-026 (coverage enforcement):** file:///C:/Dev/Specrew-design-analysis/scripts/internal/design-analysis-gate.ps1 — `Test-SpecrewDesignAnalysisLensCoverage` reads the recorded `selected` set and requires a non-placeholder `Addressed:` entry per selected lens, else an error **naming** the lens; wired into `Test-SpecrewDesignAnalysisArtifact` so the pre-plan / plan-boundary gate blocks. Deterministic, LLM/network-free, and **enforce-by-default with an EXPLICIT grandfather marker**: a pre-FR-026 questionnaire must carry `fr026_grandfathered: true` to be exempt (Iteration 4's does), so deleting every `Addressed:` entry from an FR-026-era artifact cannot silently no-op the gate (the Phase 5 hole, now closed).
- **FR-010 (still scoped):** no lens-file schema validation, no overrides, no standalone command, no auto-rationale — the deferred Proposal 156 deep scope stays out.
- **Honest framing (no overclaim):** the gate's own error string and the docs call it ANTI-OMISSION, explicitly not a quality guarantee.

### Test integrity

- file:///C:/Dev/Specrew-design-analysis/tests/unit/lens-applicability-selector.tests.ps1 — **38 pass / 0 fail**: the Iteration-4 selector tests plus T001 extraction (verbatim content, multi-line fold, missing-lens/missing-dir/empty-id graceful) and T002 enriched render (decision points + `Addressed:` placeholder, MD049-safe, back-compat without `-CatalogDir`).
- file:///C:/Dev/Specrew-design-analysis/tests/unit/design-analysis-gate.tests.ps1 — **38 assertions / 14 checkpoints, 0 fail**: the Iteration-1 gate tests plus FR-026 / SC-016 (unaddressed selected lens FAILS naming it, all-addressed PASSES, placeholder/empty/TBD FAIL, no-json no-op, determinism, placeholder detection) plus the Phase-5 rework cases (**selected lenses + no `Addressed:` entries + no marker → FAIL naming all**, and **explicit `fr026_grandfathered` marker → PASS**).
- Three additional gate suites green: design-gate-runtime-hardening (unit + integration) and design-analysis-boundary (integration). Validator **PASS**, all 6 iterations incl. 141/005.

### Evidence integrity

- Runtime-verified, not file-presence: the extractor, render, and coverage gate were exercised against real inputs; determinism + grandfather-safety + placeholder detection are test-asserted on pure functions.
- No new dependencies (pure PowerShell + JSON) — file:///C:/Dev/Specrew-design-analysis/specs/141-design-gate-runtime-hardening/iterations/005/dependency-report.md. Coverage + TG-006 ledger: file:///C:/Dev/Specrew-design-analysis/specs/141-design-gate-runtime-hardening/iterations/005/coverage-evidence.md.

### Dogfood + discriminator evidence (the load-bearing check)

Iteration-5's own design-analysis "Applicable Lenses" section was **regenerated through the
implemented enriched path** — answers in file:///C:/Dev/Specrew-design-analysis/specs/141-design-gate-runtime-hardening/iterations/005/lens-applicability.json (`data=yes`; all else no) → `Format-SpecrewApplicableLensesSection -CatalogDir`. The Decision points are now **verbatim from the lens files**, the selection reproduces the recorded JSON `selected`, and the FR-026 gate re-validated `Valid=true` (Option B intact). Then the **blocking discriminator** was applied — delete every `Addressed:` line and check the option comparison still engages each selected lens:

```text
FR-026 gate on iter-5 (tool-rendered)        : Valid=True, Selected=Option B
discriminator (strip all Addressed: lines)   :
  architecture-core (binding constraints)    : options STILL engage  [PASS]
  component-design  (decoupled units)        : options STILL engage  [PASS]
  requirements-nfr  (prove-quality)          : options STILL engage  [PASS]
  data-storage      (consistency invariant)  : options STILL engage  [PASS]
DISCRIMINATOR                                : PASSES (engagement lives in the options, not a checkbox)
```

Engagement is real, not theater → no send-back. The rendered section is regenerable verbatim via the
Iteration-5 quickstart render command.

## Task Verdicts

| Task | Requirement | Verdict | Notes |
| ---- | ----------- | ------- | ----- |
| T001 | FR-009 | pass | `Get-SpecrewLensDecisionPoints` pure extractor; graceful degradation; verbatim + folded. |
| T002 | FR-009, SC-006 | pass | Enriched render (decision points + `Addressed:` pointer); back-compat without `-CatalogDir`. |
| T003 | FR-026, FR-010 | pass | `Test-SpecrewDesignAnalysisLensCoverage` wired into the gate; anti-omission; grandfather-safe; names the lens (SC-016). |
| T004 | FR-009 | pass | Template nudge: decision points shape the options; `Addressed:` points into the comparison. |
| T005 | FR-026, SC-016, SC-006 | pass | 38/0 selector + 38-assertion gate incl. SC-016, the Phase-5 bypass-closed + explicit-marker grandfather cases, determinism. |
| T006 | TG-006, FR-009 | pass | quickstart Iteration-5 + dogfood + blocking discriminator (passed). |

## TG-006 classification (Rule 39 — implemented / enforced / observable / documented)

| Requirement | Implemented | Enforced | Observable | Documented |
| ----------- | ----------- | -------- | ---------- | ---------- |
| FR-009 (lens-informed analysis) | yes — extractor + enriched render | via FR-026 coverage (a selected lens must be addressed) | yes — rendered Decision points + `Addressed:` entries | yes — template nudge + quickstart |
| FR-026 (coverage gate) | yes — `Test-SpecrewDesignAnalysisLensCoverage` | yes — wired into `Test-SpecrewDesignAnalysisArtifact`; blocks plan | yes — error names the unaddressed lens (SC-016) | yes — spec FR-026/SC-016 + template + quickstart |
| Honest limit (anti-omission, not quality) | n/a (a discipline) | by process — blocking discriminator at review-signoff | yes — gate string + docs say "anti-omission only" | yes — spec, template, quickstart, this review |

## Gap Ledger

- No requirement (FR/SC) gaps: FR-009, FR-010, FR-026, SC-006, SC-016, TG-006 all verified: **fixed-now**.

## Follow-ups (not iteration-005 gaps)

- **(Resolved this iteration — Proposal 145 Phase 5 send-back.)** Grandfathering is now the explicit `fr026_grandfathered` marker in `lens-applicability.json`, not the presence of `Addressed:` entries; enforcement is the default. Deleting every `Addressed:` entry from an FR-026-era artifact now FAILS the gate (verified, 4/4). The blocking delete-the-`Addressed:`-lines discriminator remains the genuine-engagement check layered on top of the omission gate.
- Deferred Proposal 156 deep scope (lens-file schema-validation enforcement, overrides, standalone `specrew lens` command, per-lens rationale automation) remains future; FR-010 keeps it out here.

## Notes

- Reviewer artifacts: file:///C:/Dev/Specrew-design-analysis/specs/141-design-gate-runtime-hardening/iterations/005/reviewer-index.md, code-map.md, coverage-evidence.md, dependency-report.md, review-diagrams.md.
- Hardening-gate concerns promoted to runtime-evidence at this review-signoff (see file:///C:/Dev/Specrew-design-analysis/specs/141-design-gate-runtime-hardening/iterations/005/quality/hardening-gate.md).
