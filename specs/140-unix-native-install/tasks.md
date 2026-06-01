# Tasks: Unix-Native Install & Command Surface

**Feature**: 140-unix-native-install
**Plan**: [plan.md](./plan.md) | **Spec**: [spec.md](./spec.md)
**Date**: 2026-06-02

Tasks cover the whole feature, tagged by iteration. **Iteration 1 is the active, ready-to-implement decomposition** (approved at plan → tasks). Iteration 2 is listed for traceability + planning and is decomposed in detail when Iteration 1 closes. Every task traces to ≥1 FR/SC; every FR/SC has ≥1 task (see Traceability Matrix).

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

## Iteration 2 — bootstrap + cross-platform proof + release gate (planned; ~14 SP)

| ID | Task | FR / SC | SP | Owner | Deps |
| --- | --- | --- | --- | --- | --- |
| T010 | `install.sh` bootstrap (`curl \| sh`): verify `pwsh` (error+hint; never installs pwsh) → `Install-Module Specrew` → `specrew install-shell-wrappers` | FR-007 | 3 | Implementer | T007 |
| T011 | Ubuntu + macOS CI runtime lanes (extend `cross-platform-validation.yml`): install→PATH→`specrew version`/`start --help`, quoting/spaces forwarding, symlink resolution, pwsh-missing negative test, unknown-option passthrough | FR-012, FR-002, FR-003, FR-004, FR-008, SC-001, SC-003 | 4 | Reviewer | T004, T007 |
| T012 | CI parity-cascade job: regenerate + `git diff --exit-code`; registry↔bin↔FileList↔docs; name the cascade on failure | FR-011, FR-009 | 2 | Reviewer | T006, T009 |
| T013 | Native-first docs (`README.md`, `docs/getting-started.md`, `docs/user-guide.md`, `docs/troubleshooting.md`) + doc-example parity/allowlist | FR-014, SC-005 | 2 | Spec Steward | T007, T010 |
| T014 | Greenfield + brownfield installed validation (release gate; covers bundled Spec Kit 0.9.0); record evidence; **no beta/stable publish without explicit maintainer authorization** | FR-015, SC-006 | 3 | Reviewer | T010, T011, T013 |

**Iteration 2 SP**: 3+4+2+2+3 = **14 / 20**. Feature total ≈ **33 SP** across 2 iterations (each ≤ 20).

## Traceability Matrix

| FR / SC | Covered by |
| --- | --- |
| FR-001 | T001, T003, T004 |
| FR-002 | T002, T011 |
| FR-003 | T002, T011 |
| FR-004 | T002, T011 |
| FR-005 | T007 |
| FR-006 | T007, T008 |
| FR-007 | T010 |
| FR-008 | T002, T011 |
| FR-009 | T003, T005, T006, T012 |
| FR-010 | T009 |
| FR-011 | T006, T009, T012 |
| FR-012 | T011 |
| FR-013 | T007 |
| FR-014 | T013 |
| FR-015 | T014 |
| SC-001 | T011 |
| SC-002 | T006 |
| SC-003 | T011 |
| SC-004 | T008 |
| SC-005 | T013 |
| SC-006 | T014 |

Every task maps to ≥1 FR/SC; every FR/SC maps to ≥1 task.
