# Tasks: Unix-Native Install & Command Surface

**Feature**: 140-unix-native-install
**Plan**: [plan.md](./plan.md) | **Spec**: [spec.md](./spec.md)
**Date**: 2026-06-02

Tasks cover the whole feature, tagged by iteration. **Iterations 1 and 2 are CLOSED.** The 2026-06-02 auto-install correction (FR-007/FR-016) expanded `install.sh` beyond the original ~14 SP Iteration 2, so the feature is a **maintainer-approved 3-iteration split**: **Iteration 1** (wrappers + generator + parity + installer + FileList) and **Iteration 2** (Ubuntu-first auto-install, proven on Ubuntu CI) are closed; **Iteration 3 (macOS + `--prerelease` + docs + release gate) is decomposed below** (T018-T024, maintainer-approved 2026-06-02). The macOS-smoke FR fold (FR-014 extended; FR-018/FR-019 carved-out) is reflected. Every task traces to ≥1 FR/SC; every FR/SC has ≥1 task or an explicit carve-out/deferral (see Traceability Matrix).

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

## Iteration 3 — macOS + prerelease install + docs + release gate (decomposed; 19/20 SP; maintainer-approved 2026-06-02)

Detailed decomposition in `iterations/003/plan.md`. macOS auto-install + interactive elevation + the release-gate beta install are **manual proofs** (no clean no-`pwsh` macOS runner); the macOS wrapper runtime is **CI-proven** via the extended `validate-macos` job.

| ID | Task | FR / SC | SP | Owner | Deps |
| --- | --- | --- | --- | --- | --- |
| T018 | macOS Homebrew `pwsh` auto-install: replace the `install.sh` Darwin fail-closed stub with `brew install --cask powershell`; **install-only-if-absent**; **`brew` as the user, never `sudo brew`**; idempotent; **Homebrew absent → fail closed + manual-docs**; derive the command from MS's CURRENT macOS install docs | FR-007, FR-016 | 3 | Implementer | T014 (Iter 2 flow) |
| T019 | `install.sh --prerelease`: `-AllowPrerelease` install; `--help` + output state stable vs prerelease; installed-module-lacks-`specrew`-surface mismatch → **fail closed** | FR-017, SC-008 | 2 | Implementer | T018 |
| T020 | Extend the `validate-macos` CI job with the **macOS wrapper runtime suite** (forwarding/symlink/pwsh-missing/passthrough) + `install-shell-wrappers` → PATH → `specrew version`/`start --help` | FR-012, FR-002, FR-003, FR-004, FR-008, SC-001, SC-003 | 3 | Reviewer | T015 (Iter 2 CI) |
| T021 | macOS **manual-proof** evidence on a real host (clean `install.sh` Homebrew auto-install, surfaced + idempotent; `specrew version`/`init`/`start`); capture the Node/`nvm` + old-Spec-Kit prerequisite conditions; extends `macos-smoke-evidence.md` | FR-007, FR-016, SC-007 | 3 | Reviewer | T018, T019 |
| T022 | Native-first docs (`README.md`, `docs/getting-started.md`, `docs/user-guide.md`, `docs/troubleshooting.md`): `install.sh`/`curl`-to-`sh` first; demote manual `Install-Module` (PSGallery default-`N` note); pwsh internal-only; **troubleshooting documents** the macOS `nvm`-shadowing Node + verify `node -v` in `pwsh` + Spec Kit old-version remediation | FR-014, SC-005 | 3 | Spec Steward | — |
| T023 | Parity cascade **docs arm**: check doc command examples against the registry (or allowlist); failure names the FULL cascade (registry → wrappers → installer → FileList → docs) | FR-011, FR-009 | 2 | Reviewer | T016 (Iter 2 cascade), T022 |
| T024 | **Release gate (beta-before-stable):** maintainer-authorized beta publish → install the published beta on a real macOS host via `curl`-to-`sh` with `-s -- --prerelease` → greenfield + brownfield (`version`/`init`/`start`) validating bundled **Spec Kit 0.9.0**; **no publish without explicit maintainer authorization** | FR-015, FR-017, SC-006, SC-008 | 3 | Reviewer | T018, T019 |

**Iteration 3 SP**: 3+2+3+3+3+2+3 = **19 / 20**.

**Carved-out (separate `specrew init` slice — NOT this iteration):** FR-018 (`nvm`-shadows-Homebrew-Node diagnostics) + FR-019 (Spec Kit version UX) per maintainer decision 2026-06-02. Iteration 3 only **documents** these (T022) and **surfaces** them in the manual smoke (T021).

**Deferred (follow-up iteration):** remaining MS-supported distros (RHEL/Fedora via the MS dnf repo) for FR-007/FR-016. `install.sh` keeps failing closed for them (Iteration-2-proven path).

Feature total ≈ **57 SP** across 3 iterations (each ≤ 20): Iter 1 = 19, Iter 2 = 19, Iter 3 = 19.

## Traceability Matrix

| FR / SC | Covered by |
| --- | --- |
| FR-001 | T001, T003, T004 |
| FR-002 | T002, T015 (Ubuntu); T020 (macOS) |
| FR-003 | T002, T015 (Ubuntu); T020 (macOS) |
| FR-004 | T002, T015 (Ubuntu); T020 (macOS) |
| FR-005 | T007 |
| FR-006 | T007, T008 |
| FR-007 | T010, T011, T012, T013, T014, T015 (Ubuntu auto-install); T018 (macOS Homebrew); T021 (macOS manual proof). dnf/RHEL distros DEFERRED (fail-closed path stands) |
| FR-008 | T002, T015 (Ubuntu); T020 (macOS) |
| FR-009 | T003, T005, T006, T016, T023 |
| FR-010 | T009 |
| FR-011 | T006, T009, T016 (registry↔bin↔FileList arm); T023 (docs arm) |
| FR-012 | T015 (Ubuntu); T020 (macOS) |
| FR-013 | T007 |
| FR-014 | T022 |
| FR-015 | T024 |
| FR-016 | T010, T012, T013, T014, T017 (Ubuntu); T018, T021 (macOS) |
| FR-017 | T019 (built); T024 (proven at the release gate against a published beta) |
| FR-018 | CARVED-OUT (separate `specrew init` slice). Documented by T022; surfaced by T021 |
| FR-019 | CARVED-OUT (separate `specrew init` slice). Documented by T022; surfaced by T021 |
| SC-001 | T015 (Ubuntu); T020 (macOS) |
| SC-002 | T006 |
| SC-003 | T015 (Ubuntu); T020 (macOS) |
| SC-004 | T008 |
| SC-005 | T022 |
| SC-006 | T024 |
| SC-007 | T015 (Ubuntu auto-install); T021 (macOS manual proof) |
| SC-008 | T019 (built); T024 (proven at the release gate) |

Every task maps to ≥1 FR/SC; every in-scope FR/SC maps to ≥1 task. FR-018/FR-019 are carved to a separate `specrew init` slice (documented by T022, surfaced by T021); dnf/RHEL distro coverage of FR-007/FR-016 is deferred to a follow-up iteration with the fail-closed path standing.
