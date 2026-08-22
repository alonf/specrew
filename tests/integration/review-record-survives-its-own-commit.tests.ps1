#requires -Version 7.0
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# DRIFT-007 (2026-08-22): W38 AND W34-A HAD NO MUTUALLY SATISFIABLE STATE, AND THE CAUSE WAS UNIVERSAL.
#
#   derived block present -> W38 fails: the cited run's tree is not the current tree.
#   derived block absent  -> W34-A's absence arm hard-fails for any record with observed authorship.
#
# Each check's only offered remedy was the state the other refused.
#
# The cause: the reviewed-state digest excludes `.specrew/`, `.specify/`, `.squad/`, `.scratch/` and six
# named `.pending` byproducts - but not `specs/`. review.md, drift-log.md, state.md and every closeout
# artifact are inside the digest, so RECORDING a review moves the tree the review is measured against.
# Every run went stale at its own recording commit. It shipped four days before it first met a project
# that committed a result.
#
# WHY A FULL SUITE MISSED IT: nothing in the W38 suite ever committed the record it had just written.
# Every case checked a citation against a tree, correctly, in isolation - the third defect this week
# proven right in isolation and never exercised through the sequence a real project follows.
#
# So these cases run the sequence: real git repo, real reviewed-state digest, real authority-store
# result, real derived block, a real commit of the record, and only then validation.

BeforeAll {
    $script:RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
    . (Join-Path $script:RepoRoot 'extensions\specrew-speckit\scripts\shared-governance.ps1')
    . (Join-Path $script:RepoRoot 'scripts\internal\continuous-co-review\reviewed-state-digest.ps1')

    # The check under test, lifted from the shipped validator rather than reimplemented.
    $t = $null; $e = $null
    $ast = [System.Management.Automation.Language.Parser]::ParseFile(
        (Join-Path $script:RepoRoot 'extensions\specrew-speckit\scripts\validate-governance.ps1'), [ref]$t, [ref]$e)
    foreach ($name in @('Test-ReviewCitedRunEvidence', 'Write-TrustHardeningWarning')) {
        $fn = $ast.FindAll({ param($n) $n -is [System.Management.Automation.Language.FunctionDefinitionAst] -and
                $n.Name -eq $name }, $true) | Select-Object -First 1
        if (-not $fn) { throw "$name not found in the shipped validator" }
        . ([scriptblock]::Create($fn.Extent.Text))
    }

    function script:Invoke-Git {
        param([Parameter(Mandatory)][string]$Root, [Parameter(Mandatory)][string[]]$GitArgs)
        $out = & git -C $Root @GitArgs 2>&1
        if ($LASTEXITCODE -ne 0) { throw ("git {0} failed: {1}" -f ($GitArgs -join ' '), ($out -join '; ')) }
        return $out
    }

    function script:New-ReviewedProject {
        # A project with source, a governed iteration, and a committed history - the shape the digest
        # and the store both assume. Nothing here is mocked: the tree-ids come from the real digest.
        $root = Join-Path ([IO.Path]::GetTempPath()) ('drift007-' + [guid]::NewGuid().ToString('N'))
        New-Item -ItemType Directory -Path (Join-Path $root 'src') -Force | Out-Null
        New-Item -ItemType Directory -Path (Join-Path $root 'specs/001-fixture/iterations/001') -Force | Out-Null
        Set-Content -LiteralPath (Join-Path $root 'src/app.ts') -Value 'export const hello = () => "hi";' -Encoding UTF8
        Set-Content -LiteralPath (Join-Path $root 'src/util.ts') -Value 'export const add = (a: number, b: number) => a + b;' -Encoding UTF8
        Invoke-Git -Root $root -GitArgs @('init', '--quiet') | Out-Null
        Invoke-Git -Root $root -GitArgs @('config', 'user.email', 'fixture@example.invalid') | Out-Null
        Invoke-Git -Root $root -GitArgs @('config', 'user.name', 'Fixture') | Out-Null
        Invoke-Git -Root $root -GitArgs @('add', '-A') | Out-Null
        Invoke-Git -Root $root -GitArgs @('commit', '--quiet', '-m', 'the code under review') | Out-Null
        return $root
    }

    function script:Write-StoreResult {
        # A real ReviewResult in the real store layout, frozen against the tree that exists NOW.
        param(
            [Parameter(Mandatory)][string]$Root,
            [Parameter(Mandatory)][string]$TargetDigest,
            [string]$RunId = 'run-20260822-101500000-abcdef01'
        )
        $runDir = Join-Path $Root ".specrew/review/authority/campaigns/cmp-drift007/runs/$RunId"
        New-Item -ItemType Directory -Path $runDir -Force | Out-Null
        $result = [ordered]@{
            schema_version = '1.0'; campaign_id = 'cmp-drift007'; run_id = $RunId
            target_digest = $TargetDigest; harness_id = 'fixture-harness'
            completion = 'complete'; verdict = 'pass'; runtime_outcome = 'completed'
            termination_verified = $true; containment = 'verified'; currentness = 'current'
            validation = 'valid'; can_approve_current = $true; failure_reason = $null
            summary = 'Reviewed the fixture source.'; findings = @()
            started_at = '2026-08-22T10:15:00Z'; ended_at = '2026-08-22T10:16:00Z'; duration_ms = 60000
            examined_paths = @('src/app.ts', 'src/util.ts')
        }
        [IO.File]::WriteAllText((Join-Path $runDir 'result.json'),
            (($result | ConvertTo-Json -Depth 12) + [Environment]::NewLine), [Text.UTF8Encoding]::new($false))
        return $RunId
    }

    function script:Write-ReviewRecord {
        # The record as a real closeout writes it: prose plus the derived block, which is where the run
        # id the validator reads actually comes from.
        param([Parameter(Mandatory)][string]$Root)
        $block = Get-SpecrewDerivedIndependenceBlock -ProjectRoot $Root
        $body = @(
            '# Review: Iteration 001'
            ''
            '**Overall Verdict**: accepted'
            ''
            '## Independence'
            ''
            $block
            ''
        ) -join [Environment]::NewLine
        $path = Join-Path $Root 'specs/001-fixture/iterations/001/review.md'
        [IO.File]::WriteAllText($path, $body, [Text.UTF8Encoding]::new($false))
        return $path
    }

    function script:Get-StaleErrors {
        param([Parameter(Mandatory)][string]$Root)
        $reviewPath = Join-Path $Root 'specs/001-fixture/iterations/001/review.md'
        $errors = [System.Collections.Generic.List[string]]::new()
        $script:ValidatorSoftWarnings = 0
        Test-ReviewCitedRunEvidence -ProjectRoot $Root -ReviewLines @(Get-Content -LiteralPath $reviewPath -Encoding UTF8) -Errors $errors
        return @($errors)
    }

    function script:Get-CurrentTree {
        param([Parameter(Mandatory)][string]$Root)
        $state = Get-ContinuousCoReviewReviewedStateDigest -RepoRoot $Root
        if ($null -eq $state -or -not [bool]$state.ok) { throw 'the fixture digest did not compute' }
        return [string]$state.tree_id
    }
}

Describe 'DRIFT-007 a project that records a review can still validate' {
    It 'ACCEPTANCE: write the record, COMMIT it, and validation passes' {
        # The case the W38 suite never had. Everything before the commit was already green; the commit
        # is what moved the tree, and the commit is what every real project does next.
        $root = New-ReviewedProject
        try {
            $reviewed = Get-CurrentTree -Root $root
            $null = Write-StoreResult -Root $root -TargetDigest $reviewed
            $null = Write-ReviewRecord -Root $root
            Invoke-Git -Root $root -GitArgs @('add', '-A') | Out-Null
            Invoke-Git -Root $root -GitArgs @('commit', '--quiet', '-m', 'record the review') | Out-Null

            (Get-CurrentTree -Root $root) | Should -Not -Be $reviewed -Because 'recording the review DOES move the digest; that is the premise, not the bug'
            @(Get-StaleErrors -Root $root) | Should -BeNullOrEmpty -Because 'only records moved, and records are not the reviewed surface'
        }
        finally { Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue }
    }

    It 'goes stale the moment source changes, and names what moved' {
        # The guarantee W38 exists for, kept. If this ever passes, the fix has become a hole.
        $root = New-ReviewedProject
        try {
            $reviewed = Get-CurrentTree -Root $root
            $null = Write-StoreResult -Root $root -TargetDigest $reviewed
            $null = Write-ReviewRecord -Root $root
            Set-Content -LiteralPath (Join-Path $root 'src/app.ts') -Value 'export const hello = () => "CHANGED";' -Encoding UTF8
            Invoke-Git -Root $root -GitArgs @('add', '-A') | Out-Null
            Invoke-Git -Root $root -GitArgs @('commit', '--quiet', '-m', 'change the code after the review') | Out-Null

            $errors = @(Get-StaleErrors -Root $root)
            @($errors).Count | Should -Be 1
            $errors[0] | Should -Match 'source file\(s\) have changed since'
            $errors[0] | Should -Match 'src/app\.ts'
        }
        finally { Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue }
    }

    It 'still goes stale when source and records move together' {
        # The realistic rework shape - a fix plus its drift entry - must not hide behind the records.
        $root = New-ReviewedProject
        try {
            $reviewed = Get-CurrentTree -Root $root
            $null = Write-StoreResult -Root $root -TargetDigest $reviewed
            $null = Write-ReviewRecord -Root $root
            Set-Content -LiteralPath (Join-Path $root 'src/util.ts') -Value 'export const add = (a: number, b: number) => a + b + 0;' -Encoding UTF8
            Set-Content -LiteralPath (Join-Path $root 'specs/001-fixture/iterations/001/drift-log.md') -Value "# Drift`n`n- something" -Encoding UTF8
            Invoke-Git -Root $root -GitArgs @('add', '-A') | Out-Null
            Invoke-Git -Root $root -GitArgs @('commit', '--quiet', '-m', 'fix plus its record') | Out-Null

            $errors = @(Get-StaleErrors -Root $root)
            @($errors).Count | Should -Be 1
            $errors[0] | Should -Match 'src/util\.ts'
        }
        finally { Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue }
    }

    It 'refuses rather than passes when the reviewed tree can no longer be found' {
        # Fail-open would be wrong here: the tree moved, and "I cannot tell what changed" is a weaker
        # claim than staleness but it is not a clean bill. It is reported as exactly what it is.
        $root = New-ReviewedProject
        try {
            $null = Write-StoreResult -Root $root -TargetDigest ('0' * 40)
            $null = Write-ReviewRecord -Root $root
            Invoke-Git -Root $root -GitArgs @('add', '-A') | Out-Null
            Invoke-Git -Root $root -GitArgs @('commit', '--quiet', '-m', 'record the review') | Out-Null

            $errors = @(Get-StaleErrors -Root $root)
            @($errors).Count | Should -Be 1
            $errors[0] | Should -Match 'no longer in this repository''s object store'
        }
        finally { Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue }
    }

    It 'the general property: after recording a review, a project validates' {
        # Stated as the property rather than the instance, because the instance was already true before
        # the commit. Two consecutive record-only commits, the shape a closeout actually produces.
        $root = New-ReviewedProject
        try {
            $reviewed = Get-CurrentTree -Root $root
            $null = Write-StoreResult -Root $root -TargetDigest $reviewed
            $null = Write-ReviewRecord -Root $root
            Invoke-Git -Root $root -GitArgs @('add', '-A') | Out-Null
            Invoke-Git -Root $root -GitArgs @('commit', '--quiet', '-m', 'record the review') | Out-Null
            Set-Content -LiteralPath (Join-Path $root 'specs/001-fixture/iterations/001/retro.md') -Value "# Retro`n" -Encoding UTF8
            Set-Content -LiteralPath (Join-Path $root 'specs/001-fixture/iterations/001/code-map.md') -Value "# Code Map`n" -Encoding UTF8
            Invoke-Git -Root $root -GitArgs @('add', '-A') | Out-Null
            Invoke-Git -Root $root -GitArgs @('commit', '--quiet', '-m', 'closeout artifacts') | Out-Null

            @(Get-StaleErrors -Root $root) | Should -BeNullOrEmpty
        }
        finally { Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue }
    }
}
