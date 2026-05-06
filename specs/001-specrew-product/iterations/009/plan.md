# Iteration Plan: 009

**Schema**: v1
**Spec**: [../../spec.md](../../spec.md)
**Status**: retro
**Capacity**: 7/20 story_points
**Started**: 2026-05-07
**Completed**:

## Summary

Iteration 009 is a corrective governance slice that closes the reviewer-closeout enforcement hole exposed after Iteration 008. The work does not add new reviewer artifact formats; it makes the existing reviewer closeout packet mandatory for the active code-touching iteration, aligns the contract with the implemented scaffolder, and restores Iteration 008 to an immutable snapshot instead of retroactively folding later work into it.

This iteration exists specifically to avoid FR-054 drift. Rather than mutating Iteration 008's closed packet, Iteration 009 carries the validator changes, contract update, regression coverage, and its own reviewer closeout packet as a separate governed slice.

---

## Scope

### In Scope

- Enforce reviewer closeout packet presence for the latest code-touching iteration per feature, or any explicitly targeted iteration
- Update the iteration-artifact contract so reviewer packet requirements are normative
- Add regression coverage for missing-reviewer-packet rejection and accepted closeout after scaffold generation
- Realign existing governance tests to the new reviewer-closeout requirement
- Persist Iteration 009's own reviewer closeout packet without rewriting Iteration 008

### Out of Scope

- Multi-lane validation strategy (FR-042) now deferred to the next iteration after this corrective slice
- New reviewer artifact types beyond the existing packet
- Repo-root hygiene cleanup for the stray untracked `package.json`

---

## Requirements Traceability

| Spec Ref | Requirement | Planned Deliverables | Owner |
|----------|-------------|----------------------|-------|
| FR-046 | Code map closeout evidence | validator enforcement + reviewer packet generation for code-touching closeout | Reviewer |
| FR-049 | Coverage evidence closeout | validator enforcement + packet generation contract alignment | Reviewer |
| FR-052 | Reviewer index replay/triage surface | validator enforcement + packet generation contract alignment | Reviewer |
| FR-053 | Reviewer diagrams or explicit omissions | validator enforcement + packet generation contract alignment | Reviewer |
| FR-054 | Immutable reviewer snapshots | keep Iteration 008 unchanged and attribute the enforcement work to Iteration 009 instead | Planner + Reviewer |

---

## Tasks

| Task | Title | Requirement | Story | Effort | Owner | Status | Agent | Actual | Verdict |
| ---- | ----- | ----------- | ----- | ------ | ----- | ------ | ----- | ------ | ------- |
| T-901 | Enforce reviewer closeout packet presence for active code-touching iterations | FR-046, FR-049, FR-052, FR-053 | US-6 | 2 | Reviewer | done | copilot-agent | 2 | pass |
| T-902 | Update iteration-artifact contract for reviewer closeout enforcement | FR-046, FR-049, FR-052, FR-053 | US-6 | 1 | Planner | done | copilot-agent | 1 | pass |
| T-903 | Add regression coverage and fixture updates for reviewer closeout governance | FR-046, FR-049, FR-052, FR-053 | US-6 | 2 | Implementer | done | copilot-agent | 2 | pass |
| T-904 | Preserve Iteration 008 immutability and generate Iteration 009 reviewer closeout packet | FR-054, FR-046, FR-049, FR-052, FR-053 | US-6 | 2 | Reviewer | done | copilot-agent | 2 | pass |

**Planned Total**: 7 story_points

---

## Effort Model

| Setting | Value | Notes |
| ------- | ----- | ----- |
| Effort Unit | story_points | Unit used in task effort, capacity, and retro variance. |
| Capacity per Iteration | 20 | Maximum planned effort before overcommit guidance applies. |
| Iteration Bounding | scope | Keep the corrective slice fixed to reviewer closeout enforcement and packet immutability. |
| Time Limit (hours) | n/a | Not used for this scope-bounded corrective iteration. |
| Overcommit Threshold | 1.0 | No overcommit expected at planned capacity 7/20. |
| Defer Strategy | manual | If FR-042 work remains, keep it explicitly deferred rather than widening this corrective slice. |
| Calibration Enabled | true | Retro should confirm whether reviewer-closeout enforcement remains a small governance-only slice. |

---

## Phase Baseline

| Phase | Estimated Effort | Notes |
| ----- | ---------------- | ----- |
| Planning | 1 | Isolate the immutability breach and rescope the fix into its own iteration |
| Implementation | 3 | Validator enforcement, contract update, test coverage, and packet realignment |
| Review | 2 | Governance/regression validation plus reviewer closeout packet generation |
| Rework | 1 | Buffer for validator scope or fixture mismatches |

---

## Acceptance Checkpoints

1. The validator rejects a retro/complete code-touching iteration that lacks `code-map.md`, `coverage-evidence.md`, `reviewer-index.md`, or `review-diagrams.md`.
2. The validator still accepts historical iterations when they are not the latest iteration in a feature and were never intended to carry the reviewer packet.
3. A new regression test proves both the failing and accepted reviewer-closeout enforcement paths.
4. Iteration 008 remains an immutable snapshot of commit `8bcb28f` while Iteration 009 carries the enforcement work and its own reviewer packet.

## Notes

- This slice is a corrective follow-up created because the original retroactive Iteration 008 fix violated FR-054 immutability.
- Iteration 010 resumes the planned FR-042 multi-lane validation strategy after this closeout-enforcement repair lands cleanly.
