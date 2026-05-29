---
schema: v1
feature: 049-pipeline-hardening-intake
iteration: 005
proposal: 141
status: planned
capacity_story_points: 7.4
planned_story_points: 6.6
repair_reserve_story_points: 0.8
source_plan: specs/049-pipeline-hardening-intake/plan.md
source_iteration_plan: specs/049-pipeline-hardening-intake/iterations/005/plan.md
generated: 2026-05-28
---

# Tasks: Feature 049 Iteration 005 - Proposal 141 Crew Interaction Profile / Persona Lens Separation

**Feature**: `049-pipeline-hardening-intake`  
**Iteration**: `005`  
**Proposal**: `141`  
**Authorized Slice**: `6-8 SP`  
**Primary Planned Scope**: `6.6 SP`  
**Repair Reserve**: `0.8 SP`  
**Task Range**: `T001` through `T010`

## Scope Guardrails

- Preserve Iteration `004` / Proposal `120` unchanged; do not move, weaken, or reopen that lane.
- Preserve stable persisted keys and internal persona IDs, including `expertise.ai_research_project_management` and `ai-researcher-project-manager`.
- Keep the Crew Interaction Profile soft for all agents outside `/speckit.specify`; this release does not hard-apply it elsewhere.
- Do not reopen Iteration `003`, add a fifth lens, or split the fourth internal lens.
- Do not persist resolved per-developer profile values into shared repository files; durable guidance must point to the current-user loader/path rule only.

## Task Format

Each executable item uses this structure:

```text
- [ ] T### [P?] [US#?] [assigned_to: Role] [effort: N.N SP] Action with exact file path(s) (Trace: requirements)
```

- `[P]` marks work that can proceed in parallel once its dependencies are complete.
- `[US3]` marks the Proposal `141` user-story anchor.
- Setup, Foundational, and Polish tasks intentionally omit a story label to stay validator-safe.
- Every task below includes exact file paths, explicit requirement traces, and dependency-safe ordering.

## Workstream Envelope Summary

| Workstream | Outcome | Tasks | Effort |
| --- | --- | --- | ---: |
| W001 | Lock Crew Interaction Profile display and session-context contract | T001-T004 | 2.6 |
| W002 | Prove legacy compatibility and update runtime/profile wording | T005-T006 | 1.7 |
| W003 | Align skill, specify, and durable shared-guidance surfaces | T007-T009 | 1.7 |
| W004 | Record validator-safe compatibility and multi-developer evidence | T010 | 0.6 |
| **Primary scope** |  | **10 tasks** | **6.6** |
| **Repair reserve** | Hold for bounded fixes only | **Not pre-spent** | **0.8** |
| **Total envelope** |  |  | **7.4** |

---

## Phase 1: Setup (Evidence Scaffold)

**Purpose**: Create the bounded audit/evidence envelope before any wording, guidance, or proof surfaces are refreshed.

**Verification**: `Test-Path specs/049-pipeline-hardening-intake/iterations/005/quality/quality-evidence.md`

- [ ] T001 [assigned_to: Reviewer] [effort: 0.4 SP] Create the Iteration `005` audit scaffold in `specs/049-pipeline-hardening-intake/iterations/005/quality/quality-evidence.md` with sections for audited surface inventory, current-user session-context soft-guidance checks, durable loader/path-rule checks, paired-developer divergence proof, legacy `user-profile.yml` compatibility proof, and explicit Iteration `004` / Proposal `120` non-drift evidence (Trace: FR-036, FR-037, FR-039, FR-041, SC-007, SC-008, TG-016, TG-017)

**Checkpoint**: The evidence target exists and the bounded Proposal `141` audit envelope is locked.

---

## Phase 2: Foundational (Contract Lock)

**Purpose**: Freeze the wording, session-context, and loader-rule contract that all downstream implementation and proof tasks must follow.

**⚠️ CRITICAL**: No User Story `3` work should freeze until these tasks define the authoritative correction contract.

**Verification**: Inspect `scripts/internal/user-profile.ps1`, `scripts/specrew-start.ps1`, `README.md`, and `docs/user-guide.md` to confirm the display-label map, current-user soft-guidance framing, and loader/path rule are the agreed source of truth.

- [ ] T002 [assigned_to: Implementer] [effort: 0.8 SP] Add shared display-label metadata and Crew Interaction Profile helper mappings in `scripts/internal/user-profile.ps1` so user-facing surfaces render `Product Strategy`, `UX/UI Design`, `Software Architecture`, and `AI Delivery Planning` while keeping persisted keys and internal persona IDs unchanged (Trace: FR-032, FR-033, FR-034, FR-035, TG-017, TG-018)
- [ ] T003 [assigned_to: Implementer] [effort: 0.8 SP] Add current-user session-context profile summary helpers in `scripts/specrew-start.ps1` and `scripts/internal/user-profile.ps1` so generated `.specrew/start-summary.md`, `.specrew/start-context.json`, and `.specrew/last-start-prompt.md` frame the resolved profile as soft collaboration guidance for all agents rather than shared project truth (Trace: FR-032, FR-035, FR-038, FR-040, TG-018)
- [ ] T004 [assigned_to: Implementer] [effort: 0.6 SP] Author the durable shared-instruction loader/path-rule contract in `README.md`, `docs/user-guide.md`, `.specrew/team/agents/reviewer.md`, `.agents/agents/reviewer.md`, `extensions/specrew-speckit/squad-templates/agents/reviewer/charter.md`, and `.specify/extensions/specrew-speckit/squad-templates/agents/reviewer/charter.md` so shared guidance points to the current-user profile loader/path rule and forbids committed resolved dial values (Trace: FR-039, FR-040, FR-041, TG-018)

**Checkpoint**: Display labels, session-context semantics, and loader/path-rule language are authoritative for the rest of the slice.

---

## Phase 3: User Story 3 - Crew Interaction Profile / Persona Lens Separation (Priority: P3)

**Goal**: Refresh user-facing Proposal `141` surfaces so Specrew presents the four saved values as a Crew Interaction Profile, keeps persona lenses internal, preserves stable keys/internal IDs, carries soft current-user guidance for all agents, and keeps `/speckit.specify` as the only hard-applied behavior.

**Independent Test**: Run `pwsh -File tests/integration/f049-i003-intake-engine-tests.ps1` and confirm legacy profile fixtures load unchanged, divergent local profiles remain repository-safe, current-user session context is soft guidance for all agents, shared instructions cite only the loader/path rule, and `/speckit.specify` alone uses hard-boundary wording.

### Tests for User Story 3

> **NOTE**: Add these fixtures/assertions first and ensure they fail until the refreshed wording/guidance contract is implemented.

- [ ] T005 [US3] [assigned_to: Reviewer] [effort: 0.8 SP] Add legacy and divergent-profile fixtures under `tests/integration/fixtures/f049-legacy-user-profile/` and `tests/integration/fixtures/f049-divergent-user-profiles/`, then add failing assertions in `tests/integration/f049-i003-intake-engine-tests.ps1` proving stable-key compatibility, unchanged internal routing/depth behavior, loader/path-rule guidance, and multi-developer local-profile safety (Trace: FR-033, FR-037, FR-039, FR-041, SC-007, SC-008, TG-018)

### Implementation for User Story 3

- [ ] T006 [US3] [assigned_to: Implementer] [effort: 0.9 SP] Update first-run and profile/runtime wording in `scripts/internal/user-profile.ps1` and `scripts/specrew-start.ps1` so the four saved values are presented as Crew Interaction Profile decision areas, keep `AI Delivery Planning` as the fourth visible label, and preserve existing persisted keys/internal persona IDs without migration (Trace: FR-032, FR-033, FR-034, FR-035, FR-038, TG-017, TG-018)
- [ ] T007 [P] [US3] [assigned_to: Implementer] [effort: 0.5 SP] Refresh `/specrew-user-profile` help copy in `.github/skills/specrew-user-profile/SKILL.md`, `.claude/skills/specrew-user-profile/SKILL.md`, and `.agents/skills/specrew-user-profile/SKILL.md` so help surfaces describe decision-area labels, soft session guidance, and unchanged persisted keys/internal persona IDs (Trace: FR-032, FR-034, FR-035, FR-036, FR-040, TG-018)
- [ ] T008 [P] [US3] [assigned_to: Implementer] [effort: 0.6 SP] Align `/speckit.specify` hard-boundary wording in `.github/prompts/speckit.specify.prompt.md`, `.github/agents/speckit.specify.agent.md`, `extensions/specrew-speckit/scripts/intake/Invoke-SpecifyIntake.ps1`, and `.specify/extensions/specrew-speckit/scripts/intake/Invoke-SpecifyIntake.ps1` so the profile is described as soft current-user guidance generally but hard-applied only inside `/speckit.specify`, with shipped and mirrored intake guidance kept in lockstep (Trace: FR-032, FR-035, FR-036, FR-038, FR-040, TG-017, TG-018)
- [ ] T009 [P] [US3] [assigned_to: Implementer] [effort: 0.6 SP] Refresh durable shared-guidance wording in `docs/user-guide.md`, `README.md`, `.specrew/team/agents/reviewer.md`, `.agents/agents/reviewer.md`, `extensions/specrew-speckit/squad-templates/agents/reviewer/charter.md`, and `.specify/extensions/specrew-speckit/squad-templates/agents/reviewer/charter.md` so reviewers/operators enforce the loader/path rule, divergent local-profile safety, legacy compatibility expectations, and explicit preservation of Iteration `004` / Proposal `120` unchanged (Trace: FR-036, FR-039, FR-040, FR-041, SC-008, TG-016, TG-017, TG-018)

**Checkpoint**: Runtime, help, specify, and durable shared-guidance surfaces all reflect the bounded Proposal `141` contract.

---

## Phase 4: Polish & Cross-Cutting Verification

**Purpose**: Close the slice with validator-safe evidence proving audited surface coverage, legacy compatibility, and multi-developer safety without widening scope.

- [ ] T010 [assigned_to: Reviewer] [effort: 0.6 SP] Run the refreshed compatibility, shared-instruction, and paired-developer checks via `tests/integration/f049-i003-intake-engine-tests.ps1` and record exact results in `specs/049-pipeline-hardening-intake/iterations/005/quality/quality-evidence.md`, including audited surface coverage for `FR-032..FR-041`, proof that no shared artifact persists resolved per-developer settings, and explicit confirmation that Iteration `004` / Proposal `120` remains unchanged (Trace: FR-037, FR-038, FR-039, FR-040, FR-041, SC-007, SC-008, TG-016, TG-017, TG-018)

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1 (Setup)**: No dependencies; creates the bounded audit target.
- **Phase 2 (Foundational)**: Depends on Phase 1; freezes the wording, session-context, and loader/path-rule contract.
- **Phase 3 (US3)**: Depends on Phase 2; test proof lands before runtime/docs/specify refresh.
- **Phase 4 (Polish)**: Depends on Phase 3 completion; records final validator-safe evidence.

### Task Dependency Chain

```text
T001 -> T002 -> T003 -> T004 -> T005 -> T006 -> (T007, T008, T009) -> T010
```

### Dependency Notes

- `T002-T004` establish the authoritative contract; do not freeze story proof or shared guidance before they land.
- `T005` must codify failing legacy-compatibility and divergent-profile proof before implementation is considered complete.
- `T006` establishes the shipped runtime/session wording that `T007-T009` mirror into help, specify, and durable shared-guidance surfaces.
- `T007-T009` can proceed in parallel once `T006` lands because they touch separate help/specify/reviewer/doc surfaces.
- `T010` is the closeout gate and must verify that no task drifted into schema migration, persona-ID renames, committed per-developer values, Iteration `003` reopen, or Iteration `004` / Proposal `120` drift.

---

## Parallel Execution Example: User Story 3

```text
Task: "T007 Refresh /specrew-user-profile help copy in .github/.claude/.agents skill files"
Task: "T008 Align /speckit.specify prompt/agent and intake mirror guidance to the hard-boundary contract"
Task: "T009 Refresh durable shared-guidance wording in README.md, docs/user-guide.md, and reviewer/operator charter files"
```

---

## Implementation Strategy

### MVP First

1. Complete `T001-T004` to lock the evidence envelope, display-label contract, session-context soft-guidance rule, and durable loader/path rule.
2. Add failing proof with `T005` before broadening user-facing wording changes.
3. Complete `T006` and validate the runtime/session contract independently before parallelizing documentation surfaces.

### Incremental Delivery

1. Land the contract and loader/path-rule foundation (`T001-T004`).
2. Codify compatibility and divergent-local-profile proof (`T005`).
3. Make shipped runtime/profile surfaces truthful (`T006`).
4. Parallelize help/specify/shared-guidance refresh (`T007-T009`).
5. Finish with audited evidence and validator-safe proof (`T010`).

### Scope Boundaries

- Proposal `141` is a bounded correction slice only; do not widen into new persona architecture, schema changes, or new hard-applied role behavior outside `/speckit.specify`.
- If any task uncovers required key migration, persona-ID rename, or Iteration `004` drift, stop and replan instead of expanding this package.

---

## Task Envelope Summary

- **Total Tasks**: 10
- **Primary Scope**: 6.6 SP
- **Repair Reserve**: 0.8 SP
- **Setup**: 1 task
- **Foundational**: 3 tasks
- **US3**: 5 tasks
- **Polish**: 1 task
- **Parallel Opportunities**: 3 tasks (`T007-T009`)

## Independent Test Criteria by Story

- **US3**: Legacy `user-profile.yml` fixtures load without migration, divergent local profiles remain safe in the same repository, current-user session context stays soft guidance for all agents, shared instructions cite the loader/path rule instead of resolved dial values, and `/speckit.specify` remains the only hard-applied behavior.

## Suggested MVP Scope

- **Suggested MVP**: `T001-T006` (`US3` contract lock + failing proof + runtime/session wording refresh)

## Traceability Coverage Summary

- **FR-032**: T002, T006, T007, T008
- **FR-033**: T002, T005, T006
- **FR-034**: T002, T006, T007
- **FR-035**: T002, T003, T006, T007, T008
- **FR-036**: T001, T007, T008, T009
- **FR-037**: T001, T005, T010
- **FR-038**: T003, T006, T008, T010
- **FR-039**: T001, T004, T005, T009, T010
- **FR-040**: T003, T004, T007, T008, T009, T010
- **FR-041**: T001, T004, T005, T009, T010
- **SC-007**: T001, T005, T010
- **SC-008**: T001, T005, T009, T010
- **TG-016**: T001, T009, T010
- **TG-017**: T001, T002, T006, T008, T009, T010
- **TG-018**: T002, T003, T004, T005, T006, T007, T008, T009

## Format Validation

- All executable tasks use the required checklist format: `- [ ] T### [P?] [US#?] [assigned_to: Role] [effort: N.N SP] Description with exact file path(s) (Trace: requirements)`.
- Setup, Foundational, and Polish tasks omit story labels by design; all User Story `3` tasks include `[US3]`.
- Every task includes exact file paths, explicit trace tags, and dependency-safe ordering.

## Notes

- This refresh only updates the Iteration `005` task package for Proposal `141`; it does not modify the historical feature-level `specs/049-pipeline-hardening-intake/tasks.md`.
- Iteration `004` remains the reserved Proposal `120` bypass-detection slice and is intentionally left unchanged by this task package refresh.
