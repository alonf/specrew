# Specrew Spec Kit Extension

## Overview

This is the **Spec Kit extension** component of Specrew. It provides governance artifacts, templates, validation scripts, and Squad-native template sources that enforce spec authority and traceability within the Spec Kit lifecycle.

## Structure

```text
commands/          # Hook command definitions consumed by Spec Kit
hooks/             # Lifecycle hooks for Spec Kit workflows
templates/         # Governance artifact templates (constitution, iteration config, etc.)
scripts/           # Validation and scaffolding PowerShell scripts
squad-templates/   # Squad-native template sources (skills, ceremonies, directives, role charters)
extension.yml      # Extension configuration
```

## Squad Integration Architecture

Specrew v1 integrates with Squad using **Squad's native runtime surfaces**, not a separate packaged plugin:

- **Skills**: Templates in `squad-templates/skills/` are deployed to `.copilot/skills/specrew-*/SKILL.md` in downstream projects
- **Ceremonies**: Planning and Review/Demo templates in `squad-templates/ceremonies/` are appended to `.squad/ceremonies.md`
- **Role charters**: Templates in `squad-templates/agents/` seed the five baseline Specrew roles under `.squad/agents/`
- **Directives**: Templates in `squad-templates/directives/` are merged into `.squad/agents/*/charter.md`

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

The operating method for planning, drift detection, review/demo, and retrospective now lives in `squad-templates\` so downstream deployment surfaces receive the real workflow instead of placeholders.

This extension also ships focused scaffolding helpers:

- `scaffold-governance.ps1` creates downstream `.specrew\` governance artifacts
- `scaffold-iteration-plan.ps1` creates a planning-stub `iterations\NNN\plan.md` from a spec and requirement scope
- `scaffold-iteration-artifacts.ps1` creates `iterations\NNN\state.md` and `iterations\NNN\drift-log.md` without overwriting existing iteration work
- `scaffold-review-artifact.ps1` creates `iterations\NNN\review.md` from the iteration plan for the Review/Demo ceremony
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
