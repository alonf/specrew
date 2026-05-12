# Hardening Gate: Iteration 001

**Schema**: v1  
**Gate ID**: `pre-implementation-hardening`  
**Feature Ref**: `specs/014-handoff-format-scoping/spec.md`  
**Iteration Ref**: `specs/014-handoff-format-scoping/iterations/001`  
**Requested Review Class**: `strongest-available`  
**Effective Review Class**: `strongest-available`  
**Overall Verdict**: blocked  
**Approval Ref**: —  
**Reviewed By**: —  
**Reviewed At**: —  
**Post-Implementation Verification**: pending  
**Verified At**: —  

## Concern Review

| Concern | Category | Status | Evidence Basis | Runtime Evidence Status | Expected Controls | Blocking | Rationale | Approval |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `security-surface` | `security` | `not-applicable` | `not-applicable` | `not-needed` | Keep the feature limited to local prompt/template/checklist/corpus text and repository-local validator logic; do not add external I/O, credentials, or new trust boundaries. | `false` | Iteration 001 changes only repository-local guidance and additive warning heuristics. No new network, auth, or path-trust surface is introduced beyond the existing repository-root validator scope. | — |
| `error-handling-expectations` | `error-handling` | `planned` | `design-evidence` | `pending` | The new warnings must remain advisory, preserve existing feature-007-style soft-warning formatting, and never convert placeholder or transitional detection into hard validator failure behavior. | `false` | Iteration 001 adds new warning logic on the coordinator-response surface but must preserve current validator output shape and non-blocking semantics while still naming the triggering phrase or pattern. | — |
| `retry-idempotency-requirements` | `retry-idempotency` | `not-applicable` | `not-applicable` | `not-needed` | Keep warning evaluation stateless and read-only so repeated scans of the same response produce the same result without side effects. | `false` | The feature inspects authored response text only and introduces no persistent state or retry workflow. Idempotency is expected by construction. | — |
| `test-integrity-targets` | `test-integrity` | `planned` | `design-evidence` | `pending` | Iteration 001 must preserve the current handoff-governance regression lane and document the deferred deterministic fixture/calibration proof that remains reserved for Iteration 002. | `false` | The source spec intentionally defers violating/compliant fixtures and historical calibration to Iteration 002. Iteration 001 therefore needs an honest bounded test story and a clear deferral line before implementation begins. | — |
| `operational-resilience-concerns` | `operational` | `planned` | `design-evidence` | `pending` | Preserve existing coordinator stop-message behavior for legitimate human-blocked stops, preserve feature 012 readable-reference coverage, and keep the new warnings low-noise and additive. | `false` | Daily-UX improvements only help if legitimate stop messages stay intact and the new warnings do not create noisy false positives that erode operator trust. | — |
| `response-type-selector-correctness` | `validation` | `planned` | `design-evidence` | `pending` | Prompt, checklist, handoff template, and startup guidance must all choose the same response type for first acknowledgements, in-flight waits, true stops, and mixed cases. | `true` | If the selector logic drifts across governed surfaces, the validator and human guidance will contradict one another and the feature will add more confusion rather than reducing it. | — |
| `additive-soft-warning-behavior` | `validation` | `planned` | `design-evidence` | `pending` | `soft-warning.empty-user-action-section` and `soft-warning.transitional-stop-claim` must remain advisory, must not emit on legitimate short actions, and must preserve the current soft-warning workflow and output shape. | `true` | The feature exists to reduce noise, so warnings that block or over-fire would violate the core success criteria and regress the existing handoff-governance workflow. | — |
| `coordinator-surface-rollout-fidelity` | `prompt-consistency` | `planned` | `design-evidence` | `pending` | `.github/agents/squad.agent.md`, `.squad/templates/squad.agent.md`, prompt guidance, and checklist surfaces must all reflect the same top-level coordinator-only scope and the same stop-vs-progress examples. | `true` | The feature directly changes session-loaded coordinator guidance. Misaligned rollout across those files would produce inconsistent runtime behavior and misleading dogfooding evidence. | — |
| `feature012-scope-preservation` | `compatibility` | `planned` | `design-evidence` | `pending` | Updating `human-handoff-id-context` must extend applicability to both governed response types without weakening feature 012's readable-reference expectation or expanding it to excluded surfaces. | `true` | Feature 014 refines the scope statement around feature 012's corpus row. If that update broadens or weakens the rule incorrectly, it will silently regress an already-shipped governance surface. | — |
| `regression-preservation` | `compatibility` | `planned` | `design-evidence` | `pending` | The preserved handoff-governance regression scripts and repo-wide governance validation must stay green after Iteration 001 changes. | `true` | The feature is deliberately additive. Existing handoff-governance checks, readable-reference warnings, and repo governance validation must remain stable after the stop-vs-progress scoping change lands. | — |

## Pre-Implementation Planning Evidence

### Requirement Traceability

- **Selector and worked examples**: FR-001, FR-002, FR-003 via T003-T005
- **Additive soft-warning behavior**: FR-004, FR-005, FR-006 via T006-T008
- **Feature 012 applicability alignment**: FR-007 via T009-T013
- **Validation boundary**: T014-T015 preserve the existing regression lane inside Iteration 001; FR-008 and FR-009 remain deferred to Iteration 002

### Stack-Ready Analysis

| Stack Surface | Path | In Scope | Evidence |
| --- | --- | --- | --- |
| `handoff-validator` | `extensions/specrew-speckit/validators/handoff-governance-validator.ps1` | Yes | T006-T008 |
| `coordinator-prompts` | `extensions/specrew-speckit/prompts/*.md` | Yes | T003-T004 |
| `handoff-template` | `specs/001-specrew-product/contracts/coordinator-handoff-template.md` | Yes | T005 |
| `checklist-surface` | `extensions/specrew-speckit/checklists/coordinator-handoff-governance.md` | Yes | T009 |
| `session-loaded-guidance` | `.github/agents/squad.agent.md`, `.squad/templates/squad.agent.md` | Yes | T010-T011 |
| `governance-corpus` | `.specrew/quality/known-traps.md` | Yes | T012 |

## Deferral Note

- Deterministic violating/compliant fixtures, historical calibration, and the new misapplied-stop trap graduation remain explicitly deferred to Iteration 002.
- The opposite symmetric rule for silent real stops rendered as progress updates remains out of scope for this feature slice.

## Hardening-Gate Status

**Overall Verdict**: blocked

**Scope**: Iteration 001 stop-vs-progress scoping rollout (FR-001 through FR-007) covering selector guidance, additive warning logic, coordinator-surface alignment, and bounded regression validation.

**Pre-Implementation Planning Summary**: Planning is complete for the bounded Iteration 001 slice. The five canonical concerns appear first in the required order. Five feature-specific concerns follow and are all treated as blocking because the slice changes both validator heuristics and session-loaded coordinator guidance. Deterministic fixture proof and trap graduation stay deferred to Iteration 002 and are documented as explicit deferrals rather than hidden omissions. Until a human reviewer signs off on the blocking concerns, the truthful verdict remains `blocked`.

## Sign-Off Evidence

**Authority**: pending  
**Reviewed By**: pending  
**Reviewed At**: pending  
**Evidence Statement**: pending hardening-gate sign-off

---

**Hardening-Gate Planning Status**: planning-phase artifact complete; blocking concerns remain open and the gate stays blocked until human hardening-gate sign-off is recorded.
