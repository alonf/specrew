---
scope: boundary.before-implement
sources:
  - docs/methodology/lifecycle-discipline.md
  - extensions/specrew-speckit/squad-templates/coordinator/specrew-governance.md
reviewed_at: 2026-06-07
---
## Before-implement-stage discipline

1. **The hardening gate is real, not ceremonial.** `quality/hardening-gate.md` carries `Overall Verdict: ready` with every concern `addressed | not-applicable | deferred-with-approval` (NEVER `tbd`) and feature-specific Expected Controls + Rationale — not scaffold placeholders. Override the quality resolver's auto-n/a when the feature actually has that dimension.
2. **The iteration plan is the execution contract.** Canonical statuses only (iteration: planning|executing|reviewing|retro|complete|abandoned; tasks: planned|in-progress|done|needs-rework|deferred|blocked). `Capacity: <consumed>/<cap> <unit>` with NO trailing prose. Task table populated with traces, effort, owner globs.
3. **Boundary authorization is checked, not assumed.** The tasks → before-implement crossing requires a recorded human verdict. "The plan was approved earlier" does not authorize implementation.
4. **Scaffold before code.** state.md, drift-log.md, quality artifacts exist before the first implement commit, so resume and audit always have anchors.
5. **After the go-ahead, run.** Once the human authorizes implementation, proceed through implement → review → retro without re-asking per phase — but every gate still preflights and every boundary still commits.

Known traps: `Status: approved` / `in_progress` (invalid enums); `tbd` concern rows; capacity lines with trailing prose; starting T001 while the gate is still blocked.

Deep sources:

- {{project_root}}/docs/methodology/lifecycle-discipline.md
