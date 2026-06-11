# Drift Log: Iteration 009

**Schema**: v1

## Summary

**Total drift events**: 2
**Resolution rate**: 50% (1/2 resolved in-iteration; D-016 deferred to iteration 010)
**Specification drift**: 1 finding resolved in-iteration (D-015: delta-noise drowned the handover; fixed via
T007). 1 ARCHITECTURE pivot (D-016: the FR-022 handover approach evolves from refresh-frequency to
lean-pointer + resume reconciliation) deferred to iteration 010.

## Events

### D-015 - the rolling handover drowned in Specrew-managed scaffolding noise -> RESOLVED in-iteration (T007)

**Requirement**: FR-010 (the session delta), FR-022 (the handover surfaces useful content).

**Finding (surfaced in the live cross-host dogfood, 2026-06-11)**: `Get-SpecrewSessionDelta` took `git status`
order + `Select -First 12`, so the Specrew/Squad/Spec-Kit managed dirs (.agents/.claude/.copilot/.cursor/
.github/.specify/.squad/.specrew), which sort first, FILLED the file cap and capped OUT the user's real work
(specs/, workshop/). Every refresh surfaced the same ~53 scaffolding paths and never the spec/workshop files
- the handover was non-hollow but useless.

**Resolution (in-iteration, T007)**: partition managed vs user files; surface USER files first;
`--untracked-files=all` so untracked dirs expand to individual files; the renderer leads with the user's
files and notes the managed count, never lists it. Verified live: the bullet went from "53 uncommitted
[.agents/, ...]" to "7 changed user file(s) [.../spec.md, .../workshop/product-domain.md, ...] (+499
managed)". Committed `67ec20b3`.

### D-016 - ARCHITECTURE pivot: handover = lean pointer + RESUME reconciliation (not refresh-frequency) -> deferred to iteration 010

**Requirement**: FR-022 (the handover enables resume to restore useful context).

**Finding (maintainer-confirmed in the dogfood design review, 2026-06-11)**: iteration 009 built the handover
as a frequently-refreshed (PostToolUse mid-turn) source of truth. The dogfood reframed it: (a) the durable
state is already on disk (workshop lens files, the tree), so the per-tool-call refresh snapshots something
cheaply re-derivable on resume, at a `git status`-per-tool-call cost; (b) `SessionBootstrapManager` never
re-computes the delta on SessionStart - it REPLAYS the snapshot, so a stale last-stop (codex/copilot have no
PostToolUse; a hard kill fires no Stop) resumes to the wrong state, and the directive never says "read what
changed since the last stop and continue"; (c) the resume budget is already spent on the Specrew contract, so
the handover should be a LEAN pointer + grounding + non-durable intent, not heavy analysis. Plus a carried
bug: the workshop-skill `--source workshop` refresh stamps `from_host: host` (it does not pass `--host-kind`).

**Resolution (deferred to iteration 010)**: re-cast the handover as grounding + pointer; SessionStart
re-computes the cheap delta (one `git status`) + a reconciliation directive (read changed-since-last-stop +
continue); dial PostToolUse back (off/throttled); surface the workshop lens-progress + gate-stop tracking;
fix `from_host`. Canonical defer entry `f174-i009-defer-reconciliation-to-010` in `.squad\decisions.md`.

### Resolution Strategies (Unused)

The following resolution strategies remain available if drift is detected later in execution:

- **spec-updated**: Update the spec to reflect implementation choice
- **implementation-reverted**: Revert implementation to match spec
- **deferred**: Mark drift as deferred to next iteration
- **human-decision**: Escalate to Alon for resolution

### Notes

- Separately from the two spec drifts above, the dogfood found + fixed (as a CHORE, not iteration-009 scope)
  a codex hook-deploy crash: a corrupted array-shape `~/.codex/hooks.json` made `deploy-refocus-hooks.ps1`
  crash on the array's read-only `Length`; hardened to self-heal a non-map `hooks`. Committed `ec08752f`; its
  regression test is carried to iteration 010 with the T007 test debt.
