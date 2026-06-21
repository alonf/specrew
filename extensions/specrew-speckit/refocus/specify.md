---
scope: boundary.specify
sources:
  - docs/methodology/lifecycle-discipline.md
  - extensions/specrew-speckit/squad-templates/coordinator/specrew-governance.md
reviewed_at: 2026-06-08
---
## Specify-stage discipline

1. **The design workshop IS the intake — run it FIRST, before anything.** Invoke the `specrew-design-workshop` skill as your first action on a new feature — before any clarification questions, before `speckit-specify`, before writing anything. It is the discovery/analysis/design step: its product-domain lens gathers the request WITH the human, so do NOT pre-ground with your own questions (that duplicates the workshop and asks the human the same things twice). Work the applicable lenses one at a time, with the human, re-invoking the skill per lens. The spec is written only AFTER the workshop — lens-informed, not lens-decorated.
2. **Render before you ask.** Any agenda, diagram, component map, or option set you ask the human to confirm must be VISIBLE in the same message — never a count ("8 lenses"), never a file reference standing in for content.
3. **Honest confirmation provenance.** Record `human-confirmed` ONLY for a lens question the human actually saw and answered, with `confirmation_scope: lens-question`; record `human-delegated` with `confirmation_scope: explicit-delegation`, and `human-skipped` with `confirmation_scope: explicit-skip`. Lens approval is not workshop-question approval. Intake is not "specific enough" until every selected lens has a real answer — never stop early and backfill.
4. **Spec quality bar.** FRs are testable and unambiguous; SCs are measurable with named evidence forms; scope line is explicit with named dispositions for every OUT item; edge cases enumerated; no implementation details the workshop did not bind.
5. **Capture the workshop.** `lens-applicability.json` (exact gate shape: `workshop` → lens-id → {agenda, decision, depth, moved_on, confirmation, confirmation_scope}) + per-lens keeper records under `workshop/`. An agreement that lives only in chat scrollback is lost.
6. **Stop at the boundary.** Commit `boundary(specify): write spec.md`, sync state, and render the verdict packet through your host's approved interaction path for a verdict stop (its dedicated boundary-stop surface if it has one, otherwise render the packet directly) — as a full message, never collapsed into a picker/menu — then emit the verdict marker `<!-- SPECREW-VERDICT-BOUNDARY: intake -> specify -->` as the LAST line so the specify verdict is captured. `intake` is the marker-only name for the pre-specify side of the first gate; wait for the human verdict before clarify work.

Known traps: menu-before-render (a picker/menu collapses the verdict packet into its short fields — render the full packet as a message at a **verdict** stop, never a menu; workshop lens questions keep their normal path); fabricated lens agreement; a spec that transcribes the request instead of the decisions; missing checklists/requirements.md.

Deep sources:

- {{project_root}}/docs/methodology/lifecycle-discipline.md
- {{project_root}}/.claude/skills/specrew-design-workshop/SKILL.md
