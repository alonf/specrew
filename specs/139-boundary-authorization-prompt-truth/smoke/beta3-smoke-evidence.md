# Beta3 Smoke Evidence: Boundary Authorization Prompt Truth

**Feature**: 139-boundary-authorization-prompt-truth
**Status**: automated pre-publish candidate PASS; published beta3 and beta4 Codex host replays FAIL; beta5 package replay exposed D-009; published beta6 Step 11 PASS; stable `v0.30.0` promoted
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
| Result | PASS after published `v0.30.0-beta6` Step 11 replay and release-readiness review; stable `v0.30.0` promoted from `c745258c52c575f4704f4866d2b74b2f50381a5a` |

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

## Published Beta4 Host Replay

After publishing `v0.30.0-beta4`, the clean Codex replay failed Step 11 again:

- The welcome/welcome-back orientation did not show the active installed Specrew version/prerelease, so the human could not verify the session was running `0.30.0-beta4`.
- The prompt still contained shared runtime wording that could imply Squad lifecycle automation for non-Squad hosts, including wording like `while Squad handles the rest of the lifecycle automatically`.
- The approval gate rendered as plain numbered text instead of going through host-specific structured question/menu guidance where the selected host exposes that primitive.

This is D-008 in the iteration drift log. Commit `6507c6af` repaired the common prompt-generation path by rendering version truth, selected host, runtime class, lifecycle position, and host-specific interaction guidance into the actual generated prompt.

## Published Beta5 Package Replay

After publishing `v0.30.0-beta5`, the package-level clean Codex no-launch replay failed before human Step 11 because the generated start context and prompt still reported `0.30.0-beta4`.

Root cause: `specrew start` resolved version truth from `Get-Module -ListAvailable`, which can select a stale installed prerelease when multiple `0.30.0` prereleases exist locally. The published beta5 package manifest itself was stamped `PrivateData.PSData.Prerelease = 'beta5'`, but prompt generation did not prefer the manifest adjacent to the running module.

This is D-009 in the iteration drift log. Commit `79ceb2e8` repairs the runtime version resolver so the running module manifest is authoritative before installed-module fallback, and adds regression coverage for stale same-base prereleases.

## Published Beta6 Replay and Stable Promotion

After publishing `v0.30.0-beta6` from `c745258c52c575f4704f4866d2b74b2f50381a5a`, the human Step 11 replay and release-readiness review passed. Evidence covered Copilot/Squad greenfield, Claude greenfield, Antigravity greenfield, and beta6 release-tree validation at `origin/main` commit `c745258c` / tag `v0.30.0-beta6`.

Release-readiness validation applied Proposal 145 manually. Version/docs surfaces were coherent on the beta6 release tree: `Specrew.psd1`, `.specrew/config.yml`, both extension manifests, [README.md](file:///C:/tmp/Specrew-main-boundary-auth/README.md), and [CHANGELOG.md](file:///C:/tmp/Specrew-main-boundary-auth/CHANGELOG.md) all aligned to `0.30.0`. Selected release gates passed: `boundary-authorization-prompt-truth`, `filelist-completeness`, `start-command`, `start-command-non-interactive-first-run`, `multi-host-lifecycle-smoke`, `host-registry`, `host-detection-ux`, `validation-contract-lane`, full `validate-governance`, markdownlint on public release docs, and PSScriptAnalyzer on beta6-changed PowerShell files.

Stable `v0.30.0` was tagged on the same commit as beta6, published to PowerShell Gallery as `Specrew 0.30.0`, and released as a non-prerelease GitHub Release.

## Non-Blocking Follow-Ups

1. Direct Codex launch can consume stale `.specrew` handoff files when bypassing `specrew start`; defer to the planned host hook / durable handover proposal.
2. Greenfield-new orientation can render empty feature URLs like `specs//` before a feature exists; defer to the next feature set.
3. Full recursive PSScriptAnalyzer timed out locally; beta6-changed files passed and CI remains the release gate.
