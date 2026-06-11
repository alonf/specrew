---
proposal: 184
title: Console Experience Layer and Lens Thought Cards
status: candidate
phase: phase-2
estimated-sp: 9-14
priority-tier: 2
discussion: surfaced 2026-06-10 while discussing how to make Specrew feel more alive during workshops, gates, and long-running lifecycle steps. The maintainer asked for console graphics and for useful "fruit for thought" before each lens so the user has something productive to consider while the Crew prepares the next workshop section.
---

# Console Experience Layer and Lens Thought Cards

## Why

Specrew's lifecycle is rigorous, but the terminal experience can feel like a
sequence of dense text packets. Users may not immediately know:

- where they are in the lifecycle;
- what the Crew is doing now;
- whether the current step is waiting on tools, the model, or the human;
- which decision is load-bearing;
- what artifacts were produced;
- what useful thinking they can do while the next workshop lens is prepared.

That hurts trust and pacing. The system may be working correctly, but the user
experience can still feel inert.

Specrew should feel more alive without becoming theatrical. Console visuals
should make state, progress, decisions, and evidence easier to scan. They must
not fake progress, hide uncertainty, add LLM calls, or make CI logs noisy.

The workshop also needs better pacing between lenses. When the Crew is
preparing the next lens, the user should not just wait. Specrew can show a
short lens-specific "thought card" that gives the user useful prompts to think
about before the lens questions begin. This turns waiting time into preparation
time and reduces the feeling that the workshop is arbitrary.

## What

Add a small **Console Experience Layer** for Specrew's CLI and host-rendered
messages.

The layer should provide shared rendering primitives for:

- lifecycle phase timelines;
- workshop lens cards;
- lens thought cards;
- decision prompts;
- gate receipts;
- check summaries;
- artifact summaries;
- long-running command status;
- final handoff packets.

The first implementation should be terminal-native and conservative: text
panels, check marks or ASCII fallbacks, restrained color, width-aware wrapping,
and plain-mode support. It should not introduce a full terminal UI framework.

## User Experience Surfaces

### Lifecycle Timeline

Show the current position in the lifecycle at major boundaries:

```text
Feature 177: Software Development Rules Lens

Specify      DONE
Clarify      DONE
Plan         DONE
Tasks        DONE
Implement    DONE
Review       CURRENT
Retro        NEXT
Closeout     PENDING
```

This should appear in boundary packets, review signoff packets, and resume
surfaces where lifecycle position matters.

### Workshop Lens Card

Before each lens, show a compact card:

```text
[WORKSHOP] Architecture Lens

Step 3 of 8
Purpose: Choose boundaries, state ownership, integration style, and
         architecture constraints before implementation.

Output:  architecture decisions + feature deltas
Next:    questions about components, dependencies, data flow, and tradeoffs
```

The card should be generated from lens metadata, not hand-written in every
prompt.

### Lens Thought Card

Before each lens begins, or while the Crew is preparing the lens, show a
useful "thought card" so the user has something productive to do:

```text
Before The Architecture Lens

While I prepare the next section, think about:

1. What boundaries must not be crossed?
2. Which state is owned by which component or service?
3. What integrations are fixed constraints vs negotiable choices?
4. What would make the design hard to test or operate?

You do not need full answers yet. Short notes are enough.
```

The card should be specific to each lens. Examples:

- **Product/domain**: users, pain, current workaround, non-goals, vocabulary.
- **Architecture**: boundaries, state ownership, integration style, failure
  modes, rejected alternatives.
- **UI/UX**: primary workflow, density, accessibility, empty/error/loading
  states, responsive constraints.
- **Verification strategy**: proof goals, test mix, coverage posture, manual
  validation, CI gates.
- **Software development rules**: language/runtime, dependency posture,
  patterns, comments, API boundaries, example projects.
- **Security**: trust boundaries, data sensitivity, authz/authn, secrets,
  abuse cases.
- **DevOps**: deployment target, environments, rollback, observability, release
  gates.

Thought cards should be static catalog content with optional deterministic
substitution from known project context. They should not require a separate LLM
call.

### Decision Prompt Card

Render load-bearing questions with the decision, default, and why it matters:

```text
Decision Needed

Should this feature introduce a new runtime dependency?

Default:
  No. Prefer existing project dependencies unless the benefit is explicit.

Why it matters:
  This affects coupling, license review, security scanning, and future
  maintenance.
```

This composes with existing verdict menus and structured question behavior. It
does not replace human approval boundaries.

### Gate Receipt

Every human-judgment gate should produce a compact receipt:

```text
[GATE] Before Implement

Verdict: READY

Required checks:
  PASS  Traceability
  PASS  Capacity
  PASS  Hardening gate
  PASS  Governance validator

Human approval needed:
  Type "start implementation" to authorize source edits.

After approval:
  The Crew may write code and create implementation commits.
```

Gate receipts should make it obvious whether the system is asking for a
discussion, approval, rework, or no action.

### Long-Running Work Status

When commands or generation steps take time, show truthful status:

```text
Running checks

  Pester unit tests              running
  PSScriptAnalyzer               queued
  Governance validator           queued
```

For LLM work, do not fake percentages. Show phase and elapsed time:

```text
Preparing the Verification Strategy Lens

Elapsed: 01:42
Current: reading previous decisions and selecting the right depth

Food for thought:
  Which failures would embarrass us if they reached a user?
```

### Artifact Summary

When artifacts are produced, show them as outputs with purpose:

```text
Produced Artifacts

  spec.md                         approved scope and requirements
  plan.md                         architecture and quality bar
  tasks.md                        traced implementation breakdown
  implementation-rules.yml        rules selected for this feature
  specrew-code-rules              skill used during implementation
```

This supports Proposal 179's orientation goal: users should understand that
workshop answers become durable artifacts, context packs, and sometimes skills.

## Functional Requirements

- **FR-001**: Specrew MUST provide a shared console rendering layer for
  lifecycle timelines, workshop cards, thought cards, gate receipts, check
  summaries, and artifact summaries.
- **FR-002**: The renderer MUST support plain/no-color mode for CI, terminals
  without ANSI support, logs, and accessibility needs.
- **FR-003**: The renderer MUST be width-aware and avoid broken wrapping,
  overlapping text, or unreadable narrow-terminal output.
- **FR-004**: Workshop runtime MUST show a lens card before each lens begins,
  using lens metadata for purpose, position, expected output, and next step.
- **FR-005**: Workshop runtime MUST show a lens-specific thought card before
  each lens or while the Crew prepares the next lens, giving the user useful
  prompts to consider.
- **FR-006**: Thought cards MUST be deterministic catalog content in V1 and
  MUST NOT require an extra LLM call.
- **FR-007**: Gate packets MUST include a compact gate receipt showing verdict,
  required checks, human action needed, and what approval authorizes.
- **FR-008**: Long-running tool steps SHOULD show truthful status; LLM thinking
  MUST NOT show fake progress percentages.
- **FR-009**: Artifact-producing steps SHOULD render a concise artifact summary
  with each artifact's purpose.
- **FR-010**: The experience layer MUST respect the Crew Interaction Profile,
  allowing terse output for experienced users and richer guidance for new
  users.
- **FR-011**: The layer MUST compose with host parity: Claude, Codex, Copilot,
  Cursor, and Antigravity should receive equivalent content even if visual
  capabilities differ.
- **FR-012**: Console graphics MUST never hide blocking warnings, validator
  failures, review findings, or human-approval boundaries.

## Out Of Scope

- A full-screen terminal UI.
- A web dashboard replacement.
- Animated progress for LLM reasoning.
- Adding extra LLM calls only to make the UI feel alive.
- Replacing existing boundary packet content.
- Changing gate policy, approval wording, or lifecycle authority.
- Telemetry-driven personalization in V1.
- Complex terminal capability detection beyond practical color/plain/width
  handling.

## Effort

- **Iteration 1 (~5-8 SP)**: renderer primitives, plain/color modes,
  lifecycle timeline, gate receipt, artifact summary, and tests for wrapping
  and no-color output.
- **Iteration 2 (~4-6 SP)**: workshop lens cards, lens thought-card catalog,
  long-running status rendering, host parity checks, and documentation.
- **Total**: ~9-14 SP.

## Phase Placement

Phase 2. This is adoption, transparency, and lifecycle-understanding work. It
does not change Specrew's core methodology, but it makes the existing lifecycle
more legible and less tedious while users are learning it.

## Open Questions

1. Should thought cards show before every lens, or only when lens preparation
   takes longer than a short threshold?
2. Should the Crew Interaction Profile control thought-card depth independently
   from question depth?
3. Should box-drawing characters be enabled by default on modern terminals, or
   should ASCII be the universal default with color only?
4. Should gate receipts be persisted into gate packet files, or rendered only
   in the runtime handoff message?
5. Should the thought-card catalog live in the lens catalog, the design
   workshop skill, or a separate console-experience catalog?

## Risks

- **Visual noise**: too much decoration could make Specrew feel slower.
  Mitigation: use compact cards, profile-aware verbosity, and no animation
  unless tied to real tool execution.
- **False progress**: progress bars for model thinking would mislead users.
  Mitigation: only show deterministic command status or elapsed-time phase
  labels.
- **Accessibility regressions**: color-only meaning or box-heavy layouts can be
  hard to read. Mitigation: plain mode, text labels, and width-aware rendering.
- **Host divergence**: rich rendering may work in one host and degrade poorly
  in another. Mitigation: one content model with host-specific renderers and
  parity tests.
- **Snapshot brittleness**: console output tests can become noisy. Mitigation:
  test the semantic model and a few stable render fixtures, not every line of
  every packet.
- **Methodology dilution**: making the experience lively could hide the hard
  approval boundary. Mitigation: gate receipts must explicitly state what is
  authorized and what remains blocked.

## Cross-References

- Related proposals: 009, 012, 043, 077, 092, 141, 143, 155, 157, 165, 176,
  177, 178, 179.
- Composes with Proposal 141 by adapting output depth to the Crew Interaction
  Profile.
- Composes with Proposal 155 because typed boundary packets can provide the
  structured data for gate receipts.
- Composes with Proposal 157 because verdict-menu instruction text should
  become clearer when rendered in decision/gate cards.
- Composes with Proposal 176 because product-domain is the first lens and the
  first place where a thought card should appear.
- Composes with Proposal 177 because artifact summaries should explain which
  results become context packs or durable skills.
- Composes with Proposal 178 because verification-strategy thought cards can
  prepare the user to think about proof, coverage, CI gates, and manual
  validation before the lens starts.
- Complements Proposal 179 by turning the documented workshop mental model into
  live runtime guidance.

## Status History

- 2026-06-10: status set to candidate from maintainer request to make the
  Specrew user experience feel more alive with console graphics and
  lens-specific thought prompts while the Crew prepares each workshop lens.
