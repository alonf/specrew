---
scope: boundary.clarify
sources:
  - docs/methodology/lifecycle-discipline.md
  - extensions/specrew-speckit/squad-templates/coordinator/specrew-governance.md
reviewed_at: 2026-06-07
---
## Clarify-stage discipline

1. **Ask only what matters.** 2-3 questions max per round, each materially affecting scope, behavior, governance, or UX. Answer questions yourself when repo context or reasonable defaults resolve them — and WRITE those resolutions into the spec.
2. **Clarifications land in the spec.** Append a `## Clarifications` section with a dated session block; every answer becomes spec text, not chat memory.
3. **Skip only with recorded rationale.** Clarify may be skipped when the spec is demonstrably complete for planning (e.g., an interactive workshop already resolved the open questions) — the skip rationale is written into the spec and the human approved it at the specify verdict.
4. **No new scope through the side door.** A clarify answer that changes scope is a spec change: update FRs/SCs/scope line, not just the Clarifications block.
5. **Stop at the boundary.** The clarify → plan transition is human-judgment-required: planning converts the spec into architecture and task direction, so spec mistakes become downstream work. Emit the packet; wait.

Known traps: re-asking what the repo already answers; burying scope changes in clarify prose; advancing to plan because clarify "found nothing" without the human's verdict.

Deep sources:

- {{project_root}}/docs/methodology/lifecycle-discipline.md
