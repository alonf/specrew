# Phase 1 Design: Data Model

**Feature**: 006-human-architecture-checkpoint  
**Branch**: `008-quality-profile-foundation`  
**Date**: 2026-05-09

## Overview

This document defines the key entities and data structures involved in the architecture intent checkpoint. The checkpoint does not introduce new runtime data models (no databases, no user-facing state), but it does define formal structures for:

1. **Architecture Intent Brief**: The structured output from Squad that proposes an implementation direction
2. **Decision Record**: The human-approved decision and constraints that guide implementation
3. **Approval Status**: Metadata tracking whether a feature has received checkpoint approval and when

## Entity Definitions

### Entity 1: Architecture Intent Brief

**Purpose**: Proposes an implementation approach before planning begins. This is a communication artifact (not a data model stored in a database).

**Attributes**:

| Attribute | Type | Description | Required | Constraints |
| --- | --- | --- | --- | --- |
| `feature_id` | string | Reference to the feature spec (e.g., `006-human-architecture-checkpoint`) | ✓ | Must match spec directory name |
| `generated_at` | datetime | Timestamp when the brief was generated | ✓ | ISO 8601 format |
| `generated_by` | string | Agent/role that generated the brief (e.g., `Squad Copilot`) | ✓ | Must be human-readable identifier |
| `design_approach` | markdown | 1–2 paragraph summary of intended architecture or design approach | ✓ | Max 500 chars; plain language |
| `affected_surfaces` | list[string] | Modules, services, files, or boundaries that will be materially changed | ✓ | At least 1 item; each entry includes brief justification |
| `expected_changes` | object | Data model, API, CLI, UI, workflow, or storage changes (before/after or impact) | ✓ | Structured list with clear before/after or impact description |
| `dependency_choices` | list[object] | Important framework, library, or tooling choices (name, version, why chosen) | ✗ | Empty list if no new dependencies |
| `implications` | object | Security, reliability, migration, performance, compatibility implications | ✓ | For each domain, either explicit statement or "not applicable" |
| `assumptions` | list[string] | Known assumptions about the spec, codebase, or architecture | ✓ | At least 1 item; explicit statement |
| `alternatives_considered` | list[object] | Alternative approaches rejected and why (name, approach summary, trade-off analysis) | ✗ | Empty for routine convention-following features; when present, at least 1 alternative with explicit trade-offs |
| `open_questions` | list[object] | Decisions that require human preference or authority (question, options, recommendation) | ✓ | May be empty if all choices are clear; each question includes options and Squad's recommendation |
| `approval_status` | enum | Current status: `pending_review`, `approved`, `rejected`, `deferred` | ✓ | Controlled vocabulary |

**Validation Rules**:
- `design_approach` must be non-empty and substantive (not a placeholder like "TBD")
- `affected_surfaces` must include at least one surface; vague surfaces like "codebase" are not allowed; each entry must include a brief justification
- `alternatives_considered` may be empty for routine convention-following features where no material architectural choices exist; when present, must include explicit trade-off analysis
- `open_questions` may be empty only if all architectural choices are clear from the spec; otherwise, at least one question must be present
- If `approval_status` is `approved` or `deferred`, a corresponding Decision Record must exist (see below)

**Example**:
```yaml
feature_id: 006-human-architecture-checkpoint
generated_at: 2026-05-09T14:30:00Z
generated_by: Squad Copilot
design_approach: |
  Integrate the checkpoint as a before_plan hook in the existing Speckit extension
  mechanism. The checkpoint invokes Squad to generate a brief, surfaces it to the
  human for approval, records decisions in plan.md, and blocks task generation until
  approval is recorded.
affected_surfaces:
  - "extensions/specrew-speckit/commands/speckit.specrew-speckit.before-plan.md" (checkpoint execution prompt)
  - ".github/agents/speckit.plan.agent.md" (planning agent checkpoint integration)
  - ".specify/templates/plan-template.md" (new Architecture Intent Review section)
  - "extensions/specrew-speckit/squad-templates/coordinator/specrew-governance.md" (lifecycle guidance)
expected_changes:
  data_model: "No database changes; plan.md gains Architecture Intent Review section"
  api: "Hook API contract; Squad agent receives spec and returns brief"
  workflow: "plan.md generation now includes checkpoint approval gate"
dependency_choices: []
assumptions:
  - Human architect is available to approve direction
  - Squad has sufficient context from spec to propose meaningful direction
  - Plan.md is suitable storage for decision records
implications:
  security: No new security surfaces
  performance: Checkpoint adds 5–10 minutes to planning (human decision time)
  migration: No migration impact; existing features unaffected
alternatives_considered:
  - name: Separate /speckit.architecture-intent command
    approach: Create new CLI command before /speckit.plan
    advantages: ["More explicit separation of concerns"]
    disadvantages: ["Requires two separate invocations", "Additional workflow step for users"]
    trade_offs: "More explicit but requires two separate invocations"
    why_not_chosen: "Hook integration is less disruptive and leverages existing planning workflow"
open_questions:
  - question: Should the brief be stored as a separate artifact or presented only in chat?
    options:
      - Option A: Store brief as architecture-brief.md in spec directory
      - Option B: Present brief in chat, store only decisions in plan.md
      - Option C: Store brief as JSON schema for machine consumption
    recommendation: Option B (Phase 1); defer JSON and artifact options to Phase 2
approval_status: pending_review
```

---

### Entity 2: Decision Record

**Purpose**: Captures human-approved decisions and constraints that guide implementation.

**Attributes**:

| Attribute | Type | Description | Required | Constraints |
| --- | --- | --- | --- | --- |
| `feature_id` | string | Reference to the feature spec | ✓ | Must match spec directory name |
| `recorded_at` | datetime | Timestamp when decision was recorded | ✓ | ISO 8601 format |
| `recorded_by` | string | Human/role that made the decision | ✓ | Human name or role |
| `brief_reference` | object | Reference to the Architecture Intent Brief that prompted this decision | ✓ | Includes brief generation timestamp and generated_by |
| `accepted_direction` | markdown | Concise statement of the approved approach | ✓ | Plain language; references the brief; explicit statement of what was chosen |
| `rejected_alternatives` | list[object] | Alternatives that were rejected and why (alternative name, reason, impact if chosen) | ✗ | Empty if no alternatives were presented in brief; when alternatives exist in brief, must record which were rejected and why |
| `human_constraints` | list[string] | Explicit constraints or forbidden paths (e.g., "do not use ORM", "must use PostgreSQL") | ✗ | Empty list if no constraints; each constraint must be specific and testable |
| `human_rationale` | markdown | Human's explanation for the decisions and constraints | ✗ | Empty if not provided; if provided, max 1000 chars |
| `unresolved_questions` | list[object] | Questions from the brief that remain open and need resolution later (question, deferred_until) | ✗ | Empty if all questions were resolved; each unresolved question must have a target resolution date |
| `decision_ledger_links` | list[string] | Links to entries in `.squad/decisions.md` or other decision ledger (optional) | ✗ | Only if the project maintains a separate decision ledger; URLs or ledger IDs |
| `approval_authority` | enum | Authority level of the decision maker: `architect`, `tech-lead`, `product-owner`, `team-consensus` | ✓ | Controlled vocabulary |
| `decision_status` | enum | Current status: `approved`, `active`, `superseded` | ✓ | Controlled vocabulary |

**Validation Rules**:
- `accepted_direction` must be non-empty, substantive, and directly reference the brief
- `rejected_alternatives` must be populated only when the brief presented alternatives; empty list valid when no alternatives exist (routine features)
- `human_constraints` are optional; when present, must be specific enough that a linter or person can verify compliance (not vague like "make it good")
- Clean approval (no constraints, no rejected alternatives, no overrides) is a valid and successful outcome
- `approval_authority` determines who can modify the decision later (e.g., only an architect can override an architect-level decision)
- `decision_status` is `active` once recorded in plan.md and remains active until explicitly superseded

**Relationships**:
- **To Brief**: Each Decision Record references the Architecture Intent Brief that prompted it. A brief may have multiple Decision Records if the human approves gradually or in phases.
- **To Implementation**: Decisions are referenced in task generation and implementation to verify that proposed choices align with the approved direction. A conflict (proposed choice ≠ approved direction) triggers escalation.

**Example**:
```yaml
feature_id: 006-human-architecture-checkpoint
recorded_at: 2026-05-09T15:00:00Z
recorded_by: Alon Fliess (Spec Steward)
brief_reference:
  generated_at: 2026-05-09T14:30:00Z
  generated_by: Squad Copilot
accepted_direction: |
  Implement the checkpoint as an automatic pre-step within the /speckit.plan command.
  The brief is presented in chat; decisions are recorded in planning context before
  plan body generation; the approved Architecture Intent Review section is part of
  the finalized plan.md. Task generation happens after plan.md exists and is approved.
rejected_alternatives:
  - name: Separate /speckit.architecture-intent command
    reason: |
      Creates unnecessary workflow complexity; users would need to learn a new command.
      Automatic integration within /speckit.plan is cleaner and less disruptive.
    impact: Would be more explicit but adds user-facing complexity
human_constraints:
  - "Must integrate within /speckit.plan as automatic pre-step; do not create separate command"
  - "Decision records must be stored in plan.md (Phase 1); defer decision ledger to Phase 2"
  - "Approval must block task generation; no auto-proceeding without human decision"
human_rationale: |
  The automatic pre-step approach is the most compatible with Specrew's existing
  planning workflow. It avoids creating a new command and keeps workflow changes minimal.
  Storing decisions in plan.md is simple and auditable; we can upgrade to a separate
  ledger in Phase 2 if needed.
unresolved_questions:
  - question: Should the brief be stored as a separate artifact or presented only in chat?
    deferred_until: "Phase 2 planning; revisit if metrics show need for brief history"
decision_ledger_links: []
approval_authority: architect
decision_status: active
```

---

### Entity 3: Approval Status

**Purpose**: Tracks whether a feature has received checkpoint approval and when, enabling drift detection and enforcement.

**Attributes**:

| Attribute | Type | Description | Required | Constraints |
| --- | --- | --- | --- | --- |
| `feature_id` | string | Reference to the feature spec | ✓ | Must match spec directory name |
| `checkpoint_approved` | boolean | Whether checkpoint approval has been recorded | ✓ | False until Decision Record is created |
| `approval_recorded_at` | datetime | Timestamp when approval was recorded in plan.md | ✓ if approved | ISO 8601 format; empty if not yet approved |
| `approval_recorded_by` | string | Human/role that recorded approval | ✓ if approved | Human name; empty if not yet approved |
| `brief_generation_timestamp` | datetime | When the Architecture Intent Brief was generated | ✓ | Enables traceability |
| `tasks_generation_blocked` | boolean | Whether task generation is blocked pending approval | ✓ | True if approval not yet recorded; False after approval recorded |
| `plan_contains_architecture_intent_review` | boolean | Whether plan.md includes the Architecture Intent Review section | ✓ | Drift detector: False = checkpoint was bypassed |

**Validation Rules**:
- If `checkpoint_approved` is True, then `approval_recorded_at` and `approval_recorded_by` must be non-empty
- If `checkpoint_approved` is False, then `tasks_generation_blocked` must be True
- If `plan_contains_architecture_intent_review` is False, a drift signal is triggered

**Drift Signals**:
1. `plan_contains_architecture_intent_review` is False → Plan was generated without checkpoint
2. `tasks_generation_blocked` is False AND `checkpoint_approved` is False → Task generation was allowed without checkpoint approval
3. Tasks exist in tasks.md but `checkpoint_approved` is False → Checkpoint was bypassed

**Example**:
```yaml
feature_id: 006-human-architecture-checkpoint
checkpoint_approved: true
approval_recorded_at: 2026-05-09T15:00:00Z
approval_recorded_by: Alon Fliess
brief_generation_timestamp: 2026-05-09T14:30:00Z
tasks_generation_blocked: false
plan_contains_architecture_intent_review: true
```

---

## Data Storage and Persistence

### Storage Locations

| Entity | Storage Location | Format | Accessible To |
| --- | --- | --- | --- |
| Architecture Intent Brief | Chat conversation (Phase 1); optional `.specify/templates/architecture-brief-template.md` (Phase 2) | Markdown | Human, Squad agents, implementation reviewers |
| Decision Record | `specs/[###]/plan.md` § Architecture Intent Review | YAML frontmatter + Markdown | Human, Squad agents, implementation reviewers |
| Approval Status | Embedded in plan.md metadata and Architecture Intent Review section | Metadata in YAML frontmatter | Squad agents, implementation reviewers |
| Decision Ledger (Phase 2) | `.squad/decisions.md` (deferred) | YAML or custom ledger format | All agents, implementation reviewers, retrospective analysis |

### Consistency Rules

- The **Source of Truth** for Architecture Intent Review is plan.md. If there is any disagreement between chat conversation, decision ledger, and plan.md, plan.md is authoritative.
- The **Decision Record** is recorded in planning context within `/speckit.plan`, before plan body generation; the finalized plan.md contains the Architecture Intent Review section. Task generation happens after plan.md exists. A drift detector checks this invariant.
- The **Approval Status** in plan.md must be consistent with the presence of a Decision Record. If a Decision Record exists and is marked `active`, then `checkpoint_approved` must be True.

## Entity Relationships and Workflows

### Workflow: Checkpoint → Decision → Plan Body Generation → Implementation

1. **Inside `/speckit.plan`, after spec loading and before plan body generation, Squad generates Architecture Intent Brief** (based on spec.md and codebase analysis)
   - Brief is presented to human in chat
   - Brief has `approval_status: pending_review`

2. **Human reviews brief and provides decisions** (through chat interaction within `/speckit.plan`)
   - Human approves direction (clean approval or approval-with-constraints)
   - Human may reject alternatives, add constraints, or provide clean approval
   - Human's decision is recorded in planning context BEFORE plan body generation proceeds

3. **Plan body generation proceeds with Architecture Intent Review section**
   - Plan.md is generated including Architecture Intent Review section
   - Decision Record is embedded in the Architecture Intent Review section
   - Plan is marked with `checkpoint_approved: true`
   - Approval Status is recorded with timestamp and human

4. **Plan.md is finalized** (checkpoint complete, plan body written)
   - Plan.md now contains both the plan structure AND the Architecture Intent Review

5. **Task generation proceeds AFTER plan.md is finalized** (reading the approved plan.md)
   - Task generator reads Architecture Intent Review section of plan.md
   - Task generator incorporates constraints into task design

6. **Implementation proceeds** with visibility to approved direction
   - Implementation reviewers check tasks and proposals against approved direction
   - Conflicts trigger escalation (return to human with options)

### Relationship: Brief → Decision Record

- One Architecture Intent Brief → One or more Decision Records (if human makes staged decisions)
- One Decision Record → One Architecture Intent Brief (references it as the source of the decision)

### Relationship: Decision Record → Implementation Tasks

- One Decision Record → Many tasks (tasks reference constraints from the decision record)
- Tasks are checked for compliance with constraints during generation and review
- Violations are flagged as drift signals

---

## Validation and Constraints

### Structural Validation

- All required attributes must be present and non-empty
- Enum fields must use controlled vocabulary
- Timestamps must be ISO 8601 format
- Lists must have at least the minimum required items

### Semantic Validation (Traceability)

- `feature_id` must match the actual spec directory
- Brief references in Decision Records must match an existing Architecture Intent Brief
- Constraints in Decision Records must be specific and testable (no vague language)
- Rejected alternatives must correspond to alternatives presented in the brief

### Governance Validation

- `approval_authority` determines who can modify or supersede decisions
- `decision_status: active` decisions must be enforced during task generation
- Drift signals (missing Architecture Intent Review section, premature task generation) must trigger escalation

---

## Future Extensions (Phase 2+)

- **Decision Ledger** (`.squad/decisions.md`): Centralized repository for decisions across all features; enables cross-feature analysis and pattern detection
- **Constraint Enforcement Automation**: Automated linter or policy-as-code system that checks task proposals against recorded constraints
- **Decision Versioning**: Track changes to decisions over time if a feature's direction is revised during implementation
- **Traceability Metrics**: Count of decisions made, approval time, constraint violations, conflicts surfaced, and rework due to hidden architectural assumptions
