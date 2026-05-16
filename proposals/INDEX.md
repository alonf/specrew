# Proposal Index

This index is the navigation surface for all proposals in this directory. Sorted by status first, then proposal number.

**Note**: this file is currently human-maintained. The lifecycle-hardening feature (Proposal 028) will eventually auto-generate it from per-proposal frontmatter.

---

## Shipped (8)

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

## Draft (7)

Proposals with full source-spec content, ready for `/speckit.specify` ingestion when prioritized.

| # | Title | Phase | SP | Notes |
|---|---|---|---|---|
| [008](008-nfr-governance.md) | Non-Functional Requirement Governance | phase-2 | 28 | Absorbs queued Boundary Validation Tier |
| [010](010-multi-developer-reconciliation.md) | Multi-Developer Reconciliation | phase-5 | 75 | Major scope; unlocks team scaling |
| [011](011-architecture-intent-checkpoint.md) | Architecture Intent Checkpoint | phase-1 | 10 | On-disk spec exists at specs/006-human-architecture-checkpoint |
| [012](012-visual-artifact-extension.md) | Visual Artifact Extension | phase-1 | 15 | Pillar 4 of the interaction model |
| [030](030-quality-hardening-bundle.md) | Quality Hardening Bundle (Form-vs-Meaning Verification) | phase-2 | 35 | Bundles 4 sub-components addressing form-correct/meaning-wrong bug class |
| [031](031-specrew-distribution-module.md) | Specrew Distribution Module (PowerShell Gallery) | phase-2 | 12 | One-line install via `Install-Module Specrew`; pre-public-flip priority |
| [032](032-specrew-slash-commands.md) | Specrew Slash-Command Surface | phase-2 | 7 | `/specrew.*` commands; composes tightly with 031 (combined option recommended) |

## Candidate (17)

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

---

## Phase breakdown

For roadmap-style viewing, proposals grouped by phase placement:

**Phase 1** (interaction-model foundation):
- 001, 002, 003, 004, 005, 006, 007 (all shipped)
- 011 (Architecture Intent Checkpoint — draft, on-disk spec exists)
- 012 (Visual Artifact Extension — candidate)

**Phase 2** (convention enforcement + structural fidelity):
- 008 (NFR Governance — draft)
- 009 (Velocity Dashboard — shipped as feature-017)
- 030 (Quality Hardening Bundle — draft, HIGH-PRIORITY in queue)
- 031 (Specrew Distribution Module — draft, pre-public-flip priority)
- 032 (Specrew Slash-Command Surface — draft, composes with 031)
- 013, 014, 015, 017, 018, 019, 020, 021, 022, 023, 027, 028, 029 (candidates)

**Phase 3** (refactor + maintainability):
- 026 (Refactor Track R1-R5)

**Phase 4** (validator hardening + review-depth lift, MVP):
- 016 (Outcome Scoring — candidate)

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
