# Iteration State: 010

**Schema**: v1
**Current Phase**: implement
**Iteration Status**: executing
**Last Completed Task**: T003 — workshop-phase + authorized-gate handover frontmatter (surfacing + reader + preserve/clear)
**Tasks Remaining**: T004, T005, T006, T007, T009
**In Progress**: (none — T004 `from_host` fix is next)
**Baseline Ref**: iteration-009 HEAD (`e4822428`)
**Updated**: 2026-06-12T13:00:00Z

## Execution Summary

- **Scope-finalize + handover bug fixes** (commit `b3b9376d`): M2 (hollow-handover detector) + M3 (writer
  hardening). T001 complete (`4e05952f`): SHARED resume reconciliation. T008 complete (`9ed78bde`):
  `specrew start` / antigravity recovery + the D-009 shape-hardening, regression-tested.
- **T002 complete** (FR-022): best-effort conversation capture. New `ConversationCaptureAccessor.ps1`
  component with a FORMAT-RESILIENT 4-tier ladder (structured per-host parse -> raw bounded tail with a
  VISIBLE drift note -> payload `last_assistant_message` -> honest floor), bounded by turns + a hard char cap
  INDEPENDENT of session length. Wired through: dispatcher extracts `transcript_path` from the intact stdin
  event -> clean arg; provider resolves arg/event-json/`CURSOR_TRANSCRIPT_PATH`; `Update-SpecrewRollingHandover`
  renders a new 7th HOOK-owned section 'Recent conversation'. Real-capture confirmed on all 4 hook hosts
  (claude/codex/copilot/cursor) against PRIMARY-SOURCE docs + real on-disk files (see
  `research-host-transcript-exposure.md`); antigravity floor. Committed fixtures + `ConversationCapture.Tests.ps1`
  (4-tier ladder, 20 assertions). FileList + extension-mirror synced.
- **T003 complete** (FR-022): the handover frontmatter now carries the AUTHORIZED gate
  (`last_authorized_boundary` + `last_verdict` = verdict text + human + commit, from `boundary_enforcement`) —
  DISTINCT from `active_boundary` (the working position) — and the workshop phase (`workshop_done` /
  `workshop_remaining` from `Get-SpecrewWorkshopProgress`, only while in-flight). Emitted conditionally
  (quiet otherwise), preserved across the agent body-author, cleared on bound-empty. Reader round-trips.
  `HandoverGateWorkshop.Tests.ps1` (12 assertions). Directly answers the maintainer's "how do I know which
  workshop phase / which gate from the handover file".
- **Schema extension**: T002+T003 extend Proposal 130's fixed schema additively — recorded as drift D-017
  (174-authorized; the handover is a same-machine MIRROR, the durable truth stays committed
  `lens-applicability.json` + git `auth_commit_hash`). `HandoverHookPrimary` recalibrated to 5 mechanical
  sections.
- **T002/T003 hardening pass** (external-review remediation, pre-dogfood): five reviewer findings + one
  latent bug fixed before the maintainer's on-host test.
  - **F2** — the agent body-author (`Write-SpecrewHandoverContext`) was placeholdering every section it
    omitted, ERASING the hook-captured 'Recent conversation'. Now it preserves any AUTHORED hook-owned
    mechanical section the agent omits (surgical: scoped to the mechanical complement + gated on authored).
    Test: `HandoverConversationPreserve.Tests.ps1` (+ `AgentAuthoredHandover` A1-A4 unaffected).
  - **F3** — the transcript read was whole-file (O(session) per PostToolUse). Now `Get-Content -Tail 500`.
  - **F4** — added `DispatcherTranscriptDelivery.Tests.ps1` (real dispatcher -> stub, asserts `--transcript-path`
    + `--source-event` + `--host-kind` delivered). Tier-3 `last_assistant_message` wiring stays DEFERRED.
  - **LATENT BUG (beyond the 5)** — `Invoke-ProviderProcess` launched providers via `Start-Process
    -ArgumentList`, which does NOT quote args containing spaces: a `transcript_path` under a spaced home
    (`C:\Users\First Last\...`, the common case) was SPLIT into several args -> conversation capture silently
    broke for those users (primary clean-arg AND event-json fallback both). Rewrote to
    `ProcessStartInfo.ArgumentList` (correct per-arg Win32 escaping) + ASYNC stdout/stderr reads (pre-WaitForExit,
    deadlock-safe). Tests: `DispatcherTranscriptDelivery` (spaced path byte-for-byte) + `DispatcherLargeStdout`
    (120KB captured intact, 3.2s — no truncation/deadlock on the primitive EVERY provider uses).
  - **F1 (deploy)** — the live `.specify/` dispatcher + catalog are stale and the per-host hook configs lack
    the F-174 stop/handover events; refreshed at deploy time (separate step, surfaced to the maintainer).
- **Proposal-145 structured self-review** (6 phases + adversarial falsification, 12 agents): surfaced TWO real
  bugs the prior tests missed (P2 + P3), both FIXED. (Process honesty: the falsifier WRONGLY refuted P3's UTF-8
  finding as a false positive; an added Hebrew/emoji round-trip assertion EMPIRICALLY proved the corruption is
  real - the reviewer was right, the falsifier wrong. Trust the executable evidence, not the panel verdict.)
  - **P2 (functional)** — `Write-SpecrewHandoverContext`'s F2 preserve lacked the boundary gate its sibling
    `Write-SpecrewRollingHandover` has: an agent authoring a PARTIAL packet at a NEW boundary would resurrect a
    prior-boundary ERA-scoped narrative mechanical (stale "Context"/"What I just did" leak). Now boundary-gated
    via a new `Get-SpecrewHandoverTimeScopedSections` helper — narrative mechanicals reset on a boundary change;
    the TIME-scoped 'Recent conversation' tail still carries across (cross-session continuity). New
    cross-boundary assertions in `HandoverConversationPreserve.Tests.ps1`.
  - **P3 (NFR/encoding)** — REAL non-ASCII corruption (pre-existing; T002 makes it bite): the bootstrap provider
    INLINES the captured handover (incl. 'Recent conversation' — Hebrew/emoji/unicode dialogue) into its
    SessionStart stdout; the child pwsh's default OEM console codepage mangled it to '?' before capture, and the
    dispatcher re-mangled its own stdout to the host. Fixed across all three legs: every emitter (the 3 providers
    + the dispatcher) now declares `[Console]::OutputEncoding = UTF8` (marker `SPECREW-UTF8-OUTPUT`) and the
    dispatcher reads UTF-8 (`StandardOutputEncoding`). Proven end-to-end by a Hebrew+emoji round-trip assertion in
    `DispatcherLargeStdout`; a `ProviderMirrorParity` contract guard pins the declaration on all four emitters.
    HIGH relevance — the maintainer is Hebrew-speaking.
  - **P6/P4 (robustness)** — `Invoke-ProviderProcess`'s success-path async drain is now BOUNDED (5s) so a
    provider that leaves a grandchild holding stdout can't hang the hook; a stuck stream degrades to partial
    output + a loud WARN (the documented fail-quiet-but-loud-once doctrine) instead of silent empty.
  - **P4** — refreshed the now-historical `Start-Process`-mangling comments to the ProcessStartInfo reality.
  - **P5** — added a `$MaxTailLines` tail-bound test (a turn beyond the window is provably skipped).
  - Triaged/deferred (disposition recorded): user-home rollback runbook -> T009 docs; PostToolUse per-call
    latency -> validate in the on-host dogfood; full dispatcher->provider->handover capture integration test
    -> T006 (the deployed-path smoke covered it manually this session).
- **Proposal-145 round-4** (second external review; both reproduced) — TWO more HIGH bugs FIXED, both of which
  would have bitten the on-host dogfood directly:
  - **HIGH (conversation-only skip)** — the material-change gate (boundary OR tracked-file change) returned
    early BEFORE the transcript read, so a pure analysis/conversation turn (clean tree, same boundary) never
    captured its conversation — undercutting T002's core promise. Fix: END-OF-TURN events (Stop/agentStop/stop)
    refresh regardless (PostToolUse + workshop stay gated for cheapness); the activity bullet stays delta-gated
    so a run of conversation-only turns cannot flush real work out of the 6-bullet window (the advisor's catch).
    `ConversationOnlyCapture.Tests.ps1` (4 conversation-only Stops: each captures + the real-work bullet survives).
  - **HIGH (large event-json blocks the provider)** — the dispatcher passed the full raw event (codex's Stop
    carries a 10s-of-KB `last_assistant_message`) as `--event-json` to every provider; it exceeds the Windows
    command-line ceiling, `ProcessStartInfo` refuses to launch, and the handover (so the capture) silently never
    ran. Fix (2b): the dispatcher passes the handover provider ONLY the bounded clean args (no `--event-json`; it
    needs none — source via `--source-event`, path via `--transcript-path`; tier-3 stays deferred). Fix (2a):
    `Invoke-ProviderProcess` CONTAINS a per-provider launch failure (WARN + skip) instead of aborting the whole
    event. `DispatcherLargeEvent.Tests.ps1` (60KB event: a non-handover provider fails to launch + is contained;
    the handover provider still launches with a small argv).
  - LOW: annotated the remaining empty catch in the large-stdout test stub.
  - T009 doc note (carry): with PostToolUse staying git-gated, "last capture = last PostToolUse, seconds" holds
    only for file-editing turns; pure-analysis turns capture at Stop. Soften that doc claim.
- **Proposal-145 round-6** (third external review; both reproduced) — one HIGH (test-integrity + perf) + one
  MEDIUM (resume-truth):
  - **HIGH (parent-repo scan / hang)** — `Get-SpecrewSessionDelta` ran `git status --untracked-files=all` with
    NO check that `$ProjectRoot` is its OWN repo root. When it is not (a non-repo project root that merely sits
    under a parent git repo / worktree - exactly the temp dir the test fixture used, since `$env:TEMP` lives
    under a HOME that is itself a worktree), git scans the WHOLE parent tree: unbounded (the reviewer's hook hung
    twice) AND it reports the parent's files as this project's delta. `try/catch` does not bound a hung external
    process - the only safe fix is to not START the scan. Added `Test-SpecrewIsGitRepoRoot` (`git rev-parse
    --show-prefix`: empty + exit 0 == top-level OR worktree root; non-empty == nested; non-zero == not a repo -
    O(repo-depth), and immune to the 8.3-short-path/casing landmine that sinks a `--show-toplevel` path-compare,
    e.g. `C:\Users\ALON~1.HOM` vs git's `C:\Users\alon.HOME`). `Get-SpecrewSessionDelta` now returns the canonical
    empty shape (new `Get-SpecrewEmptySessionDelta`, single source of truth) when not a repo root. Also git-init'd
    the `SessionBootstrapManager.Tests.ps1` fixture so it is hermetic (its own root, bounded scan) instead of
    leaning on the parent. `SessionDeltaRepoRootGate.Tests.ps1` (repo-root + worktree-root pass; nested -> empty
    delta + the parent's uncommitted file provably NOT scanned; positive branch still scans).
    - **HIGH write-path half** (advisor catch — the HOTTER instance): the reviewer named the read path
      (`Get-SpecrewSessionDelta`, once per session-start), but the SAME ungated `git status --porcelain` lives in
      `Update-SpecrewRollingHandover`'s material-change gate, which fires on EVERY PostToolUse. From a nested root
      that scan walks the parent tree (hangs on the first file-editing turn) AND counts the parent's dirty files
      as this project's change. Gated it with the same `Test-SpecrewIsGitRepoRoot` (not a repo root -> no tracked
      change here, consistent with the now-empty `Get-SpecrewSessionDelta` below it). So the DEFECT CLASS is
      retired across both the read and write paths, not half. `WritePathRepoRootGate.Tests.ps1` (nested +
      PostToolUse + DIRTY PARENT -> wrote=false / no-material-change; repo root still scans + writes on a real
      change). Genuine falsifier verified: with the gate stubbed to always-true the nested root writes
      `tracked-change` off the parent — proving the assertion discriminates, not a vacuous pass.
  - **MEDIUM (stale handover drove resume snapshot)** — `Invoke-SpecrewSessionBootstrap` passed the RAW parsed
    handover into `Get-SpecrewResumeReconciliation` even when `Test-SpecrewHandoverValidity` said invalid, so the
    directive emitted "Last captured stop: <old ts> (boundary <old>)" off a STALE snapshot (violating "invalid
    state is never authoritative resume truth"), AND the stale reason was never surfaced. Fix: pass the handover
    to reconciliation ONLY when valid (the current git delta is still computed from `$null`, so the agent still
    gets the REAL tree - just no stale-snapshot anchor); add the invalid-handover findings (the `Test-...Validity`
    findings, named: "older than the freshness window: ...") to `validation_findings`. `Test-...Validity` now has
    its full `{valid; reason; findings}` result captured (was `.valid` only). `StaleHandoverNoResumeSnapshot.Tests.ps1`
    (stale -> no "Last captured stop", stale ts absent, reason surfaced; fresh control -> snapshot intact, no
    regression). No mirror/`.specify` redeploy: both files are MODULE-internal components (loaded from
    `scripts/internal/bootstrap/` by the provider's 3-tier resolver), not provider-mirror artifacts.
- **Cross-feature reconciliation (F-182 work-kind-branch-governance — MERGES BEFORE F-174)**: F-182 hands three
  items to F-174 at merge time. Verified state on this branch (2026-06-12):
  - **DF-006 (verify the session-start rewrite does NOT reset done->not-started on resume)** — DONE. F-174's
    resume/bootstrap path NEVER invokes the scaffolder (`scaffold-iteration-artifacts.ps1`) and the bootstrap
    components write ONLY the handover / session-marker / journal — they never touch state.md / tasks-progress.yml
    / tasks.md. Locked in by `ResumePreservesIterationState.Tests.ps1` (resume welcome-back AND full bootstrap
    leave committed iteration artifacts byte-identical; no done->pending reset).
  - **DF-005 (neutralize the forge/registry mandate in `launch-contract.ps1` — F-174 owns the file)** — PENDING
    the F-182 merge. F-174 MOVED the bare closeout-SDLC out of `specrew-start.ps1` (now 0 hits there) into the new
    `scripts/internal/launch-contract.ps1:402`, which still carries `gh pr create` / `Find-Module Specrew` /
    `Install-Module Specrew` with no "not a downstream mandate" marker. Neutralize it to F-182's labeled-example
    pattern when reconciling; F-182's widened forge-neutralization CI sweep is the forcing function.
  - **DF-010 (rebase onto F-182's neutralized coordinator sources, do NOT overwrite)** — reconciles CLEANLY.
    F-174 left ALL FIVE of F-182's neutralization targets untouched (coordinator-decision-guidance.md,
    coordinator-response.md, specrew-governance.md, shared-governance.ps1, lifecycle-discipline.md) — it only
    carries their stale PRE-F-182 base, so a rebase onto post-F-182 main inherits F-182's neutralized versions
    with no conflict. The ONE conflict surface is `specrew-start.ps1`: F-174 DELETED the launch-prompt block that
    F-182 neutralized in place (~L2590) -> a delete-vs-modify conflict, resolve in favor of F-174's deletion (the
    block now lives in launch-contract.ps1). F-182 not yet in origin/main; no rebase/neutralization performed.
- **Validation**: ConversationCapture (20) + HandoverGateWorkshop (12) + HandoverConversationPreserve (9) +
  ConversationOnlyCapture (12) + DispatcherLargeEvent (8) + SessionDeltaRepoRootGate (11, round-6) +
  StaleHandoverNoResumeSnapshot (13, round-6) + WritePathRepoRootGate (4, round-6 write-path) +
  ResumePreservesIterationState (12, DF-006) +
  DispatcherTranscriptDelivery (6) + DispatcherLargeStdout (5) + the targeted handover regression set
  (RollingHandover, HandoverValidation, HandoverHookPrimary, ProviderMirrorParity, CoordinatorResumeReconciliation,
  ProjectMetadataAccessor, SessionBootstrapManager, Concurrency, Regression, HostEventAdapter, PerHost) — a 28-suite
  sweep all green; the 3 subprocess-heavy suites (BootstrapProvider, AgentAuthoredHandover,
  HostDeliveryPolicy) stay load-bound (their change-relevant assertions pass; none touch the new primitive's
  hot path — HostDeliveryPolicy invokes the provider directly, not via `Invoke-ProviderProcess`).
- **Carry-forward**: T006 has a down-payment (the two new test files) but stays OPEN for its hard-kill
  simulation + per-host coverage remainder. T002's tier-3 (`last_assistant_message`) is wired in the component
  + tested but not fed by the dispatcher (passing long strings through Start-Process is fragile; the
  `transcript_path` file route is the robust primary) — a deferred refinement if dogfood shows the file route
  insufficient.
- **Next**: T004 (`from_host: host` fix — workshop-skill `--source workshop` passes `--host-kind`).
