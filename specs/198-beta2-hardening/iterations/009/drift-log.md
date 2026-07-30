# Drift Log: Iteration 009

**Schema**: v1

## Summary

**Total drift events**: 30
**Resolution rate**: 73% (22/30 resolved)
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
| 4 | `aab37c3b` | literal pathspecs, two folding dedups, the write path, and the probe itself (DRIFT-198-I009-022 through 026) |
| 5 | `2c6d7cb8` | the sweep corrected the deployed MIRROR, not the canonical source (DRIFT-198-I009-030) |
| 6 | `0e0048b0` | the guard covers one mutator of five; the probe is wrong a third time; `-CaseSensitive` is culture-aware (DRIFT-198-I009-031, 032, 033) |

The corrections were each locally right and each too shallow, because the defect is structural
rather than local. Direct measurement of the tree at round 3: **four** `IsWindows()`-keyed case
shortcuts and **twelve or more** files carrying their own path comparison, wildcard, or dedup
logic. There was no single path-identity primitive, so every call site re-decided case semantics,
literal-versus-glob semantics, and Git pathspec quoting independently, and a point fix could only
ever repair the one site the reviewer happened to reach.

### Root cause, found at round 4-5 (not by review)

The mechanism behind "locally right and each too shallow" is recorded in DRIFT-198-I009-027: a
SECOND function of the same name in `verification-plan-contract.ps1`, loaded after the primitive,
took no parameters and answered from `$IsWindows`. It silently WON in every loaded context and
swallowed the arguments its callers passed. Every call site that had been "routed through the
primitive" was still getting the OS-family answer, which is why fixing each site in turn could not
converge. It was found by enumerating definitions across the tree during the maintainer-directed
sweep — no review round could have found it from a call site, because the shadow is invisible locally.

### What the sweep did close

One primitive in `path-identity.ps1`; the duplicate deleted; every self-load guard probing a name no
duplicate can satisfy; and structural tests asserting exactly one definition of each path-identity
function, no `StringComparison` picked from an `IsWindows` test outside the primitive, and no
case-folding path dedup. A seventh site cannot appear silently. That part holds.

### What round 6 shows it did not close

Round 6 found three more, and their shape is the assessment's real conclusion:

1. **The class was mis-scoped.** DRIFT-198-I009-031 and 033 are not path-IDENTITY defects reachable
   from the primitive at all — one is a containment guard called from one mutator of five, the other
   is a comparer that is case-correct and culture-wrong at eight sites. The sweep enumerated
   comparison and dedup sites. It did not enumerate MUTATORS, and it did not question whether
   `-CaseSensitive` means ordinal. Enumerating the sites of a pattern only finds the pattern you
   already named.
2. **Centralization moved the risk, it did not remove it.** DRIFT-198-I009-032 is the third defect in
   `Get-ContinuousCoReviewPathCaseSensitive`. Now that every site routes through it, one wrong answer
   there is wrong everywhere at once — the "every call site re-decides" failure mode was replaced by a
   single point of total failure.
3. **The tests cannot see it.** The three focused suites pass 39/39 at `0e0048b0`, including the test
   written for exactly the scenario DRIFT-198-I009-032 describes. They were authored from the same
   model as the code. Focused green is not evidence that this class is closed.

Six rounds, three of them after the root cause was found and a systematic sweep applied. The
remaining question for the human was not "which site next" — it was whether this surface can be
certified by review-and-fix rounds at all.

### Resolution — maintainer decision, 2026-07-29

**Review-and-fix rounds are no longer the certification instrument for this surface. The oracle
becomes the volume.**

A differential property harness (`tests/continuous-co-review/unit/path-identity-volume-differential.Tests.ps1`)
creates real fixture trees on each CI runner — case-distinct siblings, case-flipped lookups, composed
versus decomposed Unicode — and asserts the primitive's verdicts against the OS's *observed
enumeration behavior*. No expectation in it is authored: each one is measured on the volume the test
is running on, and nothing is skipped for platform, because where a volume cannot materialize a
scenario the fact that it could not IS the measurement. It runs on the existing three-OS matrix, where
the same assertions have different measured right answers on NTFS, ext4, and APFS — the last being the
POSIX-plus-case-insensitive combination that DRIFT-198-I009-015 was reported for and that no machine
here reproduces.

The instrument was validated by falsification before being trusted: run against the pre-fix primitive
it fails 3 of 6; against the corrected one it passes 6 of 6. Its first revision did NOT fail, for the
reason recorded under DRIFT-198-I009-032 — the old case-folding memo cache answered the second probe
from the first probe's key. That near-miss is the argument for this whole approach in miniature.

Certification evidence for this surface is therefore: the differential harness green on all three CI
volumes, the registry green, and ONE certifying review — not another open-ended round.

Also decided, so it is not decided under pressure later: **if the harness shows this surface cannot
stabilize before the tag, the beta2 release claim narrows and the known path-identity limitations are
documented, rather than spending further rounds.** Beta is the correct vehicle for that honesty.

AST-based enumeration stays on the backlog: the harness dominates it. Grep-based structural tests
catch spellings; the volume catches behavior, which is the thing that was actually wrong.

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

- **Status**: resolved 2026-07-29 — both halves now hold. Routing: every site named below asks the one
  primitive instead of `$IsWindows`, and the shadowing duplicate that made that routing a no-op is gone
  (DRIFT-198-I009-027). Answer: the probe those sites depend on is corrected and, for the first time in
  this class, verified against the filesystem rather than against an authored expectation
  (DRIFT-198-I009-032). The containment predicate specifically is now pinned by a differential test
  that measures whether the volume resolves a case-aliased root to the SAME directory and requires
  `Test-ContinuousCoReviewPathUnderRoot` to answer accordingly — the exploit path described below,
  asserted against the OS instead of argued about.
- **Residual, stated plainly**: proven on Windows/NTFS locally. The macOS case — POSIX host, case-
  insensitive volume, which is the combination this defect was originally reported for and which no
  machine here reproduces — is proven only when the three-volume CI matrix runs the differential
  harness. Until that job is green, this status rests on one volume plus the corrected logic.
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

- **Status**: resolved 2026-07-29. `Get-ContinuousCoReviewMachineryPaths` dedupes through a
  volume-derived `HashSet` comparer biased to `distinct`, so the case-folding `Sort-Object -Unique`
  named below is gone from this site; the comparer's answer is now trustworthy because the probe behind
  it is corrected and volume-verified (DRIFT-198-I009-032); and the same class of dedup has been
  removed from every other site in `scripts/` and both `extensions/` trees, not just this one
  (DRIFT-198-I009-033). The structural test that permitted the intermediate `-CaseSensitive` spelling
  now rejects `Sort-Object -Unique` over paths outright, so this cannot re-enter under a different site.
- **Residual**: the same one-volume caveat as DRIFT-198-I009-015 — full proof needs the three-volume
  differential CI job green.
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

- **Status**: resolved in structure; re-verified in source at `0e0048b0`. The literal-versus-glob
  confusion described below is genuinely gone: `Test-ContinuousCoReviewDigestPathDenied` now takes a
  separate `-LiteralPath` arm matched by `Equals`/`StartsWith` and never constructed as a
  `WildcardPattern`, and DRIFT-198-I009-022 routed the two remaining Git pathspec call sites through
  `ConvertTo-ContinuousCoReviewLiteralPathspec`. Round 6 reported no finding in this sub-class. The
  residual case comparison INSIDE the literal arm still inherits the probe's answer
  (DRIFT-198-I009-032), but the literal/glob distinction itself no longer depends on it.
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

### DRIFT-198-I009-030 — the extensions sweep corrected the deployed MIRROR, not the canonical source

- **Status**: resolved; structural mirror-parity guard added
- **Severity**: major — a security correction that never reached a consumer
- **Type**: source-versus-artifact identity
- **Authority evidence**: `run-f198-i009-2c6d7cb8-sweep`, two of three major findings.
- **Confirmed source evidence**: `.specify/extensions/` is a deployed MIRROR of the canonical packaged
  source at `extensions/`. `specrew init` and `specrew update` load the packaged copy. The extensions
  sweep was applied to the mirror only, so the `Set-ManagedFile` containment guard - the correction
  for the write-through-links finding - was absent from the shipped helper, and the turn-delta dedup
  correction likewise never reached consumers. Measured: the canonical
  `deploy-squad-runtime.ps1` contained zero references to `Assert-ManagedTargetContained` while the
  mirror contained two.
- **Second defect in the same finding**: `Compare-SpecrewTurnSnapshot` kept path keys in ordinary
  PowerShell hashtables, whose string keys fold case, so on a case-sensitive repository `Foo` and
  `foo` overwrote each other. An edit to the shadowed path could yield an empty changed set,
  `material=false`, and NO required conformance packet. The earlier sweep had corrected only the
  `Sort-Object` dedup on those keys, not the maps producing them.
- **Honest note**: this is the same failure shape as DRIFT-198-I009-027 one level up - a correction
  verified against the wrong artifact. The structural tests scanned the mirror because that is the
  tree the sweep had touched, so they confirmed the sweep rather than the shipped product.
- **Correction**: all three patterns applied to the canonical `extensions/` tree; the turn-delta maps
  are `Ordinal`-keyed dictionaries in both trees; the structural tests now scan the canonical source
  as well; and a mirror-parity test asserts that a NAMED safety guard present in one tree exists in
  the other. Deliberately not byte-parity - the trees are legitimately divergent, so byte-parity
  would fail for correct reasons and be disabled.

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

### DRIFT-198-I009-031 — the deployment containment guard covers one mutator, not the four beside it

- **Status**: resolved 2026-07-29 under the maintainer's one-slice instruction. `Assert-ManagedMutationAllowed`
  is now the single choke point in BOTH the canonical `extensions/` source and the `.specify/extensions/`
  mirror, called by `Ensure-Directory`, `Write-MissingFile`, `Set-ManagedFile`, `Set-ManagedBlock`,
  `Set-ManagedTableRows`, and before both recursive host-skill deletes (`Copy-ManagedDirectory`
  delegates to `Set-ManagedFile`; retirement keeps its own DRIFT-198-I009-011 guard). A fifth
  per-mutator copy was deliberately NOT the correction — that is the shape that produced -011, -025,
  and this. Structural enforcement added: `path-identity.Tests.ps1` now enumerates the mutator
  functions in both trees and fails any whose body does not reach the choke point, and separately
  requires the gate within five lines above every `Remove-Item -Recurse`. `Assert-ManagedMutationAllowed`
  joins the mirror-parity guard list.
- **Severity**: major security defect (write path), consumer-reachable
- **Type**: path containment
- **Authority evidence**: `evidence/independent-review-0e0048b0-recert-result.json`, finding
  `finding-f790791bf593e385`, at `extensions/specrew-speckit/scripts/deploy-squad-runtime.ps1:341`.
- **Confirmed source evidence**: measured directly — `Assert-ManagedTargetContained` (defined at line 88)
  has exactly ONE caller, line 158, inside `Set-ManagedFile`. The four other mutators in the same
  shipped script never reach it: `Ensure-Directory` (line 38, `New-Item`), `Write-MissingFile`
  (line 59, `WriteAllText`), `Set-ManagedBlock` (line 341), and `Set-ManagedTableRows` (line 416). A
  consumer-controlled `.squad` or host-skill ancestor junction can therefore redirect `specrew init`
  or `specrew update` directory creation, team/routing/history writes, or host-skill cleanup outside
  the project even though runtime-FILE writes now fail closed.
- **Relation**: the THIRD appearance of this containment class — DRIFT-198-I009-011 guarded deletion,
  DRIFT-198-I009-025 guarded the `Set-ManagedFile` write, DRIFT-198-I009-030 carried 025 to the
  canonical tree. Each correction guarded the door the reviewer had reached. The guard was never
  placed where every mutator must pass through it.
- **Required correction**: a single choke point every read and mutation traverses — including
  directory creation and deletion — rather than a fifth per-mutator call.

### DRIFT-198-I009-032 — the volume probe still misreads the target, and its own tests pass

- **Status**: resolved 2026-07-29, and the ONLY defect in this iteration whose fix is proven by an
  oracle other than its author. The probe now derives every verdict from a name obtained by
  ENUMERATION: it probes inside the physical target using its children, and falls back to reading its
  own entry's REAL spelling out of the parent's listing rather than the caller's. The decision rule is
  factored into `Get-ContinuousCoReviewCaseVerdictFromListing` — both spellings listed means two real
  siblings (case-preserving); exactly one listed while the other still resolves means the lookup
  folded. The memo cache is also now an `Ordinal` dictionary; it had been a case-FOLDING hashtable,
  which is how it masked this very defect (see the falsification note below).
- **Severity**: major cross-platform path identity defect — in the primitive every other correction depends on
- **Type**: defect in the path-identity primitive itself
- **Authority evidence**: `evidence/independent-review-0e0048b0-recert-result.json`, finding
  `finding-a2b8bc687ea88fc8`, at `scripts/internal/continuous-co-review/path-identity.ps1:45`.
- **Confirmed source evidence**: read directly at lines 62-74. The probe flips `probeDir`'s own leaf,
  tests whether `parent/FLIPPED` exists, and if the enumeration of the PARENT lists `FLIPPED` it
  concludes "two real siblings, therefore case-preserving". It never checks whether the caller's
  ORIGINAL spelling is also listed, and it measures lookup in the parent rather than inside
  `probeDir`. `$probeDir` comes from `[IO.Path]::GetFullPath($Path)`, which preserves caller spelling
  and does not canonicalize to the on-disk name, so the case is reachable: where the real entry is
  `REPO` on a case-INSENSITIVE parent and the caller supplied `repo`, the parent lists `REPO`, the
  flipped name matches, and the function returns case-SENSITIVE — the opposite of the truth. A
  Windows case-sensitive directory under an insensitive parent misclassifies the other way.
- **Why this matters more than a single site**: every correction in this class now routes through this
  one function, so a wrong answer here re-opens the case-alias containment bypass of
  DRIFT-198-I009-015 and can re-collapse the distinct candidate paths of DRIFT-198-I009-016 —
  centrally, at all sites at once. The single primitive removed the "every call site re-decides"
  failure mode and replaced it with a single point of total failure that is only as correct as this probe.
- **Honest note — this is the THIRD defect in this same function.** DRIFT-198-I009-018 introduced it,
  DRIFT-198-I009-026 corrected a backwards reading of the same evidence, and this is a third
  misreading of that evidence. The 026 entry already records that the scenario "was explicitly
  considered and wrongly dismissed while writing it".
- **The test evidence is the finding.** `path-identity.Tests.ps1`, `worktree-containment.Tests.ps1`,
  and `worktree-reviewer-machinery-paths.Tests.ps1` were run at this exact tree (commit `0e0048b0`)
  and pass 39/39 with 2 platform skips — including `It 'reads two case-distinct siblings as a
  case-SENSITIVE volume, not an aliased one'`, the test written FOR this scenario. The suites encode
  the same model as the code, so they cannot falsify it. Green focused tests are not evidence that
  this class is closed, and this iteration should stop treating them as such.
- **Required correction**: require BOTH spellings to be enumerated before concluding two real
  siblings exist — if only one of the pair is listed, the lookup folded — and probe inside the
  physical target rather than its parent. Any fix needs a fixture whose assertion can FAIL when the
  probe is wrong, i.e. built from a known on-disk spelling rather than from the probe's own answer.
- **Falsification evidence (the part that matters).** The new
  `path-identity-volume-differential.Tests.ps1` was run against the OLD primitive and the NEW one on
  the same Windows volume: **3 failed / 3 passed** against the old, **6 passed / 0 failed** against
  the new. Independently, the old logic was reproduced verbatim on a fixture holding a real `REPO`
  entry and asked as `repo`: it answered case-**sensitive** on a volume measured case-**insensitive**,
  while the corrected primitive answers `False` under both spellings.
- **Two honest notes about writing that harness.** (1) The first draft PASSED against the broken
  probe. It probed both spellings under one fixture root, and the old case-FOLDING memo cache served
  the second probe the first probe's correct answer — the two spellings collided as cache keys. Only
  isolating each spelling in its own fixture made the assertion capable of failing. A harness that
  cannot fail is worth nothing, and this one silently was not, for its first revision. (2) The
  reported failure only reproduces when `flip(asked spelling)` EQUALS the real on-disk spelling, which
  needs an all-caps/all-lower pair. A `Alpha`/`ALPHA` fixture passes against the broken probe — which
  is a concrete mechanism for how the authored suite stayed green through six rounds.

### DRIFT-198-I009-033 — `-CaseSensitive` is culture-aware, so the integrity key union still folds distinct names

- **Status**: resolved 2026-07-29. All eight sites now route through
  `Get-ContinuousCoReviewOrdinalUniquePath`, which is Ordinal in BOTH dedup and ordering — the order
  matters because several of these lists are hashed into digests, and a culture-dependent order would
  make one tree hash differently on two runners. **Scope went beyond the reported site**: the reviewer
  named `review-target-port.ps1:593`, but direct measurement found the pattern at eight sites in
  `scripts/` plus four more in the `extensions/` trees — `conformance-turn-delta.ps1:214`, which is the
  key union over the very Ordinal maps DRIFT-198-I009-030 introduced, and `validate-governance.ps1:718`,
  in both canonical and mirror. Fixing only the named line would have left the identical defect in the
  shipped product, which is DRIFT-198-I009-030's lesson exactly.
- **Structural enforcement tightened**: the dedup structural test previously ACCEPTED
  `Sort-Object -Unique -CaseSensitive`, which is why this shipped. It now rejects `Sort-Object -Unique`
  over paths outright — there is no correct Sort-Object spelling for a path collection — with the
  existing explicit `specrew-dedup-not-a-path` annotation as the only exemption.
- **Severity**: major review-integrity defect (false-intact integrity evidence)
- **Type**: cross-platform path identity — dedup comparer
- **Authority evidence**: `evidence/independent-review-0e0048b0-recert-result.json`, finding
  `finding-405cb613e49a2e94`, at `scripts/internal/continuous-co-review/review-target-port.ps1:593`.
- **Confirmed source evidence**: `Sort-Object -Unique -CaseSensitive` appears at EIGHT sites —
  `review-target-port.ps1` lines 204 and 593, `review-campaign-orchestrator.ps1` lines 218 and 553,
  `review-run-reconciler.ps1` lines 43 and 45, and `reviewed-state-digest.ps1` lines 162 and 277.
  `-CaseSensitive` flips only the case flag; the comparison stays CULTURE-aware rather than ordinal,
  so byte-distinct but culture-equivalent Git names — composed versus decomposed Unicode spellings on
  a case-sensitive filesystem — still collapse. `Test-GitReviewTargetSnapshotIntegrity` iterates the
  before/after key UNION, so a collapsed key means a modified file is never compared and integrity
  reports intact.
- **Relation**: DRIFT-198-I009-023 and 024 one layer downstream, and a direct falsification of 023's
  recorded reasoning. That entry concluded `-CaseSensitive` "never needs a volume probe" because
  keeping both spellings "could only ever under-exclude". The reasoning was sound about CASE and
  blind to CULTURE. DRIFT-198-I009-024 fixed the source-hash MAPS to ordinal dictionaries and left
  the union that reads them culture-aware.
- **Required correction**: dedupe with a `HashSet` using the same ordinal or volume-derived comparer
  as the maps themselves, and sort only for presentation — at all eight sites, not at line 593 alone.

### DRIFT-198-I009-034 — the gate cannot express a human deferral for a FRESHLY discovered finding

- **Status**: open as a PRODUCT gap, but no longer load-bearing for this iteration — the maintainer
  chose 2026-07-29 to FIX DRIFT-198-I009-028 rather than build deferral vocabulary to carry it,
  because the fix is smaller than the mechanism and the defect was consumer-reachable major in its own
  right. The mechanism gap itself is now explicitly in **iteration 012's finality scope**, not the
  general backlog: a human-observed defect that a fresh reviewer re-discovers has no way to be
  recorded as deferred, and any future iteration that wants to ship with a known, accepted defect will
  hit this wall.
- **Severity**: major governance-mechanism gap — it makes an authorized deferral unrepresentable
- **Type**: review-gate disposition vocabulary
- **Observed evidence**: the maintainer instructed that a recurrence of DRIFT-198-I009-028 be treated
  as a recorded deferral rather than a certification failure. It did recur, as
  `finding-e78c294017b6e4fb` at `scripts/specrew-review.ps1:561`, and the gate has no way to say so.
- **What the machinery does support**: `worktree-reviewer.ps1` line 1022 carries an explicit
  RESOLVED-BY-DEFERRAL instruction — a prior finding is resolved when a worktree-visible record names
  it, records the approving human, and states where the work is carried. Both records exist and are
  worktree-visible (this ledger and the `## Triaged to the Next Replan` table in
  file:///C:/Dev/specrew-beta2-hardening/specs/198-beta2-hardening/iterations/009/plan.md, both under
  `specs/`, which is not stripped).
- **Why it did not engage**: that instruction is scoped to PRIOR-ROUND findings the controller carries
  into the prompt. DRIFT-198-I009-028 was never a review finding — it was observed directly by the
  implementer on 2026-07-27 — so it was in no prior-findings set, and the reviewer discovered the
  defect fresh from source. A fresh discovery gets no deferral check at all.
- **And no disposition can record it after the fact**: the remediation vocabulary is fixed at
  `worktree-review-orchestrator.ps1:318` to `more-time | different-host | narrow-scope |
  accept-partial | override-block | resolved-against-disk | allowance-reset`. None means "known,
  human-deferred, unfixed". `resolved-against-disk` demands a fix commit and would be a false claim;
  `override-block` needs a block to override, and this finding is major, not blocking.
- **Consequence**: `can_approve_current` stays false and this finding will re-appear as a fresh major
  finding in every future round indefinitely. The deferral the maintainer authorized is not
  expressible in the certification path, so it cannot be honoured without either fixing the defect or
  extending the vocabulary.
- **Required correction**: either a first-class deferral disposition that survives across campaigns
  and is surfaced to fresh rounds, or a reviewer instruction to check worktree-visible deferral
  records for newly discovered findings too. Recorded rather than acted on: this is the human's call.

### DRIFT-198-I009-035 — a port scriptblock cannot resolve ambient function names

- **Status**: resolved during the 2026-07-29 slice; caught by the registry, not by review or by the
  focused suites. Recorded because the next edit will hit it.
- **Severity**: minor structural hazard with a major failure mode (a fail-closed preflight, so no
  provider spend — but every campaign run aborts)
- **Type**: scope resolution in port scriptblocks
- **How it surfaced**: routing the integrity key union through the new dedup primitive
  (DRIFT-198-I009-033) inside `New-ReviewProductionVerificationPort`'s `$execute` scriptblock produced
  `The term 'Get-ContinuousCoReviewOrdinalUniquePath' is not recognized` at preflight, in 2 of 82
  registry suites. The primitive was correctly loaded and reachable everywhere else in the process;
  `$execute` is invoked as a PORT in a foreign scope, where ambient function names do not resolve.
- **The convention that already existed, undocumented**: that function deliberately captures
  `Get-Command` OBJECTS for its four other dependencies (`$command`, `$copyCommand`, `$disposeCommand`,
  `$hashCommand`) and invokes them with `&`. Nothing states why, so a plain call reads as correct.
- **Correction**: the primitive is captured the same way, as `$uniquePathCommand`, with the reason
  written down. Its self-load guard probes `Get-ContinuousCoReviewOrdinalUniquePath` — the function
  actually needed — rather than a sibling name: a guard probing a DIFFERENT name than the one it wants
  is exactly how DRIFT-198-I009-027's shadow survived, and a STALE copy of `path-identity.ps1`
  satisfies `Get-ContinuousCoReviewPathCaseSensitive` while lacking anything added since.
- **Why it is worth a ledger entry**: neither the differential harness nor the structural tests could
  catch this — it is not a case-semantics defect and not a spelling the greps look for. Only executing
  a real campaign run found it. It is a concrete limit on what the new instrument certifies: the
  harness proves the primitive's ANSWERS, not that every caller can reach it.

### DRIFT-198-I009-036 — the registry's contamination guard fired on the agent's own concurrent edit

- **Status**: not a product defect — the guard worked. Recorded as a process lesson.
- **Severity**: none (false failure, correctly raised)
- **Type**: test-harness operating discipline
- **Observed evidence**: the first full registry run of this slice reported
  `FAIL (CALLER REPOSITORY CONTAMINATED): tracker honesty check (FR-020) -> tracked/untracked status
  changed`, 1 of 82, at 19.8s. Cause: the run was launched in the background and drift-log.md was
  edited while it was in flight, so the caller repository's tracked status changed mid-run. That is
  precisely what the DRIFT-198-I008-056–058 caller-isolation guard exists to detect.
- **Lesson**: the registry requires a QUIESCENT tree. Backgrounding it to work in parallel on
  governance artifacts invalidates it, and the failure it produces looks like a real regression at
  first glance — which costs a diagnosis cycle. Re-run with no concurrent writes: all 82 green in
  566.6s.

### DRIFT-198-I009-037 — the canonical-vs-mirror correction over-corrected, and the scan scope hid a seventh site

- **Status**: resolved 2026-07-29
- **Severity**: major — one shipped-stale provider plus a blocking CI failure, and an unfixed
  OS-family containment shortcut on a delete-authorizing path
- **Type**: source-versus-artifact identity, and structural-enforcement scope
- **How it surfaced**: `Specrew CI` failed on this branch with
  `FAILED bootstrap suites: ProviderMirrorParity.Tests.ps1`. It was **already failing on `4d807c29`**,
  before the commit that carried the mutation gate, so it was not caused by that work.

**Defect 1 — the DRIFT-198-I009-030 fix treated `extensions/` as canonical for a file where it is
not.** For the `deploy-squad-runtime.ps1` family, `extensions/` IS the canonical packaged source and
`.specify/extensions/` is its deployed mirror; that reading is correct and is what -030 established.
But `specrew-hook-dispatcher.ps1` belongs to the PROVIDER family, whose authoritative copy is
`scripts/internal/specrew-hook-dispatcher.ps1`, with BOTH `extensions/` and `.specify/extensions/`
required byte-identical to it. Commit `0e0048b0` added a `# specrew-dedup-not-a-path` annotation to
the `extensions/` copy only, diverging it from its own source and shipping a stale provider.
`0e0048b0` is the commit whose whole purpose was "apply the sweep to the canonical source, not just
the mirror" — it fixed that error for one family and committed the mirror image of it for another.

**Defect 2, and the reason defect 1 was inevitable — the structural tests scanned
`scripts/internal/continuous-co-review`, not `scripts/internal`.** The dispatcher's `Sort-Object
-Unique` was therefore only visible in the `extensions/` MIRROR, so the annotation could only be put
there. Widening the scan to `scripts/internal` whole immediately exposed a **SEVENTH OS-family case
shortcut** that six review rounds and a systematic sweep never saw:
`review-engine-resolution.ps1:8`, `$comparison = if ([OperatingSystem]::IsWindows()) {
OrdinalIgnoreCase } else { Ordinal }`.
- That is not cosmetic. `Test-SpecrewReviewRuntimePathUnderRoot` gates
  `Assert-SpecrewReviewRuntimePathContained`, which authorizes **deleting** a file named by an
  editable managed-file marker in the target project. On a case-insensitive macOS volume the
  OS-family rule picks `Ordinal`, so a case-aliased path compares as OUTSIDE the root — DRIFT-198-I009-015's
  exploit shape, on a delete path.
- The convergence assessment says "enumerating the sites of a pattern only finds the pattern you
  already named". This is the same failure in the SCOPE dimension: the enumeration was correct and
  the search area was too small.
- **Correction**: all three dispatcher copies re-synced byte-identical from the authoritative
  `scripts/internal/` source with the annotation applied there;
  `Test-SpecrewReviewRuntimePathUnderRoot` routed through
  `Get-ContinuousCoReviewPathComparison -WhenUndetermined 'same'` (the refusing direction for
  containment) with a guarded self-load of the primitive; and BOTH structural tests now scan
  `scripts/internal` whole.

**Defect 3 — the fix for defect 2 broke the deployed runtime, and only an integration suite caught
it.** Routing `review-engine-resolution.ps1` through the primitive means that file self-loads
`continuous-co-review/path-identity.ps1` from a different tree position than every other consumer. In
that arrangement the primitive's functions ended up defined while the file-level
`$script:ContinuousCoReviewCaseSensitivityCache` assignment landed in a different script scope, and
under `Set-StrictMode -Version Latest` reading an unset `$script:` variable THROWS. Result:
`co-review-deploy-completeness.Tests.ps1` failed with
`The variable '$script:ContinuousCoReviewCaseSensitivityCache' cannot be retrieved because it has not
been set` — the deployed co-review runtime could not load at all. Blocking, and invisible to every
focused path-identity suite, which pass because they load the primitive the conventional way.
- **Correction**: the memo is now initialized defensively inside the probe rather than trusting the
  file-level assignment to have run in the scope the function resolves against. Same family as
  DRIFT-198-I009-018 / -027 / -035: the primitive must be correct in whatever scope it is loaded into,
  not only the one its author had in mind. This is the fourth distinct load-scope defect in this
  primitive, which is itself worth carrying into the replan as a signal about the design.
- **Verified**: 25 passed / 1 platform skip across the path-identity family plus the deployed-runtime
  completeness suite; all ten provider parity assertions pass; the review-engine-resolution suite is
  green.

### DRIFT-198-I009-038 — "registry green" is not "CI green", twice over

- **Status**: partially resolved; the remaining gap is recorded, not closed
- **Severity**: minor process defect with major consequences for how evidence is read
- **Type**: verification coverage claims
- **Observed evidence**: two distinct instances in one day. (1) The path-identity family was never in
  `f198-regression-suite.ps1`, so "all 82 suites green" was true through six rounds of path-identity
  defects while none of those suites ran; now registered, 82 -> 87. (2) `ProviderMirrorParity.Tests.ps1`
  is a BOOTSTRAP suite executed by a separate `Specrew CI` step, so the 87-suite registry run was
  green locally while CI was red on this branch.
- **The reporting failure this caused, stated plainly**: the matrix result for `4d807c29` was reported
  as "green on all three volumes" on the strength of the `Cross-Platform Validation` workflow, while
  `Specrew CI` for the same commit was still in progress and later failed. The narrower claim was
  true; the impression given was not. Item 2's pre-authorization was conditioned on the full matrix
  being green, so the certifying review would have been requested against a red tree had the slot not
  been held back for an unrelated reason.
- **Required correction (recorded, not done)**: the registry does not enumerate the bootstrap suites,
  so no single local command reproduces the CI gate. Either register them or state explicitly, in the
  evidence table, that "registry green" excludes them. Until then, a green registry is necessary and
  not sufficient, and every certification claim must cite the CI conclusion per workflow rather than
  one workflow's result.

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
