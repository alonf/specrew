# Specrew API Reference

## `Test-FormMeaningParity`

Location: `extensions/specrew-speckit/scripts/shared-governance.ps1`

```powershell
Test-FormMeaningParity -Declared <int> -Observed <int>
```

Returns a `PSCustomObject` with:

- `Declared`
- `Observed`
- `Gap`
- `Severity`

Severity contract:

- `error` when declared work is non-zero and observed changes are zero
- `warning` when declared and observed differ but both are non-zero
- `info` when declared and observed match, including legitimate empty iterations

This is the immutable v1 contract established by Feature 028 for Proposal 030
composition.

## `scaffold-reviewer-artifacts.ps1 -Force`

Location: `extensions/specrew-speckit/scripts/scaffold-reviewer-artifacts.ps1`

```powershell
pwsh -NoProfile -File .\extensions\specrew-speckit\scripts\scaffold-reviewer-artifacts.ps1 `
  -IterationDirectory .\specs\<feature>\iterations\<NNN> `
  -Force
```

Behavior:

- prompts before overwriting generated reviewer artifacts in interactive runs
- honors `-Confirm:$false` for non-interactive automation
- rewrites generated artifacts from the current git diff state

Keep reviewer notes and annotations in `review.md`. Generated reviewer artifacts
are intended to be safely replaceable.
