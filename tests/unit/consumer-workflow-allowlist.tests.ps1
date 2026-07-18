[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Write-Pass { param([string]$Message) Write-Host "PASS: $Message" -ForegroundColor Green }
function Fail { param([string]$Message) Write-Host "FAIL: $Message" -ForegroundColor Red; exit 1 }
function Assert-True { param([bool]$Condition, [string]$Message) if (-not $Condition) { Fail $Message } }

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
. (Join-Path $repoRoot 'scripts\init\_utilities.ps1')
. (Join-Path $repoRoot 'scripts\init\template-deploy.ps1')

$expected = @('specrew-methodology-gate.yml', 'specrew-work-kind.yml')
$templateWorkflowRoot = Join-Path $repoRoot 'templates\github\workflows'
$sourceNames = @(Get-ChildItem -LiteralPath $templateWorkflowRoot -File | Sort-Object Name | ForEach-Object Name)
Assert-True (($sourceNames -join '|') -ceq ($expected -join '|')) 'T023: template workflow directory is the exact consumer-safe allowlist'

$manifest = Import-PowerShellDataFile -LiteralPath (Join-Path $repoRoot 'Specrew.psd1')
$manifestNames = @($manifest.FileList |
        Where-Object { $_ -like 'templates/github/workflows/*' } |
        ForEach-Object { [IO.Path]::GetFileName($_) } |
        Sort-Object)
Assert-True (($manifestNames -join '|') -ceq ($expected -join '|')) 'T023: packaged workflow manifest is the exact consumer-safe allowlist'

foreach ($selfHost in @('specrew-ci.yml', 'specrew-confidence-lane.yml', 'specrew-project-sync.yml')) {
    Assert-True (Test-Path -LiteralPath (Join-Path $repoRoot ".github\workflows\$selfHost") -PathType Leaf) "T023: self-host workflow remains in repository CI: $selfHost"
    Assert-True (-not (Test-Path -LiteralPath (Join-Path $templateWorkflowRoot $selfHost))) "T023: self-host workflow is absent from consumer templates: $selfHost"
}

$scratch = Join-Path ([IO.Path]::GetTempPath()) ('specrew-t023-' + [guid]::NewGuid().ToString('N'))
try {
    $project = Join-Path $scratch 'github-consumer'
    $governancePath = Join-Path $project '.specrew\repository-governance.yml'
    $null = New-Item -ItemType Directory -Path (Split-Path -Parent $governancePath) -Force
    [IO.File]::WriteAllText($governancePath, "repository_governance:`n  provider: github`n", [Text.UTF8Encoding]::new($false))
    $layout = [pscustomobject]@{ TemplateRoot = (Join-Path $repoRoot 'templates'); Mode = 'fixture' }
    $actions = [Collections.ArrayList]::new()
    Invoke-BundledTemplateDeployment -ExecutionLayout $layout -ProjectPath $project -ForceRefresh $false `
        -SpecKitReady $false -SquadReady $false -HadSpecify $false -HadSquad $false -HadGitHub $false `
        -SpecKitExtensionOnly $false -Actions $actions -PreviewOnly:$false
    $deployedNames = @(Get-ChildItem -LiteralPath (Join-Path $project '.github\workflows') -File |
            Sort-Object Name | ForEach-Object Name)
    Assert-True (($deployedNames -join '|') -ceq ($expected -join '|')) 'T023: real bundled deployment emits exactly the consumer-safe workflow allowlist'
    Write-Pass 'T023 source, manifest, repository-CI, and real-deploy workflow boundaries passed'
}
finally {
    if (Test-Path -LiteralPath $scratch) { Remove-Item -LiteralPath $scratch -Recurse -Force }
}

exit 0
