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

**Total drift events**: 17
**Resolution rate**: 94% (16/17 resolved; DRIFT-006 open, T011 scope)
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

### DRIFT-006 — the readiness verdict reported READY for implementation before any before-implement verdict (open; T011 scope)

- **Observed**: 2026-10-13, before-implement preparation. `readiness-verdict.ps1` printed "Overall verdict: READY for implementation - 'before-implement' is authorized (this iteration's cycle is authorized through 'feature-closeout')". The ledger's `last_authorized_boundary` is `tasks`, and `verdict_history` holds no `approved for before-implement` for 202. The check reads feature 199's completed cycle as 202's.
- **Requirement**: FR-026 (all per-feature runtime state keyed to the new feature on a new-feature reset; B4F-109 widened at clarify). A false READY first line is the B4F-071 hazard: a crew can announce implementation on it.
- **Resolution**: not acted on. Implementation waits for the human verdict regardless. T011's scope already covers it ("all per-feature runtime state keyed to the new feature"). Its acceptance gains one check: the readiness verdict for a new feature never reports a prior feature's cycle as authorization.
- **Class closure**: T011's `new-feature-reset` test asserts that the readiness verdict for 202, before its before-implement verdict, is not READY.

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
