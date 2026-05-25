# Retrospective: Iteration 009

**Schema**: v1
**Date**: 2026-05-25

**Feature**: F-044 Per-Host Architecture Refactor

> Sixth LIVE-TRACKED iteration of F-044. Tiny wording-precision slice triggered by smoke-test prep regression discovery.

## Estimation Accuracy

| Task | Estimated | Actual | Delta |
| ---- | --------- | ------ | ----- |
| T001 | 0.5 | 0.5 | 0 |
| T002 | 1 | 1 | 0 |
| T003 | 0.5 | 0.5 | 0 |
| T004 | 0.5 | 0.5 | 0 |

**Average variance**: 0 SP at the task level. Clean iteration with explicit user-stated scope; no surprises.

## Phase Variance

| Phase | Estimated | Actual | Delta | Notes |
| ----- | --------- | ------ | ----- | ----- |
| Planning | 0.25 | 0.25 | 0 | Plan + scope question consumed seconds, not minutes. |
| Discovery/Spikes | 0 | 0 | 0 | Pre-iteration triage answered the question. |
| Implementation | 1.75 | 1.75 | 0 | T001 + T002 + T003. |
| Review | 0.25 | 0.25 | 0 | Markdownlint + validator. |
| Rework | 0.25 | 0 | -0.25 | Buffer unused — no rework needed. |

The -0.25 SP buffer unused is the most positive signal in F-044's arc: when scope is wording-precision (not methodology evolution or behavior change), there is genuinely no risk of rework.

## Drift Summary

- Total drift events: 0 (see [drift-log.md](./drift-log.md))
- Resolved via spec update: 0
- Resolved via revert: 0
- Deferred: 0
- Resolved during this iteration: 0

## Improvement Actions

- **Validator hardening for bare-URI enforcement**: add a parse rule that scans handoff content (committed `decisions.md` entries, scribe logs) for markdown-link-wrapped `file:///` URIs and flags them as a methodology violation. Promote from text-rule to validator-enforced. Future small-fix candidate (~2-3 SP).
- **Canonical template wording-audit checklist**: when adding methodology-fundamental wording directives to templates, run a "could an agent interpret this in a way that defeats the UX?" audit before merge. iter-009's regression came from a wording gap that was technically correct but practically ambiguous.
- **Smoke-test prep as a methodology-dogfood signal**: this iteration was triggered BEFORE the user actually ran the smoke test — just by preparing for it. Consider this pattern as a first-class methodology-dogfood mode: "pre-test rehearsal" surfaces UX gaps that don't appear in automated testing.

## What Went Well

- **User caught the regression in pre-smoke-test prep**, not during smoke test. This saved 30+ minutes of confused clicking + diagnosis time across 4 hosts.
- **The fix-path was obvious from the user's report**. No investigation needed — the regression was wording-precision in templates already authored.
- **The 10 template files mirrored cleanly**: 1 coordinator-governance + 5 agent charters + 1 user-guide + their .specify/ mirrors. No drift between canonical and deployed templates.
- **Tiny iteration ceremony justified by durable artifact value**: 2.5 SP for the touch + closeout artifacts is correct cost for capturing a methodology wording-precision lesson durably.

## What Didn't Go Well

- **The regression existed for the duration of iter-008**. The iter-008 wording was authored, mirrored, lint-clean, validator-clean, committed, pushed — and STILL had the ambiguity. Calibration insight: post-implementation lint/validator passes verify SYNTAX, not SEMANTIC PRECISION. A methodology-wording change needs a different review lens.
- **PSGallery is still v0.26.0** — iter-009 fixes land in v0.27.0 (PR #844). Users on PSGallery v0.26.0 will see the regression until PR #844 merges + v0.27.0 publishes.

## Methodology Lessons

### Wording-precision is its own iteration shape

iter-009 isn't a feature, isn't a bug fix, isn't a refactor, isn't documentation. It's tightening template wording to remove a specific ambiguity that produced an empirical regression. The methodology cost is small (~30 min ceremony, 2 SP work) but the durable artifact value is high: future template edits can read iter-009's record to understand why bare-URI is explicit. This is a calibration data point for a future "wording-precision slice type" (extension of Proposal 067 small-fix slice type).

### Methodology directives need empirical test coverage

iter-008 had the directive "use `file:///` URIs". The validator parses for the URI scheme. But there's no test for "does the URI appear bare or wrapped?". The empirical test was the user's smoke-test-prep eyeball. Future methodology-wording changes should include at least one empirical test fixture (a sample compliant + a sample violating handoff) so the validator can catch regressions of THIS class.

## Carry-Over to Next Iteration / Feature

- F-043 + F-044 bundled PR (#844) is ready for user manual smoke test after iter-009 lands.
- Future small-fix candidate: validator rule that flags markdown-link-wrapped `file:///` URIs in handoff content.
- F-044's arc is now closed: 9 iterations. No iter-010 anticipated.

## Velocity Snapshot

- F-044's 9 iterations totaled: 18 + 6 + 4 + 3 + 8 + 4 + 7 + 10 + 2.5 = 62.5 SP delivered against ~180 SP nominal capacity (20/iter × 9).
- True throughput: 62.5 SP across ~3 weeks of dogfood-driven discovery + repair + docs work.
- Velocity intentionally below capacity — F-044 was the longest-running feature in Specrew's history due to a 9-iteration arc of architectural refactor + regression discovery cycles.
