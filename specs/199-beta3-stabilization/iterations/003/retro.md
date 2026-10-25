# Retrospective: Iteration 003

**Schema**: v1
**Recorded**: 2026-09-08
**Iteration**: 003 (the beta3 respin and publish)
**Capacity**: not measurable - no plan, no tasks, no estimate

## What this iteration is about

**A release was blocked at its own gate and nobody noticed for two days.** The 31 August tag was cut, a
pre-release published, and the publish never completed: the census failed 23 of 404 named test files and the
publish job was skipped because the census gates it. From outside it looked like a release had happened.

Everything after that was reactive. There was no plan because there was no time in which to write one that
would have survived contact - each failure was classified as it surfaced, ruled individually, fixed and
recorded.

## The honest shape of the work, and why a task table would have lied

**A task table implies a plan, and the plan implies estimation, sequencing and scope.** None of those
existed. What existed was a queue of gate failures whose contents were unknown until each was opened.

**That is a legitimate way to run an emergency stabilisation and a poor fit for the artifact.** Back-filling
tasks would have produced a tidy record implying planning nobody did - and this project's whole claim is that
its lifecycle describes what happened. **An honest record of an unusual iteration is worth more than a tidy
one.**

What the drift log gave instead, and a task table would not have: **the reasoning behind each ruling**,
including the ones that were wrong and were corrected.

## What it cost, measured

| measure | value |
| --- | --- |
| drift entries | 88 |
| census runs to green | 14 local, plus 3 in CI |
| walks before one reached a boundary | 5 |
| tag cut, deleted and re-cut | 3 times |
| packaged files changed | 8, carrying 14 changes |

## What went wrong inside the fix, and it is the more useful half

**Three defects were introduced by the respin itself and caught by its own gates**: the deployed marker left
un-re-stamped after editing mirrored machinery; a workshop report that repeated on every turn, created by the
fix meant to soften it; and internal drift identifiers leaked into shipped teaching. **Each was caught by a
check that existed, which is the argument for the checks.**

**And one class recurred three times**: a hand-enumerated set repaired by adding a name to it. The exemption
for the scaffolded spec was written as a path rather than as the condition the ruling actually stated, and it
has now failed twice more - once because the predicate could never fire, once because a sibling branch read
the same set through a different clause. **The lesson is recorded with the count, because the count is what
makes it a class.**

## What the lifecycle got wrong, and what that says

**No boundary was crossed in this iteration.** The `plan` in session state was written by the scaffold, 32
seconds after it ran, carrying that `chore` commit as its authorization. So the ledger showed an authorized
plan that no human ever approved, against an artifact nobody authored.

**The uncomfortable part is that nothing noticed for eight days**, through a published release, and the
project found it only when its own closure was written. **A boundary state that can be set by scaffolding is
not a record of authorization; it is a record of scaffolding.**

## What carries forward

The backlog from this fortnight is unusually well evidenced and far too large for one release. Its cut is
beta4's first job, not this iteration's. The items are recorded with their measurements attached, which is
what will make the cut defensible.

**One rule earned its place immediately and is already in use**: the last green before a tag must be a
dispatched workflow run, not a local sweep. It was written after a local census passed twice on a commit
whose CI gate then failed, and it was followed on the very next cut.
