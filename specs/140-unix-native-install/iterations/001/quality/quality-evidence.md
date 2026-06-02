# Quality Evidence: Iteration 001

**Profile Ref**: `quality-profile.custom-composition.v1`
**Preset Refs**: bounded custom composition (PowerShell + POSIX-sh CLI tooling surface)
**Findings Ref**: `specs/140-unix-native-install/iterations/001/quality/mechanical-findings.json`
**Reviewed By**: Reviewer
**Reviewed At**: 2026-06-02T00:39:30Z

## Gate Matrix

| Gate | Requirement | Evidence Source | Status | Exception |
| --- | --- | --- | --- | --- |
| `dead-field` | FR-011, FR-027, FR-030 | `specs/140-unix-native-install/iterations/001/quality/mechanical-findings.json` | `passed` | `—` |
| `anti-pattern` | FR-011, FR-028, FR-030 | `specs/140-unix-native-install/iterations/001/quality/mechanical-findings.json` | `passed` | `—` |
| `test-integrity` | FR-011, FR-029, FR-030 | `specs/140-unix-native-install/iterations/001/quality/mechanical-findings.json` | `passed` | `—` |
| `stack-tooling-evidence` | FR-011 | `specs/140-unix-native-install/iterations/001/coverage-evidence.md` | `passed` | `—` |
| `quality-lens-review` | FR-011, FR-012 | `specs/140-unix-native-install/iterations/001/quality/quality-evidence.md` | `passed` | `—` |

## Evidence summary

- **Unit tests**: 4 files, **22 assertion-driven checks, all green** — `shell-wrapper-generator` (9), `wrapper-registry-parity` (3), `install-shell-wrappers` (6), `wrapper-filelist-parity` (4). Run against the real scripts (not synthetic stand-ins).
- **Mechanical findings**: 0 (`mechanical-findings.json`).
- **Lenses**: `security-baseline` (5 flagged surfaces, pass), `robustness-baseline` (pass), `test-integrity` (pass).
- **Tooling**: `bash -n` clean on all 8 wrappers; `markdownlint` clean on artifacts.
- **Platform boundary**: Unix runtime (symlink/PATH/quoting/pwsh-missing) is CI-only on Ubuntu/macOS (Iteration 2, T011); Iteration 1 covers the platform-agnostic core + Windows no-op.

> Note: the Gate Matrix requirement refs (`FR-027`/`028`/`029`/`030`) are the scaffold's generic gate defaults; this feature's actual FR↔test mapping lives in `tasks.md` (Traceability Matrix) + `review.md`.
