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

$workflowRelative = 'templates/github/workflows/specrew-methodology-gate.yml'
$workflowPath = Join-Path $repoRoot ($workflowRelative -replace '/', '\')
Assert-True (Test-Path -LiteralPath $workflowPath -PathType Leaf) 'T021: methodology workflow template exists'
$workflow = [IO.File]::ReadAllText($workflowPath)

Assert-True ($workflow -match "(?m)^\s+- main\s*$" -and $workflow -match "(?m)^\s+- '\[0-9\]\[0-9\]\[0-9\]-\*'\s*$") 'T021: push/PR triggers are generic main plus numbered feature branches'
Assert-True ($workflow -notmatch '001-specrew-product') 'T021: workflow contains no repository-specific feature branch'
Assert-True ($workflow -match 'actions/checkout@v\d+' -and $workflow -match 'actions/setup-node@v\d+') 'T021: GitHub actions are pinned by major'
Assert-True ($workflow -match 'markdownlint-cli@0 "\*\*/\*\.md"' -and $workflow -match '--ignore node_modules' -and $workflow -match '--ignore \.squad' -and $workflow -match '--ignore \.specify') 'T021: Markdown lint uses the F-033 ignore set'
Assert-True ($workflow -match [regex]::Escape("'./.specify/extensions/specrew-speckit/scripts/validate-governance.ps1'") -and $workflow -match '& \$validator -ProjectPath \.' -and $workflow -notmatch '-ChangedOnly') 'T021: governance runs fully from the deployed consumer path'
Assert-True ($workflow -notmatch "'./extensions/specrew-speckit/scripts/validate-governance.ps1'") 'T021: workflow has no source-tree validator fallback'
Assert-True ($workflow -match "hashFiles\('\*\*/\*\.ps1', '\*\*/\*\.psm1', '\*\*/\*\.psd1'\)" -and $workflow -match 'Invoke-ScriptAnalyzer') 'T021: PSScriptAnalyzer is conditional on PowerShell files'
Assert-True ($workflow -match '(?m)^\s+continue-on-error:\s+true\s*$') 'T021: initial methodology posture is advisory'
Assert-True (Test-Path -LiteralPath (Join-Path $repoRoot 'extensions\specrew-speckit\scripts\validate-governance.ps1') -PathType Leaf) 'T021: referenced validator exists in the shipped extension source'

$manifest = Import-PowerShellDataFile -LiteralPath (Join-Path $repoRoot 'Specrew.psd1')
Assert-True ($workflowRelative -cin @($manifest.FileList)) 'T021: methodology workflow is included in the module FileList'

$scratch = Join-Path ([IO.Path]::GetTempPath()) ('specrew-t021-' + [guid]::NewGuid().ToString('N'))
$layout = [pscustomobject]@{ TemplateRoot = (Join-Path $repoRoot 'templates'); Mode = 'fixture' }

function Invoke-DeploymentCase {
    param([string]$Name, [AllowNull()][string]$Governance)
    $project = Join-Path $scratch $Name
    $null = New-Item -ItemType Directory -Path $project -Force
    if ($null -ne $Governance) {
        $governancePath = Join-Path $project '.specrew\repository-governance.yml'
        $null = New-Item -ItemType Directory -Path (Split-Path -Parent $governancePath) -Force
        [IO.File]::WriteAllText($governancePath, $Governance, [Text.UTF8Encoding]::new($false))
    }
    $actions = [Collections.ArrayList]::new()
    Invoke-BundledTemplateDeployment -ExecutionLayout $layout -ProjectPath $project -ForceRefresh $false `
        -SpecKitReady $false -SquadReady $false -HadSpecify $false -HadSquad $false -HadGitHub $false `
        -SpecKitExtensionOnly $false -Actions $actions -PreviewOnly:$false
    return [pscustomobject]@{ Project = $project; Actions = $actions }
}

try {
    $unset = Invoke-DeploymentCase -Name 'unset' -Governance $null
    Assert-True (Test-Path -LiteralPath (Join-Path $unset.Project '.github\workflows\specrew-methodology-gate.yml') -PathType Leaf) 'T021: unset provider deploys methodology workflow'

    $github = Invoke-DeploymentCase -Name 'github-rich' -Governance "repository_governance:`n  provider: github`n"
    Assert-True (Test-Path -LiteralPath (Join-Path $github.Project '.github\workflows\specrew-methodology-gate.yml') -PathType Leaf) 'T021: recorded GitHub provider deploys methodology workflow'

    $quoted = Invoke-DeploymentCase -Name 'github-quoted' -Governance "provider: `"GitHub`" # canonical forge`n"
    Assert-True (Test-Path -LiteralPath (Join-Path $quoted.Project '.github\workflows\specrew-methodology-gate.yml') -PathType Leaf) 'T021: quoted/commented top-level GitHub provider normalizes correctly'

    $named = Invoke-DeploymentCase -Name 'github-named' -Governance "provider:`n  name: GITHUB`n"
    Assert-True (Test-Path -LiteralPath (Join-Path $named.Project '.github\workflows\specrew-methodology-gate.yml') -PathType Leaf) 'T021: rich provider.name form normalizes correctly'

    $gitlab = Invoke-DeploymentCase -Name 'gitlab' -Governance "repository_governance:`n  provider: gitlab`n"
    $workflowFiles = @(Get-ChildItem -LiteralPath (Join-Path $gitlab.Project '.github\workflows') -File -ErrorAction SilentlyContinue)
    Assert-True ($workflowFiles.Count -eq 0) 'T021: explicitly non-GitHub provider receives no GitHub Actions workflows'
    $providerAction = @($gitlab.Actions | Where-Object Step -eq 'provider-gate')
    Assert-True ($providerAction.Count -eq 1 -and $providerAction[0].Outcome -match [regex]::Escape('./.specify/extensions/specrew-speckit/scripts/validate-governance.ps1')) 'T021: non-GitHub init names the manual deployed validator command'

    Write-Pass 'T021 workflow contract and provider-keyed scratch deployment cases passed'
}
finally {
    if (Test-Path -LiteralPath $scratch) { Remove-Item -LiteralPath $scratch -Recurse -Force }
}

exit 0
