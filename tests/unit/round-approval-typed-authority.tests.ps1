#requires -Version 7.0
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# W44 (2026-08-22, maintainer ruling): ROUND APPROVAL IS A TYPED PHRASE, LIKE EVERY OTHER AUTHORITY.
#
# RED FIRST, as the ruling demanded: before this change, `specrew review --live --approve-round` minted
# an approval on BARE INVOCATION, regardless of who invoked it. An agent running the command WAS the
# approval - the only authority in the system an agent could perform rather than relay. The acceptance
# case below ("an agent invocation with no captured approval is refused") fails against that build,
# which is the red this suite existed to produce.
#
# The model now: the human types `approved for review round` in the conversation; the prompt hooks
# capture it (Stop backstop for hosts whose prompt event carries no text); the agent runs the command,
# which consumes the captured phrase as its authority and stamps it spent with the reference it became.
# A human at their own terminal - no agent session env - is still self-evidently authorized: their
# invocation IS the approving act. The !-prefix path is covered by the capture recognizing the human's
# own typed invocation as the act.
#
# GOVERNANCE, not security: an agent holding the filesystem could fabricate the capture file, exactly
# as it could fabricate verdict_history. The control makes the honest path the easy path and turns a
# quiet liberty into a deliberate, auditable forgery.

BeforeAll {
    $script:RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
    . (Join-Path $script:RepoRoot 'scripts/internal/bootstrap/HumanAuthorityStore.ps1')
    $script:ReviewCli = Join-Path $script:RepoRoot 'scripts/specrew-review.ps1'
    $script:AgentEnvNames = @(Get-SpecrewAgentSessionSignalNames)

    function script:New-CampaignFixture {
        $root = Join-Path ([IO.Path]::GetTempPath()) ('w44-' + [guid]::NewGuid().ToString('N'))
        New-Item -ItemType Directory -Path (Join-Path $root '.specrew') -Force | Out-Null
        New-Item -ItemType Directory -Path (Join-Path $root 'specs/001-fixture/iterations/001') -Force | Out-Null
        # W52 aftermath: a MINIMAL Specrew-managed marker written inline, never copied from the repo's
        # own .specrew - that directory is machinery the reviewed-state digest strips, so a fixture
        # depending on it passes in the working tree and fails in the frozen tree a reviewer is handed
        # (method rule 5's world-gap, measured by two failed review launches).
        Set-Content -LiteralPath (Join-Path $root '.specrew/config.yml') -Value "specrew_version: `"0.40.0`"`nbootstrap_mode: `"fixture`"" -Encoding UTF8
        & git init -q -b 001-fixture $root 2>&1 | Out-Null
        return $root
    }

    function script:Invoke-ReviewCli {
        # -File invocation so `--live` / `--approve-round` reach the script's own arg parser; direct
        # invocation binds them as PowerShell parameters and silently drops the live path.
        param(
            [Parameter(Mandatory)][string]$Root,
            [Parameter(Mandatory)][ValidateSet('agent', 'terminal')][string]$Context,
            [string[]]$CliArgs = @('--approve-round'),
            [switch]$OmitFeature
        )
        $envPrelude = if ($Context -eq 'terminal') {
            # Clear every agent-session signal in the CHILD, so the case is deterministic wherever the
            # suite itself runs - inside a session or in CI.
            "foreach (`$n in '" + ($script:AgentEnvNames -join "','") + "') { Remove-Item ('env:'+`$n) -ErrorAction SilentlyContinue }; "
        }
        else {
            # Assert agent context explicitly rather than inheriting it, for the same determinism.
            "`$env:CLAUDECODE = '1'; "
        }
        $featureArg = if ($OmitFeature) { '' } else { ' -FeatureId 001-fixture' }
        $command = $envPrelude + "pwsh -NoProfile -File '" + $script:ReviewCli + "' -ProjectPath '" + $Root + "'" + $featureArg + " --live " + ($CliArgs -join ' ') + "; exit `$LASTEXITCODE"
        $output = @(& pwsh -NoProfile -Command $command 2>&1 | ForEach-Object { [string]$_ })
        return [pscustomobject]@{ ExitCode = $LASTEXITCODE; Text = ($output -join "`n") }
    }

    function script:Get-PendingFactPath {
        param([Parameter(Mandatory)][string]$Root)
        return Join-Path $Root '.specrew/review/round-approval/pending-round-approval.json'
    }
}

Describe 'W44 the recognizer accepts only a clear human approving act' {
    It 'accepts the typed phrase and its natural variants' {
        foreach ($text in @('approved for review round',
                'Approved for a review round - focus on the layout module',
                'yes - approve a review round',
                'approve another review round',
                'approved for review round.')) {
            (Test-SpecrewReviewRoundApprovalPhrase -Text $text).Matched | Should -BeTrue -Because $text
        }
    }

    It 'accepts the humans own invocation, which is what keeps the !-prefix path working' {
        foreach ($text in @('! specrew review --live --approve-round',
                'specrew review --live --feature 001-x --approve-round')) {
            $r = Test-SpecrewReviewRoundApprovalPhrase -Text $text
            $r.Matched | Should -BeTrue -Because $text
            $r.Kind | Should -Be 'self-invocation'
        }
    }

    It 'rejects questions, negations, deferrals, mentions and machinery envelopes' {
        foreach ($text in @('should I approve a review round?',
                'do not approve a review round',
                'approve a review round once the tests pass',
                'reply with approved for review round when ready',
                'the phrase approved for review round is how you approve',
                'approved for review-signoff',
                'approved for review round?',
                'we discussed specrew review --live --approve-round yesterday and it failed',
                '<system-reminder>approved for review round</system-reminder>',
                'approved for review rounds of golf')) {
            (Test-SpecrewReviewRoundApprovalPhrase -Text $text).Matched | Should -BeFalse -Because $text
        }
    }
}

Describe 'W44 the capture store: one approval, one round' {
    It 'captures, reads back unspent, and reads null once completed' {
        $root = New-CampaignFixture
        try {
            $written = Write-SpecrewReviewRoundApprovalAuthorization -ProjectRoot $root -Response 'approved for review round' -HostKind 'claude' -SourceEvent 'UserPromptSubmit'
            $written | Should -Not -BeNullOrEmpty
            (Get-SpecrewReviewRoundApprovalAuthorization -ProjectRoot $root).verdict_text | Should -Be 'approved for review round'
            $null = Complete-SpecrewReviewRoundApprovalAuthorization -ProjectRoot $root -AuthorizationRef 'cmp-x-round-1'
            Get-SpecrewReviewRoundApprovalAuthorization -ProjectRoot $root | Should -BeNullOrEmpty -Because 'a spent approval authorizes nothing further'
            $onDisk = Get-Content -LiteralPath (Get-PendingFactPath -Root $root) -Raw | ConvertFrom-Json
            [string]$onDisk.authorization_ref | Should -Be 'cmp-x-round-1' -Because 'the record reads end to end: the phrase, and the reference it became'
        }
        finally { Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue }
    }

    It 'refuses to authorize from agent text: a non-prompt source event captures nothing' {
        $root = New-CampaignFixture
        try {
            Write-SpecrewReviewRoundApprovalAuthorization -ProjectRoot $root -Response 'approved for review round' -HostKind 'claude' -SourceEvent 'PostToolUse' | Should -BeNullOrEmpty
            Get-SpecrewReviewRoundApprovalAuthorization -ProjectRoot $root | Should -BeNullOrEmpty
        }
        finally { Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue }
    }

    It 'fails CLOSED on a hand-authored file that does not hash-check' {
        $root = New-CampaignFixture
        try {
            $path = Get-PendingFactPath -Root $root
            New-Item -ItemType Directory -Path (Split-Path -Parent $path) -Force | Out-Null
            # The forgery shape: the fields an author would guess, without the hash discipline.
            Set-Content -LiteralPath $path -Value '{"schema_version":"1.0","fact_type":"review-round-approval","authority_kind":"human","verdict_text":"approved for review round","response_hash":"not-the-hash","evidence_source":"hook-captured-user-prompt","source_event":"UserPromptSubmit","observed_at":"2026-08-22T00:00:00Z"}' -Encoding UTF8
            Get-SpecrewReviewRoundApprovalAuthorization -ProjectRoot $root | Should -BeNullOrEmpty -Because 'absent is the fail direction, and a file that does not check is absent'
        }
        finally { Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue }
    }
}

Describe 'W44 the agent-session signal list cannot drift from the host detector' {
    It 'matches the per-host env sets in Get-SpecrewRuntimeHostFromEnv' {
        # The parity the store comment promises. A host added to HandoverStore without being added to
        # the signal list would let that host approve rounds bare - silently.
        $handoverStore = Get-Content -LiteralPath (Join-Path $script:RepoRoot 'scripts/internal/bootstrap/HandoverStore.ps1') -Raw -Encoding UTF8
        $blockMatch = [regex]::Match($handoverStore, '(?s)\$signals\s*=\s*\[ordered\]@\{(.+?)\}')
        $blockMatch.Success | Should -BeTrue
        $declared = @([regex]::Matches($blockMatch.Groups[1].Value, "'([A-Z0-9_]+)'") | ForEach-Object { $_.Groups[1].Value }) |
            Where-Object { $_ -match '^[A-Z]' } | Sort-Object -Unique
        $mine = @(Get-SpecrewAgentSessionSignalNames) | Sort-Object -Unique
        ($mine -join ',') | Should -Be ($declared -join ',') -Because 'one signal list, two consumers, pinned together'
    }
}

Describe 'W44 ACCEPTANCE: who may fire a round, end to end through the real CLI' {
    It 'RED-FIRST CASE: an agent invocation with no captured approval is refused, naming the phrase' {
        # This is the case that fails against the pre-W44 build, where bare invocation minted.
        $root = New-CampaignFixture
        try {
            $run = Invoke-ReviewCli -Root $root -Context 'agent'
            $run.ExitCode | Should -Be 1
            $run.Text | Should -Match 'approved for review round' -Because 'the refusal must hand the agent the exact phrase to ask for'
            $run.Text | Should -Match 'no approval from them has been captured'
            $run.Text | Should -Not -Match 'Round approved'
        }
        finally { Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue }
    }

    It 'an agent invocation AFTER the typed phrase runs - and an UNDELIVERED run leaves the entitlement standing' {
        # W50 (maintainer ruling) supersedes the original stamp-at-mint expectation this case carried:
        # the allowance meters attempts; the human authorizes DELIVERIES. This fixture has no reviewer,
        # so nothing is ever delivered - and the walk proved the old behavior wrong: the capture was
        # spent by an invocation that crashed, and the one-capture-one-round refusal locked the human
        # out. The entitlement now survives every failure and is consumed only by a delivered review.
        $root = New-CampaignFixture
        try {
            $null = Write-SpecrewReviewRoundApprovalAuthorization -ProjectRoot $root -Response 'approved for review round' -HostKind 'claude' -SourceEvent 'UserPromptSubmit'
            $run = Invoke-ReviewCli -Root $root -Context 'agent'
            $run.Text | Should -Match 'Round approved by the human''s typed phrase'
            $run.Text | Should -Not -Match 'no approval from them has been captured'
            $fact = Get-Content -LiteralPath (Get-PendingFactPath -Root $root) -Raw | ConvertFrom-Json
            [string]$fact.spent_at | Should -BeNullOrEmpty -Because 'nothing was delivered, so the entitlement stands - a failure must not spend the human''s approval'
        }
        finally { Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue }
    }

    It 'a human at their own terminal is still self-evidently authorized' {
        # No agent session env, no capture needed: the invocation IS the approving act.
        $root = New-CampaignFixture
        try {
            $run = Invoke-ReviewCli -Root $root -Context 'terminal'
            $run.Text | Should -Not -Match 'no approval from them has been captured'
            $run.Text | Should -Match 'Round approved\. Specrew recorded your approval as'
        }
        finally { Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue }
    }
}

Describe 'W44 the pause menu answer that spends a round carries the same authority' {
    # Extension (maintainer, 2026-08-22): answering the pause with "run another round" IS approving a
    # round - W21 established that for the mint - so the gate covers the whole approval predicate, and
    # `--pause-choice 1` was the last invocation-is-approval surface. Choices 2 and 3 spend nothing and
    # must never be asked to authorize the spend they are declining.

    It 'an agent relaying pause-choice 1 without a captured phrase is refused' {
        $root = New-CampaignFixture
        try {
            $run = Invoke-ReviewCli -Root $root -Context 'agent' -CliArgs @('--pause-choice', '1')
            $run.ExitCode | Should -Be 1
            $run.Text | Should -Match 'no approval from them has been captured'
            $run.Text | Should -Match 'approved for review round'
        }
        finally { Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue }
    }

    It 'an agent relaying pause-choice 1 AFTER the typed phrase gets past the gate' {
        $root = New-CampaignFixture
        try {
            $null = Write-SpecrewReviewRoundApprovalAuthorization -ProjectRoot $root -Response 'approved for review round' -HostKind 'claude' -SourceEvent 'UserPromptSubmit'
            $run = Invoke-ReviewCli -Root $root -Context 'agent' -CliArgs @('--pause-choice', '1')
            # The bare fixture fails later for its own reasons; what matters is WHICH refusal.
            $run.Text | Should -Not -Match 'no approval from them has been captured'
        }
        finally { Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue }
    }

    It 'choices 2 and 3 spend nothing and are never gated on an approval' {
        $root = New-CampaignFixture
        try {
            foreach ($choice in @('2', '3')) {
                $run = Invoke-ReviewCli -Root $root -Context 'agent' -CliArgs @('--pause-choice', $choice)
                $run.Text | Should -Not -Match 'no approval from them has been captured' -Because "choice $choice declines or ends the spend; asking it to authorize one is the W21-era wedge"
            }
        }
        finally { Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue }
    }

    It 'a human at their terminal answering pause-choice 1 stays self-evident' {
        $root = New-CampaignFixture
        try {
            $run = Invoke-ReviewCli -Root $root -Context 'terminal' -CliArgs @('--pause-choice', '1')
            $run.Text | Should -Not -Match 'no approval from them has been captured'
        }
        finally { Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue }
    }

    It 'both pause surfaces name the typed phrase on the option that spends' {
        # W49 rewording: the option leads with the typed decision (`run another round`) and carries the
        # approval phrase, because choosing it approves a round.
        foreach ($file in @('scripts/internal/continuous-co-review/review-authority-core.ps1',
                'scripts/internal/continuous-co-review/continuous-co-review-navigator.ps1')) {
            $text = Get-Content -LiteralPath (Join-Path $script:RepoRoot $file) -Raw -Encoding UTF8
            $optionLine = [regex]::Match($text, "id = 1[^\r\n]*run another round[^\r\n]*").Value
            $optionLine | Should -Not -BeNullOrEmpty -Because $file
            $optionLine.Contains('approved for review round') | Should -BeTrue -Because 'the human answering in a conversation must be shown the phrase that IS the approval'
        }
    }

    It 'THE GENERAL PROPERTY: the gate condition is the same predicate that gates the mint' {
        # Checkable now, as the ruling asked: no code path mints round authority without either a
        # captured phrase or the human own invocation. The gate must sit on $roundApprovalRequested -
        # the one predicate W21 pins as the full set of round-approving entries - so a new entry added
        # to the predicate is gated automatically, and narrowing the gate back to the flag alone is a
        # detectable mutation (the pause-choice refusal case above goes red).
        $cli = Get-Content -LiteralPath $script:ReviewCli -Raw -Encoding UTF8
        $tokens = $null; $parseErrors = $null
        $ast = [System.Management.Automation.Language.Parser]::ParseInput($cli, [ref]$tokens, [ref]$parseErrors)
        $gate = @($ast.FindAll({
                    param($node)
                    $node -is [System.Management.Automation.Language.IfStatementAst] -and
                    $node.Extent.Text.Contains('no approval from them has been captured') -and
                    $node.Extent.Text.Contains('approved for review round')
                }, $true) | Sort-Object { $_.Extent.Text.Length } | Select-Object -First 1)
        @($gate).Count | Should -Be 1
        # Walk outward: the refusal must live under a $roundApprovalRequested condition.
        $node = $gate[0]; $guarded = $false
        while ($null -ne $node) {
            if ($node -is [System.Management.Automation.Language.IfStatementAst] -and
                $node.Clauses[0].Item1.Extent.Text -match 'roundApprovalRequested') { $guarded = $true; break }
            $node = $node.Parent
        }
        $guarded | Should -BeTrue -Because 'gating on ApproveRound alone leaves pause-choice 1 as an invocation-is-approval surface'
    }
}

Describe 'W50 the entitlement: the allowance meters attempts, the human authorizes deliveries' {
    # RED-FIRST against the pre-W50 build: the walk's --approve-round consumed the captured phrase and
    # minted round-2, then crashed on FeatureId validation - the approval was spent by an invocation
    # that could never run, and the one-capture-one-round refusal locked the human out.

    It 'ACCEPTANCE: an unresolvable feature refuses in consumer language and leaves the entitlement unconsumed - and says so' {
        $root = New-CampaignFixture
        try {
            # Strip every feature-resolution source: no feature dir match for the branch, no
            # session feature_ref, no feature.json.
            Remove-Item -LiteralPath (Join-Path $root 'specs/001-fixture') -Recurse -Force
            $null = Write-SpecrewReviewRoundApprovalAuthorization -ProjectRoot $root -Response 'approved for review round' -HostKind 'claude' -SourceEvent 'UserPromptSubmit'
            $run = Invoke-ReviewCli -Root $root -Context 'agent' -CliArgs @('--approve-round') -OmitFeature
            $run.ExitCode | Should -Be 1
            $run.Text | Should -Match '--feature' -Because 'the refusal names the flag in consumer language'
            $run.Text | Should -Not -Match '\[0-9\]\+-\[a-z0-9\]' -Because 'a raw id regex is an internal-language leak in a refusal'
            $run.Text | Should -Match 'was NOT spent'
            $fact = Get-Content -LiteralPath (Get-PendingFactPath -Root $root) -Raw | ConvertFrom-Json
            [string]$fact.spent_at | Should -BeNullOrEmpty -Because 'failure before invocation consumes nothing'
        }
        finally { Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue }
    }

    It 'classifies every outcome the rule names, on FR-014''s own discriminator' {
        (Resolve-SpecrewRoundEntitlementOutcome -CampaignRun ([pscustomobject]@{ invoked = $true; status = 'terminal'; result = [pscustomobject]@{ runtime_outcome = 'completed'; completion = 'complete' } })).outcome | Should -Be 'delivered'
        (Resolve-SpecrewRoundEntitlementOutcome -CampaignRun ([pscustomobject]@{ invoked = $true; status = 'terminal'; result = [pscustomobject]@{ runtime_outcome = 'completed'; completion = 'partial' } })).outcome | Should -Be 'undelivered' -Because 'a partial is consumed only when the human explicitly accepts it'
        (Resolve-SpecrewRoundEntitlementOutcome -CampaignRun ([pscustomobject]@{ invoked = $true; status = 'terminal'; result = [pscustomobject]@{ runtime_outcome = 'timed-out'; completion = 'incomplete' } })).outcome | Should -Be 'undelivered'
        (Resolve-SpecrewRoundEntitlementOutcome -CampaignRun ([pscustomobject]@{ invoked = $true; status = 'terminal'; result = [pscustomobject]@{ runtime_outcome = 'preflight-failed'; completion = '' } })).outcome | Should -Be 'not-invoked' -Because 'a run that never reached a reviewer is failure-before-invocation, whatever the plumbing says'
        (Resolve-SpecrewRoundEntitlementOutcome -CampaignRun ([pscustomobject]@{ invoked = $false; status = 'not-started'; result = $null })).outcome | Should -Be 'not-invoked'
        (Resolve-SpecrewRoundEntitlementOutcome -CampaignRun $null).outcome | Should -Be 'not-invoked'
    }

    It 'a partial the human explicitly accepts consumes the entitlement - at the acceptance' {
        $root = New-CampaignFixture
        try {
            $null = Write-SpecrewReviewRoundApprovalAuthorization -ProjectRoot $root -Response 'approved for review round' -HostKind 'claude' -SourceEvent 'UserPromptSubmit'
            $null = Write-SpecrewReviewSignoffOverrideRequest -ProjectRoot $root -TargetTreeId ('a' * 40) -CampaignId 'cmp-w50-fixture'
            $null = Write-SpecrewReviewSignoffOverrideAuthorization -ProjectRoot $root -Response 'approved for partial review signoff - the uncovered half is generated code' -HostKind 'claude' -SourceEvent 'UserPromptSubmit'
            Get-SpecrewReviewRoundApprovalAuthorization -ProjectRoot $root | Should -BeNullOrEmpty -Because 'accepting the partial IS the delivery'
            $fact = Get-Content -LiteralPath (Get-PendingFactPath -Root $root) -Raw | ConvertFrom-Json
            [string]$fact.authorization_ref | Should -Match '^partial-accepted:'
        }
        finally { Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue }
    }

    It 'THE STRUCTURE: consumption keys on delivered, the retry is bounded at one, and both are journaled' {
        # The retry loop is CLI plumbing around a live harness, so its wiring is pinned structurally:
        # Complete- fires only inside the delivered branch; the loop breaks at attempt 2; every
        # undelivered attempt and every retry choice writes the delivery journal; and the second
        # failure produces the plain-language ask, never the phrase demand.
        $cli = Get-Content -LiteralPath $script:ReviewCli -Raw -Encoding UTF8
        $loop = [regex]::Match($cli, "(?s)# W50: THE ENTITLEMENT LOOP.+?could not be delivered after a retry").Value
        $loop | Should -Not -BeNullOrEmpty
        $loop.Contains("outcome -ceq 'delivered'") | Should -BeTrue
        ([regex]::Matches($loop, [regex]::Escape('Complete-SpecrewReviewRoundApprovalAuthorization -ProjectRoot'))).Count | Should -Be 1 -Because 'delivery is the only consumption point in the loop'
        $loop.Contains('if ($entitlementAttempt -ge 2) { break }') | Should -BeTrue -Because 'unlimited retry on failure is a token-burn hole'
        $loop.Contains("'spent-without-delivery'") | Should -BeTrue -Because 'the cost is real and must stay visible'
        $loop.Contains("'automatic-retry'") | Should -BeTrue -Because 'the retry choice is recorded'
        $cli.Contains('Your approval is still standing') | Should -BeTrue -Because 'the ask is never a re-approval of the same decision'
    }
}

Describe 'W50 rider: the allowance reset is phrase-gated authority' {
    It 'recognizes the typed reset phrase conservatively' {
        (Test-SpecrewAllowanceResetPhrase -Text 'approved for allowance reset').Matched | Should -BeTrue
        (Test-SpecrewAllowanceResetPhrase -Text 'approve an allowance reset').Matched | Should -BeTrue
        (Test-SpecrewAllowanceResetPhrase -Text 'should I approve an allowance reset?').Matched | Should -BeFalse
        (Test-SpecrewAllowanceResetPhrase -Text 'do not approve the allowance reset').Matched | Should -BeFalse
        (Test-SpecrewAllowanceResetPhrase -Text 'approved for review round').Matched | Should -BeFalse -Because 'the round phrase must not double as the reset phrase - different powers, different words'
    }

    It 'an agent invocation without the captured reset phrase is refused, naming it' {
        $root = New-CampaignFixture
        try {
            $run = Invoke-ReviewCli -Root $root -Context 'agent' -CliArgs @('--remediate', 'allowance-reset', '--ack-reason', '"more rounds needed"')
            $run.ExitCode | Should -Be 1
            $run.Text | Should -Match 'approved for allowance reset'
            $run.Text | Should -Match 'no approval from them has been captured'
        }
        finally { Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue }
    }

    It 'with the captured phrase the reset applies and the capture is stamped spent' {
        $root = New-CampaignFixture
        try {
            $null = Write-SpecrewAllowanceResetAuthorization -ProjectRoot $root -Response 'approved for allowance reset' -HostKind 'claude' -SourceEvent 'UserPromptSubmit'
            $run = Invoke-ReviewCli -Root $root -Context 'agent' -CliArgs @('--remediate', 'allowance-reset', '--ack-reason', '"more rounds needed"')
            $run.Text | Should -Match 'topped up'
            Get-SpecrewAllowanceResetAuthorization -ProjectRoot $root | Should -BeNullOrEmpty -Because 'one phrase, one reset'
        }
        finally { Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue }
    }

    It 'a human at their own terminal stays self-evident' {
        $root = New-CampaignFixture
        try {
            $run = Invoke-ReviewCli -Root $root -Context 'terminal' -CliArgs @('--remediate', 'allowance-reset', '--ack-reason', '"more rounds needed"')
            $run.Text | Should -Not -Match 'no approval from them has been captured'
            $run.Text | Should -Match 'topped up'
        }
        finally { Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue }
    }
}

Describe 'W44 the hooks feed the capture' {
    It 'the prompt-entry path offers the human turn to the round-approval writer' {
        $handoverStore = Get-Content -LiteralPath (Join-Path $script:RepoRoot 'scripts/internal/bootstrap/HandoverStore.ps1') -Raw -Encoding UTF8
        $promptBlock = [regex]::Match($handoverStore, "(?s)if \(\`$Source -in @\('UserPromptSubmit'.+?prompt-submit-verdict-capture").Value
        $promptBlock | Should -Not -BeNullOrEmpty
        $promptBlock.Contains('Write-SpecrewReviewRoundApprovalAuthorization') | Should -BeTrue -Because 'the phrase must be captured the moment the human types it, so the agent can run the round in the same turn'
    }

    It 'the Stop backstop relays only a verified human transcript turn' {
        $handoverStore = Get-Content -LiteralPath (Join-Path $script:RepoRoot 'scripts/internal/bootstrap/HandoverStore.ps1') -Raw -Encoding UTF8
        $stopBlock = [regex]::Match($handoverStore, "(?s)if \(\`$isEndOfTurn\) \{.+?^    \}", [System.Text.RegularExpressions.RegexOptions]::Multiline).Value
        $stopBlock.Contains('Write-SpecrewReviewRoundApprovalAuthorization') | Should -BeTrue -Because 'observed on claude: prompt events may not deliver text, and verdict capture lands at Stop'
        $stopBlock.Contains('Test-SpecrewTurnIsHumanVerdictEvidence') | Should -BeTrue -Because 'never agent text - the same provenance rule verdict capture uses'
    }
}
