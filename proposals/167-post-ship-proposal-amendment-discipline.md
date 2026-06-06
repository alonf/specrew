---
proposal: 167
title: Post-Ship Proposal Amendment Discipline
status: candidate
phase: phase-2
estimated-sp: 3-5
priority-tier: 1
type: governance
discussion: surfaced 2026-06-06 after a Proposal 163/166 update raised the risk that editing already-implemented proposals can either hide new work or cause a future Crew to reimplement old shipped scope
composes-with:
  - 033  # Specrew Governance CLI
  - 073  # Review Evidence Integrity
  - 091  # Technology Debt Control
  - 145  # Structured Multi-Phase Reviewer
  - 166  # Concurrent Development Hygiene
audience: maintainers, contributors, Crew agents
---

# Post-Ship Proposal Amendment Discipline

## Why

Specrew proposals are both planning inputs and historical records. That dual role becomes dangerous
after a proposal ships.

If a shipped proposal is edited as if the new text had always been there, two failure modes appear:

1. **Silent unimplemented scope**: the new requirement sits inside an old proposal, but no active
   feature, task, or review gate owns it.
2. **Regression through reimplementation**: a future Crew treats the whole old proposal as current
   execution truth and reimplements already-shipped behavior, possibly damaging compatibility.

The problem is not theoretical. Specrew frequently amends proposals while parallel features are in
flight. Some proposals are still candidates and safe to edit directly; others are shipped and must
be treated as immutable historical baselines except for explicitly marked deltas.

The rule should be simple: **implemented proposals are historical records; new behavior requires a
delta record.**

## What

Add proposal-governance rules and validation support for post-ship edits.

### Pillar 1: Proposal Mutability Classes

Proposal files get an explicit mutability interpretation based on status:

| Status | Allowed normative edits |
| --- | --- |
| `candidate` | Free evolution; not yet execution truth. |
| `draft` | Controlled evolution; changes should be reflected before `/speckit.specify`. |
| `active` | Delta-only unless coordinated with the active feature state. |
| `shipped` | Historical baseline; no unmarked normative edits. |
| `superseded` | Historical baseline plus supersession pointer. |
| `withdrawn` | Historical record; corrections only. |

### Pillar 2: Post-Ship Amendment Section

Any normative change to a shipped or superseded proposal must be recorded in a dedicated
`## Post-Ship Amendments` section, never silently woven into the original `What`, `FR`, `Effort`,
or acceptance sections.

Each amendment entry must include:

| Field | Purpose |
| --- | --- |
| `amendment-id` | Stable local id, for example `A1`. |
| `date` | Date the delta was recorded. |
| `status` | `proposed`, `accepted-unimplemented`, `active`, `implemented`, `rejected`, or `superseded`. |
| `delta-summary` | What changed, stated as a delta from shipped behavior. |
| `implementation-owner` | Follow-up proposal, feature, debt entry, or `none-yet`. |
| `preserve` | Shipped behavior that must not regress. |
| `tests-required` | Characterization or regression tests needed before implementation. |

### Pillar 3: New Proposal Preferred for Behavior Changes

If an amendment changes runtime behavior, architecture, user flow, test obligations, or validator
rules, the default path is a new proposal or a clearly linked follow-up feature.

Allowed shipped-proposal direct edits without an amendment:

- Typo fixes.
- Broken link fixes.
- Errata that clarify historical meaning without changing scope.
- Adding `superseded-by` metadata that points to a new proposal.

Everything else must be delta-tracked.

### Pillar 4: Implementation Must Be Delta-Based

The Crew must not implement directly from the full body of a shipped proposal. For shipped
proposals, implementation input is:

1. The active spec/plan/tasks.
2. The specific post-ship amendment or superseding proposal.
3. The compatibility list of shipped behavior to preserve.

The plan must include a "delta from shipped behavior" section when it is based on a shipped
proposal amendment.

### Pillar 5: Review and Validator Guards

Add lightweight enforcement:

- Proposal-diff checker: warns when a shipped/superseded proposal changes normative headings
  outside `Post-Ship Amendments`.
- Review checklist: if a task references a shipped proposal, reviewer verifies that the work is
  delta-based and preserves shipped behavior.
- Closeout evidence: implementation of a post-ship amendment must link back to the amendment id
  and mark it implemented or superseded.

### Pillar 6: Index and Dashboard Surfacing

The proposal index and status surfaces should show when a shipped proposal has unimplemented
post-ship amendments. This prevents accepted deltas from disappearing inside historical text.

Example:

```text
073 Review Evidence Integrity - shipped; post-ship amendments: A1 accepted-unimplemented
```

## Functional Requirements

- **FR-001**: Specrew MUST treat shipped and superseded proposals as historical records whose
  normative shipped text is not silently rewritten.
- **FR-002**: Normative changes to shipped/superseded proposals MUST be recorded in a structured
  `Post-Ship Amendments` section or moved to a new/superseding proposal.
- **FR-003**: Each post-ship amendment MUST record status, delta summary, implementation owner,
  preserve list, and tests required.
- **FR-004**: Implementation planning from a shipped proposal amendment MUST be delta-based and
  must include shipped-behavior preservation requirements.
- **FR-005**: Review-signoff MUST verify that post-ship amendment implementation did not
  reimplement unrelated shipped scope.
- **FR-006**: Governance validation SHOULD warn when a shipped/superseded proposal changes
  normative sections outside `Post-Ship Amendments`.
- **FR-007**: Proposal index/status rendering SHOULD surface unimplemented post-ship amendments.

## Out of Scope

- Rewriting historical proposals into the new format.
- Blocking typo/link/errata fixes.
- Full semantic diffing of proposal meaning.
- Requiring every candidate/draft proposal change to use amendments.

## Effort

- **Iteration 1 (~3-5 SP)**:
  - Document the proposal mutability policy.
  - Add the amendment template.
  - Add a lightweight proposal-diff validator warning for shipped/superseded normative edits.
  - Update reviewer guidance to require delta-based implementation checks.
  - Add tests for shipped proposal amendment detection.

## Phase Placement

Phase 2, priority tier 1.

This is small but important methodology hardening. It prevents governance artifacts from becoming a
source of regression while keeping proposals useful as living discussion surfaces before they ship.

## Open Questions

1. Should normative shipped-proposal edits outside `Post-Ship Amendments` be a soft warning first
   or a hard failure immediately?
2. Should the amendment section be allowed on `active` proposals, or should active proposals use
   the normal feature amendment mechanism only?
3. Should `implemented` amendments remain in the original proposal, or should they be copied into a
   generated amendment index?

## Risks

- **Overhead on tiny corrections**: mitigate by exempting typo/link/errata fixes.
- **False confidence**: a structural amendment section does not prove behavior changed correctly;
  Proposal 145 review evidence still has to verify code and tests.
- **Amendment backlog**: accepted but unimplemented amendments can pile up. Mitigate by surfacing
  them in index/status output.

## Cross-References

- [033 Specrew Governance CLI](033-specrew-governance-cli.md) can expose amendment status.
- [073 Review Evidence Integrity](073-review-evidence-integrity.md) supplies the form-vs-meaning
  precedent.
- [091 Technology Debt Control](091-tech-debt-control.md) can record amendment backlog as debt
  when accepted deltas age without implementation.
- [145 Structured Multi-Phase Reviewer](145-structured-multi-phase-reviewer.md) verifies that
  implementation claims match the delta and preserve shipped behavior.
- [166 Concurrent Development Hygiene](166-concurrent-development-hygiene.md) is adjacent because
  both prevent hidden drift between governance files and implementation reality.

## Status History

- 2026-06-06: Created as a candidate after maintainer concern that editing already-implemented
  proposals can either hide new work or cause future reimplementation/regression.
