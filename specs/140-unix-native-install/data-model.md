# Data Model: Unix-Native Install & Command Surface

**Feature**: 140-unix-native-install
**Date**: 2026-06-02
**Purpose**: Define entities, attributes, relationships, and validation rules.

**No persisted data.** Every entity is either a transient in-memory value (during generation/install) or a static repo artifact (committed wrappers, FileList). No database, no runtime state, no migrations.

## Entity: CommandRegistryEntry

**Purpose**: one canonical command name the wrapper set must cover.

### Attributes

| Attribute | Type | Required | Validation | Description |
| --- | --- | --- | --- | --- |
| `name` | string | yes | matches `^specrew(-[a-z0-9-]+)?$` | e.g. `specrew`, `specrew-init` |
| `kind` | enum | yes | `root` \| `alias` | root command vs exported alias |
| `entrypoint` | path | yes | file exists under `scripts/` | `scripts/specrew.ps1` (root) or `scripts/specrew-<x>.ps1` |

### Lifecycle / Relationships

Sourced from `Specrew.psd1` `AliasesToExport` + the root `specrew` (v1; Proposal 150 manifest is v2). Read by the generator and parity checks; never mutated by this feature. One `CommandRegistryEntry` → one `ShellWrapper`.

## Entity: ShellWrapper

**Purpose**: a generated POSIX `sh` forwarder file in `bin/`.

### Attributes

| Attribute | Type | Required | Validation | Description |
| --- | --- | --- | --- | --- |
| `path` | path | yes | `bin/<name>` | committed, shipped via FileList |
| `content` | text | yes | `sh -n` passes; byte-identical to generator output | rendered from the single template |
| `targetEntrypoint` | path | yes | matches the registry entry | what it `exec`s via pwsh |

### Lifecycle / Relationships

Generated from a `CommandRegistryEntry` by the generator; committed; copied (not symlinked, by default) into a user bin dir by the installer. Drift between committed content and a fresh generation is a CI failure.

## Entity: WrapperInstallRequest *(transient)*

**Purpose**: parameters to `specrew install-shell-wrappers`.

### Attributes

| Attribute | Type | Required | Validation | Description |
| --- | --- | --- | --- | --- |
| `binDir` | path | no | exists OR `force=true` | default `$HOME/.local/bin` |
| `force` | bool | no | — | required to create a missing `binDir` |
| `whatIf` | bool | no | — | dry-run; changes nothing |

### Lifecycle / Relationships

Constructed per invocation; not persisted. Invariant: never writes outside `binDir`; never edits shell profiles.

## Entity: BootstrapRun *(transient)*

**Purpose**: a single `install.sh` execution.

### Attributes

| Attribute | Type | Required | Validation | Description |
| --- | --- | --- | --- | --- |
| `pwshPresent` | bool | yes | abort with hint if false | gate before any install |
| `moduleInstalled` | bool | yes | — | result of `Install-Module Specrew` |
| `wrappersInstalled` | bool | yes | — | result of `install-shell-wrappers` |

### Lifecycle / Relationships

One-shot, ordered (module first, wrappers second); not persisted. Never installs pwsh.

## Entity: FileListEntry

**Purpose**: a `Specrew.psd1` `FileList` path that must ship a wrapper/bootstrap.

### Attributes

| Attribute | Type | Required | Validation | Description |
| --- | --- | --- | --- | --- |
| `relativePath` | path | yes | present in published artifact | each `bin/` wrapper + `install.sh` |

### Lifecycle / Relationships

Packaging parity test asserts every `bin/` wrapper + `install.sh` appears in `FileList` and in the published module artifact.
