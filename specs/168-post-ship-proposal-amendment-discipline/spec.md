# Feature Specification: Post-Ship Proposal Amendment Discipline

**Feature Branch**: `168-post-ship-proposal-amendment-discipline`
**Created**: 2026-06-06
**Status**: Draft
**Input**: User description: "Implement Proposal 167: Post-Ship Proposal Amendment Discipline. Start from file:///C:/Dev/Specrew-post-ship-amendment-discipline/proposals/167-post-ship-proposal-amendment-discipline.md. Follow Specrew lifecycle strictly. Do not jump to code. Begin at specify, carry the proposal as input, and stop at each human-judgment boundary with the standard packet. Important guardrail: implementation must be delta-based and must not rewrite or reimplement shipped proposal behavior."
**Source Proposal**: file:///C:/Dev/Specrew-post-ship-amendment-discipline/proposals/167-post-ship-proposal-amendment-discipline.md

## Scope Guardrail

This feature implements Proposal 167 as a delta-only governance hardening slice. It MUST add proposal amendment discipline without rewriting historical shipped proposal bodies or reimplementing behavior already delivered by shipped proposals. Any plan or implementation work that references a shipped proposal must state the specific delta, the shipped behavior to preserve, and the evidence that unrelated shipped scope was not reimplemented.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Maintainers Can Amend Historical Proposals Safely (Priority: P1)

As a Specrew maintainer, I need shipped and superseded proposals to be treated as historical records with clearly marked post-ship deltas so new requirements cannot disappear inside old shipped text.

**Why this priority**: This is the core failure mode from Proposal 167: silent unimplemented scope and regression-prone reimplementation both begin when shipped proposal text is edited as if the new requirement had always existed.

**Independent Test**: Review the proposal discipline documentation and amendment template, then verify that shipped and superseded proposal changes are directed to `Post-Ship Amendments` while candidate and draft proposals can still evolve normally.

**Acceptance Scenarios**:

1. **Given** a proposal whose front matter status is `shipped`, **When** a maintainer needs to add a new normative requirement, **Then** the guidance requires a structured `Post-Ship Amendments` entry or a new/superseding proposal instead of weaving the requirement into the historical body.
2. **Given** a proposal whose front matter status is `candidate`, **When** the proposal evolves before execution, **Then** the guidance allows normal body edits without requiring a post-ship amendment record.
3. **Given** a shipped or superseded proposal needs a typo fix, broken link fix, errata note, or `superseded-by` metadata, **When** the maintainer edits it, **Then** the guidance allows the correction without requiring an amendment entry because shipped behavior is not changing.
4. **Given** a post-ship amendment entry, **When** it is reviewed, **Then** the entry exposes amendment id, date, status, delta summary, implementation owner, shipped behavior to preserve, and tests required.

---

### User Story 2 - Validator Warns About Unsafe Normative Edits (Priority: P1)

As a reviewer or release maintainer, I need governance validation to warn when a shipped or superseded proposal changes normative sections outside the approved amendment area so unsafe edits are caught before merge.

**Why this priority**: Documentation policy alone is easy to miss. A lightweight validator warning creates an automated tripwire while avoiding the false precision of full semantic diffing.

**Independent Test**: Run focused proposal-diff validation fixtures covering a shipped proposal body edit, an amendment-section edit, an allowed typo/link correction, and a candidate-proposal edit.

**Acceptance Scenarios**:

1. **Given** a shipped proposal whose `What`, requirements, acceptance, or effort sections changed outside `Post-Ship Amendments`, **When** governance validation runs, **Then** it emits a warning that identifies the proposal, changed normative area, and expected amendment path.
2. **Given** a shipped proposal whose only normative delta is recorded under `Post-Ship Amendments`, **When** governance validation runs, **Then** it does not warn about that amendment solely because the proposal is shipped.
3. **Given** a candidate or draft proposal with normal body edits, **When** governance validation runs, **Then** it does not apply shipped-proposal amendment warnings.
4. **Given** a shipped proposal with only typo, broken-link, errata, or supersession-pointer changes, **When** governance validation runs, **Then** it does not produce a false shipped-normative-edit warning.

---

### User Story 3 - Review Signoff Enforces Delta-Based Implementation (Priority: P1)

As a Specrew reviewer, I need review guidance to verify that implementation from shipped-proposal amendments is delta-based and preserves shipped behavior so old shipped scope is not reimplemented accidentally.

**Why this priority**: Proposal 167 explicitly warns that a future Crew can treat an old proposal as current execution truth and damage compatibility by reimplementing delivered behavior.

**Independent Test**: Inspect reviewer guidance and review checklist outputs for a task that references a shipped proposal amendment, then confirm the reviewer must identify the amendment id, preserve list, tests required, and evidence that unrelated shipped behavior was not reimplemented.

**Acceptance Scenarios**:

1. **Given** an implementation task references a shipped proposal or post-ship amendment, **When** review signoff is prepared, **Then** the reviewer checklist requires amendment-id or superseding-proposal evidence plus a shipped-behavior preservation check.
2. **Given** implementation claims to satisfy a post-ship amendment, **When** review evaluates the change, **Then** review evidence must compare the delivered delta against the amendment rather than the whole shipped proposal body.
3. **Given** the implementation modifies code originally shipped by an older proposal, **When** review evaluates it, **Then** reviewer evidence must state whether shipped behavior was characterized by tests, preserved by regression coverage, or intentionally changed by the active delta.

---

### User Story 4 - Unimplemented Amendments Are Visible in Status Surfaces (Priority: P2)

As a maintainer managing proposal backlog, I need proposal index and status views to surface accepted but unimplemented post-ship amendments so deltas do not disappear inside historical proposal files.

**Why this priority**: The amendment record prevents hidden scope only if maintainers can see amendment backlog without opening every proposal.

**Independent Test**: Add a fixture proposal with an `accepted-unimplemented` post-ship amendment and verify proposal index/status rendering includes that amendment status.

**Acceptance Scenarios**:

1. **Given** a shipped proposal has amendment `A1` with status `accepted-unimplemented`, **When** proposal index or status rendering runs, **Then** the output includes the proposal status and the unimplemented amendment id/status.
2. **Given** a shipped proposal has only `implemented`, `rejected`, or `superseded` amendments, **When** proposal index or status rendering runs, **Then** it does not imply unimplemented work remains.
3. **Given** a shipped proposal has multiple unimplemented amendments, **When** proposal index or status rendering runs, **Then** each unimplemented amendment id and status is visible enough for maintainers to route follow-up work.

### Edge Cases

- Proposal status is missing, malformed, or outside the known mutability classes; validation should report the status problem before making a shipped/superseded mutability judgment.
- A proposal is currently `active`; active proposals use the normal active-feature amendment mechanism rather than `Post-Ship Amendments`.
- A shipped proposal has an amendment section with malformed fields; validation should distinguish malformed amendment records from unsafe body rewrites.
- A proposal file is renamed, reformatted, or line-wrapped without normative content changes; validation should avoid claiming full semantic certainty and should keep findings lightweight and explainable.
- A post-ship amendment changes validator rules or reviewer obligations; planning must include the delta-from-shipped-behavior section and preservation requirements before implementation.
- Existing shipped proposals are not migrated in bulk; new rules apply prospectively and to fixtures or directly touched proposals.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Specrew MUST document proposal mutability classes for `candidate`, `draft`, `active`, `shipped`, `superseded`, and `withdrawn` proposal statuses, including the normative edit rules for each class.
- **FR-002**: Specrew MUST define a structured `Post-Ship Amendments` section for shipped and superseded proposals that records `amendment-id`, `date`, `status`, `delta-summary`, `implementation-owner`, `preserve`, and `tests-required`.
- **FR-003**: Specrew MUST define the allowed amendment statuses as `proposed`, `accepted-unimplemented`, `active`, `implemented`, `rejected`, and `superseded`.
- **FR-004**: Specrew MUST state that normative changes to shipped or superseded proposals are allowed only through a `Post-Ship Amendments` entry or a new/superseding proposal, except for typo fixes, broken link fixes, historical errata, and `superseded-by` metadata.
- **FR-005**: Specrew MUST state that behavior-changing amendments default to a new proposal or clearly linked follow-up feature rather than silently editing shipped proposal body text.
- **FR-006**: Implementation planning that uses a shipped proposal amendment MUST include a "delta from shipped behavior" section, the amendment id or superseding proposal reference, shipped behavior to preserve, and required characterization or regression tests.
- **FR-007**: Review-signoff guidance MUST require reviewers to verify that implementation of a shipped proposal amendment is delta-based and does not reimplement unrelated shipped proposal scope.
- **FR-008**: Review evidence for shipped-proposal amendment implementation MUST link back to the amendment id or superseding proposal and identify the shipped behavior preserved by the change.
- **FR-009**: Closeout evidence for an implemented post-ship amendment MUST identify the amendment id and the final amendment disposition, such as `implemented` or `superseded`.
- **FR-010**: Governance validation SHOULD warn when a shipped or superseded proposal has normative section changes outside `Post-Ship Amendments`.
- **FR-011**: Governance validation SHOULD NOT warn solely for allowed typo, broken link, historical errata, supersession-pointer, candidate-proposal, draft-proposal, or valid amendment-section changes.
- **FR-012**: Governance validation SHOULD identify malformed post-ship amendment entries separately from unsafe normative body edits.
- **FR-013**: Proposal index and status surfaces SHOULD show shipped or superseded proposals that contain unimplemented post-ship amendments with amendment id and status.
- **FR-014**: Automated tests MUST cover shipped/superseded normative edit detection, allowed corrections, valid amendment entries, candidate/draft edits, malformed amendment records, reviewer-guidance requirements, and index/status surfacing.
- **FR-015**: This feature MUST NOT rewrite historical shipped proposal bodies, bulk-migrate existing proposals, or reimplement shipped behavior from prior proposal work as part of implementation.

### Traceability & Governance Requirements *(mandatory)*

- **TG-001**: Each user story MUST map to one or more functional requirements.
- **TG-002**: Each requirement MUST identify expected owner role(s).
- **TG-003**: Each requirement MUST identify intended iteration or delivery window.
- **TG-004**: Any known spec/implementation conflict MUST include an explicit reconciliation path.
- **TG-005**: Planning MUST preserve Proposal 167's delta-only guardrail: implementation work may add amendment discipline, validation, review guidance, and status surfacing, but must not rewrite or reimplement shipped proposal behavior.
- **TG-006**: Review MUST include a gap ledger that classifies post-ship amendment behavior as documented, implemented, enforced, observable, and tested.
- **TG-007**: If a shipped proposal is touched during implementation, review MUST record why the touch is allowed and how shipped behavior was preserved.

### Requirement Ownership

| Requirement | Owner Role(s) | Delivery Window |
| --- | --- | --- |
| FR-001 | Spec Steward, Reviewer | Iteration 001 |
| FR-002 | Spec Steward, Reviewer | Iteration 001 |
| FR-003 | Spec Steward, Reviewer | Iteration 001 |
| FR-004 | Spec Steward, Reviewer | Iteration 001 |
| FR-005 | Spec Steward, Planner, Reviewer | Iteration 001 |
| FR-006 | Planner, Reviewer | Iteration 001 |
| FR-007 | Reviewer, Implementer | Iteration 001 |
| FR-008 | Reviewer, Implementer | Iteration 001 |
| FR-009 | Reviewer, Retro Facilitator | Iteration 001 |
| FR-010 | Implementer, Reviewer | Iteration 001 |
| FR-011 | Implementer, Reviewer | Iteration 001 |
| FR-012 | Implementer, Reviewer | Iteration 001 |
| FR-013 | Implementer, Reviewer | Iteration 001 |
| FR-014 | Implementer, Reviewer | Iteration 001 |
| FR-015 | Planner, Implementer, Reviewer | Iteration 001 |
| TG-001 | Planner, Reviewer | Iteration 001 |
| TG-002 | Planner, Reviewer | Iteration 001 |
| TG-003 | Planner, Reviewer | Iteration 001 |
| TG-004 | Spec Steward, Reviewer | Iteration 001 |
| TG-005 | Planner, Implementer, Reviewer | Iteration 001 |
| TG-006 | Reviewer | Iteration 001 |
| TG-007 | Reviewer | Iteration 001 |

### Key Entities *(include if feature involves data)*

- **Proposal Mutability Class**: The governance interpretation of a proposal status that determines whether body text can evolve freely, requires coordination, or is treated as historical baseline.
- **Post-Ship Amendment**: A structured delta record inside a shipped or superseded proposal containing id, date, status, delta summary, owner, preserve list, and tests required.
- **Normative Proposal Section**: A proposal section whose changed text can alter scope, obligations, acceptance, effort, validator behavior, architecture, user flow, review duties, or runtime behavior.
- **Proposal Diff Finding**: A validator observation that a changed shipped or superseded proposal may have unsafe normative edits outside the approved amendment path.
- **Delta-Based Implementation Evidence**: Review and closeout evidence that identifies the amendment being implemented, the shipped behavior preserved, tests required, and final amendment disposition.
- **Amendment Backlog Entry**: An unimplemented post-ship amendment exposed by proposal index or status rendering for maintainer routing.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Proposal discipline documentation explains all six proposal mutability classes and the allowed edit behavior for each class.
- **SC-002**: The amendment template contains all required fields from FR-002 and all allowed statuses from FR-003.
- **SC-003**: A focused validator test fixture for a shipped proposal body edit outside `Post-Ship Amendments` produces a shipped/superseded normative-edit warning.
- **SC-004**: Focused validator fixtures for valid amendment-section edits, candidate/draft proposal edits, typo/link/errata fixes, and supersession-pointer changes do not produce shipped-normative-edit false positives.
- **SC-005**: Reviewer guidance or checklist tests require delta-based review evidence when a task references a shipped proposal or post-ship amendment.
- **SC-006**: Proposal index/status rendering shows a shipped proposal with amendment `A1 accepted-unimplemented` in a human-readable status line.
- **SC-007**: Implementation review confirms the git diff does not rewrite historical shipped proposal bodies or reimplement unrelated shipped proposal behavior.
- **SC-008**: Automated tests cover malformed amendment records separately from unsafe normative body edits.
- **SC-009**: The final review gap ledger explicitly marks post-ship amendment policy as documented, implemented, enforced, observable, and tested, or records any approved defer with rationale.

## Assumptions

- Proposal front matter `status` remains the authoritative source for mutability classification.
- The existing governance validator is the appropriate surface for a lightweight shipped/superseded proposal diff warning.
- The existing proposal index or proposal status renderer is the appropriate surface for unimplemented amendment visibility.
- Initial enforcement is a warning, matching Proposal 167's `SHOULD warn` requirement.
- The implementation will add fixtures and tests rather than editing real shipped proposal bodies to demonstrate unsafe normative edits.
- Active proposals use the normal active-feature amendment flow, not the post-ship amendment section.

## Clarifications

### Session 2026-06-06

- Q: Should shipped/superseded normative edits outside `Post-Ship Amendments` remain a soft warning for this iteration, or should any case become a hard validation failure immediately? A: Warning first, not hard failure yet.
- Q: Should `Post-Ship Amendments` be allowed on `active` proposals, or should active proposals use the normal active-feature amendment mechanism only? A: Active proposals use the active-feature amendment flow, not `Post-Ship Amendments`.
- Q: Should implemented amendments remain in the original proposal and be indexed in place, or should implemented amendment records also be copied into a generated amendment index? A: Implemented amendments remain in the original proposal and are surfaced by index/status; no generated amendment index in this slice.

## Governance Alignment *(mandatory)*

- **Spec Steward**: Owns proposal mutability vocabulary, amendment schema, delta-only scope, and clarification of Proposal 167 open questions.
- **Iteration Facilitator**: Planner coordinates a single small hardening iteration and stops for human authorization before planning, tasking, implementation, review signoff, retro, and closeout.
- **Capacity Model**: 3-5 SP, planned as one iteration with warning-level validation.
- **Drift Signals**: Drift is indicated by any mismatch between Proposal 167, this spec, proposal discipline docs, validator warnings, reviewer guidance, index/status output, tests, and final review evidence.
- **Human Oversight Points**: Human review is required after specify before clarification or planning, after clarify before plan, after plan before tasks, before implementation, at review signoff, at retro, iteration closeout, and feature closeout.
