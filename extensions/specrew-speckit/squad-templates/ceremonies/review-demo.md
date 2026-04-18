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
| Chief Architect | Resolves policy or architecture disputes when needed |

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

### 4. Iteration verdict

Assign the iteration one overall verdict:

- `accepted` when work is review-complete and can advance to retro
- `needs-rework` when at least one task must re-enter execution
- `blocked` when an external blocker prevents closure

If the verdict is `needs-rework`, name the returning tasks and route them back to execution before retro starts.

### 5. Output artifact

Write `iterations/NNN/review.md` with:

- reviewed date
- overall verdict
- populated `## Task Verdicts` table
- notes on drift, blockers, and next-step routing

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
| Requirement interpretation dispute | Picard arbitrates, Alon breaks ties |
| Critical drift | Route to Picard and record formal drift entry |
| Blocked work | Route to Alon for sequencing or abandonment decision |

## Exit Condition

Review/demo ends only when `review.md` exists and the next state is explicit:

- back to execution
- forward to retrospective
- or abandoned with recorded reason
