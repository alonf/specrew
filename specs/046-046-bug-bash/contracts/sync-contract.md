# Contract: F-046 Boundary Sync Interface

**Feature**: `046-046-bug-bash`  
**Stability**: stable

## Boundary Sync Interface

The `sync-boundary-state.ps1` script is the primary automation surface for advancing boundary cursors and recording audit verdicts.

### Input Parameters
| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| ProjectPath | String | No | Defaults to current directory `.` |
| BoundaryType | String | Yes | Name of boundary or a supported prose alias |
| FeatureRef | String | No | Name of the active feature directory |
| IterationNumber | String | No | Active iteration number (e.g. `001`) |
| AuthCommitHash | String | No | The Git commit hash that authorized this boundary crossing |

### Supported Aliases
| Input | Translated Canonical Name | Notes |
| --- | --- | --- |
| `spec` | `specify` | |
| `specify` | `specify` | Canonical |
| `clarify` | `clarify` | Canonical |
| `plan` | `plan` | Canonical |
| `tasks` | `tasks` | Canonical |
| `before-implement` | `before-implement` | Canonical |
| `implement` | `review-signoff` | Maps the implementation phase to the review-signoff boundary |
| `review` | `review-signoff` | |
| `review-signoff` | `review-signoff` | Canonical |
| `retro` | `retro` | Canonical |
| `iteration` | `iteration-closeout` | |
| `iteration-closeout` | `iteration-closeout` | Canonical |
| `closeout` | `iteration-closeout` | |
| `feature` | `feature-closeout` | |
| `feature-closeout` | `feature-closeout` | Canonical |

### Behavior Guarantees (Invariants)
- **Atomicity**: Any call to `sync-boundary-state.ps1` with an active boundary enforcement context MUST update BOTH `session_state.boundary_type` and `boundary_enforcement.last_authorized_boundary` in `start-context.json` atomically in the same write pass.
- **Idempotency**: Multiple calls to `sync-boundary-state.ps1` for the same or backward boundaries MUST NOT write duplicate entries or throw errors about moving backward.
