[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

$script:repoRoot = (Resolve-Path (Join-Path -Path $PSScriptRoot -ChildPath '..\..')).Path
$script:fixtureRoot = Join-Path $script:repoRoot 'tests\unit\fixtures\015-public-readiness-pass'
$script:scratchRoot = Join-Path $script:repoRoot '.scratch\validate-governance-reader-tolerance'
$script:validatorScripts = @(
    @{ Name = 'extension'; ScriptPath = Join-Path $script:repoRoot 'extensions\specrew-speckit\scripts\validate-governance.ps1' },
    @{ Name = 'specify'; ScriptPath = Join-Path $script:repoRoot '.specify\extensions\specrew-speckit\scripts\validate-governance.ps1' }
)

Describe 'validate-governance reader-tolerance rule' {
    

    

    BeforeAll {
        # v5: top-level $script: vars run only at Discovery (kept there for -TestCases); re-establish the
        # run-phase paths in BeforeAll so BeforeAll/It/AfterAll see them during Run.
        $script:repoRoot = (Resolve-Path (Join-Path -Path $PSScriptRoot -ChildPath '..\..')).Path
        $script:fixtureRoot = Join-Path $script:repoRoot 'tests\unit\fixtures\015-public-readiness-pass'
        $script:scratchRoot = Join-Path $script:repoRoot '.scratch\validate-governance-reader-tolerance'
        if (Test-Path -LiteralPath $script:scratchRoot) {
            Remove-Item -LiteralPath $script:scratchRoot -Recurse -Force
        }

        $null = New-Item -ItemType Directory -Path $script:scratchRoot -Force
    

        # v5: helpers moved here so they are visible inside It blocks (Discovery/Run split).
        function New-TestWorkspace {
        param(
            [Parameter(Mandatory = $true)][string]$FixtureName,
            [Parameter(Mandatory = $true)][string]$WorkspaceName,
            [Parameter(Mandatory = $true)][bool]$UseHashtable
        )

        $source = Join-Path $script:fixtureRoot $FixtureName
        $destination = Join-Path $script:scratchRoot $WorkspaceName
        if (Test-Path -LiteralPath $destination) {
            Remove-Item -LiteralPath $destination -Recurse -Force
        }

        $null = New-Item -ItemType Directory -Path $destination -Force
        foreach ($item in Get-ChildItem -LiteralPath $source -Force) {
            Copy-Item -LiteralPath $item.FullName -Destination $destination -Recurse -Force
        }

        $scriptDirectory = Join-Path $destination 'scripts\internal'
        $null = New-Item -ItemType Directory -Path $scriptDirectory -Force
        $readerScript = @"
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Get-WorktreeFeatureRef {
    param([Parameter(Mandatory = `$true)][string]`$WorktreePath)

    `$featureJsonPath = Join-Path `$WorktreePath '.specify\feature.json'
    if (-not (Test-Path -LiteralPath `$featureJsonPath -PathType Leaf)) {
        return `$null
    }

    `$featureJson = Get-Content -LiteralPath `$featureJsonPath -Raw -Encoding UTF8 | ConvertFrom-Json$(if ($UseHashtable) { ' -AsHashtable -Depth 12' } else { '' })
    return `$featureJson
}
"@
        Set-Content -LiteralPath (Join-Path $scriptDirectory 'worktree-awareness.ps1') -Value $readerScript -Encoding UTF8

        return $destination
    }

function Invoke-ValidatorScript {
        param(
            [Parameter(Mandatory = $true)][string]$ScriptPath,
            [Parameter(Mandatory = $true)][string]$ProjectPath
        )

        $iterationPath = Join-Path $ProjectPath 'specs\013-validator-hardening\iterations\001'
        $output = @(& pwsh -NoProfile -ExecutionPolicy Bypass -File $ScriptPath -ProjectPath $ProjectPath -IterationPath $iterationPath 2>&1)
        $summaryPath = Join-Path $ProjectPath '.specrew\last-validator-summary.json'
        $summary = if (Test-Path -LiteralPath $summaryPath -PathType Leaf) {
            Get-Content -LiteralPath $summaryPath -Raw -Encoding UTF8 | ConvertFrom-Json -AsHashtable -Depth 6
        }
        else {
            $null
        }

        return [pscustomobject]@{
            ExitCode = $LASTEXITCODE
            Output   = @($output)
            Text     = ($output -join "`n")
            Summary  = $summary
        }
    }
}

    AfterAll {
        if (Test-Path -LiteralPath $script:scratchRoot) {
            Remove-Item -LiteralPath $script:scratchRoot -Recurse -Force
        }
    }

    It 'passes compliant readers and writes a schema-v1 validator summary for <Name>' -TestCases $script:validatorScripts {
        param($Name, $ScriptPath)

        $workspace = New-TestWorkspace -FixtureName 'public-readiness-clean' -WorkspaceName ("compliant-{0}" -f $Name) -UseHashtable $true
        $result = Invoke-ValidatorScript -ScriptPath $ScriptPath -ProjectPath $workspace

        $result.ExitCode | Should -Be 0
        $result.Text | Should -Not -Match 'category=reader-tolerance'
        $result.Summary['schema'] | Should -Be 'v1'
        $result.Summary['warnings']['hard'] | Should -Be 0
    }

    It 'fails readers that omit -AsHashtable and records hard warnings for <Name>' -TestCases $script:validatorScripts {
        param($Name, $ScriptPath)

        $workspace = New-TestWorkspace -FixtureName 'public-readiness-clean' -WorkspaceName ("violating-{0}" -f $Name) -UseHashtable $false
        $result = Invoke-ValidatorScript -ScriptPath $ScriptPath -ProjectPath $workspace

        $result.ExitCode | Should -Be 1
        $result.Text | Should -Match 'category=reader-tolerance'
        $result.Text | Should -Match 'Get-WorktreeFeatureRef'
        $result.Summary['schema'] | Should -Be 'v1'
        $result.Summary['warnings']['hard'] | Should -BeGreaterThan 0
    }
}
