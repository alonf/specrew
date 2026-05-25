# Iteration Plan: 012

**Schema**: v1
**Spec**: [../../spec.md](../../spec.md)
**Status**: complete
**Capacity**: 5/20 story_points
**Started**: 2026-05-25
**Completed**: 2026-05-25

> Eighth LIVE-TRACKED iteration of F-044. v0.27.0 release-readiness slice triggered by doc-readiness audit (single Explore agent dispatched 2026-05-25 ~08:35) flagging blockers for first-public-multi-host-release publication.

## Scope Summary

Pre-PSGallery-publish release-readiness slice. The doc-readiness audit identified 4 blockers + 1 polish item for v0.27.0 publication. Plus a proposal-number collision found by inspection (concurrent Claude session pushed proposal 110 specrew-update-experience before my own proposal 110 quality-tier-routing-bundle; both files exist on main but only mine was in INDEX). iter-012 closes all of these in a single docs-only slice.

| Requirement | Summary | Stories |
| --- | --- | --- |
| FR-012 | Documentation updated for shipped state — including release notes | US5 |

## Tasks

| Task | Title | Requirement | Story | Effort | Owner | Owner File Globs | Status | Agent | Actual | Verdict |
| ---- | ----- | ----------- | ----- | ------ | ----- | ---------------- | ------ | ----- | ------ | ------- |
| T001 | Merge `origin/main` into feature branch (auto-resolves INDEX.md gap for 104/108 shipped + 109/111 candidates already there) | FR-012 | US5 | 0.5 | Implementer | (merge commit) | done | claude | 0.5 | pass |
| T002 | Resolve proposal-110 collision: renumber my "Quality-Tier Routing" proposal 110 → 112; add other Claude's "Specrew Update Experience" proposal 110 to INDEX (it was on disk but unlisted); bump candidate count 68 → 69 | FR-012 | US5 | 1 | Implementer | proposals/INDEX.md; proposals/110-quality-tier-routing*.md (renamed); proposals/112-quality-tier-routing*.md | done | claude | 1 | pass |
| T003 | Author `docs/release-notes-v0.27.0.md` — 5-section structure (TL;DR, Why this matters, What's new F-043+F-044, External-user value, Known limitations, Migration, Verification, Next) | FR-012 | US5 | 2 | Implementer | docs/release-notes-v0.27.0.md | done | claude | 2 | pass |
| T004 | Add `--host antigravity` quickstart line in getting-started.md step 4; add Antigravity-caveat + per-host-overlay note to Known Limitations section | FR-012 | US5 | 1 | Implementer | docs/getting-started.md | done | claude | 1 | pass |
| T005 | iter-012 artifacts + scaffold reviewer artifacts + lint + validate + commit + push to PR #844 | FR-012 | US5 | 0.5 | Implementer | specs/044-per-host-architecture-refactor/iterations/012/* | done | claude | 0.5 | pass |

## Effort Model

| Setting | Value | Notes |
| ------- | ----- | ----- |
| Effort Unit | story_points | |
| Capacity per Iteration | 20 | Project default. |
| Iteration Bounding | scope | 5 tasks bounded by release-readiness audit |
| Time Limit (hours) | n/a | |
| Overcommit Threshold | 1.0 | 5/20 = 25% — under threshold. |
| Defer Strategy | manual | None expected. |
| Calibration Enabled | true | Eighth live-tracked iteration. |

## Concurrency Rationale

- T001 must run first (merge brings in latest INDEX state)
- T002 depends on T001 (renumbering edits the merged INDEX)
- T003 + T004 are independent docs files; could parallelize but sequencing matters for citation accuracy
- T005 final gate

## Phase Baseline

| Phase | Estimated Effort | Notes |
| ----- | ---------------- | ----- |
| Planning | 0.25 | This plan + post-audit triage. |
| Discovery/Spikes | 0.25 | Identifying the proposal-110 collision via git log inspection. |
| Implementation | 4 | T001 + T002 + T003 + T004. |
| Review | 0.25 | Markdownlint + validator + scaffolder. |
| Rework | 0.25 | Buffer. |

## Routing Policy

| Lens Scope | Requested Reasoning / Review Class | Effective Class (when run) | Override / Approval Record | Notes |
| --- | --- | --- | --- | --- |
| Release-readiness docs | standard | Markdownlint + integration tests + manual user re-read | n/a | iter-012's empirical test: user can publish v0.27.0 to PSGallery without external users hitting doc gaps |

## Traceability Summary

- Task coverage: 5 tasks for 4 audit-flagged blockers + 1 proposal-110 collision found by inspection.
- Traceability check: PASS at plan-boundary.
- Overcommit guardrail: 5/20 = 25% capacity. Healthy.

## Notes

- **The audit was the gate** — single Explore agent dispatched with explicit 8-area brief; produced concrete file:line citations + FIX/KEEP/ENHANCE recommendations. iter-012 is the response to that audit. Pattern worth capturing for future release-readiness slices.
- **iter-010 still deferred** — 7 Copilot PR-review findings remain pending. Decided pre-iter-008 that iter-010 ships as separate small-fix slice after v0.27.0 merge OR as a v0.27.1 patch. iter-012 does NOT close those.
- **No code changes** — pure docs + INDEX + rename. No production .ps1 touched. Validator should pass without reviewer-artifact scaffolding for code-touching iteration (will check).
