#requires -Version 7.0
$ErrorActionPreference = 'Stop'

# F-198 Iteration 005 / T037 (spec FR-052): Copilot CLI contract regressions.
#
# These encode the OBSERVED contract from
#   specs/198-beta2-hardening/iterations/005/evidence/copilot-cli-contract-characterization.md
# (GitHub Copilot CLI 1.0.70, probed 2026-07-14) as PURE / DETERMINISTIC assertions over the documented
# contract + Specrew's OWN config (the copilot host manifest, the reviewer-host catalog, the dispatcher, the
# reviewer spawn). They do NOT re-run the real Copilot CLI - the live probe already happened; this is the
# durable regression that guards Specrew's model of it. Four load-bearing facts (FR-052):
#   (a) user-hook governance is expected in BOTH `-p` and interactive (Specrew rides the USER hook);
#   (b) repo hooks in `-p` require the `trustedFolders` opt-in - set it when governance is expected, ELSE
#       report `unsupported`; NEVER silently gate;
#   (c) the agentStop gate shape is {"decision":"block","reason":...} at exit 0;
#   (d) INTENTIONAL reviewer suppression (the hook FIRES, then SPECREW_REFOCUS_DISABLE=1 no-ops it) is
#       distinguishable from ACCIDENTAL bypass (the hook NEVER fires) - by ONE observable: did the hook fire?
Describe 'F-198 T037 FR-052 Copilot CLI contract (observed 1.0.70) encoded as Specrew regressions' {
    BeforeAll {
        $script:RepoRoot = (Resolve-Path "$PSScriptRoot/../../..").Path
        $script:ScratchTmp = Join-Path $script:RepoRoot '.scratch/tmp'
        New-Item -ItemType Directory -Path $script:ScratchTmp -Force | Out-Null
        $env:TEMP = $script:ScratchTmp
        $env:TMP = $script:ScratchTmp
        $env:SPECREW_MODULE_PATH = $script:RepoRoot
        Import-Module (Join-Path $script:RepoRoot 'Specrew.psd1') -Force
        . (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/_load.ps1')

        # Specrew's model of the Copilot host (the OBSERVE baseline this task does NOT rewrite).
        $script:CopilotManifest    = Import-PowerShellDataFile -LiteralPath (Join-Path $script:RepoRoot 'hosts/copilot/host.psd1')
        $script:CopilotBindings    = $script:CopilotManifest.RefocusHookBindings
        $script:CopilotRuntime     = $script:CopilotBindings.DispatcherRuntime
        $script:CopilotManifestRaw = Get-Content -LiteralPath (Join-Path $script:RepoRoot 'hosts/copilot/host.psd1') -Raw

        # The reviewer invocation (host-neutral catalog DATA) + the reviewer-spawn / dispatcher source.
        $script:CopilotAgentic      = Get-ContinuousCoReviewHostAgenticCommand -HostName 'copilot'
        $script:WorktreeReviewerSrc = Get-Content -LiteralPath (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/worktree-reviewer.ps1') -Raw
        $script:DispatcherPath      = Join-Path $script:RepoRoot 'scripts/internal/specrew-hook-dispatcher.ps1'
        $script:DispatcherSrc       = Get-Content -LiteralPath $script:DispatcherPath -Raw

        # PURE classifier of the load-bearing (d) distinction. Evidence doc section 5: the SINGLE observable that
        # separates INTENTIONAL reviewer suppression from ACCIDENTAL downstream bypass is "did the hook FIRE?".
        #   fired + disabled -> intentional-suppression (the hook ran, then the kill switch no-oped it)
        #   fired + enabled  -> governed                (the hook ran and injected/gated governance)
        #   NOT fired        -> accidental-bypass       (governance silently absent, with NO deliberate gate)
        function Get-CopilotHookGovernanceState {
            param([bool] $HookFired, [bool] $RefocusDisabled)
            if (-not $HookFired) { return 'accidental-bypass' }
            if ($RefocusDisabled) { return 'intentional-suppression' }
            return 'governed'
        }

        # PURE evaluator of the FR-052 repo-hook `-p` rule (b): if `-p` governance EVER rides a REPO-level hook,
        # the folder MUST be in `trustedFolders` when governance is expected, ELSE report `unsupported` - NEVER
        # silently gate. USER-level delivery is not trust-gated (observed A/F), so it is always supported.
        function Get-CopilotPromptModeGovernanceSupport {
            param(
                [ValidateSet('user', 'repo')][string] $HookLevel,
                [bool] $GovernanceExpected,
                [bool] $TrustedFoldersSet
            )
            if ($HookLevel -eq 'user') { return 'supported' }    # user hooks are NOT trust-gated (observed A + F)
            if (-not $GovernanceExpected) { return 'supported' }  # nothing to gate
            if ($TrustedFoldersSet) { return 'supported' }        # opt-in set -> repo hooks fire in -p (observed C2)
            return 'unsupported'                                  # untrusted repo -p: `unsupported`, NEVER silently gated
        }
    }

    Context '(a) Specrew rides the USER-level hook, expected to govern in BOTH -p and interactive' {
        It 'models governance on a USER-level hooks file (~/.copilot/hooks), wholly Specrew-owned' {
            [string]$script:CopilotBindings.SettingsFile | Should -Match '^~/\.copilot/hooks/'
            [bool]$script:CopilotBindings.OwnsSettingsFile | Should -BeTrue
            # NOT a repo-level surface (.github/hooks or a repo settings.json) - so NOT subject to the -p trust gate.
            [string]$script:CopilotBindings.SettingsFile | Should -Not -Match '(?i)\.github|settings\.json'
        }

        It 'registers the observed user-hook lifecycle events (sessionStart + agentStop)' {
            $events = @($script:CopilotBindings.Registrations | ForEach-Object { [string]$_.Event })
            $events | Should -Contain 'sessionStart'
            $events | Should -Contain 'agentStop'
        }

        It 'expects governance in BOTH -p and interactive - user hooks are not trust-gated (observed A + F)' {
            foreach ($mode in @('-p', 'interactive')) {
                Get-CopilotPromptModeGovernanceSupport -HookLevel 'user' -GovernanceExpected $true -TrustedFoldersSet $false |
                    Should -Be 'supported' -Because "user-level hooks fire in $mode (observed scenarios A/F)"
            }
        }
    }

    Context '(b) repo hooks in -p require the trustedFolders opt-in - never silently gated' {
        It 'reports repo-level -p governance UNSUPPORTED when the folder is untrusted (never a silent gate)' {
            # This is the FR-052 rule: an untrusted repo `-p` folder silently skips repo hooks (observed C1), so if
            # governance is EXPECTED there it MUST be reported `unsupported`, not quietly assumed gated.
            Get-CopilotPromptModeGovernanceSupport -HookLevel 'repo' -GovernanceExpected $true -TrustedFoldersSet $false |
                Should -Be 'unsupported'
        }

        It 'reports repo-level -p governance SUPPORTED once the folder is in trustedFolders (observed C1 -> C2)' {
            Get-CopilotPromptModeGovernanceSupport -HookLevel 'repo' -GovernanceExpected $true -TrustedFoldersSet $true |
                Should -Be 'supported'
        }

        It 'Specrew SIDESTEPS the trust gate today by delivering governance USER-level, not repo-level' {
            # The current model rides the user hook (a), so the untrusted-repo `-p` silent-skip surface never applies.
            [string]$script:CopilotBindings.SettingsFile | Should -Match '^~/\.copilot/hooks/'
            Get-CopilotPromptModeGovernanceSupport -HookLevel 'user' -GovernanceExpected $true -TrustedFoldersSet $false |
                Should -Be 'supported'
        }
    }

    Context '(c) the agentStop gate shape is {"decision":"block","reason":...} at exit 0' {
        It 'models the Copilot agentStop stop-block lever as decision-block' {
            [string]$script:CopilotRuntime.StopBlockShape | Should -Be 'decision-block'
        }

        It 'the decision-block envelope parses to exactly decision=block + reason (order-insensitive)' {
            # Reconstruct the envelope the SAME way the dispatcher's Write-StopBlockOutput does for decision-block,
            # then parse it back so key ORDER (an unordered hashtable) can never make this flaky. The CLI parses by
            # key, at exit 0, on stdout (observed section 4).
            $reason   = 'PROBE-BLOCK-abc123'
            $envelope = @{ decision = 'block'; reason = $reason } | ConvertTo-Json -Depth 4 -Compress
            $parsed   = $envelope | ConvertFrom-Json
            $parsed.decision | Should -Be 'block'
            $parsed.reason   | Should -Be $reason
            # a COMPACT single-line JSON object (no pretty-print) - the shape the hook writes to stdout.
            $envelope | Should -Match '^\{.*"decision":"block".*\}$'
            $envelope | Should -Match '"reason":"PROBE-BLOCK-abc123"'
        }

        It 'ties the shape to Specrew''s emitter: the dispatcher maps decision-block to {decision:block, reason}' {
            # Source-contract tie: change the dispatcher's decision-block envelope and this regression breaks.
            $script:DispatcherSrc | Should -Match ([regex]::Escape("'decision-block'"))
            $needle = "decision = 'block'; reason = " + '$Reason'
            $script:DispatcherSrc | Should -Match ([regex]::Escape($needle))
        }

        It 'documents fail-open + no-built-in-loop-guard for agentStop (observed caveats, section 4)' {
            $script:CopilotManifestRaw | Should -Match '(?i)fail-open'
            $script:CopilotManifestRaw | Should -Match '(?i)loop guard'
        }
    }

    Context '(d) INTENTIONAL reviewer suppression is distinguishable from ACCIDENTAL bypass by ONE observable' {
        It 'separates the two states purely by "did the hook fire?" - and never conflates them' {
            Get-CopilotHookGovernanceState -HookFired $true  -RefocusDisabled $true  | Should -Be 'intentional-suppression'
            Get-CopilotHookGovernanceState -HookFired $false -RefocusDisabled $true  | Should -Be 'accidental-bypass'
            Get-CopilotHookGovernanceState -HookFired $false -RefocusDisabled $false | Should -Be 'accidental-bypass'
            Get-CopilotHookGovernanceState -HookFired $true  -RefocusDisabled $false | Should -Be 'governed'
            # suppression is NOT bypass - the same env-var with a fired vs non-fired hook yields DIFFERENT verdicts.
            (Get-CopilotHookGovernanceState -HookFired $true -RefocusDisabled $true) |
                Should -Not -Be (Get-CopilotHookGovernanceState -HookFired $false -RefocusDisabled $true)
        }

        It 'the reviewer invokes copilot in non-interactive -p mode (where USER hooks DO fire -> suppression is the lever)' {
            $script:CopilotAgentic | Should -Not -BeNullOrEmpty
            @($script:CopilotAgentic.pre_args) | Should -Contain '-p'
            [bool]$script:CopilotAgentic.prompt_via_stdin | Should -BeFalse
        }

        It 'wires INTENTIONAL suppression: the reviewer spawn sets SPECREW_REFOCUS_DISABLE=1 (the hook fires, then no-ops)' {
            $script:WorktreeReviewerSrc | Should -Match "SPECREW_REFOCUS_DISABLE'\]\s*=\s*'1'"
        }

        It 'PROVES fired-then-suppressed for the copilot host: the dispatcher honors the kill switch (exit 0, NO block emitted)' {
            # Deterministic subprocess (NOT the live CLI): with SPECREW_REFOCUS_DISABLE=1 the copilot dispatcher
            # RUNS (the hook fired) but no-ops BEFORE any governance / stop-block - proving reviewer suppression is
            # "fired THEN env-gated", categorically different from a hook that never ran (accidental bypass).
            $runtimeJson = ($script:CopilotRuntime | ConvertTo-Json -Depth 8 -Compress)
            $binding     = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($runtimeJson))
            $pwshPath    = (Get-Process -Id $PID).Path
            $prev = $env:SPECREW_REFOCUS_DISABLE
            try {
                $env:SPECREW_REFOCUS_DISABLE = '1'
                $out = & $pwshPath -NoProfile -NonInteractive -File $script:DispatcherPath -Event agentStop -HostKind copilot -HostBinding $binding 2>$null
                $LASTEXITCODE | Should -Be 0 -Because 'fail-open: a suppressed hook still exits 0 (a hook failure never blocks the session)'
                ([string]($out -join '')) | Should -Not -Match '(?i)"decision"\s*:\s*"block"' -Because 'suppressed = the hook FIRED then no-oped; it must NOT emit an agentStop block'
            }
            finally {
                if ($null -eq $prev) { Remove-Item Env:\SPECREW_REFOCUS_DISABLE -ErrorAction SilentlyContinue } else { $env:SPECREW_REFOCUS_DISABLE = $prev }
            }
        }

        It 'keeps ACCIDENTAL bypass off Specrew''s governed path: user-level delivery is not trust-gated, so the hook fires' {
            # Because governance rides the USER hook (a), a governed `copilot -p` session HAS hookFired=true, so its
            # normal state is `governed`, never a silent `accidental-bypass`. The repo-level untrusted case (which
            # WOULD be accidental bypass) is precisely the one FR-052 forbids leaving silently gated (b).
            [string]$script:CopilotBindings.SettingsFile | Should -Match '^~/\.copilot/hooks/'
            Get-CopilotHookGovernanceState -HookFired $true -RefocusDisabled $false | Should -Be 'governed'
        }
    }
}
