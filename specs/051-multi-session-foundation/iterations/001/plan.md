# Iteration Plan: 001 (Stub)

**Schema**: v1
**Spec**: [../../spec.md](../../spec.md)
**Status**: planning
**Capacity**: 0/20 story_points
**Started**: 2026-05-31
**Completed**:

<!--
  Validator schema (canonical, enforced by validate-governance.ps1):
  - Iteration Status MUST be one of:
      planning | executing | reviewing | retro | complete | abandoned
    (Common mistakes the validator REJECTS: `approved`, `in-progress`, `done`, `ready`.)
  - Capacity format MUST be `<consumed>/<cap> <effort_unit>` with NO trailing prose on that line.
    Append explanatory notes in the Notes section at the bottom instead.
  - Task Status (in the Tasks table) MUST be one of:
      planned | in-progress | done | needs-rework | deferred | blocked
    (Note `in-progress` uses a hyphen, not an underscore. `done` not `completed`.)
-->

## Scope Summary

| Requirement | Summary | Stories |
| ----------- | ------- | ------- |
| FR-001 | System MUST provide a `session_mode` configuration flag in `.specrew/config.yml` with two valid values: `single` and `multi` | — |
| FR-002 | System MUST provide a CLI command `specrew config set session_mode <value>` that updates `.specrew/config.yml` and validates the value is either `single` or `multi` | — |
| FR-003 | System MUST default to `single` session mode when no explicit `session_mode` is configured | — |
| FR-004 | System MUST classify Specrew-managed files into four categories: shared (must be committed and identical across developers), per-session (must be gitignored), append-only-shared (committed with atomic append discipline), and regenerable (generated from shared sources) | — |
| FR-005 | System MUST generate or update `.gitignore` during `specrew init` or when file classification changes to exclude per-session files: `.specrew/last-*`, `.specify/feature.json`, `.specrew/start-context.json`, `.specrew/host-history.json`, `.specrew/.cache/`, `.squad/sessions/`, `.squad/decisions/inbox/`, `.specrew/last-validator-summary.json` | — |
| FR-006 | System MUST remove previously tracked per-session files from git index using `git rm --cached` when file classification is applied | — |
| FR-007 | System MUST maintain a `.specrew/active-sessions.yml` file containing active session entries with fields: feature_id, user, machine_fingerprint, session_start_time, last_heartbeat_time | — |
| FR-008 | System MUST add an entry to `.specrew/active-sessions.yml` when a `specrew start` session begins | — |
| FR-009 | System MUST remove an entry from `.specrew/active-sessions.yml` when a session ends normally | — |
| FR-010 | System MUST detect when starting a session for a feature that already has an active entry in `.specrew/active-sessions.yml` and display a warning to the developer | — |
| FR-011 | System MUST automatically clear stale lock entries (last_heartbeat_time older than 24 hours) from `.specrew/active-sessions.yml` when a new session starts. Rationale: 24-hour threshold balances safety (preserving multi-day feature branches and developer breaks) against clearing obviously-dead sessions and unblocking worktrees. Configurable via `.specrew/config.yml` `stale_lock_threshold_hours` if needed (optional, defaults to 24). | — |
| FR-012 | System MUST maintain a `.squad/active-features.yml` file containing feature claims with fields: feature_id, claimed_by (user@machine), claim_start_time, last_refresh_time, branch_name | — |
| FR-013 | System MUST add a claim entry to `.squad/active-features.yml` when a developer crosses the specify boundary for a feature | — |
| FR-014 | System MUST update the `last_refresh_time` in the feature claim when lifecycle boundaries are crossed (specify, plan, tasks, implement, review, retro) | — |
| FR-015 | System MUST detect when a developer attempts to claim a feature that is already claimed by another developer and display a Layer 1 warning with claim details and option to continue | — |
| FR-016 | System MUST remove a claim from `.squad/active-features.yml` when the feature-closeout boundary sync runs and the feature is merged to main | — |
| FR-017 | System MUST split `.squad/decisions.md` into per-iteration files under `.squad/decisions/iteration-NNN/decisions.md` when in multi-session mode | — |
| FR-018 | System MUST use JSON Lines format (one JSON object per line) for append-only log files to enable atomic appends and mechanical conflict resolution | — |
| FR-019 | System MUST alphabetically sort the `Specrew.psd1` FileList array during boundary-sync writes to minimize merge conflicts | — |
| FR-020 | System MUST detect multi-developer activity signals: multiple git author emails in recent history (last 90 days), multiple machine fingerprints in session state writes, multiple concurrent session-state file writes, branch fan-out pattern (3+ feature branches diverging from same base) | — |
| FR-021 | System MUST display a multi-session recommendation message during Welcome Orientation when multi-developer signals are detected and session_mode is `single` | — |
| FR-022 | System MUST display a multi-developer indicator in the `specrew where` dashboard when signals are detected, including count of unique developers and machines | — |
| FR-023 | System MUST include multi-developer activity note in boundary-sync output when signals are detected | — |
| FR-024 | System MUST suppress multi-session recommendations when `session_mode` is already set to `multi` | — |
| FR-025 | System MUST provide a command or automated process to upgrade the project's Spec-Kit installation from version 0.8.13 to 0.8.18 | — |
| FR-026 | System MUST detect how Spec-Kit is installed in the current project (npm package, deployed extension directory, manual files) | — |
| FR-027 | System MUST identify the appropriate upgrade mechanism based on the installation method detected | — |
| FR-028 | System MUST execute the upgrade while preserving local configuration and customization in `.specify/` directories | — |
| FR-029 | System MUST update `.specrew/config.yml` `speckit_version` field to `"0.8.18"` after successful upgrade | — |
| FR-030 | System MUST validate that Specrew functions correctly with Spec-Kit 0.8.18 after upgrade by running the governance validator | — |
| FR-031 | System MUST fix the `specrew update` command to write the installed Specrew module version to `.specrew/config.yml` `specrew_version` field | — |
| FR-032 | System MUST detect the installed Specrew module version from PowerShell module metadata (Get-Module or Get-InstalledModule) | — |
| FR-033 | System MUST display a drift warning during `specrew start` when installed Specrew version differs from `.specrew/config.yml` `specrew_version` | — |
| FR-034 | System MUST support a `--dry-run` flag for `specrew update` that shows proposed changes without modifying files | — |
| FR-035 | System MUST split `.squad/identity/now.md` to separate git-tracked shared content (focus_area, body) from per-session transient fields (session_state_active, session_state_boundary, session_state_feature_path, session_state_iteration, session_state_auth_commit, session_state_recorded_at) | — |
| FR-036 | System MUST create a new gitignored split file (`.squad/identity/session-state.yml` or `.squad/identity/session-state.json`) to hold per-session transient fields, with an entry in `.gitignore` for the new file pattern | — |
| FR-037 | System MUST include migration logic that strips existing session_state_* fields from `.squad/identity/now.md` and writes them to the new split file, then commits the change to now.md | — |
| FR-038 | System MUST validate at specrew start that the split between shared and per-session content is enforced; git-tracked files MUST NOT contain session_state_* fields (detector: grep for `session_state_` in tracked files and error if any are found). The gitignored session-state file may contain these fields. | — |
| FR-039 | System MUST detect brand-new worktree condition at `specrew start` using these heuristic signals: empty `.specrew/active-sessions.yml` (or missing file), no recent boundary commits on the current feature branch, and no iteration directories matching the inherited feature_path under `specs/<feature>/iterations/` | — |
| FR-040 | System MUST skip the stale-state recovery A/B/C prompt when brand-new condition is detected and proceed directly to new-feature specify flow | — |
| FR-041 | System MUST preserve the A/B/C recovery prompt when state is genuinely inconsistent (e.g., feature_path on inherited state does not match current branch AND iteration directories exist for that path), detecting this condition by comparing inherited feature_path with current branch name and checking for local iteration evidence | — |
| FR-042 | System MUST log all brand-new detection signals and decisions to `.specrew/session-start.log` for debugging purposes, including timestamp, detected signals, and decision rationale (brand-new vs. recovery needed) | — |
| FR-043 | Machine fingerprinting for session state MUST be local-only and MUST NOT be transmitted over the network; fingerprints are used only for in-project collision detection and multi-developer signal aggregation | — |

## Tasks

| Task | Title | Requirement | Story | Effort | Owner | Owner File Globs | Status | Agent | Actual | Verdict |
| ---- | ----- | ----------- | ----- | ------ | ----- | ---------------- | ------ | ----- | ------ | ------- |

## Effort Model

| Setting | Value | Notes |
| ------- | ----- | ----- |
| Effort Unit | story_points | Unit used in task effort, capacity, and retro variance. |
| Capacity per Iteration | 20 | Maximum planned effort before overcommit guidance applies. |
| Iteration Bounding | scope | `scope` keeps requirements fixed; `time` enforces a time ceiling. |
| Time Limit (hours) | n/a | Only applies when iteration bounding is `time`. |
| Overcommit Threshold | 1.0 | Warn planners when total estimated effort exceeds 20 story_points (capacity 20 x threshold 1.0). |
| Defer Strategy | manual | How planning should choose deferrals when the iteration is over capacity. |
| Calibration Enabled | true | When true, retrospectives should suggest future capacity adjustments. |

## Concurrency Rationale

- Current roster snapshot: Spec Steward, Planner, Implementer, Reviewer, Retro Facilitator
- Technology and scope signals: Mixed frontend and backend/service signals are present in the scoped requirements.
- Task dependency graph: detailed dependencies are still pending task decomposition in this stub; revisit once the task table is populated.
- Workstream separability: Conflict-heavy signals are present, so keep same-specialty work serial unless ownership boundaries become explicit.
- Shared-surface conflict risk: elevated due to shared-state / cross-cutting cues in scope text.
- Prior reviewer ownership/hotspot evidence: No prior reviewer hotspot signals were found for this feature.
- Recommendation: do not propose Junior/Senior same-specialty expansion until the task table and ownership boundaries make safe parallelism explicit. If a same-specialty pair is approved later, record `Owner File Globs` for the parallel tasks or keep the work serial.

## Phase Baseline

| Phase | Estimated Effort | Notes |
| ----- | ---------------- | ----- |
| Planning | TBD | Populate after task decomposition and approval gating |
| Discovery/Spikes | TBD | Capture any required risk-reduction work revealed during planning |
| Implementation | TBD | Sum planned delivery tasks once the task table is complete |
| Review | TBD | Estimate review/demo effort after verdict flow is defined |
| Rework | TBD | Expected needs-work buffer if review finds gaps |

## Traceability Summary

- Requirement scope for this stub: FR-001, FR-002, FR-003, FR-004, FR-005, FR-006, FR-007, FR-008, FR-009, FR-010, FR-011, FR-012, FR-013, FR-014, FR-015, FR-016, FR-017, FR-018, FR-019, FR-020, FR-021, FR-022, FR-023, FR-024, FR-025, FR-026, FR-027, FR-028, FR-029, FR-030, FR-031, FR-032, FR-033, FR-034, FR-035, FR-036, FR-037, FR-038, FR-039, FR-040, FR-041, FR-042, FR-043
- User stories represented in current scope:
- Pending detailed planning: populate the task table, then run specrew-capacity-planning and specrew-traceability-check before approval.
- Overcommit guardrail: compare planned task effort against the configured threshold and record any required deferrals from the lowest-priority requirement slices before leaving planning.

## Notes

- This stub captures the planned scope pending detailed planning in the Specrew Planning ceremony.
- Add task rows only for work that is traceable to the scoped requirements above.
- Keep Status: planning until the plan is fully decomposed and approved.
- If task effort exceeds the configured threshold, make the deferral decision explicit in this plan before execution starts and name the lowest-priority requirement slices proposed for deferral.
