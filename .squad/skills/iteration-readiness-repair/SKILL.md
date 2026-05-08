---
name: "iteration-readiness-repair"
description: "Repair a missing or stubbed active iteration so implementation can continue without bypassing governance"
domain: "governance"
confidence: "high"
source: "earned"
tools:
  - name: "view"
    description: "Read feature plan, tasks, scaffold helpers, and validator rules together"
    when: "When deriving the smallest legitimate execution slice and the required artifact fields"
  - name: "powershell"
    description: "Run scaffold helpers and the governance validator"
    when: "When repairing missing iteration artifacts and proving readiness"
  - name: "apply_patch"
    description: "Replace generic scaffold stubs with feature-specific execution content"
    when: "When the helper created the directory but the plan/state still need reconciliation"
---

## Context

Use this when a feature has approved feature-level planning artifacts but no active `iterations\NNN\` directory, or when the active iteration contains only a scaffold stub and implementation cannot continue legitimately.

## Patterns

- Create the iteration directory with the existing scaffold helpers first; do not hand-roll the folder structure when Specrew already owns the contract.
- Replace the generated plan stub with the smallest dependency-respecting execution slice that fits `.specrew\iteration-config.yml` capacity instead of copying an oversized feature task list blindly.
- If setup tasks are already complete at the feature task-list level, carry them into the iteration plan/state explicitly so execution history remains truthful.
- Record the human's actual implementation approval text in the iteration plan and move the plan status from `planning` to `executing` only for the approved slice.
- After editing `plan.md`, re-sync `state.md` so `Last Completed Task`, `Tasks Remaining`, and execution summary match the authoritative task table.
- Validate the repaired iteration directly with `validate-governance.ps1 -IterationPath ...`; if repo-wide validation still fails elsewhere, report that as an unrelated blocker rather than pretending the repaired iteration failed.

## Examples

- Feature plan totals 38 points but iteration capacity is 20. Repair by creating `iterations\001\`, plan only the first 20-point dependency slice, defer the rest explicitly, and validate the specific iteration path.
- A scaffolded `state.md` says execution has not started, but the repaired plan marks setup tasks complete. Update `state.md` to name the last completed task and remaining queue before resuming work.

## Anti-Patterns

- Marking a stub plan `executing` without a real task table, explicit scope split, or recorded approval evidence.
- Treating repo-wide validator failures in unrelated iterations as proof that the repaired feature iteration is still blocked.
- Leaving deferred in-scope work implicit instead of naming the carry-forward tasks and target iteration.
