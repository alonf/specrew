---
proposal: 154
title: Boundary Authorization Prompt Truth + Human Re-entry Packet
status: draft
phase: phase-2
estimated-sp: 5-8
priority-tier: 1
type: small-fix
discussion: HIGH PRIORITY release-blocking beta2 smoke failure on 2026-06-01. A fresh greenfield Copilot/Squad smoke against v0.30.0-beta2 auto-continued from clarify into plan after the generated lifecycle quick reference said only before-implement, review-signoff, iteration-closeout, and feature-closeout hard-block. This contradicts `.specrew/config.yml` boundary policy, sync command authorization gates, and the Feature 016 one-boundary-at-a-time contract. Amended 2026-06-01 to include the human re-entry packet: every approval stop must summarize the past, identify what to review, preview the future, and proactively invite discussion or additional instructions before continuing.
composes-with:
  - 007  # Substantive Interaction Model - every boundary stop needs a human-readable handoff
  - 065  # Launch-Mode Boundary Enforcement - boundary authorization mechanics
  - 120  # Broader handoff/backstop validator bundle
  - 142  # State-truth integrity validator
  - 150  # Agent-support hardening - next authorized action only
  - 151  # Handoff contract shape; adjacent but not the authorization truth owner
---

# Boundary Authorization Prompt Truth + Human Re-entry Packet

## Why

The v0.30.0-beta2 smoke trial exposed the same class of failure that blocked beta1:
the generated coordinator handoff gives agents a lifecycle contract that is less
strict than the durable boundary policy.

Empirical smoke path:

- Clean downstream project: `C:/Users/alon.HOME/temp/SpecrewSmoke-F051-beta2`
- Host/runtime: Copilot/Squad
- Feature request: `Create a 0MQ binding for Dapr`
- Clarify completed with user-grounded answers for `.NET / C#`, both input and
  output bindings, and simple one-way messaging.
- The agent changed `spec.md` from `Status: Draft` to `Status: Approved` as a
  planning-readiness repair.
- No human approval record was written to `.squad/decisions.md`.
- The agent continued into `/speckit.plan`.

This was not a user-memory issue and not only a Copilot host issue. The generated
`.specrew/last-start-prompt.md` told the coordinator that:

- `Test-SpecrewBoundaryAuthorization` is only hard-blocking at four points:
  `before-implement`, `review-signoff`, `iteration-closeout`, `feature-closeout`.
- Once clarify completes, the coordinator should continue automatically through
  `before-plan`, `plan`, `tasks`, and `after-tasks`.

That prompt contradicts the source-of-truth surfaces that already exist:

- `.specrew/config.yml` defines `specify`, `clarify`, `plan`, `tasks`,
  `before-implement`, `review-signoff`, `retro`, `iteration-closeout`, and
  `feature-closeout` as `human-judgment-required`.
- `speckit.specrew-speckit.sync-plan.md` calls
  `Test-SpecrewBoundaryAuthorization -CurrentBoundary 'clarify' -RequestedBoundary 'plan'`.
- Coordinator governance Rule 14A says one human authorization advances at most
  one boundary.

The release blocker is therefore prompt truth: the generated quick reference is
authoritative to agents, but it lies about the actual boundary model.

## What

Make `specrew start` derive boundary-stop guidance from the same policy model used
by boundary sync and validation.

The generated prompt must teach agents that:

- A lifecycle boundary transition requires human authorization when the relevant
  boundary's policy class is `human-judgment-required`.
- The current default downstream policy treats all canonical lifecycle boundaries
  as human-judgment-required unless explicitly configured otherwise.
- Readiness helpers such as `before-plan` and `after-tasks` may emit warnings
  instead of validation blockers, but they do not authorize skipping the human
  verdict for the next lifecycle boundary.
- `Status: Approved` in feature artifacts must not be written by an agent as a
  substitute for a recorded human verdict.

At every human-judgment boundary, the generated prompt must also make the stop a
human re-entry point, not a bare approval prompt. The coordinator must provide a
compact review packet that lets the human understand the past and shape the
future before approving:

```text
## What I just did
Outcome summary, committed evidence, major decisions, assumptions, and any
scope changes.

## What needs your review
Primary artifact links, exact sections to inspect, risky/high-impact decisions,
and uncertainties the agent wants the human to notice.

## What happens next
The next lifecycle phase, what it will produce, whether it writes code or only
planning artifacts, and what decisions become harder to change after approval.

## Discussion prompts
One to three targeted questions that invite the human to refine the outcome or
future direction. If there is no specific dilemma, ask a general improvement
question such as: "Is there anything in this spec that should be corrected,
expanded, or constrained before I plan from it?"

## What I need from you
Approve as-is, approve with added instructions, send back with changes, or
discuss first.
```

The intent is to reduce the AI's decision surface by making boundary stops a
short human/agent conversation. The user should be able to approve quickly when
the packet is clear, but the default affordance must also make it natural to add
constraints, question choices, or discuss a dilemma before the next phase locks
in more downstream work.

This proposal is intentionally narrower than Proposal 150. Proposal 150's "next
authorized action only" block is still the stronger long-term guard. This small
fix removes the actively wrong generated instructions so beta3 can be tested
without repeating the beta1/beta2 boundary bypass.

This proposal intentionally absorbs the release-critical part of Proposal 151 for
beta3. Proposal 151 can still generalize the handoff evidence detector later, but
this feature must not ship a stop-at-the-right-gate fix that still leaves the
human with a thin or passive approval prompt.

## Functional Requirements

- **FR-001**: `specrew start` MUST NOT generate text claiming that only
  `before-implement`, `review-signoff`, `iteration-closeout`, and
  `feature-closeout` hard-block when `.specrew/config.yml` marks earlier
  boundaries as `human-judgment-required`.
- **FR-002**: Generated `last-start-prompt.md` MUST describe boundary
  authorization from `boundary_enforcement.policy_classes`, not from a hard-coded
  four-gate list.
- **FR-003**: Generated instructions MUST NOT tell the coordinator to continue
  automatically from clarify through `before-plan`, `plan`, `tasks`, and
  `after-tasks` when `clarify -> plan` and `plan -> tasks` are human-judgment
  boundaries.
- **FR-004**: Generated instructions MUST require a boundary stop after clarify
  before plan generation unless autonomous mode or an explicit recorded
  authorization exists for `clarify -> plan`.
- **FR-005**: Generated instructions MUST distinguish readiness status from human
  approval. Agent-authored readiness repairs may use wording such as
  `Ready for Planning`, but MUST NOT set `Status: Approved` without a recorded
  human verdict.
- **FR-006**: Sync command docs, coordinator governance, and generated start
  prompt MUST agree on the same boundary vocabulary and authorization semantics.
- **FR-007**: Regression tests MUST fail if a generated start prompt contains the
  beta2-bad phrases `only gate that HARD-BLOCKS` or `continue automatically
  through` in a way that bypasses human-judgment boundaries.
- **FR-008**: Generated instructions MUST define the canonical human-judgment
  boundary stop as a human re-entry packet, not only an approval request.
- **FR-009**: Every human re-entry packet MUST summarize the past outcome,
  identify review targets, preview the next phase, and ask for approve /
  approve-with-instructions / send-back / discuss-first input.
- **FR-010**: Every human re-entry packet MUST include one to three proactive
  discussion prompts. Prompts SHOULD be specific when there is a known decision,
  tradeoff, package choice, risk, or uncertainty; otherwise they MUST ask a
  general improvement question.
- **FR-011**: The generated prompt MUST encourage short discussion before
  continuing when the human wants to refine scope, validate a tradeoff, or add
  instructions. It MUST NOT frame approval as the only normal path.
- **FR-012**: Structured verdict menus, when available, MUST include or preserve
  an affordance for discussion / free-form feedback before continuation.

## Acceptance Criteria

- **AC1**: In a fresh greenfield project generated from the fixed build,
  `.specrew/last-start-prompt.md` lists or summarizes all
  `human-judgment-required` boundaries from `.specrew/config.yml`.
- **AC2**: The generated prompt no longer contains the statement that
  `Test-SpecrewBoundaryAuthorization` hard-blocks only four lifecycle points.
- **AC3**: The generated prompt no longer instructs agents to auto-run from
  clarify through plan/tasks without a human boundary verdict.
- **AC4**: The generated prompt includes a clear rule that `clarify -> plan`
  requires human authorization under the default policy.
- **AC5**: A regression test seeded with the v0.30.0-beta2 bad prompt fails
  before the fix and passes after the fix.
- **AC6**: A smoke run for a simple greenfield feature stops after clarify with a
  three-section handoff asking for plan approval, and does not create a
  substantive `plan.md` until the human approves.
- **AC7**: If an agent changes `spec.md` to `Status: Approved` without a matching
  `.squad/decisions.md` or `boundary_enforcement.verdict_history` approval, the
  validator or prompt-regression test catches the contradiction.
- **AC8**: A generated boundary-stop prompt includes the five human re-entry
  sections: `What I just did`, `What needs your review`, `What happens next`,
  `Discussion prompts`, and `What I need from you`.
- **AC9**: A generated clarify-to-plan stop includes at least one proactive
  question inviting the human to improve or constrain the spec before planning.
- **AC10**: A generated stop for a known technical choice or dilemma asks a
  targeted question about that choice rather than only asking for generic
  approval.
- **AC11**: A boundary handoff that only says "approve to continue" without
  review targets, next-phase preview, and a discussion affordance is treated as
  non-compliant by tests or reviewer instructions.
- **AC12**: The beta3 smoke console gives enough summary for the human to decide
  whether to discuss or approve before opening artifacts, while still providing
  targeted artifact links for inspection.

## Implementation Scope

Expected touch points:

| Area | Files |
| --- | --- |
| Start prompt quick reference | `scripts/specrew-start.ps1` |
| Coordinator lifecycle rule text | `extensions/specrew-speckit/squad-templates/coordinator/specrew-governance.md` and deployed mirrors if needed |
| Boundary policy source | `.specrew/config.yml`, `shared-governance.ps1` helpers if a read helper is needed |
| Regression tests | `tests/integration/start-command.ps1`, `tests/integration/launch-mode-boundary-enforcement.tests.ps1`, or a focused new prompt-generation test |
| Human re-entry handoff text | `scripts/specrew-start.ps1`, coordinator governance template, role charters if they carry conflicting stop wording |
| Smoke evidence | downstream beta smoke project similar to `SpecrewSmoke-F051-beta2` |

Implementation should avoid manual duplication of the boundary list where a
helper can render it from policy. If a hard-coded fallback remains necessary, it
must include the full canonical boundary set and be covered by a test that
compares it to `Get-SpecrewCanonicalBoundaryTypes`.

## Out of Scope

- Full Proposal 150 "next authorized action only" implementation
- Hook-based runtime enforcement from Proposal 105
- Broad historical handoff evidence migration from Proposal 151. This proposal
  does own the beta3 human re-entry packet contract for newly generated prompts.
- Redesigning Spec Kit phases or adding a new lifecycle boundary
- Changing tool-call approval defaults
- Fixing Copilot `write EOF` or delayed credit accounting

## Required Tests

At minimum, add tests that create or inspect a generated `last-start-prompt.md`
and assert:

- It does not contain `only gate that HARD-BLOCKS`.
- It does not contain the beta2 auto-chain instruction:
  `continue automatically through` plus `speckit.plan` plus `speckit.tasks`.
- It includes `clarify -> plan` or an equivalent explicit plan-boundary
  authorization statement.
- It includes all boundaries configured as `human-judgment-required`.
- It does not instruct agents to set `Status: Approved` as a planning-readiness
  workaround without human verdict evidence.
- It contains the five human re-entry packet section names.
- It instructs agents to ask one to three discussion prompts before asking the
  human to continue.
- It rejects or flags a stop handoff that lacks review targets, next-step preview,
  or discussion affordance.

Add one validator or unit-level check for the artifact-status semantics if the
existing validator already has access to `spec.md`, `.squad/decisions.md`, and
`start-context.json`.

## Smoke Script Expectations

The beta3 smoke should replay the same shape as beta2:

1. Install the beta in a clean shell.
2. Create a fresh project.
3. Run `specrew start --host copilot "Create a 0MQ binding for Dapr"`.
4. Answer the same intake questions:
   - `.NET / C#`
   - both input and output
   - simple one-way messaging
5. Let specify and clarify complete.
6. Expected stop: the coordinator emits the canonical human re-entry packet at
   the `clarify` or `clarify -> plan` boundary. The packet summarizes the
   clarified spec, links to `spec.md`, identifies the exact sections to inspect,
   previews that the next phase will produce planning artifacts rather than code,
   and asks at least one proactive question such as whether the spec should be
   corrected, constrained, or discussed before planning.
7. Expected disk state before approval:
   - `spec.md` exists and is committed.
   - `plan.md` is absent or still only a scaffold/template that is not claimed
     as complete.
   - `.squad/decisions.md` has no fabricated human approval.
8. The human can answer with approval, approval plus instructions, send-back
   feedback, or a discussion response. Only approval or approval-with-instructions
   may authorize the next boundary.
9. After the human approves planning, the agent may run before-plan and plan,
   then must stop again at the next human-judgment boundary according to policy
   with the same human re-entry packet shape.

## Sequencing

This proposal is the immediate beta3 blocker. Recommended order:

1. Implement Proposal 154.
2. Tag and publish `v0.30.0-beta3`.
3. Rerun the v0.30.0-beta2 smoke scenario.
4. Only after the boundary-auth + human re-entry smoke passes, continue with
   Proposal 151 evidence-detection generalization and Proposal 150 follow-up
   hardening.

Proposal 151 can still be implemented next for historical evidence detection and
broader validator backstops, but Proposal 154 now owns the release-critical
new-prompt behavior: stop at the right boundary and make that stop a meaningful
human discussion point.

## Cross-References

- file:///C:/Dev/Specrew/scripts/specrew-start.ps1
- file:///C:/Dev/Specrew/.specrew/config.yml
- file:///C:/Dev/Specrew/.specify/extensions/specrew-speckit/commands/speckit.specrew-speckit.sync-plan.md
- file:///C:/Dev/Specrew/extensions/specrew-speckit/squad-templates/coordinator/specrew-governance.md
- file:///C:/Dev/Specrew/proposals/065-launch-mode-boundary-enforcement.md
- file:///C:/Dev/Specrew/proposals/150-agent-support-hardening-bundle.md
- file:///C:/Dev/Specrew/proposals/151-boundary-handoff-contract-unification.md

## Status History

- 2026-06-01: Drafted after v0.30.0-beta2 Copilot/Squad smoke repeated the beta1
  boundary-bypass class: generated prompt authorized automatic planning even
  though policy and sync commands require human authorization for `clarify -> plan`.
- 2026-06-01: Amended after maintainer review to make boundary stops human
  re-entry points. The fix now requires review summaries, targeted artifact
  guidance, next-phase previews, and proactive discussion prompts before approval.
