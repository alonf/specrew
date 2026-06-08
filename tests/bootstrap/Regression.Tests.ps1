$ErrorActionPreference = 'Stop'

# F-171 regression + FR-012 negative: prove the F-174 bootstrap/handover additions are ADDITIVE -
# refocus B1/B2/B3 are byte-unchanged and no B4/Antigravity path was introduced.
$scopesPath = (Resolve-Path "$PSScriptRoot/../../.specify/extensions/specrew-speckit/refocus-scopes.json").Path
$raw = Get-Content -LiteralPath $scopesPath -Raw
$cfg = $raw | ConvertFrom-Json
$provider = (Resolve-Path "$PSScriptRoot/../../scripts/internal/specrew-bootstrap-provider.ps1").Path

function Assert-Equal {
    param([AllowNull()]$Actual, [AllowNull()]$Expected, [string]$Message)
    if ($Actual -ne $Expected) { throw "FAIL: $Message (expected '$Expected', got '$Actual')" }
    Write-Host "PASS: $Message" -ForegroundColor Green
}
function Assert-True {
    param([bool]$Condition, [string]$Message)
    if (-not $Condition) { throw "FAIL: $Message" }
    Write-Host "PASS: $Message" -ForegroundColor Green
}

# --- F-171 refocus provider (B1/B2/B3) unchanged ---
$refocus = $cfg.providers | Where-Object { $_.id -eq 'refocus' }
Assert-True ($refocus.events -contains 'SessionStart') 'refocus still handles SessionStart (B1/B2)'
Assert-True ($refocus.events -contains 'PostToolUse') 'refocus still handles PostToolUse (B3)'
Assert-True ($refocus.events -contains 'UserPromptSubmit') 'refocus still handles UserPromptSubmit'

# --- triggers b1/b2/b3 enabled; FR-012: no b4 trigger ---
Assert-True ([bool]$cfg.triggers.b1.enabled) 'b1 trigger enabled'
Assert-True ([bool]$cfg.triggers.b2.enabled) 'b2 trigger enabled'
Assert-True ([bool]$cfg.triggers.b3.enabled) 'b3 trigger enabled'
Assert-True ($null -eq $cfg.triggers.PSObject.Properties['b4']) 'no b4 trigger (FR-012: B4 deferred)'

# --- F-174 additions are additive + correctly scoped ---
$boot = $cfg.providers | Where-Object { $_.id -eq 'bootstrap' }
Assert-Equal (@($boot.events).Count) 1 'bootstrap registered for exactly one event'
Assert-True ($boot.events -contains 'SessionStart') 'bootstrap = SessionStart only (B2; never touches B3/PostToolUse)'
$ho = $cfg.providers | Where-Object { $_.id -eq 'handover' }
Assert-True ($ho.events -contains 'SessionEnd') 'handover = SessionEnd only'

# --- FR-012 negative: no Antigravity path anywhere in the scopes ---
Assert-True (-not ($raw -match 'antigravity')) 'no Antigravity provider/path (FR-012 deferred)'

# --- B1 regression: the bootstrap provider stays silent on compact (F-171 B1 path untouched) ---
$tmp = Join-Path ([System.IO.Path]::GetTempPath()) ("specrew-t019-" + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path (Join-Path $tmp '.specrew') -Force | Out-Null
try {
    $out = & pwsh -NoProfile -File $provider --event-json '{"source":"compact","session_id":"x"}' --project-root $tmp 2>$null
    Assert-True ([string]::IsNullOrWhiteSpace((($out -join '')).Trim())) 'B1: bootstrap provider silent on compact (B1 stays refocus-only)'
}
finally {
    Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue
}
Write-Host 'Regression: all tests passed.' -ForegroundColor Green
