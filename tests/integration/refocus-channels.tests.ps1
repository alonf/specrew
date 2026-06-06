# Feature 171 T004: channel-1 WrapperEmission integration tests (FR-006).
# Drives the REAL deployed wrapper (extensions/.../sync-boundary-state.ps1) on a
# scratch project (SPECREW_MODULE_PATH -> this repo's dev tree) and asserts the
# incoming stage's digest rides the wrapper's stdout, the emission is
# fingerprinted, the catalog disable silences it, and a missing engine fails open.
[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$script:Failures = 0
function Write-Pass { param([string]$Message) Write-Host "PASS: $Message" -ForegroundColor Green }
function Write-Fail { param([string]$Message) Write-Host "FAIL: $Message" -ForegroundColor Red; $script:Failures++ }
function Assert-True { param([bool]$Condition, [string]$Message) if ($Condition) { Write-Pass $Message } else { Write-Fail $Message } }

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$moduleVersion = [string](Import-PowerShellDataFile (Join-Path $repoRoot 'Specrew.psd1')).ModuleVersion
$scratchRoot = Join-Path $repoRoot '.scratch\refocus-channels'
$projectRoot = Join-Path $scratchRoot 'project'

if (Test-Path -LiteralPath $scratchRoot) { Remove-Item -LiteralPath $scratchRoot -Recurse -Force }

function New-ScratchProject {
    if (Test-Path -LiteralPath $projectRoot) { Remove-Item -LiteralPath $projectRoot -Recurse -Force }
    $scriptsDir = Join-Path $projectRoot '.specify\extensions\specrew-speckit\scripts'
    $refocusDir = Join-Path $projectRoot '.specify\extensions\specrew-speckit\refocus'
    New-Item -ItemType Directory -Path (Join-Path $projectRoot '.specrew') -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $projectRoot '.squad') -Force | Out-Null
    New-Item -ItemType Directory -Path $scriptsDir -Force | Out-Null
    New-Item -ItemType Directory -Path $refocusDir -Force | Out-Null

    # Deployed surfaces: the REAL wrapper + REAL engine + REAL digests + catalog.
    Copy-Item -LiteralPath (Join-Path $repoRoot 'extensions\specrew-speckit\scripts\sync-boundary-state.ps1') -Destination $scriptsDir -Force
    Copy-Item -LiteralPath (Join-Path $repoRoot 'scripts\internal\refocus.ps1') -Destination $scriptsDir -Force
    Copy-Item -Path (Join-Path $repoRoot 'extensions\specrew-speckit\refocus\*.md') -Destination $refocusDir -Force
    Copy-Item -LiteralPath (Join-Path $repoRoot 'extensions\specrew-speckit\refocus-scopes.json') -Destination (Join-Path $projectRoot '.specify\extensions\specrew-speckit') -Force

    # Project state: config (version matches dev tree so the stale-install guard
    # passes), start context, minimal squad ledger.
    [System.IO.File]::WriteAllText((Join-Path $projectRoot '.specrew\config.yml'), "specrew_version: `"$moduleVersion`"`n", [System.Text.UTF8Encoding]::new($false))
    $startContext = @{ session_state = @{ boundary_type = ''; feature_ref = 'test-feature' }; boundary_enforcement = @{ enabled = $false } } | ConvertTo-Json -Depth 4
    [System.IO.File]::WriteAllText((Join-Path $projectRoot '.specrew\start-context.json'), $startContext, [System.Text.UTF8Encoding]::new($false))
    [System.IO.File]::WriteAllText((Join-Path $projectRoot '.squad\decisions.md'), "# Decisions`n", [System.Text.UTF8Encoding]::new($false))
    & git -C $projectRoot init --quiet 2>$null | Out-Null
}

function Invoke-Wrapper {
    param([string[]]$WrapperArgs)
    $wrapper = Join-Path $projectRoot '.specify\extensions\specrew-speckit\scripts\sync-boundary-state.ps1'
    $stdoutPath = Join-Path $scratchRoot 'stdout.txt'
    $stderrPath = Join-Path $scratchRoot 'stderr.txt'
    $prevModulePath = $env:SPECREW_MODULE_PATH
    $env:SPECREW_MODULE_PATH = $repoRoot
    try {
        $proc = Start-Process -FilePath 'pwsh' -ArgumentList (@('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $wrapper) + $WrapperArgs) `
            -WorkingDirectory $projectRoot -Wait -PassThru -NoNewWindow `
            -RedirectStandardOutput $stdoutPath -RedirectStandardError $stderrPath
        return @{
            ExitCode = $proc.ExitCode
            StdOut   = (Get-Content -LiteralPath $stdoutPath -Raw -ErrorAction SilentlyContinue) ?? ''
            StdErr   = (Get-Content -LiteralPath $stderrPath -Raw -ErrorAction SilentlyContinue) ?? ''
        }
    }
    finally {
        if ($null -eq $prevModulePath) { Remove-Item Env:SPECREW_MODULE_PATH -ErrorAction SilentlyContinue } else { $env:SPECREW_MODULE_PATH = $prevModulePath }
    }
}

# --- 1. Golden path: sync specify -> wrapper stdout carries the CLARIFY digest ---
New-ScratchProject
$result = Invoke-Wrapper -WrapperArgs @('-ProjectPath', '.', '-BoundaryType', 'specify', '-FeatureRef', 'test-feature', '-AuthCommitHash', 'abc1234')
Assert-True ($result.ExitCode -eq 0) "sync + emission exits 0 (stderr: $($result.StdErr.Substring(0, [Math]::Min(200, $result.StdErr.Length))))"
Assert-True ($result.StdOut -match '\[specrew-refocus\] trigger=b3 scope=general\+boundary\.clarify ') 'emission banner names the INCOMING stage (specify -> clarify)'
Assert-True ($result.StdOut.Contains('Clarify-stage discipline')) 'clarify digest body rides the wrapper stdout'
Assert-True ($result.StdOut.Contains('always-true core')) 'general digest rides along (composition)'
$fingerprintPath = Join-Path $projectRoot '.specrew\runtime\refocus-channel1.json'
Assert-True (Test-Path -LiteralPath $fingerprintPath -PathType Leaf) 'channel-1 fingerprint file written'
$fingerprint = Get-Content -LiteralPath $fingerprintPath -Raw | ConvertFrom-Json
Assert-True ([string]$fingerprint.boundary -eq 'specify') 'fingerprint records the synced boundary'

# --- 2. Catalog disable silences the emission (durable kill switch) --------------
New-ScratchProject
$catalogPath = Join-Path $projectRoot '.specify\extensions\specrew-speckit\refocus-scopes.json'
$catalog = Get-Content -LiteralPath $catalogPath -Raw | ConvertFrom-Json
$catalog.triggers.b3.enabled = $false
[System.IO.File]::WriteAllText($catalogPath, ($catalog | ConvertTo-Json -Depth 6), [System.Text.UTF8Encoding]::new($false))
$result = Invoke-Wrapper -WrapperArgs @('-ProjectPath', '.', '-BoundaryType', 'specify', '-FeatureRef', 'test-feature', '-AuthCommitHash', 'abc1234')
Assert-True ($result.ExitCode -eq 0) 'disabled-trigger sync exits 0'
Assert-True (-not $result.StdOut.Contains('[specrew-refocus]')) 'catalog b3 disable yields NO emission (operator intent, silent)'
Assert-True (-not (Test-Path -LiteralPath $fingerprintPath -PathType Leaf)) 'no fingerprint written when emission is disabled'

# --- 3. Missing engine fails open (sync unaffected) -------------------------------
New-ScratchProject
Remove-Item -LiteralPath (Join-Path $projectRoot '.specify\extensions\specrew-speckit\scripts\refocus.ps1') -Force
$result = Invoke-Wrapper -WrapperArgs @('-ProjectPath', '.', '-BoundaryType', 'specify', '-FeatureRef', 'test-feature', '-AuthCommitHash', 'abc1234')
Assert-True ($result.ExitCode -eq 0) 'missing engine: sync still exits 0 (fail-open)'
Assert-True ($result.StdOut.Contains('"boundary_type"') -or $result.StdOut.Contains('boundary_type')) 'sync result JSON still emitted'
Assert-True (-not $result.StdOut.Contains('[specrew-refocus]')) 'no emission without the engine'

# --- 4. Emission failure never fails the sync (engine present but broken) ---------
New-ScratchProject
[System.IO.File]::WriteAllText((Join-Path $projectRoot '.specify\extensions\specrew-speckit\scripts\refocus.ps1'), "throw 'engine exploded'", [System.Text.UTF8Encoding]::new($false))
$result = Invoke-Wrapper -WrapperArgs @('-ProjectPath', '.', '-BoundaryType', 'specify', '-FeatureRef', 'test-feature', '-AuthCommitHash', 'abc1234')
Assert-True ($result.ExitCode -eq 0) 'broken engine: sync still exits 0 (fail-open)'

# --- 5. Channel 2: primer pointer in the coordinator governance template (FR-007) ---
foreach ($templatePath in @(
        (Join-Path $repoRoot 'extensions\specrew-speckit\squad-templates\coordinator\specrew-governance.md'),
        (Join-Path $repoRoot '.specify\extensions\specrew-speckit\squad-templates\coordinator\specrew-governance.md')
    )) {
    $shortName = $templatePath.Substring($repoRoot.Length + 1)
    $content = Get-Content -LiteralPath $templatePath -Raw -Encoding UTF8
    Assert-True ($content.Contains('/specrew-refocus')) "primer pointer present in $shortName"
    Assert-True ($content.Contains('[specrew-refocus]') -and $content -match 'binding stage discipline') "emission-block treatment rule present in $shortName"
}

# --- summary ------------------------------------------------------------------------
if (Test-Path -LiteralPath $scratchRoot) { Remove-Item -LiteralPath $scratchRoot -Recurse -Force }
if ($script:Failures -gt 0) {
    Write-Host "refocus-channels tests: $script:Failures failure(s)" -ForegroundColor Red
    exit 1
}
Write-Host 'refocus-channels tests: all passed' -ForegroundColor Green
exit 0
