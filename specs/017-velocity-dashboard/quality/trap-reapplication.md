# Trap Reapplication: Feature 017 Velocity Dashboard

## Reapplied Traps

| Trap | Result | Evidence |
| --- | --- | --- |
| dashboard-truthfulness | reapplied | dashboard renderer derives shipped effort from canonical iteration history and validator emits `WARN [dashboard]` for roadmap drift / missing artifacts |
| test-integrity | reapplied | `tests/integration/feature-017-dashboard-core.ps1` exercises the user-facing command paths rather than only internal helpers |
| path-resolution | reapplied | dashboard scripts resolve project paths through `Resolve-ProjectPath` from shared governance |

## Notes

- The dashboard never writes a mutable "current status" file during ad hoc use.
- Iteration and feature closeout snapshots are preserved once captured.
