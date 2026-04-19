# Iteration Plan: 001

**Schema**: v1
**Spec**: [../../spec.md](../../spec.md)
**Status**: planning
**Capacity**: 0/20.5 story_points
**Started**: 2026-04-19
**Completed**:

## Summary

Iteration 1 is the MVP phase. It delivers the core Specrew operating model: a working `specrew init` command for greenfield bootstrapping, the four-phase iteration lifecycle (planning, execution, review/demo, retrospective), active drift detection, and the five baseline crew roles. By the end of this iteration, a user can run a complete spec-governed iteration from start to finish with traceability enforcement and governance compliance active.

**Primary Focus**: Iteration execution engine + bootstrap command  
**Target FRs**: FR-001–FR-006, FR-008–FR-011, FR-013, FR-018  
**Target User Stories**: US-1 (Bootstrap), US-2 (Run Iteration), US-3 (Drift Detection), US-4 (Effort Measurement)  
**Deferred to Iteration 2**: FR-007 (configurable effort model), FR-012 (collision detector), FR-016 (upgrade preservation), FR-020 (brownfield bootstrap)

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
7. **Traceability enforced**: All tasks in plan.md link to spec FRs; all drift events reference source requirements; 100% traceability
8. **Full iteration can run**: Bootstrap → create spec with 3+ FRs → run planning → execute ≥2 tasks → run review → run retro → verify all artifacts exist and are contract-compliant
9. **Spec authority enforced**: Spec Steward can detect and propose resolution for drift; iterations cannot proceed without spec-aligned requirements
10. **No integration blockers**: Specrew extensions load alongside other extensions without errors; no critical platform gaps

**Review gate (Iteration 1 acceptance)**: Worf verifies all artifacts exist, all four phases completed, drift detection active, traceability 100%, and at least one end-to-end iteration documented. Alon approves MVP readiness before Iteration 2 planning begins.

---

## Governance Consistency Check

Validation that this plan respects Specrew's own governance model.

| Gate | Verdict | Notes |
|------|---------|-------|
| **Spec Authority** | ✅ PASS | All tasks trace to FR-002 through FR-011, FR-013, FR-018, or US references. Deferred work (FR-007, FR-012, FR-016, FR-020) explicitly marked. No scope exists without a spec reference. |
| **Traceability** | ✅ PASS | Traceability Matrix (above) maps each task to enabling requirements and unblocks tested FRs. T-020–T-022 link to acceptance requirements (FR-005, FR-006, FR-008, FR-009, FR-013). |
| **Ownership** | ✅ PASS | All tasks assigned to role names (Implementer, Planner) with explicit responsibility. |
| **Capacity** | ✅ PASS | 20.5 pts committed (matches Iteration 0 baseline, zero-variance proven capacity). Deferred work tracked separately; not silently cut. |
| **Artifact Consistency** | ✅ PASS | Task table mirrors traceability matrix. Capacity math verified. All artifacts contract-compliant per iteration-artifacts.md. |
| **Execution Support** | ✅ PASS | All enabling work defined: state.md template for task tracking, drift-log schema, review verdict format. No ambiguity about "complete." |

---

## Tasks

| Task | Title | Requirement | Story | Effort | Owner | Status | Agent | Actual | Verdict |
| ---- | ----- | ----------- | ----- | ------ | ----- | ------ | ----- | ------ | ------- |
| T-001 | `specrew init`: Detect and validate dependencies | FR-002, FR-013 | US-1 | 1 | Implementer | planned | | | |
| T-002 | `specrew init`: Install missing Spec Kit/Squad | FR-002 | US-1 | 1 | Implementer | planned | | | |
| T-003 | `specrew init`: Run specify init (greenfield) | FR-002, FR-011 | US-1 | 0.5 | Implementer | planned | | | |
| T-004 | `specrew init`: Run squad init (greenfield) | FR-002 | US-1 | 0.5 | Implementer | planned | | | |
| T-005 | `specrew init`: Deploy Spec Kit extension | FR-002, FR-001 | US-1 | 1 | Implementer | planned | | | |
| T-006 | `specrew init`: Deploy Squad skills | FR-002, FR-001 | US-1 | 1 | Implementer | planned | | | |
| T-007 | `specrew init`: Deploy Squad ceremonies | FR-002, FR-001 | US-1 | 1 | Implementer | planned | | | |
| T-008 | `specrew init`: Merge 5 baseline roles | FR-002, FR-004 | US-1 | 1 | Planner | planned | | | |
| T-009 | `specrew init`: Scaffold governance artifacts (downstream constitution, config, role assignments) | FR-002, FR-011 | US-1 | 1 | Planner | planned | | | |
| T-010 | `specrew init`: Version validation + error reporting | FR-002, FR-013 | US-1 | 0.5 | Implementer | planned | | | |
| T-011 | Implement drift-check skill | FR-008, FR-018 | US-3 | 1.5 | Planner | planned | | | |
| T-012 | Implement spec-authority directive (Spec Steward charter) | FR-003, FR-004 | US-3 | 0.5 | Planner | planned | | | |
| T-013 | Implement traceability directive (Planner charter) | FR-006, FR-018 | US-2 | 0.5 | Planner | planned | | | |
| T-014 | Implement drift-reporting directive (Implementer + Reviewer charters) | FR-008, FR-018 | US-2 | 0.5 | Planner | planned | | | |
| T-015 | Implement planning ceremony (generate plan.md from spec) | FR-005, FR-006 | US-2 | 2 | Implementer | planned | | | |
| T-016 | Implement review/demo ceremony (verdict verdicts + review.md) | FR-005, FR-009 | US-2 | 2 | Implementer | planned | | | |
| T-017 | Integrate Squad's retrospective ceremony with Specrew prompts | FR-005, FR-010 | US-2 | 1 | Planner | planned | | | |
| T-018 | Implement iteration artifact storage (.iterations/NNN/ directory structure) | FR-018 | US-2 | 0.5 | Implementer | planned | | | |
| T-019 | Document downstream use flow (bootstrap → plan → execute → review → retro) | FR-002, FR-005 | US-2 | 0.5 | Planner | planned | | | |
| T-020 | Create integration test: bootstrap-to-iteration (greenfield → 1 full iteration) | FR-005, FR-006 | US-1, US-2 | 1.5 | Implementer | planned | | | |
| T-021 | Create end-to-end scenario test (drift detection + resolution) | FR-008, FR-009 | US-3 | 1 | Planner | planned | | | |
| T-022 | Validate CI pipeline (markdownlint, PSScriptAnalyzer, test runner) | FR-013 | US-2 | 0.5 | Implementer | planned | | | |

**Total Effort**: 20.5 story points

---

## Phase Baseline

| Phase | Estimated Effort | Notes |
| ----- | ---------------- | ----- |
| Planning | 2 | Task decomposition, spec-to-requirement mapping, traceability validation |
| Discovery/Spikes | 0 | No pre-planning spikes needed; Iter 0 validated Squad post-task hook availability and drift-check feasibility |
| Implementation | 16 | T-001–T-019: CLI, directives, ceremonies, artifact storage, documentation |
| Review | 1 | Review/demo ceremony gate, verdict capture, traceability verification |
| Rework | 1.5 | T-020–T-022: Integration tests, scenario tests, CI pipeline validation (testing buffer) |

**Rationale**: Foundation work (Iter 0) demonstrated predictable 0-variance delivery at 20.5 pts. MVP delivery (Iter 1) involves more orchestration complexity and LLM-driven ceremony behavior, but all architectural risks have been validated. Phase baseline allocates 2 pts to planning, 16 pts to core implementation, 1.5 pts to testing/validation (now inline with implementation), and 1 pt to review gate. Post-retro recalibration is expected based on actual delivery variance.

---

### What's In Scope (Iteration 1 MVP)

- **Greenfield bootstrap only**: `specrew init` works on empty or fresh repos with Spec Kit/Squad detected/installed
- **Four-phase lifecycle**: Planning, Execution, Review/Demo, Retrospective ceremonies/phases all active
- **Active drift detection**: Drift-check skill invokes per-task or at review gate (per Iter 0 spike findings)
- **Traceability**: Every task links to a spec requirement; 100% coverage enforced
- **Governance directives**: Spec Authority, Traceability, Drift Reporting embedded in agent charters
- **Iteration artifacts**: plan.md, state.md (task tracking), drift-log.md, review.md, retro.md all created and contract-compliant
- **Board synchronization**: GitHub Project board automation deployed and operational from Iteration 0; continues mirroring iteration state without new work
- **Five baseline roles**: Spec Steward, Planner, Implementer, Reviewer, Retro Facilitator merged into `.squad/team.md`
- **Testing**: Unit tests for scripts; integration tests for full bootstrap→iteration flow; scenario test for drift detection

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

**Phase 2: Governance Directives** (T-011 through T-014)
- T-011 (drift-check) → T-012/T-013/T-014 (directives)
- These can progress in parallel after T-011 base skill is complete.
- **Blockers**: T-011 must complete before T-012 (drift-check is a dependency).

**Phase 3: Ceremonies** (T-015 through T-017)
- T-015 (planning) → T-016 (review/demo) → T-017 (retrospective)
- **Blockers**: T-015 must complete before T-016 (review depends on plan structure).

**Phase 4: Supporting Work** (T-018, T-019)
- T-018 (artifact storage) can proceed in parallel after Phase 1 (needed for T-015).
- T-019 (documentation) can proceed after T-015/T-016/T-017.

**Phase 5: Testing** (T-020, T-021, T-022)
- T-020 requires T-001–T-010 (bootstrap) + T-015–T-017 (ceremonies).
- T-021 requires T-011 (drift-check) + T-016 (review ceremony).
- T-022 runs independently; can execute anytime.

### Effort Calibration

**Rationale for task estimates**:
- **T-001 (1 pt)**: Dependency detection — multiple code paths for Spec Kit/Squad present/absent. Error handling for version mismatches.
- **T-002 (1 pt)**: Installation via official package managers. Version pinning, fallback handling.
- **T-003/T-004 (0.5 pts each)**: Orchestrating existing `specify init` and `squad init` commands. Low complexity; mostly pass-through.
- **T-005/T-006/T-007 (1 pt each)**: Copying files to correct locations, updating manifests (.specify/extensions.yml, .squad/ceremonies.md, .squad/team.md). Medium complexity.
- **T-008 (1 pt)**: Merging 5 role definitions into existing team config. Collision handling, name resolution.
- **T-009 (1 pt)**: Scaffolding three governance artifact files (downstream constitution, iteration config, role assignments). Medium complexity, clear inputs/outputs.
- **T-010 (0.5 pts)**: Version validation + error messages. Low complexity.
- **T-011 (1.5 pts)**: Drift-check skill — highest complexity. Comparing output to requirement (parsing, semantic matching, diff logic), recording drift events, producing human-readable report.
- **T-012–T-014 (0.5 pts each)**: Embedding directive text into agent charters. Low complexity, clear templates.
- **T-015 (2 pts)**: Planning ceremony — parse spec requirements, generate tasks, assign effort, estimate capacity, produce plan.md with full traceability. Core intelligence task.
- **T-016 (2 pts)**: Review ceremony — capture verdicts per task, produce review.md, validate traceability. Medium complexity.
- **T-017 (1 pt)**: Integrate Squad's retro ceremony template with Specrew-specific prompts. Low-medium complexity.
- **T-018 (0.5 pts)**: Define .iterations/NNN/ directory structure, create state.md template. Low complexity.
- **T-019 (0.5 pts)**: User-facing documentation of the iteration workflow. Low complexity.
- **T-020 (1.5 pts)**: Integration test — end-to-end bootstrap + 1 iteration. Requires all tasks T-001–T-017 to work together.
- **T-021 (1 pt)**: Scenario test for drift detection. Setup spec, execute contradicting task, verify drift caught, test resolution flow.
- **T-022 (0.5 pts)**: Validate existing CI pipeline (configured in Iter 0). Low complexity.

**Estimation philosophy**: Foundation work (Iter 0) was predictable and hit exactly (20.5/20.5 pts, 0% variance). MVP work (Iter 1) involves more LLM-driven behavior, orchestration complexity, and ceremony design. Estimates reflect Iter 0 baseline calibration. This should be recalibrated after Iter 1 retro based on actual delivery.

### Spec Steward Responsibilities (This Iteration)

- **Pre-execution**: Validate that all 22 tasks in this plan map to spec requirements (FR-001 through FR-011, FR-013, FR-018, US-1 through US-4). Ensure no scope exists outside the spec.
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

**Capacity Unchanged**: Effort estimates revised downward from implied 22 pts (original rationale) to 20.5 pts (matching Iteration 0 baseline). This reflects re-calibration to Iteration 0's zero-variance completion (20.5/20.5 actual). No capacity increase needed; plan fits standard team capacity model.

---

## Success Criteria (For Iteration 1 Closure)

1. ✅ `specrew init` command exists and works on greenfield repos
2. ✅ Bootstrap creates governance scaffold + merges 5 baseline roles
3. ✅ Planning ceremony generates iteration plan with task-to-requirement links
4. ✅ Drift-check skill detects contradictions between output and spec
5. ✅ Review/Demo ceremony produces verdicts + review.md
6. ✅ Retrospective integration produces retro.md with all required sections
7. ✅ All iteration artifacts exist and validate against contract (iteration-artifacts.md)
8. ✅ Traceability: 100% of tasks link to spec requirements
9. ✅ Integration test passes: bootstrap → spec → plan → execute → review → retro
10. ✅ Drift scenario test passes: detect contradicting output, surface to Spec Steward, propose resolution
11. ✅ CI pipeline passes: markdownlint, PSScriptAnalyzer, unit + integration tests all green
12. ✅ Review gate passed: Worf confirms all artifacts, governance active, no integration blockers
13. ✅ No regressions: Iteration 0 artifacts still valid, no platform compatibility issues

**Verdict gate**: Alon approves MVP readiness. Team consensus on operating policy rules (per .squad/identity/now.md) required before Iteration 2 can begin.
