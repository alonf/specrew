# Contract: Design Gate Runtime Hardening Public Surface

**Feature**: 141-design-gate-runtime-hardening  
**Stability**: pre-1.0  
**Builds on**: Feature 140 contract file:///C:/Dev/Specrew-design-analysis/specs/140-design-analysis-gate/contracts/design-analysis-gate.md

## Scaffold and Template (Iteration 1)

| Surface | Signature / Shape | Purpose | Errors |
| --- | --- | --- | --- |
| Design-analysis template | `extensions/specrew-speckit/templates/design-analysis.template.md` | Versioned source the scaffold emits; reconciled with the Feature 140 validator contract (TG-007). | A template change that breaks a required section must update the validator/tests and vice versa. |
| Scaffold path | `(ProjectRoot, FeatureRef, IterationNumber) -> path` | Emits `specs/<feature>/iterations/<NNN>/design-analysis.md` from the template if absent. | Must not overwrite an existing filled artifact. |

### Invariants

- A freshly scaffolded artifact passes the Feature 140 validator's structural
  checks once the Crew fills it (single-token recommendation; hyphenated
  `By-the-book`).
- The scaffold never overwrites an existing decision record.

## Pre-Plan Validator (Iteration 1)

| Symbol | Signature / Shape | Purpose | Errors |
| --- | --- | --- | --- |
| Pre-plan validator | `(ProjectRoot, FeatureRef, IterationNumber) -> result {valid, errors, selectedOption}` | Reuses the Feature 140 validation core to check the artifact + Human Decision before `plan.md` is authored. | Returns `valid:false` with actionable, section-named errors; does not mutate lifecycle state. |
| Coordinator enforcement | Generated start-prompt guidance | Instructs the coordinator not to author substantive `plan.md` before `valid:true`. | Missing guidance risks a silent pre-plan bypass. |

### Invariants

- The binding requirement is the outcome: substantive `plan.md` is not authored
  before a valid artifact and a recorded human decision (FR-003, FR-021).
- No host-native hook (Proposal 105) is introduced in this feature.

## Typed Design-Analysis Gate Packet (Iteration 1)

| Symbol | Signature / Shape | Purpose | Errors |
| --- | --- | --- | --- |
| Packet renderer | `(typedFields) -> renderedMarkdown` | Renders the six-section human re-entry packet for the design-analysis gate from typed fields. | Missing required typed field fails before render. |
| Packet validator | `(renderedMarkdown) -> result` | Validates required sections, `file:///` references, and the `approved for plan with Option <X>` verdict shape. | Bare-path references or missing sections fail validation. |
| Durable packet | `specs/<feature>/gates/...` (design-analysis gate only) | Narrow 155-lite stored packet for audit evidence. | Must not generalize to other boundaries (FR-006). |

### Invariants

- Packet capability is scoped to the design-analysis gate only; the full Proposal
  155 multi-boundary system is out of scope.
- The chosen option in the packet matches the artifact's Human Decision and the
  plan input.

## Applicable Lenses (Iteration 1, lightweight read-only)

| Surface | Signature / Shape | Purpose | Errors |
| --- | --- | --- | --- |
| Applicable Lenses section | Read-only references into `extensions/specrew-speckit/templates/quality/lenses/` | Names lenses relevant to the active feature inside `design-analysis.md`. | Absent lens files degrade to "none applicable", never error. |

### Invariants

- Read-only: no project-local overrides, no lens-schema validation, no broad lens
  automation (Proposal 156 deeper scope deferred).

## Smoke-Bundle Surfaces (later iterations)

| Surface | Signature / Shape | Purpose | Errors |
| --- | --- | --- | --- |
| Start-packet path generation | `scripts/specrew-start.ps1` generated paths | Every emitted artifact path has a non-empty feature segment. | No `specs//` empty-segment path (FR-011). |
| Host-conditional wording | `scripts/specrew-start.ps1` generated guidance | Wording reflects only the selected host. | No non-selected-host terminology, e.g. "Copilot approval mode" on Claude (FR-014). |
| Greenfield warning scope | Greenfield/downstream lifecycle warning logic | Emit only genuinely actionable warnings. | No spurious self-host/in-flight warnings in greenfield/downstream (FR-012). |
| Greenfield baseline commit | First-boundary baseline handling | Resolve baseline to a real commit, recorded consistently. | No missing/wrong baseline hash (FR-013). |

### Invariants

- The four smoke defects stay inside this feature (FR-015).
- Unix/wrapper/bootstrap surfaces are untouched except for minimal, explicitly
  scoped, unavoidable fixes; no beta/stable publishing.
