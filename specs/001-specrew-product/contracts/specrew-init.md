# Contract: specrew init — Standalone Bootstrap CLI

**Date**: 2026-04-17
**Spec**: [spec.md](../spec.md)
**Requirements**: FR-002, FR-011, FR-013, FR-020

**Architectural position**: Standalone script (`scripts/specrew-init.ps1`) at monorepo root. NOT a Spec Kit extension command. Must work before `.specify/` or `.squad/` exist. Calls `specify init` and `squad init` as sub-steps.

## Command Interface

```
specrew init [options]

Options:
  --dry-run         Show what would be created/modified without making changes
  --force           Skip confirmation prompts (still respects collision safety)
  --speckit-version Minimum Spec Kit version (default: 0.7.3)
  --squad-version   Minimum Squad version (default: 0.9.1)
  --help            Show usage
```

## Behavior Contract

### Inputs

| Input | Source | Required |
| ----- | ------ | -------- |
| Current directory | File system | Yes |
| Existing `.specify/` config | File system | No (greenfield) |
| Existing `.squad/` config | File system | No (greenfield) |

### Outputs (Greenfield)

| Output | Location | Description |
| ------ | -------- | ----------- |
| Spec Kit installation | System | Spec Kit >= 0.7.3 installed if missing |
| Squad installation | System | Squad >= 0.9.1 installed if missing |
| Spec Kit init | `.specify/` | Created by `specify init` (if not present) |
| Squad init | `.squad/` | Created by `squad init` (if not present) |
| Specrew config | `.specrew/config.yml` | Bootstrap configuration |
| Downstream constitution | `.specrew/constitution.md` | Project-specific template (NOT Specrew's own) |
| Iteration config | `.specrew/iteration-config.yml` | Default effort + capacity settings |
| Role assignments | `.specrew/role-assignments.yml` | 5 baseline roles |
| Squad team update | `.squad/` | 5 baseline roles merged into team |
| Spec Kit extension | `.specify/extensions/specrew-speckit/` | Specrew Spec Kit extension installed |
| Squad plugin | `.squad/` | Specrew Squad plugin installed via `squad plugin install` |
| Report | stdout | Summary of what was created |

### Outputs (Brownfield)

Same as greenfield, except:
- Existing `.specify/`, `.squad/` files are preserved (never overwritten)
- Baseline roles are merged (additive only)
- Version conflicts are reported and block execution
- Conflicting role names prompt the user

### Exit Codes

| Code | Meaning |
| ---- | ------- |
| 0 | Success |
| 1 | Version incompatibility detected |
| 2 | Extension collision detected |
| 3 | User cancelled |
| 4 | Prerequisite missing (Python, Node.js, Git, etc.) |

### Error Messages

- Version conflict: `"Specrew requires Spec Kit >= 0.7.3 but found 0.6.2. Run 'pip install --upgrade speckit>=0.7.3' to upgrade."`
- Collision: `"Extension conflict: hook 'before_plan' is claimed by both 'specrew-speckit' and '{other}'. Resolution options: [1] Disable {other}'s hook [2] Cancel Specrew install"`
- Role name conflict: `"Role 'Reviewer' already exists in .squad/. Options: [1] Adopt existing config for Specrew's Reviewer role [2] Rename to 'Specrew Reviewer'"`
