# Beta3 Smoke Evidence: Boundary Authorization Prompt Truth

**Feature**: 139-boundary-authorization-prompt-truth
**Status**: planned
**Created**: 2026-06-01

## Required Evidence Fields

| Field | Value |
| --- | --- |
| Tested version | TBD during beta3 smoke |
| Fresh project path | TBD during beta3 smoke |
| Host/runtime | Copilot/Squad |
| Feature request | `Create a 0MQ binding for Dapr` |
| Clarify answers | `.NET / C#`; both input and output binding; simple one-way messaging |
| Expected stop boundary | `clarify -> plan` |
| Actual stop boundary | TBD |
| `plan.md` pre-approval state | TBD; must be absent or non-substantive before approval |
| Human re-entry packet excerpt | TBD; must show all six sections |
| `.squad/decisions.md` approval state | TBD; must not contain fabricated planning approval before human approval |
| Result | TBD: PASS or FAIL |

## Acceptance Notes

The smoke passes only if the generated coordinator stops after clarify, asks for plan approval with the six-section human re-entry packet, includes a contextual discussion prompt, and does not create a substantive `plan.md` before explicit human approval.

The smoke fails if the coordinator auto-runs planning, fabricates `Status: Approved`, lacks `Why I stopped`, asks only for approval without discussion prompts, omits targeted review links, or lacks the resolved `boundary_enforcement.policy_classes` snapshot in `start-context.json`.
