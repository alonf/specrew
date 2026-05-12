# Lens Checklist: security-baseline v1.0.0

## Purpose

Capture the minimum Phase 1 security review expectations for public-facing stacks.

## Line Items

| Check | Acceptance Criteria | Default Status |
| --- | --- | --- |
| Input validation | Inputs are validated or explicitly constrained at boundaries. | pass |
| Secret handling | Secrets are not embedded in tracked source artifacts. | pass |
| Auth surface | Entry points document auth assumptions or explain why none apply. | not-applicable |

## Status Vocabulary

`pass`, `fail`, `not-applicable`, `advisory`

## Upgrade Guidance

Review each added line item before adopting a newer checklist version.

## Change Log

| Version | Change |
| --- | --- |
| v1.0.0 | Fixture baseline for security checklist scaffolding. |
