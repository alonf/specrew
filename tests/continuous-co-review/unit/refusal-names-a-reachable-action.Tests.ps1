#requires -Version 7.0
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# W39 (2026-08-21): a refusal may not name an action that the same refusal prevents.
#
# W38 and W36's provenance branch together produced a wedge every consumer reaches by committing after
# a review:
#
#   governance fails on the stale citation
#     -> the fix is a fresh round
#       -> the round's preflight runs the verification plan, which runs governance
#         -> and it fails on the same stale citation.
#
# For a block-sourced run the message named exactly one way out - "obtain a run that completed against
# the current tree" - which is the action the failure prevents. The block cannot be hand-edited, by
# design. An escape did exist (withdraw the claim in the record's own prose) and nothing said so, so
# only someone who had already reasoned it out could take it. That is the same painted-on-door shape as
# W15 and as W35's own first fix, now at a third layer.
#
# Broken at the DEPENDENCY, not the rule: staleness still fails ordinary validation and still stops the
# signoff gate, where it actually matters. It simply does not gate the one operation whose purpose is
# to end the staleness.

BeforeAll {
    $script:RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
    . (Join-Path $script:RepoRoot 'extensions\specrew-speckit\scripts\shared-governance.ps1')
    . (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/_load.ps1')

    $t = $null; $e = $null
    $ast = [System.Management.Automation.Language.Parser]::ParseFile(
        (Join-Path $script:RepoRoot 'extensions\specrew-speckit\scripts\validate-governance.ps1'), [ref]$t, [ref]$e)
    $fn = $ast.FindAll({ param($n) $n -is [System.Management.Automation.Language.FunctionDefinitionAst] -and
            $n.Name -eq 'Test-ReviewCitedRunEvidence' }, $true) | Select-Object -First 1
    if (-not $fn) { throw 'Test-ReviewCitedRunEvidence not found' }
    . ([scriptblock]::Create($fn.Extent.Text))

    function script:New-MovedTreeProject {
        # The consumer shape: a real repo, a run that reviewed an earlier tree, and a record citing it.
        $root = Join-Path ([IO.Path]::GetTempPath()) ('w39-' + [guid]::NewGuid().ToString('N'))
        New-Item -ItemType Directory -Path (Join-Path $root 'src') -Force | Out-Null
        Set-Content -LiteralPath (Join-Path $root 'src/app.ps1') -Value '# one' -Encoding UTF8
        Push-Location $root
        try {
            & git init --quiet 2>&1 | Out-Null
            & git add -A 2>&1 | Out-Null
            & git -c user.email='t@t' -c user.name='t' commit -m init --quiet 2>&1 | Out-Null
        }
        finally { Pop-Location }
        $runId = 'run-20260821-104557253-97c3785a'
        $runDir = Join-Path $root (Join-Path '.specrew' (Join-Path 'review' (Join-Path 'authority' (Join-Path 'campaigns' (Join-Path 'cmp-w39' (Join-Path 'runs' $runId))))))
        New-Item -ItemType Directory -Path $runDir -Force | Out-Null
        ([ordered]@{
                schema_version = '1.0'; campaign_id = 'cmp-w39'; run_id = $runId
                completion = 'complete'; verdict = 'pass'; currentness = 'current'; validation = 'valid'
                target_digest = 'deadbeefdeadbeefdeadbeefdeadbeefdeadbeef'
            } | ConvertTo-Json -Depth 6 -Compress) | Set-Content -LiteralPath (Join-Path $runDir 'result.json') -Encoding UTF8
        $lines = @('## Review', '',
            '<!-- SPECREW-DERIVED-INDEPENDENT-REVIEW v1 -->',
            "- Run: $runId (harness copilot-cli-file-primary)",
            '<!-- /SPECREW-DERIVED-INDEPENDENT-REVIEW -->')
        return [pscustomobject]@{ Root = $root; Lines = $lines }
    }
    function script:CheckIn {
        param([Parameter(Mandatory)]$Project, [switch]$AsPreflight)
        $prior = $env:SPECREW_REVIEW_PREFLIGHT
        if ($AsPreflight) { $env:SPECREW_REVIEW_PREFLIGHT = '1' } else { Remove-Item Env:SPECREW_REVIEW_PREFLIGHT -ErrorAction SilentlyContinue }
        $errors = [System.Collections.Generic.List[string]]::new()
        try { Test-ReviewCitedRunEvidence -ReviewLines $Project.Lines -ProjectRoot $Project.Root -Errors $errors }
        finally {
            if ($null -eq $prior) { Remove-Item Env:SPECREW_REVIEW_PREFLIGHT -ErrorAction SilentlyContinue } else { $env:SPECREW_REVIEW_PREFLIGHT = $prior }
        }
        return @($errors)
    }
}

Describe 'W39 a moved tree does not block the round that would fix it' {
    It 'ACCEPTANCE: a project whose tree moved can preflight without hand-editing anything' {
        $project = New-MovedTreeProject
        try { @(CheckIn -Project $project -AsPreflight).Count | Should -Be 0 -Because 'the round exists to refresh exactly this citation' }
        finally { Remove-Item -LiteralPath $project.Root -Recurse -Force -ErrorAction SilentlyContinue }
    }

    It 'still refuses the same record in ordinary validation' {
        # Scoped out of preflight, NOT weakened. A stale record still reads stale everywhere else.
        $project = New-MovedTreeProject
        try {
            $found = @(CheckIn -Project $project)
            $found.Count | Should -Be 1
            # DRIFT-007: the fixture's cited tree is invented, so the refusal now says what it can
            # actually establish - the trees differ and the reviewed one is unreachable - rather than
            # asserting staleness it cannot demonstrate. Still one refusal, still outside preflight.
            $found[0] | Should -Match 'the files now are tree'
        }
        finally { Remove-Item -LiteralPath $project.Root -Recurse -Force -ErrorAction SilentlyContinue }
    }

    It 'keeps every other cited-run rule live during preflight' {
        # A preflight is not a licence to cite a bad run - only the freshness rule is scoped out.
        $project = New-MovedTreeProject
        try {
            $runPath = Join-Path $project.Root (Join-Path '.specrew' (Join-Path 'review' (Join-Path 'authority' (Join-Path 'campaigns' (Join-Path 'cmp-w39' (Join-Path 'runs' (Join-Path 'run-20260821-104557253-97c3785a' 'result.json')))))))
            $r = Get-Content -LiteralPath $runPath -Raw -Encoding UTF8 | ConvertFrom-Json
            $r.completion = 'partial'; $r.verdict = 'incomplete'
            ($r | ConvertTo-Json -Depth 6 -Compress) | Set-Content -LiteralPath $runPath -Encoding UTF8
            $found = @(CheckIn -Project $project -AsPreflight)
            $found.Count | Should -Be 1
            $found[0] | Should -Match "completion 'partial'"
        }
        finally { Remove-Item -LiteralPath $project.Root -Recurse -Force -ErrorAction SilentlyContinue }
    }
}

Describe 'W39 THE GENERAL PROPERTY - no refusal names an action it prevents' {
    It 'offers the block-sourced reader a way out that does not require the blocked action' {
        # The property that would have caught all three layers of this shape: W15, W35's first fix, and
        # this. A refusal whose only named remedy is the thing it blocks is a door painted on a wall.
        $project = New-MovedTreeProject
        try {
            $runPath = Join-Path $project.Root (Join-Path '.specrew' (Join-Path 'review' (Join-Path 'authority' (Join-Path 'campaigns' (Join-Path 'cmp-w39' (Join-Path 'runs' (Join-Path 'run-20260821-104557253-97c3785a' 'result.json')))))))
            $r = Get-Content -LiteralPath $runPath -Raw -Encoding UTF8 | ConvertFrom-Json
            $r.completion = 'partial'; $r.verdict = 'incomplete'
            ($r | ConvertTo-Json -Depth 6 -Compress) | Set-Content -LiteralPath $runPath -Encoding UTF8
            $found = @(CheckIn -Project $project)
            $found.Count | Should -Be 1
            $message = [string]$found[0]
            # It may still SUGGEST the run - that is the good outcome when reachable...
            $message | Should -Match 'obtain a run that completed against the current tree'
            # ...but it must also name something the reader can do when it is not.
            $message.ToLowerInvariant() | Should -Match 'withdraw'
            $message | Should -Match "record''s own prose|record's own prose"
        }
        finally { Remove-Item -LiteralPath $project.Root -Recurse -Force -ErrorAction SilentlyContinue }
    }

    It 'names the withdrawal as the record author''s to make, and the block as not theirs' {
        # The distinction that makes the escape legitimate rather than a licence to edit evidence.
        $project = New-MovedTreeProject
        try {
            $runPath = Join-Path $project.Root (Join-Path '.specrew' (Join-Path 'review' (Join-Path 'authority' (Join-Path 'campaigns' (Join-Path 'cmp-w39' (Join-Path 'runs' (Join-Path 'run-20260821-104557253-97c3785a' 'result.json')))))))
            $r = Get-Content -LiteralPath $runPath -Raw -Encoding UTF8 | ConvertFrom-Json
            $r.completion = 'partial'; $r.verdict = 'incomplete'
            ($r | ConvertTo-Json -Depth 6 -Compress) | Set-Content -LiteralPath $runPath -Encoding UTF8
            $message = [string](@(CheckIn -Project $project))[0]
            $message | Should -Match 'cannot be edited out by hand'
            $message | Should -Match 'the block and the store are not'
        }
        finally { Remove-Item -LiteralPath $project.Root -Recurse -Force -ErrorAction SilentlyContinue }
    }
}
