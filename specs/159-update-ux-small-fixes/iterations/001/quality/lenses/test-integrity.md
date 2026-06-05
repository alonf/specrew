# Test Integrity Lens: Iteration 001

**Feature**: 159-update-ux-small-fixes  
**Lens Ref**: test-integrity@v1.0.0  
**Phase**: before-implement planning

## Planned Review

- Negative-path tests must fail if stale update mutates any protected surface.
- Protected-surface checks must use deterministic hashes/snapshots, not only `git status`.
- Equal/newer tests must prove existing update behavior remains intact.
- Active-message tests must work when `rg` is unavailable by falling back to PowerShell `Select-String`.
- Tests must distinguish active generated/routine UX from historical artifacts.
- Tests must not require applying existing stashes.

## Runtime Evidence Needed

- `pwsh -File tests/integration/update-command.ps1`
- `pwsh -File tests/integration/slash-command-compatibility.tests.ps1`
- Active-message scan evidence using `rg` or fallback path.
- Proposal 145 review claim ledger and gap ledger.
