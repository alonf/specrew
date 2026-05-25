# Current Architecture: 045-v0271-bugfix-bundle

**Source Iteration Ref**: 001
**Last Updated**: 2026-05-25T15:49:55Z

## Summary

- Latest reviewer snapshot: [iterations/001/](iterations/001/)
- Current reviewer index: [iterations/001/reviewer-index.md](iterations/001/reviewer-index.md)
- Review diagrams: [iterations/001/review-diagrams.md](iterations/001/review-diagrams.md)
- Security surface: not generated; iteration 001 changed local CLI/runtime repair paths and did not add auth, secrets, or network dependency handling.

## Iteration 001 Architecture

- Version alias routing stays in `scripts/specrew.ps1` and delegates to `scripts/specrew-version.ps1`.
- Skill-catalog state and repair logic is centralized in `scripts/internal/skill-catalog-state.ps1`.
- `scripts/specrew-start.ps1` and `scripts/specrew-init.ps1` consume the shared helper while preserving their existing command boundaries.
- Integration tests validate the public command behavior through PowerShell process execution and scratch project fixtures.
