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
- **Validation**: ConversationCapture (20) + HandoverGateWorkshop (12) + HandoverConversationPreserve (6) +
  DispatcherTranscriptDelivery (6) + DispatcherLargeStdout (5) + the targeted handover regression set
  (RollingHandover, HandoverValidation, HandoverHookPrimary, ProviderMirrorParity, Concurrency, Regression,
  HostEventAdapter, PerHost) all green; the 3 subprocess-heavy suites (BootstrapProvider, AgentAuthoredHandover,
  HostDeliveryPolicy) stay load-bound (their change-relevant assertions pass; none touch the new primitive's
  hot path — HostDeliveryPolicy invokes the provider directly, not via `Invoke-ProviderProcess`).
- **Carry-forward**: T006 has a down-payment (the two new test files) but stays OPEN for its hard-kill
  simulation + per-host coverage remainder. T002's tier-3 (`last_assistant_message`) is wired in the component
  + tested but not fed by the dispatcher (passing long strings through Start-Process is fragile; the
  `transcript_path` file route is the robust primary) — a deferred refinement if dogfood shows the file route
  insufficient.
- **Next**: T004 (`from_host: host` fix — workshop-skill `--source workshop` passes `--host-kind`).
