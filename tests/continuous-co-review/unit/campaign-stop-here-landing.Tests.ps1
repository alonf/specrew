$ErrorActionPreference = 'Stop'

# Trace: T002 / FR-005 / SC-004.
#
# T067's endgame is the reproduction this pins. A bare "stop here" ruling WEDGED against the
# signoff gate: accepted-residuals-on-an-unreviewed-tree was inexpressible, so the human was left
# adjudicating between two governors by hand. The fix is composition - one action chains the final
# frozen-tree verification, the identity-bound residual acceptance, and the gate sync, so the human
# never discovers the collision themselves.
#
# The ORDER is the safety property, not a convenience: acceptance may never be recorded against a
# tree that has not just been verified, and the gate may never be synced against an acceptance that
# was not recorded. Each step is an injectable port (the codebase's existing style) so the
# composition can be driven without standing up a live reviewer.
Describe 'Composed stop-here landing (T002)' {
    BeforeAll {
        $script:RepoRoot = (Resolve-Path "$PSScriptRoot/../../..").Path
        . (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/_load.ps1')
        . (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/review-campaign-orchestrator.ps1')

        function script:New-LandingPorts {
            param([bool]$VerifyOk = $true, [bool]$AcceptOk = $true, [bool]$GateOk = $true, [Parameter(Mandatory)]$Log)
            return @{
                VerifyPort   = { param($ctx) $Log.Add('verify') | Out-Null; if ($VerifyOk) { [pscustomobject]@{ ok = $true; reason = 'verification-passed' } } else { [pscustomobject]@{ ok = $false; reason = 'verification-command-failed:slice' } } }.GetNewClosure()
                AcceptPort   = { param($ctx) $Log.Add('accept') | Out-Null; if ($AcceptOk) { [pscustomobject]@{ ok = $true; reason = 'residuals-accepted' } } else { [pscustomobject]@{ ok = $false; reason = 'review-human-disposition-result-missing' } } }.GetNewClosure()
                GateSyncPort = { param($ctx) $Log.Add('gate') | Out-Null; if ($GateOk) { [pscustomobject]@{ ok = $true; reason = 'signoff-gate-allow' } } else { [pscustomobject]@{ ok = $false; reason = 'signoff-gate-blocked' } } }.GetNewClosure()
            }
        }

        function script:Invoke-Landing {
            param([hashtable]$Ports)
            return Invoke-ReviewCampaignStopHereLanding -ProjectRoot $script:RepoRoot -StoreRoot 'unused-in-port-mode' `
                -CampaignId 'cmp-199-x-i001' -RunId 'run-t002-a' -AuthorizedBy 'maintainer' `
                -AuthorizationRef 'test-ref' -Rationale 'accepted as recorded residuals' @Ports
        }
    }

    It 'SC-004: one action chains verification, acceptance, and gate sync IN THAT ORDER' {
        $log = [Collections.Generic.List[string]]::new()
        $landing = script:Invoke-Landing -Ports (script:New-LandingPorts -Log $log)

        $landing.landed | Should -BeTrue
        @($log) | Should -Be @('verify', 'accept', 'gate')
        @($landing.steps).Count | Should -Be 3
    }

    It 'THE T067 WEDGE: a failed verification stops the chain - residuals are never accepted on an unverified tree' {
        $log = [Collections.Generic.List[string]]::new()
        $landing = script:Invoke-Landing -Ports (script:New-LandingPorts -VerifyOk $false -Log $log)

        $landing.landed | Should -BeFalse
        @($log) | Should -Be @('verify')
        $log | Should -Not -Contain 'accept'
        $log | Should -Not -Contain 'gate'
        $landing.failed_step | Should -Be 'verification'
    }

    It 'a failed acceptance stops the chain before the gate is touched' {
        $log = [Collections.Generic.List[string]]::new()
        $landing = script:Invoke-Landing -Ports (script:New-LandingPorts -AcceptOk $false -Log $log)

        $landing.landed | Should -BeFalse
        @($log) | Should -Be @('verify', 'accept')
        $landing.failed_step | Should -Be 'residual-acceptance'
    }

    It 'a blocked gate is reported as the landing failing, never as a silent partial success' {
        $log = [Collections.Generic.List[string]]::new()
        $landing = script:Invoke-Landing -Ports (script:New-LandingPorts -GateOk $false -Log $log)

        $landing.landed | Should -BeFalse
        $landing.failed_step | Should -Be 'gate-sync'
        @($log) | Should -Be @('verify', 'accept', 'gate')
    }

    It 'FR-005: a failure names the next step, so the human never has to discover the collision' {
        $log = [Collections.Generic.List[string]]::new()
        $landing = script:Invoke-Landing -Ports (script:New-LandingPorts -VerifyOk $false -Log $log)

        $landing.message | Should -Not -BeNullOrEmpty
        $landing.message | Should -Match 'verification-command-failed:slice'
        $landing.message | Should -Match 'What to do next'
    }

    It 'the landing message is in the consumer register on success' {
        $log = [Collections.Generic.List[string]]::new()
        $landing = script:Invoke-Landing -Ports (script:New-LandingPorts -Log $log)

        $landing.message | Should -Match 'sign(ed)? off|sign-off'
        foreach ($banned in @('crossing', 'mint', 'digest', 'boundary sync', 'verdict capture', 'ratchet', 'terminalize')) {
            $landing.message | Should -Not -Match ([regex]::Escape($banned))
        }
    }
}
