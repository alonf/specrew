# Implementation Plan: Unix-Native Install & Command Surface

**Branch**: `140-unix-native-install` | **Date**: 2026-06-02 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `specs/140-unix-native-install/spec.md` (Proposal 153)

## Summary

Ship POSIX `sh` wrapper commands over Specrew's exported alias surface so macOS/Linux users run `specrew …` natively without typing `pwsh -File …`, plus a thin `install.sh` bootstrap and a `specrew install-shell-wrappers` installer. PowerShell Core stays the internal runtime. Wrappers are **generated from the canonical command registry by a generator that is the single source of truth, with the generated files committed and CI regenerating + diffing to catch drift** (generate-then-commit). The authoritative verification surface for all Unix-runtime behavior is the **Ubuntu + macOS CI lanes**; Git Bash on Windows is a development proxy only.

## Technical Context

**Language/Version**: PowerShell 7 (Core) for the module/generator/installer; POSIX `sh` for the wrappers + `install.sh`
**Primary Dependencies**: `pwsh` (PowerShell Core, runtime — verified, never auto-installed); PSGallery (`Install-Module Specrew`); Pester (PS unit tests)
**Storage**: N/A (no persisted state; wrappers + bootstrap are stateless forwarders/installers)
**Testing**: Pester unit tests (generator, installer, parity) on any platform; shell integration tests on Ubuntu + macOS CI (authoritative); packaging parity test
**Target Platform**: macOS + Linux (native command surface); Windows unchanged except docs
**Project Type**: PowerShell module + CLI command surface + packaging/distribution
**Performance Goals**: wrapper overhead negligible (single `exec` to `pwsh`); N/A throughput
**Constraints**: POSIX `sh` only (no Bash arrays, no GNU `readlink -f`); no mutation outside the requested bin dir; no shell-profile edits; symlink-resolvable module root
**Scale/Scope**: 8 exported aliases → 8 generated wrappers + root; 1 installer subcommand; 1 bootstrap; 4 docs; ~24-29 SP across 2 iterations

## Architecture

### Components

1. **Canonical command registry** — `Specrew.psd1` `AliasesToExport` (`specrew-init`, `-start`, `-update`, `-version`, `-review`, `-team`, `-where`) plus the root `specrew`. Single source for wrapper names. (`scripts/specrew-config.ps1` / `specrew-host.ps1` are root subcommands, **not** aliases → no standalone wrappers.)
2. **Wrapper generator** (`scripts/internal/generate-shell-wrappers.ps1`) — the single source of truth: reads the registry, renders each wrapper from one POSIX-`sh` template, writes committed files to `bin/`. Deterministic + idempotent (re-run yields byte-identical output). CI regenerates and `git diff --exit-code`s to detect drift.
3. **Wrapper template** — POSIX `sh`: `#!/usr/bin/env sh`, `set -eu`, `pwsh` presence check (clear error + install hint on failure), symlink-resolution loop, `module_root` resolution, then `exec pwsh -NoProfile -ExecutionPolicy Bypass -File "$module_root/scripts/<entrypoint>.ps1" "$@"`. Entrypoint mapping is 1:1 (`specrew` → `scripts/specrew.ps1`; `specrew-init` → `scripts/specrew-init.ps1`; etc.).
4. **Committed `bin/` wrappers** — 8 generated files, reviewable in-repo, shipped via `FileList`.
5. **`install-shell-wrappers`** — a new subcommand of the root `specrew` (dispatched by `scripts/specrew.ps1`, backed by a PowerShell function + script). Copies the committed `bin/` wrappers into a bin dir (default `$HOME/.local/bin`); `-BinDir`, `-Force` (required to create a missing dir), `-WhatIf` (dry-run); idempotent; warns (no profile mutation) when the bin dir is not on `PATH`; never mutates outside the requested dir; prints the exact commands installed.
6. **`install.sh` bootstrap** — repo-committed, runnable via `curl … | sh`: verify `pwsh` (error + hint otherwise; never installs pwsh) → `Install-Module Specrew` via pwsh → `specrew install-shell-wrappers` (module first, wrappers second).
7. **Parity machinery** — CI: (a) regenerate wrappers + diff vs committed `bin/`; (b) registry ↔ `bin/` parity; (c) `bin/` + `install.sh` ↔ `Specrew.psd1` `FileList`; (d) docs examples ↔ registry (allowlist where needed). On failure CI names the cascade: registry → wrappers → installer → FileList → docs.
8. **CI lanes** — extend `.github/workflows/cross-platform-validation.yml` with Ubuntu + macOS jobs that exercise the wrappers at runtime (the authoritative surface); parity checks run in the PS test lane.
9. **`FileList`** — add `bin/specrew`, `bin/specrew-*` (8), `install.sh`, the generator + template.
10. **Docs** — `README.md`, `docs/getting-started.md`, `docs/user-guide.md`, `docs/troubleshooting.md`: native-first, honest pwsh-required note + module-command fallback.

### Canonical flow

`install.sh` → verify `pwsh` → `Install-Module Specrew` → `specrew install-shell-wrappers` → copies `bin/` → `~/.local/bin` → user runs `specrew version` → wrapper resolves module root (following symlinks) → `exec pwsh … scripts/specrew.ps1 version "$@"` → output. (Full diagrams in `review-diagrams.md`.)

### FR → verification mapping

| FR | Verification | Authoritative surface |
| --- | --- | --- |
| FR-001 wrappers exist for registry | registry↔`bin/` parity test | PS unit |
| FR-002 exact arg forwarding | forwarding test (spaces/quotes/`--`/empty) | Ubuntu + macOS CI |
| FR-003 module-root via symlink | symlinked-wrapper run | Ubuntu + macOS CI |
| FR-004 pwsh-missing error | PATH-without-pwsh negative test | Ubuntu + macOS CI |
| FR-005 install-shell-wrappers | installer into temp bin | PS unit + CI |
| FR-006 idempotent/safe/-Force/-WhatIf/PATH-warn | installer unit tests | PS unit |
| FR-007 install.sh bootstrap | bootstrap run on clean host | Ubuntu + macOS CI |
| FR-008 thin forwarder (no reparse) | unknown-option passthrough test | Ubuntu + macOS CI |
| FR-009 generate-then-commit | regenerate + `git diff --exit-code` | PS/CI |
| FR-010 FileList inclusion | packaging parity test | PS/CI |
| FR-011 cascade triggers + naming | parity job on trigger paths | CI |
| FR-012 Ubuntu + macOS validation | the lanes themselves | CI |
| FR-013 Windows unchanged | Windows lane unaffected + docs | CI/manual |
| FR-014 native-first docs | docs review + example parity | manual + CI |
| FR-015 release gate | greenfield + brownfield installed validation | manual (release) |

## Phase 1 Quality Planning

**Phase Scope**: `phase-1-first-slice`
**Inferred Quality Profile**: `quality-profile.custom-composition.v1` (bounded custom composition)
**Selected preset ref or explicit custom composition**: None — bounded custom composition (no recognized preset cleanly matches a PowerShell+POSIX-sh CLI tooling surface).

### Stack Surfaces in Scope

| Stack Surface | Path Globs / Evidence | Recognized Stack | Why It Matters |
| --- | --- | --- | --- |
| `posix-sh-wrappers` | `bin/**`, `install.sh` | custom (shell) | the user-facing Unix command surface |
| `ps-tooling` | `scripts/**`, `Specrew.psd1` | custom (PowerShell) | generator, installer, registry, packaging |

### Risk Dimensions

| Risk Dimension | Status | Rationale |
| --- | --- | --- |
| `code-quality` | required | generator/installer/template must stay explicit + reviewable |
| `design-quality-and-separation-of-concerns` | required | thin-forwarder contract: option parsing stays in PowerShell, never in shell |
| `verification-confidence` | required | Unix runtime proven on real Ubuntu/macOS, not smoke-only or Git-Bash proxy |
| `maintainability` | required | generate-then-commit + parity keeps the cascade drift-proof |
| `security` | required | bin-dir confinement, no profile mutation, `ExecutionPolicy Bypass` scope, no auto-install of pwsh |
| `robustness` | required | pwsh-missing, symlink chains, quoting/spaces, missing bin dir — explicit failure semantics |

### Quality Tool Bundle

| Area | Selection |
| --- | --- |
| Bundle ID | `phase1-custom-quality-bundle` |
| Mechanical Checks | dead-field, anti-pattern, test-integrity |
| Ecosystem Tools | PSScriptAnalyzer (PS), `sh -n` / shellcheck (wrappers), markdownlint (docs), Pester (verification) |
| Manual Evidence | this Phase 1 section + `specs/140-unix-native-install/iterations/<NNN>/quality/quality-evidence.md` |

### Not-Applicable Dimensions and Rationale

| Dimension / Gate | Why Not Applicable | Follow-up |
| --- | --- | --- |
| `concurrency-correctness` | wrappers/installer are single-shot; no shared state | none |
| `resiliency` / `retry-idempotency-and-recovery` | no network retry/reconnect workflow (install-time `Install-Module` is a one-shot the user re-runs) | none |

## Phase 2 Hardening and Specialist Review Planning

**Phase 2 Slice Scope**: hardening-gate planning only; planning-time analysis + expected controls + non-applicable reasoning recorded pre-implementation; runtime-only final proof stays pending until iteration closure.
**Hardening Gate Artifact**: `specs/140-unix-native-install/iterations/<NNN>/quality/hardening-gate.md`
**Known-Traps Corpus Location**: `.specrew/quality/known-traps.md`

### Hardening Focus Areas

| Focus Area | Why It Matters | Status |
| --- | --- | --- |
| Security surface | bin-dir confinement, no out-of-dir/profile mutation, `ExecutionPolicy Bypass` scope, `curl\|sh` trust, no pwsh auto-install | required |
| Error handling / failure semantics | pwsh-missing (clear non-zero + hint), missing bin dir (`-Force`), not-on-PATH (warn-only) | required |
| Retry / idempotency | installer idempotency required; network retry N/A (recorded) | required (idempotency) / not-applicable (retry) |
| Test-integrity targets | Ubuntu + macOS runtime evidence, not Git-Bash proxy or file-presence | required |

### Lens Activation Plan

| Lens Ref | Activation | Rationale |
| --- | --- | --- |
| `security-baseline@v1.0.0` | required | install-time filesystem writes + `curl\|sh` trust surface |
| `robustness-baseline@v1.0.0` | required | failure semantics across pwsh-missing / symlink / quoting |
| `test-integrity@v1.0.0` | required | cross-platform runtime proof, not smoke-only |

### Explicit Later Deferrals

- Line-by-line lens execution evidence + runtime-only final proof deferred to the approved implement/review slice.
- Strongest-class routing enforcement evidence deferred until the routed execution path exists.

## Constitution Check

- **Spec Authority Gate**: every deliverable maps to a spec FR (see FR→verification table). PASS.
- **Layering Gate**: this is the **Specrew module / distribution layer** (PowerShell module command surface, packaging, CI) — not a Spec Kit extension change and not a Squad-layer change. PASS.
- **Traceability Gate**: deliverables link to US1-US4 + FR-001..FR-015 + planned tasks (decomposed at `/speckit.tasks`). PASS.
- **Ownership Gate**: Implementer owns generator/template/wrappers/installer/bootstrap; Reviewer owns parity + packaging + CI lanes; Spec Steward owns docs honesty + spec integrity. PASS.
- **Capacity Gate**: story points, 20 SP/iteration cap; rough estimate ~24-29 SP → 2-iteration split (below). PASS.
- **Drift/Reconciliation Gate**: registry ↔ wrapper ↔ FileList ↔ docs parity tests (CI, cascade-named); spec↔plan↔tasks traceability. PASS.
- **Verification Gate**: Ubuntu + macOS CI is the authoritative Unix-runtime surface; release gated by greenfield + brownfield installed validation (FR-015). PASS.

## Project Structure

### Documentation (this feature)

```text
specs/140-unix-native-install/
├── spec.md
├── research.md
├── plan.md
├── data-model.md
├── quickstart.md
├── contracts/
│   └── unix-native-install.md
├── review-diagrams.md
├── checklists/requirements.md
└── tasks.md            # /speckit.tasks output (not yet)
```

### Source Code (repository root)

```text
bin/                                       # generated POSIX sh wrappers (committed)
  specrew  specrew-init  specrew-start  specrew-update
  specrew-version  specrew-review  specrew-team  specrew-where
install.sh                                 # bootstrap (curl|sh)
scripts/
  specrew.ps1                              # root dispatch (+ install-shell-wrappers subcommand)
  specrew-install-shell-wrappers.ps1       # installer entrypoint (or function in module)
  internal/
    generate-shell-wrappers.ps1            # generator = single source of truth
    shell-wrapper-template.sh              # POSIX sh template (or here-string in generator)
Specrew.psd1                               # AliasesToExport (registry) + FileList (add wrappers + install.sh)
tests/
  unit/shell-wrapper-generator.tests.ps1
  unit/install-shell-wrappers.tests.ps1
  unit/wrapper-registry-parity.tests.ps1   # registry↔bin↔FileList parity
  integration/wrapper-runtime.tests.ps1    # cross-platform; run on Ubuntu+macOS CI
.github/workflows/
  cross-platform-validation.yml            # extended: Ubuntu+macOS wrapper runtime lanes
docs/                                       # README + getting-started + user-guide + troubleshooting
```

**Structure Decision**: PowerShell module + a new `bin/` of generated POSIX shell wrappers + a root `install.sh`. The generator (`scripts/internal/`) is the source of truth; `bin/` holds its committed output. Tests split between platform-agnostic Pester unit tests and Ubuntu/macOS CI integration.

## Capacity & Iteration Structure

Rough estimate **~24-29 SP** (generator + template + parity + installer + install.sh + FileList/packaging + Ubuntu/macOS CI + docs + unit tests + greenfield/brownfield installed validation) exceeds the 20 SP cap, and the cross-platform CI/install-validation surface is large. Per the maintainer instruction, split into two iterations along the defined boundary:

- **Iteration 1 — wrappers + generator + installer (platform-agnostic core, ~12-14 SP)**: registry reader, generator + template, committed `bin/` wrappers, registry↔wrapper parity, `install-shell-wrappers` subcommand, `FileList`/package inclusion + packaging parity test, PS unit tests. Verifiable without a Unix host (Pester + packaging).
- **Iteration 2 — bootstrap + cross-platform proof + release gate (~12-15 SP)**: `install.sh`, Ubuntu + macOS CI runtime lanes (forwarding/symlink/pwsh-missing/install), docs (native-first), and the greenfield + brownfield installed validation that also covers the bundled Spec Kit 0.9.0 support.

Exact per-task SP confirmed at `/speckit.tasks` + capacity. Iteration 1 is decomposed first.

## Complexity Tracking

No Constitution Check violations. (Generate-then-commit adds a generator + a parity job, but that is the chosen drift-prevention mechanism, not unjustified complexity.)
