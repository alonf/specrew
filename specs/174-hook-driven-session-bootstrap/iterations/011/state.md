# Iteration State: 011

**Schema**: v1
**Current Phase**: specify
**Iteration Status**: executing
**Last Completed Task**: (none — iteration opened at the specify boundary)
**Tasks Remaining**: (task breakdown is produced at the plan boundary; specify in progress)
**In Progress**: specify — the feature-spec amendment for the DF-3/4/5/7 boundary-authoring + verdict-integrity cluster
**Baseline Ref**: iteration-010 HEAD (`c5756473`)
**Updated**: 2026-06-13T17:30:05Z

## Charter

Iteration 011 fixes the **DF-3/4/5/7 boundary-authoring + verdict-integrity cluster** the
iteration-010 multi-host round-robin dogfood surfaced
(`file:///C:/Dev/Specrew-session-bootstrap/specs/174-hook-driven-session-bootstrap/iterations/010/dogfood-multihost-handover.md`).
Locked design + maintainer decisions:
`file:///C:/Dev/Specrew-session-bootstrap/specs/174-hook-driven-session-bootstrap/iterations/011/fix-plan-draft.md`
— **A3 hybrid authoring** (agent-callable command + mechanical Stop-hook backstop), **captured
human verdict-evidence** (not a forgeable param), **committed ≠ authorized** on resume. Core
principle: *do NOT rely on agent compliance for integrity-critical state.* Deferral recorded:
`f174-i010-defer-integrity-cluster-to-011`.

**Causal chain (one coherent fix):** `Write-SpecrewHandoverContext` is not agent-callable (DF-7) →
the boundary packet + `active_boundary` never persist (DF-3) → a resume reads committed-as-approved
(DF-4) → a bare "continue" advanced two un-authorized boundaries + the sync FABRICATED a human
verdict (DF-5). The committed tree is durable truth (antigravity recovered with no data loss), so
this is an integrity + UX + audit fix, not data-recovery.

**Sequence (from the fix plan):** Fix A (authoring + clobber) → Fix C (verdict capture) → Fix B
(committed ≠ authorized resume) → Fix D/E (DF-1 recap synthesis + DF-2 version/branch, small).
**Acceptance = a focused re-dogfood** of the DF-3/4/5/7 scenario (real-host behavior is the gate,
per the iteration-010 falsification lesson). **Out of this iteration:** DF-6 (cursor continuity)
stays WITHIN F-174 but a LATER iteration; DF-8 (agent-edits-governance) is a separate proposal.

## Specify (this boundary)

The feature spec
(`file:///C:/Dev/Specrew-session-bootstrap/specs/174-hook-driven-session-bootstrap/spec.md`) is
amended at the specify boundary:

- **FR-022 persist-clause refinement** (capture ≠ author): the agent still renders/authors the
  packet; persistence becomes mechanical (the transcript-capable Stop hook and/or an exposed
  command), grounded in T002's Stop-hook transcript access. The agent-authored + not-forced
  guarantees are unchanged.
- **FR-026 (new)** — verdict-integrity: the recorded boundary verdict derives from captured human
  input; no fabrication, no git-committer attribution; absent capture → recorded un-authorized.
- **FR-027 (new)** — committed ≠ authorized on resume; complements FR-017 on the authorization axis.
- **SC-012 / SC-013 / SC-014** — the acceptance for the above.

Guarantee-level only; mechanism (capture timing, match-strictness, the Antigravity fallback
specifics) is the plan boundary's job. DF-1 / DF-2 trace to existing FR-002 / FR-022 (no new FR).
STOP at the specify boundary for the maintainer verdict.
