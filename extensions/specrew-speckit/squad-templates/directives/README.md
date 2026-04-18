# Specrew Directives (Squad-Native Templates)

## Overview

This directory contains directive templates that will be merged into agent charters (`.squad/agents/*/charter.md`) in downstream projects by `specrew init`.

## Directives

### Spec Authority

The spec is the authoritative source of truth. Runtime charters tell agents to read the requirement first and treat undocumented deviation as drift.

### Traceability

Every task must trace to authority before assignment. Planning blocks on orphan tasks, stale references, or uncovered in-scope requirements.

### Drift Reporting

The `specrew-drift-check` skill is invoked after each task is completed. Report drift immediately, and pause silent roll-forward on moderate or critical drift.

## Deployment

Directives are governance rules included in agent charters. When `specrew init` creates or updates agents in `.squad/agents/`, it adds Specrew directives under a `## Directives` section.

## Status

**Status**: Active governance directives ready for charter merge

## References

- Contract: [squad-extension.md](../../../../specs/001-specrew-product/contracts/squad-extension.md)
