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

📌 **Iteration 1 operating policy consensus confirmed (2026-04-19)**:

- 6 core operating rules assessed and consensus verified
- No objections to rules' intent or logic from any team member
- 3 implementation tasks pending before planning ceremony:
  - Spike schedule confirmation (Picard + La Forge)
  - Retro schedule policy confirmation (Alon)
  - Template updates for per-phase tracking (Data)
- Status: Ready for Alon approval; team consensus-sound

📌 **Decision inbox merged (2026-04-19T02:06:00Z)**:

- Operating consensus check decision recorded and archived
- 6 inbox decisions consolidated into decisions.md

## Learnings

- The retrospective is the fourth phase in every Specrew iteration.
- Retro inputs include review verdicts, drift findings, and estimation accuracy.
- Improvement actions should feed back into the next planning ceremony.
- Specrew is intentionally building itself using the same process it sells downstream.
- Artifact consistency requires role naming alignment across retro.md and team.md; Alon's role is Chief Architect & Reviewer (not Spec Steward) — verified and corrected in Iteration 0 retro (2026-04-18).
- Retro closure wording must mark the ceremony complete without advancing the iteration to `complete`; only Alon's sign-off clears that final state change.

## Iteration 002 Retrospective Synthesis (2026-05-03)

### Key Findings

1. **Zero estimation variance (16/16 pts)**: Perfect task-level accuracy. Three factors:
   - Planning discipline: Pre-execution design spikes (V-R7-2, T-201) eliminated design ambiguity.
   - Well-scoped tasks: Each task mapped to a single requirement slice.
   - No mid-iteration re-scoping: Plan remained intact from approval through completion.

2. **Drift detection automated & early (6/6 events, 100% in-phase resolution)**: All drift surfaced via gate-based audits (spec review, planning validation, evaluation audit). No drift escaped to post-review discovery. This is the outcome of Iteration 0's pre-execution gates improvement working effectively.

3. **Reviewer gates worked as designed (0 rework loops)**: Worf's 2026-05-03 acceptance reviews were crisp, high-signal verdicts. Each review referenced specific test coverage and acceptance criteria. Single verdict date, no rework loops required.

4. **Slice sequencing prevented blocking**: Six independent requirement slices (FR-007, FR-015, FR-017, FR-019, FR-020, FR-021) were planned with minimal inter-task coupling. No critical-path bottlenecks emerged. Parallel slice execution kept the team moving.

5. **Specification drift corrections were narrow & accepted (4/6 events)**: Spec gaps in FR-020 (collision gates not enumerated) and FR-019 (stale metadata handling) required narrow clarifications but no rework. Root cause: Pre-execution gates ran post-planning, not during planning ceremony.

### Process Improvements Recommended

**Four tier-1 actions for Iteration 3** (zero effort + 0.5 pts documentation):

1. **Pre-Planning Spec-Authority Gate** (planning ceremony, not post-execution): Move the spec-review gate from T-205 (post-planning) to planning ceremony pre-execution. Effort 0, ROI: reduce spec-related drift latency 80%.

2. **Slice Boundary Documentation**: Add "## Scope Clarifications" to plan.md for multi-iteration requirements. Effort 0, ROI: reduce stakeholder misalignment.

3. **Mid-Iteration Phase Checkpoints**: Define expected completion dates for each phase (planning by day 2, 50% impl by day 4, etc.). Effort 1, ROI: early velocity detection.

4. **Implementer-Logged Drift Detection**: Embed drift logging in implementer charter. Each task close triggers a one-sentence drift-check prompt. Effort 0.5, ROI: distributed drift detection reduces gate bottlenecks.

### Team Routing

**Iteration 3 Planning Prerequisite**:

- **Picard**: Embed spec-authority gate into planning ceremony (Action 1). Move FR-020 brownfield audit from post-planning to planning ceremony. Add scope clarification section to plan.md template (Action 2).
- **La Forge**: Add checkpoint schedule to plan.md and velocity tracking to state.md. Update implementer charter with drift-check prompt (Action 4).
- **Worf**: Continue reviewer gate structure; no changes needed (gates working as designed).
- **Troi**: Facilitate Iteration 3 planning ceremony with pre-planning spec-authority gate. Route improvements to team consensus before execution.
- **Data**: Update plan.md template with checkpoint section and multi-iteration scope clarifications.

### Retro Verdict

**Iteration 002**: ✅ COMPLETE — Retrospective closed. Post-MVP capability expansion delivered per spec. Zero estimation variance. 100% drift detection rate. 0 rework loops. All four iteration artifacts complete. Ready for Alon final sign-off.

**Process Quality**: ✅ EXCELLENT — Operating policy rules 1–6 all effective. Governance hardening (planning gates, spec review, reviewer verdicts) working as designed. Three-gate structure has proven effective at detecting and resolving drift within the same iteration.

**Blocking Issues**: NONE. Iteration 3 can begin once Alon approves Iteration 002 closure and team consensus is reached on four tier-1 improvements.

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

### 2026-04-18T18-50-28Z: Iteration 000 Closeout Session Update

**Session**: Scribe Handoff Log — Iteration 000 Complete, Iteration 001 Planning-Ready  
**Update**: Retrospective ceremony CLOSED; operating policy (6 rules + 3 tier-1 improvements) proposed; team consensus awaiting

**Key Facts**:

- ✅ Iteration 0 retrospective ceremony CLOSED (2026-04-18) — all mandatory sections complete (estimation accuracy, drift summary, process notes, improvement actions)
- ✅ Operating policy framework finalized: 6 core rules + 3 tier-1 improvements (zero-effort resequencing, maximum ROI)
- ✅ Troi-facilitated consensus pending before Iteration 1 planning ceremony begins
- ✅ Alon final sign-off officially recorded (2026-04-18T18:15:45Z) — Iteration 0 moved to `complete` status
- ✅ Retro is now autonomous phase on fixed schedule (decoupled from Alon sign-off per operating policy)
- ✅ Three tier-1 improvements ready for adoption: spec-authority gate pre-execution, architecture-risk spikes pre-planning, retro autonomous start

**Role Note**: Retro Facilitator role now owns team consensus on operating policy before Iteration 1 planning ceremony. Three tier-1 improvements (zero new effort) recommended for immediate adoption. All future iterations will enforce same operating model (6 core rules) once team consensus confirmed.

---

## Learnings

- **2026-04-18 Final Gate Review**: The governance validator script (`validate-governance.ps1`) is now a critical ceremony gate tool. Running it at final gate confirms all artifacts are present and schema-compliant. The script enforces phase-specific artifact requirements (e.g., retro.md required only at `complete` status).
- Governance hardening creates a closed loop: spec defines the state machine (normative), contracts define the artifacts and gates, protocol defines the roles and escalation, validator enforces compliance. All four must be coherent.
- Final gate review should verify three things: (1) formal closure per lifecycle contract, (2) governance hardening implementation coherent, (3) no blocking issues for next phase. This is the pattern for future iteration closeouts.

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

---

## Iteration 0 Retrospective Complete (2026-04-18)

### Artifacts Created

✅ **state.md** — Terminal state: all 23 tasks complete, 20.5/20.5 pts delivered, zero variance  
✅ **drift-log.md** — Zero drift events; late gates prevented out-of-scope work  
✅ **retro.md** — Full retrospective with estimation accuracy, drift summary, process findings, and three tier-1 improvements  
✅ **plan.md metadata updated** — Status: complete, Capacity: 20.5/20.5, Completed: 2026-04-18

### Key Findings

1. **Estimation Accuracy**: Perfect (20.5/20.5, 0% variance). Foundation work is inherently low-discovery.
2. **Drift Summary**: Zero specification drift. Late spec-authority gates (post-execution) caught issues but created plan churn (4 revisions after execution started).
3. **Process Improvements** (Tier 1 — zero effort, maximum ROI):
   - **Move spec-authority gate to planning ceremony** (pre-execution) → prevents 80%+ plan churn
   - **Run architecture spikes pre-planning** → eliminates hidden blocking dependencies
   - **Decouple retro from sign-off** → retro autonomous on fixed schedule

### Team Routing

**Improvement Actions**:

- **Picard**: Embed spec-authority gate into planning ceremony charter (Rule 1 of operating policy)
- **La Forge**: Identify architecture-risk spikes before planning ceremony (Rule 2)
- **Data**: Add phase-level estimation tracking to plan/retro templates (Rule 6)
- **Alon**: Confirm retro autonomous schedule, separate from sign-off gate (Rule 4)
- **Team**: Consensus on six core operating rules before Iteration 1 planning

### Retro Verdict

**Iteration 0**: ✅ COMPLETE — Retrospective closed. Foundation work validated. Platform readiness confirmed. Zero integration blockers. Ready for Iteration 1 planning.

**Process Quality**: ✅ HEALTHY — Late gates created friction (improvement opportunity), but overall governance model is sound. Three minimum changes (zero effort) will reduce drift-detection latency 80%+.

**Blocking Issues**: NONE. Iteration 1 can begin.

### Learnings

- Foundation iterations naturally have lower drift risk due to mechanical output nature (scaffolding, stubs). Iteration 1+ (runtime behavior) will require closer drift monitoring.
- Late gates work (they catch issues) but waste cycle time. Early gates (pre-execution) are the same logic applied earlier — massive ROI from resequencing alone.
- Architecture spikes should run pre-planning to surface design issues before task assignments create implicit dependencies.
- Retrospective ceremony should be autonomous (fixed schedule) from human sign-off. Two separate phases (retro findings inform sign-off decision; they don't wait for it).
- Phase-level estimation tracking will reveal where tightness exists and where buffer is consumed.

### 2026-04-18T13-30-34Z: Iteration 0 Retrospective Findings Decision Merged

**Status**: ✅ DECIDED & MERGED

**Scribe Summary**: Troi's retrospective findings decision merged into `.squad/decisions.md` under "2026-04-18: Iteration 0 Retrospective Findings & Process Improvements". Three-part improvement proposal finalized:

1. **Spec-Authority Gate Pre-Execution** (planning ceremony gate, not post-execution) — Effort 0, ROI: 4 plan revisions → 0–1
2. **Architecture-Risk Spikes Pre-Planning** (spikes identified and run before planning ceremony) — Effort 0 + 1 hr/iteration, ROI: eliminates hidden dependencies
3. **Retro Ceremony Autonomous from Sign-Off** (fixed schedule, separate phase) — Effort 0, ROI: retro blocked 1+ day → same-day/next-day

**Operating Policy (6 Core Rules)** documented for team consensus:

1. Spec-Authority Gate pre-task assignment (planning ceremony)
2. Architecture-Risk Spikes pre-planning (planning prerequisite)
3. Traceability Check pre-task assignment (planning ceremony)
4. Retro & Sign-Off Decoupled (autonomous phase, fixed schedule)
5. Drift-Reporting Directive deployed at bootstrap (all agent charters)
6. Phase-Level Estimation Tracking (plan + retro templates)

**Status**: Proposed—awaiting team consensus before Iteration 1 planning ceremony.

**Implementation Checklist** (before Iteration 1 planning):

- [ ] Picard: Draft planning ceremony charter with spec-authority gate logic
- [ ] La Forge + Picard: Identify 2–3 architecture-risk spikes for Iteration 1
- [ ] Alon: Confirm retro schedule policy (e.g., "Retro runs Fridays 2pm")
- [ ] Data: Update plan.md template with per-phase effort estimates
- [ ] Troi: Facilitate team consensus on six core operating rules
- [ ] Team: Confirm operating policy before Iteration 1 planning

**Cross-Agent Implication**: Troi's improvement actions route to Picard (spec-authority), La Forge (spikes), Data (templates), Alon (policy), and team consensus. Three-part improvement is dependency-ordered: gates must move pre-execution before Iteration 1 planning can safely commence with higher-risk implementation work.

---

## Cross-Agent Team Update (2026-04-18T17:31:28Z)

**Artifact Cleanup & Validation Hardening Complete**

**Troi (Retrospective Artifact Consistency)**: retro.md role naming aligned with authoritative source (team.md).

- **Change**: Line 251, Section "Action 3: Retro Ceremony Autonomous from Sign-Off"
- **Before**: "Alon's acceptance gate (Spec Steward sign-off) remains a separate decision..."
- **After**: "Alon's acceptance gate (Chief Architect & Reviewer sign-off) remains a separate decision..."
- **Source of Truth**: team.md line 15 = Alon | Chief Architect & Reviewer; line 16 = Picard | Spec Steward
- **Impact**: Retro artifact now matches final team structure. No process/content impact; naming correction only.

**Context**: External review identified stale role names in retrospective written before Alon's role title was finalized in team.md. Cleaned up for consistency and downstream accuracy.

- **Data (Planning Artifact Cleanup)**: state.md and plan.md updated to reflect Iteration 0 final closed state
- **La Forge (Validator Tightening)**: `validate-governance.ps1` hardened; semantic lifecycle drift now caught cleanly
- **Worf (Review Artifact Freshness)**: review.md updated to post-retro state with corrected role names

**Status**: All four agents' artifact cleanup complete. Decisions merged to .squad/decisions.md. Iteration 0 closure official and binding.

---

## Documentation Truth-Gap Resolution (2026-05-XX)

### Summary

Updated `docs/getting-started.md` to align with actual runtime behavior and current upstream blockers.

### Truth Gap Identified

1. **Greenfield `-Force` requirement**: Documentation claimed git-only repos could bootstrap without `-Force`, but runtime actually prompts for confirmation in interactive mode (fails non-interactively). Test `bootstrap-to-iteration.ps1` confirmed the stall.

2. **Spec Kit 1.0.0 asset blocker**: Documentation did not mention the current `No matching release asset found for copilot` error that blocks `.specify/` initialization with latest Spec Kit. This leaves users stranded mid-bootstrap without guidance.

3. **No actionable workaround**: Users hitting the asset blocker had no documented path forward (downgrade to 0.7.3 or monitor upstream fix).

### Changes Made

**docs/getting-started.md**:

- Greenfield Prerequisites: Added warning about Spec Kit 1.0.0 asset blocker with link to Spec Kit repo
- Greenfield Bootstrap: Changed from `pwsh -File ... -ProjectPath .` to `pwsh -File ... -ProjectPath . -Force` with explicit warning that `-Force` is required even for git-only repos
- Verification section: Clarified that bootstrap can fail if CLIs fail; added note about checking `.specify/` missing = Spec Kit CLI failure
- Notes section: Removed false statement ("For truly empty repos, -Force not required"); updated to "Always use -Force for reliable non-interactive bootstrap"
- Known Limitations: Added tier-1 section "Blocker: Spec Kit CLI Asset Dependency Issue" with:
  - Current status (Spec Kit 1.0.0)
  - Impact on greenfield-to-iteration flow
  - Verification command to check if hit
  - Actionable next step: downgrade to 0.7.3 or wait for upstream fix
  - Example command using pinned version
- Known Limitations: Renamed & clarified "Environment-Specific Blocker: Spec Kit CLI Encoding (Windows Only)" with updated instructions using manual init syntax

### Learnings

- **Doc truth requirement**: Getting-started docs must be tested against actual runtime behavior (integration test stall confirmed the issue).
- **Blocker documentation**: When upstream dependencies have known issues, document them tier-1 in prerequisites, not buried in Known Limitations. Users need to know before they start.
- **Actionable paths**: For each blocker, provide the verification command + the workaround (downgrade, retry location, upstream issue tracker).
- **Greenfield non-interactive**: Even "empty" repos (git-only) prompt for confirmation without `-Force`. This is unintuitive but necessary for correct behavior.

### Files Modified

- `docs/getting-started.md` (6 edits across greenfield, verification, notes, known limitations sections)

### No Runtime Code Changes

No changes to `scripts/specrew-init.ps1` or other runtime code. All changes are documentation only, ensuring truthful guidance without behavior modification.

## 2026-05-04 - Team Command Flag Syntax Fix

**Context**: Revision 3 of FR-013 team management implementation. Previous revisions by La Forge and Data were rejected due to interface contract mismatch.

**Problem**: Docs/spec specified `--role` and `--charter` (Unix-style), but implementation only accepted `-Role` and `-Charter` (PowerShell-style).

**Solution**:

- Added argument preprocessing layer in `specrew-team.ps1` using `System.Management.Automation.InvocationInfo.UnboundArguments`
- Script now accepts both Unix-style (`--role`, `--charter`) and PowerShell-style (`-Role`, `-Charter`) flags
- Updated all usage messages to reflect documented Unix-style syntax
- Updated integration tests to use documented syntax

**Key Learning**: When building cross-platform or convention-breaking interfaces in PowerShell:

1. Document the user-facing interface first (what users should type)
2. Implement argument translation if the documented interface differs from PowerShell conventions
3. Use `System.Management.Automation.InvocationInfo.UnboundArguments` to detect and process unbound arguments
4. Re-invoke with translated arguments to maintain clean parameter binding
5. Preserve backward compatibility when practical (both syntaxes work)

**Validation**: All 8 integration tests pass. Both flag syntaxes work identically.

**Outcome**: Interface contract now truthful. Third-time implementation accepted.
