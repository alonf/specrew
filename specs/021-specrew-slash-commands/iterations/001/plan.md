# Iteration Plan: 001

**Schema**: v1
**Feature**: 021-specrew-slash-commands  
**Branch**: 021-specrew-slash-commands  
**Status**: executing
**Capacity**: 7/20 story_points
**Started**: not-started
**Completed**: (not started)
**Review Completed**: (not started)
**Retro Completed**: (not started)
**Created**: 2026-05-18  
**Updated**: 2026-05-18

## Overview

Iteration 001 is the only planned delivery slice for Feature 021. It covers the full seven-command v1 `/specrew.*` surface, the routing and compatibility contract behind that surface, and the validation evidence needed to prove coexistence with `/speckit.*` without bypassing human lifecycle boundaries.

**Scope**: FR-001 through FR-026 inside one iteration only. This artifact allocates execution capacity and guardrails, but it does **not** open tasks or implementation by itself.

## Task Summary

Primary planned scope: **6.3 SP**  
Repair reserve: **0.7 SP**  
Locked capacity ceiling: **7.0 SP**

Total grouped work packages: 4  
Total effort estimate: 6.3 Story Points (+ 0.7 SP repair reserve)

## Tasks

| Task | Title | Requirement | Story | Effort | Owner | Status | Agent | Actual | Verdict |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| I1-W001 | Catalog and contract authoring | FR-001..FR-005, FR-012..FR-015, FR-021..FR-025 | US1, US4, US5 | 1.5 | Spec Steward | planned | TBD | — | planned |
| I1-W002 | Routing, alias normalization, and arg whitelist | FR-006..FR-011 | US2 | 2.0 | Implementer | planned | TBD | — | planned |
| I1-W003 | Distribution, compatibility, and remediation delivery | FR-016..FR-020 | US3 | 1.5 | Implementer | planned | TBD | — | planned |
| I1-W004 | Discovery fallback, coexistence, and hardening evidence | FR-023..FR-026, SC-001..SC-006 | US1, US4, US5 | 1.3 | Reviewer | planned | TBD | — | planned |

## Effort Model

| Setting | Value | Notes |
| --- | --- | --- |
| Effort Unit | story_points | Unit used for scope lock, review evidence, and later retro variance |
| Capacity per Iteration | 20 | Repository default from `.specrew/iteration-config.yml` |
| Feature Slice Capacity | 7.0 | Human-locked capacity for this single-iteration feature |
| Planned Effort | 6.3 | Primary work before repair reserve |
| Repair Reserve | 0.7 | Usual 10% reserve held inside the 7 SP ceiling |
| Iteration Bounding | scope | The feature stays single-iteration; no Iteration 002 opens unless a future human decision changes scope |
| Time Limit (hours) | n/a | Only applies when iteration bounding is `time` |
| Overcommit Threshold | 1.0 | Matches repository iteration config; no silent widening beyond the 7 SP slice |
| Defer Strategy | manual | Any deferral must be named explicitly and re-authorized if it would open another iteration |
| Calibration Enabled | true | Retro should compare actual delivery against the locked 7 SP slice |
| Repair Policy | 3 cycles / 30 minutes per failing test | Active default carried from Feature 020 |

## Phase Baseline

| Phase | Estimated Effort | Notes |
| --- | --- | --- |
| Contract authoring | 1.5 | Catalog, routing contract, owner-label disposition, and governance notes |
| Implementation delivery | 3.5 | Skill assets, dispatcher wiring, alias behavior, compatibility checks, and update/init flow changes |
| Validation and review evidence | 1.3 | Discovery fallback proof, coexistence checks, hardening-gate updates, and reviewer-visible diagnostics |
| Rework reserve | 0.7 | Bounded quality repair only; no scope growth |

## Scope Guardrails

- **Single iteration only**: all planned Feature 021 scope stays in Iteration 001. Do not open Iteration 002 during this planning boundary.
- **Stewardship labels are descriptive**: product, governance, runtime, UX, distribution, reliability, and quality owner labels map onto the baseline Squad roles and do not justify roster expansion unless a later human-approved plan revision says otherwise.
- **Carry-forward defaults stay active**: 3 repair cycles, 30-minute wall-clock per failing test, live bookkeeping during execution, per-lane drift-log labeling, push after every commit, Write-Output-visible warnings, no case-insensitive PowerShell variable collisions, and markdown-link [name](file:///...) prose paths.
- **Hardening scaffold is mandatory**: file:///C:/Dev/Specrew/specs/021-specrew-slash-commands/iterations/001/quality/hardening-gate.md remains the canonical quality gate artifact.
- **Boundary safety is non-negotiable**: `/specrew.*` must remain additive to `/speckit.*` and may not imply lifecycle approval.
- **Task backlog alignment**: the executable task backlog lives at file:///C:/Dev/Specrew/specs/021-specrew-slash-commands/iterations/001/tasks.md and must stay aligned with this grouped work-package plan.

## Authorization

- **Planning approval**: Alon Fliess authorized `/speckit.plan` for Feature 021.
- **Clarify handoff**: accepted clarify-completion boundary commit `934da76`.
- **Scope source**: file:///C:/Dev/Specrew/specs/021-specrew-slash-commands/spec.md remains authoritative for this iteration plan.
- **Next boundary**: human review of the before-implement gate outcome before `/speckit.implement`.

## Notes

- This plan intentionally uses grouped work packages instead of executable tasks so the planning boundary remains intact.
- The baseline role mapping in file:///C:/Dev/Specrew/specs/021-specrew-slash-commands/plan.md is the authoritative interpretation for stewardship labels at before-implement time.
