# Lens Checklist: robustness-baseline v1.0.0

## Purpose

Capture the minimum Phase 1 robustness review expectations for resilient feature delivery.

## Line Items

| Check | Acceptance Criteria | Default Status |
| --- | --- | --- |
| Failure handling | Errors surface a deterministic response path. | pass |
| Cleanup | Resource cleanup expectations are explicit where resources are acquired. | advisory |
| Retry rationale | Retry or no-retry decisions are documented for risky operations. | not-applicable |

## Status Vocabulary

`pass`, `fail`, `not-applicable`, `advisory`

## Upgrade Guidance

Review new resilience checks before moving the project to a newer lens version.

## Change Log

| Version | Change |
| --- | --- |
| v1.0.0 | Fixture baseline for robustness checklist scaffolding. |
