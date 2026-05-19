---
proposal: 016
title: Outcome Scoring
status: candidate
phase: phase-4
estimated-sp: 27
discussion: tbd
---

# Outcome Scoring

## Why

Specrew measures **conformance** (artifact existence, lifecycle discipline, boundary patterns) extensively, but doesn't measure **outcomes** (did the feature deliver its declared requirements?). The original `evaluation/` harness was supposed to fill this gap with an outcome-quality scorer + end-to-end harness; both were deferred and never built. The harness was retired in 2026-05-15 as functionally duplicated by `validate-governance.ps1` for process-quality, but the outcome-quality idea was preserved as this proposal.

Outcome scoring answers: of the FRs declared in each feature's `spec.md`, what fraction have corresponding implementation evidence? Acceptance pass rate per iteration? Are the FRs aligned with tasks, tests, and corpus rows? These are different questions than "do the lifecycle artifacts exist?" and `validate-governance.ps1` doesn't ask them.

## What

A new scoring harness measuring:

- **Requirement coverage**: per feature, count FRs in `spec.md` with corresponding evidence (tasks in `tasks.md`, test fixtures, validator rules, corpus rows)
- **Acceptance pass rate**: per iteration, fraction of reviews accepted on first pass vs needing rework
- **Artifact consistency**: cross-check FRs in spec.md align with tasks.md, test scenarios, corpus rows

Plus:

- Aggregate scoring at repo level (overall coverage, per-feature breakdown)
- Historical snapshot retention (so trends become possible over time)
- Integration with iteration-closeout boundary (refresh report at closeout, write `specs/<feature>/iterations/<NNN>/outcome-score.md`)
- Methodology-site embedding (when the public site is built, shows aggregate score as a trust signal)

## Effort

~25-30 SP across 2-3 iterations.

## Phase placement

Phase 4 (post-MVP, methodology evolution). Sooner if external evaluation demand triggers, methodology-site requires it as trust signal, or trend analysis becomes load-bearing for methodology claims.

## Open questions

1. Coverage definition — what counts as "evidence" for an FR?
2. Acceptance pass-rate scope — first review only, or include re-review cycles?
3. Historical snapshot storage — git-tracked or external?
4. Methodology-site rendering — single aggregate, or per-feature breakdown?
5. CI integration — gate or descriptive?
6. Scoring of in-flight features — included with partial coverage, or only fully shipped?

## Risks

- **Coverage gaming**: developers might game the metric by adding trivial test fixtures. Mitigation: combine with code-review judgment; outcome-scoring is descriptive, not gating.
- **Metric staleness**: scores drift as features evolve. Mitigation: regenerate at every iteration-closeout.
- **Aggregate vs detail tension**: a single repo-level score loses nuance. Mitigation: per-feature breakdown as primary surface; aggregate is a summary.

## Cross-references

- Composes with: Proposal 013 (Methodology Site) — natural consumer of aggregate scores
- Composes with: Proposal 014 (Red Team Agent) — outcome scoring complements Red Team's design-challenging perspective
- Related: Proposal 018 (Source-Spec Fidelity Contract) — closer to "does code match spec" than outcome scoring

## Status history

- 2026-05-07: original idea in `evaluation/` harness (deferred at iteration 3, never built)
- 2026-05-15: harness retired; idea preserved as candidate proposal
