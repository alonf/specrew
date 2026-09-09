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

## Known issue: `/specrew-user-profile` is advertised but not installed

**Specrew tells you about a command it does not give you.** `init`'s completion message, the session
banner, and the launch contract all point at `/specrew-user-profile` — and **the skill is not shipped**, so
in your project the command does not exist.

**What to do instead — the settings are real and editable, just not through that command.** Your profile is
**per-user, not per-project**, and lives at:

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

**Fixed in beta5** by shipping the skill.

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

## Verification

- Regression test: `tests/integration/workshop-resolve-prefers-open-feature.tests.ps1`, in the
  `f199-class-guards` lane. It drives the resolve rather than fabricating the artifact whose production was
  broken, and carries its own positive control.
- Mutation-proved at both guarded sites with disjoint failure sets, target green before each mutation.
- Field-proved on the development tree, on the exact stale-reference state that reproduced the defect.
