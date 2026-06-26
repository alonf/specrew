$ErrorActionPreference = 'Stop'

Describe 'Proposal 197 T015 TG-011 review run workspace manager obeys implementation-rules.yml lifecycle rules' {
    BeforeAll {
        $script:RepoRoot = (Resolve-Path "$PSScriptRoot/../../..").Path
        $script:ScratchTmp = Join-Path $script:RepoRoot '.scratch/tmp'
        New-Item -ItemType Directory -Path $script:ScratchTmp -Force | Out-Null
        $env:TEMP = $script:ScratchTmp
        $env:TMP = $script:ScratchTmp
        $env:SPECREW_MODULE_PATH = $script:RepoRoot
        Import-Module (Join-Path $script:RepoRoot 'Specrew.psd1') -Force
        . (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/_load.ps1')
    

        # v5: helpers moved here so they are visible inside It blocks (Discovery/Run split).
        function Get-T015Command {
                param(
                    [Parameter(Mandatory)]
                    [string] $Name
                )

                $command = Get-Command -Name $Name -ErrorAction SilentlyContinue
                $null = ($command | Should -Not -BeNullOrEmpty)
                return $command
            }

        function New-T015Request {
                param(
                    [string] $RunId = 'run-t015-001'
                )

                return [pscustomobject][ordered]@{
                    schema_version = '1.0'
                    run_id         = $RunId
                    checkpoint_id  = 'checkpoint-t015'
                    request_hash   = "sha256:$($RunId.PadRight(64, '0').Substring(0, 64))"
                    created_at     = '2026-06-17T21:15:00Z'
                }
            }

        function New-T015BlockedVerdict {
                return [pscustomobject][ordered]@{
                    schema_version             = '1.0'
                    verdict_id                 = 'verdict-t015-blocked'
                    run_id                     = 'run-t015-cleanup-failure'
                    checkpoint_id              = 'checkpoint-t015'
                    state                      = 'blocked'
                    unresolved_blocking_count  = 1
                    blocking_finding_ids       = @('finding-t015-001')
                    created_at                 = '2026-06-17T21:16:00Z'
                }
            }
}

    

    

    

    It 'declares T015 workspace manager commands before run bundles are consumed' {
        Get-T015Command -Name 'New-ContinuousCoReviewRunWorkspace' | Should -Not -BeNullOrEmpty
        Get-T015Command -Name 'Write-ContinuousCoReviewRequestBundle' | Should -Not -BeNullOrEmpty
        Get-T015Command -Name 'Complete-ContinuousCoReviewRunWorkspace' | Should -Not -BeNullOrEmpty
    }

    It 'creates unique per-run workspaces and never reuses a workspace path across run ids' {
        $newWorkspace = Get-T015Command -Name 'New-ContinuousCoReviewRunWorkspace'
        $root = Join-Path $TestDrive 'review-run-workspaces'

        $first = & $newWorkspace -RootPath $root -RunId 'run-t015-unique-001'
        $second = & $newWorkspace -RootPath $root -RunId 'run-t015-unique-002'

        $first.run_id | Should -Be 'run-t015-unique-001'
        $second.run_id | Should -Be 'run-t015-unique-002'
        $first.path | Should -Not -Be $second.path
        (Test-Path -LiteralPath $first.path -PathType Container) | Should -Be $true
        (Test-Path -LiteralPath $second.path -PathType Container) | Should -Be $true
    }

    It 'writes immutable request bundles and rejects overwrite or bundle reuse attempts' {
        $newWorkspace = Get-T015Command -Name 'New-ContinuousCoReviewRunWorkspace'
        $writeBundle = Get-T015Command -Name 'Write-ContinuousCoReviewRequestBundle'
        $workspace = & $newWorkspace -RootPath (Join-Path $TestDrive 'immutable-bundles') -RunId 'run-t015-immutable'
        $request = New-T015Request -RunId 'run-t015-immutable'

        $bundle = & $writeBundle -Workspace $workspace -Request $request
        (Test-Path -LiteralPath $bundle.request_path -PathType Leaf) | Should -Be $true
        $bundle.immutable | Should -Be $true

        $overwriteThrew = $false
        try {
            & $writeBundle -Workspace $workspace -Request $request
        }
        catch {
            $overwriteThrew = $true
        }

        $reuseThrew = $false
        try {
            & $writeBundle -Workspace $workspace -Request (New-T015Request -RunId 'run-t015-reused')
        }
        catch {
            $reuseThrew = $true
        }

        $overwriteThrew | Should -Be $true
        $reuseThrew | Should -Be $true
    }

    It 'cleans temporary run workspaces by default after durable outcome persistence' {
        $newWorkspace = Get-T015Command -Name 'New-ContinuousCoReviewRunWorkspace'
        $completeWorkspace = Get-T015Command -Name 'Complete-ContinuousCoReviewRunWorkspace'
        $workspace = & $newWorkspace -RootPath (Join-Path $TestDrive 'cleanup-default') -RunId 'run-t015-cleanup-default'

        $result = & $completeWorkspace -Workspace $workspace -PreserveDebug:$false -GateVerdict ([pscustomobject]@{ state = 'pass'; run_id = 'run-t015-cleanup-default' })

        $result.cleanup_status | Should -Be 'cleaned'
        (Test-Path -LiteralPath $workspace.path) | Should -Be $false
    }

    It 'preserves temporary workspaces only when explicit debug preservation is enabled' {
        $newWorkspace = Get-T015Command -Name 'New-ContinuousCoReviewRunWorkspace'
        $completeWorkspace = Get-T015Command -Name 'Complete-ContinuousCoReviewRunWorkspace'
        $workspace = & $newWorkspace -RootPath (Join-Path $TestDrive 'debug-preserve') -RunId 'run-t015-debug-preserve'

        $result = & $completeWorkspace -Workspace $workspace -PreserveDebug:$true -GateVerdict ([pscustomobject]@{ state = 'pass'; run_id = 'run-t015-debug-preserve' })

        $result.cleanup_status | Should -Be 'preserved-for-debug'
        (Test-Path -LiteralPath $workspace.path -PathType Container) | Should -Be $true
    }

    It 'records cleanup failure without converting an existing blocked verdict into a pass' {
        $newWorkspace = Get-T015Command -Name 'New-ContinuousCoReviewRunWorkspace'
        $completeWorkspace = Get-T015Command -Name 'Complete-ContinuousCoReviewRunWorkspace'
        $workspace = & $newWorkspace -RootPath (Join-Path $TestDrive 'cleanup-failure') -RunId 'run-t015-cleanup-failure'
        $blockedVerdict = New-T015BlockedVerdict

        $result = & $completeWorkspace -Workspace $workspace -PreserveDebug:$false -GateVerdict $blockedVerdict -CleanupAction { throw 'simulated cleanup lock' }

        $result.gate_verdict.state | Should -Be 'blocked'
        $result.cleanup_status | Should -Be 'failed'
        $result.cleanup_failure.category | Should -Be 'cleanup-failed'
        $result.cleanup_failure.safe_details | ConvertTo-Json -Depth 20 | Should -Not -Match 'simulated cleanup lock'
    }
}
