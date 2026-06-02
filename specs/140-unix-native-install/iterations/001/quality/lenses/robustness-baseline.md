# Robustness Baseline Lens — Iteration 001

**Feature**: 140-unix-native-install
**Lens**: `robustness-baseline@v1.0.0`
**Reviewed**: 2026-06-02
**Verdict**: pass — failure semantics explicit and non-silent.

## Failure modes + controls

| Failure mode | Control | Evidence |
| --- | --- | --- |
| `pwsh` missing / not on PATH | wrapper exits non-zero (127) with a clear message + install hint; never auto-installs | wrapper template (T002); pwsh-missing negative test → Iter 2 CI |
| Missing bin dir | installer refuses without `-Force` (no silent `mkdir`) | install-shell-wrappers test (decision matrix) |
| Existing non-symlink file at target | `skip-needs-force` (no clobber) | install-shell-wrappers test |
| Bin dir not on PATH | warn-only; no shell-profile mutation | `Test-DirOnPath` test + Iter 2 CI |
| Generator non-determinism | idempotent (byte-identical re-run) + `-Check` drift detection | generator test |
| Errors / unset vars in wrappers | `set -eu` fail-fast | `bash -n` clean |

## Notes

- A real robustness bug was caught by the tests this iteration: assigning to the read-only automatic variables `$home` / `$IsWindows` (in `Resolve-SpecrewBinDir` and the test) — both fixed.
- Concurrency-correctness, resiliency, and retry/recovery are **not-applicable** (single-shot commands, no shared state, no network retry workflow) — consistent with the hardening gate.
