# Research: Descriptive References in Handoffs

**Feature**: `012-descriptive-id-handoffs`  
**Phase**: Phase 0 – Research  
**Branch**: `012-keep-descriptive-refs`  
**Date**: 2026-05-11  
**Status**: Complete — all planning unknowns resolved

---

## Research Question 1 — Where Should the Feature Live to Stay Additive to Feature 007?

### Question
How do we add descriptive references without creating a competing handoff system or weakening the user-facing handoff behavior already established by feature 007?

### Findings

**Feature 007 already defines the active handoff contract.**  
`specs/007-user-facing-progress-handoff/spec.md` establishes the two required semantic fields (`Current progress status` and `Recommended next step`) and the three-section handoff format that current Squad guidance uses.

**The live governance surfaces already exist and are durable.**  
The current contract spans `extensions/specrew-speckit/prompts/coordinator-response.md`, `extensions/specrew-speckit/prompts/coordinator-decision-guidance.md`, `extensions/specrew-speckit/checklists/coordinator-handoff-governance.md`, `specs/001-specrew-product/contracts/coordinator-handoff-template.md`, and the installed Squad startup file `.github/agents/squad.agent.md`.

**The current validator is already non-blocking and compatible with additive growth.**  
`extensions/specrew-speckit/validators/handoff-governance-validator.ps1` emits soft warnings only. This makes it the correct extension point for FR-008 and FR-009 because the spec requires later enforcement to remain non-blocking.

### Decision
**Implement descriptive references as an additive extension of the existing feature 007 handoff-governance surfaces.** Iteration 001 should update the current validator rule, prompts, checklist, template, Squad startup guidance, and worked examples instead of creating a new response format or separate validator lane.

### Rationale
Feature 012 improves readability inside the same authored narration and stop-message surfaces that feature 007 already governs. Extending the current contract preserves user expectations, keeps governance centralized, and satisfies FR-010 and TG-005.

### Alternatives Considered
- Creating a second descriptive-reference validator: rejected — it would duplicate review logic and risk conflicting outcomes.
- Adding a new handoff section or separate response block: rejected — the spec constrains the feature to readability improvements inside existing user-facing narration and stop messages.

---

## Research Question 2 — How Should the Rule Detect Opaque Numeric References Without Becoming Noisy?

### Question
What should count as a missing description, and how should the rule avoid false positives from quoted, verbatim, or tool-rendered content?

### Findings

**The spec defines a narrow input surface.**  
FR-006 and the clarified scope restrict the feature to Squad-authored user-facing narration and stop messages. Verbatim quoted material, code blocks, raw tool output, and Copilot-rendered tool-call result blocks are explicitly excluded.

**The warning threshold is already specified.**  
The clarifications state that the governance readability warning should trigger when authored narration or stop-message prose contains **three or more** numeric identifiers without descriptive scope.

**Grouped references and repeated references have bounded allowances.**  
The spec allows a shared scope statement for a clearly labeled group or range, and later mentions in the same short context may rely on the first nearby explanation.

### Decision
**Use a section-aware authored-prose rule that scans only user-authored narration/stop-message text, ignores excluded surfaces, and warns when three or more numeric references appear without inline or shared descriptive scope.** The rule must cover feature numbers, iteration numbers, task codes, requirement codes, corpus references, and commits.

### Rationale
This decision matches FR-001 through FR-006, FR-008, and FR-009 while keeping the validator low-noise. It also preserves the human-readable intent of the feature by allowing grouped/shared scope where the prose still makes the references understandable on first read.

### Alternatives Considered
- Warning on every single numeric reference without context: rejected — too noisy and contrary to the explicit three-reference threshold.
- Scanning all rendered response text including verbatim/tool blocks: rejected — directly violates FR-006 and FR-009.

---

## Research Question 3 — What Is the Cleanest Iteration Split?

### Question
Does the requested two-iteration split remain the cleanest dependency boundary after reviewing the repository surfaces and feature dependencies?

### Findings

**Guidance and rule changes can ship before replay evidence.**  
The existing validator, checklist, prompts, template, and Squad guidance are already live surfaces. They can absorb the new readable-reference rule without waiting for new replay fixtures or corpus seeding.

**Integration evidence depends on the rule and examples being stable first.**  
Scaffold-replay-path assertions, corpus seeding, and validation-lane polish make more sense once the Iteration 001 rule wording and worked examples are final.

**The user-specified split matches the repo's existing governance workflow.**  
Feature 007 and other recent governance features already separate rule/guidance rollout from replay/hardening evidence.

### Decision
**Keep the feature split to two iterations.**

- **Iteration 001**: new validator detection rule, coordinator prompt updates, checklist/template updates, `.github/agents/squad.agent.md` plus `.squad/templates/squad.agent.md`, and worked examples.
- **Iteration 002**: scaffold-replay-path integration test coverage, corpus seeding, validation-lane/documentation polish, and final low-noise evidence.

### Rationale
This split keeps dependencies clean: the rule and readable examples land first, then the replay/corpus proof is added against a stable behavior set. It also honors the explicit user guidance without inventing extra lifecycle ceremony.

### Alternatives Considered
- One iteration for everything: rejected — mixes rule design with replay/corpus proof and makes low-noise debugging harder.
- Three or more iterations: rejected — no cleaner dependency boundary emerged from research, and the user explicitly preferred two iterations.

---

## Research Question 4 — How Should Validation and Corpus Seeding Stay Bounded?

### Question
How do we plan scaffold-replay-path assertions and corpus seeding without overreaching into blocking governance or scaffolding iteration artifacts during planning?

### Findings

**The current validation lane is already documented.**  
`extensions/specrew-speckit/governance/validation-lane.md` records the authorized commands for the existing handoff-governance validator and integration tests.

**Known-trap history already emphasizes replay-path proof.**  
`.specrew/quality/known-traps.md` and existing trap-reapplication artifacts show a consistent expectation: user-facing governance features should be verified through real replay/runtime paths rather than state-file-only checks.

**The spec keeps later enforcement soft.**  
FR-008 and FR-009 require a non-blocking governance review. Nothing in the approved spec authorizes a blocking failure mode.

### Decision
**Treat scaffold-replay-path assertions, corpus seeding, and validation-lane polish as Iteration 002 work only, and keep all later enforcement bounded to non-blocking governance review.** Plan the future artifact paths, but do not scaffold iteration or quality artifacts during this planning phase.

### Rationale
This keeps the current planning session inside Phase 0 and Phase 1 outputs, matches the user instruction not to scaffold iteration artifacts yet, and still leaves a clear evidence path for SC-004 and TG-006.

### Alternatives Considered
- Scaffolding iteration 001/002 quality artifacts now: rejected — explicitly disallowed by the user.
- Upgrading the validator to a blocking gate during Iteration 002: rejected — outside the approved scope and contrary to FR-008/FR-009.

---

## Summary of Resolutions

| Research Item | Resolution |
| --- | --- |
| Feature placement | Extend the existing feature 007 handoff-governance surfaces; do not create a parallel system |
| Detection model | Scan authored narration/stop-message prose only; warn on 3+ opaque numeric references without descriptive scope; ignore excluded verbatim surfaces |
| Iteration split | Keep two iterations: Iteration 001 for rule/guidance/examples, Iteration 002 for replay tests/corpus/polish |
| Enforcement boundary | Keep all later governance review non-blocking; do not scaffold iteration artifacts during planning |

All planning unknowns are resolved. Phase 1 design may proceed.
