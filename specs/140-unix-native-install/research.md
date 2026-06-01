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

- **Decision**: A committed `install.sh` users run shell-natively: verify `pwsh` → `Install-Module Specrew` (via pwsh) → `specrew install-shell-wrappers`.
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
