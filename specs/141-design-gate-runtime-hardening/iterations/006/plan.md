# Iteration Plan: 006

**Schema**: v1
**Spec**: [../../spec.md](../../spec.md)
**Status**: planning
**Capacity**: 19/20 story_points
**Started**: 2026-06-04

<!--
  Validator schema: Iteration Status one of planning|executing|reviewing|retro|complete|abandoned.
  Capacity format `<consumed>/<cap> <unit>`. Task Status one of planned|in-progress|done|needs-rework|deferred|blocked.
-->

## Iteration Theme

Re-scope the lens intake to **interactive + expertise-adapted + inside specify** (Amendment A3,
Option B). The lens questionnaire becomes a human interaction the Crew runs **as part of `specify`,
completing before the specify boundary is synced**, so the **accepted spec is lens-informed**
(maintainer placement rule). Depth adapts to the user-profile expertise dials (F-016: terse/expert
where high; explain + recommend where low); the Crew asks about the material areas (UI,
performance/resilience, etc.), surfaces the lens decisions, and only then writes them into artifacts.
The selected lenses' decision points then inform `specify` (requirements), `clarify`, and `plan`
(FR-009). The Iteration 4-5 engine (selector, sibling map, decision-point extractor, FR-026 gate) is
retained. Also ships **FR-028** (console `file:///` vs persisted markdown links + the handoff
`token/token` bare-path fix) and **FR-029** (downstream `Specrew.psd1` FileList-sort guard). 19/20 SP.

## Scope Summary

| Requirement | Summary | Stories |
| ----------- | ------- | ------- |
| FR-025 | Interactive, expertise-adapted lens questionnaire posed to the human; dial-adapted depth; decisions surfaced before writing | US3 |
| FR-027 | Intake runs inside `specify`, before specify-sync (and thus before clarify) — the accepted spec is lens-informed | US3 |
| FR-009 | Selected lenses' decision points inform requirements (specify) + clarify + plan, not only design-analysis | US3 |
| FR-028 | File references obey context: console `file:///`, persisted `.md` markdown links; handoff bare-path rule stops flagging `token/token` prose | US0 |
| FR-029 | Boundary sync skips the `Specrew.psd1` FileList-sort when no manifest is present (downstream) | US0 |
| SC-017/018/019 | Before-clarify placement; interactive + dial-adapted (no silent auto-resolve); file-ref context model (tests) | US3/US0 |
| TG-006 | Review classifies each behavior implemented/enforced/observable/documented + gap ledger; human-experience dogfood | US0 |

## Tasks

| Task | Title | Requirement | Story | Effort | Owner | Owner File Globs | Status | Agent | Actual | Verdict |
| ---- | ----- | ----------- | ----- | ------ | ----- | ---------------- | ------ | ----- | ------ | ------- |
| T001 | Dial→depth mapping helper: given the user-profile expertise dials + a question's material area, return the interaction depth (terse-expert / explain-recommend); pure, deterministic, testable | FR-025 | US3 | 3 | Implementer | scripts/internal/lens-applicability.ps1 | planned | claude | — | — |
| T002 | Lifecycle wiring (placement rule): the Crew runs the interactive lens intake INSIDE specify, before sync-specify — (a) ask before /speckit.specify if possible, else (b) scaffold draft → intake → record lens-applicability.json (feature-level, early) → amend spec.md + checklist → validate → sync-specify; (c) never between sync and clarify. Coordinator/governance + specify-ordering guidance | FR-025, FR-027 | US3 | 4 | Spec Steward | extensions/specrew-speckit/**, scripts/internal/** | planned | claude | — | — |
| T003 | Lens-informed flow: surface the selected lenses' decision points to specify (requirements), clarify (questions), and plan; design-analysis + coordinator guidance consume the early JSON | FR-009 | US3 | 3 | Implementer | extensions/specrew-speckit/**, scripts/internal/lens-applicability.ps1 | planned | claude | — | — |
| T004 | FR-028 file-reference render helper (console `file:///` vs persisted markdown links) + fix the handoff-validator bare-path rule to not flag non-path `token/token` prose and to honor the console-vs-persisted context | FR-028 | US0 | 3 | Implementer | scripts/internal/**, extensions/specrew-speckit/validators/handoff-governance-validator.ps1 | planned | claude | — | — |
| T005 | FR-029: guard the `Specrew.psd1` FileList-sort in boundary sync — skip (no warning) when no manifest is present (downstream project) | FR-029 | US0 | 1 | Implementer | scripts/internal/sync-boundary-state.ps1 | planned | claude | — | — |
| T006 | Tests (reproduce-first): dial→depth mapping; intake JSON recording + early/in-specify placement; lens-decision-point availability to specify/clarify/plan; FR-028 render contexts + handoff bare-path no-false-positive (RRT/Bug1, FR/SC); FR-029 no-warning-downstream | FR-025, FR-027, FR-028, FR-029, SC-017, SC-018, SC-019 | US3 | 4 | Reviewer | tests/unit/**, tests/integration/** | planned | claude | — | — |
| T007 | Docs + human-experience dogfood (run the interactive intake for real — demonstrate dial-adaptation + surfaced decisions, the human-experience test Iteration 5's retro flagged as missing) + implemented/enforced/observable/documented gap ledger (TG-006) | TG-006 | US0 | 1 | Planner | specs/141-design-gate-runtime-hardening/** | planned | claude | — | — |

## Effort Model

| Setting | Value | Notes |
| ------- | ----- | ----- |
| Effort Unit | story_points | |
| Capacity per Iteration | 20 | |
| Iteration Bounding | scope | |
| Time Limit (hours) | n/a | Only applies when iteration bounding is `time`. |
| Overcommit Threshold | 1.0 | 19/20 — tight; contingency below. |
| Defer Strategy | manual | |
| Calibration Enabled | true | |

## Concurrency Rationale

- T001 (dial→depth helper) is the root for the interaction model; T002 (lifecycle wiring) depends on
  T001 + the retained engine; T003 (flow) depends on T002. T004 (FR-028) + T005 (FR-029) are
  independent of the intake and can proceed in parallel. T006 (tests) follows the code; T007
  (docs/dogfood) last. Serial baseline team.
- **Contingency (cap discipline):** if T002's lifecycle wiring exceeds estimate (it touches the
  coordinator prompt + specify ordering — the riskiest task), FR-028 + FR-029 (T004/T005) split to a
  follow-up iteration so the core interactive intake (T001-T003) ships within cap. The intake is the
  priority; the two bundled fixes are not allowed to crowd it out.

## Phase Baseline

| Phase | Estimated Effort | Notes |
| ----- | ---------------- | ----- |
| Planning | 1 | Design-analysis gate (Option B + placement rule, decision commit `3e610c4a`). |
| Implementation | 11 | T001 helper (3) + T002 wiring (4) + T003 flow (3) + T005 guard (1). |
| Review | 7 | T004 FR-028 (3, spans impl+review) + T006 tests (4). T007 docs/dogfood absorbed. |
| Rework | 0 | Buffer absorbed by the contingency split, not headroom. |

## Traceability Summary

- Iteration 6 scope: FR-025, FR-027, FR-009, FR-028, FR-029; SC-017, SC-018, SC-019; TG-006.
- Design-analysis: **completed** — gate passed (Valid=true), maintainer-selected **Option B** with the
  placement rule; decision commit `3e610c4a`, draft `92286c76`. Authoritative plan input (FR-007).
- FR mapping: FR-025→T001/T002; FR-027→T002; FR-009→T003; FR-028→T004; FR-029→T005;
  SC-017/018/019→T006; TG-006→T007. Run specrew-traceability-check after the task table.

## Notes

- **The value is the human experience.** Iteration 5's retro lesson: a mechanics dogfood is not enough.
  T007 MUST run the interactive intake for real (dial-adapted Q&A, decisions surfaced) as the
  acceptance evidence — not only unit tests of the helper.
- **Placement is binding** (maintainer): the accepted `specify` output must be lens-informed; the
  intake completes before sync-specify; "between specify-sync and clarify" is not acceptable.
- Engine retained (selector, sibling map, extractor, FR-026 gate); deferred Proposal 156 deep
  automation stays out (FR-010). No release/Unix/wrapper surfaces; no push/PR while 141 is in progress.
- This iteration writes code + prompt/governance; it stops at before-implement for the go-ahead.

## Approved-for-implement (maintainer, 2026-06-04) — mandatory acceptance criteria

Before-implement approved WITH instructions. These are binding acceptance criteria carried into the named tasks:

1. **Preserve FR-026 after the early move (T002 + T006).** Moving lens-applicability to an early/feature-level artifact MUST NOT silently disable FR-026, which today reads `iterations/<NNN>/lens-applicability.json`. T002 MUST either (a) teach the FR-026 gate (`Test-SpecrewDesignAnalysisLensCoverage`) to resolve the early feature-level artifact, OR (b) synchronize/copy the selected-lenses artifact into the iteration directory before design-analysis. T006 MUST add a regression test proving a selected lens without an `Addressed:` entry still FAILS the gate and names the lens, AFTER the early-placement move.
2. **Human-experience dogfood = a real downstream run (T007).** Not helper tests: a real `specrew start` downstream run from this branch whose evidence shows the Crew asked the material lens questions, adapted depth to the user profile, surfaced UI/performance/resilience decisions, amended `spec.md` + the checklist BEFORE sync-specify, and only then proceeded to clarify.
3. **FR-028 covers persisted artifacts (T004).** Persisted `.md` uses navigable markdown links; console text uses `file:///` URLs; `RRT/Bug1` and `FR/SC` are not flagged as bare paths (console-vs-persisted context honored).
4. **Deferred follow-ups (maintainer-approved), not covered by T001-T007:** (a) `.specify/feature.json` is gitignored yet the coordinator attempts to stage it — decide track-it vs stop-staging-it; (b) version-display inconsistency (`0.31.1-beta1` banner vs `0.31.1` config vs installed `0.31.0`). Recorded here as explicit deferred follow-ups, filed for a follow-up chore/proposal — not silently dropped.
5. **Validator gate:** implementation MUST NOT start until a FRESH validator run returns hard=0 / medium=0 (the prior summary was stale).
