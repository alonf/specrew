# Quickstart: Boundary Authorization Prompt Truth + Human Re-entry Packet

**Feature**: 139-boundary-authorization-prompt-truth
**Last verified**: 2026-06-01

## Run it

From the repository root:

```powershell
pwsh -File tests/integration/start-command.ps1
pwsh -File tests/integration/launch-mode-boundary-enforcement.tests.ps1
pwsh -File tests/unit/validate-governance.interaction-model.tests.ps1
pwsh -File .specify/extensions/specrew-speckit/scripts/validate-governance.ps1 -ProjectPath .
```

The exact implementation may add a focused test file. If so, run that file in addition to the commands above.

## Try the canonical scenario

1. Install or run the fixed Specrew build in a clean shell.
   Expected result: `specrew start` uses the fixed prompt generator.

2. Create a fresh downstream project and run:

   ```powershell
   specrew start --host copilot "Create a 0MQ binding for Dapr"
   ```

   Expected result: specify and clarify complete, then the coordinator stops before substantive planning.

3. Answer the same smoke clarifications:

   - `.NET / C#`
   - both input and output binding
   - simple one-way messaging

   Expected result: [spec.md](file:///C:/tmp/Specrew-main-boundary-auth/specs/139-boundary-authorization-prompt-truth/spec.md) has clarification-equivalent decisions, but no fabricated human planning approval.

4. Inspect the stop packet.
   Expected result: it includes `What I just did`, `Why I stopped`, `What needs your review`, `What happens next`, `Discussion prompts`, and `What I need from you`.

5. Inspect the downstream disk state before approval.
   Expected result: `plan.md` is absent or non-substantive, `.squad/decisions.md` has no fabricated approval, and `start-context.json` contains `boundary_enforcement.policy_classes`.

6. Record smoke evidence in `specs/139-boundary-authorization-prompt-truth/smoke/beta3-smoke-evidence.md`.
   Expected result: the artifact records tested version, fresh project path, stop boundary, pre-approval `plan.md` state, packet excerpt, and PASS/FAIL.

## Verify the edge cases

1. Beta2-bad phrase rejection:
   A prompt containing `only gate that HARD-BLOCKS` as a four-gate-only claim must fail regression checks.

2. Auto-chain rejection:
   A prompt containing `continue automatically through` with plan/tasks context must fail when human-judgment boundaries are configured.

3. Thin handoff rejection:
   A handoff missing `Why I stopped`, or asking only `approve?` without discussion prompts, must be non-compliant.

4. Status contradiction:
   A feature artifact with `Status: Approved` and no matching human verdict evidence must be flagged by the narrow check.
