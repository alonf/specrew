[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Assert-True {
    param([bool] $Condition, [string] $Message)
    if (-not $Condition) { throw "FAIL: $Message" }
    Write-Host "PASS: $Message" -ForegroundColor Green
}

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$source = Join-Path $repoRoot 'extensions\specrew-speckit\scripts\create-governed-feature.ps1'
$mirror = Join-Path $repoRoot '.specify\extensions\specrew-speckit\scripts\create-governed-feature.ps1'
Assert-True (Test-Path -LiteralPath $source -PathType Leaf) 'governed feature scaffold source exists'
Assert-True (Test-Path -LiteralPath $mirror -PathType Leaf) 'governed feature scaffold deployed mirror exists'
Assert-True ((Get-Content -LiteralPath $source -Raw) -eq (Get-Content -LiteralPath $mirror -Raw)) 'governed feature scaffold source and deployed mirror are byte-identical'

$scratch = Join-Path ([IO.Path]::GetTempPath()) ('specrew-governed-feature-' + [guid]::NewGuid().ToString('N'))
try {
    New-Item -ItemType Directory -Path (Join-Path $scratch '.specrew') -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $scratch '.specify\scripts\powershell') -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $scratch '.specify\extensions\specrew-speckit\scripts') -Force | Out-Null
    Set-Content -LiteralPath (Join-Path $scratch '.specrew\config.yml') -Value 'version: 1' -Encoding UTF8
    Set-Content -LiteralPath (Join-Path $scratch '.specify\scripts\powershell\create-new-feature.ps1') -Encoding UTF8 -Value @'
[CmdletBinding()]
param([switch]$Json,[switch]$AllowExistingBranch,[string]$ShortName,[long]$Number,[switch]$Timestamp,[switch]$Help,[Parameter(Position=0,ValueFromRemainingArguments=$true)][string[]]$FeatureDescription)
$ref = '001-' + $ShortName
$dir = Join-Path (Join-Path (Get-Location).Path 'specs') $ref
New-Item -ItemType Directory -Path $dir -Force | Out-Null
Set-Content -LiteralPath (Join-Path $dir 'spec.md') -Value '# Feature Specification' -Encoding UTF8
[pscustomobject]@{ BRANCH_NAME=$ref; SPEC_FILE=(Join-Path $dir 'spec.md'); FEATURE_NUM='001'; HAS_GIT=$true } | ConvertTo-Json -Compress
'@
    Copy-Item -LiteralPath (Join-Path $repoRoot 'extensions\specrew-speckit\scripts\initialize-workshop-controller-state.ps1') -Destination (Join-Path $scratch '.specify\extensions\specrew-speckit\scripts\initialize-workshop-controller-state.ps1') -Force
    Copy-Item -LiteralPath (Join-Path $repoRoot 'extensions\specrew-speckit\scripts\workshop-authority-store.ps1') -Destination (Join-Path $scratch '.specify\extensions\specrew-speckit\scripts\workshop-authority-store.ps1') -Force
    Copy-Item -LiteralPath $source -Destination (Join-Path $scratch '.specify\extensions\specrew-speckit\scripts\create-governed-feature.ps1') -Force

    Push-Location $scratch
    try {
        $json = & pwsh -NoProfile -File .specify\extensions\specrew-speckit\scripts\create-governed-feature.ps1 -Json -ShortName url-checker 'Validate reference URLs' 2>&1
        $exitCode = $LASTEXITCODE
    }
    finally { Pop-Location }

    Assert-True ($exitCode -eq 0) "governed feature scaffold exits successfully: $($json -join ' ')"
    $result = ($json -join "`n") | ConvertFrom-Json
    Assert-True ([string]$result.BRANCH_NAME -eq '001-url-checker') 'governed feature scaffold preserves the underlying feature identity'
    $statePath = Join-Path $scratch 'specs\001-url-checker\lens-applicability.json'
    Assert-True (Test-Path -LiteralPath $statePath -PathType Leaf) 'successful feature creation includes controller state before any question can be asked'
    $state = Get-Content -LiteralPath $statePath -Raw -Encoding UTF8 | ConvertFrom-Json -Depth 8
    Assert-True ([string]$state.agenda_status -eq 'pending-confirmation') 'governed scaffold writes pending-confirmation controller state'
    Assert-True ([string]$state.agenda_contract -eq 'complete-coverage-v1' -and @($state.selected).Count -eq 0 -and
        @($state.agenda.PSObject.Properties).Count -eq 0 -and @($state.skipped.PSObject.Properties).Count -eq 0 -and
        @($state.workshop.PSObject.Properties).Count -eq 0 -and [string]$state.agenda_confirmation -eq 'pending' -and [string]$state.human_turn_contract -eq 'typed-turns-v1' -and [string]$state.agenda_turn_receipt -eq 'pending') 'governed scaffold writes no model or human decisions and requires complete agenda plus typed authority before lens 1'
    Assert-True ([IO.Path]::GetFullPath([string]$result.WORKSHOP_STATE) -eq [IO.Path]::GetFullPath($statePath)) 'JSON output identifies the exact controller artifact'

    $missingInitializerRoot = Join-Path $scratch 'missing-initializer'
    New-Item -ItemType Directory -Path (Join-Path $missingInitializerRoot '.specrew') -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $missingInitializerRoot '.specify\scripts\powershell') -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $missingInitializerRoot '.specify\extensions\specrew-speckit\scripts') -Force | Out-Null
    Set-Content -LiteralPath (Join-Path $missingInitializerRoot '.specrew\config.yml') -Value 'version: 1' -Encoding UTF8
    Copy-Item -LiteralPath (Join-Path $scratch '.specify\scripts\powershell\create-new-feature.ps1') -Destination (Join-Path $missingInitializerRoot '.specify\scripts\powershell\create-new-feature.ps1') -Force
    Copy-Item -LiteralPath $source -Destination (Join-Path $missingInitializerRoot '.specify\extensions\specrew-speckit\scripts\create-governed-feature.ps1') -Force
    Push-Location $missingInitializerRoot
    try {
        $missingOutput = & pwsh -NoProfile -File .specify\extensions\specrew-speckit\scripts\create-governed-feature.ps1 -Json -ShortName refusal-case 'Must not report success without controller state' 2>&1
        $missingExitCode = $LASTEXITCODE
    }
    finally { Pop-Location }
    Assert-True ($missingExitCode -ne 0) 'governed feature scaffold refuses success when the controller initializer is unavailable'
    Assert-True (($missingOutput -join "`n") -match 'Workshop controller initializer is missing') 'refusal names the missing controller initializer instead of degrading silently'
}
finally {
    Remove-Item -LiteralPath $scratch -Recurse -Force -ErrorAction SilentlyContinue
}

Write-Host 'governed feature workshop controller: all assertions pass' -ForegroundColor Green
