# Proposal Index

This index is the navigation surface for all proposals in this directory. Sorted by status first, then proposal number.

**Note**: this file is currently human-maintained. The lifecycle-hardening feature (Proposal 028) will eventually auto-generate it from per-proposal frontmatter.

> **Terminology note (2026-05-21)**: This index uses **"the Crew"** to mean the agent team executing Specrew's lifecycle (Spec Steward, Planner, Implementer, Reviewer, Retro Facilitator + supplemental specialists). **"Squad"** refers specifically to the [squad-cli](https://www.npmjs.com/package/@bradygaster/squad-cli) npm product — currently the only Crew runtime, but the multi-host work in Proposals [024](024-multi-host-runtime-abstraction.md) and [069](069-multi-host-launch-path.md) will add Claude Code, Codex, and VS Code Chat as alternative runtimes. Older proposals (pre-2026-05-21) often use "Squad" where "the Crew" would now be more accurate; the term will appear in both roles until a future cleanup chore lands (or until proposals are opportunistically renamed when touched for other reasons). New proposals should use "the Crew" for the team-role and reserve "Squad" for the npm product, file paths (`.squad/`), CLI binary references, and historical accuracy.

---

## Shipped (28)

Proposals whose features have shipped to main and are part of Specrew's current capability.

| # | Title | Shipped as | Phase | SP |
|---|---|---|---|---|
| [001](001-path-resolution-bug.md) | Path Resolution Bug Fix | feature-009 | phase-1 | 8 |
| [002](002-specrew-start-conditional-pause.md) | Specrew-start Conditional Pause | feature-011 | phase-1 | 7 |
| [003](003-squad-descriptive-references.md) | Squad Descriptive References | feature-012 | phase-1 | 9 |
| [004](004-validator-hardening.md) | Validator Hardening | feature-013 | phase-1 | 18 |
| [005](005-handoff-format-scoping.md) | Handoff Format Scoping | feature-014 | phase-1 | 8 |
| [006](006-public-readiness-pass.md) | Public-Readiness Pass | feature-015 | phase-1 | 19 |
| [007](007-substantive-interaction-model.md) | Substantive Interaction Model | feature-016 | phase-1 | 22 |
| [009](009-velocity-dashboard.md) | Velocity Dashboard ("Where Am I?") | feature-017 | phase-2 | 19 |
| [031](031-specrew-distribution-module.md) | Specrew Distribution Module (PowerShell Gallery) | feature-019 | phase-2 | 22 |
| [032](032-specrew-slash-commands.md) | Specrew Slash-Command Surface | feature-021 | phase-2 | 7 |
| [066](066-gate-respecting-default.md) | Gate-Respecting Default + `--autonomous` Opt-In | chore `c55ec92` (2026-05-20) | phase-2 | 3 |
| [072](072-psgallery-unsigned-default.md) | PowerShell Gallery Unsigned Default | bug-fix slice `v0.24.1` (2026-05-20) | phase-2 | 2 |
| [073](073-review-evidence-integrity.md) | Review Evidence Integrity (Pre-Review Commit Gate + Form-vs-Meaning Detection) | feature-028 | phase-2 | 18 |
| [079](079-version-info-supported-vs-latest.md) | Version Information — Supported vs Latest Distinction | small-fix slice (v0.24.2 bundle) | phase-2 | 5 |
| [082](082-boundary-commit-and-upstream-push-discipline.md) | Boundary Commit + Upstream Push Discipline (Tier 1 only) | small-fix slice feature-031 (v0.24.2 bundle) — Tier 2 + Tier 3 remain candidate | phase-2 | 5 (Tier 1) |
| [083](083-local-validator-speedup.md) | Local Validator Auto-Scope for Feature-Branch Invocations | feature-030 (v0.24.2 bundle) | phase-2 | 5 |
| [086](086-validation-pipeline-performance-bundle.md) | Validation Pipeline Performance Bundle — Pillars 1 + 5 only (Validator Result Memoization + Repetition Detector) | feature-034 + feature-037 (v0.24.3 bundle) — Pillars 2-4 remain candidate | phase-2 | 11.0 (Pillars 1 + 5) |
| [088](088-markdown-lint-pre-boundary-auto-fix-discipline.md) | Markdown Lint Pre-Boundary Auto-Fix Discipline (Boundary-State-Sync Integration) | feature-033 (v0.24.3 bundle) | phase-2 | 5.25 |
| [084](084-validator-iteration-parallelization.md) | Validator Iteration Parallelization (PowerShell `ForEach-Object -Parallel`) | feature-035 (v0.24.3 bundle) | phase-2 | 7 |
| [085](085-skip-closed-iterations-in-validator.md) | Skip Closed Iterations in Validator (Fallback-Path Optimization via Closed-Iteration Index) | feature-036 (v0.24.3 bundle) | phase-2 | 5 |
| [089](089-pr-review-integration-address-pr-review-gate.md) | PR Review Integration — Address-PR-Review Lifecycle Gate (Multi-Host Aware) — minimal viable slice | feature-038 (v0.24.3 bundle) — hard-blocking gate + multi-host expansion remain candidate | phase-2 | 3.25 (minimal slice) |
| [090](090-closeout-lifecycle-sync-commands.md) | Closeout Lifecycle Sync Commands (Structural Fix for Crew-Bypass Bug Class) | feature-032 (v0.24.3 bundle) | phase-2 | 6.5 |
| [065](065-launch-mode-boundary-enforcement.md) | Launch-Mode Boundary Enforcement (Tool-Call-Layer Intercept for Lifecycle Boundaries) | feature-039 (v0.25.0) | phase-2 | 7.0 |
| [069](069-multi-host-launch-path.md) | Multi-Host Launch Path + Per-Host Flag Pass-Through (Claude Code + Codex) | feature-040 (v0.26.0) | phase-2 | 15.25 |
| [107](107-host-aware-routing-plan-fallback.md) | Host-Aware Routing Plan Fallback (F-040 follow-up: promote `--host` selection into the routing plan; host-first fallback instead of always copilot-first) | fix-bundle `a45232af` + `b1486f4c` (v0.26.0 — F-040 calc-v2 dogfooding 2026-05-23) | phase-2 | 3 |
| [104](104-multi-host-onboarding-and-selection-flow.md) | Multi-Host Onboarding + Selection Flow (host probe + `host-history.yml` + interactive numbered menu + `specrew host list/use/status` CLI surface) | feature-043 (v0.27.0) | phase-2 | 11 |
| [108](108-specrew-init-refactor-and-crew-runtime-abstraction.md) | specrew-init Refactor + Per-Host Crew-Runtime Abstraction (per-host package registry; 5-function contract; canonical `.specrew/team/agents/` source-of-truth; Antigravity host graduated to supported) | feature-044 (v0.27.0) | phase-2 | 50 (7 iterations) |
| [046](046-auto-render-dashboard-at-closeout.md) | Auto-Render Dashboard at Iteration & Feature Closeout — auto-render slice ONLY (boundary-sync writes `iterations/<NNN>/dashboard.md` + `closeout-dashboard.md`); roadmap-aware drill-down + trap-reapplication summary + cross-iteration diff remain candidate | fix-bundle `162bcdb9` (v0.26.0 — partially-shipped) | phase-2 | 2 (shipped slice) |
| [057](057-roadmap-spine-input-adapter-pattern.md) | Roadmap Spine + Input Adapter Pattern — stub-bootstrap slice ONLY (`specrew init` writes minimal `.specrew/roadmap.yml`); full input-adapter system (manual / GitHub Issues / Linear / etc.) remains candidate | fix-bundle `162bcdb9` (v0.26.0 — partially-shipped) | phase-3 | 1 (shipped slice) |

## Draft (18)

Proposals with full source-spec content, ready for `/speckit.specify` ingestion when prioritized.

| # | Title | Phase | SP | Notes |
|---|---|---|---|---|
| [008](008-nfr-governance.md) | Non-Functional Requirement Governance | phase-2 | 28 | Absorbs queued Boundary Validation Tier |
| [010](010-multi-developer-reconciliation.md) | Multi-Developer Reconciliation | phase-5 | 75 | Major scope; unlocks team scaling |
| [011](011-architecture-intent-checkpoint.md) | Architecture Intent Checkpoint | phase-1 | 10 | On-disk spec exists at specs/006-human-architecture-checkpoint |
| [012](012-visual-artifact-extension.md) | Visual Artifact Extension | phase-1 | 15 | Pillar 4 of the interaction model |
| [030](030-quality-hardening-bundle.md) | Quality Hardening Bundle (Form-vs-Meaning Verification) | phase-2 | 35 | Bundles 4 sub-components addressing form-correct/meaning-wrong bug class |
| [033](033-specrew-governance-cli.md) | Specrew Governance CLI | phase-2 | 18 | `specrew roadmap` / `propose` / `feature` CLI surfaces; absorbs Proposal 028 |
| [034](034-markdown-lint-strict-defaults-restoration.md) | Markdown Lint Cleanup and Strict-Defaults Restoration | phase-2 | 12 | Fix all ~1,565 markdown lint violations + remove `.markdownlint.json` relaxation; sequenced AFTER F-019 closes |
| [035](035-session-state-durability.md) | Session-State Durability & In-Flight Progress Tracking | phase-2 | 30 | Next up after F-019. Source spec at file:///C:/Dev/SpecrewDraft/session-state-durability.md. Addresses L6 closeout-cascade lesson. |
| [036](036-branch-reconciliation.md) | Lifecycle Branch Reconciliation | phase-2 | 13 | SDLC pillar; single-developer precursor to [010] multi-developer. MERGE only, never rebase. |
| [040](040-token-economy-governance.md) | Token Economy as Governance Driver | phase-4 | 38 | 7-layer architecture; two billing modes (metered + quota); model names ONLY in catalog L3-L4 |
| [063](063-substantive-intake-questioning.md) | Substantive Intake Questioning at /speckit.specify and /speckit.clarify | phase-2 | 25-30 | **F-025 (next-after-F-024 per 2026-05-20 sequencing decision)**. Persona-driven adaptive intake (PM 🧠 / UX 🎨 / Architect 🏗️ / PM 📋 + AI Researcher 🔬); 12-category catalog; input-quality assessment → Mode A/B/C; fires at specify + clarify + iteration kickoff + mid-feature pivot. Source spec at file:///C:/Dev/SpecrewDraft/substantive-intake-questioning.md |
| [064](064-slash-command-multi-host-correctness.md) | Slash-Command Multi-Host Correctness (F-021 Surface Restoration) | phase-2 | 7 | Restores F-021's non-functional `/specrew-*` surface; multi-deploy to `.claude/skills/`, `.github/skills/`, `.agents/skills/`; YAML frontmatter; drop dotted command forms. Source spec at file:///C:/Dev/SpecrewDraft/slash-command-multi-host-correctness.md |
| [067](067-small-fix-slice-type.md) | Small-Fix Slice Type (Lightweight Lifecycle for 2-3 SP Changes) | phase-2 | 5 | Formalizes the 2-3 SP slice between raw chore commits and full feature lifecycle. Required artifacts: code + tests + CHANGELOG + proposal + INDEX. Composes with Proposal 055 (slice-type catalog). Empirical motivation: commits `d288286`, `1838034`, `c55ec92`, `ecd7b6d`. |
| [068](068-cost-aware-model-routing.md) | Cost-Aware Model Routing with Agent-Discovered Model Catalog | phase-2 | 6-8 | **URGENT — 10-day Copilot pricing deadline.** Discovery skill (`/specrew-research-models`) writes `.specrew/model-catalog.yml`; coordinator-governance routes Junior/Implementer tasks to cheap models, Senior/Reviewer to strong; `cost_profile: lean` in `.specrew/config.yml`. Slice of Proposal 040; precedes full Multi-Host CORE (024). Agent-driven discovery — no hardcoded model names. |
| [070](070-token-economy-mvp.md) | Token Economy MVP (Cost-per-Iteration Tracking + Dashboard Surfacing) | phase-2 | 5 | **URGENT — cost-reduction bundle.** `specs/<feature>/iterations/<N>/cost.yml` records per-boundary token consumption + cost estimate from Proposal 068's catalog; `specrew where` dashboard gains COST section; `specrew cost summary/add/recompute` CLI. MVP slice of Proposal 040 (Token Economy as Governance Driver) — measurement only, no governance layer. |
| [074](074-code-commentary-standards.md) | Code Commentary Standards (Multi-Level Convention + Preference Dial) | phase-2 | 12-15 | Replaces the current "default to no comments" Implementer instruction with a four-category taxonomy (contract / why-rationale / concept / inline narration), a four-level preference dial (`minimalist` / `standard` / `educational` / `textbook`), and a language-idiomatic convention catalog (C# XML doc, JSDoc, docstring, Javadoc, godoc, rustdoc, PowerShell comment-based help, etc.). Reviewer agent gains a contract-docs verification check. Empirical motivation: 2026-05-21 smoke trial produced a complete .NET 8 snake-game solution with **zero XML doc comments on public APIs** — IntelliSense silently empty. Composes with Proposals 047 / 052 / 015 (dials, profiles, expertise). |
| [075](075-update-artifact-backfill-discipline.md) | Specrew Update Artifact Backfill Discipline | phase-2 | 10-15 | **HIGH PRIORITY** — promoted candidate → draft 2026-05-25. Sanctioned auto-fix mechanism for missing iteration artifacts (dashboard.md, review-diagrams.md, code-map.md, etc.) when iterations were closed outside Specrew runtime OR predate the artifact's introduction. Empirical motivation: 2026-05-25 F-044 closeout cleanup — 10 closed iterations missing dashboard.md because the original closeouts were orchestrated by a non-Specrew session bypassing the `sync-boundary-state.ps1` auto-render trigger. Pattern is universal across multi-host expansion. Composes with Proposal 030 (form-vs-meaning) and Proposal 067 (small-fix slice). |
| [105](105-host-native-hook-deployment.md) | Host-Native Hook Deployment for Runtime Boundary Enforcement | phase-2 | 12-18 | **HIGH PRIORITY (Tier 1)** — promoted candidate → draft 2026-05-26 after F-046 v0.27.2 Antigravity incident bypassed 4 sequential human-approval gates (commits `0857e319 → f6155e54`) in a single session despite F-039 cooperative enforcement being active. Hooks at PreToolUse / SubagentStart / Stop on Claude + Antigravity elevate F-039 from cooperative-prose-based to runtime-enforced. Codex hook deployment deferred until Codex hook surface is documented; Copilot has no hook surface. Composes with 065 / 069 / 100 / 104 / 024. |
| [055](055-always-in-flow-bug-fix-lifecycle.md) | Always-In-Flow Discipline + Slice-Type Catalog (Including Bug-Fix Lifecycle) | phase-2 | 22 | **HIGH PRIORITY (Tier 1)** — promoted candidate → draft 2026-05-26 after 4 empirical instances (2026-05-18 trial-project + 2026-05-25 Antigravity dice-app + 2026-05-25 Copilot dice-app + 2026-05-26 F-046 bug-bash). Catalog extended 7→9 slice types: added **bug-bash** (formalizing F-046 pattern with running `findings.md` + per-bug commits + retro discussing bug-classes) and **enabler** (formalizing 2026-05-26 PlanningPoC DWG-anonymizer mid-feature discovery with pause / extend / defer-with-workaround decision framework). Interim 4-pattern default (chore / small-fix / bug-bash / emergency) documented for use-until-ships. Comparative-methodology research targets (Scrum, SAFe, Kanban, XP, DA, Lean) queued for v2 catalog refinement. |

## Candidate (79)

Idea-form proposals not yet developed into full source specs. Open for discussion; may mature to draft or be withdrawn.

| # | Title | Phase | SP |
|---|---|---|---|
| [013](013-methodology-site.md) | Methodology Site | phase-2 | 20 |
| [014](014-red-team-agent.md) | Red Team Agent | phase-2 | 22 |
| [015](015-expertise-aware-adaptive-interaction.md) | Expertise-Aware Adaptive Interaction | phase-2 | 25 |
| [016](016-outcome-scoring.md) | Outcome Scoring | phase-4 | 27 |
| [017](017-learning-loop-closure.md) | Learning Loop Closure | phase-2 | 13 |
| [018](018-source-spec-fidelity-contract.md) | Source-Spec Fidelity Contract | phase-2 | 30 |
| [019](019-spec-arithmetic-mechanical-check.md) | Spec-Arithmetic Mechanical Check | phase-2 | 10 |
| [020](020-spec-scenario-integration-tests.md) | Spec-Scenario Integration Test Mandate | phase-2 | 15 |
| [021](021-bypass-detector.md) | Bypass Detector | phase-2 | 10 |
| [022](022-spec-reconciliation-detector.md) | Spec-Reconciliation Detector | phase-2 | 10 |
| [023](023-reactive-specialist-lifecycle.md) | Reactive Specialist Lifecycle Management | phase-2 | 22 |
| [024](024-multi-host-runtime-abstraction.md) | Multi-Host Runtime Abstraction | phase-6 | 65 |
| [025](025-jit-codebase-cartography.md) | JIT Codebase Cartography | phase-7 | 100 |
| [026](026-refactor-track-features.md) | Refactor Track Features (R1-R5) | phase-3 | 110 |
| [027](027-iteration-011-cleanup.md) | Iteration 011 Cleanup | phase-2 | 7 |
| [028](028-public-proposals-surface.md) | Public Proposals Surface | phase-2 | 13 |
| [029](029-handoff-format-scoping-refinement.md) | Handoff Format Scoping Refinement | phase-2 | 5 |
| [037](037-psscriptanalyzer-lint-cleanup.md) | PSScriptAnalyzer Lint Cleanup | phase-2 | 7 |
| [038](038-adaptive-boundary-discipline.md) | F-016 Adaptive Boundary Discipline (Boundary-Class Refinement) | phase-2 | 10 |
| [039](039-squad-upstream-reconciliation.md) | Squad Upstream Reconciliation | phase-3 | 22 |
| [041](041-specrew-autopilot.md) | Specrew Autopilot (Experiment + Production Feature) | phase-4 | 28 |
| [042](042-specrew-integration-test-suite.md) | Specrew Integration Test Suite | phase-2 | 31-37 |
| [043](043-structured-question-protocol.md) | Structured Question Protocol | phase-3 | 10 |
| [044](044-downstream-quality-baseline-bootstrap.md) | Downstream Quality Baseline Bootstrap | phase-2 | 10 |
| [045](045-ci-watchdog-recurrence-prevention.md) | CI Watchdog & Recurrence Prevention | phase-2 | 8 |
| [046](046-auto-render-dashboard-at-closeout.md) | Auto-Render Dashboard at Iteration & Feature Closeout — remaining scope (roadmap-aware velocity drill-down, trap-reapplication summary, cross-iteration diff, optional review-signoff capture-kind); auto-render slice already shipped in v0.26.0 | phase-2 | 3 (remaining) |
| [047](047-project-governance-profile.md) | Project Governance Profile (Init-Time Preference Capture) | phase-2 | 20 |
| [048](048-dashboard-velocity-metric-refinement.md) | Dashboard Velocity Metric Refinement | phase-2 | 5 |
| [049](049-version-check-source-unification.md) | Version-Check Source Unification | phase-2 | 3 |
| [050](050-version-surface-discoverability.md) | Version Surface Discoverability (init/start banner + `specrew version` command) | phase-2 | 3 |
| [051](051-path-reference-formatting-standard.md) | Path Reference Formatting Standard (file:/// URL + markdown-link surface rules) | phase-2 | 5 |
| [052](052-specrew-profile-system.md) | Specrew Profile System (Methodology Core + Domain Profile Composition) | phase-3 | 35 |
| [053](053-autopilot-decision-transparency.md) | Autopilot Decision Transparency (Surface Auto-Resolutions in Artifacts) | phase-2 | 3 |
| [054](054-pre-merge-lifecycle-verification-gate.md) | Pre-Merge End-to-End Lifecycle Verification Gate | phase-2 | 15 |
| [056](056-specrew-readonly-mode.md) | Specrew Readonly Mode (Concurrent-Session Inspection Safety) | phase-2 | 12 |
| [057](057-roadmap-spine-input-adapter-pattern.md) | Roadmap Spine + Input Adapter Pattern — remaining scope (input adapters: manual / GitHub Issues / Linear / Jira / Azure DevOps / iteration-end auto-sync; dashboard renderer integration; conflict resolution); stub-bootstrap slice already shipped in v0.26.0 | phase-3 | 27 (remaining) |
| [058](058-plugin-based-multi-host-distribution.md) | Plugin-Based Multi-Host Distribution (Per-Host Plugin Packaging) | phase-3 | 28 |
| [059](059-legacy-state-read-tolerance.md) | Legacy-State Read-Tolerance + Schema Migration Discipline | phase-2 | 15 |
| [060](060-prerelease-channel-staging.md) | PSGallery Prerelease Channel + Staging Discipline | phase-2 | 10 |
| [061](061-init-update-convergence-test.md) | Init/Update Convergence Test (Frozen-Snapshot Replay) | phase-2 | 13 |
| [062](062-dependency-metadata-reason-propagation.md) | Dependency Metadata + Reason Mapping + Impact-Analysis Propagation | phase-2 | 18 |
| [071](071-vscode-copilot-chat-host.md) | VS Code Copilot Chat as a First-Class Specrew Host | phase-2 | 10-12 |
| [077](077-session-resume-ux.md) | Session Resume UX for Downstream Specrew Users | phase-2 | 10-15 |
| [078](078-handoff-conversation-quality.md) | Handoff Conversation Quality at All Boundary Stops | phase-2 | 10-15 |
| [080](080-specrew-file-reference.md) | Specrew File Reference (Lifecycle Catalog for All Specrew-Managed Files) | phase-2 | 10-15 |
| [081](081-reviewer-visual-evidence.md) | Reviewer Visual Evidence — Multi-Type Diagrams + Explanatory Omissions + Mermaid Mandate | phase-2 | 33-43 |
| [082](082-boundary-commit-and-upstream-push-discipline.md) | Boundary Commit + Upstream Push Discipline (Tiers 2 + 3 only; Tier 1 shipped) | phase-2 | 16 (Tier 2 ~6 + Tier 3 ~10) |
| [086](086-validation-pipeline-performance-bundle.md) | Validation Pipeline Performance Bundle (Memoization, Rule-Applicability, Process-Level Optimization) | phase-2 | 18-26 |
| [087](087-push-to-main-validator-scoping-and-nightly-truth-check.md) | Push-to-Main Validator Scoping + Nightly Truth-Check (Stop O(corpus) Cost on Every Push) | phase-2 | 3 |
| [091](091-tech-debt-control.md) | Technology Debt Control (Ledger, Aging, Repayment Pathways, Awareness) | phase-2 | 17-22 |
| [092](092-specrew-dashboard-web-app.md) | Specrew Dashboard Web App (Observability, Insights, Multi-Developer SDLC View) | phase-4 | 80-120 |
| [093](093-proposal-discussion-field-discipline.md) | Proposal Discussion-Field Discipline (component of 096) | phase-2 | 2-3 |
| [094](094-documentation-update-discipline.md) | Documentation Update Discipline (Plan-Time Impact Declaration, Closeout Verification) | phase-2 | 8-12 |
| [095](095-proposal-lifecycle-state-richness.md) | Proposal Lifecycle State Richness (component of 096) | phase-2 | 8-12 |
| [096](096-proposal-driven-design-profile.md) | Proposal-Driven Design Profile (Opt-In Umbrella for 028/062/091-promote/093/095) | phase-3 | 8-12 |
| [099](099-installed-file-sdlc-instruction-audit.md) | Installed-File SDLC Instruction Audit (close the dogfooding deficit between maintainer paste-prompts and installed methodology files) | phase-2 | 5-8 |
| [100](100-friction-dial.md) | Friction Dial (composable strictness surface knitting Proposals 015 + 047 + 066 into named strict/default/autonomous modes; verdict-parser acceptance changes per mode; F-039 mechanism stays universal) | phase-2 | 10-15 |
| [097](097-coupling-surface-catalog.md) | Coupling Surface Catalog (Mandatory Dependency Inventory + Hygiene + Risk Surface) | phase-2 | 18-25 (MVP); 30-40 (full vision) |
| [098](098-strategic-positioning-public-architecture-docs.md) | Strategic Positioning + Public Architecture Documentation | phase-2 | 10-15 |
| [101](101-external-tracker-sync-provider.md) | External Tracker Sync Provider Abstraction (GitHub Projects / Azure DevOps / Jira / Linear) | phase-2 | 20-30 |
| [102](102-cross-model-independent-reviewer.md) | Cross-Model Independent Reviewer (Structural Author-Reviewer Independence) | phase-3 | 15-25 |
| [103](103-agent-class-threat-surface.md) | Agent-Class Threat Surface (Concrete Threat Catalog + Prevention + Detection) | phase-3 | 12-18 |
| [106](106-provider-billing-reconciliation-and-estimator-calibration.md) | Provider Billing Reconciliation + Estimator Calibration (closed-loop cost accuracy: multi-provider billing CSV/JSON import, calibration factor computation, calibration-aware estimator, dashboard surfacing of the closed loop) | phase-2 | 12-18 |
| [109](109-open-feature-awareness-and-multi-feature-switching.md) | Open-Feature Awareness + Multi-Feature Switching Discipline + Long-Running Feature Methodology (probe + surface open features at session start; `specrew feature` CLI for park/resume/abandon/indefinite-park; closeout variants for abandoned/indefinite features) | phase-2 | 15-22 |
| [110](110-specrew-update-experience.md) | Specrew Update Experience — Multi-Host Awareness + What's-New Surface + Pre-Update Safety + Agent-Driven Explanation (extends Proposals 049 + 050 with multi-host version matrix, what's-new since installed, pre-update commit for rollback, agent-driven first-run explanation) | phase-2 | 12-18 |
| [111](111-git-hook-markdownlint-enforcement.md) | Git-Hook-Level Markdownlint Enforcement (Pre-Commit + Pre-Push) — complements Proposal 088 boundary-sync gate with commit-time hook coverage for ad-hoc commits; closes the gap that caused iter-011 CI lint cascade | phase-2 | 5-8 |
| [112](112-quality-tier-routing-runtime-verification-bundle.md) | Quality-Tier Routing + Runtime Verification + Domain Specialists + Bug-Test-First + Canonical Verdict Menu + Token Budget Awareness — 6 pillars empirically motivated by 2026-05-25 4-host smoke test (Antigravity / Codex / Claude / Copilot) on C++ DirectX dice-app prompt (originally numbered 110; renumbered iter-012 to resolve concurrent collision with Specrew Update Experience proposal) | phase-2 | 35-50 |
| [113](113-empirical-user-acceptance-gate.md) | Empirical User-Acceptance Gate — Required Human Verification Before review-signoff (3 verification modes: verified / deferred / delegated; structured-field verdict parser rejects approved-for-review-signoff without explicit acceptance evidence; composes with Proposal 112 Pillar 2 agent-side verification + Proposal 055 post-closeout sanctioned-flow) | phase-2 | 5-8 |
| [114](114-cursor-host-package.md) | Cursor Host Package — Tier-1 Multi-Host Expansion Following F-044 Per-Host Architecture (5-function contract implementation; MenuPriority 1.5; `.cursor/skills/` deployment target; `cursor agent` CLI invocation; bundle candidate with Aider/Amp/OpenCode as Tier-1 wave; empirically motivated by user demand at 2026-05-25 v0.27.0 launch) | phase-2 | 8-12 |
| [115](115-spec-first-concurrent-development-workflow.md) | Spec-First Concurrent Development Workflow — Spec-PR Serialization + Per-Developer Implementation Branches (three-phase model: sequential spec PR → parallel per-developer task branches → optional feature-closeout aggregation; new `task-assignments.yml` ledger + `specrew task claim/release/list` CLI surface; user-invented model at 2026-05-25 launch-day discussion; precedes Proposal 010's full 75 SP reconciliation by ~3-6 months to gather empirical data on team friction patterns) | phase-3 | 28-38 |
| [116](116-update-time-obsolete-file-removal.md) | Update-Time Obsolete-File Removal — Manifest-Driven Pruning of Deprecated Specrew Artifacts (per-version canonical manifest + diff engine + safety gates incl. user-edit detection + audit trail; composes with 110 to extend `specrew update` from additive-only to full reconciliation; empirically motivated by 2026-05-25 v0.27.0 release work — init is UX-confusing AND additive-only, so renamed/moved/retired files accumulate as orphans) | phase-2 | 10-15 |
| [117](117-iteration-level-lifecycle-enforcement.md) | Iteration-Level Lifecycle Enforcement — Populated state.md/review.md/retro.md Per Iteration Directory (3 enforcement layers: boundary-gate population validation + template-default detection + audit-trail surfacing; phased rollout WARN → ERROR; empirically motivated by 2026-05-25 dice-projects re-audit revealing universal pattern of empty iteration directories across ALL 5 host runs; HIGH PRIORITY to ship before external testers onboard) | phase-2 | 10-15 |
| [118](118-host-autopilot-quality-profiles.md) | Host Autopilot Quality Profiles — Document + Surface Host-Default Quality Tendencies at Selection Time (4 pillars: AutopilotProfile manifest field + selection-time disclosure + per-feature quality overrides + profile-refinement telemetry; v0 profiles authored from dice-audit empirical evidence; empirically motivated 2026-05-25 — refutes Proposal 112 Pillar 1's model-strength hypothesis; host autopilot defaults are the binding constraint, not model tier; 112 Pillar 1 reframed to within-host per-role routing only) | phase-2 | 10-15 |
| [119](119-effort-convention-conversion-table.md) | **HIGH PRIORITY** — Effort Convention Conversion Table + Helper (Methodology-Level Unification of T-Shirt Sizing and Story Points) — 3 slices (conversion data + helper + validator integration; Planner charter + iteration template + docs; downstream consumer alignment); closes the F-045 iter-001 root-cause gap where Spec-Kit `/speckit.tasks` emits S/M letters while the validator enforces numeric-only `[double]::TryParse`; consumers (validator capacity + overcommit, velocity dashboard, closeout-dashboard, retro variance) all share one helper + versioned YAML conversion table; per-project override via `.specrew/effort-convention.yml`; composes with 030 (form-vs-meaning class), 009 (velocity), 047/052 (profile overrides) | phase-2 | 8-12 |
| [120](120-handoff-block-validator-enforcement.md) | Handoff-Block Validator Enforcement + Non-Specrew-Session Bypass Detection — small-fix slice with 3 detection rules (handoff-block presence check + trigger-bypass diagnosis augmentation + wrong-location warning) + shared `Test-SpecrewHandoffBlockPresent` helper; empirically motivated by 2026-05-25 F-044 dashboard-bypass + Antigravity F-046 wrong-location + Squad+Copilot PlanningPoC handoff-drop + 2026-05-26 F-046 v0.27.2 4-gate autopilot bypass; composes with 030 / 067 / 075 / 078 / 105 | phase-2 | 3-5 |
| [121](121-review-diagrams-mermaid-template-hardening.md) | Review-Diagrams Mermaid Template Hardening — small-fix slice with validator rule + scaffolder template + Reviewer charter directive; closes form-vs-meaning gap where review-diagrams.md passes lint with ASCII ` ```text` fences instead of machine-renderable Mermaid; empirically motivated by 2026-05-25 PlanningPoC iter-001 review; composes with 012 / 030 / 067 | phase-2 | 2-3 |
| [122](122-dependency-report-enrichment-via-registry-queries.md) | Dependency-Report Enrichment via Registry Queries — extends dependency-report.md template with License + Latest + Source-Org + Canonical-URL + CVE columns; ships Reviewer skill `/specrew-dependency-research` that queries npm/NuGet/PyPI/Cargo/PowerShellGallery/OSV.dev; validator rule WARNs when manifest changes detected but enrichment missing; empirically motivated by 2026-05-25 PlanningPoC iter-001 review (current dependency-report.md passes validator but delivers no audit value); composes with 030 / 042 / 052 / 097 | phase-2 | 8-12 |
| [123](123-verdict-history-atomic-single-write-refactor.md) | Verdict-History Atomic Single-Write Refactor (Boundary-Sync Atomicity Hardening) — F-046 follow-up: split `Add-SpecrewBoundaryAuthorization` into pure delta computer + persist wrapper; `Invoke-SpecrewBoundaryStateSync` composes boundary_enforcement + session_state deltas in-memory then performs ONE `Write-Utf8FileAtomic` call; closes the two-write window Copilot's PR #934 review correctly flagged on F-046 v0.27.2; backward-compatible signature; composes with 010 / 030 / 035 / 067 / 105 | phase-2 | 5-8 |
| [124](124-multi-host-catalog-expansion-tier-1.md) | Multi-Host Catalog Expansion — Tier 1 CLIs (Aider + Amp + OpenCode + Cursor) — 3 slices using the established `hosts/<kind>/` adapter contract; per-host ~half-day mechanical cost; explicitly excludes Tier 2 (Jules/Devin/Grok pending CLI verification) and Tier 3 (Cline/Kiro/Junie IDE-embedded; DeepSeek model-layer); 2026-05-24 11-host triage memory drove the cut; composes with 024 / 058 / 069 / 104 / 105 / 108 | phase-2 | 8-12 |
| [125](125-vscode-companions-and-default-md-preview.md) | VS Code Companions Bundle (default-md-preview Extension + Curated Companions Docs + Specrew Helper Stub) — Deliverable 1: ship generic `default-md-preview` extension (separate repo + marketplace) as publishing-pipeline test milestone; Deliverable 2: add "VS Code companions" section to docs/getting-started.md with 10 curated extensions; Deliverable 3: stub the Specrew Helper extension for Phase 2c; pre-external-tester onboarding | phase-2 | 4-6 |

---

## Phase breakdown

For roadmap-style viewing, proposals grouped by phase placement:

**Phase 1** (interaction-model foundation):

- 001, 002, 003, 004, 005, 006, 007 (all shipped)
- 011 (Architecture Intent Checkpoint — draft, on-disk spec exists)
- 012 (Visual Artifact Extension — candidate)

**Phase 2** (convention enforcement + structural fidelity + distribution + state durability):

- 009 (Velocity Dashboard — shipped as feature-017)
- 031 (Specrew Distribution Module — shipped as feature-019)
- 021 (Specrew Slash-Command Surface — shipped as feature-021)
- 066 (Gate-Respecting Default + `--autonomous` Opt-In — shipped as chore `c55ec92`)
- 072 (PowerShell Gallery Unsigned Default — shipped as bug-fix slice `v0.24.1`)
- 008 (NFR Governance — draft)
- 030 (Quality Hardening Bundle — draft, HIGH-PRIORITY in queue)
- 033 (Specrew Governance CLI — draft, absorbs 028)
- 034 (Markdown Lint Cleanup — draft, post-F-019)
- 035 (Session-State Durability — draft, NEXT UP)
- 036 (Branch Reconciliation — draft, SDLC pillar)
- 073 (Review Evidence Integrity — shipped as feature-028)
- 079 (Version Information Supported-vs-Latest — shipped as small-fix slice in v0.24.2 bundle)
- 074 (Code Commentary Standards — draft, queue after 073)
- 013, 014, 015, 017, 018, 019, 020, 021, 022, 023, 027, 028, 029, 037, 038, 042, 044, 045, 046, 047, 048, 049, 050, 051, 053, 054, 056, 059, 060, 061, 062, 071, 077, 078, 080, 081, 082, 091, 093, 094, 095, 097, 098, 101, 104, 106 (candidates)

**Phase 3** (refactor + maintainability + upstream reconciliation + extensibility):

- 026 (Refactor Track R1-R5)
- 039 (Squad Upstream Reconciliation — depends on 024)
- 043 (Structured Question Protocol — could fold into 024)
- 052 (Specrew Profile System — sibling to 024 Multi-Host; both are extensibility foundations)
- 057 (Roadmap Spine + Input Adapter Pattern — depends on 052; sibling Phase 3 extensibility)
- 058 (Plugin-Based Multi-Host Distribution — partner to 024; delivery layer for multi-host)
- 096 (Proposal-Driven Design Profile — opt-in anchor profile bundling 028/062/091-promote/093/095; depends on 052)
- 102 (Cross-Model Independent Reviewer — structural author-reviewer independence; composes with 089)
- 103 (Agent-Class Threat Surface — concrete threat catalog with prevention + detection; composes with 097/102)

**Phase 4** (token economy + autopilot experiment):

- 016 (Outcome Scoring — candidate)
- 040 (Token Economy Governance — draft)
- 041 (Specrew Autopilot — candidate)
- 092 (Specrew Dashboard Web App — observability/insight web surface; event-schema chore lands earlier in phase 2)

**Phase 5** (multi-developer):

- 010 (Multi-Developer Reconciliation — draft)
- 015 Capability 3 (folds in)

**Phase 6** (multi-host, conditional):

- 024 (Multi-Host Runtime Abstraction — candidate)

**Phase 7** (brownfield, conditional):

- 025 (JIT Codebase Cartography — candidate)

**Phase 8** (packaging + 1.0):

- (not yet proposalized)

---

## Lifecycle

A proposal's status moves through:

- `candidate` (idea) → `draft` (source spec written) → `active` (in lifecycle) → `shipped` (merged to main)

Or, alternative paths:

- `candidate` → `withdrawn` (decision not to proceed)
- `draft` → `superseded` (replaced by newer proposal)
- `shipped` → `superseded` (rare; only when a later feature retires the earlier one)

See `README.md` for full lifecycle semantics.

---

## How to contribute

1. **Comment on existing proposals**: open the linked discussion thread (or create one if `discussion: tbd`) and contribute. Maintainer reviews before status transitions.

2. **Propose new features**: open an issue using the **Feature Request** template, describing the problem and rough shape. Maintainer or community contributor drafts a proposal file with status `candidate`.

3. **Improve existing proposals**: open a PR with proposed edits. Reference the discussion thread.

External contributors are welcome.
