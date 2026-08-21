#requires -Version 7.0
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# 2026-08-21: how a run's baseline was CHOSEN, recorded as a fact.
#
# `specrew-review.ps1` decides whether a live run is signoff-eligible from one thing: was a baseline
# supplied? Omitted means auto-anchored to the feature merge-base and promotable; an explicit
# `--baseline-ref` makes the run exploratory and NOT promotable, so a narrow `--baseline-ref HEAD~1`
# cannot satisfy review-signoff for earlier changes that were never co-reviewed. That decision lived
# only in control flow (`$scopedExploratoryReview`) and was never persisted, so no later reader could
# tell the two apart from the record.
#
# SCOPE, as agreed: additive, optional, NEW RUNS ONLY, absence read as "not recorded" - the
# examined_paths precedent. Absence is not a value: a run written before this field existed is not an
# exploratory run, it is a run that did not say.
#
# The tree-id half of the original ask was already satisfied and is not rebuilt here: the navigator
# records `baseline_ref`, and the campaign path has no baseline at all because it freezes a whole tree
# (DRIFT-199-I001-080/089). Only the provenance half was genuinely missing.

BeforeAll {
    $script:RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
    . (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/review-run-index-writer.ps1')

    function script:New-IndexProject {
        $root = Join-Path ([IO.Path]::GetTempPath()) ('bpf-' + [guid]::NewGuid().ToString('N'))
        New-Item -ItemType Directory -Path $root -Force | Out-Null
        return $root
    }
    function script:Read-RunIndex {
        param([Parameter(Mandatory)][string]$Root, [Parameter(Mandatory)][string]$RunId)
        $path = Join-Path $Root (Join-Path '.specrew' (Join-Path 'review' (Join-Path 'inline' (Join-Path $RunId 'review-run.json'))))
        if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { return $null }
        return (Get-Content -LiteralPath $path -Raw -Encoding UTF8 | ConvertFrom-Json)
    }
    function script:Write-Index {
        param([Parameter(Mandatory)][string]$Root, [Parameter(Mandatory)][string]$RunId, [string]$BaselineSource)
        $p = @{
            RepoRoot = $Root; RunId = $RunId; CheckpointId = 'cp-1'; BaselineRef = 'abc1234'
            ReviewedRef = 'def5678'; ReviewedTreeId = 'tree-1'
        }
        if ($PSBoundParameters.ContainsKey('BaselineSource')) { $p['BaselineSource'] = $BaselineSource }
        return Write-ContinuousCoReviewRunIndex @p
    }
}

Describe 'the baseline provenance is recorded when the caller states it' {
    It 'persists an auto-anchored run as auto-anchor-merge-base' {
        $root = New-IndexProject
        try {
            $null = Write-Index -Root $root -RunId 'run-auto' -BaselineSource 'auto-anchor-merge-base'
            $record = Read-RunIndex -Root $root -RunId 'run-auto'
            $record | Should -Not -BeNullOrEmpty
            [string]$record.baseline_source | Should -Be 'auto-anchor-merge-base'
            # The tree id half was already recorded and must stay.
            [string]$record.baseline_ref | Should -Be 'abc1234'
        }
        finally { Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue }
    }

    It 'persists an explicitly scoped run as explicit-baseline-ref' {
        # The distinction that decides promotability, now legible from the record alone.
        $root = New-IndexProject
        try {
            $null = Write-Index -Root $root -RunId 'run-scoped' -BaselineSource 'explicit-baseline-ref'
            [string](Read-RunIndex -Root $root -RunId 'run-scoped').baseline_source | Should -Be 'explicit-baseline-ref'
        }
        finally { Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue }
    }
}

Describe 'absence means not recorded, not exploratory' {
    It 'writes no provenance when the caller states none' {
        # A caller that does not know must not have an answer invented for it. This is the whole reason
        # the field is optional rather than defaulted.
        $root = New-IndexProject
        try {
            $null = Write-Index -Root $root -RunId 'run-silent'
            $record = Read-RunIndex -Root $root -RunId 'run-silent'
            $record | Should -Not -BeNullOrEmpty
            $hasValue = ($record.PSObject.Properties.Name -contains 'baseline_source') -and
                (-not [string]::IsNullOrWhiteSpace([string]$record.baseline_source))
            $hasValue | Should -BeFalse -Because 'a run that did not say is not a run that said "exploratory"'
        }
        finally { Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue }
    }

    It 'treats an empty string the same as absent' {
        $root = New-IndexProject
        try {
            $null = Write-Index -Root $root -RunId 'run-empty' -BaselineSource ''
            $record = Read-RunIndex -Root $root -RunId 'run-empty'
            [string]$record.baseline_source | Should -BeNullOrEmpty
        }
        finally { Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue }
    }

    It 'still writes every field a reader already depended on' {
        # Additive means additive: nothing that was there before may move.
        $root = New-IndexProject
        try {
            $null = Write-Index -Root $root -RunId 'run-shape' -BaselineSource 'auto-anchor-merge-base'
            $record = Read-RunIndex -Root $root -RunId 'run-shape'
            foreach ($field in @('schema_version', 'run_id', 'checkpoint_id', 'baseline_ref', 'reviewed_ref', 'reviewed_tree_id', 'status')) {
                $record.PSObject.Properties.Name | Should -Contain $field
            }
        }
        finally { Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue }
    }
}

Describe 'the producer states it rather than a reader inferring it' {
    It 'has the navigator name its auto-anchor path explicitly' {
        # The navigator's promotion writes the merge-base anchor, so the provenance is true by
        # construction there. A field nothing produces would be the shape this project keeps
        # cataloguing, so the producer is pinned alongside the field.
        $navigator = Get-Content -LiteralPath (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/continuous-co-review-navigator.ps1') -Raw -Encoding UTF8
        $navigator.Contains("-BaselineSource 'auto-anchor-merge-base'") | Should -BeTrue
    }
}
