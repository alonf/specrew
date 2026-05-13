---
name: "github-project-status-alignment"
description: "Keep protocol and governance docs aligned to GitHub Projects V2 default Status-field behavior"
domain: "governance"
confidence: "high"
source: "earned"
tools:
  - name: "view"
    description: "Read the governing spec, plan, docs, and automation script sections"
    when: "When protocol wording may have drifted from the implemented board model"
  - name: "rg"
    description: "Find stale board terminology such as custom columns or review-specific lane names"
    when: "When checking for mismatches across artifacts"
---

## Context

Use this when Specrew governance artifacts mention GitHub Projects behavior and reviewer feedback suggests the protocol drifted from the implemented board model.

## Patterns

- Treat `spec.md`, `plan.md`, operational docs, and the sync script as the authority set.
- If the sync script uses the default `Status` field, protocol text must also use `Status`, not custom column names.
- Normalize lifecycle language to the default mapping: `planning` → `Todo`; `executing` / `reviewing` / `retro` → `In Progress`; `complete` / `abandoned` → `Done`.
- Separate board state from issue state: board items use `Status`; mirrored issues may close at terminal completion.

## Examples

- Replace `Backlog column` with `Status = Todo`.
- Replace `In Review column` or `Retrospective column` with `Status = In Progress` when the authoritative mapping keeps those phases in the default in-progress state.
- Replace `Closed column` with `Status = Done` plus mirrored issue closure wording if the automation closes issues.

## Anti-Patterns

- Re-introducing custom columns after spec and automation already standardized on the default board layout
- Describing board movement in a way that disagrees with the sync script
- Treating board state as authoritative over local iteration artifacts
