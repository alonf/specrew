# Contract: Hook-Driven Session Bootstrap Public Surface

**Feature**: 174-hook-driven-session-bootstrap
**Stability**: pre-1.0

## Bootstrap Directive (`PSCustomObject`)

The data-oriented instruction emitted by `DirectiveEngine` and injected by the
SessionStart B2 provider. Fields: `mode`, `sources`, `required_reads`, `render_first`
(always `true`), `menu_intent`, `validation_findings`, `dedupe_key`, plus session metadata.
The hook never collects choices; the agent is the interactive consumer.

## Component functions (illustrative signatures — final names pinned in tasks)

| Symbol | Signature | Purpose | Errors |
| --- | --- | --- | --- |
| `Invoke-SpecrewSessionBootstrap` | `(hookEvent) -> directive` | orchestrate B2 bootstrap | fail-open: returns full-mode directive |
| `Resolve-SpecrewBootstrapMode` | `(handoverState, anchorState, findings) -> {mode,reason}` | pure mode decision | never throws |
| `Test-SpecrewHandoverValidity` | `(handover, projectState) -> {valid,findings[]}` | validate handover vs project | never throws |
| `Test-SpecrewAnchorValidity` | `(anchor, projectState) -> {valid,findings[]}` | merged/closed/portability | never throws |
| `New-SpecrewBootstrapDirective` | `(mode, sources, findings) -> directive` | build directive | never throws |
| `Invoke-SpecrewSessionEndHandover` | `(event) -> handoverPath` | write-only handover | no `git add -A`; non-blocking |
| `Write-SpecrewHookJournalRecord` | `(record) -> void` | append classification record | best-effort, journaled |

## SessionStart Marker (`PSCustomObject`, local-only)

`{ started_at, host, project_root, branch, head_commit }` — written via the F-171 journal
surface, never committed, never rewrites the handover on startup.

## Invariants

- `render_first` is always `true`; a structured picker is offered only after the prose
  orientation + menu are rendered (FR-004/FR-020), and only on hosts where FR-005 evidence
  shows it does not hide the text.
- The SessionEnd hook is **write-only** by default: no `git add`, commit, or push.
- External state (handover next-step, anchor) is **advisory** and never auto-authorizes a
  lifecycle boundary (Rule 1; security d2).
- Invalid/stale/untrusted state degrades to full bootstrap (fail-open availability), never
  to silent resume or unauthorized continuation (fail-closed authority).
- The F-171 dispatcher is reused unchanged (B1/B3 regression safety).
