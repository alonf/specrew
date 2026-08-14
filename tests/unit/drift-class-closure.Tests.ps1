Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Describe 'Drift-log class closure contract' {
    BeforeAll {
        $repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
        $validatorPath = Join-Path $repoRoot 'extensions/specrew-speckit/scripts/validate-governance.ps1'
        $tokens = $null
        $parseErrors = $null
        $ast = [System.Management.Automation.Language.Parser]::ParseFile($validatorPath, [ref]$tokens, [ref]$parseErrors)
        @($parseErrors).Count | Should -Be 0

        foreach ($name in @('Get-MarkdownContent', 'Get-MarkdownMetadataValue', 'Test-DriftLogClassClosure')) {
            $definition = $ast.Find({ param($node) $node -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -eq $name }, $true)
            $null = . ([scriptblock]::Create($definition.Extent.Text))
        }

        function Invoke-ClassClosureFixture {
            param([Parameter(Mandatory)][string]$Content)
            $path = Join-Path $TestDrive ([guid]::NewGuid().ToString('n') + '.md')
            Set-Content -LiteralPath $path -Value $Content -Encoding UTF8
            $errors = [System.Collections.Generic.List[string]]::new()
            Test-DriftLogClassClosure -DriftPath $path -Errors $errors
            return @($errors)
        }
    }

    It 'grandfathers v1 drift logs' {
        @(Invoke-ClassClosureFixture "# Drift Log`n`n**Schema**: v1`n`n### DRIFT-OLD`n`n- **Resolution**: FIXED").Count | Should -Be 0
    }

    It 'accepts a v2 zero-event log' {
        @(Invoke-ClassClosureFixture "# Drift Log`n`n**Schema**: v2`n`nNo specification drift detected.").Count | Should -Be 0
    }

    It 'rejects a v2 event without class closure' {
        $errors = @(Invoke-ClassClosureFixture "# Drift Log`n`n**Schema**: v2`n`n### DRIFT-NEW`n`n- **Resolution**: FIXED")
        $errors.Count | Should -Be 1
        $errors[0] | Should -Match 'DRIFT-NEW.*missing required Class closure'
    }

    It 'accepts an executable class-closure mechanism' {
        @(Invoke-ClassClosureFixture "# Drift Log`n`n**Schema**: v2`n`n### DRIFT-NEW`n`n- **Class closure**: AST discovery derives every consumer and fails on an empty set.").Count | Should -Be 0
    }

    It 'rejects a bare NONE disposition' {
        $errors = @(Invoke-ClassClosureFixture "# Drift Log`n`n**Schema**: v2`n`n### DRIFT-NEW`n`n- **Class closure**: NONE")
        $errors.Count | Should -Be 1
        $errors[0] | Should -Match 'NONE without a reason'
    }

    It 'accepts NONE only with a reason' {
        @(Invoke-ClassClosureFixture "# Drift Log`n`n**Schema**: v2`n`n### DRIFT-NEW`n`n- **Class closure**: NONE — external host behavior cannot be made unreachable in this repository.").Count | Should -Be 0
    }
}
