# Feature 171 T003: scope-catalog validity tests (FR-003, deploy-time validation).
# Validates the REAL shipped refocus-scopes.json: schema, scope->digest integrity,
# trigger references, budgets, provider-registry rows (incl. the kind field +
# F-165 dormant-gate invariants), and boundary.next placeholder resolution
# through the real engine.
[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$script:Failures = 0
function Write-Pass { param([string]$Message) Write-Host "PASS: $Message" -ForegroundColor Green }
function Write-Fail { param([string]$Message) Write-Host "FAIL: $Message" -ForegroundColor Red; $script:Failures++ }
function Assert-True { param([bool]$Condition, [string]$Message) if ($Condition) { Write-Pass $Message } else { Write-Fail $Message } }

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$catalogPath = Join-Path $repoRoot 'extensions\specrew-speckit\refocus-scopes.json'

# --- 1. Parse + schema ---------------------------------------------------------
Assert-True (Test-Path -LiteralPath $catalogPath -PathType Leaf) 'refocus-scopes.json exists (canonical)'
$catalog = Get-Content -LiteralPath $catalogPath -Raw -Encoding UTF8 | ConvertFrom-Json
Assert-True ([string]$catalog.schema_version -eq '1') 'schema_version is 1'
foreach ($key in @('scopes', 'triggers', 'budgets', 'providers')) {
    Assert-True ($null -ne $catalog.PSObject.Properties[$key]) "catalog declares '$key'"
}

# --- 2. Scope -> digest integrity + confinement ----------------------------------
$expectedScopes = @('general') + (@('specify', 'clarify', 'plan', 'tasks', 'before-implement', 'implement', 'review-signoff', 'retro', 'iteration-closeout', 'feature-closeout') | ForEach-Object { "boundary.$_" })
foreach ($scope in $expectedScopes) {
    Assert-True ($null -ne $catalog.scopes.PSObject.Properties[$scope]) "scope '$scope' is mapped"
}
foreach ($prop in $catalog.scopes.PSObject.Properties) {
    foreach ($rel in @($prop.Value)) {
        $relStr = [string]$rel
        Assert-True (-not [System.IO.Path]::IsPathRooted($relStr) -and ($relStr -notmatch '(^|[\\/])\.\.([\\/]|$)')) "scope '$($prop.Name)' path is repo-relative + confined ($relStr)"
        $resolved = if ($relStr -like 'refocus/*') { Join-Path $repoRoot ('extensions\specrew-speckit\' + $relStr) } else { Join-Path $repoRoot $relStr }
        Assert-True (Test-Path -LiteralPath $resolved -PathType Leaf) "scope '$($prop.Name)' source exists ($relStr)"
    }
}

# --- 3. Trigger references + budgets ----------------------------------------------
$validPlaceholders = @('boundary.current', 'boundary.next')
foreach ($trigger in @('b1', 'b2', 'b3')) {
    Assert-True ($null -ne $catalog.triggers.PSObject.Properties[$trigger]) "trigger '$trigger' is declared"
    $entry = $catalog.triggers.$trigger
    Assert-True ($null -ne $entry.PSObject.Properties['enabled']) "trigger '$trigger' carries an enabled flag"
    foreach ($scope in @($entry.scopes)) {
        $scopeStr = [string]$scope
        $known = ($null -ne $catalog.scopes.PSObject.Properties[$scopeStr]) -or ($scopeStr -in $validPlaceholders)
        Assert-True $known "trigger '$trigger' scope '$scopeStr' is a known scope or placeholder"
    }
    Assert-True ($null -ne $catalog.budgets.PSObject.Properties[$trigger] -and [int]$catalog.budgets.$trigger -gt 0) "trigger '$trigger' has a positive budget"
}
Assert-True ([int]$catalog.budgets.manual -gt 0) 'manual budget is positive'

# --- 4. Provider registry (C3 + F-165 seat invariants) -----------------------------
$providers = @($catalog.providers)
Assert-True ($providers.Count -ge 1) 'provider registry has at least one row'
$ordersSeen = @{}
foreach ($row in $providers) {
    foreach ($field in @('id', 'kind', 'events', 'order', 'command')) {
        Assert-True ($null -ne $row.PSObject.Properties[$field]) "provider '$([string]$row.id)' declares '$field'"
    }
    Assert-True ([string]$row.kind -in @('inject', 'gate')) "provider '$([string]$row.id)' kind is inject|gate"
    if ([string]$row.kind -eq 'inject') {
        Assert-True ($null -ne $row.PSObject.Properties['budget_share']) "inject provider '$([string]$row.id)' declares budget_share"
    }
    Assert-True (-not $ordersSeen.ContainsKey([string]$row.order)) "provider order $([string]$row.order) is unique"
    $ordersSeen[[string]$row.order] = $true
}
$refocusRow = $providers | Where-Object { [string]$_.id -eq 'refocus' } | Select-Object -First 1
Assert-True ($null -ne $refocusRow) "registry row #1 'refocus' exists"
Assert-True ([string]$refocusRow.kind -eq 'inject') 'refocus provider is kind=inject'
# F-165 dormant-seat invariant: NO gate provider ships in F-171, and therefore no
# provider may claim PreToolUse (the registration stays dormant until the first
# gate row exists).
$gateRows = @($providers | Where-Object { [string]$_.kind -eq 'gate' })
Assert-True ($gateRows.Count -eq 0) 'no gate provider ships in F-171 (dormant F-165 seat)'
$preToolUseRows = @($providers | Where-Object { @($_.events) -contains 'PreToolUse' })
Assert-True ($preToolUseRows.Count -eq 0) 'no provider claims PreToolUse while the gate seat is dormant'

# --- 5. boundary.next resolution through the REAL engine ----------------------------
$engine = Join-Path $repoRoot 'scripts\internal\refocus.ps1'
$scratchRoot = Join-Path $repoRoot '.scratch\refocus-catalog'
$projectRoot = Join-Path $scratchRoot 'project'
if (Test-Path -LiteralPath $scratchRoot) { Remove-Item -LiteralPath $scratchRoot -Recurse -Force }
$extDir = Join-Path $projectRoot '.specify\extensions\specrew-speckit'
New-Item -ItemType Directory -Path (Join-Path $projectRoot '.specrew') -Force | Out-Null
New-Item -ItemType Directory -Path (Join-Path $extDir 'refocus') -Force | Out-Null
Copy-Item -Path (Join-Path $repoRoot 'extensions\specrew-speckit\refocus\*.md') -Destination (Join-Path $extDir 'refocus') -Force
Copy-Item -LiteralPath $catalogPath -Destination (Join-Path $extDir 'refocus-scopes.json') -Force
# Live cursor at 'implement' -> b3 (boundary.next) must inject review-signoff.
$startContext = @{ session_state = @{ boundary_type = 'implement'; feature_ref = 'catalog-fixture' } } | ConvertTo-Json -Depth 4
[System.IO.File]::WriteAllText((Join-Path $projectRoot '.specrew\start-context.json'), $startContext, [System.Text.UTF8Encoding]::new($false))

$stdoutPath = Join-Path $scratchRoot 'stdout.txt'
$stderrPath = Join-Path $scratchRoot 'stderr.txt'
$proc = Start-Process -FilePath 'pwsh' -ArgumentList @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $engine, '--trigger', 'b3') `
    -WorkingDirectory $projectRoot -Wait -PassThru -NoNewWindow `
    -RedirectStandardOutput $stdoutPath -RedirectStandardError $stderrPath
$stdout = (Get-Content -LiteralPath $stdoutPath -Raw -ErrorAction SilentlyContinue) ?? ''
Assert-True ($proc.ExitCode -eq 0) 'b3 against the real catalog exits 0'
$firstLine = ($stdout -split "`r?`n")[0]
Assert-True ($firstLine -match 'trigger=b3 scope=general\+boundary\.review-signoff ') "b3 at implement resolves boundary.next to review-signoff (got: $firstLine)"
Assert-True ($stdout.Contains('Review-signoff-stage discipline')) 'b3 payload carries the incoming stage digest'

# Cursor at the last stage: boundary.next degrades to general (no successor).
$startContext = @{ session_state = @{ boundary_type = 'feature-closeout'; feature_ref = 'catalog-fixture' } } | ConvertTo-Json -Depth 4
[System.IO.File]::WriteAllText((Join-Path $projectRoot '.specrew\start-context.json'), $startContext, [System.Text.UTF8Encoding]::new($false))
$proc = Start-Process -FilePath 'pwsh' -ArgumentList @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $engine, '--trigger', 'b3') `
    -WorkingDirectory $projectRoot -Wait -PassThru -NoNewWindow `
    -RedirectStandardOutput $stdoutPath -RedirectStandardError $stderrPath
$stdout = (Get-Content -LiteralPath $stdoutPath -Raw -ErrorAction SilentlyContinue) ?? ''
Assert-True ($proc.ExitCode -eq 0) 'b3 at the terminal stage exits 0'
$firstLine = ($stdout -split "`r?`n")[0]
Assert-True ($firstLine -match 'trigger=b3 scope=general ') "b3 at feature-closeout degrades to general only (got: $firstLine)"

# --- summary ------------------------------------------------------------------------
if (Test-Path -LiteralPath $scratchRoot) { Remove-Item -LiteralPath $scratchRoot -Recurse -Force }
if ($script:Failures -gt 0) {
    Write-Host "refocus-catalog tests: $script:Failures failure(s)" -ForegroundColor Red
    exit 1
}
Write-Host 'refocus-catalog tests: all passed' -ForegroundColor Green
exit 0
