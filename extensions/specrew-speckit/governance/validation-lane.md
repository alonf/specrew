# Validation Lane

## Purpose

This document records the authorized validation-lane commands for coordinator handoff governance.

## Authorized Commands

| Surface | Command | Purpose |
|---|---|---|
| Handoff governance validator | `pwsh -NoProfile -ExecutionPolicy Bypass -File .\extensions\specrew-speckit\validators\handoff-governance-validator.ps1 -ResponseText $coordinatorResponse` | Runs the soft validator against final coordinator response text and emits soft warnings without blocking response delivery. |
| Jargon-first contract test | `pwsh -NoProfile -ExecutionPolicy Bypass -File .\tests\integration\handoff-governance-jargon-response-test.ps1` | Verifies the validator flags jargon-first leads. |
| Plain-language contract test | `pwsh -NoProfile -ExecutionPolicy Bypass -File .\tests\integration\handoff-governance-plain-language-response-test.ps1` | Verifies the validator passes plain-language-first handoffs. |
| Review-file reference contract test | `pwsh -NoProfile -ExecutionPolicy Bypass -File .\tests\integration\handoff-governance-review-file-reference-test.ps1` | Verifies the validator warns when local file review requests omit the `file:///` URI. |

## Validation Lane Execution

The handoff-governance slice is complete when the authorized validator command and all three handoff-governance integration tests pass from the repository root.

1. Run the validator directly against representative coordinator output when evaluating a final response.
2. Run all three handoff-governance integration tests in the validation lane before iteration closeout.
3. Keep this command list aligned with `specs\007-user-facing-progress-handoff\iterations\002\quality\hardening-gate.md`.
