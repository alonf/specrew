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

- **Status**: **FINALIZED 2026-07-31 — DRIFT-198-I009-042 is re-dispositioned NOT REPRODUCIBLE AS
  REPORTED.** Held qualified until the POSIX loop sweep landed (maintainer instruction: do not state
  it flatly while one construction is unmeasured). It has now landed — see the second table — and
  both candidate constructions are measured on all three volumes. No fix was attempted.
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
verdict is never inverted.

**The second construction, measured on all three volumes at `10fbe831`.** A symlink LOOP
(`a -> b -> a`), where `stat()` fails with `ELOOP` while `lstat()` succeeds, was the remaining
candidate for producing the gap. The harness sweep now measures both:

| Leg | dangling gap | loop gap |
| --- | --- | --- |
| windows-latest / NTFS | False | False |
| macos-latest / APFS | False | False |
| ubuntu-latest / ext4 | False | False |

Neither construction produces `listed=True` with `existsApi=False` on any supported volume. That is
what finalizes the disposition: the conclusion no longer rests on a Windows measurement plus an
inference about POSIX.

**So T083 as planned has nothing to correct.** The code reads exactly as the reviewer described. The
consequence the reviewer drew from it does not occur on any supported platform.

**My error, stated plainly.** I recorded DRIFT-198-I009-042 with "Confirmed source evidence" after
reading the code and reasoning about what `Directory.Exists` / `File.Exists` do with links. I did not
measure them. That is precisely the "evidence before hypothesis" rule this iteration carries forward,
and I violated it while recording a finding as confirmed. The reviewer's code-reading was right and its
behavioural claim was wrong; I propagated the claim into the ledger, into the narrowed release claim as
limitation 2, and into this iteration's plan as a 3 SP task.

**Consequences, decided by the maintainer 2026-07-31:**

1. **DRIFT-198-I009-042 re-dispositioned NOT REPRODUCIBLE AS REPORTED** — finalized only after the
   POSIX loop sweep landed, per instruction. Recorded against the entry in
   file:///C:/Dev/specrew-beta2-hardening/specs/198-beta2-hardening/iterations/009/drift-log.md
2. **Limitation 2 of the release claim revised ONCE**, now that both constructions are measured. The
   claim is unpublished, so waiting avoided editing release-facing text twice on a provisional result.
3. **T083's 3.0 SP returns to SLACK.** Iteration 010 becomes **17.0/20 with 3.0 headroom**, and the
   headroom is explicitly NOT backfilled with new scope — "that headroom is exactly what 009 never
   had".
4. **No link-aware lookup as defence in depth.** There is no defect, and T080's fixtures now measure
   the behaviour on all three volumes, so accidental correctness that later breaks is caught by the
   oracle rather than guarded by speculation. Recorded as a backlog note — *lookup semantics: no known
   defect, guarded by harness measurement* — never as a fix.
5. **Iteration 009's closure trigger amended** — it fired on "-041, -042 and -043", which with -042
   withdrawn could never be satisfied. See the reviewer-precision datum below and the amended trigger.

**What this does NOT change.** T082 (DRIFT-198-I009-041, authority-store containment) is untouched:
it is a lexical-containment defect, independent of any `Exists` behaviour, and its fixtures are still
required. T080/T081/T084 stand.

**Backlog note (maintainer decision, not a fix): lookup semantics.** The probe asks "does this path
resolve?" where "is this entry present?" is the semantically correct question. There is **no known
defect** — both candidate constructions measure clean on all three volumes — and the harness now
measures the behaviour per volume, so an accidental correctness that later breaks is caught by the
oracle rather than pre-empted by speculation. Recorded here as a note; deliberately NOT scheduled and
NOT counted as a correction.

### Reviewer-precision datum — measure the instrument as honestly as the code

Recorded at the maintainer's instruction, 2026-07-31.

**Of every finding this campaign produced across nine independent review rounds, DRIFT-198-I009-042 is
the FIRST that measurement could not reproduce.**

| Campaign fact | Value |
| --- | --- |
| Independent rounds spent (iterations 009 + 010) | 9 |
| Findings reported and confirmed reachable | all but one |
| Findings not reproducible as reported | **1** (DRIFT-198-I009-042) |
| Nature of the miss | code reading CORRECT; the behavioural consequence drawn from it was wrong |

This is not a reason to discount the reviewer. The same instrument found the shadowing duplicate that
five rounds of point fixes could not converge on (-027), the canonical-versus-mirror miss that shipped
nothing to consumers (-030), the containment guard called from one mutator of five (-031), the
culture-aware dedup at twelve sites (-033), the lane that could false-green a container failure (-039),
and the lexical authority-store containment still open as -041. Its precision on this surface has been
high and its findings have repeatedly been sharper than the implementer's own review.

What the datum says is narrower and worth holding: **a reviewer's source reading and its behavioural
inference are separately reliable.** -042's reading of the code was exact. Its claim about what
`Directory.Exists` / `File.Exists` do with a broken symlink was not, and it was stated with the same
confidence as the reading. The implementer then propagated that claim into the ledger as "Confirmed
source evidence" without measuring it (DRIFT-198-I010-002), so the error compounded rather than being
caught at intake.

**The operational lesson**: a finding's *source* claim can be confirmed by reading; its *behavioural*
claim requires execution. Confirming the first and recording the pair as confirmed is the failure mode
this datum exists to name.

### DRIFT-198-I009-041 — T082 corrected in Iteration 010

- **Status**: resolved. `Get-ReviewAuthorityStorePath` is now the single choke point every read,
  write, and enumeration in `review-authority-store.ps1` resolves through, and it rejects a reparse
  point at the store root and at every existing ancestor component before returning a path. Verified
  locally with the same A/B discipline used for the mutation gate: fixtures for a link AT the store
  root, at a CAMPAIGN ancestor, and at a RUN ancestor.
- **RED proof (pre-fix, git-checkout A/B)**: 3 of 15 failed —
  `refuses to write through a reparse point AT THE STORE ROOT`,
  `... at a CAMPAIGN ancestor`, `... at a RUN ancestor` — each because the write silently succeeded
  and the fact landed inside the linked external directory rather than being refused.
- **GREEN proof (post-fix)**: 15/15, including a sanity control asserting an ordinary unlinked store
  root and ancestors still work.
- **Probe evidence for the escape itself**, measured before writing any assertion: with the store
  root a symlink to an external directory, `Write-ReviewAuthorityImmutableFact` returned
  `created=True` and the fact file existed under the EXTERNAL target — confirming the vulnerability
  as a real write-through-link, not merely a missed check.
- **Unlike DRIFT-198-I009-042**, this defect is not platform-dependent in the same way — .NET's
  `Directory.CreateDirectory`/`FileStream` follow reparse points identically on Windows and POSIX —
  so local A/B proof plus the standard three-volume CI run is the applied rigor, rather than a
  dedicated cross-platform RED push.

### DRIFT-198-I009-043 — T084 corrected in Iteration 010

- **Status**: resolved. `tests/unit/consumer-applicability-firewall.tests.ps1` gains Test 8, a
  case-distinct fixture (`docs/Policy.md` + `docs/policy.md`, each with a distinct mandate) that
  measures whether this runner's volume can materialize both, and if so asserts BOTH reach finding
  generation. This is coverage-only: the underlying fix (Ordinal `HashSet` dedup, replacing
  `Sort-Object FullName -Unique`) already shipped in Iteration 009 at `f738f5cf`/`3d74f123`.
- **Measured, not assumed**: on this Windows dev machine the volume folds case, so
  `[volume-oracle] case-distinct fixture: listing=[Policy.md] bothListed=False` — the second
  `Set-Content` silently overwrote the first file at the OS level, and the case cannot be
  materialized here. Recorded explicitly rather than silently skipped, per the T080 discipline. The
  real filesystem proof depends on ubuntu-latest/ext4, already measured case-sensitive in T080's own
  CI evidence.
- **Logic-level A/B, since no filesystem here can hold the state**: fed two synthetic in-memory
  entries differing only by case directly into both dedup implementations. `Sort-Object FullName
  -Unique` (pre-fix): input 2, output **1** — drops one. The current `Ordinal HashSet` dedup: input
  2, output **2** — keeps both. Confirms the fixture's shape would have caught the original defect,
  independent of any one runner's volume.

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
