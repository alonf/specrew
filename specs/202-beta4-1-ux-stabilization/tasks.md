# Tasks: beta4.1 UX stabilization (iterations 001 and 002)

**Feature**: 202-beta4-1-ux-stabilization
**Plan**: file:///C:/Dev/specrew-beta3-stabilization/specs/202-beta4-1-ux-stabilization/plan.md
**Date**: 2026-10-13
**Effort unit**: story points. 25.5 SP is planned against the 20 SP convention, an overcommit of 5.5 SP recorded by the maintainer's plan verdict. Review is governed by the codex round allowance, not SP.

Iteration 001 (Tier 1, T001 to T015, closed 2026-10-17) and iteration 002 (US8, T016 to T024, below). US7 (FR-022/023) moved to beta5 at the iteration-002 plan.

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
- **Review cadence (maintainer ruling, 2026-10-14, DRIFT-018):** co-review round 3 runs once T011 is committed and covers T006 to T011. T010 and T011 touch authority state, and rounds 1 and 2 found 13 real defects, so their fixes need a round before sign-off. Round 4, at sign-off, covers T012 to T014 and the round-3 fixes.
- **Demoted findings are checked, every one (maintainer rule for 202, until B4F-055 is fixed):** in rounds 3 and 4, every finding the engine demotes is checked against the code and listed in that round's checkpoint as real or not, with the reason, before any sign-off. Rounds 1 and 2 demoted 12 of their 13 findings (the 13th was reported minor), and all 13 were real (count corrected 2026-10-16, DRIFT-033).

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
- [x] T005 [owner: Implementer] [sp: 2.5] [US1] **Cross-host workshop acceptance and fault-injection suite.** Reopened 2026-10-14 by the maintainer (DRIFT-018); closed 2026-10-14 on run 38587028733 at `bd3de8e2`.
  - **Work:**
    - **Cross-host acceptance:** product-domain, then agenda, then one lens, through the real launcher and dispatcher with each validated host's deployed binding and the T001 fixtures. Each host yields 3 receipts and needs exactly 1 reply per checkpoint.
    - **Fault cases (a) to (e):** (e) is two real `pwsh` processes appending at once; both succeed with intact lines and no degradation.
    - **Experimental hosts:** Cursor and Antigravity run the contract test only if T001 captured their payloads; otherwise they are listed as unvalidated in the evidence.
    - **Workflow change (DRIFT-003):** a minimal `.github/workflows` change runs case (e) on Windows, macOS and Linux. It uses the existing OS matrix only, with no new jobs and no publication or deployment change.
  - **Acceptance:** the suite is green on three OSes; **the workflow diff is reviewed like code** (codex co-review covers it and the review records it); experimental hosts are labelled as such in the results.
  - **Trace:** FR-024, FR-025; SC-001, SC-002.
  - **Depends:** T002, T003, T004.
  - **Owns:** `tests/unit/cross-host-workshop.tests.ps1`, `tests/unit/journal-fault-injection.tests.ps1`, `.github/workflows/**` (minimal).
  - **Progress 2026-10-14 (reopened):**
    - **Windows, green.** Each validated host gives 3 receipts from 3 replies.
    - **Case (e):** 2,000 of 2,000 lines intact, and 5 concurrent dispatcher pairs all journaled.
    - **Mutations caught:** a plain `Append` stream on Windows lost 3 to 4 lines per run; console stdin decoding broke Claude's Hebrew reply.
    - **Workflow:** one step was added to the existing `review-runtime-fault-matrix` job. There are no new jobs.
    - **First 3-OS run (38487295823):** Windows green. Linux lost 58 of 2,000 lines and tore 1; macOS lost 32. Linux and macOS now take the permitted per-write lock on this journal (DRIFT-014).
    - **3-OS rerun with the lock (38490308475, on `34af7076`):** green on Windows, Linux and macOS, with 2,000 of 2,000 lines, none torn. The whole workflow passed.
    - **Codex review of the workflow diff:** co-review round 2 (`run-20261014-102731596-597f9ec9`) examined `.github/workflows/cross-platform-validation.yml` and raised no finding on it. Its five findings concern T003 and T004 code and are fixed (DRIFT-015).
    - **Why it is open again (maintainer, 2026-10-14):** the only 3-OS run was at `34af7076`. `0b62bf9b` later changed the Linux and macOS outage-buffer behavior (one closed file per record), and that has never run on Linux or macOS. The workflow also never ran on push for this branch, because its push filter stopped at `1*-*`; `2*-*` is now added (DRIFT-018).
    - **Closes when:** cross-platform validation is green on all three OSes at the current HEAD, with the case (e) step present in each leg's log.
    - **First push run (38563251438, on `d3c010a4`):** green; the case (e) step passed on Windows, Ubuntu and macOS. Case (e) never degrades, though, so the closed-file buffer still had not run on Linux or macOS. The same step now also runs `hook-output-journal.tests.ps1`, whose cases (b), (c), (h) and (i) go through the buffer (DRIFT-018).
    - **What the 3-OS step found next:**
      - The buffer suite's first Unix run failed on three Windows-only test-harness assumptions. These were reproduced in WSL Ubuntu and fixed (`f3f68c75`).
      - Case (e) degraded once on Linux and once on macOS: an unfair Unix lock starved a writer, an FR-001 failure. It was fixed with a 1000 ms wait for a turn, and case (e) now runs four writers (DRIFT-023).
    - **Closed (run 38587028733, on `bd3de8e2`, the HEAD at the time):** green on Windows, Ubuntu and macOS. Each leg's log shows the case (e) step passing: four writers, 4,000 of 4,000 lines, plus the outage-buffer suite.

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
- [x] T008 [owner: Implementer] [sp: 1.5] [US2] **Orientation before the first question (DA-3).** Done 2026-10-14. `orientation-order.tests.ps1` drives the real bootstrap and conformance providers with the dispatcher's turn record:
  - **Green:** the first prompt carries the finished orientation, marked `[specrew-system]`, with the real version and host, the pending decision and its approval phrase, the artifacts link and the dials line, and nothing left to fill in. The second prompt carries nothing, and the conformance lane adds no second dials line. A host flagged for direct display gets no instruction to repeat it. The B4F-096 replay (a first question with no orientation, nothing pending) gives 0 Stop blocks. Another session's bootstrap does not earn this session an orientation receipt.
  - **RED on `0e5035d2`:** the catalog does not bind the bootstrap to the prompt; no finished orientation; the B4F-096 Stop demand; any session's render claim counted.
  - **Design notes:** the finished orientation is rendered from resolved values by a new function in the bootstrap provider; the existing host orientation block leaves placeholders for the agent and was not reused. The SessionStart directive now tells the agent to show the supplied text instead of composing one. No validated host is flagged for direct display (T001), so the flag defaults off. The catalog binds the bootstrap to the prompt, and the dispatcher skips it once the per-session stamp exists (DRIFT-017). `session-orientation-rendered` moved to the new contract.
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

- [x] T009 [owner: Implementer] [sp: 1.0] [US3] **One shared dials sentence.** Done 2026-10-14. `dials-parity.tests.ps1`:
  - **Green:** for claude, codex and copilot the sentence is byte-identical apart from the correction reference, with no `key=number` text. The conformance turn-start supply and the first-prompt orientation carry it on each host. The numeric renderer is gone.
  - **RED on `d3c010a4`:** the numeric line reached all three hosts through both surfaces.
  - **Design notes:** the reference comes from the host manifest's existing `HasUserSlashCommandSurface`: `/specrew-user-profile edit` where the host has slash commands, "ask me to update your profile" where it does not (Codex). It lives beside the prose renderer in `user-profile.ps1`. The two launch-contract paths (`specrew-start.ps1`, `SessionBootstrapManager.ps1`) pass it too (DRIFT-019).
  - **Work:** use `Get-SpecrewProfileOrientationLine`'s prose sentence everywhere; remove `Get-SpecrewOrientationDialsLine` (the numeric renderer); the host binding supplies only the correction-command reference.
  - **RED:** the numeric line `software_architecture=10, ...` reaches the agent through the Stop repair.
  - **Acceptance:** byte-identical across the three validated bindings apart from the command reference; no `key=number` text on any host.
  - **Trace:** FR-016; SC-005.
  - **Depends:** T007.
  - **Owns:** `scripts/internal/user-profile.ps1`, `extensions/specrew-speckit/scripts/turn-end-store.ps1`, `tests/unit/dials-parity.tests.ps1`.

## Phase 6: US4, one answer to "what are we working on" (P2)

- [x] T010 [owner: Implementer] [sp: 2.0] [US4] **One feature resolver (DA-5).** Done 2026-10-14. `feature-resolver.tests.ps1` builds each project state and asks the resolver, the real `where` dashboard and the first-prompt orientation:
  - **Green:** all three name the same feature and the same source in every state:
    - B4F-105 (199 closed, empty pointer, branch 201) gives 201 from the branch;
    - 199 on branch 201 gives 199 from the work in flight;
    - a pointer written for this branch decides; one written on another branch does not;
    - an open workshop is in flight, and a shipped feature's stale controller is not;
    - two features in flight choose nothing and ask;
    - a pending decision wins.
    Both governed writers stamp the pointer with its branch through one writer, and `session_state` records its branch.
  - **RED on `f3f68c75`:** status showed 001 for B4F-105 and followed the stale pointer to 201 for 199-on-201. Status and orientation disagreed in five of the six states.
  - **Design notes:** a workshop is in flight only while the spec is still the unauthored stub. The dashboard no longer falls back to the lowest-numbered feature. `Resolve-SpecrewActiveFeatureRef` is now the resolver's answer, so every existing caller agrees with status (DRIFT-020).
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
- [x] T011 [owner: Implementer] [sp: 2.0] [US4] **New-feature cycle reset and per-feature runtime state (B4F-109).** Done 2026-10-14. `new-feature-reset.tests.ps1` drives the real boundary sync and the real prompt-time capture:
  - **Green:** after the first feature's closeout, a second feature's specify sync opens `feature-closeout -> specify`, and the crossing names the new feature. The typed verdict is captured with 0 out-of-band entries, and the new entry names its feature. Every legacy entry is byte-identical afterwards.
  - **The rule:** a re-sync of the same feature is not a reset; the iteration loop still is; a plain backward move is still refused. The coverage line names 0 campaigns of the closed feature (SC-009). The readiness verdict says BLOCKED, not READY, for a new feature before its before-implement verdict (DRIFT-006).
  - **RED on `5b978958`:** no crossing, the verdict not captured, the coverage state naming the closed feature's campaign, and READY "authorized through 'feature-closeout'", which is DRIFT-006's exact line.
  - **Design notes:** one rule, `Get-SpecrewBoundaryCycleReset`, serves both former copies. A closed feature the ledger does not name (a legacy entry) counts as different, since a closed feature does not specify again. `feature_ref` is added after the entry id, which hashes a fixed field list, so no id changes (DRIFT-021).
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
- [x] T012 [owner: Implementer] [sp: 1.0] [US4] **Resume from disk (B4F-089).** Done 2026-10-14 (`488468fe`). `resume-from-disk.tests.ps1` drives the real bootstrap provider and the real `specrew start` resume block:
  - **Green:** both open with WHERE WE ARE, read from disk: the pending decision, the commits since the notes (newest first) and task progress. The starting point comes from the pending decision, else the next open task. Notes matching the disk are shown as context with their age. Notes written at another boundary, before the ledger's latest decision, or about another feature are flagged with the reason and not repeated.
  - **RED on `c21d19b4`:** B4F-089's shape repeated the stale notes, and nothing was read from disk (15 of 19 checks failed).
  - **Work:** the "where we are / starting now" lines come from the pending crossing, `from_commit..HEAD` and progress only. The handover narrative is shown as context with its age, and flagged when older than the ledger or naming another feature.
  - **RED:** the 4a22ba8f shape: a narrative at iteration-closeout while disk holds the plan crossing.
  - **Acceptance:** the resume lines match disk; a stale or other-feature narrative is flagged and not repeated.
  - **Trace:** FR-019.
  - **Depends:** T010.
  - **Owns:** `scripts/internal/bootstrap/HandoverStore.ps1`, both bootstrap-provider copies, `scripts/internal/coordinator-resume.ps1`, `tests/unit/resume-from-disk.tests.ps1`.

## Phase 7: US5, a refusal names the step that fixes it (P2)

- [x] T013 [owner: Implementer] [sp: 0.5] [US5] **Design-analysis gate names its producer and lists every gap in one pass.** Done 2026-10-14 (`018c4d13`). `design-analysis-gate-refusal.tests.ps1`: a missing or empty artifact is refused with its producer and the whole format; a missing section carries everything it must hold; a crew that fixes exactly what one refusal lists passes. RED on `83f2afea`: 35 of 41 checks failed, and an empty `design-analysis.md` threw a parameter-binding error instead of refusing.
  - **Work:** `Invoke-SpecrewDesignAnalysisPlanBoundaryGate` and `Test-SpecrewDesignAnalysisArtifact` name the producing step (`New-SpecrewDesignAnalysisArtifact` / the design workshop) and report all missing sections, labels and per-option fields in one refusal (widened by DRIFT-002).
  - **RED:** today, the missing file is named without its producer, and the format is disclosed one layer per refusal (three refusals on 202).
  - **Acceptance:** one refusal lists every gap plus the producer.
  - **Trace:** FR-020.
  - **Owns:** `scripts/internal/design-analysis-gate.ps1`, `tests/unit/design-analysis-gate-refusal.tests.ps1`.

## Phase 8: US6, turn drafts never leak into commits (P3)

- [x] T014 [owner: Implementer] [sp: 1.0] [US6] **Per-session draft intake over stdin (DA-4).** Done 2026-10-15 (`b9cf8b71`, `a1096ef3`). `turn-draft-intake.tests.ps1` (26 checks), on Windows and Linux locally and in the 3-OS workflow: Hebrew, emoji and CRLF round-trip byte-exact; two concurrent sessions keep separate drafts; a host with no session id gets a disclosed per-token folder; `-MessagePath` still works; an open, silent stdin does not hang; non-UTF-8 is refused; drafts are git-ignored; the three skills name the stdin form. RED on the old code: stdin ignored, no draft, empty message. Rule 46A and four Stop instructions also name stdin (DRIFT-028).
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

- [x] T015 [owner: Implementer] [sp: 1.0] **Tier 1 acceptance evidence for the iteration-001 closeout.** Done 2026-10-15. `iterations/001/acceptance-evidence.md` maps every SC to its evidence, states host tiers (Claude, Codex and Copilot validated; Cursor and Antigravity experimental, unvalidated), and holds the friction table: the spec's before-values, with after-values null until the live walk. `iterations/001/live-walk.md` is the maintainer's walk script for the closeout. The validator against the baseline: SC-008 holds (B4F-124 records why the review-evidence count moves with campaign state). The two f199 lanes are back in the plan, re-timed cold and split to keep 2.4x (DRIFT-029).
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

## Iteration 002: one human act, one record (US8)

**Planned**: 2026-10-17, plan approved by the maintainer (`09fcbe07`). 17 SP against the 20 SP convention, accepted at
the plan stop above the maintainer's 15.25 SP scope ruling. Design: `iterations/002/design-analysis.md`, DA-1 to DA-5,
each with the maintainer's changes. B4F-127 (T017) and B4F-129 (T016) are the beta4.1 release gate.

The iteration-001 rules above carry over: RED first through the shipped entry point; mirror, twin-copy and psd1 FileList
parity; SelfLeakLintLane; the consumer-language check.

### Execution order (iteration 002)

T017, T016, co-review round 1, (rounds 2 to 4 on the fixes), T022, T020, T021, T018, T019, a further round after an
allowance reset, T023, T024. After the failed SC-011 re-walk (DRIFT-006): T025, T026, T027, T028, T029, one review
round, T030.

- T017 before T016: both change the turn record and the dispatcher twins, and T016's duplicate-receipt refusal builds on
  T017's message identity.
- T022 before T020 and T021: the receipt area is simplified before the items that change receipts.
- **Review cadence:** round 1 after T016 (covers T016 and T017, the approval handling and the release gate); round 2
  to 4 on the fixes, by the maintainer's choice (DRIFT-003), which spends the allowance. A round after T019 (covering the
  round-4 fixes, T022, T020, T021, T018, T019) follows the maintainer's allowance reset of 2026-10-17; it ran as round 5
  on 2026-10-18 (5 findings, all real, fixed). Round 6, on the round-5 fixes, T023 and T024, ran on 2026-10-18 (6
  findings, all real, fixed). Round 7, on the round-6 fixes, ran on 2026-10-18 (3 findings, all real, fixed). Round 8,
  on the round-7 fixes, ran on 2026-10-18 (2 findings, all real, fixed); it spent the last round in the allowance. The
  review closed on 2026-10-18 on the maintainer's typed partial sign-off, after the stop refused (DRIFT-003).
- **Standing rules for every round:** no commit between an approval and the step that uses it; before a round launch, a
  stop decision or an allowance reset, the stored approval must come from the maintainer's own typed message for that run
  (the B4F-127 interim rule, until T017 is reviewed); every demoted finding is checked against the code and listed as
  real or not, with the reason (B4F-055 is in beta5).

### Phase 10: US8, release gate

- [x] T017 [owner: Implementer] [sp: 4.5] [US8] **One message, one key (DA-2, B4F-127).** Done 2026-10-17. `message-identity.tests.ps1` (17 cases, its own lane `f202-i002-suites`, 106 s against 300 s) drives the shipped handover provider as a process: RED on the old code, 12 of 16 failing with B4F-127's numbers (2 approvals per message, 5 in a long transcript); green after. `turn-record-contract.tests.ps1` asserts the dispatcher forwards `--message-id` from the declared field map and `--message-identity` on every event (RED, then green). Found on the way: a Claude compaction summary was read as a human turn; it is now machinery, guarded by a case that T018 must keep green. All seven earlier lanes green on the working tree.
  - **Work:** add `PromptId` (`prompt_id`) to Claude's input field map and `turn_id` to Codex's; carry the message ID on
    the turn record (dispatcher twins) and through the provider args to both recording paths. Drop the source event from
    `Get-SpecrewTypedTurnIdentity`; key on host, session and message ID. The turn-end transcript path reads `prompt_id` from
    the human-typed transcript entry, never the entry's `uuid`; injected entries are skipped; the compaction summary's
    reuse of the `/compact` entry's ID is handled. A spent approval from the same message is final in every writer's
    unspent check. On Copilot the turn-end path records no approvals, and an approval-shaped typed message the prompt hook
    did not record is written to the journal and reported in one visible line.
  - **RED:** a replay per host from recorded payloads: one typed approval through both paths gives two rows today
    (`iterations/001/b4f-127-reproduction.md`).
  - **Acceptance:** SC-010 on Claude, Codex and Copilot: one approval gives exactly one row, and N later turns with no human
    message add none; the four affected kinds (round approval, allowance reset, stop decision, coverage deferral) each
    covered; the Copilot unrecorded-approval line covered.
  - **Trace:** FR-027; SC-010; DA-2.
  - **Owns:** `scripts/internal/bootstrap/HandoverStore.ps1`, `scripts/internal/bootstrap/HumanAuthorityStore.ps1`,
    `hosts/claude/host.psd1`, `hosts/codex/host.psd1`, `hosts/copilot/host.psd1`, both `specrew-hook-dispatcher.ps1` twins,
    both `specrew-handover-provider.ps1` twins, `extensions/specrew-speckit/scripts/shared-governance.ps1` (coverage deferral
    writer), `tests/unit/message-identity*.tests.ps1`.

- [x] T016 [owner: Implementer] [sp: 3.0] [US8] **A hook acts only for its own host (DA-1, B4F-129).** Done 2026-10-17. `host-binding-match.tests.ps1` (255 assertions, 71 s, lane `f202-i002-suites`, now 450 s for 177 s measured) runs every recorded payload through every validated host's deployed hook command. RED on the old code: 79 failures, among them all 12 Copilot payloads running in the Claude hook and a reply offered twice leaving two receipts. Each binding now declares its payload signature and carries the other hosts' (baked by the deployer); a hook stands down, writing nothing, only on a positive foreign match; an unknown shape is handled and its field names logged once; the receipt store refuses a receipt ID it already holds. All eight lanes green on the working tree.
  - **Work:** each host binding declares, per event, the payload fields only its host sends (Claude `prompt_id` or its
    event-specific fields, Codex `turn_id`, Copilot camelCase `sessionId`). The shared path stands a hook down (exit 0,
    nothing written) only when the payload positively matches another known host; a payload matching no known host is
    handled as today and logged once. The workshop receipt store refuses a receipt ID it already holds.
  - **RED:** the recorded Copilot payloads fed to the deployed Claude hook command write rows today (the walk's doubled
    receipts and the Claude-labelled stop-blocks).
  - **Acceptance:** a fixture matrix over every recorded payload (14 Copilot, plus Claude's and Codex's) against every
    host's deployed command: own host handled, another host's payload stood down, an unknown shape handled and logged
    once; a duplicate receipt ID refused.
  - **Trace:** FR-028; SC-011 (proven live in T024); DA-1.
  - **Depends:** T017.
  - **Owns:** `hosts/*/host.psd1`, both dispatcher twins, both `deploy-refocus-hooks.ps1` twins if the command needs the
    binding, `extensions/specrew-speckit/scripts/workshop-authority-store.ps1`, `tests/unit/host-binding-match*.tests.ps1`.

### Phase 11: US8, receipts and delegation

- [x] T022 [owner: Implementer] [sp: 2.25] [US8] **Retire the receipt-outcomes journal (DA-5, retro candidate 3).** Done 2026-10-18. Each session keeps its reply outcome in its own folder (`conformance-sessions/<session>/workshop-receipt-outcome.json`: the latest outcome, and the latest refusal per feature and phase); the dispatcher's disclosure and the Stop's refusal check read only that, and the journal writer is gone. R5-5 reproduced on the old code (session B's Stop check saw session A's refusal) and fixed: `receipt-disclosure` case 20. `receipt-outcomes-retired.tests.ps1` (lane `f202-slice-suites-a`) runs a real `specrew update` that deletes the journal and says so, and finds no shipped code naming it but that step; RED on the old code. `cross-host-workshop` and `hook-output-journal` read the session record now.
  - **Work:** the receipt outcome becomes a field on the current turn's record in the session's own folder; the
    dispatcher's recording disclosure and the conformance provider's latest-refusal check read it there; the journal
    writer is removed in the same change; `specrew update` deletes `.specrew/runtime/workshop-receipt-outcomes.jsonl`.
  - **RED:** two sessions in one project: a refusal in one shows in the other today (R5-5).
  - **Acceptance:** the R5-5 test green; the same-turn disclosure and the Stop's refusal check unchanged in behaviour for
    one session; no code writes or reads the journal; update removes it and says so.
  - **Trace:** FR-033; DA-5.
  - **Depends:** T016.
  - **Owns:** `extensions/specrew-speckit/scripts/workshop-authority-store.ps1`, both dispatcher twins,
    `extensions/specrew-speckit/scripts/specrew-conformance-provider.ps1`, `scripts/specrew-update.ps1`, the
    tests that read the journal today (cross-host-workshop, hook-output-journal, receipt-disclosure).

- [x] T020 [owner: Implementer] [sp: 2.0] [US8] **Delegation of the remaining lenses (DA-4, B4F-130).** Done 2026-10-18. A delegation in one of the two exact wide forms records one receipt per lens still open on the agenda, each bound to the message ID (receipts now carry `message_id`), and the turn tells the crew which lenses it covered; "the rest" delegates only the open lens; a narrow delegation with lenses open says so and names the wide phrase. A lens closes on its newest receipt, or, when it was covered by a wide delegation and only confirmed answers (the reviewer pick) came after it, on that delegation (a narrow "you decide" followed by an answer is a changed mind, as `workshop-typed-turn-authority` pins); the lens checkpoint and the readers that check a closed lens use the same rule, and a later skip still wins. The skill asks the reviewer choice once, at agenda confirmation, outside delegation. `workshop-delegation.tests.ps1` (12 s, lane `f202-i002-suites`): RED on the old code with the walk's case (one lens recorded, the mixed lens refused), green after.
  - **Work:** exact wide forms ("the remaining lenses", "all remaining lenses") record one delegation per lens left on
    the agenda, bound to the message ID, and the crew names them in one line; "the rest" is not a wide form; a narrow
    delegation with lenses pending says so and names the wide phrase; the reviewer choice is asked once at agenda
    confirmation with the default named, and stays outside delegation; a lens with delegated craft decisions and a
    confirmed reviewer pick closes without a question.
  - **RED:** the walk's case: "you decide the remaining lenses" records one lens and the next lens asks again.
  - **Acceptance:** wide form covers every remaining lens; narrow form's line names the phrase; the mixed lens closes with
    both receipts and no question.
  - **Trace:** FR-031; DA-4.
  - **Depends:** T022.
  - **Owns:** `workshop-authority-store.ps1`, `extensions/specrew-speckit/scripts/confirm-workshop-lens.ps1`,
    `extensions/specrew-speckit/squad-templates/skills/design-workshop.md`, `tests/unit/workshop-delegation*.tests.ps1`.

- [x] T021 [owner: Implementer] [sp: 1.0] [US8] **No instruction permits a question tool for workshop questions (B4F-131).** Done 2026-10-18. The permitting text was in the boundary-stop skill, which every host reads: "A picker in a design discussion ... is doing good work and stays". It now keeps pickers for exchanges nothing records and says workshop questions are never asked through a picker or question tool on any host. The launch instructions and the coordinator governance asked for "an explicit interactive question" for greenfield intake; they now ask for visible prose answered by a typed reply. `workshop-question-tool.tests.ps1` (47 shipped files, lane `f202-i002-suites`): RED on the old text with those three findings, green after.
  - **Work:** find the shipped instruction that let Copilot use its question box for lens questions and make it agree
    with the workshop rule.
  - **RED:** a text test over every shipped host instruction and skill finds the permitting text.
  - **Acceptance:** the text test is green across every host's instructions.
  - **Trace:** FR-032.
  - **Depends:** T022.
  - **Owns:** `extensions/specrew-speckit/squad-templates/**`, host instruction templates, `tests/unit/workshop-question-tool*.tests.ps1`.

### Phase 12: US8, approval form

- [x] T018 [owner: Implementer] [sp: 3.0] [US8] **Approval form (DA-3, B4F-125).** Done 2026-10-18. The router decides on the approval form before any writer runs, so every writer (the coverage-deferral copy included) follows it. On Claude a paste runs from an opening tag to the first closing tag with the same ID (an unclosed one runs to the end), nothing inside counts, and the one authority line outside every paste is the approval, while the typed text stays within the observed paste-size boundary (the smallest of 26 tagged pastes in this project's transcripts: 675 characters over 9 lines); past it the one-line rule decides, which keeps PRED-BETA4-022's 136-line specimen refused. A message carrying more than one verdict option is refused as a quoted menu on every host. Other hosts keep the phrase alone, wherever it sits, and the refusal says the host cannot tell a paste from typing. A reset typed while a round waits on the spent allowance also writes that round's approval from the same typed act (`derived_from: allowance-reset:<id>`). The review command's refusals no longer offer an invocation as the approval. `approval-form.tests.ps1` (17 cases, lane `f202-i002-suites`): RED on the old code (the live B4F-125 message, the quoted menu, the named reason, the reset), green after; `round-approval-typed-authority` 130 of 130 and the compaction-summary guard in `message-identity` stay green.
  - **Work:** on Claude, a paste is a paired `<pasted_content id="N">` ... `</pasted_content id="N">` span with the same ID;
    nothing inside counts, and a phrase leading its own line outside every paste is an approval. A message with more than
    one verdict option is refused as a quoted menu. Other hosts keep "the phrase alone", with a refusal naming the reason.
    The coverage-deferral copy of the guard follows the same rule. An allowance reset requested in order to run a round
    authorizes that round. No approval request offers a command as the approval.
  - **RED:** `iterations/001/b4f-125-live-messages.json` (the reset typed below the maintainer's own paste is refused
    today); a quoted closing tag inside a paste; a quoted menu; the observed paste-size boundary.
  - **Acceptance:** each case above; the residual (a short untagged single approval line counts) is a named test, not a gap.
  - **Trace:** FR-029; DA-3.
  - **Depends:** T017.
  - **Owns:** `scripts/internal/bootstrap/HumanAuthorityStore.ps1`, `extensions/specrew-speckit/scripts/shared-governance.ps1`,
    `tests/unit/approval-form*.tests.ps1`.

- [x] T019 [owner: Implementer] [sp: 0.5] [US8] **A reworded discussion question counts (B4F-128).** Done 2026-10-18. A declared question line absent verbatim is present when a reply question carries its meaning: identical numbers and identifiers, identical negations, and content words (lightly stemmed, without the words any question carries) of which at least 0.8 of the shorter question's are in the other and 0.5 of all are shared; each reply question answers for one declared question. `presented-check` case 9 holds B4F-128's two exact lines (RED on the old code, green after) and keeps a changed number, a changed ID, an added negation, a different question and a dropped question missing.
  - **Work:** extend the heading meaning match to question lines.
  - **RED:** B4F-128's two exact lines.
  - **Acceptance:** the reworded question passes; a question with a changed number or negation still fails.
  - **Trace:** FR-030.
  - **Owns:** `extensions/specrew-speckit/scripts/turn-end-store.ps1`, `tests/unit/presented-check.tests.ps1`.

### Phase 13: cleanup and acceptance

- [x] T023 [owner: Implementer] [sp: 0.25] [US8] **Remove the unread draft copy (retro candidate 7).** Done 2026-10-18. `declare-turn-end.ps1` no longer saves `turn-message.md`, and the record and the script's report no longer carry `draft_path`, `draft_scope` or `draft_disclosure`; the store's location and save functions are gone; the three skills and the launch contract say the message is kept in the turn's own record. `turn-draft-intake.tests.ps1` rewritten: no copy for stdin, `-MessagePath`, two sessions or no session ID, and no shipped file names the copy (RED on the old code with 11 failures, green after).
  - **Work:** `declare-turn-end.ps1` stops writing `turn-message.md`; `draft_path` and the skill mentions go.
  - **Acceptance:** no writer; `turn-draft-intake.tests.ps1` updated; the message stays inline in the turn record.
  - **Trace:** FR-034.
  - **Owns:** `extensions/specrew-speckit/scripts/declare-turn-end.ps1`, `turn-end-store.ps1`, the three skills,
    `tests/unit/turn-draft-intake.tests.ps1`.

- [x] T024 [owner: Implementer] [sp: 0.5] [US8] **Iteration 002 acceptance evidence and the Copilot re-walk script.** Done 2026-10-18. `iterations/002/acceptance-evidence.md` maps FR-027 to FR-034, SC-010 and SC-011, the release gate, the five rounds and the validator run (23 iterations, every failure in a baseline category, 202 iteration 002 passing). `iterations/002/copilot-rewalk.md` is the maintainer's SC-011 walk, with its disk checks split by host; SC-011 stays `null` until it is walked.
  - **Work:** `iterations/002/acceptance-evidence.md` maps FR-027 to FR-034, SC-010 and SC-011 to evidence; validator run
    against the baseline; a short re-walk script for the maintainer on Copilot in a project that also holds Claude's hook
    settings (SC-011), with its disk checks split by host.
  - **Trace:** SC-010, SC-011.
  - **Depends:** all iteration 002 tasks.
  - **Owns:** `specs/202-beta4-1-ux-stabilization/iterations/002/**`.

### Phase 14: US8, the failed Copilot re-walk (iteration 003; DRIFT-006)

Added 2026-10-21 on the maintainer's `go with the fix plan`. The re-walk failed SC-011 at M1: Copilot also runs
Claude's hooks, sends them a payload shape no test had, and the dispatcher handled it as Claude's (B4F-144).
Moved to iteration 003 the same day by the maintainer's ruling (`move the fixes to iteration 003`): iteration 002 closes
with T016 to T024, and iteration 003's plan takes these tasks up with their review round and the re-walk. T025 to T029
are implemented and committed (`2fd7f2d6`) but not yet reviewed.

- [x] T025 [owner: Implementer] [sp: 1.0] [US8] **Capture the real payloads (B4F-145, layer 1).** Done 2026-10-21. The probe captured every channel on Copilot 1.0.101, Claude 2.1.303 and Codex 0.163.0, sub-agents included; Copilot runs Claude's hooks only in a trusted folder that is a git repository. The fixtures are in `tests/fixtures/hook-payloads/probe/`, with no secrets. On the old code the probe failed 14 checks, all on Claude's hooks under Copilot; after T026 it passes 108 of 108, with the user's own hook and config files unchanged.
  - **Work:** `tests/host-probes/host-payload-capture-probe.ps1` runs Copilot, Claude and Codex in scratch folders with
    capture hooks on every event, a plain prompt and a sub-agent prompt each, Copilot's own hooks and Claude's hooks as
    Copilot runs them. It replays every capture through the deployed hooks, exports the payloads as fixtures with their
    provenance, and leaves the user's own host settings unchanged. The deployed-hook harness moves out of the binding
    suite into `tests/host-probes/deployed-hook-harness.ps1`, shared by the probe and the suites.
  - **Acceptance:** a capture on every channel, including Claude's hooks under Copilot; a run that captures nothing on
    that channel fails.
  - **Trace:** FR-028; SC-011.
  - **Owns:** `tests/host-probes/**`, `tests/fixtures/hook-payloads/probe/**`.

- [x] T026 [owner: Implementer] [sp: 0.75] [US8] **Copilot's second payload shape (B4F-144).** Done 2026-10-21. Copilot's payload signature lists two shapes, its own and the one it sends Claude's hooks (`timestamp` on every event); Claude's SessionStart and PostToolUse rules refuse `timestamp`, which separates the two hosts without a SessionStart decision. `host-binding-match.tests.ps1` part 1b: 32 failures on the old code, green after; twin parity and the per-host checks pass.
  - **Work:** a binding's payload signature may list alternatives. Copilot's gains the shape it sends Claude's hooks
    (snake_case with `timestamp`, never `prompt_id`, `permission_mode`, `turn_id` or `model`); Claude's SessionStart and
    PostToolUse rules refuse `timestamp`, which Claude never sends.
  - **RED:** the probe payloads in `host-binding-match.tests.ps1` (part 1b): 32 failures on the old code, every one on
    Claude's hooks under Copilot.
  - **Acceptance:** every probe payload is handled by its own host's hook and stands down in the others with nothing
    written; the live probe passes.
  - **Trace:** FR-028; SC-011.
  - **Depends:** T025.
  - **Owns:** `hosts/*/host.psd1`, both dispatcher twins, both `deploy-refocus-hooks.ps1` twins,
    `tests/unit/host-binding-match.tests.ps1`.

- [x] T027 [owner: Implementer] [sp: 0.25] [US8] **A reader for the unrecognized-payload record.** Done 2026-10-21. `host-binding-match.tests.ps1` fails on any record from a recorded payload (parts 1 and 1b), the probe fails on any record from a capture, and `copilot-rewalk.md` counts the records in `.specrew/runtime/hook-health/` and expects 0, beside a new count of hook rows under `claude`, the check the first walk failed at M1.
  - **Work:** the binding suite, the probe and the re-walk's disk checks each count `unrecognized-payload-*.json` and fail
    on any.
  - **Trace:** FR-028; DRIFT-006's class closure.
  - **Depends:** T026.
  - **Owns:** `tests/unit/host-binding-match.tests.ps1`, `tests/host-probes/**`, `iterations/002/copilot-rewalk.md`.

- [x] T028 [owner: Implementer] [sp: 0.5] [US8] **A sub-agent's task text is never a human approval (B4F-147).** Done 2026-10-21. Each host's origin rules start with a rule on the payload's own fields: a payload carrying `agent_id`, `parent_agent_id`, `agentId` or `parentAgentId` is host-injected, never typed by the human. `subagent-prompt-authority.tests.ps1` puts `approved for review round` into ten sub-agent payloads across Copilot's own channel, Claude's hooks under Copilot and Claude's own channel, and runs the deployed hook and then the real provider: RED on the old code with 23 failures (every case typed-user, and every one stored), green after; the two controls without a sub-agent field store the approval. The test pins the provider to its temp project and fails if the repository's stores change (DRIFT-007, B4F-148).
  - **Trace:** FR-027, FR-028.
  - **Owns:** `hosts/*/host.psd1`, both dispatcher twins, `tests/unit/subagent-prompt-authority.tests.ps1`.

- [x] T029 [owner: Implementer] [sp: 0.5] [US8] **Product-domain questions in prose (B4F-131, T021's rule).** Done 2026-10-21. Every host's composed guidance now says the first question about a new feature is the product-domain question and never a clarify question; Copilot's names `ask_user` as its question tool without declaring it a structured primitive (`QuestionTool` in its binding); the Codex and Claude bindings no longer say to use their question tool "for human approval gates"; the launch contract and the product-domain lens say the same. The extended scan found the instruction T021 missed, in Copilot's own agent file (`templates/github/agents/squad.agent.md`): "ask an explicit interactive question such as 'What do you want to build?'". It now asks in prose, never through `ask_user`. `workshop-question-tool.tests.ps1` (122 shipped files): RED on the old text with 11 failures, green after.
  - **Work:** every shipped instruction says product-domain and grounding questions are workshop questions, asked as
    prose and answered by a typed reply, never through the host's question tool; Copilot's guidance names `ask_user`.
  - **RED:** T021's text test extended to the templates and refocus files, and to the clarify-picker lines.
  - **Trace:** FR-032.
  - **Owns:** `hosts/*/host.psd1`, `scripts/internal/launch-contract.ps1`, coordinator guidance and templates,
    `tests/unit/workshop-question-tool.tests.ps1`.

- [ ] T030 [owner: Implementer] [sp: 0.25] [US8] **Acceptance and the re-walk with a capture hook.**
  - **Work:** the acceptance evidence for T025 to T029; `copilot-rewalk.md` installs a capture hook beside Specrew's, so
    the walk keeps every payload it sees, and adds the unrecognized-payload check.
  - **Progress (2026-10-21):** `tests/host-probes/walk-capture-hook.ps1` installs, summarizes and removes the capture
    hook; checked in scratch: the captures are written, the hook groups survive Specrew's own hook redeploy, and removal
    restores the project's Claude settings exactly. `copilot-rewalk.md` uses it. The evidence waits for the review round
    and the walk.
  - **Trace:** SC-011.
  - **Depends:** T025 to T029 and their review round.
  - **Owns:** `specs/202-beta4-1-ux-stabilization/iterations/003/**`, `iterations/002/copilot-rewalk.md`.

### Dependencies (iteration 002)

```text
T017 -> T016 -> [round 1] -> T022 -> T020, T021
T017 -> T018 -> T019 -> [round after reset] -> T023 -> T024
```

### Dependencies (iteration 003)

```text
T025 -> T026 -> T027; T028; T029 -> [one round] -> T030
```

### Coverage (iteration 002)

- **US8:** T016 to T024 in iteration 002; T025 to T030 in iteration 003.
- **FR-027:** T017. **FR-028:** T016. **FR-029:** T018. **FR-030:** T019. **FR-031:** T020. **FR-032:** T021.
  **FR-033:** T022. **FR-034:** T023. **SC-010:** T017, T024. **SC-011:** T016, T024, T025 to T027, T030.
  **FR-028** also T025 to T028; **FR-027** also T028; **FR-032** also T029.
- FR-022 and FR-023 moved to beta5 (iteration 002 DRIFT-001).
