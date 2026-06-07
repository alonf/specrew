---
proposal: 170
title: New-User Crew Interaction Profile Setup Copy
status: shipped
phase: phase-2
estimated-sp: 2-3
priority-tier: 2
type: user-onboarding-small-fix
discussion: surfaced 2026-06-07 from first-run dogfooding on a new machine; maintainer found the profile setup questions hard to understand for users new to Specrew
composes-with:
  - 141  # Crew Interaction Profile / Persona Lens Separation
  - 143  # Session Start Welcome Orientation + Reset Surface
  - 145  # Structured reviewer evidence discipline
audience: new Specrew users, maintainers
---

# New-User Crew Interaction Profile Setup Copy

## Why

The first-run Crew Interaction Profile setup asks users to enter `1-10` or
`auto` for areas such as **Product Strategy**, **UX/UI Design**, **Software
Architecture**, and **AI Delivery Planning**. That is technically consistent
with Proposal 141, but it still reads like Specrew is asking the user to rate
their professional skill in each domain.

For a user new to Specrew, the real decision is not "am I a 7 at Product
Strategy?" The real decision is "how much guidance do I want Specrew to provide
when this kind of decision appears?" The current prompt makes the user infer
that model from short labels and the terms Learning/Standard/Senior.

## What

Revise the first-run setup copy so it asks behavior-centered questions:

1. Explain the scale as collaboration behavior, not user seniority.
2. Tell new users they can press Enter for recommended defaults.
3. Prompt each area with a plain-language question: "how much guidance do you
   want?"
4. Keep the canonical decision-area label visible as continuity metadata.
5. Preserve all existing profile schema keys, persona IDs, summaries, and
   runtime behavior.

## Acceptance Criteria

- **AC1**: First-run setup clearly says the profile controls how much guidance
  Specrew gives, not the user's job title or identity.
- **AC2**: The setup scale uses behavior labels: guide me, collaborate, be
  concise, and auto/recommended defaults.
- **AC3**: Each first-run prompt asks a plain-language "how much guidance do you
  want?" question for that decision area.
- **AC4**: Pressing Enter in first-run setup records `auto`.
- **AC5**: The persisted schema keys and persona IDs remain unchanged,
  including `ai_research_project_management` and
  `ai-researcher-project-manager`.
- **AC6**: Existing profile summaries and `/speckit.specify` routing behavior
  remain compatible.
- **AC7**: Tests cover the setup metadata and input normalization instead of
  relying only on manual prompt inspection.

## Out Of Scope

- Renaming the persisted `expertise.*` schema.
- Renaming internal persona lens IDs.
- Reworking all documentation and host skill surfaces globally.
- Changing the actual question-depth behavior used by `/speckit.specify`.
- Replacing Proposal 143's broader welcome/reset surface.

## Implementation Notes

Add setup-only metadata next to the existing Crew Interaction Profile area
metadata. The canonical display labels should remain unchanged for summaries,
session context, legacy fixtures, and stable profile vocabulary. The first-run
prompt can use a more concrete `SetupLabel` and `SetupQuestion` while showing
`Profile area: <DisplayLabel>` for continuity.

Add a small input-normalization helper so blank input, whitespace, and
case-insensitive `auto` are handled consistently and are directly testable.

## Effort

Estimated 2-3 SP:

| Work item | Estimate |
| --- | --- |
| Proposal and traceability artifact | 0.5 SP |
| Prompt metadata and first-run copy update | 0.75 SP |
| Input normalization helper | 0.5 SP |
| Targeted integration tests and lint | 0.75 SP |

## Status History

- 2026-06-07: Created from maintainer dogfooding feedback during new-machine
  Specrew setup.
- 2026-06-07: Implemented and closed as Feature 172 on branch
  `172-profile-setup-ux-copy`; beta/release train remains a separate
  post-feature-closeout authorization path.
