# Squad Template Sources

## Overview

This directory contains Squad-native template sources that are deployed by `specrew init` to Squad runtime surfaces. These templates are the source of truth for Specrew's Squad integration.

## Architecture

Specrew v1 integrates with Squad using Squad's native runtime surfaces:

- **Skills**: Deployed to `.claude/skills/`, `.github/skills/`, and `.agents/skills/`; slash-command skills use per-skill subdirectories with content-identical `SKILL.md` files across all three roots
- **Ceremonies**: Only Specrew-defined ceremonies (`planning`, `review-demo`) are appended to `.squad/ceremonies.md`
- **Retrospective**: Uses Squad's built-in ceremony; `ceremonies\retro.md` is source guidance, not an appended runtime definition
- **Directives**: Merged into `.squad/agents/*/charter.md`

## Structure

```text
squad-templates/
├── agents/          # Baseline role charter templates
│   ├── spec-steward/
│   │   └── charter.md
│   ├── planner/
│   │   └── charter.md
│   ├── implementer/
│   │   └── charter.md
│   ├── reviewer/
│   │   └── charter.md
│   └── retro-facilitator/
│       └── charter.md
├── skills/          # SKILL.md templates for Specrew skills
│   ├── drift-check.md
│   ├── capacity-planning.md
│   ├── traceability-check.md
│   └── iteration-resume.md   # Resume skill deployed in Iteration 2
├── ceremonies/      # Runtime ceremony templates + built-in retro guidance
│   ├── planning.md
│   ├── review-demo.md
│   └── retro.md             # Guidance for Squad's built-in retrospective; not appended
└── directives/      # Directive templates for agent charters
    ├── spec-authority.md
    ├── traceability.md
    └── drift-reporting.md
```

## Deployment Model

When `specrew init` runs:

1. **Skills deployment**: Active Specrew skills are copied to the supported project skill roots (`.claude/skills/`, `.github/skills/`, `.agents/skills/`). The slash-command runtime skills (`specrew-where`, `specrew-status`, `specrew-update`, `specrew-team`, `specrew-review`, `specrew-help`, `specrew-version`) are written content-identically as `specrew-*/SKILL.md` in all three roots.
2. **Ceremonies deployment**: `ceremonies/planning.md` and `ceremonies/review-demo.md` are appended to `.squad/ceremonies.md`
3. **Built-in retro guidance**: `ceremonies/retro.md` informs Squad's built-in retrospective flow and is not appended as a separate Specrew ceremony
4. **Role deployment**: `agents/*/charter.md` templates seed the five baseline Squad roles in downstream `.squad/agents/`
5. **Directives deployment**: `directives/*.md` templates are merged into agent charters in `.squad/agents/*/charter.md`

All deployed Specrew skills use the `specrew-*` prefix to avoid namespace collisions. The active governance method now lives in these runtime-facing templates rather than in stub prose elsewhere.

## Enforcement Package

The minimum governance enforcement package is split across two layers:

1. **Runtime method** in these templates:
   - planning gate
   - drift discipline
   - review/demo verdict flow
   - retrospective guidance for Squad's built-in closure flow
2. **Artifact validator** in `..\scripts\validate-governance.ps1`:
   - checks lifecycle prerequisites
   - checks required artifacts by phase
   - fails invalid iteration state transitions

## Development Status

**Status**: Runtime templates are aligned to the authoritative iteration contract, including the deployed iteration-resume recovery skill

## References

- Contract: [squad-extension.md](../../../specs/001-specrew-product/contracts/squad-extension.md)
- Decision: `.squad/decisions/inbox/copilot-squad-native-surfaces-2026-04-18T00-24-57Z.md`
