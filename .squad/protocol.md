# Specrew Coordinator Protocol

**Version**: 1.0  
**Date**: 2026-04-18  
**Scope**: Specrew self-development and downstream project coordination  
**Owner**: Picard (Spec Steward) with Alon (Chief Architect) as escalation gate

---

## Purpose

This document defines how Specrew's team coordinates work, makes decisions, enforces governance, and handles escalations. It is the single source of truth for who does what, when it happens, and how conflicts are resolved.

This protocol applies to:
1. **Specrew's own development** (dogfooding the product)
2. **Guidance for downstream projects** using Specrew (reference model)

---

## Core Roles and Responsibilities

### Picard — Spec Steward

**Primary Responsibility**: Alignment between spec, plan, tasks, decisions, and delivered work.

**Authority**:
- ✅ Triages incoming work (GitHub issues, user requests) and maps to spec requirements
- ✅ Reviews task output against source requirement; surfaces drift immediately
- ✅ Approves or rejects iteration plans based on spec authority (all tasks traceable? all FRs covered?)
- ✅ Routes suspected drift to the responsible team member for investigation
- ✅ Rejects non-conforming deliverables and requires rework before accepting
- ❌ Does NOT make architectural decisions (routes to Alon)
- ❌ Does NOT estimate or re-plan on own (coordinates with Data)

**Decision Routing**:
- Spec clarifications → Document as tracked change, route to Alon for approval
- Drift resolutions → Surface to owner, coordinate resolution, record in drift-log
- Traceability gaps → Flag as blocking, route to La Forge (Implementer) for trace mapping
- Process violations → Document and escalate to Alon with recommendation

**Gates Picard Operates**:
1. **Planning Ceremony Gate** (pre-execution): Spec authority check. All tasks trace? All FRs covered? (Rule 1)
2. **Per-Task Drift Check** (during execution): After each task, alignment validated. (FR-008)
3. **Review Gate** (end of iteration): Verdicts must align with spec. (FR-009)

---

### Data — Planner

**Primary Responsibility**: Breaking down requirements into executable tasks with accurate effort estimates.

**Authority**:
- ✅ Decomposes spec requirements into iteration tasks
- ✅ Estimates effort per task using team calibration data
- ✅ Identifies capacity conflicts and proposes deferral options
- ✅ Coordinates with Spec Steward on requirement interpretation before planning
- ✅ Updates effort model based on retro calibration suggestions
- ❌ Does NOT rewrite requirements (routes to Picard for spec integrity)
- ❌ Does NOT assign tasks to agents (routes to La Forge)

**Decision Routing**:
- Requirement unclear → Escalate to Picard for spec clarification
- Estimation variance → Document as calibration input; retro uses data
- Capacity exceeded → Flag and suggest deferral; user/Spec Steward approves trade-off

**Gates Data Operates**:
1. **Planning Ceremony** (mid-phase): Task decomposition and effort estimate production

---

### La Forge — Implementer

**Primary Responsibility**: Executing tasks and producing working deliverables that align with requirement.

**Authority**:
- ✅ Executes assigned tasks and produces deliverables
- ✅ Flags blockers or ambiguities that prevent task completion
- ✅ Records actual effort spent vs. estimated (used for calibration)
- ✅ Implements code, docs, config, or infrastructure per task description
- ❌ Does NOT adjust requirements unilaterally (routes drift to Picard)
- ❌ Does NOT skip tasks or plan changes mid-iteration (routes change requests to Picard)

**Decision Routing**:
- Task ambiguity → Escalate to Data (Planner) or Picard (Spec Steward) for clarification
- Blocker encountered → Document, raise to crew, escalate if unresolvable
- Drift detected → Stop work, invoke `specrew-drift-check` skill, record in drift-log

**Gates La Forge Operates**:
1. **Task Completion** (per-task): Deliverable produced, actual effort recorded
2. **Execution Phase** (distributed across all tasks)

---

### Worf — Reviewer

**Primary Responsibility**: Verifying delivered tasks meet requirements and are ready for closure.

**Authority**:
- ✅ Reviews each completed task against source requirement
- ✅ Assigns per-task verdicts: pass / needs-work / blocked
- ✅ Produces overall iteration verdict: accepted / needs-rework / blocked
- ✅ Documents review findings in `review.md`
- ✅ Blocks iteration closure if verdicts are incomplete
- ❌ Does NOT rewrite requirements (routes to Picard)
- ❌ Does NOT decide if drift is acceptable (routes to Alon for tie-break)

**Decision Routing**:
- Task alignment ambiguous → Coordinate with Spec Steward for interpretation
- Quality concern → Raise to Alon for policy-level decision
- Drift needs policy decision → Escalate to Alon

**Gates Worf Operates**:
1. **Review/Demo Ceremony Gate** (end of iteration): Per-task verdicts, iteration verdict

---

### Troi — Retro Facilitator

**Primary Responsibility**: Capturing iteration learnings and process improvements.

**Authority**:
- ✅ Facilitates retrospective ceremony
- ✅ Collects estimation accuracy data, drift summary, process notes
- ✅ Documents improvement actions and calibration suggestions
- ✅ Produces `retro.md` artifact
- ✅ Blocks retrospective closure until artifact is complete
- ❌ Does NOT decide process changes (routes to Alon for policy)
- ❌ Does NOT reassess verdicts (Worf owns verdicts)

**Decision Routing**:
- Process improvement → Document in retro.md, route to Alon for adoption
- Estimation calibration → Feed to Data for model adjustment
- Drift pattern → Surface to Picard for coaching

**Gates Troi Operates**:
1. **Retrospective Ceremony Gate** (end of iteration): Retro artifact production, retrospective closure

---

### Alon — Chief Architect & Final Reviewer

**Primary Responsibility**: Architecture direction, governance policy, and escalation decisions.

**Authority**:
- ✅ Makes architecture-level decisions (component boundaries, integration points)
- ✅ Approves governance policy changes (iteration rules, role definitions, escalation paths)
- ✅ Reviews and approves iteration plans and retrospectives before they are finalized
- ✅ Handles tie-breaks and policy-level conflicts
- ✅ Approves abandoned iterations and exception-to-rule cases
- ✅ Final sign-off on iteration completion before next iteration begins
- ✅ Accepts or rejects deliverables based on strategic fit (Worf provides verdicts; Alon provides acceptance)
- ❌ Does NOT do implementation work (that is La Forge)
- ❌ Does NOT do backlog triage (that is Picard)

**Decision Routing**:
- Architecture question → Alon decides and documents decision to `.squad/decisions/inbox/`
- Governance change → Alon approves and updates operational rules
- Deadlock between team members → Alon mediates and decides
- Phase exception (e.g., skip retro) → Alon must explicitly approve with recorded reason

**Gates Alon Operates**:
1. **Iteration Startup Gate**: Architecture-risk spike decisions; pre-planning prerequisites
2. **Plan Approval Gate** (optional): May review plan before execution if complexity warrants
3. **Iteration Closure Gate**: Final sign-off after retro completes; approval to start next iteration

---

## Decision-Making Workflow

### Routine Decisions (No Escalation)

| Decision | Owner | Inputs | Output |
|----------|-------|--------|--------|
| Task effort estimate | Data | Requirement, team history | Estimated story points |
| Task trace to requirement | Picard | Task, spec requirement | Traceability verified or disputed |
| Task review verdict | Worf | Deliverable, requirement, drift-log | pass / needs-work / blocked |
| Estimation variance | Troi | Plan vs. actual, across tasks | Calibration note for next iteration |
| Requirement clarification | Picard | Spec text, task questions | Clarified requirement (no spec change) |

### Tracked Changes (Requires Alon Approval)

| Change | Owner | Approval | Process |
|--------|-------|----------|---------|
| Spec amendment | Picard | Alon | Create entry in `.squad/decisions/inbox/`, Alon approves, merged to spec.md |
| Requirement priority shift | Data + Picard | Alon | Document rationale, Alon approves |
| Iteration scope change (mid-execution) | Picard | Alon | Formal tracked change, new plan revision if needed |
| Governance rule change | Alon | Alon + team consensus | Proposed in `.squad/decisions/inbox/`, team confirms, Alon finalizes |
| Drift resolution → revert implementation | Worf + La Forge | Alon | Formal drift record, Alon approves revert, task re-enters backlog |
| Drift resolution → update spec | Picard | Alon | Formal drift record, spec amendment documented, traced back to drift event |

### Escalation Paths

**Tier 1 — Team Consensus** (Picard coordinates):
- Disagreement on task traceability → Picard + La Forge + Spec Steward review together
- Disagreement on review verdict → Worf + Picard review together
- Disagreement on requirement interpretation → Picard + Data review together

**Tier 2 — Alon Decision** (if Tier 1 cannot agree):
- Architecture conflict
- Process violation with no clear precedent
- Drift resolution that requires spec change
- Governance exception request
- Iteration exception (e.g., skip phase)

---

## Iteration Lifecycle Coordination

### Phase 1: Planning

**Sequence**:
1. **Pre-Planning Spikes** (La Forge + Picard): Architecture-risk spikes run before planning ceremony (Rule 2)
2. **Planning Ceremony** (Data leads, Picard gates):
   - Input: Spec requirements, iteration config, spike results
   - Data: Breaks FRs into tasks, estimates effort
   - Picard: Validates traceability, confirms all FRs covered (Rule 1)
   - Output: `plan.md` with task table
3. **Plan Review** (Alon, optional if high complexity):
   - Alon reviews for architecture risk and scope fit
   - Alon can request changes or approve
4. **Plan Approval Gate** (User or Spec Steward):
   - Stakeholder or designated decision-maker approves plan
   - Status transitions: planning → executing

### Phase 2: Executing

**Sequence**:
1. **Task Dispatch** (La Forge):
   - Agent picks up next task from plan
   - Status: planned → in-progress
2. **Task Completion** (La Forge + Picard per-task):
   - La Forge: Completes task, records actual effort
   - Picard: Runs drift check (Rule 3: traceability-check before task completes)
   - If drift detected: Record in drift-log, escalate to Worf/Alon for resolution
   - Status: in-progress → done (or needs-rework if drift)
3. **State Update** (La Forge):
   - `state.md` updated: last_completed_task, tasks_remaining, timestamp
   - (Enables resume if crew crashes)
4. **Repeat** for each task

**Concurrent Work**:
- As tasks complete, drift-log grows
- If post-task hook unavailable (Iteration 0 fallback): drift-check runs in batch at review phase

### Phase 3: Reviewing

**Sequence**:
1. **Drift-Check Batch** (if not per-task) (Picard):
   - Review all drift-log entries; no new drift should be found (already checked per-task)
   - Fallback for post-task hook unavailability
2. **Review/Demo Ceremony** (Worf leads, Picard observes):
   - Input: Completed tasks, spec requirements, drift-log
   - Worf: Assigns per-task verdicts (pass / needs-work / blocked)
   - Worf: Assigns iteration verdict (accepted / needs-rework / blocked)
   - Output: `review.md`
3. **Verdict Recording** (Worf):
   - All tasks MUST have verdicts
   - Overall iteration verdict MUST be recorded
   - If needs-work: Affected tasks re-enter executing phase (Rule 4: retro and execution can be pipelined)

### Phase 4: Retrospective

**Sequence**:
1. **Retro Ceremony** (Troi leads, Picard observes):
   - Input: All phase artifacts (plan, state, drift-log, review)
   - Estimation accuracy: Compare plan estimates to actual effort
   - Drift summary: Count events, resolution summary
   - Process notes: What went well, what didn't
   - Improvement actions: Concrete actions for next iteration
   - Output: `retro.md`
2. **Retro Review** (Alon, optional):
   - Alon may review retro for process health signals
3. **Iteration Closure** (Alon):
   - Alon reviews all phase artifacts
   - Alon may request changes or approve
   - Status: retro → complete
   - Plan metadata updated: Status = complete, Completed = timestamp
4. **Next Iteration Readiness** (Rule 4: Retro and next planning are decoupled):
   - While retro finishes, pre-planning spikes for next iteration can run in parallel
   - After retro complete + Alon sign-off, planning ceremony begins

---

## Rules for Specrew's Own Development

### Rule 1: Spec Authority Gate Before Task Assignment

The Spec Steward (Picard) gates every iteration plan before execution. The gate checks:
- ✅ All tasks trace to a spec requirement (FR, TG, or support category)
- ✅ All mandatory FRs for this iteration are covered by tasks
- ✅ No orphan tasks (every task has a requirement reference)
- ❌ If any check fails, plan is rejected and Data revises

**Enforcement**: Planning ceremony cannot transition to executing without Picard sign-off.

### Rule 2: Architecture-Risk Spikes Run Before Planning

Before the planning ceremony, La Forge and Picard identify architecture risks and run spikes to de-risk them:
- Impact on task decomposition? (affects plan)
- Blocks execution? (affects scope)
- Affects team composition? (affects role assignments)

**Enforcement**: Planning ceremony does not start until spikes complete.

### Rule 3: Traceability Check Runs Before Task Assignment

Picard runs a traceability check on the plan before any task is assigned:
- Every task maps to a requirement? ✅
- Requirement text is clear enough to execute? ✅
- Task description matches requirement intent? ✅

**Enforcement**: If traceability check fails, plan revision requested before executing phase starts.

### Rule 4: Review Verdict and Retrospective Cycle Are Decoupled

Review verdict is recorded by Worf. Retrospective can run in parallel or after:
- **Parallel**: While Troi is facilitation retro, Picard can identify pre-planning spikes for the next iteration.
- **Sequential**: Retro completes, then pre-planning spikes run, then planning ceremony.

**Enforcement**: Retro cannot be skipped. But iteration 1 prep can overlap with iteration 0 retro.

### Rule 5: Drift-Reporting Directive Deployed at Bootstrap

Every agent gets a drift-reporting directive in their charter. After each task:
1. Agent checks if output matches requirement (per drift-check skill)
2. If drift: Agent immediately invokes `specrew-drift-check` skill
3. If no drift: Agent continues to next task

**Enforcement**: Deployed in `.squad/agents/{agent}/charter.md` by `specrew init`.

### Rule 6: Estimation Tracking Includes Phase-Level Variance

Retro captures not just total effort variance, but per-phase variance:
- Planning phase tasks: estimated vs. actual
- Discovery/spike tasks: estimated vs. actual
- Rework tasks (needs-work verdicts): estimated vs. actual

**Enforcement**: Retro.md template includes per-phase variance table.

---

## Conflict Resolution

### Disagreement on Traceability

**Scenario**: La Forge delivers a task, but Picard says it doesn't match the requirement.

**Steps**:
1. Picard surfaces the mismatch (cite spec text and deliverable)
2. Picard + La Forge review together
3. If they agree: Deliverable is reworked (Task status = needs-rework) or spec is clarified (Picard proposes change)
4. If they disagree: Escalate to Alon

**Resolution**: Task re-enters executing phase or spec amendment routes to Alon

### Disagreement on Review Verdict

**Scenario**: Worf says task verdict is "pass", Picard says "needs-work" (due to drift not caught).

**Steps**:
1. Picard + Worf review the drift-log and requirement
2. If drift is valid: Verdict changed to needs-work, task re-enters executing
3. If drift is debatable: Escalate to Alon

**Resolution**: Verdicts updated in review.md or escalated per team consensus

### Disagreement on Effort Estimate

**Scenario**: Data estimates 5 pts; La Forge marks actual as 8 pts.

**Steps**:
1. La Forge documents variance in retro input
2. Troi captures variance data in retro.md
3. If pattern emerges: Data adjusts effort model or re-calibrates
4. If one-time anomaly: No change; noted for reference

**Resolution**: Calibration data feeds into next iteration planning; no blocking decision

### Governance Exception Request

**Scenario**: Team wants to skip retro for a sprint to move fast.

**Steps**:
1. Team proposes exception to Alon with rationale
2. Alon documents decision to `.squad/decisions/inbox/`
3. Alon either approves (with recorded reason) or declines
4. If approved: Exception applies only to that iteration; standard rules resume next iteration

**Resolution**: Alon decision is final; recorded in decisions.md

---

## Status Reporting & Visibility

### Iteration Status Artifact

Every iteration's status is recorded in `plan.md` metadata:

```markdown
# Iteration Plan: NNN

**Status**: planning | executing | reviewing | retro | complete | abandoned
**Capacity**: {used}/{total}
**Started**: YYYY-MM-DD
**Completed**: YYYY-MM-DD (or blank)
```

Status is updated by the phase owner as iteration progresses.

### Drift Log

As drift events occur, they are recorded in `iterations/NNN/drift-log.md`:

```markdown
- **DR-001**: Detected YYYY-MM-DD during T-001
  - **Requirement**: FR-003
  - **Deviation**: [specific mismatch]
  - **Resolution**: [spec-updated | implementation-reverted | deferred]
```

Accessible to all team members for transparency.

### Phase Completion Checklist

Before moving to the next phase, these checks MUST pass:

| From | To | Checklist |
|------|----|----|
| planning | executing | plan.md exists, traceability check passed, Picard approved |
| executing | reviewing | state.md final, drift-log complete, all tasks in terminal state |
| reviewing | retro | review.md exists, all verdicts recorded, iteration verdict recorded |
| retro | complete | retro.md exists, all mandatory fields populated, Alon approved |

---

## Escalation Summary

| Issue | Route To | Decision Criteria | Output |
|-------|----------|------------------|--------|
| Spec clarification | Picard | Req ambiguous? → Clarify or amend | Clarified requirement or tracked change |
| Drift resolution | Picard + Worf | Revert or update spec? | Implementation-reverted OR spec-updated |
| Effort estimate variance | Data + Troi | Calibration signal? → Adjust model | Model update or note for reference |
| Deadline/capacity conflict | Alon | Defer tasks or extend? → Strategic call | Updated plan or exception approval |
| Governance exception | Alon | Request documented? → Approve or decline | Decision recorded in decisions.md |
| Architecture concern | Alon | Risk to design? → Decide | Architecture decision or spike triggered |

---

## Implementation Notes

### For Specrew's Own Development

- This protocol applies immediately to Specrew's Iteration 0 closure and all subsequent iterations.
- Iteration 0 closure artifacts (state.md, drift-log.md, retro.md) MUST be created to close the phase.
- All future Specrew iterations follow this protocol explicitly.

### For Downstream Projects Using Specrew

- Downstream projects inherit this protocol as a reference model.
- The role names and escalation paths remain the same, but team members may differ.
- Downstream projects should customize where appropriate but maintain the four-phase structure.

---

## Changelog

| Date | Author | Change |
|------|--------|--------|
| 2026-04-18 | Picard | v1.0 — Initial governance protocol |

