# Contract: Canonical Iteration State Schema

**Date**: 2026-05-12
**Feature**: `specs/013-validator-hardening`
**Spec**: [../spec.md](../spec.md)
**Plan**: [../plan.md](../plan.md)
**Requirement**: FR-001, FR-009

## Purpose

This contract defines the canonical iteration `state.md` metadata schema. The validator rule introduced by FR-001 uses this document as its normative reference. Future rule changes must update both this contract and the corresponding validator logic.

## Canonical Fields

Every newly created or materially updated iteration `state.md` after feature 013 rollout MUST contain all eight fields below in the canonical `**Field Name**:` format on their own lines.

| Position | Field Name | Canonical Pattern | Allowed Values |
| --- | --- | --- | --- |
| — | `Schema` | `**Schema**:` | Any version/identifier string; pending placeholder allowed |
| — | `Last Completed Task` | `**Last Completed Task**:` | Task ID, label, or `(none)`; pending placeholder allowed |
| — | `Tasks Remaining` | `**Tasks Remaining**:` | Count, list, or `(none)`; pending placeholder allowed |
| — | `In Progress` | `**In Progress**:` | Task ID, label, or `(none)`; pending placeholder allowed |
| — | `Baseline Ref` | `**Baseline Ref**:` | Git SHA, tag, or pending placeholder |
| — | `Updated` | `**Updated**:` | ISO date or pending placeholder |
| — | `Current Phase` | `**Current Phase**:` | Lifecycle phase string; pending placeholder allowed |
| — | `Iteration Status` | `**Iteration Status**:` | Free-form text; inspected for closure-oriented keywords such as `closed` or `closeout complete` |

## Pattern Definition

The canonical field pattern is:

```
**<FieldName>**: <value>
```

- `**` opening bold markers directly before the field name.
- `**` closing bold markers directly after the field name.
- `:` immediately after the closing `**`.
- Optional whitespace before the value.
- The field must appear at the start of a line (no leading indentation).

### Regex Reference

```regex
^\*\*<FieldName>\*\*:\s*(.+?)?\s*$
```

This matches the canonical form and is consistent with the existing `Get-MarkdownMetadataValue` helper in `shared-governance.ps1`.

## Enforcement Rules

1. **Presence check**: All eight canonical fields must be detected in the file.
2. **Pattern check**: Each field must match the canonical `**FieldName**:` pattern; alternative patterns such as `Overall Status:` (no bold), `# FieldName` (heading), or `- FieldName:` (list item) are non-canonical and must trigger a FAIL.
3. **Pending values allowed**: A field value that is blank, a dash, or an explicit pending marker is valid as long as the canonical field name is present with the correct pattern.
4. **Extra sections allowed**: Narrative sections, headings, or additional non-canonical fields beyond the eight required fields must not trigger false positive failures.
5. **Grandfathering**: Iterations that existed before feature 013 rollout are grandfathered and are not subject to this enforcement unless they are materially reopened or rewritten.

## FAIL Output Contract

When the canonical schema check fails, the validator MUST emit a `Structured Validator FAIL Output` (see `data-model.md`) with:

- `file_path`: relative path to the `state.md` file
- `line_number`: line number of the first non-canonical or missing field, when detectable
- `category`: `canonical-schema`
- `message`: names the missing or non-canonical field(s)
- `remediation_hint`: instructs the author to add or correct the canonical `**FieldName**:` pattern

## Change Control

Changes to this contract require:

1. An updated `validate-governance.ps1` rule implementation.
2. Updated fixture coverage in `tests/integration/validator-hardening-iteration1.ps1`.
3. A revision note in this file naming the change, the requirement, and the date.

## Revision History

| Date | Change | Requirement |
| --- | --- | --- |
| 2026-05-12 | Initial contract created | FR-001, FR-009 |
