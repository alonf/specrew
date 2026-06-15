# Review Diagrams: Iteration 009

**Schema**: v1
**Reviewed**: 2026-06-11

## Multi-source rolling-handover save (the iteration-009 architecture)

```text
  Stop hook ──────┐
  PostToolUse ────┼──> specrew-handover-provider.ps1 ──> Update-SpecrewRollingHandover  (HandoverStore.ps1)
  workshop skill ─┘      (--source-event / --source)          │
                                                              ├─ material-change gate (boundary moved OR tracked change)
                                                              ├─ Get-SpecrewSessionDelta  (ProjectMetadataAccessor.ps1)
                                                              │     └─ partition managed vs USER files (T007) -> USER files lead
                                                              ├─ mechanical sections  (hook-authored, refreshed every stop)
                                                              ├─ interpretive sections (agent-authored, preserved if authored)
                                                              └─ atomic write: [IO.File]::Replace + .old backup + fallback
```

## Section ownership

```text
  MECHANICAL (hook-owned, always refreshed)   INTERPRETIVE (agent-owned, preserved)
  -----------------------------------------   -------------------------------------
  What I just did (accumulates across window)  Open questions
  Why I'm stopping                             Working hypothesis
  Recommended next-immediate-step              (preserved across hook stops only when
  Context the receiving host needs              authored_by_agent lists the section)
```

## Resume today vs the iteration-010 gap (D-016)

```text
  SessionStart ──> reads the handover SNAPSHOT  (SessionBootstrapManager does NOT re-compute the delta)
                                                       |
                                                       v
                          iteration 010: re-compute the cheap delta (one git status)
                                         + reconciliation directive ("changed since last stop -> read + continue")
                                         + dial PostToolUse back (durable state is on disk)
```
