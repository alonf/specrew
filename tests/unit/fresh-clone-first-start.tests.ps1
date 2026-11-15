# Feature 206, T022 (FR-001, SC-001, bug list item 22, design D6-a): a fresh clone of a governed project has neither
# `.specrew/last-start-prompt.md` nor `.specrew/start-context.json` (both are ignored by git), but it does carry the
# tracked `.squad/identity/now.md`. `specrew start` read the two absent files as stale session state and, with no
# console, refused. A governed project with neither session file is a first start; a session file that is present but
# unreadable still refuses, as T001 made it, and every other stale check still applies.
#
# The combination case (reviewer's condition, 2026-11-15) meets T020: a fresh clone whose committed files include the
# healed `squad.agent.md` and the charters an earlier start wrote neither refuses nor pauses at its first start, and a
# later user edit to one of them pauses.
#
# Everything runs inside temp folders this suite creates. The end-to-end cases run scripts/specrew-start.ps1
# -NoLaunch -SkipUpdateCheck with stdin redirected (no console) and the user profile pointed at a temp file.

BeforeAll {
    $script:RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
    . (Join-Path $script:RepoRoot 'scripts\internal\session-recovery.ps1')
    $script:StartScript = Join-Path $script:RepoRoot 'scripts\specrew-start.ps1'
    $script:TempRoots = New-Object System.Collections.Generic.List[string]

    function New-TempFolder {
        param([string]$Name)
        $root = Join-Path ([IO.Path]::GetTempPath()) ('fresh-clone-' + $Name + '-' + [guid]::NewGuid().ToString('N').Substring(0, 10))
        $null = New-Item -ItemType Directory -Path $root -Force
        $script:TempRoots.Add($root) | Out-Null
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

    # A governed project as a collaborator receives it: the feature branch checked out, a feature folder, the
    # tracked identity file and decisions ledger, and a .gitignore that keeps the per-machine session files out.
    function New-GovernedProject {
        param([string]$Name)
        $root = New-TempFolder -Name $Name
        & git -C $root init --quiet --initial-branch=001-demo
        & git -C $root config user.email 'fresh-clone-fixture@example.invalid'
        & git -C $root config user.name 'Fresh Clone Fixture'
        & git -C $root config core.autocrlf false
        Set-FixtureFile -Root $root -RelativePath '.gitignore' -Content ".specrew/last-*`n.specrew/start-context.json`n.specrew/start-summary.md`n.specrew/runtime/`n.specrew/host-history.json`n.specrew/active-sessions.yml`n"
        Set-FixtureFile -Root $root -RelativePath '.specrew/config.yml' -Content "version: 1`n"
        Set-FixtureFile -Root $root -RelativePath '.specify/README.md' -Content "fixture`n"
        Set-FixtureFile -Root $root -RelativePath '.squad/team.md' -Content "# Team`n"
        Set-FixtureFile -Root $root -RelativePath '.squad/config.json' -Content '{}'
        Set-FixtureFile -Root $root -RelativePath '.github/agents/squad.agent.md' -Content "# Squad Agent`n"
        Set-FixtureFile -Root $root -RelativePath 'specs/001-demo/spec.md' -Content "# Feature Specification: Demo`n"
        Set-FixtureFile -Root $root -RelativePath '.squad/decisions.md' -Content ("# Decisions`n`n## 2026-11-15T10:00:00Z — Boundary sync: specify`n`n- **Boundary Type**: specify`n- **Feature Ref**: 001-demo`n- **Auth Commit Hash**: 1111111111111111111111111111111111111111`n- **Recorded At**: 2026-11-15T10:00:00Z`n")
        Set-FixtureFile -Root $root -RelativePath '.squad/identity/now.md' -Content ("---`nfocus_area: `"Demo`"`nschema: v1`nsession_state_active: true`nsession_state_boundary: specify`nsession_state_feature: 001-demo`nsession_state_feature_path: (none)`nsession_state_iteration: (none)`nsession_state_task: (none)`nsession_state_auth_commit: 1111111111111111111111111111111111111111`nsession_state_recorded_at: 2026-11-15T10:00:00Z`n---`n`n# What We're Focused On`n")
        $null = Save-FixtureCommit -Root $root -Message 'governed project'
        return $root
    }

    function Invoke-NoConsoleStart {
        param([string]$Root)
        $output = @('' | & pwsh -NoProfile -ExecutionPolicy Bypass -File $script:StartScript -ProjectPath $Root -HostKind copilot -NoLaunch -SkipUpdateCheck 2>&1)
        return [pscustomobject]@{ ExitCode = $LASTEXITCODE; Text = ($output -join "`n") }
    }
}

AfterAll {
    foreach ($root in $script:TempRoots) {
        Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Describe 'A governed project with no session files is a first start (D6-a)' {
    It 'is not stale when neither last-start-prompt.md nor start-context.json exists' {
        $root = New-GovernedProject -Name 'pure-none'
        $result = Test-SpecrewStaleSessionState -ProjectRoot $root
        $result.IsStale | Should -BeFalse -Because ($result.Issues -join '; ')
        @($result.Issues).Count | Should -Be 0
    }

    It 'still refuses when last-start-prompt.md is present but unreadable' {
        $root = New-GovernedProject -Name 'pure-unreadable'
        Set-FixtureFile -Root $root -RelativePath '.specrew/last-start-prompt.md' -Content "# A prompt with no frontmatter`n"
        $result = Test-SpecrewStaleSessionState -ProjectRoot $root
        $result.IsStale | Should -BeTrue
        ($result.Issues -join "`n") | Should -Match 'present but stale or unparseable: last-start-prompt\.md'
    }

    It 'still reports the other file missing when only one session file exists' {
        $root = New-GovernedProject -Name 'pure-one'
        Set-FixtureFile -Root $root -RelativePath '.specrew/start-context.json' -Content '{"schema_version":"1.0","session_state":{"active":true,"boundary_type":"specify","feature_ref":"001-demo","feature_path":"","iteration_number":"","task_id":"","auth_commit_hash":"1111111111111111111111111111111111111111","recorded_at":"2026-11-15T10:00:00Z"}}'
        $result = Test-SpecrewStaleSessionState -ProjectRoot $root
        $result.IsStale | Should -BeTrue
        ($result.Issues -join "`n") | Should -Match 'missing on disk: last-start-prompt\.md'
    }

    It 'keeps every other stale check: a missing feature branch is still stale' {
        $root = New-GovernedProject -Name 'pure-branch'
        & git -C $root branch --quiet -m 001-demo main
        $result = Test-SpecrewStaleSessionState -ProjectRoot $root
        $result.IsStale | Should -BeTrue
        ($result.Issues -join "`n") | Should -Match 'Feature branch is missing: 001-demo'
        ($result.Issues -join "`n") | Should -Not -Match 'missing on disk'
    }
}

Describe 'A fresh clone starts with no console, and Specrew''s own committed writes do not pause it (combination with T020)' {
    BeforeAll {
        $script:ProfilePath = Join-Path ([IO.Path]::GetTempPath()) ('specrew-test-profile-' + [guid]::NewGuid().ToString('N') + '.yml')
        $script:PreviousProfile = $env:SPECREW_USER_PROFILE_PATH
        $env:SPECREW_USER_PROFILE_PATH = $script:ProfilePath

        # The project's first start happens on the maintainer's machine; what it wrote is committed.
        $script:Origin = New-GovernedProject -Name 'origin'
        $originStart = Invoke-NoConsoleStart -Root $script:Origin
        $script:OriginStartExit = $originStart.ExitCode
        $script:OriginStartText = $originStart.Text
        $null = Save-FixtureCommit -Root $script:Origin -Message 'what the first start wrote'
        $script:OriginHead = (& git -C $script:Origin rev-parse HEAD).Trim()

        $cloneParent = New-TempFolder -Name 'clone'
        $script:Clone = Join-Path $cloneParent 'project'
        & git clone --quiet $script:Origin $script:Clone 2>$null
        & git -C $script:Clone config user.email 'fresh-clone-fixture@example.invalid'
        & git -C $script:Clone config user.name 'Fresh Clone Fixture'
        & git -C $script:Clone config core.autocrlf false
        $script:ClonePrompt = Join-Path $script:Clone '.specrew\last-start-prompt.md'
    }
    AfterAll {
        $env:SPECREW_USER_PROFILE_PATH = $script:PreviousProfile
        Remove-Item -LiteralPath $script:ProfilePath -Force -ErrorAction SilentlyContinue
    }

    It 'the origin''s first start wrote charters and committed them' {
        $script:OriginStartExit | Should -Be 0 -Because $script:OriginStartText
        @(& git -C $script:Origin ls-files -- '.squad/agents/*/charter.md').Count | Should -BeGreaterThan 0
    }

    It 'the clone has the committed charters and no session files' {
        @(Get-ChildItem -Path (Join-Path $script:Clone '.squad\agents\*\charter.md') -File).Count | Should -BeGreaterThan 0
        Test-Path -LiteralPath $script:ClonePrompt | Should -BeFalse
        Test-Path -LiteralPath (Join-Path $script:Clone '.specrew\start-context.json') | Should -BeFalse
    }

    It 'neither refuses nor pauses at the clone''s first start' {
        $first = Invoke-NoConsoleStart -Root $script:Clone
        $first.ExitCode | Should -Be 0 -Because $first.Text
        $first.Text | Should -Not -Match 'could not continue'
        Get-Content -LiteralPath $script:ClonePrompt -Raw | Should -Not -Match 'PAUSE-AND-CONFIRM'
        (& git -C $script:Origin rev-parse HEAD).Trim() | Should -Be $script:OriginHead
        @(& git -C $script:Origin status --porcelain=v1 --untracked-files=all).Count | Should -Be 0
    }

    It 'pauses at the next start, naming the file, after a user edit to a committed charter' {
        $charter = @(Get-ChildItem -Path (Join-Path $script:Clone '.squad\agents\*\charter.md') -File)[0]
        [IO.File]::AppendAllText($charter.FullName, "`nA rule the collaborator added.`n")
        $null = Save-FixtureCommit -Root $script:Clone -Message 'collaborator edits a charter'
        $next = Invoke-NoConsoleStart -Root $script:Clone
        $next.ExitCode | Should -Be 0 -Because $next.Text
        $prompt = Get-Content -LiteralPath $script:ClonePrompt -Raw
        $prompt | Should -Match 'PAUSE-AND-CONFIRM'
        $prompt | Should -Match ([regex]::Escape(('.squad\agents\{0}\charter.md' -f $charter.Directory.Name)))
    }
}
