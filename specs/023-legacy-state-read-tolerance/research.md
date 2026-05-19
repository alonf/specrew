# Phase 0: Research & Clarification

## Feature: Legacy-State Read-Tolerance + Schema Migration Discipline

**Branch**: `023-legacy-state-read-tolerance`  
**Research Date**: 2026-05-19  
**Research Method**: Parallel exploration agents + codebase audit + constitution alignment

---

## Research Objectives

Resolve all "NEEDS CLARIFICATION" items from Technical Context before proceeding to Phase 1 design. Specifically:

1. **PowerShell YAML parsing**: How to ensure YAML state files are parsed into hashtables (not PSCustomObject) for StrictMode compatibility
2. **Existing state reader patterns**: Audit all current state readers to identify migration scope (PSCustomObject vs hashtables)
3. **StrictMode behavior**: Confirm hashtable indexer behavior for missing keys under `Set-StrictMode -Version Latest`
4. **Legacy version availability**: Verify feasibility of obtaining representative state files from versions 0.18.0-0.22.0
5. **Validator framework integration**: Understand how to extend existing validator (Proposal 004/F-013) with new reader tolerance rule
6. **Cross-platform testing**: Confirm Linux test lane availability in Specrew CI pipeline

---

## Decision 1: YAML Parsing Strategy

**Research Question**: How should Specrew parse YAML state files to ensure StrictMode-compatible hashtable access?

### Findings

- **Specrew does NOT currently use PowerShell-Yaml module** or any third-party YAML cmdlet
- Existing YAML parsing is **manual line-by-line** using regex and scalar extraction:
  - `scripts/specrew-start.ps1:268-289` — parses `.specrew/config.yml`
  - `scripts/internal/version-check.ps1:10-30` — parses `.specrew/config.yml`
  - `scripts/internal/task-progress.ps1:204-237` — parses `tasks-progress.yml` into ordered hashtables
  - `.specify/extensions/specrew-speckit/scripts/shared-governance.ps1:502-590` — parses `.specrew/config.yml`
  - `.specify/extensions/specrew-speckit/scripts/validate-governance.ps1:511-533` — extracts `version:` from `extension.yml`
- JSON parsing **already uses hashtables** for StrictMode compatibility:
  - `scripts/specrew-start.ps1:375` — `ConvertFrom-Json -AsHashtable -Depth 12` for `start-context.json`
  - Explicit comment at line 368-374: "Use -AsHashtable because StrictMode Latest throws on missing properties"

### Decision

**Continue manual YAML parsing** (current Specrew pattern) with hashtable output for state files requiring structured access. Rationale:

- Consistent with existing Specrew codebase style (no new dependencies)
- Manual parsing already outputs hashtables (e.g., `task-progress.ps1:207-208, 225-230`)
- PowerShell 7.0+ does not include built-in `ConvertFrom-Yaml` cmdlet
- Manual parsing allows granular control over defaults and missing-key handling
- Schema versioning (FR-001) will make field extraction more structured over time

### Alternatives Considered

- **PowerShell-Yaml module**: Rejected because it's not currently used in Specrew; adding it introduces dependency bloat for a problem already solved manually
- **ConvertFrom-Yaml -AsHashtable** (if available in future PS versions): Would be preferred for complex nested YAML, but not available in PS 7.0+ baseline

---

## Decision 2: State Reader Migration Scope

**Research Question**: Which scripts read state files and require hashtable migration?

### Findings: Comprehensive State Reader Audit

| Script | State File(s) | Current Parse Approach | StrictMode | Migration Priority |
|--------|---------------|------------------------|------------|-------------------|
| `scripts/specrew-start.ps1` | `.specrew/start-context.json` | ✅ `ConvertFrom-Json -AsHashtable` | Yes | **Already compliant** |
| `scripts/specrew-start.ps1` | `.specify/feature.json` | ⚠️ `ConvertFrom-Json` (PSCustomObject) | Yes | **HIGH** — hotfix crash site per b97a74b |
| `scripts/specrew-start.ps1` | `.specrew/config.yml` | ✅ Manual line regex (scalar-only) | Yes | **Low** — no structured access, no crashes reported |
| `scripts/internal/version-check.ps1` | `.specrew/version-check-cache.json` | ⚠️ `ConvertFrom-Json` (PSCustomObject) | Yes | **MEDIUM** — optional fields exist (`133-142`) |
| `scripts/internal/version-check.ps1` | `.specrew/config.yml` | ✅ Manual line regex (scalar-only) | Yes | **Low** — no structured access |
| `scripts/internal/coordinator-resume.ps1` | `.specrew/last-validator-summary.json` | ⚠️ `ConvertFrom-Json` (PSCustomObject) | Yes | **MEDIUM** — wrapped in try/catch, but optional fields (`38-55`) |
| `scripts/internal/task-progress.ps1` | `tasks-progress.yml` | ✅ Manual YAML → hashtables | Yes | **Already compliant** (outputs hashtables) |
| `scripts/internal/worktree-awareness.ps1` | `.specify/feature.json` | ⚠️ `ConvertFrom-Json` (PSCustomObject) | Yes | **HIGH** — uses property access (`69-75`) |
| `scripts/internal/worktree-awareness.ps1` | `.squad/identity/now.md` (frontmatter) | ✅ Manual → ordered hashtable | Yes | **Already compliant** (uses `.Contains()`) |
| `scripts/internal/sync-boundary-state.ps1` | `.squad/identity/now.md` (frontmatter) | ✅ Manual → ordered hashtable | Yes | **Already compliant** (uses `.Contains()`) |
| `.specify/extensions/specrew-speckit/scripts/shared-governance.ps1` | `.specrew/config.yml` | ✅ Manual YAML → hashtable | Yes | **Already compliant** (uses `.Contains()`, line 530-590) |
| `.specify/extensions/specrew-speckit/scripts/validate-governance.ps1` | `extension.yml` | ✅ Regex extraction (scalar-only) | Yes | **Low** — no structured access |
| `.specify/extensions/specrew-speckit/scripts/scaffold-feature-closeout-dashboard.ps1` | `.specify/feature.json` | ⚠️ `ConvertFrom-Json` (PSCustomObject) | Yes | **HIGH** — throws on missing `feature_directory` (`107-114`) |
| `.specify/scripts/powershell/common.ps1` | `.specify/feature.json` | ⚠️ `ConvertFrom-Json` (PSCustomObject) | **No StrictMode** | **LOW** — fallback logic exists (`240-250`), but no StrictMode enforcement |

### Decision

**Iteration 1 migration scope** (FR-004, FR-005, FR-006):

**HIGH priority** (causes crashes or StrictMode errors):

1. `scripts/specrew-start.ps1:375` — change `feature.json` parsing to `-AsHashtable`
2. `scripts/internal/worktree-awareness.ps1:57-75` — change `feature.json` parsing to `-AsHashtable`
3. `.specify/extensions/specrew-speckit/scripts/scaffold-feature-closeout-dashboard.ps1:106-121` — change to `-AsHashtable` + null-safe access

**MEDIUM priority** (optional fields + StrictMode, currently guarded but fragile):
4. `scripts/internal/version-check.ps1:113-143` — change `version-check-cache.json` parsing to `-AsHashtable`
5. `scripts/internal/coordinator-resume.ps1:28-56` — change `last-validator-summary.json` parsing to `-AsHashtable`

**LOW priority** (no structured access or already compliant):

- Manual YAML parsing: already outputs hashtables where needed
- `.specify/scripts/powershell/common.ps1` — no StrictMode, so not a blocker, but should be migrated for consistency in Iteration 2

### Alternatives Considered

- **Migrate ALL scripts in one iteration**: Rejected due to capacity constraints (~10 SP for Iteration 1). Split into HIGH/MEDIUM (Iteration 1) and LOW/consistency fixes (Iteration 2 or deferred).

---

## Decision 3: StrictMode Behavior Validation

**Research Question**: Confirm that hashtable indexers return `$null` for missing keys under StrictMode, while PSCustomObject property access throws.

### Findings

- **Hashtable indexer behavior**: Returns `$null` for missing keys; does NOT throw under `Set-StrictMode -Version Latest`
  - Evidence: `scripts/specrew-start.ps1:368-374` explicitly documents this: "Use -AsHashtable because StrictMode Latest throws on missing PSCustomObject properties"
  - All scripts in audit use `Set-StrictMode -Version Latest` (line 1 in most cases)
  - Hashtable-based readers use null-safe access patterns: `if ($config['key']) { ... }` or `.Contains('key')`

- **PSCustomObject property behavior**: Throws `PropertyNotFoundException` for missing properties under StrictMode Latest
  - This is the **root cause of the 2026-05-19 WSL crash** (hotfix b97a74b)
  - Evidence: `start-context.json` lacked `session_state` field; PSCustomObject access threw; migration to `-AsHashtable` fixed it

### Decision

**Use hashtable indexers for all optional field access** (FR-005). Rationale:

- PowerShell 7.0+ guarantees null return for missing hashtable keys (no throw)
- Existing Specrew codebase already relies on this behavior (e.g., `specrew-start.ps1:368-374`)
- Schema version dispatch (FR-006) can use `if ($state['schema'] -eq 'v0') { ... }` safely

### Alternatives Considered

- **Disable StrictMode**: Rejected — Constitution Principle XXIII (Specrew Is Testable As A Product) and existing practice require strict error handling

---

## Decision 4: Legacy Fixture Corpus Strategy

**Research Question**: Can we obtain representative state files from Specrew versions 0.18.0-0.22.0 for the fixture corpus (FR-007)?

### Findings

- **Version 0.19.0**: Real crash repro available from 2026-05-19 WSL trial (motivating evidence for this feature)
- **Other versions (0.18.0, 0.20.0, 0.21.0, 0.22.0)**: Can be generated by:
  1. Checking out Specrew at each version tag
  2. Running `specrew init` + basic lifecycle (start, update, etc.)
  3. Capturing state files from `.specrew/`, `.specify/`, `.squad/`, and `tasks-progress.yml`
  4. Hand-curating to ensure edge cases are represented (e.g., missing optional fields, partial state)
- **Git history**: Version tags exist in Specrew repo; release history shows 0.18.0+ shipped between 2025-Q4 and 2026-Q2

### Decision

**Hand-curate fixtures for versions 0.18.0-0.22.0 from real project snapshots** (FR-007, FR-008). Rationale:

- Iteration 1 scope is bounded to these five versions (covers ~6 months of releases)
- Real projects provide authentic edge cases (missing fields, partial state, cross-platform line endings)
- Future fixtures (0.23.0+) can be generated or hand-curated as needed per closeout template reminder (FR-013)

**Fixture directory structure**:

```
tests/fixtures/legacy-versions/
├── 0.18.0/
│   ├── .specrew/
│   ├── .specify/
│   ├── .squad/
│   └── tasks-progress.yml (if applicable)
├── 0.19.0/   # motivating crash version
├── 0.20.0/
├── 0.21.0/
└── 0.22.0/
```

### Alternatives Considered

- **Generate fixtures programmatically**: Rejected for Iteration 1 because real snapshots capture authentic schema drift and edge cases; may revisit in future iterations (per Assumptions section in spec)
- **Fixture corpus only for crash-prone files**: Rejected — FR-008 requires exercising ALL state readers against ALL fixtures for comprehensive regression coverage

---

## Decision 5: Validator Framework Integration

**Research Question**: How to extend the existing validator framework (Proposal 004/F-013) with a new rule for reader tolerance (gap #11)?

### Findings

**Validator Framework Architecture**:

- **Location**: `.specify/extensions/specrew-speckit/scripts/validate-governance.ps1` (main entrypoint, ~1700 lines)
- **Structure**: Single PowerShell script with `Test-*` functions (not a plugin registry)
  - Example rules: `Test-StateArtifact` (line 1562-1615), `Test-ReviewArtifact` (line 1617-1694), `Test-IterationCloseoutEvidence` (line 1794-1860)
  - Rules accumulate failures into `System.Collections.Generic.List[string]` via `Add-RepoStructuredValidationFailure`
- **Rule interface contract**:

  ```powershell
  function Test-RuleName {
      param(
          [string]$ProjectRoot,
          [string]$TargetPath,  # File being validated
          [System.Collections.Generic.List[string]]$Errors
      )
      # Read artifact(s), validate, push human-readable failures into $Errors
  }
  ```

- **Error format**: Structured via `Add-RepoStructuredValidationFailure`:
  - `FilePath`, `LineNumber`, `Category`, `Message`, `RemediationHint`
  - Example: `"Function Get-XYZ uses ConvertFrom-Json without -AsHashtable. State readers must use hashtables to tolerate missing fields. Add -AsHashtable parameter."`

**CI/PR Integration**:

- **GitHub Actions**: `.github/workflows/specrew-ci.yml:60-63` runs `validate-governance.ps1 -ProjectPath .`
- **PR template**: `.github/PULL_REQUEST_TEMPLATE.md:23-29` requires validator pass
- **Squad coordination**: `.github/agents/squad.agent.md:117-120` instructs Squad to run validator before lifecycle transitions

**Rule Scoping** (from Proposal 059):

- Target functions matching:
  - `Get-Specrew*SessionState`
  - `Get-Specrew*State`
  - OR any function reading from `.specrew/*`, `.specify/*`, `.squad/*` paths
- Violation condition: Function includes `ConvertFrom-Json` **without** `-AsHashtable` parameter

### Decision

**Implement gap #11 validator rule as `Test-ReaderTolerance` function** in `validate-governance.ps1` (FR-010, FR-011). Structure:

```powershell
function Test-ReaderTolerance {
    param(
        [string]$ProjectRoot,
        [System.Collections.Generic.List[string]]$Errors
    )
    
    # 1. Find all .ps1 files under scripts/, extensions/
    # 2. For each file:
    #    a. Check if it contains ConvertFrom-Json
    #    b. Check if function name matches Get-Specrew*State pattern
    #       OR if Get-Content/Test-Path targets .specrew/*, .specify/*, .squad/* paths
    #    c. If ConvertFrom-Json lacks -AsHashtable, add violation:
    #       Category: "reader-tolerance"
    #       Message: "Function {Name} uses ConvertFrom-Json without -AsHashtable"
    #       RemediationHint: "State readers must use hashtables to tolerate missing fields under StrictMode. Add -AsHashtable parameter."
}
```

**Integration point**: Add `Test-ReaderTolerance` call to main validator orchestration in `validate-governance.ps1` (near existing `Test-StateArtifact`, `Test-ReviewArtifact` calls)

**Iteration placement**: Iteration 2 (FR-010, FR-011) — after Iteration 1 migrations complete, validator enforces pattern for future changes

### Alternatives Considered

- **Separate validator script**: Rejected — existing pattern is monolithic `validate-governance.ps1`; maintaining consistency reduces complexity
- **AST-based parsing**: Considered for precise function detection but deferred — regex-based pattern matching (current validator style) sufficient for Iteration 1; AST parsing may be added in future validator refactoring

---

## Decision 6: Cross-Platform Testing

**Research Question**: Is Linux test lane available in Specrew CI pipeline for FR-014 requirement?

### Findings

- **GitHub Actions workflow**: `.github/workflows/specrew-ci.yml` exists
- **Current CI matrix**: Line 60-63 shows validator runs on `ubuntu-latest` runner
- **PowerShell 7.0+ availability**: GitHub-hosted Ubuntu runners include PowerShell 7.x pre-installed
- **Motivating evidence**: 2026-05-19 WSL trial surfaced six bugs (four form-vs-meaning gaps), confirming Linux testing necessity

### Decision

**Extend existing CI workflow to include Linux test lane for legacy fixture tests** (FR-014). Rationale:

- Infrastructure already exists (ubuntu-latest runner in current CI)
- PowerShell 7.0+ cross-platform compatibility is a Specrew prerequisite (Constitution Principle V)
- Cross-platform line-ending normalization via Git `core.autocrlf` (per Assumptions section in spec)

**Implementation**:

- Add step to `.github/workflows/specrew-ci.yml` after validator step:

  ```yaml
  - name: Test Legacy State Readers (Linux)
    run: |
      pwsh -File tests/integration/Test-LegacyStateReaders.Tests.ps1
  ```

- Pester test script (FR-008): `tests/integration/Test-LegacyStateReaders.Tests.ps1` invokes all state readers against all fixtures in `tests/fixtures/legacy-versions/`

### Alternatives Considered

- **Windows-only testing**: Rejected — FR-014 explicitly requires Linux validation; cross-platform bugs are a documented motivating factor
- **Separate Linux-only CI workflow**: Rejected — existing `specrew-ci.yml` already runs on ubuntu-latest; adding a test step is simpler than separate workflow

---

## Bootstrap Principle Confirmation

**Constitutional Requirement**: F-023's own readers and writers must demonstrate the schema versioning and reader tolerance patterns being established (per spec Assumptions section).

### Findings

- **State files written by this feature**:
  - `research.md`, `data-model.md`, `quickstart.md`, `contracts/` (this planning phase) — markdown/documentation, not persisted state
  - No runtime state files written by planning workflow itself

- **State files read during planning**:
  - `spec.md` (markdown, not JSON/YAML state)
  - Constitution, quality profile output (not persisted state files in user projects)

- **State files written during implementation** (Iteration 1):
  - ALL state file writers (`specrew-init.ps1`, `sync-boundary-state.ps1`, etc.) will add `schema: v1` markers (FR-001)
  - These writers become **reference implementations** of the schema versioning pattern

- **State files read during implementation** (Iteration 1):
  - ALL state file readers migrated to hashtable parsing (FR-004, FR-005, FR-006)
  - These readers become **reference implementations** of the reader tolerance pattern

### Decision

**Bootstrap principle satisfied** — F-023's implementation (writers adding `schema: v1`, readers using hashtables) IS the reference implementation. No separate "dogfooding" artifact needed; the feature implementation itself demonstrates the pattern.

---

## Research Summary

All "NEEDS CLARIFICATION" items from Technical Context resolved:

| Unknown | Resolution | Decision Impact |
|---------|-----------|-----------------|
| PowerShell YAML parsing | Manual line-by-line (current pattern) | No new dependencies; continue existing approach |
| Existing state reader patterns | 13 scripts audited; 5 HIGH/MEDIUM priority migrations | Iteration 1 scope: 5 critical readers + fixture corpus |
| StrictMode behavior | Hashtable indexers return `$null` (safe); PSCustomObject throws | Use `-AsHashtable` for all JSON state files |
| Legacy version availability | 0.18.0-0.22.0 fixtures from real projects | Hand-curate for Iteration 1; add closeout reminder (FR-013) |
| Validator framework | Monolithic script with `Test-*` functions | Add `Test-ReaderTolerance` in Iteration 2 |
| Cross-platform testing | Linux lane already exists in CI | Extend with Pester fixture test step (FR-014) |
| Bootstrap principle | Feature implementation IS the reference | Writers add `schema: v1`; readers use hashtables |

**Phase 0 complete** — proceed to Phase 1 design (data-model.md, contracts/, quickstart.md).
