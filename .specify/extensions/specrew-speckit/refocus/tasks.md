---
scope: boundary.tasks
sources:
  - docs/methodology/lifecycle-discipline.md
  - extensions/specrew-speckit/squad-templates/coordinator/specrew-governance.md
reviewed_at: 2026-06-07
---
## Tasks-stage discipline

1. **Bidirectional traceability or it doesn't pass.** Every task maps to ≥1 FR/SC AND every FR and SC has ≥1 covering task. Run the check both directions and write the result into tasks.md — orphans in either direction block.
2. **Tasks are deliverable-shaped.** Each row: concrete description, explicit traces, effort, owner. A task whose done-ness can't be verified is a wish, not a task.
3. **Sequencing is explicit.** Dependencies between tasks are named; parallel-safe work is only parallel when ownership boundaries (Owner File Globs) make conflicts impossible.
4. **Capacity honesty.** Iteration totals respect the cap; overcommit names explicit deferral candidates from the lowest-priority requirement slices first.
5. **After-tasks is readiness, not authorization.** The traceability check emits findings; it does NOT authorize skipping the human verdict. tasks → before-implement requires the explicit implementation go-ahead with a readiness summary (feature, clarify outcome, quality focus, team, hardening-gate status).

Known traps: SC rows with no covering task; "misc/polish" tasks traceable to nothing; capacity that ignores test effort; treating after-tasks output as permission to start coding.

Deep sources:

- {{project_root}}/docs/methodology/lifecycle-discipline.md
