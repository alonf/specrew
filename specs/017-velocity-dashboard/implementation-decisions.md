# Feature 017 Velocity Dashboard: Implementation Decisions

**Repository**: C:\Dev\Specrew-017  
**Feature**: 017-velocity-dashboard  
**Focus**: PowerShell console-first CLI rendering  
**Date**: 2026-05-15

---

## 1. Command Wiring

### Decision: Mirror existing command structure with switch dispatch

**Rationale**:
- Existing `specrew.ps1` uses switch-based command routing (lines 93-176)
- Commands follow pattern: `specrew <command>` → `scripts\specrew-<command>.ps1`
- All commands use `pwsh -NoProfile -ExecutionPolicy Bypass -File <script> @Arguments`

**Implementation**:
```powershell
# In scripts\specrew.ps1, add to switch statement:
'where' {
    $whereScript = Join-Path $scriptRoot 'specrew-where.ps1'
    if (-not (Test-Path -LiteralPath $whereScript)) {
        Write-Host "ERROR: specrew-where.ps1 not found at $whereScript" -ForegroundColor Red
        exit 1
    }
    & pwsh -NoProfile -ExecutionPolicy Bypass -File $whereScript @Arguments
    exit $LASTEXITCODE
}

'status' {
    # Alias to 'where'
    $whereScript = Join-Path $scriptRoot 'specrew-where.ps1'
    if (-not (Test-Path -LiteralPath $whereScript)) {
        Write-Host "ERROR: specrew-where.ps1 not found at $whereScript" -ForegroundColor Red
        exit 1
    }
    & pwsh -NoProfile -ExecutionPolicy Bypass -File $whereScript @Arguments
    exit $LASTEXITCODE
}
```

**Alternative considered**:
- Unified alias mechanism in script header → Rejected: adds complexity, current pattern is explicit and consistent

**Evidence**:
- `scripts\specrew.ps1:93-176` (existing dispatch)
- `scripts\specrew-review.ps1:1-12` (parameter pattern)
- `scripts\specrew-start.ps1:1-27` (CLI args handling)

---

## 2. Color & Terminal Detection

### Decision: Multi-layer detection with explicit environment honor

**Rationale**:
- Codebase only checks `[Console]::IsOutputRedirected` in one place (`scaffold-reviewer-artifacts.ps1:2504`)
- NO_COLOR is mentioned in spec (line 29) but not yet implemented in codebase
- PowerShell color usage is pervasive but unconditional (43 uses of `-ForegroundColor` in scripts/)

**Implementation**:
```powershell
function Test-ShouldUseColor {
    param(
        [switch]$NoColor  # Explicit flag
    )
    
    # Priority order (first match wins):
    # 1. Explicit --no-color flag
    if ($NoColor) { return $false }
    
    # 2. NO_COLOR environment variable (https://no-color.org/)
    if ($env:NO_COLOR) { return $false }
    
    # 3. Output redirection (non-TTY)
    if ([Console]::IsOutputRedirected) { return $false }
    
    # 4. Dumb terminal detection
    if ($env:TERM -eq 'dumb') { return $false }
    
    # 5. CI environment indicators
    if ($env:CI -eq 'true' -or $env:GITHUB_ACTIONS -eq 'true') { return $false }
    
    # 6. Check if UI supports color
    if ($null -eq $Host.UI -or $null -eq $Host.UI.RawUI) { return $false }
    
    # Default: use color
    return $true
}
```

**Alternative considered**:
- Only check `IsOutputRedirected` → Rejected: too narrow, doesn't honor NO_COLOR standard
- PowerShell `$PSStyle.OutputRendering` → Rejected: only available PS 7.2+, repo targets 7.0+

**Evidence**:
- Spec requirement FR-006 (line 140): "semantic color...monochrome fallback"
- Clarification #10 (line 29): "honors NO_COLOR, dumb-terminal detection, non-TTY"
- `scripts\specrew-init.ps1:54,250-271` (console redirection handling)
- `extensions\specrew-speckit\scripts\scaffold-reviewer-artifacts.ps1:2504` (existing detection)

---

## 3. Monochrome-Safe Visual Elements

### Decision: ASCII box-drawing with progress bars, tables, horizontal bars

**Rationale**:
- Existing code uses simple borders: `'=' * 60` in `specrew-review.ps1:342`
- Table rendering exists in `specrew-team.ps1:465-489` (plain pipe-separated Markdown)
- No existing sparkline or bar chart implementation
- Spec mandates "console-first, monochrome-safe, low-noise" (FR-004, line 138)

**Implementation**:

#### Progress Bar
```powershell
function Format-ProgressBar {
    param(
        [int]$Current,
        [int]$Total,
        [int]$Width = 40,
        [bool]$UseColor = $false
    )
    
    $percent = if ($Total -gt 0) { [Math]::Min(100, ($Current * 100 / $Total)) } else { 0 }
    $filled = [Math]::Floor($Width * $percent / 100)
    $empty = $Width - $filled
    
    $bar = ('[' + ('█' * $filled) + (' ' * $empty) + ']')
    $label = "{0,3}%" -f [int]$percent
    
    if ($UseColor) {
        $color = if ($percent -ge 80) { 'Green' } elseif ($percent -ge 50) { 'Yellow' } else { 'Red' }
        Write-Host $bar -NoNewline -ForegroundColor $color
        Write-Host " $label"
    } else {
        Write-Host "$bar $label"
    }
}
```

#### Horizontal Bar Chart (iteration summary)
```powershell
function Format-HorizontalBar {
    param(
        [string]$Label,
        [int]$Value,
        [int]$MaxValue,
        [int]$BarWidth = 30,
        [bool]$UseColor = $false
    )
    
    $barLength = if ($MaxValue -gt 0) { [Math]::Floor($BarWidth * $Value / $MaxValue) } else { 0 }
    $bar = '▓' * $barLength
    
    $line = "{0,-15} {1,3} SP │{2}" -f $Label, $Value, $bar
    
    if ($UseColor) {
        Write-Host $line -ForegroundColor Cyan
    } else {
        Write-Host $line
    }
}
```

#### Compact Table (recent iterations variance)
```powershell
function Format-IterationTable {
    param(
        [array]$Iterations,
        [bool]$UseColor = $false
    )
    
    $header = "Iteration | Planned | Actual | Delta | Days"
    $separator = "-" * 48
    
    Write-Host $header
    Write-Host $separator
    
    foreach ($iter in $Iterations) {
        $delta = $iter.Actual - $iter.Planned
        $sign = if ($delta -gt 0) { '+' } elseif ($delta -lt 0) { '' } else { ' ' }
        
        $line = "{0,-10} | {1,7} | {2,6} | {3}{4,4} | {5,4}" -f `
            $iter.Name, $iter.Planned, $iter.Actual, $sign, $delta, $iter.Days
        
        if ($UseColor -and $delta -lt 0) {
            Write-Host $line -ForegroundColor Red
        } elseif ($UseColor -and $delta -gt 0) {
            Write-Host $line -ForegroundColor Green
        } else {
            Write-Host $line
        }
    }
}
```

#### Tiny Sparkline (optional for velocity trend)
```powershell
function Format-MiniSparkline {
    param(
        [array]$Values,
        [int]$MaxWidth = 10
    )
    
    if ($Values.Count -eq 0) { return '' }
    
    # Take last N values
    $recent = $Values | Select-Object -Last $MaxWidth
    $max = ($recent | Measure-Object -Maximum).Maximum
    if ($max -eq 0) { return '▁' * $recent.Count }
    
    # Map to 8 levels: ▁▂▃▄▅▆▇█
    $levels = '▁','▂','▃','▄','▅','▆','▇','█'
    $sparkline = ''
    foreach ($val in $recent) {
        $index = [Math]::Floor(($val * 7) / $max)
        $sparkline += $levels[$index]
    }
    
    return $sparkline
}
```

**Alternative considered**:
- Unicode box-drawing characters (`─ │ ┌ ┐ └ ┘`) → Rejected: encoding issues, not universally monochrome-safe
- Full-width charts → Rejected: conflicts with 24-line compact mode requirement

**Evidence**:
- FR-004 (line 138): "horizontal bars, progress bars, compact tables, at most one tiny sparkline"
- FR-007 (line 141): "compact rendering mode...24 lines"
- `scripts\specrew-review.ps1:342-345` (existing border pattern)
- `scripts\specrew-team.ps1:465-489` (existing table rendering)

---

## 4. 24-Line Compact Mode

### Decision: Fixed-budget layout with prioritized sections

**Rationale**:
- Spec mandates "fixed maximum budget of 24 lines" (FR-007, line 141)
- Clarification #2 (line 21): "fixed v1 budget...consistent and testable"
- Iteration closeout handoffs need stable, reproducible output

**Implementation**:

```powershell
# Layout allocation (total: 24 lines)
# 
# Line 01: Repository header
# Line 02: Empty
# Line 03: Active Work section header
# Line 04: Active feature summary
# Line 05: Empty
# Line 06: Velocity section header
# Line 07: Velocity metric + sparkline
# Line 08: Empty
# Line 09: Recent Shipped section header
# Line 10-12: Top 3 recent iterations (horizontal bars)
# Line 13: Empty
# Line 14: Recent Iterations (plan vs actual) section header
# Line 15-18: Variance table (header + 3 iterations)
# Line 19: Empty
# Line 20: Roadmap Progress section header
# Line 21: Phase progress bar
# Line 22: Empty
# Line 23: Remaining Effort section header
# Line 24: ETA projection line

function Write-CompactDashboard {
    param(
        [hashtable]$Data,
        [bool]$UseColor = $false
    )
    
    $lines = @()
    
    # Line 1: Header
    $lines += "Specrew Velocity Dashboard — $($Data.RepoName)"
    
    # Lines 2-4: Active Work
    $lines += ""
    $lines += "ACTIVE WORK"
    $lines += "  $($Data.ActiveFeature) (Iteration $($Data.ActiveIteration), $($Data.ActiveDays) days)"
    
    # Lines 5-7: Velocity
    $lines += ""
    $lines += "VELOCITY"
    $sparkline = if ($Data.VelocityHistory) { Format-MiniSparkline $Data.VelocityHistory } else { '' }
    $lines += "  $($Data.VelocitySP) SP/week (last $($Data.VelocitySampleDays) days) $sparkline"
    
    # Lines 8-12: Recent Shipped
    $lines += ""
    $lines += "RECENT SHIPPED"
    foreach ($iter in ($Data.RecentIterations | Select-Object -First 3)) {
        $lines += "  $(Format-HorizontalBar -Label $iter.Name -Value $iter.StoryPoints -MaxValue $Data.MaxIterationSP -BarWidth 20 -UseColor $UseColor)"
    }
    
    # Lines 13-18: Plan vs Actual
    $lines += ""
    $lines += "RECENT ITERATIONS (plan vs actual)"
    $lines += (Format-IterationTable -Iterations ($Data.RecentIterations | Select-Object -First 3) -UseColor $UseColor)
    
    # Lines 19-21: Roadmap
    $lines += ""
    $lines += "ROADMAP PROGRESS"
    $lines += "  $(Format-ProgressBar -Current $Data.RoadmapCompleted -Total $Data.RoadmapTotal -Width 40 -UseColor $UseColor)"
    
    # Lines 22-24: Projection
    $lines += ""
    $lines += "REMAINING EFFORT"
    $lines += "  $($Data.RemainingStorySP) SP remaining · ETA: $($Data.ETA) (±$($Data.ETAUncertainty))"
    
    # Enforce line budget
    if ($lines.Count -gt 24) {
        Write-Warning "Dashboard exceeds 24-line budget ($($lines.Count) lines). Truncating."
        $lines = $lines | Select-Object -First 24
    }
    
    # Render
    foreach ($line in $lines) {
        Write-Host $line
    }
}
```

**Alternative considered**:
- Dynamic line budget based on terminal height → Rejected: conflicts with "fixed" requirement, breaks closeout reproducibility
- Pagination → Rejected: defeats "single-screen" user story

**Evidence**:
- FR-007 (line 141): "fixed maximum budget of 24 lines"
- Clarification #2 (line 21): "fixed v1 budget...stays consistent and testable"
- User Story 1, Scenario 1 (line 79): "single-screen summary"

---

## 5. Entry Point Script Structure

### Decision: Follow specrew-review.ps1 parameter pattern

**Rationale**:
- All existing commands use CmdletBinding + explicit parameter blocks
- Unix-style argument parsing via Convert-UnixStyleArguments helper
- Shared governance sourcing for project path resolution

**Implementation**:

```powershell
# scripts\specrew-where.ps1
[CmdletBinding()]
param(
    [string]$ProjectPath = '.',
    [string]$FeatureId,      # Optional: restrict to specific feature
    [string]$IterationNumber, # Optional: show specific iteration snapshot
    [switch]$Compact,         # Force compact mode
    [switch]$NoColor,         # Disable color
    [switch]$Json,            # JSON output (for automation)
    [switch]$Help,
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$CliArgs
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Source shared governance helper
$sharedGovernancePath = Join-Path (Split-Path -Parent $PSScriptRoot) 'extensions\specrew-speckit\scripts\shared-governance.ps1'
if (-not (Test-Path -LiteralPath $sharedGovernancePath -PathType Leaf)) {
    throw "Missing shared governance helper '$sharedGovernancePath'."
}
. $sharedGovernancePath

function Show-Usage {
    @'
specrew where - show velocity dashboard ("where am I?")

Usage:
  specrew where [options]
  specrew status [options]  (alias)

Options:
  --project-path <path>  Target Specrew project (default: current directory)
  --feature <id>         Restrict to one feature
  --iteration <NNN>      Show specific iteration snapshot
  --compact              Force 24-line compact mode
  --no-color             Disable color output
  --json                 Emit JSON instead of visual dashboard
  --help                 Show this help message

Examples:
  specrew where
  specrew status --no-color
  specrew where --project-path ../other-project
  specrew where --compact --json > dashboard.json
'@ | Write-Host
}

# ... Convert-UnixStyleArguments, main logic ...
```

**Alternative considered**:
- Positional command-line parsing → Rejected: inconsistent with `specrew review` pattern
- Direct `$PSBoundParameters` usage → Rejected: breaks Unix-style `--option=value` support

**Evidence**:
- `scripts\specrew-review.ps1:1-41` (parameter structure)
- `scripts\specrew-start.ps1:41-100` (Convert-UnixStyleArguments pattern)
- `extensions\specrew-speckit\scripts\shared-governance.ps1:1-100` (sourcing pattern)

---

## 6. Data Gathering Strategy

### Decision: Parse iteration state.md + retro.md + config.yml; defer to FR-002 full spec

**Rationale**:
- Existing code already parses iteration artifacts:
  - `specrew-start.ps1:273-343` (Get-MarkdownContent, Get-MarkdownSectionTable)
  - Iteration state, retro, review files under `specs\<feature>\iterations\<NNN>\`
- FR-002 mandates canonical sources: active-feature pointer, specs, iterations, retros, roadmap
- Roadmap is new, needs structured YAML or Markdown format (separate decision)

**Implementation outline**:
1. Resolve project path via `Resolve-ProjectPath` (shared-governance.ps1:4-20)
2. Parse `.specify\feature.json` for active feature (specrew-start.ps1:226-242)
3. Scan `specs\<feature>\iterations\*\state.md` for completed iterations
4. Extract story points from iteration `state.md` (Markdown table parsing: specrew-start.ps1:279-343)
5. Parse retrospective records for shipped iterations
6. Parse new `.specrew\roadmap.yml` (to be defined)
7. Aggregate into dashboard data model

**Alternative considered**:
- SQL-based artifact cache → Rejected: adds infrastructure complexity, out of scope for v1
- JSON sidecar files → Rejected: introduces duplicate state

**Evidence**:
- FR-002 (line 136): "canonical project records...active-feature pointer, feature specs, iteration state"
- `scripts\specrew-start.ps1:273-343` (existing Markdown parsing)
- `scripts\specrew-start.ps1:226-270` (feature directory resolution)

---

## 7. Error Handling & Resilience

### Decision: Bounded warnings with partial rendering (follow FR-008)

**Rationale**:
- Spec mandates "bounded warnings and partial rendering rather than crash" (FR-008, line 142)
- Existing pattern: validate but continue (validator-hardening surfaces)
- Dashboard utility degrades gracefully when data incomplete

**Implementation**:

```powershell
function Get-IterationData {
    param([string]$IterationPath)
    
    try {
        $statePath = Join-Path $IterationPath 'state.md'
        if (-not (Test-Path $statePath)) {
            Write-Warning "Missing state.md at $IterationPath"
            return $null
        }
        
        $lines = Get-Content $statePath -Encoding UTF8
        # ... parse story points ...
        
        return [PSCustomObject]@{
            Number = $iterNumber
            StoryPoints = $sp
            Planned = $planned
            Actual = $actual
        }
    }
    catch {
        Write-Warning "Failed to parse iteration at $IterationPath : $($_.Exception.Message)"
        return $null
    }
}

function Write-DashboardWithWarnings {
    param(
        [array]$Iterations,
        [bool]$UseColor
    )
    
    $validIterations = $Iterations | Where-Object { $_ -ne $null }
    
    if ($validIterations.Count -eq 0) {
        Write-Host "⚠ No valid iteration data found. Dashboard limited to active work." -ForegroundColor Yellow
        # ... render partial dashboard ...
        return
    }
    
    if ($validIterations.Count -lt $Iterations.Count) {
        $missing = $Iterations.Count - $validIterations.Count
        Write-Host "⚠ $missing iteration(s) skipped due to incomplete data." -ForegroundColor Yellow
    }
    
    # ... render full dashboard ...
}
```

**Alternative considered**:
- Fail-fast on missing data → Rejected: violates FR-008 resilience requirement
- Silent data imputation → Rejected: creates trust issues

**Evidence**:
- FR-008 (line 142): "bounded warnings and partial rendering rather than crash"
- User Story 2 (lines 86-99): "trust the dashboard...resilient when records incomplete"

---

## 8. Testing & Validation

### Decision: Integration tests + fixture-based validation

**Rationale**:
- Existing integration test pattern: `tests\integration\*.ps1`
- Validator pattern: `extensions\specrew-speckit\validators\*.ps1`
- Tests verify both happy path and degraded scenarios

**Test coverage**:

1. **Command routing test** (`tests\integration\dashboard-command-routing.ps1`)
   - `specrew where` and `specrew status` both invoke same script
   - Help flag works
   - Project path resolution

2. **Color detection test** (`tests\integration\dashboard-color-detection.ps1`)
   - NO_COLOR honored
   - Output redirection detected
   - Explicit --no-color flag

3. **Compact mode test** (`tests\integration\dashboard-compact-mode.ps1`)
   - Output exactly 24 lines (or fewer if warnings present)
   - No truncation warnings on valid data

4. **Resilience test** (`tests\integration\dashboard-resilience.ps1`)
   - Missing state.md → partial render + warning
   - Malformed YAML → skip with warning
   - No roadmap → setup message

5. **Fixture validation** (`tests\unit\fixtures\017-velocity-dashboard\`)
   - Valid multi-iteration repo
   - Empty repo (no iterations)
   - Incomplete iteration data
   - Roadmap mismatch scenarios

**Alternative considered**:
- Unit tests only → Rejected: dashboard is integration-heavy, needs E2E validation
- Manual testing only → Rejected: conflicts with "testable" requirement

**Evidence**:
- Clarification #2 (line 21): "stays consistent and testable"
- Existing test structure: `tests\integration\*.ps1`
- Validator pattern: `extensions\specrew-speckit\validators\*-validator.ps1`

---

## 9. Roadmap Source Format

### Decision: YAML config at `.specrew\roadmap.yml` with explicit phases

**Rationale**:
- Existing config uses YAML: `.specrew\config.yml`, `.specrew\iteration-config.yml`
- Roadmap needs phase grouping, SP totals, feature references
- YAML supports structured data + comments for human editability

**Schema**:

```yaml
# .specrew/roadmap.yml
roadmap:
  name: "Specrew Alpha"
  phases:
    - id: "foundation"
      name: "Foundation"
      description: "Core lifecycle and governance"
      story_points: 120
      features:
        - feature_id: "001-specrew-product"
          story_points: 15
        - feature_id: "002-planning-flow-hardening"
          story_points: 12
        # ...
    
    - id: "visibility"
      name: "Visibility & Feedback"
      description: "Developer experience and delivery metrics"
      story_points: 85
      features:
        - feature_id: "017-velocity-dashboard"
          story_points: 19
        # ...
```

**Validation**:
- Check feature_id references exist under `specs\<feature_id>\spec.md`
- Sum of feature story points must equal phase story points
- Warn on roadmap drift (features exist but not in roadmap)

**Alternative considered**:
- Markdown roadmap with tables → Rejected: harder to parse, less structured
- Hardcoded roadmap in script → Rejected: not maintainable

**Evidence**:
- FR-002 (line 136): "structured roadmap source introduced by this feature"
- Existing YAML configs: `.specrew\config.yml`, `.specrew\iteration-config.yml`

---

## 10. Cross-Feature Integration Points

### Decision: Hook into iteration closeout via Squad coordinator

**Rationale**:
- Feature 014 established handoff format
- Feature 016 established boundary discipline
- Dashboard automatically invoked at closeout, stored as iteration artifact

**Integration**:

1. **Iteration closeout hook** (in Squad coordinator or `scaffold-reviewer-artifacts.ps1`)
   ```powershell
   # After reviewer artifacts generated, before handoff:
   & (Join-Path $scriptsRoot 'specrew-where.ps1') `
       --project-path $projectPath `
       --compact `
       --output-path (Join-Path $iterationPath 'dashboard.md')
   ```

2. **Squad routing** (`.squad\directives\` or agent prompt)
   - "repository status" or "project status" → invoke dashboard
   - General conversational "status" → do NOT invoke dashboard

3. **User-facing docs** (`docs\user-guide.md` or dashboard education)
   - Explain each section
   - Roadmap maintenance instructions
   - Interpretation guidance

**Alternative considered**:
- Git hooks → Rejected: out of scope per spec line 55
- Manual-only invocation → Rejected: conflicts with User Story 3

**Evidence**:
- FR-010+ (not shown: covers lifecycle integration)
- User Story 3 (lines 102-115): "dashboard as part of normal lifecycle work"
- Clarification #6 (line 25): "iteration-closeout and feature-closeout boundaries"

---

## Summary of Key Decisions

| Decision Area | Choice | Primary Rationale |
|---------------|--------|-------------------|
| Command wiring | Switch dispatch in `specrew.ps1`, dedicated `specrew-where.ps1` | Consistency with existing commands |
| Color detection | Multi-layer: `--no-color`, `NO_COLOR`, redirection, `TERM`, CI | Spec mandates NO_COLOR + dumb terminal + non-TTY |
| Visual elements | ASCII progress bars, horizontal bars, tables, optional sparkline | Monochrome-safe, console-first, low-noise |
| Compact mode | Fixed 24-line budget with prioritized sections | Testable, reproducible, iteration closeout stability |
| Entry point | CmdletBinding + Unix-style args + shared-governance sourcing | Matches `specrew-review.ps1` pattern |
| Data sources | Parse iteration `state.md`, retros, new `.specrew\roadmap.yml` | Canonical sources per FR-002 |
| Error handling | Bounded warnings + partial rendering | FR-008 resilience requirement |
| Testing | Integration tests + fixture validation | "Testable" per clarification #2 |
| Roadmap format | YAML at `.specrew\roadmap.yml` with phases + features | Structured, parseable, consistent with existing configs |
| Closeout hook | Invoke dashboard during iteration closeout, store as artifact | User Story 3, automatic lifecycle integration |

---

## Deferred to Implementation

- Exact roadmap drift detection rules (Feature 013 validator pattern applies)
- Full-history iteration summary bar chart exact rendering (pending iteration data aggregation)
- JSON output schema (for `--json` flag)
- Velocity calculation edge cases (zero-day iterations, incomplete data)
- Team-view reserved flag message wording
- Dashboard education content structure in docs/

---

## References

- **Spec**: `specs\017-velocity-dashboard\spec.md`
- **Existing patterns**:
  - Command dispatch: `scripts\specrew.ps1:93-176`
  - Parameter handling: `scripts\specrew-review.ps1:1-41`
  - Markdown parsing: `scripts\specrew-start.ps1:273-343`
  - Console detection: `extensions\specrew-speckit\scripts\scaffold-reviewer-artifacts.ps1:2504`
  - Color usage: `scripts\specrew-review.ps1:343`, `scripts\specrew-team.ps1:91-101`
- **Testing patterns**: `tests\integration\*.ps1`
- **Config patterns**: `.specrew\config.yml`, `.specrew\iteration-config.yml`

---

**Next steps**: Share this decision document with Squad, authorize implementation planning, validate against FR-001 through FR-009 during tasks phase.
