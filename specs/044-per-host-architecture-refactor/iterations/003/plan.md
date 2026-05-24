# Iteration Plan: 003

**Schema**: v1
**Spec**: [../../spec.md](../../spec.md)
**Status**: complete
**Capacity**: 4/20 story_points
**Started**: 2026-05-24
**Completed**: 2026-05-24

> **Note**: This plan is closer to live than iter-001/002's backfills because iter-003's bugs were captured live from the user's manual dogfood, but SP estimates and Phase Baseline were authored at closeout, not at iter-003 plan-boundary. Future iterations should fully live-track plan + execute + close.

## Scope Summary

Focused **manual-test repair slice** addressing 5 of 6 Tier A bugs caught by the user's first end-to-end multi-host dogfood (Copilot + Claude + Codex on greenfield stopwatch projects). The 6th (Codex `--full-auto` flag) was confirmed already-fixed on branch — user's test loaded stale 0.24.1 PSGallery install.

Demonstrates the **dogfood-discovers-bug → fix-slice closes-it** pattern at the strongest review boundary: a real human running real workloads.

| Requirement | Summary | Stories |
| --- | --- | --- |
| FR-007 | Specrew-managed marker — generic skills now consistent with frontmatter shape (Bug 2) | US3, US4 |
| FR-012 | Documentation — bootstrap message host-aware (Bug 5) | US5 |
| FR-013 | (tooling) — hardening-gate, retro-scaffold, closeout-dashboard generator fixes (Bugs 7b/7c/7d) | (tooling) |

## Tasks

| Task | Title | Requirement | Story | Effort | Owner | Owner File Globs | Status | Agent | Actual | Verdict |
| ---- | ----- | ----------- | ----- | ------ | ----- | ---------------- | ------ | ----- | ------ | ------- |
| T001 | Bug 2 — add YAML frontmatter to `iteration-resume` skill template | FR-007 | US3, US4 | 0.5 | Implementer | extensions/specrew-speckit/squad-templates/skills/iteration-resume.md | done | claude | 0.5 | pass |
| T002 | Bug 5 — rewrite bootstrap "Usage Flow" + "Next Steps" to Crew-neutral; surface canonical team path | FR-012 | US5 | 1 | Implementer | scripts/init/post-bootstrap-output.ps1 | done | claude | 1 | pass |
| T003 | Bug 7c — `run-hardening-gate.ps1` defensive null handling for empty ExistingLines | FR-013 | (tooling) | 1 | Implementer | extensions/specrew-speckit/scripts/run-hardening-gate.ps1 | done | claude | 1 | pass |
| T004 | Bug 7b — `scaffold-retro-artifact.ps1` graceful Phase Baseline fallback (warn instead of throw) | FR-013 | (tooling) | 0.5 | Implementer | extensions/specrew-speckit/scripts/scaffold-retro-artifact.ps1 | done | claude | 0.5 | pass |
| T005 | Bug 7d — `scaffold-feature-closeout-dashboard.ps1` PassThru removal + numeric-only FeatureId prefix-match | FR-013 | (tooling) | 1 | Implementer | extensions/specrew-speckit/scripts/scaffold-feature-closeout-dashboard.ps1 | done | claude | 1 | pass |

## Effort Model

| Setting | Value | Notes |
| --- | --- | --- |
| Effort Unit | story_points | Same as iter-001/002. |
| Capacity per Iteration | 20 | Specrew project default. |
| Iteration Bounding | scope | All 5 Tier A bugs in scope. Tier B (UX) + Tier C (methodology depth) deferred. |
| Time Limit (hours) | n/a | Scope-bounded. |
| Overcommit Threshold | 1.0 | 4/20 = 0.2 — well under threshold. |
| Defer Strategy | manual | 6 deferrals (Bugs 1, 3, 4, 6, 7e, 8 + dual-install) explicitly noted in [scope.md](./scope.md). |
| Calibration Enabled | true | Future iterations should live-track. |

## Concurrency Rationale

- Same roster; serial execution because all 5 bugs touch different files (no shared-surface conflict, but no benefit from parallelism either since 4 SP total).
- Single-commit close (`18bfaeab`).

## Phase Baseline

| Phase | Estimated Effort | Notes |
| --- | --- | --- |
| Planning | 0.5 | Triage of 9 user-reported bugs into Tier A/B/C; root-cause verification per bug. |
| Discovery/Spikes | 0.5 | Confirmed Bug 7a was stale-install false positive (read codex/handlers.ps1:101 before "fixing"). |
| Implementation | 3 | T001 through T005. |
| Review | 0 | Verification deferred to user's next manual-test round — that round IS this iteration's functional review boundary. |
| Rework | 0 | No rework in iter-003 itself; rework potential lives in iter-004. |

## Routing Policy

| Lens Scope | Requested Reasoning / Review Class | Effective Class (when run) | Override / Approval Record | Notes |
| --- | --- | --- | --- | --- |
| Repair slice review | standard | Parse-check + self-review + advisor consultation deferred | n/a | Functional verification deferred to user's iter-004 manual-test round; that round IS the review boundary. |

## Traceability Summary

- Task coverage: 5 tasks address 5 Tier A bugs (1:1 mapping). 1 already-fixed bug (7a) verified no-op.
- Traceability check: PASS via [scope.md](./scope.md) bug-to-task table.
- Overcommit guardrail: 4/20 SP = 20%. Repair slices are intentionally small; iter-004 will live-track to start building actual velocity data.

## Notes

- Real review boundary: user's iter-004 manual-test round. Each fix has a documented reproduction scenario in [review.md](./review.md).
- User pre-test step: remove stale `0.24.1` PSGallery install before iter-004 testing — otherwise the dual-module-load will mask which version actually ran. See iter-003 review.md § "Recommended user pre-test step".
- Deferred to standing proposals (per [scope.md](./scope.md) § "Out of iter-003 scope"): Bug 1 → Proposal 063 or small-fix slice; Bug 3 + Bug 4 → Proposal 063 / 065; Bug 6 → Proposal 024 Category D; Bug 7e → investigation slice; Bug 8 → Proposal 068; dual-install → Proposal 060 small-fix slice.
- This plan IS the methodology fix the user requested ("Story Points... it looks like it got lost"). Specrew tooling has SP intact; my retroactive backfill of iter-001/002/003 dropped it. This commit restores the canonical contract for all 4 backfilled iterations (this + F-043 iter-001 + F-044 iter-001 + F-044 iter-002).
