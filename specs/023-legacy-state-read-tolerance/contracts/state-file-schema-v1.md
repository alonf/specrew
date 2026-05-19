# State File Schema v1 Contract

**Feature**: Legacy-State Read-Tolerance + Schema Migration Discipline  
**Branch**: `023-legacy-state-read-tolerance`  
**Schema Version**: v1  
**Effective Date**: 2026-05-19 (planned)  
**Supersedes**: Implicit v0 (pre-schema-versioning state files)

---

## Purpose

This contract defines the structural and behavioral requirements for Specrew state files using schema version 1 (`schema: v1`). All state files written by Specrew 0.23.0+ MUST conform to this contract unless explicitly documented otherwise.

---

## Schema Version Marker

### Required Top-Level Field

All v1 state files MUST include a top-level `schema` field:

```json
{
  "schema": "v1",
  ...other fields
}
```

```yaml
schema: v1
...other fields
```

**Field Specification**:

- **Name**: `schema` (lowercase, singular)
- **Type**: String
- **Position**: Top-level (not nested)
- **Value**: `"v1"` (string literal, not integer)
- **Required**: Yes for all newly written files
- **Absence Interpretation**: If `schema` field is missing, readers MUST interpret the file as schema v0 (legacy implicit schema)

---

## Reader Contract

### Hashtable-Based Parsing (FR-004)

All state readers MUST use hashtable-based data structures when parsing JSON and YAML files:

**PowerShell JSON Parsing**:

```powershell
$state = Get-Content -LiteralPath $statePath -Raw -Encoding UTF8 | 
         ConvertFrom-Json -AsHashtable -Depth 12
```

**Rationale**: Hashtable indexers return `$null` for missing keys; PSCustomObject property access throws `PropertyNotFoundException` under `Set-StrictMode -Version Latest`.

### Missing Field Tolerance (FR-005)

All state readers MUST NOT throw exceptions when accessing optional fields that don't exist:

**Correct** (hashtable indexer):

```powershell
$sessionState = $state['session_state']  # Returns $null if missing, no throw
if ($sessionState) {
    # Use session state
}
```

**Incorrect** (PSCustomObject property access):

```powershell
$sessionState = $state.session_state  # Throws under StrictMode if missing
```

### Schema Version Dispatch (FR-006)

When reader behavior differs between v0 and v1+, readers MUST provide schema-version-aware dispatch logic:

```powershell
$schema = $state['schema']
if (-not $schema) {
    # Legacy v0 file (implicit schema)
    Write-Debug "schema-implied-v0 for $statePath"
    $featurePath = $state['feature_directory']  # v0 field name
}
else {
    # Explicit schema version
    $featurePath = $state['feature_path']  # v1 field name (if renamed)
}
```

**Requirements**:

- Include comments identifying which schema version each code path handles
- Log "schema-implied-v0" at debug level when reading files without `schema` field
- Fail fast with clear error message if schema version is unsupported (e.g., `"v2"` when only v1 is implemented)

---

## Writer Contract

### Schema Marker Inclusion (FR-001)

All state writers MUST add an explicit `schema: v1` field when writing state files:

**JSON**:

```powershell
$state = @{
    schema = 'v1'
    session_state = @{ ... }
    feature_path = '/path/to/feature'
}
$state | ConvertTo-Json -Depth 12 | Set-Content -LiteralPath $statePath -Encoding UTF8
```

**YAML** (manual construction):

```powershell
$yamlContent = @"
schema: v1
team_id: $teamId
capacity_unit: $capacityUnit
"@
$yamlContent | Set-Content -LiteralPath $statePath -Encoding UTF8
```

**Frontmatter** (Markdown files):

```powershell
$frontmatter = @"
---
schema: v1
feature: $featureNumber
iteration: $iterationNumber
---
"@
```

### Extension Manifest Exception (FR-003)

For `.specify/extensions/specrew-speckit/extension.yml`, the `version:` field refers to **extension content version**, NOT schema version. A separate `schema:` field MUST be added:

```yaml
extension:
  id: specrew-speckit
  name: "Specrew Spec Kit Extension"
  version: "0.22.0"        # Extension content version
  schema: "v1"             # Schema version (NEW field)
```

### Silent Upgrade Policy

When a state reader encounters a v0 file (missing `schema` field):

- Reader MUST apply v0-compatible logic
- Next write by any state writer MUST silently upgrade to `schema: v1`
- For user-visible config files (e.g., `.specrew/config.yml`), writer MAY log a one-time notice: "Upgraded config.yml to schema v1"
- For opaque caches (e.g., `.specrew/version-check-cache.json`), upgrade silently with no log

---

## State File Catalog

### Files Requiring Schema v1 Markers (FR-001)

| File Path | Format | Content Purpose | Writer | Reader(s) |
|-----------|--------|-----------------|--------|-----------|
| `.specrew/config.yml` | YAML | User/team configuration | `specrew-init` | `specrew-start`, `version-check`, `shared-governance` |
| `.specrew/start-context.json` | JSON | Session resume state | `specrew-start` | `specrew-start` |
| `.specrew/last-validator-summary.json` | JSON | Validator run results | Validator framework | `coordinator-resume` |
| `.specify/feature.json` | JSON | Feature metadata | Feature scaffold scripts | `specrew-start`, `worktree-awareness`, `scaffold-feature-closeout-dashboard`, `common.ps1` |
| `.specify/extensions/specrew-speckit/extension.yml` | YAML | Extension manifest | Extension installer | `validate-governance` |
| `.squad/identity/now.md` | Markdown (YAML frontmatter) | Squad identity/session state | `sync-boundary-state` | `worktree-awareness`, `sync-boundary-state` |

### Files With Existing Schema Markers (Reaffirm, FR-001)

| File Path | Format | Schema Marker Source | Notes |
|-----------|--------|---------------------|-------|
| `.specrew/version-check-cache.json` | JSON | F-020 (Proposal 035) | Already includes `schema: v1`; reaffirm in this feature's implementation |
| `tasks-progress.yml` | YAML | F-020 (Proposal 035) | Already includes `schema: v1`; reaffirm in this feature's implementation |

---

## Field Conventions

### Optional vs Required Fields

**In v1 schema** (additive changes only):

- **All fields are optional** unless explicitly documented as required for a specific state file type
- Readers MUST provide safe defaults for missing optional fields:
  - String fields: `''` (empty string) or `$null`
  - Array fields: `@()` (empty array)
  - Boolean fields: `$false` or `$null`
  - Object fields: `@{}` (empty hashtable) or `$null`

**Required fields** (enforced by readers):

- `.specify/feature.json`: `feature_directory` (throws if missing per `scaffold-feature-closeout-dashboard.ps1:107-114`)
- Other required fields to be documented per state file type in future iterations

### Field Naming Conventions

- Use `snake_case` for field names (consistent with existing Specrew state files)
- Avoid abbreviations unless widely understood (e.g., `id` is acceptable, `cfg` is not)
- Prefix boolean fields with `is_` or `has_` when ambiguous (e.g., `is_worktree_mode` not `worktree`)

---

## Error Handling

### Parse Errors

When a state file contains invalid JSON/YAML syntax:

- Reader MUST throw a clear error message identifying the file path and parse failure
- Error MUST NOT affect other state files (isolation)
- Example: `"Failed to parse .specrew/config.yml: invalid YAML syntax at line 23"`

### Missing Files

When a state file does not exist:

- Reader MUST return `$null` or a safe default object (not throw)
- Caller MUST handle `$null` return gracefully
- Example: `Get-SpecrewStartContext` returns `$null` if `.specrew/start-context.json` missing

### Unsupported Schema Versions

When a state reader encounters a schema version it doesn't support (e.g., `"v2"` when only v1 is implemented):

- Reader MUST throw with clear upgrade path
- Error message format: `"State file {path} requires schema version {version}. This version of Specrew supports up to v1. Upgrade to Specrew X.Y.Z or higher."`

### Downgrade Scenarios

When an older Specrew version reads a file written by a newer version:

- If schema version is unrecognized: Same error as "Unsupported Schema Versions" above
- If schema version is v1 but file includes new optional fields unknown to older reader: Older reader MUST ignore unknown fields gracefully (forward compatibility)

---

## Testing Requirements

### Legacy Fixture Corpus (FR-007, FR-008)

All state readers MUST pass tests against legacy fixtures representing Specrew versions 0.18.0-0.22.0:

**Fixture Location**: `file:///C:/Dev/Specrew/tests/fixtures/legacy-versions/`

**Pass Criteria**:

- No exceptions thrown
- No `$null` reference errors (StrictMode compatibility)
- Return values structurally consistent with function contracts

**Coverage**:

- Each state reader function tested against each fixture version
- Negative tests for parse errors, missing files, unsupported schema versions

### CI Integration (FR-014)

Legacy fixture tests MUST run on:

- Windows (GitHub Actions: `windows-latest`)
- Linux (GitHub Actions: `ubuntu-latest`)

**Rationale**: Cross-platform bugs were a motivating factor (2026-05-19 WSL trial surfaced six bugs).

---

## Backward Compatibility Guarantees

### v0 → v1 Migration Path

- **Readers**: MUST interpret missing `schema` field as v0
- **Writers**: MUST silently add `schema: v1` on next write
- **No breaking changes**: v1 schema includes all v0 fields plus new optional fields
- **Field additions**: New optional fields in v1 MUST NOT be required (v0 readers can ignore them)

### Forward Compatibility (v1 → v2, future)

- **Breaking changes allowed**: Future v2 schema MAY remove, rename, or change type of fields
- **Explicit migration**: v1 readers encountering v2 files MUST fail with clear error message
- **Migration command**: Future proposal MAY add `specrew migrate-state` command for user-initiated migration

---

## Cross-References

- **Source Proposal**: file:///C:/Dev/Specrew/proposals/059-legacy-state-read-tolerance.md
- **Related Features**:
  - F-020 (Proposal 035 Session-State Durability): Introduced `schema: v1` for `version-check-cache.json` and `tasks-progress.yml`
  - F-013 (Proposal 004 Validator Hardening): Validator framework extended with reader tolerance rule (gap #11)
- **Constitution Principles**:
  - Principle I (Spec Is Authoritative): State files MUST NOT silently override spec decisions
  - Principle XX (Drift Detection Is First-Class): Schema drift MUST be detected and escalated

---

## Compliance Checklist

**For State File Writers**:

- [ ] Add `schema: v1` field to all newly written state files
- [ ] Distinguish extension content version from schema version (FR-003)
- [ ] Log one-time upgrade notice for user-visible config files (optional)

**For State File Readers**:

- [ ] Use `ConvertFrom-Json -AsHashtable` for JSON files
- [ ] Use manual YAML parsing with hashtable output (or equivalent hashtable-based YAML parser)
- [ ] Access all optional fields via hashtable indexers (not PSCustomObject property access)
- [ ] Provide schema-version-aware dispatch logic (if reader behavior differs between v0 and v1)
- [ ] Log "schema-implied-v0" at debug level when reading files without `schema` field
- [ ] Throw clear error for unsupported schema versions

**For CI Pipeline**:

- [ ] Run legacy fixture tests on Windows and Linux
- [ ] Block merge if any fixture test fails
- [ ] Add new fixture directory when schema version bumps (per closeout template reminder)

---

## Changelog

| Version | Date | Changes |
|---------|------|---------|
| v1 (draft) | 2026-05-19 | Initial contract definition for F-023 |

---

**Contract Authority**: This document is the authoritative specification for Specrew state file schema v1. Implementation MUST conform to this contract. Deviations require spec reconciliation per Constitution Principle VIII.
