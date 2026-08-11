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
                # The gating precondition added 2026-08-11 reads the TERMINAL RESULT from the store and
                # fails closed when it cannot. This suite runs in PORT MODE against
                # `-StoreRoot 'unused-in-port-mode'` - there is deliberately no store - so it is
                # satisfied explicitly here. That is not a way around the guard: these tests are about
                # the CHAIN COMPOSITION (order, stop-on-failure, message shape), and the precondition
                # has its own dedicated tests in campaign-pause-wiring.Tests.ps1 which exercise the REAL
                # default against real published facts, including the refusal and the fail-closed path.
                # Injecting it here keeps each suite testing one thing instead of two badly.
                GatingPrecondition = { param($ctx) [pscustomobject]@{ ok = $true; reason = 'precondition-satisfied-by-fixture' } }
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

        # FOUR steps since 2026-08-11: a gating precondition now runs BEFORE verification, so a round
        # whose result holds blocking or major findings costs nothing at all - no frozen-tree check, no
        # acceptance recorded, no gate touched. The three sanctioned steps and their order are unchanged
        # and still asserted above; this only records that the chain gained a refusal in front of them.
        @($landing.steps).Count | Should -Be 4
        [string]@($landing.steps)[0].name | Should -Be 'gating-precondition' -Because 'a refusal that runs after verification has already touched the tree it was meant to protect'
        @(@($landing.steps) | ForEach-Object { [string]$_.name }) | Should -Be @('gating-precondition', 'verification', 'residual-acceptance', 'gate-sync')
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

    # T007 / FR-013. The landing message tells the human to "fix what the message above names" - so the
    # message has to name something. A sealed verification failure reaches this prose as
    # `verification-command-failed:build:diagnostics-require-command-scoped-disclosure`, which names a
    # machine token and a locked door. The derived diagnosis is composed from facts the engine already
    # owns (never command output), so it can ride here without touching the seal.
    It 'FR-013: a failed step''s DIAGNOSIS reaches the human, not just its machine reason' {
        $log = [Collections.Generic.List[string]]::new()
        $ports = script:New-LandingPorts -Log $log
        $ports.VerifyPort = {
            param($ctx)
            $Log.Add('verify') | Out-Null
            [pscustomobject]@{
                ok = $false
                reason = 'verification-command-failed:build:diagnostics-require-command-scoped-disclosure'
                diagnosis = "  build: exit code 1, after 3.5s - it finished on its own.`n    this command could only see these environment variables: PATH, TMPDIR"
            }
        }.GetNewClosure()

        $landing = script:Invoke-Landing -Ports $ports

        $landing.landed | Should -BeFalse
        $landing.message | Should -Match 'exit code 1' -Because 'the human is told to fix what the message names, so it must name something'
        $landing.message | Should -Match 'PATH, TMPDIR'
        $landing.message | Should -Match 'diagnostics-require-command-scoped-disclosure' -Because 'the disclosure pointer is preserved, never replaced - the seal is untouched'
    }

    # Maintainer ruling 2026-08-10, on the starter plan shadowing auto-detection. The direction stays
    # (never leave a project unable to verify), but the degradation must be VISIBLE: a project whose
    # reviews check only governance while its tests never run is being told "verification passed".
    #
    # MEASURED first, as instructed: a completed verification did NOT name its commands to a consumer -
    # the success path reported a COUNT, in reviewer-facing text only. So this is owed, and it is the
    # honest-reporting answer rather than shadow-detection.
    It 'the success message NAMES what the final check actually ran' {
        $log = [Collections.Generic.List[string]]::new()
        $ports = script:New-LandingPorts -Log $log
        $ports.VerifyPort = {
            param($ctx)
            $Log.Add('verify') | Out-Null
            [pscustomobject]@{
                ok = $true; reason = 'verification-evidence-ready'
                command_labels = @('Specrew governance validation')
            }
        }.GetNewClosure()

        $landing = script:Invoke-Landing -Ports $ports

        $landing.landed | Should -BeTrue
        $landing.message | Should -Match 'Specrew governance validation' -Because 'a consumer whose tests never run must be able to SEE that only governance was checked'
        $landing.message | Should -Match '1 command'
    }

    It 'the success message pluralises honestly and lists every command' {
        $log = [Collections.Generic.List[string]]::new()
        $ports = script:New-LandingPorts -Log $log
        $ports.VerifyPort = {
            param($ctx)
            $Log.Add('verify') | Out-Null
            [pscustomobject]@{
                ok = $true; reason = 'verification-evidence-ready'
                command_labels = @('Specrew governance validation', 'Build and test')
            }
        }.GetNewClosure()

        $landing = script:Invoke-Landing -Ports $ports
        $landing.message | Should -Match '2 commands'
        $landing.message | Should -Match 'Build and test'
    }

    It 'a verify port that reports no command labels still renders a clean success message' {
        # Every other port in the codebase returns {ok, reason}. The success sentence must not grow a
        # dangling fragment when nothing was supplied.
        $log = [Collections.Generic.List[string]]::new()
        $landing = script:Invoke-Landing -Ports (script:New-LandingPorts -Log $log)

        $landing.landed | Should -BeTrue
        $landing.message | Should -Match '(?i)signed off'
        $landing.message | Should -Not -Match '\(\s*\)'
        $landing.message | Should -Not -Match '(?i)0 commands'
    }

    It 'FR-013: a step with NO diagnosis renders no empty section' {
        # Most failures are not command failures and carry nothing derived. A message that always makes
        # room for a diagnosis teaches the reader to skip the place where one appears.
        $log = [Collections.Generic.List[string]]::new()
        $landing = script:Invoke-Landing -Ports (script:New-LandingPorts -GateOk $false -Log $log)

        $landing.landed | Should -BeFalse
        $landing.message | Should -Not -Match '(?i)what the check reported'
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
