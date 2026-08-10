$ErrorActionPreference = 'Stop'

# Trace: T009 / FR-018 / ledger F7.
#
# T067 measured the failure this pins: a codex review of a planning-scale digest timed out
# SILENTLY at the shipped default while the same review produced real findings inside a 900 s
# window. The catalog row is the one seam (data, not a host-name branch in policy).
#
# The timeout MESSAGE is the second half of FR-018: a consumer who loses a review to the budget
# must be told which setting to change. The message therefore names `co_review_timeout_seconds`
# in the consumer shape (what happened -> what it means for your project -> the exact next step).
# The campaign route's message is pinned from a REAL recorded terminal result (the run-
# t003-activation-slice-1 result.json, with its runtime_outcome flipped to timed-out), so the
# fixture is instance-pinned rather than hand-invented.
Describe 'Codex review-window default and timeout message (T009 / FR-018)' {
    BeforeAll {
        $script:RepoRoot = (Resolve-Path "$PSScriptRoot/../../..").Path
        . (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/_load.ps1')

        # Instance-pinned: the shape of a real terminal result recorded by this feature's own run.
        function script:New-TimedOutResult {
            param([string]$CampaignId = 'cmp-199-beta3-stabilization-i001', [string]$RunId = 'run-t003-activation-slice-1')
            return [pscustomobject][ordered]@{
                schema_version      = '1.0'
                campaign_id         = $CampaignId
                run_id              = $RunId
                target_digest       = 'ac303964a3e632114482fc4c16577751c7351a5d'
                harness_id          = 'codex-cli-file-primary'
                completion          = 'none'
                verdict             = 'failed'
                runtime_outcome     = 'timed-out'
                termination_verified = $true
                containment         = 'unknown'
                currentness         = 'unknown'
                validation          = 'not-produced'
                can_approve_current = $false
                failure_reason      = 'review-budget-exhausted'
                summary             = 'timed-out'
                findings            = @()
                started_at          = '2026-08-10T07:26:58.2335465+00:00'
                ended_at            = '2026-08-10T07:29:12.4008647+00:00'
                duration_ms         = 134156
            }
        }
    }

    It 'the codex catalog row carries a 900-second default window' {
        (Get-ContinuousCoReviewHostDefaultTimeoutSeconds -HostName 'codex') | Should -Be 900
    }

    It 'no other host default is changed by this slice' {
        (Get-ContinuousCoReviewHostDefaultTimeoutSeconds -HostName 'claude') | Should -Be 600
        (Get-ContinuousCoReviewHostDefaultTimeoutSeconds -HostName 'copilot') | Should -Be 300
        (Get-ContinuousCoReviewHostDefaultTimeoutSeconds -HostName 'antigravity') | Should -Be 900
    }

    It 'the resolution chain returns 900 for codex when no project config overrides it' {
        $repo = Join-Path ([IO.Path]::GetTempPath()) ('ccr-window-' + [Guid]::NewGuid().ToString('N'))
        New-Item -ItemType Directory -Path $repo -Force | Out-Null
        try {
            (Get-ContinuousCoReviewNavigatorTimeoutSeconds -RepoRoot $repo -HostName 'codex') | Should -Be 900
        }
        finally { Remove-Item -LiteralPath $repo -Recurse -Force -ErrorAction SilentlyContinue }
    }

    It 'an explicit project config still wins over the catalog default' {
        $repo = Join-Path ([IO.Path]::GetTempPath()) ('ccr-window-' + [Guid]::NewGuid().ToString('N'))
        New-Item -ItemType Directory -Path (Join-Path $repo '.specrew') -Force | Out-Null
        [IO.File]::WriteAllText((Join-Path $repo '.specrew/config.yml'), "co_review_timeout_seconds: 1200`n")
        try {
            (Get-ContinuousCoReviewNavigatorTimeoutSeconds -RepoRoot $repo -HostName 'codex') | Should -Be 1200
        }
        finally { Remove-Item -LiteralPath $repo -Recurse -Force -ErrorAction SilentlyContinue }
    }

    # Round-1 finding (major): the consumer-shaped text reached the signoff-gate route but NOT the
    # public `specrew review --live` branch a consumer actually runs, and --help advertised a
    # 120-second default that no code path uses.
    It 'the PUBLIC campaign branch names the setting on a timed-out result' {
        $cli = Get-Content -LiteralPath (Join-Path $script:RepoRoot 'scripts/specrew-review.ps1') -Raw
        $campaignRender = [regex]::Match($cli, "(?ms)SPECREW CAMPAIGN REVIEW.*?Authority store").Value

        $campaignRender | Should -Not -BeNullOrEmpty
        $campaignRender | Should -Match "runtime_outcome.*timed-out"
        $campaignRender | Should -Match 'co_review_timeout_seconds'
        $campaignRender | Should -Match '--timeout-seconds'
    }

    It 'the --help text states the real default resolution, not a fictional 120 seconds' {
        $cli = Get-Content -LiteralPath (Join-Path $script:RepoRoot 'scripts/specrew-review.ps1') -Raw
        $helpLine = [regex]::Match($cli, '(?m)^\s*--timeout-seconds.*(?:\r?\n\s{20,}.*)*').Value

        $helpLine | Should -Not -BeNullOrEmpty
        $helpLine | Should -Not -Match 'default:\s*120'
        $helpLine | Should -Match 'co_review_timeout_seconds'
    }

    It 'the timeout message names the setting a consumer must change' {
        $result = script:New-TimedOutResult
        $decision = Resolve-ReviewCampaignVerdictPacketDecision -CampaignId $result.campaign_id `
            -CurrentDigest $result.target_digest -OrderedRunIds @($result.run_id) -Results @($result)

        $decision.route | Should -Be 'review-timeout'
        $decision.message | Should -Match 'co_review_timeout_seconds'
    }
}
