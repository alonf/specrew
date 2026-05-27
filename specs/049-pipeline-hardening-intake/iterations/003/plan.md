# Iteration Plan: 003

**Schema**: v1
**Spec**: [../../spec.md](../../spec.md)
**Status**: planning
**Capacity**: 9.5/20 story_points
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

Iteration `003` is the bounded Proposal `063` persona-driven `/speckit.specify` intake slice for Feature `049`. Execution remains tightly scoped to tasks `T012-T017` and requirements `FR-008`, `FR-009`, `FR-010`, `FR-011`, and `SC-003`: implement exactly **4 personas** (Product Manager, UX/UI Specialist, Architect, AI Researcher / Project Manager), present the **12-category intake catalog**, branch cleanly across Modes A/B/C based on input completeness, and support `"Other"` / `"I don't know, you decide"` fallback options. This slice intentionally excludes multi-trigger expansion (clarify / iteration-kickoff / mid-feature-pivot modes), profile composition, and validator integration — those remain deferred to future work outside this feature's approved roadmap.

## Scope Summary

| Requirement | Summary | Stories |
| ----------- | ------- | ------- |
| FR-008 | `/speckit.specify` MUST support exactly 4 target personas: Product Manager (business rules, P1/P2 journeys, MVP), UX/UI Specialist (interface state, accessibility, micro-animations), Architect (schemas, data contracts, system boundaries, clean-architecture), and AI Researcher / Project Manager (capacity planning, specialist pairings, safe-parallelism, agent charters). | US3 |
| FR-009 | The system MUST supply the approved 12-category intake catalog covering: (1) Problem/pain, (2) Customer/users, (3) Security/authn/authz, (4) Scale/performance, (5) Hosting model, (6) Framework, (7) Architecture style, (8) Additional NFRs, (9) Time/budget, (10) MVP scope, (11) Technology stack, (12) Domain research. | US3 |
| FR-010 | Intake MUST dynamically branch into Mode A (Direct Confirmation when input ≥80% coverage), Mode B (Targeted Clarify when 50-79% coverage with isolated weak spots), or Mode C (Full Interview when <50% coverage) based on input completeness assessment. | US3 |
| FR-011 | Intake forms MUST support `"Other"` and `"I don't know, you decide"` options on every question, triggering proactive agent domain research and stack-aware defaulting when selected. | US3 |

## Governance Consistency Check

| Gate | Verdict | Notes |
| ---- | ------- | ----- |
| Spec Authority | PASS | Scope matches the approved Iteration `003` roadmap in `spec.md`, feature `plan.md`, and `tasks.md`. Explicitly bounded to Proposal `063` `/speckit.specify` slice only. |
| Traceability | PASS | Every execution task maps directly to `FR-008`, `FR-009`, `FR-010`, `FR-011`, `TG-006`, `TG-007`, and `SC-003` where applicable. |
| Capacity | PASS | Authorized slice is `9.5/20` story points, inside the feature plan's Iteration `003` 10 SP budget band. |
| Roadmap Discipline | PASS | Iteration `001` remains closed history; Iteration `002` is complete and closed. Iteration `004` remains untouched and reserved for Proposal `120` five-pillar bypass detection. |
| Boundary Slice Discipline | PASS | Iteration `003` is explicitly bounded: NO clarify/iteration-kickoff/mid-feature-pivot trigger expansion, NO profile composition (Proposal `052`), NO validator integration (deferred). Only `/speckit.specify` intake behavior is authorized. |
| Before-Implement Readiness | PENDING | Owner, effort, dependency order, evidence target, and bounded file surfaces will be validated before `before-implement` boundary. |

## Tasks

| Task | Title | Requirement | Story | Effort | Owner | Owner File Globs | Status | Agent | Actual | Verdict |
| ---- | ----- | ----------- | ----- | ------ | ----- | ---------------- | ------ | ----- | ------ | ------- |
| T012 | [P] Add failing bounded-slice persona intake coverage to integration tests | FR-008, FR-009, TG-006, TG-007, SC-003 | US3 | 1.50 | Reviewer | `tests/integration/substantive-interaction-model-iteration2.ps1`, `tests/integration/skill-templates.tests.ps1` | planned | | | |
| T013 | Update `/speckit.specify` agent and prompt to offer only 4 approved personas | FR-008, TG-006, TG-007, SC-003 | US3 | 1.50 | Implementer | `.github/prompts/speckit.specify.prompt.md`, `.github/agents/speckit.specify.agent.md` | planned | | | |
| T014 | Update workflow to drive the 12-category intake catalog | FR-009, TG-006, TG-007, SC-003 | US3 | 2.00 | Implementer | `.specify/workflows/speckit/workflow.yml`, `.specify/workflow-registry.json` | planned | | | |
| T015 | Implement Mode A/B/C branching and prompt sequencing | FR-010, TG-006, TG-007, SC-003 | US3 | 2.00 | Implementer | `.github/prompts/speckit.specify.prompt.md`, `.specify/workflows/speckit/workflow.yml` | planned | | | |
| T016 | Add `"Other"` and `"I don't know, you decide"` fallback guidance and stack-aware defaulting | FR-011, TG-006, TG-007, SC-003 | US3 | 1.50 | Implementer | `.github/prompts/speckit.specify.prompt.md`, `.github/agents/speckit.specify.agent.md`, `.specify/workflows/speckit/workflow.yml` | planned | | | |
| T017 | Run bounded persona-intake regression and record Iteration `003` verification evidence | FR-008, FR-009, FR-010, FR-011, TG-006, TG-007, SC-003 | US3 | 1.00 | Reviewer | `tests/integration/substantive-interaction-model-iteration2.ps1`, `tests/integration/skill-templates.tests.ps1`, `specs/049-pipeline-hardening-intake/iterations/003/quality/quality-evidence.md` | planned | | | |

## Required Quality Gates

| Gate | Target | Notes |
| ---- | ------ | ----- |
| Persona completeness | required | `/speckit.specify` MUST present exactly 4 personas (PM, UX/UI, Architect, AI Researcher / PM) and MUST NOT silently widen to additional personas beyond the approved slice. |
| Catalog completeness | required | The 12-category intake catalog MUST be present and MUST NOT be abbreviated or extended beyond the approved Proposal `063` v1 catalog. |
| Mode branching correctness | required | Input-quality assessment MUST correctly route to Mode A (≥80%), Mode B (50-79%), or Mode C (<50%) without skipping assessment or forcing a single mode. |
| Escape hatch presence | required | Every multi-choice question MUST offer `"Other"` and `"I don't know, you decide"` options; the agent MUST NOT auto-resolve when user explicitly selects `"I don't know"`. |
| Slice boundary discipline | required | Iteration `003` MUST remain bounded to `/speckit.specify` only. NO clarify-trigger, iteration-kickoff-trigger, or mid-feature-pivot-trigger expansion is authorized. NO profile composition. NO validator integration. |
| Acceptance evidence | required | `T017` records Iteration `003` verification in `specs/049-pipeline-hardening-intake/iterations/003/quality/quality-evidence.md`. |

## Planned Execution Order

1. **T012 first (red-path test coverage)** — establish failing test coverage for the 4-persona selection, 12-category catalog, and Mode A/B/C branching BEFORE prompt/workflow changes land.
2. **T013 next (persona selection surface)** — update the specify agent and prompt to present exactly 4 personas and remove any existing auto-persona logic that bypasses user selection.
3. **T014 parallel with T015 (catalog + mode branching)** — implement the 12-category catalog structure in workflow configuration and Mode A/B/C branching logic in prompts/workflow. These can proceed independently once persona selection is stable.
4. **T016 next (escape hatches)** — add `"Other"` and `"I don't know, you decide"` options across all multi-choice questions and implement stack-aware defaulting behavior.
5. **T017 last (green-path verification)** — run the integration regression path and record acceptance evidence only after T012-T016 are present in the committed tree.

## Boundary Commit Cadence

| Commit Group | Tasks | Why this boundary exists |
| ------------ | ----- | ------------------------ |
| Red-path test baseline | T012 | Establishes failing test coverage for the approved persona-intake slice before any prompt/workflow implementation changes land. |
| Persona selection | T013 | Locks the 4-persona selection surface independently so catalog and mode-branching work can reference the stable persona list. |
| Catalog + mode branching | T014-T015 | Implements the 12-category structure and Mode A/B/C sequencing as a cohesive intake-flow change. |
| Escape hatches | T016 | Adds fallback options and stack-aware defaulting as the final intake-behavior layer. |
| Verification evidence | T017 | Preserves an auditable acceptance-evidence commit group after the implementation surfaces pass the regression path. |

## Dependencies

- `T012` is the prerequisite for the whole iteration because red-path test coverage must exist before implementation changes land.
- `T013` depends on `T012` and must complete before `T014-T015` because catalog and mode logic reference the persona selection surface.
- `T014` and `T015` both depend on `T013` and can proceed in parallel once persona selection is stable.
- `T016` depends on `T014-T015` because escape-hatch options are layered on top of the existing catalog and mode-branching structure.
- `T017` depends on `T012-T016` because verification evidence must validate the complete committed intake slice, not partial working-tree state.

## Effort Model

| Setting | Value | Notes |
| ------- | ----- | ----- |
| Effort Unit | story_points | Unit used in task effort, capacity, and retro variance. |
| Capacity per Iteration | 20 | Maximum planned effort before overcommit guidance applies. |
| Iteration Bounding | scope | `scope` keeps Iteration `003` fixed to the approved Proposal `063` small slice only. |
| Time Limit (hours) | n/a | Only applies when iteration bounding is `time`. |
| Overcommit Threshold | 1.0 | Warn planners when total estimated effort exceeds 20 story_points (capacity 20 x threshold 1.0). |
| Defer Strategy | manual | Any future deferral would require explicit replanning; none is authorized inside this slice. |
| Calibration Enabled | true | Retrospective variance should be recorded after execution completes. |

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

To keep Iteration `003` visibly bounded to the approved Proposal `063` small slice, the following expansions are explicitly OUT OF SCOPE and deferred beyond F-049's four-iteration roadmap:

| Out-of-Scope Item | Rationale | Future Home |
| ----------------- | --------- | ----------- |
| Multi-trigger expansion (clarify / iteration-kickoff / mid-feature-pivot modes) | Proposal `063` Pillar 5 describes these triggers, but Iteration `003` is intentionally scoped to `/speckit.specify` only to keep the slice small and independently testable. | Future F-050+ feature or later Proposal `063` phase |
| Profile composition (Proposal `052`) | Proposal `063` Pillar 8 describes domain-specific profile layering, but F-049's approved roadmap does not include Proposal `052` implementation. | Future F-050+ feature when Proposal `052` ships |
| Validator integration (Proposal `063` Pillar 7) | Proposal `063` Pillar 7 describes validator rules blocking `/speckit.plan` if `interview.yml` is incomplete, but F-049's approved roadmap reserves validator work for Iteration `004` Proposal `120` scope only. | Future F-050+ feature or later Proposal `063` phase |
| Structured output (`interview.yml`) | Proposal `063` Pillar 6 describes `.specrew/intake/interview.yml` as the canonical intake record, but Iteration `003` focuses on the user-facing intake flow only. Structured output persistence is deferred. | Future F-050+ feature or later Proposal `063` phase |
| Expertise dial (Proposal `015`) | Proposal `063` Pillar 9 describes expertise-aware Mode A/B/C bias, but Proposal `015` is not approved for F-049. Input-quality assessment in Iteration `003` uses only coverage percentage, not user-declared expertise. | Future feature when Proposal `015` ships |

## Notes

- **Iteration `003` is a deliberately small slice** of the full Proposal `063` scope. The approved slice focuses on `/speckit.specify` intake behavior only: 4 personas, 12-category catalog, Mode A/B/C branching, and escape hatches. All other Proposal `063` pillars remain deferred.
- **Boundary discipline**: Iteration `003` MUST NOT silently widen into clarify-trigger, iteration-kickoff-trigger, or mid-feature-pivot-trigger expansion. Any such widening would violate the approved roadmap and conflict with Iteration `004` scope.
- **Mirror parity expectation**: Changes to `.github/prompts/` and `.github/agents/` surfaces in this iteration do NOT require `.specify/` mirror updates because Spec Kit prompts/agents are not part of the mirrored deployment surface. Only changes to `extensions/specrew-speckit/scripts/` require `.specify/extensions/` mirror parity, which is out of scope for Iteration `003`.
- **Test parallelization**: `T012` is marked `[P]` in `tasks.md` to signal that test authoring can run in parallel with other validation-first work, but Iteration `003` execution will run `T012` sequentially before `T013` to establish the red-path baseline first.
- **Iteration `002` retro lessons applied**: Three-boundary commit cadence, manual Pillar 5 discipline, and boundary-commit-discipline-violations=0 target all carry forward from Iteration `002` execution.
