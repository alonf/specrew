# Iteration Plan: 012

**Schema**: v1
**Spec**: [../../spec.md](../../spec.md)
**Status**: executing
**Capacity**: 8/20 story_points
**Started**: 2026-06-06

<!--
  Validator schema: Iteration Status one of planning|executing|reviewing|retro|complete|abandoned.
  Task Status one of planned|in-progress|done|needs-rework|deferred|blocked.
-->

## Iteration Theme

**Confirm-point presentation: front-loaded catalog + open-question-first (Amendment A8 / FR-041)** — the
corrected implementation of FR-037/FR-040 after i11's dogfood proved render-before-the-menu CONDUCT
insufficient on Claude (the `AskUserQuestion` tool-gravity). Two measures of differing strength
(advisor-checked pre-build): (a) **front-load the lens catalog** at workshop open — *structural*, holds by
construction; (b) **open-question-first per lens** — the strongest available *conduct* lever (binary,
skim-proof), but behavioral. Acceptance is the consolidated cross-host re-dogfood (SC-028 + the carried SC-027).

## Scope Summary

| Requirement | Summary | Stories |
| ----------- | ------- | ------- |
| FR-041(a) / SC-028 | Front-load the full lens catalog (all 9 lenses + each one-line decision, from index.yml + lens md) at workshop open, before applicability | US-A8 |
| FR-041(b) / SC-028 | Open-question-first per lens — first turn is a presentation + open question, never a menu; menu only after content on screen | US-A8 |
| SC-027 (carried) | The A7 no-synthetic-agreement Squad check rides i12's consolidated cross-host re-dogfood | US-A8 |

## Tasks

| Task | Title | Requirement | Story | Effort | Owner | Owner File Globs | Status | Agent | Actual | Verdict |
| ---- | ----- | ----------- | ----- | ------ | ----- | ---------------- | ------ | ----- | ------ | ------- |
| T001 | Catalog-at-open: skill step 1 presents the full 9-lens catalog (ids from index.yml; each one-line decision from design-lenses/<id>.md — reuse, no parallel catalog) BEFORE inferring applicability, so the later menu is informed by on-screen content (FR-041a, structural) | FR-041 | US-A8 | 3 | Implementer | extensions/specrew-speckit/squad-templates/skills/** | planned | claude | — | — |
| T002 | Open-question-first: skill step 3 opens each lens with a presentation + an OPEN free-text question, NEVER an AskUserQuestion menu as the first move; the menu only after the lens's content is on screen; + the Big-Picture A8 note (FR-041b, the binary conduct lever) | FR-041 | US-A8 | 2 | Spec Steward | extensions/specrew-speckit/squad-templates/skills/** | planned | claude | — | — |
| T003 | Tests: presence-lock catalog-at-open + open-question-first in lens-conduct-delivery; touched suites + the full scoped validator green | SC-028 | US-A8 | 2 | Reviewer | tests/unit/** | planned | claude | — | — |
| T004 | Consolidated cross-host re-dogfood (SC-028 + carried SC-027): on Claude the catalog front-loads + the agenda holds + the component map renders before its menu; on Squad no synthetic "Human agreed". Behavioral acceptance (maintainer-run). Pre-committed escalation if the map still stuffs into the menu on Claude = a PreToolUse hook or documented host-variance, NOT another instruction | SC-028 | US-A8 | 1 | Planner | specs/141-design-gate-runtime-hardening/** | planned | claude | — | — |

## Effort Model

| Setting | Value | Notes |
| ------- | ----- | ----- |
| Effort Unit | story_points | |
| Capacity per Iteration | 20 | |
| Iteration Bounding | scope | |
| Time Limit (hours) | n/a | Only applies when iteration bounding is `time`. |
| Overcommit Threshold | 1.0 | 8/20 — minimal build (advisor: keep it small, get a testable deploy fast). |
| Defer Strategy | manual | |
| Calibration Enabled | true | |

## Concurrency Rationale

- T001 (catalog-at-open) + T002 (open-question-first) are independent skill edits; T003 (tests) follows the
  conduct; T004 (the dogfood) is the maintainer-run behavioral gate. Serial baseline team.

## Phase Baseline

| Phase | Estimated Effort | Notes |
| ----- | ---------------- | ----- |
| Planning | 1 | The mechanism is advisor-decided (see design-analysis.md); concise. |
| Implementation | 5 | T001 catalog-at-open (3) + T002 open-question-first (2). |
| Review | 3 | T003 tests (2) + T004 the consolidated re-dogfood (1). |
| Rework | 0 | Buffer via the 12/20 headroom. |

## Traceability Summary

- Iteration 12 scope: Amendment A8 (FR-041, SC-028) + carried SC-027.
- Mechanism: catalog-at-open (FR-041a, structural) → T001; open-question-first (FR-041b, conduct) → T002;
  tests → T003; the consolidated cross-host re-dogfood → T004.

## Notes

- **The acceptance is behavioral (T004).** The agenda is EXPECTED to hold (front-loading is structural); the
  component-map render before its approve menu is the case the dogfood actually tests (the testLenses8/11
  failure). Pre-committed (spec SC-028): if a host still stuffs a generated visual into its menu, the resolution
  is a host-specific `PreToolUse` hook or documented host-variance decided with the maintainer — NEVER another
  instruction edit (i11's load-bearing lesson).
- Minimal scope (advisor): the catalog reuses `index.yml` + the lens md (no parallel catalog, no drift); no
  `workshop show` command (conduct dressed as mechanism); no new runtime floor (the presence-lock is the
  deterministic half).
- `index.yml` stays pure; deploy unchanged (the skill is edited in place); no release/push while 141 in progress.
