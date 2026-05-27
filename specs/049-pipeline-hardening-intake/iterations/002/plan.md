# Iteration Plan: 002

**Schema**: v1
**Spec**: [../../spec.md](../../spec.md)
**Status**: executing
**Capacity**: 4.0/20 story_points
**Started**: 2026-05-27
**Completed**:

<!--
  Validator schema (canonical, enforced by validate-governance.ps1):
  - Iteration Status MUST be one of:
      planning | executing | reviewing | retro | complete | abandoned
    (Common mistakes the validator REJECTS: `approved`, `in-progress`, `done`, `ready`.)
  - Capacity format MUST be `<consumed>/<cap> <effort_unit>` with NO trailing prose on that line.
    Append explanatory notes in the Notes section at the bottom instead.
  - Task Status (in the Tasks table) MUST be one of:
      planned | in-progress | done | needs-rework | deferred | blocked
    (Note `in-progress` uses a hyphen, not an underscore. `done` not `completed`.)
-->

## Summary

Iteration `002` is the approved documentation-only slice for Feature `049`. Execution remains bounded to tasks `T008-T011` and requirements `FR-006`, `FR-007`, `FR-015`, `FR-016`, and `FR-017`: create the durable troubleshooting guide, register it in `Specrew.psd1`, add onboarding cross-references, and capture acceptance evidence that explicitly teaches the Shape-5 committed-tree durability lesson. No runtime behavior, Proposal `063`, or Proposal `120` scope is authorized in this iteration.

## Scope Summary

| Requirement | Summary | Stories |
| ----------- | ------- | ------- |
| FR-006 | Author `docs/troubleshooting.md` covering PSGallery side-by-side caches, FileList omissions, deploy-script exceptions, stale-state recovery, and clean reinstall flows. | US2 |
| FR-007 | Register `docs/troubleshooting.md` in `Specrew.psd1` `FileList` in the same execution slice as guide creation. | US2 |
| FR-015 | Explain the naming distinction and operational boundary between `specrew update` and `Update-Module Specrew`. | US2 |
| FR-016 | Cross-reference `docs/troubleshooting.md` from `README.md`, `docs/getting-started.md`, and `docs/user-guide.md`. | US2 |
| FR-017 | Teach the Shape-5 lesson that accepted review evidence must match committed tree state, not working-tree-only state. | US2 |

## Governance Consistency Check

| Gate | Verdict | Notes |
| ---- | ------- | ----- |
| Spec Authority | PASS | Scope matches the approved Iteration `002` roadmap in `spec.md`, feature `plan.md`, and `tasks.md`. |
| Traceability | PASS | Every execution task maps directly to `FR-006`, `FR-007`, `FR-015`, `FR-016`, `FR-017`, `TG-006`, `TG-007`, and `SC-002` where applicable. |
| Capacity | PASS | Authorized slice is `4.0/20` story points, inside the feature plan's Iteration `002` 4-6 SP budget band. |
| Roadmap Discipline | PASS | Iteration `001` remains closed history; Iterations `003` and `004` remain untouched. |
| Before-Implement Readiness | PASS | Owner, effort, dependency order, evidence target, and bounded file surfaces are explicit for `T008-T011`. |

## Tasks

| Task | Title | Requirement | Story | Effort | Owner | Owner File Globs | Status | Agent | Actual | Verdict |
| ---- | ----- | ----------- | ----- | ------ | ----- | ---------------- | ------ | ----- | ------ | ------- |
| T008 | Draft `docs/troubleshooting.md` with recovery guidance, update-vs-module clarification, and Shape-5 lesson | FR-006, FR-015, FR-017, TG-006, TG-007, SC-002 | US2 | 1.75 | Implementer | `docs/troubleshooting.md` | done | Implementer | 1.75 | implemented |
| T009 | Register `docs/troubleshooting.md` in `Specrew.psd1` `FileList` | FR-007, TG-006, TG-007, SC-002 | US2 | 0.50 | Implementer | `Specrew.psd1` | done | Implementer | 0.50 | implemented |
| T010 | Add onboarding cross-references from primary docs to `docs/troubleshooting.md` | FR-016, TG-006, TG-007, SC-002 | US2 | 1.00 | Implementer | `README.md`, `docs/getting-started.md`, `docs/user-guide.md` | done | Implementer | 1.00 | implemented |
| T011 | Review documentation surfaces and record Iteration `002` acceptance evidence | FR-006, FR-007, FR-015, FR-016, FR-017, TG-006, TG-007, SC-002 | US2 | 0.75 | Reviewer | `docs/troubleshooting.md`, `README.md`, `docs/getting-started.md`, `docs/user-guide.md`, `Specrew.psd1`, `specs/049-pipeline-hardening-intake/iterations/002/quality/quality-evidence.md` | planned | Reviewer | — | — |

## Required Quality Gates

| Gate | Target | Notes |
| ---- | ------ | ----- |
| Troubleshooting coverage | required | `docs/troubleshooting.md` must cover cache cleanup, FileList omissions, deploy-script exceptions, stale-state recovery, clean reinstall flows, and the `specrew update` vs `Update-Module Specrew` distinction. |
| Discoverability | required | `README.md`, `docs/getting-started.md`, and `docs/user-guide.md` must all point readers to `docs/troubleshooting.md`. |
| Packaging durability | required | `Specrew.psd1` `FileList` must include `docs/troubleshooting.md` in the same bounded implementation slice. |
| Shape-5 lesson retention | required | The guide and review evidence must both reinforce that accepted review evidence must match committed tree state. |
| Acceptance evidence | required | `T011` records Iteration `002` verification in `specs/049-pipeline-hardening-intake/iterations/002/quality/quality-evidence.md`. |

## Planned Execution Order

1. **T008 first** — establish the troubleshooting guide and the exact Shape-5 / command-boundary wording that downstream files will reference.
2. **T009 and T010 next** — once the guide exists, manifest registration and onboarding discoverability can land as the second implementation boundary.
3. **T011 last** — reviewer verifies the exact shipped surfaces and records evidence only after `T008-T010` are present on the committed tree under review.

## Boundary Commit Cadence

| Commit Group | Tasks | Why this boundary exists |
| ------------ | ----- | ------------------------ |
| Docs baseline | T008 | Creates the substantive guide content and locks the canonical troubleshooting narrative. |
| Packaging + discoverability | T009-T010 | Keeps FileList durability and onboarding cross-references coupled to the new guide without mixing in review evidence. |
| Review evidence | T011 | Preserves an auditable acceptance-evidence commit group after the implementation surfaces are present. |

## Dependencies

- `T008` is the prerequisite for the whole iteration because the manifest entry, onboarding links, and review evidence all depend on the guide existing.
- `T009` and `T010` both depend on `T008` and can proceed in either order after the guide content is stable.
- `T011` depends on `T008-T010` because review evidence must validate the committed documentation set, not a partial working tree.

## Effort Model

| Setting | Value | Notes |
| ------- | ----- | ----- |
| Effort Unit | story_points | Unit used in task effort, capacity, and retro variance. |
| Capacity per Iteration | 20 | Maximum planned effort before overcommit guidance applies. |
| Iteration Bounding | scope | `scope` keeps Iteration `002` fixed to the approved documentation slice only. |
| Time Limit (hours) | n/a | Only applies when iteration bounding is `time`. |
| Overcommit Threshold | 1.0 | Warn planners when total estimated effort exceeds 20 story_points (capacity 20 x threshold 1.0). |
| Defer Strategy | manual | Any future deferral would require explicit replanning; none is authorized inside this slice. |
| Calibration Enabled | true | Retrospective variance should be recorded after execution completes. |

## Concurrency Rationale

- Current roster snapshot: Implementer and Reviewer are the only active owners for this iteration slice.
- Technology and scope signals: Markdown documentation, manifest registration, and review evidence packaging dominate; no code-path or runtime behavior changes are in scope.
- Task dependency graph: `T008` → (`T009`, `T010`) → `T011`.
- Workstream separability: limited but real after `T008`; `T009` touches only `Specrew.psd1` while `T010` touches the onboarding docs.
- Shared-surface conflict risk: low to moderate because `T008` and `T010` both depend on the exact wording in `docs/troubleshooting.md`.
- Recommendation: execute the slice in the documented dependency order, using the commit groups above rather than parallelizing the first or last boundary.

## Phase Baseline

| Phase | Estimated Effort | Notes |
| ----- | ---------------- | ----- |
| Planning | 0.00 | Iteration packaging is already complete; this artifact is the execution-ready plan for the before-implement gate. |
| Discovery/Spikes | 0.00 | No separate spike is authorized; Iteration `001` retro and the approved spec already bounded the docs slice. |
| Implementation | 3.25 | Sum of Implementer tasks `T008-T010`. |
| Review | 0.75 | Reviewer task `T011` records acceptance evidence for the shipped documentation surfaces. |
| Rework | 0.00 | No pre-allocated rework buffer; any review finding would reopen against the bounded scope explicitly. |

## Traceability Summary

- Requirement scope for this iteration: `FR-006`, `FR-007`, `FR-015`, `FR-016`, `FR-017`.
- User stories represented in current scope: `US2` only.
- Approved task scope for this iteration: `T008-T011` only.
- Overcommit guardrail: `4.0` story_points consumed of `20` story_points capacity (`0.20x` capacity).
- Retro carry-forward: Iteration `001`'s Shape-5 lesson is captured here as documentation truthfulness and committed-tree evidence discipline, not as new validator/runtime scope.

## Notes

- Iteration `001` remains closed historical context and MUST NOT be reopened by this plan.
- Iteration `002` remains documentation-only: `docs/troubleshooting.md`, onboarding cross-references, `Specrew.psd1` registration, and the Shape-5 lesson/evidence path.
- Iteration `003` persona-intake work and Iteration `004` Proposal `120` validator work remain explicitly out of scope.
- Detailed task wording remains authoritative in `specs/049-pipeline-hardening-intake/tasks.md`; this plan packages the already approved Iteration `002` slice into an execution-ready before-implement artifact.
