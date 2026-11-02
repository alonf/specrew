# Tasks: beta5 stabilization (iteration 001)

**Feature**: 203-beta5-stabilization
**Plan**: file:///C:/Dev/specrew-b4f-142/specs/203-beta5-stabilization/plan.md
**Date**: 2026-10-31
**Effort unit**: story points. 28.5 SP is planned against the 20 SP convention, an overcommit of 8.5 SP accepted
by the maintainer's plan verdict. Review is governed by the review budget, not SP.

Iteration 001 is T001 to T008 and T011 to T014. T009 (scoped rounds, FR-013) and T010 (token usage, FR-012) moved
to iteration 002 at the plan verdict and keep their feature-global IDs; they are listed at the end and are not
worked in iteration 001. Tasks mirror the plan's work items: W0 is T001, W1 is T002, then in order.

**Every task lands RED-first:** its fixture first reproduces the defect through the shipped entry point (the real
dispatcher with a deployed binding, or the real script), and only then does the fix turn it green. On every
commit:

- twin-copy parity (`scripts/internal/` and `extensions/` for the dispatcher and providers);
- the psd1 FileList, with new files added in sorted position;
- SelfLeakLintLane on touched templates and skills;
- the consumer-language check (banned nouns, glossed IDs).

The `.specify` mirror is NOT synced per commit in 203: it moves only at a deployment point with the live-engine pin
(plan, "When 203's changes reach the live hooks"; manifest exception). Before the before-implement packet, main is
merged in if it has moved (custom rule `feature-203.rule.main-sync-before-implement-packet`).

## Execution order

T002 (reviewed and deployed alone), T001, T003, T004, T005, T006, T007, T008, T011, T012, T013, then review,
then T014.

- T002 comes first: until the pin is live, any engine edit in this worktree judges the maintainer's approvals.
- T001's host facts feed T003 (identity, standalone rule) and T006 (visible line).
- T003 and T004 are foundational for every capture task.
- T007 and T008 share the orchestrator and run serially.
- T014 runs only after the iteration's review sign-off.

## Phase 1: Setup (live engine pin and host facts)

- [ ] T002 [owner: Implementer] [sp: 2.0] **Live engine pin (DA-8).**
  - **Work:** the handover, navigator and bootstrap providers and the dispatcher's provider-command resolution
    let an explicitly set `SPECREW_MODULE_PATH` win over the self-host tree; add
    `scripts/internal/live-engine-pin.ps1` (create, advance, show) for a detached `git worktree` at
    `%USERPROFILE%\.specrew\live-engine\203-beta5-stabilization`; wire this worktree's hook launcher `-ModulePath`
    to it; twin-copy parity.
  - **RED:** `tests/unit/live-engine-resolution.Tests.ps1`: with the variable set, a deliberately broken engine
    file in the project tree is loaded today.
  - **Acceptance:** with the variable set, the broken project-tree file is not loaded; with it unset, behaviour is
    unchanged for downstream projects; reviewed in its own round; after sign-off, the `.specify` mirror is synced
    from the same commit and the pin is created at it.
  - **Inert until configured (before-implement verdict, 2026-11-01):** with no pin configured, engine resolution
    behaves exactly as today. Only a pin that IS configured but missing or corrupt refuses visibly. Otherwise T002's
    own review round and the pin creation step would be refused by the hooks T002 just changed. A pin is configured
    by `.specrew/runtime/live-engine.json` (machine-local, git-ignored), written only by the pin script.
  - **Acceptance, failure direction (tasks verdict, 2026-10-31):** a configured pin that is missing or corrupt (the path absent, not a
    checkout, or missing an engine file) makes the hooks refuse visibly, in plain words with one recovery action,
    and never silently fall back to the worktree's source or the deployed bundle. Today's engine loader falls back
    to the deployed bundle or the repository source. RED: `live-engine-resolution.Tests.ps1` removes and corrupts
    the pin and asserts the refusal and that no project-tree engine file was loaded.
  - **The hooks run from the pin (implement ruling, 2026-11-01; DRIFT-007):** with a pin configured, the hook
    launcher runs the pin's deployed dispatcher, which reads its catalog and providers from its own tree, and every
    hook-path code load (including the deployed extension scripts) resolves to the pin. The `.specify` mirror is
    synced in every commit again. Condition (a): the launcher passes the host's project directory as
    `-ProjectRoot` and the dispatcher uses it as given. RED and acceptance: `tests/unit/live-engine-hook-root.tests.ps1`
    runs hook events through a configured pin and asserts nothing is written into the pin or the profile's
    `.specrew`, no worktree engine copy runs, the writes land in the project, and a pin that cannot be found refuses
    visibly. Condition (b): scripts the crew runs itself keep running from this worktree's `.specify` (accepted).
  - **Review round 1 (2026-11-01; DRIFT-010):** the launcher checks the pin's HEAD against the recorded commit
    before running any pin code; the pin script refuses a dirty pin at Create and Advance; a pin record plus a
    failing or missing helper refuses in the dispatcher. Finding 1 (the refusal's visible channel per host) is a
    follow-up to T006 and the iteration-002 three-host walk.
  - **Follow-up: hook command length (2026-11-01; DRIFT-016):** every generated hook command, for every host, stays
    within 4,095 characters (half of cmd.exe's 8,191). Claude's command runs a launcher generated beside its settings,
    which carries the pin check and the baked binding; Antigravity's binding is read from beside the per-machine
    launcher. RED and acceptance: `tests/unit/hook-command-length.tests.ps1`, including runs through cmd.exe. Reviewed in
    its own round; the pin is recreated and the hooks redeployed only after its sign-off, confirmed from the transcript.
  - **Follow-up review round 3 (2026-11-01; DRIFT-017):** with a pin, the hooks use the pin's host bindings,
    written by Create and Advance from the pin's own deployer and stamped with its commit; both launchers refuse a
    missing or wrongly stamped binding before any pin code runs. The generated Claude launcher honours
    `SPECREW_REFOCUS_DISABLE` before the pin check. RED and acceptance: `live-engine-hook-root.tests.ps1` and
    `live-engine-resolution.tests.ps1`. Design follow-up for iteration 002 or 204: B5F-019 (the pin leaves shipped code).
  - **Signed off on `7abcd180` after review round 4 (2026-11-02; DRIFT-019).** Follow-ups from round 4 (Codex), both
    reported major and demoted by Specrew:
    - Finding 1, **release-blocking** (introduced in `0999ff62`): the launcher-encoded command reads its binding from
      `~/.specrew/hook-bindings/<host>.binding`, one file per machine, so deploying project B from a different module
      version or tree changes project A's typed-approval and stop rules, with or without a pin. Store the binding
      per project, or as an immutable content-addressed file the command names; a two-project test. Both deployer
      copies. Fixed in its own commit and reviewed before any release. **Fixed in `9d224109` (DRIFT-020):** the
      binding file is named by its content id and written once, the command names the id with `-BindingId`, and
      the launcher reads only that file when its content matches; RED and acceptance:
      `tests/unit/hook-binding-per-project.tests.ps1` (fails against `7abcd180`'s deployer). Reviewed in round 5.
  - **Round 5 (Codex, on `c9549a9d`; DRIFT-021).** Four findings, all reported major and demoted; 1, 3 and 4 fixed
    in `c988b849` at the maintainer's instruction, 2 joins B5F-019:
    - Finding 1: the per-machine launcher was still one file, so an older engine's launcher without `-BindingId`
      broke another project's commands. Launchers and bindings now share one content-addressed store,
      `~/.specrew/hooks/<id>/specrew-hook-launch.ps1` and `~/.specrew/hooks/bindings/<host>-<id>.binding`, written once;
      every launcher command names its launcher, an encoded one its binding too. RED and acceptance:
      `hook-binding-per-project.tests.ps1`, two projects from two launcher implementations in both orders (fails
      against `9d224109`).
    - Finding 2 (a repeat of round 4's finding 2): the per-machine launcher finds the pin only after the project's
      dispatcher file. B5F-019.
    - Finding 3: a pin record with the pin's `live-engine-resolution.ps1` missing made the handover, bootstrap and
      navigator providers and the conformance and shared-governance resolvers load the project's own code; they now
      refuse. RED and acceptance: `live-engine-hook-root.tests.ps1` (against the old providers the project's
      HandoverStore, ClassificationEngine and ProjectMetadataAccessor ran).
    - Finding 4: `crew-charter-ownership` and `version-label-one-resolver` ran the real init, which deployed the real
      home's user-level hooks with their checkout as `-ModulePath`. The deployer honours `SPECREW_USER_HOME_OVERRIDE`;
      both suites use a scratch home and check the real home's hook files are unchanged.
  - **Round 6 (Codex, on `2dd67efe`; DRIFT-022).** Three findings, all reported major and demoted; all three fixed in
    `03dd3c3b` at the maintainer's instruction:
    - Finding 1: deploy deleted the old shared `~/.specrew/hook-bindings/<host>.binding`, which commands deployed from
      `0999ff62`..`7abcd180` still read. It is left in place; the new launcher never reads it.
    - Finding 2: a named binding the launcher could not read or verify was dropped and the dispatcher fell back to a
      manifest. The per-machine launcher now refuses in plain text (exit 1), after the kill switch.
    - Finding 3 (rounds 4 to 6; B5F-019's root discovery): the per-machine launcher's root discovery also stops at a
      live-engine pin record, so a pinned project without its deployed dispatcher runs the pin's dispatcher, never
      an ancestor project's. RED and acceptance: `hook-binding-per-project.tests.ps1` and
      `live-engine-hook-root.tests.ps1` (all three fail against `2dd67efe`; the ancestor's dispatcher ran).
    - Finding 2: the per-machine launcher looks for the pin only after it finds the project's own dispatcher file,
      so a pinned project whose `.specify` dispatcher is missing runs ungoverned (exit 0, nothing recorded), or an
      ancestor project's dispatcher takes the event. Recognize the pin record during root discovery. Joins B5F-019.
  - **Trace:** FR-014; clarify instruction (live hooks only after review).
  - **Owns:** `extensions/specrew-speckit/scripts/specrew-handover-provider.ps1`,
    `extensions/specrew-speckit/scripts/specrew-co-review-navigator-provider.ps1`,
    `extensions/specrew-speckit/scripts/specrew-bootstrap-provider.ps1`,
    `extensions/specrew-speckit/scripts/specrew-conformance-provider.ps1`, both dispatcher and deployer copies,
    `extensions/specrew-speckit/scripts/live-engine-resolution.ps1`, `shared-governance.ps1`,
    `scripts/internal/bootstrap/ProjectMetadataAccessor.ps1`, `scripts/internal/live-engine-pin.ps1`, the `.specify`
    mirror of each, `.specrew/verification-plan.json`, `tests/unit/live-engine-resolution.tests.ps1`,
    `tests/unit/live-engine-hook-root.tests.ps1`.
- [ ] T001 [owner: Implementer] [sp: 2.0] **Host facts in scratch directories (W0).**
  - **Work:** in scratch directories only (rule `feature-203.rule.scratch-probes-only`): both Copilot firings
    (native and Claude-hook) for one prompt; a paste on Copilot and on Codex; a Claude hook emitting
    `systemMessage` (the maintainer observes whether it is shown); a real Claude compaction entry.
  - **RED:** `tests/unit/typed-turn-identity.Tests.ps1`: the two Copilot firings produce two identities today.
  - **Acceptance:** fixtures with provenance under `tests/fixtures/hook-payloads/<host>/`; one normalized
    identity for both firings, or the replacement named for the before-implement packet; paste and visible-line
    facts recorded in research.md.
  - **Trace:** FR-016, FR-017, FR-027; DA-2, DA-3, DA-4.
  - **Owns:** `tests/fixtures/hook-payloads/**`, `tests/unit/typed-turn-identity.Tests.ps1`,
    `specs/203-beta5-stabilization/research.md`.
  - **First commit (maintainer's instruction, 2026-11-01; DRIFT-015):** carries T002's round 2 findings 2 to 4:
    `scripts/internal/live-engine-pin.ps1`, `scripts/internal/bootstrap/ProjectMetadataAccessor.ps1`,
    `tests/unit/live-engine-resolution.tests.ps1` and the `f203-i001-suites` lane in `.specrew/verification-plan.json`.

## Phase 2: Foundational (blocks US1 to US3)

- [ ] T003 [owner: Implementer] [sp: 4.0] **Resolve-SpecrewTypedAct (DA-1 Option B).**
  - **Work:** one pure function: turn record plus pending state in, exactly one act or none with a reason out
    (data-model.md); identity per binding including the Copilot stand-in; the standalone rule (DA-3); routing to
    verdict, top-up, stop answer or workshop reply; a mismatched boundary yields none.
  - **RED:** `tests/unit/typed-act-classifier.Tests.ps1`: a quoted, backticked or pasted phrase mints today on at
    least one path; a compaction summary entry is routed.
  - **Acceptance:** non-approval phrases yield none; a compaction summary yields none; one turn yields one act.
    **Added after T002's review (DRIFT-014):** a typed approval that arrives queued (a queue-operation entry before
    the user turn) counts as typed; fixtures from DRIFT-006 and DRIFT-012.
  - **Trace:** FR-014, FR-015, FR-018, FR-020, FR-023.
  - **Owns:** `scripts/internal/bootstrap/HumanAuthorityStore.ps1`, `hosts/*/host.psd1`,
    `tests/unit/typed-act-classifier.Tests.ps1`.
- [ ] T004 [owner: Implementer] [sp: 4.0] **Write-SpecrewTypedAct and the rewiring.**
  - **Work:** the only writer for recovery paths: re-reads the cited turn and re-derives through T003, writes only
    if unrecorded; rewire the user-prompt router, turn-end recovery, transcript backstop and writer CLIs; remove
    the per-path rules and `--approve-round`; immutable supersession fact.
  - **RED:** `tests/unit/typed-act-writer.Tests.ps1`: an agent citing a real `confirm` turn mints a verdict today
    through a writer; a re-typed approval folds into an older unspent one.
  - **Acceptance:** the cited-turn case mints nothing; supersession retires, never reuses; no script or `!`
    approval path remains.
  - **Trace:** FR-010, FR-021, FR-022, FR-025.
  - **Owns:** `scripts/internal/bootstrap/HandoverStore.ps1`, `scripts/internal/bootstrap/HumanAuthorityStore.ps1`,
    `scripts/internal/continuous-co-review/review-authority-core.ps1`, `tests/unit/typed-act-writer.Tests.ps1`.

## Phase 3: US2, nothing recorded that I did not give, recorded the first time (P1)

- [ ] T005 [owner: Implementer] [sp: 1.5] [US2] **Verdict pairing across a compaction.**
  - **Work:** pair a verdict-shaped reply with the durable pending-crossing record; remove the fallback to an
    older pair; a mismatched boundary is reported and records nothing.
  - **RED:** `tests/unit/verdict-pairing.Tests.ps1`: packet, compaction, verdict returns the older pair today
    (B4F-112).
  - **Acceptance:** the verdict records once against the waiting boundary; `approved for tasks` while plan waits
    records nothing and is reported.
  - **Trace:** FR-019, FR-020.
  - **Depends:** T003, T004.
  - **Owns:** `scripts/internal/bootstrap/HandoverStore.ps1`,
    `scripts/internal/bootstrap/ConversationCaptureAccessor.ps1`, `tests/unit/verdict-pairing.Tests.ps1`.
- [ ] T012 [owner: Implementer] [sp: 1.5] [US2] **Audit and correlation.**
  - **Work:** an audit joining every authority record to a typed human turn; reservations cite the grant and the
    latest reset; turn identity on every record and campaign id on review records.
  - **RED:** `tests/unit/authority-audit.Tests.ps1`: a backstop-minted record with no typed turn passes today.
  - **Acceptance:** any record without a joined typed turn fails the audit.
  - **Trace:** FR-024, FR-041.
  - **Depends:** T004, T008.
  - **Owns:** `scripts/internal/bootstrap/*.ps1`,
    `scripts/internal/continuous-co-review/review-authority-store.ps1`, `tests/unit/authority-audit.Tests.ps1`.

## Phase 4: US3, told in the same turn (P1)

- [ ] T006 [owner: Implementer] [sp: 2.0] [US3] **Not-recorded reporter.**
  - **Work:** every none-reason except `already-recorded` and `not-standalone` reports in the same turn with its
    own reason (form unreadable, writer failed, origin unconfirmed, no pending crossing, boundary mismatch, stage
    evidence absent); the report checks the store when it speaks; Claude visible line, justified stop elsewhere;
    the refusal standard; diagnosis to the drift record.
  - **RED:** `tests/unit/not-recorded-report.Tests.ps1`: an unreadable approval form records nothing and says
    nothing today (B4F-151).
  - **Acceptance:** each branch reports with its reason; a recorded approval never reports.
    **Added after T002's review (DRIFT-014):** a recorded round approval never gets the "nothing was recorded"
    notice (it got one 4 times on 2026-11-01).
    **Added after T002's round 4 checks (DRIFT-018), the refusal-visibility follow-up from T002 round 1 finding 1:**
    a hook refusal is written as plain text. Today a launcher refusal is a `throw` and reaches the host in pwsh's
    error view: a source excerpt, the message wrapped behind a `|` gutter, ANSI color codes, or CLIXML from
    `-EncodedCommand`.
  - **Trace:** FR-026, FR-027, FR-032 (touched refusals).
  - **Depends:** T001, T003.
  - **Owns:** `scripts/internal/bootstrap/HumanAuthorityStore.ps1`, `scripts/internal/bootstrap/HandoverStore.ps1`,
    `tests/unit/not-recorded-report.Tests.ps1`.

## Phase 5: US1, approve a review budget once (P1)

- [ ] T007 [owner: Implementer] [sp: 2.5] [US1] **Budget declaration and snapshot.**
  - **Work:** parse the plan's `## Review budget` block; validate against `co_review_max_rounds` at plan sync and at
    the snapshot (the refusal names the ceiling and `.specrew/config.yml`); write the grant fact at the
    before-implement verdict, citing the verdict entry; zero rounds when no budget is stated.
  - **RED:** `tests/unit/review-budget-snapshot.Tests.ps1`: the grant is one slot per authorization today.
  - **Acceptance:** a plan edit after the verdict does not change the grant; above-ceiling refused at both points.
  - **Trace:** FR-001, FR-002, FR-003, FR-008.
  - **Depends:** T004.
  - **Owns:** `scripts/internal/sync-boundary-state.ps1`,
    `scripts/internal/continuous-co-review/review-campaign-orchestrator.ps1`,
    `tests/unit/review-budget-snapshot.Tests.ps1`.
- [ ] T008 [owner: Implementer] [sp: 5.0] [US1] **Orchestrator loop on the budget.**
  - **Work:** single grant; reservation before invocation against `budget_total`; clean ends, fix-needed runs the
    next round; the top-up starts the next round; `infra_failure_cap` consecutive infrastructure failures advance
    the host; pause facts (a) to (d) are the navigator's only stop source; the stop layout and the phrases
    (`stop the review here`, `defer finding <id> to <destination>`, `drop finding <id>`, `fix finding <id>`,
    `allow reviewer <host>`).
  - **RED:** `tests/unit/review-budget-loop.Tests.ps1`: a reviewer is invoked past the cap today (the July shape).
  - **Acceptance:** no reviewer invoked past `budget_total`; two infrastructure failures advance codex to copilot;
    an exhausted order pauses at (d); no stop asks for a round.
    **Added after T002's review (DRIFT-014):** no Stop asks for a round, a decision or a review while a round or a
    stop's final check is running. Each round report and stop states, in the engine's own words, the reviewer host
    that ran, the approval it spent with its time, and the commit reviewed. The stop layout never says "found
    nothing that needs your attention" next to a findings count.
  - **Trace:** FR-004, FR-005, FR-006, FR-007, FR-009, FR-011, FR-043.
  - **Depends:** T007.
  - **Owns:** `scripts/internal/continuous-co-review/*.ps1`, `tests/unit/review-budget-loop.Tests.ps1`.

## Phase 6: US4 part, the Stop check verifies the reply (P1 for iteration 001)

- [ ] T011 [owner: Implementer] [sp: 1.5] [US4] **Decision parts, not a second copy (FR-046).**
  - **Work:** the Stop check verifies the reply itself for the approval line, the marker and the options; a
    reworded content line passes; the word-for-word declared-vs-reply comparison goes. **Tasks verdict addition:**
    piping the packet (or any reply draft) into `declare-turn-end.ps1` goes too. The piped copy shows in the
    maintainer's terminal as the command's input, so every boundary packet reaches the human twice even when
    nothing blocks (the tasks packet did at 11:43, 2026-10-31). The declaration keeps its kind, token, summary and
    pending item; the skills and refocus surfaces that tell the agent to pipe a draft are updated, born-clean.
  - **RED:** `tests/unit/presented-check.Tests.ps1`: a reworded discussion line blocks today (09:36, 2026-10-31);
    `declare-turn-end` requires a piped draft for a boundary declaration today.
  - **Acceptance:** a reworded line passes; a missing marker or option blocks; a boundary declaration needs no
    piped draft, and no shipped skill or refocus text asks for one.
    **Evidence added (DRIFT-018):** 22:07, 2026-11-01, a conversational reply carrying the declared question
    reworded was blocked with "your reply is missing these lines from the message you declared. Add them as
    written", and the line was sent again verbatim.
  - **Trace:** FR-046.
  - **Owns:** `extensions/specrew-speckit/scripts/specrew-conformance-provider.ps1`,
    `extensions/specrew-speckit/scripts/turn-end-store.ps1`, `extensions/specrew-speckit/scripts/declare-turn-end.ps1`,
    the skill and refocus sources that name the piped draft, `tests/unit/presented-check.Tests.ps1`.

## Phase 7: Evidence and deployment

- [ ] T013 [owner: Implementer] [sp: 1.5] **Test evidence suite.**
  - **Work:** no-human-turn fixtures for every mint path; non-approval phrase fixtures; cross-host replay with
    recorded payloads, including a compaction; budget economics fixtures; all census-selected and in a PR lane.
  - **Acceptance:** the suites run green in the census selection and a PR lane.
  - **Trace:** FR-042, FR-043.
  - **Depends:** T003 to T008, T011, T012.
  - **Owns:** `tests/unit/**`, `tests/integration/**`.
- [ ] T014 [owner: Implementer] [sp: 1.0] **Deployment point and the Claude-only capture check.**
  - **Work:** after the iteration's review sign-off: advance the pin to the signed-off commit and sync the
    `.specify` mirror from it in one commit; then the maintainer's check (a verdict after a compaction, a quoted
    phrase, a pasted phrase), recorded.
  - **Acceptance:** `iterations/001/capture-check.md` records the verdict once in its own turn and nothing for the
    other two.
  - **Trace:** FR-045.
  - **Depends:** the review sign-off.
  - **Owns:** `specs/203-beta5-stabilization/iterations/001/**`, `.specify/extensions/specrew-speckit/**`.

## Moved to iteration 002 (plan verdict, 2026-10-31)

- [ ] T009 [owner: Implementer] [sp: 2.0] [US1] **Scoped late-fix round (DA-7).** The reviewer receives only the
  listed paths (sparse checkout), labelled `scoped`; coverage rule. Trace: FR-013. Owns:
  `scripts/internal/continuous-co-review/worktree-*.ps1`, `review-target-port.ps1`, `tests/unit/scoped-round.Tests.ps1`.
- [ ] T010 [owner: Implementer] [sp: 1.5] [US1] **Host-reported token usage.** Per round and at sign-off; "not
  reported by <host>" otherwise. Trace: FR-012. Owns: `scripts/internal/continuous-co-review/review-*-harness-port.ps1`,
  `review-progress-projection.ps1`, `tests/unit/review-usage.Tests.ps1`.

## Traceability

| Requirement | Tasks |
| --- | --- |
| FR-001, FR-002, FR-003, FR-008 | T007 |
| FR-004, FR-005, FR-006, FR-007, FR-009, FR-011 | T008 |
| FR-010 | T004 |
| FR-012 | T010 (iteration 002) |
| FR-013 | T009 (iteration 002) |
| FR-014 | T002, T003 |
| FR-015, FR-018, FR-023 | T003 |
| FR-016, FR-017 | T001, T003 |
| FR-019 | T005 |
| FR-020 | T003, T005 |
| FR-021, FR-022, FR-025 | T004 |
| FR-024, FR-041 | T012 |
| FR-026 | T006 |
| FR-027 | T001, T006 |
| FR-042 | T013 |
| FR-043 | T008, T013 |
| FR-045 | T014 |
| FR-046 | T011 |
