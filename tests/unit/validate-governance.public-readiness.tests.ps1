[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

Describe 'validate-governance public-readiness warnings' {
    $repoRoot = (Resolve-Path (Join-Path -Path $PSScriptRoot -ChildPath '..\..')).Path
    $fixtureRoot = Join-Path $repoRoot 'tests\unit\fixtures\015-public-readiness-pass'
    $scratchRoot = Join-Path $repoRoot '.scratch\validate-governance-public-readiness'
    $validatorScripts = @(
        @{ Name = 'extension'; ScriptPath = Join-Path $repoRoot 'extensions\specrew-speckit\scripts\validate-governance.ps1' },
        @{ Name = 'specify'; ScriptPath = Join-Path $repoRoot '.specify\extensions\specrew-speckit\scripts\validate-governance.ps1' }
    )

    function New-TestWorkspace {
        param(
            [Parameter(Mandatory = $true)][string]$FixtureName,
            [Parameter(Mandatory = $true)][string]$WorkspaceName
        )

        $source = Join-Path $fixtureRoot $FixtureName
        $destination = Join-Path $scratchRoot $WorkspaceName
        if (Test-Path -LiteralPath $destination) {
            Remove-Item -LiteralPath $destination -Recurse -Force
        }

        $null = New-Item -ItemType Directory -Path $destination -Force
        foreach ($item in Get-ChildItem -LiteralPath $source -Force) {
            Copy-Item -LiteralPath $item.FullName -Destination $destination -Recurse -Force
        }

        return $destination
    }

    function Invoke-ValidatorScript {
        param(
            [Parameter(Mandatory = $true)][string]$ScriptPath,
            [Parameter(Mandatory = $true)][string]$ProjectPath
        )

        $iterationPath = Join-Path $ProjectPath 'specs\013-validator-hardening\iterations\001'
        $output = @(& pwsh -NoProfile -ExecutionPolicy Bypass -File $ScriptPath -ProjectPath $ProjectPath -IterationPath $iterationPath 2>&1)
        return [pscustomobject]@{
            ExitCode = $LASTEXITCODE
            Output   = @($output)
            Text     = ($output -join "`n")
        }
    }

    It 'keeps clean fixtures warning-free for <Name>' -TestCases $validatorScripts {
        param($Name, $ScriptPath)

        $workspace = New-TestWorkspace -FixtureName 'public-readiness-clean' -WorkspaceName ("clean-{0}" -f $Name)
        $result = Invoke-ValidatorScript -ScriptPath $ScriptPath -ProjectPath $workspace

        $result.ExitCode | Should Be 0
        $result.Text | Should Not Match 'WARN \[public-readiness\]'
        $result.Text | Should Match 'PASS '
    }

    It 'emits additive soft warnings for drifted fixtures in <Name>' -TestCases $validatorScripts {
        param($Name, $ScriptPath)

        $workspace = New-TestWorkspace -FixtureName 'public-readiness-drift' -WorkspaceName ("drift-{0}" -f $Name)
        $result = Invoke-ValidatorScript -ScriptPath $ScriptPath -ProjectPath $workspace
        $warningLines = @($result.Output | Where-Object { [string]$_ -match 'WARN \[public-readiness\]' })

        $result.ExitCode | Should Be 0
        $warningLines.Count | Should Be 5
        $result.Text | Should Match 'WARN \[public-readiness\] missing-artifact: LICENSE'
        $result.Text | Should Match 'WARN \[public-readiness\] missing-artifact: NOTICE\.md'
        $result.Text | Should Match 'WARN \[public-readiness\] missing-artifact: CHANGELOG\.md'
        $result.Text | Should Match 'WARN \[public-readiness\] missing-artifact: docs/versioning\.md'
        $result.Text | Should Match 'WARN \[public-readiness\] stale-version-in-readme: README\.md does not contain declared version 0\.14\.0'
        $result.Text | Should Not Match 'FAIL validate-governance'
    }

    It 'preserves existing hard-fail exit behavior for <Name>' -TestCases $validatorScripts {
        param($Name, $ScriptPath)

        $workspace = New-TestWorkspace -FixtureName 'public-readiness-clean' -WorkspaceName ("hard-fail-{0}" -f $Name)
        Remove-Item -LiteralPath (Join-Path $workspace 'specs\013-validator-hardening\iterations\001\plan.md') -Force

        $result = Invoke-ValidatorScript -ScriptPath $ScriptPath -ProjectPath $workspace

        $result.ExitCode | Should Be 1
        $result.Text | Should Match 'Missing required artifact: plan\.md'
        $result.Text | Should Not Match 'WARN \[public-readiness\]'
    }
}
