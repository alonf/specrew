# Data Model: Minimal Design Alternatives / Architecture Intake Gate

**Feature**: 140-design-analysis-gate  
**Date**: 2026-06-02  
**Purpose**: Define the lifecycle, artifact, option, recommendation, decision, and compatibility entities used by the first-slice design-analysis gate.

## Entity: DesignAnalysisBoundary

**Purpose**: Represents the lifecycle stop between clarify/before-plan and plan for substantive iterations.

### Attributes

| Attribute | Type | Required | Validation Rules | Description |
| --- | --- | --- | --- | --- |
| `feature_ref` | string | yes | Must match the active feature directory. | Feature governed by the stop. |
| `iteration_number` | string | yes | Must be normalized, such as `001`. | Iteration requiring the decision. |
| `from_boundary` | string | yes | Expected to be `clarify` or the before-plan readiness position. | Boundary before design analysis. |
| `to_boundary` | string | yes | Expected next substantive boundary is `plan`. | Boundary blocked until decision evidence exists. |
| `applicability` | enum | yes | `required`, `skipped`, or `legacy-compatible`. | Whether the gate applies to this feature/iteration. |

### Lifecycle / Relationships

Created conceptually when a new substantive iteration reaches pre-plan. It owns one `DesignAnalysisArtifact`, which must contain a `HumanDesignDecision` before the `plan` boundary can advance.

## Entity: DesignAnalysisArtifact

**Purpose**: Durable per-iteration record of alternatives, recommendation, and human decision.

### Attributes

| Attribute | Type | Required | Validation Rules | Description |
| --- | --- | --- | --- | --- |
| `path` | string | yes | Must be `specs/<feature>/iterations/<NNN>/design-analysis.md`. | Artifact location. |
| `problem_framing` | markdown section | yes | Must be non-placeholder. | What problem and constraints the options address. |
| `decision_points` | markdown section | yes | Must list at least one design decision point. | Architecture decisions the options compare. |
| `alternatives` | array | yes | Minimum two options. | Simplest, Reasonable, and optionally By-the-book. |
| `crew_recommendation` | markdown section | yes | Must name one option and include rationale. | Crew recommendation before human verdict. |
| `human_decision` | object/section | yes before plan | Must include chosen option, reason/modifications, and commit hash. | Human-selected design evidence. |

### Lifecycle / Relationships

Scaffolded or authored before plan. It references one or more `DesignOption` records, exactly one `CrewRecommendation`, and one `HumanDesignDecision` before plan starts.

## Entity: DesignOption

**Purpose**: A candidate implementation approach compared in the design-analysis artifact.

### Attributes

| Attribute | Type | Required | Validation Rules | Description |
| --- | --- | --- | --- | --- |
| `id` | string | yes | Usually `A`, `B`, or `C`. | Stable option identifier. |
| `flavor` | enum | yes | `Simplest`, `Reasonable`, or `By-the-book`. | Option flavor. |
| `approach` | markdown | yes | Must be substantive. | How the implementation would work. |
| `architectural_pattern` | string | yes | Must name a pattern. | Example: helper plus sync enforcement. |
| `quality_features` | list | yes | Must cite applicable quality concerns. | Security, robustness, test integrity, compatibility, etc. |
| `effort_estimate` | string | yes | Must use the project effort unit or relative band. | Planning cost. |
| `reversibility_cost` | enum/string | yes | Low, Medium, High, or rationale. | Cost to switch later. |
| `trade_offs` | list | yes | Must include upsides and downsides. | Decision comparison. |
| `diagram_ref` | string | yes | Mermaid block or file/link. | Visual representation for the option. |

### Lifecycle / Relationships

Created as part of `DesignAnalysisArtifact`. One option is named by `CrewRecommendation` and one option is selected by `HumanDesignDecision`.

## Entity: CrewRecommendation

**Purpose**: The Crew's preferred option and rationale.

### Attributes

| Attribute | Type | Required | Validation Rules | Description |
| --- | --- | --- | --- | --- |
| `recommended_option` | string | yes | Must match an existing option id/name. | Option the Crew recommends. |
| `rationale` | markdown | yes | Must be non-placeholder and context-specific. | Why the option best fits this iteration. |
| `flip_conditions` | markdown/list | no | Should name conditions that would change the recommendation. | Helps the human evaluate trade-offs. |

### Lifecycle / Relationships

Written before human approval. It informs but does not replace `HumanDesignDecision`.

## Entity: HumanDesignDecision

**Purpose**: Explicit human verdict that authorizes planning from a selected design option.

### Attributes

| Attribute | Type | Required | Validation Rules | Description |
| --- | --- | --- | --- | --- |
| `verdict_text` | string | yes | Must name the boundary and chosen option, e.g. `approved for plan with Option B`. | Human authorization text. |
| `chosen_option` | string | yes | Must match an existing option or named modification. | Selected design path. |
| `reason` | markdown/string | yes | May be concise but must be present. | Human rationale or acceptance of Crew rationale. |
| `modifications` | markdown/string | conditional | Required when the human changes an option. | Any changes to carry into plan. |
| `commit_hash` | string | yes | Must be a boundary evidence commit hash. | Durable evidence hash. |

### Lifecycle / Relationships

Recorded in `DesignAnalysisArtifact` before plan starts. The plan must preserve the selected option and modifications as authoritative design input.

## Entity: ApplicabilityRule

**Purpose**: First-slice rule for deciding whether the gate is required.

### Attributes

| Attribute | Type | Required | Validation Rules | Description |
| --- | --- | --- | --- | --- |
| `slice_class` | enum/string | yes | Simple first-slice labels only. | Substantive, trivial, doc-only, small bug-fix, chore, legacy/in-flight. |
| `requires_design_analysis` | boolean | yes | True for new substantive iterations. | Whether missing artifact blocks plan. |
| `compatibility_reason` | string | conditional | Required for skips or legacy-compatible cases. | Why the gate does not hard-fail. |

### Lifecycle / Relationships

Evaluated before plan-boundary enforcement. It prevents unexpected breaks for existing projects/features while still blocking new substantive iterations.
