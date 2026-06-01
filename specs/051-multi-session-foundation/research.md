# Phase 0 Research: Multi-Session Foundation

**Feature**: 051-multi-session-foundation
**Date**: 2026-05-31
**Purpose**: Resolve the known unknowns and design decisions that the plan depends on, so the reviewer can see the rationale behind the chosen mechanisms before code lands.

## R1 — Spec-Kit upgrade mechanism (US7 → FR-025 through FR-030)

**Question**: How is Spec-Kit installed in this project, and what is the working path to upgrade 0.8.13 → 0.8.18?

**Findings**: Per the spec Assumptions, this repo uses the deployed-extension pattern — Spec-Kit lives under `.specify/extensions/specrew-speckit/`, not as an npm package. The upgrade must therefore (a) **detect** the install method (FR-026: check for `.specify/extensions/specrew-speckit/`, npm package metadata, or manual files), (b) **select** the matching mechanism (FR-027), (c) replace extension files to 0.8.18 while **preserving local config/customization** under `.specify/` (FR-028), (d) write `speckit_version: "0.8.18"` (FR-029), and (e) run the governance validator to confirm no compatibility warnings (FR-030).

**Decision**: Detection-first upgrade. Validate checksums pre/post and provide rollback instructions on failure, leaving the prior working state intact (Edge Case). The `max_tested` Spec-Kit version was already bumped 0.8.13 → 0.8.18 as an F-051 precursor (commit `ee320e79`), so the compatibility envelope is known.

**Open for iteration 3**: confirm the exact file set the extension upgrade replaces vs. preserves; decide whether to ship a `specrew speckit upgrade` subcommand or fold it into `specrew update`.

## R2 — Machine fingerprinting (FR-043, privacy)

**Question**: How to identify a developer's machine for collision detection without privacy/telemetry concerns?

**Decision**: Derive a **local-only** fingerprint from a combination of hostname + username (+ optional stable system identifier) available in PowerShell (`$env:COMPUTERNAME`, `$env:USERNAME`, or `[System.Environment]::MachineName`). The fingerprint is used solely for in-project collision detection and multi-dev signal aggregation, and is **never transmitted over the network** (FR-043). No hardware UUIDs, MAC addresses, or anything that could leak to telemetry. This keeps the privacy boundary trivially auditable: the value is computed locally, written only to gitignored per-session state, and read only by local collision logic.

## R3 — Atomic writes for race-safe state (Edge Cases, FR-007/FR-012)

**Question**: Two developers claim/start the same feature within milliseconds — how to avoid corrupt state?

**Decision**: Use the PowerShell **write-temp-rename** pattern — write to a sibling `.tmp` file, then `Move-Item -Force` over the target. `Move-Item` is atomic on the same volume, so no reader observes a partial write. If a true race occurs, both writes land as separate entries and the **next refresh detects and surfaces the conflict** rather than silently losing one (Edge Case). This is consistent with the rest of Specrew's state-write discipline and is cheap enough to apply to every state mutation.

## R4 — Stale-lock threshold (FR-011)

**Question**: When is an active-session lock "dead" enough to auto-clear?

**Decision**: **24 hours** of `last_heartbeat_time` staleness. Rationale: balances safety (preserving multi-day feature branches and ordinary overnight/weekend breaks — see the user's known long deep-work sessions) against unblocking worktrees held by obviously-dead/crashed sessions. Before 24h, a warning is shown but work continues; after 24h, the lock is auto-cleared with a notice. Made configurable via `.specrew/config.yml` `stale_lock_threshold_hours` (default 24) for projects with different cadences.

## R5 — Append-only log format (FR-018, SC-006)

**Question**: How to make shared append-only logs mechanically merge-friendly?

**Decision**: **JSON Lines** (one JSON object per line). Appends are atomic line-adds; when two branches both append, a git merge interleaves lines without ambiguous duplicates and with mechanically-resolvable conflicts at worst. Paired with per-iteration decisions splitting (FR-017) and alphabetical FileList sorting (FR-019), this is the three-part anti-conflict tactic that delivers SC-006 (zero/mechanical conflicts on shared governance files).

## R6 — Identity split + brand-new worktree detection (US9/US10 → FR-035 through FR-042)

**Question**: How to stop fresh worktrees from inheriting stale `session_state_*` and triggering spurious A/B/C recovery (the exact friction F-051's own launch hit)?

**Decision**: **Split** `.squad/identity/now.md` — keep shared `focus_area`/body git-tracked, move all `session_state_*` transient fields to a new gitignored `.squad/identity/session-state.yml` (FR-035/036). Migration strips the fields from now.md, writes the split file, commits now.md, and gitignores the new pattern (FR-037). A tracked-file guard greps for `session_state_` in tracked files and errors on leak (FR-038).

**Brand-new detection heuristic** (FR-039): treat the worktree as brand-new when ALL hold — `active-sessions.yml` empty/missing, no recent boundary commits on the current branch, no iteration dirs matching the inherited `feature_path`. Brand-new ⇒ skip A/B/C, go to specify (FR-040). **Genuine inconsistency** (FR-041): inherited `feature_path` mismatches current branch AND iteration dirs exist for it ⇒ show A/B/C. Parallel worktrees are evaluated independently (per-branch local evidence), so each can start fresh without cross-contamination (Edge Case). All signals + decisions logged to `.specrew/session-start.log` (FR-042).

## R7 — `specrew update` version-bump fix (US8 → FR-031 through FR-034)

**Question**: Why does `.specrew/config.yml` `specrew_version` drift from the installed module, and how to fix it?

**Decision**: Read the **installed module version** authoritatively via `Get-Module`/`Get-InstalledModule` (FR-032) and write that exact value to `specrew_version` on `specrew update` (FR-031). Add a `--dry-run` flag to preview without writing (FR-034) and a drift warning at `specrew start` when installed ≠ pinned (FR-033). This closes the SC-005 accuracy gap (0 mismatches after update).

## Out-of-scope confirmations

Proposal 148 Layers 2 (file-surface overlap warning) and 3 (predictive feature-pair selection) are explicitly **out of scope** — F-051 ships only Layer-1 same-feature claim+warning. No cross-project coordination, network locking, or real-time collaborative editing.
