# Iteration Plan: 005

**Schema**: v1
**Spec**: [../../spec.md](../../spec.md)
**Status**: complete
**Capacity**: 8/20 story_points
**Started**: 2026-05-24
**Completed**: 2026-05-24

> Second LIVE-TRACKED iteration of F-044. Plan written before code; actuals filled at task close.

## Scope Summary

Pre-PR readiness slice. User-surfaced concerns from iter-004 dogfood:

1. **Antigravity launch fails** — `agy` rejects `-output-format` and `--cwd` flags. Per actual `agy --help` output: shape is `agy -i '<prompt>' --add-dir '<path>' [--dangerously-skip-permissions]`. The Spec FR-005 reference was wrong (or agy CLI evolved).
2. **Version bump to v0.27.0** — user picked option (a) status quo from the drift analysis.
3. **Test coverage** — iter-003 + iter-004 added code without automated tests; smoke tests live in `.scratch/` only.
4. **Doc audit** — README, getting-started, user-guide, proposals INDEX may have stale Squad-language or missing references to F-040/F-043/F-044/Proposal 108.
5. **Pre-PR readiness** — bundle is ready when antigravity launches + tests cover changes + docs reflect shipped state.

| Requirement | Summary | Stories |
| --- | --- | --- |
| FR-003 | `agy` launch shape correct (interactive) | US2 |
| FR-007 | Permission-bypass flag (`--dangerously-skip-permissions`) wired | US2 |
| FR-011 | Adding a new host requires zero edits — preserved; only Antigravity package edits | US4 |
| FR-012 | Documentation updated for shipped state | US5 |
| FR-013 | `tests/integration/host-detection-ux.tests.ps1` promoted from `.scratch/` | (testing) |

## Tasks

| Task | Title | Requirement | Story | Effort | Owner | Owner File Globs | Status | Agent | Actual | Verdict |
| ---- | ----- | ----------- | ----- | ------ | ----- | ---------------- | ------ | ----- | ------ | ------- |
| T001 | Fix `New-AntigravityLaunchInvocation` flag set: `-i` (interactive) + `--add-dir <path>` + `--dangerously-skip-permissions` (allow-all); drop `-p` / `--output-format` / `--cwd` | FR-003, FR-007 | US2 | 1.5 | Implementer | hosts/antigravity/handlers.ps1 | done | claude | 1.5 | pass |
| T002 | Bump `Specrew.psd1` ModuleVersion 0.26.0 → 0.27.0 + add CHANGELOG entry | (release) | (release) | 0.5 | Implementer | Specrew.psd1; CHANGELOG.md | done | claude | 0.5 | pass |
| T003 | Promote `.scratch/iter004-smoke.ps1` to `tests/integration/host-detection-ux.tests.ps1`; add iter-005 antigravity-launch shape assertion | FR-013 | (testing) | 1 | Implementer | tests/integration/host-detection-ux.tests.ps1 | done | claude | 1 | pass |
| T004 | Add `tests/integration/post-bootstrap-output.tests.ps1` asserting Crew-neutral language + canonical team path mentions (iter-003 Bug 5 regression test) | FR-013 | (testing) | 0.5 | Implementer | tests/integration/post-bootstrap-output.tests.ps1 | done | claude | 0.5 | pass |
| T005 | Add `tests/integration/skill-templates.tests.ps1` asserting all 11 skill templates have YAML frontmatter (iter-003 Bug 2 regression test) | FR-013 | (testing) | 0.5 | Implementer | tests/integration/skill-templates.tests.ps1 | done | claude | 0.5 | pass |
| T006 | Doc audit + updates — README.md host-language sweep, docs/getting-started.md multi-host section, docs/user-guide.md cross-reference verify | FR-012 | US5 | 2 | Implementer | README.md; docs/getting-started.md; docs/user-guide.md | done | claude | 2 | pass |
| T007 | `proposals/INDEX.md` — mark Proposal 108 shipped-as F-044; add F-043 entry (deferred to post-PR-merge chore per "proposals to main only" rule; verified entries missing from INDEX, queued for on-main work) | (docs) | US5 | 1 | Implementer | proposals/INDEX.md | done | claude | 0.5 | pass |
| T008 | Verification sweep — run validator, parse-check, full integration test suite, confirm green | (verify) | (release) | 1 | Reviewer | (verification only) | done | claude | 1 | pass |

## Effort Model

| Setting | Value | Notes |
| ------- | ----- | ----- |
| Effort Unit | story_points | |
| Capacity per Iteration | 20 | Project default. |
| Iteration Bounding | scope | All 8 tasks bounded by pre-PR-readiness criterion. |
| Time Limit (hours) | n/a | |
| Overcommit Threshold | 1.0 | 8/20 = 0.4 — well under threshold. |
| Defer Strategy | manual | If T006 doc sweep blows up >2 SP, surface to user. |
| Calibration Enabled | true | Second live-tracked iteration; calibration data accumulating. |

## Concurrency Rationale

- Roster snapshot: Spec Steward, Planner, Implementer, Reviewer, Retro Facilitator.
- 8 tasks across 7 disjoint files + 1 verification. T001-T005 + T007-T008 are independent; T006 spans multiple docs. Serial execution; no Junior/Senior pair.

## Phase Baseline

| Phase | Estimated Effort | Notes |
| ----- | ---------------- | ----- |
| Planning | 0.5 | This plan + agy-help reverse-engineering. |
| Discovery/Spikes | 0.5 | Confirmed agy actual flag set from user's CLI output (no spike needed — user provided the help text inline). |
| Implementation | 5.5 | T001 (1.5) + T002 (0.5) + T003 (1) + T004 (0.5) + T005 (0.5) + T006 (2) + T007 (0.5). |
| Review | 1 | T008 verification sweep — validator + parse-check + integration tests. |
| Rework | 0.5 | Buffer if a test fails or doc sweep surfaces a missed reference. |

## Routing Policy

| Lens Scope | Requested Reasoning / Review Class | Effective Class (when run) | Override / Approval Record | Notes |
| --- | --- | --- | --- | --- |
| Release-readiness review | standard | Self-review + validator + user manual test | n/a | User runs `specrew start --host antigravity` on a fresh project against the rebuild; their feedback is final verdict before PR-to-main. |

## Traceability Summary

- Task coverage: 8 tasks for 5 user-surfaced concerns + verification. All traced to FR-003/007/011/012/013 or release-readiness scope.
- Traceability check: PASS at plan-boundary.
- Overcommit guardrail: 8/20 SP = 40% capacity. Healthy.

## Notes

- **Methodology dogfood reinforced**: Second consecutive live-tracked iteration. The pattern locks in.
- **Antigravity launch shape**: extracted directly from user's pasted `agy --help` output — the canonical source. Spec FR-005 was wrong; will need a small-fix slice OR iter-006 to update the antigravity-followup spec.
- **PR readiness**: after iter-005 closes, the branch is ready for PR-to-main as F-043 + F-044 bundle. PR description will surface all 5 iterations' contribution.
