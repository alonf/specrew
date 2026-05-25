# Iteration Plan: 001

**Schema**: v1
**Spec**: [../../spec.md](../../spec.md)
**Status**: complete
**Capacity**: 18/20 story_points
**Started**: 2026-05-23
**Completed**: 2026-05-24

> **Retroactive backfill disclaimer**: This iteration plan was reconstructed at closeout (2026-05-24) from the 24 architectural commits + design proposal. SP estimates reflect post-hoc effort reconstruction matching scope, not live planning. "Actual" equals "Estimated" because no live tracking happened — variance is necessarily 0. The "review-signoff" verdict honestly captures iter-001 closing **with 22 known findings** from the 4-agent deep review (BUG/WARN/NIT mix); iter-002 is the focused fix slice that closes them.

## Scope Summary

Implements **architectural substrate** for F-044: per-host package registry, 4 host packages with handlers, registry-driven shims replacing host-coupled scripts, and Proposal 108 Slices 1-9 (init split + 5th contract function + canonical team source-of-truth).

| Requirement | Summary | Stories |
| --- | --- | --- |
| FR-001 | Canonical team source-of-truth at `.specrew/team/agents/<role>.md` | US1, US3 |
| FR-003 | 5 contract functions per host (incl. `Install-<Kind>CrewRuntime`) | US1-4 |
| FR-004 | `InstallCrewRuntime` contract slot in `HostContractFunctionMap` | US4 |
| FR-005 | `Invoke-CrewBootstrap` dispatcher | US1-3 |
| FR-009 | `scripts/specrew-init.ps1` split into orchestrator + 9 focused files | US5 |
| FR-011 | Adding a new host requires zero edits to existing files | US4 |
| FR-002 | `AgentDir` enforcement (partial — Copilot missing, closed iter-002) | US4 |
| FR-006 | Auto-seed canonical on first `specrew start` (deferred to iter-002) | US6 |
| FR-007 | Sentinel preservation (partial — inline only, sidecar added iter-002) | US3 |
| FR-008 | User-edit preservation (deferred to iter-002) | US3 |
| FR-010 | Marker-file walk (partial — Slices 5/8 only, completed iter-002) | (infra) |
| FR-012 | Documentation updates (partial — completed iter-002) | (infra) |

## Tasks

| Task | Title | Requirement | Story | Effort | Owner | Owner File Globs | Status | Agent | Actual | Verdict |
| ---- | ----- | ----------- | ----- | ------ | ----- | ---------------- | ------ | ----- | ------ | ------- |
| T001 | Phase A — per-host package registry + 4 manifests | FR-004, FR-011 | US4 | 2 | Implementer | hosts/_registry.ps1; hosts/{copilot,claude,codex}/host.psd1 | done | claude | 2 | pass |
| T002 | Phase B — per-host handler implementations (4 contract functions × 4 hosts) | FR-003 | US1, US2, US4 | 2 | Implementer | hosts/{copilot,claude,codex,antigravity}/handlers.ps1 | done | claude | 2 | pass |
| T003 | Phase C — replace host-coupled scripts with registry-driven shims (3 commits) | FR-011 | US4 | 3 | Implementer | scripts/internal/{host-flag-translation,host-runtime-inventory,coordinator-prompt-surgery}.ps1 | done | claude | 3 | pass |
| T004 | Phase D — manifest-driven detect-hosts + Antigravity graduation + 3 ship-blocker fixes | FR-002, FR-011 | US2, US4 | 2 | Implementer | scripts/internal/detect-hosts.ps1; hosts/antigravity/* | done | claude | 2 | pass |
| T005 | Slices 1-4 — extract _utilities, preflight, template-deploy, spec-kit-deploy from specrew-init.ps1 | FR-009 | US5 | 2 | Implementer | scripts/init/{_utilities,preflight,template-deploy,spec-kit-deploy}.ps1 | done | claude | 2 | pass |
| T006 | Slices 5-8 — extract dependency-install, agent-detection, squad-deploy, post-bootstrap-output | FR-009, FR-010 | US5 | 2 | Implementer | scripts/init/{dependency-install,agent-detection,squad-deploy,post-bootstrap-output}.ps1 | done | claude | 2 | pass |
| T007 | Slice 9 — canonical `.specrew/team/` source-of-truth + 5th contract function + 4 Install handlers | FR-001, FR-003, FR-005 | US1-4 | 4 | Implementer | hosts/_team-canonical.ps1; scripts/init/crew-bootstrap.ps1; hosts/{*}/handlers.ps1 Install-* | done | claude | 4 | pass |
| T008 | Slice 9 finalization — architecture diagram + implementation review + how-to update | FR-012 (partial) | US5 | 1 | Implementer | docs/architecture/host-package-architecture.md; docs/design/proposal-108-slice-9-review.md; docs/how-to/add-a-new-host.md | done | claude | 1 | pass |
| T009 | 4-agent deep review at iter-close (22 findings) | (review) | (review) | 0 | Reviewer | (review only, no source ownership) | done | claude | 0 | needs-rework |

## Effort Model

| Setting | Value | Notes |
| --- | --- | --- |
| Effort Unit | story_points | Unit used in task effort, capacity, and retro variance. |
| Capacity per Iteration | 20 | Specrew project default. |
| Iteration Bounding | scope | Architectural slice; Phase A-D + Slices 1-9 are bounded by Proposal 108. |
| Time Limit (hours) | n/a | Scope-bounded. |
| Overcommit Threshold | 1.0 | 18/20 = 0.9 — under threshold; T009 deep review is 0 SP (overhead). |
| Defer Strategy | manual | 7 of 12 FRs closed in iter-001; 5 deferred to iter-002 cleanup. |
| Calibration Enabled | true | Backfill — no live calibration; future iterations track honestly. |

## Concurrency Rationale

- Roster snapshot: Spec Steward, Planner, Implementer, Reviewer, Retro Facilitator.
- 24 commits across 2 calendar days; serial execution because each Phase/Slice depends on the prior (Phase B needs Phase A's registry; Slice 9 needs Slices 1-8's init split).
- 4-agent parallel deep review (T009) is the only parallel work — read-only review across lint/code/docs/architecture dimensions.

## Phase Baseline

| Phase | Estimated Effort | Notes |
| --- | --- | --- |
| Planning | 0 | No upfront plan — design happened iteratively per phase in conversation; spec authored retroactively at closeout. |
| Discovery/Spikes | 1 | Proposal 108 design + design doc 0aa3ff51. |
| Implementation | 17 | T001 through T008. |
| Review | 0 | 4-agent deep review is closeout overhead (T009). |
| Rework | 0 | All findings deferred to iter-002 fix slice; no in-iteration rework loops. |

## Routing Policy

| Lens Scope | Requested Reasoning / Review Class | Effective Class (when run) | Override / Approval Record | Notes |
| --- | --- | --- | --- | --- |
| Architectural review | strongest-available (multi-agent) | 4-agent parallel deep review (lint+tests / code quality / docs accuracy / architecture coherence) | n/a | The 4-agent parallel review IS the strongest-available review class for this slice; surfaced 22 findings, all addressed in iter-002. |

## Traceability Summary

- Task coverage: 8 implementation tasks + 1 review task cover all 12 FRs (FR-002, FR-006, FR-007, FR-008, FR-010, FR-012 partial — closed in iter-002; FR-013 closed in iter-002).
- Traceability check: PASS via [scope.md](./scope.md) commit-attribution table.
- Overcommit guardrail: 18/20 SP = 90% capacity. Under threshold (1.0). Architectural-payoff iterations may legitimately run hot; future iterations should target ~70% to leave headroom for review-driven rework.

## Notes

- This iteration was developed on the `multi-host-integration-refactor` branch alongside F-043. Cross-feature entanglement documented in [scope.md](./scope.md). Net commit count this branch ahead of main: 24 architectural + 4 F-043 + 1 iter-002 + 1 iter-003 + retroactive artifact commits.
- Review verdict: APPROVED-WITH-CONDITIONS — feature-closeout gated on iter-002 closing the 22 findings (which it did).
- Retroactive backfill — see disclaimer above. Future similar slices should plan iteration before writing code, not after.
