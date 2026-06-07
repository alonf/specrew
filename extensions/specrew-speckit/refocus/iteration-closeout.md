---
scope: boundary.iteration-closeout
sources:
  - docs/methodology/lifecycle-discipline.md
  - extensions/specrew-speckit/squad-templates/coordinator/specrew-governance.md
reviewed_at: 2026-06-07
---
## Iteration-closeout-stage discipline

1. **State truth across ALL artifacts.** state.md (`Iteration Status: complete`, Current Phase consistent with prose), the iteration plan (every task in a terminal status; Capacity arithmetic = sum of Actuals), and the dashboards must agree with each other AND with git history. Cross-artifact contradictions are the empirically dominant closeout failure.
2. **No unaccounted tasks.** Every task is done, or explicitly deferred/blocked with a recorded human decision — never silently dropped.
3. **Capacity arithmetic, again.** Declared consumed/cap must equal the summed Actuals (Shape 9 was caught twice in one day in this repo — structural review missed it both times; re-compute, don't re-read).
4. **The validator runs on the committed tree.** `validate-governance.ps1` passes (or every finding has a recorded disposition) on what is COMMITTED, not on the working copy.
5. **Closing produces artifacts.** Boundary-sync renders `iterations/<NNN>/dashboard.md` and appends the closed-iteration index — verify they rendered (auto-render silently no-ops when a stale file exists: check, don't assume).
6. **Whole-file re-read before the packet.** Frontmatter, body prose, and internal consistency — closeout review goes one layer deeper than you think it needs to.

Known traps: `Status: complete` with prose still saying "executing"; dashboard stale from a review-time capture; deferred tasks that appear nowhere in the next iteration's input; closing with unapplied stashes or uncommitted churn unaccounted.

Deep sources:

- {{project_root}}/docs/methodology/lifecycle-discipline.md
