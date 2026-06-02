# Requirements And NFR Lens

## Lens ID

`requirements-nfr`

## Purpose

Turn vague needs into measurable requirements and design-driving constraints.
This lens is active when qualities like performance, usability, security,
availability, maintainability, or compliance should shape the architecture.

## Applicability Signals

- The request contains broad quality words such as fast, secure, scalable,
  reliable, usable, compatible, auditable, or cheap.
- The feature changes workflow, user experience, public behavior, release
  policy, or operational expectations.
- The scope has hidden stakeholders or disfavored users.
- Requirements are implied by examples, screenshots, prototypes, or existing
  system behavior.

## Design Decision Points

- Which NFRs are design drivers for this slice?
- Which constraints are mandatory rather than preferences?
- Which requirements need a measurable threshold?
- Which requirements are unknown enough to require clarification?
- Which acceptance criteria prove the quality, not only the happy path?

## Question Bank

- Who is the user, customer, operator, and disfavored user?
- What user pain is this feature solving?
- Which NFRs are binding for this feature?
- What does success look like in measurable terms?
- What should the system refuse to do?
- What ambiguity would cause rework if left to planning?
- What prototype, sketch, example, or existing behavior should be treated as
  requirements evidence?

## Alternative Dimensions

- **Simplest**: capture only the NFRs directly required by the slice.
- **Reasonable**: activate a focused quality profile with measurable criteria.
- **By the book**: run a broad requirements workshop style pass, including
  stakeholders, constraints, NFRs, risks, and validation strategy.

## Plan Obligations

- List design-driving NFRs and non-driving NFRs separately.
- Convert vague quality statements into measurable SCs where practical.
- Identify acceptance tests, manual smoke tests, or evidence artifacts needed
  for the selected quality goals.

## Validation Signals

- Review evidence covers NFR claims with execution, inspection, or documented
  human acceptance.
- No major quality claim is accepted only because a file exists.

## Source Notes

- Book Chapter 2.
- Course Module 2.
