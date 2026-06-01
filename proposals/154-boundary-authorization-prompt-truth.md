---
proposal: 154
title: Boundary Authorization Prompt Truth
status: draft
phase: phase-2
estimated-sp: 3-5
priority-tier: 1
type: small-fix
discussion: HIGH PRIORITY release-blocking beta2 smoke failure on 2026-06-01. A fresh greenfield Copilot/Squad smoke against v0.30.0-beta2 auto-continued from clarify into plan after the generated lifecycle quick reference said only before-implement, review-signoff, iteration-closeout, and feature-closeout hard-block. This contradicts `.specrew/config.yml` boundary policy, sync command authorization gates, and the Feature 016 one-boundary-at-a-time contract.
composes-with:
  - 007  # Substantive Interaction Model - every boundary stop needs a human-readable handoff
  - 065  # Launch-Mode Boundary Enforcement - boundary authorization mechanics
  - 120  # Broader handoff/backstop validator bundle
  - 142  # State-truth integrity validator
  - 150  # Agent-support hardening - next authorized action only
  - 151  # Handoff contract shape; adjacent but not the authorization truth owner
---

# Boundary Authorization Prompt Truth

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

This proposal is intentionally narrower than Proposal 150. Proposal 150's "next
authorized action only" block is still the stronger long-term guard. This small
fix removes the actively wrong generated instructions so beta3 can be tested
without repeating the beta1/beta2 boundary bypass.

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

## Implementation Scope

Expected touch points:

| Area | Files |
| --- | --- |
| Start prompt quick reference | `scripts/specrew-start.ps1` |
| Coordinator lifecycle rule text | `extensions/specrew-speckit/squad-templates/coordinator/specrew-governance.md` and deployed mirrors if needed |
| Boundary policy source | `.specrew/config.yml`, `shared-governance.ps1` helpers if a read helper is needed |
| Regression tests | `tests/integration/start-command.ps1`, `tests/integration/launch-mode-boundary-enforcement.tests.ps1`, or a focused new prompt-generation test |
| Smoke evidence | downstream beta smoke project similar to `SpecrewSmoke-F051-beta2` |

Implementation should avoid manual duplication of the boundary list where a
helper can render it from policy. If a hard-coded fallback remains necessary, it
must include the full canonical boundary set and be covered by a test that
compares it to `Get-SpecrewCanonicalBoundaryTypes`.

## Out of Scope

- Full Proposal 150 "next authorized action only" implementation
- Hook-based runtime enforcement from Proposal 105
- Broad handoff shape unification from Proposal 151, except where this fix needs
  to avoid contradicting it
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
6. Expected stop: the coordinator emits the canonical three-section boundary
   handoff at the `clarify` or `clarify -> plan` boundary, with links to
   `spec.md` and a clear request for plan approval.
7. Expected disk state before approval:
   - `spec.md` exists and is committed.
   - `plan.md` is absent or still only a scaffold/template that is not claimed
     as complete.
   - `.squad/decisions.md` has no fabricated human approval.
8. After the human approves planning, the agent may run before-plan and plan,
   then must stop again at the next human-judgment boundary according to policy.

## Sequencing

This proposal is the immediate beta3 blocker. Recommended order:

1. Implement Proposal 154.
2. Tag and publish `v0.30.0-beta3`.
3. Rerun the v0.30.0-beta2 smoke scenario.
4. Only after the boundary-auth smoke passes, continue with Proposal 151 and
   Proposal 150 follow-up hardening.

Proposal 151 can still be implemented next if the team chooses to bundle both
small fixes into one beta3 patch, but Proposal 154 is the release-critical
behavioral fix.

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
