---
proposal: 035
title: Session-State Durability & In-Flight Progress Tracking
status: draft
phase: phase-2
estimated-sp: 30
discussion: tbd
---

# Session-State Durability & In-Flight Progress Tracking

## Why

Specrew's session-state mechanism (`.specrew/last-start-prompt.md`, `.specrew/start-context.json`, `.squad/identity/now.md`) only updates at `specrew start` time, never at boundary events. Two empirical failure modes:

1. **2026-05-16 F-017 mid-implementation reboot**: Squad on restart loaded stale `.specrew/last-start-prompt.md` (still pointing at long-closed F-016), proposed re-authorizing already-shipped F-016 closeout work. Actual F-017 in-flight work in a separate worktree was invisible.

2. **2026-05-18 F-019 closeout cycle**: Closeout-artifact consistency cascade — Squad spent ~30+ minutes reconciling 5 governance artifacts (`closeout.md`, `retro.md`, `state.md`, `.squad/identity/now.md`, `.squad/decisions.md`) that disagreed about whether the iteration was closed. Each correction pass fixed one file's stale references but revealed another's. Captured as L6 lesson in F-019 Iter 2 retro.

Plus user-visible UX gap: `specrew where` (Velocity Dashboard, F-017) cannot report accurate in-flight state because no authoritative durable in-flight state file exists; it best-effort scans iteration directories instead.

## What

Source spec drafted at file:///C:/Dev/SpecrewDraft/session-state-durability.md (~280 lines, ready for `/speckit.specify` ingestion).

### Five pillars

1. **Boundary-event state synchronization** — every lifecycle boundary commit atomically updates `.specrew/last-start-prompt.md`, `.specrew/start-context.json`, `.squad/identity/now.md`. Closeout transitions to "no active feature" or next-queued.

2. **Mid-iteration per-task progress** — `.specrew/in-flight.yml` captures which T-task is active, last-completed, with timestamps. Survives Squad restart.

3. **Cross-worktree state awareness** — discovery mechanism so the main repo knows which worktrees have features in flight (recommended: pure derivation from `git worktree list`).

4. **Stale-state detection at `specrew start`** — verify session-state consistency with reality (branch + feature + claimed boundary + auth record). On staleness, stop and ask for re-orientation; NEVER silently act.

5. **Substantive recovery prompts** — on resume, prompt clearly states "you're at boundary X of iteration Y; here's what was last done; here's the next valid action." Closes the original 2026-05-15 session-resume-handoff-gap UX issue.

### Scope additions (confirmed 2026-05-18)

- **Module-vs-project version mismatch check** (~3 SP, no network): when installed Specrew differs from project's bootstrapped `specrew_version`, warn at `specrew start` with copy-paste `specrew update` command. Non-blocking.
- **Installed-vs-PSGallery latest check** (~3-5 SP, cached daily): when PSGallery has a newer version, warn with `Update-Module Specrew` command. Cache in `.specrew/`, refresh max once per 24h. Skippable via `--skip-update-check` or `SPECREW_SKIP_UPDATE_CHECK=1`.

**Design constraint**: NO interactive yes/no prompt for either check. Interactive prompts break automation. Warn + copy-paste command is sufficient.

### Out of scope

- Multi-developer state reconciliation (that's Proposal 010's territory; this feature is single-developer)
- Auto-updating templates or modules without explicit user action

## Effort

- **Iteration 1** (~12-15 SP): boundary-event sync + stale-state detection + module-vs-project version check
- **Iteration 2** (~12-15 SP): mid-iteration progress + cross-worktree + recovery prompts + PSGallery version check
- **Total**: ~25-30 SP

## Phase placement

**Phase 2**, slot after F-019 (Specrew Distribution Module, shipped). Top priority of remaining Phase 2 work. Source spec ready; just needs `/speckit.specify` ingestion to begin.

## Open questions

1. Active-write vs derived-state for session-state files? (Recommended: active-write + stale-state detection)
2. Per-task progress location: inline in `tasks.md` or sibling `tasks-progress.yml`? (Recommended: sibling `tasks-progress.yml`)
3. Cross-worktree mechanism? (Recommended: pure derivation from `git worktree list`)
4. Stale-state failure mode: prompt vs auto-correct? (Recommended: user re-anchoring prompt, NEVER silently act)
5. Companion bug-fix: chore commit vs in-iteration? (Recommended: small chore immediately to touch `.squad/identity/now.md` at feature-closeout; feature formalizes the pattern across all 7 boundaries)
6-10: full clarify-time question set in the source spec.
6. Should module-vs-project version check be ALWAYS on or opt-out? (Recommended: always on; check is free + warning non-blocking)
7. Should `specrew init` perform the PSGallery latest-version check? (Recommended: yes, with shared cache)

## Risks

- Atomic multi-file updates across `.specrew/` and `.squad/` could fail mid-write; need transactional pattern (write-temp-then-rename) or accept best-effort with stale-detect compensation.
- Cross-worktree state via `git worktree list` is read-only; can't enforce single-worktree invariants. Acceptable for single-developer scope.

## Cross-references

- Composes with [009](009-velocity-dashboard.md) (Velocity Dashboard reads new state files for accurate in-flight rendering — small ~3-5 SP dashboard rendering follow-up after this ships)
- Composes with [017](017-learning-loop-closure.md) (recovery prompt content can include corpus-row references)
- Extends [002](002-specrew-start-conditional-pause.md) (file-change detection → content-staleness detection)
- Predecessor: Phase 5 Multi-Developer Reconciliation needs reliable single-developer state durability first
- Source artifact: file:///C:/Dev/SpecrewDraft/session-state-durability.md

## Status history

- 2026-05-16: captured as memory after F-017 reboot incident
- 2026-05-18: priority elevated by user; F-019 closeout L6 lesson reinforced motivation; status promoted to draft proposal
