# UI And UX Lens

## Lens ID

`ui-ux`

## Purpose

Make user experience a first-class design input. If there is a UI, the Crew
should discuss the workflow, references, interaction model, data movement, and
accessibility before planning implementation tasks.

## Applicability Signals

- The feature has screens, forms, dashboards, tables, CLI prompts, messages,
  onboarding, visual evidence, or user-visible workflow.
- The user mentions Figma, screenshots, images, mockups, existing UI behavior,
  themes, pagination, sorting, grouping, streaming, or async interaction.
- The feature changes how users make decisions or recover from errors.
- The interface must work across device sizes, locales, themes, or assistive
  technologies.

## Design Decision Points

- What source of UX truth exists: Figma, screenshots, design system, existing
  product patterns, prototype, or text-only intent?
- What are the primary user journeys and interruption/recovery paths?
- Should data operations be client-side, server-side, streamed, or event-driven?
- How are loading, empty, error, disabled, offline, and conflict states shown?
- Which UI state belongs on the client, server, URL, cache, or durable store?
- What accessibility, localization, RTL, theming, or regulatory constraints
  apply?

## Workshop Conduct

- **Diagram for this lens**: UI layout / wireframe, screen-navigation flow, state — render it as **console ASCII inline** so the human sees it in the conversation (a fenced mermaid block is source text, not a picture, on a terminal host); any mermaid/svg/html file is an *additional* artifact whose clickable `file:///` link you surface in the same message.
- **Facilitate, do not dictate**: raise the Design Decision Points above as a discussion, show a console-ASCII screen layout and capture the AGREED layout in the design record, capture the human's decisions and explicit agreement, iterate until they say "move on", and record the agreement (never leave it only in the chat scrollback).
- **Re-invoke the `specrew-design-workshop` skill** before moving to the next lens.

## Question Bank

- Is there a Figma file, screenshot, image, or existing screen to match?
- What user task should the first screen optimize?
- Which controls need paging, filtering, grouping, or sorting?
- Should paging/sorting/filtering be client-side or server-side, and why?
- Does the UI need polling, push, WebSocket, streaming, or manual refresh?
- What should happen when the server update times out or returns unknown state?
- What can be optimistic, and what requires pessimistic locking or confirmation?
- What are the empty, loading, validation, partial-success, and error states?
- Are there accessibility, keyboard, screen-reader, RTL, localization, or theme
  requirements?
- Does the UI need offline mode or resynchronization?

## Alternative Dimensions

- **Simplest**: existing UI pattern, minimal states, local interactions, and
  manual refresh.
- **Reasonable**: explicit flows, state ownership, server/client query policy,
  validation behavior, accessibility baseline, and responsive behavior.
- **By the book**: design references, user journey map, state machine, full
  interaction-state matrix, offline/conflict handling, telemetry, and usability
  validation.

## Plan Obligations

- Record the UX source of truth and any missing design assets.
- Decide client/server ownership for paging, sorting, filtering, grouping, and
  synchronization.
- Plan UI tests or manual visual smoke checks for key states and responsive
  layouts.

## Validation Signals

- Screens or prompt flows are inspected, not only compiled.
- Review verifies text fits, states are reachable, and user recovery paths are
  not hidden behind happy-path tests.
- If no design artifact exists, the plan records the substitute decision source.

## Source Notes

- Book Chapter 2.
- Course Modules 2 and 5.
