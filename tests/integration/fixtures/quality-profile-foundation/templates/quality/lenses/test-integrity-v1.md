# Lens Checklist: test-integrity v1.0.0

## Purpose

Capture the minimum Phase 1 expectations for trustworthy automated verification evidence.

## Line Items

| Check | Acceptance Criteria | Default Status |
| --- | --- | --- |
| Assertions present | Tests include explicit assertions on observable behavior. | pass |
| No swallowed failures | Test helpers do not hide failing outcomes. | pass |
| Meaningful coverage | Evidence demonstrates more than a mock-only smoke check. | advisory |

## Status Vocabulary

`pass`, `fail`, `not-applicable`, `advisory`

## Upgrade Guidance

Review stricter assertion expectations before adopting a newer test-integrity checklist version.

## Change Log

| Version | Change |
| --- | --- |
| v1.0.0 | Fixture baseline for test-integrity checklist scaffolding. |
