# Implementation Plan: Human Architecture Intent Checkpoint

**Branch**: `008-quality-profile-foundation` | **Date**: 2026-05-09 | **Spec**: `specs/006-human-architecture-checkpoint/spec.md`
**Input**: Feature specification from `specs/006-human-architecture-checkpoint/spec.md`

**Note**: This template is filled in by the `/speckit.plan` command. See `.specify/templates/plan-template.md` for the execution workflow.

## Summary

Add a human-controlled implementation intent checkpoint inside `/speckit.plan`, after clarification and before the plan body is finalized. The checkpoint must use Specrew's existing hook, agent-prompt, and governance surfaces to present an implementation intent brief, interrupt the human only for expensive or risky decisions, record the accepted direction in `plan.md`, and keep the existing pre-implementation approval gate intact.

## Technical Context

**Language/Version**: PowerShell 7.x scripts plus Markdown/YAML/JSON workflow assets  
**Primary Dependencies**: Spec Kit `0.8.4`, Squad `0.9.1`, GitHub Copilot CLI prompt/agent surfaces, Specrew extension manifests and scripts  
**Storage**: Markdown/YAML governance artifacts under `specs\`, `.specify\`, `.specrew\`, `extensions\specrew-speckit\`, and `.github\agents\`  
**Testing**: Markdown lint in CI, PSScriptAnalyzer for any PowerShell helpers, focused PowerShell integration scripts under `tests\integration\`, optional operator smoke validation via `tests\manual\copilot-squad-smoke.ps1`  
**Target Platform**: Local Specrew + Spec Kit workflow driven from GitHub Copilot CLI in PowerShell  
**Project Type**: Workflow/governance extension update for Specrew and Spec Kit  
**Performance Goals**: One bounded pre-plan interaction per non-trivial feature; no extra blocking for routine reversible decisions  
**Constraints**: Must run as an automatic `/speckit.plan` pre-step, must not invent non-existent runtime stacks, must persist accepted direction in `plan.md`, and must preserve the existing pre-implementation approval gate  
**Scale/Scope**: One implementation intent brief and one Architecture Intent Review record per feature plan; source and installed extension copies must remain synchronized

## Phase 1 Quality Planning

**Phase Scope**: `phase-1-first-slice` — automatic pre-plan checkpoint, plan recording surface, and lifecycle prompt alignment  
**Inferred Quality Profile**: `quality-profile.custom-composition.v1`  
**Selected preset ref or explicit custom composition**: Custom composition for PowerShell + Markdown/YAML governance assets, prompt-routing surfaces, and deterministic integration scripts. No application-runtime preset fits this repository because the feature lands in workflow artifacts rather than a service or package.  
**Bounded custom composition**: Validate markdown prompt/template truthfulness, source/installed extension drift, and deterministic PowerShell integration coverage. Leave deeper implementation-time enforcement automation explicit as deferred.

### Stack Surfaces in Scope

| Stack Surface | Path Globs / Evidence | Recognized Stack | Why It Matters |
| --- | --- | --- | --- |
| Pre-plan hook prompts | `extensions\specrew-speckit\commands\speckit.specrew-speckit.before-plan.md`, `.specify\extensions\specrew-speckit\commands\speckit.specrew-speckit.before-plan.md`, `.specify\extensions.yml` | Specrew Spec Kit hook command | This is the real insertion point for the checkpoint inside `/speckit.plan`. |
| Planning prompt + template | `.github\agents\speckit.plan.agent.md`, `.specify\templates\plan-template.md` | Copilot/Spec Kit planning surfaces | The planning agent must wait for the checkpoint result and the template must expose the recorded direction. |
| Runtime routing and handoff prompts | `.github\agents\squad.agent.md`, `.specrew\last-start-prompt.md`, `extensions\specrew-speckit\squad-templates\coordinator\specrew-governance.md`, `.specify\extensions\specrew-speckit\squad-templates\coordinator\specrew-governance.md` | Squad-native lifecycle governance | These files tell routed sessions where the checkpoint sits and how conflicts must escalate back to the human. |
| Pre-implementation approval gate | `extensions\specrew-speckit\commands\speckit.specrew-speckit.before-implement.md`, `.specify\extensions\specrew-speckit\commands\speckit.specrew-speckit.before-implement.md` | Specrew execution-readiness gate | Feature 006 must add an earlier checkpoint without removing or weakening the existing approval gate. |
| Validation and workflow docs | `README.md`, `docs\user-guide.md`, `tests\integration\start-command.ps1`, `tests\integration\validation-contract-lane.ps1`, `tests\manual\copilot-squad-smoke.ps1` | Documentation + deterministic integration coverage | TG-002 requires the checkpoint to be visible in workflow docs and exercised by the existing validation lanes. |

### Risk Dimensions

| Risk Dimension | Status (`required` / `not-applicable`) | Rationale |
| --- | --- | --- |
| Workflow integration | required | The checkpoint must execute inside the existing `before_plan` flow without becoming a separate manual command. |
| Human decision boundary | required | The feature fails if it asks on every local detail or skips major decisions that are expensive to reverse. |
| Artifact traceability | required | The approved direction has to stay visible in `plan.md` and downstream approval prompts, not only in chat. |
| Prompt/source drift | required | Specrew keeps source templates, installed extension copies, and runtime prompts; these can silently diverge if not updated together. |
| Runtime package/build concerns | not-applicable | Feature 006 does not add an application runtime, package release, or service deployment surface. |

### Quality Tool Bundle

| Area | Selection | Evidence / Notes |
| --- | --- | --- |
| Bundle ID | `specrew-workflow-governance-checkpoint` | Custom bundle for workflow prompts, templates, and validation scripts |
| Mechanical Checks | Markdown structure review of changed prompts/templates; targeted search for fictional `src/` / `.py` surfaces; governance artifact inspection | Ensures the repaired planning slice stays on real repo surfaces |
| Ecosystem Tools | CI markdownlint, PSScriptAnalyzer for any `.ps1` changes, `tests\integration\human-architecture-checkpoint.ps1` (planned), `tests\integration\validation-contract-lane.ps1`, optional `tests\manual\copilot-squad-smoke.ps1` | Matches the repository's actual verification surfaces |

### Required Quality Gates

| Required Quality Gate | Category | Evidence Source | Phase 1 Status |
| --- | --- | --- | --- |
| Automatic checkpoint execution is visible before planning | workflow | `extensions\specrew-speckit\commands\speckit.specrew-speckit.before-plan.md`, `.github\agents\speckit.plan.agent.md`, `tests\integration\human-architecture-checkpoint.ps1` | planned |
| `plan.md` records accepted direction and constraints | artifact-inspection | `.specify\templates\plan-template.md` plus generated `specs\<feature>\plan.md` output | planned |
| Existing pre-implementation approval gate is preserved | workflow | `extensions\specrew-speckit\commands\speckit.specrew-speckit.before-implement.md` and paired installed copy | planned |
| Runtime prompts and docs show the same lifecycle order | artifact-inspection | `.specrew\last-start-prompt.md`, `.github\agents\squad.agent.md`, coordinator templates, `README.md`, `docs\user-guide.md` | planned |
| Focused integration lane covers checkpoint scenarios | tooling | `tests\integration\human-architecture-checkpoint.ps1`, `tests\integration\validation-contract-lane.ps1` | planned |

### Not-Applicable Dimensions and Rationale

| Dimension / Gate | Why Not Applicable in This Feature | Follow-up |
| --- | --- | --- |
| Database or persistence migration review | The feature records architecture intent in markdown governance artifacts; it does not introduce a repository data store. | None |
| Browser/UI compatibility testing | There is no product UI surface in scope; interaction happens through Copilot/Squad prompt flows and markdown artifacts. | None |
| Load/performance benchmarking | The slice adds a human approval checkpoint, not a throughput-sensitive runtime path. | Revisit only if the prompt flow becomes materially slow in practice. |

### Explicit Phase 2+ Deferrals

- Automated implementation-time conflict detection beyond prompt/governance instructions is deferred.
- Automatic synchronization into `.squad\decisions.md` beyond explicit references from `plan.md` is deferred.
- Longitudinal measurement for SC-003 (reduced late-stage rewrites) is deferred until multiple features use the checkpoint.
- Any new helper script should be added only under `extensions\specrew-speckit\scripts\` and the installed mirror, not under fictional application source trees.

## Phase 2 Hardening and Specialist Review Planning

**Phase 2 Slice Scope**: `future hardening slice` — checkpoint-to-implementation enforcement and conflict escalation proof  
**Hardening Gate Artifact**: `specs/006-human-architecture-checkpoint/quality/hardening-gate.md` (future slice if approved)  
**Known-Traps Corpus Location**: `.specrew/quality/known-traps.md`  
**Trap Reapplication Artifact**: `none yet`

### Hardening Focus Areas

| Focus Area | Why It Matters in This Slice | Planned Artifact / Evidence | Status (`required` / `deferred` / `not-applicable`) |
| --- | --- | --- | --- |
| Checkpoint-to-plan traceability | The accepted direction must survive from the pre-plan conversation into the generated plan artifact. | `quality/hardening-gate.md` traceability section plus generated `plan.md` examples | required |
| Plan-to-before-implement handoff | The later approval gate must still run and must see the approved direction. | `before-implement` prompt review and integration evidence | required |
| Human-unavailable and vague-spec handling | The workflow must fail closed when approval is missing or the spec is too vague to produce a responsible brief. | Hardening artifact plus checkpoint integration scenarios | required |
| Dedicated bug-hunter / strongest-class routing execution | Those review workflows are not being implemented by this feature slice. | Deferred until a later quality-governance slice | deferred |

### Lens Activation Plan

| Lens / Checklist Ref | Activation (`required` / `optional` / `not-applicable`) | Why Activated or Omitted | Planned Evidence / Artifact Path |
| --- | --- | --- | --- |
| workflow-integration-checklist | required | The feature changes lifecycle ordering inside `/speckit.plan`. | `specs/006-human-architecture-checkpoint/quality/lenses/workflow-integration.md` |
| governance-artifact-consistency | required | Prompt text, plan template, and approval gate must all say the same thing. | `specs/006-human-architecture-checkpoint/quality/lenses/artifact-consistency.md` |
| runtime-package-hardening | not-applicable | No service/package runtime surface is introduced. | none |

### Routing Policy

| Lens Scope | Requested Reasoning / Review Class | Effective Class (when run) | Override / Approval Record | Notes |
| --- | --- | --- | --- | --- |
| Workflow and artifact consistency review | governance-expert-class | TBD at execution time | none yet | Review should focus on lifecycle truthfulness across prompt and template surfaces. |
| Human decision boundary review | reasoning-expert-class | TBD at execution time | none yet | The reviewer must verify minimal interruption rather than generic over-questioning. |

### Explicit Later Deferrals

- Runtime-only proof that implementation agents stop on post-plan conflicts remains deferred until the implementation slice exists.
- Dedicated known-traps seeding for checkpoint-specific failures remains deferred.
- Strongest-class execution evidence remains deferred until those routing controls are implemented for this slice.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

### Pre-Research Evaluation

- **Spec Authority Gate** ✓ PASS: The scope maps directly to `spec.md`: an automatic checkpoint inside `/speckit.plan`, recorded human direction in `plan.md`, minimal interruption, and preserved pre-implementation approval.
- **Layering Gate** ✓ PASS: Changes are limited to Specrew/Spec Kit workflow surfaces (commands, templates, prompt overlays, tests, and docs). No fictional application layer is introduced.
- **Traceability Gate** ✓ PASS: Planned slices map cleanly to the three P1 user stories and TG-002 through TG-004 by way of hook prompts, plan template updates, routing guidance, and integration coverage.
- **Ownership Gate** ✓ PASS: Planner-owned work covers prompt/template surfaces, Reviewer-owned work covers integration validation, and Spec Steward accountability remains the human approval point inside the checkpoint.
- **Capacity Gate** ✓ PASS: The feature adds one bounded human interaction during planning and a small set of prompt/template/test edits in the repository's existing workflow stack.
- **Drift/Reconciliation Gate** ✓ PASS: Drift signals are concrete: missing `Architecture Intent Review` section, lifecycle prompts that skip the checkpoint, or a pre-implementation summary that ignores the accepted direction.
- **Verification Gate** ✓ PASS: Validation is rooted in real repository checks — markdown lint, integration scripts, and manual smoke validation where live human interaction must be observed.

### Post-Phase-1 Re-Evaluation (PLANNED)

After design completion, re-check that:

- `/speckit.plan` guidance consistently places the checkpoint before plan generation.
- `plan.md` exposes an `Architecture Intent Review` section with required fields.
- `before-implement` still blocks implementation until the later approval gate is satisfied.
- No task or validation slice points to fictional `src/`, Python, or TypeScript runtime modules.

## Project Structure

### Documentation (this feature)

```text
specs/006-human-architecture-checkpoint/
├── spec.md
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
│   ├── brief-schema.md
│   └── hook-api-contract.md
├── tasks.md
└── quality/
    └── hardening-gate.md              # Future slice only if Phase 2 is approved
```

### Repository Surfaces in Scope

```text
.specify/
├── extensions.yml
├── templates/
│   └── plan-template.md
└── extensions/
    └── specrew-speckit/
        ├── commands/
        │   ├── speckit.specrew-speckit.before-plan.md
        │   └── speckit.specrew-speckit.before-implement.md
        └── squad-templates/
            └── coordinator/
                └── specrew-governance.md

extensions/
└── specrew-speckit/
    ├── commands/
    │   ├── speckit.specrew-speckit.before-plan.md
    │   └── speckit.specrew-speckit.before-implement.md
    └── squad-templates/
        └── coordinator/
            └── specrew-governance.md

.github/agents/
├── speckit.plan.agent.md
└── squad.agent.md

.specrew/
└── last-start-prompt.md

README.md
docs/user-guide.md

tests/integration/
├── start-command.ps1
├── validation-contract-lane.ps1
└── human-architecture-checkpoint.ps1   # planned new focused integration test
```

**Structure Decision**: Implement Feature 006 entirely within existing Specrew workflow assets: hook command markdown, plan template markdown, Squad/Copilot prompt overlays, documentation, and PowerShell integration tests. Do not introduce fictional `src\...` application modules; if deterministic helper logic becomes necessary, keep it under `extensions\specrew-speckit\scripts\` and mirror the installed `.specify\extensions\specrew-speckit\scripts\` copy.

## Complexity Tracking

> **No constitution violations identified.**
