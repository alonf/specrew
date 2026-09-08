# Review Record: Iteration 003

**Schema**: v1
**Reviewed**: 2026-09-08
**Overall Verdict**: accepted, with the lifecycle record corrected rather than defended
**Campaign**: none - see below
**Rounds**: 0 of 4 used

## What This Sign-off Claims, and What It Does Not

**It claims** that the work this iteration produced was verified, by instruments that do not depend on the
iteration's own records: the full-test census green in CI on the tagged commit, a governed walk that crossed
a boundary on a typed verdict against the installed build, and a packaged delta measured from the module
FileList rather than recalled.

**It does not claim** any of the following, and each is stated because a reader would otherwise assume them:

- **It does not claim a review campaign ran.** None did. There were no rounds, no reviewer, and no findings
  ledger. Iteration 002 ran three rounds; this one ran none.
- **It does not claim the work was planned.** It was not. The plan is a stub nobody authored.
- **It does not claim any boundary was authorized.** None was - see the section below.
- **It does not claim the drift log is a substitute for a task table.** It is a record of decisions, not of
  planned work, and it cannot answer questions a task table answers: what was in scope, what was cut, what
  the estimate was against the actual.

## The Lifecycle Defect This Iteration Has To Own

**Iteration 003 shipped a release without crossing a single boundary.**

| event | UTC |
| --- | --- |
| iteration 002 closed | 2026-08-31 14:16:55 |
| `16a43c03` "chore(beta3): scaffold iteration 003" | 2026-08-31 15:40:08 |
| session state records `boundary_type: plan` | 2026-08-31 15:40:40 |

Thirty-two seconds, and the `auth_commit_hash` is the scaffold commit itself. **No gate accepted an empty
artifact - no gate ran at all**, because no boundary was ever crossed. Work proceeded past a boundary that
never opened, and the ledger read `plan` because scaffolding wrote it as a side effect of creating the
iteration.

**This is the authorization problem, not the evidence problem**, and the distinction matters: the release's
evidence is sound and independently checkable. What failed is the record of who authorized what.

Recorded as **DRIFT-199-I003-086**, with the enforceable form attached for beta4: an iteration whose
`plan.md` still carries the scaffold's stub title, or whose `tasks:` is empty, cannot hold an authorized
boundary.

## What Was Actually Verified

**The census.** It had never passed since entering the publish workflow in August - the run behind the
original 31 August tag failed 23 of 404 named test files, and that result went unread for two days. The
respin cleared every failure by classification, and the gate is now green in CI on the tagged commit.

**The walk.** Five walks ran; four ended before a boundary and each found something real. The fifth crossed
a boundary on a typed verdict, with branch head, installed module and working tree all agreeing on the
commit being tagged.

**The delta.** 8 packaged files carrying 14 changes, measured by intersecting `Specrew.psd1`'s FileList with
the diff. 37 files changed in total; 29 do not ship.

**Inertness.** The comment-only changes were proven by parsing each file before and after, dropping comments
and comparing token streams - three files executable-identical, and the fourth correctly excluded once it
gained a behavioural change.

## Findings and Dispositions

The 88 drift entries are the findings ledger. The dispositions that shipped:

- **One defect at birth** - a malformed authority marker in a deployed script - fixed.
- **A stale-fixture population** caused by the batch's own tightening from *artifact exists* to *artifact
  was produced through the governed path* - classified per file, fixed, relocated or disclosed.
- **Two defects the gate caught during the respin itself** - deployed machinery edited without re-stamping
  its install marker, and a report that repeated on every turn of a workshop. Both fixed.
- **FR-032 ships disclosed** with no passing automated test and no field proof, because proving it needs two
  concurrent sessions and a single-session walk cannot stage that. A limit of the walk format, not an
  oversight.

## Gaps Carried Forward

Named rather than closed, and all carried into the beta4 backlog with their measurements:
the fixture corpus predating the provenance shift; no test for auto-scope narrowing on the happy path; the
deployed-marker agreement check; the composed `.gitignore`; the positive-test rule generalised beyond the one
exemption it now guards; and the workshop guard's sibling branch (**DRIFT-199-I003-088**).
