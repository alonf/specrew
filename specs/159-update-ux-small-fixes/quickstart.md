# Quickstart: Specrew Update Downgrade Guard and Compatibility Message Cleanup

**Feature**: 159-update-ux-small-fixes  
**Last verified**: 2026-06-05

## Run it

From the repository root:

```powershell
pwsh -File tests/integration/update-command.ps1
pwsh -File tests/integration/slash-command-compatibility.tests.ps1
pwsh -File .specify/extensions/specrew-speckit/scripts/validate-governance.ps1 -ProjectPath .
```

During implementation review, also run the targeted active-message scan:

```powershell
rg -n "0\.24\.0|pre-v0\.24\.0|minimum compatibility is Specrew" scripts extensions tests
```

The scan should only show historical or intentionally hidden implementation references after the cleanup, not routine current-baseline UX claims.

## Try the canonical scenario

1. Create or use the scratch project from `tests/integration/update-command.ps1`.
2. Set the scratch project's `.specrew/config.yml` `specrew_version` to a version newer than the running module version.
3. Run mutating `specrew update --project-path <scratch-project>`.
4. Expected result: the command exits non-zero before mutation and reports both `Update-Module Specrew` and `SPECREW_MODULE_PATH`.
5. Compare `.specrew/config.yml`, `.specify/extensions/**`, `.squad/**`, and generated host/runtime assets before and after the command.
6. Expected result: protected files remain unchanged.

## Verify the edge cases

1. Equal baseline: set project `specrew_version` equal to the running version and run mutating `specrew update`; existing refresh behavior should continue.
2. Newer running module: set project `specrew_version` older than the running version and run mutating `specrew update`; existing forward-update behavior should continue.
3. Info mode: run `specrew update --info --project-path <scratch-project>` with any baseline; output should report state without changing project files.
4. Active compatibility text: run `specrew version --help` and inspect active generated skill/governance templates; normal users should not see `0.24.0` presented as today's minimum baseline.
