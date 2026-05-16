# Changelog

Retroactive alpha release history for shipped Specrew features. `.specrew\config.yml`
is the canonical source for the active version; this file records the feature
baseline that each release number represents.

## Unreleased

- Added `proposals/` surface as Specrew's public design pipeline. Initial
  promotion: 29 numbered proposals plus supporting README, INDEX, and
  template, ranging from shipped features (001-007) to draft features
  (008-012) to candidate ideas (013-029). Pattern follows Rust RFCs, Python
  PEPs, and TC39 proposals. A future "Public Proposals Surface" feature
  (Proposal 028) will harden the lifecycle integration with soft validators
  and auto status transitions.
- Pruned stale Recent Changes entry for 014-handoff-format-scoping in
  `.github/copilot-instructions.md` to keep the rolling window at the two
  most recent features.
- Promoted three additional proposals to the `proposals/` surface
  reflecting post-F-017/F-018 strategic decisions: 030 Quality Hardening
  Bundle (Form-vs-Meaning Verification, ~35 SP across 4 sub-components),
  031 Specrew Distribution Module (PowerShell Gallery, ~12 SP), and 032
  Specrew Slash-Command Surface (`/specrew.*` first-class commands, ~7 SP;
  031+032 recommended combined). Updated `INDEX.md` to move Proposal 009
  (Velocity Dashboard) from Draft to Shipped as feature-017 and add the
  three new proposals under Draft with phase-2 placement. Pre-promotion
  curation removed 4 leaked private references (memory entry paths +
  draft source-spec paths) following the May 15 promotion pattern.
- Bumped pinned external tooling in `.specrew/config.yml`: Spec Kit
  `0.8.4` → `0.8.11` (7 upstream patches including a PowerShell
  UTF-8-without-BOM fix and extension registration hardening) and Squad
  `0.9.1` → `0.9.4` (5 weeks of upstream work including new built-in
  skills/agents, `squad loop` and `squad config model` commands, a
  StorageProvider abstraction, `/fleet` parallel dispatch, and dozens
  of bug fixes). Bumped pre-public-flip so any regression has detection
  runway. Validator green post-bump (38 PASS, 0 FAIL, baseline WARN
  only); Specrew customizations to `.github/agents/squad.agent.md` and
  `.squad/templates/` were not touched by the Squad upgrade. Two latent
  bugs in Specrew's own update tooling surfaced during this chore and
  are queued as follow-up: (1) `scripts/specrew-update.ps1` write-back
  logic rewrites `specrew_version` to `0.1.0-dev` on every `--spec-kit`
  or `--squad` invocation; (2) `extensions/specrew-speckit/extension.yml`
  version pin was never bumped past `0.1.0-dev` during Feature 015
  Public-Readiness Pass and is the upstream source that drives bug (1).
  This commit manually preserves `specrew_version: 0.18.0` after the
  bumps.

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
