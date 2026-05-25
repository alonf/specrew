# Iteration Plan: 011

**Schema**: v1
**Spec**: [../../spec.md](../../spec.md)
**Status**: complete
**Capacity**: 3/20 story_points
**Started**: 2026-05-25
**Completed**: 2026-05-25

> Seventh LIVE-TRACKED iteration of F-044. Bug-fix slice triggered by smoke-test observation that interactive host-selection menu defaults to antigravity (alphabetical sort wins) instead of the documented `copilot` default.

## Scope Summary

User-flagged during smoke-test prep: interactive host-selection menu shows `1. antigravity` as the default option, contradicting docs that state `copilot` is the default. Root cause traced to `hosts/_registry.ps1:46-48` `Sort-Object Name` (alphabetical) feeding the menu-rendering loop.

User-specified fix (Option 1): introduce `MenuPriority` field on each host manifest, sort registry by priority, keep `--host` flag non-interactive default as `copilot` for CI/automation predictability. Priority order Claude → Codex → Copilot → Antigravity matches the cross-host audit's empirical methodology-rigor ranking.

| Requirement | Summary | Stories |
| --- | --- | --- |
| FR-011 | Adding a new host requires zero edits — preserved (MenuPriority is per-manifest, not central) | US4 |
| FR-012 | Documentation updated for shipped state — including two-default explanation | US5 |
| FR-013 | Tests added; MenuPriority validation per host | (testing) |

## Tasks

| Task | Title | Requirement | Story | Effort | Owner | Owner File Globs | Status | Agent | Actual | Verdict |
| ---- | ----- | ----------- | ----- | ------ | ----- | ---------------- | ------ | ----- | ------ | ------- |
| T001 | Add `MenuPriority` field to 4 host manifests (claude=1, codex=2, copilot=3, antigravity=4) | FR-011 | US4 | 0.5 | Implementer | hosts/{claude,codex,copilot,antigravity}/host.psd1 | done | claude | 0.5 | pass |
| T002 | Update `hosts/_registry.ps1` to sort manifests by MenuPriority (then Kind for stable tie-break); fallback priority 999 for missing field | FR-011 | US4 | 1 | Implementer | hosts/_registry.ps1 | done | claude | 1 | pass |
| T003 | Update `tests/integration/host-registry.tests.ps1` — Test 1 expected order now priority-sorted; new Test 1b asserts MenuPriority field exists on all 4 hosts with correct values | FR-013 | (testing) | 0.5 | Implementer | tests/integration/host-registry.tests.ps1 | done | claude | 0.5 | pass |
| T004 | Update docs (README, docs/getting-started.md, docs/user-guide.md) to explain two-default model: `--host` flag non-interactive default = `copilot` (unchanged for CI predictability), interactive-menu default = highest-priority installed host (Claude → Codex → Copilot → Antigravity) | FR-012 | US5 | 0.5 | Implementer | README.md; docs/getting-started.md; docs/user-guide.md | done | claude | 0.5 | pass |
| T005 | iter-011 artifacts + lint + validator + commit + push to PR #844 | FR-012 | US5 | 0.5 | Implementer | specs/044-per-host-architecture-refactor/iterations/011/* | done | claude | 0.5 | pass |

## Effort Model

| Setting | Value | Notes |
| ------- | ----- | ----- |
| Effort Unit | story_points | |
| Capacity per Iteration | 20 | Project default. |
| Iteration Bounding | scope | 5 tasks bounded by single bug-fix scope |
| Time Limit (hours) | n/a | |
| Overcommit Threshold | 1.0 | 3/20 = 15% — well under threshold. |
| Defer Strategy | manual | None expected. |
| Calibration Enabled | true | Seventh live-tracked iteration. |

## Concurrency Rationale

- Roster snapshot: Spec Steward, Planner, Implementer, Reviewer, Retro Facilitator.
- T001 + T002 — sequential (registry behavior depends on manifest field existing).
- T003 — test capture after T001+T002 land.
- T004 + T005 — docs + closeout artifacts run last.

## Phase Baseline

| Phase | Estimated Effort | Notes |
| ----- | ---------------- | ----- |
| Planning | 0.25 | This plan + investigation in pre-iteration triage. |
| Discovery/Spikes | 0.25 | Read existing _registry.ps1 + menu code; verify root cause. |
| Implementation | 2 | T001 + T002 + T003 + T004. |
| Review | 0.25 | Markdownlint + integration tests + smoke-verify priority order via direct invocation. |
| Rework | 0.25 | Buffer (unused — no rework). |

## Routing Policy

| Lens Scope | Requested Reasoning / Review Class | Effective Class (when run) | Override / Approval Record | Notes |
| --- | --- | --- | --- | --- |
| Bug-fix wording-precision + tiny refactor | standard | Integration tests + markdownlint + dry-run sort verification | n/a | iter-011's empirical test boundary: user's next `specrew start` (fresh project) shows Claude as `[default 1]`. |

## Traceability Summary

- Task coverage: 5 tasks for 1 user-surfaced bug (interactive menu default).
- Traceability check: PASS at plan-boundary.
- Overcommit guardrail: 3/20 = 15% capacity. Healthy.

## Notes

- **Why this is iter-011, not iter-010**: iter-010 was claimed for the PR-review cleanup (7 Copilot findings); user deferred iter-010 to wait for proposal-draft. iter-011 (this iter) is the bug-fix that landed first.
- **Two-defaults model is intentional**: `--host` flag default (`copilot`, non-interactive) vs interactive menu default (highest-priority installed). Different contexts → different defaults → both documented.
- **MenuPriority field is per-host** so adding a 5th host doesn't require central-config edits. Preserves FR-011 zero-edit-elsewhere guarantee.
- **No `.specify/` mirror needed**: hosts/ directory is part of the module distribution, not deployed templates. The .specify/ copy doesn't include hosts/.
