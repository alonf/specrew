---
proposal: 179
title: Workshop Pairing Orientation and Resulting Skills Explanation
status: candidate
phase: phase-2
estimated-sp: 4-7
priority-tier: 2
discussion: surfaced 2026-06-10 while dogfooding the software-development-rules lens. The maintainer observed that many developers will find Specrew workshops tedious unless Specrew explains the shifted role: the workshop is where the developer pair-programs with the agent by setting intent, constraints, tradeoffs, and proof standards before code is written. Gates are still required, but gate review is too late to be the primary guidance mechanism. The documentation and workshop preface should also explain how workshop results can become artifacts, context packs, and managed skills.
---

# Workshop Pairing Orientation and Resulting Skills Explanation

## Why

Specrew asks more questions up front than many developers expect. Without a
clear explanation, the workshop can feel like ceremony, delay, or project
management overhead.

That is the wrong framing.

The developer's job shifts in an AI-assisted workflow. The highest-leverage
pairing moment is no longer only "watch the code being typed." It is the
workshop: the human teaches the Crew the product intent, architectural
constraints, implementation rules, testing bar, and tradeoffs before the agent
writes code.

Gate approval remains mandatory, but gates are correction points. If the first
serious human guidance happens at a gate, the system has already spent time
building something that may be wrong. The point of the workshop is to avoid
that waste.

Specrew also needs to explain the downstream value of workshop outputs:

- immediate feature artifacts that guide this feature;
- feature context packs that summarize the working set;
- durable managed skills that can carry reusable project rules into future
  implementation and review sessions.

Developers need to understand that answering workshop questions is not
administrivia. It is how they pair with the agent at the moment where their
judgment has the most leverage.

## What

Add a concise orientation layer for workshops and the resulting skill/context
model.

The feature should update four surfaces:

1. **README**: short high-level explanation of why workshops exist.
2. **Getting Started**: practical "what your job is now" section for first-time
   users.
3. **Design Workshop Methodology**: deeper explanation of workshop as
   pair-programming and how artifacts/context/skills flow into implementation.
4. **Workshop runtime preface**: a short message shown before the first
   workshop lens so users understand why they are being asked questions.

The feature should also add a reusable explanation of resulting skills and
context packs, linked from the above surfaces and summarized in the runtime
preface.

## Proposed User-Facing Text

### README Section

Recommended placement: near the first description of the Specrew lifecycle.

```markdown
### Why Specrew Starts With a Workshop

Specrew moves the developer's leverage point earlier.

With an AI coding agent, the main pair-programming moment is not only while
code is being written. It is the workshop before implementation, where you set
the product intent, constraints, tradeoffs, implementation rules, and proof
standard the agent will use.

Approving a gate is still your responsibility, but gates are correction points.
If the first serious guidance happens at a gate, the Crew may already have
built the wrong thing. The workshop is where you prevent that rework.

For low-risk choices, delegate. For product, architecture, security, testing,
or dependency decisions that matter, steer the Crew before it writes code.
```

### Getting Started Section

Recommended placement: after the first example `specrew start` flow.

```markdown
## Your Role In The Workshop

The workshop is how you pair with the Crew.

Your job is not to answer every question with a long essay. Your job is to make
the decisions the agent cannot safely invent:

- who the feature is for and what problem it solves;
- what constraints, non-goals, and risks matter;
- which architecture, UI, dependency, and implementation rules must hold;
- what evidence will prove the work is done;
- which decisions are safe to delegate.

Use "you decide" for low-risk implementation details. Push back when a proposed
assumption would change product behavior, architecture, security, cost,
operations, testing, or user experience.

The first few workshops may feel slower. As project defaults, context packs,
and skills accumulate, the Crew should ask less and reuse more of what you have
already taught it.
```

### Runtime Preface Before First Workshop Lens

Recommended placement: emitted once before the product-domain or first
applicable workshop lens, not before every lens.

```text
Before the workshop starts: this is the main pair-programming moment with the
Crew.

You are not being asked questions for ceremony. You are teaching the agent the
product intent, constraints, tradeoffs, implementation rules, and proof
standard before it writes code. You can delegate low-risk choices, but decisions
made here become the context the agent uses during planning, implementation,
and review.

Gates can catch problems later. The workshop is where we avoid building the
wrong thing.
```

### Resulting Skills And Context Explanation

Recommended placement: `docs/methodology/design-workshop-methodology.md` and
linked from Getting Started.

```markdown
## What Happens To Workshop Results

Workshop results are not just chat history.

Specrew records decisions in durable artifacts, then uses them later:

- **Workshop artifacts** capture the full human-readable decision record for
  the current feature.
- **Structured records** store decisions in a machine-readable shape so gates,
  tasks, review, and future tooling can consume them.
- **Context packs** summarize the active feature's working set: inherited
  project rules, feature-specific deltas, assumptions, and links back to source
  artifacts.
- **Managed skills** expose durable project rules to agents at the moment they
  implement or review code. Examples include code rules, product context,
  architecture rules, UI/UX rules, and quality/testing rules.

The rule of thumb:

- feature-specific decisions stay in the feature context pack;
- durable project rules can be promoted into managed skills after explicit
  human approval;
- assumptions and research snapshots stay traceable to their source and
  freshness date.

This keeps prompts small while giving agents access to the decisions they need.
```

### Runtime Skill Summary After Workshop

Recommended placement: after the design workshop completes, before the next
boundary packet or plan step.

```text
Workshop results captured.

These decisions will be used in three ways:
- feature artifacts keep the full decision record;
- the feature context pack summarizes what implementers and reviewers need now;
- durable rules may be promoted to managed skills, so future agents can reuse
  project-level product, architecture, UI/UX, quality, and code guidance.

I will surface the relevant context again before implementation and review.
```

## Functional Requirements

- **FR-001**: Specrew documentation MUST explain that the workshop is the main
  pair-programming moment where the developer guides the agent before code is
  written.
- **FR-002**: Documentation MUST explain that gate approvals remain mandatory
  but are correction/accountability points, not the ideal first guidance point.
- **FR-003**: `README.md` MUST include a short "Why Specrew Starts With a
  Workshop" section or equivalent.
- **FR-004**: `docs/getting-started.md` MUST include a practical "Your Role In
  The Workshop" section or equivalent.
- **FR-005**: `docs/methodology/design-workshop-methodology.md` MUST explain
  how workshop outputs flow into artifacts, structured records, context packs,
  and managed skills.
- **FR-006**: The workshop runtime MUST emit a concise preface before the first
  workshop lens, explaining why the user is being asked questions and how to
  delegate low-risk choices.
- **FR-007**: The workshop runtime SHOULD emit a concise post-workshop summary
  explaining how captured decisions will be reused during implementation and
  review.
- **FR-008**: The skill/context explanation MUST distinguish feature-specific
  context packs from durable managed skills.
- **FR-009**: The documentation MUST avoid implying that every workshop note
  becomes a permanent skill. Durable promotion requires explicit human
  approval and source/freshness metadata.
- **FR-010**: The orientation MUST be short enough not to become another source
  of workshop fatigue for experienced users.

## Out Of Scope

- Changing the workshop lens content or adding new lenses.
- Implementing Proposal 177's full context-pack and managed-skill promotion
  system.
- Rewriting the complete README, Getting Started guide, or methodology docs.
- Adding telemetry or measuring adoption in V1.
- Making gate approval optional.

## Effort

- **Iteration 1 (~4-7 SP)**: README, Getting Started, methodology doc updates,
  runtime preface/post-workshop summary text, and tests/snapshot checks for the
  emitted text if the workshop skill has test coverage.
- **Total**: ~4-7 SP.

## Phase Placement

Phase 2. This is adoption and lifecycle-understanding work. It makes the
existing and emerging workshop system easier to use correctly without waiting
for the full managed-skill/context-pack implementation.

## Open Questions

1. Should the runtime preface show every session, only on first workshop in a
   project, or only until the project has a confirmed interaction profile?
2. Should experienced users get a terse mode controlled by the Crew Interaction
   Profile?
3. Should the post-workshop skill/context summary wait for Proposal 177 to ship,
   or should it describe the current artifact behavior plus the planned managed
   skill path?

## Risks

- **More text fatigue**: adding orientation could make the workshop feel even
  longer. Mitigation: concise preface, once per workshop, with longer detail in
  docs.
- **Overpromising skills**: documentation could imply skills exist before
  Proposal 177 ships. Mitigation: distinguish current artifacts/context from
  future durable managed-skill promotion where needed.
- **Undermining gates**: saying workshops prevent rework could sound like gates
  are less important. Mitigation: explicitly state gates remain mandatory
  accountability boundaries.
- **User role confusion**: developers may think they must answer everything.
  Mitigation: teach delegation for low-risk choices and steering for
  load-bearing decisions.

## Cross-References

- Related proposals: 007, 063, 141, 143, 156, 162, 176, 177, 178.
- Composes with Proposal 177 by explaining context packs and durable managed
  skills without implementing the full promotion system.
- Composes with Proposal 141 by aligning with the Crew Interaction Profile:
  experienced users can receive shorter orientation while new users get more
  guidance.
- Composes with Proposal 176 because product-domain is the first lens where the
  runtime preface should appear.

## Status History

- 2026-06-10: status set to candidate from maintainer discussion about
  workshop fatigue, shifted developer responsibility, and the need to explain
  resulting skills/context packs before the workshop.
