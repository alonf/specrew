# Retrospective: Iteration 009

**Schema**: v1
**Date**: 2026-06-11

## Estimation Accuracy

| Task | Estimated | Actual | Delta |
| ---- | --------- | ------ | ----- |
| T001 | 3 | 3 | 0 |
| T002 | 2 | 2 | 0 |
| T003 | 3 | 3 | 0 |
| T004 | 2 | 2 | 0 |
| T005 | 2 | 2 | 0 |
| T006 | 1 | 1 | 0 |
| T007 | 3 | 3 | 0 |

**Average variance**: +/- 0 (16/20 SP). T007 was unplanned (a deferred fast-follow pulled in when the live
dogfood proved it load-bearing) — honestly re-baselined 13 -> 16, not silently absorbed. **Honest caveat:**
0 variance does NOT mean clean — the iteration delivered its mechanism but the dogfood reframed its value
(see What Didn't Go Well).

## Drift Summary

- Total drift events: 2 (logged in drift-log.md). **D-015** (delta-noise: the handover drowned in ~53
  Specrew-managed scaffolding paths, the real work capped out) RESOLVED in-iteration (T007). **D-016** (the
  ARCHITECTURE pivot: the FR-022 handover approach evolves from refresh-frequency to lean-pointer + resume
  reconciliation; carries the `from_host: host` fix + the PostToolUse dial-back) DEFERRED to iteration 010.
  Resolution rate 50% (1/2) — honestly, because D-016 is iteration 010's deliverable. (Separately, the codex
  hook deploy crash found mid-dogfood was fixed as a chore, `ec08752f`.)

## What Went Well

- **The hook-primary handover killed the iter-008 hollow finding.** The cross-host dogfood (codex / claude /
  copilot) confirmed non-hollow capture, real `from_host`, and `welcome-back` resume on re-entry — the core
  goal landed.
- **The live dogfood earned its keep — twice.** It proved PostToolUse mid-turn refresh works on Claude AND
  surfaced the two things that mattered: the delta-noise (fixed live, T007) and the resume-reconciliation gap.
  The fast feedback loop (hooks resolve the dev tree via `SPECREW_MODULE_PATH`) let T007 land + be re-verified
  in the same session.
- **The de-noise fix made the handover legible** — the bullet went from 53 identical scaffolding paths to the
  actual workshop lens files, so a resume can finally see *where you are*.

## What Didn't Go Well

- **HEADLINE — PostToolUse mid-turn refresh was the wrong lever, and the dogfood proved it.** The durable
  state is already on disk (workshop lens files, the tree), so refreshing the handover every tool call
  snapshots something cheaply re-derivable on resume — at a `git status`-per-tool-call cost. The build !=
  live discipline applied to the handover's OWN value: it refreshed perfectly and captured nothing of unique
  worth (it was noise until T007, and even de-noised it duplicates the live tree). The real, host-independent
  value is the RESUME reconciliation, which iteration 009 did not build (`SessionBootstrapManager` never
  re-computes the delta on SessionStart — it replays the snapshot). The lesson: optimise the RESUME read, not
  the write frequency.
- **The handover competes with the live tree instead of pointing to it.** A handover that re-stores "what
  changed" duplicates `git status`; its unique value is the NON-durable intent + a pointer. Iteration 009
  built it as a (potentially stale) source of truth, not a thin pointer.
- **Process: the dogfood drifted into ad-hoc fixing.** Two real fixes (T007 de-noise; the codex self-heal)
  were committed straight to the branch mid-dogfood without governed boundaries or committed tests — a
  governance miss caught by a `/specrew-refocus` re-ground, not by discipline holding in the moment.

## Improvement Actions

1. **Owner: Implementer | Phase: iter-10 design+implement | Type: architecture (the durable fix).** Build the
   LEAN resume reconciliation: SessionStart re-computes the cheap delta (one `git status`) + a directive
   ("last stop X; changed since [...]; read + continue from the real state"); the agent (already paying the
   context cost) does the reading. Re-cast the handover as grounding + pointer + non-durable intent.
2. **Owner: Implementer | Phase: iter-10 | Type: cost.** Dial PostToolUse back (off-by-default / throttled);
   write on Stop for grounding, reconcile cheaply on resume. Reclaim the per-tool-call `git status` cost.
3. **Owner: Implementer | Phase: iter-10 | Type: tracking.** Surface the workshop lens-progress (done / next)
   + the precise gate-stop state, read from `lens-applicability.json` + `workshop/`, so "which phase" is
   explicit, not inferred.
4. **Owner: Implementer | Phase: iter-10 | Type: carry + test-debt.** Fix `from_host: host` in the
   workshop-skill refresh (pass `--host-kind`); add committed regression tests for T007 de-noise and the
   codex array-shape self-heal (the tests deferred from the ad-hoc commits).
5. **Owner: Crew | Phase: process | Type: discipline.** Dogfood findings get governed AS THEY ARISE (a
   findings ledger / drift entry with an owner), not fixed ad-hoc and reconciled later. The refocus re-ground
   should not have been necessary.

## Calibration Suggestion

- Keep the 13-18 SP band; iteration 009 ran 16/20 at 0 variance.
- **Honest caveat (reinforced):** the 0-variance streak is a velocity signal, NOT a quality signal — it was
  blind to "we built the right mechanism for the wrong lever." Quality is carried by the iteration-010
  resume-reconciliation, not the variance number.

## Signals For Next Step (iteration 010, NOT feature-closeout)

- **Iteration 010 charter:** the lean resume reconciliation + tracking surfacing + PostToolUse dial-back +
  the `from_host` fix + the carried regression tests. F-174 stays OPEN until resume actively reconciles
  (cheap delta + pointer + the agent reads) regardless of host or refresh timing.
