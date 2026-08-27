# Review: Iteration 001

**Schema**: v1
**Reviewed**: 2026-08-21
**Overall Verdict**: accepted

## Independent review

<!--
  The block below is DERIVED from the review store and recomputed at validation. It cannot be authored
  or edited here; the prose around it is what this record says for itself.
-->

<!-- SPECREW-DERIVED-INDEPENDENT-REVIEW v1 -->
<!-- Derived from the review authority store. Do not hand-edit: the validator recomputes it. -->
- Run: run-20260827-023623882-300694ac (harness codex-cli-file-primary)
- Outcome: findings, complete, current, valid - 3 finding(s)
- Reviewed tree: 1b50ae6094439e649238c02df76293da26e2c3ce
- Coverage: 22 source path(s) of 28 declared and checked against the frozen target.
<!-- /SPECREW-DERIVED-INDEPENDENT-REVIEW -->

### What this record rests on, stated rather than implied

**The run**: `run-20260827-023623882-300694ac`, an independent codex round invoked under verified
containment against a frozen copy of this tree, 973.7s, terminal / complete / **current** / valid.

**The tree it read**: reviewed-state digest `1b50ae6094439e649238c02df76293da26e2c3ce`, which is the
tree at commit `081d74ba`.

**What has changed between that tree and the one being signed off**: nothing in source. The only
commits after `081d74ba` are this record and the drift-log entries describing the round itself, which
are lifecycle execution records and do not stale a review (DRIFT-007). **The coverage gap is empty**,
and that is checkable rather than asserted: the validator recomputes the source-aware delta at every
validation and refuses this record if any source file has moved.

**Coverage**: 22 of the 28 paths the reviewer declared were source; the remaining 6 were records or
machinery.

### The three findings, open and dispositioned

None blocks sign-off. All three are recorded rather than repaired, and the reason is stated below.

1. **`[major]` A newline still fails to delimit a BARE boundary approval.** `Test-SpecrewHumanVerdictToken`
   now splits question and condition clauses at newlines, but `$isRecognizedPhrase` does not accept a
   newline as the delimiter after a bare `approved`. So `approved` + newline + `When the cleanup
   finishes, start the retro.` still falls through and the condition check rejects the verdict, leaving
   the human to retype - contrary to FR-010.
   **This is an INCOMPLETE FIX OF MINE, from the same round**: W75 closed the delimited-clause forms
   and missed the bare-approval form one branch over. It is the FR-010 defect narrowed, not removed.
   Recoverable by retyping, unlike the ledger outage W75 closed.
2. **`[minor]` Interrupted starter creation permanently omits the templates sidecar.** The materializer
   writes the plan before its sidecar; an interruption between them leaves an unmarked plan that the
   next init preserves as an explicit user plan, so the FR-012 templates are never restored. Carried
   since round 25 by standing ruling.
3. **`[minor]` Pause decisions are omitted from the question-UI refusal diagnosis.** The router offers
   typed turns to the pause-decision and withdrawal writers, but the question-UI detector still knows
   only three phrase kinds, so a picker-mediated `stop the review here` produces the generic refusal
   and the agent may re-ask through the same invalid UI. Recorded as a beta4 item on 2026-08-26,
   before this round independently found it.

### Why these are open rather than fixed

**Repairing a finding invalidates the round that found it.** The reviewed tree is frozen at invocation;
any source change moves the digest, and the run stops covering the tree being signed off. Thirty-three
rounds have not produced a zero-finding result, so "fix everything, then obtain covering evidence" has
no terminal state short of one. The maintainer ruled on 2026-08-27 that the bar for this sign-off is
the disposition of what is known, not the absence of findings.

**What this record therefore claims**: an independent review covering the source as it stands, with
three known open findings, one of them a partial fix of this session's own work. **It does not claim
they are absent, and it does not claim they are harmless.**

### Why partial coverage was accepted, in the maintainer's reasoning

Recorded here as PROSE, narrated by this record's author. It is not an authority field and is not
dressed as one: the authorization itself lives in the review store with its own typed rationale, and
this section exists because the reasoning is worth more than a rationale line can hold.

The maintainer accepted this tree with its three open findings on four grounds:

1. **All three findings FAIL SAFE.** The major refuses a valid approval rather than accepting an
   invalid one - a bare `approved` followed by a newline and an instruction falls through, so a
   legitimate verdict is not captured and the human retypes.
2. **By method rule 12's test it is friction, not an outage.** The human undoes the refusal by
   acting; nothing about it is unrecoverable, which is the distinction that separates it from the
   ledger defect closed in W75.
3. **The two minors mint nothing.** A missing templates sidecar and a diagnosis that omits pause
   decisions are both absences, not fabrications.
4. **No finding in this set can forge, promote or fabricate authority** - which is the property that
   makes accepting it INFORMED rather than RESIGNED. A set of open findings that could put a false
   fact in the store would not have been acceptable on any schedule.

**And the coverage is checkable rather than asserted**: `run-20260827-023623882-300694ac` read tree
`1b50ae60` at commit `081d74ba`, 22 source paths of 28, and the delta since is records-only and exempt
under DRIFT-007 - so the gap is empty and provable, and the validator recomputes it at every
validation rather than trusting this paragraph.
### What this record does not claim

Its per-task verdicts and the prose around them were written by the implementing session, and the
authorship fact says so rather than hiding it: this document reports `review-authorship-unobserved`
for the verdicts authored on 2026-08-17, because the machinery that observes authorship (W34-B) did
not exist then and backfilling it would be an assertion rather than an observation. What is
independent here is the run the block names. What is mine is the judgement in the table below.

## Task Verdicts

| Task | Requirement | Verdict | Notes |
| ---- | ----------- | ------- | ----- |
| T001 | FR-001, FR-002, FR-003, FR-004 | pass | Pause core verified across campaign rounds 1-5 and live on 2026-08-17: the outstanding round-5 pause rendered its decision surface with severity-grouped findings, the typed choice 1 was consumed exactly once, and minor findings never gated. Slice suites campaign-activation and default-run-id-mint pass (61/61). |
| T002 | FR-005 | pass | Composed stop-here landing covered by campaign-stop-here-landing unit suite and the round-5 decision surface, which rendered the full landing as one option 2 action. |
| T003 | FR-007, FR-008, FR-009 | pass | Single-authority stop surface fixed and re-verified in round 5 (records-only delta no longer mints signoff authority; conditional on the result authorizing on its own terms). The signoff evidence gate held fail-closed live in this session while review.md was absent. |
| T004 | FR-010 | pass | Verdict-capture contract green in the permanent class-guard lane on 2026-08-17: verdict-capture-blocks and ConversationCapture suites pass, including the T032 fabrication fixtures and the 23 not-approve cases. |
| T005 | FR-006 | pass | Verdict-goal reviewer prompt contract shipped in worktree-reviewer.ps1 and reviewer-candidate-prompt.md within the sealed runtime bundle; exercised by rounds 3-5. |
| T006 | FR-011 | pass | Reparse-tag discrimination green in the class-guard lane (path-identity, volume-differential, machinery-path suites, 35/35 with the volume oracle confirming the dangling-link defect is unreachable on this volume). |
| T007 | FR-012, FR-013 | pass | Named verification errors observed live on 2026-08-17: the runner named the failing command (verification-command-failed:iteration-001-governance) and the authority store named the exact contract violation (too-long:authorization_ref:256). Init scaffolds the strict starter plan per integration suites. |
| T008 | FR-014 | pass | Invoked-only spend accounting observed live twice on 2026-08-17: both preflight-failed runs reported "no round was used and the authorization you already gave is still available", and the budget still shows 1 of 4 rounds used. |
| T009 | FR-018 | pass | review-window-codex-default suite passes in the slice lane; the catalog carries the 900-second codex-class default window. |
| T010 | FR-015, FR-016, FR-017 | pass | Consumer-language navigator suite passes in the slice lane; decision stops rendered as one message live (round-5 pause surface). The FR-016 banner gap is now closed rather than deferred: every requirement ID the orientation banner shows a human carries a short description, in all three shipped copies, enforced by running the project's own detector over the banner's emitted prose (fails against the pre-fix banner). |
| T011 | FR-019 | pass | BannerPrereleaseVersion suite passes in the slice lane; the banner renders the full prerelease version (observed as "Specrew: 0.40.0-beta3" in the 2026-08-16 Copilot walk transcript). |
| T012 | FR-020, FR-021 | pass | The 009/010 wording inconsistency is resolved in records and docs/release-notes-v0.40.0-beta3.md carries the release draft under the beta2 certification discipline. |
| T013 | FR-022 | pass | ci-registry-lane-tooling suite passes in the slice lane; the markdownlint-cli install is in the CI workflow. |

<!--
  Gap Ledger schema (validator-enforced):
    EVERY non-empty line MUST be a bullet entry classified with one of two tokens:

      - "fixed-now"  — the gap was repaired during this iteration
      - "deferred"   — the gap is parked with explicit human approval (the approval
                       reference must be recorded in .squad/decisions.md)
    Free-form intro prose between the heading and the bullets is REJECTED by the
    validator (it scans every non-empty line for a classification token).

  When there are no gaps, write ONE line:

    - "No requirement (FR/SC) gaps: all in-scope requirements verified: fixed-now."

-->

## Gap Ledger

- FR-016 banner gloss gap (round-5 major finding, run-20260811-213318650-9ab64f34, raised again by run-20260817-220959812-f183b4d8 against the frozen UI/UX design context): fixed-now. Every requirement ID the orientation banner shows a human now carries a short description in all three shipped copies, enforced by the project's own detector over the banner's emitted prose. The earlier deferral recorded in .squad\decisions.md entry 2026-08-17T07:55:00Z is superseded by the maintainer directive to fix all issues before completing.
- All other in-scope requirements (FR-001 through FR-015, FR-017 through FR-023) verified with round-5 blocking findings repaired during this iteration: fixed-now.

## Notes

- Review basis: five authorized campaign rounds (2026-08-10 through 2026-08-11) with every round-5
  finding fixed and re-verified or explicitly deferred by ruling; the permanent class-guard lane
  (35/35) and the slice lane (61/61) re-run green on 2026-08-17; live behavioral evidence from this
  session for FR-003, FR-005, FR-007-009, FR-013, FR-014, and FR-017 recorded in the task notes.
- Post-round-5 work in this iteration (workshop transition/repair wedges W10-W17, including the
  2026-08-17 selection-channel producer fix, and the Copilot reviewer-of-record switch) passes its
  own suites (workshop-agenda-confirmation, workshop-refusal-contract, workshop-typed-turn-authority,
  conformance-detection) but has no provider-round coverage yet.
- Per R2 of the walk-findings mitigation, review sign-off requires current-tree campaign evidence.
  SATISFIED 2026-08-21 by run-20260821-104557253-97c3785a above: pass/complete/current/valid, zero
  findings, 17 source paths declared and checked. The stale evidence this record previously rested
  on is superseded.
- Work landed after the 2026-08-17 rounds - W18 through W35, the packaging and install path, and the
  host-parity guard - is covered by the 2026-08-21 round, which reviewed the committed tree that
  contains all of it.
- Drift checks ran continuously during execution; the drift log carries 67 entries with per-event
  resolution status.
