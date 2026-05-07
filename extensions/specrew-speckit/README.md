# Specrew Spec Kit Extension

## Overview

This is the **Spec Kit extension** component of Specrew. It provides governance artifacts, templates, validation scripts, and Squad-native template sources that enforce spec authority and traceability within the Spec Kit lifecycle.

## Structure

```text
commands/          # Hook command definitions consumed by Spec Kit
hooks/             # Lifecycle hooks for Spec Kit workflows
templates/         # Governance artifact templates (constitution, iteration config, quality assets, etc.)
scripts/           # Validation and scaffolding PowerShell scripts
squad-templates/   # Squad-native template sources (skills, ceremonies, directives, role charters)
extension.yml      # Extension configuration
```

Quality-governance source assets for the stack-aware quality-bar foundation live under `templates/quality/`, including versioned lens checklist sources, stack preset sources, and authoring guidance for reviewed lens upgrades.

## Squad Integration Architecture

Specrew v1 integrates with Squad using **Squad's native runtime surfaces**, not a separate packaged plugin:

- **Skills**: Templates in `squad-templates/skills/` are deployed to `.copilot/skills/specrew-*/SKILL.md` in downstream projects
- **Ceremonies**: Planning and Review/Demo templates in `squad-templates/ceremonies/` are appended to `.squad/ceremonies.md`
- **Role charters**: Templates in `squad-templates/agents/` seed the five baseline Specrew roles under `.squad/agents/`
- **Directives**: Templates in `squad-templates/directives/` are merged into `.squad/agents/*/charter.md`
- **Coordinator prompt overlay**: `deploy-squad-runtime.ps1` appends Specrew governance rules into `.github/agents/squad.agent.md` so Squad routes work through the canonical Spec-Kit + Specrew artifact flow instead of treating governance as advisory

The `specrew init` command handles this deployment. All Specrew skills use the `specrew-*` prefix for namespace safety.

## Integration

This extension integrates with Spec Kit >= 0.8.4 using documented extension surfaces:

- **Commands**: Hook-targeted command prompts registered through the extension manifest
- **Hooks**: Lifecycle hooks that fire during specification workflows
- **Templates**: Markdown templates for governance artifacts
- **Scripts**: PowerShell automation for validation and scaffolding
- **Squad Templates**: Source templates for Squad-native surfaces

## Governance Enforcement

This extension now ships a practical governance validator:

```powershell
pwsh -File .\extensions\specrew-speckit\scripts\validate-governance.ps1 -ProjectPath .
```

The validator scans iteration artifacts and fails when lifecycle prerequisites are broken, such as:

- missing `state.md`, `drift-log.md`, `review.md`, or `retro.md` for the current phase
- non-terminal tasks entering review or retro
- missing review verdicts or required retro sections

The downstream Squad coordinator is also patched to enforce the same lifecycle contract, so it must create or use the canonical Spec-Kit and Specrew artifacts before it can honestly claim end-to-end process compliance.

The operating method for planning, drift detection, review/demo, and retrospective now lives in `squad-templates\` so downstream deployment surfaces receive the real workflow instead of placeholders.

## Quality Governance Assets

Phase 1 stack-aware quality assets are sourced from `templates/quality/`:

- `templates/quality/lenses/` stores versioned, Markdown-table lens checklist sources.
- `templates/quality/presets/` stores versioned stack preset sources.
- `templates/quality/README.md` defines the reviewed lens-upgrade workflow and authoring rules so checklist changes stay explicit, auditable, and independently versioned.

These files are intended to be scaffolded into downstream `.specrew/` quality directories rather than edited ad hoc in generated copies first.

This extension also ships focused scaffolding helpers:

- `scaffold-governance.ps1` creates downstream `.specrew\` governance artifacts
- `scaffold-iteration-plan.ps1` creates a planning-stub `iterations\NNN\plan.md` from a spec and requirement scope
- `scaffold-iteration-artifacts.ps1` creates `iterations\NNN\state.md` and `iterations\NNN\drift-log.md` without overwriting existing iteration work
- `scaffold-review-artifact.ps1` creates `iterations\NNN\review.md` from the iteration plan for the Review/Demo ceremony
- `scaffold-reviewer-artifacts.ps1` creates `code-map.md`, `dependency-report.md`, `coverage-evidence.md`, optional `security-surface.md`, `review-diagrams.md`, `reviewer-index.md`, and the feature-level `current-architecture.md` reviewer companion surface
- `scaffold-retro-artifact.ps1` creates `iterations\NNN\retro.md` from the iteration plan, review artifact, and drift log for Squad's built-in Retrospective ceremony
- `resume-iteration.ps1` analyzes `state.md` plus the task table in `plan.md`, then records a resume report and next suggested task for FR-019 recovery flows

## Development Status

**Status**: Extension scaffold plus minimum governance enforcement package

## Extension Configuration

The extension is configured via `extension.yml`.

## References

- Contract: [squad-extension.md](../../specs/001-specrew-product/contracts/squad-extension.md)
- Contract: [specrew-init.md](../../specs/001-specrew-product/contracts/specrew-init.md)
- Decision: `.squad/decisions/inbox/copilot-squad-native-surfaces-2026-04-18T00-24-57Z.md`

## License

TBD
