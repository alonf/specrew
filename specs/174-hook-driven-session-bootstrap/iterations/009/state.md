# Iteration State: 009

**Schema**: v1
**Current Phase**: implement
**Iteration Status**: executing
**Last Completed Task**: iter-9.1 — multi-source handover save (core `Update-SpecrewRollingHandover` + PostToolUse hook + workshop skill); T005 tests (new `HandoverHookPrimary.Tests.ps1` incl. the uncommitted-`notekeep.py` near-miss). Full bootstrap suite 21/21; start-recovery-flow PASS.
**Tasks Remaining**: none in scope — pending on-host re-test (cross-host exit/resume re-dogfood) + maintainer review. Deferred fast-follows (logged in plan.md): transcript-tail enrichment; gate-stop/workshop curated overlay.
**In Progress**: (none — implementation complete, awaiting review)
**Baseline Ref**: iteration 008 HEAD (cross-host validation closed; hollow-handover finding carried here)
**Updated**: 2026-06-11T00:00:00Z

## Implemented this session

- **T001** Section ownership in `HandoverStore.ps1`: `Get-SpecrewHandoverMechanicalSections` / `Get-SpecrewHandoverAgentOwnedSections`; `Write-SpecrewRollingHandover` writes fresh MECHANICAL content + preserves agent INTERPRETIVE overlay; `ConvertFrom` now exposes `from_commit`.
- **T002** `Get-SpecrewSessionDelta` (ProjectMetadataAccessor): branch/HEAD/subject + uncommitted files + new-commits-since, fail-safe.
- **T003** `specrew-handover-provider.ps1`: authors the mechanical sections from the delta every material stop; *What I just did* accumulates across the boundary window; real `from_host`.
- **T004** `specrew-bootstrap-provider.ps1`: surfaces hook-captured content as resume context (no false "hollow"); multi-line activity indented.
- **iter-9.1** multi-source core save — `Update-SpecrewRollingHandover` activated by the Stop hook, a new `PostToolUse` hook (mid-workshop refresh), and the workshop skill; dispatcher passes `--source-event`. The workshop-state-saving fix.
- **Safe replace**: unchanged single atomic write path — `[IO.File]::Replace` + `.old` backup + Set-Content fallback — used by BOTH the hook and agent authors.

## Execution Summary

- **Iteration 009 opened** (maintainer direction, 2026-06-11) to act on the iter-008 finding:
  the rolling-handover body is hollow in practice because authoring was agent-/gate-dependent.
- **Approach**: the Stop hook becomes the PRIMARY author — it captures the git/fs delta and
  writes the mechanical sections on every material stop (never hollow, host-universal); the
  iter-9.1 multi-source design (core + Stop + PostToolUse + workshop skill) makes the refresh
  fire mid-workshop too. See plan.md.
