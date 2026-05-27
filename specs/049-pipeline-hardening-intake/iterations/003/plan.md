# Iteration Plan: 003

**Schema**: v1
**Spec**: [../../spec.md](../../spec.md)
**Status**: planning
**Capacity**: 19.25/20 story_points
**Started**: 2026-05-28
**Completed**:

<!--
  Validator schema (canonical, enforced by validate-governance.ps1):
  - Iteration Status MUST be one of:
      planning | executing | reviewing | retro | complete | abandoned
    (Common mistakes the validator REJECTS: `approved`, `in-progress`, `done`, `ready`.)
  - Capacity format MUST be `<consumed>/<cap> <effort_unit>` with NO trailing prose on that line.
    Append explanatory notes in the Notes section at the bottom instead.
  - Task Status (in the Tasks table) MUST be one of:
      planned | in-progress | done | needs-rework | deferred | blocked
    (Note `in-progress` uses a hyphen, not an underscore. `done` not `completed`.)
-->

## Summary

Iteration `003` is the **unified 17-20 SP medium slice** that integrates persona-driven `/speckit.specify` intake with user-level expertise-profile persistence for Feature `049`. The slice builds on the foundational Proposal `063` 4-persona intake framework (FR-008..FR-011) and extends it with expertise-dial integration (FR-023..FR-027): users self-rate their expertise across 4 personas at Specrew first-run, the system persists this profile in `user-profile.yml` for reuse across all Specrew projects, the `/specrew-user-profile` slash command allows users to view/edit/reset their profile, and `/speckit.specify` consumes the profile to personalize question depth (7-10 Senior, 4-6 Standard, 1-3 Learning, "I'm new" escape hatch) and enable stack-aware auto-decisions with Proposal 053 transparency annotations (SC-005). This unified slice keeps expertise profiling durable and user-controlled while reducing intake friction across projects.

## Scope Summary

| Requirement | Summary | Stories |
| ----------- | ------- | ------- |
| FR-008 | `/speckit.specify` MUST support exactly 4 target personas: Product Manager (business rules, P1/P2 journeys, MVP), UX/UI Specialist (interface state, accessibility, micro-animations), Architect (schemas, data contracts, system boundaries, clean-architecture), and AI Researcher / Project Manager (capacity planning, specialist pairings, safe-parallelism, agent charters). | US3 |
| FR-009 | The system MUST supply the approved 12-category intake catalog covering: (1) Problem/pain, (2) Customer/users, (3) Security/authn/authz, (4) Scale/performance, (5) Hosting model, (6) Framework, (7) Architecture style, (8) Additional NFRs, (9) Time/budget, (10) MVP scope, (11) Technology stack, (12) Domain research. | US3 |
| FR-010 | Intake MUST dynamically branch into Mode A (Direct Confirmation when input ≥80% coverage and user expertise ≥7), Mode B (Targeted Clarify when 50-79% coverage with isolated weak spots or 4-6 expertise), or Mode C (Full Interview when <50% coverage or user expertise 1-3) based on both input completeness and user expertise level. | US3 |
| FR-011 | Intake forms MUST support `"Other"` and `"I don't know, you decide"` options on every question, triggering proactive agent domain research and stack-aware defaulting when selected. | US3 |
| FR-023 | `/speckit.specify` MUST prompt the user to self-rate their expertise on a 1-10 scale for each of the 4 personas (Software Architecture, UI/UX, Product Management, AI Research / Project Management), with an escape hatch option `"I'm new, you decide"` per persona. | US3 |
| FR-024 | System MUST persist user expertise profile in a YAML file (`user-profile.yml`) at Windows `$env:USERPROFILE\.specrew\user-profile.yml` or Unix `~/.specrew/user-profile.yml`, with schema fields: `schema`, `specrew_version_at_creation`, `created_at`, `last_updated_at`, `user_name` (optional), `expertise.software_architecture`, `expertise.ui_ux`, `expertise.product_management`, `expertise.ai_research_project_management`, `preferences.preferred_intake_depth`. | US3 |
| FR-025 | System MUST deploy `/specrew-user-profile` slash command with subcommands: `show` (display current profile), `edit` (interactive update), `reset` (clear and restart). Command MUST be deployed to `.claude/skills/`, `.github/skills/`, and `.agents/skills/` using F-021 slash-command machinery. | US3 |
| FR-026 | `specrew start` MUST detect first-run (user-profile.yml absent), prompt for expertise self-rating before bootstrap completes, save the profile, and surface a profile summary in `start-context.json` and `start-summary.md`. On subsequent runs, `specrew start` MUST read the profile and surface the profile summary plus reset/edit guidance. | US3 |
| FR-027 | `/speckit.specify` MUST consume the persisted `user-profile.yml` and apply expertise-level-driven question depth rules: 7-10 (Senior) surface senior-level nuanced questions with minimal auto-decisions; 4-6 (Standard) surface standard questions plus explicit decision-confirmation; 1-3 (Learning) auto-decide using stack-aware defaults and surface decisions via Proposal 053 transparency pattern with `[AUTO-DECIDED: <decision>]` annotations. | US3 |

## Governance Consistency Check

| Gate | Verdict | Notes |
| ---- | ------- | ----- |
| Spec Authority | PASS | Scope matches the expanded Iteration `003` roadmap in `spec.md` section on "Persona-Driven Intake with Expertise Dials & User Profile Persistence", feature `plan.md` medium-slice description, and upcoming task decomposition. Explicitly unified across persona-intake foundation (FR-008..FR-011, SC-003) and expertise-profile integration (FR-023..FR-027, SC-005). |
| Traceability | PASS | Every execution task maps directly to `FR-008` through `FR-011` and `FR-023` through `FR-027`, plus `TG-003`, `TG-006`, `TG-007`, `TG-009`, `TG-010`, `SC-003`, and `SC-005` where applicable. Expertise-dial requirements explicitly anchor to user-level profile governance (TG-009, TG-012). |
| Capacity | PASS | Authorized slice is 17-20 SP (expanded from 9.5 SP small slice), inside the feature plan's Iteration `003` 20 SP nominal budget band. Expansion accommodates expertise-dial persistence, slash-command deployment, and specrew-start integration complexity. |
| Roadmap Discipline | PASS | Iteration `001` remains closed history; Iteration `002` is complete and closed. Iteration `003` now unified to include both persona intake and expertise integration. Iteration `004` remains untouched and reserved for Proposal `120` five-pillar bypass detection. |
| Boundary Slice Discipline | PASS | Iteration `003` is explicitly unified: 4 personas + 12-category catalog (FR-008..FR-011) **plus** expertise-dial persistence and slash-command deployment (FR-023..FR-027). NO multi-trigger expansion, NO project-level profile composition, NO validator integration. Only user-level expertise profiling is authorized. |
| Before-Implement Readiness | PENDING | Owner, effort, dependency order, evidence target, and bounded file surfaces will be validated during task decomposition phase. Expertise-dial requirements must validate cross-platform user-profile.yml handling and slash-command deployment parity across `.claude/skills/`, `.github/skills/`, and `.agents/skills/`. |

## Tasks

| Task | Title | Requirement | Story | Effort | Owner | Owner File Globs | Status | Agent | Actual | Verdict |
| ---- | ----- | ----------- | ----- | ------ | ----- | ---------------- | ------ | ----- | ------ | ------- |
| T012 | [P] Add failing bounded-slice persona intake coverage to integration tests | FR-008, FR-009, TG-006, TG-007, SC-003 | US3 | 1.50 | Reviewer | `tests/integration/substantive-interaction-model-iteration2.ps1`, `tests/integration/skill-templates.tests.ps1` | planned | | | |
| T013 | Update `/speckit.specify` agent and prompt to offer only 4 approved personas | FR-008, TG-006, TG-007, SC-003 | US3 | 1.50 | Implementer | `.github/prompts/speckit.specify.prompt.md`, `.github/agents/speckit.specify.agent.md` | planned | | | |
| T014 | Update workflow to drive the 12-category intake catalog | FR-009, TG-006, TG-007, SC-003 | US3 | 2.00 | Implementer | `.specify/workflows/speckit/workflow.yml`, `.specify/workflow-registry.json` | planned | | | |
| T015 | Implement Mode A/B/C branching and prompt sequencing | FR-010, TG-006, TG-007, SC-003 | US3 | 2.00 | Implementer | `.github/prompts/speckit.specify.prompt.md`, `.specify/workflows/speckit/workflow.yml` | planned | | | |
| T016 | Add `"Other"` and `"I don't know, you decide"` fallback guidance and stack-aware defaulting | FR-011, TG-006, TG-007, SC-003 | US3 | 1.50 | Implementer | `.github/prompts/speckit.specify.prompt.md`, `.github/agents/speckit.specify.agent.md`, `.specify/workflows/speckit/workflow.yml` | planned | | | |
| T017 | Run bounded persona-intake regression and record Iteration `003` verification evidence | FR-008, FR-009, FR-010, FR-011, TG-006, TG-007, SC-003 | US3 | 1.00 | Reviewer | `tests/integration/substantive-interaction-model-iteration2.ps1`, `tests/integration/skill-templates.tests.ps1`, `specs/049-pipeline-hardening-intake/iterations/003/quality/quality-evidence.md` | planned | | | |
| T018 | Create user-profile.yml schema and cross-platform path handling in specrew-start | FR-024, TG-009, TG-012 | US3 | 1.00 | Implementer | `scripts/specrew-start.ps1` | planned | | | |
| T018a | [P] Create `/specrew-user-profile` slash command in .claude/skills/ | FR-025, TG-009 | US3 | 0.50 | Implementer | `.claude/skills/specrew-user-profile.md` | planned | | | |
| T018b | [P] Create `/specrew-user-profile` slash command in .github/skills/ | FR-025, TG-009 | US3 | 0.50 | Implementer | `.github/skills/specrew-user-profile.md` | planned | | | |
| T018c | [P] Create `/specrew-user-profile` slash command in .agents/skills/ | FR-025, TG-009 | US3 | 0.50 | Implementer | `.agents/skills/specrew-user-profile.md` | planned | | | |
| T019 | Implement `specrew start` first-run expertise self-rating prompt and persistence | FR-023, FR-026, TG-009, TG-010, TG-012 | US3 | 1.25 | Implementer | `scripts/specrew-start.ps1` | planned | | | |
| T019a | Update `/speckit.specify` to consume expertise profile and apply question-depth rules | FR-027, SC-005, TG-010, TG-011 | US3 | 1.50 | Implementer | `.github/prompts/speckit.specify.prompt.md`, `.github/agents/speckit.specify.agent.md`, `.specify/workflows/speckit/workflow.yml` | planned | | | |
| T019b | Implement Proposal 053 transparency annotations for auto-decisions | FR-027, SC-005, TG-010, TG-011 | US3 | 0.75 | Implementer | `.github/prompts/speckit.specify.prompt.md`, `.github/agents/speckit.specify.agent.md`, `.specify/workflows/speckit/workflow.yml` | planned | | | |
| T020 | Update specrew-start to surface profile summary in start-context.json and start-summary.md | FR-026, TG-010 | US3 | 0.75 | Implementer | `scripts/specrew-start.ps1` | planned | | | |
| T020a | [P] Add failing test coverage for expertise-dial persistence and slash command functionality | FR-024, FR-025, FR-026, SC-005 | US3 | 1.00 | Reviewer | `tests/integration/substantive-interaction-model-iteration2.ps1`, `tests/integration/skill-templates.tests.ps1` | planned | | | |
| T020b | Add integration tests for expertise-dial-driven question depth and SC-005 metrics | FR-027, SC-005, TG-010, TG-011 | US3 | 1.25 | Reviewer | `tests/integration/substantive-interaction-model-iteration2.ps1`, `tests/integration/skill-templates.tests.ps1` | planned | | | |
| T020c | [P] Run complete expertise-dial regression suite and record full acceptance evidence | FR-008, FR-009, FR-010, FR-011, FR-023, FR-024, FR-025, FR-026, FR-027, SC-003, SC-005, TG-006, TG-007, TG-009, TG-010, TG-011, TG-012 | US3 | 0.75 | Reviewer | `specs/049-pipeline-hardening-intake/iterations/003/quality/quality-evidence.md` | planned | | | |

## Required Quality Gates

| Gate | Target | Notes |
| ---- | ------ | ----- |
| Persona completeness | required | `/speckit.specify` MUST present exactly 4 personas (PM, UX/UI, Architect, AI Researcher / PM) and MUST NOT silently widen to additional personas beyond the approved slice. |
| Catalog completeness | required | The 12-category intake catalog MUST be present and MUST NOT be abbreviated or extended beyond the approved Proposal `063` v1 catalog. |
| Mode branching correctness | required | Input-quality assessment MUST correctly route to Mode A (≥80%), Mode B (50-79%), or Mode C (<50%) without skipping assessment or forcing a single mode. |
| Escape hatch presence | required | Every multi-choice question MUST offer `"Other"` and `"I don't know, you decide"` options; the agent MUST NOT auto-resolve when user explicitly selects `"I don't know"`. |
| Expertise-dial persistence | required (NEW) | User-profile.yml MUST be created on first Specrew invocation (specrew start), persisted across projects, and readable by /speckit.specify. Windows and Unix paths MUST both work. |
| Expertise-dial application | required (NEW) | /speckit.specify MUST apply expertise dials to question depth: 7-10 (Senior) with nuanced questions, 4-6 (Standard) with confirmation prompts, 1-3 (Learning) with auto-decisions + transparency annotations. |
| Slash-command functionality | required (NEW) | /specrew-user-profile show/edit/reset MUST work in all three deployment locations (.claude/skills/, .github/skills/, .agents/skills/). Changes MUST persist to user-profile.yml immediately. |
| SC-005 success criteria | required (NEW) | Evidence of ≥30% question reduction for dial 7-10, ≥40% decision count reduction for dial 1-3, and no regression in clarify-question count. Generated specs MUST include [AUTO-DECIDED: ...] annotations for dial 1-3. |
| Slice boundary discipline | required | Iteration `003` MUST remain unified but internally scoped: FR-008..FR-011 (persona intake) + FR-023..FR-027 (expertise dials). NO clarify-trigger, iteration-kickoff-trigger, mid-feature-pivot-trigger, project-level-profile, or validator-integration expansion. |
| Acceptance evidence | required | Iteration `003` verification recorded in `specs/049-pipeline-hardening-intake/iterations/003/quality/quality-evidence.md` documenting all gate passes and SC-005 metrics. |

## Planned Execution Order

### Phase A: Persona-Driven Intake Foundation (T012-T017)

1. **T012 first (red-path test coverage)** — establish failing test coverage for the 4-persona selection, 12-category catalog, and Mode A/B/C branching BEFORE prompt/workflow changes land.
2. **T013 next (persona selection surface)** — update the specify agent and prompt to present exactly 4 personas and remove any existing auto-persona logic that bypasses user selection.
3. **T014 parallel with T015 (catalog + mode branching)** — implement the 12-category catalog structure in workflow configuration and Mode A/B/C branching logic in prompts/workflow. These can proceed independently once persona selection is stable.
4. **T016 next (escape hatches)** — add `"Other"` and `"I don't know, you decide"` options across all multi-choice questions and implement stack-aware defaulting behavior.
5. **T017 last (green-path verification)** — run the integration regression path and record acceptance evidence only after T012-T016 are present in the committed tree.

### Phase B: User-Level Expertise Profile Persistence (T018-T020)

6. **T018 (profile schema)** — create user-profile.yml schema and cross-platform path handling; runs in parallel with Phase A testing work.
7. **T018a, T018b, T018c (slash-command deployment)** — create `/specrew-user-profile` skills in all three deployment locations; can proceed in parallel once T018 schema is stable.
8. **T019 (first-run prompt)** — implement expertise self-rating prompt in specrew-start; depends on T018 schema being complete.
9. **T020 (profile summary)** — update specrew-start to surface profile summary in context and summary artifacts; depends on T019 being complete.

### Phase C: Expertise Dial Consumption (T019a-T019b)

10. **T019a (question-depth rules)** — update `/speckit.specify` to consume expertise profile and apply expertise-driven question depth rules; depends on T018-T020 (profile infrastructure) and completes Phase B.
11. **T019b (transparency annotations)** — implement Proposal 053 annotations for auto-decisions; depends on T019a being complete.

### Phase D: Integration Testing and Acceptance Evidence (T020a-T020c)

12. **T020a (red-path expertise tests)** — add failing test coverage for expertise-dial persistence, slash-command functionality, and cross-platform profile handling.
13. **T020b (green-path dial tests)** — add tests for dial-driven question depth and SC-005 metrics; depends on T019a-T019b implementation being complete.
14. **T020c last (full regression + evidence)** — run complete expertise-dial regression suite and record Iteration `003` full acceptance evidence; depends on T020a-T020b being present in committed tree.

## Boundary Commit Cadence

| Commit Group | Tasks | Why this boundary exists |
| ------------ | ----- | ------------------------ |
| Red-path test baseline (persona) | T012 | Establishes failing test coverage for the approved persona-intake slice before any prompt/workflow implementation changes land. |
| Persona selection | T013 | Locks the 4-persona selection surface independently so catalog and mode-branching work can reference the stable persona list. |
| Catalog + mode branching | T014-T015 | Implements the 12-category structure and Mode A/B/C sequencing as a cohesive intake-flow change. |
| Escape hatches | T016 | Adds fallback options and stack-aware defaulting as the final intake-behavior layer. |
| Persona intake verification | T017 | Preserves an auditable acceptance-evidence commit group after persona-intake implementation surfaces pass the regression path. |
| Expertise profile schema & infrastructure | T018, T018a, T018b, T018c | Establishes user-profile.yml schema, cross-platform path handling, and slash-command deployment across all three skill locations before first-run and summary logic lands. |
| First-run prompt + profile summary | T019, T020 | Implements specrew-start expertise self-rating and profile summary surfacing as a cohesive user-facing change. |
| Expertise dial consumption | T019a-T019b | Implements question-depth adaptation and transparency annotations as the intake-consumption layer. |
| Red-path expertise tests | T020a | Establishes failing test coverage for expertise-dial persistence, slash-command functionality, and cross-platform handling before consumption logic lands. |
| Green-path dial tests | T020b | Tests expertise-dial-driven question depth, SC-005 metrics, and acceptance evidence readiness. |
| Full expertise-dial acceptance | T020c | Records complete Iteration `003` acceptance evidence after all persona-intake and expertise-dial surfaces pass integrated regression. |

## Dependencies

### Phase A: Persona-Driven Intake (T012-T017)

- `T012` is the prerequisite for the whole persona-intake phase because red-path test coverage must exist before implementation changes land.
- `T013` depends on `T012` and must complete before `T014-T015` because catalog and mode logic reference the persona selection surface.
- `T014` and `T015` both depend on `T013` and can proceed in parallel once persona selection is stable.
- `T016` depends on `T014-T015` because escape-hatch options are layered on top of the existing catalog and mode-branching structure.
- `T017` depends on `T012-T016` because verification evidence must validate the complete committed intake slice, not partial working-tree state.

### Phase B: Expertise Profile Persistence (T018-T020)

- `T018` is the prerequisite for Phase B because the schema and path handling must exist before first-run prompt logic lands.
- `T018a`, `T018b`, `T018c` depend on `T018` and can proceed in parallel because all three slash-command skills use the same underlying schema and persistence logic.
- `T019` depends on `T018` because the first-run prompt must use the established user-profile.yml schema and path handling.
- `T020` depends on `T019` because profile summary must render the persisted expertise values from T019.

### Phase C: Expertise Dial Consumption (T019a-T019b)

- `T019a` depends on `T018-T020` (expertise profile infrastructure) because speckit.specify must read the persisted user-profile.yml to apply question-depth rules.
- `T019a` also depends on `T013` (persona selection) because expertise-dial routing references persona expertise lenses.
- `T019b` depends on `T019a` because transparency annotations require the expertise-driven auto-decision logic to be in place.

### Phase D: Integration Testing and Acceptance (T020a-T020c)

- `T020a` (red-path expertise tests) can start in parallel with Phase B but must complete before `T020b` and `T020c`.
- `T020b` depends on `T019a-T019b` (expertise dial consumption implementation) because question-depth tests validate the implemented behavior.
- `T020c` depends on `T020a-T020b` and `T017` (persona-intake verification) because full acceptance evidence must validate both persona-intake and expertise-dial integrated behavior.

### Cross-Phase Sequencing

- Phase A (T012-T017) and Phase B (T018-T020) can proceed in parallel because they touch disjoint file surfaces (specs/prompts/workflows vs scripts/skills).
- Phase C (T019a-T019b) depends on completion of Phase A (persona selection) and Phase B (profile infrastructure).
- Phase D (T020a-T020c) is the final phase and validates all prior phases integrated.
- `T017` depends on `T012-T016` because verification evidence must validate the complete committed intake slice, not partial working-tree state.

## Effort Model

| Setting | Value | Notes |
| ------- | ----- | ----- |
| Effort Unit | story_points | Unit used in task effort, capacity, and retro variance. |
| Capacity per Iteration | 20 | Maximum planned effort before overcommit guidance applies. |
| Iteration Bounding | scope | `scope` keeps Iteration `003` fixed to the approved unified medium slice: persona intake (FR-008..FR-011) + expertise-profile integration (FR-023..FR-027). |
| Time Limit (hours) | n/a | Only applies when iteration bounding is `time`. |
| Overcommit Threshold | 1.0 | Warn planners when total estimated effort exceeds 20 story_points (capacity 20 x threshold 1.0). Iteration `003` is currently allocated 17-20 SP (at or near capacity). |
| Defer Strategy | manual | Task decomposition phase will validate effort distribution. If final task estimates exceed 20 SP, manual replanning may be required; deferred scope will be explicitly marked for future iterations outside F-049. |
| Calibration Enabled | true | Retrospective variance should be recorded after execution completes. Compare actual effort to estimates for future Specrew capacity planning calibration. |

## Concurrency Rationale

- Current roster snapshot: Implementer and Reviewer are the only active owners for this iteration slice.
- Technology and scope signals: Spec Kit prompts, agent definitions, workflow YAML configuration, and integration test regression dominate; no runtime orchestration, concurrency-heavy behavior, or shared-state mutation is in scope.
- Parallel opportunities: `T014` and `T015` can proceed in parallel once `T013` is stable because catalog configuration (workflow YAML) and mode-branching logic (prompt sequencing) touch different file surfaces.
- Sequential constraints: `T012` must complete first (red-path baseline), then `T013` (persona selection), then `T014+T015` (catalog + mode), then `T016` (escape hatches), then `T017` (verification evidence).

## Lessons from Iteration 002

### Applied Lessons

1. **Three-boundary commit cadence retained** — Iteration `002` proved the three-boundary cadence (primary content → packaging/discoverability → evidence) lands exactly to plan and stays audit-friendly. Iteration `003` reuses this pattern: red-path baseline → persona/catalog/mode → escape hatches → evidence.
2. **Manual Pillar 5 discipline as execution baseline** — Iteration `002` applied manual committed-tree presence checks during `T011` before acceptance was claimed. Iteration `003` will follow the same discipline: `T017` verification evidence MUST confirm that all cited production files exist in the committed tree under review before acceptance is recorded.
3. **Boundary commit discipline enforcement** — Iteration `002` recorded `boundary-commit-discipline-violations: 0`. Iteration `003` will preserve this discipline by ensuring each planned boundary commit group lands as a separate, atomic commit without mixing unrelated surfaces.

### Explicit Non-Application

- **Mechanized Pillar 5 enforcement** remains deferred to Iteration `004`. Iteration `003` will continue using manual reviewer discipline for committed-tree presence checks rather than implementing validator automation.
- **Approval-vs-tree freshness gate** remains manual during Iteration `003`. The reviewer will verify that the Tree Under Review and cited production files match `HEAD` during `T017`, but validator-side freshness comparison waits for Iteration `004`.

## Explicit Out-of-Scope Boundaries

To keep Iteration `003` visibly unified and internally scoped, the following expansions are explicitly OUT OF SCOPE and deferred beyond F-049's four-iteration roadmap:

| Out-of-Scope Item | Rationale | Future Home |
| ----------------- | --------- | ----------- |
| Multi-trigger expansion (clarify / iteration-kickoff / mid-feature-pivot modes) | Proposal `063` Pillar 5 describes these triggers, but Iteration `003` remains scoped to `/speckit.specify` intake + expertise-profile user management only, to keep the slice focused and independently testable. | Future F-050+ feature or later Proposal `063` phase |
| Project-level expertise overrides | Iteration `003` implements user-level profile only (persisted across all Specrew projects); project-level overrides (e.g., "use Standard dial for this project even though user is Senior") remain future scope. | Future F-050+ feature when project-level profile governance ships |
| Multi-user shared profile | `user-profile.yml` is single-user only; shared team profiles (e.g., "Architect dial for this team = 6") remain out of scope. | Future F-050+ feature when shared governance ships |
| Structured output (`interview.yml`) | Proposal `063` Pillar 6 describes `.specrew/intake/interview.yml` as the canonical intake record, but Iteration `003` focuses on the user-facing intake flow only. Structured intake artifact persistence is deferred. | Future F-050+ feature or later Proposal `063` phase |
| Implicit expertise detection | Deriving expertise dial from answer quality or interaction patterns (remains Proposal 015 future scope). | Future feature when Proposal 015 ships |
| 5th+ personas | E.g., Data Engineer, DevOps/SRE, Security Engineer, Domain Expert personas remain listed as future expansion candidates but are out of scope for this feature. | Future F-050+ feature when additional personas ship |

## Notes

- **Iteration `003` is a unified 17-20 SP medium slice**, combining the Proposal `063` 4-persona `/speckit.specify` intake foundation (FR-008..FR-011, SC-003) with user-level expertise-profile persistence and management (FR-023..FR-027, SC-005). The unified scope acknowledges that intake and expertise profiling are intertwined: users set their expertise once at Specrew first-run and the system tailors subsequent intake to that profile.
- **Expertise-dial semantics**: Users self-rate 1-10 per persona with an "I'm new, you decide" escape hatch. System applies depth rules: 7-10 (Senior) surface nuanced questions with minimal auto-decisions, 4-6 (Standard) include confirmation prompts, 1-3 (Learning) auto-decide with stack-aware defaults + Proposal 053 transparency annotations `[AUTO-DECIDED: ...]`. No silent auto-decisions; all low-expertise choices are surfaced for user review.
- **User-profile.yml is user-level**, persisted at `$env:USERPROFILE\.specrew\user-profile.yml` (Windows) or `~/.specrew/user-profile.yml` (Unix), and reusable across all Specrew projects. This eliminates the need to re-enter expertise for every project while maintaining user control via `/specrew-user-profile show/edit/reset`.
- **Boundary discipline**: Iteration `003` is explicitly bounded to `/speckit.specify` intake behavior + user-profile management. NO multi-trigger expansion (clarify/iteration-kickoff/mid-feature-pivot), NO project-level profile overrides, NO validator integration. All such expansion remains future work outside F-049's approved roadmap.
- **Slash-command deployment parity**: `/specrew-user-profile` MUST deploy to `.claude/skills/`, `.github/skills/`, and `.agents/skills/` using F-021 machinery. All three locations must have identical behavior and reflect changes to the shared `user-profile.yml`.
- **Mirror parity expectation**: Changes to `.github/prompts/` and `.github/agents/` surfaces in this iteration do NOT require `.specify/` mirror updates because Spec Kit prompts/agents are not part of the mirrored deployment surface. However, any changes to `extensions/specrew-speckit/scripts/` would require `.specify/extensions/` mirror parity (not in scope for Iteration 003; Iteration 004 owns validator changes).
- **Task composition**: Current task scope (T012-T017 from previous plan) will be expanded during task decomposition to include new tasks for expertise-dial requirements (FR-023..FR-027). Effort estimates will sum persona-intake tasks (~9.5 SP) plus expertise-profile tasks (~7-10 SP) to reach the 17-20 SP capacity.
- **Iteration `002` retro lessons applied**: Three-boundary commit cadence, manual Pillar 5 discipline, and boundary-commit-discipline-violations=0 target carry forward from Iteration `002` execution, adapted to the unified persona + expertise-dial scope.
- **SC-005 measurement**: Success is empirically measured by (a) ≥30% reduction in question count for dial 7-10 vs Mode C baseline, (b) ≥40% reduction in user-faced decision count for dial 1-3 via auto-decide + transparency, (c) no regression in clarify-question count across all expertise levels, and (d) Mode-A rate remaining ≥70% (spec quality gate).
