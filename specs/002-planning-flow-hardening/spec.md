# Feature Specification: Planning Flow Hardening

**Feature Branch**: `[003-harden-planning-flow]`  
**Created**: 2026-05-07  
**Status**: Draft  
**Input**: User description: "Create or update the feature specification in the current repository for a new planning-flow hardening slice."

## Problem Statement

Specrew already relies on Spec Kit as the lifecycle and template system for `spec.md`, `plan.md`, and `tasks.md`, and this feature preserves that model. Recent planning runs showed that template use alone does not guarantee contract-valid artifacts: schema-only failures such as invalid status values, missing required sections or metadata, malformed markdown tables, and user-story-to-requirement mismatches still trigger noisy repair loops across roles. This feature hardens the planning flow after the requirement is already grounded, so deterministic contract issues are normalized before planning governance gates, while true semantic or traceability problems remain visible to the responsible planning roles.

## User Scenarios & Testing *(mandatory)*

### User Story 1 — Route planning-critical work to stronger agents consistently (Priority: P1)

A Specrew operator runs a planning-heavy flow and expects the most important planning artifacts to be handled by the strongest available delegated capability classes without bypassing Spec Kit. Planning-critical work stays inside the normal Spec Kit lifecycle, but role routing becomes predictable: Spec Steward prefers the configured stewardship-analysis capability class, while Planner and Reviewer prefer the configured planning-review capability class for planning and planning-governance work.

**Why this priority**: If planning artifacts are created or repaired on inconsistent routing paths, the same schema and contract failures recur even when the lifecycle itself is correct.

**Independent Test**: Start a planning flow with delegated capability classes available and verify that planning-critical work records the preferred routing for Spec Steward, Planner, and Reviewer, while still using the normal Spec Kit phase sequence.

**Acceptance Scenarios**:

1. **Given** a planning flow with all preferred delegated capability classes available, **When** Specrew enters planning-critical phases, **Then** Spec Steward work prefers the configured stewardship-analysis class and Planner and Reviewer work prefer the configured planning-review class without bypassing Spec Kit commands, templates, or scripts.
2. **Given** a planning flow where a preferred delegated capability class is unavailable, **When** Specrew assigns planning-critical work, **Then** it uses an explicit fallback and records what was requested, what was used instead, and why the fallback occurred.

---

### User Story 2 — Remove schema-only noise before planning governance gates (Priority: P1)

A Planner or Spec Steward produces planning artifacts through the normal Spec Kit flow, but those artifacts contain contract-safe issues such as invalid enum casing, missing required headings, malformed markdown table separators, or boilerplate metadata that can be derived from existing artifacts. Before planning governance gates run, Specrew deterministically normalizes those issues so the gates are not consumed by avoidable syntax and schema noise.

**Why this priority**: This is the core hardening slice. Without deterministic normalization, governance gates keep spending expensive review cycles on issues that do not change product meaning.

**Independent Test**: Prepare planning artifacts containing only known schema-only defects, run the planning governance flow, and verify that the artifacts are normalized before gate evaluation without introducing new meaning.

**Acceptance Scenarios**:

1. **Given** a `before-plan` or `after-tasks` governance check and artifacts containing only known schema-only defects, **When** the governance flow starts, **Then** Specrew canonicalizes those defects before the gate verdict is produced.
2. **Given** a planning artifact missing required headings or metadata that can be derived from existing project artifacts, **When** canonicalization runs, **Then** the required contract fields are restored in a deterministic way without inventing new scope, requirements, or task intent.
3. **Given** a malformed markdown table whose intended rows and cells are already unambiguous, **When** canonicalization runs, **Then** the table is reshaped into valid markdown without altering the meaning of the content.

---

### User Story 3 — Fail only for real planning issues and preserve role boundaries (Priority: P2)

After canonicalization, the Reviewer and Planner need governance failures to mean something real: semantic ambiguity, broken traceability, missing requirement quality, or task-design problems. The canonicalizer must stay bounded to deterministic contract normalization and must not act as a substitute planner or silently resolve ambiguous meaning.

**Why this priority**: Hardening only helps if it reduces false failures without weakening the accountability of Planner, Reviewer, and Spec Steward for actual planning quality.

**Independent Test**: Run governance on artifacts that contain both schema-only issues and one true semantic or traceability defect, and verify that the schema-only issues are normalized while the true planning defect still fails the gate.

**Acceptance Scenarios**:

1. **Given** a planning artifact with both schema-only defects and a real story-to-requirement mismatch, **When** canonicalization completes and governance evaluates the artifact, **Then** the gate passes over the normalized schema issues and fails only on the remaining traceability defect.
2. **Given** a planning artifact whose content is genuinely ambiguous, **When** canonicalization cannot normalize it without choosing meaning, **Then** it leaves the ambiguity for Planner, Reviewer, Spec Steward, or a human to resolve and does not silently invent an answer.

---

### Edge Cases

- A preferred delegated capability class is configured but temporarily unavailable during a planning-critical phase.
- A planning artifact contains both deterministic schema defects and a real semantic contradiction.
- A required heading or metadata field is missing in one artifact but can be derived from another authoritative planning artifact.
- A markdown table is malformed enough that row boundaries are ambiguous; canonicalization must refuse to guess.
- An artifact arrives already contract-valid; canonicalization must leave it unchanged and still allow governance to proceed.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Specrew MUST preserve Spec Kit as the authoritative lifecycle and template system for planning artifacts. This hardening slice MUST improve reliability around `spec.md`, `plan.md`, and `tasks.md` without replacing the Spec Kit flow with a separate custom planning pipeline.
- **FR-002**: Specrew MUST treat planning-critical work as a routing class with explicit preferred delegated capability classes. For planning-critical work, Spec Steward MUST prefer the configured stewardship-analysis capability class, and Planner and Reviewer MUST prefer the configured planning-review capability class.
- **FR-003**: When preferred delegated routing for planning-critical work cannot be honored, Specrew MUST use an explicit fallback and surface requested routing class, effective routing class, and fallback reason in observable run evidence.
- **FR-004**: Specrew MUST run a deterministic canonicalization step before the `before-plan` governance gate and before the `after-tasks` governance gate. In this feature, `before-plan` means the planning-governance evaluation immediately before plan artifact production begins, and `after-tasks` means the planning-governance evaluation immediately after `tasks.md` is produced.
- **FR-005**: The canonicalization step MUST normalize schema-only or contract-only defects that can be corrected without changing intended meaning, including allowed status enum normalization, required heading presence, required metadata presence, markdown table shape or separator repair, and boilerplate metadata derivation from existing authoritative artifacts. Derivation patterns MUST come from an explicit versioned derivation-pattern allow-list artifact (e.g., `.specrew/canonicalization/derivation-patterns-v1.md`) rather than open-ended authoritative-artifact reasoning. Only patterns present in the active allow-list version may be applied.
- **FR-006**: The canonicalization step MUST be deterministic: the same artifact inputs, same available authoritative planning context, and same canonicalizer version MUST produce the same normalized output and the same normalization record.
- **FR-007**: The canonicalization step MUST NOT invent new semantic content, choose between competing interpretations, create missing requirements or tasks from scratch, or silently resolve true ambiguity.
- **FR-008**: When canonicalization encounters an issue that cannot be fixed without changing meaning, Specrew MUST leave the issue unresolved for normal planning governance and identify it as a semantic or ambiguity problem rather than masking it as formatting cleanup.
- **FR-009**: After canonicalization, planning governance gates MUST fail only for remaining semantic, traceability, or requirement-quality issues, not for schema-only defects that were eligible for deterministic normalization.
- **FR-010**: Specrew MUST preserve role boundaries in the planning flow: Planner remains accountable for decomposition, scope shaping, and task design; Reviewer remains accountable for critical planning review; Spec Steward remains accountable for planning integrity; the canonicalizer remains limited to deterministic contract normalization.
- **FR-011**: Specrew MUST provide visible evidence for each planning-gate canonicalization pass, including whether the artifact was unchanged, which canonicalizer version was applied, what categories of schema-only issues were normalized, which derivation patterns (if any) were used with their allow-list references, and whether any unresolved semantic issues remained for governance review.
- **FR-012**: This hardening slice MUST remain bounded to planning-flow reliability and MUST NOT require intake hardening, lifecycle-wide escalation redesign, or implementation-phase hardening except where a dependency is strictly necessary to support the `before-plan` and `after-tasks` planning gates.

### Traceability & Governance Requirements *(mandatory)*

- **TG-001**: User Story 1 MUST be covered by FR-002 and FR-003.
- **TG-002**: User Story 2 MUST be covered by FR-004 through FR-006 and FR-011.
- **TG-003**: User Story 3 MUST be covered by FR-007 through FR-010.
- **TG-004**: Every planning-gate failure after canonicalization MUST cite the remaining semantic, traceability, or requirement-quality defect that caused the failure.
- **TG-005**: Routing evidence and canonicalization evidence for planning-critical work MUST be reviewable without inspecting raw agent conversations.
- **TG-006**: Scope expansion beyond planning-flow hardening MUST require an explicit follow-on feature rather than being absorbed silently into this slice.
- **TG-007**: FR-001 is a feature-wide preservation constraint that applies to all user stories in this slice.

### Non-Goals

- Hardening external requirement intake, scraping, or URL extraction.
- Redesigning the full lifecycle escalation model beyond what is strictly required to harden planning governance.
- Replacing Spec Kit templates with a wholly custom rendering or artifact-generation pipeline.
- Broad implementation-phase hardening unrelated to planning governance contracts.

### Key Entities *(include if feature involves data)*

- **Planning-Critical Work Item**: Any specification, planning, task-generation, repair, or governance-review activity whose output directly affects planning readiness or planning-governance verdicts.
- **Routing Capability Class**: A vendor-neutral routing label that expresses the kind of delegated reasoning required for a planning-critical work item. In the current repo policy, stewardship-analysis and planning-review capability classes may be mapped to specific agent families in configuration, but the spec does not hardcode those vendors.
- **Routing Evidence Record**: The user-visible record of requested delegated capability class, effective delegated capability class, role, phase context, and fallback reason when applicable.
- **Canonicalization Pass**: A deterministic normalization operation applied to a planning artifact before a planning governance gate.
- **Canonicalizer Version**: A semantic version identifier (e.g., `v1.2.0`) that tracks the active canonicalization rule set, derivation pattern allow-list version, and normalization logic. The canonicalization report MUST record which canonicalizer version was used.
- **Derivation Pattern Allow-List**: A versioned, explicit artifact (e.g., `.specrew/canonicalization/derivation-patterns-v1.md`) that defines which patterns may be used to derive missing metadata or boilerplate from existing authoritative planning artifacts. Derivation MUST only occur for patterns present in the active allow-list; open-ended "existing authoritative artifacts" reasoning is prohibited.
- **Canonicalization Report**: The record of whether an artifact was unchanged, what schema-only issue categories were normalized, which canonicalizer version was applied, which derivation patterns (if any) were used with their allow-list references, and what unresolved semantic issues remain.
- **Planning Governance Gate**: A named planning checkpoint in the Spec Kit-driven workflow. In this slice, `before-plan` is the gate immediately before plan generation and `after-tasks` is the gate immediately after task generation.
- **Authoritative Planning Context**: The deterministic set of existing project artifacts allowed to inform canonicalization, including the current feature's `spec.md`, `plan.md`, `tasks.md`, iteration-planning artifacts when present, and stable project governance/config files that define planning contracts. It excludes transient chat history, freeform agent memory, or unstated human intent.
- **Planning Governance Gate Result**: The final pass/fail outcome for `before-plan` or `after-tasks`, including citations for any remaining semantic, traceability, or requirement-quality failures.

### Canonicalization Boundary Examples

- **Clearly schema-only**:
  - Converting a known status value from `Ready-For-Implementation` to the contract-valid enum casing already defined by the planning schema.
  - Restoring a required heading with an empty or unchanged body when the section contract requires the heading but the missing heading does not require invented content.
  - Repairing markdown table separators when the existing rows and cells are already unambiguous.
- **Clearly semantic and not canonicalizable**:
  - Changing a task story from `US-6` to `US-2` because the current traceability matrix shows the requirement belongs to `US-2`.
  - Expanding an owner from `Junior` to `Junior Frontend Developer` when the artifact does not already identify the specialty.
  - Writing missing task content under a required heading when the missing content would have to be inferred from intent rather than copied or derived from authoritative artifacts.
- **Ambiguous and must be left to planning roles**:
  - A missing heading whose only plausible content would require choosing between multiple requirement interpretations.
  - A partially malformed table where the row boundaries are unclear.
  - An owner field that might be shorthand for a full roster title but is not uniquely determined by the artifact set.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: After a representative schema-only planning-fixture corpus and pre-hardening baseline are captured during implementation planning for this feature, at least 95% of artifacts in that corpus with only contract-safe defects are normalized and proceed to governance without manual cross-role escalation.
- **SC-002**: In representative planning-governance tests, 100% of post-canonicalization gate failures cite a remaining semantic, traceability, or requirement-quality defect rather than a normalized schema-only defect.
- **SC-003**: In representative runs where preferred delegated capability classes are unavailable, 100% of planning-critical fallback events are visible in routing evidence with requested routing, effective routing, and fallback reason.
- **SC-004**: After the pre-hardening baseline scenario is captured for the representative schema-only fixture corpus, repeated repair loops caused only by invalid enums, missing required sections or metadata, malformed tables, or other schema-only planning defects are reduced by at least 80%.
- **SC-005**: In review of planning artifacts produced under this slice, 100% of accepted decomposition and task-design decisions remain attributable to Planner, Reviewer, Spec Steward, or human decisions rather than to canonicalization.

## Assumptions

- Spec Kit templates and lifecycle commands remain the canonical source for planning artifacts in this repository.
- `before-plan` and `after-tasks` are the minimum planning-governance gates that must be hardened in this slice.
- Preferred delegated capability classes may not always be available, so explicit fallback behavior is necessary even when role policy is configured.
- Known schema-only planning failures can be identified from the artifact text and existing authoritative planning context without inventing new product meaning.
- The representative schema-only fixture corpus and pre-hardening baseline measurement for SC-001 and SC-004 will be defined during planning and implementation of this feature rather than by this draft spec itself.

## Governance Alignment *(mandatory)*

- **Spec Steward**: Owns planning-integrity policy, validates that canonicalization stays bounded to contract normalization, and prefers the configured stewardship-analysis routing class for planning-critical stewardship work.
- **Iteration Facilitator**: Approves rollout of this planning hardening slice and decides whether any discovered scope dependency warrants a separate follow-on feature.
- **Capacity Model**: One planning hardening slice that should be deliverable independently of intake hardening or broader lifecycle redesign.
- **Drift Signals**: Repeated schema-only planning failures, missing routing evidence, governance failures without semantic citations, or canonicalization that changes artifact meaning.
- **Human Oversight Points**: Human review is required when canonicalization encounters unresolved ambiguity, when routing capability-class policy changes expand beyond this slice, or when a planning gate fails for a requirement-quality issue that may require spec intent changes.
