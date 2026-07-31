# Drift Log: Iteration 010

**Schema**: v1

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

**Total drift events**: 0
**Resolution rate**: 100% (0/0 resolved)
**Specification drift**: None detected

## Events

No specification drift detected during Iteration 010 execution to date.

### Resolution Strategies (Unused)

The following resolution strategies remain available if drift is detected later in execution:

- **spec-updated**: Update the spec to reflect implementation choice
- **implementation-reverted**: Revert implementation to match spec
- **deferred**: Mark drift as deferred to next iteration
- **human-decision**: Escalate to Alon for resolution

### Notes

- This artifact was scaffolded before review starts so drift can be logged immediately when detected.
- Replace the zero-drift summary with real counts when the first drift event is recorded.

### DRIFT-198-I010-002 — DRIFT-198-I009-042's premise is FALSE on all three volumes; T083 has no reachable defect

- **Status**: open — T080 evidence contradicts the finding T083 was scheduled to fix.
  **Awaiting the maintainer's decision; no "fix" attempted.**
- **Severity**: major process finding — a confirmed-in-source finding that is not reachable in behaviour
- **Type**: evidence discipline / finding validity

**The finding.** DRIFT-198-I009-042, a major from the iteration-009 certifying round, states that
`Get-ContinuousCoReviewCaseVerdictFromListing` tests the flipped spelling with
`[IO.Directory]::Exists($candidate) -or [IO.File]::Exists($candidate)`, and that "those APIs follow a
link target and both report false for a dangling symbolic link", so a listed dangling entry on a
case-folding volume inverts the verdict.

**The first half is true; the second half is not.** Measured by T080 on all three CI volumes at
commit `7cf063c2`, for a symlink whose target never existed:

| Leg | listed | dirExists | fileExists | existsApi (`-or`) | gap reachable |
| --- | --- | --- | --- | --- | --- |
| windows-latest / NTFS | True | False | **True** | **True** | False |
| macos-latest / APFS | True | False | **True** | **True** | False |
| ubuntu-latest / ext4 | True | False | **True** | **True** | False |

`[IO.File]::Exists` returns **true** for a broken symlink on POSIX as well as Windows — .NET's
`FileStatus` completes an `lstat` and treats the link entry itself as an existing non-directory. The
`-or` therefore never evaluates false for a dangling link, the "absent" branch is never taken, and the
verdict is never inverted. A local sweep of the other candidate construction, a symlink LOOP
(`a -> b -> a`, where `stat()` fails with `ELOOP` while `lstat()` succeeds), also produced
`gap=False`; the sweep is now part of the harness so the POSIX legs measure it too rather than
inheriting a Windows inference.

**So T083 as planned has nothing to correct.** The code reads exactly as the reviewer described. The
consequence the reviewer drew from it does not occur on any supported platform.

**My error, stated plainly.** I recorded DRIFT-198-I009-042 with "Confirmed source evidence" after
reading the code and reasoning about what `Directory.Exists` / `File.Exists` do with links. I did not
measure them. That is precisely the "evidence before hypothesis" rule this iteration carries forward,
and I violated it while recording a finding as confirmed. The reviewer's code-reading was right and its
behavioural claim was wrong; I propagated the claim into the ledger, into the narrowed release claim as
limitation 2, and into this iteration's plan as a 3 SP task.

**Consequences to decide (maintainer's call, not assumed here):**

1. **DRIFT-198-I009-042** should be re-dispositioned as *not reproducible* rather than fixed — with
   this measurement as the evidence.
2. **Limitation 2** of
   file:///C:/Dev/specrew-beta2-hardening/specs/198-beta2-hardening/beta2-release-claim.md
   ("the case probe returns the wrong answer when a directory entry is a dangling link") is not
   supported by measurement and should be removed or restated at closeout.
3. **T083's 3.0 SP** frees. It should NOT be silently reallocated; that is a planning decision.
4. **The link-aware lookup may still be worth having** as defence in depth — the probe's existence
   test is semantically the wrong question even where the current answer happens to be right — but
   that is a design choice with no defect behind it, and it must not be recorded as a fix.

**What this does NOT change.** T082 (DRIFT-198-I009-041, authority-store containment) is untouched:
it is a lexical-containment defect, independent of any `Exists` behaviour, and its fixtures are still
required. T080/T081/T084 stand.

### DRIFT-198-I010-001 — the effort model cannot express a round-bounded iteration

- **Status**: open; recorded at the plan boundary, not worked around
- **Severity**: minor schema gap with a planning-honesty consequence
- **Type**: effort-model vocabulary
- **Observed evidence**: Iteration 009's single most transferable lesson is that
  review-correction work must be bounded by ROUNDS or BUDGET, never by scope — "the approved
  finding cluster is fixed" does not bound anything when each fix reveals the next defect
  (009 delivered ~70 SP against a 20 cap across eight rounds). Encoding that in this plan
  fails: `validate-governance.ps1` requires the plan's `Iteration Bounding` to match
  `.specrew/iteration-config.yml`, and that file offers only `scope` or `time`. Setting
  `rounds` produced `plan.md Effort Model 'Iteration Bounding' value '**rounds**' does not
  match iteration-config 'scope'`.
- **Consequence**: the Effort Model line for Iteration 010 says `scope`, which is not what
  bounds this iteration. The real bound is the 3-round cap in the plan's termination rule.
  A reader trusting the structured field would draw the wrong conclusion, so the plan says
  so explicitly in `## Notes`.
- **Relation**: the fifth instance of the same meta-pattern in this feature — the schema
  cannot express the honest disposition. See DRIFT-198-I009-021, -034, -044 (the
  disposition-vocabulary cluster in Iteration 012 finality scope) and -020. Candidate for
  that same cluster rather than a separate fix.
- **Required correction (deferred)**: add `rounds` (and `budget`) to the supported
  `iteration_bounding` vocabulary, with the round cap as a first-class configured value the
  validator can check against the certification section.
