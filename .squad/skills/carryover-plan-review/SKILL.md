---
name: "carryover-plan-review"
description: "Review iteration-plan carryover corrections by proving task-table, traceability, capacity, and narrative alignment from the live artifact."
domain: "review"
confidence: "high"
source: "earned"
tools:
  - name: "view"
    description: "Read the live plan and decision artifacts."
    when: "When verifying the exact text and task rows under review."
  - name: "rg"
    description: "Locate carryover tasks, totals, and narrative anchors quickly."
    when: "When checking whether named carryovers appear consistently across plan sections."
  - name: "powershell"
    description: "Compute totals and inspect tracked diffs."
    when: "When validating effort math and confirming no unrelated tracked planning drift."
---

## Context
Use this skill when a plan correction claims that previously missing carryover work has been restored. The reviewer must judge the live plan, not the effort story, and must prove that task-table changes, supporting narrative, and capacity math all agree.

## Patterns
- Start with the live iteration plan. Confirm each named carryover appears as an explicit task row with requirement traceability.
- Check the same carryovers in the summary, acceptance/gate language, capacity revision, scope notes, and sequencing sections. Narrative-only carryovers are drift.
- Recompute the totals from the task table and compare them to the stated total and any staged split (for example Iter 1a / Iter 1b).
- Use decision inbox notes only as supporting evidence that the correction intent was recorded. They do not replace the live plan as the acceptance artifact.
- For “no unrelated drift” checks, inspect the tracked diff and verify changed sections are directly coupled to the carryover restoration and resulting math/text normalization.

## Examples
- `specs\001-specrew-product\iterations\001\plan.md` — live acceptance artifact for task presence, totals, and staged split.
- `.squad\decisions\inbox\picard-board-management-gap.md` and `.squad\decisions\inbox\picard-worktree-execution-gap.md` — intent records proving the two gap corrections were explicitly captured.
- `.squad\decisions\inbox\picard-carryover-correction.md` and `.squad\decisions\inbox\data-carryover-capacity-revision.md` — supporting notes for narrative and capacity normalization.

## Anti-Patterns
- Accepting a correction because a decision note says the work was added without checking the live plan.
- Verifying task presence but skipping the capacity math or staged-split reconciliation.
- Treating unrelated new planning artifacts as part of the correction unless they are present in the tracked diff being reviewed.
