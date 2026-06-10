# Iteration State: 008

**Schema**: v1
**Current Phase**: implement (T048 done; T049 next)
**Iteration Status**: executing
**Last Completed Task**: T048 — docs reposition `specrew start` as optional (README "Two ways to start" + getting-started section 4 intro + the stale hook note + host-pick line + CHANGELOG). Stale "hook doesn't drive / prefer specrew start" claims removed; user docs now say the hook drives (confirmed Claude/Codex/Copilot) and `specrew start` is the optional host-selector / Antigravity path.
**Tasks Remaining**: T049 intake-at-init, T050 handover validation.
**In Progress**: none (T049 next).
**Baseline Ref**: iter-7 HEAD + this session's multi-host completion (codex format fixes, banner, version)
**Updated**: 2026-06-10T00:00:00Z

## Execution Summary

- **Iteration 008 opened** (maintainer direction, 2026-06-10) on the all-hosts-green baseline: claude / codex
  / copilot observed governed via the SessionStart hook; antigravity launcher-only by design.
- **iter-7 FR-024 multi-host completion landed this session** (the green baseline iter-8 builds on): codex
  entered the parity set after TWO codex-format fixes — (A) `~/.codex/hooks.json` needed codex's
  `{ hooks: { <Event> } }` wrapper (it had top-level event keys, so codex never ran the hook); (B) the
  dispatcher emitted the flat `{ additionalContext }` but codex injects context ONLY via
  `{ hookSpecificOutput: { hookEventName, additionalContext } }` (so the hook ran but its output was dropped).
  Both fixed + validated live (codex rendered the banner + drove the design workshop). Plus the mandatory
  banner hoist+expand (FR-004) and real `-SpecrewVersion` threading.
- **Spec amended**: FR-025 (user-profile intake capturable at `specrew init`, guarded interactive).
- **Scope**: T048 docs (specrew start optional) -> T049 intake-at-init -> T050 handover validation.
