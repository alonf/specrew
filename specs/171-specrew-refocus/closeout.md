# Feature Closeout: Specrew Refocus — Slash Command + Event-Driven Auto-Refocus

**Schema**: v1
**Feature**: 171-specrew-refocus
**Branch**: 171-specrew-refocus
**Closed**: 2026-06-07
**Status**: COMPLETE — branch-ready evidence only
**Closer**: Claude, authorized by Alon Fliess for feature-closeout

## Executive Summary

Feature 171 is complete as branch-ready evidence. It delivers Proposal 146 (the `/specrew-refocus` slash command) **plus** the Pillar B amendment (event-driven auto-refocus via host hooks), across two iterations (31 SP: iteration 001 = 18.5, iteration 002 = 12.5). All twenty functional requirements (FR-001..020) are implemented, reviewed (both iterations accepted), and retro'd (both approved).

The feature ships: a host-neutral refocus engine (`refocus.ps1`) with a general + 10-stage digest family driven by a data catalog (`refocus-scopes.json`); a single `SpecrewHookDispatcher` (one registration per host event, ordered/budgeted providers, kill-switch-first, self-gating, per-session circuit breaker + journal); host hook bindings verified against live documentation (Claude B1+B2+B3 via channel 1; Codex full triad; Copilot + Cursor B2; Antigravity deferred-with-path); merge-aware deploy wired into `specrew init`/`update`; and the `/specrew-refocus` skill across host catalogs.

This branch is integrated with `origin/main` (0.32.0 stable) but is NOT released, tagged, merged, PR-opened, or pushed to main.

## Delivered Scope

| Capability (Requirement) | Status | Evidence |
| --- | --- | --- |
| Host-neutral refocus engine + banner/scope flags (FR-001) | complete | `scripts/internal/refocus.ps1` (+2 mirrors); `tests/integration/refocus-engine.tests.ps1` 40/40 |
| General + 10-stage digest family with frontmatter + drift watch (FR-002, FR-019) | complete | `extensions/specrew-speckit/refocus/*.md` (11 digests ×2 trees); `refocus-digests.tests.ps1` 119/119 |
| Data-driven catalog with schema_version + fail-open (FR-003) | complete | `extensions/specrew-speckit/refocus-scopes.json`; `refocus-catalog.tests.ps1` 74/74 |
| Source confinement + budget caps + WARN codes (FR-004, FR-005, FR-012) | complete | engine suite (SOURCE_CONFINED, BUDGET_EXCEEDED, 8 reason codes) |
| Boundary-sync wrapper channel-1 injection + fingerprint (FR-006) | complete | `refocus-channels.tests.ps1` 21/21 (REAL wrapper + sync) |
| Instruction-file recovery pointer (FR-007) | complete | coordinator governance rule 4; `refocus-channels.tests.ps1` |
| SpecrewHookDispatcher — one registration, ordered/budgeted, kill-switch-first, self-gate, dormant gate seat (FR-008) | complete | `scripts/internal/specrew-hook-dispatcher.ps1` (+2 mirrors); `refocus-dispatcher.tests.ps1` 65/65 |
| Trigger routing B1/B2/B3 (state-diff, watch-the-state) (FR-009) | complete | dispatcher suite (anchor-on-first-sight, mtime cheap-guard, dedupe) |
| Per-session runtime state + bounded journal (FR-010) | complete | dispatcher suite (journal ring 20, pruning) |
| Per-session circuit breaker (auto-trip + reset matrix) (FR-011) | complete | dispatcher suite (per-trigger/global trips, loud-once, slash + channel-1 exempt) |
| Per-host hook bindings, research-gated (FR-013) | complete | `specs/171-specrew-refocus/research-matrix.md`; `hosts/{claude,codex,copilot,cursor}/host.psd1` |
| Merge-aware deploy + opt-out memory + init/update wiring (FR-014, FR-018) | complete | `deploy-refocus-hooks.ps1`, `refocus-deploy-integration.ps1`; `specrew-init.ps1`/`specrew-update.ps1`; `refocus-deploy.tests.ps1` 59/59; `filelist-completeness.tests.ps1` |
| `/specrew-refocus` skill across host catalogs (FR-015) | complete | `squad-templates/skills/refocus.md` + per-host skill dirs |
| Coordinator advisory fallback + compaction-points hygiene (FR-016, FR-017) | complete | coordinator governance rule 4; `--compact-instructions`; channels suite |
| Test coverage per FR-020 | complete | six refocus suites = 377 asserts, 0 fail |

## Tests and Validation (run at closeout on the integrated tree)

Local CI/parity mirror — **28/28 suites PASS** (the F-141 lesson: run the sets the iterations never ran), incl.:

- All three CI lanes' integration tests: legacy-state-readers, filelist-completeness, deploy-extension-missing-source-tolerance, drift-scenario, iteration-resume, planning effort/overcommit, process-quality report/scorer, version-info-states, boundary-sync-markdownlint-gate, version-checks, unix-resolver-path-semantics, managed-runtime-sidecar, managed-skill-stuck-preserving, validation-contract-lane, start-command-non-interactive-first-run, brownfield-conflict-handling.
- **F-165 `gate-stop-skill.tests.ps1` PASS** — F-165's shipped contract is intact post-merge (the regression guard for this integration).
- **Wrapper parity** (docs / filelist / registry) all PASS.
- **Six refocus suites** PASS (377 asserts): engine 40, digests 119, catalog 74, channels 21, dispatcher 65, deploy 59.
- Governance validator: PASS for both iterations (full + changed-only).

## Accepted Review and Retro Evidence

- Iteration 001: review accepted (12/12 tasks pass; 330 asserts); retro approved; TG-004 latency returned-with-data and the defer ledgered. `iterations/001/review.md`, `iterations/001/retro.md`.
- Iteration 002: review accepted (5/5 tasks pass; 377 asserts); a review-caught greenfield-init anchor defect fixed-now; retro approved. `iterations/002/review.md`, `iterations/002/retro.md`.

## Main-Integration Reconciliation (this closeout)

This branch was 53 commits behind `origin/main` at closeout prep. `origin/main` was merged in (now 0 behind / 55 ahead). Reconciliations:

- **Drift D-003 — F-165 superseded its render-gate.** F-165 shipped (0.32.0 stable, PR #2082) and replaced its `PreToolUse` render-gate (commit `49c3ba13`) with the `specrew-gate-stop` skill (`disallowed-tools: AskUserQuestion`). F-171's dormant `kind: gate`/`PreToolUse` seat therefore has no current named consumer. Resolution: the `kind: inject|gate` contract REMAINS as generic, dormant, no-behavior-change extensibility; its justification is de-coupled from F-165 (spec.md FR-008 + Key Entities annotated). **Keep-vs-remove of the dormant seat is a maintainer ruling — see Open Decision below.**
- **AskUserQuestion regression fix.** Because F-165 made "no picker at verdict stops" canonical, F-171's always-injected `general.md` digest (rule 9) and `specify.md` were updated to teach the `specrew-gate-stop` mechanism (render the six-section packet as prose; never deliver a verdict via the picker; workshop/clarify questions keep it). Without this, every refocus injection would have re-taught the exact pattern F-165 fixed — a regression. `general.md` re-trimmed under the 600-token cap (599).
- **Conflict resolution.** Four session-state files (closed-iterations index, active-features claims, lifecycle-events log, identity/now) were union-merged. No code/skill/digest conflicts.

## Open Decision (maintainer ruling at this gate)

**Dormant gate seat (`kind: gate` / `PreToolUse`).** You directed reserving it (2026-06-07) with F-165's render-gate as the motivating consumer. That consumer no longer exists (D-003). Options: (a) KEEP as generic dormant extensibility (current state — zero runtime effect, justification re-documented), or (b) REMOVE the seat (dispatcher gate path + catalog `kind` + dormant-seat tests + spec clause). Recommendation: KEEP — it is inert, costs nothing at runtime, and a future gate mechanism would otherwise re-pay the dispatcher-contract design. Your call.

## Known Non-Blocking Items

| Item | Disposition |
| --- | --- |
| e2e lanes (`update-command.ps1`, `bootstrap-to-iteration.ps1`) deploy codex/copilot/cursor hooks into the REAL user home (PATH-based detection, no home override). | Benign by design (dispatcher self-gates on `.specrew/`; identical to a real `specrew init` on this machine). Follow-up candidate: thread `-UserHomeOverride` from the e2e lanes through `Invoke-RefocusHookDeployment`. Three files were written to this machine's `~/.codex`, `~/.copilot/hooks`, `~/.cursor` during testing — maintainer may keep or remove. |
| SC-008 runtime beta validation (≥2 hook-bound hosts; Copilot B1 `source`-check at step 9). | Release gate, NOT an iteration gap — runs at the beta step under separate authorization (`specs/171-specrew-refocus/beta-validation.md`). |
| Antigravity binding deferred-with-path. | Contracted FR-013 host variance (primary docs not fetchable); ships channels 1+2 + advisory. |
| Repo-wide validator WARNs (pre-existing main dashboard regressions; hand-driven handoff-block notes). | Pre-existing on main, outside F-171; validator PASSES for F-171's iterations. |

## Branch-Ready Constraints

- Do not release. Do not tag. Do not merge. Do not open a PR. Do not push to main.
- Merge ordering: land after crew 169 (F-170 already shipped in 0.32.0); confirm 169 status before the branch→main step.
- Next valid action is a separate human authorization for the PR/beta/merge/SC-008 SDLC steps.

## Branch Hygiene at Closeout Preparation

- Branch: `171-specrew-refocus`; upstream `origin/171-specrew-refocus`.
- Integrated with `origin/main` (0.32.0 stable) via merge commit `2cedf23b`; 0 behind / 55 ahead at closeout prep.
- Working tree clean before closeout authorization; closeout commits are path-limited to F-171 artifacts + the integration reconciliation.

## Final Status

Feature 171 is complete and ready as branch evidence only — integrated with 0.32.0 stable, F-165 contract verified intact, AskUserQuestion regression fixed. It is not released, tagged, merged, PR-opened, or promoted to main.
