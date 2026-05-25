# Quickstart: F-046 Bug-Bash Bundle

**Feature**: `046-046-bug-bash`  
**Last verified**: 2026-05-25  

## Run it

All validation checks can be executed in one pass via:
```powershell
pwsh -File tests/integration/validate-bug-bash.ps1
```

## Try the canonical scenarios

### 1. Verify 'retro' boundary stale-state detection
- In a test workspace, set the boundary to `retro` in `.specrew/start-context.json` and ensure `review.md` is marked accepted.
- Run `pwsh -File scripts/specrew-start.ps1 --no-launch` and verify that no warning or recovery prompt is triggered.

### 2. Verify Scaffolder Protection
- Generate `review.md` with:
  ```markdown
  # Review: Iteration 001
  **Overall Verdict**: accepted
  ```
- Re-run `scaffold-review-artifact.ps1 -IterationDirectory <path>`
- Verify that `review.md` is NOT overwritten, a sibling `review.md.pending` is created, and a console warning is outputted.

### 3. Verify Prose Boundary Translation
- Run:
  ```powershell
  pwsh -File .specify/extensions/specrew-speckit/scripts/sync-boundary-state.ps1 -BoundaryType implement -FeatureRef 046-046-bug-bash
  ```
- Verify that it maps `implement` to `review-signoff` and synchronizes successfully.
