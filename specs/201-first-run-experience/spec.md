# Feature Specification: 201-first-run-experience

**Status**: authored, with a recorded deviation
**Work kind (project)**: `software-feature` · **This feature's conduct**: `bug-bash`

## What this feature is

Beta4's defect sweep. It fixes one shipped defect and records the rest.

**The shipped fix**: the workshop resolve selected the feature named by `.specrew/start-context.json`,
which carries the *lifecycle's* feature — after any completed feature, the previous one, stale by
construction from feature creation until the first boundary sync. The resolve looked up a completed
workshop, found nothing active, and returned silently. A project's **first** feature worked, because there
was no predecessor to name; **every second and later feature was blocked**, so no workshop question could
register, no receipt could mint, and no lens could close.

The resolve now selects the feature whose intake controller is actually open, and refuses with
`workshop-resolve-ambiguous` when two workshops are open on different features rather than binding a human's
typed reply to a question they never saw.

## Where the requirements live, and why they are not restated here

**The bug list and scope**: file:///C:/Dev/specrew-beta3-stabilization/docs/beta4-scope.md — the theme, the
six in-scope items with their evidence, what defers to beta5 and why.

**The root causes, evidence, and every finding**: file:///C:/Dev/specrew-beta3-stabilization/docs/beta4-findings.md
— B4F-001 through B4F-027, each with its measurement.

**The predictions, stated before their runs**: file:///C:/Dev/specrew-beta3-stabilization/docs/beta4-predictions.md

**The operational brief for the router-skill crew**: file:///C:/Dev/specrew-beta3-stabilization/docs/beta4-router-skill-crew-brief.md

**The release record, including the disclosed known issue**: file:///C:/Dev/specrew-beta3-stabilization/docs/release-notes-v0.40.0-beta4.md

Those documents were complete **before this feature was created**. Restating them here would produce a
second copy of a settled record with nothing keeping the two in step — the duplication defect this arc has
recorded more than any other.

## THE RECORDED DEVIATION

**This feature ran bug-bash conduct under a software-feature contract, and no design workshop was held.**

- **Its conduct was bug-bash.** The flow was bug list → root cause → fix → regression tests → review →
  closeout. The bug list and root causes existed before the feature did.
- **No workshop was run, by the maintainer's explicit ruling.** Beta4's scope was already decided and
  written down. Running eight lenses to manufacture a specification for a fix that is already written,
  reviewed and mutation-proved would be producing an artifact to satisfy a gate rather than to do the work —
  and it is the dependency the bootstrap rule forbids, since the repair would run through the part being
  repaired.
- **The declaration could not express this.** `.specrew/work-kind.yml` is **project-scoped**. Declaring
  `bug-bash` there to describe one feature's conduct made Specrew's own dogfood file false and was correctly
  caught by `work-kind-runtime` T212's SC-014 self-consistency block. **There was no correct value to
  write** — `software-feature` is wrong for this feature's conduct, `bug-bash` is wrong for Specrew's
  posture, and the mechanism offers nowhere else to say it. That is a missing scope, not a defaulting
  problem. See B4F-006 and B4F-020; **per-feature work-kind is the beta5 item and this feature is its
  evidence.**
- **This feature therefore closes as iteration 199/003 did**: on the maintainer's explicit override, with
  the deviation stated in the record rather than left for a reader to infer from an empty specification.

## Why this file was authored now rather than at closeout

Authoring it removes the not-yet-authored sentinel comment the scaffold leaves at the top of a stub, and
that sentinel is what qualified this feature as an open **intake workshop candidate**. (This paragraph
deliberately does not spell the marker out: the scan matches the token anywhere in the file, so writing it
in prose would re-arm the very condition this file exists to clear.) While it stood, feature 201 asserted
itself as an open
workshop on every Stop in this repository — minting a receipt from every typed turn, none of which answered
any question, and firing a workshop advisory on turns that were builds and installs. See B4F-025 and the
receipt discussion in B4F-011 / B4F-014 / B4F-015.

**The receipts already on disk for this feature answer no question that was ever asked, and none of them may
be cited as a lens confirmation.**
