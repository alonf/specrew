# Security Baseline Lens — Iteration 002 (auto-install surface)

**Lens**: `security-baseline@v1.0.0`
**Reviewed By**: Crew Reviewer (auto-install/supply-chain focus per maintainer instruction)
**Subject**: `install.sh` (T011–T014) — the new load-bearing trust surface: it adds a package
repository, imports a signing key, and elevates to root.
**Verdict**: `pass` — design-level controls verified AND **runtime-recorded** (Ubuntu CI run 26812981387,
all feature140 jobs green: a clean no-pwsh `ubuntu:24.04` container installed pwsh 7.6.2 from the Microsoft
apt repo end-to-end via the root path, using branch code; detection fail-closed 5/5).

## Surfaces reviewed

### 1. Supply-chain provenance (FR-016)

- PowerShell is installed **only** from the vendor source: the Microsoft package repository
  (`packages.microsoft.com/config/<distro>/<version>/packages-microsoft-prod.deb`), which registers
  Microsoft's signing key + apt source; the package is then installed via `apt-get` (signature-verified
  by apt against the imported key). This matches Microsoft's current official install doc.
- The **only** `curl|sh`-style trust the installer asks for is the Specrew bootstrap the user explicitly
  invoked. `install.sh` does **not** pipe any third-party script to a shell — there is no
  `curl … | bash` of an unofficial PowerShell installer. ✔
- The Specrew module is installed from the PowerShell Gallery (`Install-Module`), or skipped entirely if a
  module is already present (the CI local-module path) — no alternate/untrusted module source. ✔

### 2. Privilege / elevation (FR-016; ratified D11a)

- Elevation is **surfaced, never silent**: `resolve_privilege` runs `sudo` through the normal prompt
  (the user sees the password prompt and the privileged `apt-get`), or proceeds without `sudo` only when
  already root. ✔
- **Never silently elevates** and **never consumes the script body from stdin**: the script performs no
  `read` from stdin in the piped path; `sudo` uses its own `/dev/tty`. When there is no usable tty and no
  passwordless sudo and not root, it **fails closed** with download-then-run guidance rather than hanging
  or forcing elevation. ✔
- Passwordless sudo is **not** required as the primary path (only honored if already configured). ✔
- Root-without-`sudo` (container) is handled by `run_privileged` (no dependency on a `sudo` binary that a
  minimal container lacks). ✔

### 3. Fail-closed behavior (FR-007/FR-016)

- Unsupported OS (macOS / non-Linux), unsupported distro (not Ubuntu/Debian), unreadable/incomplete
  os-release, a missing PMC `.deb` (404 = unpublished/unsupported version), a failed module install, or a
  failed wrapper install all route through `fail_closed`, which prints the reason + the manual
  PowerShell-install docs link and exits non-zero. **No partial install is reported as success.** ✔
- Detection runs **before** any mutation (no repo/key changes happen for an unsupported target). ✔

## Residual / out-of-scope

- macOS (Homebrew) + non-Ubuntu/Debian distros are **fail-closed** in this iteration (Iteration 3 scope) —
  not a vulnerability, an explicit boundary.
- The interactive-`sudo`-password path cannot be exercised by CI (needs a human); it is acknowledged as
  manual proof. The root path and the no-tty fail-closed path **are** CI-proven (T015).

## Evidence

- Code: `install.sh` (`resolve_privilege`, `run_privileged`, `install_pwsh_apt`, `ensure_specrew_module`,
  `detect_platform`, `fail_closed`).
- Runtime: Ubuntu CI `feature140-install-bootstrap` (clean no-pwsh container, root path, end-to-end) +
  `install-sh-detect.sh` (fail-closed table) — **runtime-recorded: CI run 26812981387 green** (log shows
  `pwsh not found -> Installing from the Microsoft package repository -> PowerShell Core installed (7.6.2)
  -> module already available (skip gallery) -> Installed 8 wrappers -> /usr/bin/pwsh + /usr/local/bin/specrew`).
