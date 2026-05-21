# Proposal Index

This index is the navigation surface for all proposals in this directory. Sorted by status first, then proposal number.

**Note**: this file is currently human-maintained. The lifecycle-hardening feature (Proposal 028) will eventually auto-generate it from per-proposal frontmatter.

---

## Shipped (13)

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

## Draft (16)

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
| [069](069-multi-host-launch-path.md) | Multi-Host Launch Path + Per-Host Flag Pass-Through (Claude Code + Codex) | phase-2 | 9-10 | **URGENT — cost-reduction bundle.** `specrew start --host claude` / `--host codex` launches the alternate CLI with Specrew's bootstrap context. **Expanded 2026-05-21: also adds `--remote` flag pass-through with per-host translation** (Copilot `--remote`, Claude `--remote-control`/`--rc`, Codex warn-and-continue). First instance of the per-host flag-translation framework. Tactical MVP of Proposal 024 (Multi-Host CORE) — hard-coded per-host launch commands, no deep abstraction. Composes with 068 (model catalog) and 070 (cost tracking). |
| [070](070-token-economy-mvp.md) | Token Economy MVP (Cost-per-Iteration Tracking + Dashboard Surfacing) | phase-2 | 5 | **URGENT — cost-reduction bundle.** `specs/<feature>/iterations/<N>/cost.yml` records per-boundary token consumption + cost estimate from Proposal 068's catalog; `specrew where` dashboard gains COST section; `specrew cost summary/add/recompute` CLI. MVP slice of Proposal 040 (Token Economy as Governance Driver) — measurement only, no governance layer. |
| [074](074-code-commentary-standards.md) | Code Commentary Standards (Multi-Level Convention + Preference Dial) | phase-2 | 12-15 | Replaces the current "default to no comments" Implementer instruction with a four-category taxonomy (contract / why-rationale / concept / inline narration), a four-level preference dial (`minimalist` / `standard` / `educational` / `textbook`), and a language-idiomatic convention catalog (C# XML doc, JSDoc, docstring, Javadoc, godoc, rustdoc, PowerShell comment-based help, etc.). Reviewer agent gains a contract-docs verification check. Empirical motivation: 2026-05-21 smoke trial produced a complete .NET 8 snake-game solution with **zero XML doc comments on public APIs** — IntelliSense silently empty. Composes with Proposals 047 / 052 / 015 (dials, profiles, expertise). |

## Candidate (46)

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
| [042](042-specrew-integration-test-suite.md) | Specrew Integration Test Suite | phase-2 | 25 |
| [043](043-structured-question-protocol.md) | Structured Question Protocol | phase-3 | 10 |
| [044](044-downstream-quality-baseline-bootstrap.md) | Downstream Quality Baseline Bootstrap | phase-2 | 10 |
| [045](045-ci-watchdog-recurrence-prevention.md) | CI Watchdog & Recurrence Prevention | phase-2 | 8 |
| [046](046-auto-render-dashboard-at-closeout.md) | Auto-Render Dashboard at Iteration & Feature Closeout | phase-2 | 5 |
| [047](047-project-governance-profile.md) | Project Governance Profile (Init-Time Preference Capture) | phase-2 | 20 |
| [048](048-dashboard-velocity-metric-refinement.md) | Dashboard Velocity Metric Refinement | phase-2 | 5 |
| [049](049-version-check-source-unification.md) | Version-Check Source Unification | phase-2 | 3 |
| [050](050-version-surface-discoverability.md) | Version Surface Discoverability (init/start banner + `specrew version` command) | phase-2 | 3 |
| [051](051-path-reference-formatting-standard.md) | Path Reference Formatting Standard (file:/// URL + markdown-link surface rules) | phase-2 | 5 |
| [052](052-specrew-profile-system.md) | Specrew Profile System (Methodology Core + Domain Profile Composition) | phase-3 | 35 |
| [053](053-autopilot-decision-transparency.md) | Autopilot Decision Transparency (Surface Auto-Resolutions in Artifacts) | phase-2 | 3 |
| [054](054-pre-merge-lifecycle-verification-gate.md) | Pre-Merge End-to-End Lifecycle Verification Gate | phase-2 | 15 |
| [055](055-always-in-flow-bug-fix-lifecycle.md) | Always-In-Flow Discipline + Slice-Type Catalog (Including Bug-Fix Lifecycle) | phase-2 | 18 |
| [056](056-specrew-readonly-mode.md) | Specrew Readonly Mode (Concurrent-Session Inspection Safety) | phase-2 | 12 |
| [057](057-roadmap-spine-input-adapter-pattern.md) | Roadmap Spine + Input Adapter Pattern | phase-3 | 28 |
| [058](058-plugin-based-multi-host-distribution.md) | Plugin-Based Multi-Host Distribution (Per-Host Plugin Packaging) | phase-3 | 28 |
| [059](059-legacy-state-read-tolerance.md) | Legacy-State Read-Tolerance + Schema Migration Discipline | phase-2 | 15 |
| [060](060-prerelease-channel-staging.md) | PSGallery Prerelease Channel + Staging Discipline | phase-2 | 10 |
| [061](061-init-update-convergence-test.md) | Init/Update Convergence Test (Frozen-Snapshot Replay) | phase-2 | 13 |
| [062](062-dependency-metadata-reason-propagation.md) | Dependency Metadata + Reason Mapping + Impact-Analysis Propagation | phase-2 | 18 |
| [071](071-vscode-copilot-chat-host.md) | VS Code Copilot Chat as a First-Class Specrew Host | phase-2 | 10-12 |
| [075](075-update-artifact-backfill-discipline.md) | Specrew Update Artifact Backfill Discipline | phase-2 | 10-15 |
| [077](077-session-resume-ux.md) | Session Resume UX for Downstream Specrew Users | phase-2 | 10-15 |
| [078](078-handoff-conversation-quality.md) | Handoff Conversation Quality at All Boundary Stops | phase-2 | 10-15 |
| [079](079-version-info-supported-vs-latest.md) | Version Information — Supported vs Latest Distinction | phase-2 | 5 |

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
- 074 (Code Commentary Standards — draft, queue after 073)
- 013, 014, 015, 017, 018, 019, 020, 021, 022, 023, 027, 028, 029, 037, 038, 042, 044, 045, 046, 047, 048, 049, 050, 051, 053, 054, 055, 056, 059, 060, 061, 062, 071, 075, 077, 078, 079 (candidates)

**Phase 3** (refactor + maintainability + upstream reconciliation + extensibility):

- 026 (Refactor Track R1-R5)
- 039 (Squad Upstream Reconciliation — depends on 024)
- 043 (Structured Question Protocol — could fold into 024)
- 052 (Specrew Profile System — sibling to 024 Multi-Host; both are extensibility foundations)
- 057 (Roadmap Spine + Input Adapter Pattern — depends on 052; sibling Phase 3 extensibility)
- 058 (Plugin-Based Multi-Host Distribution — partner to 024; delivery layer for multi-host)

**Phase 4** (token economy + autopilot experiment):

- 016 (Outcome Scoring — candidate)
- 040 (Token Economy Governance — draft)
- 041 (Specrew Autopilot — candidate)

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
