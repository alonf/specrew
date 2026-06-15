# Iteration State: 009

**Schema**: v1
**Current Phase**: iteration-closeout
**Iteration Status**: complete
**Last Completed Task**: T007 — delta-noise fix (dogfood-driven): `Get-SpecrewSessionDelta` partitions managed vs user files, surfaces user files first (verified live). CLOSED accepted-with-qualification after the live cross-host dogfood; the resume-reconciliation + PostToolUse re-think (D-016) deferred to iteration 010.
**Tasks Remaining**: none — T001-T007 all done; cross-host dogfood (codex/claude/copilot) DONE 2026-06-11. The resume-reconciliation gap + PostToolUse dial-back + tracking surfacing + `from_host` fix + carried tests are iteration 010 (defer entry `f174-i009-defer-reconciliation-to-010`).
**In Progress**: (none — iteration CLOSED accepted-with-qualification)
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
