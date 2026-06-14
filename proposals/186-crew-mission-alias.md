---
proposal: 186
title: Crew Mission Alias for Multi-Worktree Orientation
status: candidate
phase: phase-2
estimated-sp: 3-5
priority-tier: 1
discussion: surfaced 2026-06-12 while comparing the Feature 174 session-bootstrap worktree with the Feature 182 work-kind governance worktree. The maintainer observed that temporary human names like "BootstrapHandling" would make multi-crew status reports easier to follow than paths or branch names alone.
---

# Crew Mission Alias for Multi-Worktree Orientation

## Why

Specrew now routinely runs more than one active crew/worktree at the same time.
The durable identifiers are technically correct, but awkward in conversation:

- feature number, for example `174`;
- branch name, for example `174-hook-driven-session-bootstrap`;
- worktree path, for example `C:\Dev\Specrew-session-bootstrap`;
- lifecycle boundary and iteration.

Those identifiers are necessary for correctness, but they are not ergonomic when
the maintainer is switching between active crews. During the Feature 174 and
Feature 182 overlap, the maintainer had to refer to full worktree folders to ask
which work should PR first. A short temporary name would make the conversation
clearer:

```text
Crew BootstrapHandling just did...
Crew WorkKindGovernance is waiting at review-signoff...
Crew DocsRefresh opened PR #2595...
```

The alias should improve human orientation without becoming a new source of
lifecycle truth.

## What

Add an optional **crew mission alias**: a short maintainer-provided display name
for a running Specrew mission/worktree.

The alias is:

- worktree-local by default;
- human-facing, not authoritative;
- independent of feature number, branch name, and work kind;
- surfaced in handoff/report headers, status dashboards, and multi-worktree
  comparison output;
- safe to change or clear without rewriting lifecycle history.

Example report header:

```text
Crew: BootstrapHandling
Feature: 174-hook-driven-session-bootstrap
Branch: 174-hook-driven-session-bootstrap
Worktree: C:\Dev\Specrew-session-bootstrap
Boundary: implement / iteration 010
```

Example narrative:

```text
Crew BootstrapHandling completed T003 and is waiting on T004.
Crew WorkKindGovernance is at the formal review boundary.
```

## Proposed Behavior

### Capture

Specrew should allow the alias to be set when a mission starts or resumes:

- `specrew start --mission-alias BootstrapHandling`;
- interactive prompt during multi-worktree start/resume when no alias exists;
- command surface such as `specrew mission alias set BootstrapHandling`;
- command surface such as `specrew mission alias clear`.

The exact command shape can be refined during specification. The requirement is
that a maintainer can assign a short name without editing files manually.

### Storage

Store the alias in worktree-local runtime metadata, not in feature artifacts by
default. Candidate location:

```text
.specrew/runtime/mission-alias.json
```

The stored record should include:

- alias;
- worktree path at capture time;
- branch at capture time;
- feature/iteration if active;
- last updated timestamp.

The alias is a convenience label. The durable truth remains the feature
artifacts, branch, commit history, worktree path, and boundary state.

### Surfacing

When present, the alias should appear in:

- boundary handoff packets;
- "what I just did" / "why I stopped" / "what I need from you" reports;
- `specrew where` / status summaries;
- multi-worktree collision or merge-order reports;
- session bootstrap orientation when resuming an existing worktree;
- PR guidance packets when multiple active crews exist.

The alias should not replace technical identifiers. It should lead the report,
with durable identifiers immediately below it.

### Validation

Validation should be light:

- allow letters, digits, `-`, and `_`;
- reject empty aliases;
- warn on aliases longer than a readable display threshold, such as 32
  characters;
- warn, but do not hard-block, when two active worktrees use the same alias.

## Non-Goals

- Do not make the alias part of lifecycle truth.
- Do not require aliases for single-worktree usage.
- Do not commit aliases by default.
- Do not rename branches, features, specs, PRs, or worktree folders.
- Do not use the alias as an authorization or safety primitive.
- Do not block work because an alias is missing.

## Acceptance Criteria

1. A maintainer can set, update, view, and clear a worktree-local crew mission
   alias through a Specrew command.
2. Session/bootstrap/handoff/status reports display `Crew: <Alias>` when an
   alias exists.
3. Reports still include feature, branch, worktree path, and boundary state so
   the alias cannot hide lifecycle truth.
4. Multi-worktree comparison output can refer to aliases in prose while still
   listing the underlying paths and branches.
5. Duplicate aliases across active worktrees produce a warning that includes the
   colliding paths.
6. A missing alias never fails validation or blocks lifecycle progress.
7. Alias files are treated as runtime-local state and are not staged by default.

## Dependencies and Composition

This proposal composes with:

- Proposal 172 / Feature 174: hook-driven session bootstrap and handover.
- Proposal 166: concurrent development hygiene and active-worktree awareness.
- Proposal 148: collision-aware feature selection.
- Proposal 182: work-kind governance, because aliases can make multiple
  work-kind missions easier to distinguish in reports.

The most natural implementation home is the session-bootstrap and multi-worktree
orientation layer, not the work-kind governance model.

## Implementation Notes

The implementation should be small and operational:

1. Add a worktree-local alias accessor.
2. Add CLI command(s) or start/resume flags for setting and clearing the alias.
3. Add alias display to status and handoff renderers.
4. Add duplicate-alias detection to active-worktree summaries.
5. Add tests for storage, display, duplicate warning, and "missing alias is OK."

This should not require a release-process change beyond the normal feature
release path when implemented.
