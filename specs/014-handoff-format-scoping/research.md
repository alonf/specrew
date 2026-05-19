# Research: Handoff Format Scoping

**Date**: 2026-05-12
**Spec**: [spec.md](spec.md)
**Plan**: [plan.md](plan.md)

## Decisions

### R1: How should the repository distinguish the two governed response types?

**Decision**: Keep exactly two governed coordinator response types at this layer: a **final stop message** that preserves the existing three-section format for genuine human blockers, and an **in-flight progress update** that stays a concise single-line progress note with no user-action section.

**Rationale**: The approved spec explicitly narrows the scope of the three-section stop-message format rather than redesigning it. Existing feature 007 guidance already treats progress status and next step as the core semantics; this feature refines when the full stop surface is appropriate without inventing a second multi-section template for in-flight work.

**Alternatives considered**:

- Add a second structured `Action | Status | Next` progress template: rejected — explicitly ruled out by clarification and FR-003.
- Keep using the three-section format for all coordinator handoffs and rely on softer wording only: rejected — it preserves the current noise problem and does not satisfy FR-001.

---

### R2: Where should the new warning rules be implemented?

**Decision**: Extend the existing `extensions/specrew-speckit/validators/handoff-governance-validator.ps1` warning pipeline rather than creating a parallel validator or separate review command.

**Rationale**: The repository already centralizes coordinator handoff warnings in the existing PowerShell validator, and feature 012 kept additive handoff governance in the same surface. Reusing the current warning output shape preserves compatibility, keeps the rule discoverable in one place, and matches the spec's additive/non-blocking requirement.

**Alternatives considered**:

- Create a second `handoff-format-scoping` validator script: rejected — splits one governance contract across multiple entrypoints and creates avoidable drift.
- Put the rule only in prompt/checklist guidance: rejected — FR-004 and FR-005 require detectable warnings, not guidance alone.

---

### R3: How should placeholder user-action phrases be governed?

**Decision**: Use a fixed repository-maintained literal phrase list in code, tests, and the feature contract. The initial list should cover phrases already natural in current repository wording: `Nothing yet`, `No action needed`, `No action required`, `Nothing to do`, and `No further action needed`.

**Rationale**: The approved clarification explicitly rejects a human-extensible configuration surface for this feature. A small literal list is transparent, testable, and easy for reviewers to audit when a warning fires.

**Alternatives considered**:

- YAML-configurable phrase list: rejected — out of scope and unnecessary for the current bounded feature.
- Semantic/model-based classification of "empty" user action: rejected — conflicts with the repository's deterministic PowerShell governance style.

---

### R4: What should trigger `soft-warning.transitional-stop-claim`?

**Decision**: Treat `Why I stopped` as suspect when it narrates waiting, background work, or an internal transition instead of a true human bottleneck, especially when the response also lacks a substantive human action.

**Rationale**: The spec frames the misuse as transitional narration disguised as a stop. The validator already parses handoff sections, so the cleanest extension is a section-aware check that looks for in-flight wait language in the stop rationale and contrasts it with the presence or absence of a real requested human action.

**Alternatives considered**:

- Warn on every mention of waiting or pending: rejected — legitimate stop messages can include waiting language while still requiring human action.
- Require exact heading text changes alone: rejected — heading choice is not enough; the misuse is semantic.

---

### R5: How should the `human-handoff-id-context` rule change?

**Decision**: Clarify that the readable identifier-context rule applies to both governed response types: the full final stop message and the single-line in-flight progress update.

**Rationale**: Feature 012 introduced the row to keep authored handoff references readable on first pass. Because feature 014 narrows the stop-message scope, the row must follow the broader coordinator-response contract rather than implicitly attaching only to the three-section surface.

**Alternatives considered**:

- Leave the row scoped only to stop messages: rejected — transitional progress narration would remain ambiguous and drift from FR-007.
- Copy the row into a second progress-only rule: rejected — duplicates governance meaning without adding clarity.

---

### R6: Does the planned two-iteration split still hold?

**Decision**: Yes. Preserve the draft's intended split: Iteration 001 defines and rolls out the selector/guidance/warning shape, while Iteration 002 adds deterministic fixtures, historical-sample calibration, validation-lane follow-through, and known-traps graduation.

**Rationale**: The dependency graph is straightforward. Guidance and warning semantics must exist before proving them through replay fixtures and historical calibration, but the proof work does not need to block the initial selector/contract rollout. That makes the original two-iteration split both truthful and clean.

**Alternatives considered**:

- Collapse to one iteration: rejected — mixes contract definition with proof/corpus follow-through and exceeds the approved bounded rollout.
- Split into three iterations: rejected — known-traps graduation and calibration are naturally part of the same proof slice and do not justify a third boundary.
