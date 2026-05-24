# Iteration Plan: 002

**Schema**: v1
**Spec**: [../../spec.md](../../spec.md)
**Status**: complete
**Capacity**: 6/20 story_points
**Started**: 2026-05-24
**Completed**: 2026-05-24

> **Retroactive backfill disclaimer**: Plan reconstructed at iter-002 closeout. SP estimates reflect post-hoc effort reconstruction matching the 22 findings closed by single commit `dcc4beb7`; "Actual" equals "Estimated" because no live tracking happened.

## Scope Summary

Focused **fix slice** addressing all 22 findings from iter-001's 4-agent deep review (3 BUG / 11 WARN / 8 NIT). No new features; no architectural change. Demonstrates the **review-gate-followed-by-fix-slice** methodology pattern.

| Requirement | Summary | Stories |
| --- | --- | --- |
| FR-002 | `Status='supported'` hosts must declare `AgentDir` — close Open-Closed regression | US4 |
| FR-006 | Auto-seed canonical on first `specrew start` | US6 |
| FR-007 | Sentinel marker (inline OR sidecar for Copilot) | US3 |
| FR-008 | User-edit preservation | US3 |
| FR-010 | Marker-file walk in remaining 2 sites | US4 |
| FR-012 | Documentation updates (contract rewrite + how-to + architecture + user-guide) | US5 |
| FR-013 | `tests/integration/crew-bootstrap-contract.tests.ps1` | (test) |

## Tasks

| Task | Title | Requirement | Story | Effort | Owner | Owner File Globs | Status | Agent | Actual | Verdict |
| ---- | ----- | ----------- | ----- | ------ | ----- | ---------------- | ------ | ----- | ------ | ------- |
| T001 | BUG tier — B-1 + B-2 + B-3 + A-1 cross-feature host-gate | FR-002 | US3, US4 | 2 | Implementer | hosts/copilot/host.psd1; scripts/internal/host-runtime-inventory.ps1; hosts/{*}/handlers.ps1; scripts/specrew-start.ps1 | done | claude | 2 | pass |
| T002 | WARN tier — W-1 contract rewrite + W-3 auto-seed + W-4 sentinel/sidecar + W-2 marker-walk | FR-006, FR-007, FR-008, FR-010, FR-012 | US3, US5, US6 | 2 | Implementer | hosts/_contract.md; hosts/_team-canonical.ps1; scripts/init/crew-bootstrap.ps1; scripts/init/agent-detection.ps1; hosts/{*}/handlers.ps1 | done | claude | 2 | pass |
| T003 | WARN tier — W-5 Antigravity filter + W-6 contract-presence tests + W-9/10/11 doc fixes | FR-013 | US4, US5 | 1 | Implementer | hosts/antigravity/handlers.ps1; tests/integration/{host-registry,crew-bootstrap-contract,host-coupling-firewall}.tests.ps1; docs/* | done | claude | 1 | pass |
| T004 | NIT cleanup — N-1..N-6 (dead code, stale comments, duplicated helpers, validator gap) | (cleanup) | (infra) | 1 | Implementer | scripts/init/agent-detection.ps1; hosts/_registry.ps1; hosts/_team-canonical.ps1; hosts/{claude,codex,antigravity}/handlers.ps1 | done | claude | 1 | pass |

## Effort Model

| Setting | Value | Notes |
| --- | --- | --- |
| Effort Unit | story_points | Same as iter-001. |
| Capacity per Iteration | 20 | Specrew project default. |
| Iteration Bounding | scope | All 22 findings in scope. |
| Time Limit (hours) | n/a | Scope-bounded. |
| Overcommit Threshold | 1.0 | 6/20 = 0.3 — well under threshold. |
| Defer Strategy | manual | 2 findings (W-7 + W-8) deferred to on-main work per "proposals always commit to main" rule. |
| Calibration Enabled | true | Backfill. |

## Concurrency Rationale

- Same roster; serial execution since all 4 tasks touch overlapping host-handler files.
- Single-commit close (`dcc4beb7`) — the iter-002 narrative IS "address the 22 findings," not granular commit-per-finding.

## Phase Baseline

| Phase | Estimated Effort | Notes |
| --- | --- | --- |
| Planning | 0 | Scope defined entirely by iter-001 review findings; no upfront plan. |
| Discovery/Spikes | 1 | Advisor-flagged Squad CLI parse risk on Copilot HTML comment → sidecar pattern designed mid-iteration. |
| Implementation | 4 | T001 + T002 + T003 + T004. |
| Review | 1 | Test-suite verification + manual sidecar verification. |
| Rework | 0 | No rework loops; advisor catch prevented Squad CLI parse risk before it shipped. |

## Routing Policy

| Lens Scope | Requested Reasoning / Review Class | Effective Class (when run) | Override / Approval Record | Notes |
| --- | --- | --- | --- | --- |
| Fix slice review | standard | Self-review + advisor consultation | Advisor caught W-4 implementation risk (HTML comment in Squad's charter.md) | Sidecar pattern substituted before close — see [iterations/002/review.md](./review.md). |

## Traceability Summary

- Task coverage: 4 tasks address all 22 findings + 1 advisor-caught validator gap. Mapping in [scope.md](./scope.md).
- Traceability check: PASS via finding-ID-to-task-ID matrix in scope.md.
- Overcommit guardrail: 6/20 SP = 30%. Plenty of headroom; fix slice intentionally small.

## Notes

- The single-commit close shape is correct for a focused fix slice; granular commits would have fragmented the "this iteration closes the 22 findings" narrative.
- W-7 (Proposal 108 missing on this branch) and W-8 (`proposals/INDEX.md` missing entry) deferred to on-main chore commits per the "proposals always commit to main, not feature branches" policy.
- Retroactive backfill — see disclaimer above.
