# Beta4 scope: the first-run experience release

**Recorded 2026-09-09, from the maintainer's ruling. Written down because a scoping decision that lives only
in conversation evaporates when the session does — and this one was agreed across several relays.**

## The theme, and why it is a theme rather than a backlog cut

**Beta4 is about what a stranger meets in their first ten minutes.**

People will try Specrew after the conference talk, and that is the surface they land on. A theme makes the
exclusions defensible instead of arbitrary: an item is in scope because a new user hits it, and out of scope
because they do not — rather than because someone ranked a list.

The backlog from the beta3 fortnight is unusually well evidenced and far too large for one release. Cutting
it by theme is what makes the cut arguable rather than a matter of taste.

## Timing

**Beta4 does NOT ship before the conference.** Building a release two days out, on the machine the maintainer
presents from, that nobody has walked, is how the beta3 respin started. The audience arrives over weeks
rather than hours, so a beta4 published a few days after the talk reaches nearly all of them **and can carry
a proper census, a walk and a tag**.

Beta3 is what gets presented. It is published, field-proved, and installed on the demo machine.

## In scope

All small, all evidenced by this fortnight's walks.

| item | evidence |
| --- | --- |
| **The workshop question is not registered**, so a lens cannot close AND a full packet fires every turn | DRIFT-199-I003-094, mechanism corrected and measured in B4F-005/B4F-007. One defect, two symptoms. **Top of the list, and see the reframing below — this is not a first-run item.** |

### The reframing: it is not first-run, and that makes it worse

**The item above was scoped as first-run. It is not, and the correct statement is more alarming than the
one it replaces.** Measured in B4F-007: a stranger's **first** feature works. The block lands on their
**second**.

The start context names the lifecycle's feature, which after any completed feature is the previous one —
stale by construction from feature creation until the first boundary sync. A first feature has no
predecessor to name, so it resolves correctly. Every feature after it does not.

**Failing early is cheaper for a user than failing after they have committed.** Someone who hits a wall in
their first ten minutes has lost ten minutes and can walk away. This defect gives them a good first
experience instead: the workshop works, the lenses close, the boundaries hold, and they conclude the tool is
sound. **So they commit to it — they bring it into a real repository they care about, and they invest.**
Then they open their second feature and hit a block they cannot recover from, with no message that explains
it, on a tool they have already staked work on. That is the expensive shape, and it is the one we shipped.

The theme still holds — this is what a stranger meets — but the item is not "polish the first ten minutes".
It is **the product stops working at the point the user starts trusting it.**
| **`iteration-closeout` advances without demanding a verdict** | DRIFT-199-I003-097, narrowed by -099. Its two neighbouring boundaries both stop; it alone does not. Severe, and now one boundary rather than a shared path. |
| **Near-miss reporting** when an approval phrase is present but not matching | DRIFT-199-I003-095. Measured live: the product's author, holding the spec, typing the phrase he had just been shown, got it wrong and was told nothing. |
| **Verdict whitespace and line-ending normalisation** before matching | Same surface as the near-miss — the moment a human types the thing that grants authority. |
| **Instruction ordering**: render the orientation before any research | DRIFT-199-I003-080. Cost measured: a duplicated boundary packet plus an eight-minute stop. The methodological half is stronger — research before the first question is research on assumptions nobody confirmed. |
| **The branchless-project decision** | DRIFT-199-I003-067. A new user's first governed feature currently lands on `master` with no branch. |

### Split rather than deferred

**Instrument time-to-first-question and first-reply length in beta4; leave the verbosity redesign for
beta5.** Measurement is a day, the redesign is not, and nobody can argue about proportion without a number.
The maintainer typed *"I don't understand what I should answer now"* at a first workshop question
(DRIFT-199-I003-082) — the strongest evidence in the backlog, and it deserves a metric before it gets a fix.

## Deferred to beta5 or later, with reasons

**The reasons matter more than the list.** Each of these is well evidenced; none of them is what a stranger
meets.

| item | why it defers |
| --- | --- |
| **The seven harness-enforcement rules** | They improve **how this crew builds Specrew**, not how a stranger experiences it. A release aimed at first-run should not spend itself on internal quality machinery, however well evidenced. |
| **The compiled-engine architecture question** | DRIFT-199-I003-065. A question with seven measured instances behind it, not a change. Answering it is a redesign. |
| **Proposal 166's file-surface classification registry** | Waiting to be promoted rather than rewritten. Internal. |
| **The verdict-record-in-git design question** | Internal record-keeping, invisible to a first run. |
| **Scope-determining fields cannot validate themselves** | DRIFT-199-I003-090. Machinery quality. Four instances, one already paid for and its class never named. |
| **An approval bound to a tree state freezes recording** | DRIFT-199-I003-096. Machinery quality; found by doing the right thing and noticing it hurt. |
| **The clarify fix and four docs that never shipped** | DRIFT-199-I003-091. Content is first-run adjacent, so it rides along with beta4 rather than forcing a beta3 re-cut. |

## The countermeasure that outranks the theme

**A verification path must run against a project created minutes ago by the shipped `init`, not against this
repository.** DRIFT-199-I003-068, sharpened by -076: the drift is **bidirectional**. Three findings had this
tree carrying what users lack; one had the shipped behaviour correct while this tree was stale. **Nothing
reconciles the two in either direction.**

The candidate walk script already has the right shape — fresh directory, shipped installer, real first
session. It needs to be a lane that runs rather than a checklist someone remembers. **It would have caught
the branchless defect in July.**

## The work kind, and what declaring it settled without anyone's judgment

**Beta4 is declared `bug-bash`** (`.specrew/work-kind.yml`, 2026-09-09). The capability had shipped and was
simply never selected: `work_kind` is a **project-level** declaration, its previous value's own note still
opened *"Feature 183 (this branch)"*, and features 199 and 201 inherited it unchanged because nothing at
feature creation asks. See `docs/beta4-findings.md` B4F-006.

**Its flow is `bug-list -> root-cause -> fix -> regression-tests -> REVIEW -> closeout -> merge`.** That
matters beyond the ceremony it removes: **review is a required stage of the contract now in force, not a
discretionary round somebody chooses to spend.** Three releases have closed with the reviewer column empty.
This one will not — and not because anyone decided to be more careful this time. **Declaring the work kind
answered the review question structurally.** That is the difference between a practice and a control, which
is a distinction this project has now paid for repeatedly.

**Beta5 must revisit the declaration.** It is project-level, so it stays `bug-bash` until changed, and beta5
needs `software-feature` again if it carries features rather than defects.

## Standing practice for beta4's own work

**State predictions before running anything whose outcome could be rationalised afterwards, and commit them
first.** This is why DRIFT-199-I003-097 narrowed from "systematic across the delivery path" to "one
boundary" instead of staying vague. It cost one commit. Applies immediately to the question-registration
test at beta4's first technical lens.
