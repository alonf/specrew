---
name: "iteration-execution-truth-review"
description: "Review whether an executing iteration still tells the truth after partial task acceptance."
domain: "review"
confidence: "high"
source: "earned"
tools:
  - name: "view"
    description: "Read the live iteration artifacts, contract, and reviewer decisions."
    when: "When you need to compare accepted work against what plan.md/state.md/drift-log.md still claim."
  - name: "powershell"
    description: "Run governance validation and any task-level checks tied to the accepted slice."
    when: "When you must separate validator health from artifact-truth drift."
---

## Context

Use this when an iteration has already entered `executing` and some task slice has been implemented or accepted, but the authoritative lifecycle artifacts may still be lagging behind that reality.

## Patterns

- Treat `plan.md`, `state.md`, and `drift-log.md` as the authority over execution truth; decision notes only prove that a status change may be required.
- If a task slice is accepted, reject artifacts that still leave that task merely `in-progress`.
- Check `plan.md` for task status, agent, actual effort, and verdict evidence once work is accepted.
- Check `state.md` for `Last Completed Task`, `Tasks Remaining`, and `In Progress` movement after accepted work.
- Check `drift-log.md` for stale resolutions such as "deferred to acceptance cycle" after the acceptance already happened.
- When an accepted slice closes only part of the iteration, keep the iteration in `executing` but still advance capacity-used math and the last-completed pointer to the accepted task.
- A passing governance validator does not by itself clear artifact-truth drift; validator health and lifecycle truth are separate review questions.

## Examples

- `decisions.md` records `T-205/T-206` as PASS, but Iteration 002 still shows both tasks `in-progress` with `Last Completed Task: (none)`. Verdict: NEEDS-WORK on lifecycle artifacts even if governance validation passes.
- CI parity is fixed in the workflow, but execution artifacts still lag accepted work. Verdict: accept CI correction, reject iteration-truth correction.

## Anti-Patterns

- Treating an `executing` status flip as sufficient once accepted tasks exist.
- Granting PASS because the validator passes while the artifacts still under-report completed work.
- Reopening unrelated implementation code when the defect is confined to lifecycle artifact truth.
