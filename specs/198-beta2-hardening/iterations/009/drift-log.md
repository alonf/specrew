# Drift Log: Iteration 009

**Schema**: v1

## Summary

**Total drift events**: 8
**Resolution rate**: 88% (7/8 resolved)
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

- **Status**: resolved in T079 (commit `4641bea8`); focused regression green
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
- **Correction**: `Assert-GitReviewTargetTreeSymlinksContained` walks every `120000` tree
  entry and rejects empty, NUL/undecodable, rooted (POSIX and Windows rules on every host),
  or parent-escaping link targets before both snapshot and verification-copy
  materialization, without echoing the target. Verification-support staging skips symlink
  entries, and `.antigravitycli` is classified as machinery in the core exclusion list.
- **Resolution evidence**: focused ReviewTargetPort, campaign-orchestrator, and
  machinery-path suites pass (78/78 across the six-suite correction set) with paired
  contained/escaping fixtures. The next exact-commit registry and provider-backed review
  remain the integrated proof.

### DRIFT-198-I009-005 — binding expansion rejects historical recovery facts

- **Status**: resolved in T079 (commit `0b5d0199`); focused regression green
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
- **Correction**: the authority contract and reconciler now recognize two explicit complete
  shapes — `historical-v1` (four fields) and `current-v1` (six fields). Historical facts
  recover their process, claim, snapshot, plan, and machinery bindings;
  `recovery_binding_complete` remains true only for the current shape, so missing exclusion
  identity stays fail-closed for currentness.
- **Resolution evidence**: authority-core and reconciler regressions cover both shapes plus
  the still-rejected partial groups; the focused correction set passes 78/78.

### DRIFT-198-I009-006 — managed runtime update cannot retire obsolete files

- **Status**: resolved in T079 (commit `78908cd9`); focused regression green
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
- **Correction**: deployment computes an explicit per-file managed manifest, binds it into
  `.specrew-runtime.json`, retires only previously managed, hash-unmodified files absent
  from the new source (directories, reparse points, modified files, and unsafe paths are
  preserved with named actions), and verifies deployed-vs-source bundle identity after
  copy. Engine selection hashes manifest-bound files, so preserved obsolete files no longer
  poison the handshake; an old or damaged marker is never deletion authority.
- **Resolution evidence**: review-engine resolution and deploy-completeness regressions
  cover retirement provenance, modified-file preservation, unsafe-manifest fail-closed
  behavior, and manifest-bound selection; the focused correction set passes 78/78.

### DRIFT-198-I009-007 — reviewer model identity is declared but never enforced

- **Status**: open; deferred outside the approved Iteration 009 finding set
- **Severity**: minor evidence-honesty defect
- **Type**: reviewer identity/provenance
- **Observed evidence**: the maintainer pinned the codex reviewer of record to the exact
  codex CLI model tag on 2026-07-26. `.specrew/reviewer-hosts.json` carries that `model`
  value into selection, authorization, and the persisted review result, but the invocation
  core builds the command line solely from the shipped catalog row's `agentic_args`
  (`codex exec --dangerously-bypass-approvals-and-sandbox --skip-git-repo-check`). No host
  row passes a model flag, and `Get-ContinuousCoReviewHostAgenticCommand` reads the shipped
  rows rather than the project config, so a project cannot pin the invoked model at all.
- **Actual behavior on this machine**: the codex CLI resolves its own default from
  `~/.codex/config.toml`, which currently reads `model = "gpt-5.6-sol"`. The recorded
  reviewer model therefore matches the invoked model by ambient configuration, not by
  enforcement, and `model_source: human-entered` correctly labels it a human assertion.
- **Risk**: if the ambient host configuration changes, review evidence would continue to
  name the pinned model while a different model performed the review, with no mechanism to
  detect the divergence.
- **Required correction (deferred)**: pass the project-configured model through the host
  invocation seam, or record the host-reported model as machine-observed provenance
  distinct from the human-entered declaration. This is the first real consumer for the
  deferred `model_probe` seam (DEFER-197-I010-002). It is a product change beyond the
  approved Iteration 009 finding set and is not made here.

### DRIFT-198-I009-008 — a declared reviewer model disabled the review harness

- **Status**: resolved in T079; focused regression green
- **Severity**: blocking review-infrastructure defect, consumer-reachable
- **Type**: host-capability contract mismatch, not specification drift
- **Observed evidence**: exact-commit run `run-f198-i009-9f15cb49-codex` reserved its slot, ran
  both controller verification commands green over 989.2 seconds, then ended
  `preflight-failed:harness` with `Invoked: False` and `Usage: unavailable`. The reservation was
  released, so no provider slot was spent.
- **Confirmed source evidence**: `New-ReviewProductionHarnessPort` returns an unavailable port with
  `production-harness-model-override-unsupported:<host>` whenever a model is supplied and the
  selected host's file-primary constructor declares no `Model` parameter. Only
  `New-ReviewCursorAgentFilePrimaryHarnessPort` declares one; the codex, claude, copilot, and
  antigravity constructors do not. The public command promoted the **declared**
  `.specrew/reviewer-hosts.json` model into that per-run override, and catalog rows legitimately
  carry descriptive values such as `configured-by-user` and `gpt-5.5-or-claude-4.8` that were never
  CLI tags. Any project that recorded a reviewer model - the exact state
  `specrew review --host X --authorization-ref Y` itself writes - therefore could not run a campaign
  review. Passing an explicit `--authorization-ref` on every run skips the configuration lookup
  entirely, which is why earlier runs masked the defect.
- **Correction**: the declared model is selection and provenance data only. Only an explicit
  `--model` request is attempted as a per-run harness override, and an unsupported explicit request
  still fails loudly with its named reason rather than silently reviewing on an unrequested model.
- **Resolution evidence**: the public campaign command suite passes 40/40, including a new paired
  regression proving a declared model builds the real `codex-cli-file-primary` harness while an
  explicit unsupported override still returns `production-harness-model-override-unsupported:codex`,
  plus a source-contract assertion that the promotion cannot return.
- **Relation**: DRIFT-198-I009-007 records the remaining, separate gap that the pinned model is
  declarative rather than enforced at invocation. This correction does not close that one.
