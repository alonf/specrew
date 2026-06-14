[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Feature 182 iteration 003 unit tests (T305, FR-019):
#   The automated PR reviewer is OPT-IN + forge-neutral — Specrew never bakes in a forge or a reviewer.
#   An automated reviewer is active ONLY when (a) the project opted in via
#   review_gate.automated_review.enabled AND (b) the configured provider's capability is present.
# Hermetic: temp project dirs (in the system temp, NOT git repos) hold per-scenario governance files.

function Write-Pass { param([string]$m) Write-Host "PASS: $m" -ForegroundColor Green }
function Write-Fail { param([string]$m) Write-Host "FAIL: $m" -ForegroundColor Red; exit 1 }
function Assert-True { param([bool]$c, [string]$m) if (-not $c) { Write-Fail $m } Write-Pass $m }

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
. (Join-Path $repoRoot 'extensions\specrew-speckit\scripts\shared-governance.ps1')

function New-TempProject {
    $dir = Join-Path ([System.IO.Path]::GetTempPath()) ("fnr-" + [Guid]::NewGuid().ToString('N'))
    $null = New-Item -ItemType Directory -Path (Join-Path $dir '.specrew') -Force
    return $dir
}
function Set-Gov { param([string]$Dir, [string]$Body) Set-Content -LiteralPath (Join-Path $Dir '.specrew\repository-governance.yml') -Value $Body -Encoding UTF8 }

$temps = @()
try {
    # --- 1. no governance file -> opt-out default (forge-neutral): Enabled=false, reviewer inactive ---
    $t1 = New-TempProject; $temps += $t1
    $o1 = Get-SpecrewAutomatedReviewOptIn -ProjectRoot $t1
    Assert-True (-not [bool]$o1.Enabled) 'T305: no governance file -> automated review opt-in is OFF (forge-neutral default)'
    $h1 = Test-HostProvidesAutomatedPrReview -ProjectRoot $t1
    Assert-True ($h1.ContainsKey('Active') -and -not [bool]$h1.Active) 'T305: no opt-in -> Active=false (human review only; no baked-in reviewer)'

    # --- 2. automated_review.enabled:false -> still OFF ---
    $t2 = New-TempProject; $temps += $t2
    Set-Gov -Dir $t2 -Body "repository_governance:`n  provider: github`n  review_gate:`n    automated_review:`n      enabled: false`n      provider_suggestion: copilot`n"
    $o2 = Get-SpecrewAutomatedReviewOptIn -ProjectRoot $t2
    Assert-True (-not [bool]$o2.Enabled) 'T305: automated_review.enabled:false -> opt-in OFF'
    $h2 = Test-HostProvidesAutomatedPrReview -ProjectRoot $t2
    Assert-True (-not [bool]$h2.Active) 'T305: enabled:false -> Active=false'

    # --- 3. enabled:true + provider_suggestion read correctly (incl. inline comment) ---
    $t3 = New-TempProject; $temps += $t3
    Set-Gov -Dir $t3 -Body "repository_governance:`n  provider: github`n  review_gate:`n    human_review:`n      required_approvals: 1`n    automated_review:`n      enabled: true                 # opted in`n      provider_suggestion: copilot`n    merge_requires: [human_review]`n"
    $o3 = Get-SpecrewAutomatedReviewOptIn -ProjectRoot $t3
    Assert-True ([bool]$o3.Enabled) 'T305: automated_review.enabled:true -> opt-in ON (inline comment tolerated)'
    Assert-True ($o3.ProviderSuggestion -eq 'copilot') "T305: provider_suggestion parsed as 'copilot' (got '$($o3.ProviderSuggestion)')"

    # --- 4. KEY forge-neutral assertion: opted in but the forge capability is ABSENT (temp dir, no GitHub
    #        remote) -> Active=false. Opt-in alone NEVER bakes in a reviewer without the capability. ---
    $h3 = Test-HostProvidesAutomatedPrReview -ProjectRoot $t3
    Assert-True ($h3.ContainsKey('Active') -and -not [bool]$h3.Active) 'T305: opted-in but no GitHub capability present -> Active=false (no baked-in reviewer; honest inactive)'

    # --- 5. a non-GitHub forge opted in -> still no baked-in reviewer until a verified adapter exists ---
    $t5 = New-TempProject; $temps += $t5
    Set-Gov -Dir $t5 -Body "repository_governance:`n  provider: gitlab`n  review_gate:`n    automated_review:`n      enabled: true`n      provider_suggestion: gitlab-suggested-reviewer`n"
    $o5 = Get-SpecrewAutomatedReviewOptIn -ProjectRoot $t5
    Assert-True ([bool]$o5.Enabled -and $o5.ProviderSuggestion -eq 'gitlab-suggested-reviewer') 'T305: a non-GitHub forge opt-in is read honestly'
    $h5 = Test-HostProvidesAutomatedPrReview -ProjectRoot $t5
    Assert-True (-not [bool]$h5.Active) 'T305: non-GitHub forge -> Active=false (no shipped adapter; never baked-in Copilot)'

    # --- 6. the helper NEVER hardcodes a reviewer when not opted in (string-level forge-neutrality) ---
    $fnDef = (Get-Command Test-HostProvidesAutomatedPrReview).Definition
    Assert-True ($fnDef -match 'Get-SpecrewAutomatedReviewOptIn') 'T305: Test-HostProvidesAutomatedPrReview routes through the opt-in gate (no unconditional reviewer)'
}
finally {
    foreach ($t in $temps) { Remove-Item -LiteralPath $t -Recurse -Force -ErrorAction SilentlyContinue }
}

Write-Host "`nAll T305 forge-neutral reviewer (opt-in) assertions passed." -ForegroundColor Green
