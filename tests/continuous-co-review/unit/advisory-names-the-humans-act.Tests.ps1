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

    It 'holds across the reader-facing strings in the co-review sources and the review CLI' {
        # The standing audit, retargeted twice. W44: every reader-facing line naming --approve-round
        # must carry the typed phrase. W49 extends it to --pause-choice: after W44, the pause menu spoke
        # two languages - option 1 a typed phrase, options 2 and 3 raw CLI commands with the
        # consequences stripped - and a human cannot know what they are choosing in a language that is
        # not theirs. So every reader-facing line naming --pause-choice must name at least one typed
        # decision, which makes it a MAPPING line by construction; a bare answer-channel line cannot
        # pass. The review CLI joins the file set so the terminal surfaces speak the same vocabulary.
        # W76 (2026-08-27): THE FLAGS ARE DERIVED, NOT LISTED.
        #
        # This audit used to name --approve-round and --pause-choice itself. The exhaustion advisory
        # naming `--remediate allowance-reset` was written later and nobody added it here, so THE AUDIT
        # PASSED WHILE THE SURFACE IT POLICES WAS IN VIOLATION - and it reached a human: a downstream
        # agent read that advisory and relayed the flag, correctly, because that is what it said.
        #
        # A list the auditor keeps can only catch what its author remembered. Now every `--flag` in a
        # reader-facing line is DISCOVERED, then resolved against the one table in source
        # (Get-SpecrewAuthorityFlagPhraseMap) that the advisories themselves read. A flag in the
        # authority table must name its phrase. A flag in neither table is reported as UNCLASSIFIED -
        # so the next flag added forces a decision instead of passing quietly.
        . (Join-Path $script:RepoRoot 'scripts/internal/bootstrap/HumanAuthorityStore.ps1')
        $authorityFlags = Get-SpecrewAuthorityFlagPhraseMap
        $exemptFlags = Get-SpecrewNonAuthorityFlagExemptions
        $pauseDecisions = @('run another round', 'stop the review here', 'abandon')
        $files = @(Get-ChildItem -LiteralPath (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review') -Filter '*.ps1' -File | ForEach-Object { $_.FullName })
        $files += (Join-Path $script:RepoRoot 'scripts/specrew-review.ps1')
        $offenders = [System.Collections.Generic.List[string]]::new()
        foreach ($file in $files) {
            $lineNumber = 0
            foreach ($line in @(Get-Content -LiteralPath $file -Encoding UTF8)) {
                $lineNumber++
                $trimmed = $line.TrimStart()
                if ($trimmed.StartsWith('#')) { continue }
                # A line that merely parses, matches, aliases or pattern-cases the flag is not an advisory.
                if ($line.Contains('-cmatch') -or $line.Contains('-match') -or $line.Contains('Alias(') -or $trimmed.StartsWith("'^--")) { continue }

                # Longest form first, so `--remediate allowance-reset` is not mistaken for a bare
                # `--remediate` and waved through by its exemption.
                foreach ($flag in @($authorityFlags.Keys | Sort-Object { $_.Length } -Descending)) {
                    if (-not $line.Contains($flag)) { continue }
                    $namesIt = if ($flag -ceq '--pause-choice') {
                        $lower = $line.ToLowerInvariant()
                        @($pauseDecisions | Where-Object { $lower.Contains($_) }).Count -gt 0
                    }
                    elseif ($flag -ceq '--approve-round') { Test-NamesTheDecision -Text $line }
                    else { $line.Contains([string]$authorityFlags[$flag]) }
                    if (-not $namesIt) { [void]$offenders.Add("$(Split-Path -Leaf $file):$lineNumber [$flag]") }
                    break
                }

                # UNCLASSIFIED flags: SPECREW'S OWN, discovered in a line that advises running a
                # `specrew review` command. Scoped that way deliberately - the first cut matched every
                # `--` token in these files and reported 108 offenders, almost all of them git plumbing
                # (`--name-only`, `--show-toplevel`) and reviewer-host argv, which are command
                # CONSTRUCTION and address no reader. An audit that cries wolf about 106 non-issues is
                # one nobody will keep, and its two real findings would have drowned in the noise.
                if ($line -notmatch '(?i)specrew\s+review') { continue }
                foreach ($m in [regex]::Matches($line, '--[a-z][a-z0-9-]{2,}')) {
                    $found = [string]$m.Value
                    if ($authorityFlags.ContainsKey($found) -or $exemptFlags.ContainsKey($found)) { continue }
                    if (@($authorityFlags.Keys | Where-Object { $_.StartsWith($found + ' ') }).Count -gt 0) { continue }
                    [void]$offenders.Add("$(Split-Path -Leaf $file):$lineNumber [$found is UNCLASSIFIED - add it to the authority table or the exemption table]")
                }
            }
        }
        @($offenders).Count | Should -Be 0 -Because "every reader-facing line naming an answer flag must name the typed decision it carries, and every flag must be classified (offenders: $($offenders -join ', '))"
    }

    It 'W54: every surface naming a captured phrase says it arrives as a normal chat message' {
        # W54 (maintainer ruling, 2026-08-24, from the KeyContextAI walk): a Copilot agent asked for
        # `approved for review round` through its ask-user tool twice; the replies arrived as tool
        # results, capture correctly refused both by typed-turns doctrine, and the human was asked
        # three times for one decision. Copilot actively steers agents toward the question UI, so
        # this is systematic. The fix is at the GUIDANCE layer - capture must not learn to read
        # pickers, because that reintroduces the dismissal hazard typed-turns-v1 exists to prevent -
        # so every advisory and refusal that names a hook-captured phrase carries the clause: the
        # reply is a normal chat message, and a question-UI or picker reply is not captured.
        $capturedPhrases = @('approved for review round', 'approved for allowance reset', 'continue without coverage until the review phase', 'approved for <boundary>')
        $clauseCore = 'normal chat message'
        $window = 15
        $files = @(Get-ChildItem -LiteralPath (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review') -Filter '*.ps1' -File | ForEach-Object { $_.FullName })
        $files += @(
            (Join-Path $script:RepoRoot 'scripts/specrew-review.ps1'),
            (Join-Path $script:RepoRoot 'scripts/internal/sync-boundary-state.ps1'),
            (Join-Path $script:RepoRoot 'extensions/specrew-speckit/scripts/specrew-conformance-provider.ps1'),
            (Join-Path $script:RepoRoot 'extensions/specrew-speckit/scripts/shared-governance.ps1')
        )
        $offenders = [System.Collections.Generic.List[string]]::new()
        foreach ($file in $files) {
            $lines = @(Get-Content -LiteralPath $file -Encoding UTF8)
            for ($i = 0; $i -lt $lines.Count; $i++) {
                $line = $lines[$i]
                $trimmed = $line.TrimStart()
                if ($trimmed.StartsWith('#')) { continue }
                # Recognizer patterns, writers and parser lines carry the phrase as DATA, not advisory.
                if ($line.Contains('-cmatch') -or $line.Contains('-match') -or $line.Contains('[regex]') -or $trimmed.StartsWith("'^")) { continue }
                $lower = $line.ToLowerInvariant()
                $named = $false
                foreach ($phrase in $capturedPhrases) { if ($lower.Contains($phrase)) { $named = $true; break } }
                if (-not $named) { continue }
                $clauseNearby = $false
                for ($j = [Math]::Max(0, $i - $window); $j -le [Math]::Min($lines.Count - 1, $i + $window); $j++) {
                    if ($lines[$j].ToLowerInvariant().Contains($clauseCore)) { $clauseNearby = $true; break }
                }
                if (-not $clauseNearby) { [void]$offenders.Add("$(Split-Path -Leaf $file):$($i + 1)") }
            }
        }
        @($offenders).Count | Should -Be 0 -Because "every advisory naming a captured phrase must say it arrives as a normal chat message - a question-UI or picker reply is not captured (offenders: $($offenders -join ', '))"
    }

    It 'W55: a refusal forbids BOUNDARY-VERDICT options, never the approvals its own remedy needs' {
        # W55 (maintainer ruling, 2026-08-24, from the cap-release notice firing on the crew): "Do
        # not present approval options" was doing two jobs. Its intent is to forbid boundary-verdict
        # MENUS when the evidence they would approve does not exist - but the only path to meeting
        # the released requirement IS an approval (the round approval that produces the evidence),
        # so a literal reading forbids asking for it. That is the Rule-28 shape: a strong model
        # threads it, a weak model obeys it into a wedge where it may neither proceed nor ask.
        # The clause must name what it forbids.
        $provider = Get-Content -LiteralPath (Join-Path $script:RepoRoot 'extensions/specrew-speckit/scripts/specrew-conformance-provider.ps1') -Raw -Encoding UTF8
        $offenders = [System.Collections.Generic.List[string]]::new()
        $lineNumber = 0
        foreach ($line in @(Get-Content -LiteralPath (Join-Path $script:RepoRoot 'extensions/specrew-speckit/scripts/specrew-conformance-provider.ps1') -Encoding UTF8)) {
            $lineNumber++
            if ($line.TrimStart().StartsWith('#')) { continue }
            $lower = $line.ToLowerInvariant()
            if ($lower -notmatch 'present approval options|render approval options') { continue }
            # The emitted prohibition must be scoped to boundary-verdict options AND must say that
            # asking for the evidence-producing approval is still the agent's job.
            if ($lower -notmatch 'boundary-verdict options') { [void]$offenders.Add("line ${lineNumber} [unscoped prohibition]") }
            elseif ($lower -notmatch 'remains your job') { [void]$offenders.Add("line ${lineNumber} [does not restore the ask]") }
        }
        @($offenders).Count | Should -Be 0 -Because "a refusal must forbid boundary-verdict options while leaving the evidence-producing ask intact (offenders: $($offenders -join ', '))"
        # The scoped form must actually be present - a sweep that finds nothing to check proves nothing.
        ([regex]::Matches($provider, [regex]::Escape('boundary-verdict options'))).Count |
            Should -BeGreaterOrEqual 4 -Because 'every refusal surface that suppressed approval menus carries the scoped wording'
    }

    It 'W49: no pause menu renders numbered option labels or a --flag as the answer channel' {
        # The menu is the human surface. Numbered labels teach bare-number replies - which are never
        # authority in this system - and a --flag is the agent's spelling, not the human's decision.
        foreach ($file in @('scripts/internal/continuous-co-review/continuous-co-review-navigator.ps1')) {
            $text = Get-Content -LiteralPath (Join-Path $script:RepoRoot $file) -Raw -Encoding UTF8
            $text | Should -Not -Match "Add\(\('  \{0\}\. \{1\}' -f \`$option" -Because 'option rendering must not number the labels'
            $text | Should -Not -Match "Answer with:\s+specrew review" -Because 'the menu must not hand the human a CLI command as the way to decide'
        }
    }

    It 'W49 exception (maintainer, 2026-08-23): the unauthorized-source exit menu is typed decisions, never numbered' {
        # Boundary-packet numbers stand on their recorded distinction - they index discussion prompts
        # inside one accepted typed phrase, and the verdict was never numbered. This surface is the ONE
        # exception: it numbers two DISTINCT decisions, and a typed `1` here was already quoted as an
        # implementation licence on the KeyContextAI walk. The W49 shape applied once more.
        $provider = Get-Content -LiteralPath (Join-Path $script:RepoRoot 'extensions\specrew-speckit\scripts\specrew-conformance-provider.ps1') -Raw -Encoding UTF8
        $block = [regex]::Match($provider, "(?s)elseif \(\`$blockKind -eq 'unauthorized-source'\) \{\s*\r?\n\s*# W47.+?\r?\n            \}").Value
        $block | Should -Not -BeNullOrEmpty
        $block.Contains('`approved for before-implement`') | Should -BeTrue -Because 'the licensing exit leads with its typed reply'
        $block.Contains('`revert the source changes`') | Should -BeTrue -Because 'the revert exit leads with its typed reply'
        $block | Should -Not -Match '\(\s*[12]\s*\)\s*(authorize|revert)' -Because 'numbered exits are the misreading the first live firing collected'
        $block.Contains('NEVER numbered') | Should -BeTrue -Because 'the instruction travels with the menu it governs'
    }
}

Describe 'W67 the round summary states the whole mix, and says plainly when nothing blocks' {
    # W67 (maintainer ruling, 2026-08-26): every human-facing round summary states HOW MANY findings,
    # how many BLOCKING, how many need the human's ACCEPTANCE, how many are NOTES - and what each
    # decision does given that mix. And when nothing blocks, it says so plainly, so stopping here
    # reads as the ordinary next step rather than a concession the human is talking themselves into.
    #
    # The shape this replaces made the reader assemble the mix themselves out of a gating list, a
    # trailing minors sentence and a demotion note - three places, no total anywhere, and no sentence
    # that said "nothing here blocks sign-off" even when nothing did.
    BeforeAll {
        . (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/continuous-co-review-navigator.ps1')
        function script:New-MixFinding {
            param([string]$Severity, [string]$Title = 'a finding', [string]$Location = 'src/x.ps1:1')
            return [pscustomobject]@{ severity = $Severity; title = $Title; description = 'detail'; location = $Location }
        }
        function script:Render-Mix {
            param([object[]]$Findings, [int]$RoundsUsed = 1, [int]$BudgetTotal = 4)
            $decision = Resolve-ReviewCampaignPauseDecision -Findings $Findings -RoundsUsed $RoundsUsed -BudgetTotal $BudgetTotal -ElapsedMinutes 12
            return (Format-ReviewCampaignPauseSurface -ProjectName 'mixdemo' -Decision $decision)
        }
    }

    It 'states the counts as one mix a reader can hold: total, blocking, needing acceptance, notes' {
        $surface = script:Render-Mix -Findings @(
            (script:New-MixFinding -Severity 'blocking' -Title 'auth bypass' -Location 'src/auth.ps1:12'),
            (script:New-MixFinding -Severity 'major'),
            (script:New-MixFinding -Severity 'minor'),
            (script:New-MixFinding -Severity 'minor'))
        $surface | Should -Match '(?i)4 findings'
        $surface | Should -Match '(?i)1 blocks sign-off'
        $surface | Should -Match '(?i)1 needs your acceptance'
        $surface | Should -Match '(?i)2 are notes'
    }

    It 'when NOTHING blocks, it says so plainly and frames stopping here as the ordinary next step' {
        # The wording the ruling asked for. A human reading a minors-only round should not have to
        # infer that stopping is safe; the surface says nothing blocks and what stopping does.
        $surface = script:Render-Mix -Findings @(
            (script:New-MixFinding -Severity 'minor'),
            (script:New-MixFinding -Severity 'minor'),
            (script:New-MixFinding -Severity 'minor'))
        $surface | Should -Match '(?i)nothing here blocks sign-off'
        $surface | Should -Match '(?i)3 findings'
        $surface | Should -Match '(?i)0 block sign-off|none block sign-off'
        $surface | Should -Match '(?i)3 are notes'
        # And the decision text says what stopping does GIVEN that mix - notes carried, not accepted
        # under protest.
        $surface | Should -Match '(?i)stop the review here'
        $surface | Should -Not -Match '(?i)accept the remaining findings anyway' -Because 'nothing is being conceded when nothing blocks'
    }

    It 'a round with acceptances says what stopping means for them, without calling notes acceptances' {
        $surface = script:Render-Mix -Findings @(
            (script:New-MixFinding -Severity 'major'),
            (script:New-MixFinding -Severity 'major'),
            (script:New-MixFinding -Severity 'minor'))
        $surface | Should -Match '(?i)3 findings'
        $surface | Should -Match '(?i)2 need your acceptance'
        $surface | Should -Match '(?i)1 is a note'
        # Majors do not block, so "nothing blocks" is TRUE and worth saying - but the same sentence
        # must not imply nothing is being asked of the human, because an acceptance IS.
        $surface | Should -Match '(?i)nothing here blocks sign-off'
        $surface | Should -Match '(?i)accepts those findings as follow-ups' -Because 'the acceptance is the thing stopping here actually does here'
        $surface | Should -Not -Match '(?i)nothing needs your acceptance' -Because 'two findings do'
    }

    It 'the resumed surface carries the same mix, so coming back a day later reads the same' {
        # The returning consumer is exactly who cannot reconstruct the mix from memory.
        $fact = [pscustomobject]@{
            schema_version = '1.0'; fact_type = 'pending-pause'; campaign_id = 'cmp-mixdemo-i001'
            run_id = 'run-mix'; target_digest = 'digest-mix'; blocking_count = 0; major_count = 0
            minor_count = 2; demoted_count = 0; rounds_used = 1; budget_total = 4; elapsed_minutes = 12.0
            recommendation = 'Nothing here blocks you.'; observed_at = '2026-08-26T10:00:00.0000000+00:00'
            result_produced = $true
        }
        # This renderer returns an ARRAY of lines; piping it to Should -Match would test each line
        # separately and fail on the first that does not match.
        $resumed = (@(Format-ReviewCampaignOutstandingPause -ProjectName 'mixdemo' -Fact $fact `
            -Findings @((script:New-MixFinding -Severity 'minor'), (script:New-MixFinding -Severity 'minor'))) -join "`n")
        $resumed | Should -Match '(?i)2 findings'
        $resumed | Should -Match '(?i)nothing here blocks sign-off'
    }
}

