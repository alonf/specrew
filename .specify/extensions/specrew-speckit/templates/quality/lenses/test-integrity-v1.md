# Lens Checklist: test-integrity v1

| Field | Value |
| --- | --- |
| Lens ID | `test-integrity` |
| Version | `v1.0.0` |
| Purpose | Make test quality reviewable beyond coverage counts and align manual review with Phase 1 mechanical heuristics. |
| Default Row Statuses | `pass`, `fail`, `not-applicable`, `advisory` |

## Scope

Use this lens for features that add or change automated tests. Pair it with the mechanical test-integrity checks so human review confirms the test suite proves meaningful behavior rather than test theater.

## Row Status Vocabulary

| Status | Meaning |
| --- | --- |
| `pass` | The test evidence meaningfully validates the intended behavior. |
| `fail` | The tests exist but do not prove the intended behavior or hide failure modes. |
| `not-applicable` | The feature introduces no automated test surface in the reviewed scope; rationale is recorded. |
| `advisory` | Improvement opportunity worth tracking without blocking the Phase 1 slice. |

## Checklist Items

| Item ID | Concern | Concrete Check | Acceptance Criteria | Row Status | Evidence / Notes |
| --- | --- | --- | --- | --- | --- |
| TST-001 | Assertion presence | Review new or changed tests for explicit outcome checks. | Each reviewed test makes at least one concrete assertion on behavior, state, output, or failure semantics. | `pass \| fail \| not-applicable` | |
| TST-002 | Mock realism | Inspect whether tests only prove mocks instead of system behavior. | Tests use mocks or fakes only to isolate boundaries; success does not rely solely on verifying mocked interactions with no externally meaningful assertion. | `pass \| fail \| advisory \| not-applicable` | |
| TST-003 | Failure-path proof | Confirm the suite exercises unhappy paths when the feature adds error handling or guardrails. | Negative-path expectations are asserted where the spec or implementation introduces validation, retries, exceptions, or fallback behavior. | `pass \| fail \| not-applicable` | |
| TST-004 | Broad assertions | Check for catch-all or non-specific success checks. | Tests avoid placeholder assertions such as generic truthiness when a narrower domain assertion is available. | `pass \| fail \| advisory \| not-applicable` | |
| TST-005 | Exception visibility | Review for swallowed or ignored failures inside tests. | Test code fails loudly on unexpected exceptions and does not hide defects behind empty catches or unconditional success paths. | `pass \| fail \| not-applicable` | |
| TST-006 | Determinism | Inspect whether the test depends on uncontrolled time, order, or shared state. | Test outcomes are stable across repeated local runs, with bounded fixtures and explicit setup/cleanup for mutable state. | `pass \| fail \| advisory \| not-applicable` | |

## Upgrade Guidance

When a new class of test theater or weak evidence is found:

1. Add the proposed line item here with concrete acceptance criteria and a note describing the trigger pattern.
2. Review whether the item should be blocking, advisory, or deferred for the active adoption cycle.
3. Bump the semantic version after approval, then update any preset references that need the newer lens revision.
4. Keep the manual checklist aligned with Phase 1 mechanical-check terminology so reviewers can reconcile row-level evidence with machine findings.

## Change Log

| Version | Date | Change | Review Notes |
| --- | --- | --- | --- |
| `v1.0.0` | 2026-05-07 | Initial Phase 1 baseline covering assertions, mock realism, failure-path proof, broad assertions, exception visibility, and determinism. | Aligns manual review with FR-029 test-integrity heuristics without expanding into later-phase workflows. |
