# Quickstart: Devin CLI Host — Clean-Extensibility Proof

**Feature**: 200-devin-cli-host
**Last verified**: 2026-06-24 for the handover spike; implementation commands
are plan-time acceptance instructions.

## Run It

Use the development module:

```powershell
$env:SPECREW_MODULE_PATH = (Get-Location).Path
devin --version
```

After the relevant iteration is implemented, run the focused deterministic
checks from the repository root:

```powershell
pwsh -NoProfile -File tests/integration/host-registry.tests.ps1
pwsh -NoProfile -File tests/integration/host-coupling-firewall.tests.ps1
pwsh -NoProfile -File tests/integration/filelist-completeness.tests.ps1
pwsh -NoProfile -File tests/integration/refocus-deploy.tests.ps1
pwsh -NoProfile -File tests/bootstrap/ConversationCapture.Tests.ps1
pwsh -NoProfile -File scripts/internal/test-publish-harness.ps1
```

Run migration tests only against their scratch fixtures. Do not run
`specrew init` or `specrew update` in this feature worktree.

## Try the Canonical Scenario

1. Confirm the installed CLI reports `devin 2026.7.23 (3bd47f77)`.
2. In a clean disposable project using the prerelease module, run:

   ```powershell
   specrew start --host devin
   ```

3. Verify Devin starts interactively and receives the bootstrap prompt as
   positional input, not through `-p`.
4. Verify SessionStart produces the Specrew orientation/bootstrap context.
5. Submit a normal prompt and verify UserPromptSubmit context delivery.
6. Reach a human-judgment boundary and verify Stop enforces the decision
   response.
7. End the session and verify the handover contains the synthetic user and
   assistant canaries captured through ATIF normalization.

Expected result: all lifecycle events fire, the boundary Stop is governed, and
the unchanged parser reads the normalized conversation. The evidence names the
tested build, OS, mechanism, and bounded result without retaining transcript
content.

## Verify Permission Translation

Replay launch-invocation tests for these mappings:

| Specrew mode | Expected Devin mode |
| --- | --- |
| normal | `auto` |
| autopilot | `smart` |
| allow-all | `dangerous` plus explicit notice |
| autopilot + allow-all | `dangerous` wins |

`devin -p` is used only for bounded automated canaries.

## Verify Edge Cases

- Remove Devin from `PATH`; `specrew start --host devin` must show
  manifest-provided install guidance.
- Seed `.devin/hooks.v1.json` with user entries; install/remove Specrew hooks and
  verify only Specrew-owned rows change.
- Make the hook file malformed; deployment must refuse to overwrite it.
- Plant a Devin-specific shared-core routing literal in the firewall's negative
  fixture; the purity assertion must detect it.
- Run absent, legacy, partial, and current managed-agent migration fixtures;
  each must converge in one run and produce no diff on the second run.
- On Windows, test the direct-`pwsh` hook form. If the pinned CLI still requires
  `sh.exe`, record the explicit experimental constraint rather than reporting
  parity.
