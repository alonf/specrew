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

## The review loop stops on its own

- **Every review round now ends in a pause, never another round.** The loop that ran fifteen fix rounds
  on one target cannot happen: continuation is a numbered choice the human makes, each answer authorizes
  exactly one round, and an agent cannot manufacture continuation from a previous approval.
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

- **Seventeen test failures accompany this branch, and every one is dispositioned.** Sixteen also fail
  on `main`, name for name: they are pre-existing and inherited, not introduced here. The seventeenth is
  an analyzer that reads machine-local runtime state; it passes on a fresh checkout only because that
  checkout has no such state to read, which is not evidence that it is fixed. All seventeen route to
  beta4.
- **A stale review block still re-fires at every stop** once its message has been read and correctly
  declined. The message now explains itself and says when it is advisory; suppressing the repeat is a
  behaviour change held for a later release.
- **Cloud placeholder support is verified for reading and hashing**, not for every path. Symbolic links
  and junctions remain refused wherever Specrew verifies its own files or writes review records.

## Named for beta4

The **evidence-pipeline and path-identity consolidations named in the beta2 release claim ship in
beta4**, not here. Beta3 deliberately did not take them: path identity is routed through a single shared
primitive but that primitive is still the *recommended* path rather than the *only reachable* one, and
making it unbypassable is the consolidation beta4 owns. Reading the real Windows reparse tag — which is
the precise version of the discrimination beta3 approximates by attribute — belongs there too, since it
requires P/Invoke on a safety-critical path.

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
Approve one once, per project:

```
specrew review --live --host <claude|codex|copilot|cursor-agent|antigravity> --approve-round
```

Prefer a different tool from the one that wrote the code — a second opinion is the point of the review.

**This is a setup step, not a fault.** In a dogfood run a project with no reviewer configured reported
`preflight-failed:harness`, which reads like broken tooling; the agent concluded the co-review was
unavailable and wrote the review record itself, marking 24 tasks passed when no reviewer had ever run.
That message now says what is actually missing. **Co-review works on Copilot CLI** — the failure there
was a reviewer nobody had chosen, not a host limitation.
