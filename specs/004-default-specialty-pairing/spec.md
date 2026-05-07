# Feature Specification: Default Specialty Pairing

**Feature Branch**: `[004-default-specialty-pairing]`  
**Created**: 2026-05-07  
**Status**: Draft  
**Input**: User description: "Specrew's current concurrency-aware team sizing is too conservative. The intended product behavior is that specialty-based Junior/Senior pairs are a normal default optimization model for many projects, not a rare exception."

## Problem Statement

Specrew already shapes teams after the feature scope is grounded, but its current concurrency-aware sizing is still too conservative for common product work. In practice, many features contain both bounded lower-risk specialty work that can be done faster and cheaper, and higher-risk or more ambiguous specialty work that benefits from stronger judgment. When Specrew waits for unusually strong parallelism evidence before proposing same-specialty Junior/Senior pairs, it falls back too often to baseline-only or single-member specialty coverage, reducing throughput and overusing stronger models for work that does not require them.

This feature makes specialty-based Junior/Senior pairing the normal default policy for active specialties in most projects while preserving safety, correctness, and human control. It refines how Specrew sizes and presents the team after the feature is clarified and planned; it does not replace Spec Kit, the existing lifecycle, or the requirement that a human approve the final team before implementation begins.

## Relationship to Existing Requirements

This feature is a **policy-strengthening layer** over the existing US-9 requirements in `specs/001-specrew-product/spec.md`, not a separate competing concurrency model.

- **FR-038** remains the source requirement for concurrency-aware team sizing inputs. This feature keeps those inputs and strengthens the output policy by making default pairing the normal posture for active specialties rather than waiting for unusually strong evidence.
- **FR-039** remains the source requirement for distinct Junior/Senior role identities and human approval. This feature strengthens it by requiring explicit exception records whenever an active specialty is left unpaired.
- **FR-040** remains the source requirement for Junior-vs-Senior task-class separation. This feature preserves that split and clarifies that task profile, not vendor/model backing alone, defines the role distinction.
- **FR-041** remains the source requirement for safe parallel execution. This feature preserves explicit ownership boundaries as the safety gate, treats serial execution as the fallback when boundaries are unclear, and adds observability for Junior-to-Senior escalation decisions.

This spec therefore **strengthens and operationalizes** FR-038 through FR-041 rather than superseding them.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Default to paired specialty coverage for active specialties (Priority: P1)

After the feature scope is clarified and the likely workstreams are understood, a human developer wants Specrew to treat same-specialty Junior/Senior pairing as the normal optimization model for active specialties rather than as a rare exception. The proposal should be grounded in the clarified scope, inferred stack, and planned workstreams instead of shallow keyword matching alone.

**Why this priority**: If Specrew still defaults to baseline-only or single-member specialty coverage for common full-stack features, the intended policy change does not happen and the product continues to undersize teams.

**Independent Test**: Use a clarified, planned feature that clearly touches multiple specialties such as frontend, backend, and persistence. Verify that Specrew identifies the active specialties from the grounded feature context and usually proposes both Junior and Senior members for each applicable specialty unless an explicit exception is recorded.

**Acceptance Scenarios**:

1. **Given** a clarified and planned feature with clear frontend and backend workstreams plus cross-cutting integration work, **When** Specrew performs team shaping, **Then** it proposes both Junior and Senior members for each active applicable specialty by default rather than stopping at baseline-only coverage.
2. **Given** a project whose repository and planned work indicate an active specialty such as frontend, backend, realtime, or persistence, **When** Specrew sizes the team, **Then** it uses the clarified scope, inferred stack, and planned workstreams together to decide that the specialty is active.
3. **Given** an active specialty that does not receive a Junior/Senior pair, **When** Specrew presents the team, **Then** it identifies the exception reason instead of treating baseline-only or single-member coverage as an unexplained default.

---

### User Story 2 - Route same-specialty work safely between Junior and Senior roles (Priority: P1)

A human developer wants Specrew to use paired same-specialty roles to improve both quality and throughput without creating unsafe overlap. Junior roles should absorb bounded, lower-risk, well-partitioned work, while Senior roles should own ambiguous, cross-cutting, integration-heavy, security-sensitive, concurrency-sensitive, or reviewer-gated work. When distinct delegated capability classes are available for the specialty, the Senior role should default to a strictly stronger class than the Junior role. When safe ownership boundaries are unclear, Specrew should fall back to serial execution instead of forcing parallelism.

**Why this priority**: Pairing only helps if it improves velocity without damaging correctness. Unsafe same-specialty overlap or duplicated effort would make the feature actively harmful.

**Independent Test**: Use a feature whose planned work contains both bounded specialty slices and risky integration-heavy slices. Verify that the bounded slices are routed toward Junior ownership, the risky slices are routed toward Senior ownership, and tightly coupled work falls back to serial ownership unless a safe coordination plan is explicit.

**Acceptance Scenarios**:

1. **Given** a same-specialty Junior/Senior pair and a bounded, lower-risk task slice with clear ownership boundaries, **When** Specrew assigns work, **Then** it prefers the Junior role for that slice.
2. **Given** a same-specialty Junior/Senior pair and an ambiguous, cross-cutting, integration-heavy, security-sensitive, concurrency-sensitive, or reviewer-gated slice, **When** Specrew assigns work, **Then** it prefers the Senior role for that slice.
3. **Given** distinct delegated capability classes are available for a same-specialty Junior/Senior pair, **When** Specrew finalizes routing for that pair, **Then** it assigns the Senior role to a strictly stronger delegated capability class than the Junior role by default.
4. **Given** Specrew keeps a same-specialty Junior/Senior pair on the same delegated capability class, **When** that routing is recorded, **Then** it surfaces an explicit override record with the justification for not using a stronger Senior class.
5. **Given** a same-specialty pair but the planned slices still share a high-conflict surface or unclear ownership boundary, **When** Specrew is preparing execution, **Then** it keeps the work serial or explicitly coordinates ownership before allowing concurrent execution.
6. **Given** a paired specialty where the Junior-owned slice repeatedly reveals integration risk or unsafe overlap, **When** Specrew reassesses ownership, **Then** it escalates the slice to Senior ownership or reduces same-specialty concurrency rather than persisting with unsafe parallelism.

---

### User Story 3 - Keep team expansion under human approval and explicit justification (Priority: P2)

Before implementation begins, a human developer wants Specrew to clearly present the final team composition, explain why extra same-specialty members were proposed or omitted, and require human approval before any added members are materialized. The developer should be able to trust that pairing improves quality and velocity without losing control over team size or role changes.

**Why this priority**: The feature changes default team sizing behavior. Human approval remains the governance safeguard that keeps the user in control of added capacity and cost.

**Independent Test**: Run team shaping for an eligible feature, verify the proposal explains the pairing rationale and exceptions, then confirm that no additional members are materialized or used for implementation unless the human explicitly approves them.

**Acceptance Scenarios**:

1. **Given** Specrew proposes additional Junior and Senior specialty members, **When** it presents the final pre-implementation team, **Then** it explains the role split, the expected work classes, and the reason those extra members were proposed.
2. **Given** the human developer has not approved proposed extra members, **When** Specrew reaches implementation readiness, **Then** it does not materialize or invoke those extra members.
3. **Given** the human developer approves some proposed specialty pairs but not others, **When** Specrew finalizes the roster, **Then** it uses only the approved additions and preserves explicit reasons for any specialties left unpaired.

---

### Edge Cases

- A trivial or highly localized feature touches only one narrow slice of a specialty; Specrew should treat pairing as unnecessary and record the trivial-scope exception rather than expanding the team by default without justification.
- The inferred stack contains multiple specialty signals, but the clarified feature scope or planned work only activates one of them; Specrew should size for the active feature work, not for the whole repository in the abstract.
- A feature has an active specialty, but all meaningful work within that specialty is tightly coupled on the same high-conflict surface; Specrew should prefer serial ownership or an explicit coordination plan over unsafe same-specialty parallelism.
- Specialty signals are missing, weak, or contradictory after clarification and planning; Specrew should avoid inventing an unjustified pair and should explain what evidence is missing.
- A paired specialty exists, but the Senior role must own most of the slice because the work is dominated by ambiguity, integration, or risk; Specrew should still preserve correctness and may reduce Junior scope or omit the Junior role with an explicit exception.
- The human developer declines all or part of the proposed team expansion; Specrew should preserve the approved roster only and keep implementation blocked until the team and implementation start are explicitly approved.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: This feature MUST remain a strengthening layer over the existing concurrency-aware team-sizing requirements in `specs/001-specrew-product/spec.md`, especially FR-038 through FR-041. It MUST refine team-sizing and delegated-routing policy without replacing Spec Kit, the existing lifecycle, or the existing role-based execution model.
- **FR-002**: Specrew MUST determine team composition after the feature scope is sufficiently grounded through the current lifecycle, using clarified scope, inferred stack, and planned workstreams or tasks together rather than relying only on coarse keyword heuristics.
- **FR-003**: Specrew MUST identify which specialties are active for the current feature using an explicit combination rule. A specialty is active when the clarified scope and planned work both indicate work in that specialty, or when either clarified scope or planned work indicates it and repository or product evidence confirms it. Repository or product signals alone, without scope or planned-work confirmation, MUST NOT activate a specialty.
- **FR-004**: For each active specialty in the current feature, Specrew MUST treat Junior/Senior same-specialty pairing as the default proposal policy in normal cases, not as a rare exception that requires unusually strong parallelism evidence.
- **FR-005**: If an active specialty does not receive a Junior/Senior pair, Specrew MUST treat that outcome as an exception and MUST record a **Pairing Exception Record** in the active plan's `Concurrency Rationale` section or an equivalent serialized planning surface. At minimum that record MUST include the specialty, resulting state (`serial-fallback` or `unpaired`), explicit reason, grounding evidence, and decision owner.
- **FR-006**: Specrew MUST make serial execution the fallback for an active specialty when safe ownership boundaries or partitioning are unclear, rather than treating serial execution as a sign that pairing policy does not normally apply.
- **FR-007**: A proposed Junior role MUST be defined by task profile, not by vendor or model choice alone. Junior roles MUST be positioned primarily for bounded, lower-risk, lower-ambiguity work with explicit ownership boundaries.
- **FR-008**: A proposed Senior role MUST be defined by task profile, not by vendor or model choice alone. Senior roles MUST be positioned primarily for ambiguous, cross-cutting, integration-heavy, security-sensitive, concurrency-sensitive, reviewer-gated, or otherwise higher-risk work.
- **FR-009**: Routing configuration MUST default the Senior role to a strictly stronger delegated capability class than the Junior role when distinct classes are available for the same specialty. Any same-class Junior/Senior operation MUST be treated as an explicit recorded override with justification, including when no stronger distinct class is available or when a stronger class is intentionally not used. The role distinction MUST remain grounded in expected task profile rather than agent backing alone.
- **FR-010**: When a same-specialty pair is proposed, Specrew MUST describe the Junior and Senior members as distinct roles with different expected task profiles, not as duplicate unnamed copies of the same specialty.
- **FR-011**: Specrew MUST preserve quality and correctness when pairing same-specialty roles. It MUST NOT endorse unsafe overlap, duplicated ownership, or redundant execution merely to increase nominal concurrency.
- **FR-012**: Specrew MUST only allow concurrent same-specialty execution when ownership boundaries are explicit enough to avoid conflicting or redundant work, or when an explicit coordination plan makes the partitioning safe.
- **FR-013**: If a Junior-owned slice later proves too ambiguous, integration-heavy, or conflict-prone, Specrew MUST escalate that slice to Senior ownership or reduce same-specialty concurrency rather than repeating unsafe routing.
- **FR-014**: Junior-to-Senior escalations under FR-013 MUST be recorded as canonical routing or planning evidence, analogous to the runtime evidence required elsewhere in Specrew. At minimum, the record MUST include the slice or task identifier, original Junior assignment, effective Senior assignment, escalation trigger, and reason.
- **FR-015**: Team-sizing output MUST explain, for each active specialty, whether Specrew is proposing a Junior/Senior pair, a serial same-specialty path, or no specialty expansion, and it MUST cite the reasoning in terms of grounded feature context rather than unexplained defaults.
- **FR-016**: Specrew MUST NOT default back to baseline-only or single-member specialty coverage for a common active specialty without the explicit exception reasoning required by FR-005.
- **FR-017**: When specialty signals are weak or missing, Specrew MUST avoid inventing unjustified same-specialty pairs and MUST explain what evidence is insufficient to activate the specialty.
- **FR-018**: Any additional specialty members proposed or materialized under this policy MUST remain subject to explicit human approval before implementation begins.
- **FR-019**: If the human developer approves only part of the proposed team expansion, Specrew MUST materialize and use only the approved additions and MUST preserve the final roster decision explicitly.
- **FR-020**: If the post-planning review checkpoint feature is active for the same feature, Specrew MUST fold team composition, pairing exceptions, and team-expansion approval into that single post-planning review surface rather than presenting a separate second gate. A single explicit human approval may cover both plan readiness and team composition when both are shown together.
- **FR-021**: This feature MUST stay bounded to team-sizing, delegated-routing, and pre-implementation approval policy. It MUST NOT redefine the rest of the Spec Kit lifecycle, replace specialist inference with a fixed roster, or require unsafe same-specialty parallelism for every project.

### Traceability & Governance Requirements *(mandatory)*

- **TG-001**: User Story 1 MUST be covered by FR-002 through FR-006, FR-015, FR-016, and FR-017.
- **TG-002**: User Story 2 MUST be covered by FR-006 through FR-014 and FR-015.
- **TG-003**: User Story 3 MUST be covered by FR-015, FR-018, FR-019, FR-020, and FR-021.
- **TG-004**: Every active specialty in a team-sizing decision MUST be reviewable as one of three states: paired by default, serial fallback with reason, or not activated with reason.
- **TG-005**: Every proposed extra specialty member MUST be traceable to a human approval decision before implementation begins.
- **TG-006**: Any decision to keep an active specialty baseline-only or single-member MUST include the explicit exception reasoning required by FR-005 so common features cannot silently drift back to undersized teams.
- **TG-007**: Any same-class Junior/Senior routing decision MUST be traceable as an explicit override with justification and the effective delegated capability classes used.

### Requirement Ownership & Delivery Windows

| Requirement | Expected owner role(s) | Intended delivery window |
| --- | --- | --- |
| FR-001 to FR-005 | Spec Steward, Planner, human developer | Team-shaping policy after clarify and planning are grounded |
| FR-006 to FR-012 | Planner, Implementer, Reviewer, specialty Senior role, human developer | Pre-implementation routing, delegated-capability selection, and execution-readiness decisions |
| FR-013 to FR-017 | Spec Steward, Planner, human developer | Team presentation and approval before implementation |
| FR-018 to FR-021 | Spec Steward, Iteration Facilitator | Ongoing policy governance for this feature slice |

### Non-Goals

- Replacing Spec Kit or the existing clarify, plan, tasks, and implementation lifecycle.
- Requiring every possible specialty in the repository to receive a Junior/Senior pair regardless of whether the current feature activates that specialty.
- Treating same-specialty parallelism as inherently good even when work is tightly coupled or unsafe to partition.
- Removing the human approval gate for adding or materializing extra members.
- Redesigning delegated routing for unrelated roles outside the team-sizing policy addressed by this feature.

### Key Entities *(include if feature involves data)*

- **Active Specialty**: A specialty that the current feature materially requires under FR-003's combination rule. Repository or product evidence alone is not enough; activation must be confirmed by clarified scope, planned work, or both.
- **Specialty Pair Proposal**: The team-sizing decision for an active specialty that recommends both a Junior and Senior member by default, including the rationale and expected task split.
- **Junior Specialty Role**: The bounded-work role profile for a specialty, intended for lower-risk, well-partitioned work while still meeting the same quality bar. Routing configuration may map it to cheaper or faster delegated capacity, but that mapping is not the role definition itself.
- **Senior Specialty Role**: The high-ambiguity or high-risk role profile for a specialty, intended for cross-cutting, integration-heavy, security-sensitive, concurrency-sensitive, or reviewer-gated work. Routing configuration may map it to stronger delegated capacity, but that mapping is not the role definition itself.
- **Ownership Boundary**: The explicit division of work that allows same-specialty roles to operate without unsafe overlap or conflicting edits.
- **Pairing Exception Record**: The explicit justification for why an active specialty was not paired by default or why same-specialty execution was kept serial. At minimum it records the specialty, resulting state, explicit reason, grounding evidence, and decision owner, and it lives in the active plan's concurrency rationale or an equivalent serialized planning record.
- **Pairing Validation Corpus**: The named representative set of eligible features or scenarios used to evaluate pairing defaults, exception handling, routing outcomes, and baseline comparisons for this feature.
- **Escalation Evidence Record**: The canonical record of a Junior-to-Senior reassignment, including slice identifier, original assignment, effective assignment, trigger, and rationale.
- **Team Approval Decision**: The human decision that accepts or declines proposed extra members before implementation begins.

### Pairing Decision Examples

- **Default paired specialty coverage**:
  - A common feature activates frontend and backend specialties, and each specialty contains both bounded implementation slices and cross-cutting integration work.
  - A data-heavy feature activates persistence work with separable lower-risk schema or query slices plus higher-risk migration or correctness-sensitive slices.
- **Serial fallback with pairing intent preserved**:
  - A specialty is clearly active, but every meaningful slice touches the same high-conflict surface and safe partitioning is not yet clear.
  - A same-specialty Junior/Senior pair is conceptually useful, but the immediate next phase must stay serial until ownership boundaries are clarified.
- **No pair because the specialty is not sufficiently activated or justified**:
  - The repository contains frontend signals, but the clarified feature and planned work are backend-only.
  - The feature is so trivial or localized that adding a same-specialty pair would increase coordination overhead without meaningful value.
  - The evidence is too weak or contradictory to justify activating the specialty at all.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: After a representative pairing validation corpus and pre-feature baseline are defined during planning for this feature, Specrew proposes Junior/Senior pairs for at least 80% of active applicable specialties in that corpus unless an explicit exception record is present.
- **SC-002**: In 100% of team-sizing runs, every active specialty that remains unpaired or serial-only includes an explicit reason grounded in scope, work partitioning, or missing evidence.
- **SC-003**: In 100% of pre-implementation team presentations, any proposed extra members are shown for explicit human approval before implementation, and 0 unapproved extra members are materialized.
- **SC-004**: After a representative routing-validation set is defined during planning for this feature, at least 90% of bounded lower-risk slices in that set are assigned to Junior ownership, while 100% of ambiguous, cross-cutting, integration-heavy, security-sensitive, concurrency-sensitive, or reviewer-gated slices are assigned to Senior ownership or held in serial fallback.
- **SC-005**: After the pre-feature baseline is defined for the representative corpus of eligible features, the number of clearly concurrent planned work slices increases by at least 30% without increasing approval-blocking governance failures or same-surface conflict incidents.
- **SC-006**: In representative trivial-scope, tightly coupled, and missing-signal scenarios, 100% of fallback decisions avoid unsafe same-specialty overlap and preserve an explicit justification for why default pairing was reduced or not activated.
- **SC-007**: In 100% of Junior-to-Senior escalation events triggered under this feature, canonical escalation evidence is written with the slice identifier, reassignment, trigger, and reason.

## Assumptions

- Specrew already includes a team-shaping step after specification and clarification are grounded and before implementation begins.
- Planned workstreams or tasks are available by the time the final team composition is presented, so team sizing can use more than repository keywords alone.
- Human approval of team composition remains a required governance step before implementation starts.
- Not every project or specialty will justify same-specialty concurrency at the moment work begins, but active specialties should no longer default to baseline-only coverage without an explicit exception.
- This feature refines the existing concurrency-aware team-sizing direction already present in Specrew rather than introducing a separate lifecycle or team-management system.
- Delegated capability classes may differ by project or runtime availability, so same-class Junior/Senior operation can still occur only as an explicit override rather than as an unrecorded default.
- If the post-planning review feature is active, team composition and team approval should be folded into that same review checkpoint instead of adding a second pre-implementation gate.
- The representative pairing-validation corpus, routing-validation set, and pre-feature baseline measurements will be defined during planning and implementation of this feature rather than assumed to exist already.

## Governance Alignment *(mandatory)*

- **Spec Steward**: Owns the policy boundary that active specialties normally default to Junior/Senior pairing, ensures pairing and same-class overrides are explicit, and protects correctness when concurrency would be unsafe.
- **Iteration Facilitator**: Confirms the feature remains bounded to team-sizing and delegated-routing policy, and flags follow-on work if broader lifecycle changes are needed.
- **Capacity Model**: Active specialties normally scale to a paired Junior/Senior proposal so lower-risk work can move faster while higher-risk work stays under stronger ownership.
- **Drift Signals**: Common full-stack features repeatedly falling back to baseline-only teams without recorded exceptions, same-specialty overlap on shared surfaces, missing approval records for extra members, silent Junior-to-Senior escalations, same-class Junior/Senior routing without an explicit override record, or risky work being routed away from Senior ownership without justification.
- **Human Oversight Points**: Review of the proposed team, approval or rejection of extra specialty members, review of any serial fallback or pairing exceptions, review of any same-class capability override, review of escalation evidence when ownership changes materially, and explicit approval before implementation begins.
