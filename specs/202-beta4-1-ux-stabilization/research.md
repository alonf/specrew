# Research: 202 beta4.1 UX stabilization

Phase 0 decisions. Each one was settled at the workshop or at the design-analysis co-design. Two facts stay open and are measured by T001.

| Topic | Decision | Rationale | Alternatives considered |
| --- | --- | --- | --- |
| Host input normalization | One shared `ConvertTo-SpecrewTurnRecord`. Hosts declare field maps and origin rules as data, and may name one transform from a shared registry (DA-1) | No adapter scripts exist today; two divergent normalizers exist; data bindings keep a new host cheap | Per-host adapter scripts; leaving normalization in the dispatcher |
| Journal concurrency | A share mode permitting concurrent appends first; a per-write lock on that journal only if case (e) shows torn or interleaved lines | Workshop lens 4 and code lens 7; the 199 concurrency rule amended | Generic lock framework (rejected); retry only (a backup, not the fix) |
| Degraded trust | Precise fail-closed through a per-process outage buffer | Workshop security lens, option b | Blanket fail-closed (today's deadlock); fail open |
| Presentation memory | Per (session, crossing id). Context gap = changed crossing id or reviewed artifacts, SessionStart new/resume/compact, or 8 hours. HEAD alone is not a gap | DA-2 amended: bookkeeping commits caused repaints | Turn-counter keying (today's failure) |
| Orientation order | Supplied as system output on the session's first prompt; no agent duplicate on direct-display hosts | DA-3: no host can reorder an emitted reply | A Stop-time demand (today's failure) |
| Draft path | stdin into `declare-turn-end.ps1`, stored per session; explicit UTF-8 | DA-4; B4F-065 encoding history | The agent computes the path |
| Feature identity | In-flight controller or crossing, then the pointer for this branch, then the branch as a hint; always disclosed | DA-5: the branch is not the feature | Branch-first reconciliation (the original FR-018) |
| Tuning | Retry at most 5 attempts within 250 ms; long gap 8 hours | Agreed at design-analysis | — |

## Open facts (T001 measures them in scratch directories, never in a governed worktree)

1. Per validated host: does the hook payload carry a session id? (DA-4: if not, that host's draft path is per-token.)
2. Per validated host: which hook output is displayed to the user directly? (DA-3: where it is, the orientation is system-rendered and the agent does not render it.)

Any host that cannot meet the agreed design on these facts is reported at the before-implement boundary.
