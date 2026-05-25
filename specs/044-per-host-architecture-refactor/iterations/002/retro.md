# Retrospective: Iteration 002

**Schema**: v1
**Date**: 2026-05-24

**Feature**: F-044 Per-Host Architecture Refactor

> **Retroactive backfill disclaimer**: Estimation Accuracy + Phase Variance below reflect post-hoc reconstruction matching the 22 findings closed by single commit `dcc4beb7`.

## Estimation Accuracy

| Task | Estimated | Actual | Delta |
| ---- | --------- | ------ | ----- |
| T001 | 2 | 2 | 0 |
| T002 | 2 | 2 | 0 |
| T003 | 1 | 1 | 0 |
| T004 | 1 | 1 | 0 |

**Average variance**: +/- 0 (retroactive)

## Phase Variance

| Phase | Estimated | Actual | Delta | Notes |
| ----- | --------- | ------ | ----- | ----- |
| Planning | 0 | 0 | 0 | Scope defined entirely by iter-001 review findings; no upfront plan. |
| Discovery/Spikes | 1 | 1 | 0 | Advisor-flagged Squad CLI parse risk on Copilot HTML comment → sidecar pattern designed mid-iteration. |
| Implementation | 4 | 4 | 0 | T001 + T002 + T003 + T004 all closed within estimate. |
| Review | 1 | 1 | 0 | Test-suite verification + manual sidecar verification. |
| Rework | 0 | 0 | 0 | No rework loops; advisor catch prevented Squad CLI parse risk before it shipped. |

## Drift Summary

- Total drift events: 1 (W-4 sentinel implementation pivot)
- Resolved via spec update: 0
- Resolved via revert: 0
- Deferred: 0
- Resolved during this iteration: 1 (advisor catch — inline HTML comment in Copilot charter.md → switched to sidecar marker mid-iteration before close)
- Deferred to on-main work: 2 (W-7 Proposal 108 file + W-8 INDEX entry — per "proposals always commit to main" rule)

## What Went Well

- **Two-iteration close pattern executed cleanly**: iter-001 closed with 22 known findings; iter-002 addressed them in a single focused commit; feature now closes clean. This is exactly the review-gate-driven discipline Specrew enforces — the unusual aspect is that it was applied retroactively on out-of-order work, demonstrating the methodology resilience.
- **4-agent parallel deep review found everything that mattered**: PSScriptAnalyzer + markdownlint + parse-check all passed at iter-001 close (no mechanical lint debt), yet the 4 specialized agents (lint+tests, code quality, docs accuracy, architecture coherence) surfaced 22 findings the mechanical checks would never have caught. Confirms the value of specialist-agent review at boundaries.
- **Advisor caught the Squad CLI parse risk before it shipped**: The initial W-4 implementation prepended an HTML comment to Copilot's `charter.md`. Advisor flagged this as a parse-risk for Squad CLI. Sidecar-marker pattern was substituted mid-iteration. Without the advisor call before close, the parse risk would have shipped.
- **All 3 BUG findings have regression tests now**: B-1 covered by `crew-bootstrap-contract.tests.ps1` Test 4; B-2 + B-3 closure verified by Test 2 (manifest AgentDir resolution per host); A-1 covered by the 3 pre-existing `specrew-start-*` tests that now pass.

## What Didn't Go Well

- **W-7 + W-8 deferred to on-main work**: Proposal 108 file and INDEX update belong on main per the "proposals always commit to main, not feature branches" rule. They couldn't land in this branch. Not a methodology failure — just a process artifact of the per-feature-branch rule.
- **The single-commit-close shape is unconventional for 22 findings**: Splitting into per-finding commits would have been more granular but fragmented the narrative. Made the call to keep it single-commit since iter-002's entire purpose is "address the 22 findings." Captured in commit message. Reader can navigate via [`scope.md`](./scope.md)'s finding table.

## Improvement Actions

1. **Multi-agent deep review at iteration-closeout is a high-leverage practice**. Dispatching 4 specialist agents in parallel cost about 8 minutes of wall time and found 22 substantive issues. Without it, iter-001 would have closed with all 22 latent. Worth formalizing as a closeout-boundary option in Proposal 030 (Quality Hardening Bundle).
2. **Advisor sanity-check before declaring done is non-optional for substantive work**. The Copilot HTML-comment risk would have shipped without it. The advisor sees the full transcript and can catch what a single-agent operator misses.
3. **The Sidecar pattern is a generally-useful primitive** for "file metadata that can't live in the file." Worth abstracting + documenting if a third use case appears in the future.
4. **Closing 22 findings in one commit is acceptable when scope is "address the review"**. Single-commit shapes the narrative; multi-commit fragments it. Captured for similar future fix slices.

## Action items queued

| Item | Vehicle | When |
|---|---|---|
| Proposal 108 → shipped-as-F-044 INDEX update | On-main chore commit | Immediately after this branch merges to main |
| Antigravity smoke test | Small-fix slice | Post-Gemini-deadline 2026-06-18 |
| `specrew team` CLI rewire to canonical | Small-fix slice | Post-F-044 close |
| Per-host coordinator overlay translation | Proposal 024 Category D | Phase 2 |
| Proposal 063 / F-025 / F-029 Substantive Intake Questioning | Structural fix | Phase 2b (per current sequencing) |

## Honest framing for the reader

iter-002 closes F-044 clean. The "out-of-order" methodology debt from iter-001 (spec written after implementation) is mitigated by this iteration's clean close + the retroactive backfill of all iteration artifacts. The two-iteration shape is the methodology pattern; the unusual aspect is the retroactive application. The next time a feature ships in this kind of fast-moving conversational style, Proposal 063 (Substantive Intake Questioning) should be the structural fix that prevents the upfront-discipline gap.
