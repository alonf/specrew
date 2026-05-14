---
proposal: 002
title: Specrew-start Conditional Pause
status: shipped
phase: phase-1
estimated-sp: 7
shipped-as: feature-011
discussion: tbd
---

# Specrew-start Conditional Pause

## Why

`specrew-start` is the canonical session-resume entrypoint, refreshing handoff artifacts and loading session context. But when a previous session has modified session-loaded files (agent charters, Copilot instructions, Spec Kit extension templates), silently auto-continuing into the lifecycle risks running with stale assumptions.

Users wanted Specrew to pause and ask for confirmation when it detects these changes, rather than auto-continuing into possibly-inconsistent state.

## What

Extended `specrew-start` to detect changes to session-loaded files since the last successful session-resume. When changes are detected:
- The script pauses the auto-continue path
- Surfaces a summary of which files changed
- Asks for explicit user confirmation or additional direction before lifecycle work resumes

The check is mechanical (file-modification-time-based), fast, and non-blocking when no changes exist.

See `specs/011-specrew-start-conditional-pause/spec.md` for full detail.

## Effort

~7 SP across 1 iteration.

## Phase placement

Phase 1 — session-resume reliability and explicit handoff control.

## Cross-references

- Specification: `specs/011-specrew-start-conditional-pause/spec.md`
- Composes with: `specrew-start` script, session-loaded file inventory

## Status history

- 2026-05-10: candidate captured after dogfooding revealed silent stale-state risk
- 2026-05-10: status → draft; source spec written
- 2026-05-11: status → active → shipped
