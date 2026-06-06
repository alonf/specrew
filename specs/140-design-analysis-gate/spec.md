# Feature Specification: Minimal Design Alternatives / Architecture Intake Gate

**Feature Branch**: `140-design-analysis-gate`  
**Created**: 2026-06-02  
**Status**: Draft  
**Input**: User description: "Specify the next Specrew feature: Minimal Design Alternatives / Architecture Intake Gate, based on Proposal 137."  
**Source Proposal**: file:///C:/Dev/Specrew-design-analysis/proposals/137-design-alternatives-analysis-gate.md

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Review Alternatives Before Planning (Priority: P1)

As a human developer approving Specrew lifecycle work, I need the Crew to stop before plan generation and show meaningful design alternatives so that architecture disagreements are caught before planning turns one approach into downstream tasks.

**Why this priority**: This is the core methodology gap from Proposal 137. Today the approach is often selected implicitly during planning, which makes disagreement expensive because the plan must be rewritten.

**Independent Test**: Run the lifecycle for a substantive feature through clarify/before-plan and verify the next stop creates a design-analysis artifact, recommends an option, asks for an explicit design-analysis verdict, and does not begin plan generation before a human choice is recorded.

**Acceptance Scenarios**:

1. **Given** a substantive feature has completed clarify/before-plan, **When** Specrew reaches the pre-plan boundary, **Then** it creates a `design-analysis.md` artifact before any substantive `plan.md` is written.
2. **Given** the design-analysis artifact is created, **When** the human reviews it, **Then** it presents at least the simplest and reasonable options as distinct choices and includes a Crew recommendation.
3. **Given** the human has not chosen an option, **When** the coordinator attempts to advance into plan, **Then** advancement is blocked with a clear message that the design-analysis human decision is missing.

---

### User Story 2 - Preserve the Design Decision Record (Priority: P1)

As a future maintainer reading a feature's artifacts, I need a durable record of which design option was chosen, why, and at what commit so that the implemented architecture has traceable human decision evidence.

**Why this priority**: The gate is valuable only if the chosen option survives beyond the chat transcript and becomes reviewable project history.

**Independent Test**: Approve a design-analysis stop with a named option and verify the artifact records the chosen option, human reason or modifications, and commit hash before plan starts.

**Acceptance Scenarios**:

1. **Given** the Crew recommends Option B, **When** the human replies `approved for plan with Option B`, **Then** the Human Decision section records Option B as chosen before plan starts.
2. **Given** the human modifies a choice, **When** the human replies with an approved option plus instructions, **Then** the chosen option and modifications are recorded in the artifact and become plan input.
3. **Given** the decision is recorded, **When** the design-analysis boundary is committed, **Then** the artifact records the commit hash associated with that boundary evidence.

---

### User Story 3 - Validate the Minimal Gate (Priority: P2)

As a Specrew maintainer, I need focused validation and tests for the new gate so that missing artifacts, thin alternatives, missing recommendations, and missing human decisions are caught without forcing the full Proposal 137 rollout.

**Why this priority**: The first slice must be enforceable enough to prevent silent design selection, while preserving hard scope limits around broad validator rollout and full multi-host deployment.

**Independent Test**: Run the focused tests or validation fixtures and verify they reject missing `design-analysis.md`, missing required sections, missing recommendation, and plan-boundary advancement without a human decision.

**Acceptance Scenarios**:

1. **Given** a substantive feature iteration lacks `design-analysis.md`, **When** focused validation runs, **Then** it reports the missing artifact.
2. **Given** a design-analysis artifact lacks required option fields or has fewer than two options, **When** focused validation runs, **Then** it reports the missing required content.
3. **Given** a design-analysis artifact has alternatives but no Crew recommendation, **When** focused validation runs, **Then** it reports the missing recommendation.
4. **Given** a design-analysis artifact has no Human Decision section content, **When** the plan boundary is requested, **Then** the boundary cannot advance until an explicit human decision exists.

---

### Edge Cases

- A feature is trivial, doc-only, or a very small fix; the first slice uses a simple applicability rule and may skip the gate when the work is clearly non-substantive.
- Only two design options are meaningfully distinct; the gate must allow two options and must not require a contrived by-the-book option.
- A by-the-book option is meaningfully distinct for a security-critical, foundational, or high-reversibility-cost change; the artifact must include it.
- A human chooses a modified option, such as "Option B but defer broad validator rollout"; the artifact must preserve the modification and make it plan input.
- A plan artifact already exists from a previous run; the gate must not treat that as approval for a new design decision unless the Human Decision section records a valid choice for the current feature/iteration.
- Broad historical or in-flight projects may lack this artifact; this slice must avoid disruptive hard enforcement outside the active substantive feature path unless the enforcement is cheap and low-risk.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Specrew MUST introduce a design-analysis lifecycle stop after clarify/before-plan and before plan for substantive features.
- **FR-002**: Specrew MUST use a simple applicability rule for this slice: substantive new features, architectural refactors, lifecycle/governance changes, and enabler work require design analysis; trivial, doc-only, and clearly small bug-fix or chore work may skip it.
- **FR-003**: The design-analysis stop MUST create a durable per-iteration artifact at `specs/<feature>/iterations/<NNN>/design-analysis.md` before plan starts.
- **FR-004**: `design-analysis.md` MUST include sections for problem framing, key design decision points, alternatives, Crew recommendation, and Human Decision.
- **FR-005**: The Alternatives section MUST include at least two distinct options: Simplest and Reasonable.
- **FR-006**: A By-the-book option MUST be included only when it is meaningfully distinct from the Reasonable option for the active problem.
- **FR-007**: Each option MUST include approach, architectural pattern, quality features considered, effort estimate, reversibility cost, trade-offs, and a Mermaid diagram or diagram link.
- **FR-008**: The Crew recommendation section MUST name one recommended option and explain why it is preferred for the active feature context.
- **FR-009**: The pre-plan human verdict MUST explicitly name the boundary and chosen option, using a shape equivalent to `approved for plan with Option B`.
- **FR-010**: Specrew MUST reject or hold plan-boundary advancement for the active feature/iteration when the per-iteration design-analysis artifact is missing, the Crew recommendation is not populated, or the Human Decision section does not contain a chosen option.
- **FR-011**: Specrew MUST record the chosen option, human reason or modifications, and boundary commit hash before plan starts.
- **FR-012**: Plan generation MUST treat the recorded human-selected option and modifications as authoritative design input.
- **FR-013**: Focused validation or tests MUST verify artifact creation for substantive features.
- **FR-014**: Focused validation or tests MUST verify required sections in `design-analysis.md`.
- **FR-015**: Focused validation or tests MUST verify at least two required alternatives and the required per-option fields.
- **FR-016**: Focused validation or tests MUST verify the Crew recommendation is populated and not placeholder text.
- **FR-017**: Focused validation or tests MUST verify plan-boundary advancement is blocked until a human decision exists.
- **FR-018**: The slice MUST NOT implement the full Proposal 137 lifecycle, full slice-type catalog, broad historical hard validator enforcement, or broad multi-host slash-command deployment unless a small, low-risk implementation path is discovered during planning.
- **FR-019**: The slice MUST avoid touching Unix install, shell wrapper, and bootstrap files that are owned by the parallel Unix-install feature.
- **FR-020**: The slice MUST NOT publish beta or stable release artifacts.
- **FR-021**: The slice MUST document a compatibility path where existing projects and existing in-flight features do not break unexpectedly after update; the mandatory gate applies only to new substantive iterations unless a project explicitly opts in or records a migration decision.

### Traceability & Governance Requirements *(mandatory)*

- **TG-001**: Each user story MUST map to one or more functional requirements.
- **TG-002**: Each requirement MUST identify expected owner role(s).
- **TG-003**: Each requirement MUST identify intended iteration or delivery window.
- **TG-004**: Any known spec/implementation conflict MUST include an explicit reconciliation path.
- **TG-005**: Planning MUST preserve the hard scope limits from this spec and Proposal 137 first-slice scope.
- **TG-006**: Review MUST classify the gate behavior as implemented, enforced, observable, and documented, and must record gaps before closeout.

### Requirement Ownership

| Requirement | Owner Role(s) | Delivery Window |
| --- | --- | --- |
| FR-001 | Spec Steward, Planner, Implementer, Reviewer | Iteration 001 |
| FR-002 | Spec Steward, Planner, Reviewer | Iteration 001 |
| FR-003 | Implementer, Reviewer | Iteration 001 |
| FR-004 | Spec Steward, Implementer, Reviewer | Iteration 001 |
| FR-005 | Spec Steward, Implementer, Reviewer | Iteration 001 |
| FR-006 | Spec Steward, Planner, Reviewer | Iteration 001 |
| FR-007 | Spec Steward, Implementer, Reviewer | Iteration 001 |
| FR-008 | Spec Steward, Planner, Reviewer | Iteration 001 |
| FR-009 | Spec Steward, Implementer, Reviewer | Iteration 001 |
| FR-010 | Implementer, Reviewer | Iteration 001 |
| FR-011 | Implementer, Reviewer | Iteration 001 |
| FR-012 | Planner, Implementer, Reviewer | Iteration 001 |
| FR-013 | Implementer, Reviewer | Iteration 001 |
| FR-014 | Implementer, Reviewer | Iteration 001 |
| FR-015 | Implementer, Reviewer | Iteration 001 |
| FR-016 | Implementer, Reviewer | Iteration 001 |
| FR-017 | Implementer, Reviewer | Iteration 001 |
| FR-018 | Spec Steward, Planner, Reviewer | Iteration 001 |
| FR-019 | Spec Steward, Implementer, Reviewer | Iteration 001 |
| FR-020 | Spec Steward, Reviewer | Iteration 001 |
| FR-021 | Spec Steward, Planner, Reviewer | Iteration 001 |
| TG-001 | Planner, Reviewer | Iteration 001 |
| TG-002 | Planner, Reviewer | Iteration 001 |
| TG-003 | Planner, Reviewer | Iteration 001 |
| TG-004 | Spec Steward, Reviewer | Iteration 001 |
| TG-005 | Spec Steward, Planner, Reviewer | Iteration 001 |
| TG-006 | Reviewer | Iteration 001 |

### Key Entities *(include if feature involves data)*

- **Design Analysis Boundary**: The human-judgment lifecycle stop between clarify/before-plan and plan where the Crew compares design options and records a verdict.
- **Design Analysis Artifact**: The durable per-iteration artifact at `specs/<feature>/iterations/<NNN>/design-analysis.md` containing framing, decision points, alternatives, recommendation, and human decision evidence for the active iteration.
- **Design Option**: A named implementation approach such as Simplest, Reasonable, or By-the-book, with quality, effort, reversibility, trade-off, and diagram evidence.
- **Crew Recommendation**: The Crew's explicit preferred option and rationale based on clarify outcomes, repository context, scope limits, and quality considerations.
- **Human Design Decision**: The recorded human verdict naming the boundary, chosen option, reason or modifications, and commit hash before planning begins.
- **Applicability Rule**: The first-slice rule that distinguishes substantive work requiring the gate from trivial work that can skip it.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: For a substantive feature fixture, a design-analysis stop produces `specs/<feature>/iterations/<NNN>/design-analysis.md` before plan generation.
- **SC-002**: `design-analysis.md` contains problem framing, decision points, alternatives, Crew recommendation, and Human Decision sections.
- **SC-003**: Each valid design-analysis artifact includes at least two distinct options, including Simplest and Reasonable.
- **SC-004**: Every option includes approach, architectural pattern, quality features considered, effort estimate, reversibility cost, trade-offs, and a Mermaid diagram or diagram link.
- **SC-005**: A By-the-book option is present only when it is meaningfully distinct, or the artifact states why it is not distinct enough for this slice.
- **SC-006**: The Crew recommendation names exactly one preferred option and gives context-specific rationale.
- **SC-007**: A plan-boundary request for the active feature/iteration without a design-analysis artifact, populated Crew recommendation, and Human Decision chosen option is rejected or held by focused validation or boundary logic.
- **SC-008**: A valid Human Decision records a verdict equivalent to `approved for plan with Option <X>`, the chosen option, human reason or modifications, and a boundary commit hash.
- **SC-009**: Plan inputs reference or otherwise preserve the human-selected option and modifications.
- **SC-010**: Focused tests or validation fixtures cover missing artifact, missing required sections, missing recommendation, and missing human decision.
- **SC-011**: The implementation avoids Unix install, shell wrapper, bootstrap, beta-publish, and stable-publish surfaces.
- **SC-012**: Existing or in-flight features are not broadly hard-failed solely because they predate the new design-analysis artifact.
- **SC-013**: Compatibility documentation states that the mandatory gate applies to new substantive iterations and gives existing projects/features a non-breaking migration path.

## Assumptions

- The active lifecycle can add a first-slice design-analysis stop without completing the full Proposal 137 slash-command and multi-host deployment surface.
- The active iteration is the durability scope for `design-analysis.md`; later iterations may create different alternatives or explicitly reuse a prior decision.
- The default recommended option will usually be Reasonable unless clarify outcomes or quality risks clearly justify Simplest or By-the-book.
- A lightweight Mermaid component or sequence diagram is sufficient for each option in this slice.
- Broad phased enforcement across historical projects is intentionally deferred unless planning finds a cheap and low-risk compatibility path.
- Spec Kit 0.9.0 support is merged but unreleased; release publishing is handled by a later combined release.

## Scope Limits *(mandatory)*

- Do not implement the full Proposal 137 in this slice.
- Defer full multi-host slash-command deployment unless it is cheap and low-risk.
- Defer hard validator enforcement for all existing or in-flight projects unless it is cheap and low-risk.
- Use only a simple substantive/trivial applicability rule; do not implement the full slice-type catalog.
- Avoid touching Unix install, shell wrapper, or bootstrap files owned by the parallel Unix-install feature.
- Do not publish beta or stable.

## Clarifications

### Session 2026-06-02

- Q: Where should the design-analysis artifact live for this first slice? A: Store `design-analysis.md` per iteration, starting at `specs/140-design-analysis-gate/iterations/001/design-analysis.md`. The design choice is iteration-scoped because later iterations may need different alternatives or may explicitly reuse a prior decision.
- Q: How narrow should enforcement be in this slice? A: Enforce narrowly for this feature/iteration: plan must not advance until the design-analysis artifact exists, the Crew recommendation is populated, and the human decision is recorded. Defer broad validator enforcement across all existing or in-flight projects.
- Q: What compatibility behavior is required for existing projects/features? A: Leave a durable compatibility path. Existing projects and features should not break unexpectedly after update; if the gate is mandatory only for new substantive iterations, document that clearly.
- Q: Should the by-the-book option always be generated? A: No. Keep the by-the-book option conditional and do not force a fake third option when Simplest and Reasonable are the only meaningfully distinct approaches.
- Q: Which implementation surfaces remain excluded? A: Keep Unix install and wrapper surfaces out of scope.

## Governance Alignment *(mandatory)*

- **Spec Steward**: Owns the design-analysis boundary semantics, artifact shape, option minimums, verdict wording, and scope limits.
- **Iteration Facilitator**: Planner coordinates one focused first-slice iteration and stops for human approval before plan generation.
- **Capacity Model**: 8-13 SP feature, planned as one iteration unless design-analysis or planning reveals hidden lifecycle-coupling risk.
- **Drift Signals**: Drift is indicated by any mismatch between the selected design option, `design-analysis.md`, plan input, boundary state, validation tests, and review evidence.
- **Human Oversight Points**: Human review is required after specify before clarify, after clarify/design-analysis before plan, after plan before tasks if policy requires it, before implementation, at review signoff, at iteration closeout, and at feature closeout.
