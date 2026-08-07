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

### DRIFT-198-I009-041 — T082 PARTIALLY corrected in Iteration 010; NOT delivered

- **Status**: **SUPERSEDED — see DRIFT-198-I010-004.** This entry originally read "resolved". That was
  wrong, on a coverage claim I never verified. The certifying round found that
  `Get-ReviewAuthorityStorePath` contains path RESOLUTION only; paths obtained by ENUMERATION bypass it
  entirely at four sites. **-041 is NOT delivered**, Iteration 009's closure trigger does NOT fire, and
  release-claim limitation 1 is not removed. What follows below is accurate about what T082 DID do —
  it is retained unchanged as the record of a correct-but-incomplete fix.
- **What T082 actually delivered**: `Get-ReviewAuthorityStorePath` rejects a reparse point at the store
  root and at every existing ancestor component before returning a path, and every caller that
  constructs a path from a known relative string routes through it. Verified locally with the same A/B
  discipline used for the mutation gate: fixtures for a link AT the store root, at a CAMPAIGN ancestor,
  and at a RUN ancestor. That work stands; it is the claim of COMPLETENESS that was false.
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
- **T081 makes this A/B permanent.** The git-checkout comparison above was a one-time manual check;
  `review-authority-store-mutation-gate.Tests.ps1` mutates `Get-ReviewAuthorityStorePath` back to its
  pre-fix lexical-only shape (regex-derived from the current file, not hand-written to be caught) and
  requires the T082 fixtures to fail against it on every future run. **Positive-verified before
  trusting the mutant**: dot-sourced in isolation and probed directly — a linked store root returned
  `ACCEPTED:<path>` rather than throwing, confirming the mutation genuinely removed containment and
  is not merely textually different. Measured: CONTROL 0 failed / >0 passed against the real store;
  3 fixtures failed against the mutant, matching the original manual A/B exactly. Two bugs found and
  fixed while building this, both about the mutant's OWN runtime environment rather than the
  mutation logic: (1) the mutant's `$PSScriptRoot`-relative self-load guards for
  `review-authority-core.ps1`/`path-identity.ps1` resolved to the scratch directory it was written
  to, not the real tree, so both real siblings must be copied alongside it; (2) the regex-based
  mutation itself was correct on the first attempt (verified via `[System.Management.Automation.Language.Parser]::ParseFile`,
  zero syntax errors), so the failure was entirely in the harness around it, not the mutation.

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

### DRIFT-198-I010-006 — "campaign terminated by human rule" is inexpressible to the review gate

- **Status**: open; **sixth instance** of the disposition-vocabulary gap. Clustered 2026-08-01 with
  DRIFT-198-I009-021, -034, -044 and DRIFT-198-I010-001. Moved to **beta3, alongside the containment
  consolidation** — the vocabulary proposal (Proposal 206) is now overdue at six instances.
- **Severity**: minor mechanism gap, with a real operational cost — it demands a paid action the
  governing rule forbids
- **Type**: review-gate disposition vocabulary
- **Observed live, this iteration**: after the termination rule fired on DRIFT-198-I010-004, every
  subsequent Stop emitted `Specrew campaign review — review-stale ... Implementer action:
  request-current-digest-review`. That action would spend round 2 of a 3-round cap to re-certify a tree
  whose only change since the reviewed digest is the RECORD of why certification failed — with the
  blocking defect deliberately untouched, so it would simply be found again.
- **The gap**: the campaign gate models exactly two states for a moved digest — authorized, or needs a
  review. It has no way to record "this campaign was TERMINATED by a human rule, and no further round
  is authorized". So its only honest output is a request the governing decision forbids, and the agent
  must leave a live block unanswered by design. An agent with less explicit instruction would comply
  and spend the slot.
- **Distinct from -034**, which is about a single finding's deferral. This is about the CAMPAIGN's
  terminal state.
- **Required correction (deferred to beta3)**: a terminal campaign disposition — human-authorized, with
  the authorizing reference and the rule that fired — which suppresses `request-authorized-review` and
  `request-current-digest-review` for that campaign until a human explicitly reopens it.

### DRIFT-198-I010-003 — the material-work Stop packet over-fired on turns with no material work

- **Status**: resolved 2026-08-01. Fixed as a priority instruction, spending part of the slack T083's
  withdrawal freed, per explicit maintainer override of the "do not backfill slack" guardrail — this
  is exactly what slack is for.
- **Severity**: major, consumer-reachable on every host running the governed Stop hook — alarm-fatigue
  class, actively degrading the human's trust in the packet signal
- **Type**: transcript-heuristic miscounting
- **Reported**: live, in the maintainer's own concurrent session with the Reviewer role, on a turn
  containing ZERO tool calls — pure conversational analysis. The Stop hook demanded the five-part
  packet anyway. This had been an open irritant "for days"; prior attempts to fix it at the
  instruction-text level (the refocus discipline already states "quick discussion... stays
  conversational; length alone does not count") did not hold, because the enforcement mechanism never
  implemented that policy.
- **Confirmed root cause, measured against this session's OWN live transcript
  (`83188c58-3c60-434c-92d8-4eb830ec52a2.jsonl`) before writing any fix**:
  `Get-SpecrewLongTurnSignal` in `specrew-conformance-provider.ps1` counted RAW `"type":"assistant"`
  JSONL lines since the last human message, on the theory that line count approximates turn count.
  It does not. Claude Code's transcript writer splits ONE logical assistant response into SEVERAL
  separate JSONL records — one per content block (a thinking block, a text block, a tool_use block) —
  all sharing the SAME top-level `message.id`. Grepped directly: consecutive raw assistant lines in
  the live transcript paired up under one shared `"id":"msg_..."` value. A single verbose,
  zero-tool-call reply, split into a thinking fragment plus several text fragments, could already read
  as multiple "entries" before any tool ran; a short 2-3-call read-only status-poll turn (each call
  contributing a thinking+tool_use pair under its own message id) could cross the 15-entry threshold
  the same way a genuinely long, many-STEP investigation was meant to.
- **Why the existing regression test (case PH-d, 2026-07-14) could not have caught this**: PH-d's own
  fixture helper (`New-Transcript`) writes ONE raw line per synthetic "turn" with NO `message.id`
  field at all — it always modeled "N turns = N lines" and never exercised the fragmentation shape
  that real transcripts produce. The bug was invisible to the very test written to guard this lane.
- **Correction**: the count now dedupes by `message.id` (extracted via a cheap regex, preserving the
  documented "no per-line JSON parse" performance doctrine), so ONE logical response counts ONCE
  regardless of how many raw lines the writer split it into. A line whose id cannot be extracted (a
  synthetic/legacy transcript, or an unrecognized shape) still counts on its own — fail toward STILL
  counting, never toward silently going quiet, matching the function's existing fail-open direction.
  Applied identically to both `extensions/specrew-speckit/scripts/specrew-conformance-provider.ps1`
  (canonical) and `.specify/extensions/specrew-speckit/scripts/specrew-conformance-provider.ps1` — the
  LATTER is what this repository's own live Stop hook actually executes
  (`.specify/extensions/specrew-speckit/scripts/specrew-hook-dispatcher.ps1`), confirmed identical to
  canonical in this function's body before either was touched.
- **Four new regression fixtures added to `tests/integration/conformance-detection.tests.ps1`** (cases
  PH-g/h/i/j), built with a NEW raw-JSONL helper that faithfully reproduces the fragmentation shape
  (unlike `New-Transcript`):
  - PH-g: 5 real zero-tool replies fragmented into 15 raw lines — MUST NOT block. RED before the fix.
  - PH-h: 3 real tool round-trips fragmented into 15 raw lines — MUST NOT block. RED before the fix.
  - PH-i: a short, heavily-fragmented turn that ALSO has a real file-changing surface — MUST still
    block (the material-delta lane is independent of this fix; unaffected either way).
  - PH-j: 16 genuinely distinct real tool round-trips — MUST still block. Proves the fix narrows the
    COUNT, it does not raise the BAR: a genuinely long investigation still owes the packet.
- **Two defects found and fixed in the FIXTURES themselves while proving this, both instructive**:
  (1) PH-j's first draft ended every synthetic message in a bare `tool_use` fragment with no trailing
  text anywhere in the transcript. The provider's SEPARATE `$lastAssistantText` extraction (used to
  decide whether a stop is even assessable, and whether a packet is already present) walks backward
  for the last non-empty assistant `.text` — with none anywhere, `$canAssess` was false and NOTHING
  downstream ever evaluated, independent of the long-turn fix entirely. A real agent turn ending on
  Stop always has SOME trailing text; the fixture was unrealistic, not the product. Fixed by requiring
  a minimum 3-fragment shape (`thinking` → `tool_use` → `text`) whenever `-ToolCall` is set.
  (2) Diagnosing this required extracting the target function from the live provider file into an
  isolated probe script; the naive extraction via `grep -v` piping stripped CRLF to LF, and a blind
  restore would have shown as a whole-file diff. Verified with `diff` on CR-stripped copies of both
  the pre- and post-instrumentation files before trusting the result, then explicitly restored CRLF.
- **Registry**: `tests/f198-regression-suite.ps1:160` already covers
  `conformance-detection.tests.ps1`; no new registration needed. Full suite: 75/75 passed, exit 0.

### T085 pre-certification evidence — three-volume matrix, read directly from job logs

Measured at `493128d3` (stream A complete: T080/T081/T082/T084 delivered, T083 withdrawn), per the
plan's own standard — measurements pulled from the job logs, not inferred from a green conclusion.

| Leg | Measured volume | Dangling-link defect (DRIFT-198-I009-042) | os-family mutant |
| --- | --- | --- | --- |
| windows-latest / NTFS | case-sensitive=False | not reachable | disagree=False → undetectable here |
| ubuntu-latest / ext4 | case-sensitive=True, `[REPO, Repo]` | not reachable | disagree=False → undetectable here |
| macos-latest / APFS | case-sensitive=False | not reachable | **disagree=True, harness-failed=8, CAUGHT-HERE-REQUIRED** |

Consistent with T080's original finding: the dangling-link and symlink-loop constructions both measure
`gap=False` on all three volumes (DRIFT-198-I010-002's disposition holds under repeated measurement),
and the macOS leg remains the only one that can catch the historical OS-family mutant — the harness's
falsifiability is intact after every commit in this iteration, not just the one that introduced it.

### DRIFT-198-I010-004 — T082's containment covers path RESOLUTION, not ENUMERATION; -041 is NOT delivered

- **Status**: open — **BLOCKING**, reported by the certifying round. **NOT fixed: the termination rule
  fired.** DRIFT-198-I009-041 is therefore **NOT delivered** by Iteration 010.
- **Severity**: blocking security defect (read path), consumer-reachable via checkout-borne links
- **Type**: path containment — the SAME class T082 corrected in this iteration
- **Authority evidence**: `evidence/independent-review-64878edb-certify-result.json`, blocking finding,
  at `scripts/internal/continuous-co-review/review-authority-store.ps1:309`.

**Confirmed in source, and WIDER than reported.** T082 hardened `Get-ReviewAuthorityStorePath`, which
resolves a RELATIVE path to an absolute one. Every caller that constructs a path from a known relative
string is contained. But paths obtained by ENUMERATION are never routed back through it — they are
handed straight to the reader. The reviewer named two sites; direct measurement of all
`Enumerate*` call sites in the module finds **four**:

| Line | Function | Shape | State |
| --- | --- | --- | --- |
| 200 | `Get-ReviewAuthorityCampaignFacts` (grants/reservations/spend/releases) | `EnumerateFiles(AllDirectories)` → read | **unprotected** (reviewer-named) |
| 309 | `Get-ReviewAuthorityCampaignRunResults` | `EnumerateDirectories` → `Join-Path` → read | **unprotected** (reviewer-named) |
| 362 | `Get-ReviewCampaignHumanDispositionFacts` | `EnumerateFiles(AllDirectories)` → **read**, then compare | **reads first, and the compare is lexical** |
| 447 | `Get-ReviewAuthorityClaimFacts` | `EnumerateFiles(TopDirectoryOnly)` → read | **unprotected**, not reviewer-named |

Line 362 deserves its own note: it does compare `GetFullPath($file)` against a `Get-ReviewAuthorityStorePath`-resolved
expected path — but it does so AFTER `Read-ReviewAuthorityFactFile` has already opened and read the
entry, and `GetFullPath` does not resolve reparse points. That is precisely the lesson
DRIFT-198-I009-041 recorded: lexical comparison is not containment. A link whose NAME matches the
fact's own `run_id`/`disposition_id` passes the check while pointing outside the store.

**Reachability**: a checkout-borne link — a fork PR or untrusted branch carrying
`.specrew/review/authority/campaigns/<id>/runs/<valid-name>` as a symlink to an external directory
holding a schema-valid `result.json` — puts out-of-store data into signoff and allowance decisions.
Git carries symlinks in tree objects, so this needs no local action by the user, and Specrew runs over
branches under review. Same threat model already documented in the narrowed release claim.

**My own false claim, stated plainly.** T082's commit message and its drift entry both asserted: *"This
module's every read, write, and enumeration resolves its path through this ONE function, so hardening
it here covers the whole module rather than each call site."* That is **false**. I verified it by
reading the call sites OF `Get-ReviewAuthorityStorePath` and confirming each was contained — never by
auditing every READ path to check whether it reached that function at all. Enumeration-derived paths
never do. This is the mirror image of the DRIFT-198-I010-002 error: there I propagated a reviewer's
unverified BEHAVIOURAL claim; here I authored an unverified COVERAGE claim. Both were stated with the
same confidence as the parts I had actually measured.

**Consequences (not acted on — the rule fired):**

1. **DRIFT-198-I009-041 is NOT delivered.** T082 is a partial correction, not a complete one.
2. **Iteration 009's closure trigger does NOT fire.** It requires -041 delivered; it is not. Iteration
   009 stays held open at `reviewing`, exactly as its Closure Record specifies.
3. **Limitation 1 of the narrowed release claim is NOT removed** — it must be revised to describe the
   partial state (resolution contained, enumeration not), rather than struck.
4. **The plan's Release-Claim Impact table is now wrong** where it says limitation 1 is REMOVED by T082.
5. **Vehicle assigned 2026-08-01 — a beta3 CONTAINMENT-CONSOLIDATION feature, explicitly NOT another
   per-site fix.** Maintainer decision. Two consecutive per-site containment fixes have now failed a
   completeness review — DRIFT-198-I009-031 (guard on one mutator of five) corrected in iteration 009,
   then T082/-041 (resolution but not enumeration) corrected here — which is the same "locally right,
   too shallow" shape that ended iteration 009's campaign. A third per-site patch would repeat it.
   Apply instead the playbook that actually ended the path-identity class's recurrence:
   - **ONE containment primitive** covering BOTH resolution and enumeration, so there is a single
     definition rather than a guard replicated per call site.
   - **Link-state oracle fixtures for enumerated children** — the volume as oracle, extended to the
     entry-traversal path that T080's fixtures never reached.
   - **A structural rule**: no direct enumeration-read inside the store without the primitive. This is
     what would have caught the present defect at authoring time, exactly as the
     `Sort-Object -Unique` structural rule catches its class.
   - **A mutation gate** proving those fixtures can fail, per T081's pattern.

### DRIFT-198-I010-005 — iteration 010's state.md was never updated; the supported resume path is broken

- **Status**: open — major, reported by the certifying round. **NOT fixed pending the maintainer's
  decision** (see the note on scope below).
- **Severity**: major — breaks the supported resume path for this iteration
- **Type**: artifact/state honesty — a DIFFERENT class from the containment defects corrected here
- **Authority evidence**: `evidence/independent-review-64878edb-certify-result.json`, major finding, at
  `specs/198-beta2-hardening/iterations/010/state.md:4`.
- **Confirmed in source**: `state.md` still reads `**Last Completed Task**: (none)`,
  `**Tasks Remaining**: (populate from plan.md)`, and `- Execution has not started yet.` — while
  `plan.md` marks T081/T082/T084 `done` and T085 `in-progress`. T080 is also still `planned` in the
  plan table although its fixtures and evidence are committed. `resume-iteration.ps1` parses the
  literal string `(populate from plan.md)` as a task ID and reports an unknown-task blocker, so a
  resumed session cannot recover the real T085 state.
- **Mine, and a repeat of a pattern already recorded this iteration.** I updated `plan.md` task rows
  after every task and never once updated `state.md`. This is the same failure mode as the T081 gap —
  claiming a status without checking the canonical record against reality — and it is the second time
  in this iteration.
- **Scope question for the maintainer, deliberately not decided here**: the termination rule ends the
  campaign on *"a new blocking or major finding of a class already corrected in this iteration."* This
  finding is major but belongs to no class corrected here — it is iteration bookkeeping, and correcting
  it is closeout work the closure process requires regardless, not a fix-and-recertify round on the
  surface under test. DRIFT-198-I010-004 fires the rule on its own merits either way.

### DRIFT-198-I010-007 — feature `tasks.md` stopped at Iteration 008; two iterations have no traceability of record

- **Status**: open, found 2026-08-02 while discharging the F-register obligation
- **Severity**: major — a bidirectional-traceability violation spanning two delivered iterations
- **Type**: feature-level traceability maintenance
- **Confirmed by direct search**, not inference: `specs/198-beta2-hardening/tasks.md` contains **zero
  occurrences** of `T072`–`T079` (Iteration 009) and **zero** of `T080`–`T085` (Iteration 010). Its
  task inventory ends with the Iteration 008 section and its
  `## Bidirectional traceability (tasks ↔ requirements)` block ends with the Iteration 008 check.
- **Consequence**: the tasks-stage rule is that every task maps to ≥1 FR/SC AND every FR/SC has ≥1
  covering task, run in both directions and written into `tasks.md`. For Iterations 009 and 010 that
  check was never run at the feature level. Fourteen delivered tasks have no traced requirement of
  record.
- **Root cause, and why it matters more than the bookkeeping**: Iteration 009's plan used the
  **F-labels themselves in its Requirement column** instead of FR IDs — and those labels resolved to
  nothing in the repository until
  file:///C:/Dev/specrew-beta2-hardening/specs/198-beta2-hardening/consumer-feedback-register.md
  landed today. So an iteration was planned, delivered, and reviewed against identifiers no reader
  could resolve, and the one mechanism designed to catch exactly that — the bidirectional check — had
  not been extended to cover it. The two failures are the same failure: traceability treated as a
  step that happened once rather than an invariant maintained per iteration.
- **Related**: this is the structural sibling of DRIFT-198-I010-005 (iteration `state.md` never
  updated). Both are records that drifted from disk truth because nothing checked them per iteration.
- **Deliberately NOT fixed here**: backfilling two iterations of bidirectional traceability is real
  work with a real estimate. Absorbing it silently into a closeout is the pattern this feature has
  spent nine iterations learning not to repeat. Scope and vehicle are a decision for Iteration 011's
  planning boundary.
- **Required correction (deferred)**: backfill the Iteration 009 and 010 task sections and their
  bidirectional checks in `tasks.md`; and, so it cannot recur, make the per-iteration traceability
  check a gate rather than a convention — the same "structural rule beats per-instance diligence"
  lesson the path-identity and containment classes both taught.

### DRIFT-198-I010-008 — a legitimate boundary RE-ENTRY cannot open a pending verdict

- **Status**: open, observed live 2026-08-02 while opening Iteration 011 phase 1
- **Severity**: major — the boundary mechanism cannot express the verdict stop it is designed for
- **Type**: boundary-cursor vocabulary (global monotonic cursor vs. legitimate re-entry)
- **Observed evidence, this session**: Iteration 011 was opened as a two-phase iteration by
  maintainer decision — phase 1 amends the spec (FR-019 scope, plus FR-066/067/068), phase 2 plans
  and implements against it. The spec amendments were written and committed as
  `boundary(specify)` commits `737aed76` and `327ac35c`. `sync-boundary-state.ps1` was then run for
  the `specify` boundary, twice — once without and once with `-FeatureRef` (which resolved
  correctly to `198-beta2-hardening`). **Both runs returned `pending_verdict_has_pending: false`
  with a null boundary, null approval phrase, and null marker, and
  `.specrew/runtime/pending-verdict-stop.md` was never created.** `active_boundary` was set to
  `specify`, but `last_authorized_boundary` remains `review-signoff` from Iteration 010.
- **The gap**: the boundary cursor is global and monotonic, so re-entering an EARLIER boundary for
  new work reads as backward movement rather than as a new crossing awaiting a verdict. There is no
  way to say "this feature has legitimately returned to `specify` for a scoped amendment". The
  machinery therefore cannot open the verdict stop for a boundary the human explicitly asked to be
  brought to them.
- **Not new — this is the SECOND recorded instance.** Iteration 006's `state.md` carries the same
  shape: *"the supported authorization API cannot append this entry because the stale global
  `last_authorized_boundary=before-implement` treats Iteration 006 `tasks` as backward movement.
  The ledger was not hand-edited."* Two instances, ~7 weeks apart, same root.
- **CLUSTERED 2026-08-02, maintainer instruction at the specify verdict**: joins the
  machinery/vocabulary cluster carried by Proposal 206 into beta3, alongside
  DRIFT-198-I009-021/-034/-044 and DRIFT-198-I010-001/-006. It is adjacent but DISTINCT in
  field: those five are about *dispositions* being inexpressible, this is about the *cursor*
  being unable to represent a legitimate re-entry. Same schema-completeness root, different
  vocabulary — which is exactly why it belongs in one designed vocabulary rather than a
  seventh point fix.
- **Directly relevant to FR-066**, authored in this same phase: FR-066 requires that first-boundary
  ARRIVAL sync precede the first packet. This finding is its mirror — RE-ENTRY arrival has the same
  defect one level up, and a consumer running a two-phase iteration will hit it.
- **Handled honestly, not worked around**: the ledger was NOT hand-edited and no marker was
  fabricated. The boundary packet is rendered with its verdict stated in plain language and the
  mechanism gap declared, per the refocus rule that `pending-verdict-stop.md` is authoritative —
  when it does not exist, there are no authoritative values to quote.
- **Required correction (deferred)**: allow a recorded, human-authorized re-entry to an earlier
  boundary to open a pending crossing, so the cursor can distinguish "went backward" from "returned
  deliberately". Belongs with the beta3 vocabulary work (Proposal 206) rather than a point fix.

### DRIFT-198-I010-009 — the module-manifest sorter uses a culture-aware comparer

- **Status**: open, found 2026-08-02; **not fixed — out of the maintainer's declared phase-1 scope**
- **Severity**: minor, but in a class this feature has spent two iterations eliminating
- **Type**: path/string identity comparer
- **Observed evidence**: `Specrew.psd1` arrived dirty during this session's boundary work. The
  change is **reordering only** — verified: 411 entries before, 411 after, membership identical
  under `Compare-Object`. The reordering flips `Test-CopilotInstructionsChangeType.ps1` to AFTER
  `test-consumer-assumptions.ps1`, which is culture-aware collation order, not ordinal.
- **Root cause**: `scripts/psd1-sort.ps1` sorts with
  `Sort-Object { $_.ToLowerInvariant() }` — case-normalized, but then ordered by `Sort-Object`'s
  **culture-aware default comparer**. This is the same defect class as the `Sort-Object -Unique`
  finding that the path-identity structural rules exist to prevent (DRIFT-198-I009-027's cluster):
  culture-aware ordering of strings containing hyphens and mixed case is locale-dependent, so the
  same input can produce different manifests on different machines.
- **Why it matters beyond churn**: `Specrew.psd1` is the SHIPPED module manifest. A locale-dependent
  ordering means a contributor on a different culture regenerates a spuriously different manifest.
- **Why the structural rule did not catch it**: the rules scan for `Sort-Object -Unique` and
  OS-family case derivation. A bare `Sort-Object { ... }` with a culture-aware default is neither
  spelling — which is limitation 5 of the narrowed release claim (structural enforcement is textual,
  not syntactic) demonstrating itself on a new surface.
- **Required correction (deferred)**: sort with an explicit ordinal comparer, and widen the
  structural rule to catch culture-aware `Sort-Object` on path/identity collections generally rather
  than the two spellings it knows.

### DRIFT-198-I010-010 — machinery silently FALSIFIED a governed record: state.md rewritten to "not-started"

- **Status**: observed live and CORRECTED 2026-08-03; the underlying defect is open
- **Severity**: **major** — an automated writer asserted a false claim about delivered work, with no
  announcement. This is the honesty premise failing from the tooling side rather than the agent side.
- **Type**: task-progress tracker / state summary writer
- **Observed evidence**: while planning Iteration 011, a routine `git status` showed
  `specs/198-beta2-hardening/iterations/010/state.md` modified. The diff had replaced the
  human-corrected record with generated defaults:
  - `Iteration Status`: `reviewing` → **`not-started`**
  - `Last Completed Task`: the honest T084/T085 note → **`(none)`**
  - `Tasks Remaining`: `(none)` → **all six tasks**
  - and an inserted block reading **"Execution has not started yet. Task progress: 0 complete,
    0 in-progress, 6 pending, 0 blocked."**
  Every one of those statements is false. T080/T081/T084 are delivered, T082 is `needs-rework`,
  T083 and T085 are terminal-as-deferred, and the iteration was CERTIFIED AGAINST — the campaign
  `run-f198-i010-64878edb-certify` reviewed this work.
- **Root cause, located exactly**: Iteration 010 never had a `tasks-progress.yml`. One was
  **auto-created at 2026-08-03T04:57:11Z with every task `pending`**, and the `state.md` summary
  writer then trusted that fresh all-pending tracker over the existing honest content.
  The seeding gap is one projection: `Get-TaskProgressPlanRows` in
  `scripts/internal/task-progress.ps1` reads `plan.md`'s Tasks table and projects **Task, Title,
  Requirement, Story, Effort — and deliberately not Status**, although `plan.md` carries a Status
  column recording `done` / `needs-rework` / `deferred` per task. For iteration N ≥ 2 the code's
  own comment states that *"the ledger + iterations/&lt;N&gt;/plan.md are the source of truth"*, but
  because the projection drops Status, plan.md contributes nothing to a fresh ledger and the empty
  ledger wins uncontested. The stated design and the behaviour disagree.
- **Blast radius, measured**: the defect needs an OPEN iteration with no tracker. Across this
  feature's nine iterations, 001/002/005/006 lack one but are all `complete` or `abandoned`, and
  003/007/008/009 have one. **Iteration 010 was the only exposed target, and it was hit.**
- **Why Iteration 009 was not hit**: 009 has a populated `tasks-progress.yml` from 2026-07-26, so
  no fresh all-pending file was minted and its `state.md` is untouched. The defect needs the
  *absence* of a tracker on an iteration that already has history — exactly the shape a
  mid-lifecycle iteration carries.
- **This is DRIFT-198-I010-005's defect reintroduced by machinery.** -005 was that `state.md` had
  never been updated and said "Execution has not started yet"; it was corrected by hand as record
  honesty. The tracker then restored the identical false text automatically. A correction that
  tooling can silently revert is not a correction.
- **Correction applied now**: `tasks-progress.yml` populated by hand to match `plan.md` and
  `state.md` (`done` / `needs-rework` / `deferred`), with `completed_at` left EMPTY rather than
  back-filled with invented timestamps — the writer falls back to file order and yields T084
  correctly. `state.md` restored from git. Verified stable across subsequent tool calls.
- **A second, quieter defect surfaced by the same code**: the vocabulary does not agree with itself.
  `scripts/internal/task-progress.ps1` validates writes against
  `ValidateSet('pending','in-progress','complete','blocked')` and counts completion by
  `$_ -in @('done','complete')` — but Iteration 009's committed tracker uses `completed` and
  `deferred`, neither of which is in either set. Three vocabularies for one field.
- **Required correction (deferred)**: (a) carry `Status` through `Get-TaskProgressPlanRows` and seed
  a newly-minted ledger from it — or refuse to mint and say so — so a tracker can never assert
  `pending` for a task `plan.md` records as `done`; (b) the summary writer MUST NOT downgrade a
  recorded status without announcing it (NFR-002 — legitimate paths announce themselves);
  (c) reconcile the three status vocabularies. A regression test must prove (a) by minting a
  tracker against a plan whose tasks are `done` and asserting the summary does not say
  "not-started" — RED first, since this defect passed every existing test. Candidate for the beta3
  vocabulary work alongside DRIFT-198-I010-008.

### DRIFT-198-I010-011 — the iteration-plan scaffolder can see only 8 of the spec's 70 requirements

- **Status**: open, found 2026-08-03 while opening Iteration 011's plan
- **Severity**: minor-to-major depending on reachability — it silently breaks the SUPPORTED planning
  path for any spec that records requirement provenance
- **Type**: requirement-parsing format assumption
- **Observed evidence**: running the supported scaffolder for Iteration 011 —
  `scaffold-iteration-plan.ps1 -RequirementScope FR-019,FR-066,FR-067,FR-068` — failed with
  `Requirement(s) not found in spec: FR-019, FR-066, FR-067, FR-068`, although all four are defined
  in `spec.md`.
- **Root cause**: the parser requires the exact shape `- **FR-NNN**: <text>`
  (`^\s*-\s+\*\*(FR-\d+)\*\*:\s+`). Any parenthetical provenance inside the bold makes the
  requirement invisible. **Measured on this spec: 8 of 70 FR definitions match; 62 do not** — because
  `- **FR-008 (W1)**:`, `- **FR-015 (W8, amended by maintainer ruling …)**:` and
  `- **FR-045a …**:` are the dominant convention, and are the convention the spec itself teaches by
  example. `FR-045a` also cannot match `FR-\d+` at all.
- **Why the existing guard does not catch it**: iteration 006's T003 added graceful degradation for
  a spec with ZERO canonical FRs. This spec has eight, so the guard stays silent and the scaffolder
  instead throws on whichever requirements the planner actually asked for. The partial case is worse
  than the empty case, because the empty case warns.
- **Consumer-reachable**: any downstream project that records amendment provenance the way Specrew's
  own spec does hits this the first time it scopes an iteration to an amended requirement.
- **Workaround used**: Iteration 011's plan is hand-authored against Iteration 010's proven
  structure, which the governance validator checks. No scaffolder output was faked.
- **Required correction (deferred)**: accept provenance parentheticals and the `NNNa` suffix in the
  requirement pattern, and make the partial-match case warn with the count it could see rather than
  failing on the caller's scope.

### DRIFT-198-I010-012 — the ceiling-halt message teaches a command that throws in the shipped mode

- **Status**: open, found 2026-08-03 while writing limitation 8 of the narrowed release claim
- **Severity**: **major, consumer-reachable** — it is the documented escape from a limitation the
  release is about to ship, and it does not work
- **Type**: consumer instruction vs. runtime gate
- **Observed by reading the shipped chain end to end**:
  1. `scripts/internal/continuous-co-review/review-authority-mode.json` ships
     `{"schema_version":"1.0","mode":"campaign"}`, and it **is** in `Specrew.psd1`'s FileList — so
     every consumer runs in campaign mode, not just this repo.
  2. `review-authority-cutover.ps1:73` sets `campaign_authority_enabled = ($mode -ceq 'campaign')`.
  3. `scripts/specrew-review.ps1:803` then throws for **every** `--remediate` choice except
     `override-block`: *"Campaign remediation '&lt;x&gt;' does not create signoff authority; use a new
     explicitly authorized run."*
  4. But the ceiling-halt text at `worktree-reviewer.ps1:1337` instructs the consumer to
     *"run `specrew review --remediate more-time`, or approve the assistant doing it"*, and
     `specrew-review.ps1:105-110` advertises all seven remediation choices with no indication that
     six of them fail.
- **Consequence**: a consumer who hits the round ceiling is told to run a command that throws. This
  **compounds F10** and explains the maintainer's consumer test better than F10 alone does: the
  ceiling was mis-scoped AND the named escape was nailed shut, so every run halted with no working
  door. It also puts FR-018 — which REQUIRES the halt text name the sanctioned next step — in
  violation on the shipped default, and NFR-005 ("teach, don't trap") with it.
- **The door that does work** in campaign mode is a new explicitly authorized run: a fresh
  `--authorization-ref`, which mints a new grant with a slot. Re-using a previous reference resolves
  to the same grant id and grants no new slot
  (`review-campaign-orchestrator.ps1:888-908`), so the reference must be new.
- **Instruction correction, recorded**: the maintainer's 2026-08-03 verdict directed that the
  round-ceiling limitation "name the consumer workaround (the human-typed more-time command)" in the
  affected-users table. That instruction rests on a premise this finding falsifies. The table names
  the `--authorization-ref` door instead and warns against `more-time` explicitly. Written this way
  deliberately: a release claim that tells a consumer to run a command that throws is worse than one
  that names no workaround at all.
- **Required correction (deferred to beta3, with F10)**: either make the remediation doors reachable
  in campaign mode, or make the halt text and `--help` mode-aware so they teach the door that is
  actually open. A test must assert the halt message's named command succeeds in the shipped mode —
  the absence of that assertion is why this survived.
