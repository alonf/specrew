# Hardening Gate: Iteration 001

**Schema**: v1  
**Gate ID**: `pre-implementation-hardening`  
**Feature Ref**: `specs/014-handoff-format-scoping/spec.md`  
**Iteration Ref**: `specs/014-handoff-format-scoping/iterations/001`  
**Requested Review Class**: `strongest-available`  
**Effective Review Class**: `strongest-available`  
**Overall Verdict**: ready  
**Approval Ref**: —  
**Reviewed By**: Alon Fliess  
**Reviewed At**: 2026-05-12  
**Post-Implementation Verification**: pending  
**Verified At**: —  

## Concern Review

| Concern | Category | Status | Evidence Basis | Runtime Evidence Status | Expected Controls | Blocking | Rationale | Approval |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `security-surface` | `security` | `not-applicable` | `not-applicable` | `not-needed` | Keep the feature limited to local prompt/template/checklist/corpus text and repository-local validator logic; do not add external I/O, credentials, or new trust boundaries. | `false` | Iteration 001 changes only repository-local guidance and additive warning heuristics. No new network, auth, or path-trust surface is introduced beyond the existing repository-root validator scope. | — |
| `error-handling-expectations` | `error-handling` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | The new warnings must remain advisory, preserve existing feature-007-style soft-warning formatting, and never convert placeholder or transitional detection into hard validator failure behavior. | `false` | The signed Iteration 001 slice is limited to additive warning logic inside the existing handoff-governance validator surface, so planning can fully specify the error-handling contract before implementation begins: warning text stays non-blocking, existing output shape is preserved, and validation reruns must expose any drift immediately. | — |
| `retry-idempotency-requirements` | `retry-idempotency` | `not-applicable` | `not-applicable` | `not-needed` | Keep warning evaluation stateless and read-only so repeated scans of the same response produce the same result without side effects. | `false` | The feature inspects authored response text only and introduces no persistent state or retry workflow. Idempotency is expected by construction. | — |
| `test-integrity-targets` | `test-integrity` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | Iteration 001 must preserve the current handoff-governance regression lane and document the deferred deterministic fixture/calibration proof that remains reserved for Iteration 002. | `false` | Planning now fixes the bounded evidence contract before code changes begin: Iteration 001 must re-run the preserved handoff-governance regressions and repo governance validation, while deterministic violating/compliant fixtures and calibration remain explicitly deferred to Iteration 002. That combination gives the current slice truthful test coverage without over-claiming the deferred proof surface. | — |
| `operational-resilience-concerns` | `operational` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | Preserve existing coordinator stop-message behavior for legitimate human-blocked stops, preserve feature 012 readable-reference coverage, and keep the new warnings low-noise and additive. | `false` | The signed scope is operationally safe only if real stop messages keep working, the readable-reference rule from feature 012 remains intact, and the new warnings stay low-noise. Planning now captures those resilience constraints as explicit controls so implementation and validation can test them directly rather than infer them later. | — |
| `response-type-selector-correctness` | `validation` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | Prompt, checklist, handoff template, and startup guidance must all choose the same response type for first acknowledgements, in-flight waits, true stops, and mixed cases. | `true` | Human sign-off accepted the bounded selector rollout, so planning now resolves this blocking concern into a concrete implementation contract: all governed coordinator-facing surfaces must classify the same synthetic scenarios the same way, and the iteration cannot be accepted if the selector language drifts between prompt, template, checklist, and startup guidance. | — |
| `additive-soft-warning-behavior` | `validation` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | `soft-warning.empty-user-action-section` and `soft-warning.transitional-stop-claim` must remain advisory, must not emit on legitimate short actions, and must preserve the current soft-warning workflow and output shape. | `true` | The human authorization is limited to additive warnings inside the existing validator workflow. Planning therefore resolves the warning-behavior concern up front: both warnings must stay advisory, keep the existing output contract, and avoid false positives on legitimate short stop messages. | — |
| `coordinator-surface-rollout-fidelity` | `prompt-consistency` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | `.github/agents/squad.agent.md`, `.squad/templates/squad.agent.md`, prompt guidance, and checklist surfaces must all reflect the same top-level coordinator-only scope and the same stop-vs-progress examples. | `true` | The signed scope explicitly includes session-loaded coordinator guidance, so planning must lock the rollout fidelity requirement before those files change. The implementation slice is only acceptable if every coordinator-facing surface uses the same top-level scope, the same stop-vs-progress distinction, and the same example set. | — |
| `feature012-scope-preservation` | `compatibility` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | Updating `human-handoff-id-context` must extend applicability to both governed response types without weakening feature 012's readable-reference expectation or expanding it to excluded surfaces. | `true` | The user authorized only a scope-of-applicability refinement for the existing feature 012 corpus row, not a semantic rewrite. Planning therefore resolves this compatibility concern by fixing the allowed change shape now: extend applicability to both response types, preserve readable-reference semantics, and avoid any expansion to excluded surfaces. | — |
| `regression-preservation` | `compatibility` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | The preserved handoff-governance regression scripts and repo-wide governance validation must stay green after Iteration 001 changes. | `true` | The rollout is intentionally additive and bounded. Planning resolves the blocking regression concern by making the preserved handoff-governance regression lane and repo-wide validator pass a required post-implementation exit condition for Iteration 001. | — |

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

**Overall Verdict**: ready

**Scope**: Iteration 001 stop-vs-progress scoping rollout (FR-001 through FR-007) covering selector guidance, additive warning logic, coordinator-surface alignment, and bounded regression validation.

**Pre-Implementation Planning Summary**: Planning is complete for the bounded Iteration 001 slice. The five canonical concerns appear first in the required order. Five feature-specific concerns follow and are all treated as blocking because the slice changes both validator heuristics and session-loaded coordinator guidance. Deterministic fixture proof and trap graduation stay deferred to Iteration 002 and are documented as explicit deferrals rather than hidden omissions. The human reviewer has now signed off on the bounded Iteration 001 scope, so the truthful pre-implementation verdict is `ready`.

## Sign-Off Evidence

**Authority**: human hardening-gate sign-off and implementation authorization recorded on 2026-05-12  
**Reviewed By**: Alon Fliess  
**Reviewed At**: 2026-05-12  
**Evidence Statement**: "I sign off on the Iteration 001 pre-implementation hardening gate for Feature 014 handoff-format-scoping at file:///C:/Dev/Specrew/specs/014-handoff-format-scoping/iterations/001/quality/hardening-gate.md. The planning boundary at 1aeee29 is validator-green; the four canonical planning artifacts (plan.md, state.md, drift-log.md, hardening-gate.md) are present; and the deliberate omission of review.md and retro.md placeholders during planning is correctly documented in the iteration artifacts as a truthful planning-time boundary given the current validator's lifecycle-advancement detection behavior."

---

**Hardening-Gate Planning Status**: planning-phase artifact complete; hardening-gate sign-off recorded by Alon Fliess on 2026-05-12, and the Iteration 001 slice is authorized to enter implementation.
