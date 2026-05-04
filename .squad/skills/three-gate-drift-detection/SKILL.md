---
name: "three-gate-drift-detection"
description: "Use three synchronized gates (planning, spec review, reviewer verdict) to catch and resolve specification and implementation drift within the same iteration without rework loops"
domain: "governance"
confidence: "high"
source: "earned"
tools:
  - name: "planning validator"
    description: "Run governance validator at planning gate"
    when: "Before execution starts to catch capacity, traceability, and effort-model alignment issues"
  - name: "spec-authority gate"
    description: "Spec Steward audits planned tasks for specification gaps"
    when: "During planning ceremony to surface ambiguous acceptance criteria and hidden dependencies"
  - name: "reviewer verdict gate"
    description: "Reviewer batches acceptance verdicts per requirement slice"
    when: "After all implementation tasks complete to bind specification compliance and test coverage"
---

## Context

Iteration 002 demonstrated that specification and implementation drift can be reliably caught and resolved within the same iteration using three synchronized gates, with zero rework loops required. The pattern emerged from:

- **Planning gate** (validate-governance.ps1): Enforces effort-model alignment, capacity checks, traceability validation
- **Spec review gate** (Spec Steward audit): Catches implementation drift vs. requirement intent early by auditing planned tasks
- **Reviewer verdict gate** (per-requirement slice acceptance): Binds specification compliance with test coverage and acceptance criteria verification

All three gates operate in parallel (not serial), and each gate focuses on a distinct class of drift:
- Planning gate: Structural alignment (capacity, traceability, metadata)
- Spec review gate: Specification ambiguity (acceptance criteria, implicit dependencies)
- Reviewer gate: Implementation fidelity (spec compliance, test coverage, acceptance pass)

## Pattern

### Gate 1: Planning Gate (Pre-Execution)

1. **When**: Before the iteration moves from `planning` to `executing` status
2. **Who**: Planner + validator automation
3. **What to check**:
   - All tasks have requirement references (FR/TG mappings)
   - Total estimated effort does not exceed capacity or overcommit threshold
   - Effort model snapshot is present and matches `.specrew/iteration-config.yml`
   - Phase-level estimation baseline is documented
4. **Failure path**: If validation fails, add a clarification task or defer requirement; re-plan and re-validate
5. **Success criteria**: Validator exits cleanly; all tasks pass traceability and capacity checks

### Gate 2: Spec Review Gate (During Planning Ceremony)

1. **When**: During planning ceremony, as part of task review (pre-execution, same timing as Gate 1)
2. **Who**: Spec Steward (in parallel with implementers preparing task designs)
3. **What to check**:
   - Does the spec define all acceptance criteria for each planned task?
   - Are there implicit dependencies or hidden couplings between tasks?
   - Is the success condition binary (pass/fail) or subjective?
   - Are there ambiguities in language, scope, or priority?
4. **Failure path**: If gaps are found, add clarification tasks to this iteration or defer requirement; re-plan before execution
5. **Success criteria**: Spec Steward confirms each task's requirement is unambiguous and implementable

### Gate 3: Reviewer Verdict Gate (Post-Implementation)

1. **When**: After all implementation tasks complete (before retro phase)
2. **Who**: Reviewer (batched per requirement slice, single verdict date)
3. **What to check**:
   - Does the implementation satisfy the specification?
   - Are acceptance criteria defined in the spec all verified by tests?
   - Is test coverage sufficient to prove the requirement?
   - Are any drift events logged in drift-log.md? If so, are they resolved?
4. **Failure path**: If verdict is `needs-work`, task moves back to `executing`; implementer reworks; re-review
5. **Success criteria**: Verdict recorded as `pass` or `blocked` (not `needs-work` if accepted)

## Data Flow

```
Plan Created
      ↓
Planning Gate [Validator] → (fails: replan; passes: continue)
      ↓
Spec Review Gate [Spec Steward] → (fails: replan; passes: continue)
      ↓
Execution Starts
      ↓
Tasks Complete
      ↓
Reviewer Verdict Gate [Reviewer] → (fails: rework; passes: bind verdict)
      ↓
All Verdicts Recorded
      ↓
Retro Phase Starts
```

## When To Reuse

- **Iteration planning**: Before execution starts, run both Planning and Spec Review gates to surface ambiguities early
- **Mid-iteration audits**: If execution is stalled, re-run Spec Review gate to confirm no hidden blocker
- **Review/demo ceremonies**: Batch reviewer verdicts per requirement slice to keep gate clarity high
- **Process improvement**: If estimation variance is high or rework loops are frequent, check whether all three gates are running and focused on their specific drift class

## Anti-Patterns

- **Serial gates (waterfall)**: Running gates one-at-a-time wastes cycle time. Planning and Spec Review gates should run in parallel during planning ceremony.
- **Collapsing gates**: Asking reviewers to also validate effort model or spec ambiguity overloads the verdict gate. Each gate has a single focus.
- **Skipping Spec Review**: If Spec Steward skips the planning ceremony, spec gaps won't surface until implementation or review (2–4 day latency). This is the highest-ROI gate to keep operational.
- **Loosening reviewer verdicts**: If reviewers accept `needs-work` verdicts without actual rework, the gate stops binding implementation to spec.

## Examples

### Example 1: Spec Ambiguity Caught at Planning Gate (No Rework)

**Scenario**: Iteration 2, task T-204 (FR-019 resume command). Spec says "resume from last completed task" but doesn't clarify whether "last task" means task ID or task metadata.

1. **Planning Gate**: Validator passes (task is traceable, capacity OK)
2. **Spec Review Gate**: Spec Steward asks "Does the spec define where last-task state is persisted?" Answer: No, ambiguous.
3. **Resolution**: Add a clarification line to T-204 task description or defer T-204 and add a spec-clarification task to this iteration
4. **Outcome**: Implementation T-204 runs with clear spec; no rework needed later

### Example 2: Implementation Drift Caught at Reviewer Gate (Tight Rework)

**Scenario**: Iteration 2, task T-202 (FR-017 overcommit guidance). Implementation suggests deferring tasks by order; spec requires lowest-priority-first deferral.

1. **Planning Gate**: Passes (T-202 is traceable, capacity OK)
2. **Spec Review Gate**: Passes (spec clearly says "priority-ranked deferral")
3. **Implementation**: T-202 logic deferrs by task order, not priority (implementation drift)
4. **Reviewer Gate**: Verdict is `needs-work`. Reviewer notes "Deferral logic must rank by requirement priority, not task order."
5. **Rework**: T-202 implementer adds priority-ranking logic, adds test for lowest-priority-first deferral
6. **Re-review**: Verdict flips to `pass` once tests confirm priority ranking

### Example 3: Specification Drift Caught at Both Planning and Reviewer Gates (Consensus)

**Scenario**: Iteration 2, tasks T-205/T-206 (FR-020 brownfield merge). Spec says "detect conflicts and ask user how to proceed" but doesn't enumerate what counts as a conflict.

1. **Planning Gate**: Passes (tasks are traceable)
2. **Spec Review Gate**: Spec Steward asks "What are the 7 collision classes?" Answer: Spec doesn't list them. **Red flag**: Specification gap.
3. **Resolution**: Picard (Spec Steward) conducts a focused brownfield audit (same task, same day) to enumerate the 7 gates. Spec is updated in a narrow decision memo.
4. **Implementation**: T-205/T-206 now have clear acceptance criteria (7 gates must be checked)
5. **Reviewer Gate**: Worf checks that all 7 gates are in place; verdict `pass` once confirmed

## Estimation Accuracy Benefit

Iteration 002 achieved **zero estimation variance** (16/16 story points planned = actual) when all three gates were operational:
- Planning gate ensured no scoping ambiguity before task assignment
- Spec review gate ensured no specification ambiguity before implementation
- Reviewer gate ensured no implementation-spec mismatch before closure

This pattern generalizes: **tight estimation requires all three gates to operate**.

## Scalability Note

For teams with many concurrent iterations or larger requirement slices:
- Batch Spec Review gate per requirement (not per task) to reduce planning ceremony duration
- Batch Reviewer gate per requirement slice (not per task) to simplify verdict recording
- Keep validator automation high (Gate 1) to reduce manual ceremony overhead

The three-gate pattern scales because each gate focuses on a single drift class. Adding requirements or iterations only requires more batches, not structural change.
