---
focus_area: "Between features — F-049 shipped (v0.28.0 stable) + F-050 shipped (v0.29.0 stable, PR #1226 merged); F-051 (Multi-Session Foundation + Spec-Kit upgrade 0.8.13->0.8.18 + specrew update baseline bug-fix) queued; two parallel Crew shells about to start"
active_issues: "[]"
schema: v1
updated_at: 2026-05-31T12:39:13Z
session_state_active: true
session_state_boundary: review-signoff
session_state_feature: 051-multi-session-foundation
session_state_feature_path: "C:\Dev\Specrew-051\specs\051-multi-session-foundation"
session_state_iteration: "(none)"
session_state_task: "(none)"
session_state_auth_commit: 6b8132952c55e0c2b56d6be20b28853360d461ec
session_state_recorded_at: 2026-05-31T12:39:13Z
---

# What We're Focused On

**Between features.** F-050 (Cursor Host Package, Proposal 114) shipped as **v0.29.0 stable** on PSGallery (PR [#1226](https://github.com/alonf/specrew/pull/1226) merged 2026-05-30; merge commit `32c8290c`). F-049 (Pipeline Hardening + Substantive Intake, Proposals 120 + 141) shipped earlier 2026-05-30 as v0.28.0 stable.

## Next up — F-051 + parallel small-fix bundle

Per the canonical post-F-049 sequencing (user-locked 2026-05-30):

- **F-051 = Multi-Session Foundation + Spec-Kit upgrade + `specrew update` baseline bug-fix** — Proposal 010 Pillars 1+2 + 134 Pillars 1+3 + session-mode auto-detection + recommendation surface + Spec-Kit pin bump 0.8.13->0.8.18 + `specrew update` baseline-bump bug fix; ~40-58 SP, likely 3-iteration split
- **F-052 = Structured Multi-Phase Reviewer Skill** — Proposal 145, ~30-45 SP; ships after F-051
- **F-053 = Multi-Agent Subagent Orchestration V1** — Proposal 139, ~15-25 SP; ships after F-052
- **Parallel small-fix bundle alongside F-051:** Proposal 146 Refocus (5-8 SP), Proposal 138 Spec Kit Underutilized (8-15 SP), Proposal 011 Architecture Intent Checkpoint (10 SP optional), Proposal 147 Host Options (5-8 SP)

## Active sessions

About to start **two parallel Crew shells** for concurrent implementation. Feature selection pending. Each shell will own its own worktree + feature branch off main. F-050 served as the parallel-development pilot (Proposal 114 Charter Item 5); now scaling to 2 concurrent shells.

## Recent shipped history

- v0.29.0 — F-050 (Cursor Host Package); merged 2026-05-30 (PR #1226)
- v0.28.0 — F-049 (Pipeline Hardening + Substantive Intake; Proposals 120 + 141); merged 2026-05-30 (PR #1152)
- See [CHANGELOG.md](../../../CHANGELOG.md) for full history
