# Implementation Plan: Slash-Command Multi-Host Correctness

**Branch**: `024-slash-command-multi-host-correctness` | **Date**: 2026-05-19 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `specs/024-slash-command-multi-host-correctness/spec.md`

**Note**: This template is filled in by the `/speckit.plan` command. See `.specify/templates/plan-template.md` for the execution workflow.

## Summary

Feature 024 restores the slash-command surface promised in Feature 021 by deploying all seven existing Specrew commands to `.claude/skills/`, `.github/skills/`, and `.agents/skills/` with content-identical `SKILL.md` files, valid YAML frontmatter, hyphenated `/specrew-*` naming, and safe migration of Specrew-managed legacy `.copilot/skills/specrew-*` directories during `specrew update`. This feature repairs the form-vs-meaning failure where slash commands existed on disk but were not discoverable in Claude Code or GitHub Copilot CLI, limits public v0.24.0 discoverability claims to Claude Code + GitHub Copilot CLI while deploying `.agents/skills/` as host-neutral future-proof path, and reframes Proposal 058 to non-skill instruction-file harmonization only.

## Technical Context

**Language/Version**: PowerShell 7.0+ (per `Specrew.psd1`), Markdown skill templates with YAML frontmatter  
**Primary Dependencies**: Specrew PowerShell module/runtime scripts (`Specrew.psm1`, `scripts/*.ps1`, `extensions/specrew-speckit/scripts/deploy-squad-runtime.ps1`), Git, standard PowerShell file/YAML handling already used in-repo  
**Storage**: Filesystem only — source templates under `extensions/specrew-speckit/squad-templates/skills/`, active deployment targets `.claude/skills/`, `.github/skills/`, `.agents/skills/`, legacy migration target `.copilot/skills/`  
**Testing**: Standalone PowerShell integration scripts under `tests/integration/` (`slash-command-distribution.tests.ps1`, `slash-command-discovery.tests.ps1`, `slash-command-compatibility.tests.ps1`, `slash-command-coexistence.tests.ps1`) plus three new feature tests for multi-path deployment, frontmatter validity, and legacy migration  
**Target Platform**: Windows/macOS/Linux repositories running PowerShell 7+ with Git working-tree access  
**Project Type**: PowerShell module + Spec Kit extension runtime + markdown skill-template surface  
**Performance Goals**: Keep `specrew init` / `specrew update` runtime materially unchanged while writing 7 commands × 3 active paths; no additional user-visible blocking beyond normal file deployment  
**Constraints**: Active discoverability claims limited to Claude Code + GitHub Copilot CLI; `.agents/skills/` is deployment-only future-proofing, not a Codex guarantee; active artifacts use `/specrew-*`; legacy `.copilot/skills/` cleanup must remove only explicit Specrew-owned content and preserve unmanaged content  
**Scale/Scope**: Seven existing slash commands (`where`, `status`, `update`, `team`, `review`, `help`, `version`), three supported deployment paths, one legacy migration path, existing Feature 021 integration test suite + three new tests

## Phase 1 Quality Planning

> Fill this section when the stack-aware quality-bar capability applies to the active feature. Keep it bounded to the implemented Phase 1 slice only.

**Phase Scope**: `phase-1-first-slice`  
**Inferred Quality Profile**: `quality-profile.custom-composition.v1`  
**Selected preset ref or explicit custom composition**: Custom composition for PowerShell runtime deployment + markdown skill templates + standalone integration scripts  
**Bounded custom composition**: This feature repairs slash-command deployment logic in a PowerShell module and refreshes markdown skill template content with YAML frontmatter. The quality profile is a custom composition targeting PowerShell scripting practices, template integrity, migration safety, and the existing standalone integration-test lane.

### Stack Surfaces in Scope

| Stack Surface | Path Globs / Evidence | Recognized Stack | Why It Matters |
| --- | --- | --- | --- |
| PowerShell deployment logic | `extensions/specrew-speckit/scripts/deploy-squad-runtime.ps1`, `scripts/specrew-update.ps1`, `scripts/specrew-init.ps1` | custom-powershell | Core multi-host deployment, update reporting, and legacy cleanup surfaces |
| Markdown skill templates | `extensions/specrew-speckit/squad-templates/skills/specrew-*/SKILL.md`, `extensions/specrew-speckit/squad-templates/skills/README.md` | custom-markdown-templates | Canonical slash-command metadata/body content that must become cross-host discoverable |
| Integration validation scripts | `tests/integration/slash-command-*.tests.ps1` | custom-powershell-tests | Existing regression lane must migrate to hyphenated multi-host reality and absorb three new tests |

### Risk Dimensions

| Risk Dimension | Status (`required` / `not-applicable`) | Rationale |
| --- | --- | --- |
| Deployment safety | required | The feature changes the runtime deployment surface and cleanup behavior; deleting unmanaged content or diverging target content would be a product break |
| Discoverability truthfulness | required | Feature 024 is only successful when deployed files are actually discoverable in claimed hosts, not merely present on disk |
| Test integrity | required | Existing slash-command coverage must be migrated without skipped assertions, and three new tests must prove the restored surface |
| Template validity | required | Every `SKILL.md` must gain valid YAML frontmatter while preserving Feature 021 body guidance and active `/specrew-*` naming |
| Release-message consistency | required | CHANGELOG/proposal/version-bearing artifacts must match the narrowed host-coverage claim and legacy-migration reality |

### Quality Tool Bundle

| Area | Selection | Evidence / Notes |
| --- | --- | --- |
| Bundle ID | `feature-024-custom-composition` | Custom composition for PowerShell runtime deployment + markdown skill metadata + standalone integration scripts |
| Mechanical Checks | dead-field, anti-pattern, test-integrity | Evidence recorded in the feature iteration quality artifacts during implementation |
| Ecosystem Tools | `pwsh -NoProfile -File tests/integration/slash-command-distribution.tests.ps1`, `pwsh -NoProfile -File tests/integration/slash-command-discovery.tests.ps1`, `pwsh -NoProfile -File tests/integration/slash-command-compatibility.tests.ps1`, `pwsh -NoProfile -File tests/integration/slash-command-coexistence.tests.ps1`, plus three new `pwsh -NoProfile -File ...` scripts for multi-path/frontmatter/migration | Repo-standard PowerShell validation surface; no new runner required |

### Required Quality Gates

| Required Quality Gate | Category | Evidence Source | Phase 1 Status |
| --- | --- | --- | --- |
| `dead-field` | mechanical | `specs/024-slash-command-multi-host-correctness/iterations/001/quality/mechanical-findings.json` | planned |
| `anti-pattern` | mechanical | `specs/024-slash-command-multi-host-correctness/iterations/001/quality/mechanical-findings.json` | planned |
| `test-integrity` | mechanical | `specs/024-slash-command-multi-host-correctness/iterations/001/quality/mechanical-findings.json` + migrated/new slash-command test scripts | planned |
| `stack-tooling-evidence` | tooling | `specs/024-slash-command-multi-host-correctness/iterations/001/quality/quality-evidence.md` | planned |
| `quality-lens-review` | manual-evidence | `specs/024-slash-command-multi-host-correctness/iterations/001/quality/quality-evidence.md` | planned |

### Not-Applicable Dimensions and Rationale

| Dimension / Gate | Why Not Applicable in This Feature | Follow-up |
| --- | --- | --- |
| `security-issues-v1` | No external network/API surface or secret-handling change is introduced by this slice; the meaningful risk is deletion/discoverability drift, not classic security exposure | none |
| `concurrency-correctness-review` | The approved slice is file-based and single-process; no concurrent/shared-lock protocol is introduced | none |
| `performance-profiling-v1` | This feature is dominated by a small fixed file-copy workload; no material performance tuning surface is introduced | none |

### Explicit Phase 2+ Deferrals

- Pre-implementation hardening gate sign-off and blocking semantics remain deferred in this template.
- Dedicated bug-hunter lens execution and strongest-class routing remain deferred in this template.
- Quality-drift logic, mixed-stack override workflows, and reference-implementation comparison remain deferred in this template.

## Phase 2 Hardening and Specialist Review Planning

> Fill this section when pre-implementation hardening and specialist bug-hunter review planning apply to the active feature. Mirror the bounded Phase 2 planning metadata from quality-profile resolution when available: slice scope, artifact refs, focus-area statuses, lens activation classifications, routing defaults, and explicit later deferrals, plus the planning-time-vs-runtime evidence boundary. Keep it bounded to the currently approved hardening slice; record planning-time analysis, expected controls, rationale, explicit non-applicable reasoning, and any narrow runtime-only deferments instead of implying later execution or runtime proof already happened.

**Phase 2 Slice Scope**: `Iteration 001 pre-implementation hardening plan for multi-host deployment correctness, legacy cleanup safety, and discoverability truthfulness`  
**Hardening Gate Artifact**: `specs/024-slash-command-multi-host-correctness/iterations/001/quality/hardening-gate.md`  
**Known-Traps Corpus Location**: `.specrew/quality/known-traps.md`  
**Trap Reapplication Artifact**: `none yet`

### Hardening Focus Areas

| Focus Area | Why It Matters in This Slice | Planned Artifact / Evidence | Status (`required` / `deferred` / `not-applicable`) |
| --- | --- | --- | --- |
| Discoverability/truthfulness analysis | The original failure mode was “files exist but commands are not discoverable.” The hardening slice must keep host-claim evidence and active-message truthfulness explicit before implementation starts. | `contracts/discovery-contract.md` + `iterations/001/quality/hardening-gate.md` | required |
| Error handling and migration failure semantics | Update-time cleanup must fail safely, preserve unmanaged content, and report leftovers clearly instead of silently deleting by name. | `contracts/migration-safety.md` + `iterations/001/quality/hardening-gate.md` | required |
| Retry and idempotency expectations | `specrew update` should be safely repeatable after a partial or already-completed migration; no retry loop is planned, but idempotent re-run expectations must be explicit. | `contracts/migration-safety.md` + `quickstart.md` | required |
| Test-integrity targets | The slice is only credible if existing slash-command scripts stay active and three new scripts prove multi-path deployment, frontmatter validity, and legacy migration. | `quickstart.md` + `iterations/001/quality/quality-evidence.md` | required |

### Lens Activation Plan

| Lens / Checklist Ref | Activation (`required` / `optional` / `not-applicable`) | Why Activated or Omitted | Planned Evidence / Artifact Path |
| --- | --- | --- | --- |
| `error-handling-review-v1` | required | Legacy cleanup and deployment divergence must remain reviewer-visible and non-destructive | `specs/024-slash-command-multi-host-correctness/iterations/001/quality/hardening-gate.md` |
| `test-integrity-review-v1` | required | Existing slash-command scripts plus the three new tests are the main proof surface for Feature 024 | `specs/024-slash-command-multi-host-correctness/iterations/001/quality/quality-evidence.md` |
| `operational-resilience-review-v1` | required | `specrew init` / `specrew update` must remain safe and repeatable across fresh bootstrap and upgrade scenarios | `specs/024-slash-command-multi-host-correctness/iterations/001/quality/hardening-gate.md` |
| `security-issues-v1` | not-applicable | The slice does not introduce a new network/credential/trust-boundary surface; its meaningful risks are correctness and truthfulness | N/A |

### Routing Policy

| Lens Scope | Requested Reasoning / Review Class | Effective Class (when run) | Override / Approval Record | Notes |
| --- | --- | --- | --- | --- |
| Required hardening and bug-hunter lenses | `strongest-available` | `pending-runtime-execution` | `none` | Planning sets the requested baseline only; execution evidence remains deferred until implementation/review |

### Explicit Later Deferrals

- Full line-by-line lens execution evidence and runtime-only final proof remain deferred until the approved implementation/review slice authorizes them.
- Known-traps corpus seeding, approved additions, and trap reapplication remain deferred until the dedicated known-traps slice is in scope.
- Strongest-class routing enforcement details and requested-versus-effective execution evidence remain deferred until the routed lens execution path exists.
- Quality-drift comparison, mixed-stack override workflows, and reference-implementation checks remain deferred unless the approved slice explicitly includes them.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- **Spec Authority Gate**: ✅ **PASS** — Plan scope maps directly to approved spec artifacts from `specs/024-slash-command-multi-host-correctness/spec.md`, with clarification from 2026-05-19 limiting public v0.24.0 discoverability claims to Claude Code + GitHub Copilot CLI while still deploying `.agents/skills/` as host-neutral path. All 12 functional requirements (FR-001..FR-012) are in scope, and the before-plan hook already passed after spec approval.
- **Layering Gate**: ✅ **PASS** — Changes are correctly classified as **Spec Kit layer** (extension runtime: `extensions/specrew-speckit/scripts/deploy-squad-runtime.ps1`, skill templates: `extensions/specrew-speckit/squad-templates/skills/specrew-*/SKILL.md`) and **project-level testing** (`tests/integration/slash-command-*.tests.ps1`). No Squad layer changes required. No architectural confusion.
- **Traceability Gate**: ✅ **PASS** — Phase 0 research.md will resolve YAML frontmatter requirements, multi-host deployment patterns, managed-marker detection for safe migration. Phase 1 data-model.md will define slash-command entities, deployment-target entities, legacy-migration entities. Phase 1 contracts/ will define multi-host deployment contract, frontmatter validity contract, migration safety contract, discovery contract for Claude Code + GitHub Copilot CLI + host-neutral `.agents/skills/`. Each deliverable traces to FR-001..FR-012 and User Stories 1-3.
- **Ownership Gate**: ✅ **PASS** — **Spec Steward**: Alon Fliess (accountable for preserving AC1-AC10 substance). **Iteration Facilitator**: Feature 024 Specrew squad facilitator. **Runtime Maintainer**: deploy-squad-runtime.ps1 changes. **Template Steward**: skill template YAML frontmatter and hyphenated naming. **QA Owner**: integration test migration and three new tests. **Release Owner**: v0.24.0 prerelease validation and stable promotion. **Governance Steward**: Proposal 058 reframing and FR-012 narrowed host-coverage wording.
- **Capacity Gate**: ✅ **PASS** — Effort unit: **story points**. Estimated capacity: **5-7 story points** for single-iteration Feature 024. Capacity budget: one normal feature iteration culminating in v0.24.0 after prerelease validation via v0.24.0-beta.1.
- **Drift/Reconciliation Gate**: ✅ **PASS** — Drift detection signals defined in spec: surviving `/specrew.X` references in active materials, missing/invalid frontmatter, non-identical deployment content across paths, unmanaged content deleted during migration, Proposal 058 language still treating skills as unresolved. Reconciliation: human oversight points include approve prerelease smoke evidence before stable promotion, review PR-at-feature-close, confirm changelog and proposal wording keep FR-012's narrowed host-coverage claim intact before merge.
- **Verification Gate**: ✅ **PASS** — Process verification: constitution checks (this section), spec-to-plan traceability, plan-to-tasks traceability. Outcome verification: existing slash-command integration tests pass after hyphenated-form migration, three new tests pass (multi-path deployment, frontmatter validity, legacy migration), prerelease validation via v0.24.0-beta.1 confirms restored Claude Code or GitHub Copilot CLI slash-command surface, host-neutral `.agents/skills/` deployment, metadata validity, and migration behavior. Acceptance-criteria validation: AC1-AC10 mapped to FR-001..FR-012 and success criteria SC-001..SC-005.

## Project Structure

### Documentation (this feature)

```text
specs/024-slash-command-multi-host-correctness/
├── plan.md              # This file (/speckit.plan command output)
├── research.md          # Phase 0 output (/speckit.plan command)
├── data-model.md        # Phase 1 output (/speckit.plan command)
├── quickstart.md        # Phase 1 output (/speckit.plan command)
├── contracts/           # Phase 1 output (/speckit.plan command)
│   ├── multi-host-deployment.md
│   ├── frontmatter-validity.md
│   ├── migration-safety.md
│   └── discovery-contract.md
├── checklists/
│   └── requirements.md  # Pre-plan readiness checklist (passed)
└── tasks.md             # Phase 2 output (/speckit.tasks command - NOT created by /speckit.plan)
```

### Source Code (repository root)

```text
# PowerShell module and extension runtime
Specrew.psm1                      # Main module (no changes expected for this feature)
Specrew.psd1                      # Module manifest (version bump to 0.24.0)

extensions/specrew-speckit/
├── scripts/
│   └── deploy-squad-runtime.ps1  # Multi-host deployment logic, legacy migration (lines ~377-416 expanded)
└── squad-templates/
    └── skills/
        ├── specrew-where/
        │   └── SKILL.md           # Add YAML frontmatter, rename `/specrew.where` → `/specrew-where` in body
        ├── specrew-status/
        │   └── SKILL.md           # Add YAML frontmatter, rename `/specrew.status` → `/specrew-status` in body
        ├── specrew-update/
        │   └── SKILL.md           # Add YAML frontmatter, rename `/specrew.update` → `/specrew-update` in body
        ├── specrew-team/
        │   └── SKILL.md           # Add YAML frontmatter, rename `/specrew.team` → `/specrew-team` in body
        ├── specrew-review/
        │   └── SKILL.md           # Add YAML frontmatter, rename `/specrew.review` → `/specrew-review` in body
        ├── specrew-help/
        │   └── SKILL.md           # Add YAML frontmatter, rename `/specrew.help` → `/specrew-help` in body
        └── specrew-version/
            └── SKILL.md           # Add YAML frontmatter, rename `/specrew.version` → `/specrew-version` in body

# Integration tests
tests/integration/
├── slash-command-distribution.tests.ps1      # Existing coverage to migrate from `.copilot/skills` assumptions
├── slash-command-discovery.tests.ps1         # Existing coverage to migrate from `/specrew.*` to `/specrew-*`
├── slash-command-compatibility.tests.ps1     # Existing coverage to migrate to the corrected surface
├── slash-command-coexistence.tests.ps1       # Existing coexistence guardrail coverage
├── slash-command-multi-path.tests.ps1        # NEW planned test: three-path deployment + content identity
├── slash-command-frontmatter.tests.ps1       # NEW planned test: YAML frontmatter validity
└── slash-command-legacy-migration.tests.ps1  # NEW planned test: managed legacy cleanup + unmanaged preservation

# Governance and documentation
CHANGELOG.md                                      # Add v0.24.0 entry describing restored discoverability, multi-host deployment, migration
proposals/058-plugin-based-multi-host-distribution.md  # Reframe scope to non-skill instruction-file harmonization only
```

**Structure Decision**: Feature 024 modifies existing PowerShell module runtime (deploy-squad-runtime.ps1), refreshes seven existing skill templates with YAML frontmatter and hyphenated naming, migrates four existing integration tests to new form, and adds three new integration tests. No new projects or architectural layers introduced.

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

No violations. Constitution Check passed pre-Phase 0 and post-Phase 1.

---

## Post-Phase-1 Constitution Re-Check

**Re-evaluation after Phase 1 design artifacts (research.md, data-model.md, contracts/, quickstart.md) are complete**:

- **Spec Authority Gate**: ✅ **PASS** — Phase 1 artifacts (research.md resolved all unknowns, data-model.md defined six entities, contracts/ defined four contracts, quickstart.md provided developer onboarding) all map directly to approved spec FR-001..FR-012. No scope creep, no unresolved NEEDS CLARIFICATION.
- **Layering Gate**: ✅ **PASS** — Phase 1 design remains correctly classified as **Spec Kit layer** (extension runtime + skill templates) and **project-level testing**. No Squad layer changes introduced during design. No architectural confusion.
- **Traceability Gate**: ✅ **PASS** — All Phase 1 artifacts trace to approved spec requirements:
  - research.md → FR-003 (frontmatter), FR-001/FR-002 (multi-host), FR-005 (migration), FR-004 (hyphenated naming), FR-007 (test migration), FR-008 (prerelease validation)
  - data-model.md → FR-001/FR-002 (Deployment Target), FR-003 (YAML Frontmatter Block), FR-005 (Legacy Skill Directory), entities defined
  - contracts/ → FR-001/FR-002 (multi-host-deployment.md), FR-003 (frontmatter-validity.md), FR-005 (migration-safety.md), FR-012 (discovery-contract.md)
  - quickstart.md → FR-006/FR-007 (test guidance), FR-008 (prerelease validation workflow)
- **Ownership Gate**: ✅ **PASS** — Roles remain explicit and unchanged from pre-Phase-0 check. Quickstart.md reinforces role accountability (Template Steward, Runtime Maintainer, QA Owner, Release Owner, Governance Steward).
- **Capacity Gate**: ✅ **PASS** — Effort estimate remains 5-7 story points for single-iteration Feature 024. Phase 1 design artifacts do not introduce scope expansion or capacity overrun signals.
- **Drift/Reconciliation Gate**: ✅ **PASS** — Drift detection signals defined in spec remain valid. Quickstart.md reinforces human oversight points (prerelease smoke evidence approval, PR-at-feature-close review, changelog/proposal wording verification).
- **Verification Gate**: ✅ **PASS** — Phase 1 artifacts define clear verification activities:
  - Automated tests: multi-path deployment test, frontmatter validity test, migration behavior test (quickstart.md Step 4)
  - Manual validation: prerelease smoke test for Claude Code or GitHub Copilot CLI discoverability (quickstart.md Step 7)
  - Acceptance-criteria validation: SC-001..SC-005 mapped to test coverage in data-model.md and contracts/

**Conclusion**: Constitution Check **PASSES** post-Phase-1 design. Proceed to Phase 2 (`/speckit.tasks` command) to generate tasks.md when ready.

---

## Phase 1 Completion Summary

### Artifacts Generated

1. ✅ **research.md** — Resolved six research areas: YAML frontmatter requirements, multi-host deployment patterns, managed-marker detection, hyphenated naming migration, integration test migration strategy, prerelease validation strategy.
2. ✅ **data-model.md** — Defined six entities: Slash Command Definition, Deployment Target, Legacy Skill Directory, YAML Frontmatter Block, Deployment Operation, Migration Operation. Defined relationships, validation rules, state transitions.
3. ✅ **contracts/** — Generated four contracts:
   - `multi-host-deployment.md` — Content-identical deployment to three target paths, source-of-truth, failure handling.
   - `frontmatter-validity.md` — YAML structure, validation rules, cross-host compatibility, markdown body preservation.
   - `migration-safety.md` — Managed/unmanaged classification, migration workflow, safe removal/preservation.
   - `discovery-contract.md` — Host-coverage claims (Claude Code + GitHub Copilot CLI), host-neutral `.agents/skills/` future-proofing, truthfulness requirements, discovery fallback.
4. ✅ **quickstart.md** — Developer onboarding for template editing, deployment logic updates, integration test migration, new test creation, CHANGELOG.md updates, Proposal 058 reframing, prerelease validation workflow, troubleshooting.
5. ✅ **Agent context update** — GitHub Copilot context file refreshed from the finalized plan via `.specify/scripts/powershell/update-agent-context.ps1 -AgentType copilot`.

### Key Decisions Locked In

| Decision Area | Locked Decision | Traceability |
| --- | --- | --- |
| YAML Frontmatter | Mandatory `name` (directory-matching) + `description` (non-empty) for Claude Code + GitHub Copilot CLI parity | research.md § 1, contracts/frontmatter-validity.md |
| Multi-Host Paths | Deploy to `.claude/skills/`, `.github/skills/`, `.agents/skills/` with content-identical files | research.md § 2, contracts/multi-host-deployment.md |
| Managed-Marker Detection | Reuse existing `Set-ManagedFile` tracking for safe migration | research.md § 3, contracts/migration-safety.md |
| Hyphenated Naming | `/specrew-X` in all active references, `/specrew.X` preserved in historical artifacts | research.md § 4, contracts/discovery-contract.md |
| Test Migration | Migrate 4 existing tests + add 3 new tests (multi-path, frontmatter, migration) | research.md § 5, quickstart.md Step 3-4 |
| Prerelease Validation | v0.24.0-beta.1 cycle with manual discoverability smoke + automated test pass | research.md § 6, quickstart.md Step 7 |
| Host Coverage | Public v0.24.0 claims limited to Claude Code + GitHub Copilot CLI; `.agents/skills/` deployed as host-neutral path | contracts/discovery-contract.md, FR-012 |

### Readiness for Phase 2 (Tasks Generation)

Phase 1 is **complete**. All unknowns resolved, all design artifacts generated, Constitution Check passed post-design. Ready to proceed to Phase 2 (`/speckit.tasks` command) to generate dependency-ordered tasks.md when authorized.
