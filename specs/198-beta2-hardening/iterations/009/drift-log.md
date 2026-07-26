# Drift Log: Iteration 009

**Schema**: v1

## Summary

**Total drift events**: 18
**Resolution rate**: 72% (13/18 resolved)
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

### DRIFT-198-I009-018 — Linux review suite hangs since this iteration's corrections

- **Status**: open; UNRESOLVED regression introduced by this iteration. Blocks the tag.
- **Severity**: blocking verification-integrity defect
- **Type**: process/pipe containment, platform-specific
- **Observed evidence**: `Cross-Platform Validation` was green at `afb3eda7` (2026-07-25) and has
  failed on every push since: `183f6efd`, `45853c7f`, `193c7331`, `0059834e`. macOS and Windows pass
  on the later commits; **ubuntu-latest** alone fails. Every failure is identical and silent - the
  job stops mid-`review-spend-allowance.Tests.ps1` in its orchestrator end-to-end context, emits no
  failing assertion and no `Failed: N`, goes quiet for roughly 85 seconds, and the process is killed.
  That signature is a hang, not an assertion failure.
- **Excluded so far**: THREE subprocess hypotheses were tested against CI and all three were wrong.
  Removing the `git config core.ignorecase` probe from the path-identity primitive did not fix it;
  replacing the `git check-ignore --stdin` pipe with chunked arguments did not fix it; and deleting
  the git call from the machinery scan entirely, pruning volatile roots by name instead, did not fix
  it either. All three changes are independently correct and are retained. **The hang is therefore
  not a git subprocess.** Do not spend a fourth cycle on that theory.
- **Execution context that matters**: `cross-platform-validation.yml` runs these suites on Linux as
  ROOT, via `sudo pwsh -NonInteractive -EncodedCommand`, and `review-spend-allowance` is the sixth of
  twelve suites - so the job genuinely stops there rather than finishing. Any hypothesis must explain
  a root-only, Linux-only hang with no failing assertion.
- **Scope note**: the first push bundled every commit of this session, so the culprit is anywhere in
  `afb3eda7..183f6efd`, not only in the path-identity work that the two hypotheses targeted.
- **Required correction**: bisect `afb3eda7..183f6efd` on CI - the failure reproduces only on Linux,
  so a scratch branch pushing intermediate commits is the mechanical next step - then fix the
  identified hang and re-prove all three platforms.

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
