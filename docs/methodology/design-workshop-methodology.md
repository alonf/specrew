# Specrew Design Workshop Methodology

This document describes the Specrew Design Workshop methodology: the human-agent
design conversation that happens before implementation work is planned and executed.

The workshop is part of Specrew's governed agentic SDLC. It exists to prevent
silent design decisions, reduce plan-time rework, and keep the human developer in
control of architecture, product, quality, and implementation direction.

## Purpose

The Design Workshop turns design from an implicit agent decision into an explicit,
reviewable, human-guided process.

Without the workshop, an agent can move from a request into a plan while silently
choosing architecture, decomposition, data ownership, security posture, UI behavior,
deployment assumptions, and operational behavior. Specrew treats those choices as
design decisions that must be surfaced, discussed, and recorded before they become
plan and implementation work.

The workshop has four goals:

1. Surface the design areas that matter for the current feature.
2. Facilitate a real discussion with the human, one design lens at a time.
3. Co-design structure, responsibilities, flows, and trade-offs before planning.
4. Persist the decisions as durable project artifacts, not as chat-only context.

## Relationship To The Specrew Lifecycle

The workshop participates in the formal Specrew lifecycle:

```text
specify -> clarify -> before-plan -> plan -> tasks -> before-implement -> implement
       -> review-signoff -> retro -> iteration-closeout -> feature-closeout
```

The workshop is used in two places:

1. **Specify / intake** — to make requirements lens-informed before the spec is
   finalized.
2. **Design-analysis stop** — to co-design architecture and implementation
   direction before `plan.md` is authored.

The design-analysis stop is the place where the Crew and the human compare
meaningful design choices before the plan locks in one approach. A substantive
feature must not move into planning with a silent or unrecorded architecture
decision.

## Core Principles

### 1. The workshop is a conversation, not a questionnaire

The workshop is not a one-shot checklist and not a form that the agent fills by
itself. The agent acts as a workshop facilitator. It proposes, explains, asks,
listens, adapts, records, and iterates.

Multiple-choice questions may be used when the decision is discrete and enumerable,
but they must not replace the design conversation. Open design questions should
remain open. Discrete decisions should offer clear options plus an "other / let me
explain" path.

### 2. The agent infers applicability, the human confirms material scope

The agent should infer which lenses apply from the feature, repository context, and
known product constraints. It should not make the human answer obvious yes/no
questions.

However, the agent must not silently resolve material design areas. It should
render a proposed agenda, explain why each selected lens applies, explain why
skipped lenses do not apply, and ask the human to confirm or adjust.

### 3. Every selected lens must be surfaced

A selected lens is not complete until the human has seen it and one of these is
true:

- the human confirmed the decision;
- the human explicitly delegated the decision to the agent; or
- the human explicitly skipped the lens.

The agent must never record "human agreed" for a lens the human never saw.

### 4. Render before asking

Before asking the human to approve, confirm, move on, or choose from a structured
menu, the content being approved must already be visible in the same assistant
message.

The human approves what is on screen, not a count, a summary, a file path, or a
claim that content was shown elsewhere.

This rule applies to:

- workshop agendas;
- per-lens diagrams;
- component maps;
- option and trade-off sets;
- design-analysis verdicts;
- UI layouts;
- co-design records.

### 5. Visuals are part of the workshop

Visuals are not optional decoration for structural decisions. A diagram makes the
discussion concrete and reduces hidden coupling.

On terminal or console hosts, fenced Mermaid source is not a rendered visual. Use
console ASCII inline by default. Mermaid, SVG, or HTML may be written to a file as
an additional artifact, but the agent must also provide a clickable `file:///`
reference when the host supports it.

A diagram written to disk but not shown to the human is not considered surfaced.

### 6. Co-design before options

At the design-analysis stop, the agent must not hand down finished architecture
options for the human to choose from. It must first co-design the important
structure with the human:

- design method or decomposition style;
- major components or services;
- responsibilities;
- dependency directions;
- at least one key user/system flow.

Only after the component map and at least one flow are agreed should the agent
present the remaining trade-off options.

### 7. Persist decisions as artifacts — at checkpoint time, not at the end

Workshop decisions must survive the chat. They are recorded in feature artifacts
so future agents, reviewers, and maintainers can understand why the system was
designed a certain way.

A decision that exists only in conversation scrollback is not durable Specrew
evidence.

Timing matters as much as content (Feature 174). A workshop is long, and a
mid-workshop exit, crash, or host switch is expected, not exceptional. Two
checkpoint rules make the workshop resumable:

- **Persist the agenda the moment the human confirms it** — the feature-level
  `lens-applicability.json` with the `selected` list is written before lens 1
  opens. A resuming session can only compute the remaining agenda if the agenda
  itself is on disk.
- **Persist each lens before advancing to the next** — the lens record and its
  workshop file are written when the lens completes, never batched at the end.
  A mid-workshop exit then loses at most the lens in progress; the resume
  continues from the next un-persisted lens instead of restarting the workshop.

Observed both ways in live cross-host trials: a host that persisted the agenda
and each lens resumed precisely at the next remaining lens after an exit; a host
that kept the agenda only in conversation re-ran the wrong lifecycle step on
resume because nothing on disk said which lenses remained.

## Current Lens Catalog

The current shipped workshop uses eleven design lenses, run in three bands.

**Band 1 — Product & problem domain (required first phase).** Always runs first,
before any technical lens, at adaptive depth (Light / Standard / Deep by risk and
novelty). Shipped in 0.34.0.

| Lens | Purpose |
|---|---|
| `product-domain` | Users and stakeholders, the pain or job to be done, MVP and non-goals, constraints, target outcomes, and considered alternatives — grounded before any technical decision. |

**Band 2 — Technical lenses (applicability-selected).**

| Lens | Purpose |
|---|---|
| `architecture-core` | Structure, boundaries, constraints, volatility, and design method. |
| `component-design` | Responsibilities, coupling, cohesion, dependency direction, extension seams, and testability. |
| `requirements-nfr` | Design-driving requirements, constraints, quality attributes, and measurable success criteria. |
| `ui-ux` | User journeys, screens, prompt flows, state ownership, accessibility, layout, and recovery paths. |
| `data-storage` | Persistence, ownership, consistency, migrations, lifecycle, backup, restore, and retention. |
| `security-compliance` | Identity, authorization, secrets, sensitive data, trust boundaries, audit, and compliance. |
| `integration-api` | Service boundaries, contracts, protocols, versioning, idempotency, retries, and compatibility. |
| `devops-operations` | Hosting, deployment, CI/CD, configuration, secrets, rollout, rollback, and operational roles. |
| `observability-resilience` | Logs, metrics, traces, health, failure modes, retries, recovery, and diagnosability. |

Among the technical lenses, these are normally always-on:

- `architecture-core`
- `component-design`
- `requirements-nfr`

The remaining technical lenses are selected when the feature touches their area.

**Band 3 — Code & implementation (runs last, auto-on for code-writing features).**
Runs after the technical lenses so it can bind the resolved stack and architecture.
Shipped in 0.35.0.

| Lens | Purpose |
|---|---|
| `code-implementation` | How the code is written — language version, constructs, DI / design-pattern posture, file and function size, comment policy, per-stack conventions, refactor-prevention posture, and dependency selection — captured as binding constraints and fed to the implement-time `specrew-code-rules` guidance skill. Auto-on for any feature that writes code (explicit skip for doc-only / config-only slices). |

## Lens Catalog Evolution

The lens catalog grew beyond the original nine technical lenses:

- `product-domain` shipped in **0.34.0** as the required first phase (Band 1 above).
- `code-implementation` shipped in **0.35.0** as the auto-on code-craft lens (Band 3
  above). It was previously tracked as a candidate "tenth lens"; it now ships as a
  data-driven rule catalog (`code-rules.yml`), a per-feature reference-by-ID manifest
  (`implementation-rules.yml`), and an implement-time guidance skill
  (`specrew-code-rules`). It is **guidance, not a review-time gate** — there is no
  mechanical code-conformance engine.

No additional lens is currently in flight. The next forward-looking change to the
workshop is the two-tier (product-level + per-feature) model described under
"Two-Tier Workshop Model" below, not a new lens.

## Workshop Flow

### Phase 1 — Orient the human

At the start, the agent explains what the workshop will do:

- it gathers inputs and constraints;
- it identifies the design lenses that matter;
- it prepares the human for later co-design;
- it records decisions as artifacts;
- it does not finalize the system structure during intake alone.

The agent should also explain that preparing the workshop may take a moment. That
pause should feel like preparation, not a hang.

### Phase 2 — Propose the agenda

The agent renders a visible agenda before asking for confirmation.

A good agenda entry includes:

- the lens id;
- the proposed depth: `full`, `medium`, or `light`;
- the concrete decision this lens will ask the human to make;
- the reason the lens applies.

Example:

```text
Workshop agenda — 5 lenses

architecture-core (full) — decide the decomposition style and major runtime boundaries.
component-design (full) — decide component responsibilities and dependency direction.
requirements-nfr (medium) — decide which qualities drive this slice and how to measure them.
security-compliance (light) — confirm no new identity, secret, or sensitive-data surface.
observability-resilience (medium) — decide failure handling and diagnostic evidence.

Skipped:
ui-ux — no user-facing UI or prompt-flow change in this slice.
data-storage — no durable data shape or migration change.
integration-api — no external contract or message boundary change.
devops-operations — no deployment, CI/CD, or hosting change.
```

The agent then asks the human to confirm or adjust the agenda.

The moment the human confirms, the agent persists the agenda: the feature-level
`lens-applicability.json` is written with `workshop_intake: true`,
`confirmation_required: true`, and the confirmed `selected` lens-id list —
before lens 1 opens. The per-lens `workshop` records are appended later as each
lens completes (Phase 7). This is the checkpoint that makes a mid-workshop
resume computable (Core Principle 7).

### Phase 3 — Run one lens at a time

For each selected lens:

1. Load the lens file.
2. Present the lens purpose and decision points.
3. Ask an open question first.
4. Offer a pacing choice for dense lenses:
   - answer all at once; or
   - step through the decisions one by one.
5. Discuss options and constraints.
6. Render diagrams or tables where useful.
7. Capture the decision and explicit confirmation.
8. Move on only when the human agrees, delegates, or skips.

The first move of a lens must not be a structured menu. Open with presentation and
discussion, then use structured choices only after the content is visible.

### Phase 4 — Use visuals as a shared whiteboard

Each lens has a native visual vocabulary:

| Lens | Typical visual |
|---|---|
| `product-domain` | Persona / journey sketch, problem-framing note, or MVP-scope table. |
| `architecture-core` | Component, service, or flow diagram. |
| `component-design` | Component map with dependency direction. |
| `requirements-nfr` | Quality-attribute priority table or comparison matrix. |
| `ui-ux` | Layout, wireframe, navigation flow, or state sketch. |
| `security-compliance` | Trust-boundary and attack-surface diagram. |
| `data-storage` | ERD or NoSQL document relationship sketch. |
| `integration-api` | Contract sequence or service interaction diagram. |
| `devops-operations` | Deployment topology and promotion path. |
| `observability-resilience` | Request trace or failure-mode flow. |
| `code-implementation` | Rule-group checklist or per-stack convention table (text-first). |

The agent should offer to draw the diagram and ask whether the human has an
existing diagram, Figma export, screenshot, whiteboard photo, or document to use as
input.

### Phase 5 — Co-design the structure

At design-analysis, the agent and human agree the structural baseline before the
agent writes alternatives.

For architecture or component work, this means:

1. Choose the decomposition style explicitly.
2. Build a component map together.
3. Name every component.
4. Assign one-line responsibility to every component.
5. Show dependency direction.
6. Walk at least one key flow.
7. Ask the human to rename, split, merge, or reassign.
8. Re-render the map after changes.
9. Continue until the human agrees.

Example component-map form:

```text
Proposed component map

[TrayClient] ---> [SessionManager] ---> [HostAdapter]
                      |
                      v
              [BoundaryStateStore]

Managers:
  SessionManager — owns lifecycle session state and boundary transitions.

Adapters:
  HostAdapter — invokes the selected AI host using the host contract.

Stores:
  BoundaryStateStore — persists boundary authorization and current lifecycle state.

UI:
  TrayClient — owns local user interaction and command entry points.

Key flow:
  user starts feature -> TrayClient -> SessionManager -> HostAdapter -> boundary state updated
```

### Phase 6 — Present alternatives and recommendation

After co-design, the agent may present design alternatives.

For substantive work, alternatives usually follow this shape:

- **Option A: Simplest** — smallest viable design, with explicit future cost.
- **Option B: Reasonable** — balanced production default.
- **Option C: By the book** — fuller architecture for long-lived, regulated,
  security-sensitive, or high-reversibility-cost work.

Only genuinely distinct options should be presented. Do not invent a third option
that adds no real choice.

The agent should recommend one option and explain why. The human verdict must be
explicit and recorded before plan generation uses the choice.

Example verdict shape:

```text
approved for plan with Option B
```

If the human modifies an option, the modification becomes plan input.

### Phase 7 — Capture and persist decisions

The workshop produces durable artifacts — incrementally. Each lens is persisted
when it completes (its `workshop` record plus its `workshop/<lens-id>.md` file),
and the rolling session handover body is refreshed at the same checkpoint, so an
exit at any point hands the next session both the decisions so far and the
position in the agenda. Batching persistence to the end of the workshop defeats
the resume property and is an anti-pattern.

At minimum, the per-lens record should include:

- `workshop_intake: true`
- `confirmation_required: true`
- `selected`: list of selected lens ids
- `workshop`: object keyed by lens id
- per-lens `agenda`
- per-lens `decision`
- per-lens `depth`
- per-lens `moved_on: true`
- per-lens `confirmation`
- per-lens `confirmation_scope`

Allowed confirmation values:

```text
human-confirmed
human-delegated
human-skipped
```

Required `confirmation_scope` values:

```text
human-confirmed  -> lens-question
human-delegated  -> explicit-delegation
human-skipped    -> explicit-skip
```

`human-confirmed` means the substantive questions for that lens were surfaced
and confirmed. Lens approval is not workshop-question approval.

Example shape:

```json
{
  "workshop_intake": true,
  "confirmation_required": true,
  "selected": [
    "architecture-core"
  ],
  "workshop": {
    "architecture-core": {
      "agenda": [
        "Which decomposition style governs this feature?",
        "What are the major components and responsibilities?"
      ],
      "decision": "Use a modular monolith with explicit component boundaries for this slice; defer service extraction.",
      "depth": "full",
      "moved_on": true,
      "confirmation": "human-confirmed",
      "confirmation_scope": "lens-question"
    }
  }
}
```

Keeper diagrams should be persisted under a workshop folder such as:

```text
specs/<feature>/workshop/<lens-id>.md
```

The design-analysis artifact should include a co-design record with:

- agreed component-to-responsibility map;
- at least one agreed flow;
- human-agreed marker;
- agreed UI or screen layout when UI/UX is in scope.

## Artifact Contract

The exact artifact set may evolve, but the workshop methodology expects these
durability surfaces:

| Artifact | Purpose |
|---|---|
| `specs/<feature>/lens-applicability.json` or iteration-local equivalent | Records selected lenses, applicability, and per-lens decision provenance. |
| `specs/<feature>/workshop/<lens-id>.md` | Persists keeper diagrams and lens-specific workshop notes. |
| `specs/<feature>/iterations/<NNN>/design-analysis.md` | Records problem framing, decision points, alternatives, recommendation, human decision, and co-design record. |
| `specs/<feature>/plan.md` | Consumes the human-selected design option and workshop decisions as authoritative plan input. |
| `.squad/decisions.md` or equivalent decision ledger | Records human boundary approvals and material decisions. |

## Behavioral Quality Versus Deterministic Gates

The workshop has both behavioral and deterministic parts.

The deterministic floor can verify that required artifacts exist, that selected
lenses have records, that confirmation provenance is declared, and that the
design-analysis artifact contains required sections.

The deterministic floor cannot prove the quality of the conversation. It cannot
know whether the agent truly facilitated, whether the human meaningfully engaged,
or whether the diagram clarified the decision.

Therefore, Specrew uses both:

- deterministic gates to block omission and malformed artifacts;
- runtime dogfooding and review discipline to validate collaboration quality.

## Host Behavior And Structured Menus

Different hosts render structured questions differently.

The workshop's converged host-neutral rule is:

- content followed by open discussion is reliable;
- content immediately before a structured menu may be skipped or collapsed into
  the menu on some hosts;
- therefore, open each lens with presentation plus an open question;
- use structured menus only after the content is visible;
- when approving diagrams, maps, or options, render the full content in the same
  message as the approval request.

Host-specific hooks may later enforce render-before-menu behavior where the host
supports them. That is an enforcement accelerator, not the core methodology.

## Two-Tier Workshop Model

The current shipped workshop is per-feature.

A candidate future extension proposes a two-tier model:

1. **Product/App-level workshop** — run once, re-openable, to establish macro
   architecture, design method, service landscape, cross-cutting decisions, and
   binding product constraints.
2. **Per-feature workshop** — short, inherits product-level decisions, and focuses
   only on what is new, different, touched, added, or divergent.

Until that model ships, per-feature workshops should still avoid silently
contradicting established product architecture. If a feature diverges from an
existing product-level decision, the divergence should be explicit and recorded.

## Common Anti-Patterns

### Questionnaire collapse

The agent asks a fixed list of yes/no questions and proceeds without discussing
the selected lenses.

Correct behavior: infer applicability, confirm agenda, then facilitate each
selected lens.

### Menu-before-render

The agent asks the human to approve "8 lenses" or "13 components" without
showing the actual agenda or component map.

Correct behavior: render the full agenda or component map first, then ask.

### Disk-only diagram

The agent writes a diagram file and asks the human to approve it without showing
the diagram or providing a visible link.

Correct behavior: show ASCII inline and optionally persist Mermaid/SVG/HTML.

### Fabricated agreement

The agent records "human agreed" for lenses that were never surfaced.

Correct behavior: record `human-confirmed`, `human-delegated`, or
`human-skipped` honestly with a matching `confirmation_scope`.

### Lens approval used as workshop-question approval

The agent treats a human's approval of the workshop agenda or selected lens set
as approval for all substantive questions inside those lenses.

Correct behavior: agenda/lens-set approval only authorizes running the
workshop. Every selected lens still needs a scoped per-lens answer, explicit
delegation, or explicit skip. Lens approval is not workshop-question approval.

### Finished architecture handoff

The agent presents three completed architectures for the human to choose from
without first co-designing components and flows.

Correct behavior: co-build the component map and key flow first, then discuss
remaining trade-off options.

### Re-running the full workshop for every feature

The agent repeats a long macro-architecture conversation for every feature even
when the product architecture is already established.

Correct behavior: inherit existing product decisions when available and focus on
feature deltas. The formal two-tier model is future scope, but the principle is
already useful.

## Reviewer Checklist

A reviewer assessing workshop compliance should ask:

- Was the workshop agenda rendered before confirmation?
- Did the agent infer applicability and explain selected/skipped lenses?
- Was every selected lens surfaced to the human?
- Did dense lenses offer pacing?
- Were visuals shown in-band when structural decisions were made?
- Was the design method or decomposition style explicitly discussed?
- Was the component map co-designed rather than handed down?
- Were all components named with one-line responsibilities?
- Was at least one key flow walked through the design?
- Were decisions captured with honest provenance?
- Does each selected lens have a matching `confirmation_scope`, and is agenda
  approval never reused as workshop-question approval?
- Did `design-analysis.md` preserve the human-selected option?
- Did `plan.md` consume the selected design as authoritative input?
- Are diagrams and workshop records persisted, not chat-only?
- Are any divergences from established product architecture explicit?

## Maintainer Guidance

When extending the workshop methodology:

- prefer lens content in data files over hard-coded prompt prose;
- keep the core method host-neutral;
- use deterministic gates to prevent omission, not to pretend to judge
  conversation quality;
- use host-specific hooks only as enforcement accelerators;
- keep future lenses research-gated until their decision points and enforcement
  boundaries are clear;
- update this document when the shipped methodology changes.

## Summary

The Specrew Design Workshop is the point where the human and agent jointly decide
the design direction before plan and implementation. It is a facilitated,
lens-driven, visual, artifact-backed conversation.

Its success condition is simple:

> The human can see the design, shape the design, approve the design, and later
> audit why that design became the plan.
