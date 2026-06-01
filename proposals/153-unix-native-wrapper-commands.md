---
proposal: 153
title: Unix-Native Wrapper Commands for Specrew CLI
status: draft
phase: phase-2
estimated-sp: 8-13
priority-tier: 1
type: adoption-ux
discussion: surfaced 2026-06-01 after maintainer feedback that Mac/Linux users object less to PowerShell as an implementation dependency and more to having to invoke visible PowerShell commands for normal Specrew usage. The product fix is a native Unix command surface that wraps the existing PowerShell implementation.
composes-with:
  - 031  # Specrew Distribution Module
  - 069  # Multi-Host Launch Path
  - 104  # Multi-Host Onboarding + Selection Flow
  - 150  # Agent-Support Hardening Bundle
---

# Unix-Native Wrapper Commands for Specrew CLI

## Why

Specrew currently ships as a PowerShell module and exposes its operational commands through PowerShell-oriented entrypoints. That is acceptable as an implementation substrate, but it creates adoption friction for Mac and Linux users who expect normal shell commands and do not want day-to-day Specrew instructions to start with `pwsh -File ...`.

The problem is not necessarily "Specrew depends on PowerShell." PowerShell Core is cross-platform and remains a pragmatic implementation layer for the current codebase. The product problem is that the dependency leaks into the user's command surface.

Specrew should make this distinction explicit:

- **Runtime dependency**: PowerShell Core remains required for now.
- **User-facing CLI**: Mac/Linux users run `specrew`, `specrew start`, `specrew init`, and related commands from their normal shell without seeing PowerShell in routine workflows.

This proposal keeps the implementation stable while improving first impression, documentation, demos, and team adoption on Unix-like platforms.

## What

Ship POSIX shell wrapper commands that call the existing PowerShell implementation internally.

Primary command surface:

```bash
specrew version
specrew init
specrew start --host codex --resume-feature auto
specrew where --ascii --compact
specrew update
```

Compatibility aliases should continue to exist where practical:

```bash
specrew-init
specrew-start
specrew-update
specrew-version
specrew-review
specrew-team
specrew-where
```

Internally, these wrappers invoke PowerShell in a predictable, hidden way:

```bash
exec pwsh -NoProfile -ExecutionPolicy Bypass -File "$module_root/scripts/specrew.ps1" "$@"
```

The user-facing docs should describe this honestly: "PowerShell Core is required, but normal Mac/Linux usage does not require invoking PowerShell directly."

## Functional Requirements

- **FR-001**: Specrew MUST include POSIX-compatible wrapper scripts for the primary `specrew` command and the existing command aliases.
- **FR-002**: The wrappers MUST preserve argument forwarding exactly, including quoted values, paths with spaces, and host-native passthrough flags.
- **FR-003**: The wrappers MUST resolve their installed module root robustly, including when invoked through a symlink from `~/.local/bin`, `/usr/local/bin`, or another user-selected bin directory.
- **FR-004**: The wrappers MUST fail with a clear message when `pwsh` is not installed or not on `PATH`, including a short install hint and a link/reference to Specrew installation docs.
- **FR-005**: Specrew MUST provide an installation/update command that installs or refreshes Unix wrappers into a user-visible bin directory. Recommended command shape: `specrew install-shell-wrappers`.
- **FR-006**: Wrapper installation MUST be idempotent and safe: dry-run support, explicit overwrite behavior, and no mutation outside the requested bin directory.
- **FR-007**: `specrew init`, `specrew start`, `specrew update`, and documentation examples for macOS/Linux SHOULD use the native wrapper command shape instead of `pwsh -File`.
- **FR-008**: Windows behavior MUST remain unchanged except for documentation that explains the platform-specific command surfaces.
- **FR-009**: Package publishing MUST include the wrapper scripts in `Specrew.psd1` `FileList` and verify they are present in the published module package.
- **FR-010**: CI MUST validate wrapper behavior on Ubuntu and macOS.

## Acceptance Criteria

- **AC1**: On Ubuntu with PowerShell Core installed, `./bin/specrew version` returns the same version as the PowerShell module command.
- **AC2**: On macOS with PowerShell Core installed, `./bin/specrew --help` and `./bin/specrew start --help` execute successfully.
- **AC3**: A symlinked wrapper from a temporary bin directory resolves the module root and can run `specrew version`.
- **AC4**: Quoted arguments and paths with spaces are preserved through the wrapper into the PowerShell script.
- **AC5**: If `pwsh` is unavailable, the wrapper exits non-zero with a clear "PowerShell Core is required" message.
- **AC6**: `specrew install-shell-wrappers -BinDir <temp>` creates or updates the expected wrapper names and does not touch other files.
- **AC7**: The published prerelease package contains the wrapper files and the release smoke test exercises at least `specrew version` through the wrapper on a Unix runner.
- **AC8**: README, getting-started, and user-guide examples no longer make `pwsh -File` the primary macOS/Linux user path.

## Implementation Shape

### Wrapper layout

Recommended package layout:

```text
bin/
  specrew
  specrew-init
  specrew-start
  specrew-update
  specrew-version
  specrew-review
  specrew-team
  specrew-where
```

Each alias wrapper should either be a tiny script that dispatches to `specrew <subcommand>` or a symlink/copy produced by the installer. The package should prefer real files over symlinks if PSGallery or NuGet packaging proves unreliable with symlink metadata.

### Module-root resolution

The wrapper should resolve the physical script location, following symlinks when available:

```bash
#!/usr/bin/env sh
set -eu

command -v pwsh >/dev/null 2>&1 || {
  echo "Specrew requires PowerShell Core (pwsh) on PATH." >&2
  echo "Install PowerShell Core, then re-run this command." >&2
  exit 127
}

script_path="$0"
while [ -L "$script_path" ]; do
  link_target="$(readlink "$script_path")"
  case "$link_target" in
    /*) script_path="$link_target" ;;
    *) script_path="$(dirname "$script_path")/$link_target" ;;
  esac
done

script_dir="$(cd "$(dirname "$script_path")" && pwd)"
module_root="$(cd "$script_dir/.." && pwd)"

exec pwsh -NoProfile -ExecutionPolicy Bypass -File "$module_root/scripts/specrew.ps1" "$@"
```

This is intentionally conservative: no Bash-only arrays, no GNU-only `readlink -f`, and no shell-specific behavior beyond POSIX `sh` basics.

### Installer command

Add a Specrew command that installs wrappers into a bin directory:

```powershell
specrew install-shell-wrappers [-BinDir <path>] [-Force] [-WhatIf]
```

Default bin directory:

- macOS/Linux: `$HOME/.local/bin`
- Windows: command should explain that shell wrappers are Unix-focused and no-op unless explicitly requested

The installer should:

1. Ensure the bin directory exists or ask/require `-Force` to create it.
2. Copy or symlink wrapper files.
3. Warn if the bin directory is not on `PATH`.
4. Print the exact commands installed.

## Tests

Minimum automated coverage:

- Unit test wrapper generator/installer path decisions in PowerShell.
- Integration test on Ubuntu:
  - create temp bin dir
  - install wrappers into it
  - prepend temp bin to `PATH`
  - run `specrew version`
  - run `specrew start --help`
- Integration test on macOS with the same shape.
- Negative test with `PATH` modified so `pwsh` is unavailable; assert clear error.
- Packaging test: published module artifact includes every wrapper in `FileList`.

## Documentation

Update:

- `README.md`
- `docs/getting-started.md`
- `docs/user-guide.md`
- `docs/troubleshooting.md`

Documentation stance:

- "Specrew is implemented in PowerShell Core today."
- "On macOS/Linux, install the shell wrappers once and use normal shell commands afterward."
- "If wrappers are not installed, PowerShell module commands still work as a fallback."

## Out of Scope

- Rewriting Specrew in Bash, Go, Node, Rust, or another implementation language.
- Removing PowerShell Core as a runtime dependency.
- Homebrew formula, apt package, or npm package distribution. Those are natural follow-ups after wrapper behavior is stable.
- Windows command reshaping beyond keeping existing PowerShell commands working.
- Host-specific AI CLI wrapper behavior; this proposal only wraps Specrew's own commands.

## Risks

- **Argument forwarding bugs**: Shell quoting is easy to get wrong. Mitigation: explicit tests for spaces, quotes, and passthrough flags.
- **Symlink portability**: Different Unix systems resolve symlinks differently. Mitigation: POSIX-compatible loop and CI on Ubuntu/macOS.
- **Package-manager expectations**: PSGallery does not naturally install shell commands into `PATH`. Mitigation: explicit `install-shell-wrappers` command and docs.
- **Stale wrappers after update**: Installed wrappers may point to an older module path. Mitigation: wrappers should be symlinks where safe, or `specrew update` should remind/regenerate wrappers when the module path changes.

## Sequencing

This should ship after the current release-stability fixes that protect lifecycle gates and handoffs:

1. Proposal 151 boundary handoff contract unification.
2. High-priority Proposal 150 safety/boundary-discipline items.
3. This proposal, unless adoption pressure makes Unix first-impression the next highest priority.

The work is independent of deep multi-developer validation and can ship as a focused adoption slice.

## Cross-References

- file:///C:/Dev/Specrew/proposals/031-specrew-distribution-module.md
- file:///C:/Dev/Specrew/proposals/069-multi-host-launch-path.md
- file:///C:/Dev/Specrew/proposals/104-multi-host-onboarding-and-selection-flow.md
- file:///C:/Dev/Specrew/proposals/150-agent-support-hardening-bundle.md
- file:///C:/Dev/Specrew/Specrew.psd1
- file:///C:/Dev/Specrew/scripts/specrew.ps1

## Status History

- 2026-06-01: Drafted after maintainer feedback that Mac/Linux adoption friction is primarily about exposing PowerShell in the normal command surface, not necessarily about PowerShell as an implementation dependency. Captures the wrapper-first approach as a bounded phase-2 adoption feature.
