# Security Surface: Iteration 003

**Schema**: v1
**Reviewed**: 2026-06-03

> Reconciled from the scaffolder default ("none") — this iteration **does** touch supply-chain trust
> boundaries (Homebrew, PowerShell Gallery, the `curl | sh` bootstrap). Recorded here per the security-baseline
> lens; the live provenance paths are exercised at the T024 release gate.

## Trust Boundaries Touched

- **Homebrew (macOS `pwsh` install, T018)** — `install.sh` runs `brew install --cask powershell`. Trust
  anchor: Homebrew is the vendor-recommended macOS PowerShell source; it runs **as the user, never `sudo`**;
  install-only-if-absent (never clobbers an existing `pwsh`). Residual: a compromised user tap/config could
  substitute the cask — the same trust the user already extends to Homebrew; nothing is silently elevated.
- **PowerShell Gallery (module install, T019 / T024)** — `install.sh` runs `Install-Module Specrew`
  (stable, or `-AllowPrerelease`) after `Set-PSRepository -InstallationPolicy Trusted`, scoped to
  `CurrentUser` with `-Force -AllowClobber`. Defense: `verify_specrew_wrapper_surface` fail-closes if the
  freshly installed module lacks `bin/specrew` (a version/source mismatch — e.g. an unexpected old/wrong build).
- **`curl … | sh` bootstrap (the entrypoint itself)** — the ONE trusted `curl | sh` is the Specrew bootstrap
  the user explicitly invokes; `install.sh` never pipes any other untrusted script to a shell (FR-016).
- **Microsoft apt repository (Linux, unchanged from Iteration 2)** — vendor source + verified signing key;
  listed for completeness, no Iteration-3 change.

## Sensitive Data Touchpoints

- none — no secrets, tokens, or PII handled. `--prerelease` is a public-channel selector, not a credential.

## Privilege / Elevation

- **macOS: none** — Homebrew refuses to run as root; the macOS path performs no `sudo`.
- **Linux (unchanged):** surfaced `sudo` via the ratified D11a rules (root → no sudo; tty → surfaced prompt;
  no-tty → fail closed). Never silent.

## Security Specialist Findings

- No dedicated Security Specialist this iteration. The supply-chain surface was reviewed under the
  `security-baseline` lens (hardening-gate.md `security-surface` concern, `Blocking: true`) plus this artifact.
  The macOS Homebrew + `--prerelease` provenance are **new** surfaces vs Iteration 2 — recommend an explicit
  Security Specialist pass at review-signoff if deeper supply-chain scrutiny is wanted.

## Vulnerability Highlights

- No new package manifests changed. Residual risk is the standard supply-chain trust in Homebrew + the
  PowerShell Gallery (vendor sources), bounded by fail-closed behavior + the wrapper-surface mismatch check.
  Live provenance (the published beta actually installing) is exercised at the T024 release gate.
