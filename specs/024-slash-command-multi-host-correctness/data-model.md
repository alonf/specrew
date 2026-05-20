# Data Model: Slash-Command Multi-Host Correctness

**Feature**: 024-slash-command-multi-host-correctness  
**Phase**: Phase 1 (Design)  
**Date**: 2026-05-19

## Overview

This data model defines the key entities, their attributes, relationships, validation rules, and state transitions for Feature 024's multi-host slash-command deployment, frontmatter validity, and legacy migration.

---

## Entities

### 1. Slash Command Definition

**Description**: One of the seven existing Specrew commands, expressed as a directory-scoped `SKILL.md` with a canonical hyphenated name, discovery metadata, optional tool constraints, and retained body guidance from Feature 021.

**Attributes**:

| Attribute | Type | Required | Validation | Description |
| --- | --- | --- | --- | --- |
| `commandName` | string | Yes | Must match `^specrew-(where\|status\|update\|team\|review\|help\|version)$` | Canonical hyphenated command name (e.g., `specrew-where`) |
| `directoryName` | string | Yes | Must equal `commandName` | Directory name under skill deployment paths (e.g., `specrew-where/`) |
| `yamlFrontmatterName` | string | Yes | Must equal `commandName` | YAML frontmatter `name` field value |
| `yamlFrontmatterDescription` | string | Yes | Must be non-empty, max 200 chars | YAML frontmatter `description` field value |
| `bodyGuidance` | markdown | Yes | Must preserve Feature 021 sections: Purpose, When to Use, Invocation, Inputs, Outputs, Failure Guidance | Markdown body after frontmatter delimiter |
| `sourceTemplatePath` | filepath | Yes | Must exist in `extensions/specrew-speckit/squad-templates/skills/{directoryName}/SKILL.md` | Source template file path |
| `isAlias` | boolean | No | Default: `false` | True if this command is an alias (only `specrew-status` is an alias of `specrew-where`) |
| `aliasOf` | string | No | Must reference another valid `commandName` | If `isAlias` is true, the canonical command this aliases |

**Relationships**:
- A Slash Command Definition is deployed to **three Deployment Targets** (one-to-many).
- A Slash Command Definition may have **zero or one Alias Relationship** (one-to-one optional).

**Validation Rules**:
- `yamlFrontmatterName` MUST match `directoryName` (e.g., directory `specrew-where/` requires `name: specrew-where`).
- `yamlFrontmatterDescription` MUST be non-empty and derived from Feature 021's "Purpose" section guidance.
- `bodyGuidance` MUST replace all `/specrew.X` references with `/specrew-X` hyphenated form.
- If `isAlias` is true, `aliasOf` MUST reference a canonical command (e.g., `specrew-status` aliases `specrew-where`).

**State Transitions**:
- **Template State**: Source template exists in repo, not yet deployed.
- **Deployed State**: Content-identical `SKILL.md` files exist in all three Deployment Targets.
- **Migrated State**: Legacy `.copilot/skills/{directoryName}/` deployment removed if managed.

---

### 2. Deployment Target

**Description**: A supported project skill location (`.claude/skills/`, `.github/skills/`, or `.agents/skills/`) that receives the same command definition set with content-identical `SKILL.md` files.

**Attributes**:

| Attribute | Type | Required | Validation | Description |
| --- | --- | --- | --- | --- |
| `targetPath` | string | Yes | Must match `^\\.(claude\|github\|agents)\\/skills\\/$` | Relative path from project root to deployment location |
| `hostPrimaryDiscovery` | string | Yes | Must be one of: `claude-code`, `github-copilot-cli`, `host-neutral` | Which AI coding host primarily discovers skills in this path |
| `deploymentStatus` | enum | Yes | One of: `pending`, `deployed`, `failed` | Current deployment state |
| `deployedCommandCount` | integer | No | Must equal 7 when `deploymentStatus` is `deployed` | Number of commands successfully deployed to this target |

**Relationships**:
- A Deployment Target receives **seven Slash Command Definitions** (one-to-many from Slash Command Definition).
- A Deployment Target is managed by **one Deployment Operation** (many-to-one).

**Validation Rules**:
- All three Deployment Targets MUST contain content-identical `SKILL.md` files for each command (byte-for-byte match).
- If `deploymentStatus` is `deployed`, `deployedCommandCount` MUST equal 7 (all seven commands present).
- Each Deployment Target directory MUST exist or be created during deployment.

**State Transitions**:
- **Pending**: Target path identified, deployment not yet executed.
- **Deployed**: All seven commands successfully written to target path with valid frontmatter.
- **Failed**: Deployment attempted but failed (e.g., filesystem permission error, invalid template content).

---

### 3. Legacy Skill Directory

**Description**: A pre-v0.24.0 `.copilot/skills/specrew-*` directory that may be Specrew-managed or unmanaged and therefore requires different migration behavior during `specrew update`.

**Attributes**:

| Attribute | Type | Required | Validation | Description |
| --- | --- | --- | --- | --- |
| `legacyPath` | filepath | Yes | Must match `.copilot/skills/specrew-*` pattern | Absolute path to legacy directory |
| `directoryName` | string | Yes | Must match `^specrew-(where\|status\|update\|team\|review\|help\|version)$` | Directory name (e.g., `specrew-where`) |
| `isManagedBySpecrew` | boolean | Yes | Determined by managed-marker detection from `Set-ManagedFile` tracking | True if Specrew created this directory (safe to remove), false if user-created (preserve) |
| `migrationAction` | enum | Yes | One of: `remove`, `preserve`, `pending` | Action to take during migration |
| `migrationStatus` | enum | Yes | One of: `not-started`, `in-progress`, `completed`, `failed` | Current migration state |

**Relationships**:
- A Legacy Skill Directory may correspond to **one Slash Command Definition** (one-to-one optional).
- A Legacy Skill Directory is processed by **one Migration Operation** (many-to-one).

**Validation Rules**:
- If `isManagedBySpecrew` is true, `migrationAction` MUST be `remove`.
- If `isManagedBySpecrew` is false, `migrationAction` MUST be `preserve`.
- Managed-marker detection MUST use existing `Set-ManagedFile` tracking logic from deploy-squad-runtime.ps1.
- Unmanaged content MUST NOT be silently deleted; it MUST be preserved and surfaced as leftover non-discoverable content.

**State Transitions**:
- **Not Started**: Legacy directory discovered, migration action determined, not yet executed.
- **In Progress**: Migration action (remove or preserve) currently executing.
- **Completed**: Migration action successfully executed (managed content removed, unmanaged content preserved).
- **Failed**: Migration action attempted but failed (e.g., filesystem permission error).

---

### 4. YAML Frontmatter Block

**Description**: The YAML metadata section at the top of each `SKILL.md` file, delimited by `---` markers, containing `name`, `description`, and optional `allowed-tools` fields.

**Attributes**:

| Attribute | Type | Required | Validation | Description |
| --- | --- | --- | --- | --- |
| `name` | string | Yes | Must match parent directory name, lowercase-hyphen format | Canonical command name (e.g., `specrew-where`) |
| `description` | string | Yes | Must be non-empty, max 200 chars | Single-line discovery description |
| `allowedTools` | array[string] | No | List of tool names if restrictions apply | Optional tool constraints (not used in v0.24.0) |
| `isValid` | boolean | Derived | True if `name` and `description` pass validation | Frontmatter validity status |

**Relationships**:
- A YAML Frontmatter Block belongs to **one Slash Command Definition** (one-to-one).
- A YAML Frontmatter Block is validated by **Frontmatter Validation Rules** (many-to-one).

**Validation Rules**:
- YAML frontmatter MUST be delimited by `---` at start and end.
- `name` field MUST be present and match the directory name (case-sensitive).
- `description` field MUST be present and non-empty.
- YAML syntax MUST be valid (parseable by standard YAML parsers).
- If `allowedTools` is present, it MUST be a valid YAML array of strings.

**State Transitions**:
- **Missing**: No frontmatter present in `SKILL.md` (invalid state).
- **Invalid**: Frontmatter present but fails validation (e.g., missing `name`, empty `description`, invalid YAML syntax).
- **Valid**: Frontmatter present and passes all validation rules.

---

### 5. Deployment Operation

**Description**: A single execution of the multi-host deployment logic in `deploy-squad-runtime.ps1`, responsible for synchronizing all seven slash commands to all three deployment targets.

**Attributes**:

| Attribute | Type | Required | Validation | Description |
| --- | --- | --- | --- | --- |
| `operationId` | guid | Yes | Unique identifier | Unique identifier for this deployment operation |
| `operationType` | enum | Yes | One of: `init`, `update` | Whether this is initial bootstrap or refresh |
| `projectPath` | filepath | Yes | Must be valid Git repository with Specrew initialization | Absolute path to target Specrew project |
| `operationStatus` | enum | Yes | One of: `pending`, `in-progress`, `completed`, `failed` | Current operation state |
| `deployedTargetCount` | integer | No | Must equal 3 when `operationStatus` is `completed` | Number of deployment targets successfully populated |
| `errorMessages` | array[string] | No | Populated if `operationStatus` is `failed` | Error details if deployment fails |

**Relationships**:
- A Deployment Operation manages **three Deployment Targets** (one-to-many).
- A Deployment Operation may trigger **one Migration Operation** if `operationType` is `update` (one-to-one optional).

**Validation Rules**:
- `projectPath` MUST be a valid Git repository with `.squad/` directory present (Specrew initialized).
- All seven commands MUST be deployed to all three targets for operation to be marked `completed`.
- If any target deployment fails, `operationStatus` MUST be `failed` and `errorMessages` MUST contain diagnostic information.

**State Transitions**:
- **Pending**: Operation queued, not yet started.
- **In Progress**: Deployment logic executing, writing `SKILL.md` files to targets.
- **Completed**: All seven commands deployed to all three targets with valid frontmatter.
- **Failed**: Deployment encountered error (filesystem issue, invalid template content, permission denied).

---

### 6. Migration Operation

**Description**: A single execution of the legacy `.copilot/skills/specrew-*` migration logic during `specrew update`, responsible for safely removing Specrew-managed directories while preserving unmanaged content.

**Attributes**:

| Attribute | Type | Required | Validation | Description |
| --- | --- | --- | --- | --- |
| `operationId` | guid | Yes | Unique identifier | Unique identifier for this migration operation |
| `projectPath` | filepath | Yes | Must be valid Git repository with Specrew initialization | Absolute path to target Specrew project |
| `legacyPathScanned` | filepath | Yes | Must be `.copilot/skills/` under `projectPath` | Directory scanned for legacy content |
| `discoveredLegacyCount` | integer | No | Number of `specrew-*` directories found | Count of legacy directories discovered |
| `managedRemovalCount` | integer | No | Number of managed directories removed | Count of Specrew-managed directories removed |
| `unmanagedPreserveCount` | integer | No | Number of unmanaged directories preserved | Count of user-created directories preserved |
| `operationStatus` | enum | Yes | One of: `pending`, `in-progress`, `completed`, `failed` | Current migration state |
| `errorMessages` | array[string] | No | Populated if `operationStatus` is `failed` | Error details if migration fails |

**Relationships**:
- A Migration Operation is triggered by **one Deployment Operation** (one-to-one).
- A Migration Operation processes **multiple Legacy Skill Directories** (one-to-many).

**Validation Rules**:
- `legacyPathScanned` MUST be `.copilot/skills/` under `projectPath`.
- Managed-marker detection MUST be authoritative for `isManagedBySpecrew` determination.
- Unmanaged content MUST NOT be deleted; it MUST be preserved and reported in `unmanagedPreserveCount`.
- If migration fails partway through, `operationStatus` MUST be `failed` and rollback or partial-state handling MUST be documented in `errorMessages`.

**State Transitions**:
- **Pending**: Migration queued, not yet started.
- **In Progress**: Scanning legacy directories, applying managed-marker detection, removing/preserving content.
- **Completed**: All legacy directories processed; managed content removed, unmanaged content preserved.
- **Failed**: Migration encountered error (filesystem issue, permission denied, managed-marker detection failed).

---

## Relationships Summary

```text
Slash Command Definition (1) ──── deploys to ──── (3) Deployment Target
        │
        │── contains ──── (1) YAML Frontmatter Block
        │
        │── may correspond to ──── (0..1) Legacy Skill Directory

Deployment Operation (1) ──── manages ──── (3) Deployment Target
        │
        │── may trigger ──── (0..1) Migration Operation

Migration Operation (1) ──── processes ──── (0..N) Legacy Skill Directory
```

---

## Key Validation Rules (Cross-Entity)

1. **Content Identity**: All three Deployment Targets MUST contain byte-for-byte identical `SKILL.md` files for each Slash Command Definition.
2. **Frontmatter-Directory Matching**: The YAML Frontmatter Block `name` field MUST match the parent directory name (e.g., directory `specrew-where/` requires `name: specrew-where`).
3. **Managed-Marker Authority**: Managed-marker detection from `Set-ManagedFile` tracking is the authoritative source for determining whether a Legacy Skill Directory is safe to remove.
4. **Safe Migration**: Migration Operations MUST preserve unmanaged Legacy Skill Directories and report them as leftover non-discoverable content rather than silently deleting them.
5. **Atomic Deployment**: A Deployment Operation is considered successful only when all seven commands are deployed to all three targets with valid frontmatter; partial deployment is a failure state.

---

## State Transition Summary

### Slash Command Definition
- **Template** → **Deployed** (after Deployment Operation completes)
- **Deployed** → **Migrated** (after Migration Operation removes legacy `.copilot/skills/` copy)

### Deployment Target
- **Pending** → **Deployed** (all seven commands written with valid frontmatter)
- **Pending** → **Failed** (deployment error)

### Legacy Skill Directory
- **Not Started** → **In Progress** → **Completed** (migration action executed)
- **In Progress** → **Failed** (migration error)

### YAML Frontmatter Block
- **Missing** → **Valid** (frontmatter added during template refresh)
- **Invalid** → **Valid** (frontmatter corrected during template refresh)

### Deployment Operation
- **Pending** → **In Progress** → **Completed** (all targets deployed)
- **In Progress** → **Failed** (deployment error)

### Migration Operation
- **Pending** → **In Progress** → **Completed** (all legacy directories processed)
- **In Progress** → **Failed** (migration error)

---

## Next Steps

Proceed to create **contracts/** artifacts:
- `multi-host-deployment.md` — Contract for content-identical deployment to three target paths
- `frontmatter-validity.md` — Contract for YAML frontmatter structure and validation
- `migration-safety.md` — Contract for safe managed/unmanaged legacy directory handling
- `discovery-contract.md` — Contract for Claude Code + GitHub Copilot CLI + host-neutral discoverability claims
