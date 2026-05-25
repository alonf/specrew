# Iteration Plan: 009

**Schema**: v1
**Spec**: [../../spec.md](../../spec.md)
**Status**: complete
**Capacity**: 2.5/20 story_points
**Started**: 2026-05-25
**Completed**: 2026-05-25

> Sixth LIVE-TRACKED iteration of F-044. Tiny regression-fix slice surfaced by user's smoke-test prep across all 4 hosts.

## Scope Summary

User flagged a smoke-test-readiness regression: across all 4 hosts (Copilot, Claude, Codex, Antigravity), boundary handoffs emit file references in markdown-link form `[plan.md](file:///C:/foo/plan.md)` instead of bare `file:///C:/foo/plan.md` URIs. PowerShell terminals (Windows Terminal, VS Code integrated terminal) auto-detect bare `file:///` URIs and make them clickable via Ctrl+Click — but they do NOT render markdown, so the URL is hidden inside `()` and the user can't click through to the artifact.

Root cause: coordinator-governance 14A + all 5 agent charters say "use `file:///` URIs" but don't explicitly forbid markdown-link wrapping. An agent reading the directive can legitimately emit `[name](file:///...)` because that IS a file:/// URI — just wrapped. iter-009 tightens the wording to mandate **bare** form explicitly.

| Requirement | Summary | Stories |
| --- | --- | --- |
| FR-012 | Documentation updated for shipped state — including methodology UX wording | US5 |

## Tasks

| Task | Title | Requirement | Story | Effort | Owner | Owner File Globs | Status | Agent | Actual | Verdict |
| ---- | ----- | ----------- | ----- | ------ | ----- | ---------------- | ------ | ----- | ------ | ------- |
| T001 | coordinator-governance.md 14A — add explicit "BARE file:/// URI (not markdown link form `[name](url)`)" requirement to the canonical template + welcoming-tone block. Mirror to .specify/ deployed copy | FR-012 | US5 | 0.5 | Implementer | extensions/specrew-speckit/squad-templates/coordinator/specrew-governance.md; .specify/.../specrew-governance.md | done | claude | (actual) | pass |
| T002 | All 5 agent charters — add explicit "BARE file:/// URI (not markdown link form)" to the Boundary handoff format subsection added in iter-008. Mirror to .specify/ deployed copies | FR-012 | US5 | 1 | Implementer | extensions/specrew-speckit/squad-templates/agents/*/charter.md; .specify/.../agents/*/charter.md | done | claude | (actual) | pass |
| T003 | docs/user-guide.md "What you'll see at every boundary" section — add explicit note about bare-URI requirement + why (PowerShell terminals don't render markdown, so wrapping hides the URL) | FR-012 | US5 | 0.5 | Implementer | docs/user-guide.md | done | claude | (actual) | pass |
| T004 | iter-009 artifacts + markdownlint + validator (canonical-schema) + commit + push to PR #844 | FR-012 | US5 | 0.5 | Implementer | specs/044-per-host-architecture-refactor/iterations/009/* | done | claude | (actual) | pass |

## Effort Model

| Setting | Value | Notes |
| ------- | ----- | ----- |
| Effort Unit | story_points | |
| Capacity per Iteration | 20 | Project default. |
| Iteration Bounding | scope | 4 tasks bounded by tightening template wording across 12 files (6 canonical + 6 .specify mirrors) |
| Time Limit (hours) | n/a | |
| Overcommit Threshold | 1.0 | 2.5/20 = 12.5% — well under threshold. |
| Defer Strategy | manual | If T002 surfaces additional unclear wording elsewhere, surface for re-planning. |
| Calibration Enabled | true | Sixth live-tracked iteration. |

## Concurrency Rationale

- Roster snapshot: Spec Steward, Planner, Implementer, Reviewer, Retro Facilitator.
- T001 + T002 — both text-only template tightening; serial.
- T003 — docs addition; serial after T002 so wording is consistent.
- T004 — final gate; runs last.

## Phase Baseline

| Phase | Estimated Effort | Notes |
| ----- | ---------------- | ----- |
| Planning | 0.25 | This plan + identifying the wording gap. |
| Discovery/Spikes | 0 | Investigation done in pre-iteration triage; user-confirmed scope. |
| Implementation | 1.75 | T001 + T002 + T003. |
| Review | 0.25 | Markdownlint + validator. |
| Rework | 0.25 | Buffer if smoke test surfaces secondary wording issues. |

## Routing Policy

| Lens Scope | Requested Reasoning / Review Class | Effective Class (when run) | Override / Approval Record | Notes |
| --- | --- | --- | --- | --- |
| Template text tightening | standard | Markdownlint + validator + user smoke-test re-run after PR #844 lands | n/a | iter-009's empirical test boundary is "user's next smoke run sees bare clickable URIs in every boundary handoff across all 4 hosts". |

## Traceability Summary

- Task coverage: 4 tasks for 1 user-surfaced regression (markdown-link-wrapped file:/// URIs not clickable in PowerShell).
- Traceability check: PASS at plan-boundary.
- Overcommit guardrail: 2.5/20 = 12.5% capacity. Healthy.

## Notes

- **Why this is iter-009 of F-044, not a separate feature**: same scope as iter-008 (methodology UX prominence + template wording). iter-008 surfaced 5 of 5 agent charters lacked the format directive; iter-009 surfaces that even WITH the directive, markdown-link wrapping defeats the UX. Tightly coupled to iter-008's work; same v0.27.0 release.
- **Not a methodology evolution**: this is wording precision, not a new methodology concept. Bare `file:///` URI was the intent from F-016 Pillar 1 (May 2026); iter-009 fixes the wording so it's enforced.
- **Validator hardening deferred**: promoting from text-rule to validator-enforced rule (parse handoff content + reject markdown-link-wrapped file:/// URIs) is a separate methodology-evolution candidate; not iter-009 scope. Captured in retro Improvement Actions.
