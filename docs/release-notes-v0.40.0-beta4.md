# Release notes - v0.40.0-beta4 (in preparation)

**Theme**: the first-run experience. Beta4 is a `bug-bash` release - a defect sweep whose bug list and root
causes were written before the work started. See `docs/beta4-scope.md`.

## What this release fixes

**A workshop could not register its question, so no lens could close.** The workshop resolve selected the
feature named by `.specrew/start-context.json`, which carries the *lifecycle's* feature - after any completed
feature, that is the **previous** one, and it is stale from feature creation until the first boundary sync.
The resolve then looked up a completed workshop and found nothing active, silently.

**Who this affected, and it is not who it looks like.** A project's **first** feature worked, because there
was no predecessor to name. **Every second and later feature was blocked.** So the failure did not meet a
stranger in their first ten minutes - it met them once they had already decided the tool was sound and
brought it into a repository they cared about. Failing early is cheaper for a user than failing after they
have committed.

The resolve now selects the feature whose intake controller is actually open, and refuses with
`workshop-resolve-ambiguous` when two workshops are open on different features rather than guessing which
one a human is answering.

## Fixed: a session resume could rewrite a closed iteration's records and ask for a verdict you already gave

**What happened.** After an iteration was closed out and sealed, a session that RESUMED in the project
could rewrite that iteration's `state.md` and `tasks-progress.yml` - the resume path derives a task-progress
summary and wrote it, setting the iteration status to a value that is neither canonical nor right for the
stage (`ready-for-review` on an iteration at retro). The validator then flagged the closed iteration as
edited, and - worse - **the resumed session oriented from its own rewrite and asked you for the
iteration-closeout verdict a second time**, although the ledger already held it. Confirmed end to end on
a consumer project on Copilot CLI. Three of Specrew's own writers could move a sealed iteration: the
closeout verdict's advance, a closeout re-render, and the resume's task-progress sync.

**The root.** The seal was written when the closeout boundary was *reached* - the crew asking for the
verdict - which froze `Iteration Status: retro` into the iteration. Your verdict then established
`complete`, the capture wrote it, and the arrival-time seal flagged the verdict's own write as tampering.
Measured on a consumer project: the capture's advance and a later session's resume both wrote into the
sealed iteration, and the validator flagged the verdict's own value as an edit.

**What changed.** The seal is written at *authorization* - as the closeout verdict capture's last act,
after its own advance - and never at arrival; what it pins is exactly what your verdict accepted. The
resume's task-progress writers skip a sealed iteration and journal the skip
(`.specrew/runtime/handover-journal.jsonl`, `sealed-iteration-write-skipped`), so a resume orients from the
records the verdict accepted, never from a status it derived itself.

**If you closed an iteration on beta3, it is already drifted** - every consumer that closed an iteration
before this rule carries a seal older than its records, and the validator refuses it. The refusal now
names the remedy:

```text
specrew reseal --feature <feature> --iteration <NNN>
```

It prints what drifted since the seal (the precondition), re-seals over what is on disk, and proves
nothing is touched afterwards (the postcondition). Read the journal first if you want to know which
writer moved the records; use `git checkout -- <file>` instead when a session's stray edit is what moved
them. Field-proved on a consumer project: `drifted=state.md,retro.md added=dashboard.md` before,
`touched=0` after, and the validator's trust gate passes.

**Who sealed what** is in the seal itself (`source`): `iteration-closeout-authorization` for the verdict's
own seal, `specrew-reseal` for yours, and `iteration-closeout` for a seal written by beta3 at arrival.

## Known issue: lens confirmations bind the next typed reply regardless of its content

**Read this before running a workshop on beta4.**

When a workshop lens is open, Specrew records a *receipt* for the human's typed turn and stores it as the
lens's confirmation. **The receipt proves that a typed turn occurred while a question was projected. It does
not prove that the reply answered the question.** A receipt marked `human-confirmed` is evidence of a turn,
not of assent, and nothing in the record distinguishes the two: a receipt minted from a clarifying question,
an aside, or an unrelated instruction validates **identically** to one minted from a real answer.

**Measured during beta4's own development**: five `human-confirmed` / `lens-question` receipts were minted
for a `product-domain` lens whose question had never been asked. Every one came from a code-review message.

**What this means in practice.** When a lens is presented for closing, **the next typed message is the one
that gets bound** - whatever it says. There is no reply shape that avoids it: the receipt is written for any
non-whitespace message, without inspecting its content.

- **To confirm a lens**: make `move on` the immediate next message, and hold side conversation until after
  the lens is closed.
- **To disagree with a lens - and this is the case to watch.** Typing the correction into the lens-closing
  turn mints a receipt exactly as an agreement would. **Do not answer a disagreement into the open lens.**
  Raise it while the lens is still being discussed, or stop the closing exchange and say plainly that the
  reply is a redirect and the lens stays open, then confirm it once it has been re-presented.

The natural action - typing your objection where the question was asked - is the one that binds, which is
why it is called out rather than left to be discovered.

**Why this appears in beta4 and not beta3.** Beta3 could not mint these receipts at all - the registration
defect above meant no question was ever projected, so nothing could bind. **Beta4 makes the path reachable.**
A working workshop with over-eager confirmation is strictly better than a workshop that cannot advance, but
users should know which one they have, and this is the honest statement of it.

**Status**: known limitation, disclosed rather than fixed. The integrity rule it depends on is already
stated in the design-workshop conduct - a lens may be recorded `human-confirmed` only for questions actually
surfaced and actually confirmed - and that remains the agent's obligation. Tightening the machinery so the
record can distinguish a turn from an assent is deferred to beta5 with the refusal-standard items.

## Known issue: a scaffolded feature you never started keeps announcing its workshop

**If you create a feature and then leave it alone, it will assert an open workshop on every turn** — in
every session in that project — until you either author its specification or actually run its workshop.

You will see a short note about workshop work in progress on turns that had nothing to do with it, and the
feature's lens will accept your typed replies as though they answered a question it never asked.

**Either action clears it:**

- **run the workshop** for that feature, or
- **author its specification** — which is what a feature past intake has anyway.

**Why**: Specrew decides a workshop is open by looking for a feature whose specification is still the
untouched scaffold stub. A feature created and abandoned looks identical, on disk, to one whose first
question was just asked — the only difference is whether a question was actually posed, and nothing durable
records that today. Beta5's fix is for the workshop to record the question as it asks it, so the two stop
being indistinguishable.

**This does not affect a workshop you are actually running.** It only affects features left at intake.

## Fixed: `/specrew-user-profile` is now installed by `init` and `update`

**Beta3 told you about a command it did not give you.** `init`'s completion message, the session banner
and the launch contract all pointed at `/specrew-user-profile`, and the skill shipped to no project — 0 of
37 skills in three consumer projects. Its backing script had always shipped; only the entry point was
missing. **Beta4 ships the skill** through the same deployment `init` and `update` already run, so
`/specrew-user-profile show | edit | reset` works in your project after `specrew update`.

The settings themselves are unchanged. Your profile is **per-user, not per-project**, and lives at:

```
~/.specrew/user-profile.yml
```

Edit it directly. The four expertise dials are under `expertise:`, each `1`–`10` or `null` (null keeps
Specrew's automatic choice):

```yaml
expertise:
  software_architecture: 10
  ui_ux: 6
  product_management: 7
  ai_research_project_management: 6
```

They control how much Specrew asks, explains, recommends and decides for you, and they apply across every
Specrew project you work in. Changing the file is enough — nothing needs to be re-run.

Editing the file directly still works and needs no re-run.

## Fixed: clarify refused on a brand-new feature

**What happened.** On a feature that had not reached the plan boundary yet, the clarify sync refused:

> Specrew cannot record this boundary because it does not know which iteration it belongs to.

Clarify runs *before* the plan boundary creates `iterations/001/`, but the sync still expected an iteration
for it - and the refusal told you to create the iteration first, which only a later boundary does. The
message could also print a literal `{0}` where a folder path belonged.

**What changed.** The clarify sync records its crossing on a feature with no iterations directory and no
`-IterationNumber` (fix 3, PRED-BETA4-012); the `plan` refusal names the actual iterations directory and
carries no `{0}`. The workaround of passing `-IterationNumber 001` is no longer needed. (Earlier drafts of
these notes filed both as beta5; the independent review of `ebb7597f` caught the label - they shipped in
beta4 at `sync-boundary-state.ps1`.)

## Fixed: two things the first walk on the release candidate met at every boundary

**A verdict cost two turns.** After you typed `approved for specify`, the coordinator asked what you wanted
next; after `approved for clarify`, whether to start planning. Nothing at the moment of capture told it that
the approval was the instruction. Now the capture itself says so, in the turn: *"Verdict captured: approved for
specify. The clarify stage begins in this turn: /speckit.clarify, then /speckit.specrew-speckit.sync-clarify. Do
not ask the human to start it; the approval was the instruction."* - one line per boundary, naming the stage
and the command that begins it in your host's form. The two closeout crossings name both exits and never ask.
The refocus digest carries the same sentence.

**The lint gate halted to ask for a commit of its own fix.** At the specify preflight the pre-boundary lint gate
repaired blank lines around headings and lists in the workshop records - then stopped the sync with a four-step
git sequence until you committed them. It now says what it repaired and proceeds; the boundary commit carries
the files. Unfixable violations still halt, naming the file and line - and, found on the way, that halt had
never fired: the gate's parser did not recognise markdownlint's output. It does now.

## Fixed: the crew charter fix's two missing halves, and what was under them

The audit's recheck of the installed candidate found two things the charter fix above had left undone:

**A change to a canonical charter never reached the crew.** Edit `.specrew/team/agents/<role>.md` and start:
the runtime charter (`.squad/agents/<role>/charter.md`) was kept as it was, silently. Now a charter Specrew
wrote is compared with its canonical on every start and rewritten when the canonical changed - its directives
block kept, its ownership marker re-stamped - and left alone when it is current. Under this sat an older
defect: on a fresh Copilot project the runtime charters were the squad CLI's own bodies with Specrew's
directives appended, never the canonical charters at all. Init now writes the canonical base. **On the first
start of this build, a project initialized on an earlier candidate has its untouched charters rewritten to
the canonical composition, once** - "Crew runtime synced: 5 agent file(s) written" - and is silent after
that. A charter you edited is not rewritten. **Scope, as measured: the Copilot host only.** On a fresh
project bootstrapped for Claude (`specrew init --agents claude`, one `specrew start --host claude`), each
`.claude/agents/<role>.md` carries the canonical `.specrew/team/agents/<role>.md` byte for byte after its
frontmatter, all five roles, and is rewritten from canonical on every start; the Claude crew never ran on a
generic body. The other hosts translate the same way; only the Copilot path composed on `squad init`'s file.

**The preservation notice recommended a recovery that brought the notice back.** "Delete the sidecar to keep
it without this notice" left the file unmarked, and the next start reported it again, recommending the
deletion of a file that was gone. The notice now says the charter stays as you wrote it and names two
remedies that each end it: `specrew team own <role>` keeps the charter as yours, persistently (a marker in
its owned form; nothing is deleted); `specrew team resync <role>` returns it to the canonical charter, block
kept. Both take `--project-path`, which - found on the way - had never bound for any `specrew team` verb.

## Fixed: three things a stage-demo audit of the installed beta found

An audit of the installed candidate, run as a stage-demo readiness review, is authoritative for this
release's acceptance. It found, and this build fixes:

**The mechanical checks threw on a project with nothing to scan.** Documentation-only work, or a stack with no
discoverable source, hit `Cannot bind argument to parameter 'SourceFiles' because it is an empty array`. Now
each gate says whether it applied: `not-applicable`, naming the roots and file extensions searched, when the
plan does not require it; `failed`, naming the plan's requirement, when the plan requires a gate and there is
nothing to check - so a missing implementation is never a passed scan. A project path that does not exist is
still an error.

**Five "Preserving user-edited file" warnings on a project you never edited.** Init wrote the crew charters
without the ownership marker the start command looks for. The marker now records what Specrew wrote, init
writes it, and start is silent for untouched charters; a charter you actually edited is preserved and the
notice says so - "edited since Specrew wrote it" - once.

**Feature closeout could die on a git warning.** A `warning:` line on git's stderr at the closeout gate (a
path too long for `core.longpaths=false`, for one) was read as a status line and the sync stopped with "The
property 'Length' cannot be found". Warnings are skipped; a dirty tree is still gated.

The audit's remaining findings are beta5's, as it states them - review completion invalidating its own
evidence, severity that depends on a heading, workshop correction mistaken for assent, and the rest listed in
the findings record - except the review ordering repair, which is beta4.1 unless the demo path enters live
sign-off.

## Fixed: two defects in beta4's own additions, found by an independent review of the beta

An out-of-engine review of `v0.40.0-beta3..ebb7597f` (GPT-6 Astra, the maintainer's) reproduced two defects
behind green suites. Both are fixed here; the reviewer's reproductions are the regression tests.

**The reviewed-state digest cache could conceal an unreviewed change.** Beta4 cached the reviewed-tree
identity to keep the Stop hook inside its budget; the cache was keyed on metadata (HEAD, the status listing,
file sizes and times) and the sign-off gate read it. A staged file's executable bit changed under
`core.filemode=false`, or a same-length edit with its timestamp put back, left the key unchanged and the tree
changed. Now every authority check - sign-off, the campaign orchestrator, evidence recording, the verification
runner, the review CLI - computes the identity directly (2-3 s after the pruned walk, which was most of the
saving); only the advisory Stop-hook path may read the cache, and the index mode is part of its key. A
metadata key is not tree equality, and an authority check never trusts a cache.

**Readiness borrowed the previous iteration's closeout.** The new readiness line compared lifecycle
positions, and `iteration-closeout` sorts after `before-implement` - so after closing iteration 001 and
opening 002's plan, readiness said READY for 002. It now derives from the authorizations of the current
iteration's cycle: the previous iteration's closeout is the previous iteration's, and a new cycle with no
authorization is BLOCKED, saying so.

## Fixed: an approval typed before its crossing existed vanished without a word

**What happened.** You typed `approved for before-implement` a moment before the crew had recorded the
crossing that verdict was for. Nothing was pending, so nothing was recorded - and nothing said so. The hook's
own later text then told you the approval was still owed, and you typed it again. Three times in one day on
one project.

**What changed.** A verdict typed while no crossing is pending gets one line back: that nothing is pending,
what the last authorized boundary is, and to send the phrase again when the crossing is presented. A verdict
naming a different boundary than the pending crossing gets the pending crossing and the phrase that
authorizes it. Ordinary conversation still gets nothing. And the always-on rule the crew reads now says it
plainly: a verdict typed while no crossing is pending authorizes nothing, and an agent may not treat it as
pending authority - there is no "authority-in-flight".

## Fixed: a readiness sub-agent's BLOCKED was summarized as PASS

**What happened.** The before-implement readiness agent read the ledger and reported "Overall verdict:
BLOCKED for implementation - no tasks -> before-implement authorization exists", with every artifact check
passing beneath it. The crew's packet reported the readiness check as PASS, dropped the verdict, and
announced the first implementation task. The only thing between BLOCKED and product source was a human
reading the packet.

**What changed.** The overall verdict is now a line a script prints from the boundary ledger
(`readiness-verdict.ps1`), the readiness command puts it first in its report verbatim, and the coordinator
quotes it verbatim as the first line of the packet. Passing artifact checks are never the overall verdict.

**What stays for beta5, first item.** The Stop hook will refuse a turn that writes product source while the
ledger's last authorized boundary precedes before-implement - a control that reads the ledger, which no
summary can rewrite. Until then that boundary is guarded by the agent's discipline and your read.

## Fixed: the review advisory was said to every session in the project, including one that wrote nothing

**What happened.** With two sessions open on one project - one working, one reading - every Stop of the
reading session was interrupted with "Specrew review - these files have not been reviewed yet", asking it to
approve a review round for files it had never touched. Measured at seventeen consecutive interruptions of a
reviewer session, each after it had declared its turn conversational. The co-review navigator knew the tree
was unreviewed and nothing about who was stopping.

**What changed.** The hook that judges your turn's declaration now leaves that judgment where the review
navigator can read it, and the navigator says the advisory only to a session that wrote something this turn:
declared in-flight or boundary, or declared nothing and was seen changing files. A session that declared
conversational, or did nothing, hears nothing. A review round that is waiting for your decision still stops
every session - that is your decision owed, not a file attribution.

## Fixed: the second iteration's plan sync asked for the third iteration's plan

**What happened.** After you closed iteration 001 and the crew ran the plan sync for iteration 002, the sync
recorded 002 and, in the same run, refused to open the plan crossing because "plan owes plan.md for
iteration 003". Your `approved for plan` then had nothing to bind to. Two parts of one invocation derived
the target iteration differently: the record used the number you gave it; the owed-artifact check added one,
a rule that is right at closeout authorization (where the cursor still names the closed iteration) and wrong
at the plan sync (where it already names the new one). Measured on a consumer project at its second
iteration; reproduced in the product's own order, so it was universal, not something the consumer did.

**What changed.** The target iteration is derived once, from the crossing's working boundary, and the value
the sync records is the value the check reads. Both shapes - scaffold then sync, and scaffold before the
closeout verdict - open the crossing for 002. A related fix: the iteration scaffolder could not open a second
iteration for a feature whose spec has exactly one requirement; it can now.

## Fixed: a pasted transcript with an approval phrase at its top was recorded as the approval

**What happened.** A verdict is typed as one line - `approved for review round`, or `approved for plan -
<your instructions>`. Every recognizer decided on that first line, so a message whose first line was the
phrase and whose next 135 lines were a shell transcript pasted from another project was minted as a live
review-round approval, twice (once per capture channel), with the whole transcript as its verdict text.
Nothing read past line one. Measured in the Specrew repository itself, from a reviewer session.

**What changed.** A verdict is one line: the phrase, plus at most the same-line instruction after a dash.
A message that continues past that line into content is refused - not minted - and the refusal is
disclosed in the turn with the retype: `'approved for review round' or 'approved for review round - <your
instructions>'`. It is also journaled (`.specrew/runtime/authority-capture-drops.jsonl`, `reason:
multi-line`). This applies to round approvals, pause decisions, allowance resets, coverage deferrals and
boundary verdicts. A typed **withdrawal** is deliberately not under the rule - it removes authority, and
refusing it would leave an approval you retracted still spendable.

**What this changes for you.** Beta3 accepted an approval followed by a blank line and a block of
instructions; beta4 refuses that shape and tells you so. Put the instruction on the phrase's line, after a
dash. Trailing blank lines are fine.

**What stays for beta5.** The two copies of the pasted message were captured through two channels with
different encodings (an apostrophe reached one channel as a code-page triple), so the cross-channel
dedupe could not see they were one message; that is a prompt-entry transcoding defect, recorded.

## Changed: the turn-end declaration, and the token that places it

**The hook no longer scores your agent's prose.** What decided whether a turn had ended properly used to be
a reading of the last message - header phrases, a transcript scan, an HTML comment the agent had to remember.
Each punished compliant output at least once. Now the agent runs one script as its last action,
`declare-turn-end.ps1 -Kind <boundary|in-flight|conversational>`, the script renders what is owed from the
artifacts, and the hook checks one fact: did the script run, for this session, for this turn.

**"For this session" is a token the hook hands the agent.** At the start of every turn the hook injects one
line, `[specrew-turn] ... -Token <value>`, into the agent's context - not into what you see. The agent passes
it back. With two sessions open in one project a declaration without it is refused by name; with it, each
session's declaration lands under its own. A token left behind by a session that crashed shows up in that
refusal with its file path, so it can be removed. Nothing infers whose turn it is from shared state any more;
two designs that did were each broken by the independent review in one probe.

**What it costs.** The conformance hook now runs at every prompt, not only at session start - a second
provider launch beside the existing one, measured at roughly 0.8-1.1 s per prompt on Windows, most of it
PowerShell startup and a git snapshot. That is the price of the token and of the per-turn baseline that, it
turned out, had never been captured at prompt in production before this release. Making it lighter is a
beta5 item.

## Field evidence: a consumer project adopted the beta4 rule on its own numbers

The first consumer feature run end to end on this release (an agentic-architecture skill router, one
iteration) estimated **22 story points and delivered 29 - +32%** - and its retro traced every point of
the variance to **three validation tasks, each added by a review round that found a check passing without
exercising its subject**. The retro then promoted *"proven without exercising its subject"* to a standing
reviewer focus for that project.

That is this release's own finding (B4F-018: a control that cannot fail where the product does) adopted as
a rule by a consumer, from the consumer's evidence, before the maintainers wrote it into the product. The
five governed-script surprises the same retro filed were all already in beta4's record; one of them - the
reviewer-artifact scaffold failing on an empty changed file - is fixed in this release, and the other four
are beta5 items with their numbers.

## Verification

- Regression test: `tests/integration/workshop-resolve-prefers-open-feature.tests.ps1`, in the
  `f199-class-guards` lane. It drives the resolve rather than fabricating the artifact whose production was
  broken, and carries its own positive control.
- Mutation-proved at both guarded sites with disjoint failure sets, target green before each mutation.
- Field-proved on the development tree, on the exact stale-reference state that reproduced the defect.

## How this release was reviewed, and what that says about the tool

**Beta4's own repair was reviewed by an external model, out of engine — not by a governed Specrew review
campaign.** That is worth stating plainly in a release about governance, because the reason is a defect this
release is disclosing rather than an operational shortcut.

**Specrew could not review this work with its own machinery.** The review evidence gate is a no-op at every
lifecycle boundary except `review-signoff`, so nothing asked for a review while the work was being done. At
`review-signoff` the gate asks for a completed review campaign — and the campaign cannot be created for a
feature that has no `iterations/` directory, which is exactly what this release's work kind produces. The
gate is therefore silent while the code is written and unsatisfiable once it is finished.

**So the independent read came from outside**: a separate model, given the full diff and pointed at the
places the authoring session could not see about its own work. It found two real defects in the new
turn-end machinery — a guard that could be trivially bypassed, and a failure mode that disabled enforcement
silently — both fixed before release. It did **not** finish: it stopped on a usage limit before reaching
the retirements and the converted tests, and that is stated here rather than rounded up to "reviewed".

**What this means for you**: the fixes in this release carry an external review that is real but partial,
and no governed campaign result. **Fixing the gate placement and the work-kind scoping is beta5's first
review-machinery item**, because the two are entangled: review is a required stage of the `bug-bash`
contract and the engine currently has no path to it for a feature without iterations.
