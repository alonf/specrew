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

    Context 'the banned-noun check: internal vocabulary never reaches a consumer surface' {
        It 'flags machinery nouns' -ForEach @(
            @{ noun = 'crossing' }, @{ noun = 'digest' }, @{ noun = 'ratchet' }
            @{ noun = 'terminalize' }, @{ noun = 'claim-ordered' }, @{ noun = 'controller truth' }
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
}
