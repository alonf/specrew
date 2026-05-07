---
description: Verify task-to-requirement traceability after task generation
---


<!-- Extension: specrew-speckit -->
<!-- Config: .specify/extensions/specrew-speckit/ -->
# Verify Task Traceability

After task generation completes, confirm the produced task set still traces cleanly to approved requirements.

## Required checks

1. Verify each task maps to at least one requirement or user story.
2. Flag orphaned tasks, missing ownership, or missing effort estimates before execution begins.
3. If iteration artifacts are present, you may run `pwsh -File .specify/extensions/specrew-speckit/scripts/validate-governance.ps1 -ProjectPath .` to support the review.

## Failure behavior

If traceability is incomplete, stop and report the missing links so the task plan can be corrected before execution.