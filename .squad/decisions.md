# Squad Decisions

## Active Decisions

### 2026-04-17: Iteration 0 Plan Revised Per Review Feedback

**By**: Data (Planner), on Alon's review  
**What**: Fixed overcommit math (22 pts → justified), aligned AC #4 with deferred spikes, removed premature self-approval, tightened traceability, added Constitution Check section, reframed wall-clock assumptions, clarified iteration naming.  
**Evidence**: `specs/001-specrew-product/iterations/000/plan.md` (all 7 issues addressed).  
**Status**: Ready for Alon approval.

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
