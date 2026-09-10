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

## Known issue: resuming a session can rewrite a closed iteration's state and ask for a verdict you already gave

**What happens.** After an iteration is closed out and sealed, a session that RESUMES in the project can
rewrite that iteration's `state.md` and `tasks-progress.yml` - the resume path derives a task-progress
summary and writes it, setting the iteration status to a value that is neither canonical nor right for the
stage (`ready-for-review` on an iteration at retro). Two things follow: the validator correctly flags the
closed iteration as edited, and - worse - **the resumed session orients from its own rewrite and asks you
for the iteration-closeout verdict a second time**, although the ledger already holds it. Confirmed end to
end on a consumer project on Copilot CLI; the same writer is behind the validator red first seen on the
self-host repo.

**What to do.** Do not type the verdict again. Restore the two files to their sealed content and continue:

```text
git checkout -- specs/<feature>/iterations/<NNN>/state.md specs/<feature>/iterations/<NNN>/tasks-progress.yml
```

Your earlier verdict stands; nothing in the ledger moved. If the session's opening packet asks for a
verdict at a boundary you know you crossed, check the ledger before answering - the packet is describing
the rewrite, not the project.

**Status.** Known in this release; the writer is the first item for beta4.1.

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

## Known issue: clarify refuses on a brand-new feature

**On a feature that has not reached the plan boundary yet, the clarify sync refuses:**

> Specrew cannot record this boundary because it does not know which iteration it belongs to.

**Workaround — pass the iteration explicitly:**

```
… sync-boundary-state.ps1 -BoundaryType clarify -IterationNumber 001 …
```

**Why**: clarify runs *before* the plan boundary creates `iterations/001/`, but the sync still expects an
iteration for it. The refusal even says so itself — it tells you to create the iteration first, which only a
*later* boundary does. Passing `-IterationNumber 001` satisfies it and nothing is lost.

**You may also see a literal `{0}` in that message** where a folder path should be. That is a formatting
defect in the message only; the refusal itself is behaving as described above.

Both are fixed in beta5.

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
