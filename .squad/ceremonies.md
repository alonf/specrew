# Ceremonies

> Specrew operates in four phases: planning -> execution -> review/demo -> retrospective.

## Planning Ceremony

| Field | Value |
|-------|-------|
| **Trigger** | auto |
| **When** | before |
| **Condition** | start of a new iteration, newly approved spec work, or tracked change to requirements |
| **Facilitator** | Data |
| **Participants** | Picard, Data, La Forge, Worf, Alon |
| **Time budget** | focused |
| **Enabled** | ✅ yes |

**Agenda:**

1. Read the authoritative requirements and acceptance criteria
2. Map tasks back to source requirements
3. Assign owners and capture effort estimates
4. Flag drift risks before execution begins

---

## Review and Demo Ceremony

| Field | Value |
|-------|-------|
| **Trigger** | auto |
| **When** | after |
| **Condition** | a task batch completes or an increment is ready for verdict/demo |
| **Facilitator** | Worf |
| **Participants** | Picard, La Forge, Worf, Alon |
| **Time budget** | focused |
| **Enabled** | ✅ yes |

**Agenda:**

1. Compare each delivered task to its source requirement
2. Produce a verdict: pass, needs-work, or blocked
3. Demo the increment against the requirement narrative
4. Capture drift findings for the retrospective

---

## Retrospective Ceremony

| Field | Value |
|-------|-------|
| **Trigger** | auto |
| **When** | after |
| **Condition** | review/demo completes, reviewer rejection occurs, or drift is detected |
| **Facilitator** | Troi |
| **Participants** | all-involved |
| **Time budget** | focused |
| **Enabled** | ✅ yes |

**Agenda:**

1. What happened? (facts only)
2. Measure estimation accuracy, process adherence, and drift events
3. Identify what to keep, change, or tighten in the next iteration
4. Record improvement actions for the next planning ceremony

<!-- >>> specrew-managed ceremonies >>> -->
# Specrew: Planning

**Type**: Ceremony  
**Schema**: v1  
**Status**: Active governance template

## Purpose

Turn approved scope into an executable iteration plan without breaking spec authority, traceability, or lifecycle rules.

## Trigger

- Start of an iteration
- Re-planning after an abandonment or review-driven re-entry to execution
- Any time scope changes require a new approved plan before execution continues

## Participants

| Role | Responsibility |
| ---- | -------------- |
| Planner | Leads decomposition, estimates effort, and drafts the task table |
| Spec Steward | Runs the spec-authority and traceability gates |
| Implementer | Flags execution risks, hidden dependencies, and sequencing issues |
| Project Owner (optional) | Approves plan exceptions, overcommit, and architectural trade-offs when a non-baseline approver is needed |

## Required Inputs

| Input | Source | Description |
| ----- | ------ | ----------- |
| Spec requirements | `specs/NNN-feature/spec.md` | Authoritative FRs, user stories, and constraints in scope |
| Iteration config | `.specrew/iteration-config.yml` | Capacity, effort unit, and overcommit threshold |
| Role assignments | `.specrew/role-assignments.yml` | Available owners for execution and review |
| Prior retro/review | Previous iteration artifacts | Calibration, carryover work, and process corrections |
| Pre-planning spike results | Research notes / decisions | Required architecture-risk answers before task assignment |

## Ceremony Method

### 1. Pre-planning gate

Before drafting tasks, confirm:

1. required architecture-risk spikes are complete
2. the scope is named explicitly by requirement ID
3. any carryover or deferred work is still valid against the current spec

If one of these is false, do not produce a plan.

### 2. Requirement slicing

For each in-scope requirement:

1. identify deliverables
2. identify enabling work that is still traceable to that requirement
3. note dependencies and ordering constraints
4. flag any work that belongs in a different iteration instead of sneaking it in

### 3. Task decomposition and ownership

Build a single `## Tasks` table in `plan.md`.

Initialize the artifact first when no plan exists yet:

```powershell
pwsh -File .\.specify\extensions\specrew-speckit\scripts\scaffold-iteration-plan.ps1 `
  -SpecPath .\specs\NNN-feature\spec.md `
  -IterationNumber NNN `
  -RequirementScope FR-001,FR-002
```

The scaffold creates a contract-aligned planning stub with:

- metadata prefilled from the spec and iteration config
- a scope summary table derived from the selected requirements
- an empty task table ready for decomposition
- an effort-model snapshot copied from `.specrew/iteration-config.yml`
- a phase-baseline section and traceability summary to complete during planning

Every task must include:

- task ID
- title
- requirement reference
- story reference
- effort
- owner
- initial status

Owners are role names, not agent nicknames.

### 4. Estimation and phase variance setup

Estimate effort twice:

1. **task level** for the task table
2. **phase level** for planning, discovery/spikes, implementation, review, and expected rework

This creates the baseline the retrospective will compare against.

### 5. Hard governance gates

The planning ceremony does not finish until all checks pass:

1. **Spec authority**: every task maps to an in-scope requirement
2. **Traceability**: no orphan tasks, no uncovered in-scope requirements
3. **Capacity**: total effort is within threshold or explicitly approved
4. **Lifecycle readiness**: the plan can transition to execution without missing required artifacts

Use `specrew-capacity-planning` to pressure-test estimates and `specrew-traceability-check` before approval.
If the plan is over capacity, record the explicit defer recommendation against the lowest-priority requirement slices before any approval decision is made.

### 6. Plan output

Write or update `iterations/NNN/plan.md` with:

- metadata (`Schema`, `Status`, `Capacity`, `Started`, `Completed`)
- the task table
- an `## Effort Model` section that snapshots the current iteration-config values
- a `## Phase Baseline` section for planning, discovery/spikes, implementation, review, and expected rework
- traceability summary
- known risks, deferred work, and gate outcomes

Set `Status: planning` until approval is recorded.

If you started from the scaffold helper, replace the stub sections with final planning content before approval.

## Outputs

| Output | Destination | Description |
| ------ | ----------- | ----------- |
| Iteration plan | `iterations/NNN/plan.md` | Approved task table and governance metadata |
| Traceability evidence | Embedded in `plan.md` | Requirement-to-task coverage and exceptions |
| Capacity baseline | Embedded in `plan.md` | Task and phase-level estimates for retro comparison |
| Sequencing notes | Embedded in `plan.md` | Architecture risks, dependencies, and approved deferrals |

## Escalation

| Condition | Escalation Path |
| --------- | --------------- |
| Requirement ambiguity | Route to the Spec Steward for clarification or a tracked change |
| Capacity breach | Route to the project owner for deferral or overcommit approval |
| Hidden architecture risk | Pause planning and run a pre-planning spike |
| Missing traceability | Revise the plan before any task assignment |

## Exit Condition

Planning ends only when the plan is approved and safe to transition from `planning` to `executing`.

---

# Specrew: Review/Demo

**Type**: Ceremony  
**Schema**: v1  
**Status**: Active governance template

## Purpose

Evaluate delivered work against the authoritative requirement, assign per-task verdicts, and decide whether the iteration can advance to retrospective or must re-enter execution.

## Trigger

- End of execution when all tasks are terminal
- Early closure attempt when work must be reviewed before abandonment or replanning

## Participants

| Role | Responsibility |
| ---- | -------------- |
| Reviewer | Leads the ceremony and owns verdicts |
| Spec Steward | Verifies requirement citations and drift handling |
| Implementer | Presents completed work and evidence |
| Project Owner (optional) | Resolves policy or architecture disputes when an explicit approver is needed |

## Required Inputs

| Input | Source | Description |
| ----- | ------ | ----------- |
| Iteration plan | `iterations/NNN/plan.md` | Final task list, owners, estimates, and task states |
| Iteration state | `iterations/NNN/state.md` | Resume-safe proof that execution is current and terminal |
| Drift log | `iterations/NNN/drift-log.md` | Required even when zero drift was detected |
| Delivered artifacts | Repo outputs | Code, docs, configs, scripts, and evidence of behavior |
| Authoritative spec | `specs/NNN-feature/spec.md` | Requirement text used for verdicts |

## Ceremony Method

### 1. Review entry gate

Do not start task verdicting until:

1. every task in `plan.md` is terminal (`done`, `needs-rework`, `deferred`, or `blocked`)
2. `state.md` exists and reflects the latest execution checkpoint
3. `drift-log.md` exists

If any check fails, route the iteration back to execution.

### 2. Drift reconciliation

Use the runtime drift path that matches platform capability:

- If per-task drift checks already ran, review the recorded events
- If they did not, invoke `specrew-drift-check` now for each completed task as the batch fallback

Every drift decision must cite the specific requirement that was violated, omitted, or exceeded.

### 3. Per-task verdicts

For each task in the plan:

1. compare the delivered output to the requirement text
2. confirm drift was handled correctly
3. assign one verdict:
   - `pass`
   - `needs-work`
   - `blocked`

Verdicts belong in `review.md`, not just meeting notes.

### 4. Live continuous co-review evidence

When the iteration touched code, runtime scripts, prompts, workflows, or executable governance, run live continuous co-review before assigning an accepted iteration verdict:

```powershell
specrew review --live --baseline-ref <committed-baseline> `
  --project-path . `
  --checkpoint-id review-signoff-NNN `
  --run-id review-signoff-NNN `
  --design-context-ref specs\NNN-feature\spec.md
```

Use a baseline ref that represents the committed state before the reviewed implementation slice. The live run must persist `.specrew\review\inline\<run-id>\gate-verdict.json` and `.specrew\review\inline\<run-id>\review-run.json`; cite those files in `review.md` and `reviewer-index.md`.

If the live reviewer reports blocking findings, route the affected tasks back to execution. If the reviewer infrastructure is unavailable or unsafe, record the failure as review evidence and stop for human defer/repair direction. Do not replace the missing live run with hand-authored acceptance prose.

### 5. Iteration verdict

Assign the iteration one overall verdict:

- `accepted` when work is review-complete and can advance to retro
- `needs-rework` when at least one task must re-enter execution
- `blocked` when an external blocker prevents closure

If the verdict is `needs-rework`, name the returning tasks and route them back to execution before retro starts.

### 6. Output artifact

Write `iterations/NNN/review.md` with:

- reviewed date
- overall verdict
- populated `## Task Verdicts` table
- notes on drift, blockers, and next-step routing

If `review.md` does not exist yet, initialize it from the installed Specrew helper first:

```powershell
pwsh -File .\.specify\extensions\specrew-speckit\scripts\scaffold-review-artifact.ps1 `
  -IterationDirectory .\specs\NNN-feature\iterations\NNN `
  -OverallVerdict needs-rework `
  -DefaultTaskVerdict needs-work
```

That scaffold gives the Reviewer:

- a complete `## Task Verdicts` table seeded from `plan.md`
- a contract-valid overall verdict field
- note prompts that call out blocked, deferred, and batch-drift-review cases

Before leaving the ceremony with an accepted verdict, persist the `review-signoff` boundary:

```powershell
pwsh -File .\.specify\extensions\specrew-speckit\scripts\sync-boundary-state.ps1 `
  -ProjectPath . `
  -BoundaryType review-signoff `
  -FeatureRef NNN-feature `
  -IterationNumber NNN
```

Run `specrew-traceability-check` if verdict discussion reveals scope ambiguity or orphan work.

## Outputs

| Output | Destination | Description |
| ------ | ----------- | ----------- |
| Review artifact | `iterations/NNN/review.md` | Task verdicts and overall review verdict |
| Updated drift log | `iterations/NNN/drift-log.md` | Batch fallback drift events, if needed |
| Rework routing | Back to `plan.md` / execution | Explicit list of tasks that re-enter execution |

## Escalation

| Condition | Escalation Path |
| --------- | --------------- |
| Requirement interpretation dispute | The Spec Steward arbitrates and the project owner breaks ties |
| Critical drift | Route to the Spec Steward and record a formal drift entry |
| Blocked work | Route to the project owner for sequencing or abandonment decision |

## Exit Condition

Review/demo ends only when `review.md` exists and the next state is explicit:

- back to execution
- forward to retrospective
- or abandoned with recorded reason
<!-- <<< specrew-managed ceremonies <<< -->
