# Iteration 012 Drift Log

**Feature**: F-044 | **Iteration**: 012 — v0.27.0 Release-Readiness Slice

## Drift #1 — Proposal-110 collision discovered mid-iteration

- **Planned scope** (per user direction): merge main, author release-notes, polish docs.
- **Surfaced**: pre-merge inspection of main's git log revealed `3f2bcd01` (concurrent Claude session) had committed `proposals/110-specrew-update-experience.md` BEFORE my `proposals/110-quality-tier-routing-runtime-verification-bundle.md` (commit `6f489d8f`). Same proposal number on different files. Git accepted both because filenames differed.
- **Resolution**: renumbered my proposal 110 → 112 (theirs was first by minutes); registered theirs in INDEX (they hadn't yet); bumped candidate count to reflect both now in catalog.
- **Why this is in-scope**: iter-012 is the natural place to clean this up because (a) it's a release-readiness iteration, (b) the merge from main was the first step anyway, and (c) leaving a collision unfixed pre-publish would confuse external readers.
- **Methodology lesson**: when working in parallel across Claude sessions on main, ALWAYS `git fetch origin main` immediately before drafting a new proposal to verify the next free number. Empirical motivation for Proposal 109 (open-feature awareness) — the methodology layer should surface "concurrent proposal numbers being drafted right now" at session start, not let two sessions race to the same number.

## Drift #2 — iter-009 reviewer artifacts missed at original closeout

- **Planned (iter-009)**: docs/template wording-precision iteration. Did NOT scaffold reviewer artifacts (coverage-evidence, reviewer-index, review-diagrams).
- **Discovered (iter-011 + iter-012)**: CI's full-unscoped validator caught iter-009 missing required reviewer artifacts. Local `-ChangedOnly` validator never reported it because iter-009 wasn't in subsequent diffs.
- **Resolved in iter-011 follow-up commit** `0b1c1810` (before iter-012 started): scaffolded the 3 missing artifacts retroactively.
- **Methodology lesson**: the validator's `-ChangedOnly` mode is fast but blind to drift in iterations outside the current diff. Empirical motivation for Proposal 111 (git-hook markdownlint enforcement) + a future "local validator must match CI invocation" small-fix.
- **Status**: not iter-012 scope; recorded here for traceability since the fix happened between iter-011 and iter-012.

## Surfaced-but-deferred (recorded for traceability)

- **iter-010 PR-review cleanup** — 7 Copilot review findings remain pending. Decision pre-iter-008: ships as separate small-fix slice OR v0.27.1 patch. NOT iter-012.
- **dashboard.md missing artifacts** — 9 iterations across F-031, F-043, F-044 missing dashboard.md. Validator WARNs (not FAILs). Proposal 046+048 scope; future iteration.
