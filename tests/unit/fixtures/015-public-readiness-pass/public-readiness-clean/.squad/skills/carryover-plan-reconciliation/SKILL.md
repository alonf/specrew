---
name: "carryover-plan-reconciliation"
description: "Keep iteration plan carryover narratives, task tables, and capacity sections synchronized"
domain: "governance"
confidence: "high"
source: "earned"
tools:
  - name: "view"
    description: "Read the plan sections that commonly drift apart"
    when: "When checking summary, traceability, task table, and capacity revision together"
  - name: "rg"
    description: "Find all references to carryovers, task counts, and shifted task IDs"
    when: "When inserted tasks may have broken downstream numbering or narrative claims"
---

## Context

Use this when an iteration plan says earlier carryovers were folded in, but the task table or related sections may not actually reflect them.

## Patterns

- Treat every named carryover as untrusted until it appears in the task table with owner, effort, and spec traceability.
- If a carryover derives from authoritative Q&A or design decisions instead of a formal FR, cite those spec anchors explicitly rather than inventing a new FR.
- After adding a missing task, check all downstream numbering-sensitive sections: sequencing, effort calibration, task counts, and capacity-revision math.
- If staging work into an internal 1a/1b split, keep the plan header and total-effort lines on the fully enumerated task-table total; describe the staged slice separately and call any gap below baseline an explicit buffer.
- Correct narrative overclaims mechanically; do not let a capacity note or "in scope" bullet contradict the live task table.

## Examples

- Iteration 1 claimed three carryovers but only listed the agents-detect task. Repair required adding board-management and worktree/PR execution-model tasks, then updating carryover math and shifted task references.

## Anti-Patterns

- Accepting a carryover as "already handled" because a narrative paragraph says so
- Leaving task sequencing or effort notes on old task numbers after inserting new tasks
- Promoting a correction-only carryover into a brand-new FR without a separate spec change
