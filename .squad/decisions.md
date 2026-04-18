# Squad Decisions

## Active Decisions

### 2026-04-18: Iteration 0 Execution-Phase Closure Complete

**By**: Data (Planner)  
**Date**: 2026-04-18  
**What**: Iteration 0 execution phase is now contract-complete and ready for retrospective.

#### Artifacts Created/Updated

| Artifact | Action | Status |
|----------|--------|--------|
| `plan.md` | Updated metadata (Status → `complete`, Capacity → `20.5/20.5`, Completed → `2026-04-18`) | ✅ Complete |
| `state.md` | Verified present (La Forge) | ✅ Complete |
| `drift-log.md` | Created (0 events) | ✅ Complete |
| `review.md` | Verified present (Worf) | ✅ Complete |
| `retro.md` | Pending Troi (Retro Facilitator) | ⏳ Pending |

#### Contract Compliance

Per `contracts/iteration-artifacts.md`:
- ✅ **Iteration Plan**: Metadata complete; Status, Capacity, Started, Completed all present
- ✅ **Task State**: Last completed task, tasks remaining, in-progress status recorded
- ✅ **Drift Log**: Event ledger present (0 events); schema compliant
- ✅ **Review**: Verdict recorded; acceptance gates passed
- ⏳ **Retrospective**: Pending Troi — owned by retrospective ceremony

#### Execution Phase Verdict

| Metric | Result |
|--------|--------|
| Task Completion | 23/23 (100%) |
| Effort Delivery | 20.5/20.5 (100% exact commitment) |
| Spec Drift | 0 events |
| Platform Validation | 9/9 spikes passed |
| Architecture Resolution | Squad-native surfaces; decision tracked |
| Blocker Status | None |
| Artifact Completeness | ✅ Contract-safe for retrospective |

#### Phase Sequencing (Four-Phase Lifecycle)

1. ✅ **Planning Phase** (complete 2026-04-17)
2. ✅ **Execution Phase** (complete 2026-04-18)
3. ✅ **Review/Demo Phase** (complete 2026-04-18, Worf sign-off)
4. ⏳ **Retrospective Phase** (pending 2026-04-18, Troi to write retro.md)

**Decision**: Iteration 0 execution-phase closure is **contract-complete and approved for retrospective handoff**. No blocking issues remain on planning side.

---

### 2026-04-18: Governance Hardening Implementation

**By**: Picard (Spec Steward)  
**Date**: 2026-04-18  
**Status**: Implemented  
**What**: Four governance artifacts created/updated to make Specrew's iteration lifecycle normative and binding.

#### Artifacts Created/Updated

1. **Spec.md — Added Iteration Lifecycle Contract Section**
   - Added explicit Phase State Machine showing all valid transitions
   - Made state machine enforcement normative (not optional)
   - Added Dogfooding Obligation section (Specrew must follow its own model)
   - Marked both sections *(normative)* for binding rules

2. **contracts/iteration-artifacts.md — Made State Machine Explicit**
   - Reordered to lead with normative state machine diagram
   - Added Phase Rules table (entry/exit conditions, gates, produced artifacts)
   - Added Artifact Validation Gates (phase transition blockers)
   - Added Abandoned Iteration Rule

3. **.squad/protocol.md — Single Coordinator Protocol**
   - Core Roles & Responsibilities (Picard, Data, La Forge, Worf, Troi, Alon)
   - Decision-Making Workflow (routine, tracked changes, escalation paths)
   - Iteration Lifecycle Coordination (all 4 phases, concurrency, re-entry)
   - Six Operating Rules (spec-authority, spikes, traceability, retro autonomy, drift directive, phase estimation)
   - Conflict Resolution paths
   - Status Reporting format
   - Escalation Summary

4. **Dogfooding Obligation Clarified**
   - Specrew uses its own iteration lifecycle
   - Specs authoritative for Specrew development
   - Drift detection applies internally
   - Full artifact lifecycle every iteration
   - Exception: Support/infra tracked under support FRs but still traceable

#### Governance Hardening Scope

| # | Finding | Status | Handler |
|----|---------|--------|---------|
| 1 | Artifact Contracts | ✅ ADDRESSED | contracts/iteration-artifacts.md (state machine normative) |
| 2 | Iteration State Machine | ✅ ADDRESSED | spec.md + contracts/iteration-artifacts.md (enforced) |
| 3 | Dogfooding Governance | ✅ ADDRESSED | spec.md § Dogfooding Obligation |
| 4 | Governance Validator Skill | ⏸️ DEFERRED | Implementer (La Forge) task for Iteration 1; FR-008 |
| 5 | Methodology Runtime Config | ⏸️ DEFERRED | `.specrew/methodology.yml` design deferred to Iteration 1 |
| 6 | Coordinator Protocol | ✅ ADDRESSED | `.squad/protocol.md` (single document, all rules) |

#### Expected Outcomes (Immediate)

1. ✅ Iteration 0 closure artifacts can now be created
2. ✅ Team understands phase sequencing is binding
3. ✅ Dogfooding obligation is clear
4. ✅ Single protocol document exists

#### Expected Outcomes (Ongoing, Iteration 1+)

1. Drift detection harder to hide (gates prevent orphan tasks, traceability pre-gate, drift-reporting directive active, validator enforces at review)
2. Phase state machine strict (planning → execution requires approved plan, execution → review requires terminal tasks, review → retro requires verdicts, retro → complete requires artifact)
3. Decision paths explicit (.squad/protocol.md, escalation criteria documented, tier 1 consensus before tier 2)

**Decision**: Governance hardening is **implemented; authority changes are normative and binding**. Validator skill (FR-008) and methodology.yml (Iteration 1) deferred as implementation tasks.

---

### 2026-04-18: Iteration 0 Retrospective Findings & Process Improvements

**By**: Troi (Retro Facilitator)  
**Date**: 2026-04-18  
**Status**: Proposed  
**What**: Three tier-1 process improvements (zero effort, maximum ROI) to be adopted in Iteration 1+ operating model.

#### Root Cause Analysis

All friction in Iteration 0 stems from gates running **post-execution** (review phase) instead of **pre-execution** (planning phase). Gates themselves are correct; timing is suboptimal.

**Example**: Spec-authority gate caught 4 out-of-scope proposals during late plan revisions. Same gate logic at planning ceremony would have prevented churn (zero effort, same logic, earlier timing).

#### Three Tier-1 Improvements

1. **Spec-Authority Gate Pre-Execution** (planning ceremony)
   - Effort: 0 (gate logic exists; resequence only)
   - Expected outcome: 4 plan revisions → 0–1
   - Owner: Picard

2. **Architecture-Risk Spikes Pre-Planning** (pre-ceremony)
   - Example: T-017 (Squad discovery) runs pre-planning instead of parallel with task execution
   - Effort: 0 (existing spikes) + ~1 hr/iteration to identify risky questions
   - Expected outcome: Eliminates hidden task dependencies
   - Owner: Picard + La Forge

3. **Retro Ceremony Autonomous from Sign-Off** (fixed schedule, decoupled)
   - Effort: 0 (scheduling change only)
   - Expected outcome: Retro blocked 1+ day → retro same-day or next-day
   - Owner: Alon (policy), Troi (facilitation)

#### Estimation & Drift Data (Iteration 0 Baseline)

- **Estimation Accuracy**: 20.5 planned = 20.5 actual (0% variance)
- **Specification Drift**: 0 events detected
- **Process Friction**: 4 plan revisions after execution (due to late gate timing, not estimate errors)
- **Foundation-specific**: Foundation work has lower discovery risk (outputs mechanical). Iteration 1+ behavior-implementation work will have higher risk; early gates become even more valuable.

#### Recommendation: Phase-Level Efficiency Tracking

Update `plan.md` and `retro.md` templates to track effort per phase (planning, execution, review, retro). Reveals where buffer is consumed and tightness exists.

#### Implementation Checklist (Before Iteration 1 Planning)

- [ ] **Picard**: Draft updated planning ceremony charter with spec-authority gate logic
- [ ] **La Forge + Picard**: Identify 2–3 architecture-risk spikes for Iteration 1 before planning ceremony
- [ ] **Alon**: Confirm retro schedule policy (e.g., "Retro runs Fridays 2pm, autonomous from sign-off")
- [ ] **Data**: Update `plan.md` template to include per-phase effort estimates
- [ ] **Troi**: Facilitate team consensus on six core operating rules (governance hardening policy)
- [ ] **Team**: Confirm operating policy (six rules + three tier-1 improvements) before Iteration 1 planning

#### Decision Criteria

✅ **Zero new effort** — All three improvements are resequencing only  
✅ **Maximum ROI** — Estimated 80%+ drift-detection latency reduction  
✅ **Low risk** — Existing processes remain unchanged; only order and autonomy change  
✅ **Foundation for governance hardening** — Aligns with Alon's user directive

**Decision**: Proposed—awaiting team consensus before Iteration 1 planning ceremony. If consensus reached, embed into Iteration 1 operating charters and planning ceremony structure.

---

### 2026-04-18T12:49:27Z: User Directive - Governance Hardening & Iteration 0 Closure

**By**: Alon Fliess (via Copilot CLI)  
**Date**: 2026-04-18T12:49:27Z  
**What**: Specrew must harden its own governance so future work is artifact- and gate-driven:
- Make iteration contracts normative (enforce phase state machine)
- Require dogfooding of full lifecycle unless explicitly excepted
- Add a governance validator to enforce contracts
- Deploy operating prompts into runtime surfaces (agent charters)
- Introduce a single coordinator protocol document
- Close Iteration 0 correctly before any Iteration 1 planning begins

**Why**: User request. Specrew is being built with the same spec-governed method it is meant to enable downstream. Governance must be enforced, not implicit.

**Evidence**: User directive captured in session (copilot-directive-2026-04-18T12-49-27Z.md), manifested in Picard/Worf/Troi spawn outcomes.

**Impact**: Immediate adoption priority before Iteration 1. Affects planning ceremony (gates), execution (drift directives), review (artifact validation), and retrospective (autonomous start).

**Status**: Active. Three agent teams (Picard, Worf, Troi) delivered frameworks for governance hardening and Iteration 0 closure audit.

---

### 2026-04-18: Operating Policy - Specrew v1 Self-Governance

**By**: Troi (Retro Facilitator)  
**Date**: 2026-04-18  
**What**: Six core operating rules for iteration governance:
1. **Spec-Authority Gate Runs BEFORE Task Assignment** (Planning Ceremony)
2. **Architecture-Risk Spikes Run Pre-Planning** (Planning Prerequisite)
3. **Traceability Check Runs BEFORE Task Assignment** (Planning Ceremony)
4. **Review Verdict and Retrospective Start Are Decoupled** (Autonomous retro start)
5. **Drift-Reporting Directive Deployed at Bootstrap** (All agent charters)
6. **Estimation Tracking Includes Phase-Level Variance** (Plan + Retro templates)

**Why**: Iteration 0 shipped clean (100%, zero drift) but had **implicit gates that cascaded late fixes**. Plan revised 4 times *after* execution started. Moving gates earlier (pre-execution) reduces drift 80%+ via resequencing only (zero new effort).

**Evidence**: troi-minimum-drift-reduction.md (ROI analysis), troi-operating-hardening.md (implementation checklist with immediate adoption steps).

**Impact**: 
- Iteration 0: 4 plan revisions → Iteration 1+: ≤1 (gate prevents pre-execution)
- Mid-execution spikes → Pre-planning discovery (prevents unblocking delays)
- Retro blocked 1 day → Retro autonomous same-day

**Status**: Proposed. Awaiting Picard + Alon confirmation before enforcement in Iteration 1.

---

### 2026-04-18: Iteration 0 Closure Audit - Missing Artifacts & Stale Metadata

**By**: Worf (Reviewer)  
**Date**: 2026-04-18  
**What**: Iteration 0 is **artifact-incomplete** against explicit lifecycle contract:
- **Execution Phase**: ✅ COMPLETE (all 23 tasks, 20.5/20.5 pts, review ACCEPTED)
- **Retrospective Phase**: ❌ BLOCKED (missing state.md, drift-log.md, retro.md)
- **Plan Metadata**: ⚠️ STALE (Status: in_progress [should: complete], Capacity: 0/20 [should: 20.5/20.5])

**Why**: Iteration artifacts contract (contracts/iteration-artifacts.md) requires all four phases (planning → execution → review/demo → retrospective) in sequence. Retrospective cannot start without required artifacts.

**Evidence**: worf-iteration-closure-audit.md (comprehensive audit with artifact completeness matrix, phase sequencing, closure artifact status, sign-off sequencing issues).

**Blocking**: Cannot declare Iteration 0 closed or start Iteration 1 planning until retrospective phase completes.

**Recommendation**: Option 1 (strict closure) — block Iteration 1 planning until retro completes (~1 hour). Rationale: Foundation iteration must close cleanly; skipping retro compounds estimation errors into Iteration 1.

**Status**: Active. Awaiting artifact creation and Alon decision on sequencing.

---

### 2026-04-18: Squad Native Surfaces for Specrew v1

**By**: Alon Fliess (Chief Architect)  
**Date**: 2026-04-18T00:24:57Z  
**What**: Specrew v1 will use Squad native surfaces: `.copilot/skills/` for skills and `.squad/` runtime surfaces (ceremonies, directives, routing) rather than a packaged `extensions/specrew-squad/` plugin layout.  
**Why**: Iteration 0 spike results showed Squad's local plugin architecture is marketplace-only and does not support the planned bundled `extensions/specrew-squad/` structure. The original plan assumed Squad could load extensions from a local `extensions/` directory, but Squad only loads from its marketplace or `.copilot/skills/` for user skills.  
**Evidence**: `specs/001-specrew-product/iterations/000/spikes.md` (Squad architecture mismatch finding), `.squad/decisions/inbox/copilot-squad-native-surfaces-2026-04-18T00-24-57Z.md`  
**Impact**: Squad extension scaffolding tasks (T-006–T-012) remain valid but now target native surfaces instead of plugin package structure. No change to Spec Kit extension scope.  
**Status**: Active. Execution continuing under corrected architecture.

---

### 2026-04-18: Iteration 0 Approved for Execution

**By**: Alon Fliess (Chief Architect)  
**Date**: 2026-04-18T00:12:28Z  
**What**: Approved `specs/001-specrew-product/iterations/000/plan.md` for execution. Foundation work (repository structure, extension skeletons, platform validation spikes, CI setup) can proceed. GitHub remote confirmed at `https://github.com/alonf/specrew.git`.  
**Why**: Iteration 0 plan is contract-safe, scope is limited to precondition-critical infrastructure, and all traceability/governance gates pass. Platform validation must complete before Iteration 1 MVP work begins.  
**Evidence**: `.squad/decisions/inbox/copilot-iteration-approval-2026-04-18T00-12-28Z.md`  
**Status**: Active. La Forge (Implementer) is cleared to begin execution.

---

### 2026-04-18: Final Contract Polish on Iteration 0 Plan

**By**: La Forge (Implementer)  
**Date**: 2026-04-18  
**What**: Removed final contract-violating references and normalized requirement traceability:
  - Removed nonexistent `FR-050` clarification citation; corrected to reference Spec Kit `commands/` folder deferral in spec.md
  - Mapped all scaffolding tasks (T-006–T-012) to FR-001 (Two-package architecture) as foundational infrastructure
  - Updated traceability matrix row to bind infrastructure tasks to FR-001 and US-1 with supporting rationale
  - Verified all 23 tasks now have valid FR mappings (zero em-dash entries)

**Evidence**: `.squad/decisions/inbox/laforge-final-plan-polish.md` (full technical analysis)  
**Status**: Complete. Plan is now 100% contract-safe and ready for Alon approval.

---

### 2026-04-17: Contract-Safe Iteration 0 Plan Revision

**By**: La Forge (Implementer)  
**Date**: 2026-04-17  
**What**: Revised `specs/001-specrew-product/iterations/000/plan.md` to conform to the iteration artifact contract and data model, addressing seven findings from Alon's review:
  - Added required metadata fields (Capacity, Started, Completed) per contract
  - Replaced phase-by-phase task lists with unified `## Tasks` table (23 tasks, T-001–T-023)
  - Replaced cast member names with role names (Implementer, Planner)
  - Fixed capacity math: 20 pts at 20 pt capacity (was internally inconsistent)
  - Removed stale references: TG-003, FR-050, old spike task IDs
  - Clarified scope: Iteration 0 = platform validation + enabling infrastructure only
  - Replaced fabricated citations with real spec.md references

**Evidence**: `specs/001-specrew-product/iterations/000/plan.md` (all 7 issues addressed).  
**Status**: Superseded by final polish (2026-04-18).

---

### 2026-04-17: Iteration 0 Plan Revised Per Review Feedback (Data Initial)

**By**: Data (Planner), on Alon's review  
**What**: Fixed overcommit math (22 pts → justified), aligned AC #4 with deferred spikes, removed premature self-approval, tightened traceability, added Constitution Check section, reframed wall-clock assumptions, clarified iteration naming.  
**Evidence**: `specs/001-specrew-product/iterations/000/plan.md` (foundational revisions).  
**Status**: Superseded by La Forge contract-safe revision (2026-04-17).

---

### 2026-04-17: The spec is authoritative
**By:** Alon (via Squad)
**What:** Specrew treats the source spec as the authoritative source of truth. Implementation, plans, tasks, and reviews must trace back to it, and no behavior overrides it without a tracked change.
**Why:** Specrew is being built with the same spec-governed method it is meant to enable downstream.

### 2026-04-17: Specrew works in a four-phase iteration lifecycle
**By:** Alon (via Squad)
**What:** Every iteration runs through planning, execution, review/demo, and retrospective. Planning, review/demo, and retrospective are ceremonies; execution is routed work.
**Why:** The operating model itself is part of the product and must remain explicit.

### 2026-04-17: Drift detection runs after every task
**By:** Alon (via Squad)
**What:** After each task, delivered output is compared to the originating requirement to detect drift before it compounds into the next phase.
**Why:** Early drift detection protects the integrity of the spec-first workflow.

### 2026-04-17: Specrew v1 stays Markdown-first
**By:** Alon (via Squad)
**What:** Specrew v1 uses Markdown, YAML, and PowerShell in a Markdown-based extension structure. There is no `squad.config.ts` in v1.
**Why:** The initial product scope is extension assets and operating model files, not code-heavy runtime infrastructure.

### 2026-04-17: Alon is the human architect and reviewer gate
**By:** Alon (via Squad)
**What:** Alon participates on the team as Chief Architect and Reviewer. Architecture direction and final reviewer judgment route to him.
**Why:** The squad needs an explicit human decision-maker for architecture and final review.

### 2026-04-17: Iteration 0 (Foundation) Plan Approved by Spec Steward

**By:** Picard (Spec Steward)  
**What:** Iteration 0 is Foundation-only: repository structure, extension skeletons (Spec Kit + Squad), 11 platform validation spikes, CI setup, GitHub Project board. Scope: 20 pts. All feature implementation (bootstrap script, governance scaffold, ceremonies, drift-check skill) deferred to Iteration 1.  
**Why:** Iteration 0 is precondition-critical. Platform validation and de-risking must complete before MVP (Iteration 1) begins. Plan includes explicit traceability to FRs, risk mitigation strategy, and contingency routing for spike results.

**Evidence**: `specs/001-specrew-product/iterations/000/plan.md`  
**Status**: Pending Alon (Chief Architect) approval.

---

### 2026-04-18: La Forge - Governance Enforcement Package

**By**: La Forge (Implementer)  
**Date**: 2026-04-18  
**Scope**: Specrew governance enforcement implementation  

#### Decision

Implement the minimum practical enforcement package in the Spec Kit extension by:

1. adding `extensions\specrew-speckit\scripts\validate-governance.ps1`
2. wiring the validator into CI
3. replacing ceremony and governance stubs in `extensions\specrew-speckit\squad-templates\` with actual operating method
4. adding a retrospective ceremony template for lifecycle closure on the Squad-native surface

#### Why

The authority layer is now explicit in contracts and protocol documents, but enforcement was still mostly social. The validator turns lifecycle rules into a failing check, and the Squad-native templates now carry the real method that downstream users will actually run.

#### Impact

- invalid iteration artifact transitions fail fast
- planning, drift, review, and retro behavior are discoverable in runtime-facing templates
- CI now exercises the governance contract instead of relying on documentation alone

**Status**: ✅ Implemented; authority changes binding and normative.

---

### 2026-04-18: Worf - Iteration 0 Final Gate Review — PASS

**By**: Worf (Reviewer)  
**Date**: 2026-04-18  
**Status**: Final

#### Summary

Iteration 0 final gate review completed. All three review criteria passed:

1. **Iteration 0 is formally complete** under the normative lifecycle contract
2. **Governance hardening implementation is acceptable and coherent**
3. **No blocking issues remain** for Alon sign-off or Iteration 1 planning

#### Final Verdict: ✅ PASS

##### Criterion 1: Formal Closure

Iteration 0 has completed all four phases of the lifecycle state machine:

| Phase | Status | Evidence |
|-------|--------|----------|
| Planning | ✅ Complete | plan.md approved, all tasks traced to FR-001/FR-013 |
| Executing | ✅ Complete | 23/23 tasks done, 20.5/20.5 pts delivered, zero variance |
| Reviewing | ✅ Complete | review.md ACCEPTED, all 23 task verdicts pass |
| Retrospective | ✅ Complete | retro.md produced with all mandatory sections |

All phase-terminal artifacts exist:
- `plan.md` (Status = complete, Completed = 2026-04-18)
- `state.md` (Last Completed Task = T-023, Tasks Remaining = none)
- `drift-log.md` (0 drift events)
- `review.md` (Overall Verdict = ACCEPTED)
- `retro.md` (Estimation Accuracy, Drift Summary, Improvement Actions, Process Notes)

**Governance validator**: `validate-governance.ps1 -IterationPath .\specs\001-specrew-product\iterations\000` → PASS (exit 0)

##### Criterion 2: Governance Hardening

Four governance artifacts make the iteration lifecycle normative and binding:

1. **spec.md** — Iteration Lifecycle Contract section defines four-phase state machine with enforcement rules; Dogfooding Obligation section binds Specrew to its own governance model
2. **contracts/iteration-artifacts.md** — State machine made explicit; Phase Rules table defines entry/exit conditions and blocking artifacts; Artifact Validation Gates define phase transition requirements
3. **.squad/protocol.md** — Single coordinator protocol (v1.0) with 6 roles, decision workflows, iteration coordination, 6 operating rules, and escalation paths
4. **validate-governance.ps1** — Functional script validates iteration artifact compliance at CI and ceremony gates

Deferred items (appropriately scoped to Iteration 1):
- Governance-validator skill (FR-008) — automation at phase transitions
- `.specrew/methodology.yml` — runtime config encoding phases and rules

##### Criterion 3: Blocking Issues

**None identified.**

- All artifacts exist and are schema-compliant
- All phase transitions are valid
- All task verdicts recorded
- Governance validator passes
- Operating policy (6 rules + 3 tier-1 improvements) proposed and ready for team consensus

#### Recommendation

Alon sign-off can proceed. Iteration 1 planning prerequisites:

1. ✅ Governance hardening authority finalized
2. ✅ Closure artifacts complete
3. ✅ Retrospective complete (Troi)
4. ⏳ Team consensus on operating policy (before Iteration 1 planning ceremony)
5. ⏳ Alon final sign-off

#### Impact

- Iteration 0 closure is official and binding
- Governance model is now normative for all future iterations
- Iteration 1 planning can begin after Alon sign-off

**Status**: ✅ Worf closure verdict recorded; governance hardening gate PASSED.

## Governance

- Decisions in this file are the shared team memory.
- Agents propose decisions through `.squad/decisions/inbox/`; Scribe merges them here.
- Keep history focused on work, and keep decisions focused on direction.
