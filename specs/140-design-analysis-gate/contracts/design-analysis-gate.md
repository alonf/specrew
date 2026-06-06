# Contract: Minimal Design Alternatives / Architecture Intake Gate Public Surface

**Feature**: 140-design-analysis-gate  
**Stability**: pre-1.0

## Design Analysis Artifact

The public artifact surface is the per-iteration `design-analysis.md` file created before plan for new substantive iterations.

### Artifact Shape

| Surface | Signature / Shape | Purpose | Errors |
| --- | --- | --- | --- |
| `design-analysis.md` | `specs/<feature>/iterations/<NNN>/design-analysis.md` | Durable design decision record before plan. | Missing artifact blocks active plan-boundary advancement for new substantive iterations. |
| Problem framing | Markdown section | Defines problem and constraints. | Missing or placeholder content is invalid. |
| Decision points | Markdown section | Lists design decisions under comparison. | Missing section is invalid. |
| Alternatives | Markdown section with at least two options | Compares Simplest and Reasonable, plus By-the-book when distinct. | Fewer than two options is invalid. |
| Crew recommendation | Markdown section | Names preferred option and rationale. | Empty or placeholder recommendation blocks plan. |
| Human Decision | Markdown section | Records human verdict, chosen option, reason/modifications, and commit hash. | Missing chosen option or commit hash blocks plan. |

### Option Fields

| Field | Required | Contract |
| --- | --- | --- |
| Approach | yes | Must explain how the option works. |
| Architectural pattern | yes | Must name the implementation pattern. |
| Quality features considered | yes | Must cite relevant quality dimensions and deferrals. |
| Effort estimate | yes | Must give a relative or story-point estimate. |
| Reversibility cost | yes | Must indicate cost to switch later. |
| Trade-offs | yes | Must include upsides and downsides. |
| Diagram | yes | Must be an inline Mermaid diagram or a diagram link. |

### Invariants

- Simplest and Reasonable options are required for every required design-analysis artifact.
- By-the-book is conditional and must not be forced when it is not meaningfully distinct.
- The Crew recommendation cannot replace the human decision.
- The human verdict must name the plan boundary and selected option, such as `approved for plan with Option B`.
- The plan must preserve the selected option and modifications as authoritative input.

## Active Plan-Boundary Enforcement

The first-slice enforcement surface is the active plan-boundary sync path.

### Helper API

| Symbol | Signature / Shape | Purpose | Errors |
| --- | --- | --- | --- |
| `Get-SpecrewDesignAnalysisArtifactPath` | `(ProjectRoot, FeatureRef, IterationNumber = 001) -> string` | Resolves the per-iteration artifact path without creating it. | Throws on missing project root or feature ref. |
| `Test-SpecrewDesignAnalysisGateRequired` | `(ProjectRoot, FeatureRef, IterationNumber = 001) -> bool` | Applies the narrow first-slice applicability rule. | Returns false for legacy/in-flight cases that should not hard-fail. |
| `Test-SpecrewDesignAnalysisArtifact` | `(ProjectRoot, FeatureRef, IterationNumber = 001) -> result` | Validates artifact structure, option evidence, recommendation, and Human Decision. | Returns validation errors; does not mutate lifecycle state. |
| `Invoke-SpecrewDesignAnalysisPlanBoundaryGate` | `(ProjectRoot, FeatureRef, IterationNumber = 001) -> result` | Enforces the gate before plan-boundary sync mutates state. | Throws a `[design-analysis-gate]` blocking message on missing or invalid required evidence. |

### Public Surface

| Surface | Signature / Shape | Purpose | Errors |
| --- | --- | --- | --- |
| Plan boundary sync | `sync-boundary-state.ps1 -BoundaryType plan -FeatureRef <feature>` | Advances lifecycle state into plan after plan artifacts are committed. | Must fail or hold for new substantive iterations without valid design-analysis evidence. |
| Applicability rule | Simple substantive/trivial rule | Prevents broad historical hard-fails. | Must not unexpectedly break existing/in-flight projects. |
| Error output | Human-readable blocking message | Tells coordinator what artifact/section is missing. | Vague failure output is non-compliant. |

### Applicability

The active plan-boundary gate is required when any of these conditions are true:

- The target feature/iteration already has a `design-analysis.md` artifact.
- The project baseline is Specrew 0.30.0 or later, the saved session is active on the same feature, the current/last-authorized boundary is specify, clarify, or before-plan, and the spec contains substantive signals such as functional requirements, acceptance scenarios, success criteria, or implementation scope.

The gate is not broadly applied to unrelated active features, legacy fixture projects, or historical/in-flight features solely because the updated helper exists.

### Invariants

- New substantive iterations require valid design-analysis evidence before plan sync can advance.
- Existing and in-flight features without historical artifacts must not hard-fail solely because this feature was installed.
- Broad validator enforcement is deferred in this slice.
- Boundary-state evidence and artifact evidence must agree about the selected option.

## Lifecycle Guidance

Generated lifecycle instructions must describe the new stop. Broader command/workflow metadata is deferred for Iteration 001 after capacity reconciliation.

### Public Surface

| Surface | Signature / Shape | Purpose | Errors |
| --- | --- | --- | --- |
| Generated start prompt lifecycle guidance | Markdown in `.specrew/last-start-prompt.md` | Tells the coordinator to run design analysis before plan for substantive features. | Missing stop guidance can cause silent design choice. |
| Extension command/workflow metadata | Deferred in Iteration 001 | Keeps this slice below capacity while preserving the protected helper/enforcement core. | Must not be implied as implemented before a later slice. |

### Invariants

- The lifecycle order for substantive features is clarify/before-plan -> design-analysis -> plan.
- Plan must not begin until the design-analysis human decision is recorded.
- Unix install/wrapper and release publish surfaces are excluded.
