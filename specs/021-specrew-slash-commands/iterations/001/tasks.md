---
schema: v1
feature: 021-specrew-slash-commands
iteration: 001
status: planned
capacity_story_points: 7.0
planned_story_points: 6.3
repair_reserve_story_points: 0.7
source_plan: specs/021-specrew-slash-commands/plan.md
source_iteration_plan: specs/021-specrew-slash-commands/iterations/001/plan.md
generated: 2026-05-18
---

# Tasks: Feature 021 Iteration 001 - Specrew Slash-Command Surface

**Feature**: `021-specrew-slash-commands`  
**Iteration**: `001`  
**Capacity Ceiling**: `7.0 SP`  
**Primary Planned Scope**: `6.3 SP`  
**Repair Reserve**: `0.7 SP`  
**Task Range**: `I1-T001` through `I1-T012`

## Task Format

Each executable item uses this structure:

```text
- [ ] I1-T### [P?] [US#] [assigned_to: Role] [effort: N.N SP] Action with exact file path(s) (Trace: work package; requirements)
```

- `[P]` marks work that can proceed in parallel after its dependencies are complete.
- `[US#]` marks the primary user-story anchor; additional story coverage is listed under each task.
- `Dependencies` names upstream task IDs explicitly.

## Baseline Stewardship Mapping

| Planning label | Execution role |
| --- | --- |
| Product steward + Governance steward | Spec Steward |
| Runtime steward + Distribution steward | Implementer |
| Reliability steward + Quality steward | Reviewer |
| Repair/learning carry-forward | Retro Facilitator |

## Work Package Decomposition Summary

| Work Package | Scope | Tasks | Effort |
| --- | --- | --- | ---: |
| I1-W001 | Catalog and contract authoring | I1-T001-I1-T002 | 1.5 |
| I1-W002 | Routing, alias normalization, and arg whitelist | I1-T003-I1-T006 | 2.0 |
| I1-W003 | Distribution, compatibility, and remediation delivery | I1-T007-I1-T009 | 1.5 |
| I1-W004 | Discovery fallback, coexistence, and hardening evidence | I1-T010-I1-T012 | 1.3 |
| **Primary scope** |  | **12 executable tasks** | **6.3** |
| **Repair reserve** | Hold for bounded fixes only | **Not pre-spent** | **0.7** |
| **Total** |  |  | **7.0** |

---

## Phase 1: I1-W001 - Catalog and Contract Authoring

**Goal**: Author the runtime-facing slash-command contract and help surface without reopening closed planning artifacts.

**Independent Test**: A reviewer can inspect the generated skill templates and confirm the seven-command v1 catalog, `/specrew.status` alias guidance, and `/specrew.help` fallback guidance are complete and consistent.

- [x] I1-T001 [US1] [assigned_to: Spec Steward] [effort: 0.8 SP] Author discovery-facing skill templates in `extensions/specrew-speckit/squad-templates/skills/specrew-where/SKILL.md`, `extensions/specrew-speckit/squad-templates/skills/specrew-status/SKILL.md`, `extensions/specrew-speckit/squad-templates/skills/specrew-help/SKILL.md`, and `extensions/specrew-speckit/squad-templates/skills/README.md` (Trace: I1-W001; FR-001, FR-002, FR-003, FR-012, FR-013, FR-014, FR-015)
  - **Execution**: Status=done; Agent=Spec Steward; Commit(s)=`29a130b`; Actual=0.8 SP; Verdict=PASS
  - **Title**: Discovery catalog skill authoring
  - **FR coverage**: FR-001, FR-002, FR-003, FR-012, FR-013, FR-014, FR-015
  - **User story coverage**: US1
  - **Owner role**: Spec Steward
  - **Dependencies**: None

- [x] I1-T002 [P] [US5] [assigned_to: Spec Steward] [effort: 0.7 SP] Author execution-facing skill templates in `extensions/specrew-speckit/squad-templates/skills/specrew-update/SKILL.md`, `extensions/specrew-speckit/squad-templates/skills/specrew-team/SKILL.md`, `extensions/specrew-speckit/squad-templates/skills/specrew-review/SKILL.md`, and `extensions/specrew-speckit/squad-templates/skills/specrew-version/SKILL.md` with explicit coexistence and boundary-safe wording (Trace: I1-W001; FR-004, FR-005, FR-021, FR-022, FR-023, FR-024)
  - **Execution**: Status=done; Agent=Spec Steward; Commit(s)=`29a130b`; Actual=0.7 SP; Verdict=PASS
  - **Title**: Execution catalog skill authoring
  - **FR coverage**: FR-004, FR-005, FR-021, FR-022, FR-023, FR-024
  - **User story coverage**: US4, US5
  - **Owner role**: Spec Steward
  - **Dependencies**: None

**Phase 1 Total**: 2 tasks, 1.5 SP

---

## Phase 2: I1-W002 - Routing, Alias Normalization, and Argument Whitelist

**Goal**: Make `/specrew.*` route to the intended existing workflows with alias parity, documented-argument enforcement, and visible diagnostics.

**Independent Test**: In an initialized project, a tester can invoke the v1 slash commands, observe `/specrew.status` parity with `/specrew.where`, and receive explicit help-driven failures for unsupported arguments.

- [x] I1-T003 [US2] [assigned_to: Implementer] [effort: 0.5 SP] Implement slash-command recognition and command-to-backend dispatch in `scripts/specrew.ps1` and `Specrew.psm1` for `/specrew.where`, `/specrew.update`, `/specrew.team`, `/specrew.review`, `/specrew.help`, and `/specrew.version` (Trace: I1-W002; FR-006, FR-008)
  - **Execution**: Status=done; Agent=Implementer; Commit(s)=`29a130b`; Actual=0.5 SP; Verdict=PASS
  - **Title**: Core slash router wiring
  - **FR coverage**: FR-006, FR-008
  - **User story coverage**: US2
  - **Owner role**: Implementer
  - **Dependencies**: I1-T001, I1-T002

- [x] I1-T004 [US2] [assigned_to: Implementer] [effort: 0.4 SP] Implement `/specrew.status` alias normalization and semantic parity safeguards in `scripts/specrew.ps1` and `scripts/specrew-where.ps1` (Trace: I1-W002; FR-007)
  - **Execution**: Status=done; Agent=Implementer; Commit(s)=`29a130b`; Actual=0.4 SP; Verdict=PASS
  - **Title**: Alias normalization and parity enforcement
  - **FR coverage**: FR-007
  - **User story coverage**: US2
  - **Owner role**: Implementer
  - **Dependencies**: I1-T003

- [x] I1-T005 [P] [US2] [assigned_to: Implementer] [effort: 0.6 SP] Implement per-command argument whitelist parsing, unsupported-argument rejection, and help guidance in `scripts/specrew.ps1`, `scripts/specrew-update.ps1`, `scripts/specrew-team.ps1`, and `scripts/specrew-review.ps1` (Trace: I1-W002; FR-009, FR-010, FR-011)
  - **Execution**: Status=done; Agent=Implementer; Commit(s)=`29a130b`; Actual=0.6 SP; Verdict=PASS
  - **Title**: Argument whitelist and failure handling
  - **FR coverage**: FR-009, FR-010, FR-011
  - **User story coverage**: US2
  - **Owner role**: Implementer
  - **Dependencies**: I1-T003

- [x] I1-T006 [US2] [assigned_to: Reviewer] [effort: 0.5 SP] Add routing, alias, and whitelist validation coverage in `tests/integration/slash-command-routing.tests.ps1` and `tests/unit/slash-command-arg-whitelist.tests.ps1` (Trace: I1-W002; FR-006, FR-007, FR-008, FR-009, FR-010, FR-011)
  - **Execution**: Status=done; Agent=Reviewer; Commit(s)=`29a130b`; Actual=0.5 SP; Verdict=PASS
  - **Title**: Routing validation suite
  - **FR coverage**: FR-006, FR-007, FR-008, FR-009, FR-010, FR-011
  - **User story coverage**: US2
  - **Owner role**: Reviewer
  - **Dependencies**: I1-T004, I1-T005

**Phase 2 Total**: 4 tasks, 2.0 SP

---

## Phase 3: I1-W003 - Distribution, Compatibility, and Remediation Delivery

**Goal**: Deliver the slash-command surface through standard Specrew setup/update flows with explicit compatibility checks and supported remediation.

**Independent Test**: A fresh project gains the slash-command surface through standard setup, an existing project receives updates through the supported refresh path, and unsupported baselines fail with clear remediation guidance.

- [x] I1-T007 [P] [US3] [assigned_to: Implementer] [effort: 0.5 SP] Wire runtime skill deployment for all `specrew-*` templates in `extensions/specrew-speckit/scripts/deploy-squad-runtime.ps1` and the `extensions/specrew-speckit/squad-templates/skills/specrew-*/SKILL.md` source set (Trace: I1-W003; FR-016, FR-017)
  - **Execution**: Status=done; Agent=Implementer; Commit(s)=`29a130b`; Actual=0.5 SP; Verdict=PASS
  - **Title**: Runtime skill deployment wiring
  - **FR coverage**: FR-016, FR-017
  - **User story coverage**: US3
  - **Owner role**: Implementer
  - **Dependencies**: I1-T001, I1-T002

- [x] I1-T008 [US3] [assigned_to: Implementer] [effort: 0.6 SP] Implement slash-surface provisioning, update reporting, minimum-version checks, and remediation messaging in `scripts/specrew-init.ps1`, `scripts/specrew-update.ps1`, `scripts/internal/version-check.ps1`, and `scripts/specrew.ps1` (Trace: I1-W003; FR-016, FR-017, FR-018, FR-019, FR-020)
  - **Execution**: Status=done; Agent=Implementer; Commit(s)=`29a130b`; Actual=0.6 SP; Verdict=PASS
  - **Title**: Provisioning and compatibility enforcement
  - **FR coverage**: FR-016, FR-017, FR-018, FR-019, FR-020
  - **User story coverage**: US3
  - **Owner role**: Implementer
  - **Dependencies**: I1-T007

- [x] I1-T009 [US3] [assigned_to: Reviewer] [effort: 0.4 SP] Add setup, refresh, and compatibility validation coverage in `tests/integration/slash-command-distribution.tests.ps1` and `tests/integration/slash-command-compatibility.tests.ps1` (Trace: I1-W003; FR-016, FR-017, FR-018, FR-019, FR-020; SC-003, SC-004)
  - **Execution**: Status=done; Agent=Reviewer; Commit(s)=`29a130b`; Actual=0.4 SP; Verdict=PASS
   - **Title**: Distribution and compatibility validation suite
   - **FR coverage**: FR-016, FR-017, FR-018, FR-019, FR-020
   - **SC coverage**: SC-003, SC-004
   - **User story coverage**: US3
   - **Owner role**: Reviewer
   - **Dependencies**: I1-T008
   - **Before-Implement Repair (GAP-BI-003, GAP-BI-004)**: Setup/refresh delivery outcomes moved from I1-T012 to I1-T009 because they map directly to distribution/compatibility validation.

**Phase 3 Total**: 3 tasks, 1.5 SP

---

## Phase 4: I1-W004 - Discovery Fallback, Coexistence, and Hardening Evidence

**Goal**: Prove fallback discovery, `/speckit.*` coexistence, and review evidence without bypassing boundary discipline.

**Independent Test**: Reviewers can validate host-native `/specrew.` discovery where supported, `/specrew.help` fallback everywhere else, side-by-side `/specrew.*` and `/speckit.*` usage, and a completed review evidence trail for SC-001 through SC-006.

- [x] I1-T010 [US1] [assigned_to: Reviewer] [effort: 0.4 SP] Add discovery fallback and first-time catalog validation in `tests/integration/slash-command-discovery.tests.ps1` and `specs/021-specrew-slash-commands/quickstart.md` (Trace: I1-W004; FR-012, FR-013, FR-014, FR-015; SC-001, SC-005)
  - **Execution**: Status=done; Agent=Reviewer; Commit(s)=`29a130b`; Actual=0.4 SP; Verdict=PASS
  - **Title**: Discovery fallback validation lane
  - **FR coverage**: FR-012, FR-013, FR-014, FR-015
  - **SC coverage**: SC-001, SC-005
  - **User story coverage**: US1
  - **Owner role**: Reviewer
  - **Dependencies**: I1-T001, I1-T006, I1-T009

- [x] I1-T011 [P] [US4] [assigned_to: Reviewer] [effort: 0.5 SP] Add namespace coexistence, collision handling, and boundary-safety checks in `tests/integration/slash-command-coexistence.tests.ps1` and `tests/unit/validate-governance.interaction-model.tests.ps1` (Trace: I1-W004; FR-021, FR-022, FR-023, FR-024; SC-002, SC-006)
  - **Execution**: Status=done; Agent=Reviewer; Commit(s)=`29a130b`; Actual=0.5 SP; Verdict=PASS
  - **Title**: Namespace coexistence and boundary-safety validation
  - **FR coverage**: FR-021, FR-022, FR-023, FR-024
  - **SC coverage**: SC-002, SC-006
  - **User story coverage**: US4
  - **Owner role**: Reviewer
  - **Dependencies**: I1-T002, I1-T006, I1-T009

- [x] I1-T012 [US5] [assigned_to: Reviewer] [effort: 0.4 SP] Record final review evidence and traceability in `specs/021-specrew-slash-commands/iterations/001/quality/hardening-gate.md` after executing the new slash-command suites and manual quickstart checks (Trace: I1-W004; US5)
  - **Execution**: Status=done; Agent=Reviewer; Commit(s)=`29a130b`, `d582a7e`; Actual=0.4 SP; Verdict=PASS
  - **Title**: Hardening evidence and final traceability review
  - **FR coverage**: None (FR-025 is ongoing governance discipline; FR-026 is pre-planning artifact)
  - **SC coverage**: None (SC-003 and SC-004 map to I1-T009 distribution validation)
  - **User story coverage**: US5
  - **Owner role**: Reviewer
  - **Dependencies**: I1-T010, I1-T011
  - **Before-Implement Repair (GAP-BI-001, GAP-BI-002)**: FR-025 and FR-026 traces removed because FR-025 is an ongoing governance discipline (not a single-task deliverable) and FR-026 is a pre-planning artifact (already satisfied by planning-time creation of hardening-gate.md).

**Phase 4 Total**: 3 tasks, 1.3 SP

---

## Dependencies & Critical Path

### Work-Package Order

```text
I1-W001 -> I1-W002 and I1-W003 -> I1-W004
```

### Explicit Critical Path

```text
I1-T001 -> I1-T003 -> I1-T004 -> I1-T005 -> I1-T006
I1-T002 -> I1-T007 -> I1-T008 -> I1-T009
I1-T006 + I1-T009 -> I1-T010 -> I1-T011 -> I1-T012
```

**Critical-path explanation**:

1. `I1-T001` and `I1-T002` author the runtime command contract that the router and deployment layers implement.
2. `I1-T003` through `I1-T006` establish executable routing parity, alias behavior, and argument enforcement.
3. `I1-T007` through `I1-T009` make the slash surface deployable and compatibility-safe through supported flows.
4. `I1-T010` through `I1-T012` are the final reviewer join-point tasks and cannot complete until both routing and distribution lanes are done.

## Parallel Opportunities

- `I1-T001` and `I1-T002` can start immediately in parallel.
- `I1-T005` can proceed in parallel with `I1-T004` after `I1-T003` completes.
- `I1-T007` can proceed in parallel with `I1-T003` once the corresponding skill templates are authored.
- `I1-T010` and `I1-T011` can run side by side after `I1-T006` and `I1-T009` are complete.

## Capacity and Reserve

| Bucket | SP |
| --- | ---: |
| I1-W001 | 1.5 |
| I1-W002 | 2.0 |
| I1-W003 | 1.5 |
| I1-W004 | 1.3 |
| Repair reserve | 0.7 |
| **Total** | **7.0** |

**Capacity verdict**: Planned work stays within the locked `7.0 SP` ceiling and preserves the explicit `0.7 SP` repair reserve as non-executable contingency.

## Execution Notes

- Preserve Feature 020 carry-forward defaults during execution: 3 repair cycles, 30-minute wall-clock per failing test, live bookkeeping, per-lane drift labels, push after every commit, Write-Output-visible warnings, no case-insensitive PowerShell variable collisions, and file:/// prose-path discipline.
- Treat stewardship labels as baseline Squad-role mappings only; do not reopen plan/spec ownership artifacts.
- Do not spend the `0.7 SP` reserve unless a concrete defect or evidence gap is logged against `I1-T001` through `I1-T012`.
