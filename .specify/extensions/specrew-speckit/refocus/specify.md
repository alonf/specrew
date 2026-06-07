---
scope: boundary.specify
sources:
  - docs/methodology/lifecycle-discipline.md
  - extensions/specrew-speckit/squad-templates/coordinator/specrew-governance.md
reviewed_at: 2026-06-07
---
## Specify-stage discipline

1. **Run the lens workshop before the spec.** Invoke the `specrew-design-workshop` skill at intake; work the applicable design lenses one at a time, with the human, and re-invoke the skill per lens. The spec must be lens-informed, not lens-decorated.
2. **Render before you ask.** Any agenda, diagram, component map, or option set you ask the human to confirm must be VISIBLE in the same message — never a count ("8 lenses"), never a file reference standing in for content.
3. **Honest confirmation provenance.** Record `human-confirmed` ONLY for lenses the human actually saw and answered; `human-delegated` / `human-skipped` when they said so. Intake is not "specific enough" until every selected lens has a real answer — never stop early and backfill.
4. **Spec quality bar.** FRs are testable and unambiguous; SCs are measurable with named evidence forms; scope line is explicit with named dispositions for every OUT item; edge cases enumerated; no implementation details the workshop did not bind.
5. **Capture the workshop.** `lens-applicability.json` (exact gate shape: `workshop` → lens-id → {agenda, decision, depth, moved_on, confirmation}) + per-lens keeper records under `workshop/`. An agreement that lives only in chat scrollback is lost.
6. **Stop at the boundary.** Commit `boundary(specify): write spec.md`, sync state, and at the verdict stop invoke the `specrew-gate-stop` skill (picker disabled, packet rendered as prose) — wait for the human verdict before clarify work.

Known traps: menu-before-render (the AskUserQuestion tool-gravity — at the specify **verdict** stop the `specrew-gate-stop` skill disables the picker; workshop lens questions keep it); fabricated lens agreement; a spec that transcribes the request instead of the decisions; missing checklists/requirements.md.

Deep sources:

- {{project_root}}/docs/methodology/lifecycle-discipline.md
- {{project_root}}/.claude/skills/specrew-design-workshop/SKILL.md
