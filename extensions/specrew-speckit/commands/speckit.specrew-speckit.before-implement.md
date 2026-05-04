---
description: "Validate execution readiness before implementation"
---

# Validate Execution Readiness

Before implementation starts, confirm the active iteration artifacts are approved and execution-ready.

## Required checks

1. Confirm the latest iteration plan has an approval verdict and is still the active source of truth.
2. Verify execution is not bypassing unresolved review findings or missing phase artifacts.
3. Run `pwsh -File .specify/extensions/specrew-speckit/scripts/validate-governance.ps1 -ProjectPath .` when iteration artifacts are available.

## Failure behavior

If governance validation fails or approvals are incomplete, stop implementation and report the blocking artifact or verdict.
