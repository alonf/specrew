# Tasks: Hook-Driven Session Bootstrap

**Feature**: 174-hook-driven-session-bootstrap
**Plan**: [plan.md](./plan.md) · **Design**: [iterations/001/design-analysis.md](./iterations/001/design-analysis.md)
**Decomposition method**: Option B (IDesign volatility-based); one `.ps1` file per component.

## Capacity summary

Honest total ≈ **33 SP** — exceeds the 20 SP iteration cap, so the work is **split into
two iterations** (split, not cap-raise):

- **Iteration 001 ≈ 19 SP** — direct-launch bootstrap + stale-anchor clearing (US-1, US-4).
- **Iteration 002 ≈ 14 SP** — handover round-trip + launcher dedupe + concurrency + per-host
  hardening (US-2, US-3).

`[P]` = parallelizable (distinct files, no shared-state dependency). Build order respects
IDesign layering: accessors/adapters → engines → managers → integration → verification.

## Iteration 001 — Direct-launch bootstrap + stale-anchor clearing (~19 SP)

| ID | Task | Component | SP | Traces |
| --- | --- | --- | --- | --- |
| T001 [P] | Normalize per-host SessionStart payloads | HostEventAdapter | 2 | FR-001, FR-005 |
| T002 [P] | Read/write Proposal 130 handover (.md + index) | HandoverStore | 2 | FR-009, FR-010 |
| T003 [P] | Anchor read/write + local-only SessionStart marker write | SessionStateAccessor | 2 | FR-013, FR-015, FR-018 |
| T004 [P] | Feature metadata + git merged/closed/portability reads | ProjectMetadataAccessor | 2 | FR-014, FR-015 |
| T005 [P] | Classification record write via F-171 journal | HookJournalAccessor | 1 | SC-007 |
| T006 | Pure two-stage mode decision (full/welcome-back/cleared) | ClassificationEngine | 2 | FR-001, FR-017 |
| T007 | Validate handover + anchor vs project; clear stale anchors | ValidationEngine | 3 | FR-010, FR-013, FR-015, FR-017, SC-004 |
| T008 | Build the data-oriented directive (render_first etc.) | DirectiveEngine | 1 | FR-002, FR-004 |
| T009 | Orchestrate B2: gather → classify → directive → emit (non-interactive) | SessionBootstrapManager | 2 | FR-001, FR-002, FR-003, FR-016 |
| T010 | Render-first mechanical enforcement (disallowed-tools skill) | (skill wiring) | 1 | FR-004, FR-020, SC-001 |
| T011 | Register B2 provider via F-171 deploy loop + FileList | (deploy) | 1 | FR-001 |

Iteration 001 SP: 2+2+2+2+1+2+3+1+2+1+1 = **19**.

## Iteration 002 — Handover round-trip + dedupe + concurrency + per-host (~14 SP)

| ID | Task | Component | SP | Traces |
| --- | --- | --- | --- | --- |
| T012 | `specrew start` preface + launcher↔hook dedupe handshake | LauncherIntegration | 2 | FR-006, FR-007, SC-002 |
| T013 | Write-only SessionEnd handover + opt-in scoped commit | SessionEndHandoverManager | 2 | FR-009, FR-021, SC-003 |
| T014 | Full handover round-trip + read-validate path | (integration) | 2 | FR-010, FR-017, SC-003 |
| T015 | SessionStart-marker concurrency detection (1h window) | SessionStateAccessor + ClassificationEngine | 2 | FR-018, FR-019 |
| T016 | Per-path journal-assertion tests (every mode + unclean-exit) | (tests) | 2 | SC-007 |
| T017 | B1/B3 regression + FR-012 negative test (no B4/Antigravity path) | (tests) | 1 | FR-011, FR-012, SC-005 |
| T018 | Per-host empirical verification (Claude/Codex/Copilot/Cursor) | (verification) | 2 | FR-005, SC-001, SC-005 |
| T019 | Update docs/prompts: hook = primary, `specrew start` = compat | (docs) | 1 | FR-008, SC-006 |

Iteration 002 SP: 2+2+2+2+2+1+2+1 = **14**.

## Traceability coverage (after-tasks check)

- Every task above maps to ≥1 FR/SC.
- FR coverage: FR-001 (T001,T009,T011) · FR-002 (T008,T009) · FR-003 (T009) · FR-004
  (T008,T010) · FR-005 (T001,T018) · FR-006 (T012) · FR-007 (T012) · FR-008 (T019) · FR-009
  (T002,T013) · FR-010 (T002,T007,T014) · FR-011 (T017) · FR-012 (T017 negative) · FR-013
  (T003,T007) · FR-014 (T004) · FR-015 (T003,T004,T007) · FR-016 (satisfied at
  design-analysis; realized by T009 division of labor) · FR-017 (T006,T007,T014) · FR-018
  (T003,T015) · FR-019 (T015) · FR-020 (T010) · FR-021 (T013).
- SC coverage: SC-001 (T010,T018) · SC-002 (T012) · SC-003 (T013,T014) · SC-004 (T007) ·
  SC-005 (T017,T018) · SC-006 (T019) · SC-007 (T005,T016).

## Cross-cutting obligations (apply to every task)

- One Pester `<Component>.Tests.ps1` per component; pure engines get in-memory path tests.
- Every new `.ps1` added to the module FileList (install-break guard).
- IDesign layering is review/test-enforced (no access modifiers): Manager→Engine→Accessor only.
- Engine call-rule honored: ValidationEngine may read directly; Classification/Directive stay pure.
