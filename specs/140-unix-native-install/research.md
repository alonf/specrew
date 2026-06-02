# Research: Unix-Native Install & Command Surface

**Feature**: 140-unix-native-install
**Phase**: 0 (Outline & Research)
**Date**: 2026-06-02

Most unknowns were resolved at `/speckit.clarify` (Session 2026-06-02). This records the decisions, rationale, and alternatives considered.

## D1 — Wrapper source of truth: generate-then-commit

- **Decision**: A PowerShell generator reads the canonical registry and renders the `bin/` wrapper files from a single POSIX-sh template. The generated wrappers are committed; CI regenerates and diffs to detect drift.
- **Rationale**: Single source of truth (no hand-maintained 8 files), real reviewable files ship in `FileList` (satisfies FR-010 literally), and CI drift-diff prevents registry↔wrapper divergence.
- **Alternatives**: (a) generate-only at install time — rejected: nothing reviewable in-repo, ambiguous `FileList`; (b) hand-authored static + name-only parity — rejected: content drift across 8 files.

## D2 — Bootstrap: repo-committed `install.sh` via `curl | sh`

- **Decision**: A committed `install.sh` users run shell-natively. *(Superseded 2026-06-02 on the `pwsh` step — see D11. Original: "verify `pwsh` → `Install-Module Specrew` → `install-shell-wrappers`." Now: auto-install `pwsh` when absent, then `Install-Module` → `install-shell-wrappers`. The `curl | sh` delivery + module-first ordering are unchanged.)*
- **Rationale**: Shell-native first impression; resolves the bootstrap-before-wrappers ordering (module first, then wrappers).
- **Alternatives**: documented one-liner (less shell-native); module-shipped bootstrap (worse first-install ergonomics).

## D3 — Install safety: `-Force` to create, warn-only on PATH

- **Decision**: `install-shell-wrappers` never silently creates a missing bin dir (requires `-Force`); when the bin dir is not on `PATH`, it warns with a hint and does **not** modify shell profiles. `-WhatIf` dry-run; no mutation outside the requested bin dir.
- **Rationale**: Least-surprise; no unexpected filesystem or shell-profile mutation.

## D4 — POSIX portability

- **Decision**: Wrappers target POSIX `sh` only — no Bash arrays, no GNU `readlink -f`; a manual symlink-resolution loop (per Proposal 153's reference block). `#!/usr/bin/env sh` + `set -eu`.
- **Rationale**: Works across macOS (BSD userland) + Linux (GNU userland) + minimal shells.

## D5 — Module-root resolution

- **Decision**: Resolve the physical script location by following symlinks in a loop, then `module_root = <script_dir>/..`, then `exec pwsh -NoProfile -ExecutionPolicy Bypass -File "$module_root/scripts/<entrypoint>.ps1" "$@"`.
- **Rationale**: A wrapper symlinked into `~/.local/bin` must still locate the installed module (FR-003).

## D6 — PSGallery packaging of shell files

- **Decision**: Ship the wrappers + `install.sh` as **real files** listed in `Specrew.psd1` `FileList`; do not rely on symlink metadata surviving PSGallery/NuGet packaging. A packaging parity test asserts every wrapper is present in the published artifact.
- **Rationale**: Proposal 153 risk — symlink metadata is unreliable in package managers; real files are safe.

## D7 — Canonical registry = `AliasesToExport` (8) + root `specrew`

- **Decision**: Wrappers are generated from `Specrew.psd1` `AliasesToExport` (`specrew-init`, `-start`, `-update`, `-version`, `-review`, `-team`, `-where`) plus the root `specrew`. v2 = Proposal 150's command manifest when it exists.
- **Finding**: `scripts/` contains additional entrypoints (`specrew-config.ps1`, `specrew-host.ps1`) that are **not** exported aliases — they are subcommands of the root `specrew`. Wrappers MUST be driven by the alias registry, not the `scripts/specrew-*.ps1` file set, so `config`/`host` get no standalone wrapper.
- **Decision**: `specrew install-shell-wrappers` is a **subcommand of the root `specrew`** (dispatched by `scripts/specrew.ps1`), not a new exported alias — so it adds no new wrapper file, but it is a command-surface change that triggers the parity cascade.

## D8 — CI-first verification (authoritative surface)

- **Decision**: The authoritative verification surface for all Unix-runtime requirements (FR-001..FR-008) is the **Ubuntu + macOS CI lanes** (`.github/workflows/cross-platform-validation.yml`). Git Bash on Windows is a fast local proxy only and is NOT sufficient to call a Unix-runtime requirement done.
- **Rationale**: Development happens on Windows; Git Bash diverges from real macOS/Linux exactly on quoting, symlink resolution, and `readlink` — the behaviors FR-002/003/004 exercise.

## D9 — Capacity: 2-iteration split

- **Estimate**: rough breakdown is ~24-29 SP (generator + template + install-shell-wrappers + install.sh + FileList/packaging + parity + Ubuntu/macOS CI + docs + unit tests + greenfield/brownfield installed validation), exceeding the 20 SP cap; the cross-platform CI/install-validation surface is large and runtime-risky.
- **Decision (per maintainer instruction)**: split into two iterations along the defined boundary —
  - **Iteration 1**: wrappers + generator + registry↔wrapper parity + `install-shell-wrappers` + `FileList`/package inclusion (platform-agnostic, unit-testable core).
  - **Iteration 2**: `install.sh` + docs + Ubuntu/macOS CI runtime lanes + greenfield/brownfield installed validation (cross-platform runtime proof + release gate).
- Exact per-task SP confirmed at `/speckit.tasks` + capacity.

## D10 — Release gate (carry-forward)

- **Decision**: Release is gated by installing Specrew (prerelease) and exercising BOTH greenfield and brownfield on a real Unix host (covering the bundled Spec Kit 0.9.0 support). No beta/stable publish without explicit maintainer authorization. Planning includes the gate; publishing remains a separate authorized action.

## D11 — `install.sh` auto-installs PowerShell Core as a dependency (2026-06-02 correction)

- **Decision**: When `pwsh` is absent, `install.sh` auto-installs PowerShell Core from the **vendor-recommended source** for the detected platform, then proceeds (`Install-Module Specrew` → `install-shell-wrappers`). Detect platform via `/etc/os-release` (`ID`/`VERSION_ID`) on Linux and `uname` on macOS; map to the package manager (apt/dnf/brew/snap). **Primary platform (Iteration 2): Ubuntu/Debian via the Microsoft apt repo** (`packages.microsoft.com`) with its verified signing key. Iteration 3 adds macOS (Homebrew) + remaining Microsoft-supported distros (e.g. RHEL/Fedora via the MS dnf repo).
- **Derive, don't recite — the support matrix is a build-time artifact**: the set of platforms with an official Microsoft PowerShell install method drifts. It MUST be built from Microsoft's **current** official install docs at implement time, NOT hardcoded from memory. **Fail-closed discriminator**: an official MS method exists for the detected platform → support it; otherwise → clear failure + a link to manual dependency-install docs. No cleverness about exotic distros.
- **Trust model (FR-016)**: the ONE trusted `curl | sh` is the Specrew bootstrap the user explicitly invoked. `pwsh` itself comes from the OS package manager + Microsoft's **signed** repository (apt/dnf verify package signatures against the imported, trusted key) — vendor-recommended, **never** an ad-hoc `curl | bash` of an unofficial script. **Install-only-if-absent** (prefer an existing working `pwsh`; never clobber/upgrade silently). **Idempotent repo-add** (re-running adds no duplicate source). The repo-key import step is itself a trust decision and is reviewed by the security lens.
- **Elevation / `curl | sh` tty risk (design risk, resolve at implement)**: piping the script to `sh` puts the *script* on stdin, so an interactive `sudo` password prompt or a confirmation `read` has **no controlling tty**. CI sidesteps this (root-in-container, non-interactive `apt`), but the real-user piped path does not. Resolution options to pick at implement: (a) re-exec the elevation against `/dev/tty`; (b) detect a non-tty stdin and instruct the user to download-then-run for the privileged step; or (c) document a passwordless-`sudo` expectation. Elevation MUST be surfaced (the exact privileged command shown), never silent.
- **Iteration split rationale**: Ubuntu/Debian (apt) is the cheapest **honest** proof — a clean container with no `pwsh` runs `install.sh` end-to-end in CI. macOS runners cannot provide a clean no-`pwsh` environment and the interactive-`sudo` path is not CI-reachable, so the Homebrew + interactive paths ride Iteration 3 where **manual proof** is budgeted. This keeps each iteration's runtime claim honest (no "CI-validated" label on a path CI never ran).
- **Alternatives**: (a) bundle/vendor a `pwsh` binary in Specrew — rejected: licensing, size, and update burden vs. the OS package manager; (b) snap-only — rejected: not universal, needs `snapd`; (c) generic `curl | bash` from an unofficial PowerShell installer — rejected: violates FR-016 provenance.

## D11a — piped `curl | sh` + `sudo`/no-tty elevation: RATIFIED resolution (T010, 2026-06-02)

This is the explicit, flow-gating decision the maintainer required to be settled before writing the install flow. **RATIFIED by the maintainer 2026-06-02** (the binding rules are restated at the end of this section); the behavior is verified empirically on Ubuntu CI (T015) before the hardening-gate Blocking concerns can close.

- **Problem**: `curl -fsSL <url> | sh` feeds the *script* to `sh` on **stdin**, so stdin is not the terminal. `sudo` reads its password from the controlling terminal (`/dev/tty`), not stdin — so it *can* still prompt when a controlling tty exists, but (1) any script-level `read` would consume the script text, not user input, and (2) with **no** controlling tty (CI without root, detached shells) an interactive prompt hangs or fails.
- **Options weighed (from D11)**: (a) re-exec interactive prompts against `/dev/tty` when stdin is not a tty but `/dev/tty` is openable — keeps the one-liner UX in an interactive terminal; (b) detect non-usable-tty → print the exact safe download-then-run commands and exit (never hang); (c) documented passwordless-`sudo` — fragile, poor UX, rejected as the primary path.
- **Recommended (safest implementable) — hybrid (a)+(b)**:
  1. Running as root (the CI clean-container path): no elevation needed — proceed.
  2. Else a controlling tty is available: use it for the normal `sudo` prompt (surfaced — the user sees the exact `sudo apt-get …` command); redirect any script `read` from `/dev/tty`.
  3. Else (no tty, not root): **fail closed** with a clear message + the exact download-then-run commands + the manual-dependency-docs link. Never silently elevate; never hang.
- **Why**: preserves the `curl | sh` UX in the common interactive-terminal case, keeps elevation surfaced (FR-016), and fails closed in non-interactive contexts — avoiding (c)'s fragile requirement. The exact tty behavior is verified on the real Ubuntu CI during T015.

**Ratified rules (binding — maintainer, 2026-06-02):**

1. **Running as root**: proceed without `sudo` (this is the CI/container path; `$SUDO` resolves to empty).
2. **Not root, usable controlling tty exists**: keep the one-liner UX with normal **surfaced** `sudo` behavior; any script-level interactive read is taken from `/dev/tty` (never from stdin).
3. **Not root, no usable tty**: **fail closed** — do not hang; print the exact download-then-run commands plus the manual-docs link.
4. Do **not** require passwordless `sudo` as the primary path.
5. **Never** silently elevate.
6. **Never** consume the script body from stdin by prompting through stdin (so `sudo` relies on its own `/dev/tty`; the script performs no `read` from stdin in the piped path).
7. The implementation must **prove this empirically in Ubuntu CI (T015)** before the hardening-gate Blocking concerns can close (root path + the fail-closed path are CI-provable; the interactive-`sudo`-password path needs a human and is acknowledged as manual).

## D12 — macOS manual-smoke evidence (Iteration 3 planning input, 2026-06-02)

A macOS tester ran a real-host manual smoke and hit setup friction on the **manual `Install-Module`** path
(zsh `command not found`; PSGallery untrusted prompt defaulting to `N`), plus `specrew init` dependency
issues (`nvm` shadowing Homebrew Node; an old Spec Kit `0.0.22`). The decisive finding: the tester did
**not** use `install.sh` (which already sets PSGallery `Trusted` + `Install-Module -Force -NonInteractive`
and `fail_closed`s) — so the evidence validates the native-first thesis (US2/FR-007/FR-014) and the macOS
work is path-priority docs + a macOS proof, while the Node/Spec Kit findings are `specrew init`
dependency-diagnostic concerns needing new/extended requirements. Full evidence, the six maintainer-stated
Iteration-3 requirements, the FR-coverage mapping, proposed scope additions (FR-014 extension, new FR-018
`nvm`-shadowing diagnostics, FR-019/Spec-Kit-UX), and the macOS smoke scenarios are captured in
[iterations/003/macos-smoke-evidence.md](iterations/003/macos-smoke-evidence.md). **Proposed scope changes
there await maintainer approval before they touch `spec.md` or an Iteration 3 `plan.md`.**
