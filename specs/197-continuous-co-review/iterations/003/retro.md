# Retrospective: Iteration 003 (Always-On Co-Review — Phase A, Gate Re-Architecture)

**Feature**: 197-continuous-co-review
**Iteration**: 003
**Date**: 2026-06-21
**Status**: review-signoff accepted -> retro

## Outcome

Phase A delivered a sound, adversarially-validated content-addressed + anchored co-review
gate floor, the producer that auto-anchors it, and the gate-keyed dispatcher — all 197-owned,
no F-184 protected-surface edits, full suite 176/0. The iteration's centerpiece was
re-architected mid-flight after its own co-review found it unsound, twice.

## Estimation Accuracy

- Planned (re-architecture re-plan): 24.00/25 SP.
- Actual: meaningfully higher than 24 SP once the review/fix cycles are counted (one full
  re-architecture pivot + an adversarial gate review + a 3-dimension 145 review + a confirming
  re-review + the fix passes). The SP estimate tracked the BUILD; it did not budget the
  review-and-rework loops that the dogfooding generated. Calibration note: when the iteration's
  own design is the thing under co-review, budget explicit review/rework capacity, not just build.

## What Went Well

- **The dogfood loop worked — repeatedly, and that is the headline.** Continuous co-review
  caught its OWN gate model unsound twice before it could ship: first HOLE A (gitignored
  blindness) + HOLE B (unanchored operator baseline) via the design-panel co-reviews, then a
  blocking false-allow (F1) and a second blocking false-allow (the identity-strip) via the
  adversarial + 3-dimension 145 reviews. This is the proof the feature delivers its thesis.
- **Empirical self-validation beat the flaky tooling.** When the multi-agent design workflow
  kept timing out, a 60-second hand-run `git write-tree` experiment proved the content-addressed
  mechanism's determinism + gitignored inclusion + HOLE-A closure — unblocking the design.
- **Honest-state discipline caught real problems before they compounded**: the missing
  before-implement drift-log, the premature partial-close, the stale capacity figures, and the
  probe git pollution were all surfaced and corrected rather than papered over.

## What Didn't Go Well

- **The denylist conflated two concerns and caused two false-allows.** The gate IDENTITY
  (what's in the tree-id — must be minimal, or anything excluded becomes a false-allow vector)
  is the OPPOSITE of bundle CONFIDENTIALITY (what the reviewer is shown — can be broad). Mixing
  them produced F1 and the identity-strip false-allow. Lesson: an exclusion list's correct
  breadth depends entirely on whether exclusion is safe-permissive or safe-restrictive for that
  surface; never share one list across both.
- **The multi-agent WORKFLOW tool repeatedly stream-idle-timed-out on heavy single agents**
  (the content-addressed design + synthesis, 3 times); single `reviewer` Agents and inline
  empirical work were reliable. Lesson: for long single-agent analysis, prefer direct Agent
  calls with bounded-output instructions over a workflow fan-out.
- **A read-only review sub-agent mutated the repo's git CONFIG** (set user.name/email to
  "probe"), mis-authoring 16 commits — the exact SEC-003 mutation-boundary F-197 itself
  enforces. "Temp dirs only" was not enough; git IDENTITY must be sandboxed too. Recorded in
  memory with a verification recipe (`git log --format=%an <base>..HEAD | sort -u`).
- **The FR-025 spec text lagged the design twice** (diff_hash -> tree-id) — a reminder to
  re-reconcile the normative requirement, not just the design-analysis, after a pivot.

## Drift Summary

Drift for this iteration is tracked in the iteration drift-log. The honest-state corrections
surfaced and fixed in-flight — rather than silently absorbed — were: a missing before-implement
drift-log, a premature partial-close, stale capacity figures, and probe-induced git-identity
pollution (16 mis-authored commits, since sandboxed). No spec/plan/code drift went unrecorded.

## Improvement Actions

- Phase B (Iteration 004): live Stop-hook navigator + gate enforcement WIRING; the
  reviewer-runs-in-repo-for-tests execution model (so the 145 "run tests" works on the real
  host). The wiring + Stop-hook coordinate with F-185 (merges first) and F-184.
- F3/F4 override + run-record authentication/persistence: binding obligations on the F-185
  wiring PR.
- SC-012 maintainer real-host smoke test: AFTER Phase B, when always-on actually auto-fires.
- Process fix candidates (maintainer to weigh): sandbox review-agent git identity; prefer
  direct Agents over the workflow tool for heavy single-agent reviews.
