# Hardening Gate: Iteration 001

**Schema**: v1  
**Gate ID**: `pre-implementation-hardening`  
**Feature Ref**: `specs/012-descriptive-id-handoffs/spec.md`  
**Iteration Ref**: `specs/012-descriptive-id-handoffs/iterations/001`  
**Requested Review Class**: `strongest-available`  
**Effective Review Class**: (pending sign-off)  
**Overall Verdict**: ready  
**Approval Ref**: —  
**Reviewed By**: pending  
**Reviewed At**: pending  
**Post-Implementation Verification**: pending-post-implementation  
**Verified At**: pending

## Concern Review

| Concern | Category | Status | Evidence Basis | Runtime Evidence Status | Expected Controls | Blocking | Rationale | Approval |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `security-surface` | `security` | `not-applicable` | `not-applicable` | `not-needed` | — | `false` | Iteration 001 extends handoff-governance guidance and validator rules only; no authentication boundaries, privilege checks, or user-controlled paths are introduced. The rule scans authored prose text for patterns and preserves excluded verbatim surfaces. | — |
| `error-handling-expectations` | `error-handling` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | Planning documents fail-closed behavior for validator rule failures (soft warning only, no blocking) and graceful guidance document application (no partial updates). Existing handoff-governance error handling must remain unchanged. | `false` | Iteration 001 introduces a soft-warning rule only, so fail-closed semantics remain: the validator warns but does not block, and guidance surfaces fail open if parsing or application encounters unexpected format. Regression testing ensures existing error paths remain intact. | pending |
| `retry-idempotency-requirements` | `retry-idempotency` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | Planning documents idempotent validator rule execution (safe to re-run validation scan multiple times on the same input) and idempotent guidance updates (safe to re-apply guidance document edits). The validator must be stateless. | `false` | The validator rule is stateless pattern-scanning logic applied to immutable authored prose text. Guidance surface updates are file edits with no transactional dependencies. Both are idempotent by construction. | pending |
| `test-integrity-targets` | `test-integrity` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | Planning documents explicit replay-path coverage for user-facing guidance surfaces (prompts, checklist, contract, Squad startup guidance) and worked examples. Tasks T008 and T011 require spot-check validation against the real validator rule before closeout. Regression commands must pass. | `false` | Iteration 001 does not introduce new integration tests yet (deferred to Iteration 002), but T008 and T011 enforce spot-check validation of guidance surfaces against the real validator. All guidance must be validated against actual output before considered correct. | pending |
| `operational-resilience-concerns` | `operational-resilience` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | Planning documents that the soft-warning rule must gracefully handle edge cases (numeric references that are not identifiers, repeated references in close proximity, long lists with shared scope) without false-positives or false-negatives. Validator rule thresholds are documented. | `false` | The rule applies only to authored prose, thresholds are clearly defined (three-or-more opaque numeric references), and edge cases are covered in specification clarifications and spec.md edge-case section. Rule behavior is deterministic and documented. | pending |
| `validator-detection-correctness` | `validation` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | Planning documents that the validator rule must correctly distinguish between authored-prose references and excluded verbatim surfaces (tool output, quoted blocks, code blocks, Copilot-rendered tool-call result blocks). FR-006 and FR-009 depend on this distinction. Tasks T008 and T011 validate this through spot checks. | `true` | The feature's core value depends on accurately detecting opaque references in authored prose while leaving excluded content alone. If the rule misclassifies surfaces, the feature either warns on false-positives (disruptive) or misses true opaque references (ineffective). Spot-check validation in T008 and T011 is mandatory. | pending |
| `coordinator-prompt-rollout-fidelity` | `prompt-consistency` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | Planning documents that coordinator prompts (`coordinator-response.md`, `coordinator-decision-guidance.md`) must clearly explain the descriptive-reference rule with acceptable and unacceptable examples for both narration (US1) and stop messages (US2). Prompts must match the validator rule behavior exactly. T005 and T009 update prompts; T008 and T011 validate them. | `true` | If prompt guidance drifts from the actual validator rule, authors follow the prompt and unknowingly create prose that the validator warns on. The two must stay synchronized. This is a human-facing guidance problem, not a technical defect, but it blocks effective rollout. | pending |
| `bulk-list-handling-fidelity` | `rule-completeness` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | Planning documents that grouped lists and ranges of numeric references must be allowed to use a single shared scope statement per FR-004 and spec.md clarifications. Validator rule must implement this correctly. Prompts and examples must show acceptable shared scope patterns. T003 (validator), T005/T009 (prompts), and T008/T011 (validation) all depend on this. | `false` | Grouped-list handling is a functional requirement, but it is not a security or blocking gate. The validator must implement it correctly, and guidance must explain it, but validation is straightforward. | pending |
| `tool-call-scope-exclusion` | `scope-boundary` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | Planning documents that the rule explicitly excludes tool-rendered output, Copilot-rendered tool-call result blocks, quoted material, and code blocks from the readability check. FR-006 and FR-009 require this exclusion. Validator rule must implement detection of these surfaces and skip them. T008 and T011 must validate this through examples. | `false` | Scope exclusion is critical for low-noise validation, but it is not a blocking gate. If exclusion is incomplete, the rule becomes noisy. Spot checks in T008 and T011 will catch this before rollout. | pending |
| `us1-integration-with-feature-007` | `compatibility` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | Planning documents that US1 narration guidance must preserve existing feature 007 progress-status and next-step rules. Iteration 001 must not change, remove, or weaken feature 007 guidance. Regression tests (`handoff-governance-jargon-response-test.ps1`, `handoff-governance-plain-language-response-test.ps1`, `handoff-governance-review-file-reference-test.ps1`) serve as the baseline. T001 records the baseline; T008 and T011 must pass the same tests after changes. | `false` | Feature 007 compatibility is critical for adoption, but it is enforced through regression testing, not a blocking architectural gate. If compatibility breaks, the regression tests will catch it before rollout. | pending |

## Pre-Implementation Planning Evidence

### Requirement Traceability

- **FR-001 through FR-007**: Iteration 001 addresses all shared functional requirements for readable references in authored narration and stop messages.
- **US1 (Readable narration)**: Covered by Phase 3 tasks (T005-T008).
- **US2 (Readable stop messages)**: Covered by Phase 4 tasks (T009-T011).
- **US3 (Governance checks reinforcement)**: Deferred to Iteration 002 (T012-T020).
- **FR-008 and FR-009**: Deferred to Iteration 002; non-blocking enforcement remains explicit in Phase 2 task requirements.

### Stack-Ready Analysis

| Stack Surface | Path | In Scope | Evidence |
| --- | --- | --- | --- |
| `handoff-validator` | `extensions/specrew-speckit/validators/handoff-governance-validator.ps1` | Yes | T003 extends the rule; T008 and T011 validate it |
| `coordinator-guidance` | `extensions/specrew-speckit/prompts/*.md`, `extensions/specrew-speckit/checklists/coordinator-handoff-governance.md`, `specs/001-specrew-product/contracts/coordinator-handoff-template.md` | Yes | T004, T005, T009, T010 update guidance; T008, T011 validate |
| `agent-startup-guidance` | `.github/agents/squad.agent.md`, `.squad/templates/squad.agent.md` | Yes | T006, T007 update startup guidance; synchronization enforced in same task |
| `integration-validation` | `tests/integration/**`, `extensions/specrew-speckit/governance/validation-lane.md` | No (Iteration 002) | Deferred to Iteration 002 for replay-path coverage |

### Deferral Justification

**Why Iteration 002 defers replay-path and corpus seeding**:
- Iteration 001 establishes the rule and guidance surfaces.
- Iteration 002 adds replay-path fixtures and corpus seeding once the rule behavior is stable.
- This split preserves the approved two-iteration plan and allows seeded examples to be based on final guidance.
- No blocking enforcement is added; non-blocking nature is preserved throughout.

## Known Unknowns & Planned Mitigations

| Unknown | Mitigation | Status |
| --- | --- | --- |
| How will authors respond to the new shared scope guidance for grouped lists? | Include clear examples of grouped-list shared scope in prompts and worked examples (T005, T009). Spot-check samples (T008, T011) before rollout. | planned |
| Will the existing regression tests catch a validator rule that is too strict or too loose on threshold detection? | Run regression baseline (T001) and re-run after implementation (T008, T011) to verify no breakage. Spot checks on threshold behavior are mandatory. | planned |
| Are there edge cases in opaque-reference detection (e.g., dates, counts, version numbers) that the rule must exclude? | Specification clarifications (spec.md Edge Cases section) and validation during T008/T011 address this. | planned |

## Explicit Later Deferrals

- Replay-path integration tests: Deferred to Iteration 002 (T012-T014).
- Corpus seeding in `.specrew/quality/known-traps.md`: Deferred to Iteration 002 (T015).
- Quality artifacts (`hardening-gate.md` post-implementation update, `trap-reapplication.md`): Deferred to Iteration 002 (T016).
- Blocking enforcement or failure semantics changes: Out of scope; feature remains non-blocking per FR-008 and FR-009.

## Hardening-Gate Status

**Overall Verdict**: ready

**Status**: Pre-implementation planning complete. All planning artifacts (spec.md, plan.md, research.md, data-model.md, quickstart.md, contracts/descriptive-reference-handoff.md) are finalized and in place. Iteration 001 planning artifacts (plan.md, state.md, drift-log.md, this hardening-gate.md) are scaffolded with the canonical richer pre-sign-off convention.

**Required Next Actions**:
1. Spec Steward (Alon Fliess) signs off on this hardening-gate with explicit scope refresh for Iteration 001 (T001-T011, 8 story points).
2. Spec Steward authorizes implementation to begin with T001 (pre-implementation baseline recording).
3. Once implementation is authorized, begin Phase 1 tasks and record baseline before starting shared foundational work in Phase 2.

---

*This gate remains in the pre-sign-off state until explicitly signed by the Spec Steward. Implementation must not begin until this gate is signed and fresh implementation authorization is granted.*
