---
agent: speckit.analyze
---

# /speckit.analyze — cross-artifact consistency review (before-implement)

`/speckit.analyze` is a lifecycle-adjacent Spec Kit command that belongs at the **before-implement** boundary, only after `/speckit.tasks` has produced a complete `tasks.md`.

- **Lifecycle placement**: before-implement, after `/speckit.tasks`.
- **Prerequisites**: `spec.md`, `plan.md`, and a complete `tasks.md`.
- **Purpose**: additive cross-artifact consistency and quality analysis across spec, plan, and tasks. It complements Specrew governance validation and does not replace it.
- If you reach it before `tasks.md` is complete, return at the before-implement boundary after `/speckit.tasks` completes.
