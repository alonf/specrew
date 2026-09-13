# PRED-BETA4-054 / B4F-095: ONE VERSION RESOLVER BEHIND THE MARKERS, config.yml AND BOTH ORIENTATIONS.
#
# The walk project on e9334af1 read "Specrew unknown is active on this host" from the turn-end orientation
# (the deployed extension marker, stamped by init's `specify extension add` path with no version), "0.40.0-beta4"
# from the SessionStart orientation (manifest plus Prerelease), "0.40.0" in config.yml (extension.yml), and the
# review-runtime marker had looked for Specrew.psd1 above the deployed copy. version-label.ps1 is the one
# resolver now. THIS SUITE RUNS THE REAL init on a scratch project from this repository's layout and reads the
# four surfaces. Mutation (recorded, not a switch): the review-runtime marker's old grandparent lookup restored
# reds case 2; init's marker write without the label restored reds case 1.

$ErrorActionPreference = 'Stop'
$script:Failures = 0
function Assert-True { param([bool]$Condition, [string]$Message) if ($Condition) { Write-Host ('  PASS: ' + $Message) } else { Write-Host ('  FAIL: ' + $Message); $script:Failures++ } }

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
. (Join-Path $repoRoot 'extensions/specrew-speckit/scripts/version-label.ps1')
$expected = Get-SpecrewModuleVersionInfo -ModuleRoot $repoRoot
$priorModulePath = $env:SPECREW_MODULE_PATH
$env:SPECREW_MODULE_PATH = $repoRoot

Write-Host 'version-label-one-resolver'
Assert-True ($expected.Source -eq 'manifest' -and $expected.Label -match '^\d+\.\d+\.\d+-[0-9A-Za-z]+$') ('the resolver reads this tree''s manifest: label {0} (base {1}, prerelease {2})' -f $expected.Label, $expected.Version, $expected.Prerelease)

$root = Join-Path ([IO.Path]::GetTempPath()) ('vlr-' + [guid]::NewGuid().ToString('N').Substring(0, 8))
New-Item -ItemType Directory -Path $root -Force | Out-Null
try {
    $initOut = (& pwsh -NoProfile -File (Join-Path $repoRoot 'scripts/specrew-init.ps1') -ProjectPath $root -Agents claude -SkipUpdateCheck -BrownfieldBootstrapCommit decline 2>&1 | ForEach-Object { [string]$_ }) -join "`n"
    Assert-True ($LASTEXITCODE -eq 0) ('the real init exits 0 (tail: ' + (($initOut -replace '\s+', ' ')).Substring([Math]::Max(0, ($initOut -replace '\s+', ' ').Length - 120)) + ')')

    Write-Host '  --- case 1: the deployed extension marker carries the full label ---'
    $marker = Get-Content -LiteralPath (Join-Path $root '.specify/extensions/specrew-speckit/.specrew-extension-runtime.json') -Raw | ConvertFrom-Json
    Assert-True ([string]$marker.specrew_version -eq $expected.Label) ('.specrew-extension-runtime.json specrew_version = {0} (expected {1})' -f $marker.specrew_version, $expected.Label)

    Write-Host '  --- case 2: the review-runtime marker carries the full label ---'
    $rtPath = Join-Path $root 'scripts/internal/continuous-co-review/.specrew-runtime.json'
    $rt = if (Test-Path -LiteralPath $rtPath) { Get-Content -LiteralPath $rtPath -Raw | ConvertFrom-Json } else { $null }
    Assert-True ($null -ne $rt -and [string]$rt.specrew_version -eq $expected.Label) ('.specrew-runtime.json specrew_version = {0}' -f $(if ($null -ne $rt) { $rt.specrew_version } else { '(absent)' }))

    Write-Host '  --- case 3: config.yml carries the BASE version, by design (Prop 134) ---'
    $cfg = Get-Content -LiteralPath (Join-Path $root '.specrew/config.yml') -Raw
    Assert-True ($cfg -match ('(?m)^specrew_version:\s*"?' + [regex]::Escape($expected.Version) + '"?\s*$')) ('config.yml specrew_version is the base {0}' -f $expected.Version)

    Write-Host '  --- case 4: both orientations say the same label ---'
    $boot = (& pwsh -NoProfile -File (Join-Path $repoRoot 'scripts/internal/specrew-bootstrap-provider.ps1') --project-root $root --host-kind claude 2>&1 | ForEach-Object { [string]$_ }) -join "`n"
    Assert-True ($boot.Contains($expected.Label)) ('the SessionStart orientation carries ' + $expected.Label)
    $turnEnd = Join-Path $root '.specify/extensions/specrew-speckit/scripts/declare-turn-end.ps1'
    $ast = [System.Management.Automation.Language.Parser]::ParseFile($turnEnd, [ref]$null, [ref]$null)
    $fn = $ast.FindAll({ param($n) $n -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $n.Name -eq 'Get-SpecrewOrientationBlock' }, $true) | Select-Object -First 1
    # the function resolves version-label.ps1 beside itself via $PSScriptRoot; extracted here, the deployed copy is
    # dot-sourced first exactly as the script's own guard would find it
    $deployedLabel = Join-Path $root '.specify/extensions/specrew-speckit/scripts/version-label.ps1'
    Assert-True (Test-Path -LiteralPath $deployedLabel -PathType Leaf) 'init deployed version-label.ps1 beside the turn-end script'
    $render = & pwsh -NoProfile -Command (". '" + $deployedLabel + "'; " + $fn.Extent.Text + "; (Get-SpecrewOrientationBlock -Root '" + $root + "' -Identity ([pscustomobject]@{ host = 'claude' })) -join `"`n`"")
    $renderText = ($render -join "`n")
    Assert-True ($renderText.Contains(('**Specrew {0} is active on claude.**' -f $expected.Label))) ('the turn-end orientation says "Specrew ' + $expected.Label + ' is active" (got: ' + (($renderText -replace '\s+', ' ')).Substring(0, [Math]::Min(80, ($renderText -replace '\s+', ' ').Length)) + ')')
    Assert-True ($renderText -notmatch 'Specrew unknown') 'and never "Specrew unknown"'
}
finally {
    if (Test-Path -LiteralPath $root) { Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue }
    if ($null -eq $priorModulePath) { Remove-Item Env:\SPECREW_MODULE_PATH -ErrorAction SilentlyContinue } else { $env:SPECREW_MODULE_PATH = $priorModulePath }
}

if ($script:Failures -gt 0) { Write-Host ("version-label-one-resolver: {0} FAILED" -f $script:Failures); exit 1 }
Write-Host 'version-label-one-resolver: all cases passed'
exit 0
