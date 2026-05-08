# Implementer T001 Decision Note

- **Date**: 2026-05-08
- **Iteration**: `specs/005-stack-aware-quality-bar/iterations/003`
- **Task**: `T001`

## Decision

Seed explicit Phase 2 `strength_rank` defaults in iteration-config surfaces with `claude: 30`, `codex: 20`, and `copilot: 10`.

## Why

- T001 only authorizes downstream iteration-config groundwork, so the routing signal had to stay explicit without pulling in later Phase 2 enforcement work.
- A strict numeric ordering keeps `strongest-available` selection deterministic for future routing helpers while remaining easy to override in downstream repos.
- The same ordering is now present in the scaffold template and the repo's dogfooded `.specrew/iteration-config.yml` so bootstrap output and local runtime defaults do not drift.
