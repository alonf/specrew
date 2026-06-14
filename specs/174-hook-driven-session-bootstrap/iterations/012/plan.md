# Iteration Plan: 012

**Schema**: v1
**Spec**: [../../spec.md](../../spec.md)
**Status**: planning
**Capacity**: 16/20 story_points
**Started**: 2026-06-14
**Completed**:

<!--
  Validator schema (canonical, enforced by validate-governance.ps1):
  - Iteration Status MUST be one of:
      planning | executing | reviewing | retro | complete | abandoned
  - Capacity format MUST be `<consumed>/<cap> <effort_unit>` with NO trailing prose on that line.
  - Task Status (in the Tasks table) MUST be one of:
      planned | in-progress | done | needs-rework | deferred | blocked
-->

> **DRAFT plan at the specify boundary.** This task table is the proposed plan; it is ratified at the plan +
> tasks verdicts (after the specify verdict). Documentation-only iteration — NO code/runtime change. Within the
> global 20 SP cap (no raise).

## Scope Summary

Reconcile the F-174 user-facing documentation to the shipped hook-driven session-continuity model (see
`state.md` Specify boundary, DR-1..DR-10). Delivers documentation for already-shipped, iter-011-closed behavior;
adds NO new feature requirements. Headlines: DR-1 (after `init`, start with no `specrew start`) and DR-2
(accurate cross-host handover), plus the DR-3 host-confirmation honesty fix.

## Tasks

| Task | Title | Requirement | Story | Effort | Owner | Owner File Globs | Status | Agent | Actual | Verdict |
| ---- | ----- | ----------- | ----- | ------ | ----- | ---------------- | ------ | ----- | ------ | ------- |
| T001 | README reconcile — flip the body to the hook-driven model: `init` then launch your host (no `specrew start`); rewrite "Switch your AI host mid-feature" to cross-host auto-resume via the rolling handover; add `.specrew/handover/session-handover.md` to durable artifacts; fix the false "Confirmed governed on Claude/Codex/Copilot" → Claude-confirmed, others pending (DR-1/DR-2/DR-3) | FR-006, FR-009 | US-1 | 3 | Implementer | `README.md` | planned | TBD | | |
| T002 | getting-started reconcile — say `init` deploys the hooks; "after init just launch your host, no `specrew start`" (antigravity exception); add `.specrew/handover/` + `.specrew/runtime/` to the tree; fix the resume note routed through `specrew start`; fix the host-confirmation claim (DR-1/DR-3/DR-9) | FR-028, FR-006 | US-1 | 2 | Implementer | `docs/getting-started.md` | planned | TBD | | |
| T003 | user-guide Session Continuity — bring current to iter-011: cross-host handover incl. the Claude-only rich-packet limit; verdict-integrity-on-resume ("awaiting your verdict"); per-host delivery (pointer vs inline); `specrew handover author`; fix "seven sections"→eight + the overstated three-way-rotation claim (DR-2/DR-7/DR-8) | FR-009, FR-022, FR-027 | US-3 | 3 | Implementer | `docs/user-guide.md` | planned | TBD | | |
| T004 | troubleshooting — add the iter-011 failure modes: 10K hook-output cap drop (`WARN PAYLOAD_OVERSIZE`), `SPECREW_MODULE_PATH` dev/dogfood silent-failure; replace stale `deploy-refocus-hooks.ps1` repair pointers with `specrew hooks status/install/remove`; verdict re-confirm on resume (DR-6/DR-7) | FR-028, FR-027 | US-3 | 2 | Implementer | `docs/troubleshooting.md` | planned | TBD | | |
| T005 | data-contracts + api-reference — document the handover FILE schema (`.specrew/handover/session-handover.md`: frontmatter + 8 `## ` sections + placeholder convention + atomic `.old` backup + gitignored) and add it to the Writer-contract list; document `specrew handover author` + `specrew hooks` commands; expand the `boundary_enforcement` verdict-integrity sub-schema (DR-4/DR-5) | FR-022, FR-026 | US-3 | 3 | Implementer | `docs/data-contracts.md`, `docs/api-reference.md` | planned | TBD | | |
| T006 | CHANGELOG + methodology pointer — announce the handover round-trip / auto-resume + the two new commands; remove the contradicted pre-iter-11 claims; add a methodology discovery pointer to the new session-continuity model (DR-10/DR-3) | FR-009 | US-3 | 1 | Implementer | `CHANGELOG.md`, `docs/methodology/**` | planned | TBD | | |
| T007 | Verification — markdownlint + doc token-parity (wrapper-docs-parity) green; re-run the doc-coverage assessment (or equivalent check) to confirm no HIGH gaps + no stale/false new-model claims remain (SC-1..SC-6) | SC-001 | US-3 | 2 | Implementer | `tests/**`, `docs/**` | planned | TBD | | |

Total planned: 16 SP (≤ 20 cap). Defer priority if it overruns: T006 (CHANGELOG) then T005 (contracts) — never
the two MUSTs (T001/T002/T003) or the honesty fix (T001).

## Effort Model

| Setting | Value |
| ------- | ----- |
| Effort Unit | story_points |
| Capacity per Iteration | 20 |
| Iteration Bounding | scope |
| Time Limit (hours) | n/a |
| Overcommit Threshold | 1.0 |
| Defer Strategy | manual |
| Calibration Enabled | true |

> Documentation-only iteration at the global default cap (20). No raise. Requirement IDs reference existing
> F-174 FRs (the docs deliver already-shipped behavior); SC-001 is used as the generic acceptance trace for the
> verification task.
