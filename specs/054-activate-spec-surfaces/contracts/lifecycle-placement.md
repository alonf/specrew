# Contract: Lifecycle Placement

## Command placement matrix

| Command | Approved placement | Required prerequisites | Required user-facing explanation | Forbidden implication |
| --- | --- | --- | --- | --- |
| `/speckit.checklist` | `before-plan` | A substantive spec ready for planning review | It improves requirement quality (clarity, completeness, consistency, edge cases) before planning begins | That it validates implementation correctness or is mandatory for every tiny slice |
| `/speckit.analyze` | `before-implement` | `spec.md`, `plan.md`, and a complete `tasks.md` produced by `/speckit.tasks` | It performs additive cross-artifact consistency and quality analysis across spec/plan/tasks | That it replaces Specrew governance checks or runs meaningfully before tasks exist |
| `/speckit.taskstoissues` | deferred in this slice | Explicit later re-scope only | It exists but is not part of the default lifecycle for Feature 054 | That it is active, expected, or silently available by default |

## Lifecycle rules

1. `/speckit.checklist` belongs before-plan and is in scope for this feature.
2. `/speckit.analyze` belongs after `/speckit.tasks` and before implementation; it is in scope for this feature.
3. `/speckit.taskstoissues` remains deferred by default and is not an active planning or implementation step here.
4. Discovery wording must stay consistent across docs, prompts, agents, and any lifecycle summary surface updated by this feature.
5. If a user encounters `/speckit.analyze` too early, the guidance must redirect them to the before-implement boundary rather than encouraging premature use.
