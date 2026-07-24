---
scope: boundary.implement
sources:
  - docs/methodology/lifecycle-discipline.md
  - extensions/specrew-speckit/squad-templates/coordinator/specrew-governance.md
reviewed_at: 2026-06-07
---
## Implement-stage discipline

1. **Tests ride with code.** Every task's tests land in the same commit as its implementation — never deferred to a "testing task" at the end. Run them before claiming the task done; report actual results ("38 asserts green"), not intentions.
2. **Commit per task, push per discipline.** `boundary(implement): T0NN <what>` — focused commits keep the audit trail and the lint/markdown gates functional. Batch-committing at iteration end silently bypasses every commit-scoped guardrail.
3. **State truth after every task.** Update the iteration plan row (status, Actual) and state.md (Last Completed Task, Tasks Remaining) as you go — resume safety depends on disk truth, not your memory.
4. **Drift is logged, not absorbed.** Any divergence from spec/plan/tasks (renamed file, changed format, added dependency, descoped detail) gets a drift-log.md entry with the requirement citation and the reconciliation path.
5. **Scope creep goes to the ledger, not the diff.** Mid-implementation ideas become deferred follow-ups or human questions — never silent additions.
6. **One progress sentence per major task.** Narrate outcomes ("T003 done — catalog + schema validation green"), not intentions ("let me now...").
<!-- specrew-applicability: project-detected; apply only when repository evidence selects PowerShell implementation files -->
7. **Selected PowerShell implementation discipline.** When the project contains or selects `.ps1` implementation, avoid Bash syntax in those files and use literal-path APIs. Apply PowerShell-specific StrictMode, process-argument, JSON-object, and process-working-directory cautions only inside that detected surface; otherwise follow the project's own stack rules.
8. **Co-review fires at CHECKPOINTS, not only at the end (host-neutral).** The continuous co-reviewer fires on the Stop hook — but a host that runs many tasks without yielding never checkpoints, so the review collapses to a single late pass (or none, as on a straight-through host). So ACTIVELY fire it: after each ~5 SP of COMPLETED, committed tasks, run `specrew review --live` (the co-review of the committed state, in a read-only worktree). This is a CO-REVIEW run, NOT a human gate — do NOT stop for human approval at the checkpoint; commit and continue UNLESS it returns a BLOCKING finding (surface that to the human and pause). If it exits non-zero reporting no authorized reviewer host, STOP and surface the remediation (`specrew review --host <host> --authorization-ref <ref>`) — NEVER substitute your own review (a host-internal reviewer, a manual read) for the co-review; an improvised review is not co-review evidence.

Known traps: tests written but never run; state.md frozen at T001 while code is at T009; "while I'm here" refactors with no task; tool-contract failures papered over instead of stopped on.

Deep sources:

- {{project_root}}/docs/methodology/lifecycle-discipline.md
