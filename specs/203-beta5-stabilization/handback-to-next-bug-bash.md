# Hand-back from Feature 203 to the Next Bug Bash

**Written**: 2026-11-18, feature 203 iteration 002, on the reviewer session's routine ruling. **Source of the items**:
feature 206 handed 13 bug-list items to 203 by name (206's `specs/206-bug-bash/follow-up-seed.md`, "With feature 203
(13)", and `specs/206-bug-bash/iterations/001/handover-to-203.md`, HO-206-1 to HO-206-10). 206's seed is at its
closeout gate and stays as written, so this note is where the next bug bash finds what 203 gives back.

**State checked**: on 203's local tip `597c653c1` (2026-11-18). "Fixed" means fixed on the 203 branch: it reaches main
only with 203's merge.

## Handed Back (5)

None of these is fixed or planned in 203. Each line gives 206's item number and hand-over id, the reason, and its 203
finding where one exists.

- **Item 9 (HO-206-6), the macOS review-runtime fault-matrix case: the process-group membership probe failed.**
  B5F-052 (`docs/beta5-findings.md`) proposes a task for it, but no iteration 002 task covers it.
- **Item 14 (HO-206-9), `review-posix-runtime.Tests.ps1:126`: two stream drains took 360 ms against a 250 ms budget
  on macOS.** B5F-051 site 2, recorded by B5F-061. Iteration 002 puts the rest of B5F-051's timing census out of scope.
  Commit `eee6946a6` loosened another case of the same suite (lines 103 and 113), not line 126.
- **Item 27 (HO-206-10), `journal-fault-injection.tests.ps1` on macOS: concurrent Stop dispatchers exited non-zero and
  journaled nothing.** 203 records only the suite's timing sites (B5F-051 site 1, and a 1,500 ms sleep used as a
  barrier); the dispatcher failure itself has no 203 record. Its home in 203's spec (US7, SC-007) moved to the follow-up
  feature (203 T029).
- **Item 42, a one-line approval with instructions (`approved for <to> - <instructions>`) is not captured, while the
  bare phrase is.** B5F-044 fixed approvals whose instructions run onto a second line or sit inside a paste; 206's
  one-line case, journaled with an empty `leading_text`, has no 203 record and no 203 test.
- **Item 62, the campaign reviewer is told an absolute deadline but has no way to read the time.** B5F-090 says
  "candidate, not planned"; no task covers it.

## Fixed in 203 but Thinly Guarded (Test Candidates)

These are fixed on the 203 branch, but the guard is weaker than the finding. Each is a candidate for a test in the
next bug bash.

- **Item 59, the retry message says the approval is "NOT spent" while the spend record says spent.** Fixed by 203
  T008's redesign (iteration 001 DRIFT-052, item 3: per-round approvals removed, FR-010), so the two records cannot
  disagree. No test names this case.
- **Item 60, the automatic retry after a partial result is blocked by the first attempt's own pause.** Fixed by the same
  redesign: one launch per invocation and no automatic retry (`scripts/specrew-review.ps1:1375-1377`). No test names
  this case.
- **Item 58, a partial review's findings are dropped from the pause record and the packet says it "found nothing".**
  Fixed by T008 step (iii) (RED `047cd6a0e`, fix `8b98e2ef7`; iteration 001 DRIFT-052, "Partial findings"): they stay
  open until a later complete round or the human's typed defer or drop. Guarded only by the partial case of
  `tests/unit/review-loop-stops.Tests.ps1`, not by 206's sequence.
- **Item 3 (HO-206-1), `empty-result-retry.Tests.ps1` fails intermittently.** Fixed by 203 T017 (RED `7ddafa6d6`, fix
  `56ec80966`: the agent invoker waits for the child's output after it exits), guarded by
  `agent-invoker-output-drain.Tests.ps1` and 50 green runs. The cause is "likely", not proven, and no CI recurrence
  check is recorded since the fix.
- **Item 7 (HO-206-2), the Windows review-runtime job hung past its timeout and left no log.** 203 T015 made it
  diagnosable (each suite has a named 300 s limit, and the CI step its own timeout below the job's; guard
  `bounded-suite-runner.Tests.ps1`). Why the job hung is still unexplained.

## Found in 203, Candidate (Not Planned)

- **B5F-091, the task writer re-stamps a done task.** `Set-TaskStatus -Status done` on a task already done rewrites
  its `completed_at` to the time of the call and moves state.md's "Last Completed Task" back to it (iteration 002
  DRIFT-036). A done-to-done call should be a no-op, or keep the time and say so. Not a 206 item; found by 203 on
  2026-11-18.
- **Hook commands of other hosts whose missing-launcher refusal is not plain Specrew text (not covered).** 203 fixed
  Claude's generated command (guarded-project-encoded; iteration 002 DRIFT-038, `4d750cfc2`). Not covered, by host:
  - **Codex, Copilot and Cursor** (`launcher-file`) run the per-machine launcher with `pwsh -File`, so a missing
    launcher gets pwsh's own `-File` error.
  - **Antigravity's** `launcher-encoded` command (`& '<launcher>' ...` through `-EncodedCommand`) has no
    missing-launcher guard, so pwsh's error reaches the host the way Claude's throw did. Same class, separate line
    (`deploy-refocus-hooks.ps1`, the `launcher-encoded` case).

  Placement is the maintainer's, through the reviewer session; not built in 203.
- **One "new test file" lane.** Twice on 2026-11-18 a new test file passed its own batch and was then caught by a
  repository-wide guard the batch did not run: the lane-naming guard (DRIFT-035), then the home-isolation guard
  (DRIFT-040). The guards that judge test files are listed in iteration 002's DRIFT-040: lane naming, home isolation,
  the host-coupling firewall, and CI's PSScriptAnalyzer errors. A single lane that runs all four makes the miss
  impossible. Not built in 203.
- **Tests added on main before 203 merges.** Any test that calls `Add-SpecrewBoundaryAuthorization` directly with a
  captured evidence source needs a cited typed turn (`tests/support/cited-typed-turn.ps1`), because 203's FR-022
  refuses a captured verdict without one. Any test that names a hook-writing entry point (the updater, init, start, the
  hooks command or the deployer) needs a private home or a `# specrew-test-home: not-a-writer - <why>` line, because
  203's `test-home-isolation` guard requires it. Both were added to main's tests at 203's merge of main (T030, DRIFT-044).
- **For proposal 166: two home-safety rules for start-running tests.** 206's lane guard
  (`every-suite-is-named-by-a-lane.tests.ps1`: each start-running script points `SPECREW_USER_PROFILE_PATH` at a temp
  file) and 203's `test-home-isolation` (a private home or the not-a-writer line) both guard tests that run Specrew's
  entry points. They should become one rule.
- **A reviewer's authorization reference is never checked against a record (bug-bash candidate).**
  `Test-ContinuousCoReviewReviewerAuthorization` (`reviewer-authorization-gate.ps1`) treats any non-empty
  `authorization_ref` in `.specrew/reviewer-hosts.json` as an explicit authorization and never resolves it. At 203's
  second merge of main, 203's workshop hash and 205's `workshop-205-workshop-lens-order` both satisfied it (iteration
  002 DRIFT-045). Not fixed in 203. For proposal 166, the same catalog is per project and each feature's workshop
  rewrites it, so the last merge wins.
- **Main's workshop tests need a findable typed turn before 203 merges.** A workshop receipt is used only when it names
  a typed turn that can be found, whose text it matches (203 T013, B5F-066). Fixtures that write a receipt with no turn
  (`Write-SpecrewWorkshopAuthorityReceipt` without `-TurnIdentity`, or a hand-written row) are refused on 203. Two of
  205's were adapted at 203's second merge of main (iteration 002 DRIFT-046).
- **A test named only by a parked lane is never run, so a parked lane can hide a red.** On main,
  `tests/unit/closeout-records-on-approval.tests.ps1` is red (it lifts a validator rule by text, and 206's
  `Add-ValidatorStopMessage` is missing from the lift), and only the parked lane `f202-i003-suites` names it. No CI
  job, active lane or release list runs it. 203 fixed it on its branch (DRIFT-046); main keeps the red until 203 merges.
  Candidate: a guard that every parked lane's suites also run somewhere, or a CI step that runs the parked lanes.
- **An absolute wall-clock budget inside a per-push CI step.** `tests/integration/feature-018-render-budget.ps1` gives
  one dashboard render 1,500 ms. It took 2,113 ms in 203's sweep of `f30f5ea3d`, and 1,894 then 1,292 ms alone on the
  same revision; it was green in the sweep before, with the same renderer. 206 put it in Specrew CI's per-push step
  for the script suites (F-206 T015), so a slow runner can fail a push on the margin. It is already 206's bug-list item
  11 ("sits on its 1.5 s budget"). Wanted: a relative budget, a retry with the median, or its own non-blocking job
  (iteration 002 DRIFT-047).
- **The cap's refusal names the wrong requirement for a packet block.** When a boundary packet is refused three times
  in a row, the fourth Stop is released with "verdict marker still absent or wrong", whatever the packet's actual
  problem: the cap's subject falls through to that label (`specrew-conformance-provider.ps1:1972`). In 203's Linux red
  the problem was a review link, and the message pointed at the marker. Wanted: the cap names the requirement that
  blocked (iteration 002 DRIFT-048).
- **The engine writes four-slash file URLs on Linux and macOS.** Six sites build `'file:///' +` an absolute path
  (`refocus.ps1:141` and `:240`, `design-analysis-gate.ps1:1373`, `lens-applicability.ps1:490` and `:505`,
  `validate-governance.ps1:5220`), which on a POSIX path gives `file:////tmp/...`. 203's review-link reader now reads
  that form (DRIFT-048); other readers, a host's link handling and a human's click may not. Wanted: one URL writer that
  gives `file:///tmp/...` on POSIX and `file:///C:/...` on Windows.
- **A Windows sweep cannot see a Linux-only red, and a suite can reach a feature's Linux CI for the first time only
  through a merge.** `agent-led-workshop-replay` entered Specrew CI's per-push gate with 205's named steps; 203's own
  pushes never ran it on Linux, and the merge of main ran it against 203's engine there first, red (DRIFT-048). Wanted:
  a Linux run of the gate's suites before a feature's merge push, or a way to run them locally (203 used a WSL copy of
  the tree).
- **`specrew init` checks dependencies before it checks for a non-empty workspace** (`specrew-init.ps1:338`, then
  `:430`). So a machine without uv or Node never hears the more useful message, that the target folder is not empty;
  `brownfield-conflict-handling` fails that way on such a machine (iteration 002 DRIFT-048). Wanted: the workspace
  check first, or both reported together.
- **`MarkerAtomicWrite.Tests.ps1` red once on Linux under load** ("after the race the marker is a single VALID object
  (no persistent corruption)"), 3 of 3 green alone (iteration 002 DRIFT-048, WSL). If it is real and not the test, a
  marker written by concurrent writers on Linux can be left corrupt. That is session-state damage a later hook would
  read. Wanted: a run of the race under load on Linux to tell the two apart.
- **`validator-hardening-iteration2` runs 16 to 25 minutes against a 1,500 s limit.** It took 951 and 976 s in full
  sweeps, timed out at 1,500 s in the sweep of `8bd3d15ee`, and took 1,491 s alone. Each approval-reuse case takes about
  315 s and each closed-iteration case about 96 s (iteration 002 DRIFT-048). It sits in the release list only, in no
  per-push CI step. Wanted: split it by case family, or share the validator fixture runs, so that it sits well inside
  its limit. The investigation found variation, not a regression: alone, the approval-reuse cases took 189 to 317 s each
  across four runs while the closed-iteration cases held at about 95 s (B5F-094, with the per-case table).
- **A committed feature claim declines a collaborator's `specrew start`, and per-push CI meets it** (B5F-095,
  iteration 002 DRIFT-049). `project-path-resolution-regression` builds a fresh checkout as a collaborator receives it.
  On a branch whose tracked `.squad/active-features.yml` claims the feature for someone else, start declines with no
  override, so Specrew CI's Linux gate is red on 203 and would be on any feature with a committed claim. F-051 commits
  claims on purpose, 205 left its claim committed and unreleased, 206 never committed one, and main's file holds 11
  never-released claims of merged features. Wanted: the maintainer's rule on whether claims belong in the tree, and on
  whether a collaborator may start or take over a claimed feature; proposal 166's ground.
  The maintainer's decision (2026-11-22): 203's change is test-only. The suite's fixture drops its own claim, and a
  decline case pins the decline (iteration 002 DRIFT-050); the rule questions stay open.
- **A `specrew start` declined on someone else's claim writes before it declines** (B5F-096, iteration 002
  DRIFT-050). First-time setup and the skill catalog repair run before the claim check, so the decline leaves the
  checkout dirty and the profile written. The failing test for the fix, to add to `project-path-resolution-regression`'s
  decline case: snapshot every file under the claimed fixture (its `.git` folder excepted, ignored files included) and
  under the redirected home, by path and SHA-256, before the start; after the decline, assert that no path was added,
  removed or changed in either. Today it is red on 179 fixture files and the profile; on a full checkout, not measured,
  the profile, `.specrew/runtime`, the version-check cache and 12 tracked files in `.squad` and `.github` would
  plausibly remain. The message "Start declined; no active session lock was recorded." is true and reads as "nothing
  happened": proposal 166 (a declined start on someone else's claim leaves the checkout dirty) and proposal 142's
  amendment (a refusal says what state it left).
- **`project-path-resolution-regression`'s decline case reads the records, not only the code** (iteration 002
  DRIFT-050). The case claims the feature the copied `.squad/identity/now.md` names, and goes red with "the copied
  identity file names no feature, so there is nothing to claim" when it names none. It holds today: the file names
  203 on 203's branch and 206 on main. If a closeout ever leaves the identity with no feature, this per-push suite
  turns red on that state of the records, with no code change; that is the cause to look for first.
- **`project-path-resolution-regression`'s update --info case writes to the real npm cache on every run**
  (iteration 002 DRIFT-050). It runs `specrew-update.ps1 -InfoMode` with the real home, which runs
  `npm view @bradygaster/squad-cli version` with the real `.npmrc` and leaves a debug log in
  `%LOCALAPPDATA%\npm-cache\_logs`. npm's rotation then drops the oldest log. The decline case in the same suite
  redirects the home. `test-home-isolation.Tests.ps1` cannot see it: it looks for hook-writing entry points without
  `SPECREW_USER_HOME_OVERRIDE`, and never for npm, `.npmrc` or `LOCALAPPDATA`. It also passes this file twice, on its
  `not-a-writer` line and, since this change, on the decline case's own `SPECREW_USER_HOME_OVERRIDE`, which covers
  that one case and not the file. Wanted: the case's npm calls given a private cache and user config, and a guard that
  sees npm calls.

## Seen on a released install, 0.40.0-beta41

Defects the maintainer met on a downstream project running the released 0.40.0-beta41, passed to the next bug bash
("Desktop H, I and J: pass them" and "Desktop K: pass it", typed in the reviewer session at 02:48 and 03:10 local on
2026-11-19, relayed). Each line says whether 203's merged tree (`f30f5ea3d`) still has it, from a short read; none is
fixed in 203.

- **H1. A reviewer host whose command on PATH is only an npm shim is refused at launch, after the preflight passed.**
  `Resolve-ReviewWindowsProcessLaunch` throws `runtime-command-shim-unsupported:<command>` for a `.cmd` that is not the
  one accepted PowerShell form. Two projects hit it with codex. Wanted: the preflight checks launchability, and the
  refusal names the fix (a native executable first on PATH). **Still in the merged tree: yes.** The Windows port's
  preflight checks only the job-object capability and the snapshot; the resolver runs at launch
  (`review-windows-runtime-port.ps1:164`).
- **H2. A validator message that misleads.** "plan.md status is stale: retro.md exists" reads as "the Status must be
  retro" where the engine itself advances plan.md's Status at each approval and the agent may not edit it. **Still in
  the merged tree: yes.** The text is unchanged (`validate-governance.ps1:5380`); 206's T034 exempts the pending-approval
  case but not the wording.
- **H3. The cited-run freshness rule judges a closed, sealed iteration against the live tree,** so a later commit makes
  a sealed iteration fail. The review preflight skips the rule (`SPECREW_REVIEW_PREFLIGHT`); a hand run of the validator
  does not. **Still in the merged tree: probably yes.** By a short read, the rule's only exemption is the preflight
  marker (`validate-governance.ps1:1315-1349`); not run.
- **I. A completed design workshop cannot be reopened for a scope revision.** `confirm-workshop-agenda` refuses unless
  the agenda is pending confirmation, and `repair-workshop-controller-state` throws the bare code
  `workshop-repair-only-pending-state-supported`; the only route is a new feature record. Wanted: a governed
  scope-revision path, and a refusal in plain words. **Still in the merged tree: yes**
  (`confirm-workshop-agenda.ps1:130`, `repair-workshop-controller-state.ps1:106`).
- **J1. `specrew start` crashes in a fresh worktree of a governed project.** With no start context and no saved start
  prompt, the session state comes from the identity file or the decisions log; the decisions log's state has no
  `feature_path`, and `Get-SpecrewLateBoundaryIssues` reads `$SessionState.feature_path` under strict mode ("The
  property 'feature_path' cannot be found on this object"). **Still in the merged tree: yes, by reading**
  (`session-recovery.ps1`, strict mode at :1; the decisions state, T031's reader included, carries no `feature_path`).
- **J2. A feature created in a second worktree cannot receive typed-reply receipts from the session that created
  it,** because the session's captured turns belong to the first folder; the workshop then refuses "no typed human
  reply receipt" and nothing says why. **Still in the merged tree: not checked** (it needs two worktrees).
- **K. A second feature cannot begin while another feature is open in the same folder.** The most serious of the set:
  with I and J1 it leaves no governed route for a mid-feature scope revision on the release. Wanted: `--resume-feature`
  switches the session's feature (or refuses and says why); the workshop hook resolves the feature of the open workshop
  question, not the last synced feature; a governed "park this feature, start another" step. The same assumption as
  203's T031 reader (one current feature per folder); proposal 166's ground.
  - **K1.** `specrew start --resume-feature <other>` keeps the session's old feature_ref, boundary and iteration and
    replaces only feature_path, so the start context names feature A with feature B's path; it exits 0 and says
    nothing. **Still in the merged tree: yes** (`specrew-start.ps1:3376-3386`).
  - **K2.** The prompt hook takes the open workshop question's feature from the session's feature_ref and falls back to
    the branch only when it is blank, so feature B's pre-specify question is never registered and the agenda refuses
    "Product-domain has no typed human reply receipt" with nothing naming the cause. **Still in the merged tree: yes**
    (`HandoverStore.ps1:1874`, `specrew-bootstrap-provider.ps1:707`).
  - **K3.** Only the new feature's first boundary sync moves the anchor, and it comes after the workshop that needs it.
    **Still in the merged tree: not checked separately** (it follows from K1 and K2).
  - **K4.** On the recovery prompt after a branch switch: option A re-anchors to the old feature over the
    `--resume-feature` given, option B drops the resume, and only `--recover` keeps the named feature, which then gives
    K1's mixed state. **Still in the merged tree: yes, by reading** (`Resolve-SpecrewRecoverySelection`); the no-console
    loop of the sighting is 206's fix, merged into 203.
- **L. The boundary gate's working-tree refusal** ("Desktop L: pass it", typed in the reviewer session at 04:33 local on
  2026-11-19, relayed).
  - **L1.** The refusal gives a count and no paths: "The boundary tree has 8 uncommitted product/methodology path(s);
    commit or dispose them before rendering a packet". The check classifies every path but prints none, and saves no
    per-path report. Wanted: the paths in the message, each with its class. **Still in the merged tree: yes**
    (`gate-preflight.ps1:208`; the check's evidence holds the classified records, the message does not print them).
  - **L2.** `specrew start` writes the selected host's agent files (for codex, five `.codex/agents/*.toml`, "Crew
    runtime synced") into the project, untracked and unignored, and the gate counts each as a product path, so a start
    run alone makes the next boundary sync refuse. Wanted: the start's runtime files are ignored by the project or
    classed as runtime by the gate; the Claude and Copilot hosts checked for the same. Proposal 166's ground.
    **Still in the merged tree: yes, by reading** (`specrew-start.ps1` runs `Invoke-CrewBootstrap` for the selected host
    on every launch; no ignore rule; the gate does not class host agent folders as runtime). It does not show in this
    repository only because its `.codex/agents`, `.claude/agents` and `.github/agents` are tracked.
  - **L3.** The rule that phase work is committed before a boundary sync is one line each in the coordinator
    governance text and the implementer charter, and nowhere near the sync command; the opposite rule (the engine's
    bookkeeping stays uncommitted until the verdict) is easier to remember and gets over-applied. Wanted: the sync's
    refusal says which paths are the agent's to commit and which are the engine's to leave. **Still in the merged tree:
    not checked.**
- **M. The review command** ("Desktop M: pass it", typed in the reviewer session at 21:18 local on 2026-11-19,
  relayed). M2 to M4 are the class that proposal 142's amendment addresses (every refusal names its governed repair).
  - **M1. Reviewer majors cannot gate.** The release does not ask the reviewer for a failure scenario, and the engine
    demotes any major without one ("[demoted to minor: no concrete failure scenario, so it cannot gate; reported as
    major by the reviewer]"). On two downstream projects over two weeks this was most findings of most rounds: 14 of 18
    and 12 of 14 in the latest rounds. Among them were a revoked membership's refresh token working again after the
    member was re-added, a public service identity able to read another site's sign-in secret, and a required denial
    audit that production never reaches. They were fixed because the humans read the reports, not because a gate held.
    This is the strongest downstream sighting of 206's bug-list item 61, and a reason for 203's fix to reach a release
    soon. **Still in the merged tree: no.** `d3ab3f21c` (203 T008) is in it: the prompt asks for the literal
    `Failure scenario:` clause (`reviewer-candidate-prompt.md:51`, `worktree-reviewer.ps1:1171`), and a stated scenario
    keeps its severity. The demotion of a major *without* one remains (`review-result-ingestor.ps1:193`). A question of
    its own for the next bug bash: should such a major be demoted silently at all, or returned to the reviewer?
  - **M2. `specrew review --iteration 003` from PowerShell is refused with the bare code
    `review-campaign-active-iteration-unresolved`.** PowerShell binds the bare argument as the number 3, and the
    identity check wants a string of three or more digits. Leaving the argument out, or `--iteration=003`, works. The
    same function gives a plain message for a missing feature and none for the iteration. **Still in the merged tree:
    yes** (`specrew-review.ps1:332` keeps the argument as passed; `review-authority-core.ps1:316` requires a
    `[string]` matching `^[0-9]{3,}$`; `review-campaign-orchestrator.ps1:2673` throws the bare code).
  - **M3. "allowance-exhausted" with a typed round approval captured and unspent: the output does not say that
    `--approve-round` turns it into a round.** **Still in the merged tree: no, not in this form.** 203's T008 removed
    `--approve-round` (the budget approved with the implementation pays for the rounds; `specrew-review.ps1:340`
    refuses the flag in plain words), and the allowance-exhausted text now names the typed reset reply
    (`specrew-review.ps1:1597-1604`).
  - **M4. "verification-command-failed:<id>:diagnostics-require-command-scoped-disclosure" without the derived
    diagnosis on the console** (exit code, duration, timed out or not, the environment names the plan allowed). The
    cause in that run was a test that failed only in a clean Windows checkout (a line-ending assumption), found only by
    running the command by hand. **Still in the merged tree: not checked in full.** The orchestrator builds the
    diagnosis beside the sealed reason (`review-campaign-orchestrator.ps1:495-501`) and carries it into the round's
    outcome (`:2265`, `:2437-2480`); whether it reaches the console on this path was not traced. **Seen on 203's pin
    too** (`da78b600`, 2026-11-23, round 1's first launch, iteration 002 DRIFT-052): the diagnosis reached neither the
    console nor the run's `result.json`; the failing suite was never named, and the relaunch passed.

- **N. The workshop checkpoint and the workshop repair in a later iteration** ("Desktop N: pass it", typed in the
  reviewer session at 02:28 local on 2026-11-23, relayed). In a downstream project's third iteration, the agent
  asked the human a design question and tried to save the answer with the feature-level lens checkpoint
  (`confirm-workshop-lens.ps1 -FeatureRef`). The checkpoint refused at its transition check: "The workshop plan is not
  in a state where the '<lens>' discussion can be closed. Confirm the workshop agenda first (or ask for the plan to be
  repaired) ...". The agent followed that to the repair command, which stopped on a missing version field. That
  project's feature-level `lens-applicability.json` has `workshop_intake`, `confirmation_required`, `selected`,
  `agenda`, `product_domain_record` and `workshop`, and none of `schema_version`, `agenda_contract`,
  `human_turn_contract`, `agenda_status` or `agenda_confirmation`. Nothing in the project changed, and the human's
  decision was intact. N1 to N4 are the class proposal 142's amendment (A1) addresses: a refusal names its repair and
  the state it found, and a repair says what it will discard. N5 is proposal 177's ground (the workshop skill and what
  its results feed), not proposal 140's (the reviewer's instructions). Neither script has changed on 203's branch or
  on main since feature 202, so 205's reordering of the workshop lenses did not reach them.
  - **N1. The repair crashes where it should refuse.** It runs under `Set-StrictMode -Version Latest` and reads
    `$state.schema_version` before its own contract check, so a state file without that property throws the
    language's property error, not the script's token `workshop-repair-state-contract-invalid`. A one-line check under
    the same strict mode, on an object without the property, throws `PropertyNotFoundStrict` ("The property
    'schema_version' cannot be found on this object"). The console text from the downstream run was not seen.
    **Still present on main** (`repair-workshop-controller-state.ps1:11` and `:100`).
  - **N2. Nothing says the repair is feature-wide and resets everything.** Applied, it overwrites the feature's
    `lens-applicability.json` with the canonical empty pending state (`selected`, `agenda` and `workshop` empty), and
    `discarded_workshop` lists every workshop key. Its message says "I can return only the unfinished technical agenda
    to its pre-confirmation state". It supports only schema 1.1 with `agenda_status` `pending-confirmation`, takes no
    iteration (its parameters are `-ProjectRoot` and `-FeatureRef`), and keeps only files under
    `specs/<feature>/workshop` as preserved records, so an iteration's workshop notes are outside its list. **Still
    present on main** (`:3-8`, `:56-70`, `:100-106`, `:136-154`, `:210`, `:271-273`).
  - **N3. The checkpoint's refusal recommends that repair.** For a technical lens, "Confirm the workshop agenda first
    (or ask for the plan to be repaired)" sends an agent in a later iteration to a command that would reset the
    feature's workshop state or crash. The refusal does not say which state it found or that the scope is the feature.
    A related branch already avoids this for a confirmed agenda (B4F-030, `:175-180`). This transition branch does not.
    **Still present on main** (`confirm-workshop-lens.ps1:113-125`).
  - **N4. No path for a controller file in the older shape.** A feature whose `lens-applicability.json` predates schema
    1.1 can use neither the checkpoint nor the repair, and nothing migrates it or names the cause. **Still present on
    main, by search:** the only `schema_version` check over this file in the workshop scripts is the repair's, and
    no migration of the older shape was found. Not traced in full.
  - **N5. The skill does not say plainly that the lens checkpoint is not the tool in a later iteration.** It gives the
    authority per scope (the feature-level file at intake, the iteration's at design analysis) and the Co-Design
    Record in `design-analysis.md` with `co_design: true`. Its step 7 says to close a lens with
    `confirm-workshop-lens.ps1`, which takes only `-FeatureRef` and no iteration. **Still present on main**
    (`squad-templates/skills/design-workshop.md:301-305`, `:486-488`, `:495-503`; 203's only change to this file is the
    turn-end paragraph).
- **P. Host parity: Codex as the writer reaches the gates less prepared than Claude** ("Desktop P: pass it", typed in
  the reviewer session at 02:45 local on 2026-11-23, relayed). It was seen on two downstream projects with Codex as the
  writer. The maintainer's question behind it, typed just before: "With Claude I don't have the problems we are having
  with codex, it looks like we are not enforcing the process on codex, is this a prblems of wrong hooks, oe something
  else?"
  - **The hooks are not the cause**, read by the reviewer session. The user-level Codex hook file binds SessionStart,
    UserPromptSubmit and Stop to the Specrew launcher with `-HostKind codex`. The project's runtime records show all
    three firing from Codex up to minutes before the read: hook-health markers for Codex's session start and stop,
    turn-end records, and hook-output-authority entries.
  - **The gates held on Codex every time that night:** the boundary gate's preflight (uncommitted paths, then
    `verdict-commit-durable`), the lens checkpoint's transition check, and the design-analysis pre-plan gate.
  - **Caution:** the comparison is not like for like. The crews on the maintainer's laptop run a newer pinned engine
    and have a reviewer session ruling at every step, while the downstream sessions have only the human. The fairest
    data point is the maintainer's own: one downstream project had fewer issues while Claude was its writer, on the
    same release.
  - **P1. Codex's Stop hook can only block or say nothing.** Codex's manifest lists Stop among its decision-only
    events ("Codex Stop expects JSON and only permits decision:"block"; non-blocking Stop nudges must be suppressed as
    `{}`"). Claude's output shape is `plain-or-hookSpecificOutput`, with no decision-only events. In one project's
    last 400 hook-output-authority records, Stop gave 123 "envelope" and 2 "payload". The same ratio was not counted
    for a Claude session, so this is a capability difference read in the manifest, not a measured effect. **Still
    present on main** (`hosts/codex/host.psd1:57-60`, `hosts/claude/host.psd1:72-73`; 203 does not change Codex's
    manifest).
  - **P2. The agent reads skills in parts.** The Codex sessions' own command logs show the first 85 or 90 lines of a
    skill or command file read (`Get-Content ... -TotalCount 85`), or a phrase searched with the first 13 hits taken.
    The rule missed that night, where a design agreement is recorded in a later iteration (the Co-Design Record), sits
    far past that point in the workshop skill. Claude Code loads a skill whole through its skill tool. The reviewer
    session weighs this part most. **Seen in the session logs the maintainer pasted; not traced** (this is agent
    behaviour, and the transcripts were not read).
  - **P3. No slash commands on Codex.** A skill runs only when the agent or the human calls it with the `$` prefix,
    which `specrew start --host codex` prints on the released install. **Not traced** in this tree.
  - **P4. Nothing intercepts a tool call between gates, on any host.** The deployer reports "PreToolUse dormant" for
    every host, and Claude's manifest keeps the seat empty "until the first gate-kind provider row exists".
    Enforcement is at the gates, and on Codex the agent reaches them less prepared, so the human sees more refusals.
    **Still present on main** (`scripts/internal/deploy-refocus-hooks.ps1:926` and `:996`, `hosts/claude/host.psd1:37-38`).
  - **What it suggests**, as a question for planning and not a decision: per-phase "what this phase requires next"
    text delivered by the prompt hook, which every host receives whole; and stop-time reminders carried to the next
    prompt on hosts whose Stop hook cannot carry them.
  - **Proposals.** No open proposal is about host parity.
    - Proposal 146 (refocus hooks, the Claude and Codex triad, shipped) owns the delivery channels P1 to P3 are
      about. P belongs in an amendment of it: the prompt hook carries each phase's next requirement whole, and a
      stop-time reminder that a decision-only Stop cannot show is carried to the next prompt.
    - Proposal 065 (launch-mode boundary enforcement, shipped) enforces inside the boundary skills, which refuse to
      advance. It is not what the dormant PreToolUse seat implements.
    - The tool-call intercept is proposal 180 (the PreToolUse lifecycle-entry gate), still a candidate and scoped to
      Claude Code. P4 belongs there, as a note that the seat is dormant on every host.
- **Passing findings from now on** (the maintainer, typed in the reviewer session at 03:39 local on 2026-11-23,
  relayed): "You should auto pass any finding: again: pass it". The reviewer session reads this as follows: from now on
  it passes every Specrew finding to the list that holds it, quoting these words and this time, without asking the
  maintainer per candidate. That covers recording a finding. It does not cover fixing one, a scope change, a merge or
  any approval line. F again and O below are the first two passed this way.
- **F again. A plan sync in a later iteration writes a phase label that its own state check then refuses** (a second
  sighting of 206's bug-list item 73, candidate F of 2026-11-17; passed under the 03:39 decision above).
  - What was seen: the iteration-state-truth gate refused the plan sync twice.
    - The first refusal: a file named `review-diagrams.md` sat in the iteration folder at plan time, because the agent
      had put its planning diagrams under that name.
    - After the rename, the second: "still says 'Execution has not started yet.' even though metadata says Current
      Phase='plan', Iteration Status='planning', Last Completed Task='(none)', In Progress='(none)'".
    - The repair used, on the maintainer's word in that session: delete that one sentence, with a drift entry. The
      refusal names no repair (206's item 68).
  - Why, read by the reviewer session: the store's last authorization was the previous iteration's
    iteration-closeout. So `Invoke-SpecrewIterationStateTruthGate` caps the mirror replay at `plan`, and
    `Sync-SpecrewCrossingMirrors` writes Current Phase `plan` before the check runs. The page before the sync read
    `planning`, which is exempt.
  - How this differs from the first sighting: no session-start writer was involved. The sentence was a plain bullet
    under Execution Summary, outside any managed block, and the `plan` label came from the sync itself.
  - The progress check's phase exemption lists `tasks`, `before-implement`, `planning` and `not-started`, and not `plan`.
    **Still present on main** (`scripts/internal/sync-boundary-state.ps1:953`, read by the crew; `:837` on the
    release). 203's branch changes the file elsewhere, not this line. The cap and the mirror write ahead of the check
    are **not traced** by the crew.
  - **F2. A planning diagram under a reserved file name reads as "execution has started".** The gate lists
    `review-diagrams.md` with `code-map.md`, `coverage-evidence.md`, `dashboard.md`, `dependency-report.md`,
    `reviewer-index.md` and `review.md` as evidence, and tests only that the file is present. Its refusal names the
    files ("evidence artifacts exist: ..."), but does not say that the name alone is the cause or that the name is
    reserved. **Still present on main** (`sync-boundary-state.ps1:915-923`, `:962-969`).
- **O. Specrew's deployed consumer workflows hard-code the hosted runner** (passed under the 03:39 decision above).
  - What was seen: `specrew-methodology-gate.yml` and `specrew-work-kind.yml`, as deployed into a project, say
    `runs-on: ubuntu-latest`. A private project that had used up its hosted Actions minutes for the month had both jobs
    refused before their first step ("The job was not started because recent account payments have failed or your
    spending limit needs to be increased"). Its own workflows ran on a self-hosted runner chosen through a repository
    variable.
  - The files are Specrew-deployed, so the project may not edit them, and an update would overwrite an edit. There is
    no variable or setting to choose the runner. **Still present on main** (`templates/github/workflows/
    specrew-methodology-gate.yml:20`, `specrew-work-kind.yml:22`; neither reads a variable). That an update overwrites
    an edit is **not traced** by the crew.
  - Both jobs call provider-neutral scripts already deployed in the project, so the checks could be run locally, but
    nothing tells the user that. A job that never started shows red, which reads as a failed check.
  - **Placement:** feature 182's ground. The work-kind workflow's header says GitHub Actions is the v1 wiring of a
    provider-neutral validator, and that other CI systems wire the same script. No proposal covers a configurable
    runner: the proposals that mention runners (031, 042, 087, 089, 092, 173, 205) are about other things. It is a
    candidate for the next bug bash. `tests/unit/consumer-workflow-allowlist.tests.ps1` guards these templates and
    would have to accept the change.
- **Q. The governance validator's output at a readiness check** (passed under the maintainer's 03:39 decision of
  2026-11-23). Seen at a before-implement readiness check on a downstream project.
  - **Q1. The class-closure refusal says the field is missing when only its form is wrong.** The drift entry carried
    the label as "**Class closure**" with its text after it, and named a recurrence guard, but with no colon after the
    label. The validator refused with "drift-log.md event '<id>' is missing required Class closure (name the executable
    recurrence guard, or write 'NONE — <why>')". The message does not show the form it wants,
    "**Class closure**: <text>".
    - The second sighting, on two engines: 203's own DRIFT-051 met it on this branch on 2026-11-23, where
      "**Class closure:**" with the colon inside the bold was refused.
    - **Still present on main** (`extensions/specrew-speckit/scripts/validate-governance.ps1:413`, which matches only
      `^\s*[-*]\s+\*\*Class closure\*\*:`, and `:420`, the message).
    - Proposal 142's amendment A1: a refusal names what it found and its repair.
  - **Q2. One failure under seventeen warnings.** The same run printed 17 lines of "WARN [trust-hardening]
    handoff-block-missing: Boundary commit <sha> at <boundary> has no preceding handoff evidence", one for every boundary
    commit of the feature back to its specify boundary, two closed iterations included, before the single FAIL. They
    repeat on every run and cannot be acted on for commits already made, and the one line that mattered came last.
    - The same here: every governance run on 203's branch prints three of them, for boundary commits at tasks and
      before-implement.
    - **Still present on main.** `Test-HandoffEvidenceGovernance` warns for every event in
      `.specrew/handoff-evidence.json`, with no filter for a closed or frozen iteration and no limit to the active one
      (`validate-governance.ps1:1874-2002`, the warning at `:1998`).
    - Placement: proposal 120 introduced the check (Pillar 1, FR-018), and no proposal covers warnings on closed
      history, so this is a plain item against proposal 120's check. 206's T008 rule that a frozen legacy iteration is
      judged by no check is the nearest precedent, and this check does not use it. Wanted: warn only for the active
      iteration's boundaries, and print failures before warnings, or summarise the warnings in one line.
- **R. The review pause** (passed under the maintainer's 03:39 decision of 2026-11-23). Seen in a downstream project's
  second review round. The maintainer's words about it, typed in the reviewer session at about 04:42 local: "why does
  it behave like this? I mean the stop message should tell it what to do, not to stop and ask me".
  - **R1. One human decision needs two commands, and the message names the wrong one first.** A round ended without a
    complete review, and the campaign paused ("review-round-paused:pause-decision-pending"). The pause text's
    Recommendation says to ask the human to type "approved for review round", and "Once they have typed it, run:
    specrew review --live --approve-round".
    - The human typed it, and the agent ran that command.
    - The engine answered "Round approved by the human's typed phrase ... recorded it as cmp-<...>-round-2", then
      stopped again, exit 1, with the same waiting text: round 1's pause decision was still pending.
    - Only the footer names the command that moves it, `specrew review --live --pause-choice <1|2|3>`. So the typed
      approval, which the text itself calls "the answer", does not answer the pause. A second command carrying the same
      decision is needed, and the first command the message recommends ends in a refusal-shaped stop. The agent
      stopped and went back to the human.
    - **Still present on main:** `continuous-co-review-navigator.ps1:1523-1524` ("Once they have typed it, run:
      specrew review --live --approve-round"), and `:1553-1559`, the three-way `--pause-choice` mapping.
    - **Changed on 203's branch** (T008, iteration 001; the pin `da78b600` this campaign runs on has it):
      - Review rounds take no approval of their own: the budget approved at before-implement pays for them, and
        `--approve-round` is refused in plain words (`specrew-review.ps1:340`).
      - The only pause answer left is the human's typed `stop the review here`, relayed as `--pause-choice stop-here`.
        `--pause-choice` 1 to 3 is refused (`:1193`).
      - Every review stop (a) to (d) shows one layout (`Format-ReviewCampaignStopSurface`,
        `review-campaign-orchestrator.ps1:1684`): why it stopped, what happened, the one decision, and the lines the
        human can send, each stating its consequence. No line asks for a round.
      - A typed stop answer is landed by the next launch (`specrew-review.ps1:1376-1385`).
      - T027 meets this live at the campaign's first stop.
    - Proposal 142's amendment A1: a stop names the one next action.
  - **R2. A round that "did not finish, so it found nothing and cleared nothing" still counts as used.** The release
    reads "You have used 1 of 4 review rounds" after such a round. **Still present on main**: the round count line is
    `continuous-co-review-navigator.ps1:1207`, and main does not have the rule below. **Changed on 203's branch**: a
    run that brings back no complete review spends nothing (DRIFT-052 item 3, `specrew-review.ps1:1375`). This campaign
    shows it: round 1's first launch, failed in preflight, left budget_total 4 with its reservation released and no
    spend fact.

- **S. A review launch that refuses or does nothing without saying what to do** (passed under the maintainer's 03:39
  decision of 2026-11-23). Seen on beta41 in a downstream trial on 2026-11-23, and narrowed by a retry the same day.
  - **S1. `--iteration 003` is lost, and the refusal names no cause.**
    - `specrew review --live --feature <id> --iteration 003 --host claude --code-writer-host codex --baseline-ref <sha>
      --checkpoint-id <id> --timeout-seconds 1200` ended with only `review-campaign-active-iteration-unresolved`,
      printed through `Write-Error` at `specrew-review.ps1:1988`.
    - The token has one source: `Resolve-ReviewCampaignPublicIdentity`, `review-campaign-orchestrator.ps1:1342`, when
      the iteration value is not three or more digits.
    - The same command with `--iteration=003` resolved the iteration and selected the campaign. So the space-separated
      form loses or changes the value on the way in, and the `=` form does not.
    - A plain copy of the argument chain (a function with remaining arguments, then the script, then `pwsh -File`) did
      not reproduce the loss, so the exact step is open. One lead: a bare `003` that passes through an array expression
      becomes the number 3.
    - The refusal gives no sentence and no next command. The feature refusal a few lines above it (`:1327`) was
      rewritten into a full sentence for exactly this reason; the iteration refusal was not. The agent stopped and asked
      the human, because the refusal gave it nothing to act on.
  - **S2. The "SPECREW CO-REVIEW DID NOT RUN" banner prints the reason token only.** After the `=` retry, the campaign
    refused with `allowance-exhausted`, and the banner gave no sentence and no next command. `specrew-review.ps1` has
    the sentence on another path (`:2032-2038`: the typed `approved for allowance reset` and the reset command), but the
    banner path does not print it. The comment at `:1113` describes this same gap as already measured three times.
  - **S3. Exit code 0 for a run that did not start.** The shell returned 0 although the run's status was not-started
    and nothing was invoked.

- **The review stop answers are the one review-authority folder that is tracked** (203 iteration 002 DRIFT-052).
  `.specrew/review/stop-answer/` (`HumanAuthorityStore.ps1:2912`) is not in `.gitignore`. Beside it, round-approval/,
  allowance-reset/, coverage-disposition/, signoff-gate/, pause-decision/, review/authority/ and authority/ are all
  ignored.
  - In 203 the records-only gate names it, so an answer committed after a review does not stale it.
  - Whether it should be ignored like the others is its own question: that changes what a resumed session finds on disk.
  - The same reading wants a guard: every path a store under `.specrew/review/` writes is gitignored or named.

- **A unit suite leaves a folder in `%TEMP%` for every case** (203 iteration 002 DRIFT-053; passed under the
  maintainer's standing word, 03:39 local on 2026-11-23).
  - `tests/unit/approval-form.tests.ps1:28` creates `f202-form-<guid>` for each case and never removes it. 396 were
    left in the five hours before 07:20 local on 2026-11-23, by the lanes and the review preflights that run it.
  - `%TEMP%` held 40,926 entries that morning, about twice the count of a few days before. Round 3's preflight took 48
    percent longer than rounds 1 and 2 with the processor mostly idle. The link is not shown, but it is the one machine
    condition that keeps growing.
  - **Still present on main.**

- **Proposal candidate: bring a project's own runnable files in host tool folders into the downstream review** (203
  iteration 002 DRIFT-055; the maintainer's "203 host folders: record the limit, follow up", 2026-11-23 about 14:44
  local; round 3's `finding-9cc1155f2c83f5f7`, open for this part).
  - Today `Get-ContinuousCoReviewMachineryPaths` (`worktree-reviewer.ps1`) names every existing host framework subfolder
    (`.github`, `.claude`, `.codex`, `.cursor`, `.copilot`, `.gemini`, `.antigravity` x agents, skills, commands,
    chatmodes, prompts, rules, instructions), `.agents`, `.antigravitycli` and every marked folder as machinery. The
    worktree strip and the reviewed-state digest remove all of it, so a project's own script there, such as a custom
    skill's `scripts/publish.ps1`, is never reviewed and never stales a review.
  - It must cover:
    - the strip and the digest together, since a records-only rule alone is never reached;
    - the one-time staling on upgrade, when every downstream project that holds such a file gets a new digest identity;
    - marker authenticity: a `.specrew-managed` marker is self-declared, in the strip and in a delta that adds the
      marker together with a script, so it could be checked, for example, against the deployed skill names;
    - `.agents` and `.antigravitycli` as host folders (Codex reads a project's skills from `.agents/skills`), while
      `.specify`, `.specrew` and `.squad` stay whole as tool folders;
    - Specrew's generated unmarked files there, kept by name (`.codex/agents/<role>.toml` from
      `Install-CodexCrewRuntime`, `.cursor/rules/<role>.mdc` from `Install-CursorCrewRuntime`);
    - Squad's unmarked files (`.copilot/skills/distributed-mesh/sync-mesh.ps1`, `sync-mesh.sh`, `mesh.json.example`),
      which would be reviewed and would stale on a Squad redeploy;
    - the cases parked in 203 (`.agents/skills` with and without a marker, `.antigravitycli`, the same-change marker),
      and the limit case in `records-only-covers-what-deployment-writes.Tests.ps1` turned around.
- **The hook and MCP server configuration names are a list** (203 iteration 002 DRIFT-054; passed under the
  maintainer's 03:39 decision of 2026-11-23).
  - `Test-ReviewCampaignPathIsHostCommandConfig` in `review-signoff-evidence-gate.ps1` names the files. A new host, or a
    new configuration file of this class, needs a new entry.
  - A guard could derive them from each host manifest's settings files and MCP configuration, so that a host added
    without an entry fails a test.

## Fixed in 203, for Completeness

- **Item 8 (HO-206-5), suites that rewrite the real home's hook files**: B5F-039, test first (`77bd4a2e2`, `b69cc5caf`),
  guard `tests/unit/test-home-isolation.Tests.ps1`.
- **Item 13 (HO-206-8), a supervisor still running after a failed lease handoff**: 203 T015 part 1 (RED `5388a5f13`,
  fix `fcafd224f`), guard `co-review-service.Tests.ps1`.
- **Item 61, campaign findings demoted for a missing "Failure scenario:" clause**: B5F-017, `d3ab3f21c`, guard
  `reviewer-prompt-contract.Tests.ps1` (its context at line 119 renders the campaign prompt).
