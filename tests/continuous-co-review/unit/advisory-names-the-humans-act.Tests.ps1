#requires -Version 7.0
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# W36 (2026-08-21), REWRITTEN BY W44 (2026-08-22, maintainer ruling): the advisory names a DECISION for
# the human and an EXECUTION for the agent, matching their roles.
#
# W36 drew the ownership line in the wrong place. It made the COMMAND the human's to run - the one role
# this system never gives the human anywhere else. Boundary verdicts, partial signoff and workshop
# repair are all typed phrases captured from conversation, with the agent operating the machinery
# afterwards; round approval alone demanded the human execute a CLI command, and it failed as UX on day
# one (the bash-PATH seam): the human is in a conversation, not a terminal.
#
# The model now: the human's typed reply `approved for review round` is the approval, captured by the
# hooks; the agent runs `specrew review --live --approve-round` carrying that captured phrase as its
# authority, and the CLI refuses an agent invocation that has none. So the advisory must name BOTH
# halves - the phrase to ask for (the decision) and the command to run afterwards (the execution) -
# and must never tell the agent the command is forbidden, because with a captured approval it is the
# agent's job.
#
# What survives from W36 unchanged: discoverability (the command stays named - deleting it is what
# produced two invented authorizations), and the prohibition on the agent RECORDING or fabricating an
# approval on the human's behalf.

BeforeAll {
    $script:RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
    . (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/continuous-co-review-navigator.ps1')

    # Written without regex: every generated pattern in this slice has had its escapes mangled at least
    # once, and plain string work has nothing to mangle.
    $script:ApprovalFlag = '--approve-round'
    $script:TypedPhrase = 'approved for review round'

    function script:Test-NamesTheDecision {
        # The human's half: the typed phrase, verbatim, so the reader can relay it without inventing.
        param([Parameter(Mandatory)][AllowEmptyString()][string]$Text)
        return $Text.ToLowerInvariant().Contains($script:TypedPhrase)
    }
    function script:Test-NamesTheExecution {
        # The agent's half: after the phrase, running the command is the reader's own act.
        param([Parameter(Mandatory)][AllowEmptyString()][string]$Text)
        $lower = $Text.ToLowerInvariant()
        return ($lower.Contains('run') -and $lower.Contains($script:ApprovalFlag))
    }
}

Describe 'W44 the review-request advisories split decision from execution' {
    It 'request-current-digest-review names the phrase to ask for AND the command to run after' {
        $sentence = Get-ReviewCampaignActionSentence -Action 'request-current-digest-review'
        $sentence | Should -Not -BeNullOrEmpty
        Test-NamesTheDecision -Text $sentence | Should -BeTrue -Because 'the typed phrase is the decision, and the reader must be able to relay it verbatim'
        Test-NamesTheExecution -Text $sentence | Should -BeTrue -Because 'the command stays discoverable - removing it produced two invented authorizations'
    }

    It 'request-authorized-review names both halves too' {
        $sentence = Get-ReviewCampaignActionSentence -Action 'request-authorized-review'
        Test-NamesTheDecision -Text $sentence | Should -BeTrue
        Test-NamesTheExecution -Text $sentence | Should -BeTrue
    }

    It 'offers the manual review as the alternative that spends nothing' {
        # The human reading the artifacts is a legitimate ask; the human operating the CLI is not.
        $sentence = Get-ReviewCampaignActionSentence -Action 'request-current-digest-review'
        $sentence.ToLowerInvariant().Contains('review the artifacts themselves') | Should -BeTrue
    }

    It 'does not tell the human to run the command as their own act' {
        # The W36 wording this suite used to REQUIRE. A human in a conversation is not at a terminal,
        # and operating the machinery is the one role this system gives the agent everywhere else.
        foreach ($action in @('request-current-digest-review', 'request-authorized-review')) {
            $sentence = [string](Get-ReviewCampaignActionSentence -Action $action)
            $sentence.ToLowerInvariant().Contains('ask the human to run') | Should -BeFalse -Because 'the human decides; the agent operates'
        }
    }

    It 'leaves advisories that name no approval command alone' {
        $sentence = Get-ReviewCampaignActionSentence -Action 'poll-existing-run'
        $sentence | Should -Not -BeNullOrEmpty
        $sentence.Contains($script:ApprovalFlag) | Should -BeFalse
    }

    It 'still returns empty for an unknown action rather than echoing the token' {
        Get-ReviewCampaignActionSentence -Action 'not-a-real-action' | Should -BeNullOrEmpty
    }
}

Describe 'W44 the agent channel states the split, not a prohibition on the command' {
    It 'tells the agent to ask for the phrase, never fabricate, and then run the command itself' {
        $decision = [pscustomobject]@{ ask_narrow_question = $false; route = 'review-required'; message = 'x'; run_id = ''; implementer_action = 'request-authorized-review' }
        $directive = Build-ReviewCampaignNavigatorAgentDirective -PacketDecision $decision -PendingCrossing $null
        $directive | Should -Not -BeNullOrEmpty
        $lower = $directive.ToLowerInvariant()
        Test-NamesTheDecision -Text $directive | Should -BeTrue
        $lower.Contains('never record or fabricate') | Should -BeTrue -Because 'what survives from W36 is the prohibition on inventing the approval'
        $lower.Contains('your job') | Should -BeTrue -Because 'execution is the agent role, stated in the agent channel'
        $lower.Contains('do not run it') | Should -BeFalse -Because 'the W36 prohibition is the ruling this suite was rewritten to retire'
    }
}

Describe 'W44 THE GENERAL PROPERTY - no advisory names the flag without naming the typed phrase' {
    It 'holds across every action the sentence generator can produce' {
        $actions = @('request-current-digest-review', 'request-authorized-review', 'poll-existing-run',
            'proceed', 'await-human-pause-decision', 'reconcile-run-claim', 'repair-review-state')
        $offenders = [System.Collections.Generic.List[string]]::new()
        foreach ($action in $actions) {
            $sentence = [string](Get-ReviewCampaignActionSentence -Action $action)
            if ([string]::IsNullOrWhiteSpace($sentence)) { continue }
            if (-not $sentence.Contains($script:ApprovalFlag)) { continue }
            if (-not (Test-NamesTheDecision -Text $sentence)) { [void]$offenders.Add($action) }
        }
        @($offenders).Count | Should -Be 0 -Because "an advisory naming the flag must name the typed phrase that authorizes it (offenders: $($offenders -join ', '))"
    }

    It 'holds across the reader-facing strings in the co-review sources' {
        # The standing audit, retargeted: every reader-facing line naming the approval flag must carry
        # the typed phrase, so no advisory can regress to treating bare invocation as the approval.
        $sourceDir = Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review'
        $offenders = [System.Collections.Generic.List[string]]::new()
        foreach ($file in @(Get-ChildItem -LiteralPath $sourceDir -Filter '*.ps1' -File)) {
            $lineNumber = 0
            foreach ($line in @(Get-Content -LiteralPath $file.FullName -Encoding UTF8)) {
                $lineNumber++
                $trimmed = $line.TrimStart()
                if ($trimmed.StartsWith('#')) { continue }
                if (-not $line.Contains($script:ApprovalFlag)) { continue }
                # A line that merely parses or matches the flag is not an advisory.
                if ($line.Contains('-cmatch') -or $line.Contains('-match') -or $line.Contains('Alias(')) { continue }
                if (-not (Test-NamesTheDecision -Text $line)) { [void]$offenders.Add("$($file.Name):$lineNumber") }
            }
        }
        @($offenders).Count | Should -Be 0 -Because "every reader-facing line naming the approval flag must name the typed phrase (offenders: $($offenders -join ', '))"
    }
}
