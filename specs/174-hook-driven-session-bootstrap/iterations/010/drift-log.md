# Drift Log: Iteration 010

**Schema**: v1

## Summary

**Total drift events**: 1
**Resolution rate**: 100% (1/1 reconciled in-iteration)
**Specification drift**: 1 schema EXTENSION (D-017: T002 + T003 extend Proposal 130's fixed handover schema
with the conversation tail + the gate/workshop frontmatter) — reconciled as a 174-authorized additive
extension under FR-022.

## Events

### D-017 - T002 + T003 extend Proposal 130's fixed handover schema -> RECONCILED in-iteration (174-authorized)

**Requirement**: FR-022 (the handover surfaces useful content for resume).

**Finding**: Proposal 130 Pillar-2 fixes the handover body at SIX section titles
(`Get-SpecrewHandoverSectionOrder`) and the frontmatter at a FIXED key set (schema / source / from_host /
recorded_at / from_commit / active_feature / active_boundary). HandoverStore's own header says "COMPOSES 130 …
does NOT re-author it." T002 adds a SEVENTH body section ('Recent conversation (last few exchanges,
hook-captured)') and T003 adds FOUR frontmatter keys (`last_authorized_boundary`, `last_verdict`,
`workshop_done`, `workshop_remaining`). Both diverge from 130's literal fixed schema.

**Reconciliation (in-iteration)**: ACCEPTED as a 174-authorized ADDITIVE extension, not a 130 violation:

- 174 already evolved this schema in iteration-9 (the mechanical/interpretive ownership split that 130 did not
  specify); the extension is consistent with that evolution and is what FR-022 ("useful content") requires.
- The change is purely ADDITIVE: 130's six summary sections + seven frontmatter keys are unchanged in name,
  order, and meaning. The 7th section is HOOK-owned mechanical (the complement logic in
  `Get-SpecrewHandoverMechanicalSections` includes it automatically). The four new frontmatter keys are
  emitted ONLY when present (quiet on legacy contexts / outside the intake window), so an older reader sees
  the unchanged base schema plus optional lines it can ignore.
- The new frontmatter is DERIVED (refreshed-at-write from `start-context.json` boundary_enforcement +
  `lens-applicability.json` workshop progress), never authoritative — the durable cross-machine truth stays
  the committed `lens-applicability.json` (workshop) + `auth_commit_hash` in git history (gate). The handover
  is a same-machine MIRROR (gitignored), explicitly documented as such.

**Evidence**: `HandoverGateWorkshop.Tests.ps1` (write/read round-trip, conditional emission, agent-author
preserve, hook clear) + `ConversationCapture.Tests.ps1` (4-tier ladder per host) + `HandoverHookPrimary`
recalibrated to FIVE mechanical sections. All green.
