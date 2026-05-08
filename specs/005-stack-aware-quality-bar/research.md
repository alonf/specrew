# Research: Stack-Aware Quality Bar (Phase 2 / Deferred Quality Gates)

**Date**: 2026-05-08  
**Spec**: [spec.md](spec.md)  
**Plan**: [plan.md](plan.md)

## Carry-Forward Phase 1 Decisions

### R1: Where should versioned presets and lens checklists live?

**Decision**: Continue sourcing presets and lens checklists from `extensions/specrew-speckit/templates/quality/`, then scaffold them into downstream `.specrew/` locations.

**Rationale**: Phase 1 already established this as the extension-owned source of truth. Phase 2 should extend that contract for specialist bug-hunter lenses instead of inventing a second quality-asset pipeline.

**Alternatives considered**:

- Adding an isolated Phase 2-only quality asset store: rejected because it would split authoring and review conventions.
- Storing specialist lens logic only in scripts: rejected because FR-016 through FR-019 require reviewable, versioned checklist evidence.

---

### R2: How should deterministic findings continue to relate to model-based review?

**Decision**: Preserve `mechanical-findings.json` as the deterministic prerequisite artifact and require it to exist before any required model-based lens execution begins.

**Rationale**: FR-019a makes mechanical checks a separate tier that must run first. The accepted Phase 1 findings contract already provides the right machine-readable prerequisite surface.

**Alternatives considered**:

- Folding mechanical findings into lens artifacts: rejected because it would blur the Phase 1/Phase 2 tier boundary.
- Re-running model-based review without deterministic prechecks: rejected because it contradicts FR-019a.

---

## Phase 2 Decisions

### R3: Where should pre-implementation hardening sign-off live?

**Decision**: Record the hardening gate in `specs/<feature>/iterations/<NNN>/quality/hardening-gate.md`, with the feature `plan.md` carrying the planned concern areas and blocking semantics.

**Rationale**: FR-031 through FR-033 require the gate to be reviewable and to block implementation readiness when critical concerns remain unresolved. A dedicated iteration artifact keeps sign-off lifecycle-visible and audit-friendly while the plan remains the authoritative planning surface.

**Alternatives considered**:

- Storing sign-off only in chat or review comments: rejected because it would not be durable or reviewable enough.
- Embedding hardening approval only in `review.md`: rejected because the gate must exist before implementation starts, not only after review.

---

### R4: What artifact shape should specialist bug-hunter lens execution use?

**Decision**: Use per-lens Markdown execution records under `specs/<feature>/iterations/<NNN>/quality/lenses/`, with each file capturing checklist rows, row-level status, focused findings, justified not-applicable treatment, and requested/effective reasoning class.

**Rationale**: FR-019 requires line-by-line checklist execution, and reviewers need a human-readable surface that fits the existing artifact model. Per-lens files keep evidence granular without hiding routing or exception details in a single monolithic document.

**Alternatives considered**:

- One combined “all lenses” report: rejected because it would make row-level review noisy and harder to diff.
- JSON-only lens execution: rejected because FR-019 emphasizes reviewable line-item execution rather than machine-only storage.

---

### R5: How should strongest-available routing be resolved and recorded?

**Decision**: Resolve routing from explicit configuration metadata: `.specrew/iteration-config.yml` remains the source for available agents/access paths, and `.specrew/config.yml` will gain a quality-routing block for default policy and override behavior. Each lens execution record stores both the requested class and effective class.

**Rationale**: FR-038 through FR-040 require the routing policy to be explicit, configurable, and reviewable after execution. Separating availability metadata from policy defaults keeps the design aligned with current Specrew config structure while making the effective routing auditable.

**Alternatives considered**:

- Hard-coding a preferred model in scripts: rejected because it would be opaque and not configurable.
- Recording only the effective class: rejected because reviewers also need to know whether the requested class was downgraded or overridden.

---

### R6: Where should the known-traps corpus live?

**Decision**: Store the corpus in `.specrew/quality/known-traps.md`, seeded from existing Specrew dogfooding findings, prior iteration defect logs, and cross-implementation learnings.

**Rationale**: FR-034 and FR-035 require a persistent, human-readable, versioned quality-governance artifact that survives across iterations. A downstream `.specrew/quality/` location matches the existing governance storage model and keeps project memory separate from feature-local iteration evidence.

**Alternatives considered**:

- Feature-local `specs/<feature>/...` storage only: rejected because the corpus is project-wide.
- Keeping traps only in retrospective notes: rejected because the corpus must be reusable and scanable later.

---

### R7: How should trap reapplication be represented?

**Decision**: Record trap reapplication as an iteration-local `trap-reapplication.md` artifact that lists which new or existing traps were scanned for, the search scope, and the resulting matches or “none found” outcome.

**Rationale**: FR-037 only requires that Specrew support reapplication and offer the scan path; it does not require a separate complex subsystem. A dedicated artifact keeps the behavior reviewable and lets governance verify that the scan offer/result was not silently skipped.

**Alternatives considered**:

- Inline prose inside the known-traps corpus: rejected because it would mix durable trap definitions with iteration-specific scan runs.
- No explicit artifact for reapplication results: rejected because reviewers could not tell whether the offer occurred.
