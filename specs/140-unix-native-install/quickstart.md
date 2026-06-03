# Quickstart: Unix-Native Install & Command Surface

**Feature**: 140-unix-native-install
**Last verified**: planning (pre-implementation — runtime steps confirmed on Ubuntu/macOS CI during implementation)

## Run it (developer, from the repo)

```sh
pwsh -File scripts/internal/generate-shell-wrappers.ps1   # (re)generate bin/ wrappers
pwsh -File tests/unit/shell-wrapper-generator.tests.ps1   # generator unit tests
pwsh -File tests/unit/install-shell-wrappers.tests.ps1    # installer unit tests
pwsh -File tests/unit/wrapper-registry-parity.tests.ps1   # registry <-> bin <-> FileList parity
```

Cross-platform runtime is exercised by `.github/workflows/cross-platform-validation.yml` on Ubuntu + macOS (the authoritative surface).

## Try the canonical scenario (end user, macOS/Linux)

1. Bootstrap: `curl -fsSL <install.sh-url> | sh` — verifies `pwsh`, runs `Install-Module Specrew`, installs wrappers to `~/.local/bin`. Expected: a list of installed commands and a `PATH` hint if `~/.local/bin` is not on `PATH`.
2. `specrew version` — prints the module version (identical to the PowerShell command). Expected exit 0.
3. `specrew start --help` — renders help. Expected exit 0.

## Or, when the module is already installed

1. `specrew install-shell-wrappers -BinDir ~/.local/bin` — wrappers appear; re-running is idempotent (no duplication).
2. `specrew install-shell-wrappers -WhatIf` — reports what it would do; changes nothing.

## Verify the edge cases

- **pwsh missing**: `env -i PATH=/usr/bin specrew version` → non-zero exit + `PowerShell Core (pwsh) is required` + install hint.
- **Spaces/quotes**: `specrew where "My Project"` → the argument reaches the PowerShell command unchanged.
- **Symlink resolution**: `ln -s ~/.local/bin/specrew /tmp/sx && /tmp/sx version` → resolves the real module root and works.
- **Missing bin dir without `-Force`**: `specrew install-shell-wrappers -BinDir /tmp/does-not-exist` → refuses to create it without `-Force`.
