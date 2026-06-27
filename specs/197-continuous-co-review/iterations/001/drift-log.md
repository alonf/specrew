# Drift Log: Iteration 001

**Schema**: v1
**Spec**: file:///C:/Dev/197-continuous-co-review/specs/197-continuous-co-review/spec.md

Tracks divergences between the approved specification, plan, task table, and implementation evidence for Iteration 001. Drift is logged here before review concludes; it is not silently absorbed into implementation.

## Summary

**Total drift events**: 1
**Resolution rate**: 100% (1/1 resolved)
**Specification drift**: One authorized dogfood repair is recorded: the review-signoff hard gate is default-on in 197-owned wiring and Specrew self-review includes the co-review runtime under test. The stale lifecycle-state evidence mismatch identified by review was governance-artifact drift, not requirement or implementation drift, and is repaired in the current review-position artifacts.

## Events

### D-197-I001-001 - Dogfood hard-gate repair after co-review evidence gap

**Status**: resolved
**Detected by**: live co-review `codex-hard-gate-20260627`
**Authorized by**: maintainer instruction on 2026-06-27 to make the co-review mechanism robust after the AISharedMemoryMCP host-switch dogfood failure

**Drift**: The implementation changed the review-signoff gate from an opt-in configuration key to a default-on backstop and changed the worktree reviewer visibility policy for Specrew self-review. Iteration 008 design previously treated the signoff evidence gate as surviving unchanged and the strip set as downstream methodology machinery; dogfooding proved those assumptions insufficient for the host-switch/compaction failure mode.

**Resolution**: Recorded T083/T084 in `specs/197-continuous-co-review/tasks.md`, added the dogfood repair decisions to `specs/197-continuous-co-review/iterations/008/design-analysis.md`, kept the implementation inside `scripts/internal/continuous-co-review/`, and removed the unapproved waiver parser change from protected `shared-governance.ps1` mirrors.

**Trace**: FR-025, FR-030, FR-031, NFR-001, SC-019, SC-020.

## Watch Items

- Preserve the restored Iteration 001 five-adapter floor: T035, T036, T037, and all five T042 adapter implementations stay in scope unless a new human deferral is recorded.
- Preserve SC-012 manual real-host validation as a feature-closeout acceptance requirement; the maintainer performs the live run, while the crew ships only the runbook, planted fixture, and acceptance hook.
- Do not edit protected F-184 host-runtime, hook, provider, registry, refocus, shared-governance, mirrored `.specify/extensions/specrew-speckit/scripts/` surfaces, or `validate-governance.ps1`.
- Do not claim dedicated bug-hunter execution, strongest-class routing enforcement, known-traps workflow automation, or quality-drift automation as active in Iteration 001.
