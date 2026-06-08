# DevOps Operations Workshop Record

**Lens**: devops-operations · **Depth**: light · **Confirmation**: human-confirmed
**Facilitated**: 2026-06-08.

```text
Existing F-171 deployment loop
  -> register/update SessionStart B2 bootstrap provider
  -> register SessionEnd handover writer
  -> preserve managed marker, kill switch, breaker, dedupe, uninstall behavior
  -> NO new install path
```

## Decision 1 - deployment + rollout

**Chosen: option 2 - reuse F-171's deployment loop + kill switch + managed markers.**

- The B2 bootstrap provider and the SessionEnd handover writer are registered **through the
  existing F-171 hook deployment loop**. No new installer / install path (LIR-008).
- The F-171 **kill switch** can disable bootstrap; **managed markers** keep updates from
  clobbering user edits; rollout/rollback ride F-171's existing controls.
- Rejected: option 1 (separate install path - more surface, violates "no new install
  path"); option 3 (manual opt-in - friction, contradicts the primary-bootstrap intent).
