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

- [X] T002 [owner: Implementer] [sp: 2.0] **Live engine pin (DA-8).**
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
  - **Round 7 (Codex, on `063e233a`; DRIFT-023); signed off on `063e233a`.** Two findings, both reported major and
    demoted, both a file missing from inside the pin falling back to the project's copy (the refocus lookup of
    `work-kind-common.ps1`; `Get-DispatcherCatalog`'s source-catalog fallback). The maintainer stopped the review;
    both go to B5F-019 with the class and a sweep of every hook-path load as its acceptance. The pin was advanced
    to `063e233a` and the Claude hooks redeployed from it, confirmed from the transcript.
    - Finding 2: the per-machine launcher looks for the pin only after it finds the project's own dispatcher file,
      so a pinned project whose `.specify` dispatcher is missing runs ungoverned (exit 0, nothing recorded), or an
      ancestor project's dispatcher takes the event. Recognize the pin record during root discovery. Joins B5F-019.
  - **Follow-up (maintainer, 2026-11-07; B5F-033, DRIFT-047):** syncing the mirror in every commit (the implement ruling
    above) never refreshed its install record, `.specrew-extension-runtime.json`, so from `040fb169` the deployed files
    did not match it and `validate-governance-changed-only`, whose fixture copies this `.specify`, failed W43; it was in
    no lane. `tools/maintenance/refresh-specify-mirror-record.ps1` writes the record with the installer's writer
    (`Write-SpecrewDeployedExtensionMarker`) only after confirming every deployed file is byte-identical to its source
    in `extensions/`, with no file on one side only; otherwise it refuses and leaves the record. Every commit that syncs
    the mirror runs it. Acceptance: `tests/unit/specify-mirror-record.Tests.ps1` (a hand edit in `.specify` is refused
    and W43 still names it; the committed mirror and record match) and `self-repo-review-integrity.tests.ps1` (this tree
    validated with iteration 001 in reviewing status, where W43 runs, reports no integrity error; a hand-edit control
    does) in `f203-i001-suites`; the changed-only suite green,
    with a case proving a hand edit to a deployed file still fails the validator, in its own lane
    `f203-i001-validator-scope` (1200 s; first 900 s, raised on 2026-11-07 after a run of 872 s).
  - **Trace:** FR-014; clarify instruction (live hooks only after review).
  - **Owns:** `extensions/specrew-speckit/scripts/specrew-handover-provider.ps1`,
    `extensions/specrew-speckit/scripts/specrew-co-review-navigator-provider.ps1`,
    `extensions/specrew-speckit/scripts/specrew-bootstrap-provider.ps1`,
    `extensions/specrew-speckit/scripts/specrew-conformance-provider.ps1`, both dispatcher and deployer copies,
    `extensions/specrew-speckit/scripts/live-engine-resolution.ps1`, `shared-governance.ps1`,
    `scripts/internal/bootstrap/ProjectMetadataAccessor.ps1`, `scripts/internal/live-engine-pin.ps1`, the `.specify`
    mirror of each, `.specrew/verification-plan.json`, `tests/unit/live-engine-resolution.tests.ps1`,
    `tests/unit/live-engine-hook-root.tests.ps1`; follow-up: `tools/maintenance/refresh-specify-mirror-record.ps1`,
    `.specify/extensions/specrew-speckit/.specrew-extension-runtime.json`, `tests/unit/specify-mirror-record.Tests.ps1`,
    `tests/integration/validate-governance-changed-only.tests.ps1`, `tests/integration/self-repo-review-integrity.tests.ps1`.
- [X] T001 [owner: Implementer] [sp: 2.0] **Host facts in scratch directories (W0).**
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
  - **Result (2026-11-02):** all four facts recorded in research.md (R1 to R4 W0 results); no replacement is needed
    for the before-implement packet. Copilot's two firings of one prompt carry the same session, text and instant
    (headless 1.0.103 and TUI 1.0.105); no paste marker on Copilot or Codex; Claude shows `systemMessage` to the
    human only; a real compaction summary reuses the last prompt's `promptId`. Fixtures with provenance:
    `copilot/one-prompt-two-firings/`, `copilot/tui-paste/`, `codex/tui-paste/`, `claude/compaction/`. The RED test
    fails today for the stated reason and is listed in `.specrew/release-gate-suites.txt` (outside this task's owned
    files, so the suite guard passes) until T003 moves it to the `f203-i001-suites` lane.

## Phase 2: Foundational (blocks US1 to US3)

- [X] T003 [owner: Implementer] [sp: 4.0] **Resolve-SpecrewTypedAct (DA-1 Option B).**
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
  - **RED set (maintainer's instruction, 2026-11-02):** a queued typed approval counts as typed (DRIFT-006,
    DRIFT-012); a compaction summary quoting `approved for review round` is not a typed turn (R4); a pasted
    transcript that begins with the phrase is not typed (DRIFT-023, the 14:39 paste). Each is a case in
    `typed-act-classifier.Tests.ps1`, built from a recorded fixture.
  - **Not T003 (named so the split is visible):** the re-typed approval dropped while an older one is unspent (02:44
    and 14:45 local, 2026-11-02; DRIFT-019, DRIFT-023) is T004's supersession (FR-021), and the notice the human gets
    for it is T006's.
  - **Result (2026-11-02, DRIFT-025):** `Resolve-SpecrewTypedAct` and `Get-SpecrewTypedActIdentity` in
    HumanAuthorityStore (pure; nothing calls them until T004). The Copilot stand-in identity is declared in
    `hosts/copilot/host.psd1` and built by the dispatcher, with the deployer carrying it (T002's files, twins
    synced); `typed-turn-identity.Tests.ps1` is green and both suites are in the `f203-i001-suites` lane. Found on
    the way: Claude reuses the running turn's `prompt_id` for a queued message, the cause of DRIFT-006 and
    DRIFT-012; and the live prompt-entry verdict path takes `I approved for tasks yesterday` as approval of a waiting
    crossing. The classifier refuses both; the live paths change in T004.
- [X] T004 [owner: Implementer] [sp: 4.0] **Write-SpecrewTypedAct and the rewiring.**
  - **Work:** the only writer for recovery paths: re-reads the cited turn and re-derives through T003, writes only
    if unrecorded; rewire the user-prompt router, turn-end recovery, transcript backstop and writer CLIs; remove
    the per-path rules and `--approve-round`; immutable supersession fact.
  - **RED:** `tests/unit/typed-act-writer.Tests.ps1`: an agent citing a real `confirm` turn mints a verdict today
    through a writer; a re-typed approval folds into an older unspent one.
  - **Acceptance:** the cited-turn case mints nothing; supersession retires, never reuses; no script or `!`
    approval path remains.
    **Added (maintainer's UX ruling, 2026-11-04 (19:05 local): a human answers a question when they see it, so a reply typed while the turn is still ending (Stop hook running) must just work):** a queued reply carrying the running turn's prompt id is recorded once as its own act, and the
    next turn acts on it, for an option answer such as `1` and for `approved for review round`. Failing case first,
    in `tests/unit/typed-act-writer.Tests.ps1` (case 7): run against `bb2d43f6`, the queued reply recorded nothing
    and reported nothing, for both replies; green since `c0e3df13`, where the router keys a message by its act
    identity (the prompt id with the text). The live check: after the pin advances past T004, the maintainer
    answers a question early, on purpose.
    **Added (maintainer's instruction, 2026-11-05, round 8 finding 2; DRIFT-029):** the same text retyped under the
    running prompt id is a second act. The discriminator is the host's own record of each message (on Claude, the
    prompt hook's output stored under the message's own transcript record), never a time window, and no double-fire
    tolerance folds a real retype on Claude. Cases 7b to 7d; red for 7b on `bf3ec079`, green on `fcb93ce3`.
    **Added (maintainer's instruction, 2026-11-05, round 9; DRIFT-030):** both recording paths key, hash and classify
    the message in one text form on every host; an older act never replaces a newer one, spent or not; a design
    decision is a sentence that chooses its option, never one that asks, negates, conditions or deliberates; and every
    nonempty prompt reserves, so the newest reservation is the human's newest message. Red on `cf5bd736`, green on
    `9db6cc0b`.
    **Added (maintainer's instruction, 2026-11-05, round 10; DRIFT-031):** an act the turn end derives and no writer
    records is reported and said with the phrase to retype; the capture, the mint stamp and the spend take turns on the
    waiting slot; and a design decision is the affirmative form (`option <n>` or `option <n> because <why>`). Red on
    `4e78a0ed`, green on `6741cfd1`.
    **Added (maintainer's instruction, 2026-11-06, round 11; DRIFT-033):** a transcript entry's host is the record's,
    never the caller's; a design decision is the decision alone (`design decision: option <n>`); and a reply of another
    authority family gets no boundary-verdict notice. Red on `941c76b5`, green on `ef0b9e23`.
    **Added (maintainer's instruction, 2026-11-06, after round 12; DRIFT-034):** a mention of an approval does not take a
    packet's window; the reset slot is locked and its consumption spends only the capture it used; a round approval
    derived from a reset never overwrites a newer one; a partial run is not a delivered round. Red on `c80e44b1`,
    green on `6210e2ab`.
  - **Round 13 (Codex, on `6210e2ab`; DRIFT-035); signed off on `6210e2ab`.** The maintainer's allowance reset bought
    one verification round of the round-12 fixes. Three findings, all reported major and demoted: another authority
    family's phrase still takes a boundary packet's window (DRIFT-034's fix 1 is incomplete), the approval withdrawal
    bypasses the round slot lock, and a superseding partial sign-off skips the round-approval consumption. The
    maintainer stopped the review; all three go to B5F-029.
  - **B5F-029 split (maintainer's design decision, 2026-11-07, option 3; DRIFT-039):** finding 1 (another authority
    family's phrase takes a boundary packet's window) is fixed in T004 now, before T005, failing case first; findings 2
    and 3 go to T008.
    **Fixed (DRIFT-042):** the transcript reader passes over another authority family's act as it passes over a
    mention. Red on `013a6b0d` (`HookVerdictCapture` 16). Reviewed by the iteration review after T013, live at T014
    (maintainer's decision, DRIFT-041).
  - **Trace:** FR-021, FR-022, FR-025 (FR-010 moved to T008, DRIFT-027).
  - **Owns:** `scripts/internal/bootstrap/HandoverStore.ps1`, `scripts/internal/bootstrap/HumanAuthorityStore.ps1`,
    `scripts/specrew-review.ps1` (its writer CLIs), `extensions/specrew-speckit/scripts/record-design-decision.ps1`
    (and its `.specify` twin), `tests/unit/typed-act-writer.Tests.ps1`. `review-authority-core.ps1` left T004's Owns
    on 2026-11-02 (see "Review-act supersession" below); it stays with T008.
    **Added with the RED test (2026-11-03):** `extensions/specrew-speckit/scripts/shared-governance.ps1` (and its
    `.specify` twin), where `Add-SpecrewBoundaryAuthorization` takes a captured evidence label on the caller's word;
    after T004 it honours one only by re-deriving the cited turn. Twelve existing tests call it directly with a
    captured label and move to a cited typed turn or a declared out-of-band reason: unit `closeout-records-on-approval`,
    `crossing-mint-gate`, `crossing-mirrors`, `new-feature-reset`; integration `closeout-identity-schema-parity`,
    `feature-051-iteration2a-callsite-wiring`, `launch-mode-boundary-enforcement`, `lifecycle-boundary-sync`,
    `no-code-without-approval`, `plan-sync-target-iteration`, `sealed-iteration-writers`, `verdict-capture-blocks`.
  - **Review-act supersession (2026-11-02, the maintainer's question):** the re-typed round approval (02:44 and 14:45
    local) goes green in T004 with `scripts/internal/continuous-co-review/` unchanged. The review acts are captured,
    held and spent in `HumanAuthorityStore.ps1`, not in the review engine: the capture writer keeps one pending slot
    (`.specrew/review/round-approval/pending-round-approval.json`), and the launch reads only that slot, stamps the
    grant reference on it and marks it spent after a delivered round. The fold is in that writer: an unspent record
    with the same text is returned as "the same act", and a record that already minted a grant is never replaced
    (`Test-SpecrewTypedActReplacesRecord`), so the 02:44 reply wrote nothing. T004 replaces both rules with the act
    identity: a newer typed act of the kind writes its own capture, an immutable supersession fact retires the
    older one, and the slot holds the newest, so the spender only ever sees the newest. `review-authority-core.ps1`
    decides reservation and spend by the grant reference `<campaign>-round-<rounds run + 1>`, which does not depend
    on which capture authorized it, so it needs no change. Its pause-decision facts change with T008's stop answers.
    The same rule covers the top-up, the coverage deferral and the partial sign-off, which the same file holds.
  - **RED, split (2026-11-02):** T004 keeps the capture half: a re-typed approval while an older one is unspent
    (minted or not) writes its own capture and a supersession fact; the launch stamps and spends the newer one; the
    older one is never reused. The grant and reservation records naming the typed turn that authorized them stay
    with T012 (turn identity on every record), in `review-authority-store.ps1`. Added acceptance: superseding a
    capture whose round was delivered but not marked spent never pays for that round twice; the newer act mints
    the next round.
  - **The 02:44 relaunch (maintainer's instruction, 2026-11-03; option 1):** after the newer approval supersedes one
    that already minted a grant, the relaunch keeps the same round number (`<campaign>-round-<n>`), reuses that
    grant's slot as its next reservation generation (no second grant, no second slot), and the run cites the newer
    approval through the approval's own record: the newer capture carries the round reference and, once spent, the
    run's id; no record ties the run to the superseded capture. The engine's record formats are unchanged; the run
    record naming the approval itself is T012's.
  - **The round-7 shape (maintainer's finding on `dbc4cd3b`, 2026-11-03):** approval A minted a round and B was typed
    while it ran; B takes the slot. When the round completes with A's reference, B stays unspent and the spent line
    names A. The spend applies only to the approval whose `minted_ref` matches; when the slot has moved on it is
    recorded against the superseded approval; a slot minted for another round is never stamped. The partial sign-off
    spends the approval its accepted run was minted from.
  - **Two more routes to it (maintainer's finding on `50ffca8f`, 2026-11-03):** (1) a launch attempted mid-run mints
    `<campaign>-round-<rounds run + 1>`, which leaves the running round out, so B was stamped with the running round's
    reference, the claim was refused, the stamp stayed, and the completion matched it; (2) a partial sign-off whose run
    resolves to no reference fell back to stamping the never-minted B. Now a waiting approval observed after the run was
    reserved never pays for it (at completion, at the partial sign-off, and when a later launch retires a delivered
    round), an approval that minted no round pays for no named run, and a launch refuses before minting while a round of
    the campaign is in flight (a held claim, or a reserved slot with neither a release nor a result). The automatic retry
    re-stamps its new reference, only while the slot still holds the approval the launch minted; without it, 50ffca8f
    left a delivered retry's approval unspent. RED cases 4-6 in `tests/unit/typed-act-writer.Tests.ps1`.
  - **The cited turn (2026-11-04, case 1 green):** `Write-SpecrewTypedAct` re-reads the cited turn from the host's
    record and writes only the act the classifier derives. The record is the transcript entry (cited by the host's
    message id, or by the act identity when Claude gave a queued message the running turn's `promptId`), or, for a
    prompt with no transcript entry yet, the prompt hook's own reservation of that message, which now carries the
    dispatcher's origin (`turn_origin`). `Add-SpecrewBoundaryAuthorization` honours a captured label only by re-deriving
    the cited turn itself, records the verdict line the turn says and the act identity (`turn_identity`), and a
    citation already recorded returns the existing entry. The live capture (`Invoke-SpecrewBoundaryVerdictCapture`)
    cites the turn it read; to do so the transcript verdict reader returns the captured entry's message id and text, a
    two-field addition to `ConversationCaptureAccessor.ps1` (T005's file; T005's pairing change is untouched). The twelve
    direct-caller suites: seven cite a typed turn (`tests/support/cited-typed-turn.ps1`), five whose fixtures record
    no crossing declare out-of-band, and the capture fixtures carry the host's message id and origin as recorded. One
    test changed meaning on purpose: `verdict-capture-blocks` part 3 no longer expects a second verdict for a boundary
    already crossed to append (FR-019); the same cited turn is one authorization and a later one records nothing.
  - **Cursor and Antigravity identity (maintainer's decision 2026-11-04, option 1):** both send no message id; their
    bindings declare feature 202's position key of the prompt event as the substitute (`MessageIdentity Kind
    'position-key'`), on the prompt path only, computed once per prompt event in `Update-SpecrewRollingHandover`; the
    turn end stays `none`, records nothing and reports. "One prompt event per message" is recorded as an unverified
    assumption in both bindings and in the plan (Risks and watch items). A second prompt event with the same session
    and text within 5 seconds is the same message (`Request-SpecrewPromptRepeatClaim`, a file claim read and rewritten
    under an exclusive handle, because two hooks for one message start before either has reserved anything). The
    double-fire test (`tests/unit/position-key-identity.Tests.ps1`) also found that two hooks appending to the
    exhausted-turn ledger at once made one append fail and that message record nothing without a word;
    `Register-SpecrewExhaustedTurn` now retries a sharing violation for up to three seconds. The probe of both hosts
    is open before 0.40.0 stable (B5F-028).
  - **Supersession for the top-up, the coverage deferral and the partial sign-off (2026-11-04):** one rule,
    `Resolve-SpecrewTypedActSupersession`, the round approval's: with the act's turn identity, the same message
    re-offered returns the held record, an older one arriving late keeps the newer, and a different later message
    journals an immutable `<kind>-superseded` fact (in that store's `supersessions.jsonl`) before taking the record;
    a fact that cannot be journalled writes nothing. The top-up no longer folds a re-typed reset into the older
    unspent one, the deferral no longer overwrites without a trace, and a later partial sign-off for the same request
    replaces the earlier one instead of failing as a conflict (the conflict stays for a caller with no identity).
    RED-then-green: `typed-act-writer` case 8.
  - **Writer CLIs cite the newest typed turn themselves (maintainer's decision 2026-11-04, option 1):** the agent never
    sees the host's message id, so no CLI takes one. `record-design-decision.ps1` records a decision only when
    `-HumanTurn` is the human's newest typed message as the prompt hook reserved it (same content hash, origin
    `typed-user`; `Find-SpecrewNewestTypedTurn` in `design-decision-store.ps1`), and the record carries that turn's
    identity, host and time; otherwise nothing is recorded and the refusal says which message it read
    (`tests/unit/design-decision-cited-turn.Tests.ps1`). The `confirmation` value stays, so recorded decisions stay
    valid. The review CLI writes no typed act: `--approve-round` spends the capture the prompt hook recorded, which
    carries its turn identity; its out-of-session and out-of-band forms are T008's. The tracked `.specify` copies of
    the decision scripts, like the dispatcher's, already lagged the source before T004 and are left to deployment.
  - **The router suites, migrated to a turn with an identity (FR-015):** `round-approval-typed-authority` called the
    router with a transcript position and no message id, the shape from before 202; each call now carries the host's
    id for that entry (the same position is a re-offer, a later one a retype), the prompt channel's calls carry the
    dispatcher's origin, and the Stop fixture's Claude entry carries its `promptId` and origin. Two cases changed
    meaning on purpose: W70's and W71's "the cross-channel double mint is OBSERVED" now assert FR-022's rule, one
    message one act across both channels, with no double mint left to observe; and the "seeing is not capturing"
    fixture writes its sighting as today's prompt hook does (with an identity), since 202's legacy check rightly takes
    a pre-update record of the same text for the message. `message-identity` and `approval-form` give Copilot's prompt
    the stand-in id its binding declares, and `message-identity` writes pre-update history as the old hook wrote it
    instead of replaying a message with no identity, which now records nothing.
  - **Re-scoped (maintainer's instruction, 2026-11-02; DRIFT-027):** T004 does the rewiring and the supersession, and
    keeps the per-round approval: the `approved for review round` act, its capture and `--approve-round`. Their
    removal (FR-010) lands with T007/T008, once the budget grant replaces them, so every review stays launchable.
    After T004's sign-off and the pin's advance, the crew checks the maintainer's first typed approval of each kind
    against the stores before relying on it.
  - **Launch and scope (DRIFT-028):** T004's own rounds launch from the pin's review script (`063e233a` until the pin
    advances). T004 leaves `scripts/internal/continuous-co-review/` unchanged, because a launch resolves its review
    engine to the worktree's copy and refuses when it differs from the pin's. `record-design-decision.ps1 -HumanTurn`
    is routed through the re-deriving writer. The acceptance "no script or `!` approval path remains" excludes the
    review CLI's out-of-session and out-of-band forms, which move to T008.

## Phase 3: US2, nothing recorded that I did not give, recorded the first time (P1)

- [X] T005 [owner: Implementer] [sp: 1.5] [US2] **Verdict pairing across a compaction.**
  - **Work:** pair a verdict-shaped reply with the durable pending-crossing record; remove the fallback to an
    older pair; a mismatched boundary is reported and records nothing.
    **Maintainer's design decision (2026-11-07, `verdict-pairing-out-of-tail`, option 4; DRIFT-043):** with the waiting
    crossing's marker in the tail, the marker pairs. Without it, the reply pairs only at its own prompt event, naming the
    target boundary, for a packet verified as shown in this session (`shown-crossing.json`: a compact SessionStart keeps
    it, any other clears it; for capture only) whose linked files are unchanged. A turn end never pairs without the
    marker and reports what it did not record. A verdict names the crossing's target, read through boundary aliases.
  - **RED:** `tests/unit/verdict-pairing.Tests.ps1`: packet, compaction, verdict returns the older pair today
    (B4F-112). Red on `8308d468`: a packet past the tail records nothing; a send-back walks back to the older pair
    with no project; `approved for tasks` crosses `before-implement`; a bare approval and a verdict the prompt hook
    never received are silent.
  - **Acceptance:** the verdict records once against the waiting boundary; `approved for tasks` while plan waits
    records nothing and is reported. A second session with no marker in its transcript, a shown record for another
    crossing, a packet never shown and a changed review target each record nothing and are reported.
  - **Trace:** FR-019, FR-020.
  - **Depends:** T003, T004.
  - **Owns:** `scripts/internal/bootstrap/HandoverStore.ps1`,
    `scripts/internal/bootstrap/ConversationCaptureAccessor.ps1`, `scripts/internal/bootstrap/HumanAuthorityStore.ps1`
    (the classifier's target check), `extensions/specrew-speckit/scripts/turn-end-store.ps1`,
    `extensions/specrew-speckit/scripts/specrew-conformance-provider.ps1` (the crossing key),
    `scripts/internal/specrew-handover-provider.ps1` and its extension twin (loading the turn-end store), their
    `.specify` copies, `tests/unit/verdict-pairing.Tests.ps1`.
- [ ] T012 [owner: Implementer] [sp: 1.5] [US2] **Audit and correlation.**
  - **Work:** an audit joining every authority record to a typed human turn; reservations cite the grant and the
    latest reset; turn identity on every record and campaign id on review records.
  - **RED:** `tests/unit/authority-audit.Tests.ps1`: a backstop-minted record with no typed turn passes today.
    **Added 2026-11-03 (maintainer's instruction):** the round-4 grant `grant-2ea3d06fc52ba0d3f381`
    (`cmp-203-beta5-stabilization-i001-round-4`) still shows its creation at 21:48 local on 2026-11-01, from the 21:47
    approval, although round 4 ran on 2026-11-02 and the approval that should authorize a relaunch is the newer typed
    one (DRIFT-019): no grant, reservation or run record names the typed turn that authorized it. The audit fails on
    that shape; the run and reservation records name the authorizing turn (a closed-format change in
    `review-authority-core.ps1`, after T008 makes a pinned launch load its review engine from the pin).
  - **Acceptance:** any record without a joined typed turn fails the audit.
  - **Trace:** FR-024, FR-041.
  - **Depends:** T004, T008.
  - **Owns:** `scripts/internal/bootstrap/*.ps1`,
    `scripts/internal/continuous-co-review/review-authority-store.ps1`,
    `scripts/internal/continuous-co-review/review-authority-core.ps1` (record formats, after T008),
    `tests/unit/authority-audit.Tests.ps1`.

## Phase 4: US3, told in the same turn (P1)

- [X] T006 [owner: Implementer] [sp: 2.0] [US3] **Not-recorded reporter.**
  - **Work:** every none-reason except `already-recorded` and `not-standalone` reports in the same turn with its
    own reason (form unreadable, writer failed, origin unconfirmed, no pending crossing, boundary mismatch, stage
    evidence absent); the report checks the store when it speaks; Claude visible line, justified stop elsewhere;
    the refusal standard; diagnosis to the drift record.
  - **RED:** `tests/unit/not-recorded-report.Tests.ps1`: an unreadable approval form records nothing and says
    nothing today (B4F-151).
  - **Acceptance:** each branch reports with its reason; a recorded approval never reports.
    **Added (maintainer's UX ruling, 2026-11-04 (19:05 local): a human answers a question when they see it, so a reply typed while the turn is still ending (Stop hook running) must just work):** when a reply cannot be used, the notice shown only to the human says so and asks them to type
    it again.
    **Added after T002's review (DRIFT-014):** a recorded round approval never gets the "nothing was recorded"
    notice (it got one 4 times on 2026-11-01).
    **Added after T002's round 4 checks (DRIFT-018), the refusal-visibility follow-up from T002 round 1 finding 1:**
    a hook refusal is written as plain text. Today a launcher refusal is a `throw` and reaches the host in pwsh's
    error view: a source excerpt, the message wrapped behind a `|` gutter, ANSI color codes, or CLIXML from
    `-EncodedCommand`.
    **Logged from the T004 live check (DRIFT-039, DRIFT-041):** (a) a boundary phrase for a boundary already
    authorized is told it is already approved and nothing is needed, never "send it again when the crossing is
    presented"; (b) the design-decision CLI never says "with the reason you gave" for a rationale the crew wrote;
    (c) the design-decision record names its evidence: it is verified against the reserved typed turn
    (`turn_identity`), so `confirmation` no longer reads `crew-declared-human-reply`.
  - **Trace:** FR-026, FR-027, FR-032 (touched refusals).
  - **Depends:** T001, T003.
  - **Owns:** `scripts/internal/bootstrap/HumanAuthorityStore.ps1`, `scripts/internal/bootstrap/HandoverStore.ps1`,
    `tests/unit/not-recorded-report.Tests.ps1`. **Widened by the build (DRIFT-046):** the visible line needs the hook
    output, so also `scripts/internal/specrew-handover-provider.ps1` and the dispatcher
    (`extensions/specrew-speckit/scripts/specrew-hook-dispatcher.ps1`), each with its twins, and `hosts/claude/host.psd1`
    (`VisibleLineField`); item (DRIFT-018) needs the launcher generator `scripts/internal/deploy-refocus-hooks.ps1` and its
    twin; items (b) and (c) need `record-design-decision.ps1` and `design-decision-store.ps1` with their `.specify` copies;
    `tests/integration/timestamp-read.tests.ps1` gains the turn identity a verified decision now needs.

## Phase 5: US1, approve a review budget once (P1)

- [X] T007 [owner: Implementer] [sp: 2.5] [US1] **Budget declaration and snapshot.**
  - **Work:** parse the plan's `## Review budget` block; validate against `co_review_max_rounds` at plan sync and at
    the snapshot (the refusal names the ceiling and `.specrew/config.yml`); write the grant fact at the
    before-implement verdict, citing the verdict entry; zero rounds when no budget is stated.
  - **RED:** `tests/unit/review-budget-snapshot.Tests.ps1`: the grant is one slot per authorization today.
  - **Acceptance:** a plan edit after the verdict does not change the grant; above-ceiling refused at both points.
    **Maintainer input (2026-11-05; DRIFT-032):** the snapshot's floor is 2 rounds (one review, one fix
    verification), so "zero rounds when no budget is stated" becomes 2; see T008.
  - **Trace:** FR-001, FR-002, FR-003, FR-008.
  - **Depends:** T004.
  - **Owns:** `scripts/internal/sync-boundary-state.ps1`,
    `scripts/internal/continuous-co-review/review-campaign-orchestrator.ps1`,
    `tests/unit/review-budget-snapshot.Tests.ps1`. **Widened by the build (DRIFT-048):** the snapshot runs in the one
    verdict writer, `Add-SpecrewBoundaryAuthorization`, so `extensions/specrew-speckit/scripts/shared-governance.ps1` and
    its `.specify` copy; the grant is a new store fact, so `review-authority-core.ps1` and `review-authority-store.ps1`;
    the hook says why a verdict was refused for its budget, so `scripts/internal/bootstrap/HandoverStore.ps1`.
    **Widened by the maintainer (2026-11-08):** FR-001 reaches new plans through the plan template
    (`templates/specify/templates/plan-template.md` and its `.specify` copy) and the planner guidance (the planner
    charter in `extensions/specrew-speckit/squad-templates/` and in `templates/squad/`, the planning ceremony, and their
    deployed copies under `.specify/` and `.squad/`).
- [ ] T008 [owner: Implementer] [sp: 5.0] [US1] **Orchestrator loop on the budget.**
  - **Carries from T004 (DRIFT-027):** removing the per-round approval (FR-010): the `approved for review round` act
    in the classifier, its capture writer and `--approve-round`, in the same change that makes the grant the only
    launch authority. Also from T004 (DRIFT-028): the review CLI's out-of-session form and its out-of-band
    `--authorization-ref ... --ack-reason` form; and, before T008 changes `continuous-co-review`, a pinned launch must
    load its review engine from the pin.
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
    **Evidence added 2026-11-02 (T003):** after T003's commit, mid-iteration with the review planned after T013,
    Stop blocked the turn with "your last review no longer covers these files" and asked the crew to request
    `approved for review round`: a stop whose only purpose was a round (FR-006).
  - **Maintainer input (2026-11-05; DRIFT-032):**
    1. The planned round budget has a floor of 2: one review round plus one fix-verification round, approved once
       with the plan. A plan that states fewer, or none, gets 2 (T007 snapshots it).
    2. `approved for allowance reset` grants exactly one "fix + verify the fix" cycle, and is not a separate round
       approval.
    3. The scoped fix round (T009, FR-013) comes back into this iteration if possible: an unscoped verification
       round keeps finding new rare cases in code the fix did not change (rounds 8 and 9).
    4. B5F-017 (findings that state a concrete failure scenario demoted to notes for having none) is fixed before the
       automatic cycle is trusted; otherwise the cycle signs off on unfixed findings.
  - **An empty host order and FR-006(d) (from T007, DRIFT-048 decision 2):** a grant whose plan stated no host order
    (`host_order: []`, `host_order_stated: false`) approves exactly one host: the reviewer the engine picks for the
    first round (a host other than the code's writer), recorded on that round's spend as the approved order. An empty
    order never means "any host". Every other host is outside the approved order, so when `infra_failure_cap`
    consecutive infrastructure failures exhaust that one host, the cycle stops at (d) and names the next host the
    engine would try; `allow reviewer <host>` continues with it. **Acceptance:** with an empty order, the first round
    runs on the engine's pick without a stop; two infrastructure failures on it stop at (d); no second host is invoked
    before `allow reviewer`.
    **Carried from T004 (B5F-029 findings 2 and 3; DRIFT-039):** the approval withdrawal takes the round slot lock and
    revokes only its capture; a superseding partial sign-off reaches the round-approval consumption step. The same
    withdrawal writer records `withdrew_observed_at` as ISO 8601 with its offset, not the `[string]` of a parsed date
    (`11/07/2026 00:05:09` reads as 7 November or 11 July; DRIFT-041).
    **Added (maintainer, 2026-11-07; DRIFT-045):** recording one design decision rewrote another's dates. Recording
    `verdict-pairing-out-of-tail` (`1782a5a8`) changed B5F-029's record in `design-decisions.json`:
    `turn_observed_at` and `recorded_at` went from `...+00:00` to `...+02:00`, the same instant in local time.
    `record-design-decision.ps1` writes a new record in UTC; the earlier one came back in local time. Fixed with
    the date above: a date is written once, ISO 8601 with its offset, and kept as written.
    **Acceptance added:** a plan budget below 2 snapshots as 2; a reset grants one fix round and one verification
    round; a finding that states its failure scenario keeps its severity, so the loop does not end clean on it.
    Recording a new design decision leaves every earlier record byte-identical.
  - **Trace:** FR-003, FR-004, FR-005, FR-006, FR-007, FR-009, FR-010, FR-011, FR-043.
  - **Depends:** T007.
  - **Owns:** `scripts/internal/continuous-co-review/*.ps1`, `tests/unit/review-budget-loop.Tests.ps1`,
    `extensions/specrew-speckit/scripts/record-design-decision.ps1` (and its `.specify` copy).

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
    **Added (maintainer's UX ruling, 2026-11-04 (19:05 local): a human answers a question when they see it, so a reply typed while the turn is still ending (Stop hook running) must just work):** the turn-end check never forces a re-render of a question already shown; a human may already be
    answering it.
    **Evidence added (DRIFT-018):** 22:07, 2026-11-01, a conversational reply carrying the declared question
    reworded was blocked with "your reply is missing these lines from the message you declared. Add them as
    written", and the line was sent again verbatim. **Again 2026-11-02 (T001's Copilot step):** the reply
    carried the declared "What to look for" paragraph split into a bold lead and two bullets, word for word
    otherwise; Stop blocked the same way and the paragraph was sent a second time.
    **Added (maintainer, 2026-11-10; DRIFT-054): a reply that follows a stop-hook block is recorded as a turn end.**
    Today the conformance provider judges the turn, deletes its token and steps the counter at Stop, and a provider
    that runs after it (the co-review navigator) blocks; the host continues the turn with no prompt event, so the
    reply to the block has no live token and cannot be declared, and its own Stop counts it as an undeclared turn.
    After T014 the four review stops block the same way, so every reply after one would go unrecorded. **RED first:**
    through the real dispatcher with a deployed binding, a declared turn whose Stop is blocked by a later provider,
    then a reply that declares: the declaration is accepted and recorded for that continuation (today it is refused,
    "matches no live session"). The case also pins that the counter and the token agree on which turn the
    continuation is. Also: each Stop leaves a history line (turn judged, declaration kind, token consumed or kept,
    counter step, the provider that blocked, if any), the record DRIFT-054 found missing. **Ordering:** built before
    T014 advances the pin. **How (maintainer ruling 2026-11-10):** a rule about ordering, not a special case for the
    navigator - a turn's token is used up, and its counter stepped, only after every check in that Stop has passed, so
    a block from any later check keeps the turn and its token. The RED case blocks with a check other than the
    navigator as well, so a navigator-only fix cannot pass it.
  - **Trace:** FR-046; DRIFT-054.
  - **Owns:** `extensions/specrew-speckit/scripts/specrew-conformance-provider.ps1`,
    `extensions/specrew-speckit/scripts/turn-end-store.ps1`, `extensions/specrew-speckit/scripts/declare-turn-end.ps1`,
    the skill and refocus sources that name the piped draft, `tests/unit/presented-check.Tests.ps1`.

## Phase 7: Evidence and deployment

- [ ] T013 [owner: Implementer] [sp: 1.5] **Test evidence suite.**
  - **Work:** no-human-turn fixtures for every mint path; non-approval phrase fixtures; cross-host replay with
    recorded payloads, including a compaction; budget economics fixtures; all census-selected and in a PR lane.
    **Added (maintainer, 2026-11-07; DRIFT-043):** the Codex replay covers T005's out-of-tail path: a recorded Codex
    Stop payload over a rollout transcript writes the shown record, and a verdict with the packet out of the tail
    records. `verdict-pairing` case 13 proves the provider reads the rollout format; it does not prove a real Codex has
    the reply in its rollout when Stop fires. If it does not, the shown record is not written and Codex refuses in this
    case and the human retypes; measure it on the iteration-002 three-host walk.
    **Added (maintainer, 2026-11-07; DRIFT-045, B5F-032):** the per-suite home fixes. Each suite that runs init or update
    sets its own redirected home, as `crew-charter-ownership` does. The crew's sweep runner sets one home for every
    suite and lane it starts, so a sweep no longer depends on these fixes; lanes the review engine runs pass only
    their `env_refs` and do not get it.
  - **Acceptance:** the suites run green in the census selection and a PR lane. With no home override set, a run of
    the suites that run init or update leaves the real home's hook files byte-unchanged.
  - **Trace:** FR-042, FR-043.
  - **Depends:** T003 to T008, T011, T012.
  - **Owns:** `tests/unit/**`, `tests/integration/**`.
- [ ] T014 [owner: Implementer] [sp: 1.0] **Deployment point and the Claude-only capture check.**
  - **Work:** after the iteration's review sign-off: advance the pin to the signed-off commit and sync the
    `.specify` mirror from it in one commit; then the maintainer's check (a verdict after a compaction, a quoted
    phrase, a pasted phrase), recorded.
    **Added (maintainer, 2026-11-07; DRIFT-043):** a real compaction normally leaves the marker in the tail, so that
    check can pass through the marker path. Record which path captured the verdict (the ledger's `evidence_source`:
    `hook-captured-from-transcript` is the marker, `hook-captured-user-prompt` is the out-of-tail path on Claude), and add
    one real run with the packet more than 500 transcript lines back when the verdict is typed.
    **Added (T006, DRIFT-046):** the visible line (Claude `systemMessage`) reaches the live hooks with the pin's host
    bindings, so the pin advance carries it. The plain-text launcher refusals change the launcher's bytes, so they reach
    the hooks only when the hooks are redeployed, and that rewrites the real home's per-machine launcher and hook files:
    the maintainer is asked before that redeploy. Check: one typed `drop finding F1` with no review stop waiting shows
    the not-recorded line under the prompt.
  - **Acceptance:** `iterations/001/capture-check.md` records the verdict once in its own turn and nothing for the
    other two. T005's out-of-tail path counts as verified only when the real run records `hook-captured-user-prompt`.
  - **Trace:** FR-045.
  - **Depends:** the review sign-off.
  - **Owns:** `specs/203-beta5-stabilization/iterations/001/**`, `.specify/extensions/specrew-speckit/**`.

## Moved to iteration 002 (plan verdict, 2026-10-31)

- [ ] T009 [owner: Implementer] [sp: 2.0] [US1] **Scoped late-fix round (DA-7).** **Maintainer input (2026-11-05;
  DRIFT-032): back into iteration 001 if possible, after T008**, because an unscoped verification round keeps finding
  new rare cases in unchanged code (rounds 8 and 9). **Maintainer input (2026-11-07; DRIFT-038), replacing "the
  reviewer receives only the listed paths (sparse checkout)":** scope what the round
  judges, not what the reviewer sees. The reviewer reads the whole tree and is told to judge only the fix (the
  changed lines and any code that relies on what changed); findings in that zone gate, findings in unrelated
  unchanged code are recorded as non-gating follow-ups. Labelled `scoped`; coverage rule. **Acceptance added:** a
  fix whose break lands in an untouched caller is reported as gating (round 13's finding 2 as the shape); a
  finding in unrelated unchanged code is a non-gating follow-up. Trace: FR-013. Owns:
  `scripts/internal/continuous-co-review/worktree-*.ps1`, `review-target-port.ps1`, `tests/unit/scoped-round.Tests.ps1`.
- [ ] T010 [owner: Implementer] [sp: 1.5] [US1] **Host-reported token usage.** Per round and at sign-off; "not
  reported by <host>" otherwise. Trace: FR-012. Owns: `scripts/internal/continuous-co-review/review-*-harness-port.ps1`,
  `review-progress-projection.ps1`, `tests/unit/review-usage.Tests.ps1`.

## Traceability

| Requirement | Tasks |
| --- | --- |
| FR-001, FR-002, FR-003, FR-008 | T007 |
| FR-004, FR-005, FR-006, FR-007, FR-009, FR-011 | T008 |
| FR-010 | T008 (moved from T004, DRIFT-027) |
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
