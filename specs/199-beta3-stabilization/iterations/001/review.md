# Review: Iteration 001

**Schema**: v1
**Reviewed**: 2026-08-21
**Overall Verdict**: accepted

## Independent review

<!--
  THE BLOCK IS WITHDRAWN, and the reason is a decision the maintainer made AFTER sign-off.

  Sign-off was authorized on 2026-08-27 against commit 66403e9b (tree 52fa21ce), resting on
  run-20260827-023623882-300694ac, which covered tree 1b50ae60 with a records-only delta since.
  That authorization stands and is recorded in the decisions ledger.

  The maintainer then ruled that a defect found immediately afterwards - exhaustion advisories naming
  a CLI flag and never the typed phrase - was NOT a beta4 item, being the same class this fortnight had
  closed twice already, live on a third surface and reaching a real human. Fixing it changed seven
  source files, so the run stops covering the tree.

  The validator says so exactly, and its remedy is taken here rather than worked around:
    it reviewed tree 1b50ae60 and 7 source file(s) have changed since.
-->

**Sign-off was given against commit `66403e9b`, and the covering evidence for THAT tree was
`run-20260827-023623882-300694ac`** - codex, terminal / complete / current / valid, 22 source paths of
28, reviewing tree `1b50ae60`, with only records-only commits between. That is the state the maintainer
read and authorized, and it remains true of the commit it names.

**Source has changed since sign-off, by the maintainer's explicit instruction.** W76 corrected three
exhaustion advisories that handed the reader `specrew review --remediate allowance-reset` and never the
typed phrase `approved for allowance reset`, and rebuilt the standing audit that failed to notice: it
enumerated two flags by hand, so the reset flag - added to the surfaces later - was never swept, and
**the check passed while the surface violated the rule the check exists to enforce.** The audit now
derives its flags from the surfaces and resolves each against one table in source.

**So the independence claim is WITHDRAWN pending a fresh round.** No run currently covers the source as
it stands. This is the review-repair-stale loop behaving correctly, arriving one step after a sign-off
rather than before one.

**What this record therefore claims**: sign-off was authorized against `66403e9b` on covering evidence
that was real and checkable for that tree, and the tree has since moved by three advisory corrections
and one audit rebuild. It does not claim those corrections have been independently reviewed.
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
