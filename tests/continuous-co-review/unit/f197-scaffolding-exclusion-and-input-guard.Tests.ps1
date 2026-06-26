$ErrorActionPreference = 'Stop'

# F-197 post-iter-005 fast-follow (wire the REAL reviewer so co-review reviews real code):
#   - scaffolding exclusion default + project-relative (subtree) matching + config override
#   - large-diff graceful cap (byte-budget truncation with an explicit marker)
#   - adapter input-size guard ('input-too-large' before the host is invoked)
#   - navigator "state the reason" (the reap surfaces a failure sidecar's safe category/message)
# Rules: specs/197-continuous-co-review/implementation-rules.yml
Describe 'F-197 scaffolding exclusion + large-diff cap + input-size guard' {
    BeforeAll {
        $script:RepoRoot = (Resolve-Path "$PSScriptRoot/../../..").Path
        $script:ScratchTmp = Join-Path $script:RepoRoot '.scratch/tmp'
        New-Item -ItemType Directory -Path $script:ScratchTmp -Force | Out-Null
        $env:TEMP = $script:ScratchTmp
        $env:TMP = $script:ScratchTmp
        $env:SPECREW_MODULE_PATH = $script:RepoRoot
        Import-Module (Join-Path $script:RepoRoot 'Specrew.psd1') -Force
        . (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/_load.ps1')
        # The navigator is NOT loaded by _load.ps1 (the dispatcher-facing provider dot-sources it directly);
        # dot-source it here for Get-ContinuousCoReviewNavigatorFailureReason.
        . (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/continuous-co-review-navigator.ps1')
        $script:SchemaRoot = Join-Path $script:RepoRoot 'specs/197-continuous-co-review/contracts'

        function Invoke-CcrGit { param($Root, [string[]] $GitArgs) Push-Location $Root; try { & git @GitArgs 2>&1 | Out-Null } finally { Pop-Location } }

        # Create a git repo (optionally with a nested governance SUBDIR) carrying scaffolding + user files,
        # change them all after a baseline commit, and return the governance root + baseline ref.
        function New-CcrScaffoldRepo {
            param([string] $Name, [string] $SubDir = '', [string] $ConfigYml, [int] $BigFileBytes = 0)

            $top = Join-Path $TestDrive ($Name + '-' + [guid]::NewGuid().ToString('N').Substring(0, 8))
            $gov = if ($SubDir) { Join-Path $top $SubDir } else { $top }
            New-Item -ItemType Directory -Path $gov -Force | Out-Null
            Invoke-CcrGit $top @('init', '-q'); Invoke-CcrGit $top @('config', 'user.email', 't@e.c'); Invoke-CcrGit $top @('config', 'user.name', 't'); Invoke-CcrGit $top @('branch', '-m', 'main')

            $paths = @('.specrew/config-x.txt', '.github/workflow.yml', '.claude/agent.md',
                'scripts/internal/continuous-co-review/navigator.ps1', 'CLAUDE.md', 'AGENTS.md',
                'src/app.ps1', 'infra/main.bicep')
            foreach ($rel in $paths) {
                $full = Join-Path $gov $rel
                New-Item -ItemType Directory -Path (Split-Path -Parent $full) -Force | Out-Null
                Set-Content -LiteralPath $full -Value 'baseline' -Encoding UTF8
            }
            if ($ConfigYml) {
                $cfg = Join-Path $gov '.specrew/config.yml'
                Set-Content -LiteralPath $cfg -Value $ConfigYml -Encoding UTF8
            }
            Invoke-CcrGit $top @('add', '-A'); Invoke-CcrGit $top @('commit', '-q', '-m', 'baseline')
            $baseline = (& git -C $top rev-parse HEAD).Trim()

            # Mutate every file so each shows in the change-set.
            foreach ($rel in $paths) { Set-Content -LiteralPath (Join-Path $gov $rel) -Value 'changed-content-line' -Encoding UTF8 }
            if ($BigFileBytes -gt 0) {
                Set-Content -LiteralPath (Join-Path $gov 'src/app.ps1') -Value ('x' * $BigFileBytes) -Encoding UTF8
            }
            Invoke-CcrGit $top @('add', '-A'); Invoke-CcrGit $top @('commit', '-q', '-m', 'work')
            return [pscustomobject]@{ Top = $top; Gov = $gov; Baseline = $baseline }
        }
    }

    Context 'Get-ContinuousCoReviewDefaultExcludedPathPatterns' {
        It 'includes the principled Specrew/host-deployed scaffolding patterns' {
            $p = @(Get-ContinuousCoReviewDefaultExcludedPathPatterns -RepoRoot $script:RepoRoot)
            ($p -contains '.specrew/**') | Should -Be $true
            ($p -contains '.github/**') | Should -Be $true
            ($p -contains '.claude/**') | Should -Be $true
            ($p -contains 'scripts/internal/continuous-co-review/**') | Should -Be $true
            ($p -contains 'CLAUDE.md') | Should -Be $true
            ($p -contains 'AGENTS.md') | Should -Be $true
        }

        It 'co_review_excluded_paths_remove lets a project re-include its own product source (self-host)' {
            $repo = New-CcrScaffoldRepo -Name 'cfg-remove' -ConfigYml "co_review_excluded_paths_remove: `"scripts/internal/continuous-co-review/**`""
            $p = @(Get-ContinuousCoReviewDefaultExcludedPathPatterns -RepoRoot $repo.Gov)
            ($p -contains 'scripts/internal/continuous-co-review/**') | Should -Be $false
            ($p -contains '.specrew/**') | Should -Be $true
        }

        It 'co_review_excluded_paths_add extends the default list' {
            $repo = New-CcrScaffoldRepo -Name 'cfg-add' -ConfigYml "co_review_excluded_paths_add: `"vendor/**, generated/**`""
            $p = @(Get-ContinuousCoReviewDefaultExcludedPathPatterns -RepoRoot $repo.Gov)
            ($p -contains 'vendor/**') | Should -Be $true
            ($p -contains 'generated/**') | Should -Be $true
        }
    }

    Context 'checkpoint diff applies the default exclusion' {
        It 'excludes deployed scaffolding and keeps user code (own-repo root)' {
            $repo = New-CcrScaffoldRepo -Name 'own-root'
            $excl = @(Get-ContinuousCoReviewDefaultExcludedPathPatterns -RepoRoot $repo.Gov)
            $cs = Get-ContinuousCoReviewCheckpointDiff -RepoRoot $repo.Gov -BaselineRef $repo.Baseline -CheckpointId 'cp' -ExcludedPathPatterns $excl

            ($cs.changed_paths -contains 'src/app.ps1') | Should -Be $true
            ($cs.changed_paths -contains 'infra/main.bicep') | Should -Be $true
            ($cs.changed_paths -contains '.specrew/config-x.txt') | Should -Be $false
            ($cs.changed_paths -contains '.github/workflow.yml') | Should -Be $false
            ($cs.changed_paths -contains 'scripts/internal/continuous-co-review/navigator.ps1') | Should -Be $false
            ($cs.changed_paths -contains 'CLAUDE.md') | Should -Be $false
            ($cs.excluded_paths -contains '.specrew/config-x.txt') | Should -Be $true
        }

        It 'matches patterns project-relative on a NESTED governance root (subtree-strip)' {
            $repo = New-CcrScaffoldRepo -Name 'nested' -SubDir 'Tools/Project'
            $excl = @(Get-ContinuousCoReviewDefaultExcludedPathPatterns -RepoRoot $repo.Gov)
            $cs = Get-ContinuousCoReviewCheckpointDiff -RepoRoot $repo.Gov -BaselineRef $repo.Baseline -CheckpointId 'cp' -ExcludedPathPatterns $excl

            # changed_paths stay toplevel-relative (the 81b7070e frame), exclusion is tested project-relative.
            ($cs.changed_paths -contains 'Tools/Project/src/app.ps1') | Should -Be $true
            ($cs.changed_paths -contains 'Tools/Project/.specrew/config-x.txt') | Should -Be $false
            ($cs.changed_paths -contains 'Tools/Project/scripts/internal/continuous-co-review/navigator.ps1') | Should -Be $false
            ($cs.excluded_paths -contains 'Tools/Project/.github/workflow.yml') | Should -Be $true
        }
    }

    Context 'large-diff graceful cap' {
        It 'truncates diff_inline at the byte budget with an explicit marker and keeps the full file list' {
            $repo = New-CcrScaffoldRepo -Name 'cap' -ConfigYml 'co_review_diff_byte_budget: 2000' -BigFileBytes 20000
            $cs = Get-ContinuousCoReviewCheckpointDiff -RepoRoot $repo.Gov -BaselineRef $repo.Baseline -CheckpointId 'cp'

            $cs.diff_truncated | Should -Be $true
            $cs.diff_full_bytes | Should -BeGreaterThan 2000
            ([System.Text.Encoding]::UTF8.GetByteCount([string]$cs.diff_inline)) | Should -BeLessThan ($cs.diff_full_bytes)
            ([string]$cs.diff_inline) | Should -Match 'diff truncated'
            # The full changed-paths list survives truncation (partial coverage, not lost coverage).
            ($cs.changed_paths -contains 'src/app.ps1') | Should -Be $true
        }

        It 'leaves a diff under budget untouched (no marker)' {
            $repo = New-CcrScaffoldRepo -Name 'nocap'
            $cs = Get-ContinuousCoReviewCheckpointDiff -RepoRoot $repo.Gov -BaselineRef $repo.Baseline -CheckpointId 'cp'
            $cs.diff_truncated | Should -Be $false
            ([string]$cs.diff_inline) | Should -Not -Match 'diff truncated'
        }
    }

    Context 'adapter input-size guard' {
        It 'input-too-large is a registered infrastructure-failure category' {
            (Test-ReviewerInfrastructureFailureCategory -Category 'input-too-large') | Should -Be $true
        }

        It 'returns input-too-large WITHOUT invoking the host when the stdin payload exceeds the limit' {
            $request = [pscustomobject][ordered]@{
                schema_version   = '1.0'
                run_id           = 'run-guard'
                checkpoint_id    = 'cp-guard'
                created_at       = '2026-06-26T00:00:00Z'
                provider_request = [pscustomobject][ordered]@{ requested_host = 'claude'; requested_model = 'm'; authorization_ref = 'a'; timeout_seconds = 30; fallback_policy = 'none' }
            }
            $bundle = Join-Path $TestDrive 'big-bundle.json'
            Set-Content -LiteralPath $bundle -Value ('y' * 5000) -Encoding UTF8   # 5000 bytes > the 1000 limit below

            $script:invoked = $false
            $process = {
                param($Executable, [string[]] $ArgumentList, $StandardInputPath, $TimeoutSeconds, $WorkingDirectory)
                $script:invoked = $true
                return [pscustomobject][ordered]@{ exit_code = 0; stdout = '{}'; stderr = ''; timed_out = $false }
            }

            $result = Invoke-ContinuousCoReviewReviewerHostAdapterCommand -Request $request -RequestBundlePath $bundle `
                -AdapterId 'reviewer-host-adapter-claude-prompt' -Executable 'claude' -ArgumentList @('-p') `
                -SchemaRoot $script:SchemaRoot -InvokeProcess $process -StdinByteLimit 1000

            $result.kind | Should -Be 'infrastructure-failure'
            $result.infrastructure_failure.category | Should -Be 'input-too-large'
            $script:invoked | Should -Be $false
            # The failure must serialize to a CONTRACT-VALID artifact (the category enum in
            # infrastructure-failure.schema.json must stay in sync with the PowerShell category list).
            (Test-ReviewerContractObject -ContractName 'InfrastructureFailure' -SchemaRoot $script:SchemaRoot -InputObject $result.infrastructure_failure).Valid | Should -Be $true
        }

        It 'invokes the host normally when the stdin payload is under the limit' {
            $request = [pscustomobject][ordered]@{
                schema_version   = '1.0'
                run_id           = 'run-ok'
                checkpoint_id    = 'cp-ok'
                created_at       = '2026-06-26T00:00:00Z'
                provider_request = [pscustomobject][ordered]@{ requested_host = 'claude'; requested_model = 'm'; authorization_ref = 'a'; timeout_seconds = 30; fallback_policy = 'none' }
            }
            $bundle = Join-Path $TestDrive 'small-bundle.json'
            Set-Content -LiteralPath $bundle -Value '{}' -Encoding UTF8

            $script:invoked2 = $false
            $process = {
                param($Executable, [string[]] $ArgumentList, $StandardInputPath, $TimeoutSeconds, $WorkingDirectory)
                $script:invoked2 = $true
                return [pscustomobject][ordered]@{ exit_code = 1; stdout = ''; stderr = 'ignored'; timed_out = $false }
            }

            $null = Invoke-ContinuousCoReviewReviewerHostAdapterCommand -Request $request -RequestBundlePath $bundle `
                -AdapterId 'reviewer-host-adapter-claude-prompt' -Executable 'claude' -ArgumentList @('-p') `
                -SchemaRoot $script:SchemaRoot -InvokeProcess $process -StdinByteLimit 1000000
            $script:invoked2 | Should -Be $true
        }
    }

    Context 'navigator states the failure reason' {
        It 'Get-ContinuousCoReviewNavigatorFailureReason surfaces the sidecar category and message' {
            $runDir = Join-Path $TestDrive 'failrun'
            New-Item -ItemType Directory -Path $runDir -Force | Out-Null
            ([pscustomobject]@{ schema_version = '1.0'; status = 'infrastructure-failure'; category = 'input-too-large'; message = 'prompt exceeds host limit' } | ConvertTo-Json) |
                Set-Content -LiteralPath (Join-Path $runDir 'review-failure.json') -Encoding UTF8
            $reg = [pscustomobject]@{ run_dir = $runDir }
            $reason = Get-ContinuousCoReviewNavigatorFailureReason -RepoRoot $TestDrive -Registry $reg
            $reason | Should -Match 'input-too-large'
            $reason | Should -Match 'prompt exceeds host limit'
        }

        It 'returns null when no failure sidecar is present' {
            $runDir = Join-Path $TestDrive 'cleanrun'
            New-Item -ItemType Directory -Path $runDir -Force | Out-Null
            $reg = [pscustomobject]@{ run_dir = $runDir }
            (Get-ContinuousCoReviewNavigatorFailureReason -RepoRoot $TestDrive -Registry $reg) | Should -BeNullOrEmpty
        }
    }

    Context 'contract-root resolution is deploy-aware' {
        It 'resolves the DEPLOYED layout (.specrew/review/contracts) when the source layout is absent' {
            $root = Join-Path $TestDrive 'deployed-proj'
            New-Item -ItemType Directory -Path (Join-Path $root '.specrew/review/contracts') -Force | Out-Null
            $resolved = Get-ContinuousCoReviewContractRoot -RepoRoot $root
            $resolved | Should -Be (Resolve-Path -LiteralPath (Join-Path $root '.specrew/review/contracts')).Path
        }

        It 'prefers the SOURCE layout (specs/197) when both layouts exist' {
            $root = Join-Path $TestDrive 'source-proj'
            New-Item -ItemType Directory -Path (Join-Path $root 'specs/197-continuous-co-review/contracts') -Force | Out-Null
            New-Item -ItemType Directory -Path (Join-Path $root '.specrew/review/contracts') -Force | Out-Null
            $resolved = Get-ContinuousCoReviewContractRoot -RepoRoot $root
            $resolved | Should -Be (Resolve-Path -LiteralPath (Join-Path $root 'specs/197-continuous-co-review/contracts')).Path
        }

        It 'an explicit SchemaRoot always wins over the derived root' {
            $root = Join-Path $TestDrive 'explicit-proj'
            $explicit = Join-Path $root 'custom/contracts'
            New-Item -ItemType Directory -Path $explicit -Force | Out-Null
            $resolved = Get-ContinuousCoReviewContractRoot -SchemaRoot $explicit -RepoRoot $root
            $resolved | Should -Be (Resolve-Path -LiteralPath $explicit).Path
        }
    }
}
