# Iteration 004 State

**Feature**: 197-continuous-co-review
**Iteration**: 004
**Current Phase**: complete
**Iteration Status**: complete
**Last Completed Task**: iteration-closeout (Phase B part 1 banked, 2026-06-23)
**Tasks Remaining**: (none)
**In Progress**: (none)
**Updated**: 2026-06-23

## Execution

- T070+T072 DONE (#2885): the three Stop-hook handover consumers (verdict/packet/conversation-tail) now share ONE memoized transcript parse per stop (`Get-SpecrewTranscriptParsedTurns`, single-entry keyed by path+mtime+maxlines, returns a fresh array so the verdict reader's synthetic-user append can't leak). Independently verified: verdict-capture-blocks 22/22, conformance-detection 39/39, ConversationCapture + ConversationOnlyCapture all pass, transcript-parse-once 28/28 (byte-identical goldens + leak-guard + non-vacuous parse-once 3->1). No F-184 surfaces. Plus a `.gitattributes` LF pin so the goldens survive a CRLF checkout (the regression guard can't silently die on CI).
- #2885 MEASURED (2000-line transcript): handover parse 1,400 ms -> 342 ms (75.5% / ~1.06 s saved per stop); the real ~11s drops to ~3-4s. Conformance last-assistant read is a 10 ms backward early-exit.
- T071 SUBSUMED (measured): the conformance provider has no redundant re-parse to dedup (early-exit + $hasPending-gated + T070-memoized packet read); a forced memo would regress the common case. -1.50 SP -> capacity 10.50/20.
- T073+T074 DONE (FR-025): opt-in gate enforcement wired into Invoke-SpecrewBoundaryStateSync. New `signoff-gate-wiring.ps1` (a testable seam: `Get-ContinuousCoReviewGateEnforcementEnabled` reads `.specrew/config.yml` `co_review_gate_enforcement`, default OFF; `Invoke-ContinuousCoReviewSignoffGateIfEnabled` is a no-op except review-signoff + enabled, then Asserts the gate — fail-CLOSED block propagates; allow-path emits NOTHING so the boundary-sync result pipeline can't be corrupted). Wired after the iteration-state-truth gate (canonical $BoundaryType), Out-Null-guarded. Verified: parse OK, signoff-gate-wiring 12/0 (incl. ON+no-evidence->refuse [SC-019], ON+fresh-evidence->allow [SC-020], allow-path-returns-nothing, OFF/non-review-signoff no-op), full CCR suite 188/0. No F-184; session-config.ps1 untouched.

## Scope (Phase B — Always-On, now unblocked by the F-185 merge)

Opened on merge commit `6c502c20` (origin/main = F-185 host-neutral hook surface +
0.39.0-beta1). Phase B delivers the live always-on behavior + the critical-issue fixes:

1. **Critical-issue fix — #2885 Stop-hook latency (~16s/stop).** The Stop hook is already
   slow (dominant ~11s F-174 handover transcript re-parsing + ~4s conformance). 197's
   navigator spawns a reviewer process, so the Stop path MUST be fast first. (F-184 status of
   the handover/dispatcher files under investigation.)
2. **Host-neutral Stop-hook co-review trigger (FR-026/030/031)** — register a 197 co-review
   provider into the merged 185 `specrew-hook-dispatcher` seat; the navigator runs
   ASYNC/non-blocking so it does not add to the Stop latency (#2885 constraint).
3. **Gate enforcement wiring (FR-025)** — wire `Assert-ContinuousCoReviewSignoffGate` into
   `Invoke-SpecrewBoundaryStateSync` (non-protected; 185 does not touch it).
4. **Reviewer-runs-in-repo execution model** — the spawned reviewer runs with repo read
   access + inherited env so it can read config + run tests on the real host (Proposal 145
   runtime evidence; enables the maintainer real-host smoke test).

## Carried in from Iteration 003

- F3/F4 override + run-record authentication/persistence (binding on this wiring).
- SC-012 maintainer real-host smoke test runs AFTER the always-on auto-fire lands.

## Design grounding (in progress)

- Explore: 185's merged hook/provider seam (how to register a Stop provider without editing
  the F-184 dispatcher; sync vs async).
- Explore: #2885 internals (the shared transcript parse-once fix location + F-184 status).
