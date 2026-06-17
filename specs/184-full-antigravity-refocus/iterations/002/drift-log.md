# Drift Log: Iteration 002

**Schema**: v1

## Summary

**Total drift events**: 0
**Resolution rate**: 100% (0/0 resolved)
**Specification drift**: None detected

## Events

No specification drift detected during Iteration 002 specify preparation.

### Resolution Strategies (Unused)

- **spec-updated**: Update the spec to reflect implementation choice.
- **implementation-reverted**: Revert implementation to match spec.
- **deferred**: Mark drift as deferred to a later iteration.
- **human-decision**: Escalate to Alon for resolution.

### Notes

- The known manual-dogfood findings are not drift; they are the authorized
  iteration 002 scope.

#### Session-start integrity event (2026-06-17, runtime/tooling — not spec drift)

- **What happened**: At this Claude session's start (state files stamped
  `2026-06-17T15:23:42-43Z`, ~90s after the prior codex `Stop` at
  `2026-06-17T15:22:15Z`), the resume/SessionStart machinery regenerated the
  already-CLOSED iteration 001 artifacts from a blank scaffold: `state.md` was
  reset from `iteration-closeout` / `complete` (full T001-T008 execution
  summary) back to `before-implement` / `not-started`, and a new untracked
  `iterations/001/tasks-progress.yml` marked all 8 iter-001 tasks `pending`.
- **Root-cause hypothesis**: `.specrew/start-context.json` `session_state` was
  stale — still `iteration_number: 001` / `boundary_type: iteration-closeout`
  (it predates the iter-001 close `abf18b99` and the iter-002 specify
  `2d65f3ed`). The resume machinery therefore "resumed" the wrong, closed
  iteration and re-scaffolded it.
- **Remediation (this session)**: restored `iterations/001/state.md` from
  committed truth via `git checkout`; removed the spurious
  `iterations/001/tasks-progress.yml`; reconciled the mechanical cursor to
  `{iteration 002, plan}` via `sync-boundary-state.ps1` to stop recurrence.
- **Disposition**: this is a Specrew runtime/tooling defect to be FILED as a
  proposal/issue, not blind-fixed inside this plan boundary (file-don't-blind-fix
  discipline). It does not affect the iteration 002 plan content. Drift event
  count remains 0 (this is not specification drift).

#### Deferred follow-ups from the T006 real-host run (2026-06-17 — FILED, not blind-fixed; OUT of the 20 SP scope)

These are real-host findings surfaced during T006; none is specification drift and
none blocks iteration 002. Disposition is the maintainer's; do NOT blind-fix on the
184 branch (use GitHub issues / `main` proposals).

- **Proposal 180 (deterministic lifecycle gate) — the headline finding.** A weak
  coordinator (Gemini Flash) self-authorized `specify -> clarify -> plan` despite
  the persistent `AGENTS.md` instructions AND the refocus digest both saying a human
  verdict was required. Cooperative/textual enforcement does NOT hold a weak model;
  only a deterministic `PreToolUse` gate that blocks model self-approval would. This
  is the strongest motivation yet for Proposal 180 (explicitly out of iter-002 scope).
- **Proposal 142 (state-truth integrity).** `sync-boundary-state.ps1` output showed
  `verdict_history` populated with Flash's self-approvals, yet on-disk
  `start-context.json` later showed it empty/reset — the boundary ledger is not a
  reliable record; two writers appear to clobber it. Root-cause is post-184.
- **Antigravity transcript-parser gap.** The Antigravity handover's "Recent
  conversation" falls back to a raw transcript tail; Claude's parses cleanly. Bounded,
  cosmetic; candidate follow-up.
- **Concurrent-session false advisory.** A graceful `agy` exit does not clear the
  session marker, so a quick restart-within-the-hour trips a benign
  `concurrent_session` advisory that self-corrects on the next fire. Candidate fix:
  clear the marker on graceful `Stop`.
- **Cold-init dangling reference (Proposal 143).** The coordinator fragment instructs
  "read `.specrew/last-start-prompt.md` ... before acting," but `specrew init` does
  not create those files (only `specrew start` / the `PreInvocation` hook does). The
  hook self-healed them before the model read them on the normal path, so it did not
  trip — but the content contract is incomplete. Candidate: absence-tolerant fragment
  wording and/or greenfield/brownfield init orientation (Proposal 143).
