# Specrew v0.40.0-beta3 Release Notes (DRAFT)

`v0.40.0-beta3` is a narrow stabilization prerelease for the `0.40.0` line. It has one goal, which is
also its acceptance bar: **a consumer completes their first feature without hitting an endless review
loop, a wedged gate, or a sentence they cannot understand.** It is a prerelease, not a stable promotion.

This draft is written at implementation time and is not a release claim. The certification round and its
transcribed measurements land at feature closeout.

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
