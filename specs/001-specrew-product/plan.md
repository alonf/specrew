# Implementation Plan: Specrew — Spec-Governed AI Crew Operating Model

**Branch**: `001-specrew-product` | **Date**: 2026-04-17 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `specs/001-specrew-product/spec.md`

## Summary

Specrew bridges Spec Kit (specification/governance) and Squad (multi-agent runtime) into a unified spec-governed operating model for AI crews. The technical approach is to build a Spec Kit extension for governance lifecycle plus Squad-native configuration surfaces for crew execution, sharing a monorepo, with all iteration artifacts stored as Markdown in the spec feature directory. The downstream entrypoint after bootstrap becomes a new `specrew start` command that launches or hands off to Squad and has Squad drive the full Spec Kit lifecycle on the user's behalf, including intake for new work, continuation of active work, preservation of the existing Specrew-managed roster, brownfield repo discovery/spec seeding, an explicit `specify -> clarify decision -> plan` gate, real delegated-agent routing, and escalation-aware repair handling.

**Interaction model**: Guided wrapper over Spec Kit + Squad — users bootstrap with `specrew init`, manage supplemental members with `specrew team`, and start feature delivery with `specrew start`. The start flow hands work to Squad, which first detects whether a Specrew-managed roster already exists, preserves that roster for routing, inspects active artifacts to resume in-progress work when possible, and for new brownfield work mines repo evidence (code/manifests/docs/git history) to seed the starting spec and propose stack-aware specialists before broad intake. It then gathers only the remaining fix/feature intent, optionally materializes approved specialists, and drives `specify`, an explicit clarify-or-skip decision, `plan`, `tasks`, and `implement` while only escalating unresolved questions to the human developer. `new-feature` and `brownfield-new` runs default that gate to `speckit.clarify` unless Squad can record why the generated spec is already materially complete for planning. Copilot remains the mandatory host runtime in v1, while optional delegated agents such as Claude and Codex are consented separately and used for review-heavy or problem-solving-heavy lifecycle work according to role policy. To reduce Copilot CLI blocking during launch, Specrew starts Copilot from the target project directory, defaults automated handoff sessions to the current terminal plus non-blocking approvals, and allows an explicit detached-window option when the user wants a separate shell. When governance gates fail repeatedly, the repair workflow escalates both reasoning tier and ownership rather than repeating the same low-reasoning repair loop, and delegated runtime evidence records the requested/effective agent family plus concrete model used. Review and closure operate under a no-gap policy: known alignment gaps must be fixed in-iteration or explicitly deferred with human approval, and critical review emits a gap ledger plus spec-repair loop whenever ambiguities or missing decisions are discovered. For code-touching iterations, Specrew also generates reviewer-facing closeout artifacts (code map, dependency report, coverage evidence, conditional security surface, reviewer index) and emits a stable reviewer summary or digest so human reviewers can triage the iteration without reconstructing those signals from raw diffs.

## Technical Context

**Language/Version**: Markdown, YAML, PowerShell (Spec Kit extension assets).
**Primary Dependencies**: Spec Kit >= 0.8.4 (extension starter template), Squad >= 0.9.1 (extension structure: skills/ceremonies/directives)
**Storage**: Markdown files in spec feature directories (git-tracked, human-readable)
**Testing**: PowerShell-based validation scripts (Spec Kit side), Squad CLI for ceremony/skill testing. Custom evaluation harness for end-to-end.
**Target Platform**: GitHub Copilot via Squad (v1), with optional Copilot Agent HQ delegated agents for review roles. Architecture must remain future-runtime-portable.
**Project Type**: Spec Kit extension + Squad-native runtime-surface deployment in a monorepo
**Performance Goals**: Bootstrap in <10 min user effort. Iteration planning/review add <5 min overhead per iteration.
**Constraints**: Must integrate through supported extension surfaces only (Constitution III). No Copilot/VS Code direct hacks.
**Scale/Scope**: Single-project governance scope per bootstrap. Evaluation harness runs 2–3 iterations against a reference spec.

## Constitution Check (Pre-Design)

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- **Spec Authority Gate**: PASS — Plan scope maps directly to spec.md FR-001 through FR-054 and US-1 through US-9. No plan item exists without a spec reference.
- **Layering Gate**: PASS — Every component is classified below:
  - Standalone CLI: `specrew init`, `specrew start`, `specrew update` (orchestration/maintenance layer above both platforms)
  - Spec Kit layer: governance scaffold, drift detection, extension collision detection, downstream constitution generation
  - Squad layer: baseline crew roles, iteration ceremonies (Planning, Review/Demo), skills, directives, post-task drift hook
  - Shared: iteration artifact storage format (Markdown in spec dir), evaluation harness
- **Traceability Gate**: PASS — Phased delivery plan below maps each deliverable to FR/US references.
- **Ownership Gate**: PASS — Workstreams assigned (by implementation component; see spec.md TG-002 for owner-subsystem grouping):
  - Standalone CLI (`specrew init`, `specrew start`, `specrew update`): Specrew maintainers (FR-002, FR-020, FR-024, FR-035, FR-036, FR-037)
  - Spec Kit extension: Specrew maintainers (FR-001, FR-011, FR-013, FR-016)
  - Squad extension: Specrew maintainers (FR-004, FR-005, FR-006, FR-008, FR-009, FR-010)
  - Iteration engine (cross-cutting, implemented via Squad skills): Specrew maintainers (FR-007, FR-017, FR-018, FR-019)
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
- **Non-Interference Gate (X, XI)**: PASS — Bootstrap checks hook name + role name collisions at install time. Full 5-class collision detector planned (Iter 3, FR-012). Collision Record entity defined. Error contract specified.
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
| `specrew init` | Standalone CLI | Dependency detection/install, `specify init`/`squad init` orchestration, version validation, governance scaffold, brownfield merge, extension installation, Copilot / Agent HQ delegated-agent detection + consent | FR-002, FR-020, FR-022 |
| `specrew start` | Standalone CLI | Validate downstream bootstrap, detect/preserve the Specrew-managed roster, resolve intake/resume/new-feature context, run brownfield repo discovery/spec seeding when needed, launch or hand off to Squad, continue active work when present, surface stack-aware specialist recommendations, launch Copilot from the target project directory in the current terminal by default with non-blocking approvals, allow an explicit detached window option, drive the Spec Kit lifecycle through `specify`, an explicit clarify gate (`clarify` or recorded skip rationale), `plan`, `tasks`, and `implement`, and surface explicit user-approved commit offers at iteration boundaries | FR-024, FR-025, FR-028, FR-056 |
| `specrew update` | Standalone CLI | Report installed/latest versions, upgrade Specrew-managed runtime surfaces, scope platform updates, preserve downstream artifacts, and surface per-platform compatibility results | FR-035, FR-036, FR-037 |
| Governance Scaffold | Spec Kit ext | Generate downstream constitution placeholder, iteration config template, role assignment file, and downstream repo-hygiene defaults/documentation that separate tracked governance state from transient runtime artifacts | FR-011, FR-016, FR-055 |
| Drift Detection | Spec Kit ext + Squad ext | Spec Kit side: diff logic comparing task output to requirement. Squad side: post-task hook invoking drift check. | FR-003, FR-008 |
| Collision Detector | Spec Kit ext | Scan installed extensions for hook/artifact conflicts, report clearly | FR-012 |
| Baseline Crew | Squad ext | Define 5 roles as Squad team members. Project-specific roles added via Squad config. | FR-002, FR-004 |
| Delegated Agent Router | Squad ext | Routes roles and eligible repair/gate work to preferred delegated agents per `role-assignments.yml`, defaults review/problem-solving roles toward Claude/Codex when enabled, surfaces explicit fallback reasons when routing cannot be honored, and records runtime evidence for requested/effective agent family plus concrete model while keeping Copilot as the mandatory host workhorse. | FR-021, FR-026, FR-043 |
| Concurrency Analyzer | Standalone CLI + Squad ext | Analyzes plan dependency graphs, hotspot/code-ownership signals, and conflict risk to justify same-specialty pairing and record auditable concurrency rationale before parallel work is proposed | FR-038, FR-039, FR-040, FR-041 |
| Iteration Ceremonies | Squad ext | Planning, Review/Demo (Specrew-defined), Retrospective (Squad built-in) | FR-005, FR-009, FR-010 |
| Iteration Engine | Squad ext + skills | Task mapping to requirements, effort estimation, capacity checking, task state persistence, resume, repeated-gate failure tracking, reasoning-tier escalation with independent reassignment for repair loops, and no-gap closure checks with defer recording | FR-007, FR-017, FR-018, FR-019, FR-027, FR-044 |
| Critical Review Loop | Squad ext + review artifacts | Classifies hardened governance/lifecycle requirements as implemented / enforced / observable / documented, emits a gap ledger, and drives spec clarification plus artifact reconciliation when review finds unknowns or contradictions | FR-045 |
| Reviewer Visibility Subsystem | Standalone CLI + Spec Kit ext | Generates reviewer-facing closeout artifacts, executes configured test/coverage evidence at review time, records dependency/security evidence, renders interactive/non-interactive reviewer summaries, generates Mermaid-first reviewer diagrams when grounded, exposes local-open review flows, and preserves immutable iteration snapshots alongside optional mutable current-view surfaces | FR-046, FR-047, FR-048, FR-049, FR-050, FR-051, FR-052, FR-053, FR-054 |
| Evaluation Harness | Shared (scripts) | Bootstrap fresh project, run N iterations, produce process + outcome report | FR-015 |

## 3. What Belongs in the Spec Kit Extension

The Spec Kit extension (`specrew-speckit`) contains:

- **Hooks**: `before_plan` (validate spec has requirements), `after_tasks` (verify traceability), `before_implement` (verify iteration plan approved)
- **Templates**: Downstream constitution template, iteration config template, role assignment template
- **Config**: Specrew-specific settings in `.specify/extensions.yml` (version pins, feature flags)
- **Scripts**: Governance scaffold generation, version validation, brownfield merge, collision detection, drift diff logic

**Note**: `specrew init` is NOT part of this extension. It is a standalone CLI that runs before `.specify/` exists. The Spec Kit extension activates only after `.specify/` has been created (by `specify init`, called from `specrew init`).

## 4. Squad-Native Integration (Revised Architecture)

**Decision date**: 2026-04-18 (Iteration 0 spike results)  
**Spike evidence**: T-017, T-020 confirmed Squad does NOT support packaged `extensions/specrew-squad/` plugins or local path installation. Squad's architecture uses native runtime surfaces only.

Squad configuration is deployed to Squad's native runtime locations:

```text
.copilot/
  └─ skills/
      ├─ specrew-drift-check/
      │   └─ SKILL.md          # Check task output against source requirement
      ├─ specrew-capacity-planning/
      │   └─ SKILL.md          # Estimate effort, check capacity limits
      ├─ specrew-traceability-check/
      │   └─ SKILL.md          # Verify task-to-requirement links
      └─ specrew-iteration-resume/
          └─ SKILL.md          # Resume from last completed task

.squad/
  ├─ ceremonies.md             # Planning and Review/Demo ceremonies appended here
  ├─ team.md                   # 5 baseline roles merged here
  └─ agents/
      ├─ spec-steward/
      │   └─ charter.md        # Spec Authority directive embedded
      ├─ planner/
      │   └─ charter.md        # Traceability directive embedded
      ├─ implementer/
      │   └─ charter.md        # Drift Reporting directive embedded
      ├─ reviewer/
      │   └─ charter.md        # Drift Reporting directive embedded
      └─ retro-facilitator/
          └─ charter.md        # Process improvement directives embedded
```

Squad's built-in Retrospective ceremony is used directly — Specrew does not redefine it.

**Deployment mechanism**: `specrew init` copies skill files to `.copilot/skills/specrew-*/`, appends ceremony definitions to `.squad/ceremonies.md`, merges role definitions into `.squad/team.md`, and embeds directive text into agent charters in `.squad/agents/*/charter.md`. No `squad plugin install` command is used (marketplace-only, not applicable to bundled distribution).

**Source control**: The monorepo at `C:\Dev\Specrew` contains source templates for skills, ceremonies, and directives under `extensions/specrew-speckit/squad-templates/`. These are copied to downstream project locations by `specrew init`.

**Execution model**: The iteration lifecycle has four phases (per FR-005): planning, execution, review/demo, and retrospective. Of these, three are ceremonies (structured collaborative phases): Planning, Review/Demo, and Retrospective. Execution is a phase but not a ceremony — it is routed work dispatched to agents, tracked via task state and post-task hooks. The lifecycle flow is: ceremony (planning) → routed work (execution) → ceremony (review/demo) → ceremony (retrospective).

## 5. Squad SDK Code in v1

**Decision: Defer Squad SDK (`squad.config.ts`) to post-MVP.**

Rationale:
- v1 can be fully implemented using Squad's native Markdown surfaces (skills in `.copilot/skills/`, ceremonies in `.squad/ceremonies.md`, directives in agent charters).
- The post-task drift hook is the only feature that may require SDK-level code. During implementation, validate whether Squad's `HookPipeline` can be configured via extension Markdown or requires `squad.config.ts`. If SDK is needed for the hook only, add a minimal `squad.config.ts` with just the hook registration.
- Full SDK-first mode (`squad build`) is experimental per Squad docs and adds build complexity inappropriate for MVP.

**Post-MVP**: If iteration engine features (capacity tracking, resume state machine) benefit from programmatic control, migrate to SDK-defined team configuration.

**MVP mechanism**: All Squad integration in v1 uses Squad's native Markdown surfaces (skills in `.copilot/skills/specrew-*/`, ceremonies in `.squad/ceremonies.md`, directives in agent charters). No `squad.config.ts` file is created. The 5 baseline roles are defined as Markdown charter files and merged into `.squad/team.md` by `specrew init`. This is explicit role definition — Specrew does NOT use Squad's auto-generated team proposal (Squad's interactive roster flow proposes roles heuristically; Specrew requires deterministic, auditable role definitions per FR-004).

## 6. Repository Layout

```text
specrew/                              # Monorepo root
├── .github/
│   ├── ISSUE_TEMPLATE/
│   │   ├── bug.yml
│   │   ├── feature.yml
│   │   └── task.yml
│   ├── prompts/                      # Spec Kit prompt files (placement TBD: may move to .specify/templates/commands/ per Spec Kit convention — validated in compatibility spike item 11)
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
│   └── specrew-speckit/              # Spec Kit extension package
│       ├── extension.yml
│       ├── README.md
│       ├── hooks/                   # Lifecycle hooks
│       ├── templates/               # Governance artifact templates
│       │   ├── downstream-constitution.md
│       │   ├── iteration-config.yml
│       │   └── role-assignments.yml
│       ├── scripts/                 # Bootstrap + utility scripts
│       │   ├── scaffold-governance.ps1
│       │   ├── validate-versions.ps1
│       │   ├── brownfield-merge.ps1
│       │   ├── collision-detect.ps1
│       │   └── drift-diff.ps1
│       └── squad-templates/         # Source templates for Squad-native deployment
│           ├── skills/              # Skill SKILL.md templates
│           │   ├── drift-check.md
│           │   ├── capacity-planning.md
│           │   ├── traceability-check.md
│           │   └── iteration-resume.md
│           ├── ceremonies/          # Ceremony Markdown templates
│           │   ├── planning.md
│           │   └── review-demo.md
│           └── directives/          # Directive text templates
│               ├── spec-authority.md
│               ├── traceability.md
│               └── drift-reporting.md
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

Each file follows a consistent Markdown structure for parseability by the drift-check and evaluation scripts while remaining human-readable. Each artifact type includes a `**Schema**: v1` metadata line. Required section headings and field definitions are specified in [contracts/iteration-artifacts.md](contracts/iteration-artifacts.md) and [data-model.md](data-model.md).

## 8. Bootstrap and Dependency Strategy

### For Specrew's Own Development

1. Clone the private specrew repo
2. Prereqs: Python, uv, Git, Node.js, GitHub Copilot (Constitution V)
3. Run `uv sync` (for Spec Kit tooling) and `npm install` (if Squad SDK code exists)
4. Spec Kit is already initialized (`.specify/` exists at repo root)
5. Squad is configured via Squad-native deployment: skills in `.copilot/skills/specrew-*/`, ceremonies in `.squad/ceremonies.md`, directives in agent charters

### For Downstream Projects (`specrew init` + `specrew start`)

`specrew init` is a standalone script (`scripts/specrew-init.ps1`) that runs before `.specify/` or `.squad/` exist:

```text
specrew init
  ├─ 1. Detect environment
  │   ├─ Is Spec Kit installed? → validate version >= 0.8.4
  │   ├─ Is Squad installed?    → validate version >= 0.9.1
  │   └─ Neither? Both? One?
  ├─ 2. Install missing dependencies at pinned versions
  ├─ 3. Initialize platforms (if not already done)
  │   ├─ Greenfield: Run `specify init` → creates .specify/
  │   ├─ Brownfield: Skip `specify init` if .specify/ already exists.
  │   │   Specrew manages only its own files under .specify/extensions/specrew-speckit/.
  │   ├─ Greenfield: Run `squad init --non-interactive` (or equivalent documented
  │   │   non-interactive flag) → creates .squad/ with empty team.
  │   │   If no non-interactive flag exists, create .squad/ structure directly
  │   │   using documented file layout (validated in compatibility spike item 8).
  │   └─ Brownfield: Skip squad init if .squad/ already exists.
  ├─ 4. Install Specrew extensions
  │   ├─ Spec Kit side: Run `specify extension add specrew-speckit` (Spec Kit's
  │   │   documented extension installer — handles manifest registration and
  │   │   .specify/extensions.yml update). If `specify extension add` is unavailable
  │   │   in Spec Kit 0.8.4, fall back to direct file-copy into
  │   │   .specify/extensions/specrew-speckit/ + manual extensions.yml registration.
  │   │   (Validated in compatibility spike item 9.)
  │   └─ Squad side: Deploy Squad-native configuration:
  │       - Copy skill SKILL.md files to `.copilot/skills/specrew-*/`
  │       - Append ceremony definitions to `.squad/ceremonies.md`
  │       - Merge directive text into agent charters in `.squad/agents/*/charter.md`
  │       - Merge 5 baseline roles into `.squad/team.md`
  ├─ 5. Scaffold governance artifacts
  │   ├─ downstream-constitution.md (customizable, NOT Specrew's own)
  │   ├─ iteration-config.yml (effort unit, capacity, defaults)
  │   └─ role-assignments.yml (5 baseline roles + slots for project-specific)
  ├─ 6. Configure Squad team
  │   └─ Merge 5 baseline roles into existing .squad/ team (preserve existing).
  │       Roles are written as Markdown files per Squad's documented team format.
  │       Specrew does NOT invoke Squad's interactive roster proposal.
  └─ 7. Report: what was installed, what was preserved, what needs user action
```

After bootstrap, `specrew start` becomes the downstream orchestration command. It validates the bootstrapped surfaces, detects whether the repository already has a Specrew-managed roster, defaults to intake/resume mode when no feature request is supplied, resolves whether the user is resuming active work or beginning a new fix/feature, and then launches or hands off to Squad with an exact prompt telling Squad to preserve the existing roster, continue in-progress work when possible, gather only the missing intake details when necessary, ask about extra specialists only when the current roster appears insufficient, route eligible work to delegated agents when configured, run the full Spec Kit lifecycle in order, and escalate repeated repair failures by increasing reasoning tier and then owner independence. The launcher starts Copilot from the target project directory, defaults to `--allow-all` plus current-terminal handoff for automated sessions so trust/tool approval prompts are less likely to stall startup, and exposes a detached-window option for users who explicitly want a separate shell.

**Implementation boundary**: The Spec Kit extension activates only after `.specify/` exists. The Squad extension activates only after `.squad/` exists. `specrew init` and `specrew start` are the orchestration layer above both.

## 9. GitHub Workflow for Specrew Development

**Iteration Execution Model** (per .squad/protocol.md):

Specrew uses a local-first iteration model where Markdown artifacts in `specs/001-specrew-product/iterations/NNN/` are the authoritative source of truth. The iteration lifecycle follows four phases — Planning, Execution, Review/Demo, Retrospective — with all task state, status, and closure decisions recorded in local artifact files first.

- **Repository**: Private GitHub repo, public once testable by others
- **Task artifact authority**: All task planning, execution tracking, status updates, and closure decisions are recorded in local artifacts (plan.md, state.md, drift-log.md, review.md, retro.md) first. Local iteration artifacts are the authoritative source; GitHub artifacts are derived mirrors.
- **GitHub Issues and Projects (Specrew self-development)**: REQUIRED. GitHub Issues are created from plan tasks and synchronized to GitHub Projects V2 board. Squad is responsible for creating, populating, and maintaining the board as a derived operational mirror from local artifacts. The board follows Squad's documented default layout (no custom columns). Board status movements reflect actual task state in local artifacts, never precede it. See `docs/github-project.md` for operational procedures. Manual board management is fallback-only if automation fails; capability gaps or blockers must be recorded, not silently downgraded to manual management.
- **GitHub Projects (downstream projects)**: Downstream projects MAY opt in or out of GitHub Projects board usage. Downstream projects retain choice of authority model and may use Jira, Azure DevOps, GitHub Projects, or local task artifacts as appropriate.
- **Branching**: Specrew self-development keeps an iteration integration branch per Spec Kit convention (current MVP branch: `001-specrew-product`), then routes mirrored task issues through Squad issue branches named `squad/{issue-number}-{slug}`. When parallel issue work is active, each issue branch may use its own git worktree rooted from the current integration branch.
- **PR model**: All changes via PR. CI must pass. Human review uses the standard GitHub PR path, and per-task PRs target the active integration branch after local iteration artifacts are updated. GitHub review does not replace local artifact authority.
- **CI pipeline**: Lint (markdownlint, PSScriptAnalyzer) + unit tests + integration tests on every PR
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

- **Functional tests** (`tests/squad-extension/`): Verify Squad can discover, load, and execute Specrew's skills/ceremonies/directives
  - `test-skills-load.ps1`: Copy extension into a test project's `.squad/`, verify skill files exist at expected paths. Then invoke `drift-check` skill with mock input (a requirement + contradicting output) and verify the response contains a drift flag and explanation.
  - `test-ceremonies-load.ps1`: Verify ceremony files exist at expected paths. Then start the `planning` ceremony in a test project with a minimal spec, verify an iteration plan artifact is created with task-to-requirement links.
  - `test-directives-load.ps1`: Verify directive files exist at expected paths and contain expected content strings. Verify directives are referenced in agent context by checking `.squad/` team config lists them.

### 10c. Local Validation

- Run `markdownlint` on all Markdown artifacts (skills, ceremonies, directives, templates)
- Run `PSScriptAnalyzer` (`Invoke-ScriptAnalyzer`) on all PowerShell scripts
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
| Ceremony adherence | % of iterations with all 4 phases (3 ceremonies + execution) | 100% |
| Collision detection | Bootstrap: hook name + role name collisions detected. Full 5-class scan (+ command, artifact path, ceremony) in Iter 3 (FR-012) | 100% of checked classes |
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
| Brownfield merge with existing Squad team config is complex | Edge cases may corrupt existing config | Medium | Additive-only: `specrew init` never modifies or deletes existing files — it only creates new files and appends new roles. This eliminates config corruption risk because the original files are never touched. Resume-safe idempotency — partial run is valid, re-run completes remaining steps. Precondition: downstream repo SHOULD be git-tracked; document "commit before `specrew init`" as a best practice so users can `git checkout` if any additive write is unwanted. Dry-run mode previews all changes before writing. |
| Both platforms are pre-1.0 and may introduce breaking changes | Specrew may break on upstream updates | High | Pin to minimum versions. Maintain compatibility test suite. Subscribe to upstream changelogs. Budget time for compatibility updates per release. |
| Evaluation harness depends on working end-to-end pipeline | Harness may be fragile if components are unstable | Medium | Build harness incrementally. Start with process scoring only (Markdown artifact checks). Add outcome scoring after iteration engine is stable. |
| Squad SDK-first mode is experimental | If needed, API may change | Low (deferred) | SDK deferred to post-MVP. If needed for hooks, contain to a single `squad.config.ts` file with minimal surface. |

## 14. Phased Delivery Plan

### Iteration 0 — Foundation

**Goal**: Repository setup, extension scaffolding, platform validation.

| Deliverable | FR | Description |
| ----------- | -- | ----------- |
| Monorepo scaffold | FR-001 | Create repo layout per Section 6. Set up `.github/`, `extensions/`, `tests/`, `evaluation/`, `docs/` |
| Spec Kit extension skeleton | FR-001, FR-013 | Use official Spec Kit extension starter template. Create `specrew-speckit/` with hooks/, templates/, scripts/. No user-facing Specrew commands are defined for v1; if hook wiring requires internal manifest-backed command prompt files, those remain implementation detail only. |
| Squad template source | FR-001, FR-013 | Create `extensions/specrew-speckit/squad-templates/` with skills/, ceremonies/, directives/ Markdown sources |
| Platform validation | — | Verify Spec Kit extension loads. Verify Squad-native configuration can be deployed. Document hook availability. |
| Compatibility spike | — | Explicit validation checklist: (1) Spec Kit install/update to >= 0.8.4, (2) Squad install/update to >= 0.9.1, (3) Spec Kit hook availability audit (which `before_*`/`after_*` hooks fire), (4) Squad HookPipeline surface audit (PreToolUseHook/PostToolUseHook availability), (5) Squad extension discovery test (skills/ceremonies/directives found by `squad status`), (6) Local extension development test mechanics (edit → reload → verify cycle), (7) Squad non-interactive init: verify whether `squad init` supports a `--non-interactive` flag or equivalent; if not, document the `.squad/` file layout for direct creation, (8) Spec Kit extension install mechanism: verify whether `specify extension add` exists in 0.8.4; if not, document manual file-copy + `extensions.yml` registration as the sanctioned path, (9) Squad `plugin install` local path: verify `squad plugin install ./local-path` works (vs registry-only), (10) Spec Kit prompt file placement: verify whether prompt files belong in `.github/prompts/` (plan Section 6) or `.specify/templates/commands/` (Spec Kit convention) |
| CI pipeline | — | GitHub Actions: markdownlint, PSScriptAnalyzer, test runner |
| GitHub Project board | — | GitHub Projects V2 board created and synced from iteration artifacts via automation. Board follows Squad's documented default layout (no custom columns). See `docs/github-project.md` for operational procedures. Local iteration artifacts remain authoritative; GitHub Issues/board are derived mirrors. |

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
| Post-task drift hook | FR-008 | Invoke drift-check after each task. Fallback: drift-check skill runs within Review/Demo ceremony if post-task hook unavailable. Drift-check skill writes detected drift events to `iterations/NNN/drift-log.md`. |
| Review/Demo ceremony | FR-005, FR-009 | Per-task verdict gate (pass/needs-work/blocked) |
| Retrospective integration | FR-005, FR-010 | Use Squad's built-in retro with Specrew-specific prompts (accuracy, drift, actions) |
| Iteration artifact storage | — | Create `iterations/NNN/` structure with plan.md, drift-log.md, review.md, retro.md |
| Unit + integration tests | — | Tests per Section 10a–10d |

### Post-MVP (Iterations 2–11)

| Deliverable | FR | Iteration |
| ----------- | -- | --------- |
| `specrew init` (brownfield) | FR-020 | 2 |
| Configurable effort model | FR-007 | 2 |
| Capacity planning skill | FR-007, FR-017 | 2 |
| Overcommitment detection | FR-017 | 2 |
| Task state persistence + resume | FR-019 | 2 |
| Process-quality scorer | FR-015 | 2 |
| Collision detector | FR-012 | 3 |
| Runtime portability audit | FR-014 | 3 |
| Outcome scorer + full eval harness | FR-015 | 3 |
| Upgrade preservation | FR-016 | 3 |
| Extension author documentation | — | 3 |
| Update CLI/version info + scoped upgrades | FR-035, FR-036, FR-037 | 4 |
| Reviewer code map | FR-046 | 5 |
| Reviewer dependency report + external vulnerability scan surface | FR-047 | 5 |
| Coverage and test evidence artifact | FR-049 | 5 |
| Interactive reviewer summary + non-interactive digest | FR-050, FR-051 | 5 |
| Reviewer index artifact + `specrew review` replay command | FR-052 | 5 |
| Conditional security surface | FR-048 | 6 |
| Mermaid-first reviewer diagrams + local-open viewing | FR-053 | 6 |
| Immutable iteration snapshots + separate current-architecture surface | FR-054 | 6 |
| Delegated runtime evidence for requested/effective agent + model | FR-043 | 7 |
| No-gap iteration closure + explicit defer recording | FR-044 | 7 |
| Critical reviewer gap ledger + spec-repair reconciliation | FR-045 | 7 |
| Concurrency-aware sizing + paired specialist proposals | FR-038, FR-039 | 8 |
| Parallel ownership boundaries + escalation rules | FR-040, FR-041 | 8 |
| Multi-lane validation strategy (deterministic gate + artifact/contract lane + live smoke confidence lane) | FR-042 | 10 |
| Downstream repo hygiene contract (`.gitignore`, `docs/repo-hygiene.md`, local agent-history policy) | FR-055 | 11 |
| User-approved commit offers at iteration boundaries | FR-056 | 12 |

## Complexity Tracking

No constitution violations to justify. All components map cleanly to the two-layer architecture (Constitution II). No additional layers or abstractions beyond what the spec requires.
