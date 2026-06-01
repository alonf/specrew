---
proposal: 152
title: Small-Fix Hardening Carveouts (Iteration Padding, Allow-All Safety, Windows Shell Rule)
status: shipped
phase: phase-2
estimated-sp: 2-3
type: small-fix
shipped-as: chore d5e61b36
discussion: queued from F-051 Iteration 2a closeout options on 2026-06-01
---

# Small-Fix Hardening Carveouts

## Why

F-051 Iteration 2a closeout surfaced three small but recurring governance hazards that do not justify a full feature lifecycle:

1. **Iteration padding bug**: `sync-boundary-state.ps1 -IterationNumber 2` could write closeout artifacts under `iterations/2/` and record `iteration: 2`, even though Specrew's artifact convention is `iterations/002/`.
2. **`--allow-all` safety ambiguity**: operator-facing text could imply that tool-call approval bypass also bypasses lifecycle boundary approval.
3. **Bash-on-Windows drift**: coordinator prompts lacked an explicit Windows shell rule, leaving room for Bash syntax or cross-shell file-operation pipelines in PowerShell sessions.

## Shipped Slice

- Normalize numeric iteration values through `Normalize-SpecrewIterationNumber`, preserving `001` and converting `1` to `001` before closed-index, session-state, and dashboard closeout writes.
- Clarify that `--allow-all` controls tool-call approval only and does not bypass lifecycle boundary approval.
- Add a Windows/PowerShell shell rule to generated coordinator prompts: avoid Bash syntax, Unix-only path assumptions, and cross-shell deletion/move pipelines; use PowerShell-native file operations with quoted `-LiteralPath`.

## Acceptance Evidence

- `tests/integration/closed-iteration-index.tests.ps1` covers iteration normalization and closeout sync's use of the normalized value.
- `tests/integration/start-command.ps1` covers the generated prompt text for the `--allow-all` safety carve and Windows shell rule.

## Status History

- **2026-06-01**: Shipped as a Proposal 067 small-fix slice between F-051 Iteration 2a closeout and Iteration 2b opening; renumbered to Proposal 152 during PR merge reconciliation to avoid the existing Proposal 150 draft on main.
