# Drift Log: Iteration 003

**Schema**: v1

<!--
  Markdown authoring note: keep a BLANK LINE between a colon-ending sentence and the
  list that follows it (MD032). Author drift events the same way.
-->

## Summary

**Total drift events**: 3
**Resolution rate**: 100% (3/3 resolved)
**Specification drift**: None (all three are plan/inventory-vs-reality reconciliations, not spec drift)

## Events

### D-301 — G4 is the assembled view of G1–G3, not a separate generated artifact

- **Requirement**: FR-019 (T302).
- **Observed**: The plan's T302 assumed the lifecycle-prompt Rule 46/47 feature-closeout block (G4)
  might be a separate generated/deployed artifact to regenerate. A repo sweep confirms the coupled
  closeout block lives ONLY in the three coordinator sources (G1 `coordinator-decision-guidance.md`,
  G2 `coordinator-response.md`, G3 `specrew-governance.md`); G4 is the runtime-assembled view of those.
- **Resolution**: `spec-updated` (plan reconciled). T302 collapses from "regenerate" to "verify": the
  T301 edits to G1–G3 ARE the G4 neutralization; no separate artifact exists. Verified no bare mandate
  survives in any source surface. Effort 0.5 SP vs the planned 1 SP.

### D-302 — the `.specify/` deployed mirror synced to match the neutralized source (consistency)

- **Requirement**: FR-019 (T301/T302/T304).
- **Observed**: The tracked `.specify/` self-host mirror partially mirrors the sources. Two iter-3-edited
  sources have tracked mirrors: `shared-governance.ps1` (T304) and `specrew-governance.md` (T301/G3). The
  former is held byte-for-byte by a SHA256 parity test (`pr-review-integration.tests.ps1`) and was synced
  immediately; the latter initially still carried the pre-neutralization closeout prose (the bare
  `gh pr create` mandate), leaving a committed mirror that contradicted the iteration's own purpose.
- **Resolution**: `spec-updated` (mirror synced to source). Both tracked mirrors are now synced to their
  neutralized sources — `specrew-governance.md` copied source→mirror (SHA256
  `74ebd134…`), the same blessed "sync the mirror to MATCH source" operation already applied to
  `shared-governance.ps1`. This is NOT a divergent hand-edit (the mirror is made identical to source, which
  is exactly what deploy would produce); it honors the "do not hand-edit `.specify`" rule (sync-to-match is
  allowed, divergent content authoring is not) and removes the inconsistency of syncing one tracked mirror
  while deferring an equivalent one. `.specify/` remains excluded from the SC-008 sweep (T306) and the
  host-coupling firewall as before; this change only brings the two tracked mirrors that DO appear in the
  iter-3 diff into a consistent, non-contradictory state.

### D-303 — `proposal-discipline.md` carried a `gh pr create` mandate the audit missed

- **Requirement**: FR-019 / SC-008 (T306).
- **Observed**: The Iteration-1 coupling inventory AND the planning-time sweep both missed
  `docs/methodology/proposal-discipline.md` step 11 ("open a PR (`gh pr create`)") — a downstream-governing
  methodology doc with a forge mandate. The T306 SC-008 sweep CAUGHT it (the sweep doing its job).
- **Resolution**: `implementation-reverted` (neutralized in place). Genericized to "open a PR/MR via your
  forge (the provider adapter describes how)"; the `gh pr create` token removed; the now-formalized
  Proposal-182 reference updated. In scope per the maintainer's "docs where they govern downstream
  projects"; recorded as a delta in the neutralization inventory (D2), not silently folded in.

### Resolution Strategies

- **spec-updated**: Update the plan/mirror to reflect the implementation reality (D-301, D-302).
- **implementation-reverted**: Neutralize a sweep-caught surface in place (D-303).
- **deferred**: available, unused this iteration.
- **human-decision**: available, unused this iteration.

### Notes

- Neither event is specification drift (spec ↔ implementation never diverged); both are
  plan-assumption reconciliations recorded so the descoped/deferred detail stays reviewable.
