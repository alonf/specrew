# Tasks: beta4.1 UX stabilization (Tier 1, iteration 001)

**Feature**: 202-beta4-1-ux-stabilization
**Plan**: file:///C:/Dev/specrew-beta3-stabilization/specs/202-beta4-1-ux-stabilization/plan.md
**Date**: 2026-10-13
**Effort unit**: story points. 25.5 SP is planned against the 20 SP convention, an overcommit of 5.5 SP recorded by the maintainer's plan verdict. Review is governed by the codex round allowance, not SP.

Iteration 001 only. Tier 2 (US7, FR-022/023) is planned after the maintainer's Tier 1 acceptance at the iteration-001 closeout.

Tasks are numbered feature-globally and mirror plan work items W1 to W15 one-to-one. **Every task lands RED-first:** its fixture first reproduces the defect through the shipped entry point (the real launcher and dispatcher with a deployed binding, or the real script), and only then does the fix turn it green. On every commit:

- mirror parity (`extensions/` ↔ `.specify/`) and twin-copy parity (`scripts/internal/` ↔ `extensions/` for the dispatcher and the bootstrap/handover providers);
- the psd1 FileList, with new files added in sorted position;
- SelfLeakLintLane on touched templates and skills;
- the consumer-language check (banned nouns, glossed IDs).

Before implement starts, the branch is synced with `origin/201-first-run-experience` (custom rule `feature-202.rule.beta4-line-sync`).

## Execution order

T001, T002, T003, T004, T006, T007, T008, T009, T010, T011, T012, T013, T014, T005, T015.

- T001 comes first because T002, T005, T008 and T014 branch on its measurements.
- T002 and T003 are foundational.
- The conformance-provider tasks (T004, T006, T007, T008) run serially, because they share one file.
- T005 runs once every surface it exercises exists.
- T015 assembles the closeout evidence.

## Phase 1: Setup (measurement)

- [x] T001 [owner: Implementer] [sp: 1.5] **Capture real hook payloads and measure host facts.** Done 2026-10-13, before the before-implement verdict, by the maintainer's tasks-verdict instruction (DRIFT-005). Results are in research.md, "T001 measurements".
  - **Work:** in scratch directories only, never a governed worktree (custom rule `feature-202.rule.scratch-probes-only`), record real hook-event payloads from Claude, Codex and Copilot for SessionStart, UserPromptSubmit/PreInvocation and Stop: a typed prompt, a host-injected or replayed text, and Copilot's `User skipped question`. Capture Cursor and Antigravity only as a by-product.
  - **Provenance:** each fixture records the host version, date, scratch path and event.
  - **Measurements:** per validated host, (a) whether the payload carries a session id (DA-4), and (b) which hook output the host shows directly to the user (DA-3). Results go in `research.md` under Open facts.
  - **Acceptance:** fixtures exist for all three validated hosts; both facts are recorded per host; any host that cannot meet DA-3 or DA-4 is named for the before-implement packet.
  - **Trace:** FR-024; DA-3; DA-4.
  - **Owns:** `tests/fixtures/hook-payloads/**`, `specs/202-beta4-1-ux-stabilization/research.md`.

## Phase 2: Foundational (blocks US1 to US6)

- [x] T002 [owner: Implementer] [sp: 2.5] **Standard turn record and declarative host bindings (DA-1, option B).** Done 2026-10-13. `turn-record-contract.tests.ps1` runs every case through the deployed hook command and is green; the RED had 31 failures. `twin-copy-parity.tests.ps1` is green. The 55-file hook regression sweep is green. The owned-file extension is DRIFT-010.
  - **Work:**
    - Add `ConvertTo-SpecrewTurnRecord` to the dispatcher, producing {event, host, session_id, typed_text, origin, transcript_path}.
    - Add `InputFieldMap`, `OriginRules` and an optional `InputTransform` to each `hosts/<host>/host.psd1`.
    - Add a small shared transform registry holding the Copilot replay and skipped-question transforms.
    - Remove the dispatcher's inline parsing (~1160-1203) and `HostEventAdapter.ps1` `ConvertFrom-SpecrewHostHookEvent`, rewiring the bootstrap provider to the new record.
    - Add a twin-copy parity test for the dispatcher and the bootstrap, handover and refocus providers.
  - **RED:** today, two normalizers yield different session ids for the same payload (the `id` key).
  - **Acceptance:** every T001 fixture through the real launcher and dispatcher yields the declared record; a Copilot replay yields `host-injected`; the parity test fails on a one-byte twin drift; no host-name branch remains in shared code.
  - **Trace:** FR-006, FR-024; SC-001 (contract).
  - **Depends:** T001.
  - **Owns:** `hosts/*/host.psd1`, `scripts/internal/specrew-hook-dispatcher.ps1`, `extensions/specrew-speckit/scripts/specrew-hook-dispatcher.ps1`, `scripts/internal/bootstrap/HostEventAdapter.ps1`, `tests/unit/turn-record-contract.tests.ps1`, `tests/unit/twin-copy-parity.tests.ps1`.
- [x] T003 [owner: Implementer] [sp: 3.0] **Latch-free hook-output journal.** Done 2026-10-13. `hook-output-journal.tests.ps1` is green: cases (a) to (d), the legacy marker, and a failed buffer write, all through the real dispatcher against a separate lock-holding process. The RED had 15 failures, and case (a) latched `.unhealthy`, which is B4F-108 reproduced. The concurrency measurement is in research.md: the Windows journal uses an append-only handle, and Unix waits on T005 case (e).
  - **Work:**
    - `Write-DispatcherHookOutputAuthorityRecord` opens with a share mode that permits concurrent appends and writes each line in one call.
    - A bounded retry (at most 5 attempts within 250 ms) is a backup only.
    - On persistent failure, hashes go to `.specrew/runtime/hook-output-buffer/<pid>-<guid>.jsonl`, and a `degraded` health transition is written.
    - The next successful append flushes the buffer, removes the files, and writes `recovered`.
    - No `.unhealthy` marker is ever written. A legacy marker is read as degraded and cleared by the next good append.
    - `Test-SpecrewWorkshopResponseIsHookOutput` reads the journal plus the buffer files before the prompt decision.
    - If the buffer write also fails, only that turn fails closed.
  - **RED:** a held exclusive lock today writes a permanent marker that refuses every later reply.
  - **Acceptance:**
    - fault cases (a) to (d) pass locally;
    - a per-write lock on this journal only is introduced only if case (e) in T005 shows torn or interleaved lines (code rule exception);
    - integrity stores hold hashes only.
  - **Trace:** FR-001, FR-002, FR-003, FR-004, FR-005, FR-008, FR-025; SC-002.
  - **Depends:** T002.
  - **Owns:** both dispatcher copies, `extensions/specrew-speckit/scripts/workshop-authority-store.ps1`, `tests/unit/hook-output-journal.tests.ps1`.

## Phase 3: US1, typed workshop replies count on every host (P1)

- [x] T004 [owner: Implementer] [sp: 2.0] [US1] **Disclose degraded capture; name the actual cause.** Done 2026-10-14. `receipt-disclosure.tests.ps1` is green (61 checks, through the real handover provider). The 146-file regression sweep is green apart from 3 suites that fail identically at the previous commit (feature-017/018 dashboards, the interaction-model README check). The two files outside the owned set are DRIFT-012.
  - **Work:**
    - Every silent `return $null` in `Write-SpecrewWorkshopAuthorityReceipt` becomes a typed outcome.
    - A refused or degraded mint is disclosed in the same turn, stating whether the reply was consumed.
    - `specrew status` and `where` show a health line only while degraded.
    - Orientation includes the degraded state.
    - The conformance `workshop-repair` "selection channel" inference (~1314-1321, ~1970) is replaced by the real cause.
    - When self-recovery fails, ask one decision using the reference wording "Specrew couldn't record your reply safely. May I clear the stuck error so it can record again? Nothing is deleted.", and record the approving receipt with the recovery action.
  - **RED:** a degraded reply today produces no disclosure and later a "selection channel" Stop.
  - **Acceptance:** message-content tests for each disclosure; the banned-noun check passes; never "selection channel" for a typed reply; the line-485 product-records refusal is disclosed with its cause.
  - **Trace:** FR-007, FR-009, FR-010.
  - **Depends:** T003.
  - **Owns:** `scripts/internal/bootstrap/HandoverStore.ps1`, `extensions/specrew-speckit/scripts/workshop-authority-store.ps1`, `extensions/specrew-speckit/scripts/specrew-conformance-provider.ps1`, `scripts/specrew-where.ps1`, `scripts/internal/dashboard-renderer.ps1`, `tests/unit/receipt-disclosure.tests.ps1`.
- [x] T005 [owner: Implementer] [sp: 2.5] [US1] **Cross-host workshop acceptance and fault-injection suite.** Done 2026-10-14.
  - **Work:**
    - **Cross-host acceptance:** product-domain, then agenda, then one lens, through the real launcher and dispatcher with each validated host's deployed binding and the T001 fixtures. Each host yields 3 receipts and needs exactly 1 reply per checkpoint.
    - **Fault cases (a) to (e):** (e) is two real `pwsh` processes appending at once; both succeed with intact lines and no degradation.
    - **Experimental hosts:** Cursor and Antigravity run the contract test only if T001 captured their payloads; otherwise they are listed as unvalidated in the evidence.
    - **Workflow change (DRIFT-003):** a minimal `.github/workflows` change runs case (e) on Windows, macOS and Linux. It uses the existing OS matrix only, with no new jobs and no publication or deployment change.
  - **Acceptance:** the suite is green on three OSes; **the workflow diff is reviewed like code** (codex co-review covers it and the review records it); experimental hosts are labelled as such in the results.
  - **Trace:** FR-024, FR-025; SC-001, SC-002.
  - **Depends:** T002, T003, T004.
  - **Owns:** `tests/unit/cross-host-workshop.tests.ps1`, `tests/unit/journal-fault-injection.tests.ps1`, `.github/workflows/**` (minimal).
  - **Progress 2026-10-14 (done):**
    - **Windows, green.** Each validated host gives 3 receipts from 3 replies.
    - **Case (e):** 2,000 of 2,000 lines intact, and 5 concurrent dispatcher pairs all journaled.
    - **Mutations caught:** a plain `Append` stream on Windows lost 3 to 4 lines per run; console stdin decoding broke Claude's Hebrew reply.
    - **Workflow:** one step was added to the existing `review-runtime-fault-matrix` job. There are no new jobs.
    - **First 3-OS run (38487295823):** Windows green. Linux lost 58 of 2,000 lines and tore 1; macOS lost 32. Linux and macOS now take the permitted per-write lock on this journal (DRIFT-014).
    - **3-OS rerun with the lock (38490308475, on `34af7076`):** green on Windows, Linux and macOS, with 2,000 of 2,000 lines, none torn. The whole workflow passed.
    - **Codex review of the workflow diff:** co-review round 2 (`run-20261014-102731596-597f9ec9`) examined `.github/workflows/cross-platform-validation.yml` and raised no finding on it. Its five findings concern T003 and T004 code and are fixed (DRIFT-015).

## Phase 4: US2, stops only when I have a decision to make (P1)

- [x] T006 [owner: Implementer] [sp: 2.0] [US2] **Presented-crossing memory (DA-2).** Done 2026-10-14. `crossing-presentation.tests.ps1` drives the real conformance provider and `declare-turn-end.ps1` over a real scoped pending crossing:
  - **Green:** the three B4F-104 triggers and a bookkeeping commit each give 0 blocks; a compaction gives exactly one; a changed review target, the 8-hour gap, another session and an unanchored session each owe the packet.
  - **Recovery path (DRIFT-008):** a reply carrying the approval phrase after a pasted block, with the crossing still pending, reopens the packet with the cause. The re-presented marker then captures the next typed verdict through the real prompt-time capture.
  - **RED on `39af693f`:** all four triggers block. **Mutation:** with the capture-miss rule removed, the recovery case fails, which is the second RED fixture.
  - **Design notes:** the artifacts under review are the files the packet links, content-hashed; a linked folder is recorded, not hashed, so a drift entry inside it is not a gap. A suppressed stop is journaled with its reason. Material work during a suppressed turn still owes its turn-end declaration, not a packet. The dispatcher passes the SessionStart kind to the provider (diagnosis only; every SessionStart is a gap).
  - **Work:**
    - Record `presented-crossings.json` in `turn-end/<ownerHash>/` when a boundary declaration passes.
    - `$boundaryBlock` (conformance ~1426) is true only when no record exists for (session, crossing id).
    - Context gaps clear the record: a changed crossing id, a change to the reviewed artifacts, SessionStart new/resume/compact, or 8 hours. **HEAD movement alone is not a gap.**
    - Between gaps, a reply may carry at most the one-line mention (decision plus approval phrase; no options, marker or sections), and it never produces a `Stop hook error`.
    - **Recovery path stays open (DRIFT-008, B4F-112).** A crossing that is still pending and had a capture miss can be presented again in the same session, whatever the gap state. A capture miss is a human reply received while the crossing was pending that the capture did not record as a verdict. Only a crossing that was presented, is unchanged and had no capture miss is suppressed. The capture-pairing fix itself stays beta5.
  - **RED:** today's three recorded B4F-104 triggers each repaint the packet. This session's DRIFT-014 shape is also reproduced: a bookkeeping commit repaints. **Second RED fixture:** after T006's suppression is in place, a pending crossing whose verdict was not captured cannot be presented again in the same session without the new rule. Shapes: 202's tasks boundary (compaction between packet and reply), and a verdict that did not record because a paste block came before the phrase.
  - **Acceptance:** 0 repaints and 0 Stop errors for the three triggers and for a bookkeeping commit; exactly one repaint after a compact; a pending crossing with a capture miss can be presented again in the same session and its marker captures the next typed verdict; a presented, unchanged crossing with no capture miss is still suppressed.
  - **Trace:** FR-011; SC-004.
  - **Depends:** T002.
  - **Owns:** `extensions/specrew-speckit/scripts/specrew-conformance-provider.ps1`, `extensions/specrew-speckit/scripts/turn-end-store.ps1`, `tests/unit/crossing-presentation.tests.ps1`.
- [x] T007 [owner: Implementer] [sp: 2.0] [US2] **Substance-only Stop.** Done 2026-10-14. `presented-check.tests.ps1` runs the real provider and `declare-turn-end.ps1`:
  - **Green:** a reworded conversational draft and a reworded boundary packet that keep every meaning line give 0 blocks. A dropped verdict option is named in the block. With no crossing pending, a dropped question line is named with no demand for an approval line or marker. The dials line is supplied once on the first prompt, marked as system output, and a reply without it is not blocked.
  - **RED on `044a9a84`:** both reworded drafts block (B4F-100); the no-crossing stop asks for an approval line and marker (B4F-100 live); the missing dials line costs a cycle (B4F-106).
  - **Design notes:** `declare-turn-end.ps1` records the meaning lines with the declaration, including any line it supplied. The dials line goes out at turn start because no validated host shows Stop output (DRIFT-016).
  - **Existing suites moved to the new contract:** `agent-led-workshop-replay` pinned the old Stop-time dials demand, which is B4F-106 itself; it now asserts the first-prompt supply and no Stop block, and points at its fixture profile through `SPECREW_USER_PROFILE_PATH` instead of rewriting the store's text. `turn-end-session-identity` pins "no profile", so its one-line token assertion is the same on every machine. The sweep also caught a gap in the first question-line rule: a `?` followed by an instruction on the same line ("Does this match? Type move on.") is now a question line.
  - **Work:**
    - Replace `Test-SpecrewTurnMessageVisible`'s whole-draft containment with a check over one declared meaning-line set: headings, review-target links, question line, approval line, verdict options and marker. It is declared once in the shared path and used by conformance and `declare-turn-end.ps1`.
    - Deterministic lines the system can supply (the dials line, orientation facts) are filled by the system, marked as system output and journaled, never demanded from the agent.
  - **RED:** a reply that rewords a declared draft but keeps every meaning line is blocked today (DRIFT-012 shape); a missing dials line costs a cycle (B4F-106).
  - **Acceptance:** the reworded draft passes; a dropped verdict option is named; a missing dials line is filled with 0 human-visible cycles; no block over formatting remains.
  - **Trace:** FR-012, FR-013, FR-015; SC-003.
  - **Depends:** T006.
  - **Owns:** `extensions/specrew-speckit/scripts/specrew-conformance-provider.ps1`, `extensions/specrew-speckit/scripts/turn-end-store.ps1`, `extensions/specrew-speckit/scripts/declare-turn-end.ps1`, `tests/unit/presented-check.tests.ps1`.
- [ ] T008 [owner: Implementer] [sp: 1.5] [US2] **Orientation before the first question (DA-3).**
  - **Work:**
    - On the session's first prompt, the bootstrap provider supplies the finished orientation as system output, marked and journaled.
    - On hosts that T001 found show hook output directly, the agent is told not to render it, so no duplicate appears.
    - The "bootstrap delivered" check is scoped to this session's render file, not any session's (conformance ~1466).
    - The Stop-time owed-orientation demand is removed.
  - **RED:** the B4F-096 replay: a question before orientation, then a Stop demand.
  - **Acceptance:** the first-prompt payload carries the orientation; no agent-rendered duplicate on direct-display hosts; 0 Stop demands.
  - **Trace:** FR-014; SC-003.
  - **Depends:** T001, T007.
  - **Owns:** both bootstrap-provider copies, `extensions/specrew-speckit/scripts/specrew-conformance-provider.ps1`, `tests/unit/orientation-order.tests.ps1`.

## Phase 5: US3, the same adaptation text on every host (P2)

- [ ] T009 [owner: Implementer] [sp: 1.0] [US3] **One shared dials sentence.**
  - **Work:** use `Get-SpecrewProfileOrientationLine`'s prose sentence everywhere; remove `Get-SpecrewOrientationDialsLine` (the numeric renderer); the host binding supplies only the correction-command reference.
  - **RED:** the numeric line `software_architecture=10, ...` reaches the agent through the Stop repair.
  - **Acceptance:** byte-identical across the three validated bindings apart from the command reference; no `key=number` text on any host.
  - **Trace:** FR-016; SC-005.
  - **Depends:** T007.
  - **Owns:** `scripts/internal/user-profile.ps1`, `extensions/specrew-speckit/scripts/turn-end-store.ps1`, `tests/unit/dials-parity.tests.ps1`.

## Phase 6: US4, one answer to "what are we working on" (P2)

- [ ] T010 [owner: Implementer] [sp: 2.0] [US4] **One feature resolver (DA-5).**
  - **Work:**
    - `Resolve-SpecrewActiveFeatureRef` decides in this order and returns `resolved_by`: (1) the in-flight controller or pending crossing; (2) the pointer, if written for the current branch; (3) the branch as a hint only.
    - `session_state` records `branch`.
    - `create-governed-feature.ps1` writes the pointer.
    - The status/where dashboard (`Get-SpecrewActiveFeatureDirectory`, lowest-numbered fallback) uses the resolver.
    - A Shipped or closed feature is never shown as active while one is in flight.
    - Ask only when two in-flight features compete.
  - **RED:** today, `specrew status` selects `001-specrew-product` (B4F-105), and the 199-on-201 case.
  - **Acceptance:** status, orientation and resume name the same feature in every constructed state; every feature writer updates the pointer (writer test); the disclosure names its source.
  - **Trace:** FR-017, FR-018; SC-006.
  - **Depends:** T002.
  - **Owns:** `extensions/specrew-speckit/scripts/shared-governance.ps1`, `scripts/internal/sync-boundary-state.ps1`, `extensions/specrew-speckit/scripts/create-governed-feature.ps1`, `scripts/internal/dashboard-renderer.ps1`, `scripts/specrew-where.ps1`, `tests/unit/feature-resolver.tests.ps1`.
- [ ] T011 [owner: Implementer] [sp: 2.0] [US4] **New-feature cycle reset and per-feature runtime state (B4F-109).**
  - **Work:**
    - One shared cycle-reset function treats `feature-closeout -> specify` for a different feature as a reset. It is called by `Get-SpecrewPendingBoundaryCrossing` and `Add-SpecrewBoundaryAuthorization`, replacing the duplicated rule.
    - New ledger entries and crossings carry `feature_ref`.
    - `Get-SpecrewReviewCoverageState` and `Get-SpecrewReviewCoverageLine` select only campaigns of the resolved feature.
    - Legacy entries are never rewritten; `auth-83b0f0c2...` stays.
  - **RED:** today, 202's specify sync opens no crossing and the authorization writer refuses a backward move; the coverage line names `cmp-199-beta3-stabilization-i002`.
  - **Acceptance:** a second feature's specify opens a crossing, and the verdict is captured with 0 out-of-band entries; the coverage line has 0 references to a closed feature's campaign (SC-009); an append-only test checks that no legacy entry changed.
  - **Trace:** FR-026; SC-006, SC-009.
  - **Depends:** T010.
  - **Owns:** `extensions/specrew-speckit/scripts/shared-governance.ps1`, `scripts/internal/sync-boundary-state.ps1`, `tests/unit/new-feature-reset.tests.ps1`.
- [ ] T012 [owner: Implementer] [sp: 1.0] [US4] **Resume from disk (B4F-089).**
  - **Work:** the "where we are / starting now" lines come from the pending crossing, `from_commit..HEAD` and progress only. The handover narrative is shown as context with its age, and flagged when older than the ledger or naming another feature.
  - **RED:** the 4a22ba8f shape: a narrative at iteration-closeout while disk holds the plan crossing.
  - **Acceptance:** the resume lines match disk; a stale or other-feature narrative is flagged and not repeated.
  - **Trace:** FR-019.
  - **Depends:** T010.
  - **Owns:** `scripts/internal/bootstrap/HandoverStore.ps1`, both bootstrap-provider copies, `scripts/internal/coordinator-resume.ps1`, `tests/unit/resume-from-disk.tests.ps1`.

## Phase 7: US5, a refusal names the step that fixes it (P2)

- [ ] T013 [owner: Implementer] [sp: 0.5] [US5] **Design-analysis gate names its producer and lists every gap in one pass.**
  - **Work:** `Invoke-SpecrewDesignAnalysisPlanBoundaryGate` and `Test-SpecrewDesignAnalysisArtifact` name the producing step (`New-SpecrewDesignAnalysisArtifact` / the design workshop) and report all missing sections, labels and per-option fields in one refusal (widened by DRIFT-002).
  - **RED:** today, the missing file is named without its producer, and the format is disclosed one layer per refusal (three refusals on 202).
  - **Acceptance:** one refusal lists every gap plus the producer.
  - **Trace:** FR-020.
  - **Owns:** `scripts/internal/design-analysis-gate.ps1`, `tests/unit/design-analysis-gate-refusal.tests.ps1`.

## Phase 8: US6, turn drafts never leak into commits (P3)

- [ ] T014 [owner: Implementer] [sp: 1.0] [US6] **Per-session draft intake over stdin (DA-4).**
  - **Work:**
    - `declare-turn-end.ps1` reads the draft from stdin with explicit UTF-8 on every OS and stores it at `.specrew/runtime/turn-end/<ownerHash>/turn-message.md`; the agent passes only `-Token` and `-Kind`.
    - A host without a session id (per T001) uses a per-token path, which is disclosed.
    - The three skills name the stdin form.
  - **RED:** two concurrent sessions overwrite one draft path; a non-ASCII draft is mangled (the B4F-065 class).
  - **Acceptance:** Hebrew and other non-ASCII text round-trips byte-exact on Windows, macOS and Linux; two sessions never collide; drafts are git-ignored.
  - **Trace:** FR-021.
  - **Depends:** T001, T007.
  - **Owns:** `extensions/specrew-speckit/scripts/declare-turn-end.ps1`, `extensions/specrew-speckit/scripts/turn-end-store.ps1`, `extensions/specrew-speckit/squad-templates/skills/**`, `tests/unit/turn-draft-intake.tests.ps1`.

## Phase 9: Acceptance evidence

- [ ] T015 [owner: Implementer] [sp: 1.0] **Tier 1 acceptance evidence for the iteration-001 closeout.**
  - **Work:**
    - The before/after friction table per scenario (real decisions, corrective exchanges, extra stops), with null where not captured, never zero.
    - A validator run compared against the known baseline (review-evidence, defer-provenance, 198/011 needs-rework).
    - The live-walk script for Claude, Codex (healthy worktree) and Copilot.
    - Host tiers stated as validated or experimental.
    - Before the signoff round, the two f199 lanes parked in `.specrew/verification-plan.signoff-lanes.json` return to `.specrew/verification-plan.json` (DRIFT-013, maintainer ruling 2026-10-14).
  - **Acceptance:** the evidence files exist and every SC is mapped to its evidence.
  - **Trace:** FR-024; SC-001, SC-003, SC-008.
  - **Depends:** all.
  - **Owns:** `specs/202-beta4-1-ux-stabilization/iterations/001/**`.

## Dependencies

```text
T001 -> T002 -> T003 -> T004 -> T005 (needs T002, T003, T004)
              \-> T006 -> T007 -> T008 (+T001), T009, T014 (+T001)
              \-> T010 -> T011, T012
T013 independent; T015 last
```

## Parallel opportunities

These are limited by design: the conformance provider, dispatcher and turn-end store are shared. T013 and T009 could run in parallel with the US4 chain (disjoint files), but serial execution is recommended (iteration plan, Concurrency Rationale).

## Coverage

- **US1:** T002, T003, T004, T005.
- **US2:** T006, T007, T008.
- **US3:** T009.
- **US4:** T010, T011, T012.
- **US5:** T013.
- **US6:** T014.
- **Cross-cutting evidence:** T001, T015.
- **FR-001 to FR-021 and FR-024 to FR-026** each map to at least one task. FR-022 and FR-023 belong to iteration 002.
