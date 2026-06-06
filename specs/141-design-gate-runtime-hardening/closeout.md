# Feature Closeout: Design-Gate Runtime Hardening

**Feature**: 141-design-gate-runtime-hardening
**Closed**: 2026-06-06
**Release**: 0.32.0-beta1
**Status**: COMPLETE — 12 iterations, all closed-accepted (~169.5 SP across 18 calendar days; velocity 9.42 SP/day, high confidence; 0 SP remaining)
**Closer**: Crew coordinator (hand-driven), authorized by Alon Fliess at the feature-closeout boundary (2026-06-06)

## Executive Summary

Feature 141 hardened Specrew's design-analysis gate into a runtime-trustworthy, host-neutral **per-lens design workshop** — the first-impression "plan mode" experience users get. It began as a gate-robustness slice building on Feature 140 (FR-001–FR-008, FR-022/FR-023) and evolved, through eight maintainer-directed amendments (A1–A8) each triggered by an empirical manual end-to-end dogfood, into a co-designed, visual workshop delivered as a re-invokable skill and validated across Claude, Copilot/Squad, Codex, and Antigravity.

Key shipped capabilities:

- **Design-analysis gate** (FR-001–008): per-iteration design-analysis artifact, pre-plan validation, plan-block-until-resolved, typed/rendered human gate packet under `gates/`, decision-commit integrity, and plan-input continuity — extending the Feature 140 foundation.
- **Gate robustness** (FR-022/FR-023): tolerant by-the-book detection + single-recommendation marker resolution.
- **Packet / handoff hardening** (FR-011–FR-013): generated start/handoff packets never emit empty or malformed references; greenfield and downstream projects no longer surface phantom design-analysis.
- **Stale cross-worktree session recovery** (FR-024): `specrew start` no longer re-anchors to a merged/closed feature or one whose `feature_path` is absent; confirm-gated stale-session cleanup.
- **Applicable lenses** (FR-009/FR-010, A1): repo-local design-lens knowledge surfaces each selected lens's Design Decision Points, scoped and console-vs-persisted-correct.
- **The per-lens design workshop** (A2–A6): present-then-discuss per lens, a design-analysis stop, discussable prompts, visuals (ASCII-inline default), and collaborative co-design.
- **The `design-workshop` skill** (Iteration 10): one re-invokable skill loading the right per-lens knowledge + co-located conduct per stage, deployed across all five hosts.
- **Confirmation integrity** (A7, FR-038): a deterministic floor for the workshop's confirm contracts.
- **Cross-host UX convergence** (A8, FR-040/FR-041): open-question-first (never a menu first) + mandatory dense-lens pacing — the converged "best workshop" on both Claude and Copilot — with the `AskUserQuestion` tool-gravity **governing model** documented (open-discussion content renders reliably on Claude; before-a-menu content skims → the reliable fix is the host-specific PreToolUse hook of Proposal 165, or accept-as-minor).

41 success criteria; full FR×iteration traceability is in `spec.md`.

## The Arc (12 iterations)

Per-iteration SP and verdicts are in `closeout-dashboard.md` (captured snapshot) and `iterations/001–012/` (review.md + retro.md per iteration; all verdicts accepted). The thematic progression:

- **Iteration 1** — the design-analysis gate (FR-001–008, FR-022/023), 18 SP.
- **Iteration 2** — stale cross-worktree session recovery (FR-024).
- **Iteration 3** — greenfield/downstream spurious-reference hardening (FR-012/FR-013).
- **Iterations 4–7** — the per-lens design workshop took shape across A1–A4: lens applicability (FR-009/FR-010) and selection plumbing, the file-reference render helper + FileList-sort downstream guard (FR-028/FR-029), and the design-analysis stop — culminating in the present-then-discuss workshop.
- **Iteration 8** — visuals (A5).
- **Iteration 9** — collaborative co-design (A6).
- **Iteration 10** — relocation of per-lens conduct into the re-invokable `design-workshop` skill (uniform across the five hosts).
- **Iteration 11** — confirmation-integrity deterministic floor + intake UX (A7, FR-038/FR-040), 20 SP.
- **Iteration 12** — cross-host workshop convergence (A8, FR-041), 8 SP.

## Feature-Level Release Hygiene (resolved at this closeout, 2026-06-06)

Pre-existing release-hygiene cleared before the beta, in separate clearly-labeled commits (NOT 141 feature scope except where noted):

- **FileList completeness gate** (`e8777e05`): the PR-time completeness guard scanned only `scripts/*.ps1` — blind to `extensions/` and `templates/`. Refactored to derive scan roots from the manifest's own prefixes (self-correcting; auto-excludes the non-shipping `.specify/` mirror + `docs/`). Added the 11 undeclared deployable files it now catches (the F-049 intake engine, `user-profile-awareness.md`, `closeout-template.md`) — alongside the 141 design-workshop skill + lenses fixed earlier (`7691ac5f`) that would otherwise have shipped a broken workshop.
- **Gated mirror parity** (`29271dd6`): synced 3 `.specify/` files under automated gates — `handoff-governance-validator.ps1` (141 i006; Feature-139 test), `coordinator/specrew-governance.md` (141 i011; boundary-commit-discipline T009), `deploy-speckit-extension.ps1` (FR-014; PR #1626 pre-141 drift).
- **Self-host mirror refresh** (`03169a85`): canonical deploy of 11 ungated deploy-managed files into `.specify/` (incl. the design-workshop skill + 7 `specrew-*` command SKILLs).
- **Version bump** (`a4a7a19f`): 0.31.1 → 0.32.0-beta1 across the 5 pin surfaces.

## Validation Evidence

- FileList completeness: 0 undeclared (manifest-derived roots); FileList canonically sorted (idempotent under `Sort-SpecrewManifestFileList`); wrapper-filelist/registry/docs parity green.
- Mirror parity: all gated parity tests green — F-139 `boundary-authorization-prompt-truth`, `boundary-commit-discipline` T009, `closed-iteration-index`, `boundary-sync-markdownlint-gate`, `validate-governance.interaction-model`.
- Version: 5 surfaces consistent at 0.32.0-beta1; `version-info-states` + `publish-module-harness` green.
- Unit suite: 21/22 effective (the 2 "failures" are a Pester TestDrive short-path teardown artifact on the dev machine — the assertions pass; green on CI).
- Per-iteration review/retro artifacts under `iterations/001–012/` (all verdicts accepted).

## Human Follow-Up / Deferred

- **Systemic (retro item):** the `.specify/` mirror-parity tests did not run during 141's iteration closeouts — both gated drifts (i006, i011) went unnoticed until beta-prep. This is the test-running gap (connects to the parked run-mechanical-checks `.Tests`-detection bug). Recommend wiring the parity/mechanical gates into the iteration-closeout boundary.
- **Pre-existing red (separate, non-blocking):** `closeout-lifecycle-sync-commands` asserts a `ValidateSet 'retro'` structure `sync-boundary-state.ps1` no longer has — a stale local test, not in CI, not a 141 regression. Separate test-maintenance.
- **Proposals filed (to main):** 162 (two-tier workshop), 165 (PreToolUse render-gate hook — the A8 governing-model reliable fix; RESEARCH-NEEDED).
- **Parked (NOT 141):** Rule-46 verdict-menu collapse; the Antigravity run-mechanical-checks `.Tests`-detection bug; the framework-edit hazard recurrence.
- **FR-025** (questionnaire-driven intake): deferred-within-feature — the engine is retained; activation was out of 141 scope.
- **A8 residual:** the Claude lens-agenda skim before the agenda-confirm menu is maintainer-accepted-as-minor (Proposal 165 is the optional reliable fix).

## Deployment Readiness (maintainer-controlled — beta-before-stable SDLC)

The push/PR/tag/publish steps are maintainer-controlled:

1. Push the `141-design-gate-runtime-hardening` branch; open a PR to `main`.
2. Read the GitHub Copilot PR review; address every finding.
3. Merge (merge-commit, not squash).
4. Tag `v0.32.0-beta1`; publish the prerelease to PSGallery.
5. Manual install validation of the prerelease — exercise the **design-workshop on a real host** (`--host claude`, real greenfield lifecycle), not file-presence.
6. On PASS, promote to `v0.32.0` stable + publish.

Note: 0.31.1 (F-160 — Unix Resolver Sidecar Hardening) is a separate pending-stable beta on its own track.

## Feature Status

**COMPLETE** — Feature 141 is ready for push/PR to `main` and `v0.32.0-beta1` prerelease publication.

**Acceptance Authority**: Alon Fliess (authorized the feature-closeout boundary 2026-06-06).

**Next Valid Action**: Push the branch + create the PR (maintainer).
