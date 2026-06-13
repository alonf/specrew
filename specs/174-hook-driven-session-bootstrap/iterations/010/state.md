# Iteration State: 010

**Schema**: v1
**Current Phase**: implement
**Iteration Status**: executing
**Last Completed Task**: T009 — continuity docs (antigravity no-capture + universal hard-kill floor). ALL TASKS (T001–T009) COMPLETE.
**Tasks Remaining**: (none — ready for iteration-closeout pending the maintainer's codex re-validation of the double-fire fix)
**In Progress**: (none)
**Baseline Ref**: iteration-009 HEAD (`e4822428`)
**Updated**: 2026-06-13T02:00:00Z

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
- **Codex double-hook-call — CONTAINED, root cause not definitively pinned (dogfood finding, 2026-06-12; commit
  `7a9d2086`)**: the cross-host dogfood left a corrupt `session-marker.json` on codex (two JSON objects, same
  session, ms apart) and two SessionStart `b2` injections 7s apart (`refocus-state-unknown.json`). The double-FIRE
  MECHANISM is NOT definitively pinned. Two candidates were examined: (1) a non-idempotent OLDER deploy DID leave a
  duplicate registration — `hooks.json.corrupt.bak` proves it (`hooks` as a JSON array wrapping the event-map PLUS a
  top-level duplicate = 5 dispatcher refs) — BUT that array shape is one codex cannot read (`hooks.SessionStart`
  does not index an array; the top-level keys sit outside `hooks`), so that exact artifact would register ZERO/error,
  not fire cleanly twice; (2) intrinsic codex re-firing (SessionStart emitted >1× at startup) — the 7-SECOND gap fits
  two separate events far better than one event's two registrations firing ms apart, and codex's SessionStart payload
  carries NO session_id (every codex SessionStart collides into `refocus-state-unknown.json`), consistent with a host
  that re-emits. Forensics on `~/.codex/logs_2.sqlite` did not surface codex's own hook-fire records. WEIGHT of
  evidence favors (2). EITHER WAY the harms are now contained + deploy idempotence is locked; the DECISIVE check is
  the next codex run (one vs two bootstrap renders + a single valid marker). If two renders persist it is intrinsic
  re-firing (now harmless: codex gets the lean pointer, the marker is atomic, refocus has its circuit breaker), not a
  registration bug. The CURRENT live `~/.codex/hooks.json` is healed to exactly ONE registration (verified
  empirically against the real corrupt shape). Fixed mechanism-independently:
  - **Atomic marker write** (`Write-SpecrewSessionMarker`): temp + `File.Replace` ($null backup, no `.old`
    clutter). The dest is only ever touched by an atomic rename, so a writer killed mid-write — or overlapping
    fires — can no longer leave it PERMANENTLY half-written (the corruption the dogfood saw). First write -> Move;
    any error -> direct-write fallback (a torn marker is recoverable via fail-open; a MISSING marker is the harm).
  - **Reader fail-open completed** (`Get-SpecrewSessionMarker`): empty/whitespace, an array (two concatenated
    objects — the EXACT dogfood shape), or a parse missing `started_at` now all return `$null` (was a half-true
    all-null object for the empty case). Transient mid-race torn reads stay possible but harmless by this fail-open
    (no Windows rename primitive gives 0 torn reads cheaply; the READER is the correctness guarantee).
  - **Tests**: `MarkerAtomicWrite.Tests.ps1` (round-trip + first-write guards; reader fails open on every torn
    shape; 400×2 concurrent writers -> real reader never throws + final state always a single valid marker);
    `refocus-deploy.tests.ps1` §8b LOCKS the deploy self-heal (seed the exact corrupt.bak topology -> exactly ONE
    SessionStart registration, top-level duplicate gone, 3 dispatcher refs, re-deploy byte-idempotent).
  - **Double-RENDER dedupe** (`specrew-bootstrap-provider.ps1` + `Get-/Write-/Test-SpecrewHookRenderMarker(Recent)`
    in `LauncherIntegration.ps1`): the atomic marker write above fixes the CORRUPTION the double-fire caused; this
    fixes the VISIBLE symptom — the bootstrap directive rendering twice. The provider records a marker
    (`.specrew/runtime/hook-bootstrap-render.json`) AFTER a successful render; the duplicate fire reads it and stays
    silent, keyed on the manager's canonical `dedupe_key` (`safe_session_id`, the SAME id the journal records) PLUS
    the launch `source`. **Record-at-END is the fail-safe**: a first fire that died/timed-out before rendering never
    records, so it never suppresses the retry — the worst case is the status-quo double render, never a MISSING
    directive. The two cases where suppression would be WRONG are structurally excluded: `no-session` (no stable id —
    the self-host repo where codex sends none, any Stop event) is NEVER deduped, and a different `source` (a `/clear`
    re-bootstrap reusing the session id) always re-renders. `Invoke` still runs on the duplicate fire, so the journal
    records BOTH fires (forensic count intact); the journal record now also carries `source` so the next dogfood
    shows directly whether both fires share it (the one assumption code can't prove — codex emits no captured
    `source` to grep). **SCOPE**: the bootstrap directive ONLY — the refocus banner (provider order 10) and handover
    (order 30) also re-run on codex's duplicate dispatcher fire; handover is idempotent (atomic, same content) and
    the refocus-banner doubling is a known BENIGN residual (a dispatcher-level dedupe — the only single point
    covering all three at once — was rejected for highest-in-chain blast radius). `HookRenderDedupe.Tests.ps1` (14:
    unit predicate incl. stale-window + torn/garbage-marker fail-open; integration — 2nd identical fire SILENT,
    `/clear` re-renders, `no-session`×2 both render, both fires journaled with `source=startup`). **DEPLOYED-script
    change** -> the live `.specify/` provider must be re-deployed to a downstream project to validate (an env-var
    relaunch alone won't exercise it). HostDeliveryPolicy test updated (distinct session id per host: one shared root
    + one reused session id would, correctly, self-dedupe).
  - NOTE: codex firing SessionStart with no session_id (sanitized to `unknown` -> all codex SessionStart sessions
    collide into one refocus-state file) is a SEPARATE pre-existing observation; the render dedupe's `no-session`
    guard means those self-host-repo fires are simply never deduped (they always render), so it is unaffected.
- **T004 complete (`from_host: host` fix)**: the design-workshop refresh runs the handover provider WITHOUT
  `--host-kind` (agent-invoked, not via the per-host dispatcher) and, pre-specify, the anchor has no committed host
  either -> `from_host` fell to the literal `host` sentinel (dogfood: codex + copilot). DESIGN EVOLVED from the
  planned "skill passes `--host-kind`": per-host skill baking CANNOT work because `.agents/skills` is SHARED by
  codex AND antigravity (baking one host token mislabels the other — the same deceptive-value failure the
  marker-host fallback has). Instead `Update-SpecrewRollingHandover` now detects the LIVE host from env signals
  (`Get-SpecrewRuntimeHostFromEnv`, mirroring `hosts/<kind>/handlers.ps1` `Get-<Kind>Signals`) — correct across the
  shared root (codex vs antigravity by DISTINCT session vars), never stale (live env), degrading to the honest
  `host` when nothing matches. Resolution chain: `--host-kind` (authoritative) > committed `session_state.host` >
  live env detection > `host` sentinel (env only FILLS the gap, never overrides a known host). Credential-only vars
  (CODEX_API_KEY etc., often globally set) excluded to avoid false matches. `WorkshopHostDetection.Tests.ps1` (11
  assertions: per-host detection incl. the antigravity shared-root discriminator + lone-credential negative; full
  chain incl. `--host-kind` wins + state-host wins + honest sentinel). MODULE-internal single-copy, no mirror sync.
  CAVEAT (pre-existing, out of scope): because env detection sits BELOW `session_state.host`, a STALE committed host
  (codex committed the boundary, claude now runs the refresh) would still mislabel `from_host` as codex. Fixing that
  needs env detection to win over the committed host on the refresh path — deferred; the dogfood gap was the
  literal-`host` sentinel, which this closes.
- **Validation**: ConversationCapture (20) + HandoverGateWorkshop (12) + HandoverConversationPreserve (9) +
  ConversationOnlyCapture (12) + DispatcherLargeEvent (8) + SessionDeltaRepoRootGate (11, round-6) +
  StaleHandoverNoResumeSnapshot (13, round-6) + WritePathRepoRootGate (4, round-6 write-path) +
  ResumePreservesIterationState (12, DF-006) + MarkerAtomicWrite (18, double-fire corruption) +
  HookRenderDedupe (14, double-RENDER dedupe) +
  WorkshopHostDetection (11, T004) + HandoverCrashRecovery (T006 hard-kill) + HostDeliveryPolicy (T007, +cursor) +
  DispatcherTranscriptDelivery (6) + DispatcherLargeStdout (5) + the targeted handover regression set
  (RollingHandover, HandoverValidation, HandoverHookPrimary, ProviderMirrorParity, CoordinatorResumeReconciliation,
  ProjectMetadataAccessor, SessionBootstrapManager, Concurrency, Regression, HostEventAdapter, PerHost) — the full
  `tests/bootstrap` sweep 37/37 green after the double-fire (corruption + render dedupe) + T004/T006/T007 changes,
  plus the full `refocus-deploy` integration suite (incl. the §8b self-heal lock) and the deployed tier-3 floor.
- **T006 complete (tests; M3 was already done)**: the M3 writer hardening shipped earlier (T050 handover
  atomic-replace/`.old`/write-failure-surfacing + the iter-10 marker atomic write), so T006 = the missing TESTS.
  `HandoverCrashRecovery.Tests.ps1` reproduces crash artifacts on disk and locks: torn-live + valid `.old` ->
  reader recovers `.old`; missing-live (delete+recreate-window kill) -> recovers; both-invalid -> honest `$null`
  floor; a FOREIGN-PID `.new`/`.tmp` orphan is NEVER adopted (per-PID isolation); marker torn -> fail-open +
  next-write self-heal. Per-host coverage is already SPANNED (PerHost event-parse, ConversationCapture ladder,
  WorkshopHostDetection from_host x5, HostDeliveryPolicy delivery x4, refocus-deploy bindings x4) — documented,
  not re-manufactured.
- **T007/M1 complete (seam, not an unverified flip)**: factored the inline-vs-pointer delivery into one named
  seam `Get-SpecrewContractDeliveryMode` (default behavior-preserving: claude/copilot/cursor inline, codex
  pointer). EVIDENCE-DRIVEN: the host research matrix documents a 10k `additionalContext` cap ONLY for claude
  (whose SessionStart uses PLAIN STDOUT, so it is unaffected — why inline works for the ~50KB contract); NONE is
  documented for copilot/cursor, so their oversized-drop is SUSPECTED (same envelope codex drops) but UNVERIFIED
  (copilot rendered in-band in the iter-8 dogfood). Per "don't flip delivery on a hypothesis": stay inline, LOCK
  the policy with a cursor test, residual = a one-line flip in the seam once confirmed on-host (both in the
  dogfood loop). `HostDeliveryPolicy.Tests.ps1` extended (+cursor); provider mirror re-synced.
- **T009 complete (docs)**: user-guide Session Continuity + troubleshooting now document the UNIVERSAL hard-kill
  conversation-loss floor (durable state always survives; loss bounded by per-host capture cadence) + antigravity's
  no-capture/recover-via-`specrew start` limit; also fixed a code-truth drift ("six body sections" -> SEVEN, T002
  added `Recent conversation`). markdownlint clean.
- **Carry-forward (not iteration tasks)**: T002's tier-3 (`last_assistant_message`) is wired + tested in the
  component but not fed by the dispatcher (the `transcript_path` file route is the robust primary) — a deferred
  refinement if dogfood shows the file route insufficient. The T007 copilot/cursor oversized-drop verification +
  the T004 stale-committed-host edge are open residuals (both documented above) for the dogfood loop.
- **Next**: ALL TASKS T001–T009 COMPLETE. Ready for iteration-closeout (audit + verdict), pending the
  maintainer's decisive codex re-run validating the double-fire fix (one render + a single valid marker).
