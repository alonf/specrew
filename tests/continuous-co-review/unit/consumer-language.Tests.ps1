$ErrorActionPreference = 'Stop'

# Trace: T010 / FR-015, FR-016 / SC-009.
#
# THE DEFECT CLASS, in the words the acceptance bar uses: "a sentence they cannot understand". Three
# instances measured in this session, and they are the same failure wearing different clothes:
#
#   - the stale block named a run and a snapshot, all true, and omitted the one fact that made it
#     dismissible - so the reader investigated and found nothing
#   - its only remediation was addressed to a role the reader might not hold, so the block could never
#     be cleared and re-fired forever
#   - a bare T### or FR-### is the same thing at sentence scale: an identifier the reader must go and
#     look up before the sentence means anything
#
# An ID the reader must look up is a sentence they cannot understand. The gloss is the fix.
Describe 'Consumer language layer (T010)' {
    BeforeAll {
        $script:RepoRoot = (Resolve-Path "$PSScriptRoot/../../..").Path
        . (Join-Path $script:RepoRoot 'scripts/internal/specrew-consumer-language.ps1')
    }

    Context 'the gloss helper: an identifier never travels alone' {
        It 'renders id + short description in the shape a human reads' {
            Format-SpecrewIdGloss -Id 'T006' -Title 'reparse-tag discrimination' |
                Should -Be 'T006 (reparse-tag discrimination)'
        }

        It 'REFUSES an id with no description, rather than emitting a bare id' {
            # The whole point: a helper that silently passed the id through would let every caller
            # produce exactly the defect it exists to prevent.
            { Format-SpecrewIdGloss -Id 'FR-013' -Title '' } | Should -Throw '*description*'
            { Format-SpecrewIdGloss -Id 'FR-013' -Title '   ' } | Should -Throw '*description*'
        }

        It 'refuses an empty id too' {
            { Format-SpecrewIdGloss -Id '' -Title 'something' } | Should -Throw
        }
    }

    Context 'the detector: an unglossed ID in consumer text is a failure' {
        It 'finds a bare T### and a bare FR-###' {
            $found = @(Get-SpecrewUnglossedId -Text 'Blocked by T006 until FR-013 lands.')
            $found | Should -Contain 'T006'
            $found | Should -Contain 'FR-013'
        }

        It 'accepts an id that carries a parenthesised description' {
            @(Get-SpecrewUnglossedId -Text 'Blocked by T006 (reparse-tag discrimination) until then.') |
                Should -BeNullOrEmpty
        }

        It 'a description must be more than a space - an empty gloss is still unglossed' {
            @(Get-SpecrewUnglossedId -Text 'Blocked by T006 () until then.') | Should -Contain 'T006'
        }

        It 'only the FIRST use must be glossed, so prose stays readable' {
            # Requiring every occurrence would push authors toward dropping the id entirely, which is
            # worse: the reader loses the handle they need to search records.
            $text = 'T006 (reparse-tag discrimination) is done. T006 also covers the docs.'
            @(Get-SpecrewUnglossedId -Text $text) | Should -BeNullOrEmpty
        }

        It 'is silent on text with no identifiers at all' {
            @(Get-SpecrewUnglossedId -Text 'Your review is signed off.') | Should -BeNullOrEmpty
        }

        It 'does not fire on ordinary words that merely contain letters and digits' {
            # A detector that flags version strings or hashes would be turned off within a week.
            @(Get-SpecrewUnglossedId -Text 'Version 0.40.0-beta3 at commit a1b2c3d4.') | Should -BeNullOrEmpty
        }
    }

    # THE SURFACE GUARD. The set is defined by a PROPERTY - "is passed as -Message to the decision
    # builder" - not by a list of strings I happened to find. That is the staged rule applied to my own
    # guard: an enumeration would report completeness over my list, and the seventh message added next
    # week would not be in it.
    Context 'every consumer-facing decision message is in consumer language' {
        BeforeAll {
            $script:GateSource = Get-Content -LiteralPath (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/review-signoff-evidence-gate.ps1') -Raw
            $script:GateMessages = @([regex]::Matches($script:GateSource, "-Message '(?<s>[^']+)'") | ForEach-Object { $_.Groups['s'].Value })
        }

        It 'the guard actually finds messages (a scan that matches nothing proves nothing)' {
            @($script:GateMessages).Count | Should -BeGreaterOrEqual 25 -Because 'a FLOOR, so a regex that silently stops matching is caught rather than reported as clean'
        }

        It 'no decision message carries internal machinery vocabulary' {
            $offenders = [Collections.Generic.List[string]]::new()
            foreach ($message in $script:GateMessages) {
                foreach ($noun in @(Get-SpecrewBannedConsumerNoun -Text $message)) {
                    $offenders.Add(("[{0}] {1}" -f $noun, $message)) | Out-Null
                }
            }
            # MEASURED before this landed: six of twenty-nine carried `digest`, one of those also
            # `claim-ordered`. Every one was a sentence a consumer reads at a stop.
            @($offenders) -join "`n" | Should -BeNullOrEmpty -Because 'a stop message is where a consumer is standing when they decide; internal vocabulary there is the acceptance bar failing'
        }

        It 'no decision message carries an unglossed identifier' {
            $offenders = [Collections.Generic.List[string]]::new()
            foreach ($message in $script:GateMessages) {
                foreach ($id in @(Get-SpecrewUnglossedId -Text $message)) {
                    $offenders.Add(("[{0}] {1}" -f $id, $message)) | Out-Null
                }
            }
            @($offenders) -join "`n" | Should -BeNullOrEmpty -Because 'an identifier the reader must look up is a sentence they cannot understand'
        }
    }

    # THE RULE, RESTATED BY EMISSION POINT (maintainer, 2026-08-11). My first scoping said "rendered
    # output is a consumer surface; the instructions that produce it are not" - which is the wrong AXIS.
    # The line is not which FILE the text lives in, it is WHERE THE TEXT IS EMITTED. Text a human reads
    # at a stop is a consumer surface WHEREVER it is composed.
    #
    # The proof: the block a consumer actually reads is composed of SIX lines in the navigator, and the
    # earlier guard covered exactly ONE of them - the -Message literal. The other five carried every
    # defect the fix was about, including `crossing crossing-` stuttered, a 64-character hex id with no
    # gloss, and - decisively - an INSTRUCTION TO THE AGENT printed inside the human's message.
    #
    # The skill exemption still stands and is unchanged: an agent cannot act on a thing it is forbidden
    # to be told the name of. The agent is a different reader, not a lesser one - so its directives get
    # their own channel rather than being deleted.
    Context 'the STOP BLOCK a human reads - every line, not just the message' {
        BeforeAll {
            . (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/_load.ps1')
            . (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/continuous-co-review-navigator.ps1')

            function script:New-StaleBlock {
                param([switch]$WithCrossing)
                $decision = New-ReviewCampaignVerdictPacketDecision -Route 'review-stale' `
                    -Reason 'latest-result-not-current' -Message 'Your earlier review no longer covers these files.' `
                    -CampaignId 'cmp-199-x-i001' -RunId 'run-20260810-085753967-af5bef76' `
                    -TargetDigest ('a' * 40) -ImplementerAction 'request-current-digest-review'
                $crossing = if ($WithCrossing) {
                    [pscustomobject]@{
                        crossing_id = 'crossing-fdfd08331c434810bfb008886e73a3476306c1bf484c84813463914ae4ba0605'
                        from_boundary = 'before-implement'; to_boundary = 'review-signoff'
                    }
                }
                else { $null }
                return (Build-ReviewCampaignNavigatorStopBlock -PacketDecision $decision -PendingCrossing $crossing)
            }
        }

        It 'carries NO agent directive - the agent has its own channel' {
            # The decisive case. `do NOT emit a SPECREW-VERDICT-BOUNDARY marker` is the agent's private
            # instruction printed in front of the consumer.
            $block = script:New-StaleBlock
            $block | Should -Not -Match 'SPECREW-VERDICT-BOUNDARY'
            $block | Should -Not -Match '(?i)do NOT emit'
            $block | Should -Not -Match '(?i)Ask only the narrow'
        }

        It 'the agent directives still EXIST, on their own channel' {
            # Moved, not deleted: the agent must still be told. Same guarantee, different emission point.
            $decision = New-ReviewCampaignVerdictPacketDecision -Route 'review-stale' -Reason 'r' `
                -Message 'm' -CampaignId 'cmp-199-x-i001' -RunId 'run-x' -TargetDigest ('a' * 40) `
                -ImplementerAction 'request-current-digest-review'
            $directives = Build-ReviewCampaignNavigatorAgentDirective -PacketDecision $decision -PendingCrossing $null
            $directives | Should -Match 'SPECREW-VERDICT-BOUNDARY'
        }

        It 'the navigator CARRIES the agent channel beside the block (source guard)' {
            # Creating the channel without wiring it would break the "moved, not deleted" promise and
            # leave the agent with no directive at all - a worse outcome than the defect being fixed.
            # Guarded here because a unit fixture cannot reach that assignment without the full
            # navigator harness.
            $source = Get-Content -LiteralPath (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/worktree-navigator.ps1') -Raw
            $source | Should -Match 'Build-ReviewCampaignNavigatorAgentDirective' -Because 'the directives must actually be produced, not merely producible'
            $source | Should -Match 'agent_directives'
        }

        It 'THE SECOND human block - a blocking co-review verdict - obeys the same rule' {
            # Found by re-verifying BY EMISSION POINT instead of by file. There are TWO blocks a human
            # reads at a stop, and the first pass only found one. This one carried the identical defect:
            # `do NOT emit a SPECREW-VERDICT-BOUNDARY marker` inside the human's message.
            $verdict = [pscustomobject]@{
                raw = [pscustomobject]@{
                    findings = @([pscustomobject]@{
                            severity = 'blocking'; comment = 'Unvalidated input reaches the shell.'
                            location = [pscustomobject]@{ path = 'src/app.ps1'; line_start = 10 }
                        })
                }
            }
            $block = Build-ContinuousCoReviewNavigatorStopBlock -Verdict $verdict -RunId 'run-blocking-x' -BlackboardRef ''

            $block | Should -Not -Match 'SPECREW-VERDICT-BOUNDARY' -Because 'an agent directive in the human''s block is the defect the emission-point rule exists for'
            $block | Should -Not -Match '(?i)do NOT emit'
            $block | Should -Match '(?i)your tree is unchanged' -Because 'DEMOTE, NEVER DISCARD: the reassurance in that line is for the human and must survive the split'
            $block | Should -Match 'src/app\.ps1:10' -Because 'the finding location is what the human acts on'
        }

        It 'its agent directive still exists, on the agent channel' {
            $verdict = [pscustomobject]@{ raw = [pscustomobject]@{ findings = @() } }
            $directive = Build-ContinuousCoReviewNavigatorAgentDirective -Verdict $verdict
            $directive | Should -Match 'SPECREW-VERDICT-BOUNDARY'
        }

        It 'THE THIRD emission point - console inject-notes - obeys the same rule' {
            # Found by sweeping EMISSION POINTS rather than files. inject_notes are printed to the
            # human, so they are a consumer surface even though they are not a "block". Measured when
            # this guard was written: 17 notes, 2 carrying `digest` - the other 15 were already written
            # in consumer language, which is the shape T010 generalises FROM.
            $offenders = [Collections.Generic.List[string]]::new()
            foreach ($file in @('continuous-co-review-navigator.ps1', 'worktree-navigator.ps1')) {
                $src = Get-Content -LiteralPath (Join-Path $script:RepoRoot ('scripts/internal/continuous-co-review/' + $file)) -Raw
                foreach ($match in [regex]::Matches($src, '\[co-review\][^"'']{20,}')) {
                    foreach ($noun in @(Get-SpecrewBannedConsumerNoun -Text $match.Value)) {
                        $offenders.Add(("[{0}] {1}" -f $noun, $match.Value)) | Out-Null
                    }
                }
            }
            @($offenders) -join "`n" | Should -BeNullOrEmpty -Because 'a console line the human reads is a consumer surface, block or not'
        }

        It 'no line carries a banned noun' {
            foreach ($block in @((script:New-StaleBlock), (script:New-StaleBlock -WithCrossing))) {
                foreach ($line in ($block -split "`n")) {
                    @(Get-SpecrewBannedConsumerNoun -Text $line) -join ',' |
                        Should -BeNullOrEmpty -Because "every line a human reads is a consumer surface: $line"
                }
            }
        }

        It 'the block still tells the reader WHAT TO DO - in words, with the command' {
            # SELF-CAUGHT ON A LIVE STOP. The first rewrite deleted `Implementer action:
            # request-current-digest-review` instead of translating it, and the block rendered with no
            # actionable step at all. The complaint about that line was that it was MACHINERY ADDRESSED
            # TO A ROLE - not that the reader does not need a next step. Deleting it traded one unusable
            # sentence for a missing one.
            $block = script:New-StaleBlock
            $block | Should -Match '(?i)what to do'
            $block | Should -Match 'specrew review --live'
            $block | Should -Not -Match 'request-current-digest-review' -Because 'the ACT belongs in the human''s block; the token belongs on the machine channel'
        }

        It 'an UNKNOWN action prints no line at all, rather than echoing the token' {
            # A line printing an internal identifier is worse than no line: it looks like an instruction
            # the reader has failed to follow.
            Get-ReviewCampaignActionSentence -Action 'some-future-action-nobody-glossed' | Should -BeNullOrEmpty
        }

        It 'the run identifier is glossed, not bare' {
            $block = script:New-StaleBlock
            $block | Should -Match 'run-20260810-085753967-af5bef76'
            $block | Should -Match '(?i)\(.*(support|reference|identifies).*\)' -Because 'a bare 30-character id is a thing the reader must look up before the line means anything'
        }

        It 'the route name is glossed into something a human can act on' {
            $block = script:New-StaleBlock
            ($block -split "`n")[0] | Should -Not -Match 'review-stale' -Because 'a raw route name is internal vocabulary in the very first line the reader sees'
        }

        It 'says NOTHING stuttered, and glosses the crossing id it names' {
            $block = script:New-StaleBlock -WithCrossing
            $block | Should -Not -Match 'crossing crossing-' -Because 'the label and the id both said "crossing"'
            $block | Should -Match 'before-implement' -Because 'the boundaries are the part a human can act on'
        }
    }

    Context 'the banned-noun check: internal vocabulary never reaches a consumer surface' {
        It 'flags machinery nouns' -ForEach @(
            @{ noun = 'crossing' }, @{ noun = 'digest' }, @{ noun = 'ratchet' }
            @{ noun = 'terminalize' }, @{ noun = 'claim-ordered' }, @{ noun = 'controller truth' }
            @{ noun = 'workshop controller' }, @{ noun = 'controller plumbing' }, @{ noun = 'governed controller state' }
            @{ noun = 'lens-applicability.json' }
        ) {
            @(Get-SpecrewBannedConsumerNoun -Text "The $noun is recorded.") | Should -Contain $noun
        }

        It 'leaves LIFECYCLE STAGE NAMES and approval phrases alone, by design' {
            # These are the vocabulary the human is asked to USE - banning them would make the approval
            # instruction unspeakable.
            $text = 'Reply with the phrase approved for before-implement to advance the plan boundary.'
            @(Get-SpecrewBannedConsumerNoun -Text $text) | Should -BeNullOrEmpty
        }

        It 'is case-insensitive, because a capitalised Digest is the same word' {
            @(Get-SpecrewBannedConsumerNoun -Text 'The Digest moved.') | Should -Contain 'digest'
        }

        It 'catches INFLECTIONS - found by running this detector over its own release notes' {
            # The first version matched `\bmint\b` and reported CLEAN on "a fresh authorization was
            # minted", which is the exact sentence the ban exists to catch. A detector that passes the
            # inflected form is worse than none: it certifies the text as checked.
            @(Get-SpecrewBannedConsumerNoun -Text 'A fresh authorization was minted.') | Should -Contain 'mint'
            @(Get-SpecrewBannedConsumerNoun -Text 'Specrew is minting a grant.') | Should -Contain 'mint'
            @(Get-SpecrewBannedConsumerNoun -Text 'Two markers were written.') | Should -Contain 'marker'
            @(Get-SpecrewBannedConsumerNoun -Text 'The digests differ.') | Should -Contain 'digest'
        }

        It 'the suffix rule stays BOUNDED, so the detector does not get switched off' {
            # A looser rule would start matching unrelated words, and a noisy detector gets disabled -
            # which guards nothing. These must NOT fire.
            @(Get-SpecrewBannedConsumerNoun -Text 'The mintage of coins is unrelated.') | Should -BeNullOrEmpty
            @(Get-SpecrewBannedConsumerNoun -Text 'Cross the boundary when ready.') | Should -BeNullOrEmpty
        }
    }

    Context 'workshop refusal language is guarded by its emission property' {
        BeforeAll {
            $script:WorkshopScriptRoot = Join-Path $script:RepoRoot 'extensions/specrew-speckit/scripts'
            $script:WorkshopRefusalConsumers = @(
                Get-ChildItem -LiteralPath $script:WorkshopScriptRoot -Filter '*.ps1' -File -Recurse |
                    Where-Object {
                        $source = Get-Content -LiteralPath $_.FullName -Raw -Encoding UTF8
                        $tokens = $null
                        $errors = $null
                        $ast = [Management.Automation.Language.Parser]::ParseInput($source, [ref]$tokens, [ref]$errors)
                        @($errors).Count -eq 0 -and @($ast.FindAll({
                                    param($node)
                                    $node -is [Management.Automation.Language.CommandAst] -and
                                    $node.GetCommandName() -ceq 'Get-SpecrewWorkshopRefusalContractText'
                                }, $true)).Count -gt 0
                    }
            )
            . (Join-Path $script:WorkshopScriptRoot 'workshop-authority-store.ps1')
            $script:WorkshopRefusalText = Get-SpecrewWorkshopRefusalContractText
        }

        It 'discovers every shipped caller instead of naming files from memory' {
            @($script:WorkshopRefusalConsumers).Count | Should -BeGreaterOrEqual 2 -Because 'a property-derived guard that matches nothing or loses a caller must fail loudly'
        }

        It 'the shared human recovery contract contains no internal workshop machinery' {
            @(Get-SpecrewBannedConsumerNoun -Text $script:WorkshopRefusalText) |
                Should -BeNullOrEmpty
        }

        It 'the shared human recovery contract never blames Specrew' {
            @(Get-SpecrewUnprovenFaultAttribution -Text $script:WorkshopRefusalText) |
                Should -BeNullOrEmpty
        }

        It 'the fault-attribution detector catches the wording that escaped the old guard' {
            @(Get-SpecrewUnprovenFaultAttribution -Text 'Tell the human that the Specrew workshop plumbing is broken.') |
                Should -Not -BeNullOrEmpty
            @(Get-SpecrewUnprovenFaultAttribution -Text 'There is a problem with Specrew.') |
                Should -Not -BeNullOrEmpty
        }

        It 'allows a factual first-person report without assigning fault' {
            @(Get-SpecrewUnprovenFaultAttribution -Text 'I was not able to record your workshop answer cleanly.') |
                Should -BeNullOrEmpty
        }
    }
}
