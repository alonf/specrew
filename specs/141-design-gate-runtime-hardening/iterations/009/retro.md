# Retrospective: Iteration 009

**Schema**: v1
**Date**: 2026-06-05

## Estimation Accuracy

| Task | Estimated | Actual | Delta |
| ---- | --------- | ------ | ----- |
| T001 | 4 | 4 | 0 |
| T002 | 2 | 2 | 0 |
| T003 | 2 | 2 | 0 |
| T004 | 4 | 4 | 0 |
| T005 | 4 | 4 | 0 |
| T006 | 2 | 2 | 0 |

**Average variance**: 0 on planned tasks (18/18). Unplanned rework ~4 SP: the wiring integration test (advisor-forced, the i7 lesson) + the testLenses5 A/C/D fixes (ASCII-inline, named-components, ui-ux capture floor).

## Phase Variance

| Phase | Estimated | Actual | Delta | Notes |
| ----- | --------- | ------ | ----- | ----- |
| Planning | 1 | 1 | 0 | Design-analysis (Option B). |
| Implementation | 12 | 12 | 0 | Conduct 9a/9b/9c + design-method point + the co-design floor. |
| Review | 6 | 6 | 0 | Floor tests + the SC-024 dogfood. |
| Rework | 0 | ~4 | +4 | Unplanned: the wiring integration test + the testLenses5 A/C/D fixes. |

## Drift Summary

- Total drift events: 1 (SC-024 in-band-surfacing unreliable — the conduct is correct but its DELIVERY, a one-shot mega-prompt, dilutes it).
- Resolution: **deferred to iteration 010** (the delivery relocation), maintainer-dispositioned; canonical defer entry in `.squad\decisions.md`. See [drift-log.md](drift-log.md).

## What Went Well

- **The deterministic floor + the wiring integration test held.** SC-025 is marker-gated, grandfather-safe, proven to fire through the real gate entry point (the i7 lesson, applied before the dogfood), and extended for the ui-ux capture (D) — all green.
- **The dogfood + the Codex contrast nailed the real content bug.** Running both hosts was decisive: Codex rendered ASCII inline when asked, Claude wrote HTML — that contrast proved a fenced mermaid block is source text, not a picture, on a terminal. Three rounds of "MUST surface in-band" missed it because they treated mermaid and ASCII as equivalent. The empirical A/B (Claude vs Codex) found what reasoning hadn't.
- **Report-falsification (Proposal 145) worked a third time.** The "surfacing met" claim was downgraded to "carried" against the transcript, not asserted from the green floor.

## What Didn't Go Well (the load-bearing lesson)

- **Behavioral conduct buried in a one-shot ~50-rule launch prompt has a reliability ceiling — and we hit it across FIVE dogfoods and five "looks-right" conduct edits.** The agent skims the rules; by the time it reaches a lens 20 minutes in, "name the components", "surface in-band", "co-design before options" fire inconsistently. The defect was never the rule wording — it was that *too many rules in one shot dilute attention*. Escalating the wording (MAY → MUST → MUST-in-band) was the wrong lever; the right lever is **delivery** — focused, point-of-use context (a re-invokable skill + on-demand per-lens md whose name/description stays in the system prompt), which iteration 010 builds.
- **The miss was process, not estimation:** we built the conduct in the mega-prompt three times (i6/i7/i8/i9 escalations) before recognising the delivery cause.

## Improvement Actions

1. Owner: Spec Steward/Reviewer | Phase: design/before-implement | Type: process | Expected effect: **for any behavioral/prompt capability, run a 1-run PoC up front** to check whether the agent actually obeys the conduct at the intended point — BEFORE building the full iteration. A short PoC would have surfaced "the agent skims rules when there are too many in one prompt" before three build iterations of escalating wording. (The maintainer's explicit retro framing.)
2. Owner: Implementer/Spec Steward | Phase: design | Type: delivery-architecture | Expected effect: prefer **point-of-use delivery** (a re-invokable skill + on-demand per-lens md, name/description persistently in the system prompt) over adding rules to the one-shot launch prompt for per-lens conduct. Mega-prompt rules are read once and skimmed; on-demand units are loaded when relevant. Landed as iteration 010.
3. Owner: Reviewer | Phase: review | Type: content | Expected effect: on terminal/console hosts, a fenced mermaid block is source text, not a rendered picture — ASCII is the inline form that visually lands; mermaid/svg/html must be a written file with the link surfaced in-chat. Carry this into any visual-surfacing conduct.

## Calibration Suggestion

- Planned tasks held at 0 variance; the signal is the +4 unplanned rework (wiring test + the testLenses5 fixes) and the process miss (delivery-cause found late). No estimate-model change; the lesson is the PoC-up-front rule (action 1).

## Notes

- Iteration 9 closes on its delivered + tested scope (the co-design conduct + the SC-025 floor + the A/C/D fixes). The review followed Proposal 145.
- Forward (iteration 010): the lens-conduct delivery relocation (skill + on-demand per-lens md + trimmed prompt + workshop folder), web-confirmed viable (skills re-invoke on-demand). The SC-024 in-band-surfacing pass re-confirms in the i10 dogfood. B (verdict-menu collapse) is the parked Rule-46 track; the sub-agent-per-skill model is a post-141 evolution. See [review.md](review.md) Follow-ups.
