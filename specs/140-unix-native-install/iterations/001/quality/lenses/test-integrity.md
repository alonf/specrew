# Test Integrity Lens — Iteration 001

**Feature**: 140-unix-native-install
**Lens**: `test-integrity@v1.0.0`
**Reviewed**: 2026-06-02
**Verdict**: pass — assertion-driven, real-target, negative-path coverage; no smoke-only.

## Coverage

4 new test files, **22 assertion-driven checks, all green** (run against the REAL scripts, not synthetic stand-ins):

| Test file | Checks | Covers |
| --- | --- | --- |
| `shell-wrapper-generator.tests.ps1` | 9 | registry parse, LF-only, thin alias→subcommand dispatch, idempotency, `-Check` drift (in-sync / tampered / missing / extra) |
| `wrapper-registry-parity.tests.ps1` | 3 | every alias has a wrapper, no extras, committed `bin/` byte-in-sync (`-Check`) |
| `install-shell-wrappers.tests.ps1` | 6 | arg normalization, bin-dir resolution, PATH detection, install-plan decision matrix, Windows no-op (no writes), dispatch wiring |
| `wrapper-filelist-parity.tests.ps1` | 4 | bidirectional FileList parity + generator/installer presence |

## Negative paths

`-Check` drift (tampered/missing/extra), `skip-needs-force` (non-symlink file), unknown-arg throws, Windows-no-op-makes-no-writes.

## Platform boundary (platform-not-proxy)

The Unix **runtime** behavior — symlink install, live PATH, quoting/spaces forwarding, `pwsh`-missing — is **CI-only** on Ubuntu + macOS (Iteration 2, T011), explicitly deferred and **not faked** on Windows/Git-Bash. Iteration 1's Windows-runnable tests cover the platform-agnostic decision logic + the Windows no-op.

## Tests-caught-bugs this iteration

`$home` and `$IsWindows` read-only-automatic-variable assignments — caught by the installer tests, fixed before commit.
