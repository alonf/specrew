# Drift Log: Iteration 003

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

**Total drift events**: 10
**Resolution rate**: 100% (10/10 resolved or placed)
**Specification drift**: None; Amendment A2 went through clarify (DRIFT-205-INTAKE-006); Amendment A3 recorded in spec.md, approved at the tasks boundary (DRIFT-005)

## Events

### DRIFT-001 — HookRenderDedupe I3a failed once on iteration 002's closeout push (external CI failure; handed over)

- **Observed**: 2026-11-15 03:22:57Z (05:22 local), Specrew CI run 43670851775, attempt 1, Deterministic gate job
  132681450478, step "Bootstrap suite (F-174 hook chain - incl. directive delivery cap, P2)", on `ce444ca8`. That push
  carried iteration 002's closeout records only: plan.md, the drift log, hardening-gate.md, the dashboard, the seal
  JSON, `closed-iterations.yml` and the sync's `.squad` files.
- **Failure**: `tests/bootstrap/HookRenderDedupe.Tests.ps1`, case "I3a: two concurrent missing-id fires BOTH render
  (per-launch fallback keys, never shared suppression)": expected '2', got '1'. It was the only failed bootstrap
  suite, and the Contract lane was skipped as a consequence. Test and Cross-Platform Validation were green, and the
  same suite passed on `57f14996`, `00273e84` and the pushes before them.
- **Resolution**: reported first; one rerun ruled by the reviewer session (a timing-dependent case on a records push).
  Attempt 2 was green. Iteration 002 was sealed by then, so the sighting is recorded here.
- **Earlier records naming this test** (not read into): `specs/174-hook-driven-session-bootstrap/iterations/010/state.md`,
  `specs/183-stability-quality-bundle/iterations/001/`, `specs/198-beta2-hardening/iterations/007/retro.md`,
  `specs/198-beta2-hardening/iterations/008/drift-log.md`, `specs/199-beta3-stabilization/iterations/001/drift-log.md`.
- **Count**: the third different CI failure outside 205's pushes in one night: `empty-result-retry` on `b15c5dd1`
  (iteration 002 DRIFT-020), the Windows Pester install on `fa65488d` (iteration 002 DRIFT-023), and this one.
- **Rerun rule**: not covered by the standing exception, which since 2026-11-15 covers `co-review-service.Tests.ps1:129`
  and `empty-result-retry.Tests.ps1` only (DRIFT-205-INTAKE-007). A recurrence still goes to the reviewer session.
- **Class closure**: NONE — the hook chain's test is outside 205's scope. Handed over as H-023
  (`handover-to-203.md`); the test was last changed by feature 202, and 203 holds the CI-stability hand-overs.

### DRIFT-002 — the plan scaffold listed every requirement of the spec (recurrence of iteration 002's DRIFT-002)

- **Observed**: 2026-11-15. `scaffold-iteration-plan.ps1` was run without a scope, as iteration 002 did after the
  scoped form refused every requirement. The stub lists FR-001 to FR-032.
- **Resolution**: the scope is written by hand (FR-030, FR-031, FR-032).
- **Class closure**: NONE — the scaffold is part of the deployed extension. Handed over as H-024; iteration 002
  named it a candidate but did not hand it over.

### DRIFT-003 — the quality resolver reads the stack as frontend again (recurrence of iteration 002's DRIFT-001)

- **Observed**: 2026-11-15. The plan scaffold's concurrency section reads "Frontend-oriented signals dominate the
  scoped requirements". The real stack is PowerShell 7 scripts, lens markdown, a YAML catalog and tests.
- **Resolution**: corrected by hand in the plan, as in iterations 001 and 002.
- **Class closure**: NONE — the resolver is part of the deployed extension. Handed over as H-025.

### DRIFT-004 — iteration 002's improvement actions carried into this intake

- **Actions 1 to 4** (practices): per-item checks with swap, replace and reword self-tests; re-point the verification
  plan in the first commit after before-implement; check each planned item's lens `space` tag at planning (done in the
  design analysis: FR-032 reads `space` from index.yml); `review.md` names the gate's coverage decision only after the
  sync. Carried into this plan.
- **Action 5** (the three reviewer-brief additions in the round scope-file template): open. Iteration 001's version
  was not done either. It most likely belongs to proposal 140 (Reviewer Instruction Surface), for the maintainer to
  confirm when prioritising; it is not a side question.
- **Action 6** (H-015 to H-022): with feature 203.
- **Class closure**: NONE — process carry-forward, not a defect.

### DRIFT-005 — the code lens confirms a version the human's choice depends on (maintainer decision; FR-030 wording)

- **Decision**: the maintainer's words at 19:02 local on 2026-11-15, "Yes for all", relayed by specrewreviewer-98 with
  the question it answered. The reviewer had told them Option A rests on a 90-day window and a release can land well
  inside it, as the recorded run showed (a session called a .NET release short-support, then corrected itself;
  iteration 002 DRIFT-019 item 5), and proposed one sentence for the code lens's conduct: when the human's choice
  depends on a version, the agent confirms it against the official source and shows the source and the date, even if
  the stack's line is not yet stale. With it: if the host has no way to look a source up, the conduct says so to the
  human in plain words and marks the version as unconfirmed; it does not guess.
- **Placement**: T030 (the conduct change) adds the sentence and the fallback to `code-implementation.md`'s Workshop
  Conduct. T027 covers it the way it covers the rest of the conduct text: the sentence and the fallback must be
  present, and a self-test that removes either fails naming it.
- **Spec**: FR-030 asks for dated lines and a stale marker. It does not ask the agent to confirm a version at the
  point of choice, and SC-011 does not test the conduct. Doing it under FR-030 as written would stretch the
  requirement, so it goes through clarify (TG-004) as Amendment A3, approved at the tasks boundary as A1 and A2 were at
  the plan boundary. The wording, accepted by the maintainer as written at 20:57 local on 2026-11-15 ("OK, accept the
  wording", relayed by the reviewer session) and now in spec.md with its Clarifications entry:
  - FR-030, appended: "When the human's choice depends on a version, the lens's conduct MUST tell the agent to confirm
    it against the official source at that point and show the source and the date, even when the stack's line is not
    stale. When the host cannot look a source up, the agent MUST say so in plain words and mark the version
    unconfirmed, never guessing."
  - SC-011, appended: "and the lens's conduct carries the confirm-at-the-point-of-choice rule and its no-lookup
    fallback."
- **Resolution**: spec-updated (Amendment A3); no clarify sync mid-iteration (reviewer's ruling); approved at the tasks
  boundary.
- **Class closure**: the T027 check over the conduct text.

### DRIFT-006 — the records-only push rule now covers records in general (maintainer decision)

- **Decision**: the maintainer's words at 19:02 local on 2026-11-15, "Yes for all", relayed by specrewreviewer-98 for
  all three crews, answering "should the records-only push rule cover records in general and not only Markdown".
- **The rule now**: when the only difference from the last commit on which the full pre-push checks were green is
  records, run markdownlint and the governance check, push, and follow CI to its end. Records are: Markdown under
  `specs/` or `docs/`; the files a boundary sync writes (the `.squad` records, the sign-off gate's record and listing,
  `state.md`, the closed-iterations index and the seal); and the iteration's own record files. Anything else in the
  difference (any lens file, skill, template, script, test, configuration file, deployed copy or hash record) still
  gets the full checks. Before using the rule, print the changed files and confirm each is a record of those kinds;
  one that is not clearly so is not.
- **Unchanged**: it does not relax a review round's head, and it does not widen the CI rerun exception
  (DRIFT-205-INTAKE-007).
- **Class closure**: NONE — a working rule, saved as the crew's standing rule.

### DRIFT-007 — HookRenderDedupe failed again, a different case (second sighting today; handed over)

- **Observed**: 2026-11-15 17:24:35Z (19:24 local), Specrew CI run 43739142768, attempt 1, Deterministic gate job
  132889634266, step "Bootstrap suite (F-174 hook chain - incl. directive delivery cap, P2)", on `b6ba0341`. That push
  carried Markdown records only (DRIFT-005 and DRIFT-006, plan.md, the feature plan, tasks.md).
- **Failure**: `tests/bootstrap/HookRenderDedupe.Tests.ps1`, case "I4b: all concurrent journal rows remain present"
  (the log line is cut after "present and pa"): expected '16', got '15'. The only failed suite; the Contract lane was
  skipped as a consequence. Test and Cross-Platform Validation were green, and the suite passed on `d03a1f08` an hour
  earlier.
- **Resolution**: reported first; one rerun ruled by the reviewer session for that run only. Attempt 2 was green
  (Deterministic gate job 132894671162, Contract lane job 132899218902).
- **Pattern**: the second HookRenderDedupe sighting today, a different case from the first (I3a on `ce444ca8`,
  DRIFT-001). Two concurrency cases in one suite failed on two records-only pushes within a day.
- **Rerun rule**: unchanged. The standing exception covers `co-review-service.Tests.ps1:129` and
  `empty-result-retry.Tests.ps1` only; the reviewer is asking the maintainer whether this suite should join it.
- **Class closure**: NONE — the hook chain's test is outside 205's scope. Added to H-023 (`handover-to-203.md`) as
  the second sighting.

### DRIFT-008 — HookRenderDedupe joins the standing CI rerun rule (maintainer decision)

- **Decision**: the maintainer's words at 02:56 local on 2026-11-16, "rerun: add HookRenderDedupe", relayed by
  specrewreviewer-98 after it showed them the two records-only failures of 2026-11-15 (I3a, DRIFT-001; I4b,
  DRIFT-007), each green on rerun.
- **The rule now, until feature 203 merges**: a CI failure in `co-review-service.Tests.ps1:129`, in
  `empty-result-retry.Tests.ps1`, or in the HookRenderDedupe suite's named timing cases (I3a, I4b) may be rerun once
  without asking, when the push did not touch that code or anything it reads. A failed rerun, in the same case or
  another, stops the crew. Every sighting is recorded (run, job, system, case and numbers) and passed to 203. Any
  other failure in that suite is a failure, and the exception does not apply to a push that changed hook rendering,
  the capture stores or anything the suite exercises.
- **Class closure**: NONE — a working rule, saved as the crew's standing rule.

### DRIFT-009 — co-review-service.Tests.ps1:129 failed on a records push (standing rerun exception used)

- **Observed**: 2026-11-16 00:57:31Z (02:57 local), Specrew CI run 43782743984, attempt 1, Deterministic gate job
  133024616043 (Linux runner), step "F-198 honesty regression suite (NFR-007)", on `1b8f22d6`. That push carried
  iteration 003's T034 records and the round 1 scope file only.
- **Failure**: `tests/continuous-co-review/unit/co-review-service.Tests.ps1:129`, "Expected $null or empty ... but got
  System.Diagnostics.Process (pwsh)"; 1 of 131 suites failed, and the Contract lane was skipped as a consequence.
  Test and Cross-Platform Validation were green.
- **Resolution**: covered by the standing exception (DRIFT-205-INTAKE-007, DRIFT-008): one rerun without asking.
  Attempt 2 green (Deterministic gate job 133028487355, Contract lane job 133032838976).
- **Class closure**: NONE — 203's test. Handed over as H-026.

### DRIFT-010 — the review record is pushed with the plan still at executing, by the maintainer's allowance (decision, this push only)

- **Observed**: 2026-11-16, after round 1 (`run-20261116-095117164-6e1e0a46`, no findings, on `a0c6a849`). The local
  governance check fails iteration 003 on one item beyond the standing derived-block item of iterations 001 and 002:
  "plan.md status 'executing' is stale: review.md exists, so the iteration must be in reviewing, retro, or complete".
  The review-signoff sync needs `review.md` on origin while plan.md is still at `executing`, as in iteration 002
  (its DRIFT-021).
- **Decision**: the maintainer, relayed by the reviewer session under the wider delegation. The reviewer offered
  "205: allow, standing" (recommended) or "205: allow". The maintainer's words, at 12:22 local on 2026-11-16: "205:
  ok". That allows this push under either reading; it does not say which was meant, so the reviewer relayed the
  narrower one (this push only) and is asking the maintainer once whether "standing" was meant.
- **Resolution**: `review.md` and this entry are pushed with that one named local failure. Specrew CI may be red on
  Lint for that message only; Test and Cross-Platform Validation must be green under the standing rerun rules;
  anything else red stops the work. Then the review-signoff sync binds to this commit and moves the phase lines, and a
  fully green records push follows before the sign-off packet.
- **Class closure**: NONE — the validator rule is feature 206's T034 (`3a3ba803` on 206's branch); it reaches this
  branch when main is merged in after 206 lands.
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
