# Review: Iteration 011

**Schema**: v1
**Reviewed**: 2026-06-05
**Review method**: Proposal 145 (7-phase structured review + claim-ledger + report-falsification). 145 is a candidate (not validator-enforced), followed here as the review *method*.
**Overall Verdict**: accepted for review-signoff — the in-scope **deterministic** Amendment-A7 work is delivered and unit-green; the **behavioral** acceptance (SC-027) and the corrected render (Amendment A8 / SC-028) are **human-approved deferrals to iteration 012** (maintainer-directed; see Phase 7 + Gap Ledger).

## Summary

Iteration 11 delivers Amendment A7's **confirmation-integrity floor + intake UX** — the fix for the testLenses7codex Squad blocker (the workshop recorded seven "Human agreed" lens decisions after ~three human questions) — as deterministic, unit-green work:

- **T001 (FR-039/SC-026)** — the per-lens `confirmation` provenance floor in `Test-SpecrewLensWorkshopRecords`, grandfather-gated by `confirmation_required`, with a wiring test that proves the floor FAILS through the real `Invoke-SpecrewSpecifyBoundaryLensGate` entry (`dbea2fc6`).
- **T002 (FR-038)** — the integrity invariant + count self-check + the one delegate/skip exception in the design-workshop skill (`c9538016`).
- **T003 (FR-038, the root-cause lever)** — the `squad.agent.md` stopping-completeness rule, authored into the coordinator-governance **template** so it deploys downstream (`c9538016`).
- **T004 (FR-040)** — the intake UX (prep announcement + agenda assignment + per-lens progress) + the Rule 9a pointer (`c9538016`).
- **T005** — the tests: the SC-026 floor cases + presence-locks; `lens-conduct-delivery`, `skill-templates`, `design-analysis-gate`, `design-gate-runtime-hardening` all green.

The honest counterweight, and the thing this review refuses to over-claim: **i11's behavioral acceptance is its consolidated cross-host re-dogfood (T006 / SC-027), and that gate is not met.** It is the i6/i10 pattern again — the dogfood surfacing the gap that was its purpose. The render half (T007, FR-037/FR-040 in-band surfacing, folded into i11 as conduct) was proven insufficient on Claude across **testLenses8 + testLenses11**: render-before-the-menu CONDUCT (a Big-Picture rule + fill-in templates) is defeated by the **`AskUserQuestion` tool-gravity** — the agent puts the thing-being-confirmed *into* the call's question/option fields instead of rendering it first (component map "approve 13 components" and lens agenda "8 lenses shown" both confirmed-by-reference, never rendered). It holds on Copilot + Antigravity (they render in prose first), so in-band surfacing is **host-dependent**. That finding is recorded as **Amendment A8** (FR-041 — non-discretionary presentation) and routed to **iteration 012**; the ~6-SP mechanical render does not fit i11's full 20 (the capacity validator forbids the fold). The A7 behavioral confirmation (SC-027) and the render confirmation (SC-028) **consolidate into i12's single cross-host re-dogfood** — one run confirms both, and a meaningful render run needs the mechanical fix in place first.

## Phase 0 — Context load

Loaded: spec A7 (FR-038/039/040, SC-026/SC-027) + the new A8 (FR-041, SC-028); [plan.md](plan.md) (Option B, decision `3ea67b32`); [design-analysis.md](design-analysis.md); [tasks-progress.yml](tasks-progress.yml); the i11 diff (`dbea2fc6`, `c9538016`, `b8017f07`, `b23f9cd2`→`0d4b926a`); the testLenses8 + testLenses11 dogfood transcripts (the empirical evidence for the render-ceiling finding). **Verdict: pass.**

## Phase 1 — Branch hygiene

- Branch `141-design-gate-runtime-hardening`; i11 chain `67a808d7` (plan) → `dbea2fc6` (T001) → `c9538016` (T002–T005) → `b8017f07` (plan pipe-break + hardening-gate fix) → `b23f9cd2` / `ab1f4774` / `142eeb61` / `0d4b926a` (T007 render conduct + templates) → `2926cdc0` (Amendment A8 spec).
- **No upstream / local-only is INTENTIONAL** (the standing "no push/PR while 141 in progress" constraint) — not a Shape-4 gap.
- Shape-5 audit: every file cited as delivered is committed at HEAD; working tree carries only `.squad`/`.specrew` session bookkeeping + the main-bound `proposals/145` (unstaged, not on this feature's delivery). **Verdict: pass.**

## Phase 2 — Functional correctness

- **The deterministic floor (T001):** `Test-SpecrewLensWorkshopRecords` requires each selected lens to carry a `confirmation` ∈ {`human-confirmed` | `human-delegated` | `human-skipped`} when `confirmation_required: true`; grandfather-safe (pre-A7 artifacts no-op); the wiring test proves it FAILS through the real gate entry for a missing/invalid value. Deterministic, LLM/network-free.
- **The conduct (T002–T004):** the integrity invariant + count self-check + delegate/skip exception (skill step 6), the intake UX (skill step 1/3 + Rule 9a), and the **`squad.agent.md` stopping rule** in the governance template — the root-cause lever against the Squad coordinator's early-stop persona.
- **Design → behavior conformance:** the deterministic half conforms; the **behavioral** half (does the agent actually ask before recording, and render before the menu?) is T006's dogfood — and that is where the render conduct **did not** conform on Claude. Recorded, not hidden. **Verdict: pass for the deterministic scope; behavioral conformance deferred to i12.**

## Phase 3 — Non-functional requirements

- Determinism / no-LLM-no-network: the floor + conduct are inert markdown + a deterministic PowerShell check; `index.yml` untouched; grandfather-safe; the deferred Proposal 156 scope stays out. **Verdict: pass.**

## Phase 4 — Code quality

- Lint / parse: PowerShell AST-clean (`design-analysis-gate.ps1`, `specrew-start.ps1`, the tests); markdown well-formed. No new dependencies. No anti-patterns (no sleep-as-sync, no hidden global state, no test-only production behavior). **Verdict: pass.**

## Phase 5 — Test coverage + integrity

- The SC-026 floor has positive / missing / invalid / delegate+skip / grandfather-no-op cases + the wiring case through `Invoke-SpecrewSpecifyBoundaryLensGate` (T001). The FR-038/039/040 conduct + the `squad.agent.md` rule are **presence-locked** in `lens-conduct-delivery`. The render conduct (T007) is presence-locked too — but **presence ≠ obedience**, and the dogfood proved the agent does not obey it on Claude. That is the gap-completeness (Shape 8) lesson restated: a presence-lock guards the text, not the behavior; the behavior is the dogfood.
- **Evidence replay (run at THIS review):** `lens-conduct-delivery`, `skill-templates`, `design-analysis-gate`, `design-gate-runtime-hardening` re-run green at review time (not inherited). **Verdict: pass for the deterministic floor + presence-locks; behavioral coverage is the deferred dogfood.**

## Phase 6 — System safety + ops

- Backward compatibility: the floor is marker-gated + grandfather-safe (pre-A7 artifacts no-op); the governance-template rule deploys via the existing `Set-ManagedBlock` seam; the skill edits are in place (deploy unchanged). No release/publish/push while 141 is in progress. **Verdict: pass.**

## Claim-to-Evidence Ledger

| Claim | Evidence |
| --- | --- |
| A7 deterministic floor delivered | `dbea2fc6` — `Test-SpecrewLensWorkshopRecords` SC-026 extension + 5 unit cases + wiring case; re-run green this review |
| A7 conduct + the root-cause lever delivered | `c9538016` — skill step 6 integrity + intake UX + the `squad.agent.md` stopping rule in `specrew-governance.md`; presence-locked |
| Render-before-the-menu CONDUCT is insufficient on Claude | testLenses8 (component map by count) + testLenses11 (lens agenda by count) — confirmed-by-reference, never rendered, on the latest deployed skill (byte-verified current). Root cause: the AskUserQuestion tool-gravity (advisor-confirmed) |
| SC-027 (A7 behavioral, Squad) | **NOT met — deferred to i12.** No post-fix Squad re-dogfood has run; it consolidates into i12's cross-host run |
| SC-028 (render, cross-host) | **NOT met — deferred to i12.** The render must be mechanical (A8/FR-041) before a meaningful run; i12 builds it, then the consolidated re-dogfood confirms |

## Phase 7 — Report falsification

- **Refused to bank the behavioral acceptance.** The natural over-claim is "the A7 floor + conduct shipped and the unit tests pass, so i11 is done." It is not — i11's *purpose* is behavioral (stop the synthetic agreement on Squad; render before the menu on Claude), and neither is confirmed. The deterministic floor is delivered; the behavioral gate is explicitly **deferred**, not claimed.
- **The render half is reported as a FAILURE, not a partial win.** T007's conduct is committed and presence-locked, but the dogfood falsified it on Claude. Recording it as "delivered" would be the exact form-without-runtime-compliance Shape this feature keeps catching. It is recorded as the finding that motivates A8.
- **No claim stronger than its evidence:** the deterministic claims rest on re-run suites; the behavioral claims are downgraded to deferred.

## Gap Ledger

- **A7 deterministic floor + conduct + the `squad.agent.md` rule — DELIVERED + green (fixed-now).**
- **SC-027 (A7 no-synthetic-agreement on Squad) — DEFERRED to iteration 012** (human-approved; see `.squad\decisions.md` decision `defer-141-i011-behavioral-to-i012-a8`): consolidates into i12's single cross-host re-dogfood.
- **SC-028 (confirm-point content rendered before its menu, cross-host) — DEFERRED to iteration 012** (human-approved; see `.squad\decisions.md` decision `defer-141-i011-behavioral-to-i012-a8`): requires the A8/FR-041 mechanical render, which i12 builds.
- **FR-041 / the conduct-render ceiling (Amendment A8) — DEFERRED to iteration 012** (human-approved; see `.squad\decisions.md` decision `defer-141-i011-behavioral-to-i012-a8`): the non-discretionary presentation mechanism is built in iteration 012.

## Per-Phase Verdict + Overall

per_phase: { p0: pass, p1: pass, p2: pass (deterministic), p3: pass, p4: pass, p5: pass (deterministic + presence), p6: pass }. The deterministic A7 floor + conduct + the root-cause `squad.agent.md` lever are delivered and unit-green; the behavioral acceptance (SC-027) and the corrected render (A8/SC-028) are human-approved deferrals to iteration 012's consolidated cross-host re-dogfood. **Overall: ACCEPTED for review-signoff (with SC-027 + SC-028 deferred to i12).**

## Task Verdicts

| Task | Requirement | Verdict | Notes |
| ---- | ----------- | ------- | ----- |
| T001 | FR-039 / SC-026 | pass | Provenance floor + wiring test; re-run green. |
| T002 | FR-038 | pass | Integrity invariant + count self-check + delegate/skip exception in the skill. |
| T003 | FR-038 | pass | The `squad.agent.md` stopping-completeness rule (root-cause lever) in the governance template. |
| T004 | FR-040 | pass | Intake UX (prep + agenda + per-lens progress) + Rule 9a pointer. |
| T005 | SC-026 | pass | Floor cases + presence-locks; four suites green at review. |
| T006 | SC-027 | pass | The consolidated dogfood EXECUTED its gate-completeness job (testLenses8/11) and surfaced the conduct-render ceiling — the i9/i10 "dogfood finds the gap" pattern. "Pass" = the dogfood ran + produced the finding, NOT that the workshop render or SC-027 passed; those confirmations are DEFERRED to i12 (Gap Ledger). |
| T007 | FR-037 | pass | The render conduct was delivered + presence-locked as scoped (`b23f9cd2`→`0d4b926a`). Its BEHAVIORAL insufficiency on Claude is a requirement-level finding (DRIFT-001 → FR-041/SC-028), carried in the Gap Ledger, not a task-execution failure. |

## Notes

- Hardening-gate concerns at this signoff: see [quality/hardening-gate.md](quality/hardening-gate.md).
- Iteration 11 closes on its delivered + tested **deterministic** scope (the A7 floor + conduct + the root-cause lever) plus the dogfood-surfaced render-ceiling finding that motivates Amendment A8. The behavioral acceptance moves to i12's consolidated cross-host re-dogfood — the i6/i10 pattern: the dogfood's job is to find the gap, and it did.
