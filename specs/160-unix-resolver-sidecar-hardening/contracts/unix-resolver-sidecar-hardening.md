# Contract: Unix Resolver Sidecar Hardening Public Surface

**Feature**: `160-unix-resolver-sidecar-hardening`
**Stability**: pre-1.0

## Resolver Invocation Surface

The resolver investigation may touch module/script path selection used by the
exported Specrew command aliases. The public contract is that invoking a Specrew
command from a development tree continues to load scripts from that same tree
when the tree contains the required manifest and script files.

### Exported API

| Symbol | Signature | Purpose | Errors |
| --- | --- | --- | --- |
| `Invoke-SpecrewScript` | `(CommandName: string, Arguments: object[])` | Dispatch exported aliases to the matching script path | Throws if the script path is missing |
| `specrew` alias | command alias | User-facing root command | Propagates target script exit code |
| `specrew-start` alias | command alias | User-facing start command | Propagates target script exit code |

### Invariants

- Development-tree invocation must not silently import a stale installed module
  when the local manifest and scripts are present.
- Resolver fixes must preserve Windows behavior and prove Unix/macOS or
  deterministic Unix-equivalent behavior.
- Path construction must not depend on embedded platform-specific separators.

## Managed Runtime Marker Surface

The managed-refresh investigation may touch host runtime deployment functions
and direct Squad runtime deployment. The public contract is that managed files
refresh from canonical sources, while user-edited unmanaged files are preserved.

### Exported API

| Symbol | Signature | Purpose | Errors |
| --- | --- | --- | --- |
| `Test-SpecrewManagedFile` | `(Path: string): bool` | Decide whether a host-native file may be overwritten | Returns false for existing files without markers |
| `Write-SpecrewManagedSidecar` | `(Path: string): void` | Write `<Path>.specrew-managed` sidecar marker | Propagates file write errors |
| `Install-CopilotCrewRuntime` | `(ProjectPath: string, DryRun?: switch): object` | Deploy `.squad/agents/<role>/charter.md` from canonical charters | Reports notices for preserved user-edited files |
| `Install-ClaudeCrewRuntime` | `(ProjectPath: string, DryRun?: switch): object` | Deploy `.claude/agents/<role>.md` from canonical charters | Reports notices for preserved user-edited files |
| `Install-CodexCrewRuntime` | `(ProjectPath: string, DryRun?: switch): object` | Deploy `.codex/agents/<role>.toml` from canonical charters | Reports notices for preserved user-edited files |
| `Install-CursorCrewRuntime` | `(ProjectPath: string, DryRun?: switch): object` | Deploy `.cursor/rules/<role>.mdc` from canonical charters | Reports notices for preserved user-edited files |
| `Install-AntigravityCrewRuntime` | `(ProjectPath: string, DryRun?: switch): object` | Deploy `.agents/agents/<role>.md` from canonical charters | Reports notices for preserved user-edited files |
| `deploy-squad-runtime.ps1` | `-ProjectPath <path> [-DryRun] [-PassThru]` | Deploy legacy Squad runtime and skill surfaces | Throws on missing required runtime roots |

### Invariants

- Existing files without a valid sidecar or inline `Specrew-managed` marker are
  treated as user-edited and preserved.
- Managed marker creation and marker recognition must be asserted separately.
- Deleting a managed marker opts the file out of automatic refresh unless the
  investigation proves and specifies a different contract.
- Direct deploy fixtures must not write into active runtime directories in the
  developer workspace.
