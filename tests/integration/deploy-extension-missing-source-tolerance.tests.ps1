[CmdletBinding()]
param()

# Regression test for v0.27.5 hotfix:
# Verify that deploy-speckit-extension.ps1 tolerates missing optional source items
# (notably hooks/ which PSGallery/NuGet packaging drops when only .gitkeep is present),
# rather than hard-failing on Get-Item -LiteralPath of a non-existent path.
#
# Empirical motivation: 2026-05-26 tester report on installed v0.25.0 hit
#   "Cannot find path '...\extensions\specrew-speckit\hooks' because it does not exist"
# at deploy-speckit-extension.ps1:77 during specrew update.

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Write-Pass { param([string]$m) Write-Host "PASS: $m" -ForegroundColor Green }
function Write-Fail { param([string]$m) Write-Host "FAIL: $m" -ForegroundColor Red; throw $m }

$repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$realDeployScript = Join-Path $repoRoot 'extensions/specrew-speckit/scripts/deploy-speckit-extension.ps1'
$realSharedGov    = Join-Path $repoRoot 'extensions/specrew-speckit/scripts/shared-governance.ps1'

foreach ($p in @($realDeployScript, $realSharedGov)) {
    if (-not (Test-Path -LiteralPath $p)) { Write-Fail "Source file not found: $p" }
}

# Set up a synthetic "installed module" tree mimicking what PSGallery actually ships
# (every $itemsToCopy entry EXCEPT hooks/, which PSGallery drops because it contains only .gitkeep).
$testRoot = [System.IO.Path]::Combine([System.IO.Path]::GetTempPath(), "specrew-deploy-test-$([System.IO.Path]::GetRandomFileName())")
$fakeModuleRoot = Join-Path $testRoot 'module/extensions/specrew-speckit'
$fakeProjectRoot = Join-Path $testRoot 'project'

try {
    # Synthetic module tree — include every $itemsToCopy entry EXCEPT hooks/
    New-Item -ItemType Directory -Force -Path (Join-Path $fakeModuleRoot 'commands')        | Out-Null
    New-Item -ItemType Directory -Force -Path (Join-Path $fakeModuleRoot 'scripts')         | Out-Null
    New-Item -ItemType Directory -Force -Path (Join-Path $fakeModuleRoot 'templates')       | Out-Null
    New-Item -ItemType Directory -Force -Path (Join-Path $fakeModuleRoot 'squad-templates') | Out-Null

    Set-Content -LiteralPath (Join-Path $fakeModuleRoot 'extension.yml') -Value @'
schema_version: "1.0"
schema: "v1"
extension:
  id: specrew-speckit
  name: "Specrew Spec Kit Extension"
  version: "0.27.5"
  description: "test fixture"
requires:
  speckit_version: ">=0.8.4"
'@ -Encoding utf8 -NoNewline
    Set-Content -LiteralPath (Join-Path $fakeModuleRoot 'README.md')                       -Value 'test' -Encoding utf8 -NoNewline
    Set-Content -LiteralPath (Join-Path $fakeModuleRoot 'scripts/placeholder.ps1')         -Value '# placeholder' -Encoding utf8 -NoNewline

    # Copy deploy script + shared-governance into the fake scripts/ so $PSScriptRoot
    # resolves to the fake module tree when the script runs
    Copy-Item -LiteralPath $realDeployScript -Destination (Join-Path $fakeModuleRoot 'scripts/deploy-speckit-extension.ps1') -Force
    Copy-Item -LiteralPath $realSharedGov    -Destination (Join-Path $fakeModuleRoot 'scripts/shared-governance.ps1')       -Force

    # Confirm hooks/ is intentionally absent (this is the regression case)
    if (Test-Path -LiteralPath (Join-Path $fakeModuleRoot 'hooks')) {
        Write-Fail 'Test setup error: hooks/ should be absent to exercise the regression'
    }

    # Set up target project with .specify/ + extensions.yml (deploy script requires both)
    $fakeSpecifyRoot = Join-Path $fakeProjectRoot '.specify'
    New-Item -ItemType Directory -Force -Path $fakeSpecifyRoot | Out-Null
    Set-Content -LiteralPath (Join-Path $fakeSpecifyRoot 'extensions.yml') -Value 'extensions: []' -Encoding utf8 -NoNewline

    # Invoke the deploy script FROM the fake module (so $PSScriptRoot resolves to the fake tree)
    $fakeDeployScript = Join-Path $fakeModuleRoot 'scripts/deploy-speckit-extension.ps1'
    $actions = & $fakeDeployScript -ProjectPath $fakeProjectRoot -PassThru

    if ($null -eq $actions) { Write-Fail 'Deploy script returned no actions (expected at least one)' }

    # Normalize to array
    $actions = @($actions)

    # Assertion 1: deploy script did NOT throw on missing hooks/
    Write-Pass 'Deploy script completed without throwing on missing hooks/ source dir'

    # Assertion 2: a skipped-missing-source action was logged for hooks/
    $skippedHooks = @($actions | Where-Object { $_.Action -eq 'skipped-missing-source' -and $_.Path -like '*hooks*' })
    if ($skippedHooks.Count -lt 1) {
        $observed = ($actions | ForEach-Object { "$($_.Action): $($_.Path)" }) -join "`n  "
        Write-Fail "Expected a 'skipped-missing-source' action for hooks/; observed actions:`n  $observed"
    }
    Write-Pass "Logged skipped-missing-source action for hooks/ ($($skippedHooks[0].Path))"

    # Assertion 3: items AFTER hooks/ in $itemsToCopy (scripts, templates, squad-templates) were still deployed
    # (graceful degradation — script did not bail early)
    $copiedScripts = Test-Path -LiteralPath (Join-Path $fakeSpecifyRoot 'extensions/specrew-speckit/scripts')
    if (-not $copiedScripts) {
        Write-Fail 'scripts/ was not copied — deploy bailed at hooks/ instead of continuing'
    }
    Write-Pass 'Items past hooks/ in $itemsToCopy were still deployed (graceful degradation)'
}
finally {
    if (Test-Path -LiteralPath $testRoot) {
        Remove-Item -Recurse -Force -LiteralPath $testRoot -ErrorAction SilentlyContinue
    }
}

Write-Host ''
Write-Host 'All deploy-extension-missing-source-tolerance tests passed.' -ForegroundColor Green
