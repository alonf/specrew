# Iteration Plan: 001

**Schema**: v1
**Spec**: [../../spec.md](../../spec.md)
**Status**: complete
**Capacity**: 20.5/24.0 story_points
**Started**: 2026-04-19
**Completed**: 2026-05-01

## Summary

Iteration 1 is the MVP phase. It delivers the core Specrew operating model: a working `specrew init` command for greenfield bootstrapping, the four-phase iteration lifecycle (planning, execution, review/demo, retrospective), active drift detection, and the five baseline crew roles. By the end of this iteration, a user can run a complete spec-governed iteration from start to finish with traceability enforcement and governance compliance active. The fully enumerated iteration is 24.0 pts against a 20.5-pt proven baseline, so execution is staged openly: Iter 1a commits 20.5 pts of core MVP work (including the V-R7-1 detection-API spike that precedes T-011) and Iter 1b retains 3.5 pts of downstream documentation/validation follow-through after the MVP gate. For Specrew self-development, the corrected MVP scope also makes the GitHub operational mirror explicit: authoritative task artifacts drive issue/board synchronization, and execution follows the standard GitHub branch/PR review path.

**Primary Focus**: Iteration execution engine + bootstrap command  
**Target FRs**: FR-001–FR-006, FR-008–FR-011, FR-013, FR-018, FR-022 + governance decisions DD-366, DD-369, DD-370, DD-371, DD-373  
**Target User Stories**: US-1 (Bootstrap), US-2 (Run Iteration), US-3 (Drift Detection)  
**Deferred to Iteration 2+**: FR-007 (configurable effort model), FR-012 (collision detector), FR-016 (upgrade preservation), FR-019 (programmatic task resume), FR-020 (brownfield bootstrap)

---

## Requirements Traceability

| Spec Ref | Requirement | This Iteration | Owner | Notes |
|----------|-------------|----------------|-------|-------|
| FR-001 | Spec Kit extension + Squad-native configuration | ✅ Deploy scaffolded extension to runtime | Implementer | Extension skeleton exists from Iter 0; now deploy to runtime |
| FR-002 | `specrew init` command (greenfield) | ✅ Standalone CLI implementation | Implementer | Orchestrates specify init + squad init, validates versions, installs extensions |
| FR-003 | Spec as authoritative source (spec-authority directive) | ✅ Implement directive + enforcement | Planner | Embedded in Spec Steward charter; enforces pre-task spec validation |
| FR-004 | Five baseline crew roles | ✅ Define + deploy roles | Planner | Spec Steward, Planner, Implementer, Reviewer, Retro Facilitator merged into .squad/team.md |
| FR-005 | Iteration lifecycle (4 phases) | ✅ Planning + Review/Demo ceremonies | Planner | Retro ceremony uses Squad's built-in; execution phase routed by state.md |
| FR-006 | Planning ceremony (tasks from spec) | ✅ Squad ceremony implementation | Implementer | Ceremony generates plan.md with task-to-requirement links |
| FR-008 | Drift detection (active, per-task) | ✅ Drift-check skill + fallback | Planner | Skill compares output to requirement; post-task hook invokes; fallback: runs at review gate |
| FR-009 | Review/Demo gate with verdicts | ✅ Squad ceremony + verdict recording | Implementer | Per-task verdict capture in review.md |
| FR-010 | Retrospective artifact generation | ✅ Integration with Squad built-in ceremony | Planner | Squad's retro ceremony + Specrew-specific prompts produce retro.md |
| FR-011 | Governance scaffold (constitution, config, roles) | ✅ Downstream templates via `specrew init` | Planner | Downloaded by init; user customizes; not copied from Specrew's own |
| FR-013 | Documented integration surfaces only | ✅ Validate no undocumented hooks used | Implementer | Reuse Iter 0 spike findings (R1) |
| FR-018 | Traceability directive (task-to-requirement) | ✅ Implemented as squad directive + template | Planner | Every task records FR link, owner, effort; enforced in planning ceremony |
| FR-022 | Agent detection + consent-gated opt-in | ✅ Detection probes, interactive consent prompt, non-interactive flags, config persistence | Implementer | Detect Copilot plus Agent HQ-exposed delegated agents (Copilot/Claude/Codex); prompt user for per-agent consent; persist to iteration-config.yml. No cost/billing surface — consent is the only gate. |
| R7 validation (V-R7-1) | Confirm Copilot/Agent HQ detection API shape before T-011 builds on it | ✅ Spike + documented findings | Implementer | Verifies detection call returns a deterministic list of selectable agents; documents graceful degradation when Agent HQ is not exposed for the user. Blocks T-011. |
| DD-366, DD-369, DD-371, DD-373 | Specrew self-development board sync as a derived operational mirror | ✅ `speckit.taskstoissues` + Squad GitHub Project wiring | Implementer | Authoritative local task artifacts stay primary; GitHub Issues/Projects are synchronized mirrors |
| DD-369, DD-370 | Task-authoritative execution with standard GitHub PR review | ✅ Squad worktree + branch + PR-per-task execution model | Implementer | Keeps execution aligned to local task artifacts while routing human review through normal PR flow |
| US-1 | Bootstrap Specrew in new project | ✅ via `specrew init` | — | Greenfield only (brownfield deferred to Iter 2) |
| US-2 | Run planned iteration end-to-end | ✅ Full lifecycle: plan → execute → review → retro | — | Verification scenario: bootstrap → create simple spec → 1 iteration → verify artifacts |
| US-3 | Spec Steward detects + resolves drift | ✅ Drift detection + resolution flow | — | Drift-check skill produces report; Spec Steward decides: update-spec / revert / flag |
| US-4 | Configure effort measurement | ⏳ Deferred to Iter 2 (FR-007) | — | Iter 1 uses defaults; effort model tuning later |

---

## Acceptance Criteria (Iteration-Level Gate)

1. **`specrew init` works end-to-end**: Greenfield repo → run command → Spec Kit installed, Squad installed, Specrew extensions deployed, 5 baseline roles configured, governance scaffolds created
2. **Planning ceremony produces iteration plan**: Plan.md generated with tasks mapped to spec requirements, effort estimates assigned, owners recorded
3. **Execution state persists**: state.md tracks completed tasks; provides snapshot for manual continuity review
4. **Drift detection works**: Drift-check skill invoked; detects contradictions between task output and source requirement; writes drift-log.md
5. **Review/Demo gate functional**: review.md produced with per-task verdicts (pass/needs-work/blocked); overall iteration verdict recorded
6. **Retrospective artifact created**: retro.md contains estimation accuracy, drift summary, process notes, improvement actions
7. **Traceability enforced**: All tasks in plan.md link to source spec requirements or explicit governance decisions; all drift events reference source requirements; 100% traceability
8. **Full iteration can run**: Bootstrap → create spec with 3+ FRs → run planning → execute ≥2 tasks → run review → run retro → verify all artifacts exist and are contract-compliant
9. **Spec authority enforced**: Spec Steward can detect and propose resolution for drift; iterations cannot proceed without spec-aligned requirements
10. **No integration blockers**: Specrew extensions load alongside other extensions without errors; no critical platform gaps
11. **Operational GitHub flow is aligned**: Specrew self-development can sync authoritative tasks to GitHub Issues/Projects and execute work through per-task branches/PR review without making the board authoritative

**Review gate (Iteration 1 acceptance)**: Worf verifies all artifacts exist, all four phases completed, drift detection active, traceability 100%, the GitHub operational mirror is wired to authoritative task artifacts, and at least one end-to-end iteration is documented. Alon approves MVP readiness before Iteration 2 planning begins.

---

## Governance Consistency Check

Validation that this plan respects Specrew's own governance model.

| Gate | Verdict | Notes |
|------|---------|-------|
| **Spec Authority** | ✅ PASS | All tasks trace either to in-scope FRs or to explicit governance design decisions in `spec.md` covering board automation and GitHub PR review. Deferred work (FR-007, FR-012, FR-016, FR-019, FR-020) is explicitly marked. No scope exists without a spec reference. |
| **Traceability** | ✅ PASS | Traceability Matrix (above) maps each task to enabling requirements and unblocks tested FRs. T-021–T-023 link to acceptance requirements; T-024–T-025 link to the authoritative GitHub governance decisions in `spec.md`. |
| **Ownership** | ✅ PASS | All tasks assigned to role names (Implementer, Planner) with explicit responsibility. |
| **Capacity** | ✅ PASS | 24.0 pts are fully enumerated, which is 3.5 pts over the 20.5-pt baseline. The plan keeps that overage visible and explicitly stages T-020–T-023 (3.5 pts) into Iter 1b, leaving Iter 1a at 20.5 pts — exactly on the proven baseline. The added 0.5-pt V-R7-1 spike is folded into Iter 1a to de-risk T-011. |
| **Artifact Consistency** | ✅ PASS | Task table mirrors traceability matrix. Capacity math verified. All artifacts contract-compliant per iteration-artifacts.md. |
| **Execution Support** | ✅ PASS | All enabling work defined: state.md template for task tracking, drift-log schema, review verdict format. No ambiguity about "complete." |

---

## Tasks

| Task | Title | Requirement | Story | Effort | Owner | Status | Agent | Actual | Verdict |
| ---- | ----- | ----------- | ----- | ------ | ----- | ------ | ----- | ------ | ------- |
| T-001 | `specrew init`: Detect and validate dependencies | FR-002, FR-013 | US-1 | 1 | Implementer | done | copilot-agent | 1 | pass |
| T-002 | `specrew init`: Install missing Spec Kit/Squad | FR-002 | US-1 | 1 | Implementer | done | copilot-agent | 1 | pass |
| T-003 | `specrew init`: Run specify init (greenfield) | FR-002, FR-011 | US-1 | 0.5 | Implementer | done | copilot-agent | 0.5 | pass |
| T-004 | `specrew init`: Run squad init (greenfield) | FR-002 | US-1 | 0.5 | Implementer | done | copilot-agent | 0.5 | pass |
| T-005 | `specrew init`: Deploy Spec Kit extension | FR-002, FR-001 | US-1 | 1 | Implementer | done | copilot-agent | 1 | pass |
| T-006 | `specrew init`: Deploy Squad skills | FR-002, FR-001 | US-1 | 1 | Implementer | done | copilot-agent | 1 | pass |
| T-007 | `specrew init`: Deploy Squad ceremonies | FR-002, FR-001 | US-1 | 1 | Implementer | done | copilot-agent | 1 | pass |
| T-008 | `specrew init`: Merge 5 baseline roles | FR-002, FR-004 | US-1 | 1 | Planner | done | copilot-agent | 1 | pass |
| T-009 | `specrew init`: Scaffold governance artifacts (downstream constitution, config, role assignments) | FR-002, FR-011 | US-1 | 1 | Planner | done | copilot-agent | 1 | pass |
| T-010 | `specrew init`: Version validation + error reporting | FR-002, FR-013 | US-1 | 0.5 | Implementer | done | copilot-agent | 0.5 | pass |
| V-R7-1 | Spike: Validate Copilot / Agent HQ detection API shape (research.md R7) — blocks T-011 | FR-022 | US-1 | 0.5 | Implementer | done | copilot-agent | 0.5 | pass |
| T-011 | `specrew init`: Detect agents + interactive consent (FR-022) | FR-022 | US-1 | 1.5 | Implementer | done | copilot-agent | 1.5 | pass |
| T-012 | Implement drift-check skill | FR-008, FR-018 | US-3 | 1.5 | Planner | done | copilot-agent | 1.5 | pass |
| T-013 | Implement spec-authority directive (Spec Steward charter) | FR-003, FR-004 | US-3 | 0.5 | Planner | done | copilot-agent | 0.5 | pass |
| T-014 | Implement traceability directive (Planner charter) | FR-006, FR-018 | US-2 | 0.5 | Planner | done | copilot-agent | 0.5 | pass |
| T-015 | Implement drift-reporting directive (Implementer + Reviewer charters) | FR-008, FR-018 | US-2 | 0.5 | Planner | done | copilot-agent | 0.5 | pass |
| T-016 | Implement planning ceremony (generate plan.md from spec) | FR-005, FR-006 | US-2 | 2 | Implementer | done | copilot-agent | 2 | pass |
| T-017 | Implement review/demo ceremony (verdict verdicts + review.md) | FR-005, FR-009 | US-2 | 2 | Implementer | done | copilot-agent | 2 | pass |
| T-018 | Integrate Squad's retrospective ceremony with Specrew prompts | FR-005, FR-010 | US-2 | 1 | Planner | done | copilot-agent | 1 | pass |
| T-019 | Implement iteration artifact storage (.iterations/NNN/ directory structure) | FR-018 | US-2 | 0.5 | Implementer | done | copilot-agent | 0.5 | pass |
| T-020 | Document downstream use flow (bootstrap → plan → execute → review → retro) | FR-002, FR-005 | US-2 | 0.5 | Planner | done | copilot-agent | 0.5 | pass |
| T-021 | Create integration test: bootstrap-to-iteration (greenfield → 1 full iteration) | FR-005, FR-006 | US-1, US-2 | 1.5 | Implementer | done | copilot-agent | 1.5 | pass |
| T-022 | Create end-to-end scenario test (drift detection + resolution) | FR-008, FR-009 | US-3 | 1 | Planner | done | copilot-agent | 1 | pass |
| T-023 | Validate CI pipeline (markdownlint, PSScriptAnalyzer, test runner) | FR-013 | US-2 | 0.5 | Implementer | done | copilot-agent | 0.5 | pass |
| T-024 | Wire authoritative task-to-issue sync and GitHub Project board updates (`speckit.taskstoissues` + Squad) | DD-366, DD-369, DD-371, DD-373 | US-2 | 0.5 | Implementer | done | copilot-agent | 0.5 | pass |
| T-025 | Codify Squad worktree + branch + PR-per-task execution model | DD-369, DD-370 | US-2 | 1 | Implementer | done | copilot-agent | 1 | pass |

**Total Effort**: 24.0 story points (includes 0.5-pt V-R7-1 spike)

---

## Capacity Revision

Three carryover tasks have been added to Iteration 1 from earlier planning sessions:

| Task | Title | Story | Effort | Rationale |
| ---- | ----- | ----- | ------ | --------- |
| V-R7-1 | Spike: Validate Copilot / Agent HQ detection API shape | US-1 | 0.5 | Confirms detection-call shape and graceful degradation before T-011 builds the user-facing detection/consent flow. De-risks a new platform dependency. |
| T-011 | `specrew init`: Detect agents + interactive consent (FR-022) | US-1 | 1.5 | Agent HQ integration: GitHub Copilot can expose Claude/Codex as delegated agents. Users need explicit consent (FR-022). Essential for MVP bootstrap. Depends on V-R7-1. |
| T-024 | Wire authoritative task-to-issue sync and GitHub Project board updates (`speckit.taskstoissues` + Squad) | US-2 | 0.5 | Specrew self-development requires Squad-managed GitHub Issue/Project mirroring from authoritative plan/task artifacts; carryover was named in narrative but absent from the task table. |
| T-025 | Codify Squad worktree + branch + PR-per-task execution model | US-2 | 1 | Specrew execution must keep local task artifacts authoritative while routing human review through the standard GitHub PR path; this operating-model carryover must be explicit in the plan. |

**Proven baseline from Iteration 0**: 20.5 pts  
**Fully enumerated Iteration 1 total**: 24.0 pts  
**Over baseline**: 3.5 pts (17.1% over baseline)

**Staging response**: The carryover items (agent detection, board management, worktree/PR model) plus the V-R7-1 detection spike push the fully enumerated iteration to 24.0 pts. Rather than hiding that overage, the plan explicitly stages the downstream follow-through below so Iter 1a lands on the proven 20.5-pt baseline:

| Deferred Task | Reason | Target |
| ------------- | ------ | ------ |
| T-020, T-021, T-022, T-023 (Downstream flow docs + validation) | Move 3.5 pts of post-gate documentation/integration/scenario/CI work to Iteration 1b so the initial execution slice stays below baseline | Iter 1b |

**Committed split**:

- **Iter 1a (core MVP scope)**: V-R7-1, T-001–T-019, T-024–T-025 (20.5 pts) — detection-API spike, bootstrap, directives, ceremonies, board wiring, and execution-model guardrails in scope. This lands on the proven baseline. Acceptance gate: governance directives, board mirror, and PR workflow are functional; detection API behavior is validated.
- **Iter 1b (stabilization sprint, same iteration, follows gate)**: T-020–T-023 (3.5 pts) — downstream flow documentation, integration test suite, drift scenario validation, and CI pipeline hardening. Acceptance gate: all validation work passes and no regressions remain.

This keeps the iteration cohesive (single feature delivery) without pretending the extra 3.5 pts disappeared: the total remains 24.0 pts, while the first execution slice is intentionally held to 20.5 pts before the stabilization pass.

**Approval required**: Spec Steward (Picard) and Alon sign off on the 1a/1b split before execution begins.

## Phase Baseline

| Phase | Estimated Effort | Notes |
| ----- | ---------------- | ----- |
| Planning | 2 | T-016 planning ceremony: task decomposition, spec-to-requirement mapping, traceability validation |
| Discovery/Spikes | 0.5 | V-R7-1: validate Copilot/Agent HQ detection API shape before T-011 builds on it |
| Implementation | 16 | T-001–T-015, T-018–T-019, T-024–T-025: CLI/bootstrap, directives, retro integration, artifact storage, board wiring, execution-model guardrails |
| Review | 2 | T-017 review/demo ceremony: verdict capture, traceability verification, MVP gate |
| Rework | 3.5 | T-020–T-023: downstream-flow documentation plus integration/scenario/CI validation; staged in Iter 1b post-gate |

**Rationale**: Foundation work (Iter 0) demonstrated predictable 0-variance delivery at 20.5 pts. The added carryovers for agent detection (1.5 pts), board-management wiring (0.5 pts), and the worktree/PR execution model (1 pt), plus the V-R7-1 detection spike (0.5 pts), raise the fully enumerated Iteration 1 plan to 24.0 pts. The phase baseline keeps that total honest: 0.5 pts of pre-implementation spike (V-R7-1), 2 pts of planning implementation (T-016), 16 pts of core delivery work, 2 pts of review-gate implementation (T-017), and 3.5 pts of explicitly staged follow-through in Iter 1b (T-020–T-023). Post-retro recalibration is expected based on actual delivery variance.

---

### What's In Scope (Iteration 1 MVP)

- **Greenfield bootstrap only**: `specrew init` works on empty or fresh repos with Spec Kit/Squad detected/installed
- **Four-phase lifecycle**: Planning, Execution, Review/Demo, Retrospective ceremonies/phases all active
- **Active drift detection**: Drift-check skill invokes per-task or at review gate (per Iter 0 spike findings)
- **Traceability**: Every task links to a spec requirement; 100% coverage enforced
- **Governance directives**: Spec Authority, Traceability, Drift Reporting embedded in agent charters
- **Iteration artifacts**: plan.md, state.md (task tracking), drift-log.md, review.md, retro.md all created and contract-compliant
- **Board synchronization**: `speckit.taskstoissues` + Squad GitHub Project wiring is explicitly completed so authoritative plan/task artifacts mirror to GitHub Issues and the GitHub Projects V2 board
- **Execution model**: Squad execution uses per-task worktrees/branches and standard GitHub PR review while local task artifacts remain authoritative
- **Five baseline roles**: Spec Steward, Planner, Implementer, Reviewer, Retro Facilitator merged into `.squad/team.md`
- **Staged follow-through**: T-020–T-023 remain part of Iteration 1, but downstream flow docs plus integration/scenario/CI validation are intentionally held for Iter 1b after the MVP gate

### What's Deferred to Iteration 2+

- **Brownfield bootstrap** (FR-020): Adding Specrew to projects with existing Spec Kit/Squad config → Iter 2
- **Configurable effort model** (FR-007): Allowing projects to customize effort units and capacity → Iter 2
- **Collision detector** (FR-012): Five-class collision scan (hooks, roles, commands, artifacts, ceremonies) → Iter 3
- **Programmatic task resume** (FR-019): Automated resume command from last completed task → Iter 2
- **Process scorer** (FR-015): Ceremony adherence scoring → Iter 2
- **Outcome scorer + eval harness** (FR-015): Requirement coverage + acceptance scenario scoring → Iter 3

### Task Sequencing & Dependencies

**Phase 1: Bootstrap CLI** (T-001 through T-010)

- T-001 (detect deps) → T-002 (install) → T-003/T-004 (init platforms) → T-005/T-006/T-007 (deploy extensions) → T-008/T-009 (config roles) → T-010 (validate versions)
- **Blockers**: T-003 and T-004 block T-005, T-006, T-007. T-005 blocks T-008. T-008 blocks T-009.

**Phase 2: Agent Detection + Governance Directives** (V-R7-1, T-011 through T-015)

- V-R7-1 (detection-API spike) runs before T-011 to validate the Copilot/Agent HQ detection call and document graceful degradation. Can run in parallel with Phase 1.
- T-011 (agent detect + consent) extends the bootstrap spine after Phase 1, consuming V-R7-1's findings.
- T-012 (drift-check) → T-013/T-014/T-015 (directives)
- **Blockers**: V-R7-1 blocks T-011. T-011 depends on Phase 1 bootstrap scaffolding. T-012 must complete before T-015; T-013 and T-014 can proceed once charter templates are available.

**Phase 3: Ceremonies** (T-016 through T-018)

- T-016 (planning) → T-017 (review/demo) → T-018 (retrospective)
- **Blockers**: T-016 must complete before T-017 (review depends on plan structure).

**Phase 4: Supporting Work** (T-019, T-020, T-024, T-025)

- T-019 (artifact storage) can proceed in parallel after Phase 1 (needed for T-016).
- T-020 (documentation) can proceed after T-016/T-017/T-018.
- T-024 requires T-016 so issue/board sync is wired from the authoritative iteration task output.
- T-025 follows T-024 so the per-task worktree/branch/PR path operates against the synced task context and standard review flow.

**Phase 5: Testing** (T-021, T-022, T-023)

- T-021 requires T-001–T-011 (bootstrap) + T-016–T-018 (ceremonies).
- T-022 requires T-012 (drift-check) + T-017 (review ceremony).
- T-023 runs independently; can execute anytime.

### Effort Calibration

**Rationale for task estimates**:

- **T-001 (1 pt)**: Dependency detection — multiple code paths for Spec Kit/Squad present/absent. Error handling for version mismatches.
- **T-002 (1 pt)**: Installation via official package managers. Version pinning, fallback handling.
- **T-003/T-004 (0.5 pts each)**: Orchestrating existing `specify init` and `squad init` commands. Low complexity; mostly pass-through.
- **T-005/T-006/T-007 (1 pt each)**: Copying files to correct locations, updating manifests (.specify/extensions.yml, .squad/ceremonies.md, .squad/team.md). Medium complexity.
- **T-008 (1 pt)**: Merging 5 role definitions into existing team config. Collision handling, name resolution.
- **T-009 (1 pt)**: Scaffolding three governance artifact files (downstream constitution, iteration config, role assignments). Medium complexity, clear inputs/outputs.
- **T-010 (0.5 pts)**: Version validation + error messages. Low complexity.
- **V-R7-1 (0.5 pts)**: Detection-API spike — confirm `gh copilot` / Agent HQ metadata surface, document call shape, handle Agent-HQ-unavailable path. Output: notes consumed by T-011. Low complexity, high de-risk value.
- **T-011 (1.5 pts)**: Agent detection + consent — Copilot / Agent HQ agent probing, consent messaging, and config persistence across interactive/non-interactive paths. Consent is the only gate; no cost/billing surface.
- **T-012 (1.5 pts)**: Drift-check skill — highest complexity. Comparing output to requirement (parsing, semantic matching, diff logic), recording drift events, producing human-readable report.
- **T-013–T-015 (0.5 pts each)**: Embedding directive text into agent charters. Low complexity, clear templates.
- **T-016 (2 pts)**: Planning ceremony — parse spec requirements, generate tasks, assign effort, estimate capacity, produce plan.md with full traceability. Core intelligence task.
- **T-017 (2 pts)**: Review ceremony — capture verdicts per task, produce review.md, validate traceability. Medium complexity.
- **T-018 (1 pt)**: Integrate Squad's retro ceremony template with Specrew-specific prompts. Low-medium complexity.
- **T-019 (0.5 pts)**: Define .iterations/NNN/ directory structure, create state.md template. Low complexity.
- **T-020 (0.5 pts)**: User-facing documentation of the iteration workflow. Low complexity.
- **T-021 (1.5 pts)**: Integration test — end-to-end bootstrap + 1 iteration. Requires all tasks T-001–T-018 to work together.
- **T-022 (1 pt)**: Scenario test for drift detection. Setup spec, execute contradicting task, verify drift caught, test resolution flow.
- **T-023 (0.5 pts)**: Validate existing CI pipeline (configured in Iter 0). Low complexity.
- **T-024 (0.5 pts)**: Wire `speckit.taskstoissues` output into Squad's GitHub Project flow. Narrow operational wiring; no new product surface.
- **T-025 (1 pt)**: Codify the per-task worktree/branch/PR path so execution remains task-authoritative while preserving standard GitHub review. Medium complexity, process-enabling work.

**Estimation philosophy**: Foundation work (Iter 0) was predictable and hit exactly (20.5/20.5 pts, 0% variance). MVP work (Iter 1) involves more LLM-driven behavior, orchestration complexity, and ceremony design. Estimates reflect Iter 0 baseline calibration. This should be recalibrated after Iter 1 retro based on actual delivery.

### Spec Steward Responsibilities (This Iteration)

- **Pre-execution**: Validate that all 26 tasks (25 implementation + V-R7-1 spike) in this plan map to spec requirements or explicit governance design decisions (`spec.md` board/PR operating rules). Ensure no scope exists outside the spec.
- **During execution**: Run drift-check skill after each task to detect any task output that contradicts the source requirement. Flag and propose resolution (spec update, revert, human review).
- **At review gate**: Review all drift-log.md events. Approve verdicts. If drift exists, confirm resolution before iteration closes.
- **At retro**: Capture what the team learned about estimation, process, and drift detection patterns. Suggest calibration for Iteration 2.

---

## Deferred Work Tracking

Work explicitly deferred to post-MVP iterations:

| Requirement | Reason | Target Iteration |
| ----------- | ------ | --------------- |
| FR-007 (Configurable effort model) | Iteration 1 uses hardcoded defaults; tuning requires multiple iterations of calibration data | Iteration 2 |
| FR-012 (Five-class collision detector) | Bootstrap only checks hook + role name collisions (addressed in T-010). Full 5-class scan (+ command, artifact, ceremony) deferred | Iteration 3 |
| FR-016 (Upgrade preservation) | Deferred pending brownfield bootstrap work | Iteration 3 |
| FR-020 (Brownfield bootstrap) | Requires analysis of brownfield merge edge cases; deferred to allow Iter 1 MVP to stabilize first | Iteration 2 |
| FR-019 (Programmatic task resume) | Iteration 1 provides state.md task tracking; programmatic resume command + automation deferred | Iteration 2 |

**Capacity Note**: The fully enumerated Iteration 1 plan is 23.5 pts because all three carryovers are represented explicitly. That is 3.0 pts above the 20.5-pt proven baseline, so T-020–T-023 are staged into Iter 1b and Iter 1a is intentionally capped at 20.0 pts. The 0.5-pt gap is deliberate execution buffer, not hidden scope removal.

---

## Success Criteria (For Iteration 1 Closure)

1. ✅ `specrew init` command exists and works on greenfield repos
2. ✅ Bootstrap creates governance scaffold + merges 5 baseline roles
3. ✅ Planning ceremony generates iteration plan with task-to-requirement links
4. ✅ Drift-check skill detects contradictions between output and spec
5. ✅ Review/Demo ceremony produces verdicts + review.md
6. ✅ Retrospective integration produces retro.md with all required sections
7. ✅ All iteration artifacts exist and validate against contract (iteration-artifacts.md)
8. ✅ Traceability: 100% of tasks link to source spec requirements or governance decisions
9. ✅ GitHub operational mirror works: authoritative tasks sync to GitHub Issues/Projects and execution follows the standard branch/PR review path
10. ✅ Integration test passes: bootstrap → spec → plan → execute → review → retro
11. ✅ Drift scenario test passes: detect contradicting output, surface to Spec Steward, propose resolution
12. ✅ CI pipeline passes: markdownlint, PSScriptAnalyzer, unit + integration tests all green
13. ✅ Review gate passed: Worf confirms all artifacts, governance active, no integration blockers
14. ✅ No regressions: Iteration 0 artifacts still valid, no platform compatibility issues

**Verdict gate**: Alon approves MVP readiness. Team consensus on operating policy rules (per .squad/identity/now.md) required before Iteration 2 can begin.
