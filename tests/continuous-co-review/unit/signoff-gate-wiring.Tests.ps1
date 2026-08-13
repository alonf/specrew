$ErrorActionPreference = 'Stop'

# Trace: T073, T074, FR-025, SC-019, SC-020.
# These prove the review-signoff hard-gate boundary-sync wiring SEAM (not the whole
# 1500-line sync):
#   - Get-ContinuousCoReviewGateEnforcementEnabled is TRUE by default. The old
#     co_review_gate_enforcement scalar no longer bypasses review-signoff.
#   - Invoke-ContinuousCoReviewSignoffGateIfEnabled is a no-op off the review-signoff boundary
#     and at review-signoff it REFUSES (throws) without fresh anchor-covered co-review
#     evidence (SC-019) and ALLOWS with it (SC-020).
# The gate decision logic itself is proven in review-signoff-evidence-gate.Tests.ps1; this file
# exercises only the flag-check + boundary-filter + conditional-Assert seam.
# Rules: specs/197-continuous-co-review/implementation-rules.yml
Describe 'Proposal 197 T073/T074 hard co-review signoff-gate wiring (FR-025/SC-019/SC-020)' {
    BeforeAll {
        $script:RepoRoot = (Resolve-Path "$PSScriptRoot/../../..").Path
        $env:SPECREW_MODULE_PATH = $script:RepoRoot
        Import-Module (Join-Path $script:RepoRoot 'Specrew.psd1') -Force
        # _load.ps1 brings in the gate DECISION + digest (the fixture computes the expected
        # tree-id with Get-ContinuousCoReviewReviewedStateDigest, so the test BODY needs it).
        . (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/_load.ps1')
        # The wiring functions under test.
        . (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/signoff-gate-wiring.ps1')
    

        # v5: helpers moved here so they are visible inside It blocks (Discovery/Run split).
        function Invoke-WiringGit { param($Root, [string[]] $GitArgs) Push-Location $Root; try { & git @GitArgs 2>&1 | Out-Null } finally { Pop-Location } }

        function Invoke-WiringGitCommit { param($Root, [string] $Message) Push-Location $Root; try { & git -c user.email='t@e.c' -c user.name='t' commit -q -m $Message 2>&1 | Out-Null } finally { Pop-Location } }

        function New-WiringFeatureRepo {
                # main (base = anchor) -> feature branch with one feature commit. Returns @{ repo; anchor }.
                param([string] $Name)
                $repo = Join-Path $TestDrive $Name
                New-Item -ItemType Directory -Path $repo -Force | Out-Null
                Invoke-WiringGit $repo @('init', '-q')
                Set-Content -LiteralPath (Join-Path $repo 'base.txt') -Value 'shipped' -Encoding UTF8
                Invoke-WiringGit $repo @('add', '-A'); Invoke-WiringGitCommit $repo 'base'
                Invoke-WiringGit $repo @('branch', '-M', 'main')
                $anchor = (& git -C $repo rev-parse HEAD).Trim()
                Invoke-WiringGit $repo @('checkout', '-q', '-b', 'feature')
                New-Item -ItemType Directory -Path (Join-Path $repo 'specs/001-wiring/iterations/001') -Force | Out-Null
                New-Item -ItemType Directory -Path (Join-Path $repo '.specrew') -Force | Out-Null
                Set-Content -LiteralPath (Join-Path $repo 'specs/001-wiring/spec.md') -Value '# Wiring feature' -Encoding UTF8
                ([ordered]@{
                    schema = 'v2'
                    feature_path = (Join-Path $repo 'specs/001-wiring')
                    session_state = [ordered]@{
                        active = $true
                        boundary_type = 'before-implement'
                        feature_ref = '001-wiring'
                        feature_path = (Join-Path $repo 'specs/001-wiring')
                        iteration_number = '001'
                    }
                } | ConvertTo-Json -Depth 8) | Set-Content -LiteralPath (Join-Path $repo '.specrew/start-context.json') -Encoding UTF8
                Set-Content -LiteralPath (Join-Path $repo 'feat.txt') -Value 'feature v0' -Encoding UTF8
                Invoke-WiringGit $repo @('add', '-A'); Invoke-WiringGitCommit $repo 'feat'
                return @{ repo = $repo; anchor = $anchor }
            }

        function New-WiringCampaignResult {
                param([string]$RunId, [string]$Digest)
                return [pscustomobject][ordered]@{
                    schema_version = '1.0'; campaign_id = 'cmp-001-wiring-i001'; run_id = $RunId
                    target_digest = $Digest; harness_id = 'fixture'; completion = 'complete'; verdict = 'pass'
                    runtime_outcome = 'completed'; termination_verified = $true; containment = 'verified'
                    currentness = 'current'; validation = 'valid'; can_approve_current = $true
                    failure_reason = $null; summary = 'campaign-authority wiring fixture'; findings = @()
                    started_at = '2026-08-12T00:00:00Z'; ended_at = '2026-08-12T00:01:00Z'; duration_ms = 60000
                }
            }

        function Add-WiringCleanCampaignResult {
                param([string]$Repo, [string]$RunId)
                $store = Join-Path $Repo '.specrew/review/authority'
                $digest = [string](Get-ContinuousCoReviewReviewedStateDigest -RepoRoot $Repo).tree_id
                Request-ReviewAuthorityClaim -StoreRoot $store -CampaignId 'cmp-001-wiring-i001' -RunId $RunId `
                    -TargetLineage 'lin-001-wiring' -ObservedAt '2026-08-12T00:00:00Z' | Out-Null
                Publish-ReviewRunResultFact -StoreRoot $store -CampaignId 'cmp-001-wiring-i001' -RunId $RunId `
                    -Fact (New-WiringCampaignResult -RunId $RunId -Digest $digest) | Out-Null
                Complete-ReviewAuthorityClaim -StoreRoot $store -CampaignId 'cmp-001-wiring-i001' -RunId $RunId `
                    -TargetLineage 'lin-001-wiring' -Disposition released -ObservedAt '2026-08-12T00:01:00Z' | Out-Null
            }

        function Set-WiringConfig {
                # Write a minimal .specrew/config.yml with (optionally) the enforcement scalar.
                param($Repo, [AllowNull()][string] $EnforcementLine)
                $configDir = Join-Path $Repo '.specrew'
                New-Item -ItemType Directory -Path $configDir -Force | Out-Null
                $lines = @('schema_version: "1.0"', 'session_mode: "single"')
                if (-not [string]::IsNullOrEmpty($EnforcementLine)) { $lines += $EnforcementLine }
                Set-Content -LiteralPath (Join-Path $configDir 'config.yml') -Value ($lines -join "`n") -Encoding UTF8
            }

}

    # Per-invocation git identity (the real repo's git config is never touched; TestDrive is a
    # throwaway temp tree). Identity is supplied via -c on each commit, not `git config`.
        
    
    
    
    Context 'Get-ContinuousCoReviewGateEnforcementEnabled (FR-025 hard gate, default ON)' {
        It 'is TRUE for co_review_gate_enforcement: true' {
            $f = New-WiringFeatureRepo 'enabled-true'
            Set-WiringConfig -Repo $f.repo -EnforcementLine 'co_review_gate_enforcement: "true"'
            Get-ContinuousCoReviewGateEnforcementEnabled -ProjectRoot $f.repo | Should -Be $true
        }

        It 'is TRUE for co_review_gate_enforcement: on' {
            $f = New-WiringFeatureRepo 'enabled-on'
            Set-WiringConfig -Repo $f.repo -EnforcementLine 'co_review_gate_enforcement: on'
            Get-ContinuousCoReviewGateEnforcementEnabled -ProjectRoot $f.repo | Should -Be $true
        }

        It 'is TRUE for co_review_gate_enforcement: ENABLED (case-insensitive)' {
            $f = New-WiringFeatureRepo 'enabled-enabled'
            Set-WiringConfig -Repo $f.repo -EnforcementLine 'co_review_gate_enforcement: "ENABLED"'
            Get-ContinuousCoReviewGateEnforcementEnabled -ProjectRoot $f.repo | Should -Be $true
        }

        # 145 F1 (MAJOR) regression coverage: standard YAML idioms must enable, not silently stay OFF.
        It 'is TRUE for an enabling value with a trailing inline comment (145 F1)' {
            $f = New-WiringFeatureRepo 'enabled-comment'
            Set-WiringConfig -Repo $f.repo -EnforcementLine 'co_review_gate_enforcement: true  # turn the gate on'
            Get-ContinuousCoReviewGateEnforcementEnabled -ProjectRoot $f.repo | Should -Be $true
        }

        It 'is TRUE for a SINGLE-quoted enabling value (145 F1)' {
            $f = New-WiringFeatureRepo 'enabled-singlequote'
            Set-WiringConfig -Repo $f.repo -EnforcementLine "co_review_gate_enforcement: 'true'"
            Get-ContinuousCoReviewGateEnforcementEnabled -ProjectRoot $f.repo | Should -Be $true
        }

        It 'is TRUE for a quoted enabling value WITH an inline comment (145 F1)' {
            $f = New-WiringFeatureRepo 'enabled-quoted-comment'
            Set-WiringConfig -Repo $f.repo -EnforcementLine 'co_review_gate_enforcement: "true" # on'
            Get-ContinuousCoReviewGateEnforcementEnabled -ProjectRoot $f.repo | Should -Be $true
        }

        It 'stays TRUE for co_review_gate_enforcement: false (config cannot bypass review-signoff)' {
            $f = New-WiringFeatureRepo 'disabled-false'
            Set-WiringConfig -Repo $f.repo -EnforcementLine 'co_review_gate_enforcement: "false"'
            Get-ContinuousCoReviewGateEnforcementEnabled -ProjectRoot $f.repo | Should -Be $true
        }

        It 'stays TRUE for false WITH an inline comment (config cannot bypass review-signoff)' {
            $f = New-WiringFeatureRepo 'disabled-false-comment'
            Set-WiringConfig -Repo $f.repo -EnforcementLine 'co_review_gate_enforcement: false  # still off'
            Get-ContinuousCoReviewGateEnforcementEnabled -ProjectRoot $f.repo | Should -Be $true
        }

        It 'is TRUE when the key is missing from an existing config' {
            $f = New-WiringFeatureRepo 'disabled-missingkey'
            Set-WiringConfig -Repo $f.repo -EnforcementLine $null
            Get-ContinuousCoReviewGateEnforcementEnabled -ProjectRoot $f.repo | Should -Be $true
        }

        It 'is TRUE when the config file is missing entirely' {
            $f = New-WiringFeatureRepo 'disabled-nofile'
            # No .specrew/config.yml on disk for this repo's worktree root.
            Test-Path -LiteralPath (Join-Path $f.repo '.specrew/config.yml') | Should -Be $false
            Get-ContinuousCoReviewGateEnforcementEnabled -ProjectRoot $f.repo | Should -Be $true
        }
    }

    Context 'Get-ContinuousCoReviewConfiguredTrunk (shared resolver level 1; no hardcoded main default)' {
        # The former Get-ContinuousCoReviewTrunkName (which defaulted to 'main') is retired: an unset
        # co_review_trunk now returns '' so the shared resolver AUTO-DETECTS (origin/HEAD -> upstream ->
        # conventional refs -> single pre-feature branch), never a silent 'main'.
        It 'returns empty (auto-detect) when the config file is missing' {
            $f = New-WiringFeatureRepo 'trunk-nofile'
            Get-ContinuousCoReviewConfiguredTrunk -RepoRoot $f.repo | Should -BeNullOrEmpty
        }
        It 'returns empty (auto-detect) when co_review_trunk is absent' {
            $f = New-WiringFeatureRepo 'trunk-missingkey'
            Set-WiringConfig -Repo $f.repo -EnforcementLine $null
            Get-ContinuousCoReviewConfiguredTrunk -RepoRoot $f.repo | Should -BeNullOrEmpty
        }
        It 'reads a configured non-main trunk (master)' {
            $f = New-WiringFeatureRepo 'trunk-master'
            Set-WiringConfig -Repo $f.repo -EnforcementLine 'co_review_trunk: "master"'
            Get-ContinuousCoReviewConfiguredTrunk -RepoRoot $f.repo | Should -Be 'master'
        }
        It 'reads a single-quoted trunk WITH an inline comment' {
            $f = New-WiringFeatureRepo 'trunk-develop'
            Set-WiringConfig -Repo $f.repo -EnforcementLine "co_review_trunk: 'develop'  # our default branch"
            Get-ContinuousCoReviewConfiguredTrunk -RepoRoot $f.repo | Should -Be 'develop'
        }
    }

    Context 'Invoke-ContinuousCoReviewSignoffGateIfEnabled (the conditional-Assert seam)' {
        It '(a) review-signoff + NO passing co-review run -> THROWS and persists the block [SC-019]' {
            $f = New-WiringFeatureRepo 'on-noevidence'
            $threw = $false; $msg = $null
            try {
                Invoke-ContinuousCoReviewSignoffGateIfEnabled -ProjectRoot $f.repo -BoundaryType 'review-signoff'
            } catch { $threw = $true; $msg = $_.Exception.Message }
            $threw | Should -Be $true
            $msg | Should -Match 'review-signoff refused'
            $latest = Get-Content -LiteralPath (Join-Path $f.repo '.specrew/review/signoff-gate/latest.json') -Raw | ConvertFrom-Json
            $latest.decision.decision | Should -Be 'block'
            $latest.decision.reason | Should -Be 'no-authoritative-campaign-result'
        }

        It '(b) review-signoff + a fresh PASSING run matching the current tree -> does NOT throw [SC-020]' {
            $f = New-WiringFeatureRepo 'on-fresh'
            Set-WiringConfig -Repo $f.repo -EnforcementLine $null
            Add-WiringCleanCampaignResult -Repo $f.repo -RunId 'run-fresh'
            { Invoke-ContinuousCoReviewSignoffGateIfEnabled -ProjectRoot $f.repo -BoundaryType 'review-signoff' } | Should -Not -Throw
            $latest = Get-Content -LiteralPath (Join-Path $f.repo '.specrew/review/signoff-gate/latest.json') -Raw | ConvertFrom-Json
            $latest.decision.decision | Should -Be 'allow'
            $latest.decision.reason | Should -Be 'complete-current-clean-result'
        }

        It '(b2) the allow path returns NOTHING (so it cannot corrupt the boundary-sync result pipeline)' {
            $f = New-WiringFeatureRepo 'on-fresh-silent'
            Set-WiringConfig -Repo $f.repo -EnforcementLine $null
            Add-WiringCleanCampaignResult -Repo $f.repo -RunId 'run-fresh-silent'
            $out = Invoke-ContinuousCoReviewSignoffGateIfEnabled -ProjectRoot $f.repo -BoundaryType 'review-signoff'
            $out | Should -BeNullOrEmpty
        }

        It '(b3) a human-authorized override is reachable through the wired gate and persisted' {
            $f = New-WiringFeatureRepo 'on-human-override'
            Set-WiringConfig -Repo $f.repo -EnforcementLine $null
            $override = [pscustomobject]@{
                authorized_by = 'human-tester'
                rationale = 'review provider is unavailable; defer independent review with explicit ownership'
            }

            $out = Invoke-ContinuousCoReviewSignoffGateIfEnabled -ProjectRoot $f.repo -BoundaryType 'review-signoff' -OverrideAuthorization $override

            $out | Should -BeNullOrEmpty
            $latest = Get-Content -LiteralPath (Join-Path $f.repo '.specrew/review/signoff-gate/latest.json') -Raw | ConvertFrom-Json
            $latest.decision.decision | Should -Be 'allow'
            $latest.decision.reason | Should -Be 'human-authorized-partial-override'
            $latest.decision.override.authorized_by | Should -Be 'human-tester'
            $latest.decision.override.rationale | Should -Match 'provider is unavailable'
        }

        It '(b4) a malformed wired override remains fail-closed and is persisted as a block' {
            $f = New-WiringFeatureRepo 'on-malformed-override'
            Set-WiringConfig -Repo $f.repo -EnforcementLine $null
            $override = [pscustomobject]@{ authorized_by = 'human-tester' }

            { Invoke-ContinuousCoReviewSignoffGateIfEnabled -ProjectRoot $f.repo -BoundaryType 'review-signoff' -OverrideAuthorization $override } | Should -Throw

            $latest = Get-Content -LiteralPath (Join-Path $f.repo '.specrew/review/signoff-gate/latest.json') -Raw | ConvertFrom-Json
            $latest.decision.decision | Should -Be 'block'
            $latest.decision.reason | Should -Be 'no-authoritative-campaign-result'
            $latest.decision.override | Should -BeNullOrEmpty
        }

        It '(c) explicit false config still blocks without co-review evidence' {
            $f = New-WiringFeatureRepo 'false-still-blocks'
            Set-WiringConfig -Repo $f.repo -EnforcementLine 'co_review_gate_enforcement: "false"'
            { Invoke-ContinuousCoReviewSignoffGateIfEnabled -ProjectRoot $f.repo -BoundaryType 'review-signoff' } | Should -Throw
        }

        It '(c2) flag-key absent (default ON) blocks with NO co-review evidence' {
            $f = New-WiringFeatureRepo 'default-on-blocks'
            Set-WiringConfig -Repo $f.repo -EnforcementLine $null
            { Invoke-ContinuousCoReviewSignoffGateIfEnabled -ProjectRoot $f.repo -BoundaryType 'review-signoff' } | Should -Throw
        }

        It '(d) BoundaryType = plan + flag ON -> no-op (the gate only governs review-signoff)' {
            $f = New-WiringFeatureRepo 'on-plan-noop'
            Set-WiringConfig -Repo $f.repo -EnforcementLine 'co_review_gate_enforcement: "true"'
            # No evidence at all; a plan boundary must not fire the gate even with the flag ON.
            { Invoke-ContinuousCoReviewSignoffGateIfEnabled -ProjectRoot $f.repo -BoundaryType 'plan' } | Should -Not -Throw
        }
    }
}
