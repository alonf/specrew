$ErrorActionPreference = 'Stop'

# Trace: T058, FR-025, FR-027, NFR-002, TG-013.
# Rules: specs/197-continuous-co-review/implementation-rules.yml
Describe 'Proposal 197 T058 run index records diff_hash/reviewed_ref and resolves the last passing review state' {
    BeforeAll {
        $script:RepoRoot = (Resolve-Path "$PSScriptRoot/../../..").Path
        $script:ScratchTmp = Join-Path $script:RepoRoot '.scratch/tmp'
        New-Item -ItemType Directory -Path $script:ScratchTmp -Force | Out-Null
        $env:SPECREW_MODULE_PATH = $script:RepoRoot
        Import-Module (Join-Path $script:RepoRoot 'Specrew.psd1') -Force
        . (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/_load.ps1')
    }

    function New-T058FakeRunRecord {
        param($Root, $RunId, $CheckpointId, $BaselineRef, $DiffHash, $ReviewedRef, $Status, $CreatedAt)

        $directory = Join-Path (Join-Path $Root '.specrew/review/inline') $RunId
        New-Item -ItemType Directory -Path $directory -Force | Out-Null
        $record = [pscustomobject][ordered]@{
            schema_version = '1.0'
            run_id         = $RunId
            checkpoint_id  = $CheckpointId
            baseline_ref   = $BaselineRef
            diff_hash      = $DiffHash
            reviewed_ref   = $ReviewedRef
            status         = $Status
            created_at     = $CreatedAt
            updated_at     = $CreatedAt
        }
        $record | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath (Join-Path $directory 'review-run.json') -Encoding UTF8 -NoNewline
    }

    It 'records diff_hash from the request change set and reviewed_ref on the durable run record' {
        $request = [pscustomobject][ordered]@{
            schema_version = '2.0'
            run_id         = 'run-t058a'
            request_hash   = 'reqhash'
            change_set     = [pscustomobject]@{ diff_hash = 'sha256:abc' }
        }
        $result = Write-ContinuousCoReviewRunIndex -RepoRoot $TestDrive -RunId 'run-t058a' -CheckpointId 'cp-1' -BaselineRef 'base1' -ReviewedRef 'head1' -ReviewRequest $request -GateVerdict ([pscustomobject]@{ state = 'pass' })
        $written = Get-Content -LiteralPath $result.review_run_path -Raw | ConvertFrom-Json

        $written.diff_hash | Should Be 'sha256:abc'
        $written.reviewed_ref | Should Be 'head1'
        $written.status | Should Be 'pass'
    }

    It 'prefers an explicit DiffHash over the request change set' {
        $request = [pscustomobject][ordered]@{
            schema_version = '2.0'
            run_id         = 'run-t058b'
            change_set     = [pscustomobject]@{ diff_hash = 'sha256:fromrequest' }
        }
        $result = Write-ContinuousCoReviewRunIndex -RepoRoot $TestDrive -RunId 'run-t058b' -CheckpointId 'cp-1' -BaselineRef 'base1' -DiffHash 'sha256:explicit' -ReviewRequest $request -GateVerdict ([pscustomobject]@{ state = 'pass' })
        $written = Get-Content -LiteralPath $result.review_run_path -Raw | ConvertFrom-Json

        $written.diff_hash | Should Be 'sha256:explicit'
    }

    It 'returns null when there is no inline evidence' {
        $emptyRoot = Join-Path $TestDrive 'empty-repo'
        New-Item -ItemType Directory -Path $emptyRoot -Force | Out-Null

        Get-ContinuousCoReviewLastPassingReviewState -RepoRoot $emptyRoot | Should Be $null
    }

    It 'returns the most recent pass or escalated run and skips blocked and unsafe runs' {
        $root = Join-Path $TestDrive 'resolver-repo'
        New-Item -ItemType Directory -Path $root -Force | Out-Null
        New-T058FakeRunRecord -Root $root -RunId 'r1' -CheckpointId 'cp-a' -BaselineRef 'b1' -DiffHash 'h1' -ReviewedRef 'rev1' -Status 'pass' -CreatedAt '2026-06-20T00:00:01Z'
        New-T058FakeRunRecord -Root $root -RunId 'r2' -CheckpointId 'cp-b' -BaselineRef 'b2' -DiffHash 'h2' -ReviewedRef 'rev2' -Status 'blocked' -CreatedAt '2026-06-20T00:00:02Z'
        New-T058FakeRunRecord -Root $root -RunId 'r3' -CheckpointId 'cp-c' -BaselineRef 'b3' -DiffHash 'h3' -ReviewedRef 'rev3' -Status 'escalated' -CreatedAt '2026-06-20T00:00:03Z'

        $state = Get-ContinuousCoReviewLastPassingReviewState -RepoRoot $root
        $state.run_id | Should Be 'r3'
        $state.baseline_ref | Should Be 'b3'
        $state.diff_hash | Should Be 'h3'
        $state.reviewed_ref | Should Be 'rev3'
        $state.status | Should Be 'escalated'
    }

    It 'filters candidates by checkpoint id prefix' {
        $root = Join-Path $TestDrive 'prefix-repo'
        New-Item -ItemType Directory -Path $root -Force | Out-Null
        New-T058FakeRunRecord -Root $root -RunId 'p1' -CheckpointId 'feat-A/cp-1' -BaselineRef 'b1' -DiffHash 'h1' -ReviewedRef 'rev1' -Status 'pass' -CreatedAt '2026-06-20T00:00:05Z'
        New-T058FakeRunRecord -Root $root -RunId 'p2' -CheckpointId 'feat-B/cp-1' -BaselineRef 'b2' -DiffHash 'h2' -ReviewedRef 'rev2' -Status 'pass' -CreatedAt '2026-06-20T00:00:06Z'

        $state = Get-ContinuousCoReviewLastPassingReviewState -RepoRoot $root -CheckpointIdPrefix 'feat-A/'
        $state.run_id | Should Be 'p1'
    }
}
