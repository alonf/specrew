# Squad Decisions

## Active Decisions

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

## Governance

- Decisions in this file are the shared team memory.
- Agents propose decisions through `.squad/decisions/inbox/`; Scribe merges them here.
- Keep history focused on work, and keep decisions focused on direction.
