# Architecture Core Lens

## Lens ID

`architecture-core`

## Purpose

Prevent silent structural decisions. Architecture is where costly-to-change
choices about structure, boundaries, constraints, and volatility become visible
before planning locks one path.

## Applicability Signals

- The feature introduces a new subsystem, lifecycle stage, command surface, or
  persistent artifact.
- The implementation can be shaped as inline logic, helper/module, service,
  workflow, extension point, or generated data.
- A decision would be expensive to reverse after code lands.
- Multiple stakeholders care about different qualities: users, operators,
  developers, security, UI/UX, product, or management.

## Design Decision Points

- What are the major building blocks and their responsibilities?
- Which areas are volatile and should be isolated behind data, interfaces, or
  extension points?
- Which constraints are binding, and which are preferences?
- What is deliberately out of scope for this iteration?
- Which option best balances simplicity, reversibility, and future cost?

## Question Bank

- What structural decision will be hardest to change later?
- Which part should be data-driven rather than prompt-driven or code-driven?
- What stakeholders are affected by this decision?
- Which assumptions should be recorded as constraints?
- What would make the recommended option flip to another option?
- What needs a diagram because prose alone hides the coupling?
- What is the smallest slice that still proves the architecture?

## Alternative Dimensions

- **Simplest**: keep logic local and document the decision; defer extension.
- **Reasonable**: introduce a helper, artifact, or catalog where volatility is
  already visible.
- **By the book**: create explicit boundaries, schemas, validators, diagrams,
  and migration rules for long-lived extensibility.

## Plan Obligations

- Name the chosen structure and rejected alternatives.
- Record reversibility cost and deferred architectural debt.
- Tie major building blocks to FRs, SCs, tests, and validation evidence.
- Include at least one diagram for non-trivial component or flow boundaries.

## Validation Signals

- The implementation matches the chosen option, not just the desired outcome.
- The review can point to the decision record and explain why the design exists.
- Deferred alternatives have named follow-up scope, not vague "future work".

## Source Notes

- Book Chapters 1 and 3.
- Course Modules 1 and 3.
