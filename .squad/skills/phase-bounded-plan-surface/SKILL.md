# phase-bounded-plan-surface

## Purpose

Extend a planning template for a later lifecycle phase without falsely implying that execution, evidence, or enforcement for that phase is already complete.

## When to Use

- A template needs a new section for a future quality or governance phase.
- The current task only owns planning/rendering, not the runtime or validator implementation behind it.
- Later tasks will fill in execution evidence, routing outcomes, or enforcement behavior.

## Pattern

1. Add artifact-location fields first so later work has an explicit home.
2. Render planning tables for the phase's required focus areas, but keep the cells as fill-in placeholders rather than synthesized outcomes.
3. Separate routing or activation intent from effective execution evidence.
4. Add explicit later-deferral bullets for any lifecycle behavior not yet delivered.
5. Reconcile the active iteration's plan/state/drift bookkeeping so the completed template task is recorded without claiming downstream tasks have started.

## Anti-Patterns

- Writing the template as if line-by-line review evidence already exists.
- Collapsing planning intent and runtime-effective results into one field before the execution path exists.
- Hiding deferred follow-on work inside vague task titles instead of naming it explicitly in the template.
