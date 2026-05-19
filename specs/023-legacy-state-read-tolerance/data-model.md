# Data Model: Legacy-State Read-Tolerance + Schema Migration Discipline

**Feature Branch**: `023-legacy-state-read-tolerance`  
**Created**: 2026-05-19  
**Source**: Extracted from spec.md and research.md

---

## Core Entities

### 1. State File

**Definition**: A persisted JSON or YAML file managed by Specrew that contains configuration, session state, or feature metadata.

**Purpose**: Stores runtime state, configuration settings, and workflow metadata across Specrew command invocations. State files must survive version upgrades without causing crashes or data loss.

**Attributes**:

| Attribute | Type | Required | Description | Example Values |
|-----------|------|----------|-------------|----------------|
| `file_path` | String (file:/// URI) | Yes | Absolute path to the state file | `file:///[project]/.specrew/config.yml` |
| `schema_version` | String | No (v0 if absent) | Schema contract version identifier | `"v0"` (implied), `"v1"` (explicit) |
| `format` | Enum | Yes | Serialization format | `JSON`, `YAML` |
| `content_structure` | Object/Hashtable | Yes | Parsed content (schema-specific) | Varies by file type and schema version |
| `persistence_scope` | Enum | Yes | Lifecycle boundary | `user_project`, `specrew_installation`, `session_only` |
| `last_write_version` | String | No | Specrew version that last wrote the file | `"0.19.0"`, `"0.22.0"` |

**Lifecycle**:

1. **Creation**: Written by Specrew command (e.g., `specrew init`, `specrew start`)
2. **Reading**: Parsed by subsequent Specrew operations (reader functions)
3. **Schema Evolution**: May gain new fields in newer Specrew versions (additive changes only in v1)
4. **Silent Upgrade**: On next write after upgrade, schema version bumped to latest (v0 → v1)
5. **Persistence**: Survives across Specrew version upgrades (backward compatibility required)

**Relationships**:

- **Contains**: 1 State File → 1 Schema Version Marker (optional for v0, required for v1+)
- **Read by**: 1 State File → N State Reader Functions
- **Written by**: 1 State File → N State Writer Functions
- **Exemplified by**: 1 State File → 1 Legacy Fixture (for historical versions)

**State File Types** (Iteration 1 scope):

| File Path | Format | Current Schema | Content Purpose | Reader Functions | Writer Functions |
|-----------|--------|----------------|-----------------|------------------|------------------|
| `.specrew/config.yml` | YAML | v0 (manual parse) | User/team configuration settings | `scripts/specrew-start.ps1:268-289`, `scripts/internal/version-check.ps1:19-31`, `.specify/extensions/specrew-speckit/scripts/shared-governance.ps1:502-590` | `scripts/specrew-init.ps1` |
| `.specrew/start-context.json` | JSON | v0 → v1 | Session resume state | `scripts/specrew-start.ps1:360-395` | `scripts/specrew-start.ps1` |
| `.specrew/last-validator-summary.json` | JSON | v0 → v1 | Validator run results | `scripts/internal/coordinator-resume.ps1:28-56` | Validator framework |
| `.specrew/version-check-cache.json` | JSON | v1 (F-020) | Version check cache | `scripts/internal/version-check.ps1:113-143` | `scripts/internal/version-check.ps1` |
| `.specify/feature.json` | JSON | v0 → v1 | Feature metadata | `scripts/specrew-start.ps1`, `scripts/internal/worktree-awareness.ps1:57-75`, `.specify/extensions/specrew-speckit/scripts/scaffold-feature-closeout-dashboard.ps1:106-121` | Feature scaffold scripts |
| `.specify/extensions/specrew-speckit/extension.yml` | YAML | v0 → v1 | Extension manifest | `.specify/extensions/specrew-speckit/scripts/validate-governance.ps1:569-575` | Extension installer |
| `.squad/identity/now.md` | Markdown (YAML frontmatter) | v0 → v1 | Squad identity/session state | `scripts/internal/worktree-awareness.ps1:10-52`, `scripts/internal/sync-boundary-state.ps1:46-76` | `scripts/internal/sync-boundary-state.ps1:304+` |
| `tasks-progress.yml` | YAML | v1 (F-020) | Task completion tracking | `scripts/internal/task-progress.ps1:204-238` | `scripts/internal/task-progress.ps1` |

**Invariants**:

- State files MUST be text-based (JSON or YAML); binary formats out of scope
- State files MUST tolerate missing optional fields (backward compatibility)
- State files MUST NOT silently override spec authority (Constitution Principle I)
- Schema evolution MUST be additive within a major version (no breaking field removals/renames)

**Edge Cases**:

- **Corrupted file**: JSON/YAML parse error → clear error message, does not affect other state files
- **Missing file**: Treated as absent state; defaults applied; no crash
- **Partial state**: Missing optional fields → safe defaults; no crash under StrictMode
- **Downgrade scenario**: Newer schema read by older Specrew → error message "requires version X.Y.Z or higher"
- **Schema version higher than supported**: Error message with clear upgrade path

---

### 2. Schema Version Marker

**Definition**: A top-level field in a state file indicating its structural contract version.

**Purpose**: Enables readers to apply version-specific compatibility logic, supports safe schema evolution, improves diagnostics and support resolution time.

**Attributes**:

| Attribute | Type | Required | Description | Example Values |
|-----------|------|----------|-------------|----------------|
| `version_identifier` | String | Yes | Schema version label | `"v0"`, `"v1"`, `"v2"` (future) |
| `format` | Enum | Yes | How version is encoded | `top_level_field`, `frontmatter_key` |
| `field_name` | String | Yes | Key name in state file | `"schema"` (JSON/YAML), `"schema:"` (frontmatter) |
| `implied_if_absent` | Boolean | Yes | Whether absence means v0 | `true` for v0, `false` for v1+ |
| `reader_dispatch_required` | Boolean | Yes | Whether readers need version-aware logic | `false` for v0→v1 (additive only), `true` for breaking changes |

**Lifecycle**:

1. **Absence** (legacy files): Interpreted as schema v0; reader logs "schema-implied-v0" at debug level
2. **Explicit v1** (new files): Added by writer when state file is created or updated; field `schema: v1` at top level
3. **Version bump** (future breaking changes): Reader checks schema version; applies version-specific logic; may prompt for migration

**Relationships**:

- **Contained by**: 1 Schema Version Marker → 1 State File
- **Checked by**: 1 Schema Version Marker → N State Reader Functions (version dispatch logic)
- **Written by**: 1 Schema Version Marker → N State Writer Functions (always include in v1+)

**Format Examples**:

**JSON state file** (`.specrew/start-context.json`):

```json
{
  "schema": "v1",
  "session_state": { ... },
  "feature_path": "/path/to/feature"
}
```

**YAML state file** (`.specrew/config.yml`):

```yaml
schema: v1
team_id: example-team
capacity_unit: story_points
```

**Markdown frontmatter** (`.squad/identity/now.md`):

```markdown
---
schema: v1
feature: 023-legacy-state-read-tolerance
iteration: 001
---
# Squad Identity Context
...
```

**Invariants**:

- Schema version MUST be a top-level field (not nested)
- Field name MUST be `schema` (lowercase, singular)
- Value MUST be a string (e.g., `"v1"`, not integer `1`)
- Absence MUST be interpreted as v0 (implicit legacy schema)
- Schema version MUST NOT be used for extension content version (FR-003 distinguishes `extension.version` from `extension.schema`)

**Edge Cases**:

- **Unknown schema version**: Reader encounters `"v99"` → error "unsupported schema version; requires Specrew X.Y.Z or higher"
- **Invalid schema value**: Non-string or malformed value → treated as v0 with warning log
- **Schema version in nested object**: Ignored; only top-level `schema` field is authoritative

---

### 3. Legacy Fixture

**Definition**: A test artifact representing the state files from a specific Specrew version, used for continuous integration regression testing.

**Purpose**: Ensures state readers remain backward-compatible across Specrew version upgrades; detects regressions in reader tolerance before production crashes occur.

**Attributes**:

| Attribute | Type | Required | Description | Example Values |
|-----------|------|----------|-------------|----------------|
| `specrew_version` | String | Yes | Version this fixture represents | `"0.19.0"`, `"0.22.0"` |
| `file_set` | Array[String] | Yes | Paths to state files in fixture | `[".specrew/config.yml", ".specify/feature.json"]` |
| `fixture_location` | String (file:/// URI) | Yes | Directory path | `file:///C:/Dev/Specrew/tests/fixtures/legacy-versions/0.19.0/` |
| `creation_method` | Enum | Yes | How fixture was generated | `hand_curated`, `snapshot_based`, `generated` |
| `edge_cases_covered` | Array[String] | No | Specific edge cases in this fixture | `["missing_optional_field", "partial_state", "crash_repro"]` |
| `line_ending_normalized` | Boolean | Yes | Whether Git normalized CRLF/LF | `true` (via `core.autocrlf`) |

**Lifecycle**:

1. **Generation** (Iteration 1): Hand-curated from real Specrew projects at versions 0.18.0-0.22.0
2. **CI Testing** (every PR): All state readers invoked against all fixtures; failures block merge
3. **Addition** (future versions): New fixture directory created when schema version bumps (per closeout template FR-013)
4. **Maintenance**: Fixtures remain immutable after creation (represent historical state)

**Relationships**:

- **Exemplifies**: 1 Legacy Fixture → N State Files (one fixture directory contains multiple state file types)
- **Tested by**: 1 Legacy Fixture → N Pester Test Cases (one test per reader function per fixture)
- **Version Correspondence**: 1 Legacy Fixture → 1 Specrew Release Version

**Fixture Directory Structure**:

```
tests/fixtures/legacy-versions/
├── 0.18.0/
│   ├── .specrew/
│   │   ├── config.yml
│   │   └── start-context.json
│   ├── .specify/
│   │   ├── feature.json
│   │   └── extensions/specrew-speckit/extension.yml
│   ├── .squad/
│   │   └── identity/now.md
│   └── tasks-progress.yml (if applicable for this version)
├── 0.19.0/   # Contains motivating crash repro (missing session_state field)
├── 0.20.0/
├── 0.21.0/
└── 0.22.0/
```

**Test Coverage Requirements** (FR-008):

- Pass criteria: No exceptions thrown, no `$null` reference errors, return values structurally consistent
- Readers in scope:
  - `Get-SpecrewStartContextSessionState`
  - `Get-FeatureJson`
  - `Get-ConfigMap`
  - `Get-SpecrewIdentitySessionState`
  - All other functions reading from `.specrew/*`, `.specify/*`, `.squad/*`

**Invariants**:

- Fixture directories MUST be immutable after creation (historical snapshots)
- Fixture names MUST match Specrew version tags (e.g., `0.19.0` not `v0.19.0`)
- Fixture file sets MUST include all state file types relevant to that version
- Line endings MUST be normalized via Git `core.autocrlf` (cross-platform compatibility)

**Edge Cases**:

- **Missing fixture file**: Test skips that specific reader test; logs warning (not all state files existed in early versions)
- **Fixture file with intentional corruption**: Used for negative testing (parse error handling); documented in `edge_cases_covered`
- **Fixture growth over time**: As new state files added in future versions, older fixtures remain unchanged (only test readers that existed at that version)

---

## Entity Relationships Diagram

```
┌─────────────────────────────────────────┐
│         State File                      │
│  - file_path: String                    │
│  - schema_version: String (v0/v1/...)   │
│  - format: JSON | YAML                  │
│  - content_structure: Object            │
│  - persistence_scope: Enum              │
└───────────┬─────────────────────────────┘
            │
            │ contains
            ▼
┌─────────────────────────────────────────┐
│    Schema Version Marker                │
│  - version_identifier: String           │
│  - format: top_level_field              │
│  - field_name: "schema"                 │
│  - implied_if_absent: Boolean           │
└─────────────────────────────────────────┘

┌─────────────────────────────────────────┐
│         State File                      │
└───────────┬─────────────────────────────┘
            │
            │ read by
            ▼
┌─────────────────────────────────────────┐
│    State Reader Function                │
│  - function_name: String                │
│  - uses_hashtable: Boolean              │
│  - strictmode_compatible: Boolean       │
└───────────┬─────────────────────────────┘
            │
            │ tested against
            ▼
┌─────────────────────────────────────────┐
│         Legacy Fixture                  │
│  - specrew_version: String              │
│  - file_set: Array[String]              │
│  - fixture_location: URI                │
│  - creation_method: Enum                │
└─────────────────────────────────────────┘
            │
            │ exemplifies
            ▼
┌─────────────────────────────────────────┐
│         State File (historical)         │
│  (specific version snapshot)            │
└─────────────────────────────────────────┘
```

---

## Schema Evolution Rules

**Version 0 → Version 1** (Iteration 1 scope):

- **Additive changes only**: New optional fields may be added
- **No breaking changes**: No field removals, no type changes, no field renames
- **Reader tolerance**: Readers MUST tolerate missing optional fields (return `$null` or safe defaults)
- **Writer upgrade**: Writers silently add `schema: v1` on next write after upgrade
- **No user prompt**: For most files; user-visible configs (e.g., `.specrew/config.yml`) MAY log one-time upgrade notice

**Future Version Bumps** (v1 → v2, deferred):

- **Breaking changes allowed**: Field removals, type changes, semantic shifts
- **Explicit migration**: Reader detects unsupported schema version → clear error message
- **Migration commands**: Future proposal may add `specrew migrate-state` command
- **Fixture requirement**: New fixture directory added for each breaking schema version

---

## Data Integrity Constraints

1. **Persistence Boundary Discipline** (Constitution Principle I):
   - State files MUST NOT silently override spec authority
   - Drift between state files and spec artifacts MUST be detected and escalated

2. **StrictMode Compatibility** (FR-005):
   - All state readers MUST use hashtable-based parsing (`ConvertFrom-Json -AsHashtable`)
   - All optional field access MUST use hashtable indexers (not PSCustomObject property access)

3. **Cross-Platform Normalization** (FR-014):
   - Text state files MUST use Git `core.autocrlf` for line-ending normalization
   - Binary state files out of scope (all Specrew state is text-based)

4. **Backward Compatibility** (FR-002):
   - Readers MUST interpret missing `schema` field as v0
   - Readers MUST NOT throw exceptions for missing optional fields

5. **Forward Compatibility** (edge case handling):
   - Readers MUST detect unsupported schema versions (e.g., v2 when only v1 supported)
   - Readers MUST provide clear error messages with upgrade path

---

## Phase 1 Design Complete

**Next Steps**:

- Generate interface contracts (`contracts/state-file-schema-v1.md`)
- Generate quickstart guide (`quickstart.md`)
- Update agent context (run `.specify/scripts/powershell/update-agent-context.ps1 -AgentType copilot`)
- Re-evaluate Constitution Check post-design
