# Changelog

Retroactive alpha release history for shipped Specrew features. `.specrew\config.yml`
is the canonical source for the active version; this file records the feature
baseline that each release number represents.

## Unreleased

## 0.23.0 - Legacy State Read Tolerance

- Feature 023: closed the legacy state read-tolerance feature with the full validator, documentation, fixture-corpus, and closeout-template scope delivered on the feature branch. The originally planned Iteration 2 slice (T025-T031) was absorbed into Iteration 001 instead of being deferred, so the truthful delivery total is 17 SP planned / 17 SP delivered / 0 SP variance.
- Generated the canonical feature-closeout dashboard snapshot at `specs/023-legacy-state-read-tolerance/closeout-dashboard.md` and cleared active feature identity via the existing feature-closeout scaffold path.
- Rule 15 version management: bumped `Specrew.psd1` `ModuleVersion`, `.specrew/config.yml`, and both Specrew Spec Kit extension manifests to `0.23.0`, then reran governance validation and legacy state reader regression evidence on the closeout tree.
- Added PSGallery prerelease publishing primitives so release automation can stamp `Specrew.psd1` `PrivateData.PSData.Prerelease` for prerelease tags, clear it again when promoting the same baseline to stable, and keep dry-runs/worktree safety scoped to the staged manifest path without mutating the checked-out manifest.
- Completed the `workflow_dispatch` publishing path so prerelease publish, stable publish, and prerelease promotion can safely resolve/create lightweight tags, detect divergent tag targets before publishing, and open GitHub Releases across all real tag-based publish modes.
- Shipping PR: #269 (`Feature 023: close legacy state read tolerance at 0.23.0`).

## 0.22.0 - F-020 Implementation Hotfix + Schema Parity Tests

- Feature 022: F-020 implementation hotfix + schema parity tests. Fixes three production bugs surfaced post-F-021 ship: (1) closeout-helper schema mismatch — `Set-FeatureCloseoutIdentityNow` writes human-readable frontmatter without the `session_state_*` machine-readable fields the stale-state validator requires; (2) boundary-sync hook-coverage gap — `Invoke-SpecrewBoundaryStateSync` not invoked at all 7 lifecycle boundaries (last sync entry for F-021 was at plan-boundary); (3) stale-state recovery UX broken — `specrew start` prints A/B/C options without accepting input.
- Adds three standalone PowerShell integration tests at `tests/integration/closeout-identity-schema-parity.tests.ps1`, `tests/integration/lifecycle-boundary-sync.tests.ps1`, and `tests/integration/start-recovery-flow.tests.ps1` that compose into Proposal 054's pre-merge gate scenarios.
- Shipping PR: #268

## 0.21.0 - Specrew Slash-Command Surface

- Feature 021: Introduced first-class `/specrew.*` slash-command surface with seven
  v1 commands: `/specrew.where`, `/specrew.status`, `/specrew.update`, `/specrew.team`,
  `/specrew.review`, `/specrew.help`, and `/specrew.version`. Aliases: `/specrew.status`
  is a canonical alias for `/specrew.where`.
- Command discovery and help fallback for environments where host-native command
  suggestions are unavailable or incomplete.
- Routing to intended Specrew capabilities with explicit argument validation and
  compatibility checking. Commands fail clearly with remediation guidance when
  prerequisites are missing.
- Integration with standard Specrew distribution and setup flows; slash-command
  surface provisioned as part of `specrew init` and `specrew update`.
- Coexistence with `/speckit.*` commands; no lifecycle advancement bypasses, no
  namespace collisions.
- Minimum compatibility pin to 0.21.0; incompatible baselines detected and reported
  with upgrade guidance.
- Shipping PR: #260 (`Feature 021: Specrew slash-command surface`).

## 0.20.0 - Session-State Durability & In-Flight Progress Tracking

- Feature 020: Made session state durable and surfaced in-flight progress so Squad resumes cleanly after reboot, restart, or closeout. Shipped across two iterations (31 SP delivered, 0 SP variance).
- Iteration 1 (16 SP) — boundary-event state synchronization at all 7 lifecycle boundaries via `Invoke-SpecrewBoundaryStateSync` and `scripts/internal/sync-boundary-state.ps1`; stale-state detection at `specrew start` (merged-feature, missing-branch, missing-authorization, cross-file mismatch cases); module-vs-project version mismatch warning with exact "Module version mismatch detected" capturable text via `Write-Output`.
- Iteration 2 (15 SP) — durable task-progress tracking in `tasks-progress.yml`; cross-worktree awareness via `specrew where --worktrees` derived from `git worktree list`; substantive welcome-back prompts at `specrew start` including last completed task, in-progress task, and validator warning summary; PSGallery latest-version check (cached daily, skippable via `--skip-update-check` flag or `SPECREW_SKIP_UPDATE_CHECK` env var, silent on network failure).
- New internal helpers under `scripts/internal/`: `sync-boundary-state.ps1`, `task-progress.ps1`, `worktree-awareness.ps1`, `version-check.ps1`, `coordinator-resume.ps1`. Session-state schema v1 contract at `specs/020-session-state-durability/contracts/session-state-schema.yml`.
- Integration test coverage: `tests/integration/boundary-sync-atomicity.tests.ps1`, `stale-state-detection.tests.ps1`, `version-checks.tests.ps1`, `task-progress-tracking.tests.ps1`, `cross-worktree-awareness.tests.ps1`, `psgallery-check.tests.ps1` (6 suites green at closeout).
- Phase 0 chore: `Set-FeatureCloseoutIdentityNow` helper establishes the closeout pattern that updates `.squad/identity/now.md` at feature-closeout.
- Shipping PR: #225 (`Feature 020: Session-State Durability & In-Flight Progress Tracking into main`).

## 0.19.0 - Specrew Distribution Module (PowerShell Gallery)

- Feature 019: Packaged Specrew as a first-class PowerShell module installable from PowerShell Gallery, replacing the previous clone-and-PATH onboarding friction. Shipped across two iterations.
- Iteration 1 — Windows-correct module structure (`Specrew.psd1` manifest + `Specrew.psm1` entry point); exported module functions following PowerShell verb conformance: `Invoke-Specrew`, `Initialize-Specrew`, `Start-Specrew`, `Update-Specrew`, `Show-SpecrewReview`, `Invoke-SpecrewTeam`, `Show-SpecrewStatus` plus CLI-friendly aliases (`specrew`, `specrew-init`, `specrew-start`, `specrew-update`, etc.). Template + resource bundling so `specrew init` bootstraps user projects from the installed module path. `specrew update` template-refresh preserves user-edited files.
- Iteration 2 — Cross-Platform Hardening verified on Windows 11, WSL Ubuntu, Linux Ubuntu, and macOS via PowerShell 7+. Swept 104+ embedded `\` path strings across 7 entry-point scripts, replaced with multi-arg `Join-Path` or forward slashes. Added `.github/workflows/cross-platform-validation.yml` running validator + integration tests on `ubuntu-latest` and `macos-latest`. Deferred-launch architecture via `$env:SPECREW_DEFERRED_LAUNCH_FILE` resolves the Linux PowerShell TTY stripping that exits Copilot CLI immediately when launched from script context. Documentation updated to claim "Tested on Windows + Linux (Ubuntu via WSL)" replacing the implicit Windows-only baseline.
- Publishing workflow: `.github/workflows/publish-module.yml` fires on `v*.*` tag push to publish to PSGallery. Workflow exists and is wired; first real publish deferred to weekend public-flip.
- Bumped pinned external tooling: Spec Kit `0.8.4` → `0.8.11` (7 upstream patches including PowerShell UTF-8-without-BOM fix and extension-registration hardening); Squad `0.9.1` → `0.9.4` (5 weeks of upstream work including new built-in skills/agents, `squad loop` and `squad config model` commands, StorageProvider abstraction, `/fleet` parallel dispatch).
- Fixed two latent bugs in update tooling: (1) `scripts/specrew-update.ps1` no longer rewrites `specrew_version` on `--spec-kit` or `--squad` invocations (was downgrading to `0.1.0-dev` from stale extension manifest); (2) `extensions/specrew-speckit/extension.yml` and its `.specify/extensions/specrew-speckit/extension.yml` mirror bumped from `0.1.0-dev` to the canonical version. Rule 15 extended to enumerate `extension.yml` as a required bump target at feature-closeout.
- Added the public `proposals/` surface as Specrew's design pipeline (initial promotion: 29 numbered proposals + README + INDEX + template). Pattern follows Rust RFCs, Python PEPs, TC39 proposals.
- Markdown lint config relaxed (`.markdownlint.json`) to unblock CI; methodologically-clean fix queued as Proposal 034.
- Shipping PR: #189 (`Merge pull request #189 from alonf/019-specrew-distribution-module`).

## 0.18.0

- Feature 018 — Velocity Dashboard Visual Richness + PoC-Parity Restoration: shipped rich-mode default rendering, restored PoC-parity dashboard density, aligned rich bars and roadmap drift markers, preserved Unicode while stripping ANSI from closeout snapshots, and extended fixture-backed dashboard parity coverage. Refs: feature branch `018-velocity-dashboard-visual-richness`; feature closeout boundary commit (this PR).

## 0.17.0

- Feature 017 — Velocity Dashboard ("Where Am I?"): shipped velocity dashboard rendering (`specrew where` / `specrew status`), roadmap parsing with drift-aware warnings, and immutable iteration + feature closeout dashboard snapshots with validator coverage. Refs: feature branch `017-velocity-dashboard`; feature closeout boundary commit (this PR).

## 0.16.0

- Feature 016 — Substantive Interaction Model: established boundary discipline across three linked pillars (boundary-discipline, essence-in-console, click-through-navigation), formalized post-commit verification protocol with UTC seconds-precision timestamps, added stale-reference scan mandate after boundary commits, promoted Feature 016 Iteration 2 graduation portion and accepted FR-008/FR-020-FR-024 carryovers. Refs: feature branch `016-substantive-interaction-model`; feature closeout boundary commit (this PR).

## 0.15.0

- Feature 015 — Public-Readiness Pass: established repository licensing,
  rewritten public documentation, reconciled version declarations, retroactive
  changelog, release tags (v0.13.0, v0.14.0), extended feature-closeout
  governance, and public-readiness drift detection. Refs: feature branch
  `015-public-readiness-pass`; feature closeout boundary commit (this PR).

## 0.14.0

- Feature 014 — Handoff Format Scoping: scoped bounded stop-vs-progress
  selection and additive handoff-governance warning rollout. Refs: merge
  `3ff32d4` (PR #99); feature closeout `93be46f`.

## 0.13.0

- Feature 013 — Validator Hardening: tightened canonical validator behavior,
  approval-reuse detection, and bookkeeping classification. Refs: merge
  `21d9e7f` (PR #79); feature closeout `a1881da`.

## 0.12.0

- Feature 012 — Descriptive References in Handoffs: required readable,
  descriptive references alongside numeric IDs in handoff outputs. Ref:
  `f35f319`.

## 0.11.0

- Feature 011 — Conditional Pause on `specrew start`: paused startup when
  session-loaded files changed and required an explicit resume decision. Ref:
  `9f2ec92`.

## 0.10.0

- Feature 010 — Onboarding Resume Visibility: surfaced resume-mode behavior in
  onboarding docs and the bootstrap banner. Ref: `2afe007`.

## 0.09.0

- Feature 009 — Project Path Resolution in Entry-Point Scripts: audited path
  resolution across Specrew entrypoints and added regression coverage. Ref:
  `9b464b1`.

## 0.08.0

- Feature 008 — Reviewer Escalation Symmetry and Lockout-Chain Cap: added
  reviewer-regression routing symmetry, lockout-chain capping, and
  carry-forward governance. Ref: `c8d2042`.

## 0.07.0

- Feature 007 — User-Facing Progress Handoff: shipped user-facing progress
  handoffs and the soft-validator sampling mechanism. Ref: `f198702`.

## 0.06.0

- Feature 006 — Human Architecture Intent Checkpoint: added a stable
  architecture-intent checkpoint for Specrew execution. Historical ref:
  `b621836`.

## 0.05.0

- Feature 005 — Stack-Aware Quality Bar: tightened stack-aware quality guidance
  and roadmap expectations. Historical ref: `8666bad`.

## 0.04.0

- Feature 004 — Default Specialty Pairing: introduced concurrency-planning
  governance used by default specialty pairing flows. Historical ref:
  `8bcb28f`.

## 0.03.0

- Feature 003 — Post-Planning Review: hardened post-planning review and
  reviewer closeout enforcement. Historical ref: `ce3d637`.

## 0.02.0

- Feature 002 — Planning Flow Hardening: reinforced early planning continuity
  and reviewer-packet carry-forward behavior. Historical ref: `0440f16`.

## 0.01.0

- Feature 001 — Specrew Product: established the spec-governed operating model,
  governance scaffold, and automated lifecycle start flow. Historical ref:
  `464b07e`.
