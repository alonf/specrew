# Retrospective: Iteration 004

**Schema**: v1
**Date**: 2026-05-29

## Estimation Accuracy

| Task | Estimated | Actual | Delta |
| ---- | --------- | ------ | ----- |
| T001 | 0.4 | 0.4 | 0.0 |
| T002 | 1.2 | 1.2 | 0.0 |
| T003 | 1.5 | 1.5 | 0.0 |
| T004 | 1.2 | 1.4 | +0.2 |
| T005 | 1.3 | 1.5 | +0.2 |
| T006 | 1.7 | 1.7 | 0.0 |
| T007 | 0.5 | 0.4 | -0.1 |
| T008 | 1.6 | 2.2 | +0.6 |
| T009 | 0.6 | 0.6 | 0.0 |

**Average variance**: +0.13 SP/task (≈ +1.2 SP total; planned 10.0 → actual ≈ 11.2, modestly over the 6-10 band). The T008 overrun came from two pre-existing-defect detours surfaced during fixture work (B-001 duplicate-helper shadow + the stale F-047 phrase assertion); T004/T005 absorbed the B-001 diagnosis.

## Phase Variance

| Phase | Estimated | Actual | Delta | Notes |
| ----- | --------- | ------ | ----- | ----- |
| Planning | 0.6 | 0.9 | +0.3 | Implementation-state audit (Pillars 1-3 already shipped) + the two human-decision forks. |
| Implementation | 6.0-7.0 | 6.8 | 0.0 | Pillar 5 + Pillar 4 (validator + sync) + Pillar 1 producer landed without rework. |
| Verification / Evidence | 2.5-3.0 | 3.2 | +0.2 | Over band: B-001 debugging + stale-assertion repair during T008 fixtures. |
| Rework Buffer | 0.2-0.8 | 0.0 | 0.0 | No requirement rework; RED→GREEN on first implementation pass. |

## Drift Summary

- Total drift events: 0 (no specification drift)
- Resolved via spec update: 0
- Resolved via revert: 0
- Deferred: 0
- Escalated to human decision: 0
- Non-drift tooling anomalies logged: 2 (B-001 duplicate `Get-ObjectPropertyString`; A-001 recurrence) — see `drift-log.md`.

## What Went Well

- **Scoped to the real gap.** The implementation-state audit found Pillars 1-3 already shipped (F-047); iteration 004 became completion + certification, not a 5-pillar rebuild — TG-016 honored, effort focused on Pillars 4-5.
- **Each pillar empirically verified.** Pillar 5 positive/negative + closeout-gate integration; Pillar 4 sync repair on a temp project; Pillar 1 producer positive/negative. RED→GREEN on first pass.
- **Dogfood elegance.** Iteration 004's own Pillar 5 cleanly validated its own review.md (cited production files present in the cited tree) — the feature proving itself.
- **Cross-reviewer caught the exact failure FR-021 targets.** The Proposal 140 cross-review flagged the stale resume state (now.md/start-context 2 boundaries behind) — the silent-state-progression class this iteration shipped detection for. Repaired before iteration-closeout.

## What Didn't Go Well

- **B-001 — duplicate `Get-ObjectPropertyString` (latent, pre-existing).** Two definitions with different param names (`-Names` vs `-PropertyNames`); the later shadows the former. Cost a debugging detour when Pillar 4 read an empty `boundary_type`. Worked around (direct property access); consolidation deferred.
- **Stale-install dogfooding gap.** `$env:SPECREW_MODULE_PATH` pointed at the installed PSGallery 0.27.6, so the sync wrapper dispatched to the stale internal (lacking T005/T006) until I explicitly pointed it at the dev tree. My edits ship correctly but weren't live in this repo's resolved internal by default — the F-044 stale-install pattern.
- **A-001 recurrence.** Same `Get-QualityEvidenceContent` StrictMode crash; evidence + review + retro artifacts hand-authored again.

## Improvement Actions

1. Owner: framework maintainer | Phase: framework slice | Type: bug-fix | Consolidate the duplicate `Get-ObjectPropertyString` (B-001) into one definition + audit existing `-Names` callers that may be silently broken. Bundle with the A-001 fix.
2. Owner: framework maintainer | Phase: framework slice | Type: bug-fix | A-001: strict-safe `Get-QualityEvidenceContent` + reconcile the quality-gate table schema (carried from i005). Elevated — blocks scaffold/mechanical/reviewer-artifact generation.
3. Owner: maintainer | Phase: dogfooding setup | Type: process | When dogfooding framework changes on this repo, set `$env:SPECREW_MODULE_PATH` to the dev tree (or `Import-Module .\Specrew.psm1 -Force`) so sync dispatches to dev code — otherwise the installed module's stale internal runs. Note the new `Add-SpecrewHandoffEvidence` producer (T006) only fires when the resolved internal is the dev tree.
4. Owner: maintainer | Phase: F-049 feature-closeout | Type: verification | After publishing the module, confirm Pillar 4 sync repair + Pillar 1 producer run live (they were verified via dev-tree dispatch + unit/temp tests here).

## Calibration Suggestion

- Suggested capacity adjustment: keep current baseline (`25`). This slice ran ~11.2 vs 10.0 planned; the overrun was pre-existing-defect detours (B-001, stale assertion), not estimation error on the feature work.
- Rationale: the planned tasks were accurate; variance came from latent-defect discovery during verification.

## Notes

- Pillars 1-3 shipped in F-047 (certified here, not re-implemented); TG-016 preserved; Iteration 005 (Proposal 141) closed; Iterations 001-003 closed.
- Next boundary is iteration-closeout (human gate); not auto-advanced. Cross-reviewer available for that boundary too.
- B-001 + A-001 are framework-fix candidates (drift-log); the F-049 feature-closeout cleanup checklist already carries A-001 + the capacity-bump + version-bump items.
