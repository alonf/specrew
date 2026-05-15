# Retrospective: Feature 017 Iteration 002

**Schema**: v1  
**Facilitated By**: Retro Facilitator  
**Facilitated At**: 2026-05-15  
**Review Ref**: [`./review.md`](./review.md)  
**Overall Status**: retro-boundary-complete

---

## Retro Topic 1: Pre-Implementation Review Pattern Outcome

The pre-implementation review was still worth doing. It successfully forced the team to spell out
the non-blocking closeout posture, grandfathering rules, routing classifier safety, documentation
accuracy expectations, and Iteration 001 compatibility before implementation started. That prevented
Iteration 002 from turning into an unconstrained "just wire the dashboard everywhere" change.

At the same time, the review did not catch every issue that mattered to end-user trust. The bugs
that later surfaced were not spec-authority gaps so much as runtime truth-surface gaps: the code
and bookkeeping could look structurally reasonable while still producing a misleading dashboard on
the real feature branch. The lesson is not that pre-implementation review failed; it is that this
pattern must be paired with live dashboard replay against the canonical repository before review is
considered complete.

## Retro Topic 2: Four Bug Categories Surfaced Post-Implementation

Four distinct bug categories emerged after implementation. First, the active-feature status
derivation bug (`R-V1`) marked the in-flight feature as shipped on the feature branch before any
merge-to-main evidence existed. Second, the velocity-duration bug (`R-V2`) collapsed same-day work
into an untruthful duration basis until the renderer switched to planning-to-closeout calendar-day
span handling.

Third, the story-point parsing bug (`R-Retro-1`) showed the difference between form-correct and
meaning-correct artifacts: `~18 SP` looked human-friendly in `iterations/001/state.md`, but the
dashboard parser treated it as `0`, which made Feature 017 render its own creator as delivering no
story points. Fourth, the missing-iteration-state bookkeeping bug (`R-Retro-2`) kept Iteration 002
invisible because `iterations/002/state.md` did not exist even though implementation and review had
completed. Together these four bugs show that truth surfaces break both in code and in the
bookkeeping artifacts that feed code.

## Retro Topic 3: Corpus Row Decision Reconsidered

Before this retro, the existing `dashboard-truthfulness` row in `.specrew/quality/known-traps.md`
already covered roadmap drift, missing closeout artifacts, and validator warnings. After Iteration 002,
that was no longer enough. The more precise recurring pattern is that a surface can be
form-correct in Markdown or code structure while still being meaning-incorrect when the dashboard is
actually rendered.

That is why this retro adds a new corpus row focused on form-correctness-versus-meaning-correctness.
The row records all four surfaced bugs as one reusable pattern: branch-local shipped inference,
calendar-day collapse, unparsable approximated numeric fields, and invisible iterations caused by
missing canonical artifacts. This reconsideration matters because the team now has multiple concrete
examples proving that "validator clean" or "Markdown looks fine" is not enough by itself.

## Retro Topic 4: Estimation Variance for Iteration 002

Iteration 002 was no longer honestly an "~8 SP" slice by the time work actually shipped. Iteration 001
closeout and retro had already recalibrated the carryover to roughly ~16-18 SP because the real work
included closeout integration, validator additions, documentation, compatibility preservation, and
end-to-end fixtures rather than only a narrow hook implementation. Against that recalibrated band,
Iteration 002 appears to have landed at 18 SP, which puts it at the top of the planned range rather
than far beyond it.

This is an important calibration success. The team corrected the estimate before retro, then the
delivered commit range `9b51630..6590e93` effectively consumed the full band once review-signoff
repairs were included. The variance story is therefore modest overrun against the 16 SP clean
baseline, not another Iteration 001-sized estimation miss.

## Retro Topic 5: The Headline Lesson Is Still “F-017 Iteration 1 Rendered as 0 SP”

The most important lesson from this retro is not the missing file by itself and not even the
status-derivation repair. It is that the dashboard rendered Feature 017 Iteration 001 as `0 SP`
until this retro repaired the state artifact. That is an optical and trust problem because the
feature being shipped was the trust surface itself.

If a velocity dashboard can misreport its own just-finished iteration, then users will reasonably
question every other number it shows. The repair is mechanically small—store `18 SP` as the value
and move the approximation context into notes—but the product lesson is large: machine-readable
truth must live in the parseable field, while human nuance belongs in adjacent explanation.

## Retro Topic 6: Feature-Closeout Readiness

Feature-closeout is not the next move yet, and this retro should say that plainly. Under Rule 15,
feature-closeout still requires a separate authorization boundary, a version-management pass, and
merge-to-main evidence that the active feature is truly shipped rather than merely complete on its
branch. Iteration 002 is now retro-complete, but iteration-closeout is still pending and must happen
first.

That said, no new functional regression is known after the retro repairs. `specrew where` should now
show Feature 017 Iteration 001 at 18 SP, include Iteration 002 in the plan-vs-reality tables, and
drop the missing-state warning. The remaining gap before iteration-closeout is procedural and
bookkeeping-oriented: capture the closeout boundary explicitly, then evaluate Rule 15 readiness from
that closed-iteration state.

## Retro Topic 7: Carryover to Future Work — Branch Reconciliation and Session-State Durability

Iteration 002 did not eliminate the larger Phase 2 carryovers identified in Iteration 001 retro.
Branch reconciliation is still needed so long-lived feature branches do not drift silently away from
main while retaining the F-016 audit trail, and session-state durability is still needed so
worktree-local progress survives restarts without stale coordinator guidance.

The Iteration 002 bugs actually reinforce both needs. The missing `state.md` and the branch-local
shipped-status bug both show how easy it is for lifecycle truth to become fragmented across files,
branches, and sessions. Future work should treat branch reconciliation and session-state durability
as enabling infrastructure for dashboard trustfulness, not as unrelated platform polish.

## Retro Topic 8: Dogfood Evidence for the Article

Feature 017 now has unusually strong dogfood evidence for a future article because it exercised the
entire methodology on a truth-sensitive feature and then found bugs in its own truth surface. The
story is not "the dashboard shipped perfectly." The stronger story is that the workflow exposed its
own misleading outputs, repaired them through explicit boundaries, and fed the lesson back into the
known-traps corpus.

That article can honestly show the full loop: pre-implementation review helped, implementation
landed, review caught two bugs, retro caught two more bookkeeping/truth bugs, and the final corpus
entry now teaches future teams to separate machine-parsable truth from human-friendly approximation.
That is real dogfooding because the process was used on itself and forced to become more truthful.

---

## Retro Boundary Result

Iteration 002 retro-boundary is complete. The canonical artifact set now includes `plan.md`,
`state.md`, and `retro.md`; the dashboard renders the delivered story points truthfully again; and
the next valid action is explicit iteration-closeout authorization only.
