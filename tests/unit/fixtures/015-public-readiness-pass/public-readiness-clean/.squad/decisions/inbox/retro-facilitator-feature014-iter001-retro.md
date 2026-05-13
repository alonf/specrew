# Retrospective Decision: Feature 014 Iteration 001

**Date**: 2026-05-12  
**Facilitator**: Retro Facilitator  
**Scope**: Feature 014 handoff-format-scoping, Iteration 001 retrospective boundary

---

## Context

Feature 014 iteration 001 delivered the bounded stop-vs-progress selector and additive soft-warning rollout (FR-001 through FR-007) on 2026-05-12. Review verdict was **accepted** at commit 8e99013 with zero rework required. Retrospective analysis reveals zero estimation variance (8.0 sp actual = 8.0 sp planned) and three critical process patterns to protect in future iterations.

---

## Key Findings

### 1. Zero-Variance Delivery Pattern

- **What Happened**: All 15 tasks delivered at estimated effort (0% variance total, -12.5% unused rework buffer). No discovery surprises, no late-found gaps, zero review rework cycles.
- **Root Cause**: Tight scope locking before execution. Feature 014 plan.md clearly separated Iteration 001 (selector + additive warnings) from deferred Iteration 002 (proof + calibration) before work started. No new unknowns emerged during implementation.
- **Signal**: This is not luck. Feature 007 iteration 001 also achieved 0% variance with similar upstream planning rigor. The pattern is durable.
- **Decision**: Future well-scoped feature refinements should model their capacity planning on this pattern. Reduce the rework buffer from 1.0 sp to 0.5 sp for tight-scoped features where Iteration 001 is clearly bounded and Iteration 002 is deferred. Keep exploration/spike capacity at 0.5 sp baseline.

### 2. Boundary-Claim-Without-Commit Trap (Critical)

- **What Happened**: Review.md was committed at 8e99013 claiming the review boundary is durably complete. However, retro.md did not exist until after separate human authorization in this session. The iteration state appeared complete in git history but was logically incomplete until the retrospective phase could actually start.
- **Risk**: Future automation or planners treating the review claim as complete truth when the next phase's prerequisites are not yet met.
- **Candidate Rule** (for implementation in FR-008 or a future governance feature): Before accepting a `-boundary` commit, verify that either (a) all required artifacts for the next phase exist and are committed, or (b) the next phase is explicitly deferred in state.md with a human approval note. Reject the boundary claim if both conditions fail.
- **Decision**: Add this pattern to `.specrew/quality/known-traps.md` under a new row `boundary-claim-without-commit` with the evidence from Feature 014 iteration 001. Include the detection rule candidate so future governance work can implement it as a validator gate.

### 3. Startup-Coupling Task Invisibility Trap

- **What Happened**: Tasks T010 and T011 modified startup-loaded config files (`.github/agents/squad.agent.md`, `.squad/templates/squad.agent.md`). The mandatory session-restart requirement was documented in state.md, not in the task definition itself. This requirement was only surfaced during retrospective, not at task time.
- **Risk**: Implementation team completes the work, commits it, and later planners run in old sessions without knowing a restart is required. Silent activation gaps.
- **Candidate Rule**: Scan task.md for any task that edits files under `.github/agents/`, `.squad/templates/`, or `.specrew/config/`. Flag tasks without an explicit "Session restart required" note in the acceptance criteria.
- **Decision**: Add this pattern to `.specrew/quality/known-traps.md` under a new row `startup-coupling-task-invisibility`. Include task-definition template guidance: any startup-config task must state "[Task name] | Acceptance: [description]. **Session restart required for next session.**"

### 4. Acceptance-Evidence Scattering

- **What Happened**: Task T008 (manual validator exercise) had its acceptance criteria defined in tasks.md, but the expected test outputs and scenarios were scattered across spec.md (User Story 2 scenarios), contract.md (approved scenarios), and plan.md (task description). The team had to infer evidence from multiple sources rather than reading one unified definition.
- **Risk**: Underspecified test acceptance criteria make it harder to verify task completion and increase review friction.
- **Candidate Rule**: For any task with acceptance criteria "verify X" or "manually exercise Y," the task definition must include explicit expected outcomes in a single artifact, not scattered across multiple sources.
- **Decision**: Add this pattern to `.specrew/quality/known-traps.md` under a new row `acceptance-evidence-scattering`. Include guidance: "Task definitions must include acceptance evidence signatures. Instead of 'Manually exercise the new warning paths,' write 'Manually exercise: (1) correct-final-stop → pass; (2) placeholder-only → soft-warning.empty-user-action-section; [etc]. Update contract.md with observed results.' Unify acceptance in the task boundary."

---

## Improvement Actions (Binding for Next Planning)

1. **Action**: Before any future `-boundary` commit (review, retro, closeout), run a "boundary-claim durability checklist" validation. Check: (a) Preceding phase artifacts complete and committed, (b) Next phase artifacts exist or are explicitly deferred, (c) Validator passes with both phases' minimum artifacts.
   - **Owner**: Spec Steward + Iteration Facilitator
   - **Target**: Next planning ceremony or future governance feature (FR-008+)
   - **Expected Effect**: Prevent boundary-claim-without-commit patterns from recurring.

2. **Action**: Embed acceptance evidence signatures into task definitions in plan.md and tasks.md. For any "verify X" or "test Y" task, include explicit expected outcomes (e.g., "scenario A → pass; scenario B → soft-warning X") in the task entry itself.
   - **Owner**: Iteration Facilitator + Governance prompt stewards
   - **Target**: Next planning ceremony
   - **Expected Effect**: Unify acceptance criteria in task boundary, reduce review friction.

3. **Action**: For any task modifying startup-loaded config files, add a mandatory note in acceptance criteria: "Session restart required for next session." Make this visible at task time, not discovered later.
   - **Owner**: Governance prompt stewards
   - **Target**: Next iteration planning (feature 015+)
   - **Expected Effect**: Prevent silent session-coupling gaps.

---

## Known-Traps Additions (Candidate for Feature 014 Iteration 002 FR-008)

The following candidate rows should be added to `.specrew/quality/known-traps.md` during Iteration 002:

1. **`boundary-claim-without-commit`**: Lifecycle boundary claims (review, retro, closeout) recorded in committed artifacts must not be made unless all prerequisites for that boundary are durably met or explicitly deferred. A review-boundary claim without a retro-ready state creates a durability gap.

2. **`startup-coupling-task-invisibility`**: Tasks modifying startup-loaded config files must explicitly document the session-restart requirement in task acceptance criteria. This prevents silent activation gaps where changes are committed but not loaded until a manual session restart.

3. **`acceptance-evidence-scattering`**: Task acceptance criteria for verification or testing tasks must include expected evidence signatures in the task definition itself, not scattered across spec, contract, and plan artifacts.

---

## Sign-Off

- **Retro Boundary**: Open, pending final human authorization before iteration closeout.
- **Team-Relevant Decisions**: Recorded above; shared with .squad/decisions/inbox/ for integration into next planning ceremony.
- **Deferred to Iteration 002**: Addition of the three candidate known-traps rows to `.specrew/quality/known-traps.md` as part of FR-008 work.

---

**Status**: Awaiting Alon Fliess's separate authorization before closing the retrospective boundary and opening the closeout phase.
