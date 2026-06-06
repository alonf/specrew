# Drift Log: Iteration 012

**Schema**: v1

<!--
  Markdown authoring note: keep a BLANK LINE between a colon-terminated sentence and a
  following bullet list (MD032), and never start a wrapped prose line with `+`/`*`.
-->

## Summary

**Total drift events**: 2
**Resolution rate**: 100% dispositioned (both fixed-now)
**Specification drift**: none — the catalog revert is recorded in FR-041 (the governing model), not silent divergence.

## Events

### DRIFT-001: catalog-at-open built then empirically reverted (2026-06-06)

**Type**: hypothesis-built-then-dogfood-reverted (the iterative empirical model — NOT specification drift; the spec was updated to match)
**Detected during**: the T004 cross-host dogfood (testLenses11 Copilot + Claude)
**Description**: catalog-at-open (FR-041a) was built (`0ed7cde7`) as the structural front-load. The cross-host dogfood showed it helped no host — redundant on prose hosts (Copilot rendered the catalog AND the agenda = the nine lenses twice) and skimmed on Claude (a before-a-menu render: the agent jumped to the agenda confirm menu). The Claude-only round 1 hid the harm (it just looked like the agenda-minor); only the Copilot run exposed the redundancy.
**Resolution**: **fixed-now** — reverted (`f5b01714`); FR-041/SC-028 reframed to the working conduct (open-question-first + cross-host pacing) + the governing model; no host-branching (advisor: drop > conditional).
**Status**: fixed-now (reverted; the governing model is the durable lesson).

### DRIFT-002: Copilot deferred writing the workshop records until the specify gate forced it (2026-06-06)

**Type**: cross-host conduct variance (the SC-021 deterministic floor caught it)
**Detected during**: the testLenses11 Copilot specify-sync (the gate failed: "the lens workshop happened in conversation, but the workshop artifacts were never written to disk")
**Description**: Claude wrote each per-lens workshop record as it went (step 6); Copilot deferred writing them until the specify-sync gate failed and forced the repair. The outcome was correct (the gate enforced the artifacts onto disk) but write-as-you-go is the better conduct.
**Resolution**: **fixed-now** — the gate caught and forced it; the records are on disk and committed. A write-as-you-go retro lesson; no code change required (the deterministic floor already enforces the outcome).
**Status**: fixed-now (gate-enforced).

### Resolution Strategies (Unused)

The following resolution strategies remain available if drift is detected later:

- **implementation-reverted**: Revert implementation to match spec
- **human-decision**: Escalate to Alon for resolution

### Notes

- The cross-host dogfood was the gate-completeness check, and this iteration it CONFIRMED the convergence (the workshop is the best on both hosts) while reverting one wrong hypothesis (the catalog). Both drifts are honestly dispositioned (reverted + recorded; gate-enforced), not silently carried.
