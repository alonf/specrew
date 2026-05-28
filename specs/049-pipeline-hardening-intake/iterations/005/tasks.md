---
schema: v1
feature: 049-pipeline-hardening-intake
iteration: 005
proposal: 141
status: planned
capacity_story_points: 5.0
planned_story_points: 4.4
repair_reserve_story_points: 0.6
source_plan: specs/049-pipeline-hardening-intake/plan.md
source_iteration_plan: specs/049-pipeline-hardening-intake/iterations/005/plan.md
generated: 2026-05-28
---

# Tasks: Feature 049 Iteration 005 - Proposal 141 Correction Slice

**Feature**: `049-pipeline-hardening-intake`  
**Iteration**: `005`  
**Proposal**: `141`  
**Capacity Ceiling**: `5.0 SP`  
**Primary Planned Scope**: `4.4 SP`  
**Repair Reserve**: `0.6 SP`  
**Task Range**: `T001` through `T008`

**Scope Guardrails**:

- No key or schema migration for `~/.specrew/user-profile.yml`
- No internal persona-ID rename, including `ai-researcher-project-manager`
- No Iteration `004` Proposal `120` edits or scope dilution
- No Iteration `003` architecture reopen or fifth-lens expansion

## Task Format

Each executable item uses this structure:

```text
- [ ] T### [P?] [US#?] [assigned_to: Role] [effort: N.N SP] Action with exact file path(s) (Trace: requirements)
```

- `[P]` marks work that can proceed in parallel after dependencies are complete.
- `[US3]` marks the Proposal `141` user-story anchor.
- `Trace` entries must stay explicit to `FR-032..FR-037`, `SC-007`, and `TG-016..TG-018`.

## Phase 1: Setup (Evidence Scaffold)

**Purpose**: Create the bounded audit/evidence envelope before wording changes begin.

**Verification**: `Test-Path specs/049-pipeline-hardening-intake/iterations/005/quality/quality-evidence.md`

- [ ] T001 [US3] [assigned_to: Reviewer] [effort: 0.3 SP] Create the Iteration 005 audit scaffold in `specs/049-pipeline-hardening-intake/iterations/005/quality/quality-evidence.md` with sections for runtime wording coverage, docs/skills/reviewer guidance parity, legacy `user-profile.yml` compatibility proof, and explicit Proposal `120` non-drift checks (Trace: FR-036, FR-037, SC-007, TG-016, TG-017)

---

## Phase 2: Foundational (Shared Display Contract)

**Purpose**: Lock the shared capability-label mapping over the unchanged persisted-key and internal-lens contracts.

**⚠️ CRITICAL**: Downstream docs, skills, and tests should not freeze until this mapping is authoritative.

**Verification**: Inspect `scripts/internal/user-profile.ps1` and confirm a shared display-label/presentation layer exists without renaming persisted keys or internal persona IDs.

- [ ] T002 [US3] [assigned_to: Implementer] [effort: 0.6 SP] Add shared display-label metadata and capability-vs-lens summary helpers in `scripts/internal/user-profile.ps1` so user-facing surfaces render `Product Strategy`, `UX/UI Design`, `Software Architecture`, and `AI Delivery Planning` while preserving `expertise.ai_research_project_management` and `ai-researcher-project-manager` unchanged (Trace: FR-032, FR-033, FR-034, FR-035, TG-017, TG-018)

**Checkpoint**: The wording contract is fixed; downstream runtime/docs/tests can now align to one source of truth.

---

## Phase 3: User Story 3 - Capability/Confidence Dial Correction (Priority: P3)

**Goal**: Correct all user-facing Proposal `141` surfaces so users see capability/confidence dials, while internal persona lenses, persisted keys, and Iteration `004` scope remain unchanged.

**Independent Test**: Run `pwsh -File tests/integration/f049-i003-intake-engine-tests.ps1` and confirm a legacy `user-profile.yml` fixture loads without migration, still routes through the same internal lens IDs, and renders `AI Delivery Planning` plus capability-dial wording across audited runtime/help surfaces.

### Tests for User Story 3

- [ ] T003 [US3] [assigned_to: Reviewer] [effort: 0.6 SP] Add a legacy compatibility fixture in `tests/integration/fixtures/f049-legacy-user-profile/legacy-user-profile.yml` and failing Proposal `141` assertions in `tests/integration/f049-i003-intake-engine-tests.ps1` proving existing `expertise.ai_research_project_management` data loads unchanged, keeps the same internal lens routing, and displays `AI Delivery Planning` in user-facing output (Trace: FR-033, FR-034, FR-037, SC-007, TG-018)

### Implementation for User Story 3

- [ ] T004 [US3] [assigned_to: Implementer] [effort: 0.8 SP] Update first-run/profile wording in `scripts/internal/user-profile.ps1` and `scripts/specrew-start.ps1` so the four saved values are presented as capability/confidence dials instead of job-title identities, without changing persisted keys, schema shape, or internal persona routing (Trace: FR-032, FR-033, FR-034, FR-035, TG-017, TG-018)
- [ ] T005 [P] [US3] [assigned_to: Implementer] [effort: 0.4 SP] Refresh `/specrew-user-profile` help copy in `.github/skills/specrew-user-profile/SKILL.md`, `.claude/skills/specrew-user-profile/SKILL.md`, and `.agents/skills/specrew-user-profile/SKILL.md` to use the four capability-area labels and explain that stable persisted keys/internal persona IDs stay unchanged behind the display layer (Trace: FR-032, FR-034, FR-035, FR-036, TG-018)
- [ ] T006 [P] [US3] [assigned_to: Implementer] [effort: 0.5 SP] Align specify/intake wording in `.github/prompts/speckit.specify.prompt.md`, `.github/agents/speckit.specify.agent.md`, `extensions/specrew-speckit/scripts/intake/Invoke-SpecifyIntake.ps1`, and `.specify/extensions/specrew-speckit/scripts/intake/Invoke-SpecifyIntake.ps1` so dials control question depth while personas remain internal lenses and shipped/mirrored guidance stays in lockstep (Trace: FR-032, FR-035, FR-036, TG-017, TG-018)
- [ ] T007 [P] [US3] [assigned_to: Implementer] [effort: 0.5 SP] Update downstream docs and reviewer/operator guidance in `docs/user-guide.md`, `README.md`, `.specrew/team/agents/reviewer.md`, `.agents/agents/reviewer.md`, `extensions/specrew-speckit/squad-templates/agents/reviewer/charter.md`, and `.specify/extensions/specrew-speckit/squad-templates/agents/reviewer/charter.md` so Proposal `141` consistently describes capability dials, preserves Iteration `004` as Proposal `120`, and forbids schema/persona-ID migration (Trace: FR-035, FR-036, TG-016, TG-017, TG-018)

**Checkpoint**: Runtime surfaces, skills, mirrored intake guidance, and reviewer/docs surfaces now share one bounded Proposal `141` contract.

---

## Phase 4: Polish & Cross-Cutting Verification

**Purpose**: Close the slice with explicit compatibility proof and audited-surface evidence.

- [ ] T008 [US3] [assigned_to: Reviewer] [effort: 0.7 SP] Run the updated compatibility/audited-surface checks and record evidence in `tests/integration/f049-i003-intake-engine-tests.ps1` and `specs/049-pipeline-hardening-intake/iterations/005/quality/quality-evidence.md`, including exact command results, audited surface inventory, legacy `user-profile.yml` proof, and explicit traceability to `FR-032..FR-037`, `SC-007`, and `TG-016..TG-018` (Trace: FR-037, SC-007, TG-016, TG-017, TG-018)

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1 (Setup)**: No dependencies; creates the bounded evidence target.
- **Phase 2 (Foundational)**: Depends on Phase 1; blocks downstream wording/doc/test alignment.
- **Phase 3 (US3)**: Depends on Phase 2.
- **Phase 4 (Polish)**: Depends on Phase 3 completion.

### Task Dependency Chain

```text
T001 -> T002 -> T003 -> T004 -> (T005, T006, T007) -> T008
```

### Dependency Notes

- `T003` must fail first against the legacy fixture before implementation is considered complete.
- `T004` establishes the shipped runtime wording that `T005-T007` mirror into docs, skills, prompts, and reviewer guidance.
- `T005-T007` can proceed in parallel once `T004` lands.
- `T008` is the closeout gate and must verify that no task drifted into schema migration, persona-ID renames, Iteration `004` edits, or Iteration `003` architecture changes.

---

## Parallel Execution Example: User Story 3

```text
Task: "T005 Refresh /specrew-user-profile help copy in .github/.claude/.agents skill files"
Task: "T006 Align specify/intake wording in .github prompt/agent and extension/.specify intake scripts"
Task: "T007 Update docs and reviewer/operator guidance in docs/, README.md, and reviewer charter files"
```

---

## Implementation Strategy

### MVP First

1. Complete `T001-T004` to lock the wording contract, protect stable keys/IDs, and make the runtime surfaces truthful.
2. Validate the legacy compatibility fixture from `T003` before broadening doc/guidance changes.

### Incremental Delivery

1. Land the shared display contract (`T002`).
2. Make runtime/profile/start surfaces truthful (`T004`).
3. Parallelize docs/skills/reviewer guidance (`T005-T007`).
4. Finish with evidence and compatibility proof (`T008`).

### Scope Boundaries

- Proposal `141` is a bounded wording/guidance/evidence correction slice only.
- If any task uncovers required key/schema migration, internal persona-ID rename, or Iteration `004` drift, stop and replan instead of expanding this package.

---

## Task Envelope Summary

- **Total Tasks**: 8
- **Primary Scope**: 4.4 SP
- **Repair Reserve**: 0.6 SP
- **Setup**: 1 task
- **Foundational**: 1 task
- **US3**: 5 tasks
- **Polish**: 1 task
- **Parallel Opportunities**: 3 tasks (`T005-T007`)

## Traceability Coverage Summary

- **FR-032**: T002, T004, T005, T006
- **FR-033**: T002, T003, T004
- **FR-034**: T002, T003, T004, T005
- **FR-035**: T002, T004, T005, T006, T007
- **FR-036**: T001, T005, T006, T007
- **FR-037**: T001, T003, T008
- **SC-007**: T001, T003, T008
- **TG-016**: T001, T007, T008
- **TG-017**: T001, T002, T004, T006, T007, T008
- **TG-018**: T002, T003, T004, T005, T006, T007, T008

## Notes

- The historical feature-level file `specs/049-pipeline-hardening-intake/tasks.md` remains the closed Iteration `003` package and is intentionally left untouched to avoid rewriting closed work.
- This iteration package is intentionally stored at `specs/049-pipeline-hardening-intake/iterations/005/tasks.md` so Proposal `141` planning stays isolated from Iteration `003` history and Iteration `004` reservation scope.
