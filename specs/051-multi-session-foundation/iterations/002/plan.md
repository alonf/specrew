# Iteration Plan: 002 — Iteration 2a: Collision Detection & Feature Claims

**Schema**: v1
**Spec**: [../../spec.md](../../spec.md)
**Status**: complete
**Capacity**: 12/20 story_points
**Started**: 2026-05-31
**Completed**: 2026-05-31

<!--
  Validator schema (canonical, enforced by validate-governance.ps1):
  - Iteration Status MUST be one of:
      planning | executing | reviewing | retro | complete | abandoned
  - Capacity format MUST be `<consumed>/<cap> <effort_unit>` with NO trailing prose on that line.
  - Task Status MUST be one of: planned | in-progress | done | needs-rework | deferred | blocked
  - On-disk dir is 002 (zero-padded); the "Iteration 2a" label is prose only (validator/closed-index key == dir token "002").
-->

## Scope Summary

| Requirement | Summary | Stories |
| ----------- | ------- | ------- |
| FR-007 | `.specrew/active-sessions.yml` lock file (feature_id, user, machine_fingerprint, session_start/last_heartbeat) | US3 |
| FR-008 | Add a session entry when `specrew start` begins | US3 |
| FR-009 | Remove the entry when a session ends normally (approximated at feature-closeout) | US3 |
| FR-010 | Detect + warn on an existing active entry for the same feature | US3 |
| FR-011 | Auto-clear stale locks (last_heartbeat > 24h, configurable) at next start | US3 |
| FR-012 | `.squad/active-features.yml` claims (feature_id, claimed_by, claim_start, last_refresh, branch_name) | US4 |
| FR-013 | Add a claim at the specify boundary | US4 |
| FR-014 | Refresh `last_refresh_time` at every boundary | US4 |
| FR-015 | Layer-1 warning + continue/decline on a concurrently-claimed feature | US4 |
| FR-016 | Remove the claim at feature-closeout when merged to main | US4 |
| FR-043 | Machine fingerprint local-only (population-side; no-network VALIDATION test stays in Iteration 4) | US3 |

**Decisions blessed at plan-time (2026-05-31, see spec Clarifications + drift D-003):** the lock file is per-session/gitignored and catches same-machine/worktree concurrent starts; **cross-machine** collision (US3 scenario 1) is the committed claims file's job (FR-015). The rich `machine_fingerprint` stays only in the gitignored lock; the committed claim carries only coarse `user@machine` (FR-043). Out of scope for 2a: conflict-reduction + auto-detection (Iter 2b), upgrade (Iter 3), identity split (Iter 4).

## Tasks

| Task | Title | Requirement | Story | Effort | Owner | Owner File Globs | Status | Agent | Actual | Verdict |
| ---- | ----- | ----------- | ----- | ------ | ----- | ---------------- | ------ | ----- | ------ | ------- |
| T020 | session-management.ps1 + EXTRACT shared atomic-write helper + FileList | FR-007 | US3 | 1.0 | Implementer | `scripts/internal/session-management.ps1`, `scripts/internal/atomic-write.ps1`, `scripts/internal/session-config.ps1`, `Specrew.psd1` | done | codex | 1.0 | pass |
| T020b | Get-MachineFingerprint local-only helper (FR-043 population) | FR-007, FR-043 | US3 | 0.5 | Implementer | `scripts/internal/session-management.ps1` | done | codex | 0.5 | pass |
| T020c | Add active-sessions.yml to gitignore patterns + record D-003 | FR-005, FR-007 | US3 | 0.5 | Implementer | `scripts/internal/file-classification.ps1`, `specs/051-multi-session-foundation/iterations/002/drift-log.md` | done | codex | 0.5 | pass |
| T021 | Register-SessionLock at start (atomic) | FR-008 | US3 | 1.0 | Implementer | `scripts/internal/session-management.ps1`, `scripts/specrew-start.ps1` | done | codex | 1.0 | pass |
| T022 | Remove-SessionLock at feature-closeout | FR-009 | US3 | 0.5 | Implementer | `scripts/internal/session-management.ps1`, `scripts/internal/sync-boundary-state.ps1` | done | codex | 0.5 | pass |
| T023 | Test-SessionCollision + start-time warning | FR-010 | US3 | 1.0 | Implementer | `scripts/internal/session-management.ps1`, `scripts/specrew-start.ps1` | done | codex | 1.0 | pass |
| T024 | Clear-StaleSessionLocks (24h, atomic RMW) | FR-011 | US3 | 1.0 | Implementer | `scripts/internal/session-management.ps1`, `scripts/specrew-start.ps1` | done | codex | 1.0 | pass |
| T025 | Acceptance: collision within 2s (real temp repo) | FR-010 | US3 | 0.5 | Implementer | `tests/` | done | codex | 0.5 | pass |
| T026 | Acceptance: stale-lock clear + corrupt-YAML safe-degradation | FR-011 | US3 | 0.5 | Implementer | `tests/` | done | codex | 0.5 | pass |
| T026b | Acceptance: deterministic atomic-write/race (Edge Case) | FR-007, FR-012 | US3 | 0.5 | Implementer | `tests/` | done | codex | 0.5 | pass |
| T027 | feature-claims.ps1 (reuse shared atomic-write) + FileList | FR-012 | US4 | 1.0 | Implementer | `scripts/internal/feature-claims.ps1`, `Specrew.psd1` | done | codex | 1.0 | pass |
| T028 | Add-FeatureClaim at specify boundary (upsert) | FR-013 | US4 | 0.5 | Implementer | `scripts/internal/feature-claims.ps1`, `scripts/internal/sync-boundary-state.ps1` | done | codex | 0.5 | pass |
| T029 | Update-FeatureClaim (monotonic refresh) every boundary | FR-014 | US4 | 0.5 | Implementer | `scripts/internal/feature-claims.ps1`, `scripts/internal/sync-boundary-state.ps1` | done | codex | 0.5 | pass |
| T030 | Concurrent-claim Layer-1 warning + continue/decline | FR-015 | US4 | 1.0 | Implementer | `scripts/internal/feature-claims.ps1`, `scripts/specrew-start.ps1` | done | codex | 1.0 | pass |
| T031 | Remove-FeatureClaim at closeout-when-merged | FR-016 | US4 | 0.5 | Implementer | `scripts/internal/feature-claims.ps1`, `scripts/internal/sync-boundary-state.ps1` | done | codex | 0.5 | pass |
| T032 | Acceptance: claim lifecycle + refresh + re-add | FR-013, FR-014, FR-016 | US4 | 0.5 | Implementer | `tests/` | done | codex | 0.5 | pass |
| T033 | Acceptance: concurrent-claim warning variants | FR-015 | US4 | 0.5 | Implementer | `tests/` | done | codex | 0.5 | pass |
| T033b | 2a validation: run suite + validator-as-audit + coverage-evidence + data-model reconcile | FR-007, FR-016 | US3 | 0.5 | Reviewer | `specs/051-multi-session-foundation/iterations/002/`, `scripts/internal/sync-boundary-state.ps1` | done | codex | 0.5 | pass |

## Effort Model

| Setting | Value | Notes |
| ------- | ----- | ----- |
| Effort Unit | story_points | Unit used in task effort, capacity, and retro variance. |
| Capacity per Iteration | 20 | Maximum planned effort before overcommit guidance applies. |
| Iteration Bounding | scope | `scope` keeps requirements fixed; `time` enforces a time ceiling. |
| Time Limit (hours) | n/a | Only applies when iteration bounding is `time`. |
| Overcommit Threshold | 1.0 | Warn when total estimated effort exceeds 20 story_points. |
| Defer Strategy | manual | How planning chooses deferrals when over capacity. |
| Calibration Enabled | true | Retrospectives suggest future capacity adjustments. |

## Concurrency Rationale

- Roster: baseline 5 (Spec Steward, Planner, Implementer, Reviewer, Retro Facilitator). The required **security/concurrency review lens** fires at this iteration's before-implement gate (first iteration with a concurrent-write + identity-bearing surface); no standing Security Specialist member is added for this 12 SP slice.
- Critical path: **T020 (module + shared atomic-write extraction)** gates T021-T026b AND T027 (claims reuse the extracted `Write-SpecrewFileAtomic`). T020b gates T021. T020c is independent/parallel.
- Two subsystems — Session Management (T020-T026b) + Feature Claims (T027-T033) — are otherwise parallelizable.
- Shared-surface conflict risk: `scripts/specrew-start.ps1` (T021/T023/T024/T030) and `scripts/internal/sync-boundary-state.ps1` (T022/T028/T029/T031) are each touched by multiple tasks — serialize those edits or single-owner them. **No new `specrew-<cmd>.ps1` or `specrew.ps1` dispatch case** is added in 2a, so no fresh D-002 path drift.
- Recommendation: single-developer serial execution; no Junior/Senior expansion for this slice.

## Phase Baseline

| Phase | Estimated Effort | Notes |
| ----- | ---------------- | ----- |
| Planning | done | Plan-time workflow refined 10→12 SP; decisions blessed; hardening gate authored |
| Discovery/Spikes | 0 | Mechanisms decided in research.md (R2 fingerprint, R3 atomic write, R4 24h threshold) |
| Implementation | ~8.5 SP | T020-T024, T027-T031 delivery |
| Review | ~2 SP | T025/T026/T026b/T032/T033 acceptance + review-signoff |
| Rework | ~1.5 SP | Buffer if the security/concurrency lens finds gaps |

## Traceability Summary

- Requirement scope: FR-007 through FR-016 (+ FR-043 population-side).
- User stories: US3 (Detect Concurrent Session Collisions), US4 (Claim Features to Prevent Overlap).
- Success criteria: SC-002 (collision warning within 2s), SC-008 (claim refresh 100% at boundaries).
- All 18 tasks (T020-T033b) map to ≥1 FR; all 10 in-scope FRs (007-016) have ≥1 task. Capacity 12/20 SP — within cap.

## Notes

- Capacity 12 SP is the honest plan-time re-sum (planning workflow 2026-05-31), refining TG-003's original 10. +4 sub-tasks (T020b fingerprint, T020c gitignore-fix, T026b race test, T033b 2a validation) the prior decomposition missed.
- Lifecycle status follows the `Status` field above; this artifact is currently `complete` because implementation, review-signoff, retro, and iteration-closeout are complete.
- Retro carry-forward: fix the iteration-plan and iteration-state scaffold/template sources that emitted stale lifecycle boilerplate in both Iteration 1 and Iteration 2, so future plans/states do not require review-time prose repair.
- On-disk dir is `002`; pass `-IterationNumber 002` (quoted) to every boundary sync (retro action 8 — avoid the iter-1 non-padded bug). Keep the "Iteration 2a" label in artifact titles for spec/tasks traceability.
