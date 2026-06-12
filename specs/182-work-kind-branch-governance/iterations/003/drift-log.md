# Drift Log: Iteration 003

**Schema**: v1

<!--
  Markdown authoring note: keep a BLANK LINE between a colon-ending sentence and the
  list that follows it (MD032). Author drift events the same way.
-->

## Summary

**Total drift events**: 2
**Resolution rate**: 100% (2/2 resolved)
**Specification drift**: None (both are plan-assumption-vs-reality reconciliations, not spec drift)

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

### D-302 — the `.specify/` deployed mirror re-syncs at deploy, not by hand-edit

- **Requirement**: FR-019 (T301/T302).
- **Observed**: The tracked `.specify/` self-host mirror partially mirrors the sources; its copy of
  `specrew-governance.md` still carries the pre-neutralization prose. `.specify/` is a deploy-derived
  mirror of Specrew's OWN self-host deployment, not what downstream projects receive (they get the
  `extensions/` source shipped in the module).
- **Resolution**: `deferred` (deploy-time). Per the established convention — `host-coupling-firewall`
  `$skipDirs` excludes `.specify`, and CI markdownlint runs `--ignore .specify` — the mirror is excluded
  from structural sweeps and re-syncs at the next deploy/publish (feature-closeout, outside Iter-3
  scope). NOT hand-edited (honors the maintainer's "do not hand-edit .specify" rule). The Iteration-3
  SC-008 sweep (T306) excludes `.specify/` consistently. Mirror parity is restored at deploy.

### Resolution Strategies

- **spec-updated**: Update the plan to reflect the implementation reality (D-301).
- **deferred**: Park with the correct downstream owner / deploy step (D-302).
- **implementation-reverted** / **human-decision**: available, unused this iteration.

### Notes

- Neither event is specification drift (spec ↔ implementation never diverged); both are
  plan-assumption reconciliations recorded so the descoped/deferred detail stays reviewable.
