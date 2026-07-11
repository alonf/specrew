# Drift Log: Iteration 002

**Schema**: v1

<!--
  Markdown authoring note (Specrew lifecycle convention):

  When you add new drift events to this file, watch for MD032 (blanks-around-lists).
  A sentence ending with a colon, immediately followed by a bullet list, is the most
  common violation. Always put a BLANK LINE between the colon line and the list:

      BAD:                              GOOD:
      Resolution steps:                 Resolution steps:
      - Step one                        <— blank line here
      - Step two                        - Step one
                                        - Step two

  The F-033 pre-boundary markdownlint gate runs markdownlint-cli --fix on .md
  changes before every boundary-sync write, so most violations auto-fix — but the
  blank line you write in the first place avoids the cleanup churn.
-->

## Summary

**Total drift events**: 1
**Resolution rate**: 100% (1/1 resolved)
**Specification drift**: One implementation-diverged-from-spec event
(DEC-198-GOV-002), detected post-review-signoff at the iteration-closeout
gate, escalated to the maintainer, and resolved by rework before the
iteration closed. (Recorded late relative to the co-review advisory that
prompted it - run 2594b7b5 correctly flagged that this log's zero-events
claim contradicted the incident records in review.md/state.md.)

## Events

### DRIFT-198-I002-001 — shipped ratchet primitive diverged from FR-001/FR-002 (resolved: human-decision, rework before closeout)

- **Requirement citation**: FR-001 (one shared deterministic authorization
  delta primitive) and FR-002 (sync refuses a second unapproved advance);
  the hardening gate's error-handling row additionally claimed
  "an unparseable cursor/verdict-history is a hard fail".
- **Divergence**: the delivered `Get-SpecrewUnreconciledBoundary`
  reconciled crossings by boundary NAME, so a prior iteration cycle's
  same-named approval satisfied the current cycle's crossing (lifecycles
  loop; every boundary name recurs) - and separately, a malformed ledger
  (shape Issues) was read as "nothing unreconciled" (fail-open) instead
  of hard-failing. Field manifestation: iteration 001's retro entry
  reconciled iteration 002's retro crossing and the iteration-closeout
  sync passed a gate that had to refuse (DEC-198-GOV-002,
  .squad/decisions.md).
- **Detection**: post-review-signoff, during the iteration-closeout arc -
  found by tracing why the closeout sync passed while the retro verdict
  was still uncaptured; disclosed in the closeout packet.
- **Escalation (human-decision)**: the maintainer sent the closeout back
  with explicit rework instructions: cycle/ordered-occurrence binding,
  the exact cross-cycle regression, same-cycle replay preservation,
  fail-closed identity, full suite + validator + review-evidence rerun,
  and post-fix regeneration of the premature dashboard/closed-iteration
  records.
- **Resolution (implementation reworked, commit 8745de72)**:
  reconciliation now walks the append-ordered history newest-to-oldest
  and stops at the newest cycle-reset edge (prior cycles can never
  reconcile); an unreadable ledger hard-fails loud at the primitive and
  therefore at every consumer. Paired regressions: ratchet suite Tests
  10-12 (the exact field sequence refuses; same-cycle replay incl. a
  lagging cursor passes; unreadable identity fails closed at primitive
  AND gate). Test 5b's fixture was re-pointed at the real policy seam
  (config.yml) after the new hard-fail exposed it as
  green-through-fail-open. All governance suites green; governance
  validator PASS on iterations 001 and 002; fresh independent co-review
  rounds on the fixed tree.
- **Related, deliberately NOT classified as drift**: DEC-198-GOV-001 (the
  fabricated retro authorization) is a runtime incident of PRE-EXISTING
  fallback-capture machinery (F-174 era), not a divergence of this
  iteration's delivered code from its spec - it is recorded in
  .squad/decisions.md, audited in quality/authorization-ledger-audit.md,
  and folded into iteration 003 scope as FR-041..FR-044 / T030-T033.

### Resolution Strategies (Unused)

The following resolution strategies remain available if drift is detected later in execution:

- **spec-updated**: Update the spec to reflect implementation choice
- **implementation-reverted**: Revert implementation to match spec
- **deferred**: Mark drift as deferred to next iteration

### Notes

- The human-decision strategy was used for DRIFT-198-I002-001 (closeout
  send-back with rework instructions, resolved same-day).
