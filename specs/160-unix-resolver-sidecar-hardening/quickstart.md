# Quickstart: Unix Resolver Sidecar Hardening Investigations

**Feature**: `160-unix-resolver-sidecar-hardening`
**Last verified**: 2026-06-03

## Run it

After implementation tasks create the fixtures, run:

```powershell
pwsh -NoProfile -File tests/integration/unix-resolver-path-semantics.tests.ps1
pwsh -NoProfile -File tests/integration/managed-runtime-sidecar.tests.ps1
pwsh -NoProfile -File .specify/extensions/specrew-speckit/scripts/validate-governance.ps1 -ProjectPath .
```

If a real Unix/macOS PowerShell environment is available, run the resolver path
test there as the preferred proof surface. Otherwise use the deterministic
fixture evidence emitted by the test.

## Try the Canonical Scenario

1. Run the resolver path test.
   Expected result: the output identifies whether embedded backslash path
   construction is confirmed, not confirmed, or environment-blocked before any
   resolver source change is accepted.
2. Run the managed sidecar test.
   Expected result: the output proves managed files refresh from canonical only
   when a valid marker exists, and user-edited unmanaged files are preserved.
3. Review the iteration evidence.
   Expected result: each suspected issue has a final disposition and any source
   changes are tied to a confirmed repro.

## Verify the Edge Cases

- Remove or omit a managed sidecar from a host-native file in the scratch
  fixture. Expected result: the deploy logic preserves the file and reports a
  preserve notice.
- Change canonical charter content while a managed marker is present. Expected
  result: the deployed managed file refreshes to canonical content.
- Run the resolver path fixture without real Unix/macOS access. Expected result:
  the evidence states deterministic fixture coverage or records
  environment-blocked status rather than guessing.
