---
proposal: 174
title: Boundary Variance Disclosure and Artifact Reconciliation
status: candidate
phase: phase-2
estimated-sp: 8-13
priority-tier: 1
type: lifecycle-governance
discussion: surfaced 2026-06-08 during Feature 174 dogfooding after tasks exposed a material capacity variance from the approved plan; maintainer clarified that later stages can legitimately disprove earlier assumptions, but the variance must be surfaced to the human and reconciled into artifacts before the lifecycle advances. Amended 2026-06-13 to make the agility rule explicit: the Crew may investigate and recommend implementation-time adaptation, but a material change to approved scope, design, workshop decisions, plan, test strategy, or acceptance evidence needs a human variance verdict before it becomes authoritative.
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
4. whether the human accepts the variance or sends the Crew back;
5. which changes are small enough to continue as normal implementation
   judgment.

Reviews and retros are too late for this. If a material variance is discovered
at `plan -> tasks`, `tasks -> before-implement`, or implementation closeout, the
human should see it at that gate, before the next lifecycle layer treats the new
shape as normal.

The goal is not to freeze the Crew into waterfall behavior. Specrew should stay
agile: implementation can reveal better facts than the workshop, design
analysis, or plan had. The safety rule is that learning is allowed immediately,
but authority changes only after human acceptance and artifact reconciliation.

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

### Implementation-Time Adaptation Model

The Crew classifies implementation-time discoveries before deciding whether to
continue, record, or stop for a human variance verdict:

| Class | Meaning | Required action |
| --- | --- | --- |
| `non-material adaptation` | Local implementation choice that stays inside the approved spec, design, workshop decisions, plan, task traceability, test strategy, and acceptance evidence. | Continue. Mention in normal implementation notes only if useful. |
| `material variance` | Discovery changes, invalidates, narrows, or reinterprets an approved artifact or human decision. | Stop at the nearest safe point, prepare the variance report, recommend reconciliation, and require a human variance verdict before treating the change as authoritative. |
| `blocking contradiction` | Continuing would risk building against a known-wrong approved decision, unsafe assumption, impossible plan, or disputed requirement. | Pause implementation until the human chooses revise, accept variance, split scope, defer, or restore the prior direction. |

The Crew may research, prototype, and recommend a material change quickly. It may
also prepare the artifact edits that would reconcile that change. It must not
merge those edits into the authoritative flow, claim conformance, or advance the
next lifecycle boundary until the human accepts the variance or gives another
explicit direction.

## Core Rule

Approved artifacts remain authoritative until a later gate explicitly records
and reconciles a material variance.

The Crew may discover variance, recommend a reconciliation, and prepare artifact
edits. It must not silently launder the variance into later artifacts as if the
original approval already covered it.

Agility is preserved by allowing the Crew to find and explain better facts as
soon as they appear. Governance is preserved by requiring explicit human
acceptance before a material change becomes the new source of truth.

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
- implementation-time discovery that contradicts a workshop, design-analysis,
  plan, task, dependency, or evidence assumption the human already approved;
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

### Implementation-time workshop contradiction

Prior assumption: the workshop selected direct transcript parsing as the
approved implementation path.

Observed reality: live host evidence shows the transcript format is unstable and
cannot safely support the chosen flow without a fallback ladder.

Reconciliation: continue investigation, but before the fallback ladder becomes
the authoritative design, present the material variance, name the host evidence,
update the workshop/design artifact and `workshop-decisions.yml`, and ask the
human to accept the revised path or send the Crew back to redesign.

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
- **AC9**: Gate guidance distinguishes `non-material adaptation`,
  `material variance`, and `blocking contradiction`, so agents keep ordinary
  implementation agility while surfacing authority-changing discoveries.
- **AC10**: An implementation-time discovery that contradicts an approved
  workshop/design/plan/test assumption requires a human variance verdict before
  the changed direction is treated as conforming work.
- **AC11**: Tests or fixtures cover both sides of the adaptation boundary: a
  harmless implementation choice continues without a variance block, while a
  design/workshop contradiction produces a variance report and waits for human
  acceptance.

## Out Of Scope

- Treating every implementation detail change as a material variance.
- Replacing review-signoff, retro, or drift logs.
- Allowing agents to bypass prior approvals by claiming "reality changed"
  without evidence and human acceptance.
- Automatically editing approved artifacts without a recorded variance verdict.
- Requiring a full re-run of all earlier lifecycle stages for every accepted
  variance; the reconciliation should be proportional to impact.
- Blocking ordinary implementation judgment that remains inside approved
  artifacts and does not change human-approved meaning.

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
7. Add a small adaptation classifier to gate guidance so the Crew can continue
   through non-material choices, surface material variance, and pause on
   blocking contradictions.
8. Add a regression fixture for implementation-time contradiction of a
   workshop/design decision, proving it cannot be silently normalized into the
   implementation or review.

Adoption can warn first and hard-block after several features exercise the
contract. The important immediate behavior is that variance becomes impossible
to hide in narrative closeout text.

## Status History

- 2026-06-08: Candidate created after Feature 174 dogfooding exposed a material
  capacity variance after an approved plan.
- 2026-06-13: Amended to make the intended agility posture explicit:
  implementation-time learning is allowed and encouraged, but material changes
  to approved assumptions require human variance acceptance before they become
  authoritative.
