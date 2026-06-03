---
proposal: 158
title: Native Uninstall Surface for macOS/Linux
status: candidate
phase: phase-2
estimated-sp: 3-5
discussion: surfaced 2026-06-03 after Feature 140 made install native on macOS/Linux (`install.sh` + shell wrappers), but uninstall guidance still requires PowerShell commands and does not clean native wrapper symlinks.
---

# Native Uninstall Surface for macOS/Linux

## Why

Feature 140 made first install feel native on macOS/Linux:

```sh
curl -fsSL https://raw.githubusercontent.com/alonf/specrew/main/install.sh | sh
```

The user no longer has to know that Specrew is packaged as a PowerShell module.
`install.sh` installs PowerShell Core as an internal dependency when needed,
installs the Specrew module, and creates native `specrew` shell wrappers.

Uninstall is not symmetrical. The current documented cleanup path is still
PowerShell-centric:

```powershell
Get-Module Specrew | Remove-Module -Force
Uninstall-Module Specrew -AllVersions -Force
```

That is technically correct for the module, but it is not a complete native
uninstall story:

- A macOS/Linux user who installed with `install.sh` may not know they must run
  `pwsh -NoProfile -Command ...` from their login shell.
- Removing the module does not remove the shell wrapper symlinks that were
  installed into `~/.local/bin` or a custom `--bin-dir`.
- The native wrappers may remain on `PATH` and then fail later with confusing
  "module not found" errors.
- Users may reasonably ask whether uninstall should also remove PowerShell,
  Homebrew packages, apt repository entries, `uv`, Node, GitHub CLI, or host
  CLIs. The answer should be explicit and conservative.

The install path now hides PowerShell as an implementation detail. The uninstall
path should do the same.

## What

Add a native macOS/Linux uninstall surface:

```sh
curl -fsSL https://raw.githubusercontent.com/alonf/specrew/main/uninstall.sh | sh
```

Also add a module command for the wrapper-only cleanup case:

```sh
specrew uninstall-shell-wrappers
```

The script is the reliable public entrypoint because it still works when the
module command is broken, not imported, or already partially removed. The module
command is useful for repair/update scenarios while Specrew is still installed.

## Requirements

### `uninstall.sh`

Add a POSIX `sh` script at repo root, published next to `install.sh`.

Required behavior:

1. **Native shell entrypoint** — runnable from bash/zsh/sh. Users do not need to
   start an interactive PowerShell session.
2. **Default scope** — remove only Specrew's current-user install surfaces:
   - shell wrapper symlinks from the target bin directory
   - installed Specrew PowerShell module versions in the current user's module path
   - Specrew install/version cache files, if any are created by Specrew itself
3. **Default bin directory** — same as install: `$HOME/.local/bin`.
4. **Custom bin directory** — support `--bin-dir <dir>` and `--bin-dir=<dir>` so
   uninstall mirrors install.
5. **Confirmation** — prompt before destructive action when stdin is a TTY.
   Support `--yes` / `-y` for non-interactive uninstall.
6. **Dry run** — support `--dry-run` / `--whatif` that reports exactly what would
   be removed.
7. **Partial success clarity** — if wrapper cleanup succeeds but module removal
   fails, or the reverse, print a clear summary and non-zero exit code.
8. **PowerShell invocation** — when removing the module, invoke:

   ```sh
   pwsh -NoProfile -NonInteractive -Command "Get-Module Specrew | Remove-Module -Force -ErrorAction SilentlyContinue; Uninstall-Module Specrew -AllVersions -Force"
   ```

   The final implementation may use a safer encoded/script-file form to avoid
   quoting bugs.
9. **Missing `pwsh` behavior** — if `pwsh` is missing, remove wrappers and report
   that module removal could not be verified. Do not try to reinstall PowerShell
   just to uninstall Specrew.
10. **No project cleanup by default** — do not remove `.specrew/`, `.specify/`,
    `.squad/`, `.claude/`, `.github/skills/`, `.agents/skills/`, `specs/`, or
    user project artifacts.
11. **No shared dependency removal by default** — do not remove PowerShell, Git,
    `uv`, Node/npm, GitHub CLI, Copilot, Claude, Cursor, Codex, Antigravity, or
    Homebrew/apt repository configuration.

### Wrapper cleanup safety

The uninstall script and `specrew uninstall-shell-wrappers` must be conservative:

- Remove known Specrew wrapper names from the requested bin directory:
  `specrew`, `specrew-init`, `specrew-review`, `specrew-start`, `specrew-team`,
  `specrew-update`, `specrew-version`, `specrew-where`, and any future names
  generated from the canonical command registry.
- Remove a target automatically only when it is a symlink and either:
  - it points into an installed Specrew module `bin/` directory, or
  - its target no longer exists but the link name is a known Specrew wrapper.
- Do **not** remove a non-symlink regular file by default, even if its filename
  is `specrew`.
- Support `--force` for the rare case where the user intentionally wants to
  remove non-symlink known wrapper files created by a broken/old install.
- Never delete outside the requested bin directory.

### `specrew uninstall-shell-wrappers`

Add a Specrew command implemented in PowerShell, analogous to
`specrew install-shell-wrappers`.

Required behavior:

- macOS/Linux only; Windows prints a no-op explanation.
- Same `--bin-dir`, `--dry-run` / `--whatif`, and `--force` flags as the script.
- Uses the canonical command registry or module `bin/` surface to determine
  wrapper names, so command-surface changes do not require hand-maintained
  uninstall lists.
- Does not uninstall the PowerShell module.
- Does not edit shell profile files or `PATH`.

## CLI Shape

Recommended script flags:

```text
uninstall.sh [options]

Options:
  --bin-dir <dir>       Wrapper directory to clean (default: ~/.local/bin)
  --yes, -y             Do not prompt before uninstall
  --dry-run, --whatif   Show what would be removed
  --wrappers-only       Remove shell wrappers only
  --module-only         Remove Specrew PowerShell module only
  --force               Also remove known non-symlink wrapper files in bin dir
  --help                Show usage
```

Recommended Specrew command flags:

```text
specrew uninstall-shell-wrappers [options]

Options:
  --bin-dir <dir>       Wrapper directory to clean (default: ~/.local/bin)
  --dry-run, --whatif   Show what would be removed
  --force               Also remove known non-symlink wrapper files in bin dir
  --help                Show usage
```

## Non-goals

- Do not uninstall PowerShell by default. It may be shared by unrelated tools.
- Do not remove Homebrew packages or apt repository entries by default.
- Do not remove Git, `uv`, Node/npm, GitHub CLI, or AI host CLIs.
- Do not remove project artifacts or generated lifecycle evidence.
- Do not add a Windows native uninstall script in this proposal. Windows already
  has a natural PowerShell-native uninstall path; docs should still clarify it.
- Do not make uninstall part of `specrew update`. This is a user-initiated
  destructive action.

Future optional extension: a clearly dangerous `--remove-pwsh` flag or separate
manual instructions for removing PowerShell when the user knows it was installed
only for Specrew. That should remain explicit and opt-in.

## Documentation

Update:

- `README.md` quick-start notes: add a short uninstall pointer near install.
- `docs/getting-started.md`: add macOS/Linux native uninstall instructions below
  install/update, before prerelease advanced flows.
- `docs/troubleshooting.md`: replace PowerShell-only clean-baseline guidance with
  OS-specific uninstall guidance.

Documentation must state exactly what uninstall does and does not remove.

## Tests / Validation

Add focused tests:

- `uninstall.sh --dry-run` reports wrapper and module actions without deleting.
- `uninstall.sh --wrappers-only --bin-dir <temp>` removes only known Specrew
  symlinks in that temp bin directory.
- Non-symlink `specrew` file is preserved by default.
- `--force` removes a known non-symlink wrapper file in the requested bin dir.
- Missing `pwsh` path: wrappers still clean up; module removal reports a clear
  skipped/failed state.
- `specrew uninstall-shell-wrappers --dry-run` mirrors the script wrapper plan.
- Wrapper name list stays in parity with the canonical command registry.

CI coverage should include Ubuntu at minimum. macOS coverage is preferred because
Feature 140 already runs wrapper runtime validation on both Ubuntu and macOS.

## Acceptance

- A macOS/Linux user who installed with `install.sh` can uninstall with one shell
  command and no interactive `pwsh` session.
- After uninstall, `command -v specrew` no longer resolves from the target wrapper
  directory unless another independent Specrew install remains elsewhere on PATH.
- All installed Specrew module versions are removed when `pwsh` is available.
- Uninstall never removes shared dependencies or project artifacts by default.
- Docs no longer imply PowerShell-only cleanup for macOS/Linux native installs.

## Sizing

Estimated: 3-5 SP.

Likely implementation split:

1. `specrew uninstall-shell-wrappers` command + wrapper-name parity test.
2. `uninstall.sh` with dry-run/yes/bin-dir/wrappers-only/module-only.
3. Docs + Ubuntu/macOS validation.

## Composes with

- Proposal 153 / Feature 140 — Unix-native wrapper commands and `install.sh`.
- Proposal 031 — PowerShell Gallery module distribution.
- Proposal 067 — small-fix slice type; this is likely small enough to ship as a
  focused hardening slice.
- Proposal 152 — small-fix hardening carveouts.

## Risks

- **Accidental deletion of user files named `specrew`:** mitigated by removing
  symlinks only by default and requiring `--force` for non-symlink wrapper files.
- **Broken quoting across sh → pwsh:** mitigate by using a script block/file or
  encoded command and testing on Ubuntu + macOS.
- **Dependency ownership ambiguity:** mitigate by never removing PowerShell or
  other shared dependencies by default.
- **PATH ambiguity:** another `specrew` may exist elsewhere on PATH. The script
  should report the target bin dir it cleaned and, if possible, whether another
  `specrew` still resolves after cleanup.
