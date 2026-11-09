#requires -Version 7.0
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# TYPED AUTHORITY IS CAPTURED FROM THE HUMAN'S OWN TURN, ONCE, AND NEVER FROM ANYTHING ELSE.
#
# Born as the W44 suite (2026-08-22, maintainer ruling: round approval is a typed phrase like every other
# authority). Feature 203 T008 (FR-010; DRIFT-052) removed the per-round approval and its withdrawal: the
# review budget approved with the implementation pays for review rounds. The rules this suite pinned through
# the round approval are kept, now proven on the acts that remain - the allowance reset and the stop
# decisions: a turn mints at most once, across channels; a damaged ledger or installation fails closed; a
# condition, a reversal or a following block defers; a question-UI reply is observed, never authority; and
# the retired phrase is still recognised, so it is never read as the `review` boundary verdict.
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

Describe 'W44 the retired round-approval phrase is still recognised, so it is never read as the review boundary verdict' {
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

    It 'a delimited deferral is still a deferral, whatever the delimiter - round 14 finding' {
        # Round-14 finding (DRIFT-199-I001-123): both spend-authority recognizers split the tail on
        # the delimiter and inspected element ZERO for deferral words - which for a delimited tail is
        # empty by construction - so "approved for review round, once the tests pass" minted
        # immediately and could spend a round before the stated condition held. The FOURTH recognizer
        # scoping defect in four rounds, and the first instance of the just-promoted method rule:
        # every branch and every DELIMITER that reaches the same return.
        foreach ($text in @('approved for review round, once the tests pass',
                'approved for review round; after we verify the failures',
                'approved for review round: when the lanes are green',
                'approved for review round. unless codex is busy',
                'approved for review round - if the budget allows')) {
            (Test-SpecrewReviewRoundApprovalPhrase -Text $text).Matched | Should -BeFalse -Because $text
        }
        foreach ($text in @('approved for allowance reset, after we verify the failures',
                'approved for allowance reset; once the walk finishes',
                'approved for allowance reset: when you are ready',
                'approved for allowance reset. if the drift is real',
                'approved for allowance reset - unless a round remains')) {
            (Test-SpecrewAllowanceResetPhrase -Text $text).Matched | Should -BeFalse -Because $text
        }
        # The conservative floor cuts one way only: a delimited INSTRUCTION tail still mints.
        (Test-SpecrewReviewRoundApprovalPhrase -Text 'approved for review round - use the codex reviewer').Matched |
            Should -BeTrue -Because 'instructions after the delimiter are the W44 shape, not a deferral'
        (Test-SpecrewAllowanceResetPhrase -Text 'approved for allowance reset - the drift is authority-layer code').Matched |
            Should -BeTrue -Because 'a reason is not a condition'
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

Describe 'W44 the pause menu answer that spends a round carries the same authority' {
    # Extension (maintainer, 2026-08-22): answering the pause with "run another round" IS approving a
    # round - W21 established that for the mint - so the gate covers the whole approval predicate, and
    # `--pause-choice 1` was the last invocation-is-approval surface. Choices 2 and 3 spend nothing and
    # must never be asked to authorize the spend they are declining.

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
        # W66 (round-24 finding, DRIFT-199-I001-138) moved the writer list into one router both capture
        # branches call, because the two hand-copied lists had drifted apart. The rule this case
        # protects is unchanged - the human's typed turn must be offered to the authority writers here -
        # so it now names the router instead of one writer inside it.
        $promptBlock.Contains('Invoke-SpecrewTypedAuthorityCapture') | Should -BeTrue -Because 'the phrase must be captured the moment the human types it, so the agent can run the round in the same turn'
    }

    It 'the Stop backstop relays only a verified human transcript turn' {
        $handoverStore = Get-Content -LiteralPath (Join-Path $script:RepoRoot 'scripts/internal/bootstrap/HandoverStore.ps1') -Raw -Encoding UTF8
        $stopBlock = [regex]::Match($handoverStore, "(?s)if \(\`$isEndOfTurn\) \{.+?^    \}", [System.Text.RegularExpressions.RegexOptions]::Multiline).Value
        $stopBlock.Contains('Invoke-SpecrewTypedAuthorityCapture') | Should -BeTrue -Because 'observed on claude: prompt events may not deliver text, and verdict capture lands at Stop'
        $stopBlock.Contains('Test-SpecrewTurnIsHumanVerdictEvidence') | Should -BeTrue -Because 'never agent text - the same provenance rule verdict capture uses'
    }
}

Describe 'W54 a phrase routed through a question UI is observed, diagnosed, and never authority' {
    # W54 (maintainer ruling, 2026-08-24, from the KeyContextAI walk): a Copilot agent asked for
    # `approved for review round` via its ask-user tool twice; the replies arrived as tool results,
    # capture correctly refused both by typed-turns doctrine, and the human answered the same
    # question three times. The fix is at the GUIDANCE layer: capture must not learn to read pickers
    # (that reintroduces the dismissal hazard typed-turns-v1 exists to prevent), but the refusal the
    # agent sees must name the actual cause and remedy - which requires the refusing pass to RECORD
    # what it saw. The observation is a diagnostic fact, never authority.

    It 'records the observation for a phrase inside a tool result, and mints nothing' {
        $root = Join-Path ([IO.Path]::GetTempPath()) ('w54-' + [guid]::NewGuid().ToString('N'))
        New-Item -ItemType Directory -Path (Join-Path $root '.specrew') -Force | Out-Null
        try {
            # The claude shape of an ask-user reply: a USER record whose content is a tool_result -
            # the phrase is in the transcript, and no genuine human turn carries it.
            $line = '{"type":"user","message":{"content":[{"type":"tool_result","tool_use_id":"t1","content":[{"type":"text","text":"approved for allowance reset"}]}]}}'
            $tp = Join-Path $root 'transcript.jsonl'
            [IO.File]::WriteAllLines($tp, [string[]]@($line), [Text.UTF8Encoding]::new($false))

            . (Join-Path $script:RepoRoot 'scripts/internal/bootstrap/ConversationCaptureAccessor.ps1')
            . (Join-Path $script:RepoRoot 'scripts/internal/bootstrap/ClassificationEngine.ps1')
            . (Join-Path $script:RepoRoot 'scripts/internal/bootstrap/ProjectMetadataAccessor.ps1')
            . (Join-Path $script:RepoRoot 'scripts/internal/bootstrap/HandoverStore.ps1')
            Update-SpecrewRollingHandover -ProjectRoot $root -TranscriptPath $tp -Source 'Stop' | Out-Null

            Get-SpecrewAllowanceResetAuthorization -ProjectRoot $root |
                Should -BeNullOrEmpty -Because 'a tool-result reply is not a typed turn; capture refusing it is the doctrine, not the defect'
            $obs = Get-SpecrewQuestionUiPhraseObservation -ProjectRoot $root
            $obs | Should -Not -BeNullOrEmpty -Because 'the refusing pass must record what it saw, or the refusal downstream cannot name the cause'
            [string]$obs.phrase_kind | Should -Be 'allowance-reset'
        }
        finally { Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue }
    }

    It 'does not observe the agent quoting the phrase, nor the question itself, nor CLI output echoing it' {
        $root = Join-Path ([IO.Path]::GetTempPath()) ('w54-' + [guid]::NewGuid().ToString('N'))
        New-Item -ItemType Directory -Path (Join-Path $root '.specrew') -Force | Out-Null
        try {
            $cliEcho = ('review output line`nThe approval is their typed reply: approved for allowance reset`nmore output ' + ('x' * 400))
            $lines = @(
                # The agent rendering the menu - assistant text quoting the phrase.
                '{"type":"assistant","message":{"content":[{"type":"text","text":"Reply with `approved for allowance reset` to approve one round."}]}}'
                # The QUESTION (tool_use input naming the phrase as an option) - a question is not a reply.
                '{"type":"assistant","message":{"content":[{"type":"tool_use","id":"t2","name":"ask_user","input":{"options":["approved for allowance reset","hold"]}}]}}'
                # CLI output echoing the advisory inside a LONG tool-result string - command output, not a picker reply.
                ('{"type":"user","message":{"content":[{"type":"tool_result","tool_use_id":"t3","content":[{"type":"text","text":"' + $cliEcho + '"}]}]}}')
            )
            $tp = Join-Path $root 'transcript.jsonl'
            [IO.File]::WriteAllLines($tp, [string[]]$lines, [Text.UTF8Encoding]::new($false))

            . (Join-Path $script:RepoRoot 'scripts/internal/bootstrap/ConversationCaptureAccessor.ps1')
            . (Join-Path $script:RepoRoot 'scripts/internal/bootstrap/ClassificationEngine.ps1')
            . (Join-Path $script:RepoRoot 'scripts/internal/bootstrap/ProjectMetadataAccessor.ps1')
            . (Join-Path $script:RepoRoot 'scripts/internal/bootstrap/HandoverStore.ps1')
            Update-SpecrewRollingHandover -ProjectRoot $root -TranscriptPath $tp -Source 'Stop' | Out-Null

            Get-SpecrewQuestionUiPhraseObservation -ProjectRoot $root |
                Should -BeNullOrEmpty -Because 'a false observation misdiagnoses a human who simply has not replied yet'
        }
        finally { Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue }
    }

    It 'a genuine typed capture clears the observation - the diagnosis must not outlive its cause' {
        $root = Join-Path ([IO.Path]::GetTempPath()) ('w54-' + [guid]::NewGuid().ToString('N'))
        New-Item -ItemType Directory -Path (Join-Path $root '.specrew') -Force | Out-Null
        try {
            Write-SpecrewQuestionUiPhraseObservation -ProjectRoot $root -PhraseKind 'allowance-reset' -HostKind 'copilot' -SourceEvent 'stop-transcript' | Out-Null
            (Get-SpecrewQuestionUiPhraseObservation -ProjectRoot $root) | Should -Not -BeNullOrEmpty
            $null = Write-SpecrewAllowanceResetAuthorization -ProjectRoot $root -Response 'approved for allowance reset' -HostKind 'copilot' -SourceEvent 'UserPromptSubmit'
            Get-SpecrewQuestionUiPhraseObservation -ProjectRoot $root |
                Should -BeNullOrEmpty -Because 'once the human typed it in the chat, the picker diagnosis is history, not standing state'
        }
        finally { Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue }
    }

    It 'the review CLI refusal names the cause and the remedy when the observation stands' {
        # Structural, on the shipped CLI: the refusal blocks consult the observation and carry the
        # cause ("question UI or picker") and the remedy ("type it in the chat").
        $cli = Get-Content -LiteralPath $script:ReviewCli -Raw -Encoding UTF8
        $cli.Contains('Get-SpecrewQuestionUiPhraseObservation') | Should -BeTrue -Because 'a refusal that cannot see the observation cannot name the cause'
        ([regex]::Matches($cli, [regex]::Escape('Ask the human to type it in the chat'))).Count |
            Should -BeGreaterOrEqual 1 -Because 'the allowance-reset refusal diagnoses the picker shape (feature 203 T008 removed the round approval and its refusal)'
    }
}

Describe 'W56 an approval followed by an instruction BLOCK - accepted at round 15, REVERSED by PRED-BETA4-022' {
    # Round-15 finding (DRIFT-199-I001-125, found live and then confirmed by the round): all three
    # authority recognizers collapse whitespace BEFORE deciding, so a paragraph break becomes an
    # ordinary space and a real approval followed by a multi-paragraph instruction block reads as
    # arbitrary prose after the phrase - refused, forcing the human to type a second, bare message.
    # The reviewer ruled it against FR-003/FR-010 and named the sibling site; rule 6 says prove the
    # fix against every FILE that carries a copy, so this matrix runs against all three.
    #
    # W56's rule: the approval lives on its OWN LINE, and what follows a line break is an instruction
    # block. PRED-BETA4-022 (B4F-065, maintainer ruling 2026-09-10) REVERSES the second half on a
    # measured cost: that exact rule minted a 136-line Copilot transcript from ANOTHER project, pasted
    # with the phrase at its top, as a live review-round approval in this repository - twice. A verdict
    # is ONE line: the phrase, plus at most the documented same-line instruction after a dash. What W56
    # removed - a SILENT refusal that forced a second bare message - stays removed by a different
    # means: the refusal now carries a reason, is journaled, and is said in the turn with the one-line
    # retype. The same-line refusals and the plain shapes below are exactly as round 14 left them.
    BeforeAll {
        . (Join-Path $script:RepoRoot 'extensions/specrew-speckit/scripts/shared-governance.ps1')
        $script:W56Recognizers = @(
            @{ Name = 'round-approval'; Phrase = 'approved for review round'; Fn = { param($t) (Test-SpecrewReviewRoundApprovalPhrase -Text $t).Matched }; Reason = { param($t) (Test-SpecrewReviewRoundApprovalPhrase -Text $t).Reason } }
            @{ Name = 'allowance-reset'; Phrase = 'approved for allowance reset'; Fn = { param($t) (Test-SpecrewAllowanceResetPhrase -Text $t).Matched }; Reason = { param($t) (Test-SpecrewAllowanceResetPhrase -Text $t).Reason } }
            @{ Name = 'coverage-deferral'; Phrase = 'continue without coverage until the review phase'; Fn = { param($t) (Test-SpecrewCoverageDeferralPhrase -Text $t).Matched }; Reason = { param($t) (Test-SpecrewCoverageDeferralPhrase -Text $t).Reason } }
        )
    }

    It 'REVERSED (PRED-BETA4-022): the phrase, a blank line, then an instruction block is refused BY REASON, in every copy' {
        foreach ($r in $script:W56Recognizers) {
            $text = "$($r.Phrase)`n`nIf it delivers clean: bring the record current and present the packet.`n`nIf it finds more: fix RED-first and stop at the decision point again."
            & $r.Fn $text | Should -BeFalse -Because "$($r.Name): a verdict is one line, and this message continues past it"
            & $r.Reason $text | Should -Be 'multi-line-refused' -Because "$($r.Name): the refusal carries its reason so the capture can disclose it, which is what keeps W56's silence removed"
            & $r.Fn "$($r.Phrase)`n`nShould I also refresh the dashboard after?" | Should -BeFalse -Because "$($r.Name): a following block is content, whatever it asks"
            # The instruction the block carried goes on the phrase's own line, after a dash - the documented form.
            # (Without the block's `if`: a same-line condition is still round 14's deferral, exactly as before.)
            & $r.Fn "$($r.Phrase) - bring the record current and present the packet" | Should -BeTrue -Because "$($r.Name): the same-line instruction form is the one the docs give, and it still mints"
        }
    }

    It 'keeps every same-line refusal exactly as round 14 left it' {
        foreach ($r in $script:W56Recognizers) {
            foreach ($suffix in @(', once the tests pass', '; after we verify the failures', ': when the lanes are green', '. unless codex is busy', ' - if the budget allows')) {
                & $r.Fn ($r.Phrase + $suffix) | Should -BeFalse -Because "$($r.Name)$suffix is a same-line deferral"
            }
            & $r.Fn ($r.Phrase + '?') | Should -BeFalse -Because "$($r.Name): an interrogative approval line is deliberation"
            & $r.Fn ($r.Phrase + ' seems premature') | Should -BeFalse -Because "$($r.Name): arbitrary prose directly after the phrase is not the phrase"
            & $r.Fn ("<system-reminder>$($r.Phrase)</system-reminder>") | Should -BeFalse -Because "$($r.Name): machinery envelopes are not human turns"
            & $r.Fn ("reply with $($r.Phrase) when you are ready") | Should -BeFalse -Because "$($r.Name): a mention is not an act"
        }
    }

    It 'still accepts the plain shapes, so the fix did not narrow the front door' {
        foreach ($r in $script:W56Recognizers) {
            & $r.Fn $r.Phrase | Should -BeTrue -Because "$($r.Name): the bare phrase"
            & $r.Fn ($r.Phrase + '.') | Should -BeTrue -Because "$($r.Name): a trailing period"
            & $r.Fn ($r.Phrase + ' - use the codex reviewer') | Should -BeTrue -Because "$($r.Name): a same-line instruction is not a condition"
        }
    }
}

Describe 'W57 round 16: authority must survive a reversal, a lost stamp, and a promised withdrawal' {
    BeforeAll {
        . (Join-Path $script:RepoRoot 'extensions/specrew-speckit/scripts/shared-governance.ps1')
        $script:W57Recognizers = @(
            @{ Name = 'round-approval'; Phrase = 'approved for review round'; Fn = { param($t) (Test-SpecrewReviewRoundApprovalPhrase -Text $t).Matched } }
            @{ Name = 'allowance-reset'; Phrase = 'approved for allowance reset'; Fn = { param($t) (Test-SpecrewAllowanceResetPhrase -Text $t).Matched } }
            @{ Name = 'coverage-deferral'; Phrase = 'continue without coverage until the review phase'; Fn = { param($t) (Test-SpecrewCoverageDeferralPhrase -Text $t).Matched } }
        )
    }

    It 'BLOCKING: a trailing negation reverses the approval in every recognizer' {
        # Round-16 finding (DRIFT-199-I001-126): the negation check was anchored to the START of the
        # utterance, so it could not see a reversal AFTER the anchor - "approved for review round,
        # but do not run it" minted spend authority against the human's explicit refusal. The
        # deferral scan already read the same-line tail; the negation scan now does too.
        foreach ($r in $script:W57Recognizers) {
            foreach ($suffix in @(', but do not run it', ' - do not actually run it', '; never mind', ': cancel that', ', actually stop', ' - hold off for now', ', withdraw that', '. do not proceed')) {
                & $r.Fn ($r.Phrase + $suffix) | Should -BeFalse -Because "$($r.Name)$suffix reverses the act"
            }
        }
    }

    It 'every condition the shared guard names defers the approval, in every recognizer (co-review round 6, iteration 002 of 202)' {
        # The coverage deferral kept its own six words, so 'continue without coverage until the review phase, provided the
        # security checks pass' was saved at once and silenced the coverage stop before the condition held.
        foreach ($r in $script:W57Recognizers) {
            foreach ($suffix in @(', once the tests pass', ', provided the security checks pass', ', providing the lanes pass', ', assuming the walk is clean',
                    ', contingent on the walk', ', subject to the walk', ', as long as the lanes pass', ', so long as nothing regresses', ', pending the walk')) {
                & $r.Fn ($r.Phrase + $suffix) | Should -BeFalse -Because "$($r.Name)$suffix states a condition"
            }
        }
    }

    It 'the reversal scan does not eat ordinary same-line instructions' {
        # The floor cuts one way, but it must not swallow the W44 shape it was built around.
        foreach ($r in $script:W57Recognizers) {
            & $r.Fn ($r.Phrase + ' - use the codex reviewer') | Should -BeTrue -Because "$($r.Name): a plain instruction"
            & $r.Fn ($r.Phrase + ', focus on the authority layer') | Should -BeTrue -Because "$($r.Name): a plain scope note"
        }
    }

    It 'BLOCKING: a workflow change is reviewable source, not a governance record' {
        # Round-16 finding: `.github/` was classified non-source WHOLESALE, so a commit touching only
        # .github/workflows/publish.yml read as records-only and signoff reused an older review of a
        # tree that never contained the executable change. The digest already treats workflows as
        # reviewable, so the two disagreed. Host-instruction and skill mirrors stay records.
        foreach ($p in @('.github/workflows/publish.yml', '.github/workflows/specrew-ci.yml', '.github/actions/setup/action.yml')) {
            Test-SpecrewReviewAuthorshipSourcePath -Path $p | Should -BeTrue -Because "$p is executable"
        }
        foreach ($p in @('.github/copilot-instructions.md', '.github/skills/specrew-review/SKILL.md', '.github/agents/squad.agent.md', '.github/prompts/x.prompt.md', '.specrew/config.yml', '.squad/team.md')) {
            Test-SpecrewReviewAuthorshipSourcePath -Path $p | Should -BeFalse -Because "$p is a record or a host mirror"
        }
    }

}


Describe 'W58 round 17: a claim about the frozen tree is checked, and a delivered round cannot be paid for twice' {
    BeforeAll { . (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/review-result-ingestor.ps1') }

    It 'BLOCKING: a declared path that is not in the frozen target does not buy source coverage' {
        # Round-17 finding (DRIFT-199-I001-127): nothing ever checked declared coverage against the
        # tree it claimed to describe. `examined_paths: ["src/nonexistent.cs"]` classified as source
        # by NAME, skipped the no-source degrade, and let a complete/pass result authorize a snapshot
        # whose code was never opened - the exact hollow-review shape W33 exists to catch, reachable
        # by a reviewer that simply names a file. Declared paths are now resolved inside the frozen
        # root; a path that identifies no file there counts as nothing.
        $root = Join-Path ([IO.Path]::GetTempPath()) ('w58-' + [guid]::NewGuid().ToString('N'))
        New-Item -ItemType Directory -Path (Join-Path $root 'src') -Force | Out-Null
        Set-Content -LiteralPath (Join-Path $root 'src/real.cs') -Value 'class R {}' -Encoding UTF8
        try {
            $declared = Resolve-ReviewDeclaredCoverage -Candidate ([pscustomobject]@{ examined_paths = @('src/nonexistent.cs') }) -TargetRoot $root
            @($declared.source_paths).Count | Should -Be 0 -Because 'a file that is not in the frozen tree was not examined in it'
            [bool]$declared.declared | Should -BeTrue -Because 'the reviewer did declare something; it just does not resolve'

            $real = Resolve-ReviewDeclaredCoverage -Candidate ([pscustomobject]@{ examined_paths = @('src/real.cs', 'src/nonexistent.cs') }) -TargetRoot $root
            @($real.source_paths).Count | Should -Be 1 -Because 'only the path that resolves counts'
            @($real.source_paths)[0] | Should -Be 'src/real.cs'

            # Windows-shaped and ./-prefixed declarations still resolve - a reviewer's spelling is not
            # the thing under test.
            $shapes = Resolve-ReviewDeclaredCoverage -Candidate ([pscustomobject]@{ examined_paths = @('.\src\real.cs') }) -TargetRoot $root
            @($shapes.source_paths).Count | Should -Be 1 -Because 'path spelling is normalized before resolution'

            # A traversal escape resolves to nothing: it is not IN the frozen root.
            $escape = Resolve-ReviewDeclaredCoverage -Candidate ([pscustomobject]@{ examined_paths = @('../outside/secret.cs') }) -TargetRoot $root
            @($escape.source_paths).Count | Should -Be 0 -Because 'a path outside the frozen root is not coverage of it'
        }
        finally { Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue }
    }

    It 'without a target root the classifier keeps its by-name behavior, so existing callers are unchanged' {
        # FAIL-OPEN on absence, the W33 precedent: a caller that cannot supply the frozen root gets
        # exactly today's answer rather than a fabricated degrade.
        $byName = Resolve-ReviewDeclaredCoverage -Candidate ([pscustomobject]@{ examined_paths = @('src/anything.cs') })
        @($byName.source_paths).Count | Should -Be 1
    }

}


Describe 'W61 round 19: ownership is joined through the grant, and the recovery path actually recovers' {
    BeforeAll {
        . (Join-Path $script:RepoRoot 'scripts/internal/bootstrap/HumanAuthorityStore.ps1')
        . (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/review-result-ingestor.ps1')

        function script:New-JoinFixture {
            # A campaign store shaped exactly like the live one: grant -> reservation -> run result.
            param([string]$AuthorizationRef, [string]$RunOutcome = 'completed', [string]$GrantId = 'grant-aaaa1111', [string]$Completion = 'complete')
            $root = Join-Path ([IO.Path]::GetTempPath()) ('w61-' + [guid]::NewGuid().ToString('N'))
            $campaign = 'cmp-fixture-i001'
            $base = Join-Path $root ".specrew/review/authority/campaigns/$campaign"
            New-Item -ItemType Directory -Path (Join-Path $base 'grants') -Force | Out-Null
            New-Item -ItemType Directory -Path (Join-Path $base "reservations/$GrantId/slot-001") -Force | Out-Null
            New-Item -ItemType Directory -Path (Join-Path $base 'runs/run-joined') -Force | Out-Null
            ([pscustomobject]@{ authority_kind = 'human'; authorization_ref = $AuthorizationRef; campaign_id = $campaign
                    fact_type = 'grant'; grant_id = $GrantId; observed_at = '2026-08-25T10:00:00.0000000+00:00'; schema_version = '1.0'; slots = 1 } |
                ConvertTo-Json -Compress) | Set-Content -LiteralPath (Join-Path $base "grants/$GrantId.json") -Encoding UTF8
            ([pscustomobject]@{ grant_id = $GrantId; run_id = 'run-joined'; schema_version = '1.0' } | ConvertTo-Json -Compress) |
                Set-Content -LiteralPath (Join-Path $base "reservations/$GrantId/slot-001/generation-001.json") -Encoding UTF8
            ([pscustomobject]@{ campaign_id = $campaign; run_id = 'run-joined'; runtime_outcome = $RunOutcome; completion = $Completion
                    started_at = '2026-08-25T10:05:00.0000000+00:00'; schema_version = '1.0' } | ConvertTo-Json -Compress) |
                Set-Content -LiteralPath (Join-Path $base 'runs/run-joined/result.json') -Encoding UTF8
            return [pscustomobject]@{ Root = $root; CampaignId = $campaign }
        }
    }

    It 'BLOCKING: declared coverage rejects traversal and absolute paths outright' {
        # Round-19 blocking finding: containment was a case-insensitive PREFIX test, so on a
        # case-sensitive volume a sibling root (/tmp/REVIEW next to /tmp/review) passed it, and `..`
        # components were never rejected. This volume is case-insensitive, so the sibling shape
        # cannot be built here honestly; the traversal rule is pinned BEHAVIORALLY (it closes the
        # described attack on every volume) and the volume-aware comparison STRUCTURALLY below.
        $root = Join-Path ([IO.Path]::GetTempPath()) ('w61-' + [guid]::NewGuid().ToString('N'))
        New-Item -ItemType Directory -Path (Join-Path $root 'src') -Force | Out-Null
        Set-Content -LiteralPath (Join-Path $root 'src/real.cs') -Value 'class R {}' -Encoding UTF8
        try {
            foreach ($p in @('../REVIEW/src/fake.cs', '..\sibling\src\fake.cs', 'src/../../escape/x.cs', '/etc/passwd.cs', 'C:\Windows\System32\evil.cs')) {
                $r = Resolve-ReviewDeclaredCoverage -Candidate ([pscustomobject]@{ examined_paths = @($p) }) -TargetRoot $root
                @($r.source_paths).Count | Should -Be 0 -Because "$p is not a repo-relative path inside the frozen root"
            }
            $ok = Resolve-ReviewDeclaredCoverage -Candidate ([pscustomobject]@{ examined_paths = @('src/real.cs') }) -TargetRoot $root
            @($ok.source_paths).Count | Should -Be 1 -Because 'an ordinary repo-relative path still counts'
        }
        finally { Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue }
    }

    It 'the containment test uses the volume-aware primitive, not a hard-coded case rule' {
        $src = Get-Content -LiteralPath (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/review-result-ingestor.ps1') -Raw -Encoding UTF8
        $fn = [regex]::Match($src, '(?s)function Resolve-ReviewDeclaredCoverage.+?\n\}').Value
        $fn | Should -Not -Match 'StartsWith\(\$prefix, \[StringComparison\]::OrdinalIgnoreCase\)' -Because 'the comparison must be SELECTED by the volume, never hard-coded at the call'
        $fn.Contains('Get-ContinuousCoReviewPathComparer') | Should -BeTrue -Because 'the primitive already exists in this engine'
    }
}


Describe 'W62 round 20: a condition defers every authority, and no pause choice mints a human without one' {
    BeforeAll {
        . (Join-Path $script:RepoRoot 'scripts/internal/bootstrap/ConversationCaptureAccessor.ps1')
        . (Join-Path $script:RepoRoot 'scripts/internal/bootstrap/HumanAuthorityStore.ps1')
    }

    It 'BLOCKING: "if" defers a BOUNDARY verdict, as it already defers every spend authority' {
        # Round-20 finding (DRIFT-199-I001-131): the spend recognizers were taught the full deferral
        # set in round 14 - later/after/once/when/unless/IF - and the BOUNDARY verdict recognizer,
        # in a different file, kept the five-word set. So `approved for tasks if the tests pass`
        # minted a boundary authorization immediately: the highest-stakes authority in the system,
        # crossed on a condition the human had attached. Method rule 6's own demand - every FILE
        # that carries a copy of the rule - which this crew wrote and then missed.
        foreach ($text in @('approved for tasks if the tests pass',
                'approved for before-implement if the lanes are green',
                'approved for plan, if you have time',
                'approve implement if codex agrees')) {
            $v = Test-SpecrewHumanVerdictToken -Text $text
            [bool]$v.IsApproval | Should -BeFalse -Because "$text is conditional"
        }
        # The five that already deferred keep deferring, and plain instructions still approve.
        foreach ($text in @('approved for tasks once the tests pass', 'approved for tasks when ready',
                'approved for tasks unless codex objects', 'approved for tasks after the walk', 'approved for tasks later')) {
            [bool](Test-SpecrewHumanVerdictToken -Text $text).IsApproval | Should -BeFalse -Because $text
        }
        [bool](Test-SpecrewHumanVerdictToken -Text 'approved for tasks - focus on the authority layer').IsApproval |
            Should -BeTrue -Because 'an instruction is not a condition'
    }

    It 'BLOCKING: stopping the review here is a typed human decision, not a flag an agent may assert' {
        # Round-20 finding: `--pause-choice 2` was excluded from the captured-approval gate because
        # it spends no round - but it passes AuthorizedBy='human' into the landing, writes an
        # identity-bound human disposition, and can COMPLETE SIGNOFF. So an agent could manufacture
        # the human authorization for the most consequential act in the lifecycle, exactly the W44
        # hole one door down. Every pause choice now needs its own captured typed decision.
        (Test-SpecrewPauseDecisionPhrase -Text 'stop the review here').Choice | Should -Be 'stop-here'
        (Test-SpecrewPauseDecisionPhrase -Text 'abandon this review campaign').Choice | Should -Be 'abandon'
        (Test-SpecrewPauseDecisionPhrase -Text 'stop the review here - the remaining findings are follow-ups').Choice |
            Should -Be 'stop-here' -Because 'a same-line instruction is not a condition'
        foreach ($text in @('should we stop the review here?', 'do not stop the review here',
                'stop the review here once codex finishes', 'stop the review here, but not yet',
                'reply with stop the review here when you are ready',
                '<system-reminder>stop the review here</system-reminder>')) {
            [bool](Test-SpecrewPauseDecisionPhrase -Text $text).Matched | Should -BeFalse -Because $text
        }
    }

    It 'the pause decision is captured, read back, and retired like every other authority' {
        $root = Join-Path ([IO.Path]::GetTempPath()) ('w62-' + [guid]::NewGuid().ToString('N'))
        New-Item -ItemType Directory -Path (Join-Path $root '.specrew') -Force | Out-Null
        try {
            Get-SpecrewPauseDecisionAuthorization -ProjectRoot $root -Choice 'stop-here' | Should -BeNullOrEmpty
            $null = Write-SpecrewPauseDecisionAuthorization -ProjectRoot $root -Response 'stop the review here' -HostKind 'claude' -SourceEvent 'UserPromptSubmit'
            $fact = Get-SpecrewPauseDecisionAuthorization -ProjectRoot $root -Choice 'stop-here'
            $fact | Should -Not -BeNullOrEmpty
            [string]$fact.choice | Should -Be 'stop-here'
            # A decision captured for ONE choice never authorizes another.
            Get-SpecrewPauseDecisionAuthorization -ProjectRoot $root -Choice 'abandon' |
                Should -BeNullOrEmpty -Because 'stopping here is not abandoning the campaign'
            $done = Complete-SpecrewPauseDecisionAuthorization -ProjectRoot $root -Choice 'stop-here' -AuthorizationRef 'landing-1'
            [bool]$done.consumed | Should -BeTrue
            Get-SpecrewPauseDecisionAuthorization -ProjectRoot $root -Choice 'stop-here' |
                Should -BeNullOrEmpty -Because 'a spent decision is not standing authority'
        }
        finally { Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue }
    }

    It 'the CLI gates every pause choice on a captured decision, not only the one that spends' {
        $cli = Get-Content -LiteralPath $script:ReviewCli -Raw -Encoding UTF8
        $cli.Contains('Get-SpecrewPauseDecisionAuthorization') | Should -BeTrue -Because 'choices 2 and 3 change signoff state and must carry the human'
        # The capture path must offer the human turn to the pause-decision writer, like every other authority.
        $handover = Get-Content -LiteralPath (Join-Path $script:RepoRoot 'scripts/internal/bootstrap/HandoverStore.ps1') -Raw -Encoding UTF8
        $handover.Contains('Write-SpecrewPauseDecisionAuthorization') | Should -BeTrue -Because 'a phrase nothing captures is a phrase nobody can type'
    }
}


Describe 'W63 round 21: the pause gate must actually run, be bound to its pause, and retire on every branch' {
    BeforeAll {
        . (Join-Path $script:RepoRoot 'scripts/internal/bootstrap/ConversationCaptureAccessor.ps1')
        . (Join-Path $script:RepoRoot 'scripts/internal/bootstrap/HumanAuthorityStore.ps1')
        # A fixture with a REAL pending pause: the decision gate correctly sits after "is a round
        # waiting for an answer?", because a decision cannot authorize an answer to a pause that
        # does not exist. Built with the engine's own writers so the shape is the shipped one.
        . (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/_load.ps1')
        function script:New-PendingPauseFixture {
            $root = New-CampaignFixture
            $store = Join-Path $root '.specrew/review/authority'
            $campaign = 'cmp-001-fixture-i001'
            $runId = 'run-20260825-000000000-abcdabcd'
            Request-ReviewAuthorityClaim -StoreRoot $store -CampaignId $campaign -RunId $runId -TargetLineage 'lin-fixture' -ObservedAt '2026-08-25T10:00:00Z' | Out-Null
            Publish-ReviewRunResultFact -StoreRoot $store -CampaignId $campaign -RunId $runId -Fact ([pscustomobject][ordered]@{
                    schema_version = '1.0'; campaign_id = $campaign; run_id = $runId; target_digest = 'digest-fixture'
                    harness_id = 'fixture'; completion = 'complete'; verdict = 'findings'; runtime_outcome = 'completed'
                    termination_verified = $true; containment = 'verified'; currentness = 'current'; validation = 'valid'
                    can_approve_current = $false; summary = 'one major'
                    findings = @([pscustomobject][ordered]@{ finding_id = 'finding-1'; source_local_id = 'l1'; lineage_id = 'lin-fixture'
                            severity = 'major'; title = 'A major'; description = 'Failure scenario: something concrete goes wrong.'
                            location = 'app.txt:1'; relevance = 'current'; resolution = 'open' })
                    started_at = '2026-08-25T10:00:00Z'; ended_at = '2026-08-25T10:05:00Z'; duration_ms = 300000
                }) | Out-Null
            Write-ReviewCampaignPendingPauseFact -StoreRoot $store -Fact ([pscustomobject][ordered]@{
                    schema_version = '1.0'; fact_type = 'pending-pause'; campaign_id = $campaign; run_id = $runId
                    target_digest = 'digest-fixture'; blocking_count = 0; major_count = 1; minor_count = 0
                    demoted_count = 0; rounds_used = 1; budget_total = 4; elapsed_minutes = 5.0
                    recommendation = 'Look at the major findings.'; observed_at = '2026-08-25T10:06:00.0000000+00:00'
                }) | Out-Null
            return $root
        }
    }

    It 'ACCEPTANCE: an agent relaying pause-choice 2 with no captured decision is refused, through the real CLI' {
        # Round-21 finding, named by the reviewer only in passing ("after the load-path defect is
        # fixed"): the round-20 gate was UNREACHABLE. HumanAuthorityStore is dot-sourced only when
        # $roundApprovalRequested is true - that is --approve-round or pause-choice 1 - so for
        # choices 2 and 3 the store never loaded, every Get-Command guard failed, and the gate that
        # was supposed to stop an agent manufacturing sign-off was skipped entirely. A control that
        # exists and never executes: the class this project already has a method rule about, and the
        # reason this case drives the SHIPPED CLI rather than the function.
        # Feature 203 T008 (maintainer classification 2026-11-09, class B): option 2 is `--pause-choice stop-here` now, the
        # one relay left; the same gate refuses it with no captured decision.
        $root = New-PendingPauseFixture
        try {
            $run = Invoke-ReviewCli -Root $root -Context 'agent' -CliArgs @('--pause-choice', 'stop-here')
            $run.Text | Should -Match 'no decision from them has been captured'
            $run.Text | Should -Match 'stop the review here'
            $run.ExitCode | Should -Be 1
        }
        finally { Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue }
    }

    It 'ACCEPTANCE: abandoning is gated the same way, and names its own phrase' {
        # Feature 203 T008 (maintainer classification 2026-11-09, class A; abandon retired by the 2026-11-09 mapping): there is
        # no abandon to gate. --pause-choice 3 is refused in plain words, names the one answer left, and records nothing.
        $root = New-PendingPauseFixture
        try {
            $run = Invoke-ReviewCli -Root $root -Context 'agent' -CliArgs @('--pause-choice', '3')
            $run.Text | Should -Match 'no longer exists'
            $run.Text | Should -Match 'stop the review here'
            $run.Text | Should -Match '(?i)nothing was recorded'
            @(Get-ChildItem -LiteralPath $root -Recurse -Filter 'pause-decision.json' -ErrorAction SilentlyContinue).Count | Should -Be 0
            $run.ExitCode | Should -Be 1
        }
        finally { Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue }
    }

    It 'a captured decision is bound to the pause it answers, not to the project forever' {
        # Round-21 finding: the fact carried only the choice, so a phrase typed in an unrelated
        # conversation - or against a campaign that closed weeks ago - became a standing project-wide
        # capability an agent could apply to whatever pause happened to be current. A decision
        # answers ONE pending pause.
        $root = Join-Path ([IO.Path]::GetTempPath()) ('w63-' + [guid]::NewGuid().ToString('N'))
        New-Item -ItemType Directory -Path (Join-Path $root '.specrew') -Force | Out-Null
        try {
            # No pause pending: a decision typed now answers nothing and must not be standing authority.
            $orphan = Write-SpecrewPauseDecisionAuthorization -ProjectRoot $root -Response 'stop the review here' -HostKind 'claude' -SourceEvent 'UserPromptSubmit'
            $orphan | Should -Not -BeNullOrEmpty -Because 'the human did type it; the record is honest about what it answers'
            [string]$orphan.run_id | Should -BeNullOrEmpty
            Get-SpecrewPauseDecisionAuthorization -ProjectRoot $root -Choice 'stop-here' -RunId 'run-current' |
                Should -BeNullOrEmpty -Because 'a decision bound to no pause cannot answer this one'

            # With a pause pending, the capture binds to that run and answers only it.
            $campaign = 'cmp-fixture-i001'
            $pauseDir = Join-Path $root ".specrew/review/authority/campaigns/$campaign/runs/run-current"
            New-Item -ItemType Directory -Path $pauseDir -Force | Out-Null
            ([pscustomobject]@{ schema_version = '1.0'; fact_type = 'pending-pause'; campaign_id = $campaign
                    run_id = 'run-current'; target_digest = 'digest-1'; blocking_count = 0; major_count = 1
                    minor_count = 0; demoted_count = 0; rounds_used = 1; budget_total = 4; elapsed_minutes = 5.0
                    recommendation = 'Look at the major findings.'; observed_at = '2026-08-25T10:00:00.0000000+00:00' } |
                ConvertTo-Json -Compress) | Set-Content -LiteralPath (Join-Path $pauseDir 'pending-pause.json') -Encoding UTF8

            $bound = Write-SpecrewPauseDecisionAuthorization -ProjectRoot $root -Response 'stop the review here' -HostKind 'claude' -SourceEvent 'UserPromptSubmit'
            [string]$bound.run_id | Should -Be 'run-current'
            [string]$bound.campaign_id | Should -Be $campaign
            Get-SpecrewPauseDecisionAuthorization -ProjectRoot $root -Choice 'stop-here' -RunId 'run-current' |
                Should -Not -BeNullOrEmpty
            Get-SpecrewPauseDecisionAuthorization -ProjectRoot $root -Choice 'stop-here' -RunId 'run-somewhere-else' |
                Should -BeNullOrEmpty -Because 'this decision answered a different round'
        }
        finally { Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue }
    }

    It 'the abandon branch retires its decision too, so it cannot answer a later campaign' {
        # Round-21 finding: only the stop-here branch consumed the authorization; abandoning wrote
        # the immutable pause decision and exited, leaving the captured phrase unspent and reusable.
        $cli = Get-Content -LiteralPath $script:ReviewCli -Raw -Encoding UTF8
        ([regex]::Matches($cli, [regex]::Escape('Complete-SpecrewPauseDecisionAuthorization'))).Count |
            Should -BeGreaterOrEqual 2 -Because 'both landings that use a decision must retire it'
    }

    It 'BLOCKING-CLASS: a conditional wearing a modifier still defers' {
        # Round-21 finding: the round-20 post-delimiter check matched a conditional only at the very
        # START of the tail, so the commonest English forms - "only if", "but only if" - sailed
        # through with a clean pre-comma clause. Modifiers before the conjunction do not make the
        # condition stop being one.
        foreach ($text in @('approved for plan, only if the tests pass',
                'approved for plan, but only if the tests pass',
                'approved for tasks - but only when codex agrees',
                'approved for implement, just once the lanes are green',
                'approved for plan; and only after the walk')) {
            [bool](Test-SpecrewHumanVerdictToken -Text $text).IsApproval | Should -BeFalse -Because $text
        }
        # And the instruction forms this must not eat keep approving.
        foreach ($text in @('approved for tasks, and send back the draft doc when you are done',
                'approved for plan. changes needed in the README are noted for later',
                'approved for implement. should I also update the changelog?',
                'approved for before-implement - then discuss prompt 2 with me')) {
            [bool](Test-SpecrewHumanVerdictToken -Text $text).IsApproval | Should -BeTrue -Because $text
        }
    }
}


Describe 'W64 round 22: authority machinery fails CLOSED, proven on a damaged installation' {
    # Round-22 finding (DRIFT-199-I001-133): every authority-bearing path loads the store inside a
    # swallowed catch and then runs its gate only if the functions "happen to exist". A missing,
    # unreadable or broken HumanAuthorityStore therefore did not refuse - it DISABLED the gate, and
    # an agent-supplied flag could replenish spend, launch a paid round, abandon a campaign, or
    # complete sign-off with AuthorizedBy='human' and no captured human anywhere. The generalization
    # of round 21's unreachable gate: there, one path could not load the store; here, none of them
    # cared whether it loaded.
    #
    # PROVEN ON A DAMAGED INSTALLATION, not on the function. Round 21's lesson was that a
    # function-level test passes against a gate a consumer never reaches, so this copies the shipped
    # scripts tree, deletes the authority store from the copy, and runs the copied CLI exactly as a
    # consumer would.
    BeforeAll {
        . (Join-Path $script:RepoRoot 'scripts/internal/bootstrap/HumanAuthorityStore.ps1')
        . (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/_load.ps1')

        $script:DamagedRoot = Join-Path ([IO.Path]::GetTempPath()) ('w64-install-' + [guid]::NewGuid().ToString('N'))
        New-Item -ItemType Directory -Path $script:DamagedRoot -Force | Out-Null
        # The CLI resolves shared governance from its PARENT, so a faithful installation copy needs
        # the sibling tree too - discovered by the first run of this case, which died at startup
        # instead of reaching the gate under test.
        Copy-Item -LiteralPath (Join-Path $script:RepoRoot 'scripts') -Destination (Join-Path $script:DamagedRoot 'scripts') -Recurse -Force
        Copy-Item -LiteralPath (Join-Path $script:RepoRoot 'extensions') -Destination (Join-Path $script:DamagedRoot 'extensions') -Recurse -Force
        Remove-Item -LiteralPath (Join-Path $script:DamagedRoot 'scripts/internal/bootstrap/HumanAuthorityStore.ps1') -Force
        $script:DamagedCli = Join-Path $script:DamagedRoot 'scripts/specrew-review.ps1'

        function script:Invoke-DamagedCli {
            param([Parameter(Mandatory)][string]$Root, [Parameter(Mandatory)][string[]]$CliArgs)
            $command = "`$env:CLAUDECODE = '1'; pwsh -NoProfile -File '" + $script:DamagedCli + "' -ProjectPath '" + $Root + "' -FeatureId 001-fixture --live " + ($CliArgs -join ' ') + "; exit `$LASTEXITCODE"
            $output = @(& pwsh -NoProfile -Command $command 2>&1 | ForEach-Object { [string]$_ })
            return [pscustomobject]@{ ExitCode = $LASTEXITCODE; Text = ($output -join "`n") }
        }
    }
    AfterAll { Remove-Item -LiteralPath $script:DamagedRoot -Recurse -Force -ErrorAction SilentlyContinue }

    It 'ACCEPTANCE: a damaged installation refuses to replenish the allowance' {
        $root = New-CampaignFixture
        try {
            $run = Invoke-DamagedCli -Root $root -CliArgs @('--remediate', 'allowance-reset', '--ack-reason', '"because"')
            $run.ExitCode | Should -Be 1
            $run.Text | Should -Match '(?i)cannot check'
            $run.Text | Should -Not -Match '(?i)topped up' -Because 'replenishing spend authority is authority-bearing'
        }
        finally { Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue }
    }

    It 'ACCEPTANCE: a damaged installation refuses to stop the review, which would complete sign-off' {
        # A REAL pending pause: the assertion fires when the CLI is about to take an
        # authority-bearing action, and with no pause waiting there is no action to take - refusing
        # with "cannot check authority" there would be a confusing answer to a different question.
        # Feature 203 T008 (maintainer classification 2026-11-09, class B): through `--pause-choice stop-here`, the one relay left.
        $root = New-PendingPauseFixture
        try {
            $run = Invoke-DamagedCli -Root $root -CliArgs @('--pause-choice', 'stop-here')
            $run.ExitCode | Should -Be 1
            $run.Text | Should -Match '(?i)cannot check'
            $run.Text | Should -Not -Match '(?i)sign-off is complete'
        }
        finally { Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue }
    }

    It 'the refusal names what is wrong and what to do, without blaming the human' {
        $root = New-CampaignFixture
        try {
            $run = Invoke-DamagedCli -Root $root -CliArgs @('--remediate', 'allowance-reset', '--ack-reason', '"because"')
            $run.Text | Should -Match '(?i)specrew update'
            $run.Text | Should -Match '(?i)nothing (was|has been) (spent|recorded)'
        }
        finally { Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue }
    }

    It 'an unknown session context is treated as an agent session, not as a human at a terminal' {
        # The other half of the fail-open structure: when the session-detection function is absent,
        # the CLI assumed "not an agent" - the reading that REMOVES the requirement for a captured
        # phrase. Absent evidence about who is invoking must mean the conservative answer.
        $cli = Get-Content -LiteralPath $script:ReviewCli -Raw -Encoding UTF8
        $cli | Should -Not -Match '\$insideAgentSession = \$false' -Because 'unknown context must default to requiring the human, not to trusting the caller'
        $cli | Should -Not -Match '\$insideAgentSessionReset = \$false' -Because 'the allowance-reset path shares the rule'
    }
}


Describe 'W65 round 23: a PARTIAL authority store is a damaged one, and every fact file is classified' {
    # Round-23 finding (DRIFT-199-I001-134): the round-22 readiness assertion checked only the two
    # functions its own gate calls, while the same path later relies on the mint stamp, the
    # ownership join, the entitlement resolver and the consumption - each behind an optional
    # Get-Command branch. A partially deployed or validly TRUNCATED older store keeps the two
    # checked functions and lacks the rest: the reviewer launches, the approval is never linked and
    # never consumed, and a later invocation spends again. The allowance-reset assertion had the
    # same gap around its consumption.
    #
    # AND THE FIXTURE COULD NOT HAVE SEEN IT: round 22's damaged installation deletes the WHOLE
    # store, so every function vanishes together and the partial case never arises. Method rule 5,
    # arriving against a fixture this crew wrote one round earlier - so this one truncates the store
    # at a function boundary, which is exactly what an older deployed copy looks like.
    BeforeAll {
        . (Join-Path $script:RepoRoot 'scripts/internal/bootstrap/HumanAuthorityStore.ps1')
        . (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/_load.ps1')

        function script:New-PartialInstallation {
            # Copy the shipped trees, then CUT the store at a named function - every function above
            # the cut survives, everything from it down is gone. A truncated older store, verbatim.
            param([Parameter(Mandatory)][string]$CutAtFunction)
            $installRoot = Join-Path ([IO.Path]::GetTempPath()) ('w65-install-' + [guid]::NewGuid().ToString('N'))
            New-Item -ItemType Directory -Path $installRoot -Force | Out-Null
            Copy-Item -LiteralPath (Join-Path $script:RepoRoot 'scripts') -Destination (Join-Path $installRoot 'scripts') -Recurse -Force
            Copy-Item -LiteralPath (Join-Path $script:RepoRoot 'extensions') -Destination (Join-Path $installRoot 'extensions') -Recurse -Force
            $storePath = Join-Path $installRoot 'scripts/internal/bootstrap/HumanAuthorityStore.ps1'
            $text = Get-Content -LiteralPath $storePath -Raw -Encoding UTF8
            $cutAt = $text.IndexOf("function $CutAtFunction")
            if ($cutAt -lt 0) { throw "cut point not found: $CutAtFunction" }
            Set-Content -LiteralPath $storePath -Value $text.Substring(0, $cutAt) -Encoding UTF8 -NoNewline
            return $installRoot
        }

        function script:Invoke-InstallationCli {
            param([Parameter(Mandatory)][string]$InstallRoot, [Parameter(Mandatory)][string]$Root, [Parameter(Mandatory)][string[]]$CliArgs)
            $cli = Join-Path $InstallRoot 'scripts/specrew-review.ps1'
            $command = "`$env:CLAUDECODE = '1'; pwsh -NoProfile -File '" + $cli + "' -ProjectPath '" + $Root + "' -FeatureId 001-fixture --live " + ($CliArgs -join ' ') + "; exit `$LASTEXITCODE"
            $output = @(& pwsh -NoProfile -Command $command 2>&1 | ForEach-Object { [string]$_ })
            return [pscustomobject]@{ ExitCode = $LASTEXITCODE; Text = ($output -join "`n") }
        }
    }

    It 'the readiness sets name every authority function their own path calls' {
        # Structural, and deliberately mechanical: the assertion must not drift behind the code it
        # protects. Each required set is compared against the functions that path actually guards.
        $cli = Get-Content -LiteralPath $script:ReviewCli -Raw -Encoding UTF8
        # Feature 203 T008: the round path is gone with the per-round approval; the reset and stop paths remain.
        $cli | Should -Not -Match "Assert-SpecrewAuthorityMachineryReady -Action 'approve a review round'"
        $cli | Should -Match "(?s)Assert-SpecrewAuthorityMachineryReady -Action 'replenish the review rounds'.{0,600}?Complete-SpecrewAllowanceResetAuthorization" -Because 'the reset path consumes its own capture'
    }

    It 'BLOCKING-CLASS: an enumerated fact file that redirects elsewhere is refused, not followed' {
        # Round-23 finding: the store checks its ROOT and the requested parent for links, then
        # enumerates child JSON files and hands each absolute path straight to the reader. A
        # symlinked fact file under an ordinary directory was therefore followed and its external
        # target accepted after contract validation - the store's stated refusal of redirecting
        # paths applied to directories only.
        $root = Join-Path ([IO.Path]::GetTempPath()) ('w65-store-' + [guid]::NewGuid().ToString('N'))
        $store = Join-Path $root '.specrew/review/authority'
        $outside = Join-Path $root 'outside'
        New-Item -ItemType Directory -Path $outside -Force | Out-Null
        $campaign = 'cmp-link-i001'
        $grantsDir = Join-Path $store "campaigns/$campaign/grants"
        New-Item -ItemType Directory -Path $grantsDir -Force | Out-Null
        try {
            $foreign = Join-Path $outside 'foreign-grant.json'
            ([pscustomobject]@{ authority_kind = 'human'; authorization_ref = 'cmp-link-i001-round-9'; campaign_id = $campaign
                    fact_type = 'grant'; grant_id = 'grant-forged1'; observed_at = '2026-08-25T10:00:00.0000000+00:00'
                    schema_version = '1.0'; slots = 1 } | ConvertTo-Json -Compress) | Set-Content -LiteralPath $foreign -Encoding UTF8
            $link = Join-Path $grantsDir 'grant-forged1.json'
            $made = $true
            try { New-Item -ItemType SymbolicLink -Path $link -Target $foreign -ErrorAction Stop | Out-Null }
            catch { $made = $false }
            if (-not $made) { Set-ItResult -Skipped -Because 'this machine does not allow creating symlinks without elevation; the containment rule is pinned structurally below' }
            else {
                Test-ReviewAuthorityFactPathContained -Path $link | Should -BeFalse -Because 'a fact file that redirects out of the store is not a fact of this store'
                $plain = Join-Path $grantsDir 'grant-real.json'
                Copy-Item -LiteralPath $foreign -Destination $plain -Force
                Test-ReviewAuthorityFactPathContained -Path $plain | Should -BeTrue -Because 'an ordinary file inside the store is fine'
            }
        }
        finally { Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue }
    }

    It 'the ONE reader classifies the file, so every enumeration inherits the rule' {
        # The module states that every read, write and enumeration resolves through one function,
        # and that hardening it there covers the module rather than each call site. The file-level
        # rule belongs in the same place: classified inside the reader, so an enumeration added
        # later cannot forget it - which is how this defect happened, with directory containment
        # hardened at the choke point and file containment left to the callers.
        $storeSource = Get-Content -LiteralPath (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/review-authority-store.ps1') -Raw -Encoding UTF8
        $storeSource.Contains('function Test-ReviewAuthorityFactPathContained') | Should -BeTrue -Because 'the containment rule needs a name to be reused'
        $reader = [regex]::Match($storeSource, '(?s)function Read-ReviewAuthorityFactFile.{0,3000}?\n\}').Value
        $reader | Should -Not -BeNullOrEmpty
        $reader.Contains('Test-ReviewAuthorityFactPathContained') | Should -BeTrue -Because 'the file is classified before it is opened, at the point every caller passes through'
    }
}


Describe 'W66 round 24: one routing table for typed authority, a durable mint, and a reset that cannot be reused' {
    # Round 24 found the pause decisions missing from the Stop transcript backstop. The defect under
    # that finding is older and larger: the two capture branches - prompt-entry and the Stop backstop -
    # each carried their own hand-copied list of authority writers, and the lists had silently
    # diverged - a rule enforced at each call site instead of at the one place every caller passes
    # through, the same shape as the path comparer and the fact-file classifier before it. So these
    # cases pin the ROUTER, not the copies.

    BeforeAll {
        function script:New-StopCaptureRoot {
            $root = Join-Path ([IO.Path]::GetTempPath()) ('w66-' + [guid]::NewGuid().ToString('N'))
            New-Item -ItemType Directory -Path (Join-Path $root '.specrew') -Force | Out-Null
            return $root
        }

        function script:Invoke-StopCapture {
            param([Parameter(Mandatory)][string]$Root, [Parameter(Mandatory)][string]$HumanText)
            $tp = Join-Path $Root 'transcript.jsonl'
            # Feature 203 T004 (FR-015): Claude's human entry carries its promptId and origin, as Claude records them. The id is
            # derived from the text, so re-reading the same text is the same message and a different text a new one.
            $promptId = 'prompt-' + (Get-SpecrewHumanAuthorityHash -Text $HumanText).Substring(0, 12)
            $line = '{"type":"user","promptId":"' + $promptId + '","origin":{"kind":"human"},"message":{"role":"user","content":[{"type":"text","text":"' + $HumanText + '"}]}}'
            [IO.File]::WriteAllLines($tp, [string[]]@($line), [Text.UTF8Encoding]::new($false))
            $repo = $script:RepoRoot
            # A CHILD process, so the writers one pass loads cannot leak into the next case.
            $lines = @(
                'Set-StrictMode -Version Latest'
                ". '$repo/scripts/internal/bootstrap/ConversationCaptureAccessor.ps1'"
                ". '$repo/scripts/internal/bootstrap/ClassificationEngine.ps1'"
                ". '$repo/scripts/internal/bootstrap/ProjectMetadataAccessor.ps1'"
                ". '$repo/scripts/internal/bootstrap/HumanAuthorityStore.ps1'"
                ". '$repo/scripts/internal/bootstrap/HandoverStore.ps1'"
                "Update-SpecrewRollingHandover -ProjectRoot '$Root' -TranscriptPath '$tp' -Source 'Stop' | Out-Null"
            )
            & pwsh -NoProfile -Command ($lines -join '; ') 2>&1 | Out-Null
        }
    }

    It 'RED-FIRST: a typed pause decision arriving only at Stop is captured, on the host this backstop exists for' {
        # THE FINDING. On claude the prompt event may carry no text at all - which is why the Stop
        # backstop exists - so a human who typed `stop the review here` was never recorded, and every
        # later `--pause-choice 2` refused forever. The human decided; the machinery could not see it.
        $root = New-StopCaptureRoot
        try {
            # PRECONDITION FIRST (appendix rule: a test asserts its own precondition). If this control
            # does not capture, the fixture's transcript shape is wrong and the case below would pass
            # or fail for reasons that have nothing to do with pause decisions.
            Invoke-StopCapture -Root $root -HumanText 'approved for allowance reset'
            Get-SpecrewAllowanceResetAuthorization -ProjectRoot $root |
                Should -Not -BeNullOrEmpty -Because 'the fixture must be a transcript the Stop backstop actually reads'

            Invoke-StopCapture -Root $root -HumanText 'stop the review here'
            $decision = Get-SpecrewPauseDecisionAuthorization -ProjectRoot $root -Choice 'stop-here'
            $decision | Should -Not -BeNullOrEmpty -Because 'a decision the human typed must reach the store on every supported host'
        }
        finally { Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue }
    }

    It 'the router carries EVERY typed-authority writer the store defines, so a new one cannot be half-wired' {
        # DERIVED, not enumerated: the expectation is read from the writers that exist, so adding an
        # authority writer and forgetting the router fails here rather than on a human's host.
        $sources = @(
            Join-Path $script:RepoRoot 'scripts/internal/bootstrap/HumanAuthorityStore.ps1'
            Join-Path $script:RepoRoot 'extensions/specrew-speckit/scripts/shared-governance.ps1'
            Join-Path $script:RepoRoot 'extensions/specrew-speckit/scripts/workshop-authority-store.ps1'
        )
        $expected = [Collections.Generic.List[string]]::new()
        foreach ($source in $sources) {
            $tokens = $null; $errors = $null
            $ast = [System.Management.Automation.Language.Parser]::ParseFile($source, [ref]$tokens, [ref]$errors)
            foreach ($fn in $ast.FindAll({ param($n) $n -is [System.Management.Automation.Language.FunctionDefinitionAst] }, $true)) {
                if ($fn.Name -notmatch '^Write-Specrew.*(Authorization|Withdrawal)$') { continue }
                if ($null -eq $fn.Body.ParamBlock) { continue }
                $names = @($fn.Body.ParamBlock.Parameters | ForEach-Object { $_.Name.VariablePath.UserPath })
                # The typed-phrase shape: it takes a human's words and the event they arrived on.
                if (@('ProjectRoot', 'Response', 'HostKind', 'SourceEvent' | Where-Object { $_ -notin $names }).Count -gt 0) { continue }
                $expected.Add($fn.Name) | Out-Null
            }
        }
        $expected.Count | Should -BeGreaterThan 4 -Because 'precondition: the scan must actually find the writers'
        $handover = Get-Content -LiteralPath (Join-Path $script:RepoRoot 'scripts/internal/bootstrap/HandoverStore.ps1') -Raw -Encoding UTF8
        $router = [regex]::Match($handover, '(?s)function Invoke-SpecrewTypedAuthorityCapture.*?\r?\n\}').Value
        $router | Should -Not -BeNullOrEmpty -Because 'both branches must route through one named table'
        foreach ($writer in $expected) {
            $router.Contains($writer) | Should -BeTrue -Because ($writer + " takes a human's typed words and must be offered them on every host")
        }
    }

    It 'neither capture branch keeps its own copy of the list' {
        $handover = Get-Content -LiteralPath (Join-Path $script:RepoRoot 'scripts/internal/bootstrap/HandoverStore.ps1') -Raw -Encoding UTF8
        $outsideRouter = [regex]::Replace($handover, '(?s)function Invoke-SpecrewTypedAuthorityCapture.*?\r?\n\}', '')
        $direct = @([regex]::Matches($outsideRouter, '(?m)^\s*(Write-Specrew\w*(?:Authorization|Withdrawal))\s+-ProjectRoot') |
                ForEach-Object { $_.Groups[1].Value })
        $direct | Should -BeNullOrEmpty -Because 'a hand-copied call site is how the two branches diverged in the first place'
        ([regex]::Matches($handover, 'Invoke-SpecrewTypedAuthorityCapture\s+-ProjectRoot')).Count |
            Should -BeGreaterOrEqual 2 -Because 'prompt-entry and the Stop backstop are both capture branches'
    }

    It 'RED-FIRST: allowance-reset consumption reports its outcome and verifies its own stamp' {
        $root = New-StopCaptureRoot
        $handle = $null
        try {
            $null = Write-SpecrewAllowanceResetAuthorization -ProjectRoot $root -Response 'approved for allowance reset' -HostKind 'claude' -SourceEvent 'UserPromptSubmit'
            $path = Join-Path $root '.specrew/review/allowance-reset/pending-allowance-reset.json'
            [IO.File]::Exists($path) | Should -BeTrue -Because 'precondition: there must be a capture to consume'
            $handle = [IO.File]::Open($path, [IO.FileMode]::Open, [IO.FileAccess]::ReadWrite, [IO.FileShare]::Read)
            $blocked = Complete-SpecrewAllowanceResetAuthorization -ProjectRoot $root -Reference 'reset-1'
            [bool]$blocked.consumed | Should -BeFalse -Because 'a swallowed failure that returns nothing is indistinguishable from success'
            [string]$blocked.reason | Should -Not -BeNullOrEmpty
            $handle.Dispose(); $handle = $null
            $ok = Complete-SpecrewAllowanceResetAuthorization -ProjectRoot $root -Reference 'reset-1'
            [bool]$ok.consumed | Should -BeTrue
            Get-SpecrewAllowanceResetAuthorization -ProjectRoot $root |
                Should -BeNullOrEmpty -Because 'a spent approval is not standing authority'
        }
        finally {
            if ($null -ne $handle) { $handle.Dispose() }
            Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    It 'a write that reports success but changes nothing is NOT a consumption' {
        # THE READ-BACK'S OWN CASE. The locked-file case above proves only the throwing branch: the
        # first cut of this suite deleted the whole `stamp-not-durable` check and stayed green, which
        # is the inert-control class this feature has now hit six times. A silent no-op writer is the
        # shape that branch exists for - it succeeds, and nothing changed.
        $root = New-StopCaptureRoot
        try {
            $null = Write-SpecrewAllowanceResetAuthorization -ProjectRoot $root -Response 'approved for allowance reset' -HostKind 'claude' -SourceEvent 'UserPromptSubmit'
            function Write-SpecrewFileAtomic { param([string]$Path, [string]$Content) }
            $result = Complete-SpecrewAllowanceResetAuthorization -ProjectRoot $root -Reference 'reset-2'
            [bool]$result.consumed | Should -BeFalse -Because 'the stamp must be readable back before the approval counts as spent'
            [string]$result.reason | Should -Be 'stamp-not-durable'
            Get-SpecrewAllowanceResetAuthorization -ProjectRoot $root |
                Should -Not -BeNullOrEmpty -Because 'nothing was written, so the human still holds their approval'
        }
        finally { Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue }
    }

    It 'RED-FIRST: an approval whose reset already landed cannot buy a second one, and a freshly typed phrase still can' {
        # The derived guard, mirroring W61: ownership is answered from the facts the store published,
        # not from a marker that can also fail. A reset recorded at or after the capture is the
        # evidence that THIS capture already paid - so a lost stamp cannot replenish twice.
        $root = New-StopCaptureRoot
        try {
            # FIXED INSTANTS, all in the past: the first cut of this case put the landed reset five
            # seconds in the FUTURE and then compared it against a re-typed phrase stamped with the
            # wall clock, so it measured how fast the test ran rather than what it claims to measure.
            $t0 = [DateTimeOffset]::UtcNow.AddMinutes(-10)
            $capture = Write-SpecrewAllowanceResetAuthorization -ProjectRoot $root -Response 'approved for allowance reset' `
                -HostKind 'claude' -SourceEvent 'UserPromptSubmit' -NowUtc ($t0.ToString('o'))
            $campaign = 'cmp-w66-i001'
            $resets = Join-Path $root ('.specrew/review/authority/campaigns/' + $campaign + '/budget-resets')
            New-Item -ItemType Directory -Path $resets -Force | Out-Null
            $landedAt = $t0.AddMinutes(1).ToString('o')
            ([pscustomobject]@{ schema_version = '1.0'; fact_type = 'round-budget-reset'; authority_kind = 'human'
                    campaign_id = $campaign; reset_id = 'reset-landed-1'; authorized_by = 'alon'
                    reason = 'more rounds'; observed_at = $landedAt } | ConvertTo-Json -Compress) |
                Set-Content -LiteralPath (Join-Path $resets 'reset-landed-1.json') -Encoding UTF8

            Get-SpecrewLandedResetForAllowanceCapture -ProjectRoot $root -CampaignId $campaign -CaptureObservedAt ([string]$capture.observed_at) |
                Should -Not -BeNullOrEmpty -Because 'the reset landed after this capture, so this capture is what paid for it'

            # And the recovery must actually recover: once the stale capture is retired, the human's
            # freshly typed phrase writes a NEW fact that the guard leaves alone. A guard that wedges
            # the re-typed phrase is the W61 mistake repeated.
            $null = Complete-SpecrewAllowanceResetAuthorization -ProjectRoot $root -Reference 'reset-landed-1'
            $fresh = Write-SpecrewAllowanceResetAuthorization -ProjectRoot $root -Response 'approved for allowance reset' `
                -HostKind 'claude' -SourceEvent 'UserPromptSubmit' -NowUtc ($t0.AddMinutes(2).ToString('o'))
            ([DateTimeOffset]::Parse([string]$fresh.observed_at)) |
                Should -BeGreaterThan ([DateTimeOffset]::Parse($landedAt)) -Because 'a re-typed phrase is a new act, not the old one resurrected'
            Get-SpecrewLandedResetForAllowanceCapture -ProjectRoot $root -CampaignId $campaign -CaptureObservedAt ([string]$fresh.observed_at) |
                Should -BeNullOrEmpty -Because 'no reset has landed since the human typed it again'
        }
        finally { Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue }
    }
}

Describe 'W68 round 25: a withdrawal that cannot delete still revokes, and a pause decision binds to a LIVE pause' {
    # Round 25 (the first round to cover this tree) returned both of these as major; the engine demoted
    # them to minor for want of a concrete failure scenario. The maintainer had ruled one round earlier
    # that a withdrawal failing open is the most severe class this system has - and finding 1 is that
    # class, in the router DRIFT-199-I001-138 introduced. I closed the capture gap there and left the
    # CONSUMPTION of the writer's result open, which is the report-don't-control shape this file has now
    # been corrected for four times.

    It 'RED-FIRST: a pause decision does not bind to an ALREADY-ANSWERED pause from another campaign' {
        # The reported wedge: the identity reader scans every pending-pause.json in the project and
        # takes the newest observed_at, without excluding pauses that already carry a sibling
        # pause-decision.json - which the canonical Get-ReviewCampaignPendingPause reader does exclude.
        # So a newer ANSWERED campaign captures the phrase, the CLI rejects it for the genuinely
        # outstanding run, and retyping repeats the same wrong binding. Two readers of one question,
        # for the fourth time in this feature.
        $root = Join-Path ([IO.Path]::GetTempPath()) ('w68-pause-' + [guid]::NewGuid().ToString('N'))
        New-Item -ItemType Directory -Path (Join-Path $root '.specrew') -Force | Out-Null
        try {
            $t0 = [DateTimeOffset]::UtcNow.AddHours(-2)
            $campaigns = Join-Path $root '.specrew/review/authority/campaigns'
            # OLDER campaign, still waiting for an answer - the one a typed decision belongs to.
            $liveRun = Join-Path $campaigns 'cmp-live/runs/run-20260826-000000001-aaaaaaaa'
            New-Item -ItemType Directory -Path $liveRun -Force | Out-Null
            ([pscustomobject]@{ schema_version = '1.0'; fact_type = 'pending-pause'; campaign_id = 'cmp-live'
                    run_id = 'run-20260826-000000001-aaaaaaaa'; target_digest = 'aaaa'; observed_at = $t0.ToString('o') } |
                ConvertTo-Json -Compress) | Set-Content -LiteralPath (Join-Path $liveRun 'pending-pause.json') -Encoding UTF8
            # NEWER campaign, already answered - history, not a pending decision.
            $doneRun = Join-Path $campaigns 'cmp-done/runs/run-20260826-000000002-bbbbbbbb'
            New-Item -ItemType Directory -Path $doneRun -Force | Out-Null
            ([pscustomobject]@{ schema_version = '1.0'; fact_type = 'pending-pause'; campaign_id = 'cmp-done'
                    run_id = 'run-20260826-000000002-bbbbbbbb'; target_digest = 'bbbb'; observed_at = $t0.AddHours(1).ToString('o') } |
                ConvertTo-Json -Compress) | Set-Content -LiteralPath (Join-Path $doneRun 'pending-pause.json') -Encoding UTF8
            ([pscustomobject]@{ schema_version = '1.0'; fact_type = 'pause-decision'; campaign_id = 'cmp-done'
                    run_id = 'run-20260826-000000002-bbbbbbbb'; choice = 'stop-here'; observed_at = $t0.AddHours(1).AddMinutes(5).ToString('o') } |
                ConvertTo-Json -Compress) | Set-Content -LiteralPath (Join-Path $doneRun 'pause-decision.json') -Encoding UTF8

            $identity = Get-SpecrewPendingPauseIdentity -ProjectRoot $root
            $identity | Should -Not -BeNullOrEmpty -Because 'one pause really is outstanding'
            [string]$identity.run_id | Should -Be 'run-20260826-000000001-aaaaaaaa' -Because 'an answered pause is history; the decision belongs to the one still waiting'
            [string]$identity.campaign_id | Should -Be 'cmp-live'
        }
        finally { Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue }
    }

    It 'answers nothing when every pause has already been answered' {
        # "There is no pause" is itself the answer, and it must not degrade into "here is an old one".
        $root = Join-Path ([IO.Path]::GetTempPath()) ('w68-none-' + [guid]::NewGuid().ToString('N'))
        New-Item -ItemType Directory -Path (Join-Path $root '.specrew') -Force | Out-Null
        try {
            $runDir = Join-Path $root '.specrew/review/authority/campaigns/cmp-done/runs/run-20260826-000000003-cccccccc'
            New-Item -ItemType Directory -Path $runDir -Force | Out-Null
            ([pscustomobject]@{ schema_version = '1.0'; fact_type = 'pending-pause'; campaign_id = 'cmp-done'
                    run_id = 'run-20260826-000000003-cccccccc'; target_digest = 'cccc'; observed_at = ([DateTimeOffset]::UtcNow.AddHours(-1)).ToString('o') } |
                ConvertTo-Json -Compress) | Set-Content -LiteralPath (Join-Path $runDir 'pending-pause.json') -Encoding UTF8
            ([pscustomobject]@{ schema_version = '1.0'; fact_type = 'pause-decision'; campaign_id = 'cmp-done'
                    run_id = 'run-20260826-000000003-cccccccc'; choice = 'abandon'; observed_at = ([DateTimeOffset]::UtcNow).ToString('o') } |
                ConvertTo-Json -Compress) | Set-Content -LiteralPath (Join-Path $runDir 'pause-decision.json') -Encoding UTF8
            Get-SpecrewPendingPauseIdentity -ProjectRoot $root |
                Should -BeNullOrEmpty -Because 'a decision typed against no pause authorizes no pause'
        }
        finally { Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue }
    }
}

Describe 'W69 typed-turns-v1 completed: a TURN mints at most once, ever' {
    # Maintainer ruling, 2026-08-26, after the regeneration was measured at ground truth.
    #
    # typed-turns-v1 said only a real human turn mints authority. Its unstated half - never needed
    # until the Stop backstop began re-offering turns - is that each turn mints AT MOST ONCE. The
    # phrase is the CONTENT of an act; the turn is the act. Content was always a proxy for identity,
    # and the backstop is where the proxy fails: it re-offers the most recent human turn at the end of
    # every assistant turn, and once a capture is spent the writer's unspent-and-same-hash return no
    # longer applies, so it falls through and writes a fresh unspent one. One typed phrase became an
    # unlimited supply of rounds, with a ledger that looked correct.
    #
    # Fixed at the SHARED ROUTER so every writer it reaches inherits it.

    BeforeAll {
        # The router lives in the handover store, which is where both capture branches call it from.
        foreach ($dependency in @('ConversationCaptureAccessor', 'ClassificationEngine', 'ProjectMetadataAccessor', 'HandoverStore')) {
            . (Join-Path $script:RepoRoot ('scripts/internal/bootstrap/' + $dependency + '.ps1'))
        }

        function script:New-TurnRoot {
            $root = Join-Path ([IO.Path]::GetTempPath()) ('w69-' + [guid]::NewGuid().ToString('N'))
            New-Item -ItemType Directory -Path (Join-Path $root '.specrew') -Force | Out-Null
            return $root
        }
    }

    It 'RED-FIRST: the same turn re-offered after its capture was SPENT does not mint again' {
        # The measured defect, as a case. Capture, consume, then re-offer the identical turn exactly as
        # the backstop does on the next end-of-turn.
        $root = New-TurnRoot
        try {
            Invoke-SpecrewTypedAuthorityCapture -ProjectRoot $root -Response 'approved for allowance reset' `
                -HostKind 'claude' -SourceEvent 'stop-transcript' -NowUtc ([DateTimeOffset]::UtcNow.ToString('o')) `
                -TurnPosition '7' -TurnArrival '2026-08-26T10:13:33Z' -MessageId 'msg-7'
            Get-SpecrewAllowanceResetAuthorization -ProjectRoot $root |
                Should -Not -BeNullOrEmpty -Because 'precondition: the turn minted once, which is its whole entitlement'

            $done = Complete-SpecrewAllowanceResetAuthorization -ProjectRoot $root -Reference 'round-1'
            [bool]$done.consumed | Should -BeTrue -Because 'precondition: the round really did spend it'

            # SAME turn: same position, same arrival, same text. A later Stop, nothing new from the human.
            Invoke-SpecrewTypedAuthorityCapture -ProjectRoot $root -Response 'approved for allowance reset' `
                -HostKind 'claude' -SourceEvent 'stop-transcript' -NowUtc ([DateTimeOffset]::UtcNow.AddMinutes(5).ToString('o')) `
                -TurnPosition '7' -TurnArrival '2026-08-26T10:13:33Z' -MessageId 'msg-7'
            Get-SpecrewAllowanceResetAuthorization -ProjectRoot $root |
                Should -BeNullOrEmpty -Because 'the human typed once; a turn mints at most once, ever'
        }
        finally { Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue }
    }

    It 'the exhausted-turn check runs BEFORE the spent test, not conditioned on it' {
        # The ruling names this precisely: today `spent_at` empty is a PRECONDITION of the idempotent
        # return, so a spent slot fails that clause and falls through to a fresh write. The turn check
        # must not sit behind the same condition, or it inherits the same hole.
        $root = New-TurnRoot
        try {
            Invoke-SpecrewTypedAuthorityCapture -ProjectRoot $root -Response 'approved for allowance reset' `
                -HostKind 'claude' -SourceEvent 'stop-transcript' -TurnPosition '3' -TurnArrival '2026-08-26T09:00:00Z' -MessageId 'msg-3'
            $path = Join-Path $root '.specrew/review/allowance-reset/pending-allowance-reset.json'
            [IO.File]::Exists($path) | Should -BeTrue -Because 'precondition: there is a capture to spend'
            # Delete the slot entirely - the most extreme "no unspent record to match" state there is.
            [IO.File]::Delete($path)
            Invoke-SpecrewTypedAuthorityCapture -ProjectRoot $root -Response 'approved for allowance reset' `
                -HostKind 'claude' -SourceEvent 'stop-transcript' -TurnPosition '3' -TurnArrival '2026-08-26T09:00:00Z' -MessageId 'msg-3'
            [IO.File]::Exists($path) | Should -BeFalse -Because 'the turn was already exhausted; the state of the slot is not what decides that'
        }
        finally { Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue }
    }

    It 'a genuine RETYPE is a new turn and still mints' {
        # Nothing is lost by the rule: a human typing twice is two acts. Losing this would be the
        # round-19 wedge in yet another costume.
        $root = New-TurnRoot
        try {
            Invoke-SpecrewTypedAuthorityCapture -ProjectRoot $root -Response 'approved for allowance reset' `
                -HostKind 'claude' -SourceEvent 'stop-transcript' -TurnPosition '3' -TurnArrival '2026-08-26T09:00:00Z' -MessageId 'msg-3'
            $null = Complete-SpecrewAllowanceResetAuthorization -ProjectRoot $root -Reference 'round-1'
            Get-SpecrewAllowanceResetAuthorization -ProjectRoot $root | Should -BeNullOrEmpty -Because 'precondition: the first act is spent'

            # The human types it again: a LATER turn in the transcript, its own arrival.
            Invoke-SpecrewTypedAuthorityCapture -ProjectRoot $root -Response 'approved for allowance reset' `
                -HostKind 'claude' -SourceEvent 'stop-transcript' -TurnPosition '9' -TurnArrival '2026-08-26T11:30:00Z' -MessageId 'msg-9'
            Get-SpecrewAllowanceResetAuthorization -ProjectRoot $root |
                Should -Not -BeNullOrEmpty -Because 'two typed acts are two authorities; the rule bounds re-offers, not humans'
        }
        finally { Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue }
    }

    It 'EVERY writer the router reaches inherits the rule, not only the round approval' {
        # DRIFT-199-I001-138 widened the writer set the backstop feeds; the regeneration shape reached
        # all of them. Proven on the withdrawal and the pause decision as well, because a re-minted
        # withdrawal or pause decision is the same forgery wearing different clothes.
        $root = New-TurnRoot
        try {
            Invoke-SpecrewTypedAuthorityCapture -ProjectRoot $root -Response 'stop the review here' `
                -HostKind 'claude' -SourceEvent 'stop-transcript' -TurnPosition '4' -TurnArrival '2026-08-26T09:10:00Z' -MessageId 'msg-4'
            $first = Get-SpecrewPauseDecisionAuthorization -ProjectRoot $root -Choice 'stop-here'
            $first | Should -Not -BeNullOrEmpty -Because 'precondition: the pause decision minted once'
            $null = Complete-SpecrewPauseDecisionAuthorization -ProjectRoot $root -Choice 'stop-here' -AuthorizationRef 'landing-1'
            Invoke-SpecrewTypedAuthorityCapture -ProjectRoot $root -Response 'stop the review here' `
                -HostKind 'claude' -SourceEvent 'stop-transcript' -TurnPosition '4' -TurnArrival '2026-08-26T09:10:00Z' -MessageId 'msg-4'
            Get-SpecrewPauseDecisionAuthorization -ProjectRoot $root -Choice 'stop-here' |
                Should -BeNullOrEmpty -Because 'a re-minted pause decision is the same forgery in different clothes'
        }
        finally { Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue }
    }

    It 'END TO END through the Stop backstop: the same transcript turn does not re-mint after being spent' {
        # THE ACTUAL DEFECT PATH, and the cases above do not reach it - they call the router directly
        # with an explicit identity, so the wiring that supplies it is untested by them. Proven when a
        # mutation swapping the turn's arrival for the Stop event's clock left the suite green: the
        # inert-control class again, this time hiding the one line where the regeneration lived.
        $root = New-TurnRoot
        try {
            Invoke-StopCapture -Root $root -HumanText 'approved for allowance reset'
            Get-SpecrewAllowanceResetAuthorization -ProjectRoot $root |
                Should -Not -BeNullOrEmpty -Because 'precondition: the backstop really does mint from this transcript'

            $done = Complete-SpecrewAllowanceResetAuthorization -ProjectRoot $root -Reference 'round-1'
            [bool]$done.consumed | Should -BeTrue -Because 'precondition: a round spent it'

            # The next end-of-turn, with nothing new from the human: the same transcript, re-read.
            Invoke-StopCapture -Root $root -HumanText 'approved for allowance reset'
            Get-SpecrewAllowanceResetAuthorization -ProjectRoot $root |
                Should -BeNullOrEmpty -Because 'this is the regeneration that was measured in production; one turn, one mint'
        }
        finally { Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue }
    }

    It 'a ledger it cannot read means EXHAUSTED, not "mint away"' {
        # The fail-closed branch's own case, which its first cut did not have. A false "exhausted"
        # costs the human a retype; a false "fresh" forges an authority.
        $root = New-TurnRoot
        $handle = $null
        try {
            Invoke-SpecrewTypedAuthorityCapture -ProjectRoot $root -Response 'approved for allowance reset' `
                -HostKind 'claude' -SourceEvent 'stop-transcript' -TurnPosition '2' -TurnArrival '2026-08-26T08:00:00Z' -MessageId 'msg-2'
            $ledger = Join-Path $root '.specrew/authority/exhausted-turns.jsonl'
            [IO.File]::Exists($ledger) | Should -BeTrue -Because 'precondition: a mint records its turn'
            $null = Complete-SpecrewAllowanceResetAuthorization -ProjectRoot $root -Reference 'round-1'

            $handle = [IO.File]::Open($ledger, [IO.FileMode]::Open, [IO.FileAccess]::ReadWrite, [IO.FileShare]::None)
            Invoke-SpecrewTypedAuthorityCapture -ProjectRoot $root -Response 'approved for allowance reset' `
                -HostKind 'claude' -SourceEvent 'stop-transcript' -TurnPosition '5' -TurnArrival '2026-08-26T09:00:00Z' -MessageId 'msg-5'
            Get-SpecrewAllowanceResetAuthorization -ProjectRoot $root |
                Should -BeNullOrEmpty -Because 'if it cannot tell whether this turn already minted, it must not mint'
        }
        finally {
            if ($null -ne $handle) { $handle.Dispose() }
            Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    It 'the check is in the ROUTER, ahead of the writer loop, so a writer added later cannot miss it' {
        $handover = Get-Content -LiteralPath (Join-Path $script:RepoRoot 'scripts/internal/bootstrap/HandoverStore.ps1') -Raw -Encoding UTF8
        $router = [regex]::Match($handover, '(?s)function Invoke-SpecrewTypedAuthorityCapture.*?\r?\n\}').Value
        $router | Should -Not -BeNullOrEmpty
        $guardIndex = $router.IndexOf('Test-SpecrewTypedTurnExhausted')
        # 203 T004 (DA-1 option B): the writer loop is gone; the classifier's act reaches its one writer through the sink.
        $loopIndex = $router.IndexOf('Invoke-SpecrewTypedActSink')
        $guardIndex | Should -BeGreaterThan -1 -Because 'the rule lives at the one place every writer passes through'
        $loopIndex | Should -BeGreaterThan -1
        $guardIndex | Should -BeLessThan $loopIndex -Because 'a turn already exhausted must not reach any writer at all'
    }
}

Describe 'W70 round 27: the one-turn rule must hold across CHANNELS and must fail closed when it cannot record' {
    # Round 27 covered the tree W69 landed on and reported two BLOCKING findings against W69 itself,
    # plus the campaign-scoping half of W68 that I had left as "secondary hardening". The engine
    # demoted all of them to minor for want of a concrete failure scenario; the substance is that the
    # ruling W69 implements does not hold on a host that delivers BOTH prompt text and a transcript.
    #
    # A fix that does not fix the thing it was ruled to fix is not a minor.

    BeforeAll {
        foreach ($dependency in @('ConversationCaptureAccessor', 'ClassificationEngine', 'ProjectMetadataAccessor', 'HandoverStore')) {
            . (Join-Path $script:RepoRoot ('scripts/internal/bootstrap/' + $dependency + '.ps1'))
        }

        function script:New-ChannelRoot {
            $root = Join-Path ([IO.Path]::GetTempPath()) ('w70-' + [guid]::NewGuid().ToString('N'))
            New-Item -ItemType Directory -Path (Join-Path $root '.specrew') -Force | Out-Null
            return $root
        }
    }

    It 'SUPERSEDED by 203 T004 (FR-022): with the host message id on both channels, one message is one act' {
        # 203 T004: the residual W71 accepted is gone where the host gives the message its own id. Both channels key the
        # message by it (202 T017), and the writer records only an act no path has recorded (FR-022), so the turn end's
        # delivery of a message the prompt channel already minted mints nothing, and there is no double mint to observe.
        # This case asserted cross-channel SUPPRESSION. The maintainer's 2026-08-26 ruling removed it:
        # round 28 showed the match was not an identity (it wedged a genuine later retype forever and
        # still leaked when the ledger write failed), and the two findings contradicting each other
        # were the guess failing to be an identity, stated twice. Same-channel exhaustion is the
        # guarantee that survives; the second channel is observed. Rewritten to the rule that now holds
        # rather than deleted, so the history of what was tried stays visible.
        $root = New-TurnRoot
        try {
            Invoke-SpecrewTypedAuthorityCapture -ProjectRoot $root -Response 'approved for allowance reset' `
                -HostKind 'claude' -SourceEvent 'UserPromptSubmit' -NowUtc '2026-08-26T15:40:45Z' `
                -TurnPosition 'prompt-entry' -TurnArrival '2026-08-26T15:40:45Z' -MessageId 'msg-11' -TurnOrigin 'typed-user'
            Get-SpecrewAllowanceResetAuthorization -ProjectRoot $root |
                Should -Not -BeNullOrEmpty -Because 'precondition: the prompt channel minted the human act'
            $null = Complete-SpecrewAllowanceResetAuthorization -ProjectRoot $root -Reference 'round-1'
            Invoke-SpecrewTypedAuthorityCapture -ProjectRoot $root -Response 'approved for allowance reset' `
                -HostKind 'claude' -SourceEvent 'stop-transcript' -NowUtc '2026-08-26T15:52:10Z' `
                -TurnPosition '11' -TurnArrival '2026-08-26T15:40:45Z' -MessageId 'msg-11'
            Get-SpecrewAllowanceResetAuthorization -ProjectRoot $root |
                Should -BeNullOrEmpty -Because 'one human message is one act however many channels deliver it'
            $ledger = Join-Path $root '.specrew/authority/exhausted-turns.jsonl'
            (Get-Content -LiteralPath $ledger -Raw -Encoding UTF8) | Should -Not -Match 'cross-channel-double-mint' `
                -Because 'nothing minted twice, so there is nothing to observe'
        }
        finally { Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue }
    }

    It 'a Stop-only host still mints a genuine retype, so the cross-channel rule wedges nobody' {
        # The rule is scoped to "Stop must not re-mint what PROMPT-ENTRY already minted". Where
        # prompt-entry is dead - the host the backstop exists for - a retype is a later turn and still
        # mints. Without this the fix would trade a forgery for a wedge, which is the round-19 lesson.
        $root = New-ChannelRoot
        try {
            Invoke-SpecrewTypedAuthorityCapture -ProjectRoot $root -Response 'approved for allowance reset' `
                -HostKind 'claude' -SourceEvent 'stop-transcript' -TurnPosition '3' -TurnArrival '2026-08-26T09:00:00Z' -MessageId 'msg-3'
            $null = Complete-SpecrewAllowanceResetAuthorization -ProjectRoot $root -Reference 'round-1'
            Invoke-SpecrewTypedAuthorityCapture -ProjectRoot $root -Response 'approved for allowance reset' `
                -HostKind 'claude' -SourceEvent 'stop-transcript' -TurnPosition '9' -TurnArrival '2026-08-26T11:30:00Z' -MessageId 'msg-9'
            Get-SpecrewAllowanceResetAuthorization -ProjectRoot $root |
                Should -Not -BeNullOrEmpty -Because 'on a prompt-entry-less host the backstop is the only channel, and a retype is a new act'
        }
        finally { Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue }
    }

    It 'prompt-entry SEEING content is not prompt-entry CAPTURING it, so the backstop still mints' {
        # The cross-channel rule keys on a real mint, never on a sighting - and this is the case that
        # proves the difference. Without it, a mutation making the rule key on sightings stayed green:
        # prompt-entry reserves EVERY turn it is offered, so a sighting-keyed rule would silence the
        # backstop for every phrase prompt-entry saw and failed to capture, which is precisely the set
        # of turns the backstop exists for.
        $root = New-ChannelRoot
        try {
            $hash = Get-SpecrewHumanAuthorityHash -Text 'approved for allowance reset'
            $ledger = Join-Path $root '.specrew/authority/exhausted-turns.jsonl'
            New-Item -ItemType Directory -Path (Split-Path -Parent $ledger) -Force | Out-Null
            # What prompt-entry leaves behind when it sees a turn and captures nothing: a reservation
            # with an EMPTY minted list. 203 T004: written as today's prompt hook writes it, under that message's own
            # key and with its identity, so it is a sighting of ANOTHER message, not pre-update history (which 202's
            # legacy check matches on content and time, and would rightly take for this message).
            ([pscustomobject]@{ schema_version = '1.0'; fact_type = 'typed-turn-exhausted'
                    turn_id = 'some-other-turn-id'; content_hash = $hash; host_kind = 'claude'
                    source_event = 'UserPromptSubmit'; minted = ''; identity = 'typed-act'
                    observed_at = '2026-08-26T15:40:45Z' } | ConvertTo-Json -Compress) |
                Set-Content -LiteralPath $ledger -Encoding UTF8

            Invoke-SpecrewTypedAuthorityCapture -ProjectRoot $root -Response 'approved for allowance reset' `
                -HostKind 'claude' -SourceEvent 'stop-transcript' -TurnPosition '4' -TurnArrival '2026-08-26T15:40:45Z' -MessageId 'msg-4'
            Get-SpecrewAllowanceResetAuthorization -ProjectRoot $root |
                Should -Not -BeNullOrEmpty -Because 'the backstop exists for turns prompt-entry saw and did not capture'
        }
        finally { Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue }
    }

    It 'RED-FIRST: a turn that cannot be RECORDED as exhausted does not mint at all' {
        # THE SECOND BLOCKING FINDING, and it is the report-don't-control shape reintroduced in my own
        # fix: the registration was piped to Out-Null and its exceptions swallowed, so if the ledger
        # could not be appended the approval existed and the turn was never marked - and the next Stop
        # re-offered it. A limit that silently stops limiting is worse than no limit, because the
        # ledger still looks like one.
        $root = New-ChannelRoot
        $handle = $null
        try {
            # Create the ledger, then hold it so it can be READ but never APPENDED. The exhaustion
            # check therefore succeeds (nothing recorded yet) and only the registration fails, which
            # isolates this branch from the locked-ledger case that covers the reader.
            $ledger = Join-Path $root '.specrew/authority/exhausted-turns.jsonl'
            New-Item -ItemType Directory -Path (Split-Path -Parent $ledger) -Force | Out-Null
            [IO.File]::WriteAllText($ledger, '', [Text.UTF8Encoding]::new($false))
            $handle = [IO.File]::Open($ledger, [IO.FileMode]::Open, [IO.FileAccess]::Read, [IO.FileShare]::Read)

            Invoke-SpecrewTypedAuthorityCapture -ProjectRoot $root -Response 'approved for allowance reset' `
                -HostKind 'claude' -SourceEvent 'stop-transcript' -TurnPosition '2' -TurnArrival '2026-08-26T08:00:00Z' -MessageId 'msg-2'
            Get-SpecrewAllowanceResetAuthorization -ProjectRoot $root |
                Should -BeNullOrEmpty -Because 'if the one-turn limit cannot be recorded, the mint it is supposed to bound must not happen'
        }
        finally {
            if ($null -ne $handle) { $handle.Dispose() }
            Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    It 'SUPERSEDED by W75: a TORN ledger line is skipped and recorded, not treated as every turn' {
        # The reader skipped malformed lines, so an interrupted append produced exactly the false-fresh
        # result the ledger exists to prevent. A line it cannot parse is a line it cannot rule out.
        $root = New-ChannelRoot
        try {
            Invoke-SpecrewTypedAuthorityCapture -ProjectRoot $root -Response 'approved for allowance reset' `
                -HostKind 'claude' -SourceEvent 'stop-transcript' -TurnPosition '2' -TurnArrival '2026-08-26T08:00:00Z' -MessageId 'msg-2'
            $null = Complete-SpecrewAllowanceResetAuthorization -ProjectRoot $root -Reference 'round-1'
            $ledger = Join-Path $root '.specrew/authority/exhausted-turns.jsonl'
            # An interrupted append: the tail of the file is half a record.
            Add-Content -LiteralPath $ledger -Value '{"schema_version":"1.0","fact_type":"typed-turn-exh' -Encoding UTF8

            Invoke-SpecrewTypedAuthorityCapture -ProjectRoot $root -Response 'approved for allowance reset' `
                -HostKind 'claude' -SourceEvent 'stop-transcript' -TurnPosition '7' -TurnArrival '2026-08-26T10:00:00Z' -MessageId 'msg-7'
            Get-SpecrewAllowanceResetAuthorization -ProjectRoot $root |
                # W72 asserted -BeNullOrEmpty here. The maintainer reversed it on 2026-08-27, and round
                # 31 is why: failing closed on "can this PROJECT ever be authorized again" is an
                # outage, not a safety property. This is a DIFFERENT turn, so it mints; the damage is
                # recorded rather than charged to every future act.
                Should -Not -BeNullOrEmpty -Because 'one interrupted append must not permanently end a project''s ability to be authorized'
        }
        finally { Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue }
    }

    It 'RED-FIRST: a pause decision binds to the campaign being answered, not the newest one anywhere' {
        # The major finding, and the half of W68 I left undone. Excluding ANSWERED pauses fixed the
        # reported wedge; scoping was called secondary hardening and was not. With two campaigns each
        # holding an unanswered pause, the human answering the active feature is bound to whichever
        # campaign paused most recently, the CLI rejects it for the run actually waiting, and retyping
        # repeats the binding. Same wedge, reached by the door left open.
        $root = New-ChannelRoot
        try {
            $t0 = [DateTimeOffset]::UtcNow.AddHours(-3)
            $campaigns = Join-Path $root '.specrew/review/authority/campaigns'
            foreach ($c in @(
                    @{ id = 'cmp-active'; run = 'run-20260826-000000001-aaaaaaaa'; at = $t0 }
                    @{ id = 'cmp-other'; run = 'run-20260826-000000002-bbbbbbbb'; at = $t0.AddHours(2) })) {
                $runDir = Join-Path $campaigns ($c.id + '/runs/' + $c.run)
                New-Item -ItemType Directory -Path $runDir -Force | Out-Null
                ([pscustomobject]@{ schema_version = '1.0'; fact_type = 'pending-pause'; campaign_id = $c.id
                        run_id = $c.run; target_digest = 'dddd'; observed_at = $c.at.ToString('o') } |
                    ConvertTo-Json -Compress) | Set-Content -LiteralPath (Join-Path $runDir 'pending-pause.json') -Encoding UTF8
            }
            # Answering the ACTIVE campaign, which is not the newest pause in the project.
            $identity = Get-SpecrewPendingPauseIdentity -ProjectRoot $root -CampaignId 'cmp-active'
            $identity | Should -Not -BeNullOrEmpty
            [string]$identity.campaign_id | Should -Be 'cmp-active' -Because 'the decision belongs to the campaign the human is answering'
            [string]$identity.run_id | Should -Be 'run-20260826-000000001-aaaaaaaa'
        }
        finally { Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue }
    }

    It 'with no campaign named it still answers, so an unscoped caller is not broken' {
        # Fail-open on SCOPE only: callers that cannot name a campaign keep the project-wide behaviour,
        # minus answered pauses. Refusing them would wedge every caller that has no campaign to give.
        $root = New-ChannelRoot
        try {
            $runDir = Join-Path $root '.specrew/review/authority/campaigns/cmp-solo/runs/run-20260826-000000009-eeeeeeee'
            New-Item -ItemType Directory -Path $runDir -Force | Out-Null
            ([pscustomobject]@{ schema_version = '1.0'; fact_type = 'pending-pause'; campaign_id = 'cmp-solo'
                    run_id = 'run-20260826-000000009-eeeeeeee'; target_digest = 'eeee'
                    observed_at = ([DateTimeOffset]::UtcNow.AddHours(-1)).ToString('o') } |
                ConvertTo-Json -Compress) | Set-Content -LiteralPath (Join-Path $runDir 'pending-pause.json') -Encoding UTF8
            [string](Get-SpecrewPendingPauseIdentity -ProjectRoot $root).campaign_id | Should -Be 'cmp-solo'
        }
        finally { Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue }
    }
}

Describe 'W71 round 28: OBSERVE the second channel, do not suppress it; and prove fixes at the production call site' {
    # Maintainer ruling, 2026-08-26. Findings 3 and 4 of round 28 contradict each other - one says do
    # not suppress without a proven distinct act, the other says suppress when the mint cannot be
    # recorded - and the ruling names that for what it is: not two defects, but the guess failing to be
    # an identity, stated twice. The cross-channel rule was a heuristic wearing an identity's clothes.
    #
    # So it goes. Same-channel exhaustion stays; the second channel is OBSERVED rather than blocked.
    # The residual is bounded and its size is the reason it is acceptable: each channel mints at most
    # once per utterance, so a dual-event host yields AT MOST TWO mints from one typed act. The
    # pre-W69 hole was unlimited. And it is a spend-accounting cost, not a forgery - the human did
    # approve a round; the machinery may grant a second.

    BeforeAll {
        foreach ($dependency in @('ConversationCaptureAccessor', 'ClassificationEngine', 'ProjectMetadataAccessor', 'HandoverStore')) {
            . (Join-Path $script:RepoRoot ('scripts/internal/bootstrap/' + $dependency + '.ps1'))
        }
        function script:New-W71Root {
            $root = Join-Path ([IO.Path]::GetTempPath()) ('w71-' + [guid]::NewGuid().ToString('N'))
            New-Item -ItemType Directory -Path (Join-Path $root '.specrew') -Force | Out-Null
            return $root
        }
    }

    It 'RED-FIRST: the wedge is gone - a later retype at Stop mints even after a prompt-entry mint' {
        # The wedge I introduced in W70 and then found in my own commit: the cross-channel rule matched
        # content and host with no comparison of arrival, so an old prompt-entry mint suppressed a
        # genuinely later retype at Stop forever, with no recovery, exactly when the backstop is needed.
        $root = New-W71Root
        try {
            Invoke-SpecrewTypedAuthorityCapture -ProjectRoot $root -Response 'approved for allowance reset' `
                -HostKind 'claude' -SourceEvent 'UserPromptSubmit' -NowUtc '2026-08-26T10:00:00Z' `
                -TurnPosition 'prompt-entry' -TurnArrival '2026-08-26T10:00:00Z' -MessageId 'msg-prompt-1' -TurnOrigin 'typed-user'
            $null = Complete-SpecrewAllowanceResetAuthorization -ProjectRoot $root -Reference 'round-1'
            Get-SpecrewAllowanceResetAuthorization -ProjectRoot $root | Should -BeNullOrEmpty -Because 'precondition: the first act is spent'

            # Hours later the human types it again, and prompt-entry misses that turn.
            Invoke-SpecrewTypedAuthorityCapture -ProjectRoot $root -Response 'approved for allowance reset' `
                -HostKind 'claude' -SourceEvent 'stop-transcript' -NowUtc '2026-08-26T14:00:00Z' `
                -TurnPosition '31' -TurnArrival '2026-08-26T13:59:00Z' -MessageId 'msg-31'
            Get-SpecrewAllowanceResetAuthorization -ProjectRoot $root |
                Should -Not -BeNullOrEmpty -Because 'the backstop must still work; a phrase the human can never make count is a wedge'
        }
        finally { Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue }
    }

    It 'SUPERSEDED by 203 T004 (FR-022): the second channel of one message mints nothing, so no double mint is recorded' {
        # 203 T004: W71 observed the double mint because the two channels had no shared identity. With the host's message
        # id on both they have one, and the second delivery of a minted message reaches no writer.
        # Visibility was the right answer to the exhaustion gap and to the picker gap, and it is the
        # right answer here: the ledger shows every double mint, so beta4 gets field data instead of
        # speculation about how often two channels deliver one utterance.
        $root = New-W71Root
        try {
            Invoke-SpecrewTypedAuthorityCapture -ProjectRoot $root -Response 'approved for allowance reset' `
                -HostKind 'claude' -SourceEvent 'UserPromptSubmit' -NowUtc '2026-08-26T10:00:00Z' `
                -TurnPosition 'prompt-entry' -TurnArrival '2026-08-26T10:00:00Z' -MessageId 'msg-4' -TurnOrigin 'typed-user'
            $null = Complete-SpecrewAllowanceResetAuthorization -ProjectRoot $root -Reference 'round-1'
            Invoke-SpecrewTypedAuthorityCapture -ProjectRoot $root -Response 'approved for allowance reset' `
                -HostKind 'claude' -SourceEvent 'stop-transcript' -NowUtc '2026-08-26T10:05:00Z' `
                -TurnPosition '4' -TurnArrival '2026-08-26T10:00:00Z' -MessageId 'msg-4'

            Get-SpecrewAllowanceResetAuthorization -ProjectRoot $root |
                Should -BeNullOrEmpty -Because 'the turn end delivered a message the prompt channel already minted'
            $ledger = Join-Path $root '.specrew/authority/exhausted-turns.jsonl'
            $observations = @(Get-Content -LiteralPath $ledger -Encoding UTF8 |
                    ForEach-Object { try { $_ | ConvertFrom-Json -Depth 6 } catch { $null } } |
                    Where-Object { $null -ne $_ -and [string]$_.fact_type -ceq 'cross-channel-double-mint' })
            @($observations).Count | Should -Be 0 -Because 'one message minted once leaves no double mint to observe'
        }
        finally { Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue }
    }

    It 'same-channel exhaustion still holds, which is the guarantee that survives' {
        $root = New-W71Root
        try {
            Invoke-SpecrewTypedAuthorityCapture -ProjectRoot $root -Response 'approved for allowance reset' `
                -HostKind 'claude' -SourceEvent 'stop-transcript' -TurnPosition '7' -TurnArrival '2026-08-26T10:13:33Z' -MessageId 'msg-7'
            $null = Complete-SpecrewAllowanceResetAuthorization -ProjectRoot $root -Reference 'round-1'
            Invoke-SpecrewTypedAuthorityCapture -ProjectRoot $root -Response 'approved for allowance reset' `
                -HostKind 'claude' -SourceEvent 'stop-transcript' -TurnPosition '7' -TurnArrival '2026-08-26T10:13:33Z' -MessageId 'msg-7'
            Get-SpecrewAllowanceResetAuthorization -ProjectRoot $root |
                Should -BeNullOrEmpty -Because 'one channel, one utterance, one mint - the attack the store actually recorded'
        }
        finally { Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue }
    }

    It 'RED-FIRST: the PRODUCTION writer binds a pause decision to the active feature campaign' {
        # Round-28 finding, and the tenth inert-control instance: W70 added -CampaignId to the helper
        # and the test exercised the helper. The production writer calls it with ProjectRoot alone, so
        # the fix never reached the path that uses it. This case names the CALL SITE, per the method
        # rule the maintainer sharpened after three of these in three rounds.
        $root = New-W71Root
        try {
            # A REAL feature branch: a commit (so HEAD resolves) and specs/<branch>/ (which is what
            # makes a branch a FEATURE branch by the contract the resolver enforces). Two earlier cuts
            # of this fixture lacked each in turn, and both times the empty scope looked like a defect
            # in the code under test. A case that names a production call site needs a
            # production-shaped project, or it is testing the fixture.
            & git init -q -b 199-beta3-stabilization $root 2>&1 | Out-Null
            New-Item -ItemType Directory -Path (Join-Path $root 'specs/199-beta3-stabilization') -Force | Out-Null
            Set-Content -LiteralPath (Join-Path $root 'specs/199-beta3-stabilization/spec.md') -Value '# fixture' -Encoding UTF8
            & git -C $root add -A 2>&1 | Out-Null
            & git -C $root -c user.name=t -c user.email=t@t commit -q -m init 2>&1 | Out-Null
            $t0 = [DateTimeOffset]::UtcNow.AddHours(-3)
            $campaigns = Join-Path $root '.specrew/review/authority/campaigns'
            foreach ($c in @(
                    @{ id = 'cmp-199-beta3-stabilization-i001'; run = 'run-20260826-000000001-aaaaaaaa'; at = $t0 }
                    @{ id = 'cmp-999-other-feature-i001'; run = 'run-20260826-000000002-bbbbbbbb'; at = $t0.AddHours(2) })) {
                $runDir = Join-Path $campaigns ($c.id + '/runs/' + $c.run)
                New-Item -ItemType Directory -Path $runDir -Force | Out-Null
                ([pscustomobject]@{ schema_version = '1.0'; fact_type = 'pending-pause'; campaign_id = $c.id
                        run_id = $c.run; target_digest = 'dddd'; observed_at = $c.at.ToString('o') } |
                    ConvertTo-Json -Compress) | Set-Content -LiteralPath (Join-Path $runDir 'pending-pause.json') -Encoding UTF8
            }

            # THE PRODUCTION PATH: the writer, exactly as the router calls it - no CampaignId to give.
            $null = Write-SpecrewPauseDecisionAuthorization -ProjectRoot $root -Response 'stop the review here' `
                -HostKind 'claude' -SourceEvent 'UserPromptSubmit'
            $decision = Get-SpecrewPauseDecisionAuthorization -ProjectRoot $root -Choice 'stop-here'
            $decision | Should -Not -BeNullOrEmpty
            [string]$decision.campaign_id | Should -Be 'cmp-199-beta3-stabilization-i001' -Because 'the decision belongs to the feature the human is working on, not to whichever campaign paused most recently'
        }
        finally { Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue }
    }
}

Describe 'W73 round 30: a CONDITIONAL reply is not authority, in every recognizer' {
    # Round 30 graded this BLOCKING on its own account - not demoted - and it is the fabrication class:
    # a human expresses conditional approval and the machinery records it as unconditional, so an agent
    # crosses a boundary, spends a round, stops a campaign or resets allowance before the condition is
    # met. The human said "if"; the ledger says "yes".
    #
    # Five copies of the same six-word set (later|after|once|when|unless|if) across three files, and
    # exactly ONE of them - the post-delimiter branch in ConversationCaptureAccessor - also knows
    # provided|assuming|contingent|subject to. So the words a person actually reaches for when hedging
    # were the ones no recognizer checked in the same clause.

    BeforeAll {
        . (Join-Path $script:RepoRoot 'scripts/internal/bootstrap/ConversationCaptureAccessor.ps1')
    }

    It 'RED-FIRST: conditional ROUND approval is not an approval' {
        foreach ($text in @(
                'approved for review round provided the tests pass'
                'approved for review round, provided the tests pass'
                'approved for review round assuming CI is green'
                'approved for review round, subject to the final check'
                'approved for review round contingent on the lanes staying green')) {
            [bool](Test-SpecrewReviewRoundApprovalPhrase -Text $text).Matched |
                Should -BeFalse -Because ("a condition is not a yes: " + $text)
        }
    }

    It 'RED-FIRST: conditional PAUSE decisions are not decisions' {
        foreach ($text in @(
                'stop the review here, subject to the final check'
                'stop the review here provided nothing else is outstanding'
                'abandon this review campaign assuming the rewrite lands')) {
            [bool](Test-SpecrewPauseDecisionPhrase -Text $text).Matched |
                Should -BeFalse -Because ("stopping or abandoning on a condition is not stopping: " + $text)
        }
    }

    It 'RED-FIRST: a conditional ALLOWANCE RESET does not replenish' {
        foreach ($text in @(
                'approved for allowance reset provided the budget holds'
                'approved for allowance reset, assuming we still need it')) {
            [bool](Test-SpecrewAllowanceResetPhrase -Text $text).Matched |
                Should -BeFalse -Because ("lifting a spend limit on a condition is not lifting it: " + $text)
        }
    }

    It 'the UNCONDITIONAL phrases still work - the rule bounds hedges, not humans' {
        # The control that stops this becoming a wedge. Every phrase the docs tell a human to type must
        # still mint. (W56's approval-followed-by-a-block shape is no longer one of them - PRED-BETA4-022
        # made a verdict one line; the same-line form carries the instruction instead.)
        [bool](Test-SpecrewReviewRoundApprovalPhrase -Text 'approved for review round').Matched | Should -BeTrue
        [bool](Test-SpecrewReviewRoundApprovalPhrase -Text 'approved for review round - run it with --host codex').Matched | Should -BeTrue
        (Test-SpecrewReviewRoundApprovalPhrase -Text "approved for review round`n`nRun it with --host codex.").Reason | Should -Be 'multi-line-refused'
        [bool](Test-SpecrewPauseDecisionPhrase -Text 'stop the review here').Matched | Should -BeTrue
        [bool](Test-SpecrewAllowanceResetPhrase -Text 'approved for allowance reset').Matched | Should -BeTrue
        # And a phrase that merely CONTAINS a condition word about something else is still an approval.
        [bool](Test-SpecrewReviewRoundApprovalPhrase -Text 'approved for review round. The iffy test is unrelated.').Matched |
            Should -BeTrue -Because 'the guard keys on a conditional CLAUSE, not on a substring'
    }

    It 'ONE rule, read by every recognizer, so the sets cannot drift again' {
        # The divergence class, at five call sites. The words lived in five places and agreed in none.
        $sources = @(
            (Join-Path $script:RepoRoot 'scripts/internal/bootstrap/HumanAuthorityStore.ps1')
            (Join-Path $script:RepoRoot 'scripts/internal/bootstrap/ConversationCaptureAccessor.ps1')
        )
        foreach ($source in $sources) {
            # CODE lines only. A comment quoting the old set is documentation of what was fixed, not a
            # second copy of it - and the entry explaining this fix necessarily names the words.
            $codeLines = @(Get-Content -LiteralPath $source -Encoding UTF8 | Where-Object { $_ -notmatch '^\s*#' })
            $inline = @($codeLines | Where-Object { $_ -match '\(later\|after\|once\|when\|unless\|if' })
            @($inline).Count | Should -Be 0 -Because ("the conjunction set must live in one place, not inline in " + (Split-Path $source -Leaf))
        }
        $store = Get-Content -LiteralPath (Join-Path $script:RepoRoot 'scripts/internal/bootstrap/ConversationCaptureAccessor.ps1') -Raw -Encoding UTF8
        $store | Should -Match 'function Test-SpecrewConditionalDeferralClause' -Because 'one named rule is what stops five copies disagreeing'
    }
}

Describe 'W75 round 31: a damaged ledger must not end the project, and a following line must not erase a verdict' {
    # Maintainer ruling, 2026-08-27, on the two findings that will not ship.
    #
    # FINDING 1 IS MINE, from the fail-closed rule I added in W70 and repeated in W72. The distinction
    # I missed, and the sharpest version of the wedge-versus-spend trade in this log:
    #
    #   Failing closed on "should this ACT be authorized" is SAFETY.
    #   Failing closed on "can this PROJECT ever be authorized again" is an OUTAGE.
    #
    # A torn line returned "exhausted" for every later turn, permanently: one interrupted append and
    # the project accepts no further approval, pause, reset or withdrawal, retyping cannot recover it,
    # and the refusal contract forbids hand-editing the store. A consumer who hits Ctrl+C at the wrong
    # moment is left with an ungovernable project and no sanctioned way out. Not exotic - this session
    # had a process killed mid-operation twice.

    BeforeAll {
        foreach ($dependency in @('ConversationCaptureAccessor', 'ClassificationEngine', 'ProjectMetadataAccessor', 'HandoverStore')) {
            . (Join-Path $script:RepoRoot ('scripts/internal/bootstrap/' + $dependency + '.ps1'))
        }
        function script:New-W75Root {
            $root = Join-Path ([IO.Path]::GetTempPath()) ('w75-' + [guid]::NewGuid().ToString('N'))
            New-Item -ItemType Directory -Path (Join-Path $root '.specrew') -Force | Out-Null
            return $root
        }
    }

    It 'RED-FIRST: a torn line in the turn ledger does not end the project' {
        $root = New-W75Root
        try {
            # A real, complete history: one turn minted and was spent.
            Invoke-SpecrewTypedAuthorityCapture -ProjectRoot $root -Response 'approved for allowance reset' `
                -HostKind 'claude' -SourceEvent 'stop-transcript' -TurnPosition '2' -TurnArrival '2026-08-27T08:00:00Z' -MessageId 'msg-2'
            $null = Complete-SpecrewAllowanceResetAuthorization -ProjectRoot $root -Reference 'round-1'
            $ledger = Join-Path $root '.specrew/authority/exhausted-turns.jsonl'
            # Ctrl+C during an append.
            Add-Content -LiteralPath $ledger -Value '{"schema_version":"1.0","fact_type":"typed-turn-exh' -Encoding UTF8

            # A DIFFERENT turn, typed afterwards. It must still be able to mint.
            Invoke-SpecrewTypedAuthorityCapture -ProjectRoot $root -Response 'approved for allowance reset' `
                -HostKind 'claude' -SourceEvent 'stop-transcript' -TurnPosition '9' -TurnArrival '2026-08-27T09:30:00Z' -MessageId 'msg-9'
            Get-SpecrewAllowanceResetAuthorization -ProjectRoot $root |
                Should -Not -BeNullOrEmpty -Because 'one interrupted append must not leave a project that can never be authorized again'
        }
        finally { Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue }
    }

    It 'RED-FIRST: the damage is RECORDED, so a silent skip is not the price of staying usable' {
        # Observe, do not suppress - the W71 pattern, applied to the ledger itself. Skipping a torn line
        # without saying so would trade an outage for an invisible hole.
        $root = New-W75Root
        try {
            Invoke-SpecrewTypedAuthorityCapture -ProjectRoot $root -Response 'approved for allowance reset' `
                -HostKind 'claude' -SourceEvent 'stop-transcript' -TurnPosition '2' -TurnArrival '2026-08-27T08:00:00Z' -MessageId 'msg-2'
            $ledger = Join-Path $root '.specrew/authority/exhausted-turns.jsonl'
            Add-Content -LiteralPath $ledger -Value '{"fact_type":"typed-turn-exh' -Encoding UTF8
            $null = Get-SpecrewAllowanceResetAuthorization -ProjectRoot $root
            Invoke-SpecrewTypedAuthorityCapture -ProjectRoot $root -Response 'approved for allowance reset' `
                -HostKind 'claude' -SourceEvent 'stop-transcript' -TurnPosition '11' -TurnArrival '2026-08-27T10:00:00Z' -MessageId 'msg-11'
            (Get-Content -LiteralPath $ledger -Raw -Encoding UTF8) | Should -Match 'authority-ledger-damaged' `
                -Because 'a ledger that lost a record must say so, or the hole is invisible'
        }
        finally { Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue }
    }

    It 'REVERSED by PRED-BETA4-022: a following-line instruction is refused BY REASON, not erased in silence' {
        # W75 (2026-08-27) made the line break end the approval clause so a following instruction could
        # not turn a valid verdict into a condition on it - and the verdict minted with the block under
        # it. PRED-BETA4-022 (B4F-065, 2026-09-10) reverses the second half: the same rule on the
        # round-approval path minted a pasted 136-line transcript, and a verdict is ONE line. What W75
        # protected - FR-010, the human is not silently un-approved - is kept by a different means: the
        # refusal carries a reason, and the prompt-entry disclosure names the one-line retype. The
        # same-line form carries the instruction.
        foreach ($text in @(
                ("approved for tasks" + [char]10 + "Run the cleanup when the review finishes.")
                ("approved for tasks" + [char]10 + "Once that lands, start the retro.")
                ("approved for plan" + [char]10 + [char]10 + "If anything looks off, tell me."))) {
            $v = Test-SpecrewHumanVerdictToken -Text $text
            [bool]$v.IsApproval | Should -BeFalse -Because ("a verdict is one line: " + ($text -replace [char]10, ' / '))
            [string]$v.Action | Should -Be 'refused-multi-line' -Because 'the refusal is by reason, so the disclosure can name the retype instead of leaving silence'
        }
        [bool](Test-SpecrewHumanVerdictToken -Text 'approved for tasks - then start the retro.').IsApproval |
            Should -BeTrue -Because 'the same-line instruction form is the documented one and still mints'
        [bool](Test-SpecrewHumanVerdictToken -Text ("approved for tasks" + [char]10 + [char]10)).IsApproval |
            Should -BeTrue -Because 'trailing blank lines are not content; only a continuation that says something is refused'
    }

    It 'a SAME-LINE condition still defers the boundary verdict' {
        # The guard that must survive: the whole point of the conjunction set is that a condition ON
        # the approval clause defers it. Only the line break is being restored as a delimiter.
        foreach ($text in @(
                'approved for tasks when the tests pass'
                'approved for tasks once CI is green'
                'approved for tasks provided the lanes hold')) {
            [bool](Test-SpecrewHumanVerdictToken -Text $text).IsApproval |
                Should -BeFalse -Because ("a condition in the approval clause is still a condition: " + $text)
        }
    }
}

Describe 'W76 the third surface: the reset advisory names a flag and never the phrase, and the sweep could not see it' {
    # Maintainer finding, 2026-08-27. NOT beta4 - the same defect class this fortnight closed twice,
    # live on a third surface, and it reached a real human: a downstream agent read the exhaustion
    # advisory and relayed `--remediate allowance-reset` to the maintainer, correctly, because that is
    # what Specrew told it to say.
    #
    # W44 swept --approve-round. W49 extended the sweep to --pause-choice. The reset flag's advisory
    # text was added afterwards and was never swept - so the standing check PASSED while the surface
    # violated the rule that check exists to enforce.
    #
    # THE SWEEP IS THE REAL DEFECT. It enumerated two flags by hand, so it could only ever catch the
    # flags someone remembered to add to it. That is the enumerated-versus-derived lesson from the
    # self-leak firewall, arriving in the surface sweep - and it is why fixing only the two advisory
    # lines would leave the next flag to repeat this exactly.

    BeforeAll {
        # Feature 203 T008 (maintainer ruling 2026-11-09): the orchestrator joins, since the budget-spent message lives there now.
        $script:CoReviewSources = @(
            (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/continuous-co-review-navigator.ps1')
            (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/review-authority-core.ps1')
            (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/review-campaign-orchestrator.ps1')
        )
    }

    It 'RED-FIRST: the exhaustion advisories name the typed phrase, not only the flag' {
        foreach ($source in $script:CoReviewSources) {
            $text = Get-Content -LiteralPath $source -Raw -Encoding UTF8
            if (-not $text.Contains('--remediate allowance-reset')) { continue }
            $text | Should -Match 'approved for allowance reset' -Because (
                (Split-Path -Leaf $source) + ' hands the human a CLI flag for an act only their typed phrase can authorize')
        }
    }

    It 'RED-FIRST: the sweep DERIVES the authority flags it checks, rather than listing them' {
        # The fix that matters. A sweep that names its own flags can only catch the ones its author
        # thought of; the flag added next quarter walks past it in silence, which is exactly what
        # happened here.
        $sweep = Get-Content -LiteralPath (Join-Path $script:RepoRoot 'tests/continuous-co-review/unit/advisory-names-the-humans-act.Tests.ps1') -Raw -Encoding UTF8
        $sweep | Should -Match 'Get-SpecrewAuthorityFlagPhraseMap' -Because 'one table, read by the sweep, so a new flag is a decision rather than an omission'
        # And the table must live in SOURCE, where the advisories can read it too - not in the test.
        $store = Get-Content -LiteralPath (Join-Path $script:RepoRoot 'scripts/internal/bootstrap/HumanAuthorityStore.ps1') -Raw -Encoding UTF8
        $store | Should -Match 'function Get-SpecrewAuthorityFlagPhraseMap' -Because 'the advisory and its audit must read the same table, or they can disagree again'
    }

    It 'RED-FIRST: an authority flag appearing in an advisory with NO table entry fails the sweep' {
        # The derivation''s teeth: the sweep discovers flags from what the surfaces actually say. A flag
        # it has never heard of is a decision someone must make, not something to skip quietly.
        . (Join-Path $script:RepoRoot 'scripts/internal/bootstrap/HumanAuthorityStore.ps1')
        $map = Get-SpecrewAuthorityFlagPhraseMap
        $map.Keys | Should -Not -Contain '--approve-round' -Because 'feature 203 T008 removed the per-round approval and its flag'
        $map.Keys | Should -Contain '--pause-choice'
        $map.Keys | Should -Contain '--remediate allowance-reset' -Because 'the flag that started this must be in the table it should always have been in'
        [string]$map['--remediate allowance-reset'] | Should -Be 'approved for allowance reset'
    }

}

Describe 'PRED-BETA4-022 / B4F-065: a verdict is ONE line - a message that continues past its phrase is refused, disclosed, never minted' {
    # Maintainer ruling, 2026-09-10, on a live record in THIS repository: a 136-line Copilot shell
    # transcript from the router-skill project, pasted into a reviewer session with the human's typed
    # `approved for review round` still at its top, was minted here as a live review-round approval -
    # twice (UserPromptSubmit and Stop), under two encodings (one copy's apostrophe mangled to a
    # code-page triple), with spent_at null. The first line matched; the other 135 were never read.
    #
    # The rule: a verdict is the phrase plus at most the documented same-line instruction form; a
    # message continuing into multi-line content is refused, not minted. And because a refusal nobody
    # can see is B4F-043's silence again, the refusal carries a reason, is journaled in the
    # authority-capture-drops ledger the partial-signoff override already uses, and is said in the turn
    # with the one-line retype.
    #
    # The specimen below is the RECORDED SHAPE, not the recorded text: the same first six lines, the
    # same 136-line length, transcript-like content in between. The recorded text itself is another
    # project's session and stays in the record.
    BeforeAll {
        foreach ($dependency in @('ConversationCaptureAccessor', 'ClassificationEngine', 'ProjectMetadataAccessor', 'HandoverStore')) {
            . (Join-Path $script:RepoRoot ('scripts/internal/bootstrap/' + $dependency + '.ps1'))
        }
        . (Join-Path $script:RepoRoot 'extensions/specrew-speckit/scripts/shared-governance.ps1')
        $script:HandoverProvider = Join-Path $script:RepoRoot 'scripts/internal/specrew-handover-provider.ps1'
        function script:New-B4F065Specimen {
            param([string]$Head = 'approved for allowance reset')
            $lines = [System.Collections.Generic.List[string]]::new()
            $lines.Add($Head)
            $lines.Add('Thought for 1s')
            $lines.Add('')
            $lines.Add("I'll run the approved final review round against the iteration 002 planning artifacts.")
            $lines.Add('')
            $lines.Add('Shell Run approved live planning review 14 lines.')
            $n = 1
            while ($lines.Count -lt 133) {
                $lines.Add(('PS> pwsh -File scripts/specrew-review.ps1 --live --approve-round   # attempt {0}: exit 1' -f $n))
                $lines.Add('')
                $n++
            }
            $lines.Add("None right now - I'll proceed with the review retry and cursor repair.")
            $lines.Add('The session cannot move on from here.')
            return ($lines -join "`n")
        }
        function script:New-B4F065Root {
            $root = Join-Path ([IO.Path]::GetTempPath()) ('b4f065-' + [guid]::NewGuid().ToString('N'))
            New-Item -ItemType Directory -Path (Join-Path $root '.specrew') -Force | Out-Null
            return $root
        }
        function script:Read-B4F065Drops {
            param([string]$Root)
            $p = Join-Path $Root '.specrew/runtime/authority-capture-drops.jsonl'
            if (-not (Test-Path -LiteralPath $p)) { return @() }
            return @(Get-Content -LiteralPath $p -Encoding UTF8 | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | ForEach-Object { $_ | ConvertFrom-Json })
        }
    }

    It '1. the recorded shape is NOT matched, and the refusal names its reason' {
        $specimen = New-B4F065Specimen
        @($specimen -split "`n").Count | Should -Be 136 -Because 'the specimen is the recorded length'
        $r = Test-SpecrewAllowanceResetPhrase -Text $specimen
        [bool]$r.Matched | Should -BeFalse -Because 'a verdict is one line, and this message has 136'
        [string]$r.Reason | Should -Be 'multi-line-refused'
        $sweep = Get-SpecrewAuthorityMultiLineRefusal -Text $specimen
        $sweep | Should -Not -BeNullOrEmpty
        [string]$sweep.Kind | Should -Be 'allowance-reset'
        [int]$sweep.LineCount | Should -Be 136
        [string]$sweep.FirstLine | Should -Be 'approved for allowance reset'
    }

    It '2. every MINTING sibling refuses the same shape by reason; the WITHDRAWAL, which removes authority, does not' {
        $tail = ((New-B4F065Specimen) -split "`n", 2)[1]
        foreach ($case in @(
                @{ Fn = 'Test-SpecrewPauseDecisionPhrase'; Head = 'stop the review here' }
                @{ Fn = 'Test-SpecrewAllowanceResetPhrase'; Head = 'approved for allowance reset' }
                @{ Fn = 'Test-SpecrewCoverageDeferralPhrase'; Head = 'continue without coverage until the review phase' })) {
            $r = & $case.Fn -Text ($case.Head + "`n" + $tail)
            [bool]$r.Matched | Should -BeFalse -Because "$($case.Fn): the one-line rule is one rule, read by every minting recognizer"
            [string]$r.Reason | Should -Be 'multi-line-refused' -Because "$($case.Fn) refuses by reason"
            [bool](& $case.Fn -Text $case.Head).Matched | Should -BeTrue -Because "$($case.Fn): the bare phrase still mints"
        }
        # The withdrawal's floor cuts the other way - refusing it would fail OPEN, leaving an approval the
        # human retracted still spendable - so a withdrawal typed above a block of notes still withdraws.
        [bool](Test-SpecrewApprovalWithdrawalPhrase -Text ('withdraw the review round approval' + "`n" + $tail)).Matched |
            Should -BeTrue -Because 'the one-line rule bounds what MINTS; a withdrawal removes authority'
    }

    It '3. the boundary-verdict recognizer refuses the shape by reason too - the cross-project paste is not a boundary verdict either' {
        $tail = ((New-B4F065Specimen) -split "`n", 2)[1]
        $v = Test-SpecrewHumanVerdictToken -Text ('approved for plan' + "`n" + $tail)
        [bool]$v.IsApproval | Should -BeFalse
        [string]$v.Action | Should -Be 'refused-multi-line'
        [bool](Test-SpecrewHumanVerdictToken -Text 'approved for plan').IsApproval | Should -BeTrue -Because 'the phrase alone still authorizes'
        [bool](Test-SpecrewHumanVerdictToken -Text 'approved for plan - then start the retro.').IsApproval | Should -BeTrue -Because 'the same-line instruction form still authorizes'
    }

    It '4. the writer, handed the specimen at both source events, writes NOTHING; the one table the hooks call discloses it once' {
        $specimen = New-B4F065Specimen
        $root = New-B4F065Root
        try {
            foreach ($ev in @('UserPromptSubmit', 'Stop')) {
                $written = Write-SpecrewAllowanceResetAuthorization -ProjectRoot $root -Response $specimen -HostKind claude -SourceEvent $ev
                $written | Should -BeNullOrEmpty -Because "at $ev the writer mints nothing from a continuing message"
            }
            Test-Path -LiteralPath (Join-Path $root '.specrew/review/allowance-reset/pending-allowance-reset.json') | Should -BeFalse -Because 'no pending approval exists - the file the defect produced'
            $now = '2026-09-10T18:28:54.0000000+00:00'
            Invoke-SpecrewTypedAuthorityCapture -ProjectRoot $root -Response $specimen -HostKind claude -SourceEvent UserPromptSubmit -NowUtc $now -TurnPosition 'prompt-entry' -TurnArrival $now -MessageId 'msg-b4f065' -TurnOrigin 'typed-user' 2>$null
            Test-Path -LiteralPath (Join-Path $root '.specrew/review/allowance-reset/pending-allowance-reset.json') | Should -BeFalse -Because 'the table, which is what the hooks call, mints nothing either'
            $drops = @(Read-B4F065Drops -Root $root)
            $drops.Count | Should -Be 1 -Because 'the refusal is disclosed ONCE for the turn, whichever writer refused it'
            [string]$drops[0].event | Should -Be 'authority-phrase-matched-but-rejected'
            [string]$drops[0].phrase | Should -Be 'allowance-reset'
            [string]$drops[0].reason | Should -Be 'multi-line'
            [int]$drops[0].line_count | Should -Be 136
            [string]$drops[0].fix | Should -Match "send exactly one line: 'approved for allowance reset'" -Because 'the journal names the one move that clears it (B4F-064)'
            [string]$drops[0].source_event | Should -Be 'UserPromptSubmit'
        }
        finally { Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue }
    }

    It '4b. the prompt-entry provider says it IN THE TURN, where the human reads, and captures nothing' {
        $specimen = New-B4F065Specimen
        $root = New-B4F065Root
        try {
            $out = ((& pwsh -NoProfile -File $script:HandoverProvider --project-root $root --host-kind claude --source-event UserPromptSubmit --last-user-message $specimen 2>&1) -join "`n")
            $out | Should -Match 'NOT recorded as a allowance-reset' -Because 'the disclosure reaches the inject stdout, so it reaches the same turn'
            $out | Should -Match 'a verdict is ONE line' -Because 'it names the rule'
            $out | Should -Match "exactly one line: 'approved for allowance reset' or 'approved for allowance reset - <your instructions>'" -Because 'it names the retype, in the words the docs use'
            $out | Should -Match 'continues for 135 more line' -Because 'it says how far the message went on'
            Test-Path -LiteralPath (Join-Path $root '.specrew/review/allowance-reset/pending-allowance-reset.json') | Should -BeFalse
            @(Read-B4F065Drops -Root $root).Count | Should -Be 1
        }
        finally { Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue }
    }

    It '5. the one-line forms still mint, and a clean turn discloses NOTHING - the rule bounds pastes, not humans' {
        $root = New-B4F065Root
        try {
            foreach ($text in @('approved for allowance reset', 'approved for allowance reset.', 'approved for allowance reset - use the codex reviewer', "approved for allowance reset`n`n", "approved for allowance reset`r`n")) {
                [bool](Test-SpecrewAllowanceResetPhrase -Text $text).Matched | Should -BeTrue -Because ("still a verdict: " + ($text -replace "\r?\n", '\n'))
                Get-SpecrewAuthorityMultiLineRefusal -Text $text | Should -BeNullOrEmpty -Because 'nothing to disclose'
            }
            Get-SpecrewAuthorityMultiLineRefusal -Text "What is the status of the tests directory?`nAnd the lanes?" | Should -BeNullOrEmpty -Because 'ordinary multi-line conversation is not a refused verdict; the sweep fires only when a phrase led'
            $now = '2026-09-10T18:28:54.0000000+00:00'
            Invoke-SpecrewTypedAuthorityCapture -ProjectRoot $root -Response 'approved for allowance reset - use the codex reviewer' -HostKind claude -SourceEvent UserPromptSubmit -NowUtc $now -TurnPosition 'prompt-entry' -TurnArrival $now -MessageId 'msg-b4f065' -TurnOrigin 'typed-user' 2>$null
            Test-Path -LiteralPath (Join-Path $root '.specrew/review/allowance-reset/pending-allowance-reset.json') | Should -BeTrue -Because 'the same-line instruction form mints through the table'
            @(Read-B4F065Drops -Root $root).Count | Should -Be 0 -Because 'a clean turn writes no drop row'
        }
        finally { Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue }
    }

    It '6. MUTATION CONTROL: with the continuation guard removed, the SAME specimen mints - the recorded defect, reproduced on demand' {
        # The guard is what stands between the paste and the ledger. A copy of the store with
        # Test-SpecrewAuthorityMessageContinues answering "no" to everything is the pre-fix build; in a
        # child process, so nothing here is mutated. If this case ever goes green-by-accident (the
        # specimen refused for some OTHER reason), the fix above is not what is being tested.
        $specimen = New-B4F065Specimen
        $root = New-B4F065Root
        $mutant = Join-Path ([IO.Path]::GetTempPath()) ('b4f065-mutant-' + [guid]::NewGuid().ToString('N') + '.ps1')
        try {
            $source = Get-Content -LiteralPath (Join-Path $script:RepoRoot 'scripts/internal/bootstrap/HumanAuthorityStore.ps1') -Raw -Encoding UTF8
            $guardLine = '    return (-not [string]::IsNullOrWhiteSpace([string]$parts[1]))'
            ([regex]::Matches($source, [regex]::Escape($guardLine))).Count | Should -Be 1 -Because 'the mutation must hit exactly the guard'
            [IO.File]::WriteAllText($mutant, $source.Replace($guardLine, '    return $false'), [Text.UTF8Encoding]::new($false))
            $specimenPath = Join-Path $root 'specimen.txt'
            [IO.File]::WriteAllText($specimenPath, $specimen, [Text.UTF8Encoding]::new($false))
            $script = @(
                ('. "{0}"' -f (Join-Path $script:RepoRoot 'scripts/internal/bootstrap/ConversationCaptureAccessor.ps1'))
                ('. "{0}"' -f $mutant)
                ('$s = [IO.File]::ReadAllText("{0}")' -f $specimenPath)
                ('$w = Write-SpecrewAllowanceResetAuthorization -ProjectRoot "{0}" -Response $s -HostKind claude -SourceEvent UserPromptSubmit' -f $root)
                'Write-Output ("minted=" + ($null -ne $w))'
            ) -join "`n"
            $out = ((& pwsh -NoProfile -Command $script 2>&1) -join "`n")
            $out | Should -Match 'minted=True' -Because 'without the guard the first line decides and the paste mints - which is the record'
            $pending = Join-Path $root '.specrew/review/allowance-reset/pending-allowance-reset.json'
            Test-Path -LiteralPath $pending | Should -BeTrue -Because 'the file the defect produced, reproduced'
            $fact = Get-Content -LiteralPath $pending -Raw -Encoding UTF8 | ConvertFrom-Json
            @(([string]$fact.verdict_text) -split "`n").Count | Should -Be 136 -Because 'the whole transcript became verdict_text, as in the record'
        }
        finally {
            Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue
            Remove-Item -LiteralPath $mutant -Force -ErrorAction SilentlyContinue
        }
    }
}
