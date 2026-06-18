# Quickstart: Stability and Quality Bundle

**Feature**: 183-stability-quality-bundle
**Last verified**: 2026-06-16

## Run It

Use the development tree, not a global module install:

```powershell
$env:SPECREW_MODULE_PATH = (Get-Location).Path
```

After implementation tasks are complete, run the focused validation set from the
repository root:

```powershell
pwsh -NoProfile -File tests/bootstrap/DirectiveDeliveryCap.Tests.ps1
pwsh -NoProfile -File tests/integration/refocus-deploy.tests.ps1
pwsh -NoProfile -File tests/integration/specrew-hooks-command.tests.ps1
pwsh -NoProfile -File tests/integration/closeout-lifecycle-sync-commands.tests.ps1
pwsh -NoProfile -File .specify/extensions/specrew-speckit/scripts/validate-governance.ps1 -ProjectPath . -ChangedOnly -NoParallel
```

The final test list may be narrowed or expanded in `tasks.md`, but it must cover
FR-001 through FR-007 and SC-001 through SC-009.

## Try the Canonical Scenario

1. Install or refresh hooks in a scratch/project test context.
2. Force a SessionStart payload that would exceed the host cap.
3. Verify the bootstrap fragment survives and lower-priority refocus content is
   dropped or shrunk.
4. Force provider failure.
5. Verify stdout contains a non-empty degraded-governed fallback, exits 0, and
   points to `specrew where` or `/specrew-refocus`.
6. Run the missing-session-ID fixture.
7. Verify no new state is written under global `unknown`.

## Verify Edge Cases

- Missing, blank, and malformed host session IDs resolve to a per-launch token.
- Dirty `.specify/extensions/` plus companion `.specify` files classify
  coherently.
- A branch without an upstream does not say a commit "must be pushed."
- Dashboard auto-detect regenerates the dashboard from current artifacts.
- Antigravity hook config merge preserves existing user hook entries in
  `.agents/hooks.json`.
- Antigravity docs/status do not claim parity for unverified events.

## Manual Release Readiness

Before stable promotion:

1. Inspect local tags, origin tags, and published package/release state.
2. Choose the next valid `0.37.0-beta<N>`.
3. Validate the beta with a real host run for SessionStart/fallback.
4. Validate Antigravity hook behavior on a real host if FR-007 ships.
5. Promote `0.37.0` stable only after validation passes.
