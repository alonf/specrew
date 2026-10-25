#requires -Version 7.0
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# W42 (2026-08-21, KeyContextAI walk): a local named after a PowerShell automatic variable took the
# reviewer scaffold down, and reading could not see it.
#
#   $matches = New-Object System.Collections.Generic.List[string]
#   ...
#   if ($pathText -match $regex) { $null = $matches.Add($pattern) }
#
# `-match` REPLACES $matches with a Hashtable, whose Add() takes two arguments, so `.Add($pattern)`
# throws `Cannot find an overload for "Add" and the argument count: "1"`. It fires only once a pattern
# actually matches, so a project with no matching files never sees it - which is why it survived
# reading, -WhatIf, -DryRun, and three of my own reproduction fixtures. I closed the blocker on a
# different defect in the same script and it was still open.
#
# So this is a STRUCTURAL guard rather than a case: the failure mode is invisible per-site, and the
# only reliable defence is refusing the shape everywhere at once.

BeforeAll {
    $script:RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path

    # Automatics whose VALUE the surrounding code then relies on. $null and $_ are deliberately absent:
    # `$null = ...` is the idiomatic discard and shadowing $_ inside a scriptblock is normal PowerShell.
    $script:DangerousAutomatics = @('matches', 'args', 'input', 'error', 'host', 'profile', 'this',
        'switch', 'foreach', 'psitem', 'pwd', 'pid', 'home')

    function script:Get-AutomaticAssignments {
        param([Parameter(Mandatory)][string]$Path)
        $tokens = $null; $errors = $null
        $ast = [System.Management.Automation.Language.Parser]::ParseFile($Path, [ref]$tokens, [ref]$errors)
        if ($errors.Count -gt 0) { return @() }
        return @($ast.FindAll({
                    param($n)
                    ($n -is [System.Management.Automation.Language.AssignmentStatementAst]) -and
                    ($n.Left -is [System.Management.Automation.Language.VariableExpressionAst])
                }, $true) |
                Where-Object { $script:DangerousAutomatics -contains $_.Left.VariablePath.UserPath.ToLowerInvariant() } |
                ForEach-Object { '{0}:{1}  ${2}' -f (Split-Path -Leaf $Path), $_.Extent.StartLineNumber, $_.Left.VariablePath.UserPath })
    }
}

Describe 'W42 no shipped script assigns to a PowerShell automatic variable' {
    It 'holds across every script the module ships' {
        # FileList is the authority on what ships, so the guard covers exactly what a consumer runs.
        $fileList = @((Import-PowerShellDataFile -LiteralPath (Join-Path $script:RepoRoot 'Specrew.psd1')).FileList)
        $offenders = [System.Collections.Generic.List[string]]::new()
        foreach ($entry in $fileList) {
            if ($entry -notlike '*.ps1') { continue }
            $full = Join-Path $script:RepoRoot ([string]$entry).Replace([char]92, [char]47)
            if (-not (Test-Path -LiteralPath $full -PathType Leaf)) { continue }
            foreach ($hit in (Get-AutomaticAssignments -Path $full)) { [void]$offenders.Add($hit) }
        }
        @($offenders).Count | Should -Be 0 -Because "assigning to an automatic is invisible until the path that repopulates it runs (offenders: $($offenders -join '; '))"
    }

    It 'holds for the deployed .specify mirror too, which is what a project actually executes' {
        $mirror = Join-Path $script:RepoRoot '.specify/extensions/specrew-speckit'
        if (-not (Test-Path -LiteralPath $mirror -PathType Container)) { Set-ItResult -Skipped -Because 'no deployed mirror in this checkout'; return }
        $offenders = [System.Collections.Generic.List[string]]::new()
        foreach ($file in @(Get-ChildItem -LiteralPath $mirror -Filter '*.ps1' -File -Recurse)) {
            foreach ($hit in (Get-AutomaticAssignments -Path $file.FullName)) { [void]$offenders.Add($hit) }
        }
        @($offenders).Count | Should -Be 0 -Because "the deployed copy is what runs (offenders: $($offenders -join '; '))"
    }
}

Describe 'W42 the failure mode itself, so the guard is not merely a style rule' {
    It 'reproduces the exact reported error when the shape is present' {
        # Proof that this is a real defect class and not a naming preference: the shape throws the
        # error the walk reported, verbatim.
        $thrown = ''
        try {
            & {
                $matches = New-Object System.Collections.Generic.List[string]
                foreach ($p in @('app')) { if ('src/app.cs' -match $p) { $null = $matches.Add($p) } }
            }
        }
        catch { $thrown = $_.Exception.Message }
        $thrown | Should -Match 'Cannot find an overload for "Add" and the argument count: "1"'
    }

    It 'does not throw once the local is renamed' {
        $thrown = ''
        try {
            & {
                $matchedItems = New-Object System.Collections.Generic.List[string]
                foreach ($p in @('app')) { if ('src/app.cs' -match $p) { $null = $matchedItems.Add($p) } }
                $matchedItems.Count | Out-Null
            }
        }
        catch { $thrown = $_.Exception.Message }
        $thrown | Should -BeNullOrEmpty
    }
}
