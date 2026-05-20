# Contract: Frontmatter Validity

**Contract Version**: 1.0.0  
**Feature**: 024-slash-command-multi-host-correctness  
**Effective Boundary**: Plan-complete / pre-implementation

## Overview

This contract defines the YAML frontmatter structure, validation rules, and discovery metadata requirements for Specrew slash-command `SKILL.md` files, ensuring compatibility with Claude Code and GitHub Copilot CLI discovery mechanisms.

---

## YAML Frontmatter Structure

Every deployed `SKILL.md` file MUST begin with a YAML frontmatter block delimited by `---` markers:

```yaml
---
name: specrew-where
description: Show the current Specrew project status dashboard — the "where am I?" velocity view for the active feature and iteration.
---
```

**Required Fields**:

| Field | Type | Required | Validation | Description |
| --- | --- | --- | --- | --- |
| `name` | string | **Yes** | Must match parent directory name, lowercase-hyphen format | Canonical command name (e.g., `specrew-where`) |
| `description` | string | **Yes** | Must be non-empty, max 200 chars, single-line | Discovery description for host UI |

**Optional Fields**:

| Field | Type | Required | Validation | Description |
| --- | --- | --- | --- | --- |
| `allowed-tools` | array[string] | No | List of tool names if restrictions apply | Optional tool constraints (not used in v0.24.0) |

---

## Validation Rules

### 1. YAML Delimiter Validation

- Frontmatter MUST start with `---` on the first line of the file.
- Frontmatter MUST end with `---` on its own line.
- Content after the closing `---` is treated as the markdown body.

**Failure mode**: If delimiters are missing or malformed, the `SKILL.md` is considered invalid and the host may not discover the skill.

### 2. `name` Field Validation

**Required Fields**:

- MUST be present (missing `name` field is a validation error).
- MUST match the parent directory name exactly (case-sensitive).
  - Example: Directory `specrew-where/` requires `name: specrew-where`.
  - Counter-example: Directory `specrew-where/` with `name: specrew.where` is **invalid**.
- MUST use lowercase-hyphen format (no dots, no underscores, no camelCase).
- MUST match the pattern `^specrew-(where|status|update|team|review|help|version)$` for the seven existing commands.

**Failure mode**: If `name` does not match directory name, GitHub Copilot CLI may reject the skill or discovery may fail.

### 3. `description` Field Validation

**Rules**:

- MUST be present (missing `description` field is a validation error).
- MUST be non-empty (empty string or whitespace-only is invalid).
- SHOULD be a single-line summary suitable for discovery menu display (max 200 characters recommended).
- SHOULD be derived from the "Purpose" or "When to Use" sections of the Feature 021 skill templates.

**Failure mode**: If `description` is missing or empty, Claude Code discovery may show poor or missing metadata, and GitHub Copilot CLI may reject the skill.

### 4. YAML Syntax Validation

**Rules**:

- The frontmatter block MUST be valid YAML syntax (parseable by standard YAML 1.2 parsers).
- Common YAML pitfalls to avoid:
  - Unquoted strings containing colons (e.g., `description: Show: status` is invalid; use `description: "Show: status"`).
  - Inconsistent indentation in multi-line fields or arrays.
  - Missing space after colon in key-value pairs (e.g., `name:specrew-where` is invalid; use `name: specrew-where`).

**Failure mode**: If YAML syntax is invalid, the host may fail to parse the frontmatter and the skill will not be discoverable.

---

## Cross-Host Compatibility

### Claude Code Requirements

- **Minimum valid frontmatter**: `description` field recommended; `name` field optional but recommended for parity.
- **Discovery behavior**: Claude Code uses `description` for skill discovery menu; missing or empty `description` degrades discovery experience.

### GitHub Copilot CLI Requirements

- **Minimum valid frontmatter**: Both `name` and `description` fields mandatory.
- **Discovery behavior**: GitHub Copilot CLI validates `name` matches directory; missing or mismatched `name` causes discovery failure.

### Specrew v0.24.0 Standard

To ensure **cross-host parity**, Specrew adopts the **strictest superset**:

- Both `name` and `description` are **mandatory**.
- `name` must match directory name (GitHub Copilot CLI requirement).
- `description` must be non-empty (Claude Code + GitHub Copilot CLI shared requirement).

This ensures slash commands are discoverable in both hosts without host-specific template variations.

---

## Markdown Body Preservation

After the closing `---` delimiter, the `SKILL.md` file MUST retain the markdown body guidance from Feature 021:

**Required sections** (from Feature 021 templates):

- **Purpose**: High-level description of what the command does.
- **When to Use**: Scenarios and user prompts that should trigger this command.
- **Invocation**: Command syntax and argument examples.
- **Inputs**: Table of arguments, types, required/optional, descriptions.
- **Outputs**: Expected output format and content.
- **Failure Guidance**: Error-handling behavior and remediation guidance.

**Migration requirement**: All `/specrew.X` references in the markdown body MUST be replaced with `/specrew-X` hyphenated form.

---

## Testing Requirements

### Required Automated Tests

1. **Frontmatter Validity Test** (`SlashCommand.Frontmatter.Tests.ps1`):
   - For each deployed `SKILL.md` in all three target paths (`.claude/skills/`, `.github/skills/`, `.agents/skills/`):
     - Assert YAML frontmatter is present and delimited by `---`.
     - Assert `name` field is present and matches directory name.
     - Assert `description` field is present and non-empty.
     - Assert YAML syntax is valid (parseable by PowerShell `ConvertFrom-Yaml` or equivalent).

2. **Directory-Name Matching Test**:
   - For each command directory (e.g., `specrew-where/`):
     - Read `SKILL.md` frontmatter.
     - Assert `name` field equals the directory name (e.g., `name: specrew-where`).
     - If mismatch detected, fail test with diagnostic message.

3. **Hyphenated-Form Migration Test**:
   - For each deployed `SKILL.md` markdown body:
     - Assert no references to `/specrew.X` dot-notation remain.
     - Assert references to `/specrew-X` hyphenated notation are present where expected (e.g., "canonical command" sections).

---

## Example Valid Frontmatter

### Example 1: `specrew-where`

```yaml
---
name: specrew-where
description: Show the current Specrew project status dashboard — the "where am I?" velocity view for the active feature and iteration.
---

# specrew-where

**Type**: Operational Skill
**Schema**: v1
**Status**: Active
**Namespace**: `/specrew`
**Canonical command**: `/specrew-where`

## Purpose

Show the current Specrew project status dashboard — the "where am I?" velocity view for the active feature and iteration.

[... rest of markdown body ...]
```

### Example 2: `specrew-status` (alias)

```yaml
---
name: specrew-status
description: Alias for /specrew-where. Show the current Specrew project status dashboard.
---

# specrew-status

**Type**: Operational Skill
**Schema**: v1
**Status**: Active (alias)
**Namespace**: `/specrew`
**Canonical command**: `/specrew-status`
**Alias of**: `/specrew-where`

## Purpose

Alias for `/specrew-where`. Show the current Specrew project status dashboard. Produces the exact same semantic result as `/specrew-where`.

[... rest of markdown body ...]
```

---

## Example Invalid Frontmatter

### Invalid Example 1: Missing `name` field

```yaml
---
description: Show the current Specrew project status dashboard.
---
```

**Validation error**: GitHub Copilot CLI requires `name` field; skill will not be discoverable.

### Invalid Example 2: `name` does not match directory

Directory: `specrew-where/`

```yaml
---
name: specrew.where
description: Show the current Specrew project status dashboard.
---
```

**Validation error**: `name: specrew.where` does not match directory `specrew-where/`; GitHub Copilot CLI will reject or fail to discover the skill.

### Invalid Example 3: Empty `description`

```yaml
---
name: specrew-where
description:
---
```

**Validation error**: `description` is empty; Claude Code and GitHub Copilot CLI discovery will show poor or missing metadata.

### Invalid Example 4: Invalid YAML syntax

```yaml
---
name: specrew-where
description: Show: the current status
---
```

**Validation error**: Unquoted `Show: the current status` is ambiguous YAML (colon after `Show` looks like a nested key); should be `description: "Show: the current status"`.

---

## Failure Modes and Remediation

| Failure Mode | Detection | Remediation |
| --- | --- | --- |
| Missing frontmatter | Automated test fails; host discovery fails | Run `specrew update` to re-deploy skill templates with valid frontmatter |
| Missing `name` field | Automated test fails; GitHub Copilot CLI discovery fails | Run `specrew update` to re-deploy skill templates with valid frontmatter |
| `name` does not match directory | Automated test fails; GitHub Copilot CLI discovery fails | Report issue to Specrew maintainers (indicates template or deployment logic bug) |
| Missing or empty `description` | Automated test fails; Claude Code discovery shows poor metadata | Run `specrew update` to re-deploy skill templates with valid frontmatter |
| Invalid YAML syntax | Automated test fails; host parsing fails | Report issue to Specrew maintainers (indicates template syntax bug) |
| Surviving `/specrew.X` references in body | Automated test fails; body guidance uses deprecated dot-notation | Run `specrew update` to re-deploy skill templates with hyphenated form |

---

## Open Questions and Deferrals

- **Optional `allowed-tools` field**: Should v0.24.0 include `allowed-tools` constraints for any of the seven commands? → Deferred; v0.24.0 omits `allowed-tools` from all templates unless specific tool restrictions are identified during implementation.
- **Multi-line `description` support**: Should `description` support multi-line YAML for longer summaries? → Deferred; v0.24.0 uses single-line `description` only (max 200 chars recommended).
- **Custom Specrew-specific fields**: Should frontmatter include Specrew-specific metadata (e.g., `specrew-version`, `specrew-lifecycle-stage`)? → Deferred to post-v0.24.0 feature when use case is proven.

---

## Version and Governance

**Contract Version**: 1.0.0  
**Effective Date**: 2026-05-19 (Feature 024 plan-complete)  
**Amendment Policy**: Changes to this contract require explicit feature scope, spec approval, and cross-reference from tasks.md and implementation plan.  
**Supersedes**: Feature 021 skill templates (no frontmatter, dot-notation `/specrew.X` references in body).
