# Changelog

Retroactive alpha release history for shipped Specrew features. `.specrew\config.yml`
is the canonical source for the active version; this file records the feature
baseline that each release number represents.

## Unreleased

### Added

- **feat(governance): Proposal 082 Tier 1 — Boundary Commit + Upstream Push Discipline (text-only methodology additions)**: Adds explicit instructions across the Crew's governing surfaces — coordinator governance prompt (new rule 14B at the same authority level as 14A), all 5 baseline agent charters (per-role responsibilities), and `docs/user-guide.md` (new "Boundary Commit Discipline" section with three-tier enforcement plan). Rule 14B mandates: at EVERY lifecycle boundary, the Crew commits the boundary-phase work in semantic commit groups BEFORE invoking `Invoke-SpecrewBoundaryStateSync`; pushes to origin AFTER each commit; verifies `git rev-parse HEAD == git rev-parse origin/<feature-branch>` BEFORE signaling boundary readiness. Per-role responsibilities: Implementer primary committer with semantic groups + immediate push; Spec Steward oversees boundary cleanliness + verifies push parity; Reviewer rejects PRs containing WIP at PR-open time as a hard reject; Retro Facilitator records `boundary-commit-discipline-violations` count as a standard retro signal; Planner anticipates commit cadence in plan.md output. Mirror parity preserved across `extensions/specrew-speckit/` + `.specify/extensions/specrew-speckit/` (6 files, SHA256-verified). Test suite at `tests/integration/boundary-commit-discipline.tests.ps1` (9 test groups) verifies methodology-surface presence + mirror parity + terminology compliance. Empirical motivation: 4 boundary-discipline rejection cycles in F-029 + 1 in F-030/083, all stemming from absence of explicit commit-discipline instructions in any Crew-governing surface (grep returned zero matches pre-082). Tier 2 (validator rule for `boundary-wip-uncommitted` at warning severity, ~6 SP) and Tier 3 (hard enforcement in `Invoke-SpecrewBoundaryStateSync` + auto-push hook, ~10 SP) ship in later releases. See Proposal 082 + spec at `file:///C:/Dev/Specrew/specs/031-commit-push-discipline/spec.md`.

- **chore(speckit-max-tested-bump)**: Bumped `scripts/internal/supported-versions.yml` `speckit.max_tested` from `0.8.11` → `0.8.12`. Spec Kit 0.8.12 (released 2026-05-20) was assessed SAFE per static-evidence review: no changes to extension hook contract (`before_plan` / `after_tasks` / `before_implement`), no changes to `extension.yml` schema, no changes to `/speckit.*` slash-command interface; the release is a refactor-and-polish (`CatalogStackBase` consolidation, `integration: "auto"` workflow default, Codex dot-to-hyphen render note). Declares Spec Kit 0.8.12 as Specrew-validated for the v0.24.2 release per Rule 15 version-management discipline. Chore commit, no proposal entry; rides with the v0.24.2 reliability bundle.

- **chore(version-info-supported-vs-latest)**: `specrew update --info` now distinguishes Specrew-validated `LatestSupported` (max_tested) from `UpstreamLatest` (advisory) for Spec Kit and Squad. New module-side declaration at `scripts/internal/supported-versions.yml` ships with the module (maintainer-managed); reads min/max per dependency. Four-state status replaces the prior two-state (`current` / `update-available`) with `current`, `update-available-supported`, `ahead-of-supported`, `behind-supported`. Advisory line surfaces when upstream-latest exceeds max_tested, explaining "Specrew has validated only through X.Y.Z" so users do not silently adopt untested upstream versions. New `--upstream-latest` flag opts into the historical behavior (upgrade-target = upstream-latest). Default upgrade target is now `max_tested`, preventing accidental upgrades to versions Specrew has not validated. Hardcoded `$minimumSpecKitVersion = '0.8.4'` and `$minimumSquadVersion = '0.9.1'` constants removed from `scripts/specrew-update.ps1`; both now sourced from the shipped declaration with a graceful fallback (warning + two-state behavior) when the file is missing or malformed. New test suite `tests/integration/version-info-states.tests.ps1` covers four-state logic, parser correctness, env-override hooks (`SPECREW_SUPPORTED_MAX_SPECKIT` / `SPECREW_SUPPORTED_MAX_SQUAD`), and missing/malformed-file fallback. Small-fix slice per Proposal 067. See Proposal 079.

- **Feature 028 (Review Evidence Integrity)**: Added pre-review commit gate validator rule, form-vs-meaning parity helper function, scaffolder defensive warnings, and idempotent review artifact regeneration with `-Force` flag. The pre-review commit gate (`Test-PreReviewCommitGate` rule in `validate-governance.ps1`) blocks iteration advancement from implement→review when iteration artifacts declare completed work but committed file changes in git diff are empty (form-vs-meaning gap). The reusable `Test-FormMeaningParity` helper (in `shared-governance.ps1`) compares declared vs. observed metrics and returns structured gap severity (error for zero-diff, warning for partial mismatch, info for no gap). Review artifact scaffolder (`scaffold-reviewer-artifacts.ps1`) emits prominent gap warnings at the top of `code-map.md`, `dependency-report.md`, `coverage-evidence.md`, and `review-diagrams.md` when form-vs-meaning gap is detected. Scaffolder gains `-Force` switch with interactive confirmation prompt (`-Confirm:$true` by default) and non-interactive escape hatch (`-Confirm:$false` for CI/CD) to enable safe re-run after late commits. Integration test suite in `tests/integration/review-evidence-integrity.tests.ps1` validates helper API contract, composition stability for Proposal 030, and core detection logic. Empirical motivation: 2026-05-21 smoke trial revealed empty review artifacts when implementation was late-committed after scaffolding; iteration appeared "complete" with zero evidence. This feature enforces the review-boundary invariant that implementation work must be committed before review evidence can be scaffolded. See Proposal 073.

### Changed

- **feat(governance): Proposal 088 — Markdown Lint Pre-Boundary Auto-Fix Discipline**: Adds a pre-sync gate to `Invoke-SpecrewBoundaryStateSync` that runs `markdownlint-cli --fix` on changed `.md` files BEFORE any state-file writes. Eliminates the catch-fix-retry cycle for markdown lint violations (3 PRs hit this in one day, costing ~30 min wall-clock; 47 violations total). Two new helpers in `shared-governance.ps1` (+ mirror): `Get-ChangedMarkdownFiles` (reuses Proposal 083's `Get-SpecrewLocalScopeBaseRef` for scoped diff identification) and `Invoke-MarkdownLintAutoFix` (runs `npx --yes markdownlint-cli --fix`, detects auto-fixes via SHA256 hash compare before/after, collects unfixable violations via no-fix pass, gracefully degrades when npx unavailable). New `Invoke-PreBoundaryMarkdownLintGate` function in `scripts/internal/sync-boundary-state.ps1` called at the START of `Invoke-SpecrewBoundaryStateSync` BEFORE state-file writes. On auto-fix: throws with directive "commit the fixes as `chore(lint):` and re-run sync." On unfixable: throws with `file:line: rule` messages. On `npx` unavailability: emits `[markdownlint-gate] markdownlint-cli unavailable; skipping gate (warning)` and proceeds. Integration tests at `tests/integration/boundary-sync-markdownlint-gate.tests.ps1` (7 assertions). Mirror parity preserved for `shared-governance.ps1`. Empirical motivation: PR #424 (15 MD032), commit `2c2ef23` (10 MD027 + MD032), PR #462 (22 MD047 + MD009 + MD032). After 088 ships, all 47 violation classes would have been caught at boundary-sync time. Pillar 3 (memoization composition) deferred until Proposal 086 P1 ships. See Proposal 088 + spec at `specs/033-markdown-lint-pre-boundary/spec.md`.

- **feat(governance): Proposal 090 — Closeout Lifecycle Sync Commands (Structural Fix for Crew-Bypass Bug Class)**: Closes the architectural gap where the closeout half of Specrew's lifecycle (review-signoff, retro, iteration-closeout, feature-closeout) had no automated sync coverage. Adds 4 new sync command files at `extensions/specrew-speckit/commands/speckit.specrew-speckit.sync-{review-signoff,retro,iteration-closeout,feature-closeout}.md` (and mirror), registers them in `extension.yml` `provides.commands`, extends the canonical boundary ValidateSet in `scripts/internal/sync-boundary-state.ps1` (lines 188, 222, 670) to include `retro` as a first-class boundary, and adds the `Test-SessionStateBoundaryCanonical` validator rule to `validate-governance.ps1` (+ mirror) catching non-canonical boundary strings (e.g., `feature-closed`, `iteration-closed`) AND `session_state_active=true` combined with `session_state_boundary=feature-closeout` contradictions. New helper functions `Get-SpecrewCanonicalBoundaryTypes` and `Get-SpecrewClosureBoundaryTypes` in `shared-governance.ps1` (+ mirror). Charter updates for Implementer, Spec Steward, Reviewer, Retro Facilitator + coordinator governance prompt rule 5 documenting the new commands as the canonical closeout path (NOT inline PowerShell, NOT manual state-file edits). Integration tests at `tests/integration/closeout-lifecycle-sync-commands.tests.ps1` (9 assertions) and `tests/integration/session-state-boundary-canonical.tests.ps1` (9 assertions). Mirror parity preserved across `extensions/specrew-speckit/` + `.specify/extensions/specrew-speckit/` for all 14 touched files. Empirical motivation: 2026-05-22 Feature 030 / Proposal 083 lifecycle produced FOUR distinct manifestations of the same Crew-bypass bug class — `.specify/feature.json` not cleared (Copilot review caught on PR #462), `session_state_active: true` post-feature-closeout (specrew start recovery mode caught), `session_state_boundary: feature-closed` (non-canonical string, zero codebase matches), and `Current Phase: iteration-closed` (non-canonical string). All four stemmed from the Crew manually editing state files instead of invoking `Invoke-SpecrewBoundaryStateSync`. After 090 ships, the Crew using canonical sync slash commands cannot reproduce the bug class, and the validator rule mechanically rejects any non-canonical strings or contradictions that slip through. See Proposal 090 + spec at `specs/032-closeout-lifecycle-sync/spec.md`.

- **chore(validator-perf-feature-json-exclusion)**: Removed `.specify/feature.json` from the `Get-ValidatorGlobalStatePathspecs` load-bearing list in `shared-governance.ps1` (both `extensions/specrew-speckit/` and `.specify/extensions/specrew-speckit/` mirrors). Rationale: `.specify/feature.json` is purely a "current feature pointer" consumed only by `scaffold-feature-closeout-dashboard.ps1` for path resolution; no validator rule depends on it. Including it forced every feature-transitioning PR (e.g., feature-closeout PRs) to fall back to full-repo validation even when the actual scope was tiny, multiplying PR-CI wait time. Empirical motivation: 2026-05-22 — Feature 030's feature-closeout PR would have triggered ~10-25 min of full-repo PR-CI Lint despite touching one iteration plus boilerplate state files, because `.specify/feature.json` updates on every feature transition. With this exclusion, scoped PR-CI returns to fast-path (~30-60 sec for typical feature-transition PRs). Companion to Proposal 087 (push-to-main scoping). Mirror parity preserved. No test regression (no test asserted the prior fallback behavior). Chore commit; no proposal entry per the validator-perf-dedupe precedent.

- **Proposal 087 (Push-to-Main Validator Scoping + Nightly Truth-Check)**: Changed `.github/workflows/specrew-ci.yml` push-to-main validator step to invoke `validate-governance.ps1 -ChangedOnly` with `GITHUB_BASE_REF` set to `github.event.before` (the parent commit SHA), so every push to main validates only iterations whose files appear in the push diff rather than the full corpus. Added a new scheduled workflow `.github/workflows/specrew-nightly-truth-check.yml` (cron `0 6 * * *` UTC + `workflow_dispatch` for manual triggers) that runs the full-repo validator as a safety-net audit catching drift in closed iterations. Until Proposal 083 merges to main, the push-to-main step falls back to full-repo (same as today, no regression) because the pre-083 validator's `Get-ChangedIterations` helper cannot resolve SHA-style base refs; once 083 merges, the SHA-aware `Resolve-SpecrewGitBaseRefCandidate` activates and scoping kicks in automatically without further workflow edits. Empirical motivation: 2026-05-22 observation that push-to-main runs were spending ~3-5 min on full-repo validation that was 99%+ redundant (closed iterations don't change between pushes); without this fix, that cost grows linearly with corpus size (44 iterations today → 200+ in a year → hits the 25-min step timeout). Composes forward with Proposal 084 (which will parallelize all validator invocations including the nightly), Proposal 085 (which will add `-IncludeClosed` for genuine closed-iteration truth-check), and Proposal 086 (memoization + metadata cache + rule-applicability filter). Small-fix slice per Proposal 067. See Proposal 087.
- **Proposal 083 (local-validator-auto-scope)**: Local `validate-governance.ps1` runs on feature branches now auto-detect the base ref and default to changed-only scope, closing the local/runtime gap that left F-029 boundary validation paying full-repo cost on every boundary. Added a first-line `[validator-scope]` banner for every run, a deliberate `-FullRun` opt-out for Crew workflows that need a complete repository sweep, and mirror-parity documentation/test updates covering auto-scope, on-main full-repo behavior, and base-undetectable fallback.
- **chore(validator-perf-dedupe)**: Narrowed the `shared-governance.ps1` global-state pathspec list to load-bearing validator surfaces only: `.specrew/config.yml`, `.specrew/constitution.md`, `.specrew/iteration-config.yml`, `.specrew/role-assignments.yml`, `.specrew/presets/**`, `.specrew/lenses/**`, `.specrew/roadmap.yml`, `.squad/identity/wisdom.md`, and `.specify/feature.json`. Session-state churn such as `.specrew/last-start-prompt.md`, `.specrew/start-context.json`, `.specrew/last-validator-summary.json`, `.specrew/version-check-cache.json`, and `.squad/identity/now.md` no longer forces `-ChangedOnly` to fall back to full validation; load-bearing config changes still do. Added explicit guidance in Squad coordinator governance prompt (`specrew-governance.md` rule 5) documenting when the validator runs in changed-only vs full mode. Deduplicated `Get-DeclaredCompletedTaskCount` by consolidating it into `shared-governance.ps1` and removing duplicate implementations from `validate-governance.ps1` and `scaffold-reviewer-artifacts.ps1`; the consolidated helper preserves original validator behavior by using `Get-NormalizedKeyword` for state.md task status parsing (which extracts keywords like 'done'/'pass' via regex) and `Normalize-MarkdownCell` for plan.md parsing (which strips whitespace and backticks). Added lightweight timing instrumentation: `Write-SpecrewValidatorSummary` now accepts and persists a `duration_ms` field, and `validate-governance.ps1` captures elapsed time via `[System.Diagnostics.Stopwatch]`, writes it to `.specrew/last-validator-summary.json`, and emits a single `[validator-timing]` stdout line summarizing mode, elapsed time, iteration count, and trigger source. Mirror parity preserved across `extensions/specrew-speckit/` and `.specify/extensions/specrew-speckit/` for all modified scripts. Small-fix slice per Proposal 067.
- ci(lint-scoping): PR-CI Lint job now scopes markdownlint, PSScriptAnalyzer, and `validate-governance.ps1` to files changed in the current PR diff. Typical PR Lint job time drops from ~15 min to <1 min (~15x speedup). Push-to-main events still run full-repo lint as the truth check. Validator gains a `-ChangedOnly` switch + `Get-ChangedIterations` helper that falls back to full validation only when load-bearing validator-global-state surfaces change (for example `.specrew/config.yml`, `.specrew/roadmap.yml`, `.squad/identity/wisdom.md`, or `.specify/feature.json`). Empirical motivation: F-024 PR #306 burned ~80 min of CI runtime over 5+ iterative cycles; the cost-reduction bundle (F-068/F-070/F-069) would pay the same tax without this fix. Chore-shaped slice; no proposal entry per the project-validator-scoping-chore decision.

### Fixed

- **fix(frontmatter)**: `ConvertFrom-SpecrewFrontmatter` now captures the outer regex groups into local variables before iterating through per-line `-match` operations. This prevents PowerShell's ambient `$Matches` reuse from corrupting the preserved markdown body when frontmatter parsing succeeds and later line-level matches overwrite the original capture groups.
- **Feature 029 (Baseline Hygiene)**: `Invoke-SpecrewBoundaryStateSync` now refreshes `.specrew\last-start-prompt.md` `baseline_commit_hash` to the current `HEAD` at every managed lifecycle boundary (`specify`, `clarify`, `plan`, `tasks`, `review-signoff`, `iteration-closeout`, `feature-closeout`). This keeps F-011's session-loaded file detector anchored to the latest boundary commit so Specrew-managed governance edits no longer trigger repeat false-positive pause prompts, while genuine out-of-band watched-file changes still surface immediately. Feature-closeout coverage now also verifies the inactive session sentinel and refreshed baseline remain durable through the closeout path.
- **chore(boundary-sync): clear last-start-prompt body at feature-closeout** (post-F-029 corrigendum): F-029's E1 closeout-invalidation correctly set `session_state_active: false` in `.specrew/last-start-prompt.md` frontmatter but left the BODY content intact. The body retained `Mode: resume-feature, Active feature: <last-feature>` + a Welcome Back Snapshot listing the closed feature's task progress + Suggested Next Actions for that feature. On the next `specrew start` session, the Crew read the body and tried to resume the closed feature instead of acting on the fresh user directive, burning premium quota on stale-state reconciliation. Fix: `Invoke-SpecrewBoundaryStateSync` now forces body refresh at `feature-closeout` only (other boundaries still preserve any human-edited body via the existing path). At `feature-closeout`, `Get-SpecrewPromptBody` renders the `active='false'` branch ("No active feature; Last feature; Last boundary; Recorded at; Authorization commit") instead of the resume-feature body. Empirical motivation: 2026-05-21 session restart after F-029 merge — the Crew burned tokens reading 15+ files to reconcile state that should have been a one-line "no active feature; awaiting next directive." Surfaced as memory `[[project-f029-closeout-body-not-cleared-2026-05-21]]`. Sibling to Proposal 077 (Session Resume UX) which addresses the broader resume-UX surface; this fix is narrow and ships ahead of 077.

### Deprecated

### Removed

### Security

## [0.24.1] - 2026-05-20

### Fixed

- Authenticode trust-chain failure on default-trust clients. The release flow previously signed modules with a self-signed publisher certificate whose root was not in any default client trust store, causing `Install-Module Specrew` to fail without `-SkipPublisherCheck`. The release flow no longer signs the module; modules ship unsigned per the OSS PowerShell Gallery norm. CA-signed releases for corporate and enterprise consumers are tracked as future work. See Proposal 072.

## [0.24.0] - 2026-05-20

- **docs(init-banner)**: Center-align the "GOVERNED AGENTIC SDLC" tagline under the wordmark on the `specrew init` ASCII banner. Tagline previously rendered at 1-space leading indent (left of center by 3 cols); now at 4-space leading indent so both wordmark and tagline center on col 18.5, aligned with the hexagon's vertical axis. Pure presentation fix in `scripts/specrew-init.ps1`. Small-fix slice per Proposal 067.
- **ci(deterministic-gate)**: Skip Linux-incompatible `validate-versions-cli-behavior` step; `.cmd` shim scripts require Windows. Pre-existing limitation; full multi-platform bootstrap shimming queued post-F-024.
- **ci(deterministic-gate)**: Skip Linux-incompatible `bootstrap-asset-blocker-recovery` step; `.cmd` shim scripts require Windows. Pre-existing limitation; full multi-platform bootstrap shimming queued post-F-024.
- **ci(timeout)**: Bumped validator step timeout from 15 to 25 minutes to absorb growing iteration count (44 closed iterations in governance validation pipeline).
- Feature 024: corrected the slash-command surface to the hyphenated `/specrew-*` catalog, deployed the managed skills set to `.claude/skills/`, `.github/skills/`, and `.agents/skills/`, and added YAML frontmatter to every shipped slash-command `SKILL.md`.
- Added migration-safe cleanup for legacy project-local `.copilot/skills/specrew-*` content, preserving unmanaged leftovers while repopulating the active multi-host roots.
- Added the Feature 024 regression lane: migrated slash-command distribution/discovery/compatibility/coexistence coverage, added multi-path/frontmatter/legacy-migration integration tests, and aligned runtime messaging and forward-looking governance docs with the corrected multi-host surface.
- **docs(getting-started)**: Added Option C "Install from a local clone (installed-equivalent from a clone)" to `docs/getting-started.md`. Documents the copy-into-PowerShell-module-path workflow so `Import-Module Specrew` (no path) resolves and `Get-Module Specrew -ListAvailable` lists the module — same behavior as a PSGallery install, but sourced from a local clone. Includes the symbolic-link variant for live-syncing changes from the clone. Documents the tradeoff vs Option A (PSGallery): Option C does NOT exercise the FileList machinery that catches missing-from-shipped-package regressions, so PSGallery prerelease channel remains the definitive pre-release validation path. Renumbered the prior "Direct script invocation" option from C to D; updated all cross-references throughout the file. Small-fix slice per Proposal 067.
- **docs(branding)**: Theme-aware logo system at `docs/assets/`. Final structure: `specrew-icon.png` (the brand symbol — hexagon with internal connected-node "S" tracing, cyan→blue gradient; theme-neutral, looks correct on both light and dark backgrounds), `specrew-wordmark-light.svg` (dark navy wordmark + dark teal tagline for light backgrounds), and `specrew-wordmark-dark.svg` (white wordmark + light cyan tagline for dark backgrounds). `README.md`, `docs/getting-started.md`, and `docs/user-guide.md` use GitHub's `#gh-light-mode-only` / `#gh-dark-mode-only` image-fragment switching on the wordmarks so the text is legible regardless of viewer theme; the icon PNG is shown unconditionally. Tagline is "Governed Agentic SDLC" (was "Governed AI SDLC") — better captures Specrew's differentiation as a governance methodology for multi-agent software delivery, not just AI-assisted coding. ASCII banner in `specrew init` updated to match. Prior placeholder SVG icon (which the user flagged as poor) removed; replaced with user-provided PNG symbol. Prior single full-logo PNG (containing the old "Governed AI SDLC" tagline) removed to keep the asset directory brand-consistent.
- **docs(branding-layout)**: Logo lockup corrected to match the original PNG. Icon is now to the LEFT of the wordmark in a horizontal arrangement (was previously stacked icon-above-wordmark), with both elements vertically center-aligned via `align="middle"` on the `<img>` tags. The two text lines ("Specrew" wordmark + "GOVERNED AGENTIC SDLC" tagline) sit to the right of the icon and are centered against the icon's vertical axis, matching the brand-canonical layout. Sizing tuned so the rendered text content visually represents ~55–65% of the icon's height (consistent with the original's proportions). Applied uniformly across README, getting-started, user-guide.
- **docs(proposals)** (this commit): Added Proposal 067 (Small-Fix Slice Type) at `proposals/067-small-fix-slice-type.md`. Formalizes the 2-3 SP slice between raw chore commits and full feature lifecycle. Required artifacts at ship time: code + tests + CHANGELOG entry + proposal entry + INDEX update. Empirical motivation: the past 24 hours produced multiple changes (logo addition, banner ASCII, gate-respecting default) that fell into the methodology gap between chore-commit and feature-lifecycle. This commit is itself the first slice that follows the new pattern end-to-end.
- **docs(proposals)**: Added Proposal 068 (Cost-Aware Model Routing with Agent-Discovered Model Catalog) at `proposals/068-cost-aware-model-routing.md`. URGENT due to 10-day Copilot pricing deadline (~$1,500/mo projected if no action). Design: `/specrew-research-models` skill discovers per-host models via web-search + official-doc lookup; writes `.specrew/model-catalog.yml`; coordinator-governance routes Junior/Implementer tasks to cheap models and Senior/Reviewer/Spec-Steward tasks to strong models; `cost_profile: lean` defaults populated at `specrew init`. Agent-driven discovery — no hardcoded model names (survives the 10-day pricing pivot). Estimated 6-8 SP. Slice of Proposal 040 (Token Economy); precedes full Multi-Host CORE (024). Implementation begins after F-024 PR merges.
- **docs(proposals)**: Added Proposal 069 (Multi-Host Launch Path) at `proposals/069-multi-host-launch-path.md`. URGENT — cost-reduction bundle, part 2. Adds `specrew start --host claude` / `--host codex` / `--host auto` parameter to route launch to a non-Copilot CLI when desired. Tactical MVP of Proposal 024 (Multi-Host Runtime CORE) — hard-coded per-host launch commands, no deep abstraction. Bootstrap context unchanged; only the CLI invocation differs. Composes with Proposal 068 (catalog) and Proposal 070 (cost tracking). Estimated 7 SP. Implementation begins after F-024 PR merges + Proposal 068 lands.
- **docs(proposals)**: Added Proposal 070 (Token Economy MVP) at `proposals/070-token-economy-mvp.md`. URGENT — cost-reduction bundle, part 3. Records per-boundary token consumption + cost estimate in `specs/<feature>/iterations/<N>/cost.yml`; `specrew where` dashboard gains COST section showing recent iterations with cost-per-SP and trend; `specrew cost summary/add/recompute` CLI surfaces. Measurement only — no cost-priority routing or budget gates (those live in full Proposal 040). Estimator reads per-token cost from Proposal 068's model catalog; manual entry escape hatch for billing-page reconciliation. Estimated 5 SP. Implementation begins after Proposal 068 lands (provides the cost catalog).
- **fix(start)** (commit `c55ec92`): Default `specrew start` to gate-respecting mode. Squad now stops at every lifecycle approval boundary (specify, clarify, plan, tasks, implement, review, retro) and waits for explicit human verdict before advancing. Previously, Specrew auto-enabled Copilot CLI's `--autopilot` flag once feature scope was grounded, which caused Squad to bypass prose-based boundary handoffs without human input. Empirical motivation: three independent boundary-breach incidents over three days (WSL trial 2026-05-18, gym subscription test 2026-05-19, F-024 implementation-approval breach 2026-05-20). New `--autonomous` opt-in flag (or `-Autonomous` PowerShell switch) enables Copilot CLI autopilot mode for unattended runs such as overnight execution. `--allow-all` and `--autonomous` are now independent: the former controls tool-call approval; the latter controls lifecycle-gate advancement. Intake stage stays interactive regardless of `--autonomous` so initial scope is never auto-resolved. Full design rationale at file:///C:/Dev/Specrew/proposals/066-gate-respecting-default.md.

## 0.23.0 - Legacy State Read Tolerance

- Feature 023: closed the legacy state read-tolerance feature with the full validator, documentation, fixture-corpus, and closeout-template scope delivered on the feature branch. The originally planned Iteration 2 slice (T025-T031) was absorbed into Iteration 001 instead of being deferred, so the truthful delivery total is 17 SP planned / 17 SP delivered / 0 SP variance.
- Generated the canonical feature-closeout dashboard snapshot at `specs/023-legacy-state-read-tolerance/closeout-dashboard.md` and cleared active feature identity via the existing feature-closeout scaffold path.
- Rule 15 version management: bumped `Specrew.psd1` `ModuleVersion`, `.specrew/config.yml`, and both Specrew Spec Kit extension manifests to `0.23.0`, then reran governance validation and legacy state reader regression evidence on the closeout tree.
- Added PSGallery prerelease publishing primitives so release automation can stamp `Specrew.psd1` `PrivateData.PSData.Prerelease` for prerelease tags, clear it again when promoting the same baseline to stable, and keep dry-runs/worktree safety scoped to the staged manifest path without mutating the checked-out manifest.
- Completed the `workflow_dispatch` publishing path so prerelease publish, stable publish, and prerelease promotion can safely resolve/create lightweight tags, detect divergent tag targets before publishing, and open GitHub Releases across all real tag-based publish modes.
- Shipped `Specrew.psd1` FileList fix (commit `a77c8e3`): three runtime-required internal helpers (`scripts/internal/coordinator-resume.ps1`, `task-progress.ps1`, `worktree-awareness.ps1`) were missing from the shipped FileList, which broke `specrew where` and `specrew start` in the PSGallery package; caught via the `v0.23.0-beta.1` prerelease channel and fixed in `v0.23.0-beta.2` before promotion to stable. First empirical validation of the prerelease channel design.
- Repo-wide markdown lint deep cleanup (PR #270): reduced ~4,238 violations to 0, removed unnecessary `.markdownlint.json` rule disables, consolidated `.markdownlintrc` into `.markdownlint.json`, and added per-iteration verbose logging to `Test-IterationGovernance` after diagnosing the apparent CI hang as cumulative slowness across 43+ iterations.
- Shipping PRs: #269 (`Feature 023: close legacy state read tolerance at 0.23.0`) and #270 (`Proposal 034 markdown lint deep cleanup + validator diagnosis`).

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
