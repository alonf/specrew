# Iteration 009 Drift Log

**Feature**: F-044 | **Iteration**: 009 — Bare file:/// URI Enforcement (Smoke-Test Regression Fix) (LIVE-TRACKED)

## No drift events

iter-009 is a tiny wording-precision iteration (2.5 SP) with explicit user-stated scope. Plan written, executed, closed — no surprises.

## Lessons from this clean iteration

- **Wording precision is its own slice type**: not a feature, not a bug, not a refactor — just tightening template text to remove ambiguity. The methodology cost is small (~30 min for the touch + lint + validate) but the durable record is valuable: future template edits can read this iteration's record to understand WHY the bare-URI requirement is explicit.
- **Smoke-test prep is a high-signal regression discovery moment**: the user found this regression while preparing to run the smoke test, BEFORE actually running it. Calibration insight: the methodology should encourage smoke-test-prep dogfooding even when no manual test will run, because the act of preparing surfaces UX gaps.
