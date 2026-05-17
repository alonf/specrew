# Boundary-Event State Synchronization API

**Feature**: 020-session-state-durability  
**Script**: `scripts/internal/sync-boundary-state.ps1`  
**Purpose**: Helper script to atomically update session-state files at lifecycle boundaries

---

## API Contract

### Function Signature

```powershell
sync-boundary-state.ps1 `
  -BoundaryType <string> `
  -FeatureNumber <string> `
  [-IterationNumber <int>] `
  [-TaskId <string>] `
  [-AuthCommitHash <string>] `
  [-Verbose]
```

### Parameters

| Parameter | Type | Required | Validation | Description |
| --------- | ---- | -------- | ---------- | ----------- |
| `BoundaryType` | String (enum) | Yes | One of: `specify`, `clarify`, `plan`, `tasks`, `review-signoff`, `iteration-closeout`, `feature-closeout` | Lifecycle boundary being crossed |
| `FeatureNumber` | String | Yes | Pattern: `^\d{3}$` (e.g., "020") | Feature number |
| `IterationNumber` | Int | No | Range: 1-99 | Current iteration; required if BoundaryType is `iteration-closeout` |
| `TaskId` | String | No | Pattern: `^T\d{3}$` (e.g., "T005") | Current task; optional for all boundaries |
| `AuthCommitHash` | String | No | Pattern: `^[0-9a-f]{7,40}$` | Git commit hash of boundary event; recommended for auditability |
| `Verbose` | Switch | No | N/A | Enable verbose logging |

### Return Values

- **Exit Code 0**: All session-state files updated successfully
- **Exit Code 1**: One or more file updates failed (partial write prevented via write-temp-then-rename)
- **Exit Code 2**: Invalid parameters (validation failed)

### Output

**On Success**:
```
Session-state synchronized: boundary=tasks, feature=020, iteration=1
Updated files:
  .specrew/last-start-prompt.md
  .specrew/start-context.json
  .squad/identity/now.md
  .squad/decisions.md
```

**On Failure**:
```
ERROR: Failed to update .specrew/last-start-prompt.md: disk full
Session-state files may be inconsistent. Run stale-state detection at next specrew start.
```

---

## Behavior Specification

### File Update Logic

For each of four session-state files:

1. Read current content (if file exists)
2. Generate new content based on boundary type and parameters
3. Write new content to `.tmp` file in same directory
4. Rename `.tmp` file to target file (atomic operation)
5. If rename fails, preserve original file and log error

**Cross-File Atomicity**: Best-effort only. Files updated sequentially. If system crashes mid-sync, some files may be updated and others not. Stale-state detection at `specrew start` compensates by identifying inconsistencies.

### Content Templates

#### `.specrew/start-context.json`

```json
{
  "active_feature": "<FeatureNumber>",
  "current_boundary": "<BoundaryType>",
  "iteration_number": <IterationNumber or null>,
  "task_id": "<TaskId or null>",
  "recorded_at": "<ISO8601 timestamp>",
  "last_completed_commit_hash": "<AuthCommitHash or null>"
}
```

#### `.specrew/last-start-prompt.md`

```markdown
---
active_feature: "<FeatureNumber>"
current_boundary: "<BoundaryType>"
recorded_at: "<ISO8601 timestamp>"
---

# Welcome Back: Feature <FeatureNumber> - <Feature Name>

**Current State**: <Human-readable boundary description>

**Last Completed**: <Previous boundary> at <timestamp>

**Next Actions**:
- <Suggested next step 1>
- <Suggested next step 2>
```

#### `.squad/identity/now.md`

```markdown
# Squad Current Focus

**Active Feature**: <FeatureNumber>-<feature-name>  
**Current Boundary**: <BoundaryType> (Iteration <IterationNumber or N/A>)  
**Last Updated**: <ISO8601 timestamp>

<Context-specific focus guidance based on boundary type>
```

#### `.squad/decisions.md`

Append new entry:
```markdown
## [<ISO8601 timestamp>] Boundary: <BoundaryType> (Feature <FeatureNumber>, Iteration <IterationNumber or N/A>)

**Decision**: <Boundary-specific decision text>

**Context**: <Boundary-specific context>

**Authorization Commit**: `<AuthCommitHash>` (branch: <FeatureNumber>-<feature-name>)

**Next Boundary**: <Expected next boundary>
```

### Error Handling

- **Disk Full**: Log error, exit code 1, preserve original files
- **Permission Denied**: Log error, exit code 1, preserve original files
- **Invalid Parameters**: Log validation error, exit code 2, no file writes attempted
- **File Not Found** (first run): Create file with initial content, exit code 0
- **Rename Failure** (filesystem limitation): Log error, exit code 1, preserve original files; document fallback to direct write for next release

---

## Integration Points

### Boundary 1: Specify Completion

**Invoked By**: `speckit.specify` command (or equivalent)  
**When**: After new feature spec created and committed  
**Example**:
```powershell
.\scripts\internal\sync-boundary-state.ps1 `
  -BoundaryType "specify" `
  -FeatureNumber "020" `
  -AuthCommitHash "a1b2c3d" `
  -Verbose
```

### Boundary 2: Clarify Completion

**Invoked By**: `speckit.clarify` command  
**When**: After clarification questions resolved and spec updated  
**Example**:
```powershell
.\scripts\internal\sync-boundary-state.ps1 `
  -BoundaryType "clarify" `
  -FeatureNumber "020" `
  -AuthCommitHash "b2c3d4e"
```

### Boundary 3: Plan Completion

**Invoked By**: `speckit.plan` command  
**When**: After `plan.md` generated and committed  
**Example**:
```powershell
.\scripts\internal\sync-boundary-state.ps1 `
  -BoundaryType "plan" `
  -FeatureNumber "020" `
  -AuthCommitHash "c3d4e5f"
```

### Boundary 4: Tasks Completion

**Invoked By**: `speckit.tasks` command  
**When**: After `tasks.md` generated and committed  
**Example**:
```powershell
.\scripts\internal\sync-boundary-state.ps1 `
  -BoundaryType "tasks" `
  -FeatureNumber "020" `
  -IterationNumber 1 `
  -AuthCommitHash "d4e5f6g"
```

### Boundary 5: Review Signoff

**Invoked By**: `specrew review` command (or review/demo ceremony)  
**When**: After review verdict recorded and committed  
**Example**:
```powershell
.\scripts\internal\sync-boundary-state.ps1 `
  -BoundaryType "review-signoff" `
  -FeatureNumber "020" `
  -IterationNumber 1 `
  -AuthCommitHash "e5f6g7h"
```

### Boundary 6: Iteration Closeout

**Invoked By**: Iteration closeout ceremony  
**When**: After iteration closeout commit to feature branch  
**Example**:
```powershell
.\scripts\internal\sync-boundary-state.ps1 `
  -BoundaryType "iteration-closeout" `
  -FeatureNumber "020" `
  -IterationNumber 1 `
  -AuthCommitHash "f6g7h8i"
```

### Boundary 7: Feature Closeout

**Invoked By**: Feature closeout ceremony  
**When**: After feature merge to main (or closeout commit)  
**Example**:
```powershell
.\scripts\internal\sync-boundary-state.ps1 `
  -BoundaryType "feature-closeout" `
  -FeatureNumber "020" `
  -AuthCommitHash "g7h8i9j"
```

**Special Behavior**: At feature-closeout, also clears `.specify/feature.json` `feature_directory` field and updates `last-start-prompt.md` to "no active feature" state.

---

## Testing Strategy

### Unit Tests (`tests/unit/sync-boundary-state.tests.ps1`)

- **Test 1**: Valid parameters → exit code 0, all files updated
- **Test 2**: Invalid parameters → exit code 2, no files written
- **Test 3**: Write-temp-then-rename success → original file replaced, no `.tmp` file remains
- **Test 4**: Write-temp-then-rename failure (disk full simulation) → original file preserved, exit code 1
- **Test 5**: Permission denied simulation → original file preserved, exit code 1
- **Test 6**: First run (no existing files) → files created with initial content

### Integration Tests (`tests/integration/boundary-sync-atomicity.tests.ps1`)

- **Test 1**: All seven boundary types invoke sync successfully
- **Test 2**: Cross-file consistency after sync (all four files reference same feature/boundary)
- **Test 3**: System crash mid-sync simulation → stale-state detection identifies inconsistency
- **Test 4**: Multiple rapid boundary crossings → files remain consistent

---

## Version History

**v1 (F-020 Iteration 1)**: Initial implementation with seven boundaries, write-temp-then-rename atomicity, best-effort cross-file consistency
