# Feature 206, T003 (FR-003, bug list item 2b, design condition 3): specrew start heals Specrew's coordinator
# section into .github/copilot-instructions.md before it classifies the file's changes, so Specrew's own block
# was classified as the user's behavior change and paused the session. Before comparing, Specrew's
# specrew-managed blocks are stripped from both sides, but ONLY when every opening and closing marker forms a
# matched pair; a missing or unbalanced marker compares the whole file, as before.
#
# Pure functions only: the heal is reproduced with Merge-SpecrewManagedInstructionSection on fixture text, and
# the classifier runs on content. No specrew start, no files written, no hooks.

BeforeAll {
    $script:RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
    . (Join-Path $script:RepoRoot 'scripts\internal\instruction-file-merge.ps1')
    . (Join-Path $script:RepoRoot 'extensions\specrew-speckit\scripts\Test-CopilotInstructionsChangeType.ps1')
    $script:StartScript = Join-Path $script:RepoRoot 'scripts\specrew-start.ps1'

    $fixtures = Join-Path $script:RepoRoot 'tests\integration\fixtures\013-validator-hardening\copilot-instructions'
    $script:Before = Get-Content -LiteralPath (Join-Path $fixtures 'before.md') -Raw -Encoding UTF8
    $script:AfterTimestamp = Get-Content -LiteralPath (Join-Path $fixtures 'after-timestamp.md') -Raw -Encoding UTF8
    $script:AfterBehavior = Get-Content -LiteralPath (Join-Path $fixtures 'after-behavior.md') -Raw -Encoding UTF8
    $script:Fragment = Get-SpecrewCoordinatorFragment
    $script:BeginMarker = Get-SpecrewInstructionBeginMarker -SectionName 'coordinator'
    $script:EndMarker = Get-SpecrewInstructionEndMarker -SectionName 'coordinator'

    function Get-Classification {
        param([string]$BeforeContent, [string]$AfterContent)
        $pair = Get-SpecrewInstructionComparisonPair -BeforeContent $BeforeContent -AfterContent $AfterContent
        Test-CopilotInstructionsChangeType -BeforeContent $pair.BeforeContent -AfterContent $pair.AfterContent
    }
}

Describe 'Matched specrew-managed blocks are not the user''s change (FR-003)' {
    It 'classifies a healed coordinator block plus a timestamp change as bookkeeping' {
        $healed = Merge-SpecrewManagedInstructionSection -ExistingContent $script:AfterTimestamp -ManagedContent $script:Fragment
        $healed | Should -Match ([regex]::Escape($script:BeginMarker))
        $result = Get-Classification -BeforeContent $script:Before -AfterContent $healed
        $result.Classification | Should -Be 'bookkeeping'
        $result.RequiresRestart | Should -BeFalse
    }

    It 'strips a matched block present on both sides' {
        $before = Merge-SpecrewManagedInstructionSection -ExistingContent $script:Before -ManagedContent $script:Fragment
        $after = Merge-SpecrewManagedInstructionSection -ExistingContent $script:AfterTimestamp -ManagedContent ($script:Fragment + "`n`nA newer fragment line.")
        $pair = Get-SpecrewInstructionComparisonPair -BeforeContent $before -AfterContent $after
        $pair.Stripped | Should -BeTrue
        $pair.AfterContent | Should -Not -Match 'specrew-managed'
        (Test-CopilotInstructionsChangeType -BeforeContent $pair.BeforeContent -AfterContent $pair.AfterContent).Classification | Should -Be 'bookkeeping'
    }

    It 'still classifies a user change outside the markers as behavior' {
        $healed = Merge-SpecrewManagedInstructionSection -ExistingContent $script:AfterBehavior -ManagedContent $script:Fragment
        $result = Get-Classification -BeforeContent $script:Before -AfterContent $healed
        $result.Classification | Should -Be 'behavior'
        $result.RequiresRestart | Should -BeTrue
    }
}

Describe 'A missing or unbalanced marker compares the whole file (FR-003, condition 3)' {
    It 'pauses when the closing marker is missing' {
        $broken = $script:AfterTimestamp.TrimEnd() + "`n`n" + $script:BeginMarker + "`n" + $script:Fragment + "`n"
        $pair = Get-SpecrewInstructionComparisonPair -BeforeContent $script:Before -AfterContent $broken
        $pair.Stripped | Should -BeFalse
        $pair.AfterContent | Should -BeExactly $broken
        (Test-CopilotInstructionsChangeType -BeforeContent $pair.BeforeContent -AfterContent $pair.AfterContent).RequiresRestart | Should -BeTrue
    }

    It 'pauses when a closing marker has no opening marker' {
        $broken = $script:AfterTimestamp.TrimEnd() + "`n`n" + $script:Fragment + "`n" + $script:EndMarker + "`n"
        $pair = Get-SpecrewInstructionComparisonPair -BeforeContent $script:Before -AfterContent $broken
        $pair.Stripped | Should -BeFalse
        (Test-CopilotInstructionsChangeType -BeforeContent $pair.BeforeContent -AfterContent $pair.AfterContent).RequiresRestart | Should -BeTrue
    }

    It 'pauses when the markers name different sections' {
        $otherEnd = Get-SpecrewInstructionEndMarker -SectionName 'other'
        $broken = $script:AfterTimestamp.TrimEnd() + "`n`n" + $script:BeginMarker + "`n" + $script:Fragment + "`n" + $otherEnd + "`n"
        $pair = Get-SpecrewInstructionComparisonPair -BeforeContent $script:Before -AfterContent $broken
        $pair.Stripped | Should -BeFalse
    }

    It 'compares both sides whole when only the baseline is unbalanced' {
        $brokenBefore = $script:Before.TrimEnd() + "`n`n" + $script:BeginMarker + "`n" + $script:Fragment + "`n"
        $healed = Merge-SpecrewManagedInstructionSection -ExistingContent $script:AfterTimestamp -ManagedContent $script:Fragment
        $pair = Get-SpecrewInstructionComparisonPair -BeforeContent $brokenBefore -AfterContent $healed
        $pair.Stripped | Should -BeFalse
        $pair.BeforeContent | Should -BeExactly $brokenBefore
        $pair.AfterContent | Should -BeExactly $healed
    }
}

Describe 'A copilot-instructions.md missing on one side does not stop specrew start (FR-003; found at T015)' {
    # T003 called the classifier with content, and its mandatory -BeforeContent/-AfterContent refuse an empty
    # string: when the file did not exist at the baseline commit (or no longer exists), the second `specrew start`
    # stopped with "Cannot bind argument to parameter 'BeforeContent' because it is an empty string." Before T003
    # the classifier read the files itself and compared an absent side as empty; that comparison stands.
    BeforeAll {
        $source = Get-Content -LiteralPath $script:StartScript -Raw
        $script:RestartTriggerFunction = [regex]::Match($source, '(?s)function Get-RestartTriggerFiles \{.*?\r?\n\}\r?\n').Value
        $script:ClassifierRepo = Join-Path ([IO.Path]::GetTempPath()) ('classifier-missing-side-' + [guid]::NewGuid().ToString('N').Substring(0, 10))
        $null = New-Item -ItemType Directory -Path (Join-Path $script:ClassifierRepo '.github') -Force
        [IO.File]::WriteAllText((Join-Path $script:ClassifierRepo 'README.md'), "fixture`n")
        & git -C $script:ClassifierRepo init --quiet
        & git -C $script:ClassifierRepo add -A
        & git -C $script:ClassifierRepo -c user.name='Classifier Fixture' -c user.email='classifier-fixture@example.invalid' commit --quiet -m 'baseline without instructions'
        $script:BaselineWithout = (& git -C $script:ClassifierRepo rev-parse HEAD).Trim()
        $healed = Merge-SpecrewManagedInstructionSection -ExistingContent $script:Before -ManagedContent $script:Fragment
        [IO.File]::WriteAllText((Join-Path $script:ClassifierRepo '.github\copilot-instructions.md'), $healed)
        & git -C $script:ClassifierRepo add -A
        & git -C $script:ClassifierRepo -c user.name='Classifier Fixture' -c user.email='classifier-fixture@example.invalid' commit --quiet -m 'instructions added'
        $script:BaselineWith = (& git -C $script:ClassifierRepo rev-parse HEAD).Trim()
    }
    AfterAll {
        Remove-Item -LiteralPath $script:ClassifierRepo -Recurse -Force -ErrorAction SilentlyContinue
    }

    It 'classifies a file added since the baseline as changed instead of throwing' {
        $script:RestartTriggerFunction | Should -Not -BeNullOrEmpty
        . ([scriptblock]::Create($script:RestartTriggerFunction))
        $result = @(Get-RestartTriggerFiles -ResolvedProjectPath $script:ClassifierRepo -BaselineCommitHash $script:BaselineWithout -ChangedFiles @('.github/copilot-instructions.md'))
        $result | Should -Contain '.github\copilot-instructions.md'
    }

    It 'classifies a file deleted since the baseline as changed instead of throwing' {
        . ([scriptblock]::Create($script:RestartTriggerFunction))
        Remove-Item -LiteralPath (Join-Path $script:ClassifierRepo '.github\copilot-instructions.md') -Force
        try {
            $result = @(Get-RestartTriggerFiles -ResolvedProjectPath $script:ClassifierRepo -BaselineCommitHash $script:BaselineWith -ChangedFiles @('.github/copilot-instructions.md'))
            $result | Should -Contain '.github\copilot-instructions.md'
        }
        finally {
            & git -C $script:ClassifierRepo checkout --quiet -- .github/copilot-instructions.md
        }
    }
}

Describe 'specrew start classifies the compared pair (FR-003)' {
    It 'passes the stripped pair to the classifier in Get-RestartTriggerFiles' {
        $source = Get-Content -LiteralPath $script:StartScript -Raw
        $function = [regex]::Match($source, '(?s)function Get-RestartTriggerFiles \{.*?\r?\n\}\r?\n').Value
        $function | Should -Match 'Get-SpecrewInstructionComparisonPair'
        $function | Should -Match 'Test-CopilotInstructionsChangeType\s+-BeforeContent'
    }
}
