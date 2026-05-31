# Research: Discoverable Spec Kit Surfaces

## Decision 1: Treat the repo as a PowerShell/Markdown/YAML governance product

- **Decision**: Plan this feature against the repository's PowerShell scripts, Spec Kit extension assets, Markdown prompts/docs, and PowerShell validation lanes rather than against the placeholder `package.json` dependency list.
- **Rationale**: `README.md`, `docs/user-guide.md`, `.specify/extensions.yml`, the extension scripts, and `tests/README.md` all describe Specrew as a PowerShell-driven governance workflow layered over Spec Kit. Those sources are the operative product surfaces for this feature.
- **Alternatives considered**:
  - Treat the repo as a Node-first application because `package.json` exists — rejected because the active architecture and lifecycle behavior are governed by PowerShell, Markdown, YAML, and Spec Kit extension assets.

## Decision 2: Preserve clarified lifecycle placement as authoritative

- **Decision**: Keep `/speckit.checklist` before-plan, keep `/speckit.analyze` before-implement only after `/speckit.tasks` has produced a complete `tasks.md`, and keep `/speckit.taskstoissues` deferred unless a later slice explicitly re-scopes it.
- **Rationale**: The feature spec, requirements checklist, and current agent/prompt assets already establish these placements. This feature is about surfacing and explaining those commands, not reopening lifecycle placement.
- **Alternatives considered**:
  - Surface `/speckit.analyze` during plan or tasks — rejected because its own prompt requires `spec.md`, `plan.md`, and `tasks.md`.
  - Activate `/speckit.taskstoissues` as part of the default workflow — rejected because the approved scope explicitly defers it.

## Decision 3: Use markdownlint as the active stack-specific lint/analyzer for this slice

- **Decision**: Use `npx --yes markdownlint-cli` as the active stack-specific lint/analyzer command for this feature's discovery/docs surfaces; keep `Invoke-ScriptAnalyzer` conditional only if implementation later expands into `.ps1` runtime or test-script edits.
- **Rationale**: The active slice primarily changes Markdown and prompt/agent text surfaces. The repository already documents markdown-lint discipline at lifecycle boundaries, while `tests/README.md` positions `Invoke-ScriptAnalyzer` as the optional PowerShell script check rather than the primary lint for doc-first changes.
- **Alternatives considered**:
  - Use only PowerShell analysis — rejected because the approved surface is mostly Markdown-driven.
  - Introduce a Node- or YAML-specific analyzer as the primary lint — rejected because current repo standards do not show that as the authoritative path for this slice.

## Decision 4: Require executable discovery/lifecycle evidence beyond mechanical gates

- **Decision**: In addition to baseline mechanical gates and checklist references, require stack-tooling evidence from the existing PowerShell integration lanes that verify discovery, routing, coexistence, lifecycle-boundary sync, and contract parity.
- **Rationale**: First-class command surfacing is a product behavior claim, not just a documentation claim. `tests/integration/slash-command-discovery.tests.ps1`, `slash-command-routing.tests.ps1`, `slash-command-coexistence.tests.ps1`, `lifecycle-boundary-sync.tests.ps1`, and `validation-contract-lane.ps1` are the repository-standard evidence sources that can prove the updated guidance remains truthful.
- **Alternatives considered**:
  - Rely only on mechanical gates and checklist references — rejected because that would not prove lifecycle/discovery behavior.
  - Add a new YAML-only evidence lane — rejected because no repo-standard YAML lane is currently required for this slice.

## Decision 5: Use the repo-standard iteration planning scaffold now, but defer execution artifacts

- **Decision**: Create the canonical `iterations/001/plan.md` scaffold at the planning boundary and reference the future hardening artifacts under `iterations/001/quality/`, while deferring execution-only scaffolds (`state.md`, `drift-log.md`, review/retro artifacts, hardening execution evidence) until later approved boundaries.
- **Rationale**: `docs/user-guide.md` explicitly calls `scaffold-iteration-plan.ps1` the helpful planning scaffold, while `scaffold-iteration-artifacts.ps1` belongs to execution. This preserves lifecycle discipline without crossing into tasks or implementation.
- **Alternatives considered**:
  - Skip iteration scaffolding entirely until after tasks — rejected because the repository already defines a canonical planning scaffold.
  - Create full execution artifacts now — rejected because the user asked to stop at the plan boundary.
