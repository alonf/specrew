# State Reconciliation: Pre-Plan Dirty Worktree

**Feature**: 168-post-ship-proposal-amendment-discipline
**Recorded**: 2026-06-06
**Boundary**: clarify -> plan
**Purpose**: Classify dirty worktree state before planning so unrelated drift does not enter Feature 168 plan commits.

## Branch Evidence

- Local branch: `168-post-ship-proposal-amendment-discipline`
- Upstream branch: `origin/168-post-ship-proposal-amendment-discipline`
- Last confirmed parity before plan approval: `3bbf078c`

## Legitimate Feature 168 Scope

Only files under `specs/168-post-ship-proposal-amendment-discipline/`, `.specify/feature.json`, `.specrew/last-validator-summary.json`, and lifecycle sync evidence directly produced for Feature 168 may be staged for Feature 168 boundary commits.

Plan work must use path-limited `git add` commands and must not stage unrelated dirty files.

## Dirty Drift Classified Out of Scope

The following dirty paths were present before planning and are not part of Feature 168 plan scope:

- `.codex/agents/implementer.toml`
- `.codex/agents/planner.toml`
- `.codex/agents/retro-facilitator.toml`
- `.codex/agents/reviewer.toml`
- `.codex/agents/spec-steward.toml`
- `.github/agents/squad.agent.md`
- `.squad/casting/registry.json`
- `.squad/config.json`
- `specs/140-unix-native-install/iterations/003/tasks-progress.yml`
- `.cursor/`
- `.specrew/version-check-cache.json`

## Planning Guardrails

- Keep implementation narrow and fixture-driven.
- Prefer synthetic proposal fixtures and tests over touching real shipped proposal bodies.
- Treat the legacy handoff warning for commit `100bfc83` as out-of-scope validator drift.
- Carry FR-006 and FR-015 as release-blocking planning and review constraints.
- Do not rewrite historical shipped proposal bodies.
- Do not reimplement shipped proposal behavior from prior proposal work.
