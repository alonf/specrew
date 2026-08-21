#requires -Version 7.0
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# W36 (2026-08-21): an advisory the agent reads must not hand it the human's approval command.
#
# The stop hook carries the review block into agent context, where "What to do: run a fresh review of
# your files as they are now: specrew review --live --approve-round" reads as a to-do. That flag is
# documented at scripts/specrew-review.ps1 as "Approve one review round. Specrew records your approval
# and mints the reference itself" - it exists so the approval phrase cannot be forged. Naming it with
# no owner hands an agent the one command whose entire purpose is recording the HUMAN's decision.
#
# This is the W15 shape - guidance naming an action the reader must not take - and worse than W15,
# because W15 offered an obviously forbidden action while this one looks routine. On the 2026-08-20
# walk the agent noticed and held. An earlier host, under less provocation, hand-wrote a controller.
#
# THE FIX IS NOT DELETING THE COMMAND. The navigator's own comment records why it is named: neither
# dogfood host could discover the flag, so both improvised an authorization. Discoverability and
# attribution are both required, so the line keeps the command AND says whose act it is.

BeforeAll {
    $script:RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
    . (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/continuous-co-review-navigator.ps1')

    # Written without regex: every generated pattern in this slice has had its escapes mangled at least
    # once, and plain string work has nothing to mangle.
    $script:ApprovalFlag = '--approve-round'
    $script:OwnerTokens = @('ask the human', "human's", 'their decision', 'your approval', "human''s")

    function script:Test-NamesTheOwner {
        param([Parameter(Mandatory)][AllowEmptyString()][string]$Text)
        $lower = $Text.ToLowerInvariant()
        foreach ($token in $script:OwnerTokens) { if ($lower.Contains($token.ToLowerInvariant())) { return $true } }
        return $false
    }
}

Describe 'W36 the review-request advisories name whose act it is' {
    It 'attributes the approval command to the human for request-current-digest-review' {
        $sentence = Get-ReviewCampaignActionSentence -Action 'request-current-digest-review'
        $sentence | Should -Not -BeNullOrEmpty
        # Discoverability is preserved - the command stays, because removing it is what produced two
        # invented authorizations in the first place.
        $sentence.Contains($script:ApprovalFlag) | Should -BeTrue -Because 'the flag must remain discoverable'
        Test-NamesTheOwner -Text $sentence | Should -BeTrue -Because 'and the line must say whose act it is'
    }

    It 'attributes the approval command to the human for request-authorized-review' {
        $sentence = Get-ReviewCampaignActionSentence -Action 'request-authorized-review'
        $sentence.Contains($script:ApprovalFlag) | Should -BeTrue
        Test-NamesTheOwner -Text $sentence | Should -BeTrue
    }

    It 'leaves advisories that name no approval command alone' {
        # The rule is about the approval flag, not about every sentence having an owner clause.
        $sentence = Get-ReviewCampaignActionSentence -Action 'poll-existing-run'
        $sentence | Should -Not -BeNullOrEmpty
        $sentence.Contains($script:ApprovalFlag) | Should -BeFalse
    }

    It 'still returns empty for an unknown action rather than echoing the token' {
        Get-ReviewCampaignActionSentence -Action 'not-a-real-action' | Should -BeNullOrEmpty
    }
}

Describe 'W36 the agent channel says the command is not the agent to run' {
    It 'tells the agent, in its own channel, not to record the approval' {
        # The consumer block explains the act; the agent's private channel draws the boundary around who
        # performs it. Putting it only in the human block would leave the agent inferring.
        $decision = [pscustomobject]@{ ask_narrow_question = $false; route = 'review-required'; message = 'x'; run_id = ''; implementer_action = 'request-authorized-review' }
        $directive = Build-ReviewCampaignNavigatorAgentDirective -PacketDecision $decision -PendingCrossing $null
        $directive | Should -Not -BeNullOrEmpty
        $directive.Contains($script:ApprovalFlag) | Should -BeTrue
        Test-NamesTheOwner -Text $directive | Should -BeTrue
        $directive.ToLowerInvariant().Contains('do not run it') | Should -BeTrue
    }
}

Describe 'W36 THE GENERAL PROPERTY - no advisory names the approval flag without an owner' {
    It 'holds across every action the sentence generator can produce' {
        # The specific two are fixed above; this is the class. A new action added later that names the
        # flag without saying whose it is fails here rather than reaching an agent.
        $actions = @('request-current-digest-review', 'request-authorized-review', 'poll-existing-run',
            'proceed', 'await-human-pause-decision', 'reconcile-run-claim', 'repair-review-state')
        $offenders = [System.Collections.Generic.List[string]]::new()
        foreach ($action in $actions) {
            $sentence = [string](Get-ReviewCampaignActionSentence -Action $action)
            if ([string]::IsNullOrWhiteSpace($sentence)) { continue }
            if (-not $sentence.Contains($script:ApprovalFlag)) { continue }
            if (-not (Test-NamesTheOwner -Text $sentence)) { [void]$offenders.Add($action) }
        }
        @($offenders).Count | Should -Be 0 -Because "an advisory that names the approval flag must say it is the human's (offenders: $($offenders -join ', '))"
    }

    It 'holds across the reader-facing strings in the co-review sources' {
        # The audit the finding asked for, as a standing check rather than a one-off sweep. Scans the
        # co-review sources for reader-facing string literals that name the approval flag and requires
        # each to carry an owner clause. Comments are skipped: they explain, they do not instruct.
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
                if (-not (Test-NamesTheOwner -Text $line)) { [void]$offenders.Add("$($file.Name):$lineNumber") }
            }
        }
        @($offenders).Count | Should -Be 0 -Because "every reader-facing line naming the approval flag must attribute it (offenders: $($offenders -join ', '))"
    }
}
