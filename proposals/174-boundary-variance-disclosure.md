---
proposal: 174
title: Boundary Variance Disclosure and Artifact Reconciliation
status: candidate
phase: phase-2
estimated-sp: 8-13
priority-tier: 1
type: lifecycle-governance
discussion: surfaced 2026-06-08 during Feature 174 dogfooding after tasks exposed a material capacity variance from the approved plan; maintainer clarified that later stages can legitimately disprove earlier assumptions, but the variance must be surfaced to the human and reconciled into artifacts before the lifecycle advances
composes-with:
  - 007  # Substantive Interaction Model
  - 021  # Bypass Detector
  - 142  # State-truth integrity validator
  - 145  # Structured reviewer evidence discipline
  - 156  # Workshop decision producer manifest
  - 163  # Code implementation lens rules
  - 154  # Boundary authorization prompt truth
  - 155  # Typed boundary gate packets
  - 167  # Post-ship proposal amendment discipline
  - 175  # Supplemental domain/platform analysis packs
audience: maintainers, Crew agents, reviewers
---

# Boundary Variance Disclosure and Artifact Reconciliation

## Why

Specrew intentionally approves artifacts in layers: spec, design-analysis, plan,
tasks, implementation, review, and retro. Each approved layer carries assumptions
forward. Later work often tests those assumptions against reality.

Sometimes the later stage proves that the earlier assumption was wrong or
incomplete, even when the Crew followed the approved decision in good faith:

- planning assumes 8-13 SP, but task decomposition shows 35 SP;
- design-analysis chooses a component boundary, but implementation discovers a
  dependency or host behavior that requires a different cut;
- tasks assume a test strategy, but code reality shows a missing fixture,
  unmockable surface, or stronger end-to-end evidence requirement;
- review finds the code implemented the right user outcome but not exactly the
  planned internal shape.

That is not necessarily agent drift. It can be legitimate learning. But today
the lifecycle does not have a first-class place at every gate to say:

1. what prior approved assumption changed;
2. why the new evidence changed it;
3. what source artifact must now be updated;
4. whether the human accepts the variance or sends the Crew back.

Reviews and retros are too late for this. If a material variance is discovered
at `plan -> tasks`, `tasks -> before-implement`, or implementation closeout, the
human should see it at that gate, before the next lifecycle layer treats the new
shape as normal.

## What

Add a required **Boundary Variance Report** section to every human-judgment gate
packet and typed gate artifact.

The section is short when no variance exists, but it must be explicit:

```text
## Variance Since Last Approved Artifact

- Status: none
```

When a material variance exists, the gate packet must record:

```text
## Variance Since Last Approved Artifact

- Status: material variance
- Prior approved assumption:
- Observed reality:
- Why this happened:
- Evidence:
- Impact:
- Proposed reconciliation:
- Artifacts to update:
- Human decision needed:
```

The human verdict must decide the variance, not only the next boundary:

- accept the variance and update artifacts;
- send back to revise the previous stage;
- split scope or iteration;
- defer the variance explicitly with a tracked follow-up;
- reject the variance and restore the prior assumption.

## Core Rule

Approved artifacts remain authoritative until a later gate explicitly records
and reconciles a material variance.

The Crew may discover variance, recommend a reconciliation, and prepare artifact
edits. It must not silently launder the variance into later artifacts as if the
original approval already covered it.

## Material Variance

A variance is material when it changes, invalidates, or meaningfully narrows any
of the following:

- approved scope, FR/SC interpretation, or user story coverage;
- selected design option, architectural boundary, or component responsibility;
- plan capacity, iteration split, or delivery sequencing;
- task traceability, task count, or evidence obligations;
- implementation approach compared with design-analysis or plan;
- selected workshop decision records, including the Proposal 156
  `workshop-decisions.yml` manifest;
- test strategy, reviewer evidence, or acceptance proof;
- gate authority, human approval scope, or artifact source of truth.

Small wording improvements, lint-only changes, and mechanical formatting changes
are not material unless they change one of those meanings.

## Gate Examples

### Plan to tasks

Prior assumption: plan estimates a single 8-13 SP implementation slice.

Observed reality: task decomposition shows 35 SP.

Reconciliation: present the variance at the gate, propose a multi-iteration
split, update `tasks.md` and any capacity notes, and ask the human whether the
split is accepted or planning should be sent back.

### Tasks to before-implement

Prior assumption: iteration 001 includes a 19 SP slice near the cap.

Observed reality: maintainer decides that near-cap iterations are too tight and
wants the same scope regrouped into about three 11 SP iterations.

Reconciliation: update `tasks.md`, rerun traceability, and present the changed
iteration structure as an accepted/send-back decision.

### Implementation to review

Prior assumption: `ValidationEngine` stays pure.

Observed reality: implementation proves the engine must call targeted accessors
because the data is predictable and too large to pass through the manager.

Reconciliation: mark the design variance, update design-analysis or a design
delta artifact, update tests to prove the new boundary, and ask for acceptance
before review treats the implementation as conforming.

## Artifact Contract

Each boundary variance report must be stored with the typed gate packet when
typed packets are available (Proposal 155). It should also be reflected in the
source artifact that becomes authoritative after acceptance.

Examples:

- capacity variance found during tasks updates `tasks.md` and, when needed,
  `plan.md` capacity notes;
- implementation design variance updates `design-analysis.md`, a design-delta
  artifact, `workshop-decisions.yml`, or the review `design-code-trace.yml`;
- scope variance updates `spec.md`, task traceability, or a follow-up proposal;
- workshop-decision variance updates the source workshop/design artifact and the
  corresponding `workshop-decisions.yml` decision record, or records an
  accepted exception that Proposal 145 can verify in
  `workshop-decision-conformance.yml`;
- deferred variance creates an explicit proposal, issue, or backlog item and
  records why deferral is safe.

The report is not enough by itself. If the human accepts the variance, the
artifact layer must be reconciled so future sessions reconstruct the new truth
from files, not from chat memory.

## Relationship To Proposal 145

This proposal is related to Proposal 145 but not a replacement for it.

Proposal 145 asks whether review and gate evidence is structurally trustworthy:
claims map to evidence, phases are covered, design/code traces exist, and
unsupported claims fail validation. It also verifies selected workshop decisions
from `workshop-decisions.yml` through `workshop-decision-conformance.yml`.

This proposal asks a different lifecycle question: did later evidence invalidate
a previously approved assumption, and was that variance disclosed and accepted
before the lifecycle advanced?

145 can validate the shape and evidence of a variance report. It should not own
the semantic rule that approved artifacts remain authoritative until a variance
is accepted and reconciled.

## Acceptance Criteria

- **AC1**: Every human-judgment gate packet includes a
  `Variance Since Last Approved Artifact` section with either `none` or a
  populated material-variance record.
- **AC2**: A material variance record names the prior approved assumption,
  observed reality, why it happened, evidence, impact, proposed reconciliation,
  artifacts to update, and the human decision needed.
- **AC3**: Boundary advancement is blocked, or at least warns during adoption,
  when a material variance is present but no human variance verdict is recorded.
- **AC4**: Accepted material variance updates the relevant authoritative
  artifacts before the next stage treats the changed shape as normal.
  When the variance changes a selected workshop decision, this includes both the
  human-readable source artifact and the corresponding `workshop-decisions.yml`
  decision record.
- **AC5**: Rejected or send-back variance leaves the prior artifact authoritative
  and records what must be revised before retrying the gate.
- **AC6**: Deferred variance creates a tracked follow-up and records why deferral
  is safe for the current boundary.
- **AC7**: Gate-local preflight and Proposal 145 review consume variance reports
  as evidence inputs, but do not replace the human variance verdict.
- **AC8**: Regression coverage includes the Feature 174 capacity example: an
  approved plan followed by a larger task decomposition must surface a material
  variance and require artifact reconciliation.

## Out Of Scope

- Treating every implementation detail change as a material variance.
- Replacing review-signoff, retro, or drift logs.
- Allowing agents to bypass prior approvals by claiming "reality changed"
  without evidence and human acceptance.
- Automatically editing approved artifacts without a recorded variance verdict.
- Requiring a full re-run of all earlier lifecycle stages for every accepted
  variance; the reconciliation should be proportional to impact.

## Implementation Notes

First slice:

1. Add the variance section to typed gate packet templates.
2. Update gate rendering instructions so packets always state `none` or material
   variance explicitly.
3. Add a lightweight validator that detects missing variance sections and
   material variance records without a human decision.
4. Add reconciliation checks for changed workshop decisions so accepted
   variance updates both source artifacts and `workshop-decisions.yml`.
5. Add methodology text explaining the difference between agent drift and
   legitimate assumption variance.
6. Add regression fixtures for the plan-capacity and design-code variance
   patterns.

Adoption can warn first and hard-block after several features exercise the
contract. The important immediate behavior is that variance becomes impossible
to hide in narrative closeout text.
