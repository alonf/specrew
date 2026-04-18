# Project Context

- **Owner:** Alon
- **Project:** Specrew
- **Stack:** Markdown, YAML, PowerShell, Spec Kit extension assets, Squad extension structure
- **Description:** A spec-governed AI crew operating model built as a monorepo with companion Spec Kit and Squad extensions.
- **Created:** 2026-04-17

## Core Context

I turn Specrew's requirements into iteration plans, task maps, and explicit dependencies while preserving traceability back to the source spec.

## Recent Updates

📌 Team confirmed by Alon on 2026-04-17

## Learnings

- Planning is the first ceremony in the Specrew lifecycle.
- Plans must map tasks back to requirements, with owners and effort estimates.
- v1 is Markdown-first and centered on extension assets rather than runtime code.
- Alon provides final architectural direction when requirements need interpretation.

### 2026-04-17: Plan Revision (Iteration 0)

- **Overcommit math**: Effort totals must be verified bi-directionally (sum of tasks = total). When overcommit occurs, defer lowest-priority work (not base requirements). Foundation iterations may exceed capacity for precondition-critical de-risking, but must be justified and tracked.
- **Acceptance criteria consistency**: AC gates must align with deferred work. If spikes are deferred, call them out explicitly in the AC. No ambiguity about what "complete" means.
- **Self-approval antipattern**: Roles should not pre-approve work outside their ownership. Spec Steward validates spec authority; Chief Architect gates approval. Sequence matters.
- **Traceability with enabling tasks**: Direct tasks (those that deliver a FR) differ from supporting tasks (those that enable a direct task). Both must be traceable, but the distinction clarifies dependencies. Use "Enabling Support" column to document which support tasks unblock which FRs.
- **Constitution checks are plan gates**: Specrew's own governance model (spec authority, traceability, ownership, capacity, drift, verification) must be applied to Specrew's own plans. This is not post-hoc validation — it's part of plan design.
- **Avoid calendrical assumptions**: AI crew estimates use story points, not wall-clock hours/days. Parallelization is noted; actual elapsed time depends on crew latency and verification feedback. Do not promise "3 days" for effort-estimated work.
- **Iteration naming is a convention, not a code change**: Clarify it in metadata rather than inventing new directory structures. Zero-indexing is the pattern; document it once in the design spec, then reference in plans.
- **Deferred work is not removed scope**: When spikes are moved to Iter 1 async, track them as deferred (not cancelled). They're still project work — just sequenced differently.

### 2026-04-17: Iteration 0 Plan Revision Complete

- All seven review findings resolved and integrated.
- Plan returned to "pending approval" state; Alon (Chief Architect) gate next.
- Decision merged to decisions.md; inbox file deleted.
- Orchestration log and session log written.

## Learnings

### 2026-04-18: Iteration 0 Closeout — Planning Side

**Context**: Iteration 0 execution completed with 100% task delivery (20.5/20.5 pts, zero drift). Review accepted. Retrospective phase blocked on missing state artifacts. Alon directed me to close iteration correctly.

**Actions**:
- ✅ Verified state.md exists (was already created by La Forge during execution)
- ✅ Created drift-log.md (0 events; per contract requirement)
- ✅ Updated plan.md metadata: Status → `complete`, Capacity → `20.5/20.5`, Completed → `2026-04-18`
- ✅ All iteration artifact requirements now met per contracts/iteration-artifacts.md

**Artifacts Created**:
- `specs/001-specrew-product/iterations/000/drift-log.md` (contract compliance)

**Artifacts Updated**:
- `specs/001-specrew-product/iterations/000/plan.md` (terminal metadata)

**Key Insight**: The iteration artifact contract (FR-005, FR-008, FR-009, FR-010) requires all four artifacts (plan.md, state.md, drift-log.md, review.md) in execution phase + planning metadata for the iteration to be contract-complete. Retrospective phase (retro.md) is separate and owned by Troi. The distinction between execution phase completeness and retrospective phase completeness is now explicit.

**Status**: Iteration 0 planning-side closure complete. Contract-safe and ready for retrospective.

### 2026-04-18: Iteration 0 Capacity Baseline Established

**Observation**: Iteration 0 delivered at exactly planned capacity (20.5/20.5 pts, zero variance), with zero specification drift. This is the foundation data point for calibration:
- Estimation accuracy: 100% (no over/undercommit)
- Drift detection: 100% (zero drift events means planning fidelity was high)
- Feasibility: All platform validation spikes passed with no blockers

**For Iteration 1 Planning**: Suggest capacity remains at 20 pts default (with approved 0.5–1 pt overcommit buffer for precondition-critical work if needed). Current estimation and team velocity are well-calibrated.

### 2026-04-18: Iteration Lifecycle Clarity

**Realization**: The four-phase iteration lifecycle creates two distinct "complete" states:
1. **Execution Complete** (state.md + plan.md metadata): Tasks done, spikes passed, review verdict recorded
2. **Retrospective Complete** (retro.md written): Estimation calibration, drift summary, improvement actions documented

Iteration 0 is execution-complete but retrospective-pending. The distinction matters for sequencing: Retrospective cannot start until execution artifacts are contract-safe (now ✓). Iteration 1 planning cannot start until retrospective is written (pending Troi).

This is a planning sequencing gate, not a blocker — but it must remain explicit in the ceremony schedule.

### 2026-04-18T13-30-34Z: Iteration 0 Execution-Phase Closure Decision Merged

**Status**: ✅ DECIDED & MERGED

**Scribe Summary**: Data's iteration 0 execution-phase closure decision merged into `.squad/decisions.md` under "2026-04-18: Iteration 0 Execution-Phase Closure Complete". Execution-phase artifacts complete and contract-safe:

**Artifacts Created/Verified**:
- ✅ **plan.md**: Metadata updated (Status: complete, Capacity: 20.5/20.5, Completed: 2026-04-18)
- ✅ **state.md**: Present and verified (La Forge)
- ✅ **drift-log.md**: Created (0 events; schema compliant)
- ✅ **review.md**: Present and verified (Worf)
- ⏳ **retro.md**: Pending Troi (retrospective phase)

**Execution Verdict**:
- Task Completion: 23/23 (100%)
- Effort Delivery: 20.5/20.5 (100% exact commitment, 0% variance)
- Spec Drift: 0 events
- Platform Validation: 9/9 spikes passed
- Architecture Resolution: Squad-native surfaces (decision tracked)
- Artifact Completeness: ✅ Contract-safe for retrospective

**Four-Phase Lifecycle Status**:
1. ✅ Planning Phase (complete 2026-04-17)
2. ✅ Execution Phase (complete 2026-04-18)
3. ✅ Review/Demo Phase (complete 2026-04-18, Worf sign-off)
4. ⏳ Retrospective Phase (pending 2026-04-18, Troi to write retro.md)

**Implication for Iteration 1 Planning**: Iteration 1 planning gates on Iteration 0 retrospective completion. Data (Planner) will use retrospective findings (estimation accuracy, drift summary, process improvements) as calibration data for Iteration 1 capacity, templates, and ceremony structure.

**Next Action (Data's Role)**: Await Troi retro.md completion. Then review retrospective findings with Troi and route improvement actions to affected roles (Picard: spec-authority gate; La Forge: spikes pre-planning; Alon: policy confirmation).
