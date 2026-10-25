# Runtime state inventory for the 202 retro: hook paths and authority paths

Read-only research on worktree `C:\Dev\specrew-beta3-stabilization`, branch `202-beta4-1-ux-stabilization`, HEAD `3ebdd195`.
Nothing in the worktree was changed. No scripts or tests were run. Nothing under `.specify/` was read; only the source under
`scripts/`, `scripts/internal/` and `extensions/specrew-speckit/scripts/` was read.

## 0. Baseline correction (read this first)

The brief named `acbb4366ae` as the point where 202 left main. That commit is older than that. The range
`acbb4366ae..HEAD` (784 commits) also holds **feature 199** (beta3 stabilization, from 2026-08-10), **feature 201**
(first-run experience) and the beta4 release fixes. Feature 202's first commit is `3821a05c` (2026-10-13). Its parent,
**`24e5701a` (2026-09-14)**, is the real "before 202" tree.

This report gives three columns of existence for every store:

- **B0**: present at `acbb4366ae`, as the brief asked.
- **P**: present at `24e5701a`, the tree 202 started from.
- **HEAD**: present now.

A store is counted as **"added by 202"** only if it is absent at P. Without this correction the 36 stores that 199 and 201
added would be blamed on 202. Two corrections follow from this:

- `scripts/internal/bootstrap/HumanAuthorityStore.ps1` is **not** new in 202. It was added by `7cb02c04` (2026-08-14, feature 199). No 202 commit touches it.
- `turn-end-store.ps1`, `declare-turn-end.ps1` and `workshop-authority-store.ps1` also existed at P. 202 grew them.

The 202 code diff (`24e5701a..HEAD`, product scripts only) is about 4,000 added lines in 31 files. Most of it is in five files:

| File | Lines changed |
| --- | --- |
| hook dispatcher (two byte-identical copies) | 777 each |
| `turn-end-store.ps1` | 593 |
| `workshop-authority-store.ps1` | 508 |
| `shared-governance.ps1` | 457 |
| `HandoverStore.ps1` | 233 |

The review engine (`scripts/specrew-review.ps1`, `scripts/internal/continuous-co-review/*`) and `HumanAuthorityStore.ps1` have
no 202 code change. The only exception is a refreshed hash manifest, `.specrew-runtime.json`, in `18115d0c`.

## 1. Counts

A "store" here is one file family with one job. A directory of per-run or per-session files counts as one store, and a lock
file that belongs to a journal counts as one store for all journals.

| Point | Stores on the hook and authority paths |
| --- | --- |
| B0, `acbb4366ae` | **42** |
| P, `24e5701a` (just before 202) | **78** (36 added by features 199 and 201 and the beta4 fixes) |
| HEAD | **90** |
| Added by 202 | **12** (all 12 still present) |
| Removed by 202 | **0** |
| Already existing, changed in shape or write behaviour by 202 | **9** |
| Changed in shape again **during 202's own review rounds** | 4 of the 12 new stores, plus 1 older one (section 4) |

Of the 12 stores 202 added:

- **2 have no reader**: `turn-end/.../turn-message.md` and `reply-recording-recovery.jsonl`.
- **1 is read only to copy a field into another store**: `session-start.json`.
- **7 belong to one family**: the hook-output journal and the recovery of that journal.

## 2. Inventory at HEAD, with before-202 status

Short names:

- `R` = `.specrew/runtime`.
- `SR` = `R/conformance-sessions/<own>`, the per-session folder, where `<own>` is the sha256 of `host|session`. With no session id, `SR` falls back to `R` with a `conformance-` name prefix.
- `TER` = `R/turn-end/<own>`.
- `CMP` = `.specrew/review/authority/campaigns/<id>`.

Source files:

| Short name | Source file |
| --- | --- |
| DISP | `scripts/internal/specrew-hook-dispatcher.ps1`, byte-identical to the `extensions/` copy |
| TES | `turn-end-store.ps1` |
| CP | `specrew-conformance-provider.ps1` |
| WAS | `workshop-authority-store.ps1` |
| HAS | `HumanAuthorityStore.ps1` |
| HS | `HandoverStore.ps1` |
| SG | `shared-governance.ps1` |
| SBS | `scripts/internal/sync-boundary-state.ps1` |
| BP | bootstrap provider |
| SRV | `scripts/specrew-review.ps1` |
| ORCH | `review-campaign-orchestrator.ps1` |
| GATE | `review-signoff-evidence-gate.ps1` |
| NAV | `continuous-co-review-navigator.ps1` |

Status column:

- **base**: present at B0.
- **199/201**: absent at B0, present at P.
- **202**: absent at P. The introducing commit is given.
- **202Δ**: a store that already existed and that 202 changed.

### 2a. Hook paths: dispatcher, turn-end store, declare-turn-end, SessionStart, UserPromptSubmit and Stop handlers

| # | Store (path pattern) | Format | Scope | Writer(s) | Reader(s) | Decision it feeds | Retention | Status |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | `SR/turn-token.json` | json | per-session, open turn | `Write-SpecrewTurnToken` (TES), called by CP at SessionStart and prompt | `Read-SpecrewTurnToken` (CP); `Get-SpecrewLiveTurnTokens` and `Resolve-SpecrewTurnTokenHolder` (declare-turn-end) | Which session a turn-end declaration belongs to | Removed by `Remove-SpecrewTurnToken` at a real Stop. Leftovers after a crash never age out | 199/201 (`6d296d21`) |
| 2 | `SR/turn-counter.json` | json `{turn}` | per-session | `Step-SpecrewTurnCounter` (CP Stop) | `Get-SpecrewTurnId` (TES) | The current `turn-N` id | Overwritten, never deleted | 199/201 (`dfae6133`) |
| 3 | `SR/turn-material.json` | json | per-session, per-turn | `Write-SpecrewTurnMaterialVerdict` (CP Stop) | `Read-…`, `Test-SpecrewTurnMaterialVerdictQuiet` (navigator provider) | Whether the "not reviewed" advisory stays quiet | Overwritten; 120 s freshness | 199/201 (`d0312a4a`) |
| 4 | `TER/turn-N.json` | json | per-session, one file per turn | `Write-SpecrewTurnEndRecord` (declare-turn-end) | `Read-SpecrewTurnEndRecord` (CP Stop); `Get-SpecrewInFlightRepeatCount` scans every file | Declared turn kind; in-flight bound of 3; meaning-line check | **Never deleted**; grows one file per turn | 199/201; **202Δ**: `meaning_lines` (`8904b71f`, T007), `draft_*` fields (`b9cf8b71`, T014) |
| 5 | `TER/turn-message.md` (or `R/turn-end/token-<tok>/turn-message.md`, or shared `R/turn-end/turn-message.md`) | md | per-session, per-token or shared | `Save-SpecrewTurnDraft` (declare-turn-end) | **none** | None. A copy of the draft, which is also stored in the record's `message` field | Overwritten; token folders never cleaned | **202** (`b9cf8b71`, T014) |
| 6 | `TER/presented-crossings.json` | json `{id, approval_phrase, packet tag, reviewed_artifact_state[], presented_at, session_start_kind, verdict_reply_at}` | per-session, per pending boundary | `Write-SpecrewPresentedCrossing` (CP Stop); `Register-SpecrewPresentedCrossingReply` (CP prompt) | `Get-SpecrewPresentedCrossingDecision` (TES via CP) | Suppress repainting an unchanged pending-boundary packet in this session | Cleared on every SessionStart | **202** (`0b62bf9b`, T006) |
| 7 | `TER/session-start.json` | json `{kind, at}` | per-session | `Write-SpecrewSessionStart` (CP SessionStart) | `Write-SpecrewPresentedCrossing` (copies `kind` into #6) | Diagnostic only | Overwritten | **202** (`0b62bf9b`) |
| 8 | `SR/orientation-rendered.json` | json `{rendered_at}` | per-session | CP Stop (inline write) | CP dials lane and Stop check; BP first-prompt lane; TES builds an unused `OrientationPath` | The session still owes an orientation | Never deleted | 199/201 (`2f57e49a`); **202Δ**: BP became a reader (`aac6a3fa`) |
| 9 | `SR/dials-line-supplied.json` | json `{supplied_at, line}` | per-session | CP prompt lane | CP (`Test-Path`) | Supply the dials line once per session | Never deleted | **202** (`8904b71f`, T007) |
| 10 | `R/hook-bootstrap-orientation-<sid>.json` | json flag file | per-session (raw session id) | BP first-prompt lane | DISP (skip BP on later prompts); BP; CP (suppress the dials line) | Orientation already supplied with the first prompt | Removed only by `Clear-DispatcherUndeliveredOrientationStamp` when that fire's output was withheld (`61714dbd`, round 4) | **202** (`aac6a3fa`, T008) |
| 11 | `R/hook-bootstrap-render-<key>-<src>.json` | json claim (CreateNew) | per-session, per SessionStart source | `Request-SpecrewHookRenderClaim` (LauncherIntegration) | same function; CP Stop | One bootstrap render per session and source | Never deleted, by design | base; **202Δ**: the CP reader narrowed to this session (`aac6a3fa`) |
| 12 | `R/hook-output-authority.jsonl` | jsonl `{output_hash, event, host, output_kind}` | project | `Write-DispatcherHookOutputAuthorityRecord` → `Add-DispatcherJournalText` (DISP); flush in `Complete-DispatcherHookOutputRecovery` | `Test-DispatcherHookOutputJournalText` (DISP, turn origin); `Test-SpecrewWorkshopResponseIsHookOutput` (WAS); `Get-SpecrewReplyRecordingHealthLine` (SG) | Typed text that equals Specrew's own output is not a human reply | Append-only; moved aside after a human-approved recovery | 199/201 (`7cb02c04`); **202Δ**: the record shape is the same, but the write path was rewritten (`aa2ffb7b` T003: no latch, retry, buffer, health) and gained a Unix lock (`34af7076`, round-1 fix) |
| 13 | `R/hook-output-authority.set-aside-<ts>.jsonl`, `…unhealthy.set-aside-<ts>.txt` | jsonl / txt | project | `Invoke-SpecrewReplyRecordingRecoveryIfApproved` (WAS, move) | DISP origin check; WAS reader (both still read set-aside files) | Same as #12 | Never deleted | **202** (`0edfb321`, T004) |
| 14 | `R/hook-output-buffer/<pid>-<guid>.jsonl` (temp `.writing`, claimed as `.flushing-<guid>.jsonl`) | jsonl, one closed file per failed append | project | DISP degraded path; renamed by `Complete-DispatcherHookOutputRecovery` | DISP origin check; WAS; SG health line (counts files) | Outage buffer that still counts as recorded output | Removed after a flush if the length is unchanged | **202** (`aa2ffb7b`); `.flushing` (`34af7076`, round 1); one closed file per record (`0b62bf9b`, round 2) |
| 15 | `R/hook-output-health.jsonl` | jsonl, degraded and recovered transitions | project | `Write-DispatcherHookOutputHealth` (DISP) | `Get-DispatcherLastHealthRecord` (DISP); `Get-SpecrewReplyRecordingDegradedSince` (WAS); `Get-SpecrewReplyRecordingHealthLine` (SG) | Start time of a degraded episode, which drives the recovery question and the disclosures | Append-only, never rotated | **202** (`aa2ffb7b`, T003) |
| 16 | `R/hook-output-authority.jsonl.unhealthy` | text flag file | project | **no writer at HEAD** (the pre-202 DISP wrote it) | `Complete-DispatcherHookOutputRecovery` deletes it; WAS moves it aside; SG checks it | Pre-202: refused every reply (the latch). Now it is legacy and only cleared | Deleted or moved | 199/201; **202Δ**: semantics removed (`aa2ffb7b`) |
| 17 | `<journal>.lock` (for `hook-output-authority.jsonl` and `hook-output-health.jsonl`) | empty lock file | project | `Enter-DispatcherAppendLock` (DISP, non-Windows only) | same | Serializes Unix appends | **Never deleted** | **202** (`34af7076`, round-1 fix). Budget per fire from `46d18d82` (DRIFT-023) |
| 18 | `R/refocus-state-<sid>.json` | json, breaker and 20-entry ring | per-session | `Save-SessionState` (DISP); `Invoke-RefocusResetBreaker` | `Read-SessionState`, breaker tests (DISP) | Refocus de-duplication and circuit breaker | Pruned after 7 days | base |
| 19 | `R/refocus-channel1.json` | json `{boundary, at}` | project | body of `extensions/.../sync-boundary-state.ps1` | `Get-ChannelOneFingerprint` (DISP) | Refocus de-duplication after a sync | Overwritten | base |
| 20 | `R/session-marker.json` | json | project, last writer wins | `Write-SpecrewSessionMarker` (SessionStateAccessor) | ClassificationEngine; `Get-SpecrewCrossingOwnerIdentity` (SG); hook-health | Concurrency advisory; owner fallback for the pending boundary; "are hooks active?" | Overwritten | base; **202Δ** (minor): the session id now comes from the T002 turn record (`7bb8028f`) |
| 21 | `R/bootstrap-journal.jsonl` (+ `.append.lock`) | jsonl | project | `Add-SpecrewBootstrapJournalRecord` (HookJournalAccessor) | `Test-SpecrewBootstrapDirectiveArrived` (hook-health) | Did the bootstrap fire this session | Append-only | base |
| 22 | `R/launcher-bootstrap.json` | json | project | `Write-SpecrewLauncherBootstrapMarker`: **tests only, no production caller** | `Test-SpecrewLauncherBootstrapRecent` (BP) | Launcher-to-hook de-duplication. In practice it can never fire | Overwritten | base, **dead** |
| 23 | `R/hook-degradation-warned-<sid>` | text flag file | per-session (a third key form) | `Get-SpecrewHookDegradationWarning` | same | Warn once that hooks look inactive | Never deleted | base |
| 24 | `R/hook-health/<host>-<surface>-<event>.json` | json | project, per host and event | `Write-SpecrewHookHealthReceipt` via `Write-DispatcherHookHealthReceipt` | `Resolve-SpecrewHookHealth`, `Get-SpecrewHookEventCoverage` | Proof that the hooks fire | Overwritten per key | base |
| 25 | `R/handover-journal.jsonl` | jsonl diagnostic events | project | HS (verdict capture, disclosures, rolling handover); SG (refusal and seal events); WAS (`workshop-confirmation-not-bound-disclosed`) | no program reader (`validate-governance.ps1` and humans) | Diagnostics | Append-only | base |
| 26 | `.specrew/handover/session-handover.md` (+ `.old`) | md | project | `Write-SpecrewRollingHandoverContent` (HS) | `Get-SpecrewRollingHandover`, `Get-SpecrewResumeFromDisk` | Resume notes (context, not authority) | Rolling, one `.old` kept | base; 202 (`488468fe`, T012) changed only how it is read |
| 27 | `SR/stop-block.json` | json `{key, count, epoch}` | per-session | `Set-SpecrewBlockCount` (CP) | `Get-SpecrewBlockCount`, `Get-SpecrewBlockRecord` (CP) | Cap of 3 consecutive stop blocks | Deleted when compliant | base |
| 28 | `SR/continue-guard.json` | json | per-session | `Set-SpecrewBlockCount` inside an **unreachable** branch (CP) | none | Intended guard against a runaway `continue` | n/a | base, **dead** |
| 29 | `SR/last-fire.json` | json `{identity, epoch}` | per-session | CP Stop | CP | Ignore a duplicate Stop within 60 s | Overwritten | base |
| 30 | `SR/material-satisfied.json` | json `{key, epoch}` | per-session | `Set-SpecrewMaterialSatisfiedKey` (CP Stop) | `Get-SpecrewMaterialSatisfiedKey` | Do not ask again for a material surface already covered | Overwritten | base |
| 31 | `SR/material-nudged.json` | json `{key, epoch}`, same writer as #30 | per-session | CP PostToolUse | CP | One nudge per surface | Overwritten | base |
| 32 | `SR/turn-baseline.json` | json git snapshot | per-turn | `Write-SpecrewTurnBaseline` (conformance-turn-delta) | `Read-SpecrewTurnBaseline` | Material-work change for this turn | Overwritten each turn | base |
| 33 | `SR/cap-facts.jsonl` | jsonl | per-session | `Write-SpecrewCapFact` (CP) | `Test-SpecrewCapFactRecorded` | Announce a capped stop once | Append-only | 199/201 (`1331449f`) |
| 34 | `R/conformance-journal.jsonl` | jsonl diagnostics | project | CP | **none** | Diagnostics only | Never pruned | base; **202Δ**: new fields `presented_*` (`0b62bf9b`), `dials_missing_not_blocked` (`8904b71f`), `orientation_not_shown_not_blocked` (`aac6a3fa`) |
| 35 | `.specrew/active-sessions.yml` | yaml | project, per feature × machine | `Register-SessionLock`, `Remove-SessionLock`, cleanup (`session-management.ps1`, `session-recovery.ps1`) | `Test-SessionCollision` (`specrew-start.ps1`) | Two machines on the same feature | Stale after 24 h | base |

### 2b. Workshop authority (receipts, recovery requests)

| # | Store | Format | Scope | Writer(s) | Reader(s) | Decision it feeds | Retention | Status |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 36 | `specs/<f>/lens-applicability.json` (workshop controller state) | json | per-feature | initialize, confirm-agenda, confirm-lens, repair scripts | WAS receipt writer; design-analysis gate; ProjectMetadataAccessor; CP | Which workshop steps are legal; whether design-analysis passes | Durable artifact | base |
| 37 | `R/workshop-authority.jsonl` (+ `.lock`, deleted after each write) | jsonl receipts | project | `Write-SpecrewWorkshopAuthorityReceipt` (WAS, from HS at prompt) | `Get-/Test-SpecrewWorkshopAuthorityReceipt`; confirm-agenda; confirm-lens; gate; CP | A typed human receipt that lets a lens or agenda close | Never pruned | 199/201 (`5bb77132`). The record is unchanged in 202; the writer gained turn-origin and session checks (T002/T004, round 1) |
| 38 | `R/workshop-receipt-outcomes.jsonl` | jsonl `{status, cause, response_hash, session_id}` | project | `Set-SpecrewWorkshopReceiptOutcome` (WAS; every exit of the receipt writer) | `Get-SpecrewWorkshopLatestRefusal` (CP); `Get-SpecrewWorkshopTurnReceiptOutcome` (DISP) | Same-turn disclosure of a refused or degraded reply | Never pruned | **202** (`0edfb321`, T004); `session_id` added in `5c56dbed` (round 5) |
| 39 | `.specrew/handover/workshop-question.json` | json v3 | project singleton | `Update-SpecrewWorkshopQuestionHandover` (CP Stop) | WAS receipt writer and disclosure; CP | Binds a typed reply to the open workshop question | Rewritten or deleted every Stop | base (v3 from `5bb77132`, 199/201) |
| 40 | `.specrew/handover/workshop-agenda-proposal.json` | json | project singleton | confirm-agenda `-RenderOnly` | CP | Proof that the agenda was shown before it was confirmed | Deleted on confirm | 199/201 (`cc00c504`) |
| 41 | `.specrew/handover/workshop-controller-repair-proposal.json` | json | project | repair script `-Request` | `Write-SpecrewWorkshopRepairAuthorization`; repair apply | The repair a human can approve | Deleted after apply | 199/201 (`dc56de97`) |
| 42 | `R/workshop-controller-repair-authority.jsonl` (+ `.lock`) | jsonl | project | `Write-SpecrewWorkshopRepairAuthorization` | `Get-SpecrewWorkshopRepairAuthorization`; repair apply | The typed approval that must exist before a repair | Never pruned | 199/201 |
| 43 | `R/workshop-controller-repair-history.jsonl` | jsonl | project | repair apply | **none** | Audit only | Never pruned | 199/201 |
| 44 | `specs/<f>/design-decisions.json` | json map | per-feature | `record-design-decision.ps1` | `Read-SpecrewDesignDecisions`, called **only by its own writer** | Nothing at HEAD (the script says "the gate reads it"; no gate does) | Durable | 199/201 (`dfae6133`) |
| 45 | `R/reply-recording-recovery-request.json` | json `{asked_at, asked_session, degraded_since, question_hash, declined_at?}` | project file, answerable by one session | `Get-SpecrewReplyRecordingRecoveryAsk` (WAS); `declined_at` written by `Invoke-SpecrewReplyRecordingRecoveryIfApproved` | `Get-SpecrewReplyRecordingRecoveryRequest` (WAS); HS; `Clear-DispatcherUndeliveredRecoveryRequest` (DISP) | Whether the "set the stuck record aside?" question is open, and which session may answer it | Deleted when stale, when recovered, or when the question was not delivered | **202** (`0edfb321`, T004); `asked_session` (`0b62bf9b`, round 2); re-ask on threshold (`61714dbd`, round 4); `declined_at` and undelivered rollback (`5c56dbed`, round 5) |
| 46 | `R/reply-recording-recovery.jsonl` | jsonl `approved / declined / result` | project | `Invoke-SpecrewReplyRecordingRecoveryIfApproved` | **none** | Audit of the human's answer (written before the action) | Never pruned | **202** (`0edfb321`) |

### 2c. Boundary authority (approval and verdict capture, boundary ledger, pending decisions)

| # | Store | Format | Scope | Writer(s) | Reader(s) | Decision it feeds | Retention | Status |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 47 | `.specrew/start-context.json`: `session_state{…}` and `boundary_enforcement{last_authorized_boundary, pending_next_boundary, pending_crossing{…}, verdict_history[], correction_history[], bypass_history[]}` | json, whole file rewritten via a temp file; **no lock** | project | `Update-SpecrewStartContext` (SBS); `Set-SpecrewBoundaryEnforcementState` (SG), used by `Add-SpecrewBoundaryAuthorization` (verdict capture), `Set-SpecrewPendingBoundaryCrossingScope`, `Test-SpecrewBoundaryAuthorization`, and the bypass, correction and initialize writers | `Get-SpecrewBoundaryEnforcementState`, `Get-SpecrewPendingVerdictState`, `Resolve-SpecrewActiveFeature`, HS resume, `readiness-verdict.ps1`, the boundary gate | **The boundary approval ledger**: what is authorized and which boundary step waits for a human verdict | Histories grow without limit | base; **202Δ**: `session_state.branch` (`55e0dddc`, T010); `feature_ref` on `verdict_history[]` and on the pending boundary (`f46c9fb1`, T011, see section 7); `identity_version = 2` with the feature hashed into the pending id (`5c56dbed`, round 5) |
| 48 | `R/pending-verdict-stop.md` | md: boundary, approval phrase, packet tag with id, last authorized boundary, commit, tree | project | `Sync-SpecrewPendingVerdictStopArtifact` (SBS); `Sync-SpecrewPendingVerdictArtifactAfterAuthorization` (HS) | CP; declare-turn-end; `launch-contract.ps1`; packet renderer | Tells the agent to stop, and gives the exact phrase and tag | Deleted when nothing is pending | base |
| 49 | `.specrew/last-start-prompt.md` | md with `session_state_*` frontmatter | project | SBS (`Update-SpecrewMarkdownStateFile`); `specrew-start.ps1` | session-recovery, refocus, BP, validate-governance, worktree-awareness | Restores the position on resume (the launch contract) | Overwritten each sync | base |
| 50 | `.squad/identity/now.md` | md, same frontmatter | project | SBS | Squad readers | Copy of the position | Overwritten | base |
| 51 | `.squad/decisions.md` (+ `.lock` taken by `Invoke-WithFileLock`) | md ledger entries ("Boundary sync", "Boundary enforcement: …") | project, tracked | `Add-DecisionsLedgerEntry` via SBS and SG writers | `Get-LatestSpecrewBoundarySyncState` (sync, coordinator-resume, session-recovery, SRV) | Last synced boundary; resume | Append-only | base |
| 52 | `.squad/events/lifecycle-events.jsonl` | jsonl | project | `Add-SpecrewLifecycleEvent` (SBS) | lifecycle readers | Audit of boundary moves | Append-only | base |
| 53 | `specs/<f>/iterations/<n>/state.md` `Current Phase` and `plan.md` `Status` (mirrors) | md lines | per-iteration | `Sync-SpecrewCrossingMirrors` (SG, inside the verdict capture) | `Get-SpecrewCrossingMirrorIssues` | Copies of the last authorized boundary; a copy ahead of the ledger is refused | Forward only | files are base; the mirror writer is 199/201 |
| 54 | `specs/<f>/iterations/<n>/.specrew-iteration-seal.json` | json with sha256 per file | per-iteration | `Write-SpecrewIterationSeal` (SG, at iteration close); `specrew-reseal.ps1` | `Test-SpecrewIterationSealIntegrity`, `Test-SpecrewIterationSealed` | A closed iteration is frozen | Permanent | 199/201 (`4ca7013f`) |
| 55 | `.specify/feature.json` (active feature pointer; path only, not read) | json | project | `Set-SpecrewActiveFeaturePointer` (SG, from SBS and create-governed-feature); `Clear-SpecrewActiveFeature` | `Resolve-SpecrewActiveFeature` | Which feature is active | Cleared at feature close | base; **202Δ**: `branch` key and one shared resolver (`55e0dddc`, T010) |

### 2d. Typed human authority (HumanAuthorityStore) and review pause decisions

None of these changed in 202.

| # | Store | Format | Scope | Writer(s) | Reader(s) | Decision it feeds | Retention | Status |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 56 | `.specrew/authority/exhausted-turns.jsonl` | jsonl, 3 record types (turn used, cross-channel double grant, ledger damaged) | project, keyed per turn | `Register-SpecrewExhaustedTurn` and two observation writers (HAS), via HS `Invoke-SpecrewTypedAuthorityCapture` | `Test-SpecrewTypedTurnExhausted`, `Get-SpecrewCrossChannelMint` (HAS) | A typed turn grants authority at most once. **Boundary verdicts do not go through this ledger** | Append-only; one line per non-empty turn | 199/201 (`906c4fca`) |
| 57 | `.specrew/authority/withdrawals.jsonl` | jsonl | project | `Write-SpecrewApprovalWithdrawal` (HAS) | `Test-SpecrewApprovalIsWithdrawn` (HAS) | Revokes a review-round approval | Append-only | 199/201 (`5bd3fe73`) |
| 58 | `R/authority-capture-drops.jsonl` | jsonl | project | HAS (multi-line drop, override writer) | **none** | Diagnostic: an approval phrase matched but was rejected | Append-only | 199/201 (`2b71e93d`) |
| 59 | `.specrew/review/round-approval/pending-round-approval.json` | json single slot with `spent_at`, `minted_ref`, `withdrawn_at`, `authorization_ref` | project | `Write-…RoundApprovalAuthorization`, `Complete-…`, `Set-…MintedRef`, withdrawal (HAS) | `Get-SpecrewReviewRoundApprovalAuthorization` (HAS ← SRV) | Whether one review round may be started | Deleted on withdrawal | 199/201 (`395e4ea0`) |
| 60 | `.specrew/review/round-approval/captures.jsonl` | jsonl approvals and withdrawals | project | HAS | `Test-SpecrewApprovalIsWithdrawn` (withdrawal rows only) | Revocation (second copy of #57) | Append-only | 199/201 |
| 61 | `.specrew/review/round-approval/delivered-unconsumed.json` | json flag file | project | `Write-SpecrewUnconsumedDeliveryFact` (HAS ← SRV) | `Get-…` (SRV) | Refuse to spend again after a delivered but unrecorded round | Cleared by SRV | 199/201 (`1cf4f14c`) |
| 62 | `.specrew/review/round-approval/delivery-journal.jsonl` | jsonl | project | `Write-SpecrewRoundDeliveryJournal` (HAS ← SRV) | **none** (path quoted in text) | Audit of spend without delivery | Append-only | 199/201 (`d5dadc7b`) |
| 63 | `.specrew/review/round-approval/question-ui-observation.json` | json diagnostic | project | `Write-SpecrewQuestionUiPhraseObservation` (HAS ← HS) | SRV | The refusal names the picker as the cause | Cleared on a typed approval | 199/201 (`8ddfeff9`) |
| 64 | `.specrew/review/pause-decision/<choice>.json` (`stop-here.json`, `abandon.json`) | json, stamped `spent_at` | project, one slot per choice | `Write-/Complete-SpecrewPauseDecisionAuthorization` (HAS ← HS router) | `Get-SpecrewPauseDecisionAuthorization` (SRV) | Agent may run pause choice 2 or 3 only with an unspent typed capture | Overwritten; **tracked in git, not in `.gitignore`** | 199/201 (`a75a1276`) |
| 65 | `.specrew/review/pause-decision/captures.jsonl` | jsonl | project | same writer | **none** | Audit only | Append-only; **tracked in git** | 199/201 |
| 66 | `.specrew/review/allowance-reset/pending-allowance-reset.json` | json single slot, `spent_at` | project | `Write-/Complete-SpecrewAllowanceResetAuthorization` (HAS ← SRV) | `Get-…` (SRV) | Agent may run `--remediate allowance-reset` | Never deleted | 199/201 (`d5dadc7b`) |
| 67 | `.specrew/review/signoff-gate/pending-override.json` | json request | project | `Write-SpecrewReviewSignoffOverrideRequest` (HAS ← signoff wiring) | HAS | What the typed partial-signoff phrase binds to | Never deleted | 199/201 (`7cb02c04`) |
| 68 | `.specrew/review/signoff-gate/override-authorizations/<id>.json` | json, immutable, never stamped spent | per request | `Write-SpecrewReviewSignoffOverrideAuthorization` (HAS); it **spends the round approval** (#59) | signoff wiring; GATE (carried across records-only changes) | Sign off with partial coverage | Permanent | 199/201 (`7cb02c04`) |
| 69 | `.specrew/review/coverage-disposition/coverage-deferral.json` | json single slot, no spend stamp | project | `Write-SpecrewCoverageDeferralAuthorization` (SG) | CP; GATE; `Test-SpecrewCoverageDeferralCurrent` | Silences the coverage stop until review | Overwritten | 199/201 (`ac5250b5`) |

### 2e. Review engine stores on the authority path

None of these changed in 202.

| # | Store | Scope | Writer → reader | Decision | Status |
| --- | --- | --- | --- | --- | --- |
| 70 | `.specrew/review/signoff-gate/latest.json` + `history/` | project | `Write-ContinuousCoReviewSignoffGateDecisionEvidence` → `Get-ContinuousCoReviewRecordedSignoffGateDecision` (GATE reads its own output back) | Sign-off gate result; quiets the stop surface | base (field `override_request` from 199/201) |
| 71 | `CMP/runs/<run>/pending-pause.json` (immutable) | per run | ORCH `Add-ReviewCampaignRoundPause` → store readers, GATE, SRV, and **a second, unvalidated reader in HAS** (`Get-SpecrewPendingPauseIdentity`) | A human decision is pending; the round counts as spent | 199/201 (`9061486f`) |
| 72 | `CMP/runs/<run>/pause-decision.json` (immutable) | per run | SRV (stop-here, fix-and-continue, abandon; **and the allowance reset auto-answers fix-and-continue**) → store readers, HAS | Whether the next round may run | 199/201 (`9061486f`) |
| 73 | `CMP/budget-resets/<id>.json` | per campaign | SRV → ORCH budget state; HAS raw read | Moves the start point of the round count | 199/201 (`f5beaebe`) |
| 74 | `CMP/{grants, reservations, spend, releases, claims, runs/<run>/<stage>.json, dispositions, finalization.json}` (immutable facts) | per campaign or run | `review-authority-store.ps1` writers ← ORCH, ingestor, reconciler; `finalization.json` is written by the GATE read path → GATE verdict packet, budget state, HAS raw read | Spend, round count, currentness, sign-off | base (pause and reset kinds from 199/201) |
| 75 | `R/review-authorship.json` | project | `Write-SpecrewReviewAuthorshipObservation` (SG ← CP) → `Get-SpecrewReviewAuthorship` (validate-governance) | Implementing vs independent session label | 199/201 (`65759609`) |
| 76 | `R/co-review-round-state.json` (legacy mode only) | project | legacy orchestrator; **NAV resets `round=0` when the escalation latch closes** → legacy orchestrator | Legacy round ceiling (default 2) | base |
| 77 | `R/co-review-escalation-latch.json` (legacy only) | project | NAV → NAV | Block the stop once, then stay quiet | base |
| 78 | `R/co-review-lineage-lease/<hash>.json` | per lineage | lineage lease functions → NAV | One reviewer per lineage | base |
| 79 | `R/co-review-navigator-state.json` | project | NAV → NAV, worktree-navigator | Fire de-duplication | base |
| 80 | `R/co-review-navigator-journal.jsonl` (last 50 lines) | project | navigator provider → **none** | Observability | base |
| 81 | `<git-dir>/specrew-reviewed-state-digest-cache.json` | per worktree | reviewed-state hash module → same | Speed only | 199/201 (`4b247894`) |
| 82 | `R/review-pause-write-failures.jsonl` | project | ORCH outer catch → **none**; it cannot see the pause-write failure it is named for | Trace | 199/201 (`a7551807`) |
| 83 | `.specrew/review/inline/<run>/degraded-ack.json` | per run | SRV `--ack-degraded` (git user name, **no typed phrase**) → GATE legacy path | Degraded-evidence allow | base |
| 84 | `.specrew/review/inline/<run>/degraded-block-override.json` | per run | legacy orchestrator → **none** | Audit | base |
| 85 | `.specrew/review/inline/<run>/{review-run, gate-verdict, findings-result, …}.json` | per run | run-index writer, blackboard writer → legacy gate, co-review service | Legacy sign-off evidence | base |
| 86 | `.specrew/review/pending/<run>.json` + `<run>/` | per run | isolated task launcher → NAV reap, ORCH | Async results and reaping | base |
| 87 | `continuous-co-review/review-authority-mode.json` (`campaign` throughout) | shipped config | cutover script → cutover | Legacy vs campaign authority | base |
| 88 | `.specrew/review/test-evidence/<hash>.json` | per test-run hash | test-evidence recorder → reviewer evidence | Reviewer may skip re-running suites | base |
| 89 | `.specrew/bypass-audit/bypass-log.md` | project | work-kind validator, **no production caller** → none | Audit | base, **dead** |
| 90 | `.specrew/reviewer-regression-log.md` | project | `manage-reviewer-regression.ps1` → SG, validate-governance | Reviewer lockout chain | base |

## 3. The same inventory, before 202

**At B0 (`acbb4366ae`), 42 stores** (numbers from section 2):

| Group | Stores |
| --- | --- |
| hook | 11, 18-32, 34, 35 |
| workshop | 36, 39 |
| boundary | 47-52, 55 |
| review engine | 70, 74, 76-80, 83-90 |

At B0:

- There was no turn-end store and no hook-output journal.
- There were none of the HumanAuthorityStore typed-authority stores and no workshop receipt journal.
- `start-context.json` had no `feature_ref` on the pending boundary or on its verdicts, and no branch on the session position.

**Added between B0 and P by features 199 and 201 and the beta4 fixes: 36 stores.**

| Group | Stores |
| --- | --- |
| hook | 1-4 (turn-end store), 8, 12, 16 (the `.unhealthy` latch), 33 |
| workshop | 37, 40-44 |
| boundary | 53, 54 |
| typed authority | 56-69 (all of HumanAuthorityStore and the coverage deferral) |
| review engine | 71-73, 75, 81, 82 |

One store was retired in that range, not in 202: `R/conformance-material-owner.json` (`b8936d67`, 2026-09-10).

**At P (`24e5701a`), 78 stores.** Relevant shapes at P, before 202 changed them:

- **#12 `hook-output-authority.jsonl`**:
  - It was opened with `FileShare.Read`, and a failed append wrote the **`.unhealthy` flag file (#16)**, which then refused every later typed reply (the B4F-108 latch that T003 removed).
  - A malformed line threw.
  - There was no buffer, no health journal, no lock and no set-aside.
- **#4 `turn-N.json`** had no `meaning_lines` and no `draft_*` fields.
- **#47 `start-context.json`** pending boundary id hashed `from, to, working boundary, commit, tree`, with no feature (the tuple dates from `4e38c55d`, 2026-07).
- **#55 `.specify/feature.json`** had no `branch`.
- **#11 render claim**: CP read any session's claim.
- **#34 `conformance-journal.jsonl`** had none of the `presented_*`, dials or orientation fields.

**Added by 202: 12 stores.** These are #5, 6, 7, 9, 10, 13, 14, 15, 17, 38, 45 and 46, by introducing task:

| Task | Commit | Stores added |
| --- | --- | --- |
| T003 | `aa2ffb7b` | 14 (buffer), 15 (health) |
| T004 | `0edfb321` | 13 (set-aside), 38 (receipt outcomes), 45 (recovery request), 46 (recovery receipts) |
| T006 | `0b62bf9b` | 6 (`presented-crossings.json`), 7 (`session-start.json`) |
| T007 | `8904b71f` | 9 (dials flag file) |
| T008 | `aac6a3fa` | 10 (orientation flag file) |
| T014 | `b9cf8b71` | 5 (turn-message.md) |
| round-1 fix | `34af7076` | 17 (Unix lock files) |

**Changed by 202: 9 stores.** These are #4, 8, 11, 12, 16, 20, 34, 47 and 55, with the commits in section 2.

## 4. State added during 202's own review rounds

This table is the direct test of "each fix added state". Each row is a fix to a review-round finding that added a new store, a new field, or a new path that writes or clears state.

| Round fix | State added | Next finding that came from it |
| --- | --- | --- |
| Round 1 (`34af7076`) | Unix `.lock` files (#17); `.flushing-<guid>` claim names (#14); the recovery approval is recorded before acting (#46 ordering) | **R2-2**: the flush removed a buffer that a Unix writer still held open. The lock's wait starved writers (**DRIFT-023**), which needed a per-fire budget (`46d18d82`) and left B4F-123 open |
| Round 2 (`0b62bf9b`) | `asked_session` on #45; one closed file per buffer record (#14); the dispatcher reads set-aside files too | **R4-5**: a question asked in a session that later ended could be answered by no one |
| Round 3 (`fdf9972f`, `1dd20060`, `e206d1b7`, `d0d41902`) | Disclosure built from #38 at the dispatcher's final append; a shape check before field reads in the readers of #12, #15 and #38; one shared link reader for #6 | **R4-3** (the Stop-block path lacked it); **R5-5** (the #38 lookup had no session, and round 4 added more callers); **R6-1** (the shape check looked only at `state`); **R5-6** (code examples); **R6-3** (parentheses in links) |
| Round 4 (`61714dbd`) | A re-ask branch on #45 (a second write before delivery); rollback of the #10 flag file on a withheld fire | **R5-3** (a declined question stayed armed) and **R5-4** (a question written during a withheld fire survived; round 4's rollback covered only #10) |
| Round 5 (`5c56dbed`) | `declined_at` on #45; `session_id` on #38 rows; `identity_version 2` on #47; `Clear-DispatcherUndeliveredRecoveryRequest` | Round 6 found no defect in these. All four round-6 findings were older code |
| Round 6 (`0e6a8a01`) | Default values for partial #15 lines; link and option parsing (no new state) | (no further round) |

## 5. Which store each review finding involved (32 findings, rounds 1 to 6)

Sources: drift-log DRIFT-014 (R1), DRIFT-015 (R2), DRIFT-024 (R3), DRIFT-031 (R4) and DRIFT-032 (R5, R6), plus B4F-055 in `docs/beta4-findings.md`.

Class key:

- **A**: the main store involved was added by 202.
- **B**: the main store existed before 202, but 202 changed its shape or write path.
- **C**: no runtime store involved (text parsing or artifact reading).

| Finding | Short description | Store(s) involved | Class |
| --- | --- | --- | --- |
| R1-1 | The turn origin was passed but not enforced | #37 receipt writer, origin from #12 | B |
| R1-2 | A buffer flush could delete unread data | #14 | A |
| R1-3 | A malformed journal line threw and refused every later reply | #12 (with #38 outcome handling) | B |
| R1-4 | The recovery approval read a decline as approval | #45 | A |
| R1-5 | A recovery question outlived its episode | #45, #15 | A |
| R1-6 | Recovery acted before recording the approval | #46, #13 | A |
| R1-7 | No disclosure in the affected turn | #15, #38 | A |
| R1-8 | The non-Windows journal append was not atomic | #12 write path (fix added #17) | B |
| R2-1 | The dispatcher still latched on a malformed line (a second reader of the same journal) | #12 | B |
| R2-2 | A flush removed a buffer still held open | #14, #17 | A |
| R2-3 | Recovery was recorded while a buffer stayed unreadable | #14, #15, #45 | A |
| R2-4 | Another session's "yes" approved the recovery | #45 (project-wide slot) | A |
| R2-5 | An unreadable record check was disclosed as a host-added reply | #38 | A |
| R3-1 | A question quoting the approval phrase read as a missed approval | #6 | A |
| R3-2 | Markdown review links were invisible to the reviewed-file memory | #6 | A |
| R3-3 | A `{}` line threw in three readers | #12 (and siblings #15, #38) | B |
| R3-4 | A degraded episode at the final append went undisclosed | #15, #38 | A |
| R4-1 | `specrew start` resumed a different feature | #55, #47 (two sources for the active feature) | B |
| R4-2 | Resume progress read iteration 1's task list | none (artifact read) | C |
| R4-3 | The Stop-block path lacked the disclosure | #15, #38 | A |
| R4-4 | An orientation was flagged as supplied before delivery | #10 | A |
| R4-5 | A recovery question from an ended session could never be answered | #45 (`asked_session`) | A |
| R5-1 | Two features shared one pending-boundary id | #47 (`feature_ref` added after the id), #6 | B |
| R5-2 | A conditional yes approved the recovery | #45 | A |
| R5-3 | A declined recovery question stayed armed | #45 | A |
| R5-4 | A recovery question recorded during a withheld fire survived | #45 | A |
| R5-5 | The disclosure reported another session's outcome | #38 (no session field) | A |
| R5-6 | An approval phrase in a code example read as a missed approval | #6 | A |
| R6-1 | A partial health line latched the journal | #15 | A |
| R6-2 | Verdict options as bullets were invisible to the meaning check | none (text parsing; `meaning_lines` in #4) | C |
| R6-3 | A link with parentheses was cut, so its edits were invisible | #6 | A |
| R6-4 | Two links differing only by case were merged | #6 | A |

**Totals: A = 23, B = 7, C = 2.**

Not every class A finding is a state-lifecycle defect. 4 of the 23 are about recognizing a typed phrase that then writes to a store (R1-4, R3-1, R5-2, R5-6). The other 19 are about who owns a record, when it is cleared, which session it belongs to, or how a damaged line is read.

By store family:

| Family | Findings | Count |
| --- | --- | --- |
| Hook-output journal (#12) and the seven stores 202 built around it (#13, 14, 15, 17, 38, 45, 46) | R1-1..8, R2-1..5, R3-3, R3-4, R4-3, R4-5, R5-2..5, R6-1 | **22 of 32** |
| Presented boundary memory (#6) | R3-1, R3-2, R5-1, R5-6, R6-3, R6-4 | 6 |
| Orientation flag file (#10) | R4-4 | 1 |
| Active-feature sources (#55, #47) and the resume read | R4-1, R4-2 | 2 |
| Meaning-line parsing | R6-2 | 1 |

The recovery request (#45) alone was involved in **9 findings**. Its fields grew in rounds 2, 4 and 5.

No finding involved the 36 stores that 199 and 201 added in HumanAuthorityStore or the review engine. 202 did not change that code.

## 6. Candidates to merge or remove

The candidates are ordered by how many 202 findings involved the store. "Findings" means the review-round findings from section 5.

1. **Recovery request and recovery receipts (#45, #46), and the human question they serve.**
   - **What is redundant:** the recovery moves the hook-output journal aside (#13). Both readers still read set-aside files (DISP since round 2, WAS since T004), so the move loses no information. The question guards an action that cannot lose data, and #46 has no reader.
   - **Candidate:** set aside automatically when the journal cannot be appended, and record that as a field on the health record (#15). Remove #45, #46 and the yes/no/unclear recognizer.
   - **Caveat:** FR-009 asks for the human's approval. This is a spec decision, not a refactor.
   - **Findings:** R1-4, R1-5, R1-6, R2-3, R2-4, R4-5, R5-2, R5-3, R5-4 (**9**).
2. **Health journal (#15), the legacy `.unhealthy` flag file (#16) and the buffer count.**
   - **What is redundant:** "degraded" can be derived from what is already there. Buffer files exist (#14), or this fire's append failed. `degraded_since` can come from the oldest buffer file's time.
   - **Readers:** three functions in three files read #15 (DISP, WAS, SG). It grows forever. #16 has no writer at HEAD and only cleanup code reads it.
   - **Candidate:** derive the state from #14 and drop #15. Remove #16's handling after one release.
   - **Findings:** R1-5, R1-7, R2-3, R3-3 (sibling reader), R3-4, R4-3, R6-1 (**7**).
3. **Receipt outcomes (#38).**
   - **What is redundant:** a recorded reply is written to both #37 and #38 with the same `response_hash`. An unbound agenda confirmation is also in `handover-journal.jsonl` (#25).
   - **Use:** its only use is a disclosure in the same turn. It is project-wide, so it had to be filtered by time, then by hash, then by session.
   - **Candidate:** a field on this turn's record (#4) or a value passed within the fire, with no shared journal.
   - **Findings:** R1-3, R1-7, R2-5, R3-3, R3-4, R4-3, R5-5 (**7**).
4. **Lock files (#17) and the outage buffer (#14).**
   - **Candidate:** B4F-123 (the buffer as a queue for contended appends) would make the buffer the normal path for contention and remove the wait-and-lock files.
   - **Note:** it adds a "contended" outcome. The maintainer ruled it out of 202 because it is "a new store state built before the last review round". It is a merge candidate, not a removal.
   - **Findings:** R1-8, R2-2; DRIFT-023 (**2 + 1 drift**).
5. **Presented boundary memory (#6) and the session-start record (#7).**
   - **What is redundant:** #6 copies the pending id, approval phrase and packet tag. Those are already in #47 `pending_crossing` and in `pending-verdict-stop.md` (#48), which makes three copies. #7 is read only to copy `kind` into #6.
   - **Candidate:** keep only what is new in #6 (the reviewed-file fingerprints and the times it was presented and answered), keyed by the pending id. Derive the rest from #47. Drop #7 and take the kind from the SessionStart event that clears #6.
   - **Findings:** R3-1, R3-2, R5-1, R5-6, R6-3, R6-4 (**6**). Most were in parsing that feeds the fingerprints, so a merge would remove the duplication but not those findings.
6. **Four "orientation done" flag files (#8, #9, #10, #11), keyed three ways.**
   - **The keys:** a sha256 owner folder, a raw session id in `R/`, and another sanitized id for #23.
   - **Candidate:** one per-session orientation record in `SR/` with `claimed_at`, `supplied_at`, `rendered_at` and `dials_supplied_at`. Also remove the unused `OrientationPath` in TES.
   - **Findings:** R4-4, which led to the rollback that R5-4 then had to extend (**1, plus 1 follow-on**).
7. **Per-session keying spread across `R/`.**
   - **What is spread out:** #10, #18 and #23 use raw or differently sanitized session ids. #20 is project-wide, last writer wins. Session liveness is guessed from folder modification times.
   - **Candidate:** everything per-session goes under `SR/<own>/`, and #20 is derived from the newest folder.
   - **Findings:** R4-4, R2-4, R4-5 and R5-5 (the cross-session class), indirectly.
8. **Draft copy (#5).**
   - **Why remove:** it has no reader, and the same text is in the turn record's `message` field.
   - **Findings:** 0 (but the T014 drift entry DRIFT-028 needed it).
9. **Active-feature sources (#55 `branch`, #47 `session_state.branch` and `feature_ref`, branch name, pending boundary).**
   - **What happened:** 202's T010 unified the readers and added two more branch fields.
   - **Candidate:** one recorded fact, the pointer, plus the branch derived at read time.
   - **Findings:** R4-1, R5-1 (**2**).
10. **Dead or reader-less stores outside 202 (cleanup, not a 202 cause):**
    - `continue-guard.json` (#28: its write is unreachable);
    - `launcher-bootstrap.json` (#22: no production writer);
    - `bypass-audit/bypass-log.md` (#89: no production caller);
    - `design-decisions.json` (#44: read only by its writer).
    - Write-only journals that could become one diagnostics journal: #34, #43, #46, #58, #62, #65, #80, #82, #84.
    - **Findings:** 0.
11. **One stop-here decision is written to five places:**
    - #64 slot;
    - #65 captures (no reader, tracked in git);
    - #72 per-run decision;
    - #74 disposition;
    - #70 latest.
    - There are also five typed-authority families with five different shapes (#59, #64, #66, #67/#68, #69), three ways to reset the round count (#73, the legacy #76 reset, and the NAV latch close), and two round counters with different defaults (2 and 4).
    - **Findings:** 0 code findings in 202. However, the tracked `pause-decision/` files (#64, #65) are modified in the working tree right now. A commit in the middle of a round moved round 5's snapshot (B4F-126, DRIFT-032 "Stop refused"). Ignoring that folder in git would remove one way a commit can carry runtime state.
12. **Boundary position kept in four to five places:**
    - The working position is in #47, #49, #50 and #51.
    - The last authorized boundary is in #47, #48, #53, `session-handover.md` and #51.
    - Each is written by its own step, and #47 has no lock.
    - **Findings:** these were not changed by 202 and had 0 findings in 202. R5-1 involved the pending-id part of #47.

## 7. Does the evidence support the maintainer's concern?

**Mostly yes.**

- **Where the findings were:** 23 of the 32 findings were in stores that 202 added. 7 more were in stores whose shape or write path 202 changed. 22 of the 32 were in one family: the hook-output journal and the seven stores built around it to remove its latch.
- **The chain in section 4 is direct.** In every round from 1 to 4, a fix added a store, a field or a write path. In the next round a finding landed on exactly that addition:
  - the lock led to R2-2 and DRIFT-023;
  - `asked_session` led to R4-5;
  - the round-3 disclosure led to R4-3 and R5-5;
  - the round-4 re-ask and rollback led to R5-3 and R5-4;
  - the round-3 shape guard led to R6-1.
- **Why the chain stopped:** round 6 found nothing in round 5's own changes. It only stopped there because round 5 was told to be the last scope expansion.

**Two cautions, so the retro does not over-read this:**

- **Review scope.** Each round reviewed the 202 diff, so 202's new code would attract the findings whether or not it was state. The sharper comparison is inside 202:
  - the non-state work (T010 resolver, T012 resume, T007 option parsing, T014 drafts) produced 3 findings (R4-1, R4-2, R6-2);
  - the state work (T003, T004, T006, T008 and their fixes) produced the rest.
  - The dispatcher and `workshop-authority-store.ps1`, where most of the new state lives, are also the largest diffs (777 and 508 lines). Size and state are partly the same signal.
- **Older code.** Five of round 5's six findings and all four of round 6's are older than the code under review in that round (DRIFT-032 calls them carry-ins). Most of that older code is still earlier 202 work, from T003, T004, T006 and T007. One finding, R5-1, joins a pre-202 tuple from 2026-07 with 202's `feature_ref`.

## 8. Provenance notes found on the way

- **T011 code in a bootstrap commit.** `f46c9fb1` ("chore(specrew): bootstrap scaffold", author "Specrew Bootstrap", 2026-10-14) carries the T011 code: the `feature_ref` fields in `shared-governance.ps1` and `readiness-verdict.ps1`. The commit labelled T011, `e0d8c33e`, touches only `.specrew/verification-plan.json`. This is the stray commit already recorded in DRIFT-022 and B4F-120. It means a `git log -S feature_ref` attribution points at a bootstrap identity, not at T011.
- **Tracked runtime files.** `.specrew/review/pause-decision/` is not in the repository `.gitignore`. `stop-here.json` and `captures.jsonl` are tracked (`eeb1195d`) and are modified in the working tree now. The consumer ignore list (`scripts/internal/file-classification.ps1`) also leaves out the following folders:
  - `round-approval/`
  - `allowance-reset/`
  - `coverage-disposition/`
  - `pause-decision/`
  - `.specrew/authority/`
- **Nothing is pruned.** No journal on these paths is rotated or pruned except `refocus-state-*` (7 days) and the navigator journal (last 50 lines). Two stores grow by one entry per turn: `turn-end/<own>/turn-N.json` (one file per turn, and every file is scanned for the in-flight count) and `exhausted-turns.jsonl` (one line per non-empty turn).
