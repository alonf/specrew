# F-174 iteration 011 (T012, FR-028 layer 3, SC-018): the degradation diagnostic deterministic core —
# Test-SpecrewBootstrapDirectiveArrived + the warn-ONCE gate Get-SpecrewHookDegradationWarning. Proves the
# warning fires at most ONCE per session and ONLY in a Specrew project where the bootstrap directive did not
# arrive; never when it DID arrive; never outside a Specrew project; never throws (fail-open toward silence).
[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$script:Failures = 0
function Write-Pass { param([string]$Message) Write-Host "PASS: $Message" -ForegroundColor Green }
function Write-Fail { param([string]$Message) Write-Host "FAIL: $Message" -ForegroundColor Red; $script:Failures++ }
function Assert-True { param([bool]$Condition, [string]$Message) if ($Condition) { Write-Pass $Message } else { Write-Fail $Message } }

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
. (Join-Path $repoRoot 'scripts\internal\specrew-hook-health.ps1')

$scratchRoot = Join-Path $repoRoot '.scratch\hook-degradation'
function New-Project {
    param([switch]$WithExtension, [switch]$WithDirectiveTrail, [string]$SessionId)
    if (Test-Path -LiteralPath $scratchRoot) { Remove-Item -LiteralPath $scratchRoot -Recurse -Force }
    $proj = Join-Path $scratchRoot 'project'
    New-Item -ItemType Directory -Path (Join-Path $proj '.specrew\runtime') -Force | Out-Null
    if ($WithExtension) { New-Item -ItemType Directory -Path (Join-Path $proj '.specify\extensions\specrew-speckit') -Force | Out-Null }
    if ($WithDirectiveTrail) {
        $marker = @{ started_at = '2026-06-14T00:00:00Z'; host = 'claude'; session_id = $SessionId } | ConvertTo-Json
        [System.IO.File]::WriteAllText((Join-Path $proj '.specrew\runtime\session-marker.json'), $marker, [System.Text.UTF8Encoding]::new($false))
    }
    return $proj
}

# --- 1. Specrew project, NO directive trail -> warns ONCE (then silent) --------------------------------------
$proj = New-Project -WithExtension
$w1 = Get-SpecrewHookDegradationWarning -ProjectPath $proj -SessionId 'sess-1'
Assert-True (-not [string]::IsNullOrWhiteSpace($w1)) '1: warns when in a Specrew project with no bootstrap directive this session'
Assert-True ($w1 -match 'hooks do not appear active' -and $w1 -match 'specrew hooks status') '1: warning carries the FR-028 wording + the repair pointer'
$w2 = Get-SpecrewHookDegradationWarning -ProjectPath $proj -SessionId 'sess-1'
Assert-True ($null -eq $w2) '1: warn-ONCE — a second call in the same session is silent (marker recorded)'

# --- 2. a DIFFERENT session warns again (per-session, not global) --------------------------------------------
$w3 = Get-SpecrewHookDegradationWarning -ProjectPath $proj -SessionId 'sess-2'
Assert-True (-not [string]::IsNullOrWhiteSpace($w3)) '2: a new session id warns again (warn-once is per-session, not cross-session)'

# --- 3. directive DID arrive (session-marker references this session) -> never warns -------------------------
$proj = New-Project -WithExtension -WithDirectiveTrail -SessionId 'sess-live'
Assert-True (Test-SpecrewBootstrapDirectiveArrived -ProjectPath $proj -SessionId 'sess-live') '3: Test-SpecrewBootstrapDirectiveArrived true when the marker references this session'
Assert-True ($null -eq (Get-SpecrewHookDegradationWarning -ProjectPath $proj -SessionId 'sess-live')) '3: no warning when the directive arrived this session'

# --- 4. NOT a Specrew project (no deployed extension) -> never warns -----------------------------------------
$proj = New-Project   # .specrew/ present but NO .specify/extensions/specrew-speckit
Assert-True (-not (Test-SpecrewIsProject -ProjectPath $proj)) '4: a bare .specrew/ without the deployed extension is NOT a Specrew project'
Assert-True ($null -eq (Get-SpecrewHookDegradationWarning -ProjectPath $proj -SessionId 'sess-x')) '4: no warning outside a fully-provisioned Specrew project'

# --- 5. -Peek computes the verdict WITHOUT recording the warn-once marker (status/test use) -------------------
$proj = New-Project -WithExtension
$peek1 = Get-SpecrewHookDegradationWarning -ProjectPath $proj -SessionId 'sess-peek' -Peek
$peek2 = Get-SpecrewHookDegradationWarning -ProjectPath $proj -SessionId 'sess-peek' -Peek
Assert-True ((-not [string]::IsNullOrWhiteSpace($peek1)) -and (-not [string]::IsNullOrWhiteSpace($peek2))) '5: -Peek is repeatable (does NOT record the warn-once marker)'
Assert-True (-not (Test-Path -LiteralPath (Join-Path $proj '.specrew\runtime\hook-degradation-warned-sess-peek') -PathType Leaf)) '5: -Peek left no marker on disk'

# --- 6. directive-arrival session scoping: a marker for ANOTHER session does not count -----------------------
$proj = New-Project -WithExtension -WithDirectiveTrail -SessionId 'other-session'
Assert-True (-not (Test-SpecrewBootstrapDirectiveArrived -ProjectPath $proj -SessionId 'my-session')) '6: a directive trail for a DIFFERENT session does not count as arrived for mine'
Assert-True (-not [string]::IsNullOrWhiteSpace((Get-SpecrewHookDegradationWarning -ProjectPath $proj -SessionId 'my-session' -Peek))) '6: -> the diagnostic warns for my session (session-scoped)'

# --- summary -------------------------------------------------------------------------------------------------
if (Test-Path -LiteralPath $scratchRoot) { Remove-Item -LiteralPath $scratchRoot -Recurse -Force }
if ($script:Failures -gt 0) {
    Write-Host "hook-degradation-diagnostic tests: $script:Failures failure(s)" -ForegroundColor Red
    exit 1
}
Write-Host 'hook-degradation-diagnostic tests: all passed' -ForegroundColor Green
exit 0
