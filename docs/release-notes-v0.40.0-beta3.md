# Specrew v0.40.0-beta3 Release Notes

`v0.40.0-beta3` is a narrow stabilization prerelease for the `0.40.0` line. It has one goal, which is
also its acceptance bar: **a consumer completes their first feature without hitting an endless review
loop, a wedged gate, or a sentence they cannot understand.** It is a prerelease, not a stable promotion.

**Published 2026-09-01**, on the tag `v0.40.0-beta3` (commit `4f4dce52`). The two publish gates this
release was held for are both closed and described below: a brand-new project walked from init through the
clarify boundary on these exact bits, and the recovery path was proved against the original stranded
specimen. What remains ahead of the batch is the beta3 branch's own pull-request review, which happens once
at `feature-closeout`.

## What this release is about

Beta2 shipped a review system that worked and was hard to live with. Beta3 does not add capability; it
removes the ways the system could take a consumer's time, money, or understanding without giving
anything back.

## The tag batch (iteration 002)

Ten findings from two live walks against the released build - KeyContextAI and a greenfield
HelloWinUIReactive - plus two defects this iteration's own boundaries produced while it ran. Every fix
carries a mutation that turns its own case red by asserting observable state.

**Authority cannot be forged.** A boundary crossing is no longer minted until the stage it enters has its
owed artifacts on disk, at all three minting mechanisms; the verdict marker carries its crossing identity
and the capture refuses a marker for a superseded one; and no packet offers verdict options for a stage
that has produced nothing - one discipline now, in the gate-stop skill, Rule 53, the refocus texts and the
methodology table, where they previously contradicted each other.

**A pending crossing is owed by the session that recorded it.** The boundary demand fired in every session
on every stop for as long as any crossing stayed open, so a second session could not hold an ordinary
conversation. Ownership now resolves to three states; only a different, live session is suppressed, and an
owner that cannot be confirmed - including one that resumed into a new identity - still gets the demand,
with a sentence saying so.

**The record agrees with itself.** The crossing writer now writes every enumerated copy of the authority it
records (state.md Current Phase, plan.md Status), in each file's existing vocabulary; the sync re-mirrors
forward and the truth gate refuses a copy that runs ahead of the store.

**Greenfield projects are not asked to publish.** `pushed-head` carried two jobs under one name; it is now
delivery-only at closeouts, reading the enforcement mode a project already recorded, while a separate
`verdict-commit-durable` check keeps every boundary's commit durable wherever a remote exists.

**Refusals say what happened.** A document that matches none of a constrained reader's constructs is
reported as unparseable, naming the representation, instead of firing every field backstop; a lens is closed
by a governed writer that checks the typed reply, the record and the lens's own validator at its own
checkpoint; a reply that is not the closing phrase is acknowledged rather than silently re-asked; a verdict
that did not capture says so at prompt entry; the specification is no longer scaffolded before the workshop
that decides it; and the closeout seal is written last, so the first validation of a closed iteration passes.

## The review loop stops on its own

- **Every review round now ends in a pause, never another round.** The loop that ran fifteen fix rounds
  on one target cannot happen: continuation is a numbered choice the human makes, each answer authorizes
  exactly one round, and an agent cannot manufacture continuation from a previous approval. At four of
  four rounds, the public command refuses before reviewer setup or spend; another round requires the
  human to run the explicit allowance-reset ceremony.
- **The pause surface says what it found, what it cost, and what happens next** — findings with their
  locations, minutes and rounds spent, the budget position, and three numbered options with their
  consequences. Nothing runs and nothing is spent until you answer.
- **Minor findings never gate.** They are carried as recorded follow-ups, so a documentation nit cannot
  hold sign-off hostage.
- **A finding that states no concrete failure scenario cannot cost you a round.** It is demoted below
  the gating floor rather than discarded — and the demotion is now visible on the surface, naming the
  severity the reviewer originally gave it. A demotion you cannot see would be a silencing.
- **"Stop here" is one action**, chaining the final check, the acceptance of remaining findings, and
  sign-off. Previously this collided with the sign-off gate and left the human adjudicating by hand.

## Gates that can be answered

- **One stop surface, one authority.** A review block no longer claims authority over a lifecycle
  decision it does not govern; it names the lifecycle decision it defers to and says so plainly.
- **A stale review block now says whose result it is** — naming the review that owns it, so a run name
  that looks like another project cannot send you investigating something unrelated — **and says when
  the block is advisory** for a reader who is not the person running reviews.
- **A review that cannot start now says why, and what to run.** A fresh project gets a starter
  verification plan at `specrew init` instead of a refusal that names a requirement id.
- **Verification failures name the missing piece**: which command failed, its exit code and duration,
  and exactly which environment variable names the plan allowed through — derived entirely from facts
  the engine already owns. **No sealed diagnostic was unsealed to do this**; the human-authorized,
  scoped, redacted disclosure door is unchanged.
- **Cloud-synced installs work.** OneDrive-backed module installs were refused outright, which made the
  product unusable on the default Windows install and blocked even the door for recording a governance
  decision. Symbolic links and junctions are still refused; a cloud placeholder is read.

## Language you can act on

Consumer surfaces no longer carry internal vocabulary, and identifiers no longer travel alone: a
`T###` or `FR-###` in a message a human reads carries a short description on first use. An identifier
you must look up is a sentence you cannot understand.

The blocking self-leak firewall now derives Specrew provenance shapes instead of remembering only
recent feature and decision prefixes. Governed commands and workshop teaching contain no Specrew
history IDs; implementation provenance is allowed only through an exact token list with a recorded
reason, so a newly added ID is red by default. The lane explicitly covers the FileList-derived files
that init/update copies into consumer projects, not module-only engine internals.

## The workshop waits for your typed answer

- **Workshop questions use visible prose on every supported host.** A host picker is not the authority
  surface for product, agenda, or lens decisions. On Copilot CLI, pressing `Ctrl+O` dismisses a picker;
  it supplies no answer and grants no delegation. Specrew re-renders the unanswered workshop question
  instead of allowing the agent to choose the product framing or technical decisions itself.
- **The complete technical-lens agenda is shown before lens 1.** Selected lenses include their depth and
  purpose; every skipped lens is listed with a feature-specific reason. The workshop waits for a typed
  confirmation of that exact selected/skipped set before continuing.
- **Workshop-record-only lens transitions stay on the normal question path.** Persisting the previous
  lens and asking the next one no longer produces a duplicate five-part material-work packet. If the
  turn changes anything outside the workshop record set, the ordinary material-work packet still wins.
- **The first product-domain question stays conversational after feature scaffolding.** The untouched
  `spec.md` template created beside the workshop controller is not treated as authored material, while
  any real spec edit still requires the ordinary packet. Hook, task, system, and environment prompts
  replayed by a host never count as a typed human answer and cannot authorize the workshop. The hook
  dispatcher journals hashes of both the visible prose and exact host envelope, so this rejection does
  not depend on remembering every consumer-facing prefix.
- **Workshop ordering is enforced where an answer is produced.** A product question shown before feature
  setup is refused before the human can answer it. The technical agenda cannot be rendered until the
  product grounding has been recorded, and an agenda shown early is stopped with the real prerequisite
  instead of inviting confirmations that can never count. If the agenda is shown with rewritten bullets
  or spacing, that Stop says so immediately and asks for the command output unchanged; the check is not
  relaxed. Answers consumed through a structured picker or a dismissed question UI mint no workshop
  authority; when product records were persisted that way, the next Stop names the selection channel
  and requires each question re-asked as visible prose with a typed reply — on every host, including
  ones with no per-tool-call hook event. Work outside the workshop notes still owes the ordinary
  material-work summary, but during a workshop that request now names the open topic and the work
  that triggered it, and the summary has to end by asking the same question again, so a design
  conversation is never replaced by an engineering interrupt. Recovery says whether an answer was
  actually preserved, proposes one action, and does not diagnose or blame Specrew.

## The workshop's first turn no longer interrupts you

**Type what you want to build, and the first thing you see is the first question.** That was not true
until this release.

Creating a feature writes a placeholder specification, which says in so many words that the specification
comes after the workshop. A guard then noticed that a file outside the workshop notes had changed and
stopped to tell you about it, before you had answered anything, about a file the product had written
itself seconds earlier and you had never touched.

An exemption for exactly this case already existed and had never once worked. It compared the placeholder
against the upstream specification template, but the governed step replaces that template with a much
shorter stub, on purpose, so a template cannot tempt anyone into writing requirements early. The two files
were never the same size, so the comparison failed before it began.

The check now reads the same marker the specify boundary already reads to decide whether a specification
has been written. One rule, one answer.

**What still stops you is unchanged.** If anything writes real content into that file during the workshop,
you are told, because that is genuine work you did not see happen. That protection was proven in both
directions before this shipped: an authored specification still stops, and the untouched placeholder no
longer does.

## What a review actually costs

Stated as a receipt rather than an estimate, from the authority ledger of T067 (the dogfood feature whose review loop exposed these costs):

> **Twenty-six human authorizations for one feature's reviews, twenty-five of them spent.**

At least one of those was demonstrably unnecessary. A pre-invocation failure released its slot at
21:17:07, nothing surfaced that the authorization had come back, and a fresh one was issued three
minutes later. **That specific waste is what this release fixes**: when a review fails before it starts,
the slot returns and Specrew now tells you so, in the place where you would otherwise reach for a new
authorization.

**Limit of this evidence, stated rather than implied**: those counts are relayed from the T067 store,
which is not present on the machine where this release was built, so they were not re-measured here. The
mechanism they describe — a restored slot that nothing surfaced — was verified directly in code.

## What this tag names

**The tag sits on commit `4f4dce52`, now several commits behind the branch tip.** That is deliberate, and
the gap is disclosed in full below rather than rounded off.

**These bits were walked, not just built.** On 2026-09-01 a brand-new project took the installed 4f4dce52
build from init through the clarify boundary with **zero governance stops that were not about the work** -
including the first field execution of `confirm-intake-lens` on any build, the path whose absence used to
deadlock every new project at its first workshop lens. The comparison that matters is the first walk of
this fortnight, which took nine stops to reach specify. Same activity, both ends. The walk ran on the
claude host; a codex fresh-project datum was not collected.

**And the recovery branch was proved on the specimen that motivated it.** The project that had genuinely
been stranded by the pre-fix defect was preserved rather than repaired when it was found. On 2026-09-01 the
recovery close ran against it untouched, on codex, on these same bits: it consumed the human's preserved
receipt rather than minting authority for itself, left the confirmed agenda alone, and produced a record
that validated at the checkpoint. Both publish gates - a fresh project through clarify, and the recovery on
a real stranded one - are complete, and no tag-relevant evidence row is unproven. `4f4dce52` is
the commit that was built, installed, and walked, so the tag, the build stamp, and every walk's evidence
name the same bytes by construction — no rebuild, no restart, no gap between what was verified and what
ships.

**Three commits now sit outside the tag** (updated 2026-08-31 as the hold continued), and the third is not
like the other two:

- `aef84004` - the drift record about holding this publish for a final walk. Unpackaged spec artifact only.
- `4a652621` - the Copilot walk's field results, the third-reader finding, and the tag-identity ruling.
  Records only.
- `e3ccc53f` - **product code**: the clarify boundary's refusal now names the two forms it accepts instead
  of saying only `spec.md required content`, with a guard and a mutation proof. **This tag does not contain
  it.** beta3 ships the bare refusal, and the fix rides the next build; it is recorded as pre-plan work at
  DRIFT-199-I003-014 pending ratification at beta4 planning.

The first two are the diary; the third is a real change deliberately left outside, because the tag names
the bytes that were **built, installed and walked**. Moving the tag to pick up the fix would mean rebuilding
and re-walking everything, and unverified bytes under a verified tag is the worse trade. Process history
about the release act continues past the tag; a release tag names the bytes that ship, not the diary of its
own creation.

## How this release was reviewed

**The tag has no pull request, by design.** `v0.40.0-beta3` is a ref on a pushed commit; the independent
review that stands behind it is the **campaign record** — reviewer evidence produced on a different harness
than the one that wrote the code — together with the **two field walks** described above, both run on these
exact bits.

**The release gate is rehearsed before the tag exists, and that rehearsal has already paid for itself.**
A `workflow_dispatch` dry-run now runs the full-tree census on the release branch before any tag is cut.
The first one caught a PSGallery corrupt-zip transient in `prepublish-validation` - the publish-test
container failing to install Specrew with `End of Central Directory` - which had nothing to do with the
code and everything to do with what happens next: on a tag push that is a red job, a skipped publish, an
empty gallery, and no one watching. It would have blocked this release silently for the **second
consecutive time**, on a cause unrelated to the first. The rehearsal turned it into a re-run.

**What the code-unchanged proof proves, stated so it is not read as more than it is.** It compares
NON-COMMENT token streams, so what it establishes is that **the code is unchanged** - not that the comments
are inert. Those two claims come apart exactly where a comment carries something a tool reads, and this
tree has such a case: an authority-marker comment that a guard parses as machine-readable data. None of the
six rewrites touched a marker, so the gap did not bite - but that was luck rather than scope, and the proof
is named for what it measures. **A comment correction to a marker-bearing line is NOT covered by it.**

**Scope of the inertness proof, stated so it is not read as more than it is.** The six comment rewrites in
the deployed scripts were proved inert by tokenizing the four affected files before and after, discarding
comment and whitespace tokens, and showing the remaining token streams identical - with a negative control
demonstrating the comparison detects a real code change hidden under a comment change. **That proves those
four files' behaviour is unchanged. It proves nothing about the tree.** At the moment it was run the tree's
`.specify/` mirrors still disagreed with those four files, and the census caught that separately. The proof
is valid for exactly what it claims and is not a tree-level guarantee.

**The full PR review of the beta3 branch happens once, at `feature-closeout`, in beta4.** The feature branch
stays unmerged until then; only documentation crosses to `main` ahead of it, so that the repository's front
page describes the release a visitor can actually install.

Whether **Copilot PR review** joins that closeout gate is a decision to be made deliberately at that gate,
not inherited from how this batch happened to run. Recorded here so it is a choice someone makes rather
than a default nobody noticed.

**And there is now a data point for that decision, from this release.** The documentation pull request
carrying these notes, the README banner and the CHANGELOG entry received its only external review from the
**Copilot PR reviewer**, and it found **three real defects** in the release's public voice that every human
and agent in the loop had read past:

1. the README's "latest stable baseline" still said **0.37.0**, contradicting, on the same page, the new
   banner that points readers at `releases/latest` (which resolves to **v0.38.0**);
2. this file was still titled **(DRAFT)** while serving as the body of a published GitHub Release;
3. it still carried a **future-dated disclaimer** ("this draft is written at implementation time and is not
   a release claim") on the document that *was* the release claim.

None is subtle, and that is the uncomfortable part. **These are the most-read documents of the release** -
the front page a beta tester lands on and the notes attached to the download - and they were reviewed by
the fewest eyes. Every gate this batch built points inward at the code and the lifecycle records; nothing
pointed at the prose that represents them. The bot was the only reader positioned to see the page as a
stranger sees it.

## This tag was cut once before, on 31 August, and did not publish

**A tag named `v0.40.0-beta3` already existed. It was deleted and re-cut, and this section is why.**

On 31 August the tag was cut on commit `4f4dce52` and a GitHub pre-release was published from it. The
publish never completed. The workflow the tag triggered ran three jobs: pre-publish validation passed, the
full-test census failed, and the publish job was skipped because the census gates it.

The census failed 23 of 404 named test files.

**Nobody noticed for two days.** The pre-release was visible the whole time, so from outside it looked like
a release had happened. What had actually happened is that the gate did its job and the result went unread.
That is the part worth saying plainly: the failure was not subtle and not hidden, it was simply not looked
at.

The response was a respin rather than a patch on top. A branch was taken from the same commit, and the work
was confined to tests, the census harness, and a small set of packaged fixes the census surfaced. The
original tag and its pre-release were then deleted and `v0.40.0-beta3` re-cut at the respin candidate, so
the name points at bits that passed their own gate.

**If you installed from the 31 August pre-release, replace it.** It carries a malformed authority marker in
a deployed script, described in the next section, and it is a build whose gate never went green.

## What the release gate measured, and why its failure count went up

The full-tree census is the gate this release hangs on. Reading its numbers needs one fact stated plainly,
because the raw figures invite the opposite conclusion.

**The census went from 22 failures to 25 - and that is the gate getting stronger, not weaker.** A bare
Windows runner has no `uv` and ships Node 22, while Specrew's own declared floor is Node 24 - unchanged
since beta2. So `specrew init` failed its own dependency check and the gate recorded the product correctly
refusing an unsupported machine as failing tests. Provisioning the runner to the product's own stated
requirements made the census **measure the tree** rather than the runner; tests that could not previously
run - one of them needs markdownlint - now genuinely execute. More measurement, more findings. Provisioning
would only be cheating if it went **past** what a real consumer needs; it does not.

Of the 13 new entries, 9 were a single mirror-parity defect introduced and fixed inside this work, and 4
are distinct. 12 entries survived from the first run and are the real remainder.

**A related limit, stated rather than implied**: this project has no census baseline, because **the census
has never passed**. The job was added on 2026-08-26, after the beta2 release, which therefore never ran
it, and every run containing it since has failed. These results are a **first measurement, not a
regression list**. Nothing in a census result should be read as "this broke recently"; only a local control, holding
the machine and the harness fixed while varying the tree, can date a failure. The tests are years older
than the gate, so an individual failure may still be long-standing - one of them is confirmed so.

## What the release gate actually found

**The census found ZERO regressions.** Nothing that worked in the previous release stopped working in this
one.

It found one **defect at birth** - a malformed authority marker in a deployed script, where the marker
prefix was followed by prose instead of an identifier, so a scanner captured the word "the" as a control
name. It shipped in `v0.40.0-beta3`'s first tag and is fixed here.

Everything else was a **test corpus that had not caught up with the batch's own tightening.** This release
moved several governance checks from *"the artifact exists"* to *"the artifact was produced through the
governed path"* - a crossing cannot open into a stage whose artifacts are absent, `state.md` must mirror
the authority record rather than be written alongside it, and `review.md` must carry observed authorship.
Every fixture in the corpus fabricates its artifacts, because fabrication was sufficient when the checks
asked only whether a file existed. It is no longer sufficient.

So the honest summary of this census is: **the batch tightened the contracts and the test corpus had not
caught up.** That is a more useful finding than a regression list, and it is what the evidence supports.
The remaining items are environmental (a runner that could not bootstrap the product) and longstanding
(failures already present in the previous release).

One consequence worth stating: the validator's scoping was checked directly during this work and is
correct. It selects exactly the changed iteration and reports scoped mode. Seven distinct fallback
conditions positively confirm it does not silently narrow when the diff base is ambiguous. No test covers
narrowing on the ordinary path, so that confirmation should not be read as broader than it is.

The gate also caught a defect this work introduced, which is the clearest argument for having run it.
Editing the deployed machinery in this repository without re-stamping its install marker left the recorded
install state disagreeing with the deployed files, and the integrity check refused rather than reporting a
clean run it could not vouch for. The marker was regenerated through the product's own writer rather than
edited by hand, because hand-writing the artifact a check reads is the exact habit this release exists to
make harder. Nothing here reached users: the marker is per-project deployment state that every install
regenerates, it is not part of the package, and a project installing this build gets a marker describing
this build.

The comment-only changes in this release are proven, not asserted. Each affected script was parsed at the
previous tag and at this one, comments dropped, and the remaining token streams compared. **Three** are
executable-identical, and the proof covers those three only.

The fourth, the conformance provider, no longer belongs in that set. It began as a comment rewrite and now
also carries a behavioural fix, so it sits in two categories the way the workshop-lens script already does.
The fix is described under the workshop's first turn below, and it is the reason the candidate was rebuilt
and re-walked.

## A disclosed verification gap: FR-032

**FR-032 - a pending crossing is owed by the session that recorded it - ships in this release with no
passing automated test and no field proof.** It is disclosed here rather than inherited quietly.

The fix is real and answers an observed defect: a second, live session arriving at a boundary it did not
create was stop-blocked with nothing it could discharge, producing repeated interruptions until the cap.
Reverting the fix reinstates that. So it ships.

What does not exist behind it:

- **No passing automated test.** Its locking test had eight assertions that were red from the moment they
  were authored, in the same commit as the fix they were written to lock. That test is relocated to
  `tools/pending/` with the mechanism recorded.
- **No field proof.** The behaviour needs two concurrent sessions, and a single-session walk cannot stage
  that. All three walks behind this release were single-session. **This is a limit of the walk format, not
  an oversight** - no amount of walk discipline reaches a two-session scenario.

A replacement test is a beta4 item. Until it exists, FR-032's behaviour is supported by the reasoning in
its fix and by the defect it was written to remove, and by nothing else.

## Known issues

- **Review severity summaries understate what the review found — read the raw findings.** A round's
  summary and its stored counts can show `0 blocking` and `0 major` for a round whose reviewer graded
  findings at those levels: severities are demoted when a finding states no concrete failure scenario, and
  the demotion is written into the campaign record rather than only displayed. In this release's own
  campaign a **blocking** finding — a defect that wedged every second iteration — was stored as `minor`,
  and reading the summary alone would have shipped it. The raw findings preserve the reviewer's grade in
  `demoted_from`, so open the run's `result.json` under
  `.specrew/review/authority/campaigns/<campaign>/runs/<run>/` and read those rather than the summary
  before deciding a round is clean. Fixing the record is beta4 work; this workaround is what saved this
  release's own review and it is written here because you deserve it in writing rather than by discovery.
- **After a closeout verdict, the iteration seal reports 2 drifted mirror files.** The seal is written
  inside the closeout sync; the closeout verdict lands after that sync by definition; and the verdict then
  advances `plan.md` Status and `state.md` Current Phase / Iteration Status to their closed values. So the
  seal has already hashed those two files before the authorization that completes the closeout changes
  them. **The records are correct and only the seal's snapshot is stale.** Re-seal through the engine's own
  writer once the verdict has landed — `Write-SpecrewIterationSeal` — rather than editing either file to
  match the checksum, which would make a true record false to satisfy a hash. Reordering the seal is beta4
  work: the choice is between excluding the derived mirror lines from the manifest and re-stamping the seal
  at crossing write, and the seal writer is the side where an unreviewed change costs more than the noise
  it removes.
- **A stale review block still re-fires at every stop** once its message has been read and correctly
  declined. The message now explains itself and says when it is advisory; suppressing the repeat is a
  behaviour change held for a later release.
- **Cloud placeholder support is verified for reading and hashing**, not for every path. Symbolic links
  and junctions remain refused wherever Specrew verifies its own files or writes review records.
- **Reviewer filesystem confinement is still instructional.** Specrew freezes and verifies the target
  it reviews and contains reviewer processes, but beta3 does not claim an OS-enforced read boundary that
  prevents a reviewer from reading other same-user files. That remains `DEFER-197-I010-003`.
- **Historical lifecycle records are incomplete.** Feature 185 has no closeout and Feature 198 has no
  feature-level closeout. Beta3 does not manufacture retroactive authorization for either; its release
  claim is limited to the beta3 tree and evidence named here.

## Named for beta4

**Natural-language authority conflicts have no detector.** Two measured instances this batch - a
maintainer instruction pair that could not both be satisfied, and an agent's sequencing that spent four
typed approvals on one signoff - both spent human authority, and nothing in the system saw either. Every
authority control here reads a single instruction; a contradiction exists only between two. Filed beside
the instruction-corpus work as a question with evidence attached, not a specification: a false positive at
an authority boundary would be worse than no detector at all.

The broader **evidence-pipeline consolidation** named in the beta2 release claim still belongs to beta4.
The continuous-co-review path-identity seam no longer does: beta3 hard-loads the shared volume-aware
comparer throughout that engine, and structural guards reject OS-family case folding and hard-coded
case-insensitive path sets. The remaining beta4 work is outside that engine, plus reading the real
Windows reparse tag (the precise version of the discrimination beta3 approximates by attribute), which
requires P/Invoke on a safety-critical path.

Boundary packets also run a provider-free preflight before state mutation: remote-delivered projects
must have the current branch pushed at HEAD, ahead-count provenance is surfaced, dirty paths are
classified by writer, task/status summaries must agree, and the boundary's owed artifact must exist.
Local-only projects name the remote check as not applicable rather than inventing a forge obligation.

**Feature creation should not write a specification file at all.** This release fixes the symptom: a guard
that interrupted the workshop's first turn over a placeholder the product itself had just written. The
cause is that the placeholder exists. Nothing reads it before the workshop ends, every path that touches
it has to special-case it, and the walk that found this hit it on turn one. Removing it changes feature
creation, which is why it was not done under a release candidate.

**Every exemption owes a test that proves it fires.** The interruption fixed in this release had an
exemption written for exactly that case, and it had never once worked in the twenty-two days since it was
added. It compared the placeholder against the wrong file, so it declined every time it was asked. Nothing
noticed, because a rule that declines because the case does not apply and a rule that declines because it
is broken behave identically, and the tests around it only ever checked that the guard stops things. A
suite written entirely in the negative agrees with a dead exemption perfectly. The cheap fix is a rule: any
exemption needs one test proving it says yes, not only tests proving the guard says no.

**A guard should test its purpose, not a proxy for it.** The interruption above fired after the agent had
already explained the placeholder unprompted, so the thing the guard exists to guarantee had happened and
it stopped anyway. It checks whether a file changed rather than whether the human was told. That shape is
worth hunting for elsewhere, because a guard that fires after its own purpose is served costs the
interruption and buys nothing.

**The test corpus has to catch up with the provenance shift, and that is the largest item here.** This
release moved several checks from asking whether an artifact exists to asking whether it was produced
through the governed path. Every fixture in the corpus fabricates its artifacts, so any fixture that
hand-writes a governed artifact is now living on borrowed time. Two are already measured: one trips four
separate gates, another can no longer mint the crossing it depends on. The method is known rather than
speculative, because the release walk already uses it: drive the real lifecycle and let each boundary
produce its own artifacts.

**Nothing checks that the deployed machinery still matches its install stamp.** This release found that
disagreement the hard way, from inside a test that inherited it. The check that catches it runs only when
an iteration is validated, so a repository can carry the drift for days without noticing. Re-stamping
belongs in whatever syncs the deployed copy, or the release gate should assert the two agree. It is a
one-line assertion either way.

**"This change is comments only" should be measured, not reviewed.** The four such changes in this release
were proven by parsing each file before and after, dropping comments, and comparing the token streams. That
proof was written for this release and should become a standing check, because reading a diff and
concluding it is inert is exactly the judgement a machine makes better.

**Auto-scoping has no test for narrowing on the ordinary path.** Seven separate tests confirm it does not
silently narrow when the diff base is ambiguous, and they all pass. None covers the case where everything
resolves cleanly and it selects too few iterations anyway. The confirmation that exists is real and it is
narrower than it looks.

## What "continuous co-review" means in this release — read this before relying on it

**Specrew checks, at every stop, whether your last review still covers your files, and tells you when it
does not. It does not start a review by itself.** Starting one spends a review round, and a round needs
your approval — so you start it:

```
specrew review --live --approve-round
```

**This is more specific than "gate-triggered", and the difference matters.** The checkpoint is not
silent and it is not asleep. It EVALUATES, repeatedly, in an open implementation window, against a tree
carrying your code — and it reports that the last result no longer covers you, rather than beginning a
new review. Measured on a dogfood run: `last_authorized_boundary: before-implement`, 32 source files
under `src/`, and six consecutive journal entries all reading `latest-result-not-current`.

**Why it stops there.** A round that fires on its own is a provider spend nobody authorized, so this
release requires your approval for each one. The consequence is that a review is something you run, and
the product's job is to tell you clearly and promptly when you need to — which it does.

**What is deferred to beta4** is a design question, not a bug fix, and it is narrower than "automatic or
approved". A middle exists: fire automatically only when an approved round is already sitting unspent.
One approval still mints one round, nothing spends without your say-so, and the review runs when there is
something to review.

Underneath it is an older question this release does not settle: **what does approving a reviewer host
actually authorize?** Approving *who may review* and granting *this review may run* are different things,
and Specrew has not kept them apart. Until it does, treat the reviewer you approve and the rounds you
approve as separate decisions — because that is what they are.

## Choose a reviewer before your first review

Specrew does not pick a reviewer for you, and until you pick one there is nothing to run a review with.
Authorize one once, per project, without spending a review round:

```
specrew review --host <claude|codex|copilot|cursor-agent|antigravity> --authorization-ref workshop-<feature>
```

Prefer a different tool from the one that wrote the code — a second opinion is the point of the review.
The code-implementation workshop now presents the installed choices and performs this setup after the
human picks one. A completed code workshop cannot pass specify preflight with an unresolved `auto-select`
or without the matching command-written authorization.

**This is a setup step, not a fault.** In a dogfood run a project with no reviewer configured reported
`preflight-failed:harness`, which reads like broken tooling; the agent concluded the co-review was
unavailable and wrote the review record itself, marking 24 tasks passed when no reviewer had ever run.
That message now says what is actually missing. **Co-review works on Copilot CLI** — the failure there
was a reviewer nobody had chosen, not a host limitation.

## What the complete lifecycle walk does at review

The walkthrough is deliberately not unattended. When implementation reaches review, Specrew stops and
waits for a human to authorize one provider-spend round:

```
specrew review --live --approve-round
```

Reviewer setup already happened in the workshop. One `--approve-round` authorizes one round.
The expected stop is the product working: no reviewer process starts, and no spend occurs, until the
tester grants that round. A complete, valid result for the exact active campaign and current file digest
is required before `review-signoff` can advance; a hand-written `review.md` is not review evidence.

For an exceptional case where the human deliberately accepts partial review coverage, the blocked
boundary first records a request bound to the exact campaign and tree. Only a typed prompt response in
the following exact form can satisfy it; the resulting allow decision (including the human response and
rationale) is written to `.specrew/review/signoff-gate/`:

```
approved for partial review signoff - <why accepting partial coverage for this exact tree is safe>
```

This is an explicit human disposition, not a recovery command for an agent to infer or issue itself.
