# Beta3 Smoke Evidence: Boundary Authorization Prompt Truth

**Feature**: 139-boundary-authorization-prompt-truth
**Status**: automated pre-publish candidate PASS; published beta3 Codex host replay FAIL
**Created**: 2026-06-01
**Updated**: 2026-06-01

## Evidence Fields

| Field | Value |
| --- | --- |
| Tested version | Local `0.30.0-beta3` candidate working tree before release tag |
| Fresh project path | `file:///C:/tmp/Specrew-main-boundary-auth/.scratch/f139-beta3-smoke` |
| Host/runtime | `specrew start --no-launch` generated Copilot/Squad handoff artifacts |
| Feature request | `Create a 0MQ binding for Dapr` |
| Clarify answers | Not entered in this automated pre-publish smoke; use `.NET / C#`, both input and output binding, and simple one-way messaging for the manual beta3 host replay |
| Expected stop boundary | `clarify -> plan` |
| Actual stop boundary | Generated lifecycle contract requires `clarify -> plan` human authorization before `before-plan` or substantive `plan.md` generation |
| `plan.md` pre-approval state | PASS: no `plan.md` exists in the fresh project before approval |
| Human re-entry packet excerpt | PASS: generated prompt contains `## What I Just Did`, `## Why I Stopped`, `## What Needs Your Review`, `## What Happens Next`, `## Discussion Prompts`, and `## What I Need From You` |
| Host orientation truth | FAIL in published `v0.30.0-beta3`: clean Codex replay generated an orientation block saying `running on Claude Code` and claiming Crew roles all run inside the session while `start-context.json` recorded `selected_host: codex` |
| `.squad/decisions.md` approval state | PASS: no fabricated planning approval was created by the generated-start smoke |
| `boundary_enforcement.policy_classes` snapshot | PASS: generated `start-context.json` includes the resolved snapshot |
| Beta2-bad hard-block phrase | PASS: generated prompt does not contain `is the only gate that HARD-BLOCKS` |
| Beta2-bad auto-chain phrase | PASS: generated prompt does not contain the old clarify-to-plan/tasks auto-chain instruction |
| Result | FAIL for published beta3 replay; stable promotion blocked until a repaired prerelease is published and Step 11 replay passes |

## Command Output Summary

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File scripts\specrew.ps1 start `
  'Create a 0MQ binding for Dapr' `
  --project-path .scratch\f139-beta3-smoke `
  --no-launch
```

Observed machine-check summary:

```json
{
  "ExitCode": 0,
  "PromptHasClarifyPlan": true,
  "PromptHasSixSections": true,
  "PromptHasBadHardBlock": false,
  "PromptHasBadAutoChain": false,
  "ContextHasPolicyClasses": true,
  "PlanExists": false
}
```

## Acceptance Notes

The smoke passes only if the generated coordinator stops after clarify, asks for plan approval with the six-section human re-entry packet, includes a contextual discussion prompt, and does not create a substantive `plan.md` before explicit human approval.

The smoke fails if the coordinator auto-runs planning, fabricates `Status: Approved`, lacks `Why I stopped`, asks only for approval without discussion prompts, omits targeted review links, or lacks the resolved `boundary_enforcement.policy_classes` snapshot in `start-context.json`.

## Published Beta3 Host Replay

After publishing `v0.30.0-beta3`, the clean Codex replay failed Step 11 because generated prompt orientation was not host-accurate:

- `.specrew/start-context.json` recorded `selected_host: codex`.
- `.specrew/last-start-prompt.md` instructed the visible opener to say `running on Claude Code`.
- The same orientation block claimed the Crew roles all run inside the session, which is false for a Codex host replay without an active Squad/Copilot role runtime.

This is D-007 in the iteration drift log. The repaired prerelease must prove Codex says Codex, non-Copilot hosts do not claim Squad/Copilot role runtime behavior, and Copilot/Squad describes Squad coordination only when the runtime is active.
