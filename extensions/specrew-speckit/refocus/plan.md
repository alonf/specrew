---
scope: boundary.plan
sources:
  - docs/methodology/lifecycle-discipline.md
  - extensions/specrew-speckit/squad-templates/coordinator/specrew-governance.md
reviewed_at: 2026-06-07
---
## Plan-stage discipline

1. **The design decision is consumed, never re-decided.** For substantive features the design-analysis stop already produced a human verdict (`approved for plan with Option <X>`) and the pre-plan gate must PASS before plan.md is authored. The plan realizes the chosen option; re-opening it is drift.
2. **FR-to-test mapping is the plan's spine.** Every FR group names its test vehicle and the SC evidence it produces — review-signoff will hold implementation to this table.
3. **Wave B artifacts ship WITH the plan.** data-model.md, quickstart.md, contracts/<feature>.md, review-diagrams.md must exist with substantive content before /speckit.tasks — they are what the human reviews before code exists.
4. **Capacity arithmetic is real arithmetic.** Per-task SP must SUM to the declared capacity; declared capacity must fit the iteration cap; the Effort Model snapshot must match `.specrew/iteration-config.yml`. Structural presence is not arithmetic truth (Shape 9).
5. **Embed the quality profile.** The resolved quality profile, lenses, and risk dimensions are plan input — including honest overrides where the resolver's auto-detection misses a dimension the feature actually has.
6. **Scaffold/template first, author second.** Canonical artifacts (design-analysis, gates, iteration plans) have validator-enforced schemas and shipped templates — author INTO the scaffold, never freehand (3 gate-conformance rounds taught this).
7. **Stop at the boundary.** plan → tasks is human-judgment-required. Commit, sync, packet, wait.

Known traps: plans that quietly re-litigate the design option; declared-vs-summed capacity mismatch; Wave B authored as placeholders; quality profile pasted without feature-specific reconciliation.

Deep sources:

- {{project_root}}/docs/methodology/lifecycle-discipline.md
