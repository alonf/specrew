# Test-Integrity Lens — Iteration 002

**Lens**: `test-integrity@v1.0.0`
**Reviewed By**: Crew Reviewer
**Subject**: the auto-install + wrapper-runtime proof — assertion-driven, not smoke; CI-vs-manual labeled.
**Verdict**: `pass` (the proof is correctly constructed; it becomes runtime-recorded once the Ubuntu CI
lane is green — T015).

## CI-vs-manual enumeration (no blanket "CI-validated")

| Path | How proven | Surface |
| --- | --- | --- |
| Ubuntu/Debian apt auto-install, end-to-end (no pwsh → `specrew version`) | clean `ubuntu:24.04` container, **branch** module pre-seeded on `PSModulePath` | CI (`feature140-install-bootstrap`) |
| Platform detection + fail-closed (distro/version/os-release) | table-driven os-release fixtures via `install.sh --check` | CI (`install-sh-detect.sh`) |
| Wrapper runtime: forwarding (FR-002), symlink (FR-003), pwsh-missing (FR-004), passthrough (FR-008) | committed wrapper vs a stub module-root that echoes args, on real sh + pwsh | CI (`wrapper-runtime.sh`) |
| `install.sh` / shell tests lint | `shellcheck` | CI |
| generate-then-commit drift + registry/FileList parity | `-Check` + `git diff --exit-code` + parity tests | CI (`feature140-parity-cascade`) |
| `Install-Module Specrew` resolving the **published** artifact from PSGallery | — | **Iteration 3 release gate** (cannot prove published behavior pre-publish) |
| Interactive `sudo` password prompt (real human, tty) | — | **manual** (CI cannot type a password) |

## Integrity checks

- Tests run the **real** `install.sh` and the **committed** wrapper (not synthetic stand-ins); the only
  test seam is `SPECREW_OS_RELEASE_FILE` (a file path, identical parsing) and pre-seeding the local module
  on `PSModulePath` (the documented install-if-absent path, not a CI-only code branch). ✔
- Negative paths are asserted, not just happy paths: unsupported distro, missing version, missing
  os-release, pwsh-missing → exit 127. ✔
- Forwarding is byte-exact (spaces/quote/empty/`--`/glob), CR-insensitive only as a defensive no-op on
  Linux. ✔
- Git-Bash-on-Windows is used only as a local syntax/forwarding proxy (FR-002/FR-008 smoke); it is **not**
  the verdict — Ubuntu CI is.

## Evidence

- `tests/integration/install-sh-detect.sh`, `tests/integration/wrapper-runtime.sh`,
  `tests/fixtures/install-sh/os-release/*`, `.github/workflows/cross-platform-validation.yml`
  (feature140 jobs) — **pending green CI run** to record the runtime evidence.
