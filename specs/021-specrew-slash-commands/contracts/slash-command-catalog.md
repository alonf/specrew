# Contract: Specrew Slash-Command Catalog

**Contract Version**: 1.0.0  
**Feature**: 021-specrew-slash-commands  
**Effective Boundary**: Plan-complete / pre-implementation

## Overview

This contract defines the user-facing `/specrew.*` command catalog, its canonical naming rules, discovery/help behavior, alias semantics, and coexistence guardrails.

## Canonical Namespace Rules

- All v1 commands use the `/specrew.<command>` namespace.
- No dash-style canonical alternatives (for example `/specrew-where`) are introduced.
- New commands may be added only as explicit catalog entries in later features.
- `/specrew.*` remains additive to `/speckit.*`; neither namespace may silently shadow the other.

## v1 Catalog

| Canonical command | Alias of | Backend route / intent | Discovery/help summary | Boundary rule |
| --- | --- | --- | --- | --- |
| `/specrew.where` | — | Existing project-status workflow via `specrew where` / `scripts/specrew-where.ps1` | Show the current Specrew dashboard/status surface | Must not imply lifecycle approval |
| `/specrew.status` | `/specrew.where` | Alias to the same backend and semantic result as `/specrew.where` | Alias for project status | Must remain alias-only |
| `/specrew.update` | — | Existing refresh/update workflow via `specrew update` | Refresh Specrew-managed assets and supported platform baselines | Must not widen update scope beyond documented args |
| `/specrew.team` | — | Existing team-management workflow via `specrew team` | Manage Squad team members and baseline-role composition | Must preserve managed baseline-role rules |
| `/specrew.review` | — | Existing review replay workflow via `specrew review` | Trigger or inspect the review-oriented workflow | Must preserve explicit human review boundaries |
| `/specrew.help` | — | Canonical Specrew catalog/help surface | Show the full Specrew slash-command catalog and next-step guidance | Must never replace `/speckit.*` lifecycle help |
| `/specrew.version` | — | Version/baseline display using installed/runtime and project config state | Show the installed Specrew version and slash-command compatibility state | Must fail clearly when project context is missing or outdated |

## Discovery Contract

### Preferred path

- Host-native `/specrew.` prefix discovery is the preferred experience when the environment supports it.

### Required fallback

- `/specrew.help` is the canonical fallback catalog in every supported environment.
- Broader help surfaces may reference `/specrew.help`, but they must not absorb the full Specrew catalog in a way that obscures `/speckit.*`.

## Deployment Contract

### Source of truth

- Slash-command skill definitions are distribution-managed artifacts in the Specrew source tree.

### Runtime deployment

- Runtime skills are deployed into `.copilot/skills/specrew-*/SKILL.md`.
- Directory naming stays `specrew-*` to preserve namespace clarity and existing Squad-native patterns.

## Alias Contract

- `/specrew.status` is the only alias in v1.
- Alias behavior is semantic parity, not “similar output.”
- Alias routing must preserve the same validation, diagnostics, and dashboard semantics as `/specrew.where`.

## Coexistence Contract

- `/specrew.*` and `/speckit.*` must be usable in the same session.
- A Specrew slash command may never act as authorization to move from specify to plan, plan to tasks, or tasks to implementation/review without an explicit lifecycle command and human approval where required.
- Collision handling must be explicit and non-destructive.

## Compatibility Contract

- Minimum compatibility is the first published Specrew release that ships Feature 021.
- Planning assumes the current repository baseline `0.20.0` is pre-slash-command and the next shipping release becomes the minimum compatible version.
- When compatibility is not met, the user must receive supported remediation guidance rather than a silent no-op.
