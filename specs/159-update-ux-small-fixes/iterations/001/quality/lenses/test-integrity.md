# Test Integrity Lens: Iteration 001

**Feature**: 159-update-ux-small-fixes  
**Lens Ref**: test-integrity@v1.0.0  
**Phase**: review-signoff

## Planned Review

- Negative-path tests must fail if stale update mutates any protected surface.
- Protected-surface checks must use deterministic hashes/snapshots, not only `git status`.
- Equal/newer tests must prove existing update behavior remains intact.
- Active-message tests must work when `rg` is unavailable by falling back to PowerShell `Select-String`.
- Tests must distinguish active generated/routine UX from historical artifacts.
- Tests must not require applying existing stashes.

## Runtime Evidence Needed

- Complete. `pwsh -NoProfile -ExecutionPolicy Bypass -File tests\integration\update-command.ps1` exited 0.
- Complete. `pwsh -NoProfile -ExecutionPolicy Bypass -File tests\integration\slash-command-compatibility.tests.ps1` exited 0.
- Complete. Active-message scan used default `rg` path when available and forced `Select-String` fallback path in the same test.
- Complete. Proposal 145 review claim ledger and gap ledger are recorded in `review-claim-ledger.yml` and `review.md`.

## Verdict

pass
