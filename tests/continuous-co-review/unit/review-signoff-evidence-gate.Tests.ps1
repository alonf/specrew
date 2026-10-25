$ErrorActionPreference = 'Stop'

# Trace: T067, FR-025, FR-027, NFR-001, TG-013.
# These prove the campaign-authority signoff decision: only a complete, valid result for the
# exact active campaign and current reviewed-state digest authorizes signoff. The retired inline
# tree-id/anchor-chain fixtures used to make every campaign-mode case fail closed before reaching
# its assertion; this suite now writes the campaign facts the production gate consumes.
# Rules: specs/197-continuous-co-review/implementation-rules.yml
Describe 'Proposal 197 T067 re-architected co-review signoff gate (FR-025)' {
    BeforeAll {
        $script:RepoRoot = (Resolve-Path "$PSScriptRoot/../../..").Path
        $env:SPECREW_MODULE_PATH = $script:RepoRoot
        Import-Module (Join-Path $script:RepoRoot 'Specrew.psd1') -Force
        . (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/_load.ps1')
    

        # v5: helpers moved here so they are visible inside It blocks (Discovery/Run split).
        function Invoke-GateGit { param($Root, [string[]] $GitArgs) Push-Location $Root; try { & git @GitArgs 2>&1 | Out-Null } finally { Pop-Location } }

        function New-FeatureRepo {
                # main (base) -> feature branch with one feature commit. Returns @{ repo; anchor }.
                param([string] $Name)
                $repo = Join-Path $TestDrive $Name
                New-Item -ItemType Directory -Path $repo -Force | Out-Null
                Invoke-GateGit $repo @('init', '-q'); Invoke-GateGit $repo @('config', 'user.email', 't@e.c'); Invoke-GateGit $repo @('config', 'user.name', 't')
                Set-Content -LiteralPath (Join-Path $repo 'base.txt') -Value 'shipped' -Encoding UTF8
                Invoke-GateGit $repo @('add', '-A'); Invoke-GateGit $repo @('commit', '-q', '-m', 'base')
                Invoke-GateGit $repo @('branch', '-M', 'main')
                $anchor = (& git -C $repo rev-parse HEAD).Trim()
                Invoke-GateGit $repo @('checkout', '-q', '-b', 'feature')
                New-Item -ItemType Directory -Path (Join-Path $repo 'specs/001-gate/iterations/001') -Force | Out-Null
                New-Item -ItemType Directory -Path (Join-Path $repo '.specrew') -Force | Out-Null
                Set-Content -LiteralPath (Join-Path $repo 'specs/001-gate/spec.md') -Value '# Gate feature' -Encoding UTF8
                ([ordered]@{
                    schema = 'v2'
                    feature_path = (Join-Path $repo 'specs/001-gate')
                    session_state = [ordered]@{
                        active = $true
                        boundary_type = 'before-implement'
                        feature_ref = '001-gate'
                        feature_path = (Join-Path $repo 'specs/001-gate')
                        iteration_number = '001'
                    }
                } | ConvertTo-Json -Depth 8) | Set-Content -LiteralPath (Join-Path $repo '.specrew/start-context.json') -Encoding UTF8
                Set-Content -LiteralPath (Join-Path $repo 'feat.txt') -Value 'feature v0' -Encoding UTF8
                Invoke-GateGit $repo @('add', '-A'); Invoke-GateGit $repo @('commit', '-q', '-m', 'feat')
                return @{ repo = $repo; anchor = $anchor }
            }

        function New-GateCampaignResult {
                param([string]$RunId, [string]$Digest)
                return [pscustomobject][ordered]@{
                    schema_version = '1.0'; campaign_id = 'cmp-001-gate-i001'; run_id = $RunId
                    target_digest = $Digest; harness_id = 'fixture'; completion = 'complete'; verdict = 'pass'
                    runtime_outcome = 'completed'; termination_verified = $true; containment = 'verified'
                    currentness = 'current'; validation = 'valid'; can_approve_current = $true
                    failure_reason = $null; summary = 'campaign-authority gate fixture'; findings = @()
                    started_at = '2026-08-13T00:00:00Z'; ended_at = '2026-08-13T00:01:00Z'; duration_ms = 60000
                }
            }

        function Add-CleanCampaignResult {
                param([string]$Repo, [string]$RunId, [AllowNull()][string]$Digest)
                $store = Join-Path $Repo '.specrew/review/authority'
                if ([string]::IsNullOrWhiteSpace($Digest)) {
                    $Digest = [string](Get-ContinuousCoReviewReviewedStateDigest -RepoRoot $Repo).tree_id
                }
                Request-ReviewAuthorityClaim -StoreRoot $store -CampaignId 'cmp-001-gate-i001' -RunId $RunId `
                    -TargetLineage 'lin-001-gate' -ObservedAt '2026-08-13T00:00:00Z' | Out-Null
                Publish-ReviewRunResultFact -StoreRoot $store -CampaignId 'cmp-001-gate-i001' -RunId $RunId `
                    -Fact (New-GateCampaignResult -RunId $RunId -Digest $Digest) | Out-Null
                Complete-ReviewAuthorityClaim -StoreRoot $store -CampaignId 'cmp-001-gate-i001' -RunId $RunId `
                    -TargetLineage 'lin-001-gate' -Disposition released -ObservedAt '2026-08-13T00:01:00Z' | Out-Null
            }

        function Add-CampaignClaimWithoutResult {
                param([string]$Repo, [string]$RunId)
                Request-ReviewAuthorityClaim -StoreRoot (Join-Path $Repo '.specrew/review/authority') `
                    -CampaignId 'cmp-001-gate-i001' -RunId $RunId -TargetLineage 'lin-001-gate' `
                    -ObservedAt '2026-08-13T00:02:00Z' | Out-Null
            }
}

    

    

    

    It 'blocks when there is no co-review evidence' {
        $f = New-FeatureRepo 'no-ev'
        (Get-ContinuousCoReviewSignoffGateDecision -RepoRoot $f.repo -TrunkName 'main').reason | Should -Be 'no-authoritative-campaign-result'
    }

    It 'ALLOWS when the active campaign has a complete valid result for the current digest' {
        $f = New-FeatureRepo 'allow'
        Add-CleanCampaignResult -Repo $f.repo -RunId 'run-one'
        $d = Get-ContinuousCoReviewSignoffGateDecision -RepoRoot $f.repo -TrunkName 'main'
        $d.decision | Should -Be 'allow'
        $d.reason | Should -Be 'complete-current-clean-result'
    }

    It 'does not stale on untracked ignored output outside the repository product-source boundary' {
        $f = New-FeatureRepo 'hole-a'
        Set-Content -LiteralPath (Join-Path $f.repo '.gitignore') -Value "gen/`n" -Encoding UTF8
        New-Item -ItemType Directory -Path (Join-Path $f.repo 'gen') -Force | Out-Null
        Set-Content -LiteralPath (Join-Path $f.repo 'gen/logic.py') -Value 'def s(): pass' -Encoding UTF8
        Invoke-GateGit $f.repo @('add', '.gitignore'); Invoke-GateGit $f.repo @('commit', '-q', '-m', 'ignore')
        Add-CleanCampaignResult -Repo $f.repo -RunId 'run-one'
        (Get-ContinuousCoReviewSignoffGateDecision -RepoRoot $f.repo -TrunkName 'main').decision | Should -Be 'allow'   # baseline state passes
        Set-Content -LiteralPath (Join-Path $f.repo 'gen/logic.py') -Value 'def s(): evil()' -Encoding UTF8           # gitignored drift
        (Get-ContinuousCoReviewSignoffGateDecision -RepoRoot $f.repo -TrunkName 'main').reason | Should -Be 'complete-current-clean-result'
    }

    It 'BLOCKS a result recorded for an earlier digest instead of promoting partial coverage' {
        $f = New-FeatureRepo 'hole-b'
        $earlierDigest = [string](Get-ContinuousCoReviewReviewedStateDigest -RepoRoot $f.repo).tree_id
        Set-Content -LiteralPath (Join-Path $f.repo 'feat.txt') -Value 'feature v1' -Encoding UTF8
        Invoke-GateGit $f.repo @('add', '-A'); Invoke-GateGit $f.repo @('commit', '-q', '-m', 'feat2')
        Add-CleanCampaignResult -Repo $f.repo -RunId 'run-one' -Digest $earlierDigest
        $d = Get-ContinuousCoReviewSignoffGateDecision -RepoRoot $f.repo -TrunkName 'main'
        $d.decision | Should -Be 'block'
        $d.reason | Should -Be 'latest-result-not-current'
    }

    It 'ALLOWS the newest complete current result when an active campaign has multiple released runs' {
        $f = New-FeatureRepo 'multi-result'
        Add-CleanCampaignResult -Repo $f.repo -RunId 'run-one'
        Add-CleanCampaignResult -Repo $f.repo -RunId 'run-two'
        $d = Get-ContinuousCoReviewSignoffGateDecision -RepoRoot $f.repo -TrunkName 'main'
        $d.decision | Should -Be 'allow'
        $d.reason | Should -Be 'complete-current-clean-result'
        $d.matched_run_id | Should -Be 'run-two'
    }

    It 'BLOCKS when the latest campaign claim has no terminal result' {
        $f = New-FeatureRepo 'latest-gap'
        Add-CleanCampaignResult -Repo $f.repo -RunId 'run-one'
        Add-CampaignClaimWithoutResult -Repo $f.repo -RunId 'run-two'
        (Get-ContinuousCoReviewSignoffGateDecision -RepoRoot $f.repo -TrunkName 'main').reason | Should -Be 'active-claim-run-state-missing'
    }

    It 'blocks stale when the tracked tree drifts after the pass' {
        $f = New-FeatureRepo 'stale'
        Add-CleanCampaignResult -Repo $f.repo -RunId 'run-one'
        Set-Content -LiteralPath (Join-Path $f.repo 'feat.txt') -Value 'drifted' -Encoding UTF8
        (Get-ContinuousCoReviewSignoffGateDecision -RepoRoot $f.repo -TrunkName 'main').reason | Should -Be 'latest-result-not-current'
    }

    It 'does not consult the retired trunk-anchor model under campaign authority' {
        $f = New-FeatureRepo 'no-trunk'
        Add-CleanCampaignResult -Repo $f.repo -RunId 'run-one'
        $d = Get-ContinuousCoReviewSignoffGateDecision -RepoRoot $f.repo -TrunkName 'nonexistent-trunk'
        $d.decision | Should -Be 'allow'
        $d.reason | Should -Be 'complete-current-clean-result'
    }

    It 'allows under a well-formed human-authorized recorded override (and records it)' {
        $f = New-FeatureRepo 'override'
        $override = [pscustomobject]@{ authorized_by = 'alon'; rationale = 'documented partial coverage for a vendored tree' }
        $d = Get-ContinuousCoReviewSignoffGateDecision -RepoRoot $f.repo -TrunkName 'main' -OverrideAuthorization $override
        $d.decision | Should -Be 'allow'
        $d.reason | Should -Be 'human-authorized-partial-override'
        $d.override.authorized_by | Should -Be 'alon'
    }

    It 'ignores a malformed override (no rationale) and blocks normally' {
        $f = New-FeatureRepo 'bad-override'
        $override = [pscustomobject]@{ authorized_by = 'alon' }   # no rationale
        (Get-ContinuousCoReviewSignoffGateDecision -RepoRoot $f.repo -TrunkName 'main' -OverrideAuthorization $override).reason | Should -Be 'no-authoritative-campaign-result'
    }

    It 'Assert throws on a block' {
        $f = New-FeatureRepo 'assert'
        $threw = $false
        try { Assert-ContinuousCoReviewSignoffGate -RepoRoot $f.repo -TrunkName 'main' | Out-Null } catch { $threw = $true }
        $threw | Should -Be $true
    }
}
