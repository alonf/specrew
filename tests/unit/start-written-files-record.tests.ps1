# Feature 206, T020 (FR-003, SC-002, bug list item 21, design D5-a): `specrew start` heals
# `.github/agents/squad.agent.md` and creates the `.squad/agents/*/charter.md` files itself. Once those writes are
# committed, the next start read them as the user's changes to session-loaded files and paused
# (PAUSE-AND-CONFIRM). Start now records, in a git-ignored runtime record, the SHA-256 of each session-loaded file
# it created or changed during its run; at the next start a changed file whose committed content still matches the
# recorded hash is Specrew's own, and an edited one is the user's.
#
# Everything runs inside temp folders this suite creates. The end-to-end case runs scripts/specrew-start.ps1
# -NoLaunch -SkipUpdateCheck on a temp fixture with the user profile pointed at a temp file; it writes nothing
# outside the fixture (feature 206 T014/T015 read of the start path).

BeforeAll {
    $script:RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
    . (Join-Path $script:RepoRoot 'scripts\internal\instruction-file-merge.ps1')
    . (Join-Path $script:RepoRoot 'extensions\specrew-speckit\scripts\Test-CopilotInstructionsChangeType.ps1')
    $script:StartScript = Join-Path $script:RepoRoot 'scripts\specrew-start.ps1'
    $script:StartSource = Get-Content -LiteralPath $script:StartScript -Raw
    $script:RestartTriggerFunction = [regex]::Match($script:StartSource, '(?s)function Get-RestartTriggerFiles \{.*?\r?\n\}\r?\n').Value
    $script:Globs = @('.github/agents/*', '.github/copilot-instructions.md', '.squad/agents/*/charter.md')
    $script:TempRoots = New-Object System.Collections.Generic.List[string]

    function New-FixtureRepo {
        param([string]$Name)
        $root = Join-Path ([IO.Path]::GetTempPath()) ('start-written-' + $Name + '-' + [guid]::NewGuid().ToString('N').Substring(0, 10))
        $null = New-Item -ItemType Directory -Path $root -Force
        $script:TempRoots.Add($root) | Out-Null
        & git -C $root init --quiet
        & git -C $root config user.email 'start-written-fixture@example.invalid'
        & git -C $root config user.name 'Start Written Fixture'
        & git -C $root config core.autocrlf false
        return $root
    }

    function Set-FixtureFile {
        param([string]$Root, [string]$RelativePath, [string]$Content)
        $path = Join-Path $Root $RelativePath
        $parent = Split-Path -Parent $path
        if (-not (Test-Path -LiteralPath $parent)) { $null = New-Item -ItemType Directory -Path $parent -Force }
        [IO.File]::WriteAllText($path, $Content, [Text.UTF8Encoding]::new($false))
    }

    function Save-FixtureCommit {
        param([string]$Root, [string]$Message)
        & git -C $Root add -A
        & git -C $Root commit --quiet -m $Message
        return (& git -C $Root rev-parse HEAD).Trim()
    }
}

AfterAll {
    foreach ($root in $script:TempRoots) {
        Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Describe 'The record of files start wrote (D5-a)' {
    It 'lives under .specrew/runtime, which git ignores' {
        $root = New-FixtureRepo -Name 'path'
        $recordPath = Get-SpecrewStartWrittenFilesRecordPath -ProjectPath $root
        $recordPath | Should -BeLike (Join-Path $root '.specrew\runtime\*')
        $gitignore = Get-Content -LiteralPath (Join-Path $script:RepoRoot '.gitignore') -Raw
        $gitignore | Should -Match '(?m)^\.specrew/runtime/\s*$'
    }

    It 'hashes content the same with LF or CRLF line endings, a BOM or a trailing newline' {
        $lf = Get-SpecrewStartWrittenContentHash -Content "# Charter`nLine two`n"
        Get-SpecrewStartWrittenContentHash -Content "# Charter`r`nLine two`r`n" | Should -Be $lf
        Get-SpecrewStartWrittenContentHash -Content ([string][char]0xFEFF + "# Charter`nLine two") | Should -Be $lf
        Get-SpecrewStartWrittenContentHash -Content "# Charter`nLine three`n" | Should -Not -Be $lf
        $lf | Should -Match '^[0-9a-f]{64}$'
    }

    It 'records the files whose content changed during the run, keeps earlier entries, and drops deleted files' {
        $root = New-FixtureRepo -Name 'save'
        Set-FixtureFile -Root $root -RelativePath '.github/agents/squad.agent.md' -Content "# Squad Agent`n"
        Set-FixtureFile -Root $root -RelativePath '.squad/agents/old/charter.md' -Content "# Old`n"
        Set-FixtureFile -Root $root -RelativePath '.squad/agents/gone/charter.md' -Content "# Gone`n"
        Set-FixtureFile -Root $root -RelativePath '.github/copilot-instructions.md' -Content "# User rules`n"
        Save-SpecrewStartWrittenFilesRecord -ProjectPath $root -Before @{} -After @{
            '.squad/agents/old/charter.md'  = (Get-SpecrewStartWrittenContentHash -Content "# Old`n")
            '.squad/agents/gone/charter.md' = (Get-SpecrewStartWrittenContentHash -Content "# Gone`n")
        }
        Remove-Item -LiteralPath (Join-Path $root '.squad/agents/gone/charter.md') -Force

        $before = Get-SpecrewSessionLoadedFileSnapshot -ProjectPath $root -Globs $script:Globs
        $before.Keys | Should -Contain '.github/agents/squad.agent.md'
        $before.Keys | Should -Contain '.github/copilot-instructions.md'

        # The run heals squad.agent.md and creates a charter; copilot-instructions.md is left alone.
        Set-FixtureFile -Root $root -RelativePath '.github/agents/squad.agent.md' -Content "# Squad Agent`n`nHealed body.`n"
        Set-FixtureFile -Root $root -RelativePath '.squad/agents/planner/charter.md' -Content "# Planner`n"
        $after = Get-SpecrewSessionLoadedFileSnapshot -ProjectPath $root -Globs $script:Globs
        Save-SpecrewStartWrittenFilesRecord -ProjectPath $root -Before $before -After $after

        $record = Read-SpecrewStartWrittenFilesRecord -ProjectPath $root
        $record['.github/agents/squad.agent.md'] | Should -Be (Get-SpecrewStartWrittenContentHash -Content "# Squad Agent`n`nHealed body.`n")
        $record['.squad/agents/planner/charter.md'] | Should -Be (Get-SpecrewStartWrittenContentHash -Content "# Planner`n")
        $record['.squad/agents/old/charter.md'] | Should -Be (Get-SpecrewStartWrittenContentHash -Content "# Old`n")
        $record.Contains('.github/copilot-instructions.md') | Should -BeFalse
        $record.Contains('.squad/agents/gone/charter.md') | Should -BeFalse

        $raw = Get-Content -LiteralPath (Get-SpecrewStartWrittenFilesRecordPath -ProjectPath $root) -Raw
        $raw | Should -Not -Match ([regex]::Escape($root))
        # The review preflight runs lanes with an emptied environment, so USERNAME may be unset there; an empty
        # pattern matches everything, so only a real user name is checked.
        $userName = [Environment]::UserName
        if (-not [string]::IsNullOrWhiteSpace($userName)) {
            $raw | Should -Not -Match ([regex]::Escape($userName))
        }
    }

    It 'reads a missing or unreadable record as empty' {
        $root = New-FixtureRepo -Name 'read'
        (Read-SpecrewStartWrittenFilesRecord -ProjectPath $root).Count | Should -Be 0
        Set-FixtureFile -Root $root -RelativePath '.specrew/runtime/start-written-files.json' -Content '{ not json'
        (Read-SpecrewStartWrittenFilesRecord -ProjectPath $root).Count | Should -Be 0
    }
}

Describe 'A changed session-loaded file that start wrote itself is not a restart trigger (FR-003)' {
    BeforeAll {
        $script:TriggerRoot = New-FixtureRepo -Name 'trigger'
        Set-FixtureFile -Root $script:TriggerRoot -RelativePath 'README.md' -Content "fixture`n"
        $script:TriggerBaseline = Save-FixtureCommit -Root $script:TriggerRoot -Message 'baseline'
        $script:CharterContent = "# Planner`n`nSpecrew wrote this charter.`n"
        Set-FixtureFile -Root $script:TriggerRoot -RelativePath '.squad/agents/planner/charter.md' -Content $script:CharterContent
        Set-FixtureFile -Root $script:TriggerRoot -RelativePath '.github/agents/squad.agent.md' -Content "# Squad Agent`n`nHealed.`n"
        $null = Save-FixtureCommit -Root $script:TriggerRoot -Message 'start writes committed'
    }

    It 'skips a file whose committed content matches its recorded hash' {
        $script:RestartTriggerFunction | Should -Not -BeNullOrEmpty
        . ([scriptblock]::Create($script:RestartTriggerFunction))
        $record = @{
            '.squad/agents/planner/charter.md' = (Get-SpecrewStartWrittenContentHash -Content $script:CharterContent)
            '.github/agents/squad.agent.md'    = (Get-SpecrewStartWrittenContentHash -Content "# Squad Agent`n`nHealed.`n")
        }
        $result = @(Get-RestartTriggerFiles -ResolvedProjectPath $script:TriggerRoot -BaselineCommitHash $script:TriggerBaseline -ChangedFiles @('.squad/agents/planner/charter.md', '.github/agents/squad.agent.md') -StartWrittenFiles $record)
        $result.Count | Should -Be 0
    }

    It 'still triggers on a file the user edited after start wrote it' {
        . ([scriptblock]::Create($script:RestartTriggerFunction))
        $record = @{ '.squad/agents/planner/charter.md' = (Get-SpecrewStartWrittenContentHash -Content "# Planner`n`nAn older Specrew charter.`n") }
        $result = @(Get-RestartTriggerFiles -ResolvedProjectPath $script:TriggerRoot -BaselineCommitHash $script:TriggerBaseline -ChangedFiles @('.squad/agents/planner/charter.md') -StartWrittenFiles $record)
        $result | Should -Contain '.squad\agents\planner\charter.md'
    }

    It 'still triggers on a changed file with no record entry' {
        . ([scriptblock]::Create($script:RestartTriggerFunction))
        $result = @(Get-RestartTriggerFiles -ResolvedProjectPath $script:TriggerRoot -BaselineCommitHash $script:TriggerBaseline -ChangedFiles @('.github/agents/squad.agent.md') -StartWrittenFiles @{})
        $result | Should -Contain '.github\agents\squad.agent.md'
    }

    It 'compares the committed content, not a working-tree copy start may have rewritten' {
        . ([scriptblock]::Create($script:RestartTriggerFunction))
        $userEdit = "# Planner`n`nThe user changed this.`n"
        Set-FixtureFile -Root $script:TriggerRoot -RelativePath '.squad/agents/planner/charter.md' -Content $userEdit
        $null = Save-FixtureCommit -Root $script:TriggerRoot -Message 'user edits the charter'
        # This run's heal puts Specrew's content back in the working tree before the comparison.
        Set-FixtureFile -Root $script:TriggerRoot -RelativePath '.squad/agents/planner/charter.md' -Content $script:CharterContent
        $record = @{ '.squad/agents/planner/charter.md' = (Get-SpecrewStartWrittenContentHash -Content $script:CharterContent) }
        $result = @(Get-RestartTriggerFiles -ResolvedProjectPath $script:TriggerRoot -BaselineCommitHash $script:TriggerBaseline -ChangedFiles @('.squad/agents/planner/charter.md') -StartWrittenFiles $record)
        $result | Should -Contain '.squad\agents\planner\charter.md'
    }
}

Describe 'Only changes made inside one of start''s writing steps are recorded (round 1, F5)' {
    # The before snapshot used to be taken before the first write and the after snapshot after the last, so the window
    # spanned start's interactive prompts: a change a user or another tool made while start waited was recorded as
    # Specrew's own. Each writing step now has its own region, and nothing between regions is recorded.
    It 'records what a region writes and nothing written between regions' {
        $root = New-FixtureRepo -Name 'f5'
        Set-FixtureFile -Root $root -RelativePath '.github/agents/squad.agent.md' -Content "# Squad Agent`n"
        $region = Start-SpecrewStartWrittenRegion -ProjectPath $root -Globs $script:Globs
        Set-FixtureFile -Root $root -RelativePath '.github/agents/squad.agent.md' -Content "# Squad Agent`n`nHealed by start.`n"
        Complete-SpecrewStartWrittenRegion -ProjectPath $root -Globs $script:Globs -Before $region

        # While start waits on a prompt, the user writes a charter.
        Set-FixtureFile -Root $root -RelativePath '.squad/agents/user-added/charter.md' -Content "# The user's own role`n"

        $region = Start-SpecrewStartWrittenRegion -ProjectPath $root -Globs $script:Globs
        Set-FixtureFile -Root $root -RelativePath '.squad/agents/planner/charter.md' -Content "# Planner`n"
        Complete-SpecrewStartWrittenRegion -ProjectPath $root -Globs $script:Globs -Before $region

        $record = Read-SpecrewStartWrittenFilesRecord -ProjectPath $root
        $record.Contains('.github/agents/squad.agent.md') | Should -BeTrue
        $record.Contains('.squad/agents/planner/charter.md') | Should -BeTrue
        $record.Contains('.squad/agents/user-added/charter.md') | Should -BeFalse
    }

    It 'specrew start takes no snapshot that spans its prompts' {
        $promptLine = [regex]::Match($script:StartSource, '(?m)^\s*\$expertiseDials = Invoke-FirstRunExpertisePrompt').Index
        $regions = [regex]::Matches($script:StartSource, '(?m)^\s*\$\w+ = Start-SpecrewStartWrittenRegion\b')
        $regions.Count | Should -BeGreaterOrEqual 3
        $script:StartSource | Should -Not -Match '(?m)^\s*\$startWrittenSnapshotBefore\s*='
        foreach ($m in $regions) {
            $completeAt = $script:StartSource.IndexOf('Complete-SpecrewStartWrittenRegion', $m.Index)
            $completeAt | Should -BeGreaterThan $m.Index
            ($m.Index -lt $promptLine -and $completeAt -gt $promptLine) | Should -BeFalse -Because 'a region must not contain the first-run profile prompt'
        }
    }
}

Describe 'copilot-instructions.md is shared, so the record never covers it (round 1, F1)' {
    # Start writes only its managed block into .github/copilot-instructions.md and keeps every other byte, so the file
    # is not one start wrote whole. A user's uncommitted edit outside the block, present when start refreshes the
    # block, must not become "Specrew's own" once committed: T003's block-aware classifier decides that file.
    BeforeAll {
        $fixtures = Join-Path $script:RepoRoot 'tests\integration\fixtures\013-validator-hardening\copilot-instructions'
        $script:F1Before = Get-Content -LiteralPath (Join-Path $fixtures 'before.md') -Raw -Encoding UTF8
        $script:F1UserEdit = Get-Content -LiteralPath (Join-Path $fixtures 'after-behavior.md') -Raw -Encoding UTF8
        $script:F1Fragment = Get-SpecrewCoordinatorFragment
    }

    It 'pauses on the user''s committed edit after start refreshed its block around it' {
        $root = New-FixtureRepo -Name 'f1'
        Set-FixtureFile -Root $root -RelativePath '.github/copilot-instructions.md' -Content (Merge-SpecrewManagedInstructionSection -ExistingContent $script:F1Before -ManagedContent $script:F1Fragment)
        $baseline = Save-FixtureCommit -Root $root -Message 'baseline with the coordinator block'

        # The user edits outside the block and has not committed; start then refreshes its block (a new fragment).
        Set-FixtureFile -Root $root -RelativePath '.github/copilot-instructions.md' -Content (Merge-SpecrewManagedInstructionSection -ExistingContent $script:F1UserEdit -ManagedContent $script:F1Fragment)
        $before = Get-SpecrewSessionLoadedFileSnapshot -ProjectPath $root -Globs $script:Globs
        Set-FixtureFile -Root $root -RelativePath '.github/copilot-instructions.md' -Content (Merge-SpecrewManagedInstructionSection -ExistingContent $script:F1UserEdit -ManagedContent ($script:F1Fragment + "`n`nA refreshed coordinator line."))
        $after = Get-SpecrewSessionLoadedFileSnapshot -ProjectPath $root -Globs $script:Globs
        Save-SpecrewStartWrittenFilesRecord -ProjectPath $root -Before $before -After $after
        $null = Save-FixtureCommit -Root $root -Message 'user commits the edit with the refreshed block'

        $record = Read-SpecrewStartWrittenFilesRecord -ProjectPath $root
        $record.Contains('.github/copilot-instructions.md') | Should -BeFalse
        . ([scriptblock]::Create($script:RestartTriggerFunction))
        $result = @(Get-RestartTriggerFiles -ResolvedProjectPath $root -BaselineCommitHash $baseline -ChangedFiles @('.github/copilot-instructions.md') -StartWrittenFiles $record)
        $result | Should -Contain '.github\copilot-instructions.md'
    }

    It 'ignores a copilot-instructions.md entry an older record still holds' {
        $root = New-FixtureRepo -Name 'f1-old'
        Set-FixtureFile -Root $root -RelativePath '.github/copilot-instructions.md' -Content (Merge-SpecrewManagedInstructionSection -ExistingContent $script:F1Before -ManagedContent $script:F1Fragment)
        $baseline = Save-FixtureCommit -Root $root -Message 'baseline'
        $edited = Merge-SpecrewManagedInstructionSection -ExistingContent $script:F1UserEdit -ManagedContent $script:F1Fragment
        Set-FixtureFile -Root $root -RelativePath '.github/copilot-instructions.md' -Content $edited
        $null = Save-FixtureCommit -Root $root -Message 'user edit'
        . ([scriptblock]::Create($script:RestartTriggerFunction))
        $result = @(Get-RestartTriggerFiles -ResolvedProjectPath $root -BaselineCommitHash $baseline -ChangedFiles @('.github/copilot-instructions.md') -StartWrittenFiles @{ '.github/copilot-instructions.md' = (Get-SpecrewStartWrittenContentHash -Content $edited) })
        $result | Should -Contain '.github\copilot-instructions.md'
    }
}

Describe 'specrew start keeps the record across runs (end to end, item 21)' {
    BeforeAll {
        $script:ProfilePath = Join-Path ([IO.Path]::GetTempPath()) ('specrew-test-profile-' + [guid]::NewGuid().ToString('N') + '.yml')
        $script:PreviousProfile = $env:SPECREW_USER_PROFILE_PATH
        $env:SPECREW_USER_PROFILE_PATH = $script:ProfilePath
        $script:E2ERoot = New-FixtureRepo -Name 'e2e'
        Set-FixtureFile -Root $script:E2ERoot -RelativePath '.specrew/config.yml' -Content "version: 1`n"
        $null = New-Item -ItemType Directory -Path (Join-Path $script:E2ERoot '.specify') -Force
        Set-FixtureFile -Root $script:E2ERoot -RelativePath '.specify/README.md' -Content "fixture`n"
        Set-FixtureFile -Root $script:E2ERoot -RelativePath '.squad/team.md' -Content "# Team`n"
        Set-FixtureFile -Root $script:E2ERoot -RelativePath '.squad/config.json' -Content '{}'
        Set-FixtureFile -Root $script:E2ERoot -RelativePath '.squad/decisions.md' -Content "# Decisions`n"
        Set-FixtureFile -Root $script:E2ERoot -RelativePath '.github/agents/squad.agent.md' -Content "# Squad Agent`n"
        Set-FixtureFile -Root $script:E2ERoot -RelativePath '.gitignore' -Content ".specrew/runtime/`n"
        $null = Save-FixtureCommit -Root $script:E2ERoot -Message 'seed'
        $script:PromptPath = Join-Path $script:E2ERoot '.specrew\last-start-prompt.md'

        function Invoke-FixtureStart {
            $output = @(& pwsh -NoProfile -ExecutionPolicy Bypass -File $script:StartScript -ProjectPath $script:E2ERoot -HostKind copilot -NoLaunch -SkipUpdateCheck 2>&1)
            return [pscustomobject]@{ ExitCode = $LASTEXITCODE; Text = ($output -join "`n") }
        }
    }
    AfterAll {
        $env:SPECREW_USER_PROFILE_PATH = $script:PreviousProfile
        Remove-Item -LiteralPath $script:ProfilePath -Force -ErrorAction SilentlyContinue
    }

    It 'does not pause on the files the first start wrote, once they are committed' {
        $first = Invoke-FixtureStart
        $first.ExitCode | Should -Be 0 -Because $first.Text
        $null = Save-FixtureCommit -Root $script:E2ERoot -Message 'commit what start wrote'

        $second = Invoke-FixtureStart
        $second.ExitCode | Should -Be 0 -Because $second.Text
        Get-Content -LiteralPath $script:PromptPath -Raw | Should -Not -Match 'PAUSE-AND-CONFIRM'
        Test-Path -LiteralPath (Join-Path $script:E2ERoot '.specrew\runtime\start-written-files.json') | Should -BeTrue
    }

    It 'pauses, naming the file, when the user edits a charter start wrote' {
        $charter = @(Get-ChildItem -Path (Join-Path $script:E2ERoot '.squad\agents\*\charter.md') -File)[0]
        $charter | Should -Not -BeNullOrEmpty
        [IO.File]::AppendAllText($charter.FullName, "`nA rule the user added.`n")
        $null = Save-FixtureCommit -Root $script:E2ERoot -Message 'user edits a charter'

        $third = Invoke-FixtureStart
        $third.ExitCode | Should -Be 0 -Because $third.Text
        $prompt = Get-Content -LiteralPath $script:PromptPath -Raw
        $prompt | Should -Match 'PAUSE-AND-CONFIRM'
        $prompt | Should -Match ([regex]::Escape(('.squad\agents\{0}\charter.md' -f $charter.Directory.Name)))
    }
}
