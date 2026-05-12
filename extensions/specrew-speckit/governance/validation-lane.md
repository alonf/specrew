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
| Readable-narration contract test | `pwsh -NoProfile -ExecutionPolicy Bypass -File .\tests\integration\handoff-governance-descriptive-narration-test.ps1` | Verifies the iteration 001 readable-reference rollout still flags opaque narration and accepts described narration. |
| Readable stop-message contract test | `pwsh -NoProfile -ExecutionPolicy Bypass -File .\tests\integration\handoff-governance-descriptive-stop-message-test.ps1` | Verifies the iteration 001 readable-reference rollout still flags opaque stop messages and accepts described stop messages. |
| Authored-prose replay lane | `pwsh -NoProfile -ExecutionPolicy Bypass -File .\tests\integration\descriptive-reference-authored-prose.ps1` | Replays fixture-backed narration and stop-message samples through the real governance validator path and asserts on `status`, `findings`, and `summary` output. |
| Excluded-surface replay lane | `pwsh -NoProfile -ExecutionPolicy Bypass -File .\tests\integration\descriptive-reference-excluded-surfaces.ps1` | Replays quoted, code-block, raw-tool, and Copilot-rendered tool-call fixtures through the real governance validator path and proves excluded verbatim content stays out of scope. |

## Validation Lane Execution

The descriptive-reference implementation boundary is review-ready when the authorized validator command, the three feature 007 handoff-governance integration tests, the two iteration 001 readable-reference tests, the two iteration 002 replay tests, and `validate-governance.ps1 -ProjectPath .` all pass from the repository root.

1. Run the validator directly against representative coordinator output when evaluating a final response.
2. Run the existing three handoff-governance integration tests plus the readable-reference narration and stop-message tests to preserve feature 007 and iteration 001 behavior.
3. Run the two replay scripts so the new feature 012, descriptive references in handoffs, fixtures exercise the real validator path with assertions on user-visible output.
4. Keep this command list aligned with `specs\012-descriptive-id-handoffs\iterations\002\quality\hardening-gate.md` and the feature-level quality follow-through artifacts.
