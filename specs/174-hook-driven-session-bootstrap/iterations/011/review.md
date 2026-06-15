# Review: Iteration 011

**Schema**: v1
**Reviewed**: 2026-06-14
**Overall Verdict**: accepted
**Verdict Qualification**: accepted for the DELIVERED scope — the DF-3/4/5/7 boundary-authoring + verdict-integrity cluster (FR-022/026/027), the FR-028 hook install/discovery hardening (T010–T012), AND the host-delivery + packaging cluster the real-host re-dogfood surfaced at the acceptance gate (P1 resolver, P2 10K-cap drop, the StrictMode `$null.Count` banner-blocker). F-174 the feature stays OPEN; CAP-1 + silent-failure hardening + D-001 host-neutral marker emission are recorded deferrals.

> **Honesty note — consolidated at the iteration-closeout boundary (2026-06-14).** This review.md consolidates
> the GENUINE review work recorded across this iteration into the canonical closeout artifact: the structured
> Proposal-145 multi-agent review (`review-signoff.md` + `review-145-hook-deploy.md`, 10 agents, adversarial
> verification), the second Proposal-145 review of the host-delivery fixes (5 confirmed / 6 refuted), and the
> maintainer's real-host re-dogfood on Claude. The content reflects review work actually performed; the artifact
> is made canonical at closeout, not invented.

## Scope reviewed

The full iteration-011 delta plus the host-delivery cluster found at the gate. Two commit clusters:

- T001–T012 (`c5756473..69a5dd31`): the agent-callable `specrew handover author` (DF-7), captured human
  verdict-evidence (DF-5), committed≠authorized resume (DF-4), the pointer-mode decision recap (DF-1), the
  resolved version/branch in the directive (DF-2), and the FR-028 hook install/discovery hardening.
- The real-host cluster (`f76014a7`, `9d3564f2`): P2 per-host lean SessionStart directive under the 10K hook
  cap, P1 clean-install resolver guard, and the StrictMode empty-`done_decisions` crash fix.

## Result

**Two structured Proposal-145 passes; both adversarially verified.** Pass 1 (T001–T012): 14 findings — 0 HIGH,
3 MEDIUM (all fixed with regression tests), 6 LOW, 5 INFO. Pass 2 (host-delivery fixes): 11 findings — 5
confirmed (2 HIGH: RES-1 handover-budget ordering, CAP-1 budget composition; 3 LOW), 6 refuted. Every confirmed
finding was remediated or recorded as a deferral. The integrity guarantees (no fabricated verdict, no gate-skip,
committed≠authorized, mechanical capture/clobber) held under direct probing.

**Real-host acceptance gate (the decisive evidence):** the Claude re-dogfood found the bootstrap banner not
surfacing — root-caused to the P2 cap drop AND the StrictMode `$null.Count` crash, both of which the synthetic
suite missed (the extraction tests did not run under StrictMode). Both fixed; the **banner now surfaces on
Claude** (maintainer-confirmed). Full bootstrap suite **45/45** + integration green.

## Deferrals (recorded, not blocking acceptance)

- **CAP-1** (drift D-007): the bootstrap directive + the co-resident refocus fragment self-bound to their OWN
  budgets that do not compose under 10K at their ceilings. Not breaching today (the cap test now measures the
  real refocus fragment + surfaces the residual). Structural fix = a dispatcher fragment-priority drop. Proposal
  candidate.
- **Silent-failure hardening** (drift D-008): the provider's fail-open catch emits nothing on an internal error
  (stderr-only WARN, invisible on Claude) — it hid both real-host bugs. Proposal candidate.
- **D-001**: host-neutral verdict-marker emission — fast-follow (integrity-safe today; only cross-host liveness
  is missing).

## Verdict

**ACCEPTED.** The delivered scope is sound, green, twice-145-reviewed, and the core deliverable (the hook
surfaces orientation on the host) is now real-host-confirmed on Claude. Honest residual: the published-beta
install validation remains a later feature-closeout gate; the three deferrals are recorded above.
