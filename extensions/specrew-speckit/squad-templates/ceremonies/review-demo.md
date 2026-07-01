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
