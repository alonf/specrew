# Implementation Plan: Specrew — Spec-Governed AI Crew Operating Model

**Branch**: `001-specrew-product` | **Date**: 2026-04-17 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `specs/001-specrew-product/spec.md`

## Summary

Specrew bridges Spec Kit (specification/governance) and Squad (multi-agent runtime) into a unified spec-governed operating model for AI crews. The technical approach is to build two companion extensions — a Spec Kit extension for governance lifecycle and a Squad extension for crew execution — sharing a monorepo but independently packaged, with all iteration artifacts stored as Markdown in the spec feature directory.

## Technical Context

**Language/Version**: Markdown, YAML, PowerShell (Spec Kit extension assets). TypeScript/Node.js for Squad SDK config if needed.
**Primary Dependencies**: Spec Kit >= 0.7.3 (extension starter template), Squad >= 0.9.1 (extension structure: skills/ceremonies/directives)
**Storage**: Markdown files in spec feature directories (git-tracked, human-readable)
**Testing**: PowerShell-based validation scripts (Spec Kit side), Squad CLI for ceremony/skill testing. Custom evaluation harness for end-to-end.
**Target Platform**: GitHub Copilot via Squad (v1). Architecture must be runtime-portable.
**Project Type**: Extension pair (Spec Kit extension + Squad plugin) in a monorepo
**Performance Goals**: Bootstrap in <10 min user effort. Iteration planning/review add <5 min overhead per iteration.
**Constraints**: Must integrate through supported extension surfaces only (Constitution III). No Copilot/VS Code direct hacks.
**Scale/Scope**: Single-project governance scope per bootstrap. Evaluation harness runs 2–3 iterations against a reference spec.

## Constitution Check (Pre-Design)

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- **Spec Authority Gate**: PASS — Plan scope maps directly to spec.md FR-001 through FR-020 and US-1 through US-7. No plan item exists without a spec reference.
- **Layering Gate**: PASS — Every component is classified below:
  - Standalone CLI: `specrew init` (orchestration layer above both platforms)
  - Spec Kit layer: governance scaffold, drift detection, extension collision detection, downstream constitution generation
  - Squad layer: baseline crew roles, iteration ceremonies (Planning, Review/Demo), skills, directives, post-task drift hook
  - Shared: iteration artifact storage format (Markdown in spec dir), evaluation harness
- **Traceability Gate**: PASS — Phased delivery plan below maps each deliverable to FR/US references.
- **Ownership Gate**: PASS — Workstreams assigned:
  - Standalone CLI (`specrew init`): Specrew maintainers (FR-002, FR-020)
  - Spec Kit extension: Specrew maintainers (FR-001, FR-011, FR-013, FR-016)
  - Squad extension: Specrew maintainers (FR-004, FR-005, FR-006, FR-008, FR-009, FR-010)
  - Iteration engine: Specrew maintainers (FR-007, FR-017, FR-018, FR-019)
  - Evaluation harness: Specrew maintainers (FR-015)
  - Spec Steward accountability: assigned per-project at bootstrap (FR-004)
- **Capacity Gate**: Effort unit = story points (Specrew v1 design decision). Iteration capacity = scope-boxed. Detailed capacity set per iteration at planning time.
- **Drift/Reconciliation Gate**: Active post-task drift detection via Squad hook (FR-008). Spec Steward reviews each task output against source requirement. Formal review at Review/Demo gate (FR-009). Drift events recorded as Markdown files.
- **Verification Gate**: Process quality via ceremony adherence checks. Outcome quality via requirement-to-deliverable traceability. Evaluation harness (FR-015) validates both end-to-end. Acceptance criteria validated per US acceptance scenarios.

## Constitution Check (Post-Design)

*Re-evaluated after Phase 1 design completion.*

- **Spec Authority Gate (I)**: PASS — Architecture shows spec as authoritative input. `spec-authority.md` directive enforces. FR-003 traced.
- **Layering Gate (II)**: PASS — Every component assigned to Spec Kit, Squad, or shared layer. No cross-layer leakage.
- **Traceability Gate (IX, XVIII)**: PASS — All deliverables mapped to FR references. Data model requires task-to-requirement tracing. Traceability directive enforces at runtime.
- **Ownership Gate (XIII, XIV)**: PASS — Workstream ownership assigned. 5 baseline roles with explicit responsibilities, persisted and auditable.
- **Capacity Gate (XVI)**: PASS — Iteration Config defines effort_unit, capacity_per_iteration, overcommit threshold. Capacity planning skill checks limits.
- **Drift/Reconciliation Gate (VIII, XX)**: PASS — Skill+directive pattern for per-task drift detection (research R1). Drift Event entity defined. Contracts specify inputs/outputs.
- **Verification Gate (XXI, XXIII, XXIV, XXV)**: PASS — Testing strategy, quality model, evaluation harness cover process and outcome quality.
- **Extension Surface Gate (III)**: PASS — All components use documented extension surfaces. No undocumented hooks (research R1).
- **Non-Interference Gate (X, XI)**: PASS — Collision detector planned (Iter 3). Collision Record entity defined. Error contract specified.
- **Constitution Stability**: PASS — No constitution amendments required. All product behavior in spec/plan.

## 1. Architecture Overview

```text
┌──────────────────────────────────────────────────────────────┐
│                        User / Human                          │
│  (Spec Steward, Iteration Facilitator, Stakeholder)          │
└──────────────┬──────────────────────────┬────────────────────┘
               │ specrew init             │ iteration lifecycle
               ▼                          ▼
┌──────────────────────────────────────────────────────────────┐
│  Standalone Bootstrap CLI (specrew init)                      │
│  • Works before .specify/ or .squad/ exist                   │
│  • Calls specify init + squad init as sub-steps              │
│  • Installs Specrew extensions, scaffolds governance          │
└──────────────┬────────────────────────────────┬───────────────┘
               │                                │
               ▼                                ▼
┌──────────────────────────┐  ┌─────────────────────────────────┐
│   Spec Kit Extension      │  │     Squad Extension             │
│   (specrew-speckit)       │  │     (specrew-squad)             │
│                           │  │                                 │
│  • Governance scaffold    │  │  • Baseline crew roles          │
│  • Downstream constitution│  │    (Steward, Planner,           │
│  • Drift detection logic  │  │     Implementer, Reviewer,      │
│  • Collision detection    │  │     Retro Facilitator)          │
│  • Spec lifecycle hooks   │  │  • Ceremonies:                  │
│  • Version validation     │  │    - Planning (Specrew-defined) │
│  • Brownfield merge       │  │    - Review/Demo (Specrew-def.) │
│                           │  │    - Retrospective (Squad blt.) │
│  Activates: .specify/     │  │  • Skills:                      │
│  must exist                │  │    - Drift check skill          │
│                           │  │    - Capacity planning skill    │
│                           │  │    - Traceability skill         │
│                           │  │  • Directives:                  │
│                           │  │    - Spec authority directive   │
│                           │  │    - Traceability directive     │
│                           │  │  • Post-task hook (drift)       │
│                           │  │                                 │
│                           │  │  Activates: .squad/             │
│                           │  │  must exist                     │
└──────────────┬───────────┘  └──────────────┬──────────────────┘
               │                              │
               ▼                              ▼
┌──────────────────────────────────────────────────────────────┐
│               Shared: Iteration Artifacts                    │
│  specs/NNN-feature/iterations/NNN/                           │
│    plan.md | drift-log.md | review.md | retro.md             │
│  specs/NNN-feature/evaluation/                               │
│    report.md                                                 │
└──────────────────────────────────────────────────────────────┘
```

## 2. Main Components and Responsibilities

| Component | Layer | Responsibilities | Spec References |
| --------- | ----- | ---------------- | --------------- |
| `specrew init` | Standalone CLI | Dependency detection/install, `specify init`/`squad init` orchestration, version validation, governance scaffold, brownfield merge, extension installation | FR-002, FR-020 |
| Governance Scaffold | Spec Kit ext | Generate downstream constitution placeholder, iteration config template, role assignment file | FR-011, FR-016 |
| Drift Detection | Spec Kit ext + Squad ext | Spec Kit side: diff logic comparing task output to requirement. Squad side: post-task hook invoking drift check. | FR-003, FR-008 |
| Collision Detector | Spec Kit ext | Scan installed extensions for hook/artifact conflicts, report clearly | FR-012 |
| Baseline Crew | Squad ext | Define 5 roles as Squad team members. Project-specific roles added via Squad config. | FR-002, FR-004 |
| Iteration Ceremonies | Squad ext | Planning, Review/Demo (Specrew-defined), Retrospective (Squad built-in) | FR-005, FR-009, FR-010 |
| Iteration Engine | Squad ext + skills | Task mapping to requirements, effort estimation, capacity checking, task state persistence, resume | FR-006, FR-007, FR-017, FR-018, FR-019 |
| Evaluation Harness | Shared (scripts) | Bootstrap fresh project, run N iterations, produce process + outcome report | FR-015 |

## 3. What Belongs in the Spec Kit Extension

The Spec Kit extension (`specrew-speckit`) contains:

- **Hooks**: `before_plan` (validate spec has requirements), `after_tasks` (verify traceability), `before_implement` (verify iteration plan approved)
- **Templates**: Downstream constitution template, iteration config template, role assignment template
- **Config**: Specrew-specific settings in `.specify/extensions.yml` (version pins, feature flags)
- **Scripts**: Governance scaffold generation, version validation, brownfield merge, collision detection, drift diff logic

**Note**: `specrew init` is NOT part of this extension. It is a standalone CLI that runs before `.specify/` exists. The Spec Kit extension activates only after `.specify/` has been created (by `specify init`, called from `specrew init`).

## 4. What Belongs in the Squad Extension

The Squad extension (`specrew-squad`) contains:

```text
specrew-squad/
├── skills/
│   ├── drift-check.md          # Check task output against source requirement
│   ├── capacity-planning.md    # Estimate effort, check capacity limits
│   ├── traceability-check.md   # Verify task-to-requirement links
│   └── iteration-resume.md     # Resume from last completed task
├── ceremonies/
│   ├── planning.md             # Specrew-defined: plan iteration from spec
│   └── review-demo.md          # Specrew-defined: per-task verdict gate
├── directives/
│   ├── spec-authority.md       # "The spec is the source of truth" directive
│   ├── traceability.md         # "Every task must trace to a requirement" directive
│   └── drift-reporting.md      # "Report drift immediately, do not normalize" directive
└── README.md
```

Squad's built-in Retrospective ceremony is used directly — Specrew does not redefine it.

## 5. Squad SDK Code in v1

**Decision: Defer Squad SDK (`squad.config.ts`) to post-MVP.**

Rationale:
- v1 can be fully implemented using Squad's documented extension structure (skills, ceremonies, directives) — all Markdown-based.
- The post-task drift hook is the only feature that may require SDK-level code. During implementation, validate whether Squad's `HookPipeline` can be configured via extension Markdown or requires `squad.config.ts`. If SDK is needed for the hook only, add a minimal `squad.config.ts` with just the hook registration.
- Full SDK-first mode (`squad build`) is experimental per Squad docs and adds build complexity inappropriate for MVP.

**Post-MVP**: If iteration engine features (capacity tracking, resume state machine) benefit from programmatic control, migrate to SDK-defined team configuration.

## 6. Repository Layout

```text
specrew/                              # Monorepo root
├── .github/
│   ├── ISSUE_TEMPLATE/
│   │   ├── bug.yml
│   │   ├── feature.yml
│   │   └── task.yml
│   ├── prompts/                      # Spec Kit prompt files
│   ├── workflows/
│   │   ├── ci.yml                    # Lint + test on PR
│   │   └── release.yml               # Package + publish on tag
│   └── CODEOWNERS
├── .specify/                         # Spec Kit project config (created by specify init)
│   ├── extensions.yml
│   ├── memory/
│   │   └── constitution.md           # Specrew's OWN constitution
│   ├── templates/
│   └── scripts/
├── specs/                            # Specrew's own feature specs
│   └── 001-specrew-product/
│       ├── spec.md
│       ├── plan.md
│       └── ...
├── scripts/
│   └── specrew-init.ps1              # Standalone bootstrap CLI (runs before .specify/ or .squad/ exist)
├── extensions/
│   ├── specrew-speckit/              # Spec Kit extension package
│   │   ├── commands/
│   │   ├── hooks/
│   │   ├── templates/
│   │   │   ├── downstream-constitution.md
│   │   │   ├── iteration-config.yml
│   │   │   └── role-assignments.yml
│   │   ├── scripts/
│   │   │   ├── init.ps1
│   │   │   ├── validate-versions.ps1
│   │   │   ├── brownfield-merge.ps1
│   │   │   ├── collision-detect.ps1
│   │   │   └── drift-diff.ps1
│   │   ├── config.yml
│   │   └── README.md
│   └── specrew-squad/                # Squad extension package
│       ├── skills/
│       │   ├── drift-check.md
│       │   ├── capacity-planning.md
│       │   ├── traceability-check.md
│       │   └── iteration-resume.md
│       ├── ceremonies/
│       │   ├── planning.md
│       │   └── review-demo.md
│       ├── directives/
│       │   ├── spec-authority.md
│       │   ├── traceability.md
│       │   └── drift-reporting.md
│       └── README.md
├── evaluation/                       # Evaluation harness
│   ├── reference-specs/
│   │   └── calculator-spec.md        # Simple reference spec for eval
│   ├── harness.ps1                   # Main evaluation runner
│   ├── scorers/
│   │   ├── process-scorer.ps1
│   │   └── outcome-scorer.ps1
│   └── README.md
├── tests/
│   ├── speckit-extension/
│   │   ├── test-init-greenfield.ps1
│   │   ├── test-init-brownfield.ps1
│   │   ├── test-collision-detect.ps1
│   │   └── test-drift-diff.ps1
│   ├── squad-extension/
│   │   ├── test-skills-load.ps1
│   │   ├── test-ceremonies-load.ps1
│   │   └── test-directives-load.ps1
│   ├── integration/
│   │   ├── test-bootstrap-to-iteration.ps1
│   │   └── test-drift-detect-and-resolve.ps1
│   └── e2e/
│       └── test-full-evaluation.ps1
├── docs/
│   ├── architecture.md
│   ├── getting-started.md
│   └── extension-authors.md
├── LICENSE
└── README.md
```

**Structure Decision**: Monorepo with `extensions/` containing both packages side by side. This keeps governance artifacts (`.specify/`, `specs/`) at the root for Specrew's own development while isolating distributable extension code under `extensions/`.

## 7. Storage Layout for Iteration Artifacts

All iteration artifacts are Markdown files, git-tracked, stored under the spec feature directory:

```text
specs/NNN-feature/
├── spec.md
├── plan.md
├── tasks.md
├── iterations/
│   ├── 001/
│   │   ├── plan.md               # Iteration plan: tasks, effort, owners, requirement links
│   │   ├── state.md              # Task execution state (for resume capability)
│   │   ├── drift-log.md          # Drift events detected during this iteration
│   │   ├── review.md             # Review/demo verdicts per task
│   │   └── retro.md              # Retrospective: accuracy, drift summary, actions
│   └── 002/
│       └── ...
└── evaluation/
    └── report.md                 # Evaluation harness output (process + outcome)
```

Each file follows a consistent Markdown structure for parseability by the drift-check and evaluation scripts while remaining human-readable.

## 8. Bootstrap and Dependency Strategy

### For Specrew's Own Development

1. Clone the private specrew repo
2. Prereqs: Python, uv, Git, Node.js, GitHub Copilot (Constitution V)
3. Run `uv sync` (for Spec Kit tooling) and `npm install` (if Squad SDK code exists)
4. Spec Kit is already initialized (`.specify/` exists at repo root)
5. Squad is configured via the specrew-squad extension under `extensions/`

### For Downstream Projects (`specrew init`)

`specrew init` is a standalone script (`scripts/specrew-init.ps1`) that runs before `.specify/` or `.squad/` exist:

```text
specrew init
  ├─ 1. Detect environment
  │   ├─ Is Spec Kit installed? → validate version >= 0.7.3
  │   ├─ Is Squad installed?    → validate version >= 0.9.1
  │   └─ Neither? Both? One?
  ├─ 2. Install missing dependencies at pinned versions
  ├─ 3. Initialize platforms (if not already done)
  │   ├─ Run `specify init` → creates .specify/
  │   └─ Run `squad init`   → creates .squad/
  ├─ 4. Install Specrew extensions
  │   ├─ Install specrew-speckit extension into .specify/extensions/
  │   └─ Install specrew-squad plugin via squad plugin install
  ├─ 5. Scaffold governance artifacts
  │   ├─ downstream-constitution.md (customizable, NOT Specrew's own)
  │   ├─ iteration-config.yml (effort unit, capacity, defaults)
  │   └─ role-assignments.yml (5 baseline roles + slots for project-specific)
  ├─ 6. Configure Squad team
  │   └─ Merge 5 baseline roles into existing .squad/ team (preserve existing)
  └─ 7. Report: what was installed, what was preserved, what needs user action
```

**Implementation boundary**: The Spec Kit extension activates only after `.specify/` exists. The Squad extension activates only after `.squad/` exists. `specrew init` is the orchestration layer above both.

## 9. GitHub Workflow for Specrew Development

*(Specrew project-development choice only. Not imposed on downstream projects.)*

- **Repository**: Private GitHub repo, public once testable by others
- **Issue tracking**: GitHub Issues with templates (bug, feature, task). Issues are created for visibility/tracking via `speckit.taskstoissues`, but local tasks.md remains the authoritative source of truth for implementation order and status.
- **Project board**: GitHub Projects V2 using Squad's documented default board layout (no custom columns)
- **Branching**: Feature branches per Spec Kit convention (`NNN-feature-name`)
- **PR model**: All changes via PR. CI must pass. Human review via standard GitHub PR review — no formal "Human Reviewer" crew role.
- **CI pipeline**: Lint (markdownlint, shellcheck) + unit tests + integration tests on every PR
- **Release**: Semantic versioning. Tag-triggered workflow packages both extensions.
- **Dogfooding**: Squad is used to develop Specrew from Iteration 0. The Specrew crew (5 baseline roles) operates on its own spec from the start.

## 10. Testing Strategy

### 10a. Spec Kit Extension Testing

- **Unit tests** (`tests/speckit-extension/`): PowerShell scripts that test each script in isolation
  - `test-init-greenfield.ps1`: Create temp dir, run init, verify all artifacts created
  - `test-init-brownfield.ps1`: Create temp dir with pre-existing Spec Kit config, run init, verify merge
  - `test-collision-detect.ps1`: Install mock conflicting extension, verify detection and error message
  - `test-drift-diff.ps1`: Provide a requirement and a contradicting output, verify drift is flagged

### 10b. Squad Extension Testing

- **Load tests** (`tests/squad-extension/`): Verify Squad can discover and load Specrew's skills/ceremonies/directives
  - `test-skills-load.ps1`: Copy extension into a test project's `.squad/`, run `squad status`, verify skills listed
  - `test-ceremonies-load.ps1`: Same approach for ceremonies
  - `test-directives-load.ps1`: Same approach for directives

### 10c. Local Validation

- Run `markdownlint` on all Markdown artifacts (skills, ceremonies, directives, templates)
- Run `shellcheck` on all PowerShell/shell scripts
- Run Spec Kit's own `check-prerequisites.ps1` to verify project integrity
- Manual: bootstrap in a test repo and run one iteration

### 10d. Integration Testing

- **Bootstrap-to-iteration** (`tests/integration/test-bootstrap-to-iteration.ps1`):
  - Create temp repo → `specrew init` → create a simple spec → start iteration → verify plan generated with traceability
- **Drift-detect-and-resolve** (`tests/integration/test-drift-detect-and-resolve.ps1`):
  - Start iteration → complete a task with contradicting output → verify drift detected → verify resolution flow

### 10e. End-to-End Scenario Testing

- **Full evaluation** (`tests/e2e/test-full-evaluation.ps1`):
  - Run the evaluation harness against the reference spec
  - Verify the report is produced with both process and outcome sections
  - Verify that introduced drift is detected and scored

## 11. Quality Model

### 11a. Process Quality

- Were all four iteration phases executed (planning, execution, review/demo, retro)?
- Did the Spec Steward review each task's output?
- Were drift events detected and recorded?
- Was the iteration plan approved before execution?

### 11b. Governance Quality

- Does every task trace to a spec requirement?
- Is the downstream constitution distinct from Specrew's own?
- Are role assignments documented and auditable?
- Are drift events resolved through explicit reconciliation (not silently)?

### 11c. Integration Quality

- Does `specrew init` work on greenfield and brownfield?
- Do both extensions load without errors alongside other extensions?
- Are collisions detected and reported?
- Does the brownfield merge preserve existing config?

### 11d. Delivery/Outcome Quality

- Do deliverables match their source requirements?
- Does the evaluation harness pass on a reference spec?
- Are all acceptance scenarios from the spec testable?

### 11e. Measurable Quality Gates

| Gate | Metric | Threshold |
| ---- | ------ | --------- |
| Traceability | % of tasks with requirement link | 100% |
| Drift detection | % of introduced drifts caught | >= 90% |
| Bootstrap time | User effort to bootstrap | < 10 min |
| Ceremony adherence | % of iterations with all 4 phases | 100% |
| Collision detection | Known collisions detected | 100% |
| Estimation accuracy | Actual vs. estimated effort variance | Tracked per retro, improving trend |
| Evaluation harness | Produces valid report | Pass/fail on reference spec |

## 12. Evaluation Harness Architecture

```text
evaluation/harness.ps1
  │
  ├─ 1. Setup
  │     Create temp directory
  │     Run specrew init (greenfield)
  │     Verify bootstrap artifacts
  │
  ├─ 2. Load reference spec
  │     Copy reference-specs/calculator-spec.md into specs/
  │     Verify spec has >= 3 requirements
  │
  ├─ 3. Run iteration 1
  │     Start planning ceremony → verify plan.md created
  │     Execute tasks → verify state.md updated per task
  │     Trigger drift (optional, for process scoring)
  │     Run review/demo → verify review.md with verdicts
  │     Run retro → verify retro.md
  │
  ├─ 4. Run iteration 2
  │     Same as above, with learning from retro applied
  │
  ├─ 5. Score
  │     scorers/process-scorer.ps1
  │       • Ceremony completion (4/4 phases per iteration)
  │       • Drift detection accuracy
  │       • Traceability coverage
  │       • Estimation accuracy delta
  │     scorers/outcome-scorer.ps1
  │       • Requirement coverage (deliverables vs. spec requirements)
  │       • Acceptance scenario pass rate
  │       • Artifact consistency (plan ↔ tasks ↔ output)
  │
  └─ 6. Report
        Generate evaluation/report.md
        Summary: PASS/FAIL with per-criterion scores
        Detail: per-iteration breakdown
```

## 13. Key Technical Risks and Mitigation

| Risk | Impact | Likelihood | Mitigation |
| ---- | ------ | ---------- | ---------- |
| Squad's post-task hook may not exist exactly as needed | Drift detection requires fallback to batch review | Medium | Validate hook surface during Iteration 0. If unavailable, implement drift check as a skill invoked by the Reviewer role at review time (degrade gracefully). |
| Spec Kit extension starter template may not support all needed hook types | Some governance hooks may not fire | Low | Audit available hook points during Iteration 0. Document workarounds for missing hooks. |
| Brownfield merge with existing Squad team config is complex | Edge cases may corrupt existing config | Medium | Treat merge as additive-only (never delete/modify existing). Full backup before merge. Dry-run mode for `specrew init`. |
| Both platforms are pre-1.0 and may introduce breaking changes | Specrew may break on upstream updates | High | Pin to minimum versions. Maintain compatibility test suite. Subscribe to upstream changelogs. Budget time for compatibility updates per release. |
| Evaluation harness depends on working end-to-end pipeline | Harness may be fragile if components are unstable | Medium | Build harness incrementally. Start with process scoring only (Markdown artifact checks). Add outcome scoring after iteration engine is stable. |
| Squad SDK-first mode is experimental | If needed, API may change | Low (deferred) | SDK deferred to post-MVP. If needed for hooks, contain to a single `squad.config.ts` file with minimal surface. |

## 14. Phased Delivery Plan

### Iteration 0 — Foundation

**Goal**: Repository setup, extension scaffolding, platform validation.

| Deliverable | FR | Description |
| ----------- | -- | ----------- |
| Monorepo scaffold | FR-001 | Create repo layout per Section 6. Set up `.github/`, `extensions/`, `tests/`, `evaluation/`, `docs/` |
| Spec Kit extension skeleton | FR-001, FR-013 | Use official Spec Kit extension starter template. Create `specrew-speckit/` with empty commands/, hooks/, templates/, scripts/ |
| Squad extension skeleton | FR-001, FR-013 | Create `specrew-squad/` with skills/, ceremonies/, directives/, README.md per Squad docs |
| Platform validation | — | Verify Spec Kit extension loads. Verify Squad extension loads. Document hook availability. |
| CI pipeline | — | GitHub Actions: markdownlint, shellcheck, test runner |
| GitHub Project board | — | Create V2 board using Squad's documented default layout |

### MVP (Iteration 1)

**Goal**: Bootstrap works, one iteration can run end-to-end, drift detection active.

| Deliverable | FR | Description |
| ----------- | -- | ----------- |
| `specrew init` (greenfield) | FR-002, FR-011 | Install deps, scaffold governance, configure Squad team with 5 roles |
| Downstream constitution template | FR-011 | Clearly labeled project-specific template, not a copy of Specrew's constitution |
| Iteration config + role assignments | FR-002, FR-004 | YAML templates for effort unit, capacity, role assignment |
| Planning ceremony | FR-005, FR-006 | Squad ceremony: generate iteration plan from spec requirements with task mapping |
| Spec authority directive | FR-003 | Squad directive enforcing spec-as-source-of-truth |
| Traceability directive + skill | FR-006, FR-018 | Every task records requirement link, owner, effort |
| Drift-check skill | FR-008 | Compare task output against source requirement, flag deviations |
| Post-task drift hook | FR-008 | Invoke drift-check after each task (or degrade to review-time if hook unavailable) |
| Review/Demo ceremony | FR-005, FR-009 | Per-task verdict gate (pass/needs-work/blocked) |
| Retrospective integration | FR-005, FR-010 | Use Squad's built-in retro with Specrew-specific prompts (accuracy, drift, actions) |
| Iteration artifact storage | — | Create `iterations/NNN/` structure with plan.md, drift-log.md, review.md, retro.md |
| Unit + integration tests | — | Tests per Section 10a–10d |

### Post-MVP (Iterations 2–3)

| Deliverable | FR | Iteration |
| ----------- | -- | --------- |
| `specrew init` (brownfield) | FR-020 | 2 |
| Configurable effort model | FR-007 | 2 |
| Capacity planning skill | FR-007, FR-017 | 2 |
| Overcommitment detection | FR-017 | 2 |
| Task state persistence + resume | FR-019 | 2 |
| Collision detector | FR-012 | 3 |
| Runtime portability audit | FR-014 | 3 |
| Evaluation harness | FR-015 | 3 |
| Upgrade preservation | FR-016 | 3 |
| Extension author documentation | — | 3 |

## Complexity Tracking

No constitution violations to justify. All components map cleanly to the two-layer architecture (Constitution II). No additional layers or abstractions beyond what the spec requires.
