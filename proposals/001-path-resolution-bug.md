---
proposal: 001
title: Path Resolution Bug Fix
status: shipped
phase: phase-1
estimated-sp: 8
shipped-as: feature-009
discussion: tbd
---

# Path Resolution Bug Fix

## Why

Specrew's bootstrap (`specrew-init`) and start (`specrew-start`) scripts had path-resolution issues that affected project initialization and session continuation across different working-directory conventions. The bug surfaced through dogfooding when projects in non-standard locations or with non-ASCII paths failed to bootstrap cleanly.

## What

Hardened path resolution across the Specrew script surface. Normalized handling of:
- Relative vs absolute path inputs
- Trailing-slash variants
- Non-ASCII characters in path segments
- Cross-drive paths (Windows-specific)
- Symlinks and reparse points

Added integration tests covering the corner cases that originally surfaced the bug.

See `specs/009-project-path-resolution/spec.md` for full detail.

## Effort

~8 SP, single iteration.

## Phase placement

Phase 1 — foundational reliability before public flip. Path resolution is a basic correctness concern that affects every Specrew operation.

## Cross-references

- Specification: `specs/009-project-path-resolution/spec.md`
- Composes with: `specrew-init`, `specrew-start`, and `specrew.ps1` entry points

## Status history

- 2026-05-09: candidate captured following dogfooding-discovered bug
- 2026-05-09: status → draft; source spec written
- 2026-05-10: status → active; entered Specrew lifecycle
- 2026-05-10: status → shipped
