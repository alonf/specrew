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
    outcome (`:2265`, `:2437-2480`); whether it reaches the console on this path was not traced.

## Fixed in 203, for Completeness

- **Item 8 (HO-206-5), suites that rewrite the real home's hook files**: B5F-039, test first (`77bd4a2e2`, `b69cc5caf`),
  guard `tests/unit/test-home-isolation.Tests.ps1`.
- **Item 13 (HO-206-8), a supervisor still running after a failed lease handoff**: 203 T015 part 1 (RED `5388a5f13`,
  fix `fcafd224f`), guard `co-review-service.Tests.ps1`.
- **Item 61, campaign findings demoted for a missing "Failure scenario:" clause**: B5F-017, `d3ab3f21c`, guard
  `reviewer-prompt-contract.Tests.ps1` (its context at line 119 renders the campaign prompt).
