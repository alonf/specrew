#requires -Version 7.0
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# W46 (2026-08-22): SELF-LEAK, SECOND CLASS - internal requirement ids in emitted strings.
#
# The provenance rule says implementation history is recorded for maintainers and is never emitted as
# consumer instruction. The first self-leak firewall enforces that for the DEPLOYED-FILE surface
# (templates and the extension tree, via lint-self-leak.ps1 and its deny-list). This guard covers the
# other half: strings the RUNTIME emits - refusals, advisories, doctor output, generated records -
# which reach downstream humans and agents who have no referent for FR-015 or T091. Worse than
# jargon, the ids COLLIDE: a downstream project has its own FR-004, so a Specrew citation reads as a
# claim about the consumer's spec.
#
# 51+ such strings were swept on 2026-08-22 (drift -107): the behavior words stayed ("fail-loud",
# "containment", "anti-omission"), the ids moved to adjacent comments. This check exists so the next
# one cannot ship.
#
# THE COMMENT HALF STAYS SANCTIONED. Comments are not string literals, so the AST scan never sees
# them - which is exactly the rule: cite requirements for maintainers in comments, speak to consumers
# in behavior terms.
#
# Exemption, for the rare string that must carry an id: a comment containing
#   specrew-internal-id-ok: <reason>
# on the string's first line or the line above it. Exemptions are DEBT MADE VISIBLE, not clean passes
# - the known ones below are asserted individually so their reasons stay reviewed.

BeforeAll {
    $script:RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
    # Internal id shapes, case-sensitive: hyphenated requirement/criterion ids, bare task ids (T091),
    # bare walk ids (W29), and Specrew drift/feature ids. The consumer's own ids never appear in
    # SHIPPED string literals - shipped code cannot know them - so any match is Specrew speaking
    # about itself.
    $script:IdPattern = [regex]::new('\b(?:FR|SC|NFR|T|W|DRIFT|DEC|OBS)-[0-9]{1,4}\b|\bT[0-9]{3}\b|\bW[0-9]{1,3}\b')
    $script:OkMarker = 'specrew-internal-id-ok:'

    function script:Get-EmittedIdFindings {
        param([Parameter(Mandatory)][string]$Path)
        $tokens = $null; $errors = $null
        $ast = [System.Management.Automation.Language.Parser]::ParseFile($Path, [ref]$tokens, [ref]$errors)
        if (@($errors).Count -gt 0) { return @("$(Split-Path -Leaf $Path): PARSE ERROR") }

        # Comment tokens by line, for the exemption check.
        $commentLines = [System.Collections.Generic.HashSet[int]]::new()
        foreach ($token in $tokens) {
            if ($token.Kind -eq [System.Management.Automation.Language.TokenKind]::Comment -and
                $token.Text.Contains($script:OkMarker)) {
                for ($ln = $token.Extent.StartLineNumber; $ln -le $token.Extent.EndLineNumber; $ln++) { $null = $commentLines.Add($ln) }
            }
        }

        $findings = [System.Collections.Generic.List[string]]::new()
        $strings = $ast.FindAll({ param($n)
                $n -is [System.Management.Automation.Language.StringConstantExpressionAst] -or
                $n -is [System.Management.Automation.Language.ExpandableStringExpressionAst] }, $true)
        foreach ($s in $strings) {
            # Nested constants inside an expandable string are visited separately; skip the child copy.
            if ($s.Parent -is [System.Management.Automation.Language.ExpandableStringExpressionAst]) { continue }
            $text = if ($s -is [System.Management.Automation.Language.StringConstantExpressionAst]) { $s.Value } else { $s.Extent.Text }
            $matched = @($script:IdPattern.Matches($text) | ForEach-Object { $_.Value } | Sort-Object -Unique)
            if ($matched.Count -eq 0) { continue }
            $line = $s.Extent.StartLineNumber
            if ($commentLines.Contains($line) -or $commentLines.Contains($line - 1)) { continue }
            [void]$findings.Add(('{0}:{1} [{2}]' -f (Split-Path -Leaf $Path), $line, ($matched -join ',')))
        }
        return @($findings)
    }
}

Describe 'W46 no shipped script emits internal requirement ids to consumers' {
    It 'holds across every script the module ships' {
        $fileList = @((Import-PowerShellDataFile -LiteralPath (Join-Path $script:RepoRoot 'Specrew.psd1')).FileList)
        $offenders = [System.Collections.Generic.List[string]]::new()
        foreach ($entry in $fileList) {
            if ($entry -notlike '*.ps1') { continue }
            $full = Join-Path $script:RepoRoot ([string]$entry).Replace([char]92, [char]47)
            if (-not (Test-Path -LiteralPath $full -PathType Leaf)) { continue }
            foreach ($hit in (Get-EmittedIdFindings -Path $full)) { [void]$offenders.Add($hit) }
        }
        @($offenders).Count | Should -Be 0 -Because "a downstream reader has no referent for Specrew's internal ids, and the ids collide with the consumer's own FR namespace (offenders: $($offenders -join '; '))"
    }

    It 'the known exemptions are individually justified, so the debt stays visible' {
        # An exemption is not a clean pass. Each one below is a decision with a reason; a NEW exemption
        # added anywhere fails the count here and forces this list - and its reasons - to be re-reviewed.
        $fileList = @((Import-PowerShellDataFile -LiteralPath (Join-Path $script:RepoRoot 'Specrew.psd1')).FileList)
        $annotated = [System.Collections.Generic.List[string]]::new()
        foreach ($entry in $fileList) {
            if ($entry -notlike '*.ps1') { continue }
            $full = Join-Path $script:RepoRoot ([string]$entry).Replace([char]92, [char]47)
            if (-not (Test-Path -LiteralPath $full -PathType Leaf)) { continue }
            $lineNumber = 0
            foreach ($line in @(Get-Content -LiteralPath $full -Encoding UTF8)) {
                $lineNumber++
                if ($line.Contains($script:OkMarker) -and $line.TrimStart().StartsWith('#')) {
                    [void]$annotated.Add((([string]$entry).Replace([char]92, [char]47)))
                }
            }
        }
        $expected = @(
            # The governed launch contract: a full document whose text still cites internal ids.
            # Rewriting a governed document is not mechanical; named debt, tracked for beta4.
            'scripts/internal/launch-contract.ps1',
            # The generated hook launcher: the id sits in a COMMENT of the generated file - the
            # sanctioned half of the rule - but the generator carries it as a string literal.
            'scripts/internal/deploy-refocus-hooks.ps1',
            'extensions/specrew-speckit/scripts/deploy-refocus-hooks.ps1',
            # Stage-evidence rule-table provenance: maintainer-facing data consumed by no consumer
            # surface; the field exists to record who ruled what, which is the comment role in data.
            'extensions/specrew-speckit/scripts/shared-governance.ps1'
        )
        (@($annotated | Sort-Object -Unique) -join ';') | Should -Be (@($expected | Sort-Object -Unique) -join ';') -Because 'every exemption is a named decision; a new one must be argued here, not slipped in'
    }
}

Describe 'W46 the failure mode itself, so the guard is not a style rule' {
    It 'flags an id-bearing emitted string in a fixture script' {
        $fixture = Join-Path ([IO.Path]::GetTempPath()) ('w46-' + [guid]::NewGuid().ToString('N') + '.ps1')
        try {
            Set-Content -LiteralPath $fixture -Value 'Write-Host "refusing to record unbound evidence (fail-loud, FR-015)."' -Encoding UTF8
            @(Get-EmittedIdFindings -Path $fixture).Count | Should -Be 1
        }
        finally { Remove-Item -LiteralPath $fixture -Force -ErrorAction SilentlyContinue }
    }

    It 'does not flag the same citation in a comment - the sanctioned half' {
        $fixture = Join-Path ([IO.Path]::GetTempPath()) ('w46-' + [guid]::NewGuid().ToString('N') + '.ps1')
        try {
            Set-Content -LiteralPath $fixture -Value "# FR-015: fail-loud, never degrade`nWrite-Host 'refusing to record unbound evidence (fail-loud).'" -Encoding UTF8
            @(Get-EmittedIdFindings -Path $fixture).Count | Should -Be 0
        }
        finally { Remove-Item -LiteralPath $fixture -Force -ErrorAction SilentlyContinue }
    }

    It 'honors the exemption annotation, same line or line above' {
        $fixture = Join-Path ([IO.Path]::GetTempPath()) ('w46-' + [guid]::NewGuid().ToString('N') + '.ps1')
        try {
            Set-Content -LiteralPath $fixture -Value "# specrew-internal-id-ok: fixture reason`nWrite-Host 'per FR-015'`nWrite-Host 'per FR-016' # specrew-internal-id-ok: fixture same-line" -Encoding UTF8
            @(Get-EmittedIdFindings -Path $fixture).Count | Should -Be 0
        }
        finally { Remove-Item -LiteralPath $fixture -Force -ErrorAction SilentlyContinue }
    }
}
