# Iteration Plan: 009

**Schema**: v1
**Spec**: [../../spec.md](../../spec.md)
**Status**: retro
**Capacity**: 17.50/20 story_points
**Started**: 2026-06-28

<!--
  Validator schema (canonical):
  - Iteration Status: planning | executing | reviewing | retro | complete | abandoned
  - Capacity: `<consumed>/<cap> <unit>` with NO trailing prose.
  - Task Status: planned | in-progress | done | needs-rework | deferred | blocked
-->

## Scope Summary

Reviewer robustness (graceful degradation). Live EnglishIntake field evidence showed the worktree co-reviewer is field-unstable on real change-sets: a large diff times out -> "no parseable findings" -> the review-signoff gate deadlocks; `--host` is silently overridden; the configured timeout is unenforced (1200s ran 1h12m). Maintainer ruling 2026-06-28: **any review is better than nothing; the gate must never hard-deadlock.** R1-R6 = FR-033..FR-038 + SC-024 extend the existing worktree pipeline at named seams (no new architecture). Sequenced in 4 phases by leverage (R5 hard-timeout first).

| Requirement / Issue | Summary |
| ------------------- | ------- |
| FR-037 (R5) | Hard timeout = a real wall (watchdog + process-tree kill + stdio-redirect + graceful flush; WSL-validated). |
| FR-033 (R1) | Harvest partial findings on timeout (incremental emission + prose-salvage floor). |
| FR-038 (R6) | Human remediation menu (more time / host / narrow scope / accept / override). |
| FR-035 (R3) | Human-gated host-independence fallback (labelled same-host fallback; never block). |
| FR-034 (R2) | Human-gated time extension (post-hoc + pre-flight budget heuristic). |
| FR-036 (R4) | Tiered degraded-evidence gate (full+independent auto; partial/same-host need recorded ack; never deadlock). |
| SC-024 | Never-deadlock acceptance: a timed-out run yields partial findings + menu; gate never blocks on "no parseable verdict". |

## Tasks

| Task | Title | Requirement | Story | Effort | Owner | Owner File Globs | Status |
| ---- | ----- | ----------- | ----- | ------ | ----- | ---------------- | ------ |
| T091 | Hard timeout = a real wall: CONSOLIDATE the inline reviewer spawn onto the existing iter-005 isolated-task supervisor (one cross-platform watchdog: deadline poll + `Stop-Process -Force` + process-tree kill); instrument the live escape FIRST; remove worktree-reviewer.ps1's duplicate inline `$proc.Kill($true)`; stdio-redirect; 5s graceful flush; WSL-validated (hard gate). | FR-037, SC-024, NFR-001 | Hard timeout | 3.00 | Implementer | `scripts/internal/continuous-co-review/worktree-reviewer.ps1`; `scripts/internal/agent-tasks/isolated-task-supervisor.ps1`; `scripts/internal/agent-tasks/isolated-task-launcher.ps1`; `scripts/internal/agent-tasks/process-tree.ps1`; `tests/continuous-co-review/**` | deferred |
| T090 | Harvest partial findings: reviewer instruction contract emits each finding incrementally (one JSON object per line to a findings file); harvest the clean prefix on kill; prose-salvage floor. | FR-033, SC-024, NFR-001 | Partial harvest | 2.50 | Implementer | `scripts/internal/continuous-co-review/worktree-review-orchestrator.ps1`; `scripts/internal/continuous-co-review/worktree-reviewer.ps1`; `tests/continuous-co-review/**` | done |
| T096 | Remediation menu at the next Stop (more time / different host / narrow scope code-process-file-function / accept partial / override); carry the choice via co-review-round-state.json; honour the human-directed scope. | FR-038, FR-024, FR-025 | Remediation menu | 3.00 | Implementer | `scripts/internal/continuous-co-review/continuous-co-review-navigator.ps1`; `extensions/specrew-speckit/scripts/specrew-co-review-navigator-provider.ps1`; `tests/continuous-co-review/**` | deferred |
| T093 | Host-independence fallback: pre-flight independence check; fire labelled same-host fallback immediately (never block); the answer upgrades the next run; honour-or-surface --host. | FR-035, FR-016, SEC-004 | Host fallback | 1.50 | Architect | `scripts/internal/continuous-co-review/reviewer-selection-policy.ps1`; `scripts/internal/continuous-co-review/reviewer-authorization-gate.ps1`; `tests/continuous-co-review/**` | deferred |
| T092 | Time-extension gate: post-hoc "more time" menu option + pre-flight generous-budget heuristic for large diffs. | FR-034, NFR-002 | Time extension | 1.50 | Implementer | `scripts/internal/continuous-co-review/worktree-review-orchestrator.ps1`; `scripts/internal/continuous-co-review/worktree-reviewer.ps1`; `scripts/internal/continuous-co-review/continuous-co-review-navigator.ps1`; `tests/continuous-co-review/**` | done |
| T094 | Tiered degraded-evidence gate: 3-dimension label (completeness/independence/budget); full+independent auto; partial/same-host need a recorded first-class ack verdict; never deadlock; degraded-block override with recorded reason. | FR-036, SC-019, SC-020, SC-024 | Degraded gate | 2.50 | Reviewer | `scripts/internal/continuous-co-review/review-signoff-evidence-gate.ps1`; `scripts/internal/continuous-co-review/inline-review-gate-evaluator.ps1`; `tests/continuous-co-review/**` | deferred |
| T095 | Resolve the T083-T085 collision: renumber the iter-008 Dogfood Repair Addendum to T087-T089 (iter-006's commit-cited T083-T086 stay canonical). Governance hygiene; non-requirement. | governance | Collision cleanup | 0.50 | Spec Steward | `specs/197-continuous-co-review/iterations/008/**`; `specs/197-continuous-co-review/tasks.md` | done |
| T097 | R7/Phase-1 detach leak fix: clear HANDLE_FLAG_INHERIT on stdout/stderr before the detached spawn (Windows; Unix verified clean 2.8s) so the review cannot inherit the dispatcher's pipe; fail-open + WARN; revert T092's AUTO generous-budget bump (generous stays manual-`--live`). | FR-039, FR-040, SC-025 | Detach leak fix | 2.00 | Implementer | `co-review-service.ps1`; `worktree-review-orchestrator.ps1`; `tests/continuous-co-review/integration/detached-spawn-no-block.Tests.ps1` | done |
| T098 | R8 revert the unconfirmed flush-race conformance re-read (4x tail-200 parse, ~17s on a large transcript) that taxed every material stop + starved the navigator's Stop budget. | FR-040, SC-025 | Re-read revert | 1.00 | Implementer | `specrew-conformance-provider.ps1` + `.specify` mirror | done |

## Effort Model

| Setting | Value | Notes |
| ------- | ----- | ----- |
| Effort Unit | story_points | Unit used in task effort, capacity, and retro variance. |
| Capacity per Iteration | 20 | Maximum planned effort before overcommit guidance applies. |
| Iteration Bounding | scope | `scope` keeps requirements fixed; time varies. |
| Time Limit (hours) | n/a | Not used for this scope-bounded iteration. |
| Overcommit Threshold | 1.0 | Planned effort must stay at or below 20 story_points. |
| Defer Strategy | manual | Any overcommit requires explicit human deferral. |
| Calibration Enabled | true | Retro compares planned and actual effort. |

## Traceability Summary

- In-scope: FR-033..FR-038 (R1-R6) + SC-024 (never-deadlock acceptance). PLUS the R7/R8 scope-expansion (dogfood D-197-I009-005, maintainer-authorized 2026-06-28): FR-039 (detached process lifecycle) + FR-040 (Stop-hook performance) + SC-025.
- Bidirectional: every FR-033..FR-040 + SC-024/SC-025 has a covering task; every requirement-driven task (T090-T094, T096, T097, T098) traces to at least one FR/SC. T095 is governance hygiene (non-requirement). PASS.
- R7/R8 SCOPING FLAG: Phase-1 fixes T097 + T098 are in iter-009 (within cap). The remainder — T099 (gate the conformance parse, 1.5 SP) + T100 (Phase-2 robust supervisor: activity-watchdog + Job/cgroup atomic kill + session-scoped launcher, 4.0 SP) — is flagged for a fresh **iter-010**: folding it into iter-009 overcommits it to 23/20. Maintainer scoping decision pending.
- Capacity status: PASS, 17.50/20 story_points.

## Acceptance gates

- **R5 WSL-validation (hard gate)**: the hard timeout + process-tree kill proven on WSL, not Windows-only; a configured timeout actually kills the reviewer tree with no orphaned children.
- **Never-deadlock**: a timed-out review yields harvestable partial findings + the remediation menu; the signoff gate never blocks on "no parseable verdict".
- **Deploy-completeness smoke**: the degraded paths fire in a deployed consumer project, not only self-host unit tests.
- **Degraded-evidence honesty**: a `partial` / `same-host` signoff records a first-class human ack verdict in the evidence trail.
- **R5 (FR-037) closure DEFERRED to iter-010** (co-review escalation, drift-log D-197-I009-006): the WSL-validation of the live-inline-path tree-kill (a configured timeout kills the reviewer tree with no orphaned children) + a genuine consolidation-or-reword of T091 are owed in iteration 010 alongside T099/T100.

## Notes

- No new architecture; R1-R6 extend the existing worktree pipeline at named seams (the design-analysis component map).
- No new dependencies; PowerShell 7.x + Pester 5.5. No F-184 protected-surface edits.
- Deferred: automated live cross-host CI (Proposals 181/194); the lifecycle-pointer / state-truth durable fix (Proposals 142/193, a separate feature after F-197); the iter-008 plan.md backfill + closed-index rebuild.
