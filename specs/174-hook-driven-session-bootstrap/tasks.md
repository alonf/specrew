# Tasks: Hook-Driven Session Bootstrap

**Feature**: 174-hook-driven-session-bootstrap
**Plan**: [plan.md](./plan.md) · **Design**: [iterations/001/design-analysis.md](./iterations/001/design-analysis.md)
**Decomposition method**: Option B (IDesign volatility-based); one `.ps1` file per component.

## Capacity summary

Same scope as the plan (nothing trimmed; FR-018/FR-019 retained; Option B unchanged).
The honest total ≈ **35 SP** is regrouped into **three** iterations so none sits near the
20 SP cap — a regroup of the same tasks, not a scope cut:

- **Iteration 001 ≈ 12 SP** — direct-launch full bootstrap + stale-anchor clearing
  (US-1, US-4), Claude-first. The highest-value original-incident fix.
- **Iteration 002 ≈ 11 SP** — handover-first classification + welcome-back + SessionEnd
  write + launcher dedupe (US-2, US-3).
- **Iteration 003 ≈ 12 SP** — SessionStart-marker concurrency detection + per-host
  expansion + journal-assertion/regression tests + docs.

`[P]` = parallelizable (distinct files). Components built across iterations are *extended*
incrementally (e.g. ValidationEngine gains handover validation in 002, concurrency in 003).

## Iteration 001 — Direct-launch bootstrap + stale-anchor clearing (~12 SP)

| ID | Task | Component | SP | Traces |
| --- | --- | --- | --- | --- |
| T001 [P] | Normalize Claude SessionStart payload (per-host expansion → it003) | HostEventAdapter | 1 | FR-001, FR-005 |
| T002 [P] | Anchor read/write; absolute-path treated non-portable | SessionStateAccessor | 2 | FR-013, FR-015 |
| T003 [P] | Feature metadata + git merged/closed/portability reads | ProjectMetadataAccessor | 2 | FR-014, FR-015 |
| T004 | Pure mode decision (full / cleared-anchor; anchor stage) | ClassificationEngine | 2 | FR-001, FR-017 |
| T005 | Validate anchor vs project state; clear stale anchors | ValidationEngine | 2 | FR-013, FR-015, FR-017, SC-004 |
| T006 | Build the data-oriented directive (`render_first`) | DirectiveEngine | 1 | FR-002, FR-004 |
| T007 | Orchestrate B2 (non-interactive) + render-first disallowed-tools skill + B2 register/FileList + basic journal record | SessionBootstrapManager | 2 | FR-001, FR-002, FR-003, FR-004, FR-016, FR-020, SC-001, SC-007 |

Iteration 001 SP: 1+2+2+2+2+1+2 = **12**.

## Iteration 002 — Handover round-trip + welcome-back + launcher dedupe (~11 SP)

| ID | Task | Component | SP | Traces |
| --- | --- | --- | --- | --- |
| T008 [P] | Read/write Proposal 130 handover (.md + index) | HandoverStore | 2 | FR-009, FR-010 |
| T009 | Extend validation: handover vs project state (recency necessary-not-sufficient) | ValidationEngine | 2 | FR-010, FR-017 |
| T010 | Extend classification: handover-first stage + welcome-back mode | ClassificationEngine | 1 | FR-010, FR-017 |
| T011 | Write-only SessionEnd handover + opt-in scoped commit (off by default) | SessionEndHandoverManager | 2 | FR-009, FR-021, SC-003 |
| T012 | Full SessionEnd→SessionStart round-trip (read-validate-surface) | (integration) | 2 | FR-010, FR-017, SC-003 |
| T013 | `specrew start` preface + launcher↔hook dedupe handshake | LauncherIntegration | 2 | FR-006, FR-007, SC-002 |

Iteration 002 SP: 2+2+1+2+2+2 = **11**.

## Iteration 003 — Concurrency detection + per-host + verification + docs (~12 SP)

| ID | Task | Component | SP | Traces |
| --- | --- | --- | --- | --- |
| T014 | SessionStart marker write + 1h-window freshness state | SessionStateAccessor | 2 | FR-018 |
| T015 | Advisory local same-worktree concurrency signal (no locks) + unclean-exit detection | ClassificationEngine | 2 | FR-018, FR-019 |
| T016 [P] | Per-host SessionStart/SessionEnd normalization (Codex/Copilot/Cursor) | HostEventAdapter | 2 | FR-005 |
| T017 | Per-host empirical verification (render-before-picker, all 4 hosts) | (verification) | 2 | FR-005, SC-001, SC-005 |
| T018 | HookJournalAccessor + per-path journal-assertion tests (every mode + unclean-exit) | HookJournalAccessor | 2 | SC-007 |
| T019 | B1/B3 regression + FR-012 negative test (no B4/Antigravity path executes) | (tests) | 1 | FR-011, FR-012, SC-005 |
| T020 | Update docs/prompts: hook = primary bootstrap, `specrew start` = compat | (docs) | 1 | FR-008, SC-006 |

Iteration 003 SP: 2+2+2+2+2+1+1 = **12**.

(Totals: 12 + 11 + 12 = **35 SP** across three iterations; max iteration 12 SP, all clear
of the 20 cap.)

## Traceability coverage (after-tasks check, re-run for the new split)

- Every task maps to ≥1 FR/SC; every FR/SC has ≥1 task.
- FR coverage: FR-001 (T001,T004,T007) · FR-002 (T006,T007) · FR-003 (T007) · FR-004
  (T006,T007) · FR-005 (T001,T016,T017) · FR-006 (T013) · FR-007 (T013) · FR-008 (T020) ·
  FR-009 (T008,T011) · FR-010 (T008,T009,T010,T012) · FR-011 (T019) · FR-012 (T019 negative) ·
  FR-013 (T002,T005) · FR-014 (T003) · FR-015 (T002,T003,T005) · FR-016 (satisfied at
  design-analysis; realized by T007 division of labor) · FR-017 (T004,T005,T009,T010,T012) ·
  FR-018 (T014,T015) · FR-019 (T015) · FR-020 (T007) · FR-021 (T011).
- SC coverage: SC-001 (T007,T017) · SC-002 (T013) · SC-003 (T011,T012) · SC-004 (T005) ·
  SC-005 (T017,T019) · SC-006 (T020) · SC-007 (T007,T018).

## Cross-cutting obligations (apply to every task)

- One Pester `<Component>.Tests.ps1` per component; pure engines get in-memory path tests.
- Every new `.ps1` added to the module FileList (install-break guard).
- IDesign layering is review/test-enforced (no access modifiers): Manager→Engine→Accessor only.
- Engine call-rule honored: ValidationEngine may read directly; Classification/Directive stay pure.
