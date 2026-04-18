# Squad Template Sources

## Overview

This directory contains Squad-native template sources that are deployed by `specrew init` to Squad runtime surfaces. These templates are the source of truth for Specrew's Squad integration.

## Architecture

Specrew v1 integrates with Squad using Squad's native runtime surfaces:

- **Skills**: Deployed to `.copilot/skills/specrew-*/` (per-skill subdirectory with `SKILL.md`)
- **Ceremonies**: Appended to `.squad/ceremonies.md`
- **Directives**: Merged into `.squad/agents/*/charter.md`

## Structure

```text
squad-templates/
├── skills/          # SKILL.md templates for Specrew skills
│   ├── drift-check.md
│   ├── capacity-planning.md
│   ├── traceability-check.md
│   └── iteration-resume.md
├── ceremonies/      # Ceremony definition templates
│   ├── planning.md
│   ├── review-demo.md
│   └── retro.md
└── directives/      # Directive templates for agent charters
    ├── spec-authority.md
    ├── traceability.md
    └── drift-reporting.md
```

## Deployment Model

When `specrew init` runs:

1. **Skills deployment**: Each `skills/*.md` template is copied to `.copilot/skills/specrew-{skill-name}/SKILL.md` in the target project
2. **Ceremonies deployment**: `ceremonies/*.md` templates are appended to `.squad/ceremonies.md`
3. **Directives deployment**: `directives/*.md` templates are merged into agent charters in `.squad/agents/*/charter.md`

All Specrew skills use the `specrew-*` prefix to avoid namespace collisions. The active governance method now lives in these runtime-facing templates rather than in stub prose elsewhere.

## Enforcement Package

The minimum governance enforcement package is split across two layers:

1. **Runtime method** in these templates:
   - planning gate
   - drift discipline
   - review/demo verdict flow
   - retrospective closure flow
2. **Artifact validator** in `..\scripts\validate-governance.ps1`:
   - checks lifecycle prerequisites
   - checks required artifacts by phase
   - fails invalid iteration state transitions

## Development Status

**Status**: Governance templates are active and aligned to the authoritative iteration contract

## References

- Contract: [squad-extension.md](../../../specs/001-specrew-product/contracts/squad-extension.md)
- Decision: `.squad/decisions/inbox/copilot-squad-native-surfaces-2026-04-18T00-24-57Z.md`
