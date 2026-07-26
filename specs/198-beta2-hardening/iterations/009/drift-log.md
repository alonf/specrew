# Drift Log: Iteration 009

**Schema**: v1

## Summary

**Total drift events**: 1
**Resolution rate**: 100% (1/1 resolved)
**Specification drift**: None detected

Article Amplifier supplies read-only field evidence for F6, F10–F17. New
findings discovered during implementation are recorded here only when they are
product defects or material plan drift. Tooling mistakes and content-neutral
formatting are corrected and recorded without creating human stops.

## Events

### DRIFT-198-I009-001 — recursive cleanup deadlocked or stranded long-path worktrees

- **Status**: resolved in T079; focused regression green
- **Severity**: blocking review-infrastructure defect
- **Type**: process I/O and timeout containment, not specification drift
- **Observed evidence**: the exact-commit Iteration 009 review completed deterministic
  verification, then remained blocked in `icacls /remove:d /T`. The native helper read
  redirected stdout to EOF before draining stderr, allowing recursive error output to fill
  the stderr pipe and deadlock. The outer 35-minute command timeout returned while the
  review `pwsh` and `icacls` child remained live; no authority result was produced.
- **Second exact-path evidence**: after the pipe correction, verification completed and
  cleanup returned honestly, but Git failed to delete its disposable verification copy
  with `Filename too long`. The run again stopped before provider invocation. Git had
  unregistered the worktree but left its directory behind.
- **Containment**: the identified process tree was terminated; no second provider was
  launched. The protected disposable target was restored with the corrected helper in
  29.8 seconds, then unregistered and deleted. The primary worktree and consumer evidence
  were unchanged.
- **Correction**: `Invoke-ReviewTargetNativeCommand` now drains stdout/stderr concurrently,
  applies a 120-second default timeout, kills the full child tree on timeout, waits for EOF,
  and returns explicit exit 124 timeout evidence. Every ReviewTargetPort Git invocation on
  Windows also supplies process-local `core.longpaths=true`; no user or repository Git
  configuration is mutated.
- **Resolution evidence**: the ReviewTargetPort suite passes a dual-pipe payload exceeding
  200 KB on each stream without hanging and proves a sleeping native child is reaped within
  the bounded timeout. A real linked worktree containing a path beyond MAX_PATH is removed
  successfully; all 15 ReviewTargetPort tests pass.
