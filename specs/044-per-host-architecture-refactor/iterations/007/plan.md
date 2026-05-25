# Iteration Plan: 007

**Schema**: v1
**Spec**: [../../spec.md](../../spec.md)
**Status**: complete
**Capacity**: 7/20 story_points
**Started**: 2026-05-25
**Completed**: 2026-05-25

> Fourth LIVE-TRACKED iteration of F-044 (iter-004 + iter-005 + iter-006 + iter-007). Plan written before code; actuals filled at task close.

## Scope Summary

Antigravity's WSL dogfood of v0.27.0 (the iter-006 fixed branch) drove the FULL Specrew lifecycle end-to-end successfully (specify → feature-closeout) — methodology win. But it patched ONE remaining deployed Specrew script (`.specify/.../scaffold-reviewer-artifacts.ps1`) because of a Windows-only `'C:\'` hardcoded path. iter-007 canonicalizes that fix, audits the codebase for sibling bugs, expands the README with the host-switching narrative (which is the methodology's killer differentiator vs raw CLI dogfooding), and runs a full pre-PR doc + lint sweep so the F-043 + F-044 bundled PR is ready to land cleanly through CI.

| Requirement | Summary | Stories |
| --- | --- | --- |
| FR-009 | Tooling robustness (extends to Linux portability of deployed scripts) | US5 |
| FR-011 | Adding a new host requires zero edits — preserved | US4 |
| FR-012 | Documentation updated for shipped state | US5 |
| FR-013 | Tests added; Linux portability assertion | (testing) |

## Tasks

| Task | Title | Requirement | Story | Effort | Owner | Owner File Globs | Status | Agent | Actual | Verdict |
| ---- | ----- | ----------- | ----- | ------ | ----- | ---------------- | ------ | ----- | ------ | ------- |
| T001 | Canonicalize Antigravity's `scaffold-reviewer-artifacts.ps1` Linux-portability fix — line 998 hardcoded `'C:\'` → platform-detection root prefix + substring index; also fix line 990's `-replace '/', '\'` (Linux Split-Path breaks on `\` literal paths) | FR-009 | US5 | 1.5 | Implementer | extensions/specrew-speckit/scripts/scaffold-reviewer-artifacts.ps1 | done | claude | 1.5 | pass |
| T002 | Audit ALL extension scripts + scripts/* for hardcoded `C:\` / Windows-only path constants; grep for sibling bugs; fix any found | FR-009 | US5 | 1 | Implementer | extensions/**/*.ps1; scripts/**/*.ps1 | done | claude | 1 | pass |
| T003 | README enhancement — add the host-switching advantage (continue from same spot across Copilot ↔ Claude ↔ Codex ↔ Antigravity without context loss) as a top-tier differentiator section near the "Why Specrew" copy | FR-012 | US5 | 1.5 | Implementer | README.md | done | claude | 1.5 | pass |
| T004 | Audit + refresh `docs/getting-started.md`, `docs/user-guide.md`, `proposals/INDEX.md` (read-only sweep for F-043/F-044/Proposal 108 / v0.27.0 staleness) | FR-012 | US5 | 1 | Implementer | docs/getting-started.md; docs/user-guide.md; proposals/INDEX.md | done | claude | 1 | pass |
| T005 | Markdown lint sweep — run `markdownlint-cli` locally on all touched + new docs (iter-001 through iter-007 artifacts, README, getting-started, user-guide); fix violations | FR-012 | US5 | 1 | Implementer | **/*.md | done | claude | 1 | pass |
| T006 | Add Linux-portability regression assertions to `multi-host-lifecycle-smoke.tests.ps1` (or new test file) — parse the fixed scaffolder under `$IsLinux` mock context | FR-013 | (testing) | 0.5 | Implementer | tests/integration/multi-host-lifecycle-smoke.tests.ps1 | done | claude | 0.5 | pass |
| T007 | Pre-PR final verification — merge `origin/main` (Proposal 108 file), bump `.specrew/config.yml` to 0.27.0, run full integration test suite, parse-check, markdownlint, write PR description | FR-012 + FR-013 | US5 | 0.5 | Implementer | various | done | claude | 0.5 | pass |

## Effort Model

| Setting | Value | Notes |
| ------- | ----- | ----- |
| Effort Unit | story_points | |
| Capacity per Iteration | 20 | Project default. |
| Iteration Bounding | scope | 7 tasks bounded by post-WSL-dogfood readiness + PR submission |
| Time Limit (hours) | n/a | |
| Overcommit Threshold | 1.0 | 7/20 = 0.35 — well under threshold. |
| Defer Strategy | manual | If T002 audit surfaces deep refactor scope, surface for re-planning. |
| Calibration Enabled | true | Fourth live-tracked iteration. |

## Concurrency Rationale

- Roster snapshot: Spec Steward, Planner, Implementer, Reviewer, Retro Facilitator.
- T001 + T002 — both touch scaffolders; serial since T002 reuses T001's fix pattern.
- T003 + T004 — doc tasks; can run sequentially after T001/T002 implementation done.
- T005 — markdown lint runs against the cumulative output of T003 + T004 + new iter-007 artifacts.
- T006 — test capture; serial after T001 (the fix it asserts).
- T007 — final gate before PR; runs after all above.

## Phase Baseline

| Phase | Estimated Effort | Notes |
| ----- | ---------------- | ----- |
| Planning | 0.5 | This plan + reading Antigravity's WSL session output to extract the patch. |
| Discovery/Spikes | 0.5 | Grep audit for sibling `C:\` / Windows-only patterns. |
| Implementation | 4.5 | T001 + T002 + T003 + T004 + T005 + T006. |
| Review | 0.5 | Parse-check + integration test pass on touched files. |
| Rework | 1 | Buffer for markdown lint violations or sibling bugs surfaced in T002. |

## Routing Policy

| Lens Scope | Requested Reasoning / Review Class | Effective Class (when run) | Override / Approval Record | Notes |
| --- | --- | --- | --- | --- |
| Portability fix + docs + PR readiness | standard | Parse-check + integration tests + markdownlint clean + CI passes on PR | n/a | iter-007's empirical test boundary is "PR-to-main CI passes". |

## Traceability Summary

- Task coverage: 7 tasks for 1 user-surfaced bug (Linux portability) + 1 user-surfaced docs gap (host-switching narrative) + audit + lint + PR prep.
- Traceability check: PASS at plan-boundary.
- Overcommit guardrail: 7/20 = 35% capacity. Healthy.

## Notes

- **Empirical motivation**: Antigravity's WSL test drove FULL lifecycle on Linux for the first time — that's a methodology validation milestone. It only had to patch ONE remaining file, which is a major improvement vs prior dogfoods. iter-007 closes the loop on that one remaining patch + makes the bundle PR-ready.
- **README host-switching narrative**: User explicitly called this out as a "main advantage of Specrew" that's hard to convey otherwise. Methodology preserves context (artifact-on-disk) so swapping host preserves the project state — a context-window problem solved by structural design.
- **iter-007 is the SAFE close** for the F-043 + F-044 bundle. Iter-008+ (host-specific init deferral proposal candidate, etc.) ships separately.
