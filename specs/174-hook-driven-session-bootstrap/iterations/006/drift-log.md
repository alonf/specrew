# Drift Log: Iteration 006

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

**Total drift events**: 2
**Resolution rate**: 50% (1/2 resolved in-iteration; D-011 deferred to iteration 007)
**Specification drift**: 1 plan refinement (the regression net did not characterize the contract -> T035a split + SP re-baseline; human pre-authorized at before-implement). 1 review-time finding (D-011: hook <-> specrew start parity DISPROVEN; the deployed floor proved file-existence, not live read-and-follow -> deferred to iteration 007).

## Events

### D-010 - the specrew-start regression suite does NOT characterize the contract -> T035a split + re-baseline 19->20

**Requirement**: FR-023 (the T035 extraction's regression net) + before-implement instruction #2.

**Finding (surfaced LEADING T035, as instruction #2 required)**: the design pass called the specrew-start
integration suite "the behavior-preserving regression floor" for moving `Get-StartPrompt` out to a shared
lib. Confirming that BEFORE extracting (instruction #2) revealed it is FALSE as a contract guard:
`specrew-start-end-to-end.ps1` pins the directive-block wrapping (PostRestartDirective present, ordering)
and the pause-and-confirm behavior, but it does NOT assert `Get-StartPrompt`'s actual CONTRACT content (the
Lifecycle Quick Reference, the governance-scripts table, the boundary-authorization block) NOR the
`boundary_enforcement` init in start-context.json. So "behavior-preserving, guarded by the suite" was a
PLEDGE - a green suite would not catch an extraction that silently altered the contract. (The exact
build != live class iter-6 exists to kill, caught here at the right time because instruction #2 forced the
lead-with-characterization check.)

**Resolution (in-iteration, human pre-authorized at before-implement instruction #2)**: split **T035a** -
build the genuine characterization (assert the contract's invariant markers survive in last-start-prompt.md
and boundary_enforcement is initialized, after a real `specrew start` run) BEFORE the extraction; re-baseline
capacity 19 -> 20 honestly (T035a = 1 SP) rather than silently absorbing it into T035's 4. The extraction
(T035) is gated on T035a being green.

### D-011 - hook <-> `specrew start` read-and-follow PARITY disproven at review-signoff (the build != live recurrence) -> deferred to iteration 007

**Requirement**: FR-023 (read-and-follow parity), FR-024 (injection-reaches-model), FR-022 (deployed live wiring), SC-011 (the deployed live-wiring floor).

**Finding (surfaced at review-signoff, maintainer side-by-side)**: T036/T037 landed the contract-write +
DRIVE directive, and T038's deployed floor ran GREEN - but a maintainer side-by-side comparison of the hook
path vs `specrew start` DISPROVED parity: the hook skips the coordinator-prompt-surgery step (so it writes a
THIN contract), and the agent does not actually read `last-start-prompt.md` and follow it. T038's green
asserted the contract file + the correct provider copy exist ON DISK, NOT the live read-and-follow
experience. This is the exact `build != live` class iteration 6 existed to kill (iter-5 D-009), recurring
one level up inside the floor built to catch it.

**Resolution (deferred to iteration 007)**: keep the byte-identical, validator-green T035 generator
extraction; DEFER the read-and-follow parity (FR-022/FR-023/FR-024) to iteration 007 with a REAL
read-and-follow floor (not a file-existence smoke). Iteration 006 closes honestly-qualified - NOT a parity
success. Canonical defer entry in `.squad\decisions.md`.

### Resolution Strategies (Unused)

The following resolution strategies remain available if drift is detected later in execution:

- **spec-updated**: Update the spec to reflect implementation choice
- **implementation-reverted**: Revert implementation to match spec
- **deferred**: Mark drift as deferred to next iteration
- **human-decision**: Escalate to Alon for resolution

### Notes

- This artifact was scaffolded before review starts so drift can be logged immediately when detected.
- Replace the zero-drift summary with real counts when the first drift event is recorded.
