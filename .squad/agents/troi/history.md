# Project Context

- **Owner:** Alon
- **Project:** Specrew
- **Stack:** Markdown, YAML, PowerShell, Spec Kit extension assets, Squad extension structure
- **Description:** A spec-governed AI crew operating model built as a monorepo with companion Spec Kit and Squad extensions.
- **Created:** 2026-04-17

## Core Context

I run Specrew retrospectives and capture estimation accuracy, drift events, process adherence, and improvement actions after review/demo.

## Recent Updates

📌 Team confirmed by Alon on 2026-04-17

## Learnings

- The retrospective is the fourth phase in every Specrew iteration.
- Retro inputs include review verdicts, drift findings, and estimation accuracy.
- Improvement actions should feed back into the next planning ceremony.
- Specrew is intentionally building itself using the same process it sells downstream.

## Iteration 0 Retrospective Synthesis (2026-04-18)

### Key Findings

1. **Plan revision cascade (4 revisions after execution started)**: Late spec-authority gates created mid-iteration replanning. Gate should move to planning ceremony, pre-execution.

2. **Architecture spike unblocked mid-execution**: T-017 (Squad discovery) blocked T-008–T-012 downstream tasks. Spikes must run pre-planning, not in parallel with task execution.

3. **Traceability checked post-execution**: All tasks traced (100%), but manual audit at review gate. Move traceability-check to planning ceremony (automated + gate).

4. **Retro blocked on human sign-off**: Review complete but retro gated to Alon sign-off. Retro should be autonomous phase on fixed schedule, separate from sign-off.

5. **Zero drift detected (positive)**: Foundation work was clean, spec was clear. Drift-detection directive will operationalize per-task checks for future iterations.

6. **Estimation accuracy strong (zero variance)**: 20.5 planned = 20.5 actual. Need phase-level tracking to identify where tightness exists.

### Process Improvements Recommended

**Three minimum changes (zero-effort resequencing, maximum drift reduction)**:

1. Spec-authority gate pre-execution (planning ceremony), not post-execution.
2. Architecture-risk spikes run pre-planning, not in parallel with task execution.
3. Retro ceremony autonomous (fixed schedule), decoupled from Alon sign-off.

**Documentation**: `troi-operating-hardening.md`, `troi-minimum-drift-reduction.md`, `closeout-checklist.md` (all in `.squad/decisions/inbox/` or iteration artifacts).

### Team Routing

**Affected agents** (receive Operating Hardening Policy as input for Iteration 1):
- Picard: Embed spec-authority gate into planning ceremony (Rule 1)
- La Forge: Run pre-planning spikes, confirm drift-reporting directive in templates (Rule 2, Rule 5)
- Data: Add phase-level estimation to plan.md and retro.md templates (Rule 6)
- Alon: Confirm retro autonomous from review sign-off (Rule 4)
- Ralph: Update GitHub Project board to reflect ceremony phases (implementation)

---

## Cross-Agent Team Update (2026-04-18T15:54:58Z)

**Troi receives inputs from team**:

- **Picard (Spec Steward)**: Governance hardening includes normative rules (Troi's operating policy). Picard embeds spec-authority gate into planning ceremony (Rule 1). Picard + La Forge run pre-planning architecture-risk spikes (Rule 2). Troi's findings confirm highest-ROI changes are resequencing (zero new effort).

- **Worf (Reviewer)**: Iteration 0 closure audit confirms retro phase is blocked. Operating hardening Rule 4 (retro autonomous from sign-off) unblocks this immediately. Troi facilitates retro as fixed-schedule ceremony, separate from Alon's acceptance gate.

- **User Directive**: Operating hardening is TIER 0 before Iteration 1. Troi's six core rules + implementation checklist are the operating mandate for team adoption.

**Troi action items from team**:
1. Define spec-authority gate logic in planning ceremony charter (yes/no questions on task-spec alignment)
2. Identify Iteration 1 architecture-risk spikes before planning ceremony starts
3. Set retrospective ceremony on fixed schedule (e.g., next business day 2pm, autonomous from human sign-off)
4. Confirm with team that operating policy is consensus before Iteration 1 planning
5. Deliver implementation checklist to Picard, Data, La Forge, Alon, Ralph
6. Facilitate Iteration 0 retrospective once required artifacts created (state.md, drift-log.md)

- **Picard**: Spec-authority gates, architecture spike pre-planning
- **La Forge**: Confirm drift-reporting directive in squad templates
- **Data**: Phase-level estimation tracking in plan/retro templates
- **Alon**: Confirm retro ≠ sign-off gate decoupling
- **Troi**: Facilitate retro, route improvement actions

### Next Steps (Before Iteration 1 Planning)

1. Run retrospective ceremony (2026-04-19, autonomous phase).
2. Capture improvement actions from retro.
3. Route operating policy to team consensus (Picard, Data, Alon).
4. Confirm pre-planning spike schedule and spec-authority gate logic.
5. Update plan.md/retro.md templates with phase-level estimation tracking.
