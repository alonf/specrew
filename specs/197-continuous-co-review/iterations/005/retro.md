# Iteration 005 Retro

**Feature**: 197-continuous-co-review
**Iteration**: 005 (async co-review navigator on the isolated-task launcher)
**Date**: 2026-06-24

## What went well

- **The spike-gates-the-build discipline paid off.** T076 (prove the detached self-limiting
  cross-platform spawn FIRST) caught the design risk before any production code — and the cross-platform
  leg caught a real Linux-only blocking bug a Windows-only spike would have shipped.
- **Dogfooding on the iteration's own code found 2 real bugs every green unit test missed** (the `& git`
  redirected-provider encoding throw + the huge-arg `git diff` limit) — both only manifest in the real
  redirected-provider context on a real-sized repo.
- **Adversarial 145 review out-performed green tests on soundness:** two real issues neither the 216/0
  suite nor the implementers caught — the absence-of-blocking promotion (would launder a non-pass to a
  gate `pass`) and the catalog-row drift (the navigator inert on live dispatch while fixtures stayed
  green). Both fixed, not deferred.

## What hurt (friction -> learning)

1. **The green-but-inert trap (the headline learning).** The `co-review-navigator` row was in the
   extension-source `refocus-scopes.json` but NOT the `.specify` deployed copy the dispatcher loads
   first — so the navigator NEVER fired on live dispatch, while every fixture-catalog test was green and
   the dogfood (which called the function directly) also passed. **Learning: file-presence != runtime,
   AND fixture-green != live-wiring.** Parity coverage must include the registry/catalog, not just the
   `.ps1` provider scripts. -> ACTION DONE: `refocus-scopes.json` parity guard added to ProviderMirrorParity.
2. **A governance gate is only as honest as what feeds it.** The PASS->gate promotion plus the
   always-passing stub made the gate auto-satisfiable, and the first cut promoted on mere
   absence-of-blocking. **Learning: a stub/non-review must NEVER satisfy a governance gate; promotion
   needs an affirmative-pass allow-list, not "no blocking finding."** -> FIXED (stub-exclusion + affirmative-pass).
3. **Cross-platform spawn is a Windows-hides-it hazard.** The detached child inherits the parent's
   stdio pipes on Unix, so the parent BLOCKS on exit (18.2s) — invisible on Windows, which detaches by
   default. The maintainer's "we are cross platform" pushback forced the WSL validation that caught it.
   **Learning: process-spawn/detachment work is Unix-validated (WSL), not Windows-only.** -> memory captured.
4. **A surface can be "done" yet show the user nothing.** The navigator surfaces only a summary and
   DELETES the full verdict on reap — invisible while the reviewer is the no-findings stub, a real loss
   the moment a real reviewer emits findings. **Learning: a review surface's deliverable is the findings
   the human sees, not the gate signal.** -> Iteration 006 headline scope.
5. **Stale session anchor (#2784) churned a closed iteration all session.** `start-context.json`
   `iteration_number` frozen at `001` made every test-run touch iter-001's state. Worked around by
   hand-driving the closeout targeting 005 explicitly. -> #2784 (out of 197's scope) tracks the fix.

## Effort calibration

Planned 18.00 -> raised to 28.00/30 (informed maintainer "implement all, fix all" expansion). The
overrun was real-issue-driven: the dogfood + the adversarial 145 surfaced work that did not exist at
plan time (2 dogfood bugs, the affirmative-pass soundness fix, the catalog MAJOR). **Learning: budget
closeout headroom for dogfood + adversarial-review findings on integration-heavy iterations — they
reliably surface real, plannable-only-in-hindsight work.**

## Action items

- [x] `refocus-scopes.json` catalog-parity guard (ProviderMirrorParity) — done this iteration (`938731eb`).
- [ ] File the deploy-mechanism proposal (`refocus-scopes.json` not synced on `specrew update`),
  COORDINATED with Proposal 198 (self-host currency; same class as the Devin `extensions.yml` drift).
- [ ] Iteration 006: real reviewer + durable full-findings reporting surfaced via the 197 blackboard.
- [ ] Document the 4 pre-existing `probe`-authored main commits as an accepted cosmetic blemish (no rewrite).
