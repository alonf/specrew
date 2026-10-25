#requires -Version 7.0
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# 2026-08-21: a derived hint may promote a task, never demote one.
#
# `Get-TaskProgressDerivedStatusHints` reads the feature-root tasks.md checkboxes, and the hand-driven
# flow leaves those unchecked even after the work is finished. The sync preserved live `in-progress`,
# `blocked`, `needs-rework` and `deferred` against that - but not `done`, so a re-sync silently reset
# completed tasks to `pending`.
#
# The code carried a note saying the iteration-001 re-sync was still exposed and that it was out of
# scope for that slice. It then happened for real: a KeyContextAI re-sync reset all 18 completed tasks
# to `pending`, and state.md began contradicting itself - the managed progress block said 0 tasks
# complete while the prose below said all 18 were done. A deferral with a real instance attached.

BeforeAll {
    $script:RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
    . (Join-Path $script:RepoRoot 'scripts/internal/task-progress.ps1')

    function script:New-LedgerProject {
        # Iteration 001 specifically: the case the deferral note left exposed. tasks.md is UNCHECKED,
        # which is what the hand-driven flow actually leaves behind.
        param([string]$LedgerStatus = 'done')
        $root = Join-Path ([IO.Path]::GetTempPath()) ('tp-' + [guid]::NewGuid().ToString('N'))
        $feature = '001-thing'
        $featureDir = Join-Path $root (Join-Path 'specs' $feature)
        $iter = Join-Path $featureDir (Join-Path 'iterations' '001')
        New-Item -ItemType Directory -Path $iter -Force | Out-Null

        Set-Content -LiteralPath (Join-Path $featureDir 'tasks.md') -Encoding UTF8 -Value @(
            '# Tasks', '', '- [ ] T001 Build the engine', '- [ ] T002 Wire the adapter')
        # The real column set, copied from this project's own plan.md rather than invented: the catalog
        # projects Task/Title/Requirement/Story/Effort, and a fixture missing any of them throws before
        # reaching the behaviour under test.
        Set-Content -LiteralPath (Join-Path $iter 'plan.md') -Encoding UTF8 -Value @(
            '# Iteration Plan', '', '## Tasks', '',
            '| Task | Title | Requirement | Story | Effort | Owner | Owner File Globs | Status | Agent | Actual | Verdict |',
            '| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |',
            '| T001 | Build the engine | FR-001 | S1 | 1 | implementer | src/** | done | implementer | 1 | pass |',
            '| T002 | Wire the adapter | FR-002 | S1 | 1 | implementer | src/** | done | implementer | 1 | pass |')
        Set-Content -LiteralPath (Join-Path $iter 'tasks-progress.yml') -Encoding UTF8 -Value @(
            'schema_version: 1',
            'tasks:',
            '  T001:',
            '    title: Build the engine',
            "    status: $LedgerStatus",
            '    started_at: null',
            '    completed_at: null',
            '    blocked_reason: null',
            '  T002:',
            '    title: Wire the adapter',
            "    status: $LedgerStatus",
            '    started_at: null',
            '    completed_at: null',
            '    blocked_reason: null')
        return [pscustomobject]@{ Root = $root; FeatureRef = $feature; Iteration = $iter }
    }

    function script:Get-LedgerStatuses {
        param([Parameter(Mandatory)][string]$IterationDirectory)
        # The writer emits quoted scalars - status: "done" - so an unquoted-only pattern reads every
        # ledger as empty and every assertion becomes vacuous. Read what the writer actually writes.
        $text = Get-Content -LiteralPath (Join-Path $IterationDirectory 'tasks-progress.yml') -Raw -Encoding UTF8
        return @([regex]::Matches($text, 'status:\s*"?(?<s>[a-z-]+)"?') | ForEach-Object { $_.Groups['s'].Value })
    }
}

Describe 'a re-sync may not demote a completed task' {
    It 'keeps done tasks done when tasks.md is unchecked' {
        # The KeyContextAI shape exactly.
        $p = New-LedgerProject -LedgerStatus 'done'
        try {
            $null = Sync-IterationTaskProgress -ProjectRoot $p.Root -FeatureRef $p.FeatureRef -IterationNumber '001'
            $statuses = Get-LedgerStatuses -IterationDirectory $p.Iteration
            @($statuses | Where-Object { $_ -eq 'pending' }).Count | Should -Be 0 -Because 'an unchecked checkbox is a hint, not a retraction'
            @($statuses | Where-Object { $_ -eq 'done' }).Count | Should -Be 2
        }
        finally { Remove-Item -LiteralPath $p.Root -Recurse -Force -ErrorAction SilentlyContinue }
    }

    It 'still preserves the other live states it always protected' {
        foreach ($live in @('in-progress', 'blocked', 'needs-rework', 'deferred')) {
            $p = New-LedgerProject -LedgerStatus $live
            try {
                $null = Sync-IterationTaskProgress -ProjectRoot $p.Root -FeatureRef $p.FeatureRef -IterationNumber '001'
                @(Get-LedgerStatuses -IterationDirectory $p.Iteration | Where-Object { $_ -eq $live }).Count |
                    Should -Be 2 -Because "$live was already preserved and must stay so"
            }
            finally { Remove-Item -LiteralPath $p.Root -Recurse -Force -ErrorAction SilentlyContinue }
        }
    }

    It 'still lets a ticked checkbox promote a pending task to done' {
        # Promotion is the direction the derivation exists for; only demotion is refused.
        $p = New-LedgerProject -LedgerStatus 'pending'
        try {
            $tasksPath = Join-Path (Join-Path $p.Root (Join-Path 'specs' $p.FeatureRef)) 'tasks.md'
            Set-Content -LiteralPath $tasksPath -Encoding UTF8 -Value @(
                '# Tasks', '', '- [x] T001 Build the engine', '- [x] T002 Wire the adapter')
            $null = Sync-IterationTaskProgress -ProjectRoot $p.Root -FeatureRef $p.FeatureRef -IterationNumber '001'
            @(Get-LedgerStatuses -IterationDirectory $p.Iteration | Where-Object { $_ -eq 'done' }).Count | Should -Be 2
        }
        finally { Remove-Item -LiteralPath $p.Root -Recurse -Force -ErrorAction SilentlyContinue }
    }
}
