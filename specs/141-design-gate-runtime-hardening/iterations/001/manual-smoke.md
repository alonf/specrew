# Manual Smoke Evidence: Iteration 001

**Schema**: v1
**Date**: 2026-06-02
**Smoke repo**: `C:\Temp\SpecrewTrials\test1234`
**Feature tested**: `specs/001-azure-bicep-upgrade-scanner`
**Runtime under test**: Feature 141 Iteration 1 design-gate runtime
**Recorded by**: Crew (coordinator), from the maintainer's external manual smoke

## Verified smoke-repo facts

- `specs/001-azure-bicep-upgrade-scanner/gates/` — **does not exist** (no durable design-gate packet).
- `design-analysis.md` Human Decision recorded `Decided at commit: a30fed5`.
- `git log --oneline` confirms the decision sequence: `a30fed5` design-analysis draft → `2c1956a` option approval → `c66b043` plan → `dd42f6b` tasks. The approval commit is `2c1956a`, not `a30fed5`.

## Observation results

| # | Observation | Result | Disposition |
| --- | --- | --- | --- |
| 1 | `specrew start --host codex` showed clean artifact paths (no `specs//...`) | PASS | FR-011 (Iteration 2) already behaves; no action this iteration |
| 2 | `design-analysis.md` created before `plan.md` | PASS | FR-001 working |
| 3 | Crew stopped for a design-option decision before `plan.md` | PASS | FR-002/FR-003 cooperative stop working |
| 4 | Selecting `1` interpreted as `approved for plan with Option B` | PASS | verdict-shape mapping working |
| 5 | `plan.md` written after the option decision, not before | PASS | sequencing working |
| 6 | Durable gate packet under `specs/<feature>/gates/` | FAIL | **code change** — packet persistence was an unused helper; wire into enforced flow (Fix 1) |
| 7 | Explicit `Invoke-SpecrewDesignAnalysisPrePlanGate` before `plan.md` | FAIL / not proven | **code change** — make pre-plan validator mandatory + exercised (Fix 2) |
| 8 | `Decided at commit` matches the option-approval commit | FAIL | **code change** — recorded draft commit `a30fed5` instead of approval `2c1956a`; fix metadata model (Fix 3) |
| 9 | Proposal 156 lenses activated (security/DevOps/data/CLI/architecture questions) | UX GAP | **deferred-within-feature** — FR-009/FR-010 pre-deferred; recorded as a later-iteration obligation, not vague future work |
| 10 | Handoff explained design principles deeply (ports/adapters, dependency isolation, report-contract stability, reversibility, plugin overbuild) | UX GAP | **code change** — add per-option "Design principle / why this matters" to template + handoff (Fix 4) |

## Findings requiring code changes (this iteration)

1. **Packet not in the real flow (obs 6).** `Save-SpecrewDesignAnalysisGatePacket` existed but the coordinator flow never rendered/validated/persisted a packet, so no `gates/` artifact appeared. Fix: the pre-plan validator now requires a valid durable packet, and the generated start guidance mandates render → validate → persist → pre-plan-call before `plan.md`.
2. **Pre-plan validator not exercised (obs 7).** Fix: generated guidance explicitly names `Invoke-SpecrewDesignAnalysisPrePlanGate` as a mandatory step before authoring `plan.md`; the at-sync plan-boundary gate remains the artifact/decision backstop.
3. **Decision-commit metadata drift (obs 8).** Fix: clearer Human Decision model — `Decision verdict`, `Decision recorded in commit` (the commit that contains the populated decision), and an optional `Design-analysis draft commit`; validator rejects recording the draft commit as the decision commit.
4. **Shallow handoff (obs 10).** Fix: template adds a per-option "Design principle / why this matters" field (dependency isolation, ports/adapters/layering, report-contract stability, reversibility, simplest-is-cheaper-but-coupled, by-the-book-overbuild).

## Findings deferred-within-feature (correct scope)

- **Lens activation (obs 9).** FR-009/FR-010 (Proposal 156 Applicable Lenses) were pre-deferred from Iteration 1 (recorded human approval, 2026-06-02). Lens activation did **not** happen in this smoke, which is **expected for Iteration 1 only because lenses were deferred**. Feature 141 keeps lens activation (focused security/DevOps/data/CLI/architecture questions in design-analysis) as a **named later-iteration obligation**, not vague future work. This is not an Iteration 1 in-scope failure.

## Outcome

Sent back to implementation; runtime gaps (Fixes 1–4) implemented and review redone. No in-scope Iteration 1 requirement is left falsely claimed; the lens UX gap is correctly scoped as deferred-within-feature.
