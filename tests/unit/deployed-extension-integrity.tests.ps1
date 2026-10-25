#requires -Version 7.0
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# W43 (2026-08-21): the rest of the deployed runtime gets the integrity check the co-review bundle
# already had.
#
# `scripts/internal/continuous-co-review/` ships a `.specrew-runtime.json` with per-file hashes and
# refuses on drift. `.specify/extensions/specrew-speckit/` - which holds validate-governance.ps1,
# shared-governance.ps1 and every scaffold - had no marker and no check.
#
# During the walk a downstream agent hand-patched a deployed scaffold to clear a blocker. Its fix was
# right and it said so. Nothing stopped it, and nothing would have detected the same edit to the
# VALIDATOR - the file every guarantee from this iteration assumes runs as shipped.
#
# HONEST LIMIT: this is a self-check. An agent that edits the validator could also edit the marker, or
# the verifier. It raises the cost of an undetected edit from zero to three coordinated ones, and it
# catches every accidental or single-file edit - which is what actually happened.

BeforeAll {
    $script:RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
    . (Join-Path $script:RepoRoot 'extensions\specrew-speckit\scripts\shared-governance.ps1')

    $t = $null; $e = $null
    $ast = [System.Management.Automation.Language.Parser]::ParseFile(
        (Join-Path $script:RepoRoot 'extensions\specrew-speckit\scripts\validate-governance.ps1'), [ref]$t, [ref]$e)
    $fn = $ast.FindAll({ param($n) $n -is [System.Management.Automation.Language.FunctionDefinitionAst] -and
            $n.Name -eq 'Test-DeployedExtensionIntegrity' }, $true) | Select-Object -First 1
    if (-not $fn) { throw 'Test-DeployedExtensionIntegrity not found' }
    . ([scriptblock]::Create($fn.Extent.Text))

    function script:New-DeployedProject {
        # A project shaped like a deployed one: the extension scripts under .specify, stamped.
        param([switch]$Unstamped)
        $root = Join-Path ([IO.Path]::GetTempPath()) ('w43-' + [guid]::NewGuid().ToString('N'))
        $ext = Join-Path $root '.specify/extensions/specrew-speckit/scripts'
        New-Item -ItemType Directory -Path $ext -Force | Out-Null
        Set-Content -LiteralPath (Join-Path $ext 'validate-governance.ps1') -Value '# shipped validator' -Encoding UTF8
        Set-Content -LiteralPath (Join-Path $ext 'shared-governance.ps1') -Value '# shipped helpers' -Encoding UTF8
        Set-Content -LiteralPath (Join-Path $ext 'scaffold-review-artifact.ps1') -Value '# shipped scaffold' -Encoding UTF8
        if (-not $Unstamped) { $null = Write-SpecrewDeployedExtensionMarker -ProjectRoot $root -SpecrewVersion '0.40.0' }
        return $root
    }
    function script:Check {
        param([Parameter(Mandatory)][string]$Root)
        $errors = [System.Collections.Generic.List[string]]::new()
        Test-DeployedExtensionIntegrity -ProjectRoot $Root -Errors $errors
        return @($errors)
    }
}

Describe 'W43 a modified deployed validator is detected and refused' {
    It 'ACCEPTANCE: refuses when the deployed validator has been edited, naming specrew update' {
        $root = New-DeployedProject
        try {
            $validator = Join-Path $root '.specify/extensions/specrew-speckit/scripts/validate-governance.ps1'
            Add-Content -LiteralPath $validator -Value '# hand-patched to clear a blocker' -Encoding UTF8
            $found = @(Check -Root $root)
            $found.Count | Should -Be 1
            $found[0] | Should -Match 'validate-governance\.ps1'
            $found[0] | Should -Match 'specrew update --project-path'
        }
        finally { Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue }
    }

    It 'detects an edited scaffold too, which is what actually happened' {
        $root = New-DeployedProject
        try {
            Add-Content -LiteralPath (Join-Path $root '.specify/extensions/specrew-speckit/scripts/scaffold-review-artifact.ps1') -Value '# local fix' -Encoding UTF8
            @(Check -Root $root)[0] | Should -Match 'scaffold-review-artifact\.ps1'
        }
        finally { Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue }
    }

    It 'detects a deleted managed file, not only a modified one' {
        $root = New-DeployedProject
        try {
            Remove-Item -LiteralPath (Join-Path $root '.specify/extensions/specrew-speckit/scripts/shared-governance.ps1') -Force
            @(Check -Root $root)[0] | Should -Match 'missing: .*shared-governance\.ps1'
        }
        finally { Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue }
    }

    It 'says nothing about an untouched deployment' {
        $root = New-DeployedProject
        try { @(Check -Root $root).Count | Should -Be 0 }
        finally { Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue }
    }

    It 'fails OPEN on a project deployed before the marker existed' {
        # The installed base has no marker. Refusing every one of them would wedge projects for a check
        # they never had, and `specrew update` - the remedy for real drift - is also what writes it.
        $root = New-DeployedProject -Unstamped
        try {
            Add-Content -LiteralPath (Join-Path $root '.specify/extensions/specrew-speckit/scripts/validate-governance.ps1') -Value '# edited' -Encoding UTF8
            @(Check -Root $root).Count | Should -Be 0
        }
        finally { Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue }
    }

    It 'does not report a CRLF/LF checkout difference as tampering' {
        # The comment claimed line-ending normalisation while the code hashed raw bytes. Every governed
        # project commits .specify/, so the first clone taken with different line endings would have been
        # told its validator was modified when nobody had touched it - and a refusal that fires on
        # innocent state teaches the reader to route around it, which costs more than the gap it closed.
        $root = New-DeployedProject
        try {
            $validator = Join-Path $root '.specify/extensions/specrew-speckit/scripts/validate-governance.ps1'
            $text = [IO.File]::ReadAllText($validator)
            $flipped = if ($text.Contains("`r`n")) { $text.Replace("`r`n", "`n") } else { $text.Replace("`n", "`r`n") }
            $flipped | Should -Not -Be $text -Because 'the case is meaningless if the line endings did not actually change'
            [IO.File]::WriteAllText($validator, $flipped)
            @(Check -Root $root).Count | Should -Be 0 -Because 'the same content with other line endings is the same content'
        }
        finally { Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue }
    }

    It 'tells a deliberate patcher where the edit actually belongs' {
        # The reachable-action property: refusing is not enough if the reader had a real reason to edit.
        $root = New-DeployedProject
        try {
            Add-Content -LiteralPath (Join-Path $root '.specify/extensions/specrew-speckit/scripts/validate-governance.ps1') -Value '# edited' -Encoding UTF8
            $message = @(Check -Root $root)[0]
            $message | Should -Match 'make it in the Specrew repository and reinstall'
            $message | Should -Match 'overwritten by the next update'
        }
        finally { Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue }
    }
}
