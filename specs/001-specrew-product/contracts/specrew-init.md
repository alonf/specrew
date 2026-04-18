# Contract: specrew init — Standalone Bootstrap CLI

**Date**: 2026-04-17
**Spec**: [spec.md](../spec.md)
**Requirements**: FR-002, FR-011, FR-013, FR-020

**Architectural position**: Standalone script (`scripts/specrew-init.ps1`) at monorepo root. NOT a Spec Kit extension command. Must work before `.specify/` or `.squad/` exist.

## Platform Initialization Algorithm

```text
Step 3a — Spec Kit:
  IF .specify/ does NOT exist:
    Run `specify init` → creates .specify/
  ELSE:
    Do NOT re-run `specify init` (would overwrite constitution, templates).
    Specrew manages only its own extension files under .specify/extensions/specrew-speckit/.

Step 3b — Squad:
  IF .squad/ does NOT exist:
    Run `squad init --non-interactive` (if flag exists — validated by compatibility spike item 8).
    IF --non-interactive is unavailable:
      Create .squad/ directory structure directly using documented file layout.
    Specrew then writes its 5 baseline roles into .squad/ team files.
  ELSE:
    Do NOT re-run `squad init` (interactive flow would propose unwanted roster changes).
    Specrew merges baseline roles additively into existing .squad/ team files.

Step 4a — Spec Kit Extension Install:
  Run `specify extension add specrew-speckit` (if available — validated by compatibility spike item 9).
  IF `specify extension add` is unavailable in Spec Kit 0.7.3:
    Copy extension files into .specify/extensions/specrew-speckit/.
    Register in .specify/extensions.yml manually.

Step 4b — Squad Extension Install:
  Run `squad plugin install ./extensions/specrew-squad` (local path — validated by spike item 10).
```

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
| Spec Kit init | `.specify/` | Created by `specify init` only if .specify/ does not already exist |
| Squad init | `.squad/` | Created by `squad init` (idempotent, no flags needed) only if .squad/ does not already exist |
| Specrew config | `.specrew/config.yml` | Bootstrap configuration |
| Downstream constitution | `.specrew/constitution.md` | Project-specific template (NOT Specrew's own) |
| Iteration config | `.specrew/iteration-config.yml` | Default effort + capacity settings |
| Role assignments | `.specrew/role-assignments.yml` | 5 baseline roles |
| Squad team update | `.squad/team.md` | 5 baseline roles merged into team |
| Squad skills | `.copilot/skills/specrew-*/` | Specrew skills deployed to Squad-native skill directories |
| Squad ceremonies | `.squad/ceremonies.md` | Planning and Review/Demo ceremonies appended |
| Squad directives | `.squad/agents/*/charter.md` | Specrew directives merged into agent charters |
| Spec Kit extension | `.specify/extensions/specrew-speckit/` | Specrew Spec Kit extension installed |
| Report | stdout | Summary of what was created |

### Outputs (Brownfield)

Same as greenfield, except:
- Existing `.specify/`, `.squad/` files are preserved (never overwritten)
- Baseline roles are merged (additive only)
- Version conflicts are reported and block execution
- Conflicting role names prompt the user

**Protected Paths** (never overwritten or deleted by `specrew init`):
- `.specify/memory/constitution.md` — User's project constitution
- `.specify/templates/` — All contents (user-customized templates)
- `.specify/extensions.yml` — Existing extension registrations
- `.squad/` — All state files (team config, memory, plugins)
- `specs/` — All existing spec directories and contents
- `.specrew/` — Any user customization files

### Exit Codes

| Code | Meaning |
| ---- | ------- |
| 0 | Success |
| 1 | Version incompatibility detected |
| 2 | Extension collision detected |
| 3 | User cancelled |
| 4 | Prerequisite missing (Python, Node.js, Git, etc.) |

### Collision Detection Scope (Bootstrap)

`specrew init` checks **2 of 5** collision classes at bootstrap time:

| Class | Checked at Bootstrap | Rationale |
| ----- | -------------------- | --------- |
| Hook name | Yes | Duplicate hook registrations cause immediate runtime errors |
| Role name | Yes | Duplicate role names corrupt team config |
| Command name | No — Iter 3 (FR-012) | No Specrew commands in v1; low immediate risk |
| Artifact path | No — Iter 3 (FR-012) | Conflicts only manifest at artifact write time during iterations |
| Ceremony name | No — Iter 3 (FR-012) | Conflicts only manifest when ceremony is invoked |

The full 5-class collision detector is delivered as part of FR-012 in Iteration 3.

### Error Messages

- Version conflict: `"Specrew requires Spec Kit >= 0.7.3 but found 0.6.2. Run 'pip install --upgrade speckit>=0.7.3' to upgrade."`
- Collision: `"Extension conflict: hook 'before_plan' is claimed by both 'specrew-speckit' and '{other}'. Resolution options: [1] Disable {other}'s hook [2] Cancel Specrew install"`
- Role name conflict: `"Role 'Reviewer' already exists in .squad/. Options: [1] Adopt existing config for Specrew's Reviewer role [2] Rename to 'Specrew Reviewer'"`

### Failure Recovery

**Strategy**: Resume-safe idempotency (no rollback).

All `specrew init` writes are additive-only — existing files are never overwritten or deleted. If the script fails at any step:

1. Already-created artifacts remain valid and usable
2. The workspace is in a consistent but incomplete state
3. Re-running `specrew init` detects completed steps (via file/directory existence checks) and skips them
4. Only remaining uncompleted steps execute

No backup directory (`.specrew-backup/`) or transaction log is needed. The `--dry-run` flag can be used to preview what a re-run would do before executing.
