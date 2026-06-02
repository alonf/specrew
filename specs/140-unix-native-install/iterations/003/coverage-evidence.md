# Coverage Evidence: Iteration 003

**Schema**: v1
**Reviewed**: 2026-06-03
**Overall Verdict**: needs-rework

> **Note on the form-vs-meaning warning (scaffolder heuristic):** the scaffolder flagged "5 completed tasks
> vs 19 files in diff". That delta is expected and benign here: the implemented slice spans code
> (`install.sh`), CI (`cross-platform-validation.yml`), 4 docs, 3 test files, and the iteration-3 spec
> artifacts — more files than the 5 *code/doc* tasks. T021 and T024 are **blocked** (not done), so the
> 5-done count is accurate. All cited files are committed (HEAD), satisfying the review-evidence-integrity
> rule (Shape-5).

## Test Strategy

Feature-140 surfaces are POSIX shell (`install.sh` + wrappers) + a PowerShell docs-parity check + CI YAML.
The fast proxy is host-independent shell suites runnable on any POSIX `sh` (Windows/Ubuntu/macOS); the
authoritative macOS runtime is the `validate-macos` CI lane (GREEN — run 26852247885) + the T021 manual proof. Each
path is labeled CI-proven vs manual so closeout cannot overstate coverage.

## Tests Run (this review, local — Windows/MINGW POSIX sh + pwsh 7)

| Command | Result | Pass Count | Fail Count | Exit Code | Notes |
| ------- | ------ | ---------- | ---------- | --------- | ----- |
| `sh tests/integration/install-sh-detect.sh` | pass | 7 | 0 | 0 | apt branch (ubuntu/debian/arch/no-version/no-os-release) + macOS Homebrew present/absent, via SPECREW_UNAME_OVERRIDE |
| `sh tests/integration/install-sh-prerelease.sh` | pass | 4 | 0 | 0 | `--help` documents `--prerelease`; wrapper-surface mismatch predicate (present/absent/empty) |
| `pwsh -File tests/unit/wrapper-docs-parity.tests.ps1` | pass | 1 | 0 | 0 | every specrew-* doc token resolves to alias/skill/allowlist (4 docs, 16 valid names) |
| `run-mechanical-checks.ps1 -FeaturePath specs/140-unix-native-install` | pass | n/a | 0 | 0 | dead-field / anti-pattern / test-integrity: `findings: []` |
| `sh -n install.sh` + markdownlint (README + 3 docs + iter-3 md) | pass | n/a | 0 | 0 | shell syntax + markdown lint clean |

> The macOS `wrapper-runtime.sh` suite (FR-002/003/004/008 on macOS) and the macOS native-command-surface
> step **ran GREEN** on the `validate-macos` CI lane (T020, run 26852247885, SHA 224bbd6f). The clean macOS
> `install.sh` auto-install + `specrew init`/`start` remain the T021 **manual** proof (PENDING — macOS
> runners ship pwsh, so the clean-no-pwsh path is not CI-reachable).

## Coverage Estimate

- Kind: qualitative
- Label: focused_regression + host-independent shell suites; macOS wrapper runtime CI-proven (run 26852247885); clean auto-install + release gate are manual
- Tool: shell test harness + Pester-style ps1 + mechanical lenses

## Coverage-to-Requirements (accurate per-requirement)

| Requirement | Verified by | CI-proven? |
| ----------- | ----------- | ---------- |
| FR-007 (macOS install) | `install-sh-detect.sh` (macOS supported/fail-closed cases); full brew auto-install → T021 manual | partial (detection CI; install manual) |
| FR-016 (macOS supply-chain) | `install-sh-detect.sh` (no-Homebrew fail-closed); `security-surface.md` lens | partial |
| FR-017 (`--prerelease`) | `install-sh-prerelease.sh` (`--help` + mismatch predicate); live prerelease install → T024 | partial (surface CI; live install release-gate) |
| FR-012, FR-002/003/004/008 (macOS) | `wrapper-runtime.sh` on `validate-macos` (T020) + Ubuntu T015 mechanism | **yes** (run 26852247885) |
| FR-014 (native-first docs) | manual review + markdownlint + `wrapper-docs-parity.tests.ps1` (no stale refs) | yes (lint + parity) |
| FR-011, FR-009 (docs-parity arm) | `wrapper-docs-parity.tests.ps1` (+ existing registry/FileList parity) | yes |
| SC-005 (docs lead native) | README/getting-started/user-guide reviewed; `Install-Module` demoted | yes |
| SC-001/SC-003 (macOS) | `wrapper-runtime.sh` on macOS (T020) | **yes** (run 26852247885) |
| SC-007 (macOS auto-install) | T021 manual proof | NO — manual, PENDING |
| SC-006, SC-008 (release gate / prerelease beta) | T024 release gate | NO — manual, BLOCKED on maintainer auth |

## Closeout-blocking coverage gaps

- SC-007 (macOS clean auto-install): requires T021 on a real Mac.
- SC-006 / SC-008 (greenfield+brownfield + prerelease beta): requires T024 under maintainer authorization.
- FR-012 + macOS halves of SC-001/SC-003: **CLEARED** — `validate-macos` ran green (run 26852247885, SHA 224bbd6f).
