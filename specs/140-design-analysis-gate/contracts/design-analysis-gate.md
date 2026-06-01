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

### Public Surface

| Surface | Signature / Shape | Purpose | Errors |
| --- | --- | --- | --- |
| Plan boundary sync | `sync-boundary-state.ps1 -BoundaryType plan -FeatureRef <feature>` | Advances lifecycle state into plan after plan artifacts are committed. | Must fail or hold for new substantive iterations without valid design-analysis evidence. |
| Applicability rule | Simple substantive/trivial rule | Prevents broad historical hard-fails. | Must not unexpectedly break existing/in-flight projects. |
| Error output | Human-readable blocking message | Tells coordinator what artifact/section is missing. | Vague failure output is non-compliant. |

### Invariants

- New substantive iterations require valid design-analysis evidence before plan sync can advance.
- Existing and in-flight features without historical artifacts must not hard-fail solely because this feature was installed.
- Broad validator enforcement is deferred in this slice.
- Boundary-state evidence and artifact evidence must agree about the selected option.

## Lifecycle Guidance

Generated lifecycle instructions and command/workflow metadata must describe the new stop.

### Public Surface

| Surface | Signature / Shape | Purpose | Errors |
| --- | --- | --- | --- |
| Generated start prompt lifecycle guidance | Markdown in `.specrew/last-start-prompt.md` | Tells the coordinator to run design analysis before plan for substantive features. | Missing stop guidance can cause silent design choice. |
| Extension command/workflow metadata | Markdown/YAML command surfaces when low-risk | Gives host-visible command guidance for design-analysis/sync. | Must not expand into full multi-host deployment unless cheap and low-risk. |

### Invariants

- The lifecycle order for substantive features is clarify/before-plan -> design-analysis -> plan.
- Plan must not begin until the design-analysis human decision is recorded.
- Unix install/wrapper and release publish surfaces are excluded.
