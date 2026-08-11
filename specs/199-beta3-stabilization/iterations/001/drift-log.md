# Drift Log: Iteration 001

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

**Total drift events**: 27 (DRIFT-199-I001-001 through -027)
**Resolution status**: carried per event in each entry's own heading — several are marked open with a
recorded maintainer ruling, so a single rate here would misstate them.
**Specification drift**: None detected; the events are defect and process records.

## THE AUTHORIZED SIGNOFF ROUND — and the LIVE ACCEPTANCE MEASUREMENT for FR-001..FR-004 (2026-08-11)

Run `run-20260811-093414640-d58e787b`, host codex, authorization reference
`beta3-i001-signoff-round-1`, one slot, reserved against the SAME single grant (reservations 3 -> 4 —
grant reuse working on a live authorized round, not a fixture).

**Transcribed from the run, not drafted ahead of it:**

> `review terminal elapsed=817.7s remaining<=82.3s tree=dead output=observed validated-findings=8`
> `- terminal-result-published`
> `Run: run-20260811-093414640-d58e787b  Status: terminal  Invoked: True`
> `Verdict: findings  Completion: complete  Currentness: current  Can approve current: False`
> `Observed elapsed: 817.7s  Heartbeats: 99  Usage: unavailable`

**2 blocking, 5 major, 1 minor.** The full finding text is in the run's terminal result under the
authority store; the two blocking ones are verified on disk below.

### THE ACCEPTANCE MEASUREMENT — FR-001 through FR-004 are NOT MET on the shipped path

Each observation is what the RUN showed, with the limit of what it establishes stated beside it. None is
asserted from the code.

| FR | What the run showed | Limit of this observation |
| --- | --- | --- |
| **FR-001** — render the decision surface and terminate the round loop | The round DID terminate after ingest (`Status: terminal`, one round, no second invocation). **NO decision surface was rendered** — the command printed a flat findings list and exited. | Shows the terminal half holds and the surface half does not, ON THE PUBLIC COMMAND. It does not show the surface is absent from the engine — `Invoke-ReviewCampaignRun` does return one. |
| **FR-002** — severity groups, non-gating minors, cost, budget position, recommendation, three numbered options, nothing-spends line | **NONE of these appeared.** Output was `[severity] text` lines. No cost, no budget, no recommendation, no options, no nothing-spends line. | Shows the consumer surface is absent on the shipped path. Says nothing about `Format-ReviewCampaignPauseSurface`, which is unit-green and simply never reached. |
| **FR-003** — continuation is an explicit human choice, single-run grant, budget of 4 | **NOT EXERCISABLE.** No continuation was offered, so no choice could consume a grant. The ALLOWANCE half was observed: one grant carried a 4th reservation. | Shows the human-choice half is unreachable. It does NOT show the single-run rule is broken — that rule is unit-pinned and was never given the chance to run. |
| **FR-004** — minors never gate, auto-carried as follow-ups | The minor finding did not gate (`Can approve current: False` is driven by the blocking/major set). **Whether it was auto-carried as a recorded follow-up is NOT VISIBLE** in the output. | Shows non-gating only. The carry half is unobserved, not confirmed. |

**The cause is finding 2, verified on disk**: a workspace search finds **ZERO production references** to
`Write-ReviewCampaignPauseDecisionFact`, `Test-ReviewCampaignContinuationAuthorized`, and
`Invoke-ReviewCampaignStopHereLanding`. `Invoke-ReviewCampaignCommand` (`review-campaign-orchestrator.ps1:1100`)
mentions neither `pause` nor `slot_restored`. **The economics core exists as helpers and tests and is not
reachable by a consumer.**

### The two blocking findings, VERIFIED on disk rather than taken from the reviewer

- **Packaged install would be broken.** `Specrew.psd1`'s FileList does NOT contain
  `reparse-tag-policy.ps1` or `specrew-consumer-language.ps1`, while it DOES contain
  `path-identity.ps1` — so the pattern exists and the two new files were simply never added. `_load.ps1`
  and `review-authority-store.ps1` hard-depend on the reparse policy, so a consumer installing the
  packaged beta3 gets an engine that fails to load. **A defect introduced by this feature's own new
  files.**
- **The pause protocol is unwired**, as measured above.

### What this says about the session, recorded because it is the durable part

**I spent the day catching "the wiring is what drifts" one layer at a time — the demotion marks, the
verification diagnosis, the restored-slot note, the fifth failed-run return — and the TOP-LEVEL wiring
of the feature's headline capability was missing the whole time.** Every guard I wrote was inside a
layer; none asked whether the layer was reached from the shipped command. The F4 disclosure is the
sharpest instance: carried through five returns, guarded, rendered in the CLI, transcribed from a live
stop — and dropped by the projection between them, which no guard covered.

**The reviewer found in one round what four suites and a day of my own measurement did not**, because it
asked a question I never asked: *can a consumer reach this?* That is the same gap the gate-preflight
finding names — a reviewer cannot see the packet, and my guards could not see the command.

## T008 — re-read against its task text, clause by clause (2026-08-11)

Re-read rather than closed from memory of having worked on it, which is the standing rule. Its text has
five clauses; three are satisfied outright and TWO DEVIATE, both recorded rather than papered over.

| Clause | State |
| --- | --- |
| the pre-invocation path (`preflight-failed`, `claim-contended`, `launch-failed`) **publishes run records** | **SATISFIED** — asserted per outcome in the three-failure sequence |
| **never consumes the allowance** | **SATISFIED** — 0 spends, 3 releases, slot still available, each assertion naming WHICH counter |
| **aligned to the legacy spend-class rule** | **SATISFIED** — `Get-ContinuousCoReviewRoundSpendClass` pins `preflight-failed` as consuming neither budget, and the campaign path was measured to match |
| **"RED: the T067 three-infra-failure sequence..."** | **DEVIATES — it never went red** |
| **owns `tests/continuous-co-review/unit/spend-accounting.Tests.ps1`** | **DEVIATES — that file does not exist** |

**DEVIATION 1 — the RED never happened, and that is the finding.** The task specifies a RED fixture. All
of T008's cases passed on first run with zero product change, because **grant reuse and
non-consumption already worked** — measured 12 times across five real authority stores. A RED was
impossible without breaking something first. Reported throughout as a CHARACTERIZATION rather than a
repair, and the honest framing was committed BEFORE the measurement precisely so this outcome could not
be quietly relabelled. The one thing F4 turned out to be — a restored slot nobody surfaced — was a
DISCLOSURE gap, and that fix did go red first.

**DEVIATION 2 — the named test file does not exist.** T008 names
`tests/continuous-co-review/unit/spend-accounting.Tests.ps1`. The work landed in the pre-existing
`review-spend-allowance.Tests.ps1`, which ALREADY owned two-budget accounting (`provider spend vs round
allowance`, lines 132-151) and the allowance-reset rules. **Creating the named file would have split one
subject across two homes** to satisfy a path, which is how a suite becomes hard to reason about. Same
class as T006's "frozen-snapshot check" — a task text naming a surface that does not exist — and handled
the same way: record it, do not invent the artifact to match the sentence.

**Conclusion**: T008's substance is delivered and its deviations are recorded, so it closes.

## T012 — the 009/010 registry-vs-claim wording inconsistency, RESOLVED (records-only, 2026-08-11)

Carried into this feature as item 10 and marked `[research-needed]`: *"specifics to be pulled from the
198 records during implementation."* Pulled, and both sides are quoted rather than summarised.

**THE 009 SIDE — the retro named the problem and assigned it a vehicle**
(`198/iterations/009/retro-draft.md:146`):

> `Establish one local command that runs exactly what CI runs (lint + registry + bootstrap), or state`
> `per-claim that "registry green" excludes them | Reviewer | Iteration 010`

**THE 010 SIDE — the claim was then made bare** (`198/iterations/010/drift-log.md:331-332`):

> `**Registry**: tests/f198-regression-suite.ps1:160 already covers conformance-detection.tests.ps1;`
> `no new registration needed. Full suite: 75/75 passed, exit 0.`

**THE INCONSISTENCY, stated exactly**: 009 required that a "registry green" claim either be backed by a
command running everything CI runs, or SAY what it excludes. 010 did neither — *"Full suite: 75/75
passed, exit 0"* reads as total coverage while the registry excludes lint and the bootstrap suites. The
words "full suite" are doing work the measurement does not support.

**WHY IT MATTERS BEYOND TIDINESS**: this is the honest-claims class this whole feature is about. A
reader taking "full suite passed" at face value believes CI would pass; a lint or bootstrap failure then
arrives as a surprise from a system that had reported itself green. It is the same shape as a demotion
nobody can see, in the evidence record rather than the console.

**RESOLUTION (records-only, this feature's convention going forward)**: **a suite claim states its
SCOPE and its EXCLUSIONS, or it names the command that ran.** Not "full suite: 75/75" but "the
deterministic registry lane: 75/75, exit 0 — excludes markdownlint and the bootstrap suites, which run
as separate CI jobs." Every measurement recorded in this feature already follows it — the seventeen are
always reported as `N failed / M passed across tests/continuous-co-review/unit`, naming the path rather
than claiming totality.

**NOT WRITTEN INTO THE 198 RECORDS.** `spec.md` declares that ledger a read-only input committed on
another branch; correcting another feature's records from this one is the cross-boundary write the
governance model exists to prevent. The resolution is recorded here and surfaces at closeout.

## METHOD RULES TO CARRY — staged for the ledger's method-rules section (maintainer ruling, 2026-08-10)

**Ruling**: both homes, differently. The INSTANCES stay in this drift log as evidence — they are what
make the rules credible. The RULES themselves go to the carry ledger's method-rules section, because
they apply to every feature and the ledger is what beta4 inherits. **A rule that lives only in one
iteration's drift log dies with that iteration.**

**NOT WRITTEN TO THE LEDGER FROM HERE, and that is deliberate.** `spec.md` declares
`C:\Dev\specrew-beta2-hardening\specs\198-beta2-hardening\beta3-carry-ledger.md` a **read-only input**
committed on another branch. Writing into another feature's records from this one would be exactly the
kind of unauthorized cross-boundary edit the governance model exists to prevent. They are staged here,
verbatim and ready to paste, for the closeout leg (T012 / FR-021) or the maintainer to carry across.

> **RULE — a fixture can only prove the shape it invents.** When a function consumes data produced
> ELSEWHERE — a filesystem, another builder, an external system — synthesised inputs test the AUTHOR'S
> MODEL of that data, not the data. Either feed it a real artifact once before the fixture is believed,
> or read every field defensively and pin the partial case explicitly. A green suite over invented
> inputs is evidence about the author, not about the world.

*Evidence: DRIFT-199-I001-023, -024, -025 — three instances in a single day, the second inside the fix
for the first, and the third inside the fix for the second.*

> **RULE — comments record intent; they do not enforce it. Where a comment states a rule that matters,
> add a guard that asserts it.** The author who writes the rationale is not thereby protected by it.

*Evidence: twice in one day the same author wrote a rationale and then built the exact failure it warned
against — the starter plan scaffolding a command that could not run, minutes after commenting that this
was the thing to avoid; and the `@()` array-nesting bug, documented in a comment ~300 lines above the
line written, and read that same day. The countermeasure that DID work is the structural fixture
asserting the diagnosis composer's body never mentions `stdout`/`stderr`/`ReadAllText`.*

> **RULE — in a ledger with nested identity paths, COUNT THE LEAF FACTS.** Any aggregate identity
> computed over CONTAINER counts silently encodes an occupancy assumption — that every container is
> populated — and it will be wrong precisely when something was minted and never used, which is the
> state you are usually investigating. Derive nothing from `A - B` across two ledgers when you can count
> the thing itself.

*Evidence: DRIFT-199-I001-026 — both parties made this error in mirror image on the same store within an
hour. One derived reuses as `reservations - grants` and produced a committed, false defect claim; the
other counted grant subdirectories as reservations and produced arithmetic that would not close. The
stores were clean throughout; only the counting was wrong.*

**RULED IN 2026-08-11 — this rule joins the other two in the ledger**, with the maintainer's refinement:
the abstract form is not checkable in review, the operational form is. Staged in the operational form.

> **RULE — IF A GUARD ASSERTS A COUNT, ASK WHAT DEFINES THE SET.** A count means something over a set
> defined by the INVARIANT; over a hand-enumerated list it silently converts *"I found four"* into
> *"there are four."* When the invariant is "every X must do Y", assert it against the property that
> MAKES something an X, never against the incidental form of the X's you happened to find.
>
> **The diagnostic for a correctly-stated invariant**: out-of-scope cases fall out NATURALLY instead of
> needing an exception list. If you are writing an exception, the invariant is probably still describing
> forms rather than the property.

*Evidence: TWO source guards in one session, both mine, both rewritten after failing to guard what they
claimed. The first sliced a function body with `.*?\n\}`, stopped at the first nested brace, and guarded
almost nothing. The second keyed on `status = 'failed'; reason = $reason`, asserted EXACTLY four
matches, and went green while a fifth return - `status = 'not-started'`, reason composed inline -
restored a slot and dropped the fields fifty lines away. It was written specifically to stop a fifth
return from doing that.*

*THE WORKED EXAMPLE, kept because the rule is easier to agree with than to apply: the fix in both cases
was to assert the INVARIANT rather than the form — slice to the next top-level function; match on
`$failed.` appearing in the returned object. The count then became a FLOOR (`>= 5`), guarding only
against the regex silently matching nothing, since an exact count was the defect itself.*

*THE COMPANION DIAGNOSTIC, which is the checkable half: the `$failed.` phrasing excludes the
reservation-refused return NATURALLY, because that return genuinely has no `$failed`. The
`status = 'failed'` phrasing would have needed the author to already know every status a return might
carry — which is exactly what they did not know. When out-of-scope cases need an exception list, the
invariant is still describing forms.*

*Distinct from the synthesis rule, and worth separating: that one is about INPUTS (invented data testing
the author's model of real data). This is about the PREDICATE (an invented enumeration testing the
author's model of the code's shape). Same failure, opposite ends of the fixture.*

> **RULE — A SUITE MADE ONLY OF PROHIBITIONS IS SATISFIED BY SILENCE.** For every *"must not appear"*,
> ask what MUST appear instead, and assert that too. A guard that only forbids is satisfied by an empty
> message, and deleting the offending sentence will always pass it.

*Evidence: the stop-block rewrite asserted "no banned noun", "no raw route name", "no agent directive" —
every one a prohibition. The block then rendered with NO NEXT STEP AT ALL, because the machinery-worded
action line had been deleted rather than translated, and every fixture stayed green. It was caught by
reading a live stop, not by the suite. The worked example is the case added afterwards: the block must
MATCH `What to do` and match the command, not merely fail to match the token.*

*This is the same failure as "demote, never discard" seen from the test side: the rule says do not delete
the signal, and a prohibition-only suite cannot tell you when you have.*

## BETA4 LIST — everything this feature routed out, collected in one place

Scattered "routes to beta4" clauses are easy to lose at closeout, so they are collected here with the
entry that carries the full reasoning. **This section is a pointer list, not the record** — each item's
evidence stays in its own entry.

| Item | Why it is not in scope | Entry |
| --- | --- | --- |
| **Read the REAL reparse tag** (`IO_REPARSE_TAG_CLOUD*` vs `IO_REPARSE_TAG_APPEXECLINK`) — the precise version of what the non-linking ruling APPROXIMATES. Needs P/Invoke. Belongs with the path-identity consolidation. | Adding P/Invoke to a shipped safety-critical hot path at the tail of an over-scope feature is the wrong trade; the hash carries the trust meanwhile. | -024 |
| **Path-identity consolidation** — make the comparer the ONLY REACHABLE path, not the recommended one. | A primitive that can be bypassed by forgetting a dot-source will be bypassed again; proven three times in one day. | -014, -017 |
| **Flush-race re-read variant** in the conformance Stop provider. | Changes read semantics in the most safety-critical hook path; beta4 does that deliberately, not as a fifth in-flight exception. | -015 |
| **Campaign command does not resolve the feature id** (`--feature`/`--iteration` must be passed by hand). | Sits in the CLI's campaign branch parameter contract, not in code this feature touches. | -009 |
| **Pending-verdict stop artifact not emitted at the plan sync.** | Diagnosis only was ordered; the fix stays deferred unless it lands in files this feature already touches. | -002 |
| **Trust-hardening `cycle_id`** — the validator warns `state-advance-without-verdict` while HOLDING the verdict, because persisted entries carry no `cycle_id` to match. | A WARN on a passing validator that blocks nothing; the fix is in the trust-hardening cycle model. | -022 |

| **GATE-PREFLIGHT SCRIPT** — deterministic boundary checks run before any packet is rendered. | The preflight exists as PROSE, not as a guard, so it covers what someone remembered to include. Three defects reached a boundary packet seconds before a spend. | see below |
| **CI RATCHET** — CI globs the test directories with the 16 inherited failures explicitly quarantined. | Same defect one altitude up: nothing mechanically holds the line, so a new failure is indistinguishable from an inherited one. **Status: UNDER CONSIDERATION as standalone work outside this feature — not ruled, do not build.** | the SEVENTEEN triage |

### The gate-preflight finding — why a reviewer could never have caught these (2026-08-11)

Three corrections were caught by the maintainer AT THE BOUNDARY, seconds before a provider spend: the
branch had **never been pushed** (98 commits on one machine), the packet's commit count was measured from
an arbitrary mid-session commit, and the status enum carried two values for one state.

**NONE of them was catchable by the campaign reviewer, for structural reasons worth recording rather
than rediscovering:**

- **It works in a DETACHED COPY.** Relational facts — *is this pushed*, *how far ahead of main* — do not
  exist there to be asked.
- **THE PACKET IS NOT A FILE.** The reviewer's input is a changed-file set, so the one artifact that
  reaches the human directly is the one artifact no reviewer ever sees. **Every claim in a boundary
  packet is unverified by construction.**
- **Machinery paths are STRIPPED** from its worktree, so `tasks-progress.yml` is not even present.
- **It is asked whether the CODE has defects**, not whether the CLAIMS are true.

**AND THE PREFLIGHT ALREADY EXISTS AS PROSE.** The discipline says to run validator / parity /
dirty-state / artifact / stale-phrase / packet / evidence checks before any boundary packet. **Searched:
nothing in `scripts/` checks push state or ahead-count** — the only `ls-remote` is
`specrew-update.ps1:423`, and it queries `--tags` for version resolution. The preflight DID catch the
missing `review.md`; it missed these three because those checks were never written.

**That is this session's own rules at process level, twice over**: *comments record intent, they do not
enforce it* — the preflight is a comment; and *a guard that enumerates covers what someone remembered*,
not what the invariant requires.

**THE CHECKS — all deterministic, zero-judgment, sub-second, no provider spend:**

> `git ls-remote --heads origin <branch>`   -> pushed at all?
> `git rev-list --count origin/main..HEAD`  -> does the packet's count match?
> `git status --porcelain`                  -> dirty paths, classified by kind
> `status:` values in `tasks-progress.yml`  -> enum consistent, count matches `state.md`?
> the boundary's owed artifact exists       -> already covered today

**ONE REFINEMENT, learned by running the checks by hand at this boundary.** The dirty-path check needs a
classifier, and the obvious one is wrong. Classifying by governance PREFIX (`.squad/`, `.specrew/`,
`.claude/`, `.specify/`) flags `specs/<feature>/iterations/<NNN>/state.md` as PRODUCT — but it is
TOOL-WRITTEN: the tracker sync rewrites its `**Updated**:` timestamp on every call. The same applies to
`tasks-progress.yml`. **A classifier that cries wolf on tool-written records is a classifier people
learn to skip**, which is how the real dirty path gets waved through. The records-only set must be
defined by WHO WRITES THE FILE, not by where it sits.

Verified at this boundary: the flagged `state.md` diff was exactly one line, the timestamp, and nothing
else.

**RECORDED, NOT BUILT.** Beta3 scope is closed and this is not on the acceptance bar.

**Explicitly NOT on this list, recorded so nobody re-adds it**: the shell-wrapper installer's blanket
reparse refusal. It was measured and found not to be an instance of the class on its own platform —
macOS/Linux only, enforced in code, and CloudFilter is a Windows mechanism. A deferral would have left
beta4 an item that does not exist. See the class sweep in -023.

## Before-implement verdict — ratification clause (maintainer, 2026-08-10)

Recorded verbatim in intent alongside the verdict, so the ledger explains itself without
cross-referencing. The verdict history would otherwise show a jump from `tasks` to
`before-implement` with three implement-labelled commits in between.

> This verdict authorizes ordinary implementation from here forward AND ratifies the
> three exception commits that preceded it — `afe1dd1e` (the activation-premise repair),
> `99860254` (the run-id minter fix), and `477a649c` (the committed verification plan) —
> each ruled in scope by the maintainer individually under the closed-scope exception,
> with its bounded instruction recorded in this drift log.

Hashes verified against `git log` before recording: all three resolve to the commits
named above.

## METHOD RULE — a relayed diagnostic is evidence only if the relayer measured it

Recorded 2026-08-10 at the maintainer's instruction, as a rule in its own right rather than as a
footnote to the defect that produced it.

> A diagnostic handed to the next session carries the authority of a MEASUREMENT only when the
> relayer actually measured it. Reading a function's head and its comment and reporting the result
> as verified is INFERENCE, and inference from a comment inherits whatever that comment gets wrong.

**The instance**: the session-opening brief stated that `Get-ContinuousCoReviewMachineryPaths` called
without `-RepoRoot` "returns the core list only" and ruled the previous session's hypothesis out on
that basis. The claim came from the function's own comment (`omit for the core-only list`). The
comment was false — the bare call returns THIRTEEN entries, three of them the co-review engine
itself — and the false clause was the whole defect (DRIFT-199-I001-016). Re-measuring found in one
probe what the relayed diagnostic had ruled out.

**Why it is worth a rule and not just a correction**: the two other hypotheses in the same brief WERE
measured and were correctly excluded, so the brief was right about everything it had actually run.
The failure mode is specific — a comment read as a result — and it is invisible at the receiving end,
because a relayed conclusion arrives stripped of how it was obtained.

**How to apply**: state the method alongside the claim when relaying a diagnostic ("measured, probe
output below" versus "read from the comment, unverified"), and re-measure anything that arrives
without one before letting it narrow a search.

## Post-boundary spec amendments (surface at review-signoff as a diff-to-approve)

Recorded per the 198 obs-7 lesson: amendments landing after a boundary verdict are
surfaced explicitly at the next boundary, never absorbed silently.

- **2026-08-10, maintainer ruling** — FR-012 and SC-007 amended: acceptance for the
  campaign bootstrap is a fresh project completing a FULL ROUND, not merely passing
  preflight. Rationale recorded in the spec: getting one round to run during this
  feature required clearing seven distinct defects, so the first-run path has never
  been exercised end to end, and a preflight-only criterion would pass while the path
  stayed broken. US5 scenario 1 aligned to the same wording.

## Standing instructions carried from the same verdict

- **T003 fixture case (two-governor collision)**: when T003 resumes, add a fixture
  pinning the adjudication rule the maintainer confirmed — a recorded crossing in
  controller truth WINS over the campaign block's self-describing no-marker clause.
  Evidence: the 2026-08-10 before-implement stop, where the boundary evidence gate
  demanded the verdict marker for `crossing-9b3d255e` while the campaign block
  simultaneously instructed that no marker be emitted.
- **T007 PSModulePath question — measure, do not judge**: every governed project's plan
  carries at least one PowerShell-invoked command (the governance validator), so whether
  the PowerShell stack default carries `PSModulePath` is a stack-default question, not a
  project-specific one. In T007, run the governance validator once under a scrubbed
  environment WITHOUT `PSModulePath` and let the result decide. Record the measurement,
  not the reasoning.
  **MEASURED 2026-08-10 — ANSWERED: the PowerShell stack default DOES carry it, so the
  starter plan does not need the env_ref.** The variable was REMOVED from the child
  environment (not blanked — an empty string is a value PowerShell may repopulate, and the
  question is what a plan that does not declare the env_ref actually gets). Transcribed from
  the probe:

  | Run | `PSModulePath` | Exit | Elapsed | stderr |
  | --- | --- | --- | --- | --- |
  | Control (plan as authored) | inherited | **0** | 11.9 s | empty |
  | Scrubbed | removed from the child env | **0** | 11.2 s | empty |

  The effective value inside a child started WITHOUT it, read back from that child:

  > `C:\Users\alon\OneDrive - Zionet LTD\Documents\PowerShell\Modules;C:\Program Files\`
  > `PowerShell\Modules;c:\program files\powershell\7\Modules;;C:\Program Files\`
  > `WindowsPowerShell\Modules;C:\Windows\system32\WindowsPowerShell\v1.0\Modules`

  **What it decides**: `pwsh` reconstitutes a full default module path at startup when the
  variable is absent, so module resolution does not depend on inheriting it. The disclosed
  addition recorded in DRIFT-199-I001-010 ("this repository's verification commands are
  PowerShell and resolve modules through it") was therefore a correct precaution resting on
  an incorrect premise. T007's starter plan ships the N4 default list WITHOUT `PSModulePath`;
  this project's own plan keeps it, which is harmless and now documented as unnecessary
  rather than load-bearing.

## Events

### DRIFT-199-I001-001 — two-message decision stop at the co-design ask (resolved)

- **Observed**: 2026-08-10. The co-design presentation ended the turn without the
  non-boundary context packet; the Stop hook bounced and the packet was rendered in a
  follow-up message — a live instance of the two-message decision-stop pattern that
  FR-017 (one-message decision stops) drives to zero at the instruction layer.
- **Citation**: FR-017; the 208 rule lineage in the beta3 carry ledger (stop-surface
  family, decision-yield composition).
- **Resolution**: human-decision — recorded as evidence for W8's instruction-layer
  work; subsequent decision-yield stops in this session compose packet + ask in one
  message.

### DRIFT-199-I001-002 — pending-verdict stop artifact not emitted at the plan sync (open)

- **Observed**: 2026-08-10T01:15:50Z. The plan boundary sync recorded the crossing
  (`crossing-eb1123ca...`, clarify -> plan, boundary commit d9b1cc85) in
  `.specrew/start-context.json` but `.specrew/runtime/pending-verdict-stop.md` was
  not written; the two earlier syncs (specify, clarify) emitted it. The preceding
  attempts of the same sync halted at the markdownlint pre-boundary gate and at the
  stale-hash guard — sequence possibly relevant. The boundary stop was rendered from
  the recorded `pending_crossing` (controller truth) with the marker taken from its
  from/to values, per the gate-stop skill's artifact-first rule rationale.
- **Citation**: FR-023 (records state facts); gate-stop skill DRIFT-198-I011-012
  lineage (marker must come from controller truth, never phase inference).
- **Resolution**: deferred — routes to the ledger's beta4 list unless it recurs and
  blocks a boundary (scope-closed feature; the crossing record sufficed here).
  **Human instruction (plan verdict, 2026-08-10)**: if it recurs at the tasks
  boundary, diagnose the root cause and record it here before implementation starts —
  diagnosis only; the fix stays deferred to beta4 unless the diagnosis shows it lands
  inside files this feature already touches.

### DRIFT-199-I001-003 — plan sync recorded without iteration identity (resolved)

- **Observed**: 2026-08-10. The first plan boundary sync omitted `-IterationNumber`;
  the crossing recorded with an empty iteration identity, and the Stop-side evidence
  gate refused the boundary stop (stage evidence not locatable in the bound tree) —
  the FR-068-lineage gate behaving as shipped. No verdict was offered against the
  unverifiable state.
- **Citation**: the beta2 release claim's stage-evidence gate; 199 spec FR-023
  (evidence tools verified before trusted).
- **Resolution**: implementation-reverted (process form) — re-synced with
  `-IterationNumber 001`; fresh crossing `crossing-fd27261c` bound to commit
  ffeea775 with the iteration identity present; the stop re-rendered and the plan
  verdict was given over the verifiable state.

### DRIFT-199-I001-005 — F1 (OneDrive) reproduced live on the maintainer's install (CLOSED 2026-08-10)

**CLOSED on a measurement, not on a green suite.** All three real OneDrive states are now admitted and
hashed end to end through `Get-SpecrewReviewRuntimeManagedTextSha256` — the exact function whose refusal
opened this entry — against the INSTALLED module. Transcribed from the run at commit `dda0e660`:

> `start (pinned)           attrs 0x80420   hydrate-cloud     7b3249f4...d40e`
> `evicted (dehydrated)     attrs 0x501620  hydrate-cloud     7b3249f4...d40e`
> `hydrated-unpinned        attrs 0x420     admit-nonlinking  7b3249f4...d40e`
> `0x420 admitted AND bytes verified against half 1: True`
> `RESTORED (pinned)        attrs 0x80420   hydrate-cloud     7b3249f4...d40e`

Every hash is identical to the value half 1 recorded before any eviction, so the bytes survived a real
round trip through the cloud in both directions. The pin state was restored and confirmed; the
maintainer's module is as it was found.

**What closes it, stated as the three separate claims it actually took**: a dehydrated placeholder is
classified as cloud and READING IT HYDRATES (half 2); a hydrated file is not silently refused once its
transient markers clear (the pinned case, DRIFT-199-I001-023); and the hydrated-UNPINNED state that
Storage Sense leaves behind is admitted rather than refused (the non-linking ruling,
DRIFT-199-I001-024). The first fix satisfied none of these on a real install; the second satisfied one;
only all three together close the defect.

**Three attempts, and each was declared done before it was.** Recorded plainly because that is the
useful part of this entry's history: attempt one passed its fixtures while refusing every file on the
machine; attempt two passed its fixtures and the real pinned files while still refusing the state a
consumer reaches after Storage Sense runs; attempt three was measured in all three states before anyone
said the word closed.

### DRIFT-199-I001-005 — the original reproduction (kept for the record)

- **Observed**: 2026-08-10, running `specrew review --remediate override-block` through the
  INSTALLED module. Exit 1 with
  `review-runtime-managed-file-link-unsupported:C:\Users\alon\OneDrive - Zionet LTD\Documents\PowerShell\Modules\Specrew\0.40.0\scripts\internal\continuous-co-review\_load.ps1`.
- **Significance beyond ledger F1**: the refusal blocked a SANCTIONED REMEDIATION DOOR,
  not merely a campaign run. T067 recorded campaigns being unusable from a OneDrive
  install; this instance shows the disposition/remediation path is equally unreachable,
  so a consumer on the default CurrentUser install cannot even record a governance
  decision. The repo-script path (`pwsh -File scripts/specrew-review.ps1`) is unaffected
  (local volume), which is how work continued.
- **Citation**: FR-011 (reparse-tag discrimination); ledger T067-F1.
- **Resolution**: in scope, covered by task T007 in the harness queue / T006 in tasks.md —
  the reparse-tag work. This instance is added as a second RED reproduction target: the
  remediation door must work from a cloud-placeholder install.
  **FIRST ATTEMPT DID NOT FIX IT — see DRIFT-199-I001-023.** The classifier committed in `a95a453c`
  detected only DEHYDRATED placeholders, so on this very install every file still refused. The cloud
  family was widened to the pinned/unpinned retention markers and re-measured against these exact files;
  `_load.ps1` now classifies `hydrate-cloud`. Recorded rather than quietly amended, because a green suite
  reported this fixed while it was not.
  **HALF 1 — ADMISSION: MEASURED AND PASSED 2026-08-10** (commit `599c15cb`). Transcribed from the run,
  not drafted ahead of it. The committed `reparse-tag-policy.ps1` and `review-engine-resolution.ps1` were
  dot-sourced from the beta3 tree and `Get-SpecrewReviewRuntimeManagedTextSha256` — the exact function
  whose refusal opened this entry — was called against the INSTALLED module at
  `...\OneDrive - Zionet LTD\Documents\PowerShell\Modules\Specrew\0.40.0`, which carries **396 real
  cloud-backed files**:

  > `_load.ps1     attrs 0x80420  hydrate-cloud  b39636f90458bf6a4f5cf55117c78ba81801063749e7fe6b86b527053f6941fb`
  > `CHANGELOG.md  attrs 0x80420  hydrate-cloud  9d57a9f71160c3ea5ed786df4c57fed9b352b37ac362201c2bc1e9910c71a640`
  > `install.sh    attrs 0x80420  hydrate-cloud  7fced5a8f18dc24fe93c45190f21924df625722c61cb57880f0bea8968ba5a9c`
  > `LICENSE       attrs 0x80420  hydrate-cloud  7b3249f4035970ca7bbf8574f09499b76707a650eb42a3fad8484fba6c3dd40e`

  A hash, not `review-runtime-managed-file-link-unsupported`. **What this proves, stated narrowly**:
  admission — a real cloud-backed file is classified as cloud and read rather than refused, on the
  machine and the install that produced the original defect. **What it does NOT prove**: that reading
  HYDRATES anything. Every file above was already local, so the fetch path is still unexercised.

  **HALF 2 — HYDRATION: RUN 2026-08-10 under the maintainer's explicit go-ahead, on `LICENSE`. The
  three-point claim PASSED. The entry does NOT close.** Transcribed from the run:

  > `before     attrs 0x80420  [PINNED]  -> hydrate-cloud`
  > `attrib exit=0  (exit code NOT trusted; the attribute is re-read below)`
  > `evicted    attrs 0x501620 [UNPINNED RECALL_ON_DATA_ACCESS OFFLINE]  -> hydrate-cloud`
  > `hash actual   : 7b3249f4035970ca7bbf8574f09499b76707a650eb42a3fad8484fba6c3dd40e`
  > `hash expected : 7b3249f4035970ca7bbf8574f09499b76707a650eb42a3fad8484fba6c3dd40e  (HALF 1, before eviction)`
  > `hash match    : True`
  > `hydrated   attrs 0x420  []  -> refuse-unknown`
  > `recall bit cleared by the read: True`
  > `RESULT: PROVEN - dehydrated placeholder classified as cloud, reading hydrated it, bytes verified identical.`

  The eviction was VERIFIED rather than assumed — `RECALL_ON_DATA_ACCESS` (`0x00400000`) was polled for
  and observed set before the probe ran, so a silently-skipped eviction could not have produced a passing
  probe. **PIN STATE RESTORED** and confirmed: `restored attrs 0x80420 [PINNED]`, identical to the
  `before` value. The maintainer's module is as it was found.

  **WHY THIS ENTRY STAYS OPEN DESPITE THE PROOF.** Step 4 of the same run shows the hydrated file at
  `attrs 0x420` classifying as `refuse-unknown`, and a follow-up measurement confirmed that is a STABLE
  state rather than a momentary one. A OneDrive file that has been freed up and re-opened is therefore
  still refused. The fix closes this defect for PINNED files and reproduces it for hydrated-unpinned
  ones, and the two cannot be separated from an AppExecLink by any signal the classifier reads. That is
  DRIFT-199-I001-024, and it needs a maintainer ruling. **Closing here on "half 2 passed" would have been
  exactly the false-green this feature exists to prevent.**

  **CODE LANDED 2026-08-10, MEASUREMENT STILL OWED.** All three integrity checks now route through the
  one reparse-tag policy: a symlink or junction still refuses, an unrecognised tag fails closed, and a
  cloud placeholder is read rather than refused — `Get-SpecrewReviewRuntimeManagedTextSha256` is the
  exact line that refused `_load.ps1` above. This entry stays OPEN on purpose: the fix is proven at the
  seam and the live OneDrive leg is the maintainer's manual measurement (see the T006 limit-of-evidence
  entry). It closes when that proof line is transcribed, not when the suite is green.

### DRIFT-199-I001-006 — no expressible off-ramp for the pre-code campaign review demand (open)

- **Observed**: 2026-08-10 at the before-implement boundary. The campaign surface goes
  live at `before-implement` by design (worktree-navigator.ps1:158-174, hardened
  2026-08-08 from the testbeta3 dogfood) on the stated premise that "there is
  implementation to review". At that cursor NO implementation exists yet: the block
  `review-required / no-authoritative-campaign-result` demands a review of the PLANNING
  digest.
- **The inexpressible disposition**: the maintainer ruled to decline the pre-code review
  and spend the review budget on the code at review-signoff. The sanctioned instrument
  (`--remediate override-block`) refuses: "Campaign override-block requires --run-id and
  --ack-reason; the disposition is never implicit." Every remediation choice binds to a
  run, and zero runs exist — so "no review is owed at this cursor" has no expressible
  form. The only mechanical exit is to run (and pay for) the review.
- **Relation to the acceptance bar**: this is the F8 family's missing off-ramp
  (fix-everything default with no sanctioned decline) appearing BEFORE any code exists —
  the pattern ledger finding F8 records as the headline failure, and adjacent to the
  sanctioned-quiet-state semantics the maintainer added at the architecture lens (D3).
- **Citation**: FR-007, FR-008 (single-authority stop surface, sanctioned quiet states);
  ledger F8, F5.
- **Resolution**: human-decision, 2026-08-10 — ruled IN SCOPE under the closed-scope exception
  (an unsatisfiable, undeclinable stop surface is clause two of the acceptance bar failing
  live) with a bounded repair: align activation with the rule's own stated premise, RED-first,
  no gate weakened, no bypass added, nothing broader. Delivered as T003 work landing early,
  not new scope.
  **Amended shipped guarantee (maintainer permission, 2026-08-10)**: the 2026-08-08 cases
  `campaign <before-implement|review-signoff>: the packet gate is STILL consulted from the
  implement window onward` asserted the gate stage-UNCONDITIONALLY, while the rule they protect
  is premise-CONDITIONAL ("there is implementation to review"). The two readings diverge on
  exactly one state — an empty stage. Under the maintainer's conditions the guarantee was made
  STRONGER, not looser: each original case keeps its provenance comment plus the recorded
  sharpening rationale and now asserts the live direction against GENUINE committed work; each
  gained a paired sibling asserting quiet ONLY for a fully-resolved records-only delta; and a
  third pair pins fail-closed behaviour (an unresolvable coverage anchor keeps the gate
  consulted). Evidence: 39/39 green across
  `tests/continuous-co-review/unit/continuous-co-review-navigator.Tests.ps1` and
  `tests/continuous-co-review/unit/campaign-activation-implementation-premise.Tests.ps1`.

### DRIFT-199-I001-007 — the campaign engine rejects the run id it just minted (open)

- **Observed**: 2026-08-10, first authorized campaign round
  (`authorization-ref: beta3-t003-activation-slice-1`). Exit 1 with
  `review-campaign-invalid-run-id:run-20260810T072512585-18f6c6e4`.
- **Root cause (read from source, not inferred from the message)**:
  `review-campaign-orchestrator.ps1:751-752` mints an auto run id from the timestamp
  format `yyyyMMddTHHmmssfff`, which contains a literal UPPERCASE `T`.
  `review-authority-core.ps1:89` validates identifiers with
  `-cmatch '^run-[a-z0-9][a-z0-9-]{0,63}$'` — case-SENSITIVE, lowercase only. The minted
  id can therefore never satisfy the validator, so **every campaign run that does not
  receive an explicit `--run-id` fails before a reviewer is invoked**.
- **Cost**: none. The failure precedes any store write — no campaign facts existed
  afterwards, no allowance consumed, no provider spend.
- **Provenance**: the timestamp format arrived with `cbd7b615`
  ("feat(review): wire campaign command authority").
- **Workaround used (no product change)**: supply an explicit lowercase run id
  (`--run-id run-t003-activation-slice-1`). A second validation gap surfaced immediately
  behind it: `FeatureId` does not auto-resolve for the campaign path, so `--feature` and
  `--iteration` must also be passed explicitly.
- **Consumer impact**: a consumer following the block's own instruction
  ("request-authorized-review") cannot run one from the documented CLI surface without
  discovering two undocumented flags.
- **Resolution**: FIXED in scope 2026-08-10 under the maintainer's closed-scope exception
  (a default campaign invocation that fails is a wedged gate with an unreadable message,
  and it lands in files T001/T008 already own).
  **The MINTER was fixed, never the validator**: run ids become filesystem path segments
  under the authority store, so the lowercase-only case-sensitive identifier rule is a
  path-identity containment rule (the beta2 certify-round-3 class) and must not be
  relaxed. The stamp format became `yyyyMMdd-HHmmssfff` — lowercase-safe, still sortable,
  still unique per run.
  **COVERAGE LESSON (maintainer, recorded as instructed)**: this stayed latent from
  `cbd7b615` until now because every run ever observed supplied an explicit `--run-id`,
  so no fixture exercised the DEFAULT path. The new fixture
  `tests/continuous-co-review/unit/campaign-default-run-id-mint.Tests.ps1` pins the
  default path specifically — identity resolved with NO run id — plus uniqueness and an
  explicit guard that an UPPERCASE id is still refused, so the containment rule cannot be
  loosened later in the name of convenience. Evidence: 3 of 4 cases RED before the fix
  (the guard green from the start), 4/4 green after; 61/61 green across the campaign
  orchestrator and public-command suites.

### DRIFT-199-I001-014 — my path-identity consumer never loaded the primitive (resolved)

- **Observed**: 2026-08-10, wider-suite regression. `path identity primitive: lets no consumer fall
  back to a case rule the volume did not choose (DRIFT-198-I009-018)` failed.
- **Cause**: the round-1 fix routed the activation predicate through
  `Get-ContinuousCoReviewPathComparison`, but `worktree-navigator.ps1` never dot-sourced
  `path-identity.ps1` at file scope, so the call depended on ambient load order. That is the
  SHADOWING class the guard exists to stop — a duplicate primitive loaded later silently
  answers with the OS-family rule, invisibly, at every call site.
- **Significance**: this is the SECOND path-identity defect I introduced in the same day, on the
  same code, immediately after recording that the class recurs. The first was using the wrong
  comparison; this was using the right one unsafely. The guard caught what the review and my own
  attention did not — further evidence for beta4's consolidation.
- **Resolution**: FIXED — file-scope guarded dot-source added, guarded on a name unique to the
  module (DRIFT-198-I009-027). `path-identity.Tests.ps1` and the activation fixture green.

### DRIFT-199-I001-015 — the flush-race analyzer reopened on a signature captured TODAY (open)

- **Observed**: 2026-08-10, wider-suite regression. `T109 flush-race forensic analyzer
  (D-197-I009-003 refuted; reopens on a real signature)` failed with the captured record:

  > `10/08/2026 9:11:11: blocked on a PARTIAL header read (dx_lat_hits=2 of 6, dx_lat_len=3321)
  > - possible mid-flush truncation`

- **What it means**: the suspicion was a flush/read race in the conformance Stop-provider — a
  valid packet on disk read as absent, producing a spurious block or double render. The July
  forensic REFUTED it on the then-corpus, and this analyzer was left in place to reopen the
  question if a real signature ever appeared on any machine. The signature above was captured
  during THIS session, in this repository's own conformance journal.
- **Not a regression of this feature**: the analyzer reads machine-local runtime state
  (`.specrew/runtime/conformance-journal.jsonl`), not code. It shows as "new" against the trunk
  baseline only because the baseline worktree carries a different corpus. No change in this
  feature caused the signature; the session's own stop traffic captured it.
- **Standing consequence**: the suite will keep reporting this while the corpus holds the record,
  so it needs a disposition rather than silence.
- **Resolution**: pending maintainer ruling. The analyzer's own note names the remedy (a cheap
  re-read variant, per the iteration-009 revert note), which is conformance-provider work outside
  this feature's ten items — so the default routing is beta4, unless the spurious-block behaviour
  is judged to hit the acceptance bar's wedged-gate clause.

### DRIFT-199-I001-016 — the records-only predicate asked the machinery resolver with no root, and failed OPEN (resolved)

- **Observed**: 2026-08-10. The T003 case `a delta containing implementation DOES stale it`
  expected `review-stale` and got `review-current`. A delta containing
  `scripts/internal/continuous-co-review/worktree-navigator.ps1` classified as records-only.
- **Hypotheses ruled out first, so the record shows what the cause was NOT**: there are no blank
  entries in the machinery list (a blank root would match every path via `StartsWith`), and the
  predicate's early return for a non-records path was present and correct.
- **The measured cause**: `Get-ContinuousCoReviewMachineryPaths` answers DIFFERENTLY depending on
  the root it is handed, and `Test-ReviewCampaignDeltaIsRecordsOnly` called it BARE. With no root
  it cannot run `Test-ContinuousCoReviewSpecrewSourceRepo`, so it takes the DEPLOYED-project branch
  (worktree-reviewer.ps1:116-125) and appends `scripts/internal/continuous-co-review`,
  `scripts/internal/agent-tasks` and `scripts/internal/atomic-write.ps1` to the machinery list.
  Measured directly rather than reasoned about — the bare call returns THIRTEEN entries, not the
  ten-entry core list:

  > `.specrew .specify .squad .agents .antigravitycli .git .claude/settings.local.json CLAUDE.md`
  > `AGENTS.md GEMINI.md scripts/internal/continuous-co-review scripts/internal/agent-tasks`
  > `scripts/internal/atomic-write.ps1`

- **Severity — it fails in the one direction this feature must never fail in**: in the Specrew
  SOURCE repo those three paths are the feature under review, not machinery. A change to the
  co-review engine itself therefore classified as records-only and left a stale review reading as
  current. Under-staling means a real code change slips past a review; every other rule in this
  feature fails toward staling more.
- **Second defect in the same predicate, found while fixing the first**: the comment above it
  promises the machinery list "can never drift from the digest and worktree strips". It had already
  drifted — the digest strip in `Test-ReviewCampaignFinalizationEnvelope` passes `-RepoRoot`, so the
  two lists were computed from different questions in the same file.
- **Third, same call site**: the case rule came from `Get-ContinuousCoReviewPathComparison -Path
  $PSScriptRoot` — the volume holding the ENGINE, not the volume holding the changed paths. On the
  default CurrentUser install those are routinely different volumes (DRIFT-199-I001-005 is that exact
  split: engine under OneDrive, project on a local disk). Asking the engine's volume for the
  project's case rule is the same wrong-source mistake as an `$IsWindows` shortcut.
- **The comment was the trap, and it is now removed at the FUNCTION** (maintainer ruling
  2026-08-10): fixing only the caller would have left `Get-ContinuousCoReviewMachineryPaths`
  documented as safe to call bare, waiting for the next caller. There is no honest core-only answer
  to return — parts (a) and (b) of the resolver disagree about exactly those three paths depending on
  which repository is being described — so a bare call now REFUSES
  (`review-machinery-paths-requires-repo-root`) instead of guessing a branch, and the false comment
  is replaced by the reason. Verified safe first: every call site in the tree already passes
  `-RepoRoot`, so nothing relied on the removed behaviour. Pinned by a new case in
  `tests/continuous-co-review/unit/worktree-reviewer-machinery-paths.Tests.ps1`.
- **A brittle guard found while pinning it, fixed rather than padded**: that suite's structural case
  sliced a fixed 6000-character window from the function start, so adding a comment silently
  truncated the block and the assertions failed for a reason unrelated to what they guard. It now
  slices to the next top-level function. A structural test that reports the wrong defect is worse
  than none.
- **Citation**: FR-009 (records deltas must not stale a reviewed digest); FR-012 (the one machinery
  resolver); the path-identity volume rule (DRIFT-198-I009-018).
- **Resolution**: FIXED. `-RepoRoot` threaded through `Resolve-ReviewCampaignVerdictPacketDecision`
  into the predicate and on to the resolver, so the answer belongs to the root being classified; the
  comparison now asks the PROJECT's volume; and an absent or unresolvable root fails CLOSED (stales)
  rather than guessing a machinery list, since guessing is what produced this. Not made a mandatory
  parameter on purpose: this runs on the Stop path, where a missing mandatory parameter prompts an
  interactive host and hangs the hook instead of failing.
  **Both directions of the same call are now pinned**, because the fix is "consult the resolver for
  THIS root", not "hardcode the source-repo answer": in the source repo the engine path stales; under
  a non-source root the identical path is records-only; an unresolvable root stales. Evidence: 11/11
  green in `tests/continuous-co-review/unit/campaign-stop-authority.Tests.ps1`, and 88/88 green
  across `review-public-campaign-command`, `review-window-codex-default`,
  `campaign-activation-implementation-premise` and `continuous-co-review-navigator`.

### DRIFT-199-I001-017 — path-identity, THIRD instance in one day; and what the guard actually did (resolved)

- **Observed**: 2026-08-10. `review-signoff-evidence-gate.ps1` calls
  `Get-ContinuousCoReviewPathComparison` but carried NO file-scope dot-sources at all, so the call
  depended on ambient load order — the SHADOWING class where a duplicate primitive loaded later
  silently answers with the OS-family rule, invisibly, at every call site.
- **Third instance of this class in a single day**, in the very file T003 was editing: the first used
  the wrong comparison, the second (DRIFT-199-I001-014, worktree-navigator.ps1) used the right one
  unsafely, this one repeats the second in a different file.
- **Resolution**: FIXED the same way — a file-scope guarded dot-source, guarded on
  `Get-ContinuousCoReviewPathComparison`, the exact function this file calls. Guarding on the exact
  function rather than a sibling name is the sharper form (`review-engine-resolution.ps1` uses it):
  DRIFT-198-I009-027's shadow survived a guard that probed a DIFFERENT name, and a stale copy of
  path-identity.ps1 satisfies the older names while lacking anything added since.

**The guard finding, CORRECTED by measurement — the working assumption was that the guard had missed
this instance, so it was not scanning every file that calls the primitive. It is, and it did not miss
it.** Run against the tree before any fix, `path-identity.Tests.ps1` was already RED, naming the file:

> `because review-signoff-evidence-gate.ps1 must load the primitive into its own scope, but it did
> not match.` (14 passed, 1 failed, 1 skipped)

The guard enumerates its consumers DYNAMICALLY — every `*.ps1` under the co-review directory whose
source matches the primitive's call spelling — so the new consumer was picked up the moment the call
was written. Widening its file enumeration would buy nothing; there is nothing to widen.

**What the real gap is, and why it matters more than the assumed one**: the guard was never RUN. The
previous session added the call and then ran only the T003 fixture, so a red guard sat in the tree and
was committed inside `c14a063f`. The failure was authored, detected, and unobserved. Consequences
recorded as facts:

- **SEVENTEEN is correct for the branch point; EIGHTEEN for commit `c14a063f`, which carried a red
  guard.** Both numbers are right about different trees, and a reader who finds eighteen in the
  history should find this entry rather than suspect the baseline. Confirmed by measurement after the
  fix: **17 failed / 1000 passed** across `tests/continuous-co-review/unit`, failure set identical
  name for name to the recorded seventeen.
- **The lesson, and it is not the one first assumed.** The working assumption was a coverage gap in
  the guard; the maintainer retracted that after the measurement above. The durable lesson is that
  **a guard only guards code whose author runs it** — a per-file edit does not know which class guard
  it just broke, and selection-by-what-the-task-touches will always trail the code.
- **Acted on immediately rather than deferred (maintainer ruling)**: the class-guard suites are now a
  PERMANENT lane in `.specrew/verification-plan.json` (`f199-class-guards`: the path-identity guard,
  the volume differential, and the machinery-path policy), never selected by what a task happens to
  touch. That converts the lesson into a mechanism inside work this feature already owns, and it
  means the next engine edit cannot commit a red guard unnoticed. Roughly 10 s combined, validated
  through the shipped contract (`Test-ContinuousCoReviewVerificationPlan` → valid).
- **Still one more argument for the beta4 consolidation target** already recorded — making the
  primitive the ONLY REACHABLE path rather than the recommended one. The lane catches a red guard
  fast; only unreachability stops the defect being written.

### DRIFT-199-I001-018 — making the pause consult live turned a latent ordering bug into a wedge (resolved)

- **Observed**: 2026-08-10, immediately on wiring the four T003 consults into
  `Get-ReviewCampaignVerdictPacketDecision`. T051's own fixture (`delegates one public operation
  through campaign ports and preserves the exact origin state`) went red: the signoff gate returned
  `block` where it had returned `allow`, with
  `reason=human-pause-decision-outstanding`.
- **Cause, and it is mine**: `Resolve-ReviewCampaignVerdictPacketDecision` evaluated the pending-pause
  quiet BEFORE the latest-result evaluation. That ordering was harmless while nothing supplied
  `-PendingPause`; the wiring made it live. **T001 makes every round end in a pause**, so after any
  completed round a pending pause and that round's clean pass describe the SAME tree at the same
  moment — and the pause short-circuited `boundary-clean`.
- **Why it is a wedge rather than noise**: the boundary packet IS how the human answers a pause.
  Quieting it left them holding a decision with no surface to answer it through, on a tree whose
  review had already passed cleanly. That is the wedge class this feature exists to remove, arriving
  from the direction the pause rule was written to protect.
- **The rule that resolves it**: a pending pause suppresses a DEMAND — do not nag for another review
  or another disposition while one is already sitting with the human — and releasing what they need
  in order to answer is not a demand. So the pause never suppresses a boundary-releasing result.
- **Resolution**: FIXED. The "would this reach a boundary route" question is now ONE predicate,
  `Test-ReviewCampaignResultReleasesBoundary`, consumed by both the pause guard and the
  `boundary-clean` return so the two cannot drift apart; the sequential gates between them stay
  sequential because each owes the consumer a different message. Pinned by a paired fixture — a clean
  pass plus a pause on the same tree returns `boundary-clean`, while the same pause over a findings
  result still returns `pause-pending`, so the fix can never be read as "a pause is ignorable".
- **Method note worth keeping**: this was caught by an EXISTING fixture in a suite I had not changed,
  not by reasoning about my own edit — the same shape as DRIFT-199-I001-014. The wiring's own new
  fixtures were all green while this was broken.

### FR-009 — the expectations it moved, old and new side by side (recorded 2026-08-10 at the maintainer's instruction)

Recorded so a later reader sees a guarantee SHARPENED BY A REQUIREMENT rather than a test bent to fit
new code. All four live in `tests/continuous-co-review/unit/review-public-campaign-command.Tests.ps1`.

**The requirement that moved them** — FR-009: *commits touching only governance/records files MUST NOT
stale a reviewed digest.* Its live evidence is DRIFT-199-I001-013, where a commit whose entire content
was this drift log flipped the surface to `review-stale`: writing down what a review found invalidated
that review, so currency was unachievable by construction.

| Case | Delta | Old assertion | New assertion |
| --- | --- | --- | --- |
| `denies every non-review-evidence finalization path` (spec) | `specs/001-demo/spec.md` | `route = review-stale` | `route = review-current` |
| same (contract) | `specs/001-demo/iterations/007/plan.md` | `route = review-stale` | `route = review-current` |
| same (state) | `specs/001-demo/iterations/007/state.md` | `route = review-stale` | `route = review-current` |
| same (script) | `scripts/change.ps1` | `route = review-stale` | **unchanged** — reviewable content still stales |
| same (test) | `tests/change.Tests.ps1` | `route = review-stale` | **unchanged** |
| `denies an allowlisted envelope chain whose finalization parent is not the reviewed commit` | two commits, both under `specs/001-demo/iterations/007/` | `route = review-stale` | `route = review-current` |

**What did NOT move, in any row**: no boundary packet is released and no finalization fact is
published. Those were previously implied by the route name; they are now asserted EXPLICITLY
(`render_boundary_packet`, `render_verdict_marker`, and the absent finalization fact), which leaves
each case stating its own guarantee instead of borrowing one. The route answers "does the review still
cover this tree"; the assertions answer "was anything authorized". Only the first is what FR-009
speaks to, and separating them is what makes this a sharpening rather than a relaxation.

**RULED 2026-08-10 — narrowed, on a principle rather than an enumeration of directories.** The
distinction is not where a file lives; it is whether the artifact is **INPUT TO** a review or
**OUTPUT OF** one:

- **Output** — a record of what a review found, or of the process around it. It cannot invalidate the
  review that produced it. Saying otherwise is circular, and that circularity is exactly the absurdity
  DRIFT-199-I001-013 caught.
- **Input** — `spec.md`, `plan.md`, `tasks.md`, contracts, data-model, quickstart, design-analysis,
  research. These are the STANDARD the code was judged against. Change one and what the review
  concluded changes, even though the code did not move, so they must stale.

Implemented as an **allowlist** of process-record artifacts with everything else staling, scoped to
the **ACTIVE** feature's records tree. The allowlist direction is load-bearing and is the reason an
enumeration is acceptable here when it was rejected for the class guards: an allowlist fails toward
NAGGING (an unlisted artifact stales, and the human is asked for a review they may not owe), while a
blocklist fails toward SILENCING (an unlisted artifact goes quiet, and a real change slips past a
review). An omission here is therefore SAFE.

**The table above is superseded by this ruling.** Restated with the same old/new discipline — exactly
ONE row moves, not four:

| Case | Delta | Old assertion | New assertion | Why |
| --- | --- | --- | --- | --- |
| `denies every non-review-evidence finalization path` (state) | `specs/001-demo/iterations/007/state.md` | `route = review-stale` | `route = review-current` | process record — output |
| same (spec) | `specs/001-demo/spec.md` | `route = review-stale` | **unchanged** | the standard the code was judged against |
| same (contract) | `specs/001-demo/iterations/007/plan.md` | `route = review-stale` | **unchanged** | same — input |
| same (script) | `scripts/change.ps1` | `route = review-stale` | **unchanged** | reviewable content |
| same (test) | `tests/change.Tests.ps1` | `route = review-stale` | **unchanged** | reviewable content |
| `denies an allowlisted envelope chain…` | `review.md` + `coverage-evidence.md` | `route = review-stale` | `route = review-current` | review EVIDENCE — the same six names this engine already allowlists for a finalization envelope |

Both directions pinned in `campaign-stop-authority.Tests.ps1`: nine review-output paths stay records,
nine review-input paths stale, another feature's records tree is ordinary content, an absent feature
id fails closed, and an unlisted artifact stales.

### Verification-plan sizing — the principle, recorded so the question does not recur (maintainer, 2026-08-10)

The two pre-existing commands stay as they are. The half-window rule governs **MEASURED consumption**,
not declared ceilings: the successful round spent 245 s of 900 on preflight including verification —
27%, and the right shape. **A ceiling is a hang-catcher, not a duration estimate.**

The invariant that actually matters is the one the 1200-versus-900 defect violated
(DRIFT-199-I001-012): the **SUM of ceilings must fit inside the round window**, or a slow day dies at
the window with a sealed failure. Currently 600 s of 900 — satisfied, with the class-guard lane
measured at 10.3 s against its 120 s ceiling.

### FR-013 — the ONE expectation T007 moved, old and new side by side (recorded 2026-08-10)

Same discipline as the FR-009 and FR-006 tables: a later reader should see a guarantee sharpened by a
requirement, not a test bent to fit new code. It lives in
`tests/continuous-co-review/unit/verification-plan-runner.Tests.ps1`.

**The requirement that moved it** — FR-013: a failure must name the missing piece and the next step,
not a requirement id. Its live evidence is DRIFT-199-I001-008, where the campaign preflight died with
`verification-not-configured` while the stop surface demanded a review that could not start, and
neither surface said what to do.

| Case | What changed | Old | New | Why |
| --- | --- | --- | --- | --- |
| `the selected-plan RESOLVER: absent -> unavailable ...` | the absent-plan assertion | `reason \| Should -Match 'supplier'` | `reason` is non-empty AND names `.specrew/verification-plan.json` | The GUARANTEE is "absent -> unavailable, with a stated reason". The word `supplier` is INTERNAL VOCABULARY that happened to be in the string, and pinning it would have made the case fail for a rewrite that improved the message. The new assertions pin the guarantee and the one durable fact — which file is missing. |

**What did NOT move**: the case still asserts `available = $false` for an absent plan, still asserts a
schema-invalid plan is refused loudly, and still asserts a valid plan is available. Only the wording
probe moved, and it moved from a word to a guarantee.

**The message itself, old and new**, since that is the actual deliverable:

> **Old**: `no supplier output at .specrew/verification-plan.json (FR-049 supplier not configured)`
> **New**: `no verification plan at .specrew/verification-plan.json, so nothing was checked. Run:`
> `specrew init - it creates a starter plan you can edit. You can also write the file yourself.`

Consequence first (nothing was checked — the state a reader most needs), then the exact command, then
the manual alternative. The requirement id is gone: it is a note to us, not an instruction to them.

### FR-006 — the expectations T005 moved, old and new side by side (recorded 2026-08-10)

Same discipline as the FR-009 table: a later reader should see a guarantee sharpened by a requirement,
not a test bent to fit new code. Both moves are in
`tests/continuous-co-review/unit/review-result-ingestor.Tests.ps1`.

**The requirement that moved them** — FR-006 as the maintainer ruled it: *a prompt is a REQUEST; a
contract needs a REJECTION.* If a finding omits a concrete failure scenario and ingest accepts it at
its stated severity anyway, "every finding states a concrete failure scenario or it is not a finding"
is aspirational text. The fail direction is **DEMOTE, never discard** — losing a real blocking finding
is worse than admitting a weak one — so a scenario-less gating finding lands below the gating floor as
a `minor`, carried as a recorded follow-up.

| Case | What changed | Old | New | Why |
| --- | --- | --- | --- | --- |
| `waits for verified process-tree death … retains valid partial findings` | the shared `New-IngressFinding` default description | `'Incorrect behavior'` | the same plus a `Failure scenario:` clause | The case is about RETENTION of a blocking partial finding, not about severity. Left alone, its `blocking` assertion would have been measuring the DEMOTION instead of the behaviour it exists to guard. These fixtures stand in for real reviewer output, so they must look like output that satisfies the contract. |
| `keeps moved-snapshot findings visible with lineage…` | the prior finding's identity fields | hand-copied literals | DERIVED from the same helper | Lineage matches on title/description/location, so a hand-copied description silently stops matching the moment the helper changes — which is exactly what happened here. Coupling them keeps the case measuring LINEAGE rather than string luck. |

**Nothing about either case's subject moved**: the timeout case still asserts a `blocking` finding
survives a verified tree-death, and the lineage case still asserts `lin-existing` links and that
lineage never rewrites reviewer severity. The demotion rule itself is pinned separately, in both
directions, by `reviewer-prompt-contract.Tests.ps1`.

**Known behaviour change on first deploy, stated rather than discovered later**: detection requires the
literal `Failure scenario:` clause, so a reviewer whose prompt predates this change has ALL its gating
findings demoted on the first round after deploy. Accepted: the findings stay visible and reach the
human as follow-ups, and the alternative — inferring a failure scenario from prose — would make the
contract a heuristic and therefore not a contract.

### DRIFT-199-I001-019 — `hooks status` reported a drifted wiring as installed (resolved)

- **Observed**: 2026-08-10 (the live diagnosis T004 names), reproduced as a fixture before the fix. On
  an EVENT-MAP host, `Get-SpecrewHooksStatus` asked one question — "is the dispatcher mentioned
  anywhere in this file?" A settings file registering Specrew for `SessionStart` and `Stop`, written
  before the manifest grew `UserPromptSubmit` and `PostToolUse`, answered YES. Measured against the
  pre-fix probe:

  > `drifted config reported 'installed'` (detail: `dispatcher via manifest project placeholder (cwd-robust)`)

- **Cause**: event names were folded into the required-token set only for `named-definition` config
  shapes. Event-map hosts — Claude among them — never had their registered events checked at all.
- **Why it matters more than an inaccurate status line**: verdict capture rides `UserPromptSubmit`. A
  drifted config silently downgrades capture to the Stop path alone, and the consumer sees a green
  status while a verdict goes unwritten. The surface whose job is to report wiring reported the
  wiring it was not checking.
- **What was NOT broken, stated so the fix is not over-claimed**: DEPLOY already reconciled. Its
  assertion passes against the pre-fix tree too, because the deploy strips Specrew entries and
  re-appends every manifest-declared event. The defect was entirely in the status surface.
- **Resolution**: FIXED. Registered events are now checked STRUCTURALLY per event, and a config that
  is wired but incomplete reports `stale` — already the "run install" state — with the missing events
  NAMED, so the consumer sees what was not firing rather than being told to re-run and hope.
  Structural rather than a search for the event NAME on purpose: a user's own unrelated hook on that
  event would satisfy a name search and report wired while Specrew is absent. The fixture pins exactly
  that case. One shared inspection helper now serves the whole-file and per-event probes, including
  `-EncodedCommand` payloads, so the two cannot disagree about what a Specrew entry is.
- **Evidence**: `tests/integration/hooks-reconcile.Tests.ps1` (new, 6 assertions, RED before the fix);
  nine hook suites green, including `refocus-deploy`, `specrew-hooks-command`, `ProviderMirrorParity`
  and `stopblock-deployed-binding`.

### DRIFT-199-I001-027 — FR-013 groups a REVIEWER-side concept with two verification-plan ones (resolved by ruling)

- **Observed**: 2026-08-11, implementing T007 part 2. FR-013 and its acceptance scenario 3 require that a
  failure name *"the schema element or required defer format"*, listing the missing pieces as
  **env_refs, plan schema, defer-record format**. The first two ARE verification-plan concepts, so the
  grouping implies the third is one too.
- **Measured, and the premise is wrong**: `verification-plan-contract.ps1` and
  `verification-plan-runner.ps1` contain **no** defer, waiver or skip concept at all. There is nothing
  in the verification path to name. The search found nothing because the premise was wrong, not because
  the search was.
- **Where the concept actually lives**: reviewer-side, in the prompt at
  `worktree-reviewer.ps1:1104-1114`. A recorded human deferral must live in a WORKTREE-VISIBLE artifact
  (an iteration drift-log event, a specs decision artifact, or a proposal work item), NAME the issue,
  RECORD the approving human, and STATE where the work is carried — and a deferral CLAIM without such a
  record is already ruled a blocking finding.
- **Two readings were possible and the difference was scope**: (a) the verification plan GAINS a defer
  concept, or (b) the requirement is about surfacing the EXISTING reviewer-side format. **(a) DECLINED
  by the maintainer** — new machinery, and TG-004 closes scope.
- **RULED (b), 2026-08-11, with a refinement**: it lands in the REVIEWER PROMPT, not in engine code,
  because the prompt is the only place a defer record is ever judged. The format is already written
  there and already enforced; what was missing is the instruction to STATE it when raising the finding.
  **No engine code was written for this.**
- **Resolution**: the prompt's deferral clause now requires that a blocking finding for an unverifiable
  deferral claim NAME all four required elements and the next step (mirror the decision into one of
  those artifacts and cite it). Rationale recorded in the prompt itself: naming the rule without naming
  its shape leaves the implementer guessing at exactly the moment they are trying to comply.
- **Recorded as drift rather than quietly reinterpreted**, because silently re-reading a requirement to
  fit what the code happens to support is the failure this feature punishes everywhere else. The spec's
  grouping is wrong; this entry is the reconciliation so the next reader does not repeat the hunt.

### DRIFT-199-I001-026 — TWO aggregate-over-containers errors, one each side, and a retracted finding (resolved)

**A recorded finding was WRONG and is retracted.** Commit `0424ab6e` asserted that i008 left "four
released slots never reused and four fresh authorizations minted instead". Measurement disproves it:
**i008 reused every slot it released — five releases, five reuses**, across four grants (one carried
generations 001-003, three carried 001-002). Verified independently before recording this retraction,
counting generation leaf files and treating a reuse as any generation beyond the first on a grant/slot:

| Store | grants | res containers | res LEAF | releases | REUSES | reuses = releases? |
| --- | --- | --- | --- | --- | --- | --- |
| `cmp-198-beta2-hardening-i008` | 25 | **21** | 26 | 5 | **5** | yes |
| `cmp-198-beta2-hardening-i009` | 8 | 8 | 11 | 3 | 3 | yes |
| `cmp-198-beta2-hardening-i010` | 1 | 1 | 1 | 0 | 0 | yes |
| `cmp-198-beta2-hardening-i011` | 6 | 6 | 7 | 1 | 1 | yes |
| `cmp-199-beta3-stabilization-i001` | 1 | 1 | 3 | 2 | 2 | yes |

**BOTH SIDES MADE THE SAME CLASS OF ERROR, in mirror image, and that is why it is one entry:**

- **The implementer's**: computed reuses as `reservations - grants`, an identity valid only if EVERY
  grant is reserved against. In i008 four grants were minted and never reserved (25 grants, 21
  containers), so the identity reported 1 reuse where there were 5 — and produced a confident,
  committed, FALSE defect claim.
- **The maintainer's**: counted the 26 grant SUBDIRECTORIES under `reservations/` and relayed them as 26
  reservations; the true leaf count is 29 generation files. That is why the relayed arithmetic
  (25 spends + 4 releases = 29 over "26" reservations) refused to close.

**Zero spent-and-released overlaps, zero duplicate dispositions, every reservation resolved exactly
once, in all five stores. The stores were clean the whole time**; only the counting was wrong.

**THE RULE — in a ledger with nested identity paths, COUNT THE LEAF FACTS.** Any aggregate identity
computed over CONTAINER counts silently encodes an occupancy assumption, and it will be wrong precisely
when something was minted and never used — **which is the state you are usually investigating.** Staged
for the carry ledger with the other method rules.

**Also corrected by this measurement**: grant reuse was NEVER broken, so the bisect proposed for "which
change fixed it" is scratched — there is no regression, and searching for the cause of an event that did
not happen is pure cost. F4's real residue is a DISCLOSURE gap, recorded in the design record.

**Worth stating plainly**: this was the third unverified claim relayed to the implementer in one day, and
the implementer's own false finding was committed to the record. The recovery in both cases was the same
act — measure the artifact rather than reason about it.

### DRIFT-199-I001-025 — the synthesis trap, THIRD instance in one day, inside the fix for the second (resolved)

- **Observed**: 2026-08-10, wiring the FR-013 derived diagnosis. Two EXISTING fixtures in a suite I had
  not touched went red:

  > `verification-copy-failed: The property 'failure_reason' cannot be found on this object.`
  > `Verify that the property exists.`

- **Cause**: `Get-ContinuousCoReviewVerificationFailureDiagnosis` read every evidence field directly
  (`$record.failure_reason`, `$record.exit_code`, ...). Evidence records are produced by SEVERAL
  builders and do not all carry the same fields, so under `Set-StrictMode -Version Latest` the first
  real record threw.
- **And its own fixtures were green**, because they SYNTHESISED records carrying every field. A partial
  record is the NORMAL case in production, not an edge, and the fixture had no way to know that because
  it invented its inputs.
- **Why this is worth its own entry rather than a line in a commit**: it is the THIRD instance today of
  the same trap, and the second one INSIDE a fix for the first.

  1. The reparse classifier refused every real file while its synthesised dehydrated shapes passed
     (DRIFT-199-I001-023).
  2. The fix for that synthesised `unpinned+hydrated` as `0x100420`; the real value is `0x420`, and no
     synthesised shape included `SPARSE 0x200` (DRIFT-199-I001-024).
  3. This one.

- **The rule, restated because three instances earn a rule**: **a fixture can only prove the shape it
  invents.** When a function consumes data produced ELSEWHERE — a filesystem, another builder, an
  external system — synthesised inputs test the author's model of that data, not the data. Either feed
  it a real record once, or read every field defensively and pin the partial case explicitly.
- **Resolution**: FIXED. All field reads go through one tolerant accessor; a missing `command_id`
  renders `(unnamed command)` rather than dropping the record, because a failed command that vanishes
  from the diagnosis is worse than an ugly label. Two new cases pin exactly the shape that broke it — a
  record carrying only `command_id` and `command_succeeded`, and one carrying neither.
- **Method note**: caught by EXISTING fixtures in a suite the change did not touch, which is now the
  fifth time this session. `review-campaign-verification.Tests.ps1` was not written for this function
  and had no idea it existed.

### DRIFT-199-I001-024 — a HYDRATED-UNPINNED cloud file is indistinguishable from an AppExecLink (RESOLVED by maintainer ruling 2026-08-10)

**RULED IN SCOPE.** Storage Sense evicting a module folder, plus any later read, leaves a consumer in
exactly this state; a refused install means they cannot complete a first feature. That is the acceptance
bar's first clause, not a nicety.

**THE RULING — take the third option, which neither party had named: admit a reparse point that .NET
reports as NON-LINKING, and let the HASH carry the trust.** Refusal is now EXACTLY the linking family.

**It opens with the maintainer correcting their own earlier warning**, recorded because the correction is
the load-bearing step: *"allow-by-default would admit an AppExecLink, so the allowlist stays"* was right
about the general claim and wrong about its relevance to these call sites. **An AppExecLink redirects
EXECUTION. None of the three sites executes anything** — they read text, hash it, and walk path
components for containment. A true general statement was applied to sites it does not reach, and the
`0x420` measurement is what exposed that.

The reasoning, recorded for the design record:

- For a READ, the only redirection that matters is *this path returns some OTHER file's bytes*. That is
  exactly what `LinkType` and `LinkTarget` name, and .NET names it reliably for the redirecting
  family — symlink and junction, both measured live.
- Every plausible non-linking reparse tag in a module tree or an authority store is content
  VIRTUALIZATION rather than path redirection: cloud files, Windows Server dedup, ProjFS. In all of them
  the file IS the file; the bytes merely arrive later. Refusing them buys nothing.
- Trust already rests on the hash of the bytes actually read — the security lens's S1 principle, already
  ratified for the cloud family. Extending it to any non-linking tag applies that principle CONSISTENTLY
  instead of carving an exception around one vendor's attribute bits.
- For CONTAINMENT walks the same holds: a directory that redirects is a junction or a directory symlink,
  both named. A cloud or ProjFS directory placeholder redirects nothing.

**THE RESIDUAL, recorded explicitly because this IS a widening**: an unknown tag that redirects a READ
without .NET naming it would now pass. No such tag is known, and the hash still catches wrong bytes — but
the honest statement is **"not known"**, not "impossible".

**THE BOUNDARY**: this rule holds for READ, HASH and CONTAINMENT. It does **NOT** extend to any future
call site that EXECUTES a path, where an AppExecLink genuinely redirects and the hash proves nothing.
`admit-nonlinking` is therefore kept DISTINCT from `hydrate-cloud` so such a site can refuse it without
reopening this decision, and every current site asks `Test-SpecrewReparseRefusesRead` rather than
comparing dispositions itself — three hand-written sets would be three things that drift apart.

**The AppExecLink fixture is kept and now asserts what HAPPENS to it** (admitted) rather than that it is
refused, so a later reader sees the case was decided rather than overlooked.

**THE DURABLE FIX ROUTES TO BETA4**: reading the real reparse tag is the only thing that truly separates
these two, it needs P/Invoke, and adding that to a shipped safety-critical hot path at the tail of an
over-scope feature is the wrong trade today. **Named in the beta4 list as the precise version of what
this ruling approximates**, alongside the path-identity consolidation.

**The synthesis recurrence is resolved too.** The four-state fixture was REBUILT from MEASURED values
with provenance on each row — `0x80420` pinned, `0x501620` evicted, `0x420` hydrated-unpinned, all
transcribed from the maintainer's install — rather than from constructed attribute arithmetic. The
evicted value is the proof that this mattered: it carries `FILE_ATTRIBUTE_SPARSE_FILE` (`0x200`), which
no amount of reasoning from the constant list would have suggested, and which every synthesised shape
omitted. **Twice now synthesised attributes described a state the filesystem does not produce.**

### DRIFT-199-I001-024 (original finding, kept for the record) — how it was found

**Found by half 2 of the hydration proof, at its own step 4** — the measurement the maintainer designed to
confirm the fix is what showed the fix is incomplete. Recorded as a finding in its own right rather than
as a caveat on the proof.

**Measured, twice, on the maintainer's install** (`LICENSE`, evicted and re-hydrated, then polled):

> `start (pinned)         attrs 0x80420  -> hydrate-cloud`
> `evicted (unpinned)     attrs 0x501620 -> hydrate-cloud`
> `immediately after read attrs 0x420    -> refuse-unknown`
> `after +2s              attrs 0x420    -> refuse-unknown`
> `after +5s              attrs 0x420    -> refuse-unknown`
> `after +10s             attrs 0x420    -> refuse-unknown`

**It is a STABLE state, not a momentary artifact.** A OneDrive file that has been freed up and then
re-opened settles at `0x420` — ReparsePoint + Archive, **no cloud marker of any kind** — and the
classifier refuses it. So DRIFT-199-I001-005 is fixed for PINNED files and reproduces for
hydrated-unpinned ones.

**Why this cannot be fixed by widening the allowlist again.** The maintainer's AppExecLink measurement
and this one are the SAME on every signal the classifier can see:

| | attrs | LinkType | LinkTarget | required disposition |
| --- | --- | --- | --- | --- |
| hydrated-unpinned OneDrive file | `0x420` | empty | absent | **admit** |
| AppExecLink (`winget.exe`) | `0x420` | empty | absent | **refuse** |

Admitting `0x420` would admit AppExecLinks — the exact containment hole the maintainer explicitly ruled
must stay closed. Refusing it leaves real cloud files unreadable. **Attributes plus `LinkType`/`LinkTarget`
cannot separate these two; only the real reparse tag can** (`IO_REPARSE_TAG_CLOUD*` vs
`IO_REPARSE_TAG_APPEXECLINK`), and reading it needs P/Invoke or `fsutil` — a subprocess on a per-component
path walk, which T006's design record rejected on the evidence of a prior CI hang.

**This was a genuine fork and it was the maintainer's to take** — both branches trade a containment
guarantee against a usability one. **Taken above**: neither branch was chosen; a third option was, once
the maintainer noticed that the AppExecLink objection does not reach a call site that never executes.

**AND THE FIXTURES WERE WRONG IN THE SAME WAY AS BEFORE.** The four-state case added in
DRIFT-199-I001-023 synthesised "unpinned + hydrated" as `ReparsePoint|Archive|UNPINNED` (`0x100420`).
Measurement says that shape is not what a hydrated-unpinned file reports — it reports `0x420` with no
marker at all. So the fix for the synthesis trap contained a fresh instance of the synthesis trap: an
invented shape asserted as if it were the world. **Resolved under the ruling above** — the context was
rebuilt from measured values with provenance, and the `SPARSE` bit it had been missing is now pinned as
its own case.

### DRIFT-199-I001-023 — the reparse classifier detected only DEHYDRATED placeholders, so T006 did not fix the bug it was written for (resolved)

- **Observed**: 2026-08-10, by the MAINTAINER measuring their own installed module at
  `Documents\PowerShell\Modules\Specrew\0.40.0` through the just-committed classifier (`a95a453c`):

  > `CHANGELOG.md  attrs 0x80420  ->  refuse-unknown`
  > `install.sh    attrs 0x80420  ->  refuse-unknown`
  > `LICENSE       attrs 0x80420  ->  refuse-unknown`

  `0x80420` is ReparsePoint + Archive + `FILE_ATTRIBUTE_PINNED` (`0x00080000`) — a HYDRATED,
  locally-available OneDrive file. None of `OFFLINE`, `RECALL_ON_OPEN` or `RECALL_ON_DATA_ACCESS` is
  set, so the cloud branch never fired and every file fell through to `refuse-unknown`.
- **THE DEFECT IS THE PREDICATE'S BASIS, not a missing constant.** All three original markers describe a
  file that is NOT CURRENTLY DOWNLOADED — a TRANSIENT STATE a file leaves the moment anyone reads it —
  when the property the predicate means to test is the STABLE one: is this file cloud-backed. This is the
  snapshot-versus-state family again, in a new place.
- **And it is exactly why the fixtures passed.** They SYNTHESISED the dehydrated shape, so they could
  only ever confirm the shape they invented; dehydrated was the only state the predicate could see. The
  suite was green about a case that does not occur on a working install, while the case that does occur
  on every working install was refused.
- **Severity**: T006 as committed did NOT fix DRIFT-199-I001-005 on the machine that produced it. The
  sanctioned remediation door stayed shut, and the green suite said otherwise.
- **DO NOT generalise to "any reparse point .NET does not call a link is safe"** (maintainer, measured on
  the same machine): an AppExecLink at `LOCALAPPDATA\Microsoft\WindowsApps\winget.exe` reports
  `attrs 0x420` with `LinkType` EMPTY and no `LinkTarget` — attribute-identical to a symbolic link and
  separable only by `LinkType`. Allow-by-default would admit it. **The allowlist stays.**
- **Resolution**: FIXED, RED first (5 failing cases before any product edit). The cloud family widened to
  the four REAL OneDrive states by adding `FILE_ATTRIBUTE_PINNED` (`0x00080000`) and
  `FILE_ATTRIBUTE_UNPINNED` (`0x00100000`) — the consumer's RETENTION CHOICE, which survives hydration —
  alongside the three transient markers. The cloud branch now requires `LinkType` AND `LinkTarget` to be
  BOTH absent, and the item shim passes the raw target through rather than only folding it into the
  type: widening the markers makes that guard load-bearing rather than theoretical, since a redirect
  carrying a pinned bit would otherwise be admitted.
- **Fixtures**: `0x80420` is pinned AS MEASURED DATA with a comment naming where it came from, kept as a
  literal rather than composed from constants because it is evidence. All four states are synthesised —
  pinned and unpinned, hydrated and dehydrated — so a future NARROWING fails loudly. The AppExecLink case
  is pinned too, with the 0x80420-versus-0x420 pair asserted side by side so the one bit separating them
  cannot be optimised away.
- **Evidence — measured on the real install, not synthesised**, after the fix:

  > `CHANGELOG.md     attrs 0x80420  ->  hydrate-cloud`
  > `install.sh       attrs 0x80420  ->  hydrate-cloud`
  > `LICENSE          attrs 0x80420  ->  hydrate-cloud`
  > `_load.ps1        attrs 0x80420  ->  hydrate-cloud`   <- the file DRIFT-199-I001-005 died on
  > `winget.exe       attrs 0x420  LinkType='' LinkTarget=(absent)  ->  refuse-unknown`

  Live symlink and junction refusal fixtures re-run and green, so the refusing direction is untouched.
- **The class was swept for other instances, and the sweep is clean where it matters.** The cloud
  attribute constants exist in exactly ONE file (`reparse-tag-policy.ps1`), so no second copy of this
  predicate can be drifting — the consolidation this feature argued for, working.
  **One APPARENT instance, measured and found NOT to be one on its own platform — CLOSED, not deferred**
  (maintainer, 2026-08-10). `scripts/specrew-install-shell-wrappers.ps1:148-149` classifies any reparse
  point as a link, which read as the same blanket-refusal shape. It is not, because that script never
  runs where the shape exists:

  - It is **macOS/Linux only** — stated in its synopsis and, checked in CODE rather than taken from the
    comment (the DRIFT-199-I001-016 trap), enforced at the entry point: `Test-IsUnixPlatform` gates
    `Invoke-SpecrewInstallShellWrappers` at line 181 and returns before any path is classified. On
    Windows it is an explained no-op. Default bin directory `$HOME/.local/bin`.
  - The cloud-placeholder attribute model (`PINNED`, `UNPINNED`, `RECALL_ON_*`, `OFFLINE`) is a **Windows
    CloudFilter** mechanism. On Unix, .NET sets `ReparsePoint` **only** for symlinks.

  So on the platform that script actually runs on, "any reparse point is a link" is **CORRECT**, and
  there is no reachable instance of the class there. **Recorded as CLOSED rather than routed to beta4** —
  a deferral would have left beta4 an open item that does not exist, which is its own kind of false
  record. **If that script ever gains a Windows path, this note is the reason to revisit it.**

  The sweep's conclusion therefore reads: the constants live in one file, and the one apparent second
  instance was measured and found not to be one.
- **THE LESSON, and it is the THIRD time this session that measuring the real artifact contradicted a
  confident model of it** (after the `Get-ContinuousCoReviewMachineryPaths` comment and the demotion
  marks). The classifier was designed from the .NET API surface and a table of attribute constants, and
  it was WRONG about the only case that matters. A fixture can only prove the shape it synthesises; the
  real value came from measuring the maintainer's install. **When a predicate describes an external
  system's state, the fixture is a regression guard — it is not the evidence that the predicate is
  right.** That evidence has to come from the real artifact, once, before the fixture is believed.

### DRIFT-199-I001-022 — the trust-hardening validator cannot match a verdict it has (observation, routes to beta4)

- **Observed**: 2026-08-10, incidental to the T007 PSModulePath measurement. The governance
  validator passes (exit 0) but emits:

  > `WARN [trust-hardening] state-advance-without-verdict: Active session boundary advanced to`
  > `human-judgment gate 'before-implement' (iteration 001) without a matching CURRENT-CYCLE`
  > `boundary_enforcement.verdict_history entry naming an authorizing human.`

- **The verdict is present.** `.specrew/start-context.json` carries the
  `tasks -> before-implement` entry with the full text, `auth_commit_hash`
  `47476f93`, `evidence_source: hook-captured-from-transcript`, and an
  `authorization_id`. The record is not missing.
- **Measured cause, stated narrowly**: the persisted entries carry no `cycle_id` field at all,
  so a check keyed on a CURRENT-CYCLE match cannot succeed for any entry, however well-formed.
  The warning describes the validator's inability to match, not an unauthorized advance.
- **Why it still matters**: the surface whose job is to report that a human authorized this
  boundary reports the opposite while holding the authorization. That is the honest-state class,
  and on a louder day it would read as a missing verdict.
- **A method note on how it was nearly misread**: the first probe of `verdict_history` selected
  `.boundary` and `.cycle_id` and printed blanks, which looked like corroboration that the
  records were empty. The fields are `from_boundary`/`to_boundary`; the probe was wrong, not the
  data. Recorded because a wrong probe that agrees with your hypothesis is the most expensive
  kind.
- **Disposition**: DEFERRED to the beta4 list. It is a WARN on a passing validator, it advances
  and blocks nothing, and the fix is in the trust-hardening validator's cycle model rather than
  in any file this feature touches. Not routed in scope; raised for the maintainer's ruling if
  they judge it to hit the acceptance bar's honest-state clause.

### DRIFT-199-I001-020 — the demotion marks never reached the human; found by the maintainer asking for the END-TO-END check (resolved)

- **Observed**: 2026-08-10, acting on the maintainer's instruction to *verify rather than assume* that
  at least one T005 fixture drives a scenario-less finding through the REAL ingress entry point rather
  than only through the pure gating-eligibility function.
- **No such fixture existed.** Every T005 case called `Resolve-ReviewFindingGatingEligibility` (and one
  called `Resolve-ReviewCampaignPauseDecision`) directly. All four were green.
- **And the gap was hiding a live defect.** `Invoke-ReviewResultIngress` rebuilds every finding into the
  terminal result from an EXPLICIT field list (`review-result-ingestor.ps1`), and `demoted` was not in
  it. The mark was set on the graded copy and dropped one function later, so end to end a demoted
  finding reached the store — and the human — as an ordinary `minor` with no trace of the fact that the
  reviewer had reported it as blocking. The demotion worked; the TELLING did not.
- **Why the ruling's premise needed correcting, stated plainly**: the instruction to make demotion
  visible said "the data already exists: the finding carries a demoted flag". It does at the grader,
  and it did NOT anywhere downstream. Counting `demoted` in the pause resolver as instructed, with no
  other change, would have produced a counter that read zero forever and a surface that stayed silent —
  a fix that tests green and changes nothing.
- **Severity — it fails in this feature's forbidden direction**: a demotion the human cannot see is a
  SILENCING, which is the direction the whole feature exists to close. The demotion rule was written to
  stop a scenario-less finding costing a round; without the marks it also stopped the human learning
  that a reviewer's security finding had been lowered.
- **Citation**: FR-006 (the failure-scenario contract); FR-002/FR-015 (the decision surface); the
  maintainer's demotion-visibility ruling, 2026-08-10.
- **Resolution**: FIXED end to end, RED first (8 failing cases before any product edit).
  `demoted` and `demoted_from` are carried into the terminal projection and admitted by the terminal
  finding contract; `Resolve-ReviewCampaignPauseDecision` counts them (`demoted_count`,
  `demoted_from_blocking`, `demoted_from_major`); `New-ReviewCampaignPendingPauseFact` carries
  `demoted_count` so the RECORD is not quieter than the screen; and the surface names the demotion, the
  reviewer's original severity, and where the finding went.
  **The CANDIDATE finding shape stayed closed at five fields on purpose**: `demoted`/`demoted_from` are
  the controller's determination ABOUT a reviewer's output, so a reviewer must be unable to supply
  either — neither to mark itself demoted nor, worse, to declare itself un-demotable and keep a gate it
  did not earn.
  **`demoted_from` is structured data rather than a re-parse of our own prose.** The demotion note in
  the description already named the original severity, and reading it back would have been a string
  contract between two files — the shape that drifts silently.
- **Evidence**: 46/46 green across
  `tests/continuous-co-review/unit/campaign-pause-core.Tests.ps1` and
  `tests/continuous-co-review/unit/reviewer-prompt-contract.Tests.ps1`; 17 failed / 1042 passed across
  `tests/continuous-co-review/unit`, failure set identical name for name to the recorded seventeen.
- **METHOD NOTE, and it is the sixth instance**: this was not found by reasoning about the code. It was
  found because the maintainer asked for the end-to-end check specifically, on the stated grounds that
  THE WIRING IS WHAT DRIFTS. Every link in this chain was independently green while the chain was
  broken. The new fixture drives reviewer output -> ingest -> store -> decision -> rendered words in one
  case, and reads the result back THROUGH THE CONTRACT rather than from the in-memory object, so a
  future projection that drops the marks fails loudly instead of silently.

### DRIFT-199-I001-021 — the T006 design record named a third site that does not exist (records-only)

- **Observed**: 2026-08-10, wiring T006's call sites. The design record names the sites to move as
  `Get-ReviewAuthorityStorePath` (authority store), `Assert-SpecrewReviewRuntimePathContained` and
  `Get-SpecrewReviewRuntimeManagedTextSha256` (module install), **and the frozen-snapshot check**.
- **Measured, not assumed** (the relayed-diagnostic method rule): a tree-wide search for reparse
  handling returns exactly two engine files — `review-authority-store.ps1` (2 checks) and
  `review-engine-resolution.ps1` (3 checks). The frozen-snapshot path
  (`Test-GitReviewTargetSnapshotIntegrity`) hashes worktree sources via
  `Get-ContinuousCoReviewWorktreeSourceHashes` and carries NO reparse refusal to discriminate.
- **Consequence**: T006's "symmetric across module install, authority store, frozen snapshot" is
  satisfied by moving the five checks that exist. There was no fourth site to convert, and inventing a
  refusal in the snapshot path to match the record would have ADDED a new refusal under the banner of
  removing one.
- **Resolution**: recorded here rather than silently absorbed; the design record's site list is correct
  about the two real files and anticipatory about the third.

### T006 LIMIT OF THE EVIDENCE — the cloud branch is proven at the seam, not end to end (2026-08-10)

Recorded in the same discipline as T004's backstop, so a green suite is not read as more than it is.

**What the suite proves.** The refusing direction is proven on the REAL filesystem: live symlink and
junction fixtures classify as `refuse-link`, and the pre-existing refusal fixtures that this task
required to stay green were re-run and did — `review-authority-store.Tests.ps1` (store root, campaign
ancestor, run ancestor) and `tests/unit/review-engine-resolution.tests.ps1` ("a reparse-point ANCESTOR
is refused before hashing or deleting"). The store's falsifiability mutation gate still catches a
link-blind store. Each of the three call sites is proven to CONSULT the one classifier and to honour a
`hydrate-cloud` answer.

**AMENDED 2026-08-10 after DRIFT-199-I001-023 — the evidence position changed materially, and the
original wording of this entry was part of the problem.** It treated "the cloud branch is unit-testable
by attribute synthesis" as an acceptable substitute for measuring the real thing. It was not: the
synthesised attributes described a state that does not occur on a working install, and the classifier was
wrong about every file on the maintainer's own machine while this entry called the evidence adequate.

**Now measured on the REAL install** (transcribed in DRIFT-199-I001-023): the four files including
`_load.ps1` — the exact path the original refusal died on — classify `hydrate-cloud` at `0x80420`, and a
real AppExecLink still refuses. The CLASSIFIER is therefore no longer seam-only evidence; it has been run
against the real artifacts it exists to judge.

**What is still NOT proven.** That a DEHYDRATED placeholder actually hydrates on read and hash-verifies
afterwards — every file measured was already local, so the fetch path itself has not been exercised.

**NO LONGER A DEFERRED HUMAN MEASUREMENT (maintainer ruling, 2026-08-10).** The reviewer session has
shell access to the same machine and the installed module carries 396 real cloud-backed files, so the
decisive leg is executable here rather than owed. It runs in TWO HALVES against the committed tree, and
they prove different things:

1. **ADMISSION** — dot-source the committed `reparse-tag-policy.ps1` and `review-engine-resolution.ps1`
   from the beta3 tree and call `Get-SpecrewReviewRuntimeManagedTextSha256` against a file under the
   installed module. That is the exact function whose refusal on `_load.ps1` opened
   DRIFT-199-I001-005. Expected: a hash, not `review-runtime-managed-file-link-unsupported`.
2. **HYDRATION** — evict a file FIRST so `RECALL_ON_DATA_ACCESS` is genuinely set (`attrib -p +u`, or the
   folder's "Free up space"), confirm the attribute actually flipped, then run the same probe. This is
   the only half that proves the three things no seam test can reach: a dehydrated placeholder
   classifies as cloud, READING IT HYDRATES, and the hash verifies the bytes that arrived.

Both transcriptions are recorded against DRIFT-199-I001-005. **It closes only on the SECOND** — the first
proves admission, the second proves the property the whole branch exists for.

**The hydration-FAILURE path is likewise seam-proven**: the wrap is exercised by a path whose read
fails for an ordinary reason, which shows the message is produced and shaped, not that a sync client
actually declined to fetch a file.

### Measured proof line — T010's SECOND human block, transcribed from a real render (2026-08-11)

The blocking co-review stop, rendered from the shipped composer and pasted verbatim:

> `Specrew co-review — BLOCKING. The fresh-context review of your latest increment found an issue to`
> `address before you continue. Fix it, then re-stop so co-review can re-check.`
>
> `Review run run-blocking-demo (identifies this review if you need to refer to it)  -  2 blocking finding(s):`
>
> — `[src/app.ps1:10]` — Unvalidated input reaches the shell.
>
> — `[src/poll.ps1:41]` — The retry loop never backs off.
>
> `(This review ran on a private copy; your tree is unchanged.)`

And its AGENT channel, which is where the directive went:

> `Co-review navigator block, not a boundary verdict - do NOT emit a SPECREW-VERDICT-BOUNDARY marker.`

**HOW THIS EVIDENCE WAS OBTAINED, stated because it differs from the campaign block's.** That one is
transcribed from a LIVE STOP on the maintainer's own session. This one is a DIRECT RENDER of the shipped
composer: producing it from a live stop would require an actual blocking reviewer verdict, which means a
review round, which is a provider-spend event needing the maintainer's authorization. **A direct render
proves the composer's output; it does not prove the delivery path.** The delivery path is covered by the
source guard asserting the navigator assigns both `stop_block` and `agent_directives`.

**What it shows**: the run id is glossed, the findings carry clean `[path:line]` locations, the
reassurance survives the split, the agent directive is absent — and the block still names a NEXT STEP
("Fix it, then re-stop"), which is the fourth rule's requirement rather than merely the absence of
banned words.

### Measured proof line — T010's FULL stop block by emission point, transcribed from a live stop (2026-08-11)

The earlier proof line below covered the MESSAGE only, which is exactly the mistake the emission-point
ruling corrected. This is the whole block a human reads, rendered on the maintainer's own session after
the composer rewrite:

> `Specrew review — your last review no longer covers these files.`
> `The latest campaign result remains useful evidence but targets a moved or earlier snapshot and`
> `cannot authorize the current tree. That result belongs to this review`
> `(cmp-199-beta3-stabilization-i001) - whatever its run name suggests - so it is about your own`
> `earlier snapshot, not another project. If you are not the person running reviews for this project,`
> `this is advisory: there is nothing here for you to run, and it does not block your work.`
> `What to do: run a fresh review of your files as they are now: specrew review --live`
> `Review run: run-20260810-085753967-af5bef76 (identifies this review if you need to refer to it)`
> `This does not decide the approval you still owe (before-implement -> review-signoff); that decision`
> `is unaffected and still waits for you.`

**Every line is now something a reader can act on or safely skip.** The raw route name is gone from the
first line, the run id says what it is FOR, the next step names the command, the boundaries name the
decision still owed, and the 64-character identifier and the `crossing crossing-` stutter are gone.
**Both agent directives are absent** — they travel on `agent_directives` beside the block.

**THE INTERMEDIATE STATE IS RECORDED TOO, because it is the more useful evidence.** The first rewrite
rendered this same block with NO `What to do:` line at all: the machinery-addressed action had been
deleted rather than translated. That was caught by reading a live stop, not by a fixture — the fixtures
were green, because none of them asserted that a next step must exist. The lesson is the one already in
these records, generalised: **demote, never discard**, which applies to sentences as well as findings.

### Measured proof line — T010's stale-block message, transcribed from a live stop (2026-08-11)

Not drafted ahead of the run. The FIRST stop after `5b62b02f` landed rendered both new clauses on the
maintainer's own session, on the same block that had been adjudicated at every stop of this session:

> `Specrew campaign review — review-stale.`
> `The latest campaign result remains useful evidence but targets a moved or earlier snapshot and`
> `cannot authorize the current tree. That result belongs to this review`
> `(cmp-199-beta3-stabilization-i001) - whatever its run name suggests - so it is about your own`
> `earlier snapshot, not another project. If you are not the person running reviews for this project,`
> `this is advisory: there is nothing here for you to run, and it does not block your work.`
> `Run: run-20260810-085753967-af5bef76`
> `Implementer action: request-current-digest-review`

**What it demonstrates, stated narrowly**: the block keeps its review position and its implementer
action unchanged, and adds the two facts a reader needed to act — WHOSE result it is, and whether the
instruction is theirs to execute. The ownership clause names the campaign beside the run id, which is
what stops a run name from implying another project.

**What it does NOT demonstrate, recorded so the evidence is not over-read**: this run id
(`run-20260810-...`) does not look foreign, so the live stop does not exercise the misleading-run-id
case that motivated the clause — that case is covered by the fixture, not by this transcription. And the
block still RE-FIRES at every stop; the message half is fixed, the suppression is a behaviour change
and remains the maintainer's scope call.

### Measured proof line — T003's two-governor fix, transcribed from a live stop (2026-08-10)

Not drafted ahead of the run. The FIRST stop after `9d93c91c` landed rendered the scoped clause on
the maintainer's own session, on the same collision that had been adjudicated by an agent three times
earlier in this feature:

> `Specrew campaign review — review-stale.`
> `The latest campaign result remains useful evidence but targets a moved or earlier snapshot and`
> `cannot authorize the current tree.`
> `Run: run-20260810-085753967-af5bef76`
> `Implementer action: request-current-digest-review`
> `(This is a campaign review block, not a lifecycle verdict. It does not govern the recorded`
> `crossing crossing-fdfd08331c434810bfb008886e73a3476306c1bf484c84813463914ae4ba0605`
> `(before-implement -> review-signoff), which is still pending your decision: that crossing's`
> `verdict marker applies as normal, and this block does not suppress it.)`

**What it demonstrates, stated narrowly**: the block kept its review position (`review-stale`, and
the same implementer action), stopped claiming authority over the lifecycle marker, and named the
exact crossing it defers to — read from controller truth, not inferred. The adjudication a consumer
could not previously make is now stated ON the surface (FR-007 / SC-003).

**What it does NOT demonstrate, recorded so the evidence is not over-read**: deferring on the marker
is not a marker being OWED. At this stop the crossing's destination is `review-signoff`, whose
evidence (`review.md`) does not exist in the bound tree, so the boundary evidence gate is the governor
that decides — and it has been refusing correctly. The two governors now say compatible things:
"this block does not suppress the crossing's marker" and "that crossing has no evidence to approve
yet" can both be true at once, which is precisely what they could not do before.

### Measured proof line — first successful end-to-end campaign round

Transcribed from the run output, not drafted ahead of it:

> `review terminal elapsed=687.8s remaining<=212.2s tree=dead output=observed
> validated-findings=3 - terminal-result-published`
> Run `run-20260810-085753967-af5bef76`; `Invoked: True`; `Verdict: findings`;
> `Completion: complete`; `Currentness: current`; heartbeats 87.

Shape after the resize: preflight (including the slice verification lane) completed at
245.0 s, leaving ~430 s of the 900 s window for the reviewer — the reviewer received the
majority of the budget, which is the shape the maintainer's sizing rule asks for.

This is the first round in this feature to reach a reviewer at all. Reaching it required
clearing, in order: the pre-code activation demand (DRIFT-199-I001-006), the run-id minter
(-007), the feature-id non-resolution (-009, worked around), the missing verification plan
(-008/-010), and the window/scope mismatch (-012).

### DRIFT-199-I001-013 — a records-only commit staled the review that produced those records (open)

- **Observed**: 2026-08-10, immediately after commit `9a23da56`, whose ENTIRE content is this
  drift log — a records file. The campaign stop surface flipped from `review-required` to
  `review-stale` / `latest-result-not-current`, naming run
  `run-20260810-085753967-af5bef76` and demanding `request-current-digest-review`.
- **The shape**: writing down what the review found is what invalidated the review. The
  ledger's F5 sharpening names this exactly — satisfying the gate moves the target, so
  currency is unachievable by construction.
- **Why the digest moved**: the machinery strip excludes `.specrew`, `.specify`, `.squad`
  and host-mirror dirs, but `specs/` is reviewable content and therefore digest-significant.
  A lifecycle-records commit consequently reads as a source change.
- **Direct evidence for FR-009** ("commits touching only governance/records files MUST NOT
  stale a reviewed digest"): this instance is the T003 fixture — a commit whose entire delta
  is under the feature's own `specs/<feature>/` records tree must leave a reviewed result
  current.

### Round-1 fix ruling and the two method lessons (maintainer, 2026-08-10)

**Why all three were fixed rather than carried** — recorded because it models the rule this
feature is building, not a fix-everything default: each clears the severity floor with a
concrete failure scenario in a SHIPPED surface of this feature. One silences a review gate;
two leaves a consumer requirement unfinished on the path a consumer actually runs; three
makes an acceptance criterion falsely green. Polish would have ridden as a recorded residual.

**Path-identity lesson (finding 1)**: this is the beta2 certify-round-3 path-identity class
RECURRING. The single-source comparer (`path-identity.ps1`) already existed, and it appears in
`reviewed-state-digest.ps1` — a file read while writing the defective fix. The reviewer session
endorsed the predicate without catching it. Vigilance did not catch this class even freshly
named and freshly read; the mechanical comparer would have. That is evidence for beta4's
path-identity consolidation: the fix is routing every containment comparison through the one
primitive, not asking reviewers to remember.
Fixed by routing through `Get-ContinuousCoReviewPathComparison` (the sibling the comparer
wraps, and the shape a `StartsWith`/`Equals` call needs) with `-WhenUndetermined 'distinct'`,
so an undetermined volume keeps the surface LIVE.

**Test-design lesson (finding 3)**: a test that derives its expectation from the same source as
the code under test cannot detect that the source is wrong — it verifies plumbing, not the
requirement. The T011 fixture derived the expected version from the manifest the provider reads
and asserted only that some suffix existed, so it passed while the manifest said `beta2` and
SC-010 (`0.40.0-beta3`) was false. **Rule**: acceptance criteria that fix a LITERAL value get
LITERAL assertions; derived assertions are for invariants only. The manifest prerelease is now
`beta3` (psd1 field only, `extension.yml` left bare per the beta2 precedent;
`validate-versions` re-run clean: Spec Kit 0.12.9, Squad 0.11.0, compatible, exit 0).

### Round-1 findings (held for the maintainer; no fix round started)

Three findings, all severity `major`, recorded in the authority store under the run above:

1. **Case-insensitive path matching can suppress a real review** — the implementation-presence
   classifier added by `afe1dd1e` compares changed paths to the machinery and `specs` roots
   with `OrdinalIgnoreCase`, while this repository derives path case semantics from the target
   volume. On a case-sensitive filesystem a change under a case-distinct root is a genuine
   reviewable path but classifies as records-only; if it is the only delta the navigator
   returns `campaign-not-applicable` and never consults the gate.
2. **The public campaign timeout output still omits the next step** — the consumer-shaped
   text added by T009 sits on the signoff-gate decision route only. The `specrew review
   --live` campaign branch prints the raw failure reason and exits without naming
   `co_review_timeout_seconds`, and `--help` still advertises a 120-second default.
3. **The banner acceptance test blesses the stale manifest** — the manifest still declares
   `Prerelease = 'beta2'`, so the fixed provider renders `0.40.0-beta2`. The T011 fixture
   derives its expectation from that same manifest and only checks that some suffix exists,
   so it passes while SC-010 (`0.40.0-beta3`) is false.

Transcribed from the measurement, not drafted ahead of it (198 method rule). Run locally
at HEAD after the three ratified exception commits:

> `F-198 honesty regression suite: all 95 suites green in 627.685s.` (exit 0; measured
> elapsed 628.5 s, `-PerTestTimeoutSeconds 300`)

This includes `tests/continuous-co-review/unit/continuous-co-review-navigator.Tests.ps1`
(34.560 s) — the file whose 2026-08-08 guarantee was sharpened — so the amended assertions
pass inside the honesty regression lane as well as in isolation.

### DRIFT-199-I001-012 — the slice review's verification budget cannot fit its window (open; authoring error owned)

- **Observed**: 2026-08-10, run `run-20260810-074723936-616f0b0e`. Terminal after 894.6 s
  of a 900 s window: `verification-command-failed:f199-deterministic-registry:
  diagnostics-require-command-scoped-disclosure`. `Invoked: False` — the reviewer was
  never started, so no provider spend; roughly 15 minutes of wall clock was consumed.
- **Cause, established by measurement rather than by unsealing**: the registry command
  needs ~628 s and is fully green (proof line above). The round's total budget was 900 s,
  and the verification command's own `timeout_seconds` was authored at 1200 s — larger
  than the window containing it. The plan could not pass by construction.
- **Authoring error owned**: the 1200 s figure was copied from the beta2 plan, which
  governed SIGNOFF-grade verification where a long window is appropriate. Reusing it for
  a mid-implementation slice review under a 900 s window was the mistake.
- **Second finding, ledger F3 reproduced**: the failure reason was SEALED
  (`diagnostics-require-command-scoped-disclosure`) — the consumer cannot see why their
  verification failed without a human-authorized diagnostic disclosure. FR-013 is the fix;
  this is a live reproduction on the maintainer's own repository.
- **Ruled 2026-08-10 (maintainer)**: no unsealing — the local clock already answered it.
  The registry passes (95/95, 627.7 s), so the sealed failure was the window, not a red
  suite; spending a diagnostic authorization would buy nothing. Resizing rule: size
  verification to fit COMFORTABLY inside the round — more than roughly half the window is
  the wrong shape, since the reviewer needs the remainder (627.7 s of 900 s was 70%).
  Scope rule: the full deterministic registry is the RELEASE GATE lane; a slice review
  points at the suites the slice touches, and the plan legitimately differs between those
  contexts. Both rules recorded in T007's design record.
- **Underlying defect, recorded separately as the durable half**: per-command
  `timeout_seconds` and the round window are unrelated numbers with NO consistency check,
  so the engine accepted a plan that could not possibly pass, ran it for the full window,
  and reported a sealed failure. A consumer authoring their first plan will do exactly
  the same thing with no way to see why. The cheap fix — validate at plan-validation time
  that command timeouts fit the configured window, naming BOTH numbers in the message —
  is recorded in T007's design record; implement only if it is a few lines, else beta4.

### DRIFT-199-I001-011 — ledger F5 (in-flight blindness) reproduced with store evidence (open)

- **Observed**: 2026-08-10, while the authorized round was executing. The campaign stop
  surface emitted `review-required / no-authoritative-campaign-result` with implementer
  action `request-authorized-review` — instructing that a review be requested while one
  was already running under the maintainer's authorization.
- **Store evidence at that moment** (`.specrew/review/authority/campaigns/cmp-199-beta3-stabilization-i001/runs/`):
  - `run-20260810-074723936-616f0b0e` — `requested.json`, `reserved.json`, and NO
    `result.json`: reserved and in flight, not terminal.
  - `run-t003-activation-slice-1` — the earlier terminal `preflight-failed` run.
- **Maintainer ruling 2026-08-10 — this narrows FR-008's work**: the task is NOT "add
  in-flight awareness" but "make the EXISTING `review-running` route recognize a
  reserved, non-terminal run". T003's fixture pins exactly that shape — a run holding
  `requested.json` + `reserved.json` with no `result.json` must suppress the block and
  route to `poll-existing-run` — and it writes itself from the evidence below.
- **Sharper than the ledger's statement**: the classifier already HAS an in-flight route
  (`review-running` / `current-review-in-flight` / `poll-existing-run`,
  `review-signoff-evidence-gate.ps1:366`). The defect is not a missing concept — the
  existing detection did not match this reserved, non-terminal run. T003's FR-008 fixture
  should pin THIS shape: a reserved run with no terminal result must suppress the block
  and route to `poll-existing-run`.
- **Incidental confirmation**: the run id `run-20260810-074723936-616f0b0e` is the fixed
  minter's output (lowercase-safe stamp) reaching the store on the default path, with no
  explicit `--run-id` supplied — the DRIFT-199-I001-007 fix working end to end in the
  shipped flow.

### DRIFT-199-I001-010 — the verification definition is per-machine, not in the repository (sharpens ledger F2)

**Measured 2026-08-10** against `C:\Dev\specrew-beta2-hardening\.specrew\verification-plan.json`
(commands run in that worktree; results transcribed):

| Property | Measurement |
| --- | --- |
| Tracked by git | NO — `git ls-files --error-unmatch` errors; `git status` reports `??` |
| Ignored by git | NO — `git check-ignore -v` returns nothing (it could have been committed) |
| Created / last modified | 2026-07-19 16:02:54 / 2026-07-19 18:54:29 |
| Feature/iteration binding | hardcoded: `plan_id: f198.i008.signoff.v5`, and `-IterationPath specs/198-beta2-hardening/iterations/008` |

Consequences, stated as facts: the definition survives neither a clone, nor a new
worktree, nor a new feature. It is hand-authored and per-machine. This feature's own
worktree had none, which is why the first authorized campaign round terminated
`preflight-failed` (DRIFT-199-I001-008).

**Honest-claims item against the release record**: the three certification rounds that
gated the v0.40.0-beta2 tag verified against a definition that is absent from the
repository. The runs and their results are recorded in the review authority store and
stand as recorded; the verification DECLARATION they executed is not reconstructible from
the repository at any commit. This is a recorded gap in the evidence chain, not a
reopening of the certification and not a claim about the runs' outcomes.

**Resolution for this feature**: `.specrew/verification-plan.json` is authored for
feature 199 and COMMITTED (maintainer ruling: the verification definition must live in
the tree the reviewer reads, not beside it). It carries the deterministic registry lane
plus governance validation pointed at `specs/199-beta3-stabilization/iterations/001`, and
the N4 env_refs list including TMPDIR. One disclosed addition beyond N4: `PSModulePath`,
because this repository's verification commands are PowerShell and resolve modules
through it — exactly the project-specific one-line addition the N4 default anticipates.
Validated through the shipped contract before use (`Test-ContinuousCoReviewVerificationPlan`
returned valid).

### DRIFT-199-I001-009 — the campaign command does not resolve the feature id (deferred)

- **Observed**: 2026-08-10, immediately behind the run-id defect. With `--run-id` supplied
  but no `--feature`, the campaign path failed with
  `Cannot validate argument on parameter 'FeatureId'. The argument "" does not match the
  "^[0-9]+-[a-z0-9][a-z0-9-]*$" pattern.`
- **Cause**: the campaign command does not consult `.specify/feature.json` the way other
  Specrew scripts do, so the feature id arrives empty at a validated parameter. (The
  identity resolver itself has fallbacks — navigator feature root, then branch name — but
  the empty value is rejected before reaching them.)
- **Consumer impact**: a consumer running the review the stop surface demands must
  discover `--feature` and `--iteration` by trial.
- **Resolution**: DEFERRED per the maintainer's ruling — it is not a one-line fix inside
  code already being touched (it sits in the CLI's campaign branch parameter contract,
  not in the identity minter). Routes to the beta4 list.

### DRIFT-199-I001-008 — ledger F2 reproduced: the authorized review cannot run without a verification plan (open)

- **Observed**: 2026-08-10, run `run-t003-activation-slice-1` (codex, 900 s window,
  `authorization-ref: beta3-t003-activation-slice-1`). Terminal state after 134.2 s:
  `runtime_outcome: preflight-failed`,
  `failure_reason: verification-not-configured:no supplier output at
  .specrew/verification-plan.json (FR-049 supplier not configured)`.
- **Significance**: this is ledger finding T067-F2 (fresh projects have no verification
  plan and the campaign preflight cannot proceed) reproducing on the maintainer's own
  repository, and it produces a BOOTSTRAP DEADLOCK at the gate: the campaign stop surface
  demands a review, and the review cannot start without an artifact that only
  `specrew init` scaffolds. Task T007 (FR-012/FR-013) is the fix.
- **Cost measured, not assumed**: `invoked: null` — the reviewer process was never
  started, so no provider spend; and a release fact
  (`releases/res-c7aec2d1e10f88a63c15.json`) returned the reserved slot with the failure
  reason, so no round allowance was consumed.

### Evidence note — ledger F4 did NOT reproduce on this failure class

Ledger finding F4 records infrastructure failures consuming the round allowance. On this
`preflight-failed` run the pre-invocation release path worked: the slot was reserved,
then released, with the failure reason recorded. Stated as a measurement, not a claim
about F4 generally — T008's RED fixture must therefore pin the specific failure classes
that do NOT release, rather than assume every infrastructure failure charges a round.

### THE SEVENTEEN — FAIL-ON-MAIN TRIAGE, MEASURED 2026-08-11 (each one dispositioned before the gate)

Ordered before review-signoff rather than discovered at it. The same suite was run in a DETACHED
WORKTREE at `origin/main` and the two failure sets compared name for name.

> `MAIN   PASSED=933  FAILED=16`
> `BRANCH PASSED=1098 FAILED=17`

**SIXTEEN OF SEVENTEEN ALSO FAIL ON MAIN — pre-existing, and the branch introduced none of them.**
Name for name identical: the inline `$proc.Kill` fallback; the ceiling-halt escalation finding; the
partial-run `moreTimeNote`; the ten T067 signoff-gate cases; and the three T073/T074 conditional-Assert
cases. **Disposition: inherited, out of this feature's closed scope, routed to beta4** — unchanged from
the recorded baseline, now MEASURED rather than assumed from their having been constant.

**THE SEVENTEENTH — `the captured corpus contains NO flush/read race signature` — PASSES ON MAIN, and
that does NOT make it branch-introduced.** The measurement has a confound and it must be stated, not
resolved by the convenient reading:

- The analyzer reads MACHINE-LOCAL runtime state (`.specrew/runtime/conformance-journal.jsonl`), not
  code. The triage worktree is a fresh temp checkout, so it carries NO journal — the analyzer passes
  there because **its evidence is absent**, not because the code differs.
- That is precisely the case the recorded rule anticipates: *a detector that goes green because its
  evidence was deleted has not been fixed.* A green on main is exactly such a green.
- **So "passes on main" is uninformative for this one detector.** No code change in this feature could
  have produced the signature; the session's own stop traffic captured it, in this worktree's journal.

**Disposition: environment-dependent detector, evidence-preserving, routed to beta4** (DRIFT-199-I001-015
and the flush-race routing ruling), with the durable evidence being the verbatim signature recorded
there rather than the pass/fail state of the analyzer.

**Net: zero branch-introduced failures.** Seventeen dispositioned — sixteen inherited by measurement,
one environment-dependent with its confound named. The +165 passing tests on the branch (933 -> 1098)
are this feature's own additions.

### THE BRANCH TEST BASELINE IS SEVENTEEN (restated 2026-08-10 by maintainer ruling)

A future measurement reading 17 must not treat it as a fresh regression. The branch baseline is:

> **16 inherited failures at `acbb4366`** (named individually below) **+ 1 T109 flush-race
> analyzer failure**, firing on a preserved real signature dispositioned to beta4.
> Measured total on this branch: **17 failed / 989 passed** across
> `tests/continuous-co-review/unit`.

**Rule recorded with it — a detector that goes green because its evidence was deleted has not
been fixed.** The T109 analyzer reads machine-local journal state
(`.specrew/runtime/conformance-journal.jsonl`). If that corpus rolls over, the test passes again
while the defect is untouched. The DURABLE evidence is the verbatim signature captured below, and
that is what beta4 inherits. A later green is not resolution.

### Flush-race routing ruling (maintainer, 2026-08-10) — beta4

DRIFT-199-I001-015 routes to beta4. Reasoning recorded so the routing stays honest:

- **Not a wedge.** A spurious packet block costs one extra turn and then passes. That is what
  separates it from every defect ruled in scope today, each of which made a state unreachable or
  a requirement false.
- **New territory.** It lives in the conformance provider, a subsystem this feature has not
  touched; taking it would open a fifth exception into new code on the strength of one signature.
- **Cheap in lines, not in risk.** The remedy the analyzer names (a cheap re-read variant) changes
  READ SEMANTICS IN THE STOP PATH — the most safety-critical hook path in the product. Beta4 does
  that deliberately rather than as a fifth in-flight exception.

### Path-identity: what the guard proves (recorded 2026-08-10, maintainer framing)

The counter-story to "vigilance failed". The guard that caught DRIFT-199-I001-014 was written for
a PREVIOUS incident of the same class (DRIFT-198-I009-027). It caught today's defect after both
the reviewer session and the implementer's own attention had missed the class TWICE in one day —
once using the wrong comparison, once using the right one unsafely.

**What this sharpens for beta4's path-identity consolidation**: the target is not "use the
comparer". It is to make the comparer the ONLY REACHABLE PATH. A primitive that can be bypassed by
forgetting a dot-source will be bypassed again — today is the proof, from someone who had just
finished writing the lesson down.

### Named test baseline — inherited failures, measured 2026-08-10 (not this feature's)

Measured at the maintainer's instruction so this feature never inherits credit or blame
for failures it did not cause. Both runs used the identical capture script and path
(`tests/continuous-co-review/unit`).

| Measurement | Commit | Passed | Failed |
| --- | --- | --- | --- |
| Trunk baseline (detached worktree) | `acbb4366` (merge-base with origin/main) | 933 | **16** |
| This branch, after the T003-early repair | `afe1dd1e` | 941 | **16** |

**The two failure sets are IDENTICAL, name for name.** Regressions caused by this
repair: **zero**. The branch also passes 8 more tests than the baseline (the 7 cases this
repair added, plus one further test that runs on the branch and not at the baseline — an
unexplained but non-material delta, recorded rather than smoothed over).

The 16 inherited failures, at `acbb4366`:

1. `T091 inline reviewer spawn - OS-native containment` — the divergent inline `$proc.Kill`
   fallback is DELETED (one kill mechanism)
2. `T026 TG-011 non-convergence escalation` — a ceiling-halt emits a VISIBLE escalation
   finding (false-green guard D-197-I009-010)
3. `navigator "more time" note on a partial reap (T092/R2)` — partial run -> moreTimeNote
   present
4-13. `T067 re-architected co-review signoff gate (FR-025)` — ten cases: blocks with no
   evidence; ALLOWS on a chained pass; BLOCKS HOLE A (gitignored-source staleness);
   BLOCKS HOLE B (unchained pass); A1 multi-hop ALLOWS; A1 multi-hop gap BLOCKS; blocks
   stale after tree drift; blocks when the trunk anchor cannot be resolved (fail-closed);
   allows under a well-formed human-authorized override; ignores a malformed override
14-16. `T073/T074 hard co-review signoff-gate wiring (FR-025/SC-019/SC-020)` — three cases
   on the conditional-Assert seam: (a) no passing run THROWS and persists the block;
   (b) a fresh passing run does not throw; (b2) the allow path returns nothing

Disposition: inherited, out of this feature's closed scope. Routed to the beta4 list
unless one of them blocks the acceptance bar. Not a claim about their cause — only a
measurement of what was already red at the branch point.

### DRIFT-199-I001-004 — plan total arithmetic error (resolved, records-only)

- **Observed**: 2026-08-10, at tasks decomposition. plan.md stated "12.1 SP planned"
  while the W1–W13 table sums to 13.1 SP. The approved table itself was correct and
  is unchanged; only the stated total was wrong.
- **Citation**: honest-state rule (count-claims must match artifacts).
- **Resolution**: spec-updated (records-only) — the total line corrected to 13.1 SP
  with the overcommit against the ~10–12 target made visible; surfaced prominently
  at the tasks boundary stop for the maintainer's ruling.

### Resolution Strategies (Unused)

The following resolution strategies remain available if drift is detected later in execution:

- **spec-updated**: Update the spec to reflect implementation choice
- **implementation-reverted**: Revert implementation to match spec
- **deferred**: Mark drift as deferred to next iteration
- **human-decision**: Escalate to Alon for resolution

### Notes

- This artifact was scaffolded before review starts so drift can be logged immediately when detected.
- Replace the zero-drift summary with real counts when the first drift event is recorded.
