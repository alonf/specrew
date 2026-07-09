# Seed: co-review subtree-scoping for nested-project (governance-root != git-root)

**Feature**: 197-continuous-co-review (follow-on feature/iteration — start CLEAN, not on the iter-007 dogfood session)
**Status**: seed / design-analysis input
**Date**: 2026-06-25
**Maintainer choice**: "Specrew subtree-scoping (proper fix)" — fix Specrew so a project nested in a larger git repo scopes to its OWN subtree.

## Problem

When a Specrew governance root is a SUBDIRECTORY of the git repo (e.g. `iTeach-Avatar/Tools/EnglishIntake`,
`.git` two levels up), the co-review navigator's git operations run against the WHOLE git repo, not the
governance subtree. The iter-007 real-host dogfood proved it: with the git-dir fix (`ef47ef72`) the navigator
*fires*, but it materializes the entire `iTeach-Avatar` tree -> it would review the whole parent repo. The
hollow handover (`boundary:null`, `no-material-change`) is the same root: the session-delta is computed
whole-repo and mis-resolves from the subdir.

Already fixed in iter-007 (do NOT redo): schema-read (`b9b0df92`), trunk detection + git-dir resolution
(`ef47ef72`). Those are the *fire* blockers; this seed is the *scope* fix.

## Approach

Compute the governance root's path WITHIN the git repo once — `git -C <governanceRoot> rev-parse --show-prefix`
(returns e.g. `Tools/EnglishIntake/`; returns EMPTY when governance-root == git-root) — and thread it as a
pathspec through the four git-op surfaces. **The empty-prefix (project == git root) path MUST be unchanged —
that is the common case and every existing test must stay green.**

## The four surfaces to scope

1. **Reviewed-state digest** (`review-run-index-writer.ps1` / `reviewed-state-digest.ps1`): currently
   `git add -A` + `git write-tree` over the whole index. Scope to the subtree — the trickiest: a git tree
   is repo-rooted, so scoping likely means restricting the temp index to `<prefix>` paths (the digest
   already does per-path `git add -f` / `git rm --cached` strip-listing — extend that to confine to the
   prefix) OR `git ls-tree <tree> <prefix>` to derive the subtree id. Pin the exact mechanism in design.
2. **Checkpoint diff / merge-base** (`checkpoint-diff-provider.ps1`, `Get-ContinuousCoReviewMergeBaseAnchor`):
   the merge-base anchor is fine repo-wide; the DIFF that decides "reviewable checkpoint" must be
   `... -- <prefix>` so only subtree changes count.
3. **git-archive materialize** (`isolated-task-launcher.ps1` line ~124): `git archive <tree> -- <prefix>` so
   the read-only worktree contains ONLY the subtree (and `--prefix` strip so the reviewer sees a clean root).
4. **Handover session-delta** (`HandoverStore.ps1` / `specrew-handover-provider.ps1`): the `no-material-change`
   detection must diff `-- <prefix>`; the `boundary:null` half is likely the same subdir mis-resolution —
   confirm whether it's git-scope or a separate context-resolution miss.

## Edge cases / tests

- project == git root -> `--show-prefix` empty -> NO pathspec -> identical to today (regression gate).
- nested 1, 2+ levels; Windows path/pathspec quoting; a project whose subtree has no changes this checkpoint.
- governance root not in a git repo at all (current fail-open must hold).
- Synthetic nested-repo fixture (a subdir governance root) + the normal at-root fixture.

## Deploy note (separate, also filed)

The `specrew` CLI is always the INSTALLED module's command (ignores `SPECREW_MODULE_PATH`); each project
carries an init-time in-project navigator copy that ProjectRoot-shadows the module. So source fixes need
per-project re-sync until that deploy-resolution bug is addressed. Account for it when validating any fix on
a real project.
