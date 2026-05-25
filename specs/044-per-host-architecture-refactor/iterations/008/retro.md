# Retrospective: Iteration 008

**Schema**: v1
**Date**: 2026-05-25

**Feature**: F-044 Per-Host Architecture Refactor

> Fifth LIVE-TRACKED iteration of F-044. plan.md authored before code; actuals at task close. Mid-iteration scope expansion from 7 SP → 10 SP captured in drift-log.

## Estimation Accuracy

| Task | Estimated | Actual | Delta |
| ---- | --------- | ------ | ----- |
| T001 | 1 | 1 | 0 |
| T002 | 1 | 1 | 0 |
| T003 | 2 | 2 | 0 |
| T004 | 2 | 2 | 0 |
| T005 | 1 | 1 | 0 |
| T006 (mid-iter addition) | 1.5 | 1.5 | 0 |
| T007 (mid-iter addition) | 1 | 1 | 0 |
| T008 (mid-iter addition) | 0.5 | 0.5 | 0 |

**Average variance**: 0 SP at the task level. **Total iteration scope expanded from 7 → 10 SP mid-iteration** (drift #1). The expansion was triggered by user manual-test feedback that surfaced a methodology-fundamental regression. Adding it was the correct call: user explicitly flagged manual re-test conditional on the fix, and the fix sat structurally inside spare capacity (10 SP final / 20 SP capacity = 50%).

## Phase Variance

| Phase | Estimated | Actual | Delta | Notes |
| ----- | --------- | ------ | ----- | ----- |
| Planning | 0.5 | 0.75 | +0.25 | Original plan + mid-iteration re-plan for T006/T007/T008. |
| Discovery/Spikes | 0 | 0.5 | +0.5 | Investigating where the three-section format directive lived: charters, governance, validator, deployed template. Found the prominence gap. |
| Implementation | 5.5 | 7.75 | +2.25 | T001 + T002 + T003 + T004 + T006 + T007 + T008. |
| Review | 0.5 | 0.5 | 0 | Markdownlint + validator. |
| Rework | 0.5 | 0.5 | 0 | Buffer absorbed nothing — clean iteration. |

The +2.25 SP at implementation maps to the 3-task scope expansion. Pre-expansion estimate was correct for the original 5 tasks.

## Drift Summary

- Total drift events: 2 (see [drift-log.md](./drift-log.md))
- Resolved via spec update: 0
- Resolved via revert: 0
- Deferred: 0 in iter-008 scope (Proposal 109 candidate is user-scoped as separate commit to main, not iter-008 deferral)
- Resolved during this iteration: 2 (drift #1 mid-iteration scope expansion accepted; drift #2 .specify/ mirror discipline reinforced)

## Improvement Actions

- **Canonical-template propagation check**: when adding a methodology-fundamental directive (like Feature 016 Pillar 1's three-section format), the propagation surface MUST include all 5 agent charters AND the coordinator governance template — not just whichever role most-often hits the boundary. Add to the next pre-merge review checklist for methodology-shape changes.
- **Three-section format validator hardening**: the validator already parses for the format (`shared-governance.ps1:2479`). Promoting from parse-detect to enforcement-rule (e.g., warn if a boundary handoff lacks the format) is a candidate for a future small-fix iteration. Not iter-008 scope but worth queueing.
- **`.specify/` mirror automation**: this is the THIRD iteration where I've manually mirrored canonical-template edits to `.specify/` (iter-007 + iter-008 + ad-hoc previous). A `bin/sync-specify-mirror.ps1` script that copies `extensions/...` to `.specify/extensions/...` on demand would prevent drift and reduce per-iteration cost by ~5 minutes. Future small-fix candidate.

## What Went Well

- **Mid-iteration scope expansion was a clean accept, not scope creep.** The added tasks (T006/T007/T008) were tightly coupled to the existing iter-008 docs work and the user explicitly flagged manual re-test conditional on the fix. Capacity (10/20 = 50%) absorbed the expansion without forcing deferral. Calibration data: methodology-fundamental regressions DESERVE mid-iteration scope expansion when capacity allows.
- **Investigation found the root cause cleanly** — five minutes of grep revealed only 1 of 5 charters mentioned the format, and the coordinator governance had it as a single bullet. No speculation required. The fix-path (add to all 5 + expand governance directive) was obvious from the investigation output.
- **The walkthrough (T004) was the most leveraged piece of work in iter-008.** A reader can now follow a complete feature end-to-end with concrete boundary-handoff examples. Future docs improvements can reference and extend this walkthrough rather than rebuild from scratch.
- **iter-008 has the highest task count (8) in F-044's live-tracked set, AND the cleanest variance.** Estimation lands hard when iteration scope starts from clear user-stated outcomes and stays within capacity.

## What Didn't Go Well

- **The three-section format regression should have been caught earlier.** It's a Feature 016 (May 2026) guarantee. F-044's Slice 9 canonical-team migration silently lost prominence of the directive — propagated as a one-line bullet rather than as a structural template. No automated check fires when a methodology-fundamental directive moves between source locations and loses prominence. Future improvement: methodology-fundamental directives should have BOTH a code-level reference (e.g., validator parse rule) AND a structural prominence in agent charters; whichever is touched must verify the other.
- **`.specify/` mirror duplication is a methodology-recurring cost.** Three iterations (iter-007 + iter-008 plus earlier) have paid the manual-mirror cost. Future small-fix automation candidate.
- **Docs investigation drained 0.5 SP I hadn't budgeted in Phase Baseline.** Discovery time for "where does the three-section format live in the codebase?" was non-trivial. Calibration insight: when adding methodology-text changes that span multiple template files, budget 0.5-1 SP for code-investigation phase BEFORE planning the prose changes.

## Methodology Lessons

### Prominence > existence in methodology directives

The three-section format directive technically existed. It was in coordinator-governance.md 14A. The validator parsed for it. The Implementer charter mentioned it. But it WASN'T applied consistently in practice because **prominence is what survives migration**. A one-line bullet in a long list of rules migrates fine but doesn't anchor agent behavior. A `### Boundary handoff format` section in every charter, with the canonical template inline, anchors behavior.

This generalizes: methodology directives that depend on agent behavior need STRUCTURAL prominence (named section, code-fence template, repeated in every role's charter), not just textual existence. If the directive can be described in one line and that's all the methodology layer provides, the directive is at risk.

### Mid-iteration scope expansion is a feature, not a bug

iter-008's 7 → 10 SP expansion happened because the user manual-tested mid-iteration and surfaced something fundamental. The methodology absorbed the expansion cleanly because (a) capacity was healthy, (b) the added tasks were tightly coupled to existing scope, (c) the user explicitly conditioned manual re-test on the fix. The pattern is: when user feedback during an iteration is methodology-fundamental AND fits inside spare capacity, expand — don't defer.

## Carry-Over to Next Iteration / Feature

- F-043 + F-044 bundled PR (#844) is ready for user manual re-test after iter-008 lands.
- Post-PR-merge: draft Proposal 109 candidate (open-feature awareness + multi-feature switching + never-closed feature methodology) on main per user direction.
- Future small-fix candidate: `bin/sync-specify-mirror.ps1` to automate canonical-template → `.specify/` mirror discipline.
- Future small-fix candidate: validator hardening for three-section format (promote parse-detect → enforcement).

## Velocity Snapshot

- F-044's 8 iterations totaled: 18 + 6 + 4 + 3 + 8 + 4 + 7 + 10 = 60 SP delivered against ~160 SP nominal capacity (20/iter × 8).
- True throughput: 60 SP across ~3 weeks of dogfood-driven discovery + repair + docs work.
- Velocity intentionally below capacity — F-044 was discovery-heavy (4 backfill + 5 live-tracked iterations covering Phase A-D refactor + Slice 9 + 5 dogfood-discovered repair slices).
