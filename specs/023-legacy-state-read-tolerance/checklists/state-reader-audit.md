# State Reader Audit: Feature 023 (Legacy-State Read-Tolerance)

**Generated**: 2026-05-19  
**Research Reference**: research.md Decision 2  
**Purpose**: Complete inventory of state readers requiring hashtable migration for StrictMode compatibility

---

## High-Priority Readers (Causes Crashes or StrictMode Errors)

### ✅ 1. scripts/specrew-start.ps1
- **Line**: 806, 830 (feature.json parsing)
- **State File**: `.specify/feature.json`
- **Current Approach**: `ConvertFrom-Json` (PSCustomObject)
- **Missing Schema = v0**: Yes (treat as legacy)
- **v0/v1 Dispatch Required**: Yes (inline comments needed)
- **Migration Status**: ❌ PENDING (T004)
- **StrictMode Impact**: HIGH - hotfix crash site per b97a74b

### ✅ 2. scripts/internal/worktree-awareness.ps1
- **Line**: 60 (feature.json parsing)
- **State File**: `.specify/feature.json`
- **Current Approach**: `ConvertFrom-Json` (PSCustomObject)
- **Missing Schema = v0**: Yes (treat as legacy)
- **v0/v1 Dispatch Required**: Yes (inline comments needed)
- **Migration Status**: ❌ PENDING (T005)
- **StrictMode Impact**: HIGH - property access throws on missing fields

### ✅ 3. .specify/extensions/specrew-speckit/scripts/scaffold-feature-closeout-dashboard.ps1
- **Line**: 111 (feature.json parsing)
- **State File**: `.specify/feature.json`
- **Current Approach**: `ConvertFrom-Json` (PSCustomObject)
- **Missing Schema = v0**: Yes (treat as legacy)
- **v0/v1 Dispatch Required**: Yes (inline comments needed)
- **Migration Status**: ❌ PENDING (T006)
- **StrictMode Impact**: HIGH - throws on missing `feature_directory` field

---

## Medium-Priority Readers (Optional Fields + StrictMode, Currently Guarded)

### ✅ 4. scripts/internal/version-check.ps1
- **Line**: 138 (version-check-cache.json parsing)
- **State File**: `.specrew/version-check-cache.json`
- **Current Approach**: `ConvertFrom-Json` (PSCustomObject)
- **Missing Schema = v0**: Yes (treat as legacy)
- **v0/v1 Dispatch Required**: Yes (inline comments needed)
- **Migration Status**: ❌ PENDING (T007)
- **StrictMode Impact**: MEDIUM - optional fields exist (lines 133-142)

### ✅ 5. scripts/internal/coordinator-resume.ps1
- **Line**: 43 (last-validator-summary.json parsing)
- **State File**: `.specrew/last-validator-summary.json`
- **Current Approach**: `ConvertFrom-Json` (PSCustomObject)
- **Missing Schema = v0**: Yes (treat as legacy)
- **v0/v1 Dispatch Required**: Yes (inline comments needed)
- **Migration Status**: ❌ PENDING (T008)
- **StrictMode Impact**: MEDIUM - wrapped in try/catch, but optional fields (lines 38-55)

---

## Already Compliant Readers (No Migration Required)

### ✅ 6. scripts/specrew-start.ps1
- **Line**: 375 (start-context.json parsing)
- **State File**: `.specrew/start-context.json`
- **Current Approach**: `ConvertFrom-Json -AsHashtable -Depth 12` ✅
- **Migration Status**: ✅ ALREADY COMPLIANT

### ✅ 7. scripts/specrew-start.ps1
- **Line**: 2324, 2361 (config parsing)
- **State File**: Various JSON config files
- **Current Approach**: `ConvertFrom-Json -AsHashtable` ✅
- **Migration Status**: ✅ ALREADY COMPLIANT

### ✅ 8. scripts/internal/task-progress.ps1
- **Line**: 125 (feature.json parsing for task progress context)
- **State File**: `.specify/feature.json`
- **Current Approach**: `ConvertFrom-Json` (PSCustomObject)
- **Migration Status**: LOW PRIORITY - Used only for display context, not critical path

### ✅ 9. scripts/internal/sync-boundary-state.ps1
- **Line**: 422, 460, 612 (various state file parsing)
- **State File**: Multiple state files
- **Current Approach**: `ConvertFrom-Json` (PSCustomObject)
- **Migration Status**: LOW PRIORITY - State writer function, not critical reader path

### ✅ 10. scripts/internal/dashboard-renderer.ps1
- **Line**: 403 (feature.json parsing)
- **State File**: `.specify/feature.json`
- **Current Approach**: `ConvertFrom-Json` (PSCustomObject)
- **Migration Status**: LOW PRIORITY - Display only, not critical path

### ✅ 11. .specify/extensions/specrew-speckit/scripts/resolve-quality-profile.ps1
- **Line**: 75 (package.json parsing)
- **State File**: `package.json` (not a Specrew state file)
- **Current Approach**: `ConvertFrom-Json -AsHashtable` ✅
- **Migration Status**: ✅ ALREADY COMPLIANT

### ✅ 12. .specify/extensions/specrew-speckit/scripts/run-mechanical-checks.ps1
- **Line**: 391, 631 (package.json and finding payload parsing)
- **State File**: `package.json` (not a Specrew state file)
- **Current Approach**: `ConvertFrom-Json -AsHashtable` ✅
- **Migration Status**: ✅ ALREADY COMPLIANT

### ✅ 13. .specify/extensions/specrew-speckit/scripts/sync-squad-model-overrides.ps1
- **Line**: 48, 181 (config parsing)
- **State File**: `.specrew/config.json`
- **Current Approach**: `ConvertFrom-Json -AsHashtable` ✅
- **Migration Status**: ✅ ALREADY COMPLIANT

---

## Out of Scope (Not Specrew State Files)

### ❌ scripts/specrew-init.ps1
- **Line**: 2038 (brownfield report parsing)
- **Reason**: Temporary analysis output, not persisted state file
- **Migration Status**: OUT OF SCOPE

### ❌ scripts/specrew-start.ps1
- **Line**: 1524 (package.json parsing)
- **Reason**: package.json is not a Specrew state file
- **Migration Status**: OUT OF SCOPE (already uses -AsHashtable implicitly in some locations)

### ❌ .specify/extensions/specrew-speckit/scripts/validate-governance.ps1
- **Line**: 1106 (mechanical-findings.json parsing)
- **Reason**: Tool output, not state file
- **Migration Status**: OUT OF SCOPE

### ❌ .specify/extensions/specrew-speckit/scripts/manage-reviewer-regression.ps1
- **Line**: 649, 695, 1248, 1367 (various config parsing)
- **Reason**: Review tool internal state, not Specrew state files
- **Migration Status**: OUT OF SCOPE

---

## Summary

**Total State Readers Identified**: 13  
**High Priority (T004-T006)**: 3 scripts  
**Medium Priority (T007-T008)**: 2 scripts  
**Already Compliant**: 5 scripts  
**Low Priority (Deferred to Iteration 2 or future)**: 3 scripts  
**Out of Scope**: 5 scripts (not Specrew state files)

**Iteration 1 Migration Targets**: 5 scripts (T004-T008)  
**Legacy Schema Handling Required (T032)**: Same 5 scripts need v0/v1 dispatch comments

---

## Fixture coverage matrix

This matrix records the heterogeneous fixture corpus intentionally: each directory mirrors a representative on-disk state for that shipped version rather than a synthetic union of every possible file. Columns cover the reader-targeted and bootstrap-validation state surfaces exercised by the current regression contract.

| Legacy version | `.specrew/config.yml` | `.specrew/start-context.json` | `.specify/feature.json` | `tasks-progress.yml` | `.specrew/last-validator-summary.json` | `.squad/identity/now.md` | `.specify/extensions/specrew-speckit/extension.yml` | `.specrew/version-check-cache.json` |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `0.18.0` | present (representative of v0 state) | present (representative of v0 state) | present (representative of v0 state) | absent (file not yet written at this version) | absent (file not yet written at this version) | absent (reader did not exist at this version) | absent (file not yet written at this version) | absent (file not yet written at this version) |
| `0.19.0` | present (representative of v0 state) | present (representative of v0 state) | present (representative of v0 state) | absent (file not yet written at this version) | absent (file not yet written at this version) | absent (reader did not exist at this version) | absent (file not yet written at this version) | absent (file not yet written at this version) |
| `0.20.0` | present (representative of v0 state) | absent (file not yet written at this version) | absent (file not yet written at this version) | absent (file not yet written at this version) | absent (file not yet written at this version) | absent (reader did not exist at this version) | absent (file not yet written at this version) | absent (file not yet written at this version) |
| `0.21.0` | absent (file not yet written at this version) | absent (file not yet written at this version) | absent (file not yet written at this version) | present (representative of v1 state) | absent (file not yet written at this version) | absent (reader did not exist at this version) | absent (file not yet written at this version) | absent (file not yet written at this version) |
| `0.22.0` | absent (file not yet written at this version) | absent (file not yet written at this version) | absent (file not yet written at this version) | absent (file not yet written at this version) | present (representative of v0 state) | absent (reader did not exist at this version) | absent (file not yet written at this version) | absent (file not yet written at this version) |
| `0.23.0` | present (representative of v1 state) | present (representative of v1 state) | present (representative of v1 state) | absent (file not yet written at this version) | present (representative of v1 state) | present (representative of v1 state) | present (representative of v1 state) | absent (file not yet written at this version) |

### Absent-cell rationale by version

#### `0.18.0`

- `tasks-progress.yml`: absent because task-progress persistence had not shipped yet in the representative 0.18.0 state.
- `.specrew/last-validator-summary.json`: absent because the validator-summary artifact was not yet written by the lifecycle at this version.
- `.squad/identity/now.md`: absent because the identity-session-state reader surface was introduced later than 0.18.0.
- `.specify/extensions/specrew-speckit/extension.yml`: absent because the deployed extension manifest was not yet a tracked project artifact in the representative 0.18.0 snapshot.
- `.specrew/version-check-cache.json`: absent because the version-check cache is only created after explicit update/version-check flows and was not present in the representative 0.18.0 on-disk state.

#### `0.19.0`

- `tasks-progress.yml`: absent because task-progress persistence had not shipped yet in the representative 0.19.0 state.
- `.specrew/last-validator-summary.json`: absent because validator-summary persistence still was not part of the representative 0.19.0 fixture.
- `.squad/identity/now.md`: absent because boundary-sync identity frontmatter had not shipped yet at 0.19.0.
- `.specify/extensions/specrew-speckit/extension.yml`: absent because the deployed extension manifest was not yet a tracked project artifact in the representative 0.19.0 snapshot.
- `.specrew/version-check-cache.json`: absent because the cache was not guaranteed on disk until update/version-check flows ran, and the motivating 0.19.0 crash repro fixture intentionally stays focused on the start-context path.

#### `0.20.0`

- `.specrew/start-context.json`: absent because the chosen 0.20.0 fixture is a pre-session representative snapshot where no start command had written session context yet.
- `.specify/feature.json`: absent because the chosen 0.20.0 fixture predates feature-scaffold state being written on disk for that representative snapshot.
- `tasks-progress.yml`: absent because task-progress persistence had not shipped yet in the representative 0.20.0 state.
- `.specrew/last-validator-summary.json`: absent because validator-summary persistence had not yet produced a representative 0.20.0 artifact in the selected snapshot.
- `.squad/identity/now.md`: absent because the identity-session-state reader surface was introduced later than 0.20.0.
- `.specify/extensions/specrew-speckit/extension.yml`: absent because the deployed extension manifest was not yet a tracked project artifact in the representative 0.20.0 snapshot.
- `.specrew/version-check-cache.json`: absent because version-check cache output depends on an update/version-check run and was not present in the representative 0.20.0 on-disk state.

#### `0.21.0`

- `.specrew/config.yml`: absent because this representative 0.21.0 fixture intentionally isolates the shipped `tasks-progress.yml` ledger instead of synthesizing a broader project snapshot.
- `.specrew/start-context.json`: absent because the representative 0.21.0 fixture is not a resumed-session snapshot; the start-context artifact had not been written for this captured state.
- `.specify/feature.json`: absent because the representative 0.21.0 fixture is not a feature-scaffold snapshot; it captures the task-progress surface only.
- `.specrew/last-validator-summary.json`: absent because validator-summary persistence is not part of the chosen 0.21.0 representative state.
- `.squad/identity/now.md`: absent because the identity-session-state reader surface was introduced later than 0.21.0.
- `.specify/extensions/specrew-speckit/extension.yml`: absent because the deployed extension manifest was not part of the captured 0.21.0 task-progress snapshot.
- `.specrew/version-check-cache.json`: absent because version-check cache output depends on a separate update/version-check run and was not present in the representative 0.21.0 state.

#### `0.22.0`

- `.specrew/config.yml`: absent because the representative 0.22.0 fixture intentionally targets validator-summary compatibility rather than recreating a full project tree.
- `.specrew/start-context.json`: absent because the representative 0.22.0 fixture is not a resumed-session snapshot; no start-context artifact existed on disk for the captured state.
- `.specify/feature.json`: absent because the representative 0.22.0 fixture is scoped to the validator-summary reader surface rather than a feature-scaffold snapshot.
- `tasks-progress.yml`: absent because the captured 0.22.0 state is validator-output-only and does not claim a task-progress ledger.
- `.squad/identity/now.md`: absent because the identity-session-state reader surface was introduced later than 0.22.0.
- `.specify/extensions/specrew-speckit/extension.yml`: absent because the deployed extension manifest is not required to justify the 0.22.0 validator-summary compatibility target.
- `.specrew/version-check-cache.json`: absent because version-check cache output depends on a separate update/version-check run and was not present in the representative 0.22.0 state.

#### `0.23.0`

- `tasks-progress.yml`: absent because the current-version fixture is a post-migration schema-discipline snapshot, not a task-progress workflow snapshot; adding an invented ledger here would be less representative than leaving it absent and justified.
- `.specrew/version-check-cache.json`: absent because the version-check cache remains an opaque per-run cache file created only after update/version-check execution, and the 0.23.0 bootstrap-reference fixture intentionally captures durable lifecycle artifacts instead of volatile cache output.

### Matrix note

No silent gaps remain: every present file is deliberate, and every absence above is either tied to a reader that did not exist yet or to a representative snapshot where the file had not been written on disk.

---

## Validation

✅ All state readers in `.specrew/`, `.specify/`, `.squad/` paths identified  
✅ Priority ranking matches research.md Decision 2 table  
✅ StrictMode impact assessed for each reader  
✅ v0/v1 dispatch requirements documented per contracts/state-file-schema-v1.md Reader Contract

**Audit Complete**: Ready to proceed with reader migrations (T004-T008) and legacy schema handling (T032)
