# Validation Lane

## Purpose

This document records the authorized validation-lane commands for Feature 016's
substantive interaction model and the preserved handoff-governance regression
lane.

## Authorized Commands

| Surface | Command | Purpose |
|---|---|---|
| Feature 016 integration replay | `pwsh -NoProfile -ExecutionPolicy Bypass -File .\tests\integration\substantive-interaction-model-iteration2.ps1` | Replays the Iteration 002 authorization-fidelity, docs/template-truth, navigation-graduation, and post-commit verification scenarios. |
| Feature 016 unit coverage | `pwsh -NoProfile -ExecutionPolicy Bypass -File .\tests\unit\validate-governance.interaction-model.tests.ps1` | Verifies canonical UTC-seconds authoring, commit-reference synchronization helpers, stale-reference scanning, and bare-path severity behavior against both mirrored validator scripts. |
| Repo governance validator | `pwsh -NoProfile -ExecutionPolicy Bypass -File .\extensions\specrew-speckit\scripts\validate-governance.ps1 -ProjectPath .` | Confirms the repository-level governance surfaces stay green on the exact committed tree. |
| Jargon-first contract test | `pwsh -NoProfile -ExecutionPolicy Bypass -File .\tests\integration\handoff-governance-jargon-response-test.ps1` | Preserves feature 007 jargon-first warning behavior. |
| Plain-language contract test | `pwsh -NoProfile -ExecutionPolicy Bypass -File .\tests\integration\handoff-governance-plain-language-response-test.ps1` | Preserves plain-language-first pass behavior. |
| Review-file reference contract test | `pwsh -NoProfile -ExecutionPolicy Bypass -File .\tests\integration\handoff-governance-review-file-reference-test.ps1` | Preserves the `file:///` review-link requirement. |
| Readable-narration contract test | `pwsh -NoProfile -ExecutionPolicy Bypass -File .\tests\integration\handoff-governance-descriptive-narration-test.ps1` | Preserves the additive readable-reference narration rollout. |
| Readable stop-message contract test | `pwsh -NoProfile -ExecutionPolicy Bypass -File .\tests\integration\handoff-governance-descriptive-stop-message-test.ps1` | Preserves the additive readable-reference stop-message rollout. |

## Post-Commit Verification Expectations

Every implementation-boundary rerun must:

1. update `.squad/decisions.md` authorization entries from `pending` to the real
   boundary hash
2. keep `Recorded At` values in canonical UTC seconds precision
3. run a stale-reference scan against the cited `file:///` targets
4. rerun this lane on the exact committed tree before claiming readiness

## Validation Lane Execution

Feature 016 Iteration 002 is implementation-boundary ready when the full command
set above passes from the repository root and the evidence is recorded in
`specs\016-substantive-interaction-model\iterations\002\quality\quality-evidence.md`.
