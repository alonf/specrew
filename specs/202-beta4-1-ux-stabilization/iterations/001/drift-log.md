# Drift Log: Iteration 001

**Schema**: v2

<!--
  Markdown authoring note (Specrew lifecycle convention):

  When you add new drift events to this file, watch for MD032 (blanks-around-lists).
  A sentence ending with a colon, immediately followed by a bullet list, is the most
  common violation. Always put a BLANK LINE between the colon line and the list:

      BAD:                              GOOD:
      Resolution steps:                 Resolution steps:
      - Step one                        <— blank line here
      - Step two                        - Step one
                                        - Step two

  The F-033 pre-boundary markdownlint gate runs markdownlint-cli --fix on .md
  changes before every boundary-sync write, so most violations auto-fix — but the
  blank line you write in the first place avoids the cleanup churn.
-->

## Summary

**Total drift events**: 26
**Resolution rate**: 100% (26/26 resolved)
**Specification drift**: 1 (spec-updated at design-analysis)

## Events

### DRIFT-001 — FR-018 used the branch as a reconciliation source; the branch is not the feature (resolved)

- **Observed**: 2026-10-13, design-analysis co-design (DA-5). As approved at specify, FR-018 said a stale pointer is reconciled "from the branch and the in-flight work". The maintainer corrected this: this worktree ran feature 199 on branch `201-first-run-experience`, so the branch name is evidence of nothing.
- **Requirement**: FR-018, and US4 scenario 2 (spec.md).
- **Resolution**: spec-updated, by human decision at design-analysis. The precedence is now (1) the in-flight controller or pending crossing, (2) the pointer if written for the current branch, (3) the branch name as a hint only, always disclosing which source decided. US4 scenario 2 was updated to match. The data-storage lens binding `pointer-branch-guard: stale-on-branch-mismatch-reconcile-disclose` still holds.
- **Class closure**: NONE — This is a requirement correction, not a code defect; the resolver test for SC-006 pins the precedence order, including the 199-on-201 case.

### DRIFT-002 — the design-analysis gate disclosed its required format one layer per refusal (observation)

- **Observed**: 2026-10-13, plan sync for iteration 001. Three consecutive refusals each named a different layer of the required design-analysis format. The first named missing Alternatives, Crew Recommendation, Human Decision fields and a detectable flow. The second named the Simplest, Reasonable and By-the-book labels. The third named per-option fields (Architectural pattern, Quality features considered, Effort estimate, Reversibility cost, a Mermaid diagram). Each refusal was accurate, but none listed the complete contract, so the agent spent three repair cycles. No human turn was consumed.
- **Requirement**: adjacent to FR-020 (B4F-102: a refusal names the producing step). The producing step exists (`New-SpecrewDesignAnalysisArtifact`, design-analysis-gate.ps1 ~950), and its scaffold would have carried the full format. The refusal never named it.
- **Resolution**: the content was restructured to the format with no change to any agreed decision. T013 (FR-020) is extended in scope to cover this case: the plan-gate refusal names the scaffold step and reports every missing field in one pass.
- **Class closure**: T013's fixture asserts that a design-analysis missing several layers gets one refusal listing all of them, together with the scaffold step.

### DRIFT-003 — T005's 3-OS workflow change contradicts the workshop's devops-operations skip (resolved by human decision)

- **Observed**: 2026-10-13, at the plan verdict. The confirmed workshop agenda skipped devops-operations with the reason "No pipeline or deployment change in scope". Plan W5/T005 changes `.github/workflows/**` so that fault-injection case (e), two real processes appending at once, runs on Windows, macOS and Linux (FR-025).
- **Requirement**: FR-025 (case (e) on three operating systems), against the devops-operations skip reason in lens-applicability.json.
- **Resolution**: human-decision (maintainer, plan verdict 2026-10-13). The workflow change stays. It is kept minimal: only what runs case (e) on the existing OS matrix, with no new jobs, publication or deployment change. T005's acceptance states that the workflow diff is reviewed like code. The skip reason in the confirmed agenda is not rewritten; this entry records the exception.
- **Class closure**: NONE — This is a scope exception decided by the maintainer, not a defect. T005's acceptance pins the review requirement.

### DRIFT-004 — the tasks verdict was not captured because a context compaction landed between the packet and the reply (resolved)

- **Observed**: 2026-10-13, tasks boundary. The maintainer replied `approved for tasks - Run T001 first...` after Claude Code had compacted the context. `last_authorized_boundary` stayed `plan`. The read-only capture check returned the older `clarify -> plan` pair; the classifier reads the reply as `approve` for `tasks`.
- **Requirement**: FR-026 neighbourhood (per-feature capture state), and the governing principle "verdicts stay explicit typed replies".
- **Resolution**: resolved by re-presenting the same `plan -> tasks` crossing after the compaction. The Stop hook required a boundary packet with the crossing's marker. The maintainer typed the verdict again after that packet (`approved for tasks - Codex: a...`), and the hook captured it (`verdict_history`, tasks entry, `auth_commit_hash` 9973f2c3, `hook-captured-from-transcript`). The out-of-band writer was not used, and no authorization was written by the agent. The earlier reply's instructions (T001 early, measurement only) have no ledger record of their own; they are ratified in the maintainer's before-implement verdict text (see DRIFT-005). Recorded as B4F-112 (beta5 candidate).
- **Class closure**: NONE — not in 202. The capture-pairing fix stays beta5 (B4F-112, maintainer ruling at before-implement). The recovery path that resolved this case, re-presenting a pending crossing whose verdict was not captured, is protected in T006's acceptance (DRIFT-008).

### DRIFT-005 — T001 ran before the before-implement verdict, and measured new host facts (resolved by human decision)

- **Observed**: 2026-10-13. tasks.md places T001 after the before-implement verdict. The maintainer's tasks verdict moved it ahead, as measurement only, in scratch directories with no product code. Results are in research.md, "T001 measurements".
- **Requirement**: FR-024; DA-3; DA-4.
- **Resolution**: human-decision. For Claude and Copilot, DA-3 and DA-4 both hold, so the plan needs no amendment for them. Three facts refine task acceptance without changing scope:
  - Copilot fires the prompt hook before SessionStart (T008 keys "first prompt" on the prompt event).
  - Copilot dismissals produce no hook event and use the strings "User cancelled the request." and "User responded: <default>", not "User skipped question" (T002 registry fixture; B4F-113).
  - Hook stdin arrives as UTF-8 while the hook process's console input encoding is `ibm437` (T002 and T014 decode bytes explicitly).
  - **Codex** needed persisted hook trust. The maintainer chose option a at the tasks verdict. The three trusted hooks were confirmed to be the scratch capture hooks and nothing else. The trust entry was recorded in research.md and then removed, and the scratch folder was deleted. DA-3 and DA-4 hold for Codex too. **No validated host fails DA-3 or DA-4, so the plan is not amended.**
- **Ratification (maintainer, before-implement verdict text, 2026-10-13)**: the first tasks-stage reply ("Run T001 first, before the before-implement stop; measurement only; scratch directories outside any governed worktree; no product code; nothing in the governed tree beyond committing its findings as evidence") was lost to the compaction (B4F-112). The ledger's tasks entry holds only the later "Codex: a" reply. The maintainer's before-implement verdict is the record that T001 ran early by the maintainer's decision. That verdict licenses every fixture under `tests/fixtures/hook-payloads/`: 24 files, namely Claude 7, Codex 7 and Copilot 10, each count including that host's `provenance.json`. It also licenses the `.gitattributes` rule `tests/fixtures/hook-payloads/** -text`. The verdict text said "21"; the committed count is 24 (`git ls-files`).
- **Open capture gap**: every fixture is a typed-turn SessionStart, prompt or Stop event. No host-injected or replayed user-turn payload was captured on any host. T002's opening step attempts that capture (maintainer instruction at before-implement), and DRIFT-009 records the outcome.
- **Class closure**: the T001 fixtures under `tests/fixtures/hook-payloads/` pin these facts for T002's contract test.

### DRIFT-006 — the readiness verdict reported READY for implementation before any before-implement verdict (resolved in T011)

- **Observed**: 2026-10-13, before-implement preparation. `readiness-verdict.ps1` printed "Overall verdict: READY for implementation - 'before-implement' is authorized (this iteration's cycle is authorized through 'feature-closeout')". The ledger's `last_authorized_boundary` is `tasks`, and `verdict_history` holds no `approved for before-implement` for 202. The check reads feature 199's completed cycle as 202's.
- **Requirement**: FR-026 (all per-feature runtime state keyed to the new feature on a new-feature reset; B4F-109 widened at clarify). A false READY first line is the B4F-071 hazard: a crew can announce implementation on it.
- **Resolution**: not acted on. Implementation waits for the human verdict regardless. T011's scope already covers it ("all per-feature runtime state keyed to the new feature"). Its acceptance gains one check: the readiness verdict for a new feature never reports a prior feature's cycle as authorization.
- **Class closure**: T011's `new-feature-reset` test asserts that the readiness verdict for 202, before its before-implement verdict, is not READY.
- **Resolved 2026-10-14 (T011)**: the cause was that only an iteration-closeout ended a readiness cycle. A feature-closeout entry stayed in the next feature's cycle and, sorting after every boundary, read as authorization through feature-closeout. A feature-closeout now ends a cycle too. Case 6 of `new-feature-reset` reproduces the original line on the pre-T011 tree ("READY … authorized through 'feature-closeout'") and gets BLOCKED now. The fix is in `readiness-verdict.ps1`, outside T011's listed files (DRIFT-021).

### DRIFT-007 — the validator counts the T001 evidence fixtures as unauthorized product source (resolved by human decision)

- **Observed**: 2026-10-13. `validate-governance.ps1` FAIL `source-without-implement-authorization` named the seven Codex fixtures under `tests/fixtures/hook-payloads/codex/`, committed after the tasks authorization was recorded.
- **Coverage gap (maintainer review at before-implement)**: the check flagged only those seven files. The 14 Claude and Copilot fixtures and the `.gitattributes` change were committed in `78366194` and `9973f2c3`. The tasks authorization was recorded at `9973f2c3`, so those files fall in the `plan -> tasks` window, which `source-without-implement-authorization` does not examine. Source written before the tasks authorization passes unflagged. This is a validator coverage gap, recorded as B4F-114 (beta5 candidate); it is not 202 scope.
- **Requirement**: the maintainer's tasks-stage instruction authorized committing T001's findings as evidence, with no product code. Fixtures are recorded host payloads, not code.
- **Resolution**: human-decision. No revert. The maintainer's before-implement verdict licenses all 24 fixture files and the `.gitattributes` rule (DRIFT-005 ratification).
- **Class closure**: NONE — not in 202. Two questions are left to B4F-114: whether the check should cover the whole span since the last implement authorization, and whether recorded-evidence fixtures should be exempt.

### DRIFT-008 — T006 (presented-crossing memory) must not remove the B4F-112 recovery path (resolved by human decision)

- **Observed**: 2026-10-13, maintainer review at before-implement. DRIFT-004 was resolved by re-presenting the same pending crossing in the same session after a compaction. As planned, T006 suppresses repainting per (session, crossing id). A compaction keeps the session id, so after T006 a verdict lost the same way would leave no packet to answer.
- **Requirement**: FR-011 (presented-crossing memory) against the governing principle that "verdicts stay explicit typed replies".
- **Resolution**: human-decision. T006's acceptance gains a RED fixture: a crossing that is still pending and whose verdict was not captured, for example after a compaction, can be presented again in the same session. Only a crossing that was presented, is unchanged and had no capture miss is suppressed. The capture-pairing fix stays beta5 (B4F-112), because iteration 001 is already at 25.5 SP. No SP change.
- **Class closure**: the T006 RED fixture `crossing-presentation` "pending, capture missed, re-presentable" pins the recovery path.

### DRIFT-009 — host-injected capture: two classes have no recorded payload and use synthetic fixtures (resolved by human decision)

- **Observed**: 2026-10-13, T002 opening step (maintainer item 3), run in scratch folders only.
  - **Recorded:** host-injected prompt payloads on **Claude** (a background-task `<task-notification>` arriving as UserPromptSubmit) and on **Copilot** (a Stop-block reason replayed as `userPromptSubmitted`).
  - **Codex 0.162.1:** produced none. Its Stop block continues the same `turn_id`.
  - **Copilot 1.0.96:** never emits the "User skipped question" string to a hook (B4F-113).
- **Requirement**: FR-006 and B4F-108 (the three-valued origin rule: typed-user, host-injected, unknown); the hardening gate's test-integrity row.
- **Resolution**: human-decision (maintainer item 3). Two synthetic fixtures, each marked in its file name and its provenance:
  - **Codex, host-injected prompt:** `codex/synthetic-userpromptsubmit-host-injected.json`.
  - **Copilot, skipped question:** `copilot/synthetic-userpromptsubmitted-skipped-question.json`.

  research.md and the hardening gate are updated to match.
- **Class closure**: T002's contract test names synthetic fixtures as synthetic and never counts them as recorded-host evidence. The provenance `origin` field carries this, and the test asserts it.

### DRIFT-010 — T002 reached two files outside its owned set, and corrected one research note (resolved)

- **Observed**: 2026-10-13, T002 implementation.
  - **Launcher stdin.** The generated per-machine hook launcher, written by `deploy-refocus-hooks.ps1` (both twins), read hook stdin with `[Console]::In`, exactly like the dispatcher. Under a host's hidden console that decodes UTF-8 as `ibm437`. The RED reproduced it: a Hebrew prompt reached the provider as mojibake on Claude (dispatcher path) and on Copilot (launcher path). The same deployer also has to bake the declared input contract into `-HostBinding`, or deployed projects would never see it (the same trap as StopBlockShape, 145 F1).
  - **Codex origin note.** research.md's host-injected section said a Codex prompt matching no rule is `unknown`. Under FR-006 that would refuse every typed Codex reply.
- **Requirement**: FR-006, FR-021 (UTF-8 intake, B4F-065 class), FR-024; T002's owned-file list.
- **Resolution**:
  - T002 also owns both `deploy-refocus-hooks.ps1` twins (launcher stdin decode, and binding bake of `InputFieldMap`, `OriginRules`, `InputTransform`) and the bootstrap rewiring files (`SessionBootstrapManager.ps1`, both `specrew-bootstrap-provider.ps1` twins, and the seven bootstrap tests that used the removed normalizer). The rewiring was already in T002's work text; only the owned-file list missed it.
  - research.md is corrected in place, with the correction marked.
- **Class closure**: `turn-record-contract.tests.ps1` runs every case through the deployed command under a hidden console, the way hosts spawn hooks, so a `[Console]::In` read anywhere on the path turns the Hebrew cases red. `twin-copy-parity.tests.ps1` fails on any twin drift.

### DRIFT-011 — the pre-review verification plan still validated feature 199, and the first 202 round could not start (resolved)

- **Observed**: 2026-10-13, at the T002 and T003 co-review checkpoint (round approved by the maintainer; no round spent). Three refusals came in sequence, none of them from the reviewer:
  - **Runtime drift**: the self-host `.specify` copies had been refreshed by hand for T002 and T003. The maintainer approved `specrew update --specrew` from the repo; it ran and is committed (`18115d0c`).
  - **Round approval misread**: the capture read only the latest turn and attributed the phrase to a picker (B4F-117). The maintainer re-sent the phrase.
  - **The frozen-tree verification failed**, on two counts:
    - `f199-class-guards`: `every-suite-is-named-by-a-lane` was red, because T002's and T003's three new suites ran in no lane.
    - `iteration-003-governance`: it validated feature 199's closed stub iteration 003, which fails on records the stub never had. It also failed on a review check that now reads 202's freshly created campaign as the active one, which is B4F-109's per-feature-state class (T011).
- **Requirement**: the plan's own label for the governance command: "the ACTIVE iteration" (re-pointed twice under 199, DRIFT-199-I003-007).
- **Resolution**:
  - The governance command is re-pointed to `specs/202-beta4-1-ux-stabilization/iterations/001`.
  - A `f202-slice-suites` lane names the three new suites.
  - Four of this log's `NONE` class-closure lines lacked the `NONE — <why>` form the validator requires, and are fixed.
  - Iteration 001 validates PASS. No check was removed or loosened.
- **Class closure**: NONE — the durable fix (a governance command that names the active iteration, not a number) is the open beta4 item the plan's label records; it stays beta5. `every-suite-is-named-by-a-lane` already catches the unregistered-suite half.
- **Addendum (same night)**:
  - **A self-inflicted held slot.** One relaunch was stopped by the crew mid-verification to widen the window. Verification alone takes about 520 s locally, against a 900 s default round. That left the approved round's slot reserved with no release, and the next launch refused with `allowance-exhausted`. `specrew review --reconcile-run` released it (`non-invoked-reservation-reconciled`), and the reviewer was never invoked. Rule for the crew: never stop a launched round; pass `--timeout-seconds` up front.
  - **The frozen copy still fails.** The next launch, with a 2400 s window, failed `f199-class-guards` inside the frozen copy, although the same lane passes in the working tree. The cause is being reproduced in a clean checkout with the plan's restricted environment.

### DRIFT-012 — T004 reached two files outside its owned set for the health line and the orientation (resolved)

- **Observed**: 2026-10-14, T004 implementation. FR-007 puts the degraded state in `specrew status`/`where` and in session-start orientation. The one health check both can load is `shared-governance.ps1`: `where` already loads it, and so does the bootstrap provider. The orientation line is added by the bootstrap provider twins.
- **Requirement**: FR-007; T004's owned-file list (`where`, `dashboard-renderer`).
- **Resolution**: `Get-SpecrewReplyRecordingHealthLine` lives in `shared-governance.ps1`. `specrew-where.ps1` shows it first while degraded (`status` is the same command). The bootstrap provider passes it into the orientation directive. `dashboard-renderer.ps1` needed no change.
- **Class closure**: `receipt-disclosure.tests.ps1` case 7 asserts the line appears only while degraded, carries no internal noun, and is wired into both `where` and the orientation.

### DRIFT-013 — the class-guard lane ran twice its own timeout, so the frozen-copy verification killed a passing lane (resolved by human decision)

- **Observed**: 2026-10-14, at the first co-review checkpoint. Three launches failed the pre-review verification on `f199-class-guards` (one also on `f199-slice-suites`), reported only as the sealed reason `diagnostics-require-command-scoped-disclosure`. The crew checked pass/fail in four conditions and could not reproduce a failure. It never checked duration. The maintainer measured the lane in the working tree, exactly as the plan defines it: **exit 0 in 243 s, against `timeout_seconds` 120**. Its label still said "roughly 20 s combined", but the lane had grown to 31 sequential child `pwsh` processes plus 4 Pester files. The one `f199-slice-suites` failure (480 s bound, 199 s measured under 199) is the same class under load (DRIFT-199-I001-116). DRIFT-199-I001-112 was very likely this too.
- **Requirement**: the plan's own per-command `timeout_seconds`; the project's 2.4x measured-headroom convention (DRIFT-199-I001-116).
- **Resolution** (maintainer ruling 2026-10-14):
  - **The lane is parallelized** the way DRIFT-199-I001-116 did the slice lane: `ForEach-Object -Parallel`, throttle 6, with the result count pinned to 31 so a swallowed suite cannot read as a pass. Measured cold, in a fresh checkout with only the plan's `env_refs`: **exit 0 in 109.4 s**. Its timeout is now 270 s (2.47x), and the stale "20 s" label is corrected.
  - **Checkpoint rounds run only 202's lanes (option a).** `iteration-001-governance-202` measured 16.9 s against 180 s, and `f202-slice-suites` 64.7 s against 600 s. Both f199 lanes are parked in `.specrew/verification-plan.signoff-lanes.json` and return to the plan for the signoff round (T015 carries the step). `every-suite-is-named-by-a-lane` reads the parked file, so their suites stay named meanwhile and it stays green.
  - **The reporting gap** is recorded as beta5 finding B4F-118. The engine computes a derived diagnosis outside the seal (command, exit code, duration, `timed_out`), but it never reaches `result.json` or `report.md`.
- **Class closure**: NONE — the class is "a timeout reported as an opaque sealed failure", and its closure is the engine change B4F-118 records for beta5. This entry fixes the instance and restores headroom; nothing yet re-measures a lane against its timeout as suites are added.

### DRIFT-014 — co-review round 1 found eight defects in T002 to T004; all are fixed, one by the planned Unix lock (resolved)

- **Observed**: 2026-10-14, co-review round 1 (`run-20261013-234651770-ac649a7e`, codex, on `c26b1d42`). The round returned 8 findings. The engine demoted all 8 to minor for stating no concrete failure scenario. The crew checked each one against the code and the spec, and every one is a real defect:
  1. **Origin passed but not enforced.** `--turn-origin` reached the handover provider and stopped there. A Copilot dismissed-question prompt classified host-injected still produced a receipt. The old store's text check accepts "User skipped question" (verified).
  2. **Buffer flush could delete unread data.** The flush swallowed buffer read errors and then deleted every listed file. RED: a buffer held unreadable but deletable lost its hash.
  3. **A malformed journal line threw.** The exception escaped the receipt writer's outcome handling, so the turn went silent. Because the line never goes away, it also refused every later reply.
  4. **Recovery approval read a decline as approval**, for example "okay, do not clear it".
  5. **A recovery question outlived its episode.** It survived automatic recovery, so a later unrelated "yes" could move the record.
  6. **Recovery acted before recording the approval**, and still said "your approval was recorded" when that write failed.
  7. **No disclosure in the affected turn.** A degraded state was not said in the turn the human typed into, stating whether the reply was used.
  8. **The non-Windows journal append was not atomic.** T005 case (e) on the 3-OS CI run (38487295823) measured it: Linux lost 58 of 2,000 lines and tore 1; macOS lost 32.
- **Requirement**: FR-006 ("only typed-user can produce a receipt"); FR-002 and FR-003 (no permanent latch); FR-007 (disclosed in the affected turn, stating whether the reply was consumed); FR-009 (the recovery action records the approving reply's receipt); FR-001 with T003's conditional per-write lock.
- **Resolution**:
  1. The handover provider reads `--turn-origin`. `Write-SpecrewWorkshopAuthorityReceipt` refuses any origin other than typed-user, with the new cause `not-typed-by-human`, disclosed in the turn. A direct caller with no turn record keeps the text checks.
  2. The flush renames each buffer file out of its writer's way, reads it, and journals it. It removes the file only if the file was read and has not grown since.
  3. A malformed line is skipped and counted; it can authenticate nothing, and the decision rests on the readable records.
  4. Recovery approval rejects any reply that also declines or holds off.
  5. A stale question, from a recovered or earlier episode, is closed instead of being answered.
  6. The approval is recorded first. If it cannot be, nothing changes and the turn says so.
  7. While degraded, the prompt turn says whether the reply was used.
  8. Linux and macOS take the per-write lock T003 planned for this case: a sidecar lock held for one write. Windows is unchanged.
- **Tests**: `receipt-disclosure` cases 9 to 14, `hook-output-journal` case (h), and `cross-host-workshop` host-injected prompts through the deployed hook. Case (h) and the case 9 premise were confirmed RED on the previous code.
- **Class closure**: the cases above are permanent members of `f202-slice-suites`. The 3-OS step makes case (e) a standing check on every run of the matrix job.

### DRIFT-015 — co-review round 2 found five more defects in the round-1 fixes; all are fixed (resolved)

- **Observed**: 2026-10-14, co-review round 2 (`run-20261014-102731596-597f9ec9`, codex, 43 paths examined, the T005 workflow diff among them). The round returned 5 findings and the engine demoted all 5 to minor. It ran while T006 was being written, so it reports the snapshot as moved; the findings concern the round-1 code, which had not changed. The crew checked each one against the code, and every one is a real defect:
  1. **The dispatcher still latched on a malformed line.** Round 1 made the store's reader skip one, but the dispatcher's origin check read the same journal and returned "unavailable" on it. Every later typed prompt then got origin `unknown`, and the receipt writer refused it. `receipt-disclosure` case 10 passed only because it supplied the origin itself.
  2. **A flush could remove a buffer a Unix writer still held open.** A rename does not detach a handle opened before it, so a hash written after the flush removed the file was lost while the output was still shown.
  3. **Recovery was recorded while a kept buffer stayed unreadable.** That closed the degraded episode, hid the degraded disclosure and closed the recovery question, while prompts were still being refused.
  4. **Another session's "yes" could approve the recovery.** The request was project-wide, so a session that was never asked could have its answer consumed as the approval.
  5. **An unreadable record check was disclosed as a host-added reply.** The dispatcher gives that case origin `unknown`, and the store told the human their typed reply "was added by the assistant's host".
- **Requirement**: FR-003 (no permanent latch); FR-004 and FR-005 (retained output identity); FR-007 and FR-009 (disclosure and the recovery decision stay true to the episode); FR-010 (the actual cause).
- **Resolution**:
  1. The dispatcher skips a malformed line, as the store does. Only a store that cannot be read is "unavailable". The dispatcher also reads a set-aside journal now, as the store already did.
  2. Each buffered record is published as its own closed file: written in full under a hidden name, then renamed into place. No visible buffer file is ever written again.
  3. The episode closes only when no buffer file is left.
  4. The recovery request records the session it was asked in, and only that session's typed yes approves it. The handover provider now passes the session id.
  5. Origin `unknown` is recorded as `record-check-unavailable` (degraded) with its own cause text.
- **Tests**: `cross-host-workshop` (a typed reply after a malformed journal line, through the deployed hook on claude and codex), `hook-output-journal` case (b) (one published file per record) and case (i) (the episode stays degraded while a buffer is unreadable), and `receipt-disclosure` cases 15 and 16. All are RED on `39af693f` and green after the fix.
- **Class closure**: the cases above join `f202-slice-suites`. The dispatcher and the store now apply the same malformed-line policy, and the new cross-host case runs it through the deployed hook.

### DRIFT-016 — T006 and T007: one file outside the owned set, and the channel for the system-filled line (resolved)

- **Observed**: 2026-10-14, T006 and T007 implementation.
  1. **T006 reached the dispatcher.** The presented record names which SessionStart preceded it, for diagnosis. Only the dispatcher sees the host's SessionStart `source`, so it now passes `--session-start-source` to the conformance provider. That is one argument, in all three dispatcher copies. Every SessionStart clears the memory whatever its kind, so behavior does not depend on the argument.
  2. **T007's system-filled dials line is supplied at turn start, not at Stop.** FR-013 says the system fills the line in and marks it as system output. T001 measured that no validated host shows hook output to the human directly (DA-3), and Claude does not show Stop-hook output at all. A line filled in at Stop would therefore never be seen. The conformance provider now supplies the finished line once, on the session's first prompt, marked `[specrew-system]`. The dispatcher records it in the hook-output journal, as it does all provider output. The agent includes it as written. Stop never demands it; a reply without it is journaled, not blocked. T008 uses the same channel for the whole orientation.
  3. **The dials reader honors `SPECREW_USER_PROFILE_PATH`**, the override `user-profile.ps1` already uses. Both now read the same profile, and the test can point at a fixture profile.
- **Requirement**: FR-011 (T006); FR-013 and DA-3 (T007).
- **Resolution**: as above. T006's owned files plus the dispatcher argument; T007 within its owned files (`turn-end-store.ps1`, the conformance provider, `declare-turn-end.ps1`).
- **Class closure**: `crossing-presentation` case 4 asserts the record names the gap it followed (`compact`). `presented-check` case 6 asserts the line is supplied once, marked, and that its absence is not blocked.

### DRIFT-017 — T008 reached the catalog and the dispatcher, and retired one suite's contract (resolved)

- **Observed**: 2026-10-14, T008 implementation.
  1. **The catalog.** The bootstrap provider ran only on SessionStart, and Copilot fires its first prompt before SessionStart (T001). Supplying the orientation on the first prompt needs the provider bound to `UserPromptSubmit` in `refocus-scopes.json`, in both copies.
  2. **The dispatcher, for cost.** Bound to every prompt, the provider's early exit measured about 0.5 s a prompt, against about 0.2 s for a bare `pwsh` start. The once-per-session stamp is therefore named by session id, as the render claims already are: `.specrew/runtime/hook-bootstrap-orientation-<session>.json`. The dispatcher skips launching the bootstrap on a prompt once that stamp exists. The first prompt pays about 0.86 s once per session; later prompts pay nothing. This is one guarded `continue`, in all three dispatcher copies.
  3. **A retired contract.** `session-orientation-rendered` pinned the Stop-time orientation demand, the shape research.md records as the failure DA-3 replaces and B4F-096 reproduced. Its assertions now pin the new contract: no Stop demands the orientation, alone or riding along on another block; the receipt still comes from the opening message; and it is per session, keyed on that session's own render claim. Its fixture claims now use the real `<session>-<source>` name, and so does the `agent-led-workshop-replay` fixture.
  4. **The finished text.** The existing host orientation block leaves placeholders for the agent (`<project-root-url>`, `<one specific action>`), so a new renderer builds the finished orientation from resolved values in the bootstrap provider.
- **Requirement**: FR-014; DA-3; T008's owned files (the bootstrap provider copies, the conformance provider, `orientation-order.tests.ps1`).
- **Resolution**: as above.
- **Class closure**: `orientation-order` case 1 asserts the catalog binding in both copies. Case 3 asserts the per-session stamp and the dispatcher's skip on it. The moved `session-orientation-rendered` asserts no Stop-time orientation demand in any shape.

### DRIFT-018 — two CI jobs and the 3-OS workflow never ran on 202; T005 reopened; review cadence set (resolved by human decision)

- **Observed**: 2026-10-14, maintainer review of the US2 checkpoint.
  1. **Lint hid two jobs.** The Specrew CI `Lint` job failed on every push to this branch, on extra blank lines in 202's intake documents. `Deterministic gate` and the `Contract` lane wait on `Lint`, so neither has run on any 202 code. The markdown step fails first, so the job's own PSScriptAnalyzer and governance steps never ran either.
  2. **The 3-OS workflow never ran on push.** `cross-platform-validation.yml` matched only `0*-*` and `1*-*` feature branches, so 202, and every feature numbered 200 or higher, never ran it on push. Its only 3-OS run here was dispatched by hand, at `34af7076`.
  3. **T005 was closed too early.** `0b62bf9b` changed the Linux and macOS outage-buffer behavior (one closed file per record) after that run, and the change has never run on Linux or macOS.
- **Requirement**: T005's acceptance (the 3-OS run); DRIFT-003's minimal workflow rule; the review budget.
- **Resolution** (maintainer decisions):
  1. The blank lines are removed from the four intake documents that carried them (five errors). `.markdownlintignore` excludes `specs/*/workshop/preserved-product-answers/`, whose record's SHA-256 is pinned in DRIFT-202-INTAKE-004, so that file stays byte-identical. After the fix, `Deterministic gate` and `Contract` must be seen to run and pass on the branch; any failure they surface is work in this iteration.
  2. `2*-*` is added to the workflow's push branches. This is within T005's workflow ownership and DRIFT-003's rule: no new job, no publication or deployment change.
  3. T005 is reopened. It closes when cross-platform validation is green on all three OSes at the current HEAD, with the case (e) step present in each leg's log.
  4. Co-review round 3 is held until T011 is committed and covers T006 to T011. Round 4, at sign-off, covers T012 to T014 and the round-3 fixes.
  5. Until B4F-055 is fixed, every finding the engine demotes in rounds 3 and 4 is checked against the code and listed in that round's checkpoint, real or not, before any sign-off. The evidence is added to B4F-055.

- **Addendum (same day)**: the first push run (38563251438, on `d3c010a4`) was green, with the case (e) step passing on all three OSes. Case (e) never degrades, so the closed-file buffer path still had not run on Linux or macOS. The same step now also runs `hook-output-journal.tests.ps1`, whose cases go through the buffer. That is one more script in an existing step, within DRIFT-003's rule.
- **What the unblocked jobs found (run 38563251443, on `d3c010a4`)**: `Lint` passed. `Deterministic gate` ran and failed on two `tests/bootstrap` suites, both T008 regressions. The crew's sweeps globbed only `tests/unit` and `tests/integration`, so they never reached that folder. `Contract` was skipped behind it.
  1. `Regression.Tests` pinned the bootstrap provider at exactly two events; T008 binds a third (`UserPromptSubmit`). It now pins three, with the reason.
  2. `DirectiveDeliveryCap` 3b found the pending-verdict SessionStart directive at 10,045 characters, over the 10,000 host cap, after T008 added its line. Item 1's long composing guidance, for text that now arrives finished, left the directive; the worst case is 9,288.
  The sweep now also covers `tests/bootstrap` and `tests/continuous-co-review`. On the rerun (run 38569172619, on `60267598`), `Lint`, `Deterministic gate` and `Contract` all passed.
- **What the buffer suite found on Linux and macOS (run 38569172660, on `60267598`)**: its first Unix run failed. Reproduced in WSL Ubuntu, all three causes were in the test harness, not the product:
  1. The holder locked the journal itself. On Unix, .NET takes an advisory `flock` only for `FileShare.None` or read-only access, so a writer opening the journal with `ReadWrite` sharing is never blocked by it. Contention between Specrew writers lives on the sidecar `<journal>.lock`, and the holder now takes that off Windows.
  2. `Start-Process` there lets the holder inherit the stub's stdout, which is the dispatcher's pipe. The dispatcher's read of the stub therefore waited for the holder to exit, and the lock was gone before the append. Off Windows, the holder's output now goes to files.
  3. The holder slept with `Start-Sleep` as the first cmdlet in a bare `pwsh`. That first call costs about 890 ms on Linux, against about 70 ms on Windows, so a "120 ms" hold lasted a second. It now uses `[Threading.Thread]::Sleep`. The dispatcher was checked for the same cost and does not have it: it has loaded the cmdlet module before any wait. Run against the unchanged dispatcher, the corrected suite passes. So the dispatcher is unchanged.
  Two platform shapes follow: hidden windows only on Windows, and an exclusive hold, not a Delete-only share, to make a buffer unreadable on Unix. The corrected suite passes 3 of 3 on Linux (WSL) and still passes on Windows.
- **Class closure**: the `2*-*` filter makes every 200-series feature run the 3-OS workflow on push. The lint exclusion names the preserved-answers folder by pattern, so it applies to any feature's preserved answers. The demoted-finding rule is written into tasks.md's execution notes. NONE for the engine's demotion itself: beta5, B4F-055.

### DRIFT-019 — T009 passed the correction reference through four callers outside its owned files (resolved)

- **Observed**: 2026-10-14, T009 implementation. FR-016 asks for one sentence on every host, with only the correction reference from the adapter. The sentence reaches the human through four surfaces. Two were 202's own (the conformance turn-start supply and the bootstrap's first-prompt orientation). Two were launch-contract paths that already used the prose sentence with a hardcoded slash command (`specrew-start.ps1`, `SessionBootstrapManager.ps1`) and the bootstrap's SessionStart directive. Leaving those with the hardcoded command would tell a Codex user to type a command Codex does not have.
- **Requirement**: FR-016, SC-005; T009's owned files (`user-profile.ps1`, `turn-end-store.ps1`, `dials-parity.tests.ps1`).
- **Resolution**: `Get-SpecrewProfileCorrectionReference` lives beside the prose renderer in `user-profile.ps1` and reads the host manifest's existing `HasUserSlashCommandSurface`. No manifest gains a key. Each caller passes its host. The bootstrap and conformance providers were already in 202's set; `specrew-start.ps1` and `SessionBootstrapManager.ps1` each gain one argument.
- **Class closure**: `dials-parity` asserts byte-identical text apart from the reference across the three validated hosts, through both delivery surfaces, and that the numeric renderer is gone.

### DRIFT-020 — T010 changed what every existing feature reader answers, and reached the orientation (resolved)

- **Observed**: 2026-10-14, T010 implementation.
  1. **One answer, so existing callers change.** `Resolve-SpecrewActiveFeatureRef` read `session_state.feature_ref` first, even for an inactive or closed session. Its pointer fallback read a `.feature` key that no writer ever writes. It now returns `Resolve-SpecrewActiveFeature`'s answer, so the review-signoff evidence gate and the other callers choose what status and orientation choose. With two features in flight it returns empty, rather than guessing.
  2. **"In flight" needed one more condition.** On this repository, 201's controller still reads as an open workshop, because a lens was never marked moved on, although 201 shipped. A workshop is the step before the spec, so it counts as in flight only while the spec is still the scaffold's unauthored stub. Without that condition this repository resolved as two features in flight.
  3. **The dashboard's lowest-numbered fallback is gone.** When nothing resolves, nothing is shown as active, and the "Chosen" line says why. That fallback is how B4F-105 showed 001 (Shipped).
  4. **The orientation asks the resolver too**, a change in the bootstrap provider (T008's file and T012's). The acceptance requires status and orientation to agree, and they now share the "Chosen" line.
  5. **The pointer is Spec Kit's file too.** `/speckit.specify` writes it with no branch. The one writer (`Set-SpecrewActiveFeaturePointer`) keeps keys it does not own, and the resolver ranks a pointer with no branch below the branch hint.
- **Requirement**: FR-017, FR-018, DA-5; T010's owned files.
- **Resolution**: as above.
- **Class closure**: `feature-resolver` asserts the three surfaces agree in each constructed state and pins both writers to the one pointer writer.

### DRIFT-021 — T011's reset reached the readiness verdict, and the coverage line now asks the resolver (resolved)

- **Observed**: 2026-10-14, T011 implementation.
  1. **DRIFT-006 lived in `readiness-verdict.ps1`**, outside T011's listed files. T011's acceptance names it, through DRIFT-006, so the one-line fix (a feature-closeout ends a readiness cycle) landed with T011.
  2. **The coverage line's feature is the resolver's** (T010). Campaigns are named `cmp-<feature>-iNNN`, and only the resolved feature's are read. When no feature resolves, every campaign is read, as before.
  3. **A legacy closeout entry does not name its feature**, and none is inferred from other state. The rule counts an unnamed closed feature as different. A closed feature does not specify again, and a re-sync of a feature the ledger does name stays a non-reset.
  4. **The authorization writer reads the pending crossing's feature** (else the active session's) before its order check, so the feature recorded on the entry and the feature the rule compared are the same value.
- **Requirement**: FR-026; T011's owned files (`shared-governance.ps1`, `sync-boundary-state.ps1`, `new-feature-reset.tests.ps1`).
- **Resolution**: as above. `sync-boundary-state.ps1` needed no change: its mint goes through `New-SpecrewPendingCrossingScope`, which now passes both features to the rule.
- **Class closure**: `new-feature-reset` runs the real sync and the real capture, checks append-only by byte comparison, and asserts the readiness line.

### DRIFT-022 — a sweep suite committed T011's work under a bootstrap identity, and it was pushed (resolved; history kept)

- **Observed**: 2026-10-14, during the T011 regression sweep, run with T011's changes uncommitted. At 17:33:15, `f46c9fb1` "chore(specrew): bootstrap scaffold" (author "Specrew Bootstrap") committed the eight uncommitted T011 files, and nothing else. The crew's own T011 commit, `e0d8c33e`, then carried only the lane label, and both were pushed together.
- **Where T011 is**: `f46c9fb1` holds T011's code, test and records; `e0d8c33e`'s message describes them. The content is exactly what the sweep ran against.
- **Mechanism**: B4F-120. The greenfield bootstrap baseline commits in whatever repository encloses the project path, and a fixture under this repository's `.scratch/` is enclosed by it. The triggering suite was not identified.
- **Resolution**: history is not rewritten. A force push would rewrite a pushed branch, and the content is right. From now on, the crew runs sweeps only on a fully committed tree, so a stray commit can hold nothing that is not already committed.
- **Class closure**: NONE — the product guard and the fixture locations are beta5 (B4F-120); in 202 the only mitigation is the sweep rule above. *Superseded 2026-10-15: the maintainer pulled B4F-120 into 202, and DRIFT-027 closes the class.*
- **Update, 2026-10-14 (after co-review round 3, on the maintainer's instruction)**: the product defect is reproduced in a scratch directory: an enclosing repository with no commits is committed in full, unrelated work included (B4F-120). The probable trigger is the two `start-command` suites sharing `.scratch/start-command`. That collision also explains `start-command` failing only inside the sweep: in a throwaway clone it failed 2 of 2 when run together with the first-run suite and passed alone. Whether the fix moves into 202 is the maintainer's decision, pending.

### DRIFT-023 — the Unix journal lock starved a writer under contention, an FR-001 failure (resolved)

- **Observed**: 2026-10-14. Case (e) degraded once on the Linux CI leg (38573833479) and once on the macOS CI leg (38583777333). The printed record shows each time a writer that waited out the sidecar `<journal>.lock`. Nothing was lost: the flush re-journaled the buffered hashes as one or three duplicate lines. But FR-001 says concurrent appends succeed, and a degraded episode is a failure. Five 2-writer runs in WSL Ubuntu could not reproduce it; four writers reproduced it in 2 of 3 runs.
- **Cause**: the per-write lock is an advisory flock, and it is unfair. Its wait was 200 ms, inside FR-002's 250 ms retry window, polled every 2 ms. A waiter loses the short gaps between another writer's back-to-back appends. A wait for a turn is not a failed append, but it was budgeted as one.
- **Requirement**: FR-001; FR-002 (the retry window governs appends that fail).
- **Resolution**: the lock wait has its own bound, 1000 ms, polled every millisecond. The retry window is unchanged. Case (e) now runs four writers, so it reproduces the starvation instead of meeting it now and then. With the fix, four writers passed 6 of 6 in WSL Ubuntu, and the buffer suite passes on Linux and Windows. The 3-OS CI run on the next push is the acceptance.
- **Class closure**: case (e) with four writers, on Windows, Linux and macOS in every push run, plus the printed degraded record when it degrades.
- **Deviation, awaiting the maintainer's decision (recorded 2026-10-14 on the maintainer's instruction)**: the design-analysis tuning the maintainer agreed is at most 5 retry attempts within 250 ms (research.md; plan.md, Performance Goals). The retry window is unchanged, but one attempt's wait for the Unix lock can now run to 1000 ms, polled every 1 ms, which is outside it.
  - **Sample**: 50 four-writer runs per variant in WSL Ubuntu, 4,000 appends a run, through the shipped writer with only the lock function instrumented:

    | Variant | Degraded runs | Lock timeouts | Longest wait |
    | --- | --- | --- | --- |
    | 1000 ms, 1 ms poll (today) | 0 of 50 | 0 | 299.6 ms |
    | 200 ms, 1 ms poll (inside the agreed window) | 10 of 50 | 18 | budget reached |
    | 200 ms, `Start-Sleep` 2 ms (the original) | 27 of 50 | 59 | budget reached |

    The unfairness is real: the agreed budget with the fast poll still degrades one run in five. A cold `Start-Sleep` (706 to 847 ms on its first call in a fresh pwsh) makes it worse, but it is not the whole cause. Across 200,000 contended acquisitions the longest wait was 299.6 ms, and 10 waits exceeded 200 ms.
  - **Worst-case added hook latency**: one hook fire records two outputs (payload and envelope). On the worst path, every lock wait runs to its full bound: the payload's append, its degraded health record, the envelope's append, and, since round 3's finding 4, the disclosed payload and envelope. That is 5 waits, up to about 5 s at 1000 ms against about 1 s at 200 ms. Without contention a wait costs nothing, and none of the 200,000 measured waits came near the bound.
  - **CPU of the 1 ms poll**: a waiter that polls a held lock for the full bound uses 228 ms of CPU over 1000 ms, about 23% of one core, across about 800 failed opens. Under the four-writer stress, CPU per run was the same for all three variants (about 19.5 s, mostly pwsh itself), even though the original variant polls half as often.
  - **Fairer mechanisms**: not considered when the change was made; weighed now.
    1. **A blocking flock**, queued in the kernel through P/Invoke: no polling. But the call has no timeout, so it needs a watchdog thread and a per-OS libc binding, and an abandoned call can still take the lock after its caller gave up.
    2. **A ticket file**: first come, first served. But a killed hook leaves its ticket and stalls every later writer until a stale-ticket timeout, which is a new latch in the path FR-003 just made latch-free.
    3. **A queue through the outage buffer**: a writer that cannot get the lock within a short wait publishes its record as a closed buffer file (the round-2 path), and the next writer that gets the lock flushes it. No writer waits for a turn, latency stays inside the agreed window, and nothing is lost. Today, though, a buffered record opens a degraded episode with a human-facing disclosure. Contention is not degradation, so this needs a separate "contended" outcome that opens no episode, and the flush runs often instead of rarely. Estimated at 0.5 to 1 SP plus a 3-OS run.
  - **Why the longer wait was taken**: it was the smallest change that made FR-001 hold, it measures 0 of 50 against 10 of 50 at the agreed bound, and it is 3-OS green. The buffer queue is the better design: it keeps the agreed window, and nothing waits for a turn.
- **Ruling, 2026-10-15 — accepted deviation from the agreed 250 ms tuning (maintainer: "Lock a, amended")**: keep 1000 ms, but as one deadline across all attempts, not 1000 ms per wait. When it passes, the record goes to the outage buffer as before. The buffer queue (option b) is the maintainer's preferred design, but "not as a new store state built before the last review round". It is recorded for beta5 as B4F-123.
  - **As built** (`46d18d82`): one hook fire makes up to five appends, so a deadline per append would still allow about 5 s. To deliver the ruling's bound, the budget is **one 1000 ms per hook fire**, shared by every attempt of every append. That also holds per append. Once the budget is spent, the lock is tried once without waiting, and a held lock goes straight to the buffer with no retry. The worst-case added hook latency is about 1 s, and the busy poll runs 1 s per fire at most.
  - **Test**: `journal-fault-injection` Part 0 checks the budget on every OS. Three waits on a held lock take 1,021 ms in total (Linux) and 1,029 ms (Windows); later waits in the same fire take 1 ms; and a free lock is still taken after the budget is spent. On the old code, the three waits took 3,035 ms. Case (e)'s writers now model fires: a payload and an envelope share one budget, 500 fires per writer, still 4,000 appends a run.
  - **Re-measured: 50 four-writer runs in WSL Ubuntu**, through the shipped lock with only a timing wrapper (`lockbench-fire.ps1`), 100,000 fires in all:

    | Variant | Degraded runs | Lines | Lock timeouts | Longest single wait | Longest fire total | Fires over 250 ms | Fires over 500 ms |
    | --- | --- | --- | --- | --- | --- | --- | --- |
    | 1000 ms budget per fire (as built) | **0 of 50** | 4,000 of 4,000 in all 50 | 0 | 770.2 ms | 774.6 ms | 24 | 6 |

    All six fires over 500 ms are in one run (run 22), which overlapped with Windows-side test runs on the same machine. Without that run, the longest fire total was 344.9 ms. No fire came near the budget, and none degraded. CPU per run averaged 19.5 s across the four writers, the same as all three earlier variants, so the shared budget did not change the poll's cost under contention.

### DRIFT-024 — co-review round 3 found four more defects; the engine demoted all four, and all four are real (resolved)

- **Observed**: 2026-10-14, co-review round 3 (`run-20261014-173122349-f5d4f978`, codex), covering T006 to T011, round 2's fixes and the CI changes. The round returned 4 findings, each reported major and demoted to minor for lacking the failure-scenario clause. Under the maintainer's interim rule (B4F-055), each was checked against the code before anything else, and each is a real defect:
  1. **A question quoting the approval phrase read as a missed approval** (`turn-end-store.ps1`, T006). Any typed reply containing the phrase marked the presented crossing as answered. A question ("What does 'approved for before-implement' mean?") or a refusal left the crossing pending, and Stop then repainted the packet and told the agent to say the approval had not registered.
  2. **Markdown review links passed one check and missed two** (`turn-end-store.ps1`, T006/T007). The packet validator accepted `[spec](C:\...)`, `[spec](/C:/...)` and `[spec](/...)`, but the meaning lines and the reviewed-artifact memory read only `file:///` URLs. Such a link could be dropped from the reply unnoticed, and a change to its file never lifted suppression.
  3. **A journal line that is valid JSON but not a record threw** (`workshop-authority-store.ps1`, round-1 fix). The parse guard caught bad JSON only; `{}` threw under StrictMode at the field read, the provider failed, and the line stays in the append-only journal, so every later workshop reply failed. The same class was in two siblings: the dispatcher's last-health reader, where a `{}` health line made every later append withhold its output, and the receipt-outcome reader.
  4. **A degraded episode that began at the dispatcher's final append went undisclosed** (`specrew-hook-dispatcher.ps1`, T003/T004). The providers compose their disclosure before that append, so the payload went out unchanged and only stderr knew. When buffering failed too, the whole payload was withheld and the turn said nothing.
- **Requirement**: FR-011 (a question is answered, not repainted); FR-015 (review links are substance); FR-003 (no permanent latch); FR-005 and FR-007, SC-002 (disclosure in the affected turn).
- **Resolution**:
  1. An approval attempt must lead its line, as the verdict recognizer anchors it, and its clause must not be a question. The DRIFT-008 shape, the phrase on its own line after a pasted block, still counts (`e206d1b7`).
  2. `Get-SpecrewReviewTargetLinks` is the one reader for all three. The accepted formats are unchanged, so no packet that passed before is refused now (`d0d41902`).
  3. Each reader checks a record's shape before its fields, and a non-record is skipped and counted (`1dd20060`).
  4. The dispatcher notes when its own append degraded and adds the store's disclosure, with whether the reply was used (from the receipt outcome journaled during that fire). It then records the output as delivered. A withheld turn shows one `Specrew:` sentence, which is never accepted as a typed reply (`fdf9972f`).
- **Tests**: `crossing-presentation` cases 5 and 7, `presented-check` case 7, `receipt-disclosure` case 10b, and `hook-output-journal`'s "damaged health line" and "final-append" cases. Each was RED on the code before its fix.
- **Class closure**: all four suites are in `f202-slice-suites`. One shared link reader replaces the three regexes that drifted apart. The shape-first rule covers every reader of the three latch-free journals: hook-output authority, hook-output health and receipt outcomes. Two readers keep throwing on a non-record by design, because they guard authority stores that fail closed on any damage: the workshop receipt reader, which already wraps the throw in its named "store invalid" refusal, and the repair-authorization reader. Neither is the FR-003 class.

### DRIFT-025 — T012 reached one suite outside its owned set, and the SessionStart headroom narrowed (resolved)

- **Observed**: 2026-10-14, T012. Two things outside T012's owned files:
  1. **`DirectiveDeliveryCap`** pinned the old handover header ("Validated handover captured"), which T012 replaces on purpose with "Context from the previous session, recorded N ago". Its pending-decision worst case also had to carry the new WHERE WE ARE lines to stay an honest worst case.
  2. **`contract-parity-side-by-side`** caught a real inconsistency in T012's first version. A launch writes its contract a moment before it records the ledger, so the hook's copy said "no step is approved yet" while `specrew start`'s said "the last step approved is 'plan'". With nothing pending, the resume now states the boundary the session is at, and the caller passes in its own session boundary, so both generations agree byte for byte.
- **Requirement**: FR-019; FR-002 and FR-004 of feature 174 (the SessionStart payload fits the 10,000-char host cap).
- **Resolution**: the cap suite's assertion names the new header, and its worst case carries realistic full-length resume lines. The worst case now measures 9,750 of 10,000 chars, against 9,288 after T008: 248 chars of headroom are left. The two new header lines were shortened to get there.
- **Class closure**: `DirectiveDeliveryCap` 3b now includes the resume lines, so any later growth there shows up against the cap. The lasting reduction is Proposal 191 (precompute the in-flight digest to a file and point at it), which is outside 202. `resume-from-disk` joins `f202-slice-suites`.
- **Update, 2026-10-15 (found by the T014 follow-up run)**: a third pin of the old header was missed: `deployed-bootstrap-floor` Part 3 still matched "Validated handover captured by the previous session", and it was red from T012 on. It is in no lane, so only a full sweep runs it, and T012's sweep did not. It now matches the new header and passes (`dede9b3d`). No test pins the old header any more.

### DRIFT-026 — the f202 lane outgrew its headroom and is split in two (resolved)

- **Observed**: 2026-10-14, after T012, T013 and the round-3 cases. `f202-slice-suites` passed in 309.7 s against its 600 s timeout: 1.94x, under the 2.4x floor the lane was measured against (242.7 s after T011, recorded in its label as needing a raise or a split at the next suite).
- **Requirement**: the verification plan's timeouts carry real headroom, so a slower runner does not kill a passing lane (DRIFT-013's lesson).
- **Resolution**: split, not raised. A longer timeout would hide growth; two lanes keep each one well inside the same 600 s. `f202-slice-suites-a` holds the reply-path suites (crossing presentation, turn record, cross-host workshop, twin-copy parity, dials parity, the design-analysis refusal). It passed in 124.8 s (4.8x). `f202-slice-suites-b` holds the journal and resume suites (hook-output journal, case (e), receipt disclosure, presented check, orientation order, feature resolver, new-feature reset, resume from disk). It passed in 183.9 s (3.3x). Every suite of the old lane is in exactly one of the two.
- **Class closure**: each lane's label records its measured time, so the next addition is measured against its own lane. T014's suite goes into lane a.

### DRIFT-027 — B4F-120 and B4F-122 pulled into 202: init never writes outside its project folder (resolved by human decision)

- **Observed**: 2026-10-14 to 10-15. B4F-120 (DRIFT-022's stray commit) was reproduced in scratch: inside an enclosing repository with no commits, `specrew init <new-folder>` committed that repository in full. B4F-122 was found during the reproduction: Squad's own `squad init` wrote `.github/agents/squad.agent.md` at the enclosing repository's root. Both are outside Tier 1. The maintainer decided on 2026-10-15: "B4F-120 into 202", with B4F-122 folded in if the same top-level check closes it.
- **Requirement**: none of 202's FRs. This is a data-integrity defect in the first-run path, pulled in by human decision.
- **Resolution** (`8266e01c`):
  1. **No commit of an enclosing repository.** The greenfield path checks `Get-SpecrewProjectGitScope` right before staging. A folder that is not its own repository's top level gets no commit, records an offered bootstrap commit, and names the enclosing repository.
  2. **Init classifies the same way.** `Resolve-SpecrewBootstrapMode` makes an empty folder inside another repository brownfield.
  3. **Staging is project-only:** `add --all -- .` and `commit -- .`.
  4. **Squad's Git discovery is fenced** at the project's parent for the init call, and at the install root for the capability probe.
  5. **Fixtures moved:** `start-command.ps1` and `bootstrap-commit` build in per-run folders under the system temp folder.
- **Outside the owned files**: these are product init scripts, not T001 to T015 files. Two source-shape pins followed the new call shape: `bootstrap-commit`'s classification assertion and `squad-init-closed-stdin`'s Squad call-site assertions. Each still pins the same guarantee.
- **Tests**: `tests/unit/init-stays-in-project.tests.ps1` has 23 assertions: an unborn enclosing repository, an enclosing repository with commits, the project's own repository, the classification, and Squad confined for the init call and the probe. It was RED on the unborn case, and the unfenced Squad call wrote at the enclosing root. It passes on Windows and Linux, and `bootstrap-commit`, `post-bootstrap-output` and `squad-init-closed-stdin` pass. Run side by side, `start-command` and the first-run suite pass with HEAD unchanged (they failed 2 of 2 together before).
- **Class closure**: the suite joins `f202-slice-suites-a`. The closure is the before-staging scope check: whatever leaves the folder enclosed, whether a classification miss, a vanished `.git` or a direct caller, the commit is refused there. Squad's writes are confined at their only two call sites.
- **Update, 2026-10-15 (the maintainer's check)**: `GIT_CEILING_DIRECTORIES` is set only on the Squad child processes, through `ProcessStartInfo.Environment` in `Invoke-NativeCommandWithClosedInput`, and never in the session's own environment. `init-stays-in-project` now asserts that the caller's value, and the process environment, are unchanged after both the init call and the capability probe.

### DRIFT-028 — T014 reached the launch contract, the Stop instructions and the 3-OS workflow (resolved)

- **Observed**: 2026-10-15, T014. The three skills were not the only places that told an agent to write a draft file. Rule 46A of the launch contract said to "save that draft to a UTF-8 file and pass `-MessagePath`". Four Stop and conformance instructions in `specrew-conformance-provider.ps1` named `-MessagePath` too. With only the skills changed, an agent following the contract or a Stop instruction would still have chosen a draft path of its own, which is B4F-101's leak path.
- **Requirement**: FR-021 (drafts are saved where the saving script resolves; the three skills name it). The acceptance names Windows, macOS and Linux.
- **Resolution** (`b9cf8b71`, `a1096ef3`):
  1. **The draft arrives on stdin.** `declare-turn-end.ps1` reads raw bytes, decodes them as strict UTF-8, and saves them byte-exact in the session's own ignored folder.
  2. **Every instruction names stdin.** Rule 46A and the four provider lines now say the same as the three skills.
  3. **`-MessagePath` stays accepted.** A caller that has not moved over still works, and its draft is kept in the session folder too. One behavior change: a file that is not valid UTF-8 is now refused with a plain reason. Before, it was read lossily, and the human's text was silently replaced.
  4. **The suite runs on three OSes.** `turn-draft-intake` joins `f202-slice-suites-a` and the 3-OS workflow, which runs it on Windows, macOS and Linux.
- **Outside the owned files**: `scripts/internal/launch-contract.ps1`, `extensions/specrew-speckit/scripts/specrew-conformance-provider.ps1`, `.github/workflows/cross-platform-validation.yml` and `.specrew/verification-plan.json`. All four are text or wiring changes, and no logic outside the owned files changed.
- **Tests**: `turn-draft-intake` has 26 checks, and it was RED on the old code (stdin ignored, no draft, empty message). The suites that read the contract and the provider text pass.
- **Class closure**: every place that tells an agent how to hand over its draft names stdin, and the saving script decides the path on both routes.

### DRIFT-029 — the restored f199 lanes were under the headroom floor, and are split (resolved)

- **Observed**: 2026-10-15, T015. The maintainer's instruction was to re-time the two parked f199 lanes cold, with only the plan's `env_refs`, before the signoff round, keeping the 2.4x headroom. They were last measured on 10-14, and T006 to T014 have added suites since. Both passed, and both were under the floor:
  - `f199-class-guards`: 164.6 s against 270 s (1.64x).
  - `f199-slice-suites`: 298.8 s against 480 s (1.61x).
- **Requirement**: the plan's timeouts carry real headroom (DRIFT-013, DRIFT-026), so the sign-off round cannot fail on a timeout.
- **Resolution**: split, not raised, as for f202 (`f91fc20d`). Each part was re-timed cold the same way:
  - **Class guards.** The parallel set alone took 132.3 s (2.04x), so the set itself is split. `-a` runs verdict capture first, as the lane's label requires, then 15 suites and `crew-charter-ownership` (75.4 s alone, the heaviest): 78.6 s (3.44x). `-b` runs the other 14 suites and the Pester block: 62.1 s (4.35x).
  - **Slice suites.** `-a` is the 25 parallel script suites, 181.1 s (2.65x). `-b` is the Pester block, 112.9 s (4.25x).
  - **Same suites.** All 77 suites of the two old lanes are in exactly one new lane, checked by set comparison. The lane guard passes.
  - **The f202 lanes, re-timed after today's suites.** Lane a ran 193.9 s (3.09x). Lane b ran 240.9 s (2.49x), just above the floor, so its label says the next suite added there splits it. The governance lane ran 22.3 s against 180 s (8.07x).
- **The parked file stays.** It keeps its lanes and gains a "restored" note. The lane guard refuses an empty parked file, and moving the file needs the maintainer's approval.
- **Class closure**: every lane's label records its cold measurement against its own timeout, so a lane that falls under the floor is visible at its next re-timing.
- **Update, 2026-10-15 (round-4 launch)**: the install copied the parked lanes without their `provenance` object, which the plan schema requires. The round-4 launch refused the plan before starting ("command at index 3 is invalid: provenance is required"), and it used no round: the approval stayed available. Each split lane now carries its parked lane's provenance (`af68bad4`). Re-timed cold after the DRIFT-030 changes: `f202-slice-suites-b` ran 180.9 s (3.32x), and `f199-class-guards-b`, with the B4F-116 suite added, ran 71.3 s (3.79x). Lane b's two cold runs differ by 60 s on this machine, so its label keeps the slower figure (2.49x).

### DRIFT-030 — T007's first live run with T014 repainted a whole reply over two reworded headings (resolved)

- **Observed**: 2026-10-15, the first live turn declared through T014's stdin route. The Stop blocked the reply:

  > Specrew: your reply is missing these lines from the message you declared. Add them as written; the wording around them is yours:
  > `## The lock: kept at 1000 ms, now as one budget per hook fire`
  > `## T014: turn drafts come in over stdin, stored per session (done)`

  The reply had carried `## The lock: kept at 1000 ms, now one budget per hook fire` and `## T014: turn drafts come in over stdin and are stored per session (done)`. Each heading differed from the draft by function words only, and the crew rendered the whole message again. The maintainer recorded this as the B4F-104 repaint class on the fix's first live run: T007's promise is that the Stop checks meaning, not wording.
- **Cause**: T007 made the Stop compare only meaning lines, but each one by exact substring. A heading reworded by one word read as absent. There is a second detail: the host accessors hand the Stop the reply flattened to single spaces, so a reply heading cannot be found by line.
- **Requirement**: FR-012 (the Stop checks substance, never formatting); FR-015; SC-003 (0 extra stops).
- **Resolution** (`dc5a4fb8`): a declared heading counts as present when a reply heading carries its meaning. The match finds reply headings by their `#` markers, and needs three things:
  1. the same numbers and identifiers (so "Round 3" never answers for "Round 4", nor `T013` for `T014`);
  2. the same negations (so "does not hold" never answers for "holds");
  3. content words with a Jaccard similarity of 0.75 or more, after function words are dropped.

  Each reply heading answers for one declared heading only. Links, the question line, the approval line, the options and the marker stay exact, because they are what the human acts on.
- **Tests**: `presented-check` case 8 carries the live turn's exact lines. It was RED before the fix: the Stop blocked them. Now they pass at the function level and through the real Stop. The cases that must still block do block: a changed number, a changed id, an added negation, a different subject, a dropped heading, and one reply heading claimed for two declared headings. One more finding along the way: the suite decoded its child processes' output with the caller's console encoding, so case 6's em dash failed whenever a Git Bash caller ran it (it passed from PowerShell and in CI). It now decodes as UTF-8.
- **Class closure**: the meaning comparison lives in the one store function both the declaration and the Stop use, and case 8 pins the live failure. A future rewording of a heading that keeps its numbers, identifiers and negations no longer costs a repaint.
<!--
  Every new ### DRIFT-... event includes:

  - **Class closure**: the executable mechanism that makes the next instance impossible or loud

  If the change fixes only this instance, write NONE — <why class closure is not in scope>.
  A bare Resolution: FIXED is not class closure.
-->

### Resolution Strategies (Unused)

The following resolution strategies remain available if drift is detected later in execution:

- **spec-updated**: Update the spec to reflect implementation choice
- **implementation-reverted**: Revert implementation to match spec
- **deferred**: Mark drift as deferred to next iteration
- **human-decision**: Escalate to Alon for resolution

### Notes

- This artifact was scaffolded before review starts so drift can be logged immediately when detected.
- Replace the zero-drift summary with real counts when the first drift event is recorded.
