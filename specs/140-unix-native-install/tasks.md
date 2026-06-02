# Tasks: Unix-Native Install & Command Surface

**Feature**: 140-unix-native-install
**Plan**: [plan.md](./plan.md) | **Spec**: [spec.md](./spec.md)
**Date**: 2026-06-02

Tasks cover the whole feature, tagged by iteration. **Iteration 1 is CLOSED.** The 2026-06-02 auto-install correction (FR-007/FR-016) expands `install.sh` beyond the original ~14 SP Iteration 2, so the feature is **proposed as a 3-iteration split** (a feature-shape change for maintainer decision at plan → tasks): **Iteration 2 (Ubuntu-first auto-install, proven on Ubuntu CI) is the active decomposition**; **Iteration 3 (macOS + remaining distros + docs + release gate) is sketched** (no task table yet) and decomposed in detail when Iteration 2 closes. Every task traces to ≥1 FR/SC; every FR/SC has ≥1 task (see Traceability Matrix).

Effort unit: story points (SP). Iteration cap: 20 SP.

## Iteration 1 — wrappers + generator + parity + installer + FileList (capacity 19/20 SP)

| ID | Task | FR / SC | SP | Owner | Deps |
| --- | --- | --- | --- | --- | --- |
| T001 | Canonical registry reader: parse `Specrew.psd1` `AliasesToExport` + root `specrew` into registry entries (name/kind/entrypoint) | FR-001, FR-009 | 1 | Implementer | — |
| T002 | POSIX `sh` wrapper template: shebang + `set -eu`, `pwsh` presence check (clear error + hint), symlink-resolution loop, module-root resolution, `exec pwsh … scripts/<entrypoint>.ps1 "$@"` | FR-002, FR-003, FR-004, FR-008 | 2 | Implementer | T001 |
| T003 | `scripts/internal/generate-shell-wrappers.ps1` generator: render one wrapper per registry entry; deterministic + idempotent (byte-identical re-run) | FR-009, FR-001 | 3 | Implementer | T001, T002 |
| T004 | Generate + commit the 8 `bin/` wrappers from the generator | FR-001 | 1 | Implementer | T003 |
| T005 | Generator unit tests (Pester): registry parsing, template rendering, idempotency/byte-identical, entrypoint mapping | FR-009 | 2 | Implementer | T003 |
| T006 | Registry ↔ wrapper parity test: `bin/` set == registry; adding an alias without a wrapper fails; removed/renamed alias flagged | FR-009, FR-011, SC-002 | 2 | Reviewer | T004 |
| T007 | `specrew install-shell-wrappers` subcommand: copy committed `bin/` → `-BinDir` (default `~/.local/bin`); `-Force` to create missing dir; `-WhatIf`; idempotent; PATH warn (no profile edit); no out-of-dir mutation; wire into `scripts/specrew.ps1` dispatch; Windows explained no-op | FR-005, FR-006, FR-013 | 4 | Implementer | T004 |
| T008 | Installer unit tests (Pester): path decisions, idempotency, `-Force` gating, `-WhatIf`, PATH-warn, bin-dir confinement | FR-006, SC-004 | 2 | Implementer | T007 |
| T009 | `Specrew.psd1` `FileList` inclusion (8 wrappers + generator + template) + packaging parity test (`bin/` ↔ FileList ↔ artifact) | FR-010, FR-011 | 2 | Reviewer | T004, T007 |

**Iteration 1 SP**: 1+2+3+1+2+2+4+2+2 = **19 / 20**.

## Iteration 2 — install.sh + Ubuntu/Debian auto-install, proven on Ubuntu CI (active; ~19 SP)

Detailed decomposition in `iterations/002/plan.md`. Ubuntu-first because a clean no-`pwsh` container is the cheapest **honest** runtime proof; auto-install is built AND proven in this iteration (no build-now/prove-later deferral on the high-risk surface). **T010 (the piped-`curl`-to-`sh` + `sudo`/no-tty decision) explicitly gates the install flow** per the maintainer instruction.

| ID | Task | FR / SC | SP | Owner | Deps |
| --- | --- | --- | --- | --- | --- |
| T010 | **Decision (gates the flow; no code):** resolve piped `curl`-to-`sh` + `sudo`/no-tty — compare the D11 options (`/dev/tty` re-exec; detect non-tty → download-then-run; passwordless-`sudo`) → choose the safest implementable behavior; record in research D11a (ratify at before-implement) | FR-007, FR-016 | 1 | Implementer | T007 |
| T011 | `install.sh` orchestration (built around the T010 decision): shebang + `set -eu`, shell lint, happy path (detect → ensure pwsh → `Install-Module Specrew` → `install-shell-wrappers`), fail-closed structure, arg surface (`--bin-dir`/`--help`), non-interactive/CI mode | FR-007 | 2 | Implementer | T010 |
| T012 | Platform + package-manager detection framework (`/etc/os-release` ID/VERSION_ID; apt/dnf/brew/snap); **derive the supported-platform + install-command matrix from Microsoft's CURRENT install docs (D11), not memory**; **unsupported → fail closed + manual-docs link**; table-driven os-release fixtures + tests | FR-007, FR-016 | 3 | Implementer | T011 |
| T013 | Ubuntu/Debian pwsh auto-install (Microsoft apt repo + verified signing key + `apt-get install -y powershell`); **install-only-if-absent**; **idempotent repo-add**; non-interactive flags for CI | FR-007, FR-016 | 3 | Implementer | T012 |
| T014 | Implement the **chosen** tty / elevation behavior from T010: detect non-tty stdin, apply the selected resolution, surface the privileged command, never silently elevate | FR-007, FR-016 | 2 | Implementer | T010, T011 |
| T015 | **Ubuntu CI runtime proof** (extend `cross-platform-validation.yml`): clean no-`pwsh` container end-to-end (install.sh → auto-install pwsh → `Install-Module` → `install-shell-wrappers` → `specrew version`/`start --help`) + Ubuntu wrapper runtime suite (forwarding spaces/quotes/`--`/empty, symlink resolution, pwsh-missing negative, unknown-option passthrough) + shellcheck gate | FR-012, FR-002, FR-003, FR-004, FR-008, FR-007, SC-001, SC-003, SC-007 | 4 | Reviewer | T011, T012, T013, T014 |
| T016 | Parity-cascade CI job: regenerate + `git diff --exit-code`; registry↔`bin/`↔`FileList` arm; name the cascade on failure (docs arm → Iter 3) | FR-011, FR-009 | 2 | Reviewer | T006, T009 |
| T017 | Security lens evidence for the auto-install surface: supply-chain provenance (MS repo + verified key trust), surfaced elevation, fail-closed, install-if-absent, idempotent repo-add, **no untrusted `curl`-piped-to-`bash` beyond the trusted Specrew bootstrap** | FR-016 | 2 | Reviewer | T012, T013, T014 |

**Iteration 2 SP**: 1+2+3+3+2+4+2+2 = **19 / 20** (Ubuntu auto-install + wrapper runtime proven in-iteration; T010 decision gates the flow).

## Iteration 3 — macOS + remaining distros + prerelease install + docs + release gate (SKETCH; ~14-18 SP; not yet decomposed)

Decomposed in detail when Iteration 2 closes (no task table yet, per the planning boundary). Sketch scope:

- macOS/Homebrew `pwsh` auto-install + remaining MS-supported distros (e.g. RHEL/Fedora via the MS dnf repo), each proven on its surface — macOS lacks a clean no-`pwsh` CI env, so **manual proof** is budgeted. (FR-007, FR-016, FR-012 macOS, SC-007 macOS)
- macOS wrapper runtime lane: forwarding / symlink / pwsh-missing / passthrough. (FR-002/003/004/008 macOS, SC-001/SC-003 macOS)
- Docs-example parity arm of the cascade. (FR-011 docs arm)
- Native-first docs (`README.md`, `docs/getting-started.md`, `docs/user-guide.md`, `docs/troubleshooting.md`): bash/zsh-first, pwsh as internal dependency, unsupported/manual fallback documented. (FR-014, SC-005)
- **`install.sh --prerelease` (FR-017)**: install Specrew **beta** from PSGallery (`Install-Module -AllowPrerelease` / PSResourceGet `-Prerelease` equivalent); `--help` + installer output state stable vs prerelease; version/source mismatch (installed module lacks the `specrew` wrapper command) → **fail closed** non-zero with an incompatibility message. Built AND proven here — a published beta exists at the release-gate moment, so the prerelease install + the mismatch check are exercised for real. (FR-017, SC-008)
- Greenfield + brownfield installed validation (release gate; covers bundled Spec Kit 0.9.0), exercised via the **shell-native prerelease flow** `curl … | sh -s -- --prerelease` → `specrew version` / `specrew init` / `specrew start`; **no beta/stable publish without explicit maintainer authorization**. (FR-015, SC-006)

Feature total ≈ **51-55 SP** across 3 iterations (each ≤ 20) — pending maintainer approval of the split.

## Traceability Matrix

| FR / SC | Covered by |
| --- | --- |
| FR-001 | T001, T003, T004 |
| FR-002 | T002, T015 (Ubuntu); Iter 3 (macOS) |
| FR-003 | T002, T015 (Ubuntu); Iter 3 (macOS) |
| FR-004 | T002, T015 (Ubuntu); Iter 3 (macOS) |
| FR-005 | T007 |
| FR-006 | T007, T008 |
| FR-007 | T010, T011, T012, T013, T014, T015 (Ubuntu auto-install); Iter 3 (macOS/other distros) |
| FR-008 | T002, T015 (Ubuntu); Iter 3 (macOS) |
| FR-009 | T003, T005, T006, T016 |
| FR-010 | T009 |
| FR-011 | T006, T009, T016 (registry↔bin↔FileList arm); Iter 3 (docs arm) |
| FR-012 | T015 (Ubuntu); Iter 3 (macOS) |
| FR-013 | T007 |
| FR-014 | Iter 3 |
| FR-015 | Iter 3 |
| FR-016 | T010, T012, T013, T014, T017 |
| FR-017 | Iter 3 (`--prerelease` built + proven with the release gate) |
| SC-001 | T015 (Ubuntu); Iter 3 (macOS) |
| SC-002 | T006 |
| SC-003 | T015 (Ubuntu); Iter 3 (macOS) |
| SC-004 | T008 |
| SC-005 | Iter 3 |
| SC-006 | Iter 3 |
| SC-007 | T015 (Ubuntu auto-install); Iter 3 (macOS) |
| SC-008 | Iter 3 (`install.sh --prerelease` proven at the release gate) |

Every task maps to ≥1 FR/SC; every FR/SC maps to ≥1 task (Iteration 3 coverage is sketched pending its decomposition).
