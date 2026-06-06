# Review: Iteration 012

**Schema**: v1
**Reviewed**: 2026-06-06
**Review method**: Proposal 145 (7-phase structured review + claim-ledger + design-trace + report-falsification). 145 is a candidate (not validator-enforced), followed here as the review *method*.
**Overall Verdict**: accepted for review-signoff — the behavioral acceptance (SC-028 + SC-027) is **met** by the cross-host dogfood (testLenses11 Copilot/Squad + Claude); the catalog-at-open hypothesis was dogfood-reverted; the agenda skim is the maintainer-dispositioned accept-as-minor.

## Summary

Iteration 12 delivers Amendment A8 / FR-041 — the corrected implementation of FR-037/FR-040 after i11's dogfood proved render-before-the-menu **conduct** insufficient on Claude (the `AskUserQuestion` tool-gravity). The **cross-host dogfood** (testLenses11 on Copilot/Squad AND Claude) is the behavioral gate, and it **confirmed the convergence** — the maintainer's verdict: *"on both copilot and claude this is the best workshop."*

**What holds (the win):**

- **Open-question-first (FR-041b)** — every lens opened with a rendered presentation + an open question, never a menu-first, on **both** hosts. This is the per-lens render that failed for six straight edits on Claude; it now holds cross-host. The **component map rendered in-band on Claude** (lens 2, the 15-component layered map, as prose + an open question) — the advisor's *"real test"* — passed, because a per-lens open has no competing menu.
- **Cross-host mandatory pacing (FR-041b)** — both hosts offered "all at once or one at a time" and walked the decisions one-by-one. The testLenses11 Copilot wall (five subjects bundled into one open question) is fixed.
- **SC-027 (no synthetic agreement on Squad)** — Copilot worked all 9 lenses against the human's real answers and wrote the per-lens records; the testLenses7codex failure (synthetic agreements for un-asked lenses) did **not** recur.

**What was reverted (the empirical answer):**

- **Catalog-at-open (FR-041a)** — built (`0ed7cde7`), cross-host dogfood-tested, and **reverted** (`f5b01714`): redundant on prose hosts (Copilot rendered the catalog AND the agenda = the nine lenses twice) and skimmed on Claude (a before-a-menu render). It helped no host. The deliverable is the **empirical answer + the governing model**, not a catalog.

**The honest edge (a decision, not a defect):** on Claude the agenda-confirm menu still references "above" with the list inside the question (a before-a-menu render). The maintainer dispositioned it — *accept-as-minor ("we can ignore it")*. This is the governing-model edge case, documented; the reliable fix (a `PreToolUse` hook) is an optional future iteration, never another instruction.

## Phase 0 — Context load

Loaded: spec A8 (FR-041, SC-028) + the refined/converged versions; [plan.md](plan.md), [design-analysis.md](design-analysis.md); the **testLenses11 Copilot + Claude transcripts** (the behavioral evidence — full 9-lens workshops on both hosts); the i12 diff (`0ed7cde7` → `a16daadd` → `f5b01714` + the spec/test edits). **Verdict: pass.**

## Phase 1 — Branch hygiene

- Branch `141-design-gate-runtime-hardening`; i12 chain `0ed7cde7` (catalog-at-open + open-question-first) → `a16daadd` (pacing + round-1 record) → `f5b01714` (catalog revert + pacing mandatory cross-host) + the spec refinements (`26ef631e`, and the convergence spec edits in `f5b01714`).
- **No upstream / local-only is INTENTIONAL** (the "no push/PR while 141 in progress" constraint).
- Shape-5 audit: every cited file is committed at HEAD; working tree carries only `.squad`/`.specrew` session bookkeeping + the main-bound `proposals/145`. **Verdict: pass.**

## Phase 2 — Functional correctness

- **The conduct delivered (T002):** skill step 3 opens each lens with a presentation + an open question (never a menu first — the binary lever); the dense-lens pacing offer is mandatory cross-host; the Big-Picture A8 note carries the governing model.
- **The catalog reverted (T001):** skill step 1 back to framing + agenda-assignment; no host-branching (advisor: drop > conditional).
- **Design → behaviour conformance:** the cross-host dogfood **conforms** — both hosts ran all 9 lenses with rendered presentations + open questions + pacing; the component map rendered in-band on Claude. The behavioral case i11 could not pass now passes cross-host. **Verdict: pass.**

## Phase 3 — Non-functional requirements

- Determinism / no-LLM-no-network: the skill + lens md are inert markdown; `index.yml` untouched (the catalog reuse was reverted with the catalog); deploy unchanged. **Verdict: pass.**

## Phase 4 — Code quality

- Lint / parse: markdown well-formed; PowerShell test AST-clean. No new dependencies. No anti-patterns. The test updates removed the catalog presence-locks and added the open-question-first + governing-model + cross-host-pacing locks. **Verdict: pass.**

## Phase 5 — Test coverage + integrity

- Presence-locks: open-question-first (`never a menu first`, the binary test), pacing (`pacing choice`, `one at a time`, `not optional on a dense lens`), and the `governing model`. **Crucially, unlike i11 the dogfood CONFIRMED obedience cross-host** — presence and behavior agree this time (the per-lens render held on both hosts).
- **Evidence replay (run at THIS review):** `lens-conduct-delivery` + `skill-templates` re-run green. **Verdict: pass.**

## Phase 6 — System safety + ops

- Deploy unchanged (the skill is edited in place; auto-discovery); grandfather-safe; no release/publish/push while 141 is in progress. **Verdict: pass.**

## Claim-to-Evidence Ledger

| Claim | Evidence |
| --- | --- |
| Open-question-first holds cross-host | testLenses11 Copilot + Claude: every lens opened with a presentation + an open question, no menu-first; the component map rendered in-band on Claude (lens 2) |
| Pacing works cross-host | both hosts offered all-at-once/one-at-a-time and walked decisions one-by-one (the Copilot wall is fixed) |
| SC-027 (no synthetic agreement on Squad) | Copilot ran all 9 lenses against real answers + wrote the per-lens records; testLenses7codex failure did not recur |
| Catalog-at-open reverted for the right reason | `f5b01714`; redundant on prose (Copilot rendered catalog+agenda) + skimmed on Claude (before-a-menu) |
| The agenda skim is dispositioned, not a defect | maintainer: "we can ignore it" — accept-as-minor; the governing model documents the hook as the optional reliable fix |

## Design → Code → Test Trace

| Design (A8/FR-041) | Implementation | Evidence | Status |
| --- | --- | --- | --- |
| Open-question-first per lens | skill step 3 (never a menu first) | dogfood (cross-host) + presence-locks | matched (confirmed) |
| Mandatory cross-host pacing | skill step 3 (dense-lens pacing) | dogfood (both hosts) + presence-locks | matched (confirmed) |
| Catalog-at-open | reverted (skill step 1) | dogfood (redundant/skim) → revert | reverted (empirical) |
| Governing model | FR-041 + skill Big Picture | presence-lock (`governing model`) | matched |

## Phase 7 — Report falsification

- **Did not over-claim the agenda.** The agenda still skims on Claude; this review records it as the maintainer's accept-as-minor decision, NOT "fixed." Calling it fixed would be the form-without-runtime-compliance Shape this feature keeps catching.
- **The design-analysis-stop component map is a WATCH item, not a claim.** The run reached the *specify* boundary; the design-analysis stop (a later boundary) was not reached. Its co-design map is the other before-a-menu render — same accept-as-minor or the hook if/when the maintainer reaches it. Recorded as a carry, not asserted.
- **The component-map render IS proven at the component-design lens** (lens 2) — the in-band render is in the transcript, not inferred from a floor.
- **No claim stronger than the dogfood evidence:** the cross-host acceptance rests on the maintainer's "best workshop" verdict + the two transcripts.

## Per-Phase Verdict + Overall

per_phase: { p0: pass, p1: pass, p2: pass, p3: pass, p4: pass, p5: pass, p6: pass }. Open-question-first + mandatory cross-host pacing are delivered and **dogfood-confirmed cross-host**; the catalog-at-open hypothesis was correctly reverted; the agenda skim is the maintainer-accepted minor. **Overall: ACCEPTED for review-signoff.**

## Task Verdicts

| Task | Requirement | Verdict | Notes |
| ---- | ----------- | ------- | ----- |
| T001 | FR-041a | pass | Catalog-at-open built, cross-host dogfood-tested, and correctly **reverted** (redundant on prose, skims on Claude). The empirical answer + the governing model are the deliverable, not a catalog. |
| T002 | FR-041b | pass | Open-question-first + mandatory cross-host pacing; **confirmed working on both hosts** (the per-lens render held; pacing walked decision-by-decision). |
| T003 | SC-028 | pass | Presence-locks updated (catalog locks removed; open-question-first + governing-model + cross-host-pacing locks added); `lens-conduct-delivery` + `skill-templates` green. |
| T004 | SC-028 / SC-027 | pass | The cross-host dogfood — both hosts "best workshop"; the component map rendered in-band on Claude; no synthetic agreement on Squad (SC-027 met). |

## Gap Ledger

- **Open-question-first + mandatory cross-host pacing — DELIVERED + dogfood-confirmed (fixed-now).**
- **Catalog-at-open — REVERTED (fixed-now);** the governing model (open-discussion renders hold on Claude; before-a-menu renders skim → hook or host-variance) is the durable lesson, baked into FR-041 + the skill.
- **The presence-lock → behavior gap is closed for this conduct (fixed-now):** i11's lesson was presence ≠ obedience; i12's dogfood confirmed obedience cross-host, so presence and behavior now agree for open-question-first + pacing.

## Notes

- **The agenda skim (Claude, before-a-menu render) is a maintainer DECISION, not a gap:** accept-as-minor ("we can ignore it"). The reliable fix (a `PreToolUse` hook) is an optional future iteration; recorded in `.squad\decisions.md`.
- **The design-analysis-stop component map is a WATCH/carry:** a later boundary not reached this run; the same accept-as-minor or the hook applies.
- Iteration 12 closes on the **cross-host behavioral acceptance** — the workshop is "the best" on both hosts. The six-edit grind + the convergence won. Feature 141 is ready for feature-closeout.
