[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Feature 051 Iteration 2b acceptance tests.
# Covers T034-T041 (decisions split, JSONL append, manifest sort) and T042-T052
# (multi-developer signal detection + recommendation suppression).

function Write-Pass { param([string]$m) Write-Host "PASS: $m" -ForegroundColor Green }
function Write-Fail { param([string]$m) Write-Host "FAIL: $m" -ForegroundColor Red }
function Assert-True { param([bool]$c, [string]$m) if (-not $c) { Write-Fail $m; exit 1 } Write-Pass $m }
function Assert-Match { param([string]$Text, [string]$Pattern, [string]$Message) Assert-True ([regex]::IsMatch($Text, $Pattern)) $Message }
function Assert-NoMatch { param([string]$Text, [string]$Pattern, [string]$Message) Assert-True (-not [regex]::IsMatch($Text, $Pattern)) $Message }

$repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
. (Join-Path $repoRoot 'scripts/decisions-split.ps1')
. (Join-Path $repoRoot 'scripts/append-only-logs.ps1')
. (Join-Path $repoRoot 'scripts/psd1-sort.ps1')
. (Join-Path $repoRoot 'scripts/auto-detection.ps1')

function New-TempProject {
    $d = Join-Path ([System.IO.Path]::GetTempPath()) ("specrew-f051-i2b-{0}" -f ([System.Guid]::NewGuid().ToString('N')))
    New-Item -ItemType Directory -Path (Join-Path $d '.specrew') -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $d '.squad') -Force | Out-Null
    Set-Content -LiteralPath (Join-Path $d '.specrew/config.yml') -Value "session_mode: `"single`"" -Encoding UTF8
    return $d
}

function Invoke-Git {
    param(
        [Parameter(Mandatory = $true)][string]$ProjectRoot,
        [Parameter(Mandatory = $true)][string[]]$Arguments
    )

    $output = @(& git -C $ProjectRoot @Arguments 2>&1)
    if ($LASTEXITCODE -ne 0) {
        throw ("git {0} failed: {1}" -f ($Arguments -join ' '), ($output -join [Environment]::NewLine))
    }
    return $output
}

# --- T034/T040: decisions split into per-iteration files, idempotent ---
$p = New-TempProject
try {
    $ledger = @'
# Decisions

## 2026-06-01T00:00:00Z - Iteration 003 decision

- **Type**: boundary-sync
- **Iteration Number**: 003
- **Rationale**: keep this in iteration 003

## 2026-06-01T00:01:00Z - Iteration 004 decision

- **Type**: boundary-sync
- **Iteration Number**: 004
- **Rationale**: keep this in iteration 004
'@
    Set-Content -LiteralPath (Join-Path $p '.squad/decisions.md') -Value $ledger -Encoding UTF8
    $first = Split-SpecrewDecisionsByIteration -ProjectRoot $p -PassThru
    Assert-True ($first.iteration_numbers -contains '003' -and $first.iteration_numbers -contains '004') "T034: decisions split finds iteration 003 and 004 entries"
    $iter003 = Get-Content -LiteralPath (Join-Path $p '.squad/decisions/iteration-003/decisions.md') -Raw -Encoding UTF8
    Assert-Match $iter003 'Iteration 003 decision' "T040: iteration-003 file contains the iteration-003 decision"
    Assert-NoMatch $iter003 'Iteration 004 decision' "T040: iteration-003 file excludes iteration-004 entries"
    $second = Split-SpecrewDecisionsByIteration -ProjectRoot $p -PassThru
    Assert-True ($second.written_count -eq 0) "T034: decisions split is idempotent on a second run"
}
finally { Remove-Item -LiteralPath $p -Recurse -Force -ErrorAction SilentlyContinue }

# --- T036/T037: JSON Lines append-only lifecycle event log ---
$p = New-TempProject
try {
    Add-SpecrewLifecycleEvent -ProjectRoot $p -EventType 'boundary-sync' -NowUtc '2026-06-01T00:00:00Z' -Payload @{ boundary_type = 'plan'; feature_ref = '051-x' }
    Add-SpecrewLifecycleEvent -ProjectRoot $p -EventType 'boundary-sync' -NowUtc '2026-06-01T00:01:00Z' -Payload @{ boundary_type = 'before-implement'; feature_ref = '051-x' }
    $eventsPath = Get-SpecrewLifecycleEventsPath -ProjectRoot $p
    $lines = @(Get-Content -LiteralPath $eventsPath -Encoding UTF8)
    Assert-True ($lines.Count -eq 2) "T036: lifecycle event log appends one JSON object per line"
    $events = @(Read-SpecrewJsonLines -Path $eventsPath)
    Assert-True ($events.Count -eq 2 -and $events[1]['payload']['boundary_type'] -eq 'before-implement') "T037: JSON Lines reader returns structured lifecycle payloads"
}
finally { Remove-Item -LiteralPath $p -Recurse -Force -ErrorAction SilentlyContinue }

# --- T038/T041: manifest FileList alphabetical sort preserves parseability/membership ---
$p = New-TempProject
try {
    $manifestPath = Join-Path $p 'Specrew.psd1'
    @'
@{
    RootModule = 'Specrew.psm1'
    FileList = @(
        'z.ps1',
        'a.ps1',
        'm.ps1'
    )
    PrivateData = @{ PSData = @{} }
}
'@ | Set-Content -LiteralPath $manifestPath -Encoding UTF8
    $result = Sort-SpecrewManifestFileList -ManifestPath $manifestPath -PassThru
    Assert-True ($result.changed) "T038: unsorted FileList reports a change"
    $data = Import-PowerShellDataFile -Path $manifestPath
    Assert-True (($data.FileList -join ',') -eq 'a.ps1,m.ps1,z.ps1') "T041: FileList remains parseable and alphabetically sorted"
}
finally { Remove-Item -LiteralPath $p -Recurse -Force -ErrorAction SilentlyContinue }

# --- T042/T043/T047/T051: two recent git authors trigger recommendation within 2s ---
$p = New-TempProject
try {
    Invoke-Git -ProjectRoot $p -Arguments @('init') | Out-Null
    Invoke-Git -ProjectRoot $p -Arguments @('-c','user.name=Dev One','-c','user.email=dev1@example.test','commit','--allow-empty','-m','dev-one') | Out-Null
    Invoke-Git -ProjectRoot $p -Arguments @('-c','user.name=Dev Two','-c','user.email=dev2@example.test','commit','--allow-empty','-m','dev-two') | Out-Null
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    $signals = Get-SpecrewMultiDeveloperSignals -ProjectRoot $p
    $sw.Stop()
    Assert-True ($signals.unique_git_author_count -eq 2) "T043: detector counts two unique recent git authors"
    Assert-True ($signals.has_multi_developer_signal -and -not [string]::IsNullOrWhiteSpace($signals.recommendation_message)) "T047/T051: single-session multi-dev signal returns a recommendation"
    Assert-True ($sw.Elapsed.TotalSeconds -lt 2) "T051: recommendation generated within 2 seconds"
}
finally { Remove-Item -LiteralPath $p -Recurse -Force -ErrorAction SilentlyContinue }

# --- T044/T050/T052: machine count detected; session_mode multi suppresses recommendation ---
$p = New-TempProject
try {
    Set-Content -LiteralPath (Join-Path $p '.specrew/active-sessions.yml') -Value @'
sessions:
  - feature_id: "051-x"
    user: "a"
    machine_fingerprint: "HOST-A-secret"
    session_start_time: "2026-06-01T00:00:00Z"
    last_heartbeat_time: "2026-06-01T00:00:00Z"
  - feature_id: "051-y"
    user: "b"
    machine_fingerprint: "HOST-B-secret"
    session_start_time: "2026-06-01T00:01:00Z"
    last_heartbeat_time: "2026-06-01T00:01:00Z"
'@ -Encoding UTF8
    $signals = Get-SpecrewMultiDeveloperSignals -ProjectRoot $p
    Assert-True ($signals.unique_machine_count -eq 2) "T044: detector counts unique machine fingerprints from local active-sessions.yml"
    Assert-NoMatch ([string]$signals.recommendation_message) 'HOST-A-secret|HOST-B-secret' "T044: recommendation does not expose rich machine fingerprints"

    Set-Content -LiteralPath (Join-Path $p '.specrew/config.yml') -Value "session_mode: `"multi`"" -Encoding UTF8
    $suppressed = Get-SpecrewMultiDeveloperSignals -ProjectRoot $p
    Assert-True ($suppressed.has_multi_developer_signal -and $suppressed.recommendation_suppressed) "T050: multi-session mode records suppression while preserving signal"
    Assert-True ([string]::IsNullOrWhiteSpace([string]$suppressed.recommendation_message)) "T052: session_mode multi suppresses redundant recommendation"
}
finally { Remove-Item -LiteralPath $p -Recurse -Force -ErrorAction SilentlyContinue }

# --- SC-008 (Feature 141 FR-012): a single developer's own bootstrap writes must NOT
#     trigger a spurious "Multiple developers detected" recommendation. Reproduce-first:
#     `specrew init`/`specrew start` write start-context.json + last-start-prompt.md +
#     decisions.md within ~1s of each other on every fresh project, so writeSignals>=1 even
#     with 0 git authors / 0 machines / 0 branch fanout. Close-together shared-state writes
#     cannot attribute activity to distinct actors, so they must only CORROBORATE a genuine
#     signal, never trigger the recommendation alone. ---
$p = New-TempProject
try {
    Set-Content -LiteralPath (Join-Path $p '.specrew/start-context.json') -Value '{"schema":"v2"}' -Encoding UTF8
    Set-Content -LiteralPath (Join-Path $p '.specrew/last-start-prompt.md') -Value "---`nx: 1`n---`n" -Encoding UTF8
    Set-Content -LiteralPath (Join-Path $p '.squad/decisions.md') -Value "# Decisions`n" -Encoding UTF8
    $bootstrapInstant = [DateTime]::UtcNow
    foreach ($f in @('.specrew/start-context.json', '.specrew/last-start-prompt.md', '.squad/decisions.md')) {
        (Get-Item -LiteralPath (Join-Path $p $f)).LastWriteTimeUtc = $bootstrapInstant
    }
    $signals = Get-SpecrewMultiDeveloperSignals -ProjectRoot $p
    Assert-True ($signals.unique_git_author_count -eq 0 -and $signals.unique_machine_count -eq 0 -and $signals.branch_fanout_count -eq 0) "SC-008: fixture is a single-developer fresh project (0 authors, 0 machines, 0 branch fanout)"
    Assert-True ($signals.concurrent_write_count -ge 1) "SC-008: bootstrap writes ARE close-together (the spurious-warning precondition is present)"
    Assert-True (-not $signals.has_multi_developer_signal) "SC-008/FR-012: single-developer bootstrap writes do NOT set a multi-developer signal"
    Assert-True ([string]::IsNullOrWhiteSpace([string]$signals.recommendation_message)) "SC-008/FR-012: no spurious 'Multiple developers detected' recommendation for a lone developer"
}
finally { Remove-Item -LiteralPath $p -Recurse -Force -ErrorAction SilentlyContinue }

# --- SC-008 (Feature 141 FR-012, preserve actionable): genuine multi-developer signals
#     (>=2 unique git authors) MUST still produce a recommendation, and close-together writes
#     remain as corroborating detail. Guards against over-suppression. ---
$p = New-TempProject
try {
    Invoke-Git -ProjectRoot $p -Arguments @('init') | Out-Null
    Invoke-Git -ProjectRoot $p -Arguments @('-c','user.name=Dev One','-c','user.email=dev1@example.test','commit','--allow-empty','-m','one') | Out-Null
    Invoke-Git -ProjectRoot $p -Arguments @('-c','user.name=Dev Two','-c','user.email=dev2@example.test','commit','--allow-empty','-m','two') | Out-Null
    Set-Content -LiteralPath (Join-Path $p '.specrew/start-context.json') -Value '{"schema":"v2"}' -Encoding UTF8
    Set-Content -LiteralPath (Join-Path $p '.specrew/last-start-prompt.md') -Value "---`nx: 1`n---`n" -Encoding UTF8
    $bootstrapInstant = [DateTime]::UtcNow
    foreach ($f in @('.specrew/start-context.json', '.specrew/last-start-prompt.md')) {
        (Get-Item -LiteralPath (Join-Path $p $f)).LastWriteTimeUtc = $bootstrapInstant
    }
    $signals = Get-SpecrewMultiDeveloperSignals -ProjectRoot $p
    Assert-True ($signals.has_multi_developer_signal -and -not [string]::IsNullOrWhiteSpace($signals.recommendation_message)) "SC-008/FR-012: a genuine 2-author signal still produces a recommendation (no over-suppression)"
    Assert-Match ([string]$signals.recommendation_message) 'close-together shared-state writes' "SC-008/FR-012: write signals remain as corroborating detail alongside a genuine signal"
}
finally { Remove-Item -LiteralPath $p -Recurse -Force -ErrorAction SilentlyContinue }

Write-Host ""
Write-Host "All Feature-051 Iteration 2b acceptance tests passed." -ForegroundColor Green
exit 0
