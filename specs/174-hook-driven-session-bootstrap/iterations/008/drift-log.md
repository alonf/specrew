# Drift Log: Iteration 008

**Schema**: v1

## Summary

**Total drift events**: 3
**Resolution rate**: 67% (2/3 resolved in-iteration; D-012 deferred to iteration 009)
**Specification drift**: 1 deferred finding (D-012: the rolling handover is HOLLOW in practice -> the architectural fix is iteration 009). 2 implementation findings resolved in-iteration (D-013 deployable-mirror skew; D-014 anchorless-workshop handover never surfaced).

## Events

### D-012 - the rolling handover is HOLLOW in practice (the cross-host dogfood finding) -> deferred to iteration 009

**Requirement**: FR-022 (the rolling handover) + SC-003 / SC-008 / SC-009 (handover surfaces across exit modes).

**Finding (surfaced at T050 cross-host validation, 2026-06-11)**: the multi-host (claude / codex / copilot)
exit-resume dogfood PROVED the resume re-anchor works across exit, restart, and host-switch - but it ALSO
found the rolling-handover BODY is hollow in practice: 84/84 and 15/15 `hollow-handover-at-stop` across the
dogfood worktrees. Root cause: authoring was agent-/gate-dependent and the Stop hook is transcript-blind by
design, so build / workshop / kill-mid-flight stops never author, and the single most valuable moment
(mid-implement, uncommitted) was the hollowest. The handover passed its mechanical tests but did not produce
real content live - the `build != live` class again.

**Resolution (deferred to iteration 009)**: the architectural fix is iteration 009 - the Stop hook becomes
the PRIMARY delta-author (capture the git/fs delta into the mechanical sections every material stop; never
hollow; host-universal; no transcript or agent cooperation). Iteration 008's validation did its job: it
surfaced the gap before it shipped silently. Canonical defer entry `f174-i008-defer-hollow-handover-to-009`
in `.squad\decisions.md`.

### D-013 - the rolling handover never wrote at Stop (deployable-mirror skew) -> RESOLVED in-iteration

**Requirement**: FR-022.

**Finding**: the deployable mirror `extensions/specrew-speckit/scripts/specrew-handover-provider.ps1` was a
STALE pre-iter-5 copy (it dropped the `-Sections` param -> silent fail-open), so the rolling handover never
wrote at Stop in a deployed layout.

**Resolution (in-iteration)**: re-synced the mirror byte-identical to the module copy + generalized
`ProviderMirrorParity.Tests.ps1` so the divergence cannot recur silently. RESOLVED.

### D-014 - anchorless-workshop handover never surfaced (blank feature_ref) -> RESOLVED in-iteration

**Requirement**: FR-022.

**Finding**: the pre-specify workshop leaves `session_state.feature_ref` blank -> the Stop floor stamped an
empty `active_feature` -> `Test-SpecrewHandoverValidity` returned `no-feature` -> the handover was NEVER
surfaced on resume (the "resync takes minutes" root cause).

**Resolution (in-iteration)**: the Stop floor-writer resolves the feature from the current branch
(`Resolve-SpecrewBranchFeatureRef`, new in `ProjectMetadataAccessor.ps1`) when the anchor is blank, so the
handover validates -> surfaces -> the resume-repair path fires on every host. Proven by 4 resolver unit
tests + 1 anchorless-workshop integration test + bootstrap suite 20/20. RESOLVED (handover-first; NO
central-state write - advisor-corrected from the prior early-anchor design, which is DEFERRED).

### Resolution Strategies (Unused)

The following resolution strategies remain available if drift is detected later in execution:

- **spec-updated**: Update the spec to reflect implementation choice
- **implementation-reverted**: Revert implementation to match spec
- **deferred**: Mark drift as deferred to next iteration
- **human-decision**: Escalate to Alon for resolution

### Notes

- This drift-log is a RETROACTIVE reconstruction (2026-06-11): iteration 008 closed at the boundary (commit
  7fe04228) without a committed drift-log.md; this records the documented in-iteration findings + the
  deferred hollow-handover carry from the state.md and the iteration-009 plan.
