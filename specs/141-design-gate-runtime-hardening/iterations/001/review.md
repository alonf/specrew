# Review: Iteration 001

**Schema**: v1
**Reviewed**: 2026-06-02
**Overall Verdict**: accepted
**Review Style**: Proposal 145 structured review
**Implementation Commit**: `32ed8383`
**Smoke Send-Back Fixes Commit**: `eedf1604`
**Re-tested At**: `eedf1604`

## Findings

- No blocking findings.
- The scaffolder's form-vs-meaning heuristic notes 10 completed tasks vs 15 changed files. This is an expected count mismatch, not a gap: the 15 files are 6 source/test files (helper, template, start-prompt, manifest, 2 test suites) plus 9 governance/spec artifacts, and several tasks legitimately touch the shared helper. All work is committed (`32ed8383` → `74aba427`); the heuristic's 1:1 task-to-file expectation does not hold for a single-helper feature.

## Smoke Send-Back and Fixes (2026-06-02)

An external manual smoke (`C:\Temp\SpecrewTrials\test1234`, feature
`001-azure-bicep-upgrade-scanner`) sent this iteration back from review. The smoke
was honest and correct: the helpers existed but were not wired into the enforced
flow. Evidence and the per-observation pass/fail table are in
`iterations/001/manual-smoke.md`. Four in-scope gaps were fixed and re-verified;
one UX gap is correctly deferred-within-feature:

- **Packet not in the real flow (FR-020, fixed)**: `Invoke-SpecrewDesignAnalysisPrePlanGate` now **requires** the durable `gates/` packet (exists + valid); packet persistence is enforced, not an unused helper. Dogfooded — Feature 141 now has `specs/141-design-gate-runtime-hardening/gates/design-analysis-001.md`.
- **Pre-plan validator not exercised (FR-002/FR-003/FR-021, fixed)**: the generated handoff mandates the explicit sequence (record decision → render packet → validate → persist → call the pre-plan validator) before `plan.md`.
- **Decision-commit drift (FR-008 refinement, fixed)**: the validator rejects recording the design-analysis draft commit as the decision commit; the Human Decision model now separates `Design-analysis draft commit` from `Decision recorded in commit`. Feature 141's own artifact was corrected (`337e2523` draft vs `e07446b4` decision).
- **Shallow handoff (FR-004 refinement, fixed)**: the template presents a per-option "Design principle / why this matters" rationale.
- **Lens activation (FR-009/FR-010, deferred-within-feature)**: not activated in the smoke, which is expected for Iteration 1 only because lenses were pre-deferred; remains a named later-iteration obligation, not an Iteration 1 in-scope failure.

All four code fixes are re-verified at `eedf1604`: 141 unit + integration suites pass (incl. missing-packet-blocks, decision-commit-drift-rejected, and at-sync backstop), Feature 140 suites still pass, mechanical checks empty, governance validator clean.

## Proposal 145 Structured Review

| Review Area | Verdict | Evidence |
| --- | --- | --- |
| Context load | pass | Reviewed the clarified spec, Option B design-analysis decision, plan.md (18 SP, lens deferred), and the four FR-021 review-emphasis points supplied at the implement gate. |
| Branch hygiene | pass | All implementation committed across `32ed8383`/`f4172cb4`/`2926dea0`/`74aba427` on `141-design-gate-runtime-hardening` (stacked on the Feature 140 tip); unrelated runtime/agent churn left unstaged; `.squad/decisions.md` churn intentionally not committed per the Feature 140 retro practice. |
| Functional correctness | pass | Scaffold emits a conformant artifact (non-destructive); pre-plan validator blocks on missing/invalid artifact or Human Decision and passes only when valid; typed packet renders/validates/persists scoped to `gates/`; selected option flows to plan input; validator robustness accepts prose By-the-book and resolves one recommendation despite contextual mentions. |
| NFR/security | pass | No auth, secrets, network, or eval surface introduced; the helper only reads/validates local lifecycle artifacts. Durable packet is scoped to the design-analysis gate only (no Proposal 155 generalization). No Proposal 105 host hooks. |
| Code quality | pass | New functions are isolated, named consistently with the Feature 140 helper, and reuse the existing validation core; the Feature 140 helper was extended, not rewritten (FR-008). |
| Test integrity | pass | New 141 unit + integration suites assert real block/pass and render/validate behavior (not file-presence), including negative cases (missing artifact, missing decision, genuine multi-recommendation, missing packet section, bare-path packet). Feature 140 unit + integration suites still pass (no regression). |
| System safety/ops | pass | At-sync plan-boundary gate still invoked in `sync-boundary-state.ps1` for the `plan` boundary as the bypass backstop; boundary-sync atomicity unaffected; governance validator clean repo-wide; mechanical-findings empty. |

## FR-021 Enforcement Classification (per review emphasis)

Reviewed honestly against the accepted Iteration 1 model — **not** as a host-hook or tool-level mechanical write-block:

- **Implemented / enforced by**: cooperative coordinator instruction (generated guidance in `scripts/specrew-start.ps1` mandates the explicit record → render → validate → persist → call sequence before `plan.md`) **plus** a callable pre-plan validator (`Invoke-SpecrewDesignAnalysisPrePlanGate`) that fails closed on a missing/invalid artifact, Human Decision, **or durable `gates/` packet** (smoke-amended 2026-06-02 — packet now required-in-flow, not an unused helper).
- **Backed by**: the at-sync plan-boundary hard gate (`Invoke-SpecrewDesignAnalysisPlanBoundaryGate`, invoked in `sync-boundary-state.ps1` for the `plan` boundary) — if the coordinator bypasses the pre-plan call, the plan-boundary sync still blocks before state advancement.
- **NOT**: a host-native mechanical write-block and **not** Proposal 105 hook-level enforcement. A non-cooperating process could still write `plan.md` bytes; the guarantee is cooperative-plus-backstop, not OS/tool interception.
- **Overclaim check**: no delivered artifact claims `plan.md` "cannot be written mechanically" or implies Proposal 105 hooks. The spec FR-021, the plan, and the contract all state the cooperative-prompt + callable-validator + sync-backstop model explicitly. No correction required.

### Four verified review points

1. `scripts/specrew-start.ps1` generated guidance instructs the coordinator to run the pre-plan validator before authoring `plan.md` — verified in the design-analysis lifecycle row.
2. The callable validator blocks when `design-analysis.md` or the Human Decision is missing/invalid — verified by `tests/integration/design-gate-runtime-hardening.tests.ps1` (two block cases).
3. The callable validator passes only when the artifact and decision are valid — verified by the same suite (pass case).
4. The at-sync plan-boundary gate still catches violations on bypass — `Invoke-SpecrewDesignAnalysisPlanBoundaryGate` remains wired in the `plan` sync path and is covered by `tests/integration/design-analysis-boundary.tests.ps1` (Feature 140, still passing).

## Task Verdicts

| Task | Requirement | Verdict | Notes |
| ---- | ----------- | ------- | ----- |
| T001 | FR-016, FR-017, FR-018, FR-019 | pass | Scope, Option B, scope limits, and lens deferral confirmed; recorded in drift-log. |
| T002 | FR-001, FR-008, TG-007 | pass | Template file + non-destructive scaffold reconciled with the validator contract; scaffold-conformance tested. |
| T003 | FR-022 | pass | By-the-book detection tolerates prose ("By the book") while still enforcing the option shape; Feature 140 tests unaffected. |
| T004 | FR-023 | pass | Marker-based single-recommendation resolution; passes with contextual rejected-option mentions, still fails on genuine multi-recommendation. |
| T005 | FR-002, FR-003, FR-021 | pass | Callable pre-plan validator + generated coordinator enforcement; classified honestly above; at-sync backstop intact. |
| T006 | FR-004, FR-005 | pass | Typed packet renders from typed fields and validates (sections, file:/// refs, verdict shape). |
| T007 | FR-006, FR-007, FR-020 | pass | Durable 155-lite packet scoped to `specs/<feature>/gates/`; selected option exposed for plan input; no generalization. |
| T009 | SC-001, SC-004, SC-014 | pass | Unit suite covers scaffold, packet, and validator-robustness positive/negative. |
| T010 | FR-002, FR-003, SC-012 | pass | Integration suite covers pre-plan block/pass and compatibility skip. |
| T011 | TG-006, SC-011 | pass | Contract refreshed with as-built names; new template added to Specrew.psd1 FileList; excluded surfaces untouched. |

## Behavior Classification

| Dimension | Verdict | Evidence |
| --- | --- | --- |
| Implemented | pass | Scaffold, pre-plan validator, typed packet path, and validator robustness added by extending `scripts/internal/design-analysis-gate.ps1`; template added and declared in `Specrew.psd1`. |
| Enforced | pass | Pre-plan validator fails closed; coordinator-prompt guidance instructs the pre-plan call; at-sync plan-boundary gate is the backstop. Cooperative + backstop, not mechanical interception (see FR-021 classification). |
| Observable | pass | Blocking errors name the missing artifact/section; tests and `mechanical-findings.json` provide review evidence; `gates/` packet is a durable record. |
| Documented | pass | Spec clarifications, plan, contract (as-built surface), quickstart, and start-prompt guidance describe the behavior and the cooperative-enforcement model. |

## Regression Review (shared Feature 140 helper)

- Iteration 1 necessarily extended `scripts/internal/design-analysis-gate.ps1` (Feature 140 runtime). Regression risk was reviewed: the FR-022/FR-023 changes broaden acceptance only (tolerant By-the-book matching; marker-first recommendation with legacy whole-text fallback). Feature 140 unit and integration suites both still pass, and the Feature 140 design-analysis.md / 141 design-analysis.md both still validate. No behavior change for existing valid artifacts.

## Drift Review

- Verdict: PASS.
- Evidence: Delivered scaffold, pre-plan validator, typed packet, validator robustness, tests, and docs match FR-001–FR-008, FR-020/FR-021, FR-022/FR-023, and SC-001–SC-005/SC-011–SC-014. FR-009/FR-010 (lens) are deferred-within-feature with recorded human approval; FR-011–FR-015 are later-iteration scope.
- Drift log update: no new drift event required.

## Gap Ledger

- No requirement (FR/SC) gaps for the Iteration 1 scope: all in-scope requirements verified: fixed-now.

## Proposal 145 Compliance Addendum

### 1. Seven review phases (all run)

| # | Phase | Verdict | Basis |
| --- | --- | --- | --- |
| 1 | Context load | pass | Clarified spec, Option B decision, plan, and the FR-021 review-emphasis points loaded. |
| 2 | Branch hygiene | pass | All work committed (`32ed8383`→`b8cc5685`); only unrelated runtime/agent churn uncommitted. |
| 3 | Functional correctness | pass | Scaffold, pre-plan block/pass, packet render/validate/persist, selected-option, validator robustness all behave per spec. |
| 4 | NFR / security | pass | No auth/secrets/network/eval; durable packet scoped to the gate; no Proposal 105 hooks. |
| 5 | Code quality | pass | Isolated functions; reuses the validation core; Feature 140 helper extended, not rewritten. |
| 6 | Test coverage + integrity | pass | New unit + integration suites assert runtime behavior with negative cases; not file-presence. |
| 7 | System safety + ops | pass | At-sync plan-boundary backstop intact; boundary-sync atomicity preserved; validator clean. |

No phase was N/A; all seven ran.

### 2. FR × phase coverage

| Requirement | Verifying phase(s) |
| --- | --- |
| FR-001 (scaffold) | 3 Functional, 6 Test |
| FR-002 / FR-003 (block before plan) | 3 Functional, 6 Test, 7 System safety |
| FR-004 / FR-005 (typed packet) | 3 Functional, 6 Test |
| FR-006 (packet scope) | 4 NFR, 5 Code quality |
| FR-007 (selected-option continuity) | 3 Functional, 6 Test |
| FR-008 (extend not rewrite) | 5 Code quality, regression check |
| FR-020 (durable packet scoped) | 3 Functional, 4 NFR |
| FR-021 (enforcement) | 3 Functional, 7 System safety (see §3) |
| FR-022 / FR-023 (validator robustness) | 3 Functional, 6 Test, regression check |
| FR-016 / FR-017 / FR-018 / FR-019 (sequencing/scope/governance) | 2 Branch hygiene, 7 System safety |

Every in-scope FR maps to at least one phase.

### 3. FR-021 honest classification

Implemented/enforced by **cooperative coordinator instruction** (`scripts/specrew-start.ps1` generated guidance) **plus a callable pre-plan validator** (`Invoke-SpecrewDesignAnalysisPrePlanGate`), **backed by the at-sync plan-boundary hard gate** (`Invoke-SpecrewDesignAnalysisPlanBoundaryGate` in `sync-boundary-state.ps1`). It is **NOT** a host-native mechanical write-block and **NOT** Proposal 105 hook enforcement; a non-cooperating process could still write `plan.md` bytes. No review claim asserts mechanical write-prevention.

### 4. Feature 140 shared-helper regression

`scripts/internal/design-analysis-gate.ps1` (Feature 140 runtime) was extended. Regression checked: Feature 140 unit + integration suites re-run at `b8cc5685` — pass. FR-022/FR-023 broaden acceptance only; existing valid artifacts are unaffected.

### 5. Evidence integrity

- No review claim relies on uncommitted or working-tree-only evidence. All implementation (`32ed8383`, `f4172cb4`, `2926dea0`, `74aba427`) and review artifacts (`e3951c35`, `9bb5f13b`, `b8cc5685`) are committed; the only uncommitted working-tree files are unrelated runtime/agent churn, not feature evidence.
- Tests and mechanical checks cited in this review were **re-run at commit `eedf1604`** (the smoke-fix commit): Feature 140 unit + integration, Feature 141 unit + integration all pass; `mechanical-findings.json` is empty. The smoke-driven runtime fixes (enforced packet, pre-plan packet requirement, decision-commit integrity, design-principle template, plus the 141 dogfood packet and updated tests) are committed at `eedf1604`; no review claim relies on uncommitted evidence.
