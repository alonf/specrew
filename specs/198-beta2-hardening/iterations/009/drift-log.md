# Drift Log: Iteration 009

**Schema**: v1

## Summary

**Total drift events**: 6
**Resolution rate**: 50% (3/6 resolved)
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

### DRIFT-198-I009-002 — measured slow-suite ceiling and retry-count assertion caused false red

- **Status**: resolved in T079; focused proof green
- **Severity**: blocking verification-integrity defect
- **Type**: deterministic test-harness drift, not product requirement drift
- **Observed evidence**: the first clean exact-commit registry after cleanup repair failed
  before provider spend. Direct command-scoped reproduction showed the public-campaign and
  conformance suites timing out at 300 seconds, although Iteration 009 W1 had already measured
  them at 278–294 seconds. The same loaded run exposed a POSIX test that demanded at least two
  membership probes inside a 25 ms wall-clock budget even though the first probe can consume
  that budget legitimately.
- **Correction**: retain the 300-second default for 80 suites and give only the two measured
  slow suites an explicit 420-second bounded ceiling in both parallel and serial lanes. Record
  each effective ceiling in timing evidence. The POSIX test now requires one-or-more probes
  plus bounded false return, matching the production contract without inventing a retry count.
- **Resolution evidence**: runner parse and W1/W2 source-contract tests pass; the POSIX suite
  passes 7/7 applicable tests with 4 platform skips. The next exact-commit complete registry
  remains the integrated proof.

### DRIFT-198-I009-003 — shared reviewer prompt disabled Codex inspection

- **Status**: resolved in T079; focused contract proof green
- **Severity**: blocking cross-harness review defect
- **Type**: host-capability contract mismatch, not specification drift
- **Observed evidence**: the first provider-backed review of exact commit `a21df0b7`
  completed with a valid file-primary result after one invocation but reported
  `completion=partial`, `verdict=incomplete`, and no findings. Its summary stated that the
  permitted `Read`, `Glob`, and `Grep` tools were unavailable. The shared prompt prohibited
  every other inspection tool and all shell commands even though only Claude's catalog row
  mechanically exposes that named tool set; Codex exposes `shell_command` instead.
- **Containment**: the incomplete result cannot approve the candidate
  (`can_approve_current=false`). It is retained as immutable evidence and is not interpreted
  as a clean review.
- **Correction**: the canonical prompt now states the truthful cross-host contract: use the
  inspection tools the selected host actually exposes; general-tool hosts may use shell
  commands only for read-only listing/searching/reading and read-only Git inspection; the
  sole permitted mutation remains writing raw JSON to the exact candidate path. Claude's
  launch vector remains mechanically restricted to `Read,Glob,Grep,Write`.
- **Resolution evidence**: the shared harness and Codex/Copilot adapter suites pass 38/38.
  They reject a false universal tool restriction, assert the truthful general-tool posture
  in rendered prompts, preserve the Claude allowlist, and retain file-primary single-write
  authority. A complete exact-commit registry and provider-backed retry remain required.

### DRIFT-198-I009-004 — tracked symlink escapes the frozen review tree

- **Status**: open; gate-reported product defect
- **Severity**: blocking review-integrity defect
- **Type**: snapshot containment and currentness
- **Authority evidence**: `evidence/independent-review-29e9f6fa-result.json`,
  finding `finding-a5f8eb2502002352`.
- **Confirmed source evidence**: `git ls-files -s` records
  `.antigravitycli/f95594b5-b180-4b4d-b9e9-93dd0b5890b8.json` with mode `120000`;
  on this machine it resolves to an absolute file outside the repository. Candidate
  materialization uses `git read-tree --reset -u` and performs no post-check for symlink
  or reparse-point escapes before reviewers read the snapshot.
- **Required correction**: reject or safely neutralize any reviewed path whose link target
  escapes the frozen workspace, with positive/negative containment tests. Classify the
  volatile `.antigravitycli` runtime path consistently so it cannot enter product source by
  accident.

### DRIFT-198-I009-005 — binding expansion rejects historical recovery facts

- **Status**: open; gate-reported product defect
- **Severity**: major recovery-compatibility defect
- **Type**: tolerant-reader/backward-compatibility
- **Authority evidence**: `evidence/independent-review-29e9f6fa-result.json`,
  finding `finding-72cda2db29037f83`.
- **Confirmed source evidence**: the unchanged `RecoveryFact` schema version now treats
  six binding fields as one all-or-none group. Facts written immediately before F16 carry
  the formerly complete four-field group and therefore fail validation before reconciliation
  can recover their process, claim, or snapshot.
- **Required correction**: accept the historical complete four-field shape explicitly,
  preserve fail-closed currentness for missing exclusion identity, and add immutable-fact
  reader/reconciliation regressions for both historical and current shapes.

### DRIFT-198-I009-006 — managed runtime update cannot retire obsolete files

- **Status**: open; gate-reported product defect
- **Severity**: major update/engine-identity defect
- **Type**: managed deployment convergence
- **Authority evidence**: `evidence/independent-review-29e9f6fa-result.json`,
  finding `finding-823296e1c4cada0e`.
- **Confirmed source evidence**: `Copy-ManagedDirectory` creates or overwrites source files
  but never removes obsolete managed target files. The deployed marker hashes the stale
  target, while runtime selection compares that target to the clean installed bundle, so a
  retired or renamed runtime file creates a permanent mismatch that repeated update cannot
  heal.
- **Required correction**: deploy from an explicit managed manifest, remove only previously
  managed files absent from the new source, preserve user-owned/modified files safely, and
  prove update convergence plus modification protection.
