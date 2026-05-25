# Retrospective: Iteration 001

**Schema**: v1
**Date**: 2026-05-24

**Feature**: F-044 Per-Host Architecture Refactor

> **Retroactive backfill disclaimer**: Estimation Accuracy + Phase Variance reflect post-hoc reconstruction. Actual=Estimated because no live tracking happened during iter-001. The `needs-rework` review verdict captures 22 findings honestly closed in iter-002.

## Estimation Accuracy

| Task | Estimated | Actual | Delta |
| ---- | --------- | ------ | ----- |
| T001 | 2 | 2 | 0 |
| T002 | 2 | 2 | 0 |
| T003 | 3 | 3 | 0 |
| T004 | 2 | 2 | 0 |
| T005 | 2 | 2 | 0 |
| T006 | 2 | 2 | 0 |
| T007 | 4 | 4 | 0 |
| T008 | 1 | 1 | 0 |
| T009 | 0 | 0 | 0 |

**Average variance**: +/- 0 (retroactive — no live tracking)

## Phase Variance

| Phase | Estimated | Actual | Delta | Notes |
| ----- | --------- | ------ | ----- | ----- |
| Planning | 0 | 0 | 0 | No upfront plan — design happened iteratively per phase in conversation; spec authored retroactively at closeout. |
| Discovery/Spikes | 1 | 1 | 0 | Proposal 108 design + design doc commit `0aa3ff51`. |
| Implementation | 17 | 17 | 0 | T001 through T008. |
| Review | 0 | 0 | 0 | 4-agent deep review is closeout overhead (T009). |
| Rework | 0 | 0 | 0 | All findings deferred to iter-002 fix slice; no in-iteration rework loops. |

## Drift Summary

- Total drift events: 5 (see [drift-log.md](./drift-log.md))
- Resolved via spec update: 0
- Resolved via revert: 0
- Deferred: 3 (Drift #3 Antigravity smoke test; #4 coordinator-overlay translation; #5 `specrew team` CLI rewire)
- Resolved during this iteration: 2 (Drift #1 spec written after impl — methodology debt documented; Drift #2 Slice 9 canonical-source-of-truth redesign accepted mid-flight)
- Resolved in next iteration: 22 deep-review findings → iter-002

## What Went Well

- **Open-Closed posture achieved**: Adding a new host (Cursor, Windsurf, Grok, etc.) now genuinely requires only `mkdir hosts/<kind>/` + 3 files + a FileList entry. The structural firewall test (`tests/integration/host-coupling-firewall.tests.ps1`) makes drift CI-blocking. This was the explicit acceptance criterion the user named: "in the future, adding a host for Cursor, windsurf or grok code should not open existing files." Achieved.
- **`specrew-init.ps1` shrunk from 2,428 → ~800 lines**: Net win for maintainability. Each extracted file has a single responsibility, <300 lines. Every previously internal function still works via dot-source.
- **Canonical team source-of-truth is a clean abstraction**: The mid-flight redesign (Drift #2) produced a better architecture than the original Proposal 108 plan. Users now have a single editable location (`.specrew/team/agents/<role>.md`) that propagates to all 4 hosts on every `specrew start`.
- **Review-gate caught real issues**: The 4-agent deep review found 3 BUG-tier defects (one functional regression, two Open-Closed seams), 11 WARN-tier gaps (mostly docs drift + behavioral mismatches with stated docs), and 8 NIT-tier cleanups. Without the review-gate, these would have shipped to main as latent debt.

## What Didn't Go Well

- **Methodology violations were systemic in this iteration** (Drift #1 — see [`drift-log.md`](./drift-log.md)). Spec was written AFTER the work. Clarify and plan boundaries never happened in real-time. Review was almost skipped — only the user's explicit closeout request saved it. This is precisely the failure mode Substantive Intake Questioning (Proposal 063 / F-025 / F-029) is designed to prevent. The user explicitly named it: "we work really hard and not so by Specrew methodology since I want available and I let you run."
- **Slice 9 PowerShell parsing gotchas wasted ~30min**: Two non-obvious PowerShell behaviors caused first-attempt failures — (a) `,` binds tighter than `+` inside `@(...)` literals causing all-on-one-line concatenation; (b) `@(...) -join "`n"` on a single expression returns zero LFs. Both documented in `docs/how-to/add-a-new-host.md` as canonical gotchas for future contributors, so the cost converts to a lasting lesson.
- **Antigravity smoke test skipped** (Drift #3). The host was graduated from "deferred" to "supported" on inference, not empirical verification. First user to run `specrew start --host antigravity` may surface format errors.
- **Coordinator overlay translation not shipped** (Drift #4). Claude / Codex / Antigravity users get a team but no coordinator overlay file — coordination is prose-driven from the bootstrap prompt. Functional but less polished than Copilot. Deferred to Proposal 024 Category D work.
- **`specrew team` CLI still writes to legacy `.squad/team.md`** (Drift #5). Cross-host team customization requires manual file creation at the canonical location until the CLI is rewired.

## Improvement Actions

1. **Substantive Intake Questioning (Proposal 063) is structurally required** before fast-moving multi-feature pushes. F-044's drift-1 is the same shape as F-043's auto-drafted-overnight pattern — both are symptoms of the same gap. F-025 / F-029 is the standing fix; this iteration adds another empirical incident to its motivation.
2. **The Sentinel/Sidecar pattern is the right design for "Specrew-managed" file marking**. iter-001's inline-HTML-comment approach in Copilot's `charter.md` would have risked Squad CLI parse failure. iter-002 introduced the sidecar pattern (`<path>.specrew-managed`) for hosts whose native format cannot tolerate a comment header. Captured for future hosts whose subagent formats are strict.
3. **`AgentDir` must be an enforced required field for `Status='supported'` hosts**. iter-001 declared it for 3/4 hosts but left Copilot without it (the latent bug B-2 / B-3 root cause). iter-002's validator update enforces this; future hosts cannot ship "supported" without declaring the directory.
4. **Marker-file walk on `Specrew.psd1` should be a canonical helper, not duplicated**. iter-001 had it inline in `_utilities.ps1::Get-SpecrewExecutionLayout`, then Slice 9's new files re-introduced the fragile 2-level Split-Path pattern that Slice 5/8 had explicitly fixed. iter-002 cleaned the regression. A factored `Get-SpecrewDistRoot` helper would prevent re-occurrence — queued as a small chore.
5. **Two-iteration close pattern is the right shape for retroactive backfill on out-of-order work**. Demonstrates the methodology even when the work shipped before the methodology was applied. Worth formalizing as a doc-able pattern in Proposal 067 (Small-Fix Slice Type) when it ships.

## Action items queued for follow-up

| Item | Vehicle | When |
|---|---|---|
| Antigravity empirical smoke test (`agy` binary) | Small-fix slice | After Gemini-deadline 2026-06-18 resolution |
| Per-host coordinator-overlay translation (Claude / Codex / Antigravity) | Proposal 024 Category D | After F-044 closes |
| `specrew team` CLI rewire to canonical `.specrew/team/agents/<role>.md` | Small-fix slice | Post-F-044 closeout |
| Factor `Get-SpecrewDistRoot` marker-walk helper to prevent re-duplication | Small chore | Opportunistic |
| Proposal 063 / F-025 / F-029 Substantive Intake Questioning | Structural fix | Phase 2b (per current sequencing) |

## Honest framing for the reader

iter-001 shipped major architectural value but with significant methodology debt. The two-iteration close (iter-001 with known issues + iter-002 fix slice) is the discipline pattern; the unusual aspect is that it was applied retroactively. The user's own framing ("we work really hard and not so by Specrew methodology") is the most important data point in this retro — and the fix is structural, not procedural (F-025 / F-029 is the standing work).
