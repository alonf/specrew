# Iteration Plan: 004

**Schema**: v1
**Spec**: [../../spec.md](../../spec.md)
**Status**: complete
**Capacity**: 3/20 story_points
**Started**: 2026-05-24
**Completed**: 2026-05-24

> **First LIVE-TRACKED iteration of F-044.** iter-001/002/003 plans were retroactive backfills. iter-004 starts here BEFORE implementation, with SP allocation and Phase Baseline authored at plan-boundary. Actual values get filled at task close, producing real variance.

## Scope Summary

User-surfaced UX improvements after seeing iter-003's fixes in their `specrew host` output:

1. **`specrew start` (no `--host`)**: currently prompts `Read-Host "Select a host (copilot / claude / codex)"` requiring text input of kind name. User wants a numbered menu (1/2/3/N) for one-keystroke selection.
2. **`specrew host list`**: currently lists hosts alphabetically with `available` / `not on PATH` markers. User wants installed hosts FIRST, then a separate `(not installed)` section showing the install URL for hosts they could add.
3. **Detection robustness** (proactive — Bug 7e adjacent from iter-003 retro): both `Test-SpecrewHostAvailable` and the first-run probe check only `$manifest.Binary`; `BinaryAliases` is declared in the contract but never consulted. Future hosts with alternate command names would silently fail to detect.

| Requirement | Summary | Stories |
| --- | --- | --- |
| FR-011 | Adding a new host requires zero edits to existing files (preserved — these changes touch contract consumers, not the contract itself) | US4 |
| FR-013 | First-run probe non-TTY exit guidance (improved — numeric menu maintains TTY behavior; non-TTY path unchanged) | US1 |

## Tasks

| Task | Title | Requirement | Story | Effort | Owner | Owner File Globs | Status | Agent | Actual | Verdict |
| ---- | ----- | ----------- | ----- | ------ | ----- | ---------------- | ------ | ----- | ------ | ------- |
| T001 | Numbered-menu first-run probe — show installed first, not-installed in separate section with install URL, accept 1-N OR kind-name | FR-013 | US1 | 1.5 | Implementer | scripts/internal/host-history.ps1 (Invoke-SpecrewFirstRunHostProbe) | done | claude | 1.5 | pass |
| T002 | `specrew host list` sort: installed first, then `(not installed)` group with install URL hints | (UX) | US4 | 1 | Implementer | scripts/specrew-host.ps1 (Invoke-SpecrewHostList) | done | claude | 1 | pass |
| T003 | Detection probes BinaryAliases when Binary itself is not on PATH | FR-011 | (infra) | 0.5 | Implementer | scripts/internal/detect-hosts.ps1 (Test-SpecrewHostAvailable); scripts/internal/host-history.ps1 (Invoke-SpecrewFirstRunHostProbe binary probe) | done | claude | 0.5 | pass |

## Effort Model

| Setting | Value | Notes |
| ------- | ----- | ----- |
| Effort Unit | story_points | Live-tracked this time. |
| Capacity per Iteration | 20 | Specrew project default. |
| Iteration Bounding | scope | 3 UX improvements bounded; no scope expansion mid-iteration. |
| Time Limit (hours) | n/a | Scope-bounded. |
| Overcommit Threshold | 1.0 | 3/20 = 0.15 — well under threshold. |
| Defer Strategy | manual | If any task exceeds estimate by >50%, surface to user for deferral decision. |
| Calibration Enabled | true | First live-tracked iteration; variance data feeds future capacity planning. |

## Concurrency Rationale

- Roster snapshot: Spec Steward, Planner, Implementer, Reviewer, Retro Facilitator.
- 3 tasks touch 3 disjoint files (with T001 + T003 sharing one — `host-history.ps1`). Serial execution; no Junior/Senior pair.

## Phase Baseline

| Phase | Estimated Effort | Notes |
| ----- | ---------------- | ----- |
| Planning | 0.25 | This plan; written before code (live tracking starts). |
| Discovery/Spikes | 0 | All 3 tasks have clear root cause from user feedback. |
| Implementation | 2.5 | T001 (1.5) + T002 (1) + T003 (0.5) = 3 SP — minus 0.5 for cross-cutting test code that overlaps. |
| Review | 0.25 | Parse-check + manual test of new menu UX. |
| Rework | 0 | None expected; if user's next test surfaces new bugs, those open iter-005. |

## Routing Policy

| Lens Scope | Requested Reasoning / Review Class | Effective Class (when run) | Override / Approval Record | Notes |
| --- | --- | --- | --- | --- |
| UX improvement review | standard | Manual test by user (canonical review boundary for UX) | n/a | User runs `specrew start` (no `--host`) and `specrew host list` against the updated build; their feedback is the review verdict. |

## Traceability Summary

- Task coverage: 3 tasks for 3 user-surfaced concerns + 1 proactive (BinaryAliases). All traced to FR-011 or FR-013 or general UX scope.
- Traceability check: PASS at plan-boundary (will re-verify at tasks-boundary if scope shifts).
- Overcommit guardrail: 3/20 SP = 15% capacity. Plenty of headroom.

## Notes

- **Methodology dogfood**: This is iter-004's first commit — the plan. iter-001-003 had no live `state.md` because they were backfilled. iter-004 starts with `Status: planning`, advances to `executing` on first task pickup, to `reviewing` after T003 closes, to `complete` after user signoff.
- **Bug 7e (Copilot 3-skill loader failure)** intentionally NOT in iter-004 scope — needs reproduction against current Copilot CLI which the user can't do until weekly quota refills (per iter-003 retro deferral).
- **User's antigravity-on-WSL finding** confirms current detection logic is environment-scoped correctly: agy is in WSL PATH but not Windows PATH, so Windows-side `Get-Command agy` returns null. This is correct behavior — Specrew probes the shell it's running in. No code change needed for cross-environment detection (that would be a separate proposal-scale feature).
