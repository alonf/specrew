# Contract: Specrew Update Downgrade Guard Public Surface

**Feature**: 159-update-ux-small-fixes  
**Stability**: pre-1.0

## `scripts/specrew-update.ps1`

Refreshes Specrew-managed project assets and optionally updates managed platform dependencies. This feature adds a pre-mutation guard that refuses to mutate a project when the running Specrew module/source version is older than the project's recorded `.specrew/config.yml` `specrew_version`.

### Command Surface

| Command | Purpose | Mutation |
| --- | --- | --- |
| `specrew update --info` | Report platform version state | No |
| `specrew update` | Refresh Specrew-managed project assets | Yes |
| `specrew update --specrew` | Refresh Specrew-managed project assets | Yes |
| `specrew update --spec-kit` | Update Spec Kit dependency state | Yes |
| `specrew update --squad` | Update Squad dependency state | Yes |
| `specrew update --all` | Update all requested surfaces | Yes |

### Exported API

| Symbol | Signature | Purpose | Errors |
| --- | --- | --- | --- |
| `Convert-UnixStyleArguments` | `(ProjectPath, InfoMode, All, Specrew, Squad, SpecKit, SkipUpdateCheck, UpstreamLatest, Help, CliArgs) -> object` | Normalize PowerShell and POSIX-style CLI arguments | Throws on unknown or missing-value arguments |
| `Get-ConfigMap` | `(ConfigPath) -> hashtable` | Read scalar project config values | Returns empty map for missing config path |
| `Get-ParsedVersion` | `(Value, Name) -> version` | Parse comparable version text | Throws when version text cannot be parsed |
| `Update-SpecrewConfig` | `(ConfigPath, SpecrewVersion, SpecKitVersion, SquadVersion) -> string` | Persist config version fields after successful update | Writes only after guard passes |
| `Test/Invoke planned guard helper` | `(RunningVersion, ProjectBaseline, Invocation) -> decision` | Planned helper or inline equivalent for stale-module refusal before mutation | Fails closed on older running version or unparsable present baseline |

### Invariants

- `--info` remains read-only and does not change project files.
- Every mutating update scope checks stale-module safety before any project mutation.
- If running Specrew is older than the project baseline, no protected file is changed.
- Refusal output includes both `Update-Module Specrew` and `SPECREW_MODULE_PATH`.
- Equal or newer running Specrew continues through existing update behavior.
- The guard does not attempt to install or update the Specrew PowerShell module.

## `scripts/specrew-version.ps1` and Active Generated Guidance

Reports installed/project Specrew versions and slash-command compatibility state. This feature changes routine message wording so `0.24.0` is not presented as a current minimum compatibility baseline to normal users.

### Invariants

- Historical records may still mention `0.24.0`.
- Active routine help/report/governance text should refer to current module/project alignment and upgrade guidance without surfacing old-baseline noise.
- Incompatible or unknown states still produce actionable remediation.
