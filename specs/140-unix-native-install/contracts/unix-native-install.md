# Contract: Unix-Native Install & Command Surface Public Surface

**Feature**: 140-unix-native-install
**Stability**: pre-1.0

## Wrapper (`bin/<name>`)

A POSIX `sh` thin forwarder: resolves the module root (following symlinks), verifies `pwsh`, then `exec`s the PowerShell entrypoint, forwarding all arguments unchanged. It owns **no** option parsing.

### Invariants

- Every user argument reaches the PowerShell command byte-for-byte (spaces, quotes, empty strings, `--` passthrough).
- Exit code equals the PowerShell command's exit code, except `pwsh` missing → non-zero (e.g. 127).
- `pwsh` missing → clear message + install hint; never auto-installs PowerShell.
- POSIX `sh` only (no Bash arrays, no GNU `readlink -f`); resolves correctly when invoked via a symlink from any bin directory.
- The wrapper set is exactly the canonical registry (no more, no fewer).

## `specrew install-shell-wrappers` (root subcommand)

### Exported API

| Symbol | Signature | Purpose | Errors |
| --- | --- | --- | --- |
| `install-shell-wrappers` | `specrew install-shell-wrappers [-BinDir <path>] [-Force] [-WhatIf]` | copy committed `bin/` wrappers into `BinDir` (default `$HOME/.local/bin`); idempotent | refuses to create a missing `BinDir` without `-Force` |

### Invariants

- No mutation outside `BinDir`; never edits shell profiles.
- `-WhatIf` reports intended actions and changes nothing.
- Warns clearly when `BinDir` is not on `PATH`; prints the exact commands installed.
- Re-running is idempotent (no duplicate/partial state).
- On Windows: explained no-op unless explicitly requested.

## `install.sh` (bootstrap)

`curl … | sh` flow: verify `pwsh` (abort with install hint if missing; never installs pwsh) → `Install-Module Specrew` via pwsh → `specrew install-shell-wrappers`. Ordering: module first, wrappers second.

## `generate-shell-wrappers.ps1` (generator)

Reads the canonical registry and renders `bin/` wrappers from one template. Deterministic and idempotent (re-run → byte-identical output). CI regenerates and `git diff --exit-code`s to detect drift.

## Canonical command registry

- v1: `Specrew.psd1` `AliasesToExport` + the root `specrew`.
- v2: Proposal 150's `.specrew/agent-command-manifest.json` when available.

### Invariants

- `count(bin/ wrappers) == count(registry)` (registry ↔ wrapper parity).
- Every `bin/` wrapper + `install.sh` is present in `Specrew.psd1` `FileList` and in the published artifact.
- A command-surface change (registry, `scripts/specrew*.ps1`, manifest, docs) triggers the parity cascade in CI: registry → wrappers → installer → FileList → docs.
