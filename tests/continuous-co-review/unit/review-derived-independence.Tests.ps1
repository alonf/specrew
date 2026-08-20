#requires -Version 7.0
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# W34-A (2026-08-20): the independence claim is derived from the store; the judgement around it is not.
#
# The KeyContextAI falsity was one sentence - "the independent review ran and passed against this exact
# tree" - and it is entirely a function of the authority store, so nothing should be writing it by hand.
# The per-task verdicts are NOT derivable and stay authored: a campaign result carries verdict,
# completion, findings, summary and examined_paths, nothing that reconstructs a row citing two live
# observations and an exact contract-violation string. Deriving that table from a run that never saw the
# tasks would trade a false independence claim for a false evidence table.
#
# Integrity is recomputation, not trust in the writer: anything may emit the block, and the validator
# derives it again and refuses a mismatch.

BeforeAll {
    $script:RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
    . (Join-Path $script:RepoRoot 'extensions\specrew-speckit\scripts\shared-governance.ps1')

    $t = $null; $e = $null
    $ast = [System.Management.Automation.Language.Parser]::ParseFile(
        (Join-Path $script:RepoRoot 'extensions\specrew-speckit\scripts\validate-governance.ps1'), [ref]$t, [ref]$e)
    $fn = $ast.FindAll({ param($n) $n -is [System.Management.Automation.Language.FunctionDefinitionAst] -and
            $n.Name -eq 'Test-ReviewDerivedIndependenceBlock' }, $true) | Select-Object -First 1
    if (-not $fn) { throw 'Test-ReviewDerivedIndependenceBlock not found' }
    . ([scriptblock]::Create($fn.Extent.Text))

    function script:New-StoreProject {
        param(
            [string]$Completion = 'complete', [string]$Verdict = 'pass',
            [string]$Currentness = 'current', [string]$Validation = 'valid',
            [object[]]$ExaminedPaths, [switch]$DeclareExamined, [switch]$NoRun,
            [string]$RunId = 'run-20260820-083412478-d85dda20'
        )
        $root = Join-Path ([IO.Path]::GetTempPath()) ('w34a-' + [guid]::NewGuid().ToString('N'))
        New-Item -ItemType Directory -Path $root -Force | Out-Null
        if (-not $NoRun) {
            $runDir = Join-Path $root ".specrew/review/authority/campaigns/cmp-a/runs/$RunId"
            New-Item -ItemType Directory -Path $runDir -Force | Out-Null
            $result = [ordered]@{
                schema_version = '1.0'; campaign_id = 'cmp-a'; run_id = $RunId; harness_id = 'copilot-cli-file-primary'
                completion = $Completion; verdict = $Verdict; currentness = $Currentness; validation = $Validation
                target_digest = 'b64dbee0fc94b608be2dc32d19871c010632e6be'; findings = @()
            }
            if ($DeclareExamined) { $result['examined_paths'] = @($ExaminedPaths) }
            [IO.File]::WriteAllText((Join-Path $runDir 'result.json'), ($result | ConvertTo-Json -Depth 8 -Compress), [Text.UTF8Encoding]::new($false))
        }
        return $root
    }
    function script:CheckBlock {
        param([Parameter(Mandatory)][string]$Root, [Parameter(Mandatory)][string]$Block)
        $errors = [System.Collections.Generic.List[string]]::new()
        Test-ReviewDerivedIndependenceBlock -ReviewLines @($Block -split "`n") -ProjectRoot $Root -Errors $errors
        return @($errors)
    }
}

Describe 'W34-A deriving the independence claim' {
    It 'names the qualifying run and the tree it reviewed' {
        $root = New-StoreProject -DeclareExamined -ExaminedPaths @('src/Engine.cs', 'src/Map.cs')
        try {
            $block = Get-SpecrewDerivedIndependenceBlock -ProjectRoot $root
            $block | Should -Match 'run-20260820-083412478-d85dda20'
            $block | Should -Match 'b64dbee0'
            $block | Should -Match '2 source path\(s\) of 2 declared'
        }
        finally { Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue }
    }

    It 'says coverage is UNKNOWN for a run that predates the declared-coverage contract' {
        # Derived from the real KeyContextAI store this names run-...083412478 - the 67-second run that
        # read governance artifacts. Such a run stays eligible so the gate does not wedge shut on the
        # past, so the block must LABEL it rather than lend it derived authority.
        $root = New-StoreProject
        try {
            $block = Get-SpecrewDerivedIndependenceBlock -ProjectRoot $root
            $block | Should -Match 'Coverage: UNKNOWN'
            $block | Should -Match 'evidence that a review RAN, not evidence'
        }
        finally { Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue }
    }

    It 'refuses to count a run whose declared coverage holds no source' {
        $root = New-StoreProject -DeclareExamined -ExaminedPaths @('specs/001-x/iterations/001/plan.md')
        try {
            Get-SpecrewDerivedIndependenceBlock -ProjectRoot $root |
                Should -Match 'No run in this project'
        }
        finally { Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue }
    }

    It 'says so plainly when nothing qualifies' {
        foreach ($project in @(
                (New-StoreProject -NoRun),
                (New-StoreProject -Completion 'partial' -Verdict 'incomplete'),
                (New-StoreProject -Currentness 'stale'),
                (New-StoreProject -Validation 'invalid'))) {
            try {
                $block = Get-SpecrewDerivedIndependenceBlock -ProjectRoot $project
                $block | Should -Match 'No run in this project'
                $block | Should -Match 'must say what'
            }
            finally { Remove-Item -LiteralPath $project -Recurse -Force -ErrorAction SilentlyContinue }
        }
    }

    It 'counts a findings verdict, which is a reviewed outcome' {
        $root = New-StoreProject -Verdict 'findings' -DeclareExamined -ExaminedPaths @('src/Engine.cs')
        try { Get-SpecrewDerivedIndependenceBlock -ProjectRoot $root | Should -Match 'run-20260820' }
        finally { Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue }
    }
}

Describe 'W34-A the block cannot be authored by hand' {
    It 'accepts a record carrying exactly the derived block' {
        $root = New-StoreProject -DeclareExamined -ExaminedPaths @('src/Engine.cs')
        try { @(CheckBlock -Root $root -Block (Get-SpecrewDerivedIndependenceBlock -ProjectRoot $root)).Count | Should -Be 0 }
        finally { Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue }
    }

    It 'refuses a block edited to name a run the store does not support' {
        # The KeyContextAI shape, mechanised: a record asserting an independent pass it does not have.
        $root = New-StoreProject -Completion 'partial' -Verdict 'incomplete'
        try {
            $forged = @(
                '<!-- SPECREW-DERIVED-INDEPENDENT-REVIEW v1 -->',
                '<!-- Derived from the review authority store. Do not hand-edit: the validator recomputes it. -->',
                '- Run: run-20260819-211204294-86de8c6e (harness copilot-cli-file-primary)',
                '- Outcome: pass, complete, current, valid - 0 finding(s)',
                '- Reviewed tree: b8585be9fc94b608be2dc32d19871c010632e6be',
                '<!-- /SPECREW-DERIVED-INDEPENDENT-REVIEW -->') -join "`n"
            $found = @(CheckBlock -Root $root -Block $forged)
            $found.Count | Should -Be 1
            $found[0] | Should -Match 'does not match what this project'
        }
        finally { Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue }
    }

    It 'is not fooled by CRLF, so a Windows checkout does not read as tampering' {
        $root = New-StoreProject -DeclareExamined -ExaminedPaths @('src/Engine.cs')
        try {
            $crlf = (Get-SpecrewDerivedIndependenceBlock -ProjectRoot $root).Replace("`n", "`r`n")
            @(CheckBlock -Root $root -Block $crlf).Count | Should -Be 0
        }
        finally { Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue }
    }

    It 'stays silent on a record that carries no block at all' {
        # Fail-open on absence, like W33 and W34-B: every record written before this has none.
        $root = New-StoreProject
        try { @(CheckBlock -Root $root -Block "# Review: Iteration 001`n`nAll tasks verified.").Count | Should -Be 0 }
        finally { Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue }
    }
}
