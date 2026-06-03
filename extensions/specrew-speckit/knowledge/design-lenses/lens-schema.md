# Design Lens Schema

Each lens file is markdown with stable headings. The headings are intentionally
simple so an agent or script can parse them without a fragile document model.

## Required Fields

- `Lens ID`: stable kebab-case identifier matching `index.yml`.
- `Purpose`: what design risk this lens prevents.
- `Applicability Signals`: clues that the lens should be active.
- `Design Decision Points`: decisions that must be surfaced as alternatives.
- `Question Bank`: concrete questions the Crew may ask or answer from context.
- `Alternative Dimensions`: axes that distinguish simplest, reasonable, and
  by-the-book options.
- `Plan Obligations`: what the chosen plan must record if the lens applies.
- `Validation Signals`: evidence that implementation/review should seek.
- `Source Notes`: source anchors used to create the lens.

## Guidance

- Questions should be short and decision-bearing.
- The lens should not force a solution. It should force explicit comparison.
- A lens can be marked applicable even when the answer is "no database",
  "no UI", or "no CI impact" if that negative decision affects the plan.
- Add specialized lenses instead of overloading a broad one when the question
  bank becomes too large to scan.
