# Drift Log: Iteration 009

**Schema**: v1

## Summary

**Total drift events**: 29
**Resolution rate**: 72% (21/29 resolved)
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

### DRIFT-198-I009-009 — ignored-tree machinery enumeration overflowed the recovery-fact cap

- **Status**: resolved in T079; focused regression green
- **Severity**: blocking review-infrastructure defect
- **Type**: containment contract bound, not specification drift
- **Observed evidence**: exact-commit run `run-f198-i009-fbe93ad1-codex` passed all seven preflight
  checks - target, verification, store, contract, containment, harness, and runtime - after 942.4
  seconds, then failed at runtime start with
  `review-recovery-fact-invalid:too-many:machinery_paths:512`. `Invoked: False` and
  `Usage: unavailable`: the machinery again failed closed with zero provider spend.
- **Confirmed source evidence**: `Get-ContinuousCoReviewMachineryPaths` recurses the whole project
  for `.specrew-managed` markers. This repository's `.scratch` area holds whole project copies left
  by earlier diagnostics, contributing 539 of 612 machinery paths. Git ignores `.scratch/`
  (`.gitignore:37`) and tracks zero files beneath it, so every one of those entries was already
  outside the reviewed candidate and bought no additional exclusion.
- **Correction**: marker-detected paths that Git already ignores are dropped from the machinery
  list. The core roots and the bounded host-mirror vocabulary are always listed, and any Git failure
  keeps the unfiltered list rather than silently under-stripping.
- **Resolution evidence**: the machinery-path, containment, and origin-path-hygiene suites pass
  28/28, including a new fixture proving a marked directory inside an ignored tree is excluded while
  a tracked deployed mirror is still stripped. The live list drops from 612 to 73 paths with
  `.specrew` and `.antigravitycli` retained and zero `.scratch` entries remaining.

### DRIFT-198-I009-010 — case-insensitive ignored-path matching could under-strip machinery

- **Status**: resolved in T079; focused regression green
- **Severity**: major candidate-membership defect
- **Type**: cross-platform path identity
- **Authority evidence**: `evidence/independent-review-178a3772-result.json`,
  finding `finding-58755c38340abc2f`, reported by the complete, current, valid independent review of
  commit `178a3772` (target digest `b6ef0626a86323dce8598966d8434c0fec85243d`).
- **Confirmed source evidence**: the DRIFT-198-I009-009 filter stored Git's ignored-path output in a
  `HashSet` using `OrdinalIgnoreCase` on every platform. On a supported case-sensitive Linux or
  macOS worktree, an ignored directory and a **distinct** non-ignored directory whose paths differ
  only by case collapse to one key, so the non-ignored deployed machinery is dropped from the
  machinery list. Git still includes its files in the reviewed digest, so it survives into the
  materialized reviewer candidate and machinery-only changes can perturb the certified source
  identity. The defect was introduced by the immediately preceding correction in this same task.
- **Correction**: compare by exact ordinal identity. Git echoes each ignored path back verbatim, so
  ordinal matching always matches the filter's own input on every platform while never collapsing
  two genuinely distinct paths.
- **Resolution evidence**: a source-contract assertion pins `Ordinal` on every platform, and a
  case-collision fixture proves a non-ignored path survives an ignored path differing only by case.
  That fixture is skipped on case-insensitive filesystems and executes on the Linux and macOS CI
  runners. The machinery-path and containment suites pass 23 with that one platform skip, and the
  live machinery list stays at 73 paths.
- **Convention**: this matches the existing platform-appropriate case-sensitivity contract already
  proven for `Test-ContinuousCoReviewPathUnderRoot` by an earlier co-review finding.

### DRIFT-198-I009-011 — retired-runtime cleanup can delete a file outside the project

- **Status**: open; gate-reported product defect awaiting human replan
- **Severity**: blocking security defect
- **Type**: path containment
- **Authority evidence**: `evidence/independent-review-d2b786e6-result.json`,
  finding `finding-3dc22598568c5103`.
- **Confirmed source evidence**: `Remove-RetiredManagedRuntimeFiles` resolves each managed-file
  entry with `[IO.Path]::GetFullPath` and accepts it via the purely lexical
  `Test-SpecrewReviewRuntimePathUnderRoot`, then tests `ReparsePoint` only on the **final** item. If
  any ancestor beneath the runtime root is a symlink or junction to an external directory, the path
  still compares as under the root while `Get-Item`, hashing, and `[IO.File]::Delete` follow that
  ancestor to the external file. The previous marker is an editable file in the target project that
  supplies both `managed_files.path` and its expected hash, so a validly shaped marker can authorize
  deleting a matching file outside the project. The empty-parent cleanup loop is lexical for the same
  reason. Introduced by the DRIFT-198-I009-006 correction in commit `78908cd9`.
- **Required correction**: resolve and contain every existing path component, or reject any
  reparse-point ancestor, before hashing or deleting, with paired escape regressions.
- **Correction**: `Assert-SpecrewReviewRuntimePathContained` walks every existing component from the
  runtime root down, rejects a reparse point at any component and at the root itself, and re-verifies
  containment before returning the resolved path. Retirement calls it before `Get-Item`, hashing, or
  deletion, and records `preserved-uncontained-retired-runtime-file` instead of deleting when it
  refuses. The empty-parent cleanup is safe by construction because no ancestor can be a link.
- **Resolution evidence**: the engine-resolution suite proves an ordinary contained path is accepted,
  a lexical parent escape is refused, and - with a real symlink materialized during the run - a
  reparse-point **ancestor** is refused before hashing or deleting while the external file is left
  untouched. Source-contract assertions pin both the containment call and the preserve action.

### DRIFT-198-I009-012 — digest stripping still collapses distinct paths on case-sensitive hosts

- **Status**: open; gate-reported product defect awaiting human replan
- **Severity**: major review-integrity defect
- **Type**: cross-platform path identity
- **Authority evidence**: `evidence/independent-review-d2b786e6-result.json`,
  finding `finding-32208ddd3f920dec`.
- **Confirmed source evidence**: `Test-ContinuousCoReviewDigestPathDenied` applies
  `OrdinalIgnoreCase` to every subtree prefix and `IgnoreCase` to every wildcard. On Linux or macOS,
  canonical machinery such as `.github/agents` existing alongside a distinct reviewable
  `.GitHub/agents` removes the latter from the temporary index even though Git treats them as
  separate source, so edits to omitted source can leave the reviewed tree identity unchanged.
- **Relation**: this is the same defect class as DRIFT-198-I009-010 one layer downstream. That
  correction repaired the ignored-path set only and did not reach this case-folding, which is the
  primary evidence that the path-identity class needs one systematic pass rather than point fixes.
- **Correction**: both the subtree-prefix comparison and the wildcard matcher now take their case
  rule from the host - `OrdinalIgnoreCase` on Windows, `Ordinal` on POSIX - matching the
  platform-appropriate contract already proven for `Test-ContinuousCoReviewPathUnderRoot`.
- **Resolution evidence**: a digest-level case-collision regression asserts exact-case machinery and
  secrets stay denied on every platform while a case-distinct path is denied on Windows and kept as
  reviewable source on a case-sensitive host. The digest suite passes.
- **Correction note**: a suspected separator bug in the same branch was investigated and **not**
  found; the subtree probe already used `/`, matching the normalized path.

### DRIFT-198-I009-013 — generated Codex agent mirrors remain in the reviewed candidate

- **Status**: open; gate-reported product defect awaiting human replan
- **Severity**: major machinery-boundary defect
- **Type**: candidate membership
- **Authority evidence**: `evidence/independent-review-d2b786e6-result.json`,
  finding `finding-2d1a04c6f2e879c2`.
- **Confirmed source evidence**: the host-mirror vocabulary omits `.codex` from `$hostDirs`, and the
  generated `.codex/agents` files carry no `.specrew-managed` marker for the scan to find. Disk
  confirms five generated mirrors - `implementer`, `planner`, `retro-facilitator`, `reviewer`, and
  `spec-steward` `.toml` - and no marker file, so all five enter the frozen target while analogous
  host mirrors are stripped. Regenerated reviewer instructions can therefore perturb the certified
  source identity.
- **Required correction**: add the Codex host mirror to the single machinery policy with a paired
  reviewer-visibility regression.
- **Correction**: `.codex` joins the host-mirror vocabulary in the one machinery policy, so its
  generated agent/skill mirrors are stripped with marker or without.
- **Resolution evidence**: a paired fixture proves `.codex/agents` and `.codex/skills` are classified
  as machinery while ordinary user host configuration such as `.codex/config.toml` stays reviewable.

### DRIFT-198-I009-014 — machine-local test report enters the frozen candidate

- **Status**: open; gate-reported product defect awaiting human replan
- **Severity**: major origin-disclosure defect
- **Type**: candidate membership and reviewer-bundle hygiene
- **Authority evidence**: `evidence/independent-review-d2b786e6-result.json`,
  finding `finding-40389710f858ef55`.
- **Confirmed source evidence**: `testResults.xml` sits in the repository root, untracked and
  matched by no ignore rule, so the untracked-product-file inclusion rule pulls it into the target
  digest. Its NUnit environment and suite attributes disclose the origin working directory, machine
  and user identity, and absolute test paths, violating the zero-origin-address reviewer-bundle
  requirement and making candidate identity depend on stale machine-local output.
- **Required correction**: ignore or runtime-classify this artifact, or project sanitized evidence
  outside the reviewed source tree.
- **Correction**: `testResults.xml` joins the canonical per-session classification set, so init and
  update write the ignore rule into consumer projects, and this repository's own `.gitignore`
  now carries it. Git therefore excludes it from the candidate by normal repository policy.
- **Resolution evidence**: `git check-ignore` resolves `testResults.xml` to `.gitignore:72`, and the
  Feature-051 classification and gitignore-write suites remain green.

## Convergence assessment (path identity)

Four consecutive independent review rounds have each reported new defects in the same
path-identity class, every round one level deeper than the correction before it:

| Round | Commit | Path-identity finding |
| --- | --- | --- |
| 1 | `178a3772` | ignored-path set folded case (DRIFT-198-I009-010) |
| 2 | `d2b786e6` | digest denial folded case (DRIFT-198-I009-012) |
| 3 | `5117c807` | case rule taken from OS family, not the volume (DRIFT-198-I009-015) |

The corrections were each locally right and each too shallow, because the defect is structural
rather than local. Direct measurement of the current tree: **four** `IsWindows()`-keyed case
shortcuts and **twelve or more** files carrying their own path comparison, wildcard, or dedup
logic. There is no single path-identity primitive, so every call site re-decides case semantics,
literal-versus-glob semantics, and Git pathspec quoting independently, and a point fix can only
ever repair the one site the reviewer happened to reach.

The durable correction is one shared primitive that (a) determines case sensitivity from the actual
volume or Git worktree rather than the OS family, (b) keeps literal machinery identities distinct
from user exclusion globs, and (c) passes literal Git pathspecs - with every call site routed
through it. That is a design change beyond a point correction and is left for the human's decision
rather than attempted as a fifth consecutive in-flight fix.

### DRIFT-198-I009-018 — the path-identity primitive was never loaded on the consumer's own door

- **Status**: resolved; focused regression green on Linux (WSL Ubuntu 24.04, as root) and Windows
- **Severity**: blocking review-integrity defect
- **Type**: cross-platform path identity — dependency load scope
- **There was never a hang.** The earlier record of this entry described a silent root-only Linux
  hang and excluded three subprocess theories against it. Every observation behind that reading was
  an artifact of the diagnostic tool: `gh run view --log` **truncates per-job output**, and the
  truncated tail was read as silence. Proof: the **green** run at `afb3eda7` truncates at the byte-identical
  line — `Context two-budget accounting wired into the orchestrator (end-to-end)` — and that job
  succeeded. The untruncated log (`gh api repos/<owner>/<repo>/actions/jobs/<id>/logs`) shows all
  twelve suites running to completion and one ordinary failing assertion.
- **Confirmed source evidence**: the real failure is
  `worktree-containment.Tests.ps1:167` — *"Expected $false, because this VOLUME is case-sensitive:
  parent/repo is a DIFFERENT directory from parent/Repo, not under it, but got $true."* Its `Describe`
  loads only `worktree-reviewer.ps1`, never `_load.ps1`, so `path-identity.ps1` was absent from the
  scope in which `Test-ContinuousCoReviewPathUnderRoot` was defined. Every consumer of the primitive
  guarded its call with `Get-Command ... -ErrorAction SilentlyContinue` and, when the lookup missed,
  silently substituted a DIFFERENT comparison — `OrdinalIgnoreCase` for the containment predicates,
  `Ordinal` for the stripping ones. Traced live: `gcFound=False`, `cmp=OrdinalIgnoreCase`. The
  case-distinct sibling therefore compared as *under* the root.
- **Why only Linux failed**: Windows and macOS volumes fold case, so the substituted rule happened to
  match the right answer there and both stayed green. Only a case-sensitive volume exposes it. This is
  the same defect class as DRIFT-198-I009-015 (an OS-family shortcut deciding case semantics), but
  re-entering through the **loader** rather than the comparison — which is why fixing every comparison
  site did not remove it.
- **Reach**: seven call sites across six files carried the silent fallback — `review-design-context.ps1`,
  `review-authority-store.ps1`, `review-target-port.ps1`, `reviewed-state-digest.ps1` (x2),
  `worktree-reviewer.ps1`, and `verification-plan-runner.ps1`. In practice the volume-derived
  correction was dead code on every door that did not go through `_load.ps1`.
- **Latent second defect found in the same pass**: `verification-plan-runner.ps1` invoked
  `Get-ContinuousCoReviewPathComparison` with **no arguments** although both parameters are
  `Mandatory`, so that branch could only ever have thrown under `-NonInteractive`. The OS-family
  branch beside it was the only code that ever ran.
- **Correction**: every consumer now dot-sources `path-identity.ps1` into its own scope at file load
  (the existing `review-linux-runtime-port.ps1` convention), and the per-call-site fallbacks are
  deleted — the primitive is called unconditionally. A fallback that silently answers with a
  different case rule is the defect, not the mitigation.
- **Resolution evidence**: on Linux as root, `worktree-containment` passes 11/0 (was 10 passed, 1
  failed) and path-identity, digest, authority-store, target-port, machinery-paths, origin-path-hygiene,
  fault-matrix, and verification-plan-runner are all green; the same eight suites are green on Windows.
  Two new regressions in `path-identity.Tests.ps1` pin it: one loads each consumer in a CHILD process
  with no shared loader and requires the primitive to be reachable, the other forbids any consumer
  from guarding the primitive with a substitute comparison. `path-identity.Tests.ps1` is now wired
  into `cross-platform-validation.yml` so the primitive is proven on all three volumes.
- **Method note for the next session**: `gh run view --log` and `--log-failed` truncate. For any CI
  diagnosis, read the untruncated job log via `gh api repos/<owner>/<repo>/actions/jobs/<id>/logs`,
  and confirm a suspicious tail against a known-GREEN run before theorising about it. Three CI cycles
  were spent on subprocess theories for a hang that never existed.

### DRIFT-198-I009-019 — git-ignore filter deleted on the disproven hang theory

- **Status**: resolved; focused regression green on Linux
- **Severity**: major candidate-membership defect
- **Type**: regression introduced while chasing DRIFT-198-I009-018
- **Confirmed source evidence**: commit `af5696fc` removed `Remove-ContinuousCoReviewGitIgnoredPath`
  from the machinery scan and replaced it with a hard-coded volatile-root NAME list, on the theory
  that its `git check-ignore` subprocess caused the Linux hang. That theory is now disproven, and the
  removal silently reverted both DRIFT-198-I009-009 (ignored trees add no exclusion and overflow the
  512-path cap) and DRIFT-198-I009-010 (Ordinal identity matching). A name list cannot know that a
  project ignores `scratch/` or `vendor-copies/`; only the repository can.
- **Correction**: two passes, cheapest first — the NAME prune still removes the conventional volatile
  roots without a subprocess, then Git's own ignore policy handles the rest, argument-chunked (never
  through git's stdin, which is the real DRIFT-198-I009-001 pipe-deadlock class).
- **Third defect, in the test itself**: the fixture asserted with `Should -Contain` / `Should -Not -Contain`,
  which are backed by PowerShell's **case-insensitive** `-contains`. It therefore could not tell
  `Scratch/...` from `scratch/...` — the exact distinction it exists to prove — and reported the
  surviving path as a match for the stripped one. It has never passed on a case-sensitive volume; it
  only ever SKIPPED on Windows and macOS, and no CI job on this branch ran it on Linux. Now asserted
  with `-ccontains`.
- **Resolution evidence**: `worktree-reviewer-machinery-paths` passes 8/0 on Linux as root (was 7
  passed, 1 failed) and 7/0 with 1 platform skip on Windows.

### DRIFT-198-I009-015 — case semantics taken from the OS family, not the volume

- **Status**: open; gate-reported product defect awaiting human decision
- **Severity**: blocking containment defect
- **Type**: cross-platform path identity
- **Authority evidence**: `evidence/independent-review-5117c807-result.json`,
  finding `finding-7fa12721aff475fa`.
- **Confirmed source evidence**: `Test-ContinuousCoReviewPathUnderRoot` applies
  `OrdinalIgnoreCase` only on Windows and `Ordinal` on every POSIX host, and
  `Get-ContinuousCoReviewPhysicalPath` preserves caller spelling for ordinary components. macOS
  volumes are commonly case-insensitive, so `/Users/.../repo` and `/users/.../repo` can name the
  same directory yet compare as different, letting `New-GitReviewTargetSnapshot` accept an
  explicitly supplied case-aliased `ExternalRoot` that is physically inside the origin and so
  violate the external disposable-worktree containment guarantee. The same OS-family shortcut in
  `reviewed-state-digest.ps1` - added by the DRIFT-198-I009-012 correction - fails to strip
  case-variant machinery on such a volume. Four such shortcuts exist in the current tree.
- **Exploitability note**: normal operation derives the external root itself rather than taking it
  from the caller, so this needs a deliberately case-aliased explicit root on a case-insensitive
  volume. It is a genuine containment weakness, not a default-path failure.
- **Required correction**: determine case semantics from the actual volume or Git worktree and cover
  both case-insensitive and case-sensitive macOS volumes.

### DRIFT-198-I009-016 — case-insensitive dedup drops distinct machinery paths

- **Status**: open; gate-reported product defect awaiting human decision
- **Severity**: major candidate-membership defect
- **Type**: cross-platform path identity
- **Authority evidence**: `evidence/independent-review-5117c807-result.json`,
  finding `finding-aa7a64741420cc36`.
- **Confirmed source evidence**: `Get-ContinuousCoReviewMachineryPaths` ends with
  `Sort-Object -Unique`, whose default comparison is case-insensitive. On a case-sensitive worktree
  holding two non-ignored marker-detected machinery directories differing only by case, one is
  discarded before the digest builds its strip patterns, so files under the discarded directory stay
  in the frozen candidate despite both being machinery.
- **Required correction**: use a comparer following the worktree's real case semantics, with a
  fixture where both case-distinct marker directories are non-ignored.

### DRIFT-198-I009-017 — literal machinery paths are interpreted as wildcards

- **Status**: open; gate-reported product defect awaiting human decision
- **Severity**: major review-integrity defect
- **Type**: literal-versus-glob path identity
- **Authority evidence**: `evidence/independent-review-5117c807-result.json`,
  finding `finding-eccd3156d99cea58`.
- **Confirmed source evidence**: marker-detected machinery paths are literal repository identities,
  but the digest appends them straight onto the denylist where `Test-ContinuousCoReviewDigestPathDenied`
  evaluates non-subtree entries as `WildcardPattern` values. A legal directory name containing glob
  metacharacters therefore matches unrelated source - machinery `generated[1]` also matches a root
  file named `generated1` - removing real reviewable source from the tree identity, which is the
  false-allow this denylist exists to prevent. The same frozen paths later reach Git pathspec-taking
  commands without literal escaping.
- **Required correction**: keep literal machinery identities separate from user exclusion globs and
  pass them to Git with literal pathspec semantics.

### DRIFT-198-I009-022 — verification support passed literal machinery identities to Git as pathspecs

- **Status**: resolved; focused regression green on Windows and Linux
- **Severity**: blocking review-integrity defect (false-green verification evidence)
- **Type**: literal-versus-glob path identity
- **Authority evidence**: `run-f198-i009-aab37c3b-codex-2`, blocking finding.
- **Confirmed source evidence**: `Get-ReviewCampaignVerificationSupportManifest` passed frozen
  machinery identities straight to `git ls-tree`, and `Add-ReviewCampaignVerificationSupport` passed
  the resulting names straight to `git restore`. Git reads both batches as PATHSPECS, so a legal
  marker-detected machinery name containing `*`, `?`, or `[]` selects a different tracked path. If
  that product path was explicitly excluded it is absent from the snapshot, so the collision check
  does not stop it: the file is restored into the verification copy, can change the command result,
  is removed afterwards, and the post-run digest still matches `target_digest`. That certifies GREEN
  verification evidence for a composition other than the authorized candidate.
- **Relation**: this is DRIFT-198-I009-017 one layer downstream. `ConvertTo-ContinuousCoReviewLiteralPathspec`
  already existed and was already used by the digest; these two call sites simply never routed
  through it - the same "every call site re-decides" pattern the convergence assessment names.
- **Correction**: both batches now convert every path through the literal-pathspec primitive.

### DRIFT-198-I009-023 — case-distinct explicit exclusions were silently collapsed

- **Status**: resolved; focused regression green
- **Severity**: major candidate-membership defect
- **Type**: cross-platform path identity
- **Authority evidence**: `run-f198-i009-aab37c3b-codex-2`, major finding.
- **Confirmed source evidence**: `ExcludedPathPatterns` were normalized with `Sort-Object -Unique`,
  whose default comparison folds case. On a case-sensitive worktree `Foo/**` and `foo/**` are two
  DIFFERENT operator authorities, but one was discarded, so the discarded subtree stayed in the
  reviewed digest and the materialized target despite being explicitly excluded.
- **Correction**: both normalization sites dedupe with `-CaseSensitive`. Keeping both spellings is
  safe on every volume - where the volume folds case they select the same files, and where it does
  not they are genuinely distinct - so this never needs a volume probe. Folding could only ever
  under-exclude.

### DRIFT-198-I009-024 — the source integrity manifest could not represent case-distinct files

- **Status**: resolved; focused regression green
- **Severity**: major review-integrity defect
- **Type**: cross-platform path identity
- **Authority evidence**: `run-f198-i009-aab37c3b-codex-2`, major finding.
- **Confirmed source evidence**: `Get-ContinuousCoReviewWorktreeSourceHashes` stored relative paths
  in a plain PowerShell hashtable, whose string keys are case-insensitive. On a case-sensitive
  filesystem `Foo` and `foo` overwrote the same entry, so the before/after integrity comparison could
  miss a change or deletion of the shadowed file and `source_hashes_before` was not an exact
  manifest of the candidate.
- **Correction**: a `Dictionary[string,string]` keyed with the volume-derived comparer, biased to
  `distinct` when the volume cannot be determined - an extra entry is visible, a swallowed one is not.

### DRIFT-198-I009-025 — managed runtime deployment wrote through untrusted links

- **Status**: resolved; focused regression green
- **Severity**: major security defect (write path)
- **Type**: path containment
- **Authority evidence**: `run-f198-i009-aab37c3b-codex-2`, major finding.
- **Confirmed source evidence**: `Set-ManagedFile` read and overwrote `TargetPath` without rejecting
  reparse points or verifying that the resolved destination stayed inside the project. Every managed
  file the deployment writes goes through it, so a project-controlled junction, directory symlink, or
  managed-file symlink - for example at `scripts/internal/continuous-co-review` - could redirect
  `specrew update` writes onto arbitrary external files.
- **Relation**: the same containment class DRIFT-198-I009-011 closed for the RETIREMENT path. That
  correction guarded deletion and left the WRITE path uncovered, which is why the reviewer found the
  mirror image of an already-fixed defect.
- **Correction**: `Assert-ManagedTargetContained` rejects a reparse point at the project root and at
  every existing component beneath it, and re-verifies containment, BEFORE any read or write.

### DRIFT-198-I009-026 — the volume probe read a case-distinct sibling as proof of aliasing

- **Status**: resolved; focused regression green and EXECUTING (not skipping) on Linux
- **Severity**: major cross-platform path identity defect
- **Type**: defect in the path-identity primitive itself
- **Authority evidence**: `run-f198-i009-aab37c3b-codex-2`, major finding.
- **Confirmed source evidence**: `Get-ContinuousCoReviewPathCaseSensitive` declared a volume
  case-INSENSITIVE whenever a path with the directory's case-flipped name existed. A case-sensitive
  volume may legitimately hold BOTH `Repo` and `REPO` as distinct directories, so the probe returned
  exactly the wrong comparer and every downstream identity then folded genuinely distinct paths. The
  same flaw sat in the child-entry fallback.
- **Honest note**: this defect was introduced by the DRIFT-198-I009-018 correction earlier the same
  day, and the scenario was explicitly considered and wrongly dismissed while writing it. Existence
  of the flipped spelling proves nothing on its own; only the directory LISTING distinguishes a
  folded lookup from two real siblings.
- **Correction**: both probe branches now compare against the parent's enumerated entries - a folded
  lookup resolves a name the parent does not list, whereas two real siblings are both listed.
  Enumeration returns true on-disk names, so the probe stays a pure read and still writes nothing.

### DRIFT-198-I009-027 — a same-named duplicate silently SHADOWED the path-identity primitive

- **Status**: resolved by the systematic sweep; structural enforcement added
- **Severity**: blocking review-integrity defect — and the ROOT CAUSE of the whole convergence pattern
- **Type**: cross-platform path identity, dependency resolution
- **Discovered**: during the maintainer-directed systematic sweep (2026-07-28), not by review.
- **Confirmed source evidence**: `verification-plan-contract.ps1` defined a SECOND function named
  `Get-ContinuousCoReviewPathComparison`, taking no parameters and returning
  `OrdinalIgnoreCase`/`Ordinal` from `$IsWindows`. `_load.ps1` loads that file AFTER
  `path-identity.ps1`, so in every loaded context the duplicate WON. Measured directly:
  `Get-Command Get-ContinuousCoReviewPathComparison` resolved to `verification-plan-contract.ps1`
  with **0 parameters** after `_load.ps1`.
- **Why it was invisible**: the duplicate declared no `param()` block, so PowerShell silently
  swallowed the `-Path` and `-WhenUndetermined` arguments its callers passed instead of failing.
  Every call site that had been "routed through the primitive" - including all six corrected in
  DRIFT-198-I009-018 hours earlier - was still receiving the OS-family answer. The self-load guards
  made it worse: they probed for `Get-ContinuousCoReviewPathComparison`, a name the DUPLICATE
  satisfied, so they never loaded the real primitive.
- **Why five rounds of point fixes could not converge**: each fix was verified at its own call site
  and each looked correct in isolation, because the shadow is invisible locally - the call compiles,
  runs, and returns a plausible comparison. Only enumerating definitions ACROSS the tree exposes it.
  This is the mechanism behind the convergence assessment's observation that every correction was
  "locally right and each too shallow".
- **Impact**: on Windows and on ext4 the shadowed answer coincidentally matched the correct one,
  so nothing failed. On a case-insensitive macOS volume it returned `Ordinal` where the volume folds
  case - DRIFT-198-I009-015 unfixed, despite having been recorded as corrected.
- **Correction**: the duplicate is deleted; `verification-plan-contract.ps1` self-loads the primitive
  and its one caller passes `-Path`/`-WhenUndetermined`. Every self-load guard now probes
  `Get-ContinuousCoReviewPathCaseSensitive`, a name unique to the primitive that no duplicate of the
  comparison function can satisfy.
- **Structural enforcement**: `path-identity.Tests.ps1` now asserts (1) exactly ONE definition of each
  of the five path-identity function names across `scripts/`, (2) no line outside `path-identity.ps1`
  picks a `StringComparison`/`StringComparer` from an `IsWindows` test, and (3) no `Sort-Object -Unique`
  over paths omits `-CaseSensitive` unless explicitly annotated `specrew-dedup-not-a-path`. A seventh
  site can no longer appear silently.

### DRIFT-198-I009-028 — recording a reviewer grant clobbers unrelated host policy

- **Status**: open; recorded not fixed, and TRIAGED into the next replan (maintainer instruction
  2026-07-28: a ledger entry alone is not a disposition). See the `## Triaged to the Next Replan`
  table in file:///C:/Dev/specrew-beta2-hardening/specs/198-beta2-hardening/iterations/009/plan.md
- **Severity**: major governance-integrity defect, consumer-reachable
- **Type**: configuration write scope
- **Observed evidence**: `specrew review --host codex --authorization-ref <ref>` records the grant and
  exits. On 2026-07-27 that single call rewrote `.specrew/reviewer-hosts.json` and, besides the
  intended `authorization_ref`, ALSO: changed the codex row's `model` from the maintainer-pinned
  `gpt-5.6-sol` to `chatgpt`, and nulled the copilot row's `authorization_ref`, destroying the note
  `suspended-2026-07-26-reviewer-independence: the row's claude-4.8 arm cannot be excluded per-run,
  so copilot is not selectable while the implementation host is claude`.
- **Why it matters**: the copilot value was a deliberate reviewer-INDEPENDENCE suspension. Silently
  nulling it could make copilot selectable while the implementation host is claude - the exact
  independence violation it was recorded to prevent. The model overwrite separately destroys the
  pinned reviewer-of-record provenance that review evidence cites.
- **Assessment**: the writer appears to serialize a partially-populated in-memory host model over the
  whole file rather than updating one field of one row, so every unrelated row loses values the
  in-memory model does not carry.
- **Containment applied**: the file was restored from HEAD and the single intended line re-applied by
  hand; the pinned model and the copilot suspension are intact in the committed tree.
- **Required correction (deferred)**: update only the addressed row's `authorization_ref`, preserving
  every other field and row verbatim; add a regression asserting that recording a grant for one host
  leaves all other rows byte-identical.
- **Relation**: distinct from DRIFT-198-I009-007, which records that the declared model is never
  ENFORCED at invocation. This one OVERWRITES the declaration.

### DRIFT-198-I009-029 — a configured verification command inherits the operator's ambient PATH

- **Status**: open; RECORDED not fixed, per maintainer instruction 2026-07-28
- **Severity**: minor diagnosability defect; the fail-closed behaviour itself is correct
- **Type**: verification execution environment
- **Observed evidence**: run `run-f198-i009-aab37c3b-codex` failed pre-spend with
  `verification-command-failed:f198-full-registry:diagnostics-require-command-scoped-disclosure`.
  The registry was red only because the review had been launched from a Git-Bash-derived shell, so
  `pwsh` inherited a PATH placing MSYS `/usr/bin/tar` ahead of `C:\Windows\system32\tar.exe`. MSYS
  tar reads `C:\...` as a `host:path` remote spec and fails with `Cannot connect to C: resolve
  failed`. From a clean PowerShell environment the identical test passes 10/10.
- **What is CORRECT here and must not be "fixed" away**: refusing to spend a paid reviewer slot while
  a configured verification command is red is right, and keeping command output private by default
  is right. No provider budget was consumed.
- **The actual gap**: the stable reason names the failing command but cannot distinguish "your tree is
  red" from "this command could not execute in this environment". The operator reads the former and
  investigates code. Discovering the true cause cost a full 345-second registry run.
- **Required correction (deferred)**: distinguish an execution-environment failure (executable
  resolution, spawn failure) from a command that ran and returned non-zero, and name that distinction
  in the stable reason without disclosing output.

### DRIFT-198-I009-020 — retroactive iteration closeout has no first-class boundary crossing

- **Status**: open; backlog — product gap in Specrew itself, recorded at the maintainer's instruction
- **Severity**: minor governance-mechanism gap
- **Type**: boundary-authorization model
- **Observed evidence**: closing Iteration 003 on 2026-07-27 is a genuine `iteration-closeout`
  decision, but the active lifecycle cursor sat at `tasks` for Iteration 008/009. The Rule 46 stop
  contract requires a trailing `<!-- SPECREW-VERDICT-BOUNDARY: <from> -> <to> -->` marker so the Stop
  hook can capture the human's typed verdict as the authorization. Emitting the canonical
  `retro -> iteration-closeout` would have recorded that crossing against the **active** iteration —
  asserting that Iteration 008/009 entered closeout, which is false.
- **Containment**: the marker was deliberately suppressed for that stop and the suppression was
  stated in the packet, so the human could overrule it. The maintainer confirmed the refusal was
  correct and directed that the gap be recorded here rather than left in conversation.
- **The gap**: the boundary model assumes one moving cursor per feature, so every verdict is a
  crossing of the CURRENT position. It has no way to express "a human authorized a boundary decision
  about a HISTORICAL iteration" — retroactive closure, a correction to a closed iteration, or any
  out-of-band governance repair. The only options today are to mis-record the crossing or to record
  no authorization at all; both are wrong, and the second is what a careful agent will choose.
- **Required correction (deferred)**: give the verdict record an explicit subject — the
  (feature, iteration) the decision is ABOUT — distinct from the cursor position it advances, so a
  retroactive closeout can be captured as real authorization without moving the active cursor. Until
  then, retroactive closures rely on the packet text plus the commit as their authorization trail.

### DRIFT-198-I009-021 — hardening gate cannot express evidence recorded by a successor iteration

- **Status**: open; backlog — product gap in Specrew itself
- **Severity**: minor evidence-honesty gap
- **Type**: hardening-gate schema
- **Observed evidence**: closing Iteration 003 required each blocking concern to leave
  `Runtime Evidence Status: pending-post-implementation`. The schema offers exactly three
  destinations: `recorded` (paired with `Evidence Basis: runtime-evidence`), `not-needed`, or staying
  pending and blocking closure. Iteration 003's residual scope was delivered and proven in Iteration
  007, so the runtime evidence genuinely exists — just not in 003.
- **Why each available value is wrong**: `recorded` + `runtime-evidence` asserts 003 recorded proof
  it never recorded, which is precisely the false-green pattern the gate exists to prevent.
  `not-needed` understates it — evidence WAS needed and does exist. Staying pending blocks a closure
  the maintainer authorized.
- **Disposition taken**: `not-needed` plus an explicit `## Closure Follow-Through` section naming,
  per concern, which controls landed in 003, which landed in 007, and where each one's runtime
  evidence lives. Point, do not claim.
- **Required correction (deferred)**: add a concern-level disposition meaning "runtime evidence
  recorded by a named successor iteration", carrying that iteration reference so the pointer is
  machine-checkable instead of prose the validator cannot read.
