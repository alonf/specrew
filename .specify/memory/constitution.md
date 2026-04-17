<!--
Sync Impact Report
- Version change: N/A (template) -> 1.0.0
- Modified principles:
  - [PRINCIPLE_1_NAME] -> I. The Spec Is Authoritative
  - [PRINCIPLE_2_NAME] -> II. Specrew Is A Layered System
  - [PRINCIPLE_3_NAME] -> III. Integrate Through Supported Extension Surfaces
  - [PRINCIPLE_4_NAME] -> IV. Compatibility Is A Product Requirement
  - [PRINCIPLE_5_NAME] -> V. Dual-Toolchain Prerequisite
  - Added VI-XXVII as explicit constitutional principles
- Added sections:
  - Operating Constraints
  - Workflow And Delivery Model
- Removed sections:
  - None
- Templates requiring updates:
  - .specify/templates/plan-template.md: ✅ updated
  - .specify/templates/spec-template.md: ✅ updated
  - .specify/templates/tasks-template.md: ✅ updated
  - .specify/templates/commands/*.md: ✅ no files present, no update required
  - .specify/extensions/git/README.md: ✅ no constitution-specific references requiring change
- Follow-up TODOs:
  - None
-->

# Specrew Constitution

## Core Principles

### I. The Spec Is Authoritative

The approved project specification is the primary source of truth for intent.
Implementation, runtime decisions, and team memory MUST NOT silently supersede
the spec. When implementation reality changes, Specrew MUST reconcile the spec
through explicit updates rather than normalize drift.

### II. Specrew Is A Layered System

Specrew MUST preserve a two-layer architecture: a Spec Kit layer for
specification and governance artifacts, and a Squad layer for runtime team
execution, routing, and memory. Changes MUST be assigned to the correct layer.

### III. Integrate Through Supported Extension Surfaces

Specrew MUST rely on supported Spec Kit extension points and Squad extension,
plugin, configuration, or SDK surfaces. Specrew MUST NOT depend on direct hacks
to GitHub Copilot or VS Code behavior as a primary architectural mechanism.

### IV. Compatibility Is A Product Requirement

Specrew MUST preserve forward compatibility with evolving Spec Kit and Squad
versions wherever feasible. Current Copilot-based execution is accepted as an
implementation target, but architecture MUST remain portable to future
Squad-supported coding-agent runtimes.

### V. Dual-Toolchain Prerequisite

Specrew environments MUST satisfy prerequisites for both ecosystems. At minimum,
Python, uv, Git, Node.js, and GitHub Copilot support MUST be available before
normal Specrew workflows are executed.

### VI. Runtime-Layer Technology Neutrality

Specrew MUST remain language-neutral above the runtime layer unless a component
requires specific language features. Configuration, markdown, extension assets,
and scripts MUST be preferred before introducing custom code.

### VII. Artifact Hierarchy Of Authority

The authoritative order MUST be: (1) Constitution, (2) approved specification
artifacts, (3) approved implementation plans, (4) task definitions,
(5) runtime decisions and team memory, (6) source code and generated outputs.
Lower layers MUST NOT override higher layers without reconciliation.

### VIII. Reconciliation Over Silent Divergence

If runtime decisions or implementation discoveries conflict with approved
artifacts, Specrew MUST surface the conflict and require an explicit
reconciliation path.

### IX. Mandatory Feature And Iteration Traceability

Every non-trivial task MUST trace to a feature or user story, an approved spec
or plan, an owning role, and an iteration context.

### X. Non-Interference With External Integrations

Specrew MUST coexist with other Spec Kit and Squad extensions wherever
possible and MUST avoid breaking Jira, Azure DevOps, GitHub Projects,
MCP-based services, and equivalent organizational integrations.

### XI. Explicit Collision Handling

When a hard-stop collision exists, Specrew MUST detect it, report it clearly,
refuse the conflicting activation path, and MUST NOT silently override,
disable, or corrupt other integrations.

### XII. Namespaced Behavior

Specrew commands, hooks, ceremonies, skills, and directives MUST be explicitly
namespaced and scoped to avoid ambiguous ownership and hidden side effects.

### XIII. Required Spec Stewardship

Every Specrew team MUST define explicit spec stewardship responsibility. The
Spec Steward role MAY be dedicated or assigned, but responsibility MUST be
named and auditable.

### XIV. Mandatory Iteration Facilitation

Every team MUST explicitly define responsibility for iteration flow, planning
cadence, blocker management, and retrospective follow-through.

### XV. Human Oversight Is First-Class

Humans MUST remain in approval, prioritization, conflict resolution, and major
reconciliation decisions. Specrew MUST NOT assume autonomous authority over
product or architecture direction.

### XVI. Capacity-Aware Iterations

Every iteration MUST use measurable effort and measurable capacity models.
Accepted units include complexity points, estimated iterations, token budgets,
or another explicitly documented unit used consistently.

### XVII. Planning Starts From Approved Specs

Iteration planning MUST start from approved specification artifacts and linked
stories, requirements, and tasks. Work assignment MUST NOT be driven purely by
ad-hoc prompts or local agent preference.

### XVIII. Explicit Task Ownership

Each task MUST define an owner, ownership rationale, capacity placement, and a
link to the relevant story or planning artifact.

### XIX. Inspectable Delivery Lifecycle

Each iteration MUST include explicit planning, execution, review/demo, and
retrospective steps as ceremonies, artifacts, or both.

### XX. Drift Detection Is First-Class

Specrew MUST actively detect drift across constitution, specification, plan,
tasks, runtime decisions, and implementation outputs.

### XXI. Verification Is Mandatory

No workflow is complete without verification of process quality, artifact
consistency, implementation outcomes, and acceptance-criteria alignment.

### XXII. Governance Over Convenience

When runtime convenience conflicts with constitutional governance, governance
MUST prevail.

### XXIII. Specrew Is Testable As A Product

Specrew MUST include automated evaluation for its own operating model and not
only for generated implementation artifacts.

### XXIV. End-To-End Evaluation Is Mandatory

The evaluation harness MUST support project creation, Specrew bootstrap,
multi-iteration execution, planning and assignment checks, review and
retrospective checks, drift handling, and implementation quality checks.

### XXV. Process And Outcome Are Co-Equal

Testing MUST evaluate process integrity and final project outcome. Successful
execution requires both generated implementation and sound operating behavior.

### XXVI. Constitution Changes Are Intentional

Constitution amendments MUST be explicit, reviewed, justified, and traceable.
Constitution drift is a high-severity governance event.

### XXVII. Specrew Evolves Through Explicit Layer Design

New capabilities MUST be classified as Spec Kit layer behavior, Squad layer
behavior, Specrew team configuration, or out of scope before implementation.

## Operating Constraints

- Specrew MUST use supported extension surfaces instead of direct platform hacks.
- Specrew MUST preserve compatibility with future Spec Kit and Squad evolution.
- Specrew MUST avoid extension interference except under explicit hard collisions.
- Drift detection and reconciliation MUST remain continuously enabled.
- Capacity accounting, spec stewardship, and human oversight MUST be explicit.
- Automated evaluation of process and outcome MUST remain mandatory.

## Workflow And Delivery Model

- Planning inputs MUST originate from approved specification artifacts.
- Tasks MUST include owner, rationale, traceability links, and iteration
  capacity placement before implementation starts.
- Iteration artifacts MUST include planning records, execution logs,
  review/demo evidence, and retrospective outputs.
- Verification gates MUST evaluate artifact consistency, acceptance criteria,
  and governance compliance before completion.

## Governance

- This constitution supersedes conflicting process conventions and runtime
  shortcuts.
- Amendments require documented rationale, explicit review approval, impact
  analysis across templates and commands, and migration notes when needed.
- Semantic versioning policy:
  - MAJOR for backward-incompatible governance changes or principle removals.
  - MINOR for new principles/sections or materially expanded obligations.
  - PATCH for clarifications and editorial refinements only.
- Compliance review expectations:
  - Every plan MUST pass constitution checks before execution phases.
  - Every spec MUST define traceable stories and measurable outcomes.
  - Every task set MUST expose ownership, capacity, and traceability metadata.
  - Every iteration MUST retain inspectable review and retrospective evidence.

**Version**: 1.0.0 | **Ratified**: 2026-04-17 | **Last Amended**: 2026-04-17
