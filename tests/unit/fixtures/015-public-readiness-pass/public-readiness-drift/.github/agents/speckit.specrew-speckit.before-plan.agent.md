---
description: Validate requirement readiness before planning
---


<!-- Extension: specrew-speckit -->
<!-- Config: .specify/extensions/specrew-speckit/ -->
# Validate Requirement Readiness

Before planning proceeds, verify the active specification is ready for implementation planning.

## Required checks

1. Confirm the current spec contains explicit requirement statements and that they are actionable.
2. Stop planning if requirements are missing, ambiguous, or still awaiting approval.
3. If iteration artifacts already exist, you may run `pwsh -File .specify/extensions/specrew-speckit/scripts/validate-governance.ps1 -ProjectPath .` for an additional governance check.

## Failure behavior

If readiness is not clear, do not continue to planning. Explain what is missing and direct the user back to spec clarification.