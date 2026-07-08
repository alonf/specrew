#requires -Version 7.0
# T093 / FR-035 + SEC-004 (iter-009 D1): host-independence is a pre-flight, FIRST-CLASS label.
#   - An independent authorized peer is preferred (existing behavior) and labelled 'independent'.
#   - When only the code-writer host is authorized, the same-host review FIRES IMMEDIATELY as a
#     LABELLED fallback ('same-host') - never blocks, never silently substitutes; the navigator
#     surfaces the one-time authorize-an-independent-host ask, and the answer upgrades the NEXT run.
#   - An explicit --host is honoured (labelled) or SURFACED ('requested-host-not-available'), never
#     silently substituted.
#   - An unknown code-writer host labels 'unverified' (the gate treats it as not-independent).

BeforeAll {
    $script:RepoRoot = (Resolve-Path "$PSScriptRoot/../../..").Path
    . (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/_load.ps1')
    . (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/worktree-review-orchestrator.ps1')
    . (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/continuous-co-review-navigator.ps1')

    function script:New-TestCatalogRow {
        param([string]$HostName, [string]$AuthorizationRef, [int]$Rank = 5)
        return [pscustomobject]@{
            host              = $HostName
            model             = "model-$HostName"
            adapter_id        = "ccr-$HostName"
            allowed           = $true
            installed         = $true
            fallback_allowed  = $true
            review_class_rank = $Rank
            model_source      = 'catalog'
            cost_class        = 'non-default'
            authorization_ref = $AuthorizationRef
            timeout_seconds   = 30
        }
    }

    function script:New-TempGitRepo {
        $repo = Join-Path ([System.IO.Path]::GetTempPath()) ('t093-repo-' + [guid]::NewGuid().ToString('N'))
        New-Item -ItemType Directory -Path $repo -Force | Out-Null
        & git -C $repo init -q 2>&1 | Out-Null
        Set-Content -LiteralPath (Join-Path $repo 'app.txt') -Value 'content' -Encoding UTF8
        & git -C $repo -c user.name='t' -c user.email='t@t.local' add -A 2>&1 | Out-Null
        & git -C $repo -c user.name='t' -c user.email='t@t.local' commit -q -m seed 2>&1 | Out-Null
        return $repo
    }
}

Describe 'T093 reviewer independence labelling (selection policy)' {

    It 'labels the preferred independent peer as independent' {
        $catalog = [pscustomobject]@{ hosts = @((script:New-TestCatalogRow -HostName 'claude' -AuthorizationRef 'ref-a'), (script:New-TestCatalogRow -HostName 'codex' -AuthorizationRef 'ref-b')) }
        $sel = Select-ContinuousCoReviewReviewerCandidate -Catalog $catalog -CodeWriterHost 'claude'
        $sel.host | Should -Be 'codex'
        $sel.independence | Should -Be 'independent'
        $sel.selection_reason | Should -Be 'preferred-independent-reviewer-for-code-writer-host'
    }

    It 'fires the same-host candidate as a LABELLED fallback when no independent host is authorized' {
        $catalog = [pscustomobject]@{ hosts = @((script:New-TestCatalogRow -HostName 'claude' -AuthorizationRef 'ref-a'), (script:New-TestCatalogRow -HostName 'codex' -AuthorizationRef '')) }
        $sel = Select-ContinuousCoReviewReviewerCandidate -Catalog $catalog -CodeWriterHost 'claude'
        $sel | Should -Not -BeNullOrEmpty -Because 'never block: the same-host review fires immediately (D1)'
        $sel.host | Should -Be 'claude'
        $sel.independence | Should -Be 'same-host'
        $sel.selection_reason | Should -Be 'same-host-fallback-no-independent-authorized'
    }

    It 'honours an explicit same-host request and labels it (requested-host-honoured)' {
        $catalog = [pscustomobject]@{ hosts = @((script:New-TestCatalogRow -HostName 'claude' -AuthorizationRef 'ref-a'), (script:New-TestCatalogRow -HostName 'codex' -AuthorizationRef 'ref-b')) }
        $sel = Select-ContinuousCoReviewReviewerCandidate -Catalog $catalog -CodeWriterHost 'claude' -RequestedHost 'claude'
        $sel.host | Should -Be 'claude' -Because 'an explicit --host is honoured even when an independent peer exists'
        $sel.independence | Should -Be 'same-host'
        $sel.selection_reason | Should -Be 'requested-host-honoured'
    }

    It 'labels unverified when the code-writer host is unknown' {
        $catalog = [pscustomobject]@{ hosts = @((script:New-TestCatalogRow -HostName 'claude' -AuthorizationRef 'ref-a')) }
        $sel = Select-ContinuousCoReviewReviewerCandidate -Catalog $catalog
        $sel.independence | Should -Be 'unverified' -Because 'independence cannot be asserted without knowing the code-writer'
    }

    It 'returns null (for surfacing) when the explicitly requested host is not eligible' {
        $catalog = [pscustomobject]@{ hosts = @((script:New-TestCatalogRow -HostName 'claude' -AuthorizationRef 'ref-a')) }
        $sel = Select-ContinuousCoReviewReviewerCandidate -Catalog $catalog -CodeWriterHost 'claude' -RequestedHost 'codex'
        $sel | Should -BeNullOrEmpty -Because 'an un-honourable --host must surface, not silently substitute'
    }
}

Describe 'T093 orchestrator surfaces the selection outcome' {

    It 'distinguishes requested-host-not-available from no-authorized-reviewer-host' {
        $repo = script:New-TempGitRepo
        try {
            # A fresh repo has no .specrew/reviewer-hosts.json -> nothing is authorized.
            $runDir1 = Join-Path $repo '.runs/r1'
            $st1 = Invoke-ContinuousCoReviewWorktreeReviewRun -RepoRoot $repo -RunDir $runDir1 -RunId 't093-auto' -TimeoutSeconds 30
            $st1.status | Should -Be 'failed'
            $st1.failure_reason | Should -Be 'no-authorized-reviewer-host'

            $runDir2 = Join-Path $repo '.runs/r2'
            $st2 = Invoke-ContinuousCoReviewWorktreeReviewRun -RepoRoot $repo -RunDir $runDir2 -RunId 't093-req' -RequestedHost 'codex' -TimeoutSeconds 30
            $st2.status | Should -Be 'failed'
            $st2.failure_reason | Should -Match '^requested-host-not-available' -Because 'the explicit --host outcome is surfaced with its own reason'
            $st2.failure_reason | Should -Match 'codex'
        }
        finally {
            Remove-Item -LiteralPath $repo -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}

Describe 'T093 navigator surfaces the same-host label + upgrade ask' {

    It 'appends the same-host note and the authorize-once upgrade ask to a surfaced verdict' {
        $repo = script:New-TempGitRepo
        try {
            $runId = 't093-samehost-note'
            $runDir = Join-Path $repo ".specrew/review/pending/$runId"
            New-Item -ItemType Directory -Path $runDir -Force | Out-Null
            $resultPath = Join-Path $runDir 'result.out'
            # A non-pass, non-blocking verdict -> the advisory branch (no promotion machinery needed).
            Set-Content -LiteralPath $resultPath -Value '{"disposition":"needs-work","blocking":false,"summary":"minor"}' -Encoding UTF8
            $pendingDir = Join-Path $repo '.specrew/review/pending'
            $reg = [pscustomobject]@{
                schema_version        = '1.0'
                run_id                = $runId
                status                = 'done'
                result_path           = $resultPath
                run_dir               = $runDir
                tree_id               = 'deadbeef'
                reviewer_independence = 'same-host'
            }
            ($reg | ConvertTo-Json -Depth 6) | Set-Content -LiteralPath (Join-Path $pendingDir "$runId.json") -Encoding UTF8

            $reap = Invoke-ContinuousCoReviewNavigatorReap -RepoRoot $repo
            $notes = @($reap.inject_notes) -join ' || '
            $notes | Should -Match 'SAME-HOST' -Because 'a same-host fallback review is surfaced as such (FR-035)'
            $notes | Should -Match 'Authorize an INDEPENDENT reviewer once' -Because 'the one-time upgrade ask rides the surfaced verdict'
        }
        finally {
            Remove-Item -LiteralPath $repo -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}
