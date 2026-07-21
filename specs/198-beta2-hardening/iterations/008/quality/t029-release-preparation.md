# T029 Prerelease Preparation Evidence

**Task**: T029
**Starting commit**: `923b16b4fb03db7eea0f61ad1538504e387cc605`
**Target tag**: `v0.40.0-beta2`
**Scope state**: authorized through green release-PR checks; merge, tag, and publication wait for the maintainer

## Authorized Boundary

The maintainer authorized preparation, validation, push, PR creation, and observation of required PR checks.
After those checks pass, the authoring identity must stop. It must not bypass protected-branch review, attempt the
merge, retry a refusal, create the release tag, publish, or promote stable without the maintainer's next explicit
instruction.

## Release Identity Surfaces

| Surface | Required value |
| --- | --- |
| `Specrew.psd1` `ModuleVersion` | `0.40.0` |
| `Specrew.psd1` `Prerelease` | `beta2` |
| Source extension manifest | `0.40.0` |
| Deployed extension manifest mirror | `0.40.0` |
| Installed extension registry | `0.40.0` |
| `.specrew/config.yml` | `0.40.0` |
| Release notes and changelog | `0.40.0-beta2` |

## Required Publication Evidence

After the maintainer authorizes merge and the tag-driven workflow completes, T029 must record all three facts:

1. the immutable tag and commit it resolves to;
2. the **Publish Specrew module** workflow run ID/URL and outcome;
3. the visible PSGallery `0.40.0-beta2` listing.

No stable tag or promotion is part of T029.

## Preparation Validator Correction

The first local release-surface assertion stopped before the broader suite because its extension-manifest regex
anchored `version:` at column zero. Both shipped extension manifests correctly store the base version as the
indented YAML key/value `version: "0.40.0"`; extension surfaces do not carry the prerelease suffix. The maintainer
authorized one corrected validation attempt. The corrected assertion accepts YAML indentation while still
requiring the exact base value `0.40.0`; only `Specrew.psd1` requires `Prerelease = 'beta2'`.

The corrected sequence then exposed a separate prepublication-harness incompatibility. Commit `f01a4dcf` moved
the Docker image to Spec Kit `0.12.9` / Squad `0.11.0`, but the upgrade fixture still bootstrapped published
Specrew `0.27.6`. That baseline calls the removed `specify init --ai` surface and therefore cannot initialize
under Spec Kit `0.12.9` (`--integration` is the replacement). The Devin feature worktree retains the earlier
`0.8.4` / `0.9.1` pins; it did not introduce this Beta2 pin sweep.

The authorized correction makes the historical and candidate identities explicit. Phase 4 keeps the real
`0.27.6` bootstrap under Spec Kit `0.8.4` / Squad `0.9.1`. Phase 5 loads the Beta2 candidate and calls its
production `Update-Specrew -All -SkipUpdateCheck` path, which upgrades the tools to the candidate's exact
`0.12.9` / `0.11.0` `max_tested` pins while refreshing project surfaces. Exact pre/post probes fail closed, and
the contract regression prevents collapsing the two identities, removing Phase 4, or bypassing production update
with harness-owned tool installs.

The one authorized corrected Docker harness run passed on 2026-07-21 in `181.1 s`. It proved all 392 `FileList`
entries, base-version parity at `0.40.0`, exact baseline tool identities, successful published-`0.27.6`
initialization, production-path upgrades to the exact candidate pins, project transition to `0.40.0`, post-update
FileList integrity, and zero duplicate Squad rows. The strengthened harness-contract regression also passed before
the container run. No second Docker harness run was used.

## Release PR Gate Corrections

PR #3090 initially exposed three bounded problems before merge handoff:

- Markdown lint reported 31 mechanical findings across eight historical/current Markdown files. The exact
  PR-changed Markdown surface now passes `markdownlint`, with no content change beyond the necessary nested-code
  wording repairs.
- Independent review found that campaign-mode `specrew review --live` did not reload a project-level recorded
  reviewer authorization. Commit `e305ecec` routes the persisted selected host/model/reference through the existing
  selection policy into the one-slot campaign grant. A real public-command, provider-free regression proves one
  grant fact, zero spend facts, and fail-closed preflight; 85 focused campaign/selection/authorization tests pass.
- Changed-only governance surfaced the already-recorded Iteration 005 missing-`plan.md` exception. Iteration 005 now
  has an archival `abandoned` plan plus matching canonical state fields, following the repository's existing
  post-hoc disposition precedent. It records T035–T039 as delivered and T040 as deferred, does not fabricate a
  review/retro/closeout cycle, and grants no new implementation authority. The explicit Iteration 005 governance
  validation passes.

The subsequent required deterministic gate run `29795301413` exposed seven Linux/aggregate-lane defects rather
than release-surface failures. The bounded correction keeps the proof obligations intact:

- origin-root scrubbing now recognizes foreign Windows absolute paths without resolving them as Unix-relative;
- Linux lease liveness uses the kernel `/proc/<pid>/stat` start tick, with a cross-process regression and
  conservative compatibility for in-flight legacy lease records;
- the detached-service handoff fixture creates its harmless process before installing the Pester mock, avoiding
  Linux mock recursion while still proving that a failed handoff stops the process and releases the lease;
- stale-boundary output and synthetic Windows path-length assertions are lexical and formatting-independent;
- the distribution-upgrade fixture archives one immutable tracked candidate snapshot instead of repeatedly
  copying from a live checkout;
- unprivileged generic Linux skips only the duplicate native-process matrix cases; the dedicated three-OS job
  retains `SPECREW_REQUIRE_POSIX_RUNTIME_PROOF=1`, provisions cgroup v2, and must execute every adapter/runtime
  case.

Local correction evidence is provider-free: the two script regressions pass; Windows Pester records 45 passed and
one Linux-only skip, including all eleven native fake-provider/Job Object cases; WSL Pester records the origin,
lease, service, and generic-lane corrections green, with eleven explicitly reported unprivileged cgroup skips.
The PR remains blocked until fresh required checks verify the committed correction on hosted Windows, Linux, and
macOS.

Fresh deterministic run `29797440970` then passed 71/73 honesty suites and narrowed the remaining red state to
two fixture assertions. The stale-boundary fixture now checks the semantic invariant directly: nonzero refusal,
the exact live 40-hex commit in output, and byte-unchanged authority context, independent of native-error
ANSI/layout. The distribution fixture uses one Git archive for both module simulations; standalone local runs
still snapshot tracked pre-commit edits. No release surface, version, tag, or publication action changed.

Runs `29798607395` and `29800204611` narrowed the aggregate gate to the same 72/73 Linux-only failure. A native
WSL reproduction proved that the archived `.specify` directory existed and was readable: `Test-Path` returned
true, while PowerShell's `Get-Item` excluded the dot-directory as hidden. `Copy-Surface` now uses `Get-Item -Force`.
The same native run then reached the final prompt assertion and exposed its Windows-only separator regex; that
assertion now accepts both native separators. The speculative aggregate commit-pinning machinery was removed; it
did not address the reproduced failure.

Run `29801334882` passed all 73 honesty suites and then exposed two stale release-tree contracts in the broader
bootstrap lane. The bootstrap-provider's canonical/module/project mirrors are re-synchronized byte-for-byte, and
the old TG-004a assertion now reflects T070's approved Claude `UserPromptSubmit` B3/turn-start adapter while still
forbidding the expensive `PostToolUse` registration. The intentional self-host iteration reference keeps its
firewall provenance annotation in all three mirrors.

Run `29802463361` passed the deterministic gate and narrowed the remaining red state to the Linux contract lane.
Production deliberately renders the Windows shell rule only when `$IsWindows`, but the start-command integration
test still required that rule on every platform. The corrected regression preserves the production contract in
both directions: Windows must include both the shell meta-rule and `-LiteralPath` guidance, while non-Windows
prompts must exclude that Windows-only block.

The corrected native Linux contract lane then reached the review replay contract and exposed a campaign-cutover
ordering regression: an explicit unavailable `--host` reached allowance resolution before the promised
honor-or-surface refusal. Cross-platform run `29804856293` caught the first correction masking invalid-design
input on hosted runners without Claude. The campaign application service now validates an explicit host's catalog
entry, executable, and authorization after input/design validation but before authority-store, target, or provider
work. Refusal remains loud, reports the resolved timeout, and writes neither legacy pending state nor campaign
authority evidence.

## Manual Live-Console Init Correction

The maintainer's pre-merge PowerShell 7.6.3 test against candidate
`b5f17296afa7336d6302dc76b02c67d7d12d41df` reached **Running squad init** and waited indefinitely. Squad CLI
0.11.0 branches its two wizard prompts on `process.stdin.isTTY` despite receiving `--non-interactive`; Specrew
captured output while inheriting console input, making the prompt invisible and leaving it able to wait forever.

The correction resolves external applications and Windows npm `.ps1` shims through one cross-platform process
launcher, redirects stdin, and closes it immediately. Both the scratch capability probe and the production Squad
init call use that primitive. The deterministic regression deliberately keeps the parent process's input pipe open;
its fake Squad waits for EOF, so either old call path times out while both corrected paths finish, retain
`init --non-interactive`, observe zero-length redirected stdin, and create `.squad`.

The real packaged-module bootstrap then exposed two adjacent test/consumer hygiene defects. Squad-owned workflow
files were incorrectly counted as additions to Specrew's exact two-file template allowlist; the combined test now
asserts exactness only over Specrew-managed `specrew-*` names while the dedicated source/manifest/deploy allowlist
test stays unchanged. The generated `.specrew/version-check-cache.json` was ignored in the self-host repository but
not in downstream projects; it is now canonical per-session state, ignored before creation, untracked without
deleting its local copy, and idempotent on a second init.

Focused evidence is green: the closed-stdin regression, file-classification pairs, exact Specrew workflow
allowlist, real packaged-module bootstrap, idempotent rerun, command-surface deploy, Crew bootstrap, dry-run
publication, CLI-version behavior, and installed Spec Kit `0.12.9` / Squad `0.11.0` validation. The first bounded
aggregate run passed 73/74 suites; only the T025 distribution-update fixture exceeded 300 seconds because it leaked
an unrelated PSGallery query. Adding its existing `--skip-update-check` test flag left production unchanged and the
same real update assertions passed in 82.5 seconds. Commit `acc39fea9bbafeaca2a21b0b4a183c57f868be80` then
passed all 21 PR checks across exact-head workflow runs `29827129094`, `29827134174`, `29827134218`, and
`29827134230`. Its fresh independent review returned only the bounded-wait note recorded below, so manual retest
and merge handoff remained blocked on that correction rather than on the immediate-EOF implementation.

No provider, merge, tag, workflow dispatch, publication, or stable-promotion action occurred during this correction.

## Independent Review Finding and Fatal-Timeout Correction

Exact-digest Claude run `run-t029-claude-windows-acc39fea-da3428b3-01` reviewed commit
`acc39fea9bbafeaca2a21b0b4a183c57f868be80` at canonical digest
`da3428b344ffb06e2c8688d3697cc4baaa79f512`. Both configured verification commands passed; containment,
termination, validation, and currentness were verified. The run spent its one authorized slot and returned one
note-level finding: the launcher closed stdin but still waited without a production timeout.

The maintainer accepted the robustness correction and clarified the failure semantics: reaching the timeout means
the child failed, so it must never become evidence that `--non-interactive` is unsupported and must never select
the fallback scaffold. The launcher now requires an explicit timeout, requests whole-tree termination, verifies
the process exit, bounds post-kill diagnostic draining, and throws `System.TimeoutException` with stable timeout,
termination, and diagnostic fields. The probe uses 30 seconds and rethrows timeout; production init uses 120
seconds and aborts loudly.

The paired fixture retains the normal open-parent-input/EOF proof and adds a fake Squad that ignores EOF and spawns
a child. A one-second probe bound must throw the typed timeout, report verified termination, and leave the child
dead. Ordinary completed non-support remains the only route to the direct scaffold fallback. The corrected local
Feature 198 registry passes all 74 suites in 787.7 seconds. Hosted verification and exact-digest independent review
remain required before the maintainer's manual retest.

## Run 02 Reconciliation and Follow-on Corrections

Commit `249992b7b6bf7b96da6ade1b4a9f4d648d9c1f9e` passed the required exact-head pull-request workflows:
Specrew CI `29848194319`, Cross-Platform Validation `29848194342`, and Test `29848194521`. A separate
push-triggered Windows job could not resolve Pester from PSGallery; the identical-head pull-request job passed
without a code change, so that transient availability failure did not justify another workflow retry.

Authorized run `run-t029-claude-windows-249992b7-e897e2dd-02` reviewed canonical digest
`e897e2dd8b4f53778b4b2eef54c8a967aa842d65` and spent exactly one provider slot. Claude wrote a complete raw
candidate, but an output-producing progress renderer escaped into the PowerShell pipeline and changed the runtime
result into an array. Terminal publication failed on missing property `process_tree_live`; the contained reviewer
PID was verified dead, and no retry occurred. The maintainer then authorized provider-free reconciliation.
Reconciliation used the immutable spend/recovery facts and existing candidate, invoked no provider, retired the
claim, and published one current/valid partial-incomplete result with `runtime_outcome=abandoned` and verified
termination/containment.

The reconciled result preserves one note finding: after a successful root exit, stdout/stderr `GetResult()` calls
were still unbounded. The correction is paired and narrow:

- orchestration and external-renderer boundaries both discard every progress-sink return value; projection and
  real orchestration fixtures return a sentinel yet publish no extra pipeline object;
- normal output draining uses the same named 10-second bound as timeout diagnostics; a root-exit/descendant-pipe
  fixture must throw the stable typed drain-timeout contract instead of hanging or returning success.

Focused local proof passes the five progress/retro tests, all nineteen campaign-orchestrator tests, PowerShell
parsing, and the cross-platform live-console fixture. The complete Feature 198 registry passes all 74 suites in
910.5 seconds. Scoped governance in the primary worktree correctly refused an unrelated pre-existing local
`state.md` phase edit; the same staged candidate passes from a clean detached worktree in 23.6 seconds with only
historical dashboard warnings. Hosted exact-head CI and a fresh independent review remain required. This
correction grants and spends no provider slot.

## Run 03 Review and Runtime-Progress Boundary Correction

Commit `9b32d8e79ae511b2ac1cf5c97cffac2eb9ae8732` passed exact-head Specrew CI `29856856265`, Test
`29856856269`, and Cross-Platform Validation `29856856271`. Its canonical reviewed-state digest
`f270afb385572d71d08ebeb5cf2fd8bad4900b70` reproduced three times from the clean detached review source.

Authorized Claude run `run-t029-claude-windows-9b32d8e7-f270afb3-03` spent one provider slot. The controller
completed both frozen verification commands before spend, invoked exactly once under verified Windows Job Object
containment, verified target currentness and termination, and published a complete, current, valid result. Claude
verified the progress-renderer and bounded-drain corrections but returned one note-level latent finding: the
runtime sampler still invoked its progress callback without discarding callback output locally. Production did not
currently leak because the upstream orchestration callback returned nothing, but the adapter boundary depended on
that distant invariant.

The correction discards callback output inside `Write-ReviewRuntimeProgressSample`, symmetrically with the two
previously hardened boundaries. A pure sampler fixture makes the callback return a sentinel and proves zero output;
the real Windows Job Object timeout fixture uses an output-producing callback and still receives exactly one scalar
runtime result while retaining heartbeat and process-tree evidence. The focused 14-test progress/runtime set passes.
The complete Feature 198 registry passes all 74 suites in 876.3 seconds. Hosted exact-head verification and a fresh
independent review are required before manual retest and merge handoff.
