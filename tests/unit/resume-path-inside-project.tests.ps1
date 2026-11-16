# Feature 206, T023 (FR-001, SC-001, bug list item 23): `specrew start` re-anchored to, and wrote into, a feature
# outside the -ProjectPath it was given. The route: the tracked `.squad/identity/now.md` carried an absolute
# `session_state_feature_path`; with no prompt or start context the session state came from it; start then adopted
# that path (or recovery choice A passed it as the resume override), and `Resolve-FeatureDirectory` accepted any
# rooted path. Now a resume path outside the project is refused, start does not adopt an outside path from the
# session state, and the identity file records the feature path relative to the project.
#
# Everything runs inside temp folders this suite creates. The end-to-end cases run scripts/specrew-start.ps1
# -NoLaunch -SkipUpdateCheck with the user profile pointed at a temp file.

BeforeAll {
    $script:RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
    . (Join-Path $script:RepoRoot 'scripts\internal\session-recovery.ps1')
    $script:StartScript = Join-Path $script:RepoRoot 'scripts\specrew-start.ps1'
    $script:StartSource = Get-Content -LiteralPath $script:StartScript -Raw
    $script:ResolveFeatureDirectory = [regex]::Match($script:StartSource, '(?s)function Resolve-FeatureDirectory \{.*?\r?\n\}\r?\n').Value
    $script:SyncSource = Get-Content -LiteralPath (Join-Path $script:RepoRoot 'scripts\internal\sync-boundary-state.ps1') -Raw
    $script:TempRoots = New-Object System.Collections.Generic.List[string]

    function New-TempFolder {
        param([string]$Name)
        $root = Join-Path ([IO.Path]::GetTempPath()) ('resume-inside-' + $Name + '-' + [guid]::NewGuid().ToString('N').Substring(0, 10))
        $null = New-Item -ItemType Directory -Path $root -Force
        $script:TempRoots.Add($root) | Out-Null
        return (Resolve-Path -LiteralPath $root).ProviderPath
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
    }

    function New-GovernedProject {
        param([string]$Name, [string]$IdentityFeaturePath = '(none)')
        $root = New-TempFolder -Name $Name
        & git -C $root init --quiet --initial-branch=001-demo
        & git -C $root config user.email 'resume-inside-fixture@example.invalid'
        & git -C $root config user.name 'Resume Inside Fixture'
        Set-FixtureFile -Root $root -RelativePath '.gitignore' -Content ".specrew/last-*`n.specrew/start-context.json`n.specrew/start-summary.md`n.specrew/runtime/`n.specrew/host-history.json`n.specrew/active-sessions.yml`n"
        Set-FixtureFile -Root $root -RelativePath '.specrew/config.yml' -Content "version: 1`n"
        Set-FixtureFile -Root $root -RelativePath '.specify/README.md' -Content "fixture`n"
        Set-FixtureFile -Root $root -RelativePath '.squad/team.md' -Content "# Team`n"
        Set-FixtureFile -Root $root -RelativePath '.squad/config.json' -Content '{}'
        Set-FixtureFile -Root $root -RelativePath '.github/agents/squad.agent.md' -Content "# Squad Agent`n"
        Set-FixtureFile -Root $root -RelativePath 'specs/001-demo/spec.md' -Content "# Feature Specification: Demo`n"
        Set-FixtureFile -Root $root -RelativePath '.squad/decisions.md' -Content ("# Decisions`n`n## 2026-11-15T10:00:00Z — Boundary sync: specify`n`n- **Boundary Type**: specify`n- **Feature Ref**: 001-demo`n- **Auth Commit Hash**: 1111111111111111111111111111111111111111`n- **Recorded At**: 2026-11-15T10:00:00Z`n")
        Set-FixtureFile -Root $root -RelativePath '.squad/identity/now.md' -Content ("---`nfocus_area: `"Demo`"`nschema: v1`nsession_state_active: true`nsession_state_boundary: specify`nsession_state_feature: 001-demo`nsession_state_feature_path: $IdentityFeaturePath`nsession_state_iteration: (none)`nsession_state_task: (none)`nsession_state_auth_commit: 1111111111111111111111111111111111111111`nsession_state_recorded_at: 2026-11-15T10:00:00Z`n---`n`n# What We're Focused On`n")
        Save-FixtureCommit -Root $root -Message 'governed project'
        return $root
    }

    # Another checkout holding a feature of the same name: the place bug 23's runs wrote into.
    function New-OutsideFeature {
        $outside = New-TempFolder -Name 'outside'
        & git -C $outside init --quiet
        & git -C $outside config user.email 'resume-inside-fixture@example.invalid'
        & git -C $outside config user.name 'Resume Inside Fixture'
        Set-FixtureFile -Root $outside -RelativePath 'specs/001-demo/spec.md' -Content "# Feature Specification: Somewhere else`n"
        Set-FixtureFile -Root $outside -RelativePath 'specs/001-demo/iterations/001/plan.md' -Content "# Iteration Plan: 001`n`n**Status**: executing`n"
        Set-FixtureFile -Root $outside -RelativePath 'specs/001-demo/iterations/001/state.md' -Content "# Iteration State: 001`n`n**Schema**: v2`n"
        Save-FixtureCommit -Root $outside -Message 'another checkout'
        return $outside
    }

    function Invoke-FixtureStart {
        param([string]$Root, [string[]]$Extra = @())
        $output = @('' | & pwsh -NoProfile -ExecutionPolicy Bypass -File $script:StartScript -ProjectPath $Root -HostKind copilot -NoLaunch -SkipUpdateCheck @Extra 2>&1)
        return [pscustomobject]@{ ExitCode = $LASTEXITCODE; Text = ($output -join "`n") }
    }
}

AfterAll {
    foreach ($root in $script:TempRoots) {
        Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Describe 'Which paths are inside the project' {
    It 'accepts the project root and paths below it, and refuses a sibling whose name starts the same' {
        $root = New-TempFolder -Name 'inside'
        Test-SpecrewPathInsideProject -ProjectRoot $root -Path $root | Should -BeTrue
        Test-SpecrewPathInsideProject -ProjectRoot $root -Path (Join-Path $root 'specs\001-demo') | Should -BeTrue
        Test-SpecrewPathInsideProject -ProjectRoot $root -Path ($root + '-sibling\specs\001-demo') | Should -BeFalse
        Test-SpecrewPathInsideProject -ProjectRoot $root -Path (Join-Path $root '..\elsewhere') | Should -BeFalse
    }
}

Describe 'A link inside the project does not make an outside folder inside (round 1, F3)' {
    BeforeAll {
        $script:LinkRoot = New-TempFolder -Name 'f3'
        $script:LinkTargetRoot = New-TempFolder -Name 'f3-target'
        $null = New-Item -ItemType Directory -Path (Join-Path $script:LinkTargetRoot 'specs\001-demo') -Force
        $null = New-Item -ItemType Directory -Path (Join-Path $script:LinkRoot 'specs') -Force
        $script:LinkPath = Join-Path $script:LinkRoot 'specs\linked'
        $linkType = if ($IsWindows) { 'Junction' } else { 'SymbolicLink' }
        $null = New-Item -ItemType $linkType -Path $script:LinkPath -Target (Join-Path $script:LinkTargetRoot 'specs') -Force
    }
    AfterAll {
        # Remove the link itself first, so the cleanup never walks into the target.
        if (Test-Path -LiteralPath $script:LinkPath) { [IO.Directory]::Delete($script:LinkPath, $false) }
    }

    It 'treats a path through a junction or symlink as outside' {
        Test-Path -LiteralPath (Join-Path $script:LinkPath '001-demo') | Should -BeTrue
        Test-SpecrewPathInsideProject -ProjectRoot $script:LinkRoot -Path (Join-Path $script:LinkPath '001-demo') | Should -BeFalse
    }

    It 'still accepts an ordinary folder inside the same project' {
        $null = New-Item -ItemType Directory -Path (Join-Path $script:LinkRoot 'specs\002-real') -Force
        Test-SpecrewPathInsideProject -ProjectRoot $script:LinkRoot -Path (Join-Path $script:LinkRoot 'specs\002-real') | Should -BeTrue
    }

    It 'Resolve-FeatureDirectory refuses a feature folder reached through a link' {
        . ([scriptblock]::Create($script:ResolveFeatureDirectory))
        { Resolve-FeatureDirectory -Root $script:LinkRoot -ResumeFeature 'specs\linked\001-demo' } | Should -Throw -ExpectedMessage '*outside the project*'
    }
}

Describe 'A resume path outside -ProjectPath is refused (item 23)' {
    It 'Resolve-FeatureDirectory refuses a rooted path outside the project' {
        $script:ResolveFeatureDirectory | Should -Not -BeNullOrEmpty
        . ([scriptblock]::Create($script:ResolveFeatureDirectory))
        $root = New-TempFolder -Name 'resolve'
        $outside = New-TempFolder -Name 'resolve-outside'
        { Resolve-FeatureDirectory -Root $root -ResumeFeature (Join-Path $outside 'specs\001-demo') } | Should -Throw -ExpectedMessage '*outside the project*'
    }

    It 'Resolve-FeatureDirectory still resolves a path inside the project, rooted or relative' {
        . ([scriptblock]::Create($script:ResolveFeatureDirectory))
        $root = New-TempFolder -Name 'resolve-inside'
        Resolve-FeatureDirectory -Root $root -ResumeFeature (Join-Path $root 'specs\001-demo') | Should -Be ([IO.Path]::GetFullPath((Join-Path $root 'specs\001-demo')))
        Resolve-FeatureDirectory -Root $root -ResumeFeature 'specs\001-demo' | Should -Be ([IO.Path]::GetFullPath((Join-Path $root 'specs\001-demo')))
    }

    It 'specrew start refuses --resume-feature outside the project and writes nothing there' {
        $previous = $env:SPECREW_USER_PROFILE_PATH
        $env:SPECREW_USER_PROFILE_PATH = Join-Path ([IO.Path]::GetTempPath()) ('specrew-test-profile-' + [guid]::NewGuid().ToString('N') + '.yml')
        try {
            $root = New-GovernedProject -Name 'flag'
            $outside = New-OutsideFeature
            $result = Invoke-FixtureStart -Root $root -Extra @('-ResumeFeature', (Join-Path $outside 'specs\001-demo'))
            $result.ExitCode | Should -Not -Be 0 -Because $result.Text
            $result.Text | Should -Match 'outside the project'
            @(& git -C $outside status --porcelain=v1 --untracked-files=all).Count | Should -Be 0
        }
        finally {
            Remove-Item -LiteralPath $env:SPECREW_USER_PROFILE_PATH -Force -ErrorAction SilentlyContinue
            $env:SPECREW_USER_PROFILE_PATH = $previous
        }
    }

    It 'specrew start does not adopt an outside feature path from the identity file, and writes nothing there' {
        $previous = $env:SPECREW_USER_PROFILE_PATH
        $env:SPECREW_USER_PROFILE_PATH = Join-Path ([IO.Path]::GetTempPath()) ('specrew-test-profile-' + [guid]::NewGuid().ToString('N') + '.yml')
        try {
            $outside = New-OutsideFeature
            $root = New-GovernedProject -Name 'identity' -IdentityFeaturePath (Join-Path $outside 'specs\001-demo')
            $result = Invoke-FixtureStart -Root $root
            $result.ExitCode | Should -Be 0 -Because $result.Text
            $prompt = Get-Content -LiteralPath (Join-Path $root '.specrew\last-start-prompt.md') -Raw
            $prompt | Should -Not -Match ([regex]::Escape($outside))
            @(& git -C $outside status --porcelain=v1 --untracked-files=all).Count | Should -Be 0
        }
        finally {
            Remove-Item -LiteralPath $env:SPECREW_USER_PROFILE_PATH -Force -ErrorAction SilentlyContinue
            $env:SPECREW_USER_PROFILE_PATH = $previous
        }
    }
}

Describe 'An outside session path that is not adopted is not written back either (round 1, F4)' {
    It 'clears the outside path from the prompt when no feature resolves' {
        $previous = $env:SPECREW_USER_PROFILE_PATH
        $env:SPECREW_USER_PROFILE_PATH = Join-Path ([IO.Path]::GetTempPath()) ('specrew-test-profile-' + [guid]::NewGuid().ToString('N') + '.yml')
        try {
            $outside = New-OutsideFeature
            # A governed project with no feature folder, so nothing resolves; the identity names no feature, so no
            # branch or authorization check makes it stale; its feature path points into another checkout.
            $root = New-TempFolder -Name 'f4'
            & git -C $root init --quiet --initial-branch=main
            & git -C $root config user.email 'resume-inside-fixture@example.invalid'
            & git -C $root config user.name 'Resume Inside Fixture'
            Set-FixtureFile -Root $root -RelativePath '.gitignore' -Content ".specrew/last-*`n.specrew/start-context.json`n.specrew/start-summary.md`n.specrew/runtime/`n.specrew/host-history.json`n.specrew/active-sessions.yml`n"
            Set-FixtureFile -Root $root -RelativePath '.specrew/config.yml' -Content "version: 1`n"
            Set-FixtureFile -Root $root -RelativePath '.specify/README.md' -Content "fixture`n"
            Set-FixtureFile -Root $root -RelativePath '.squad/team.md' -Content "# Team`n"
            Set-FixtureFile -Root $root -RelativePath '.squad/config.json' -Content '{}'
            Set-FixtureFile -Root $root -RelativePath '.squad/decisions.md' -Content "# Decisions`n"
            Set-FixtureFile -Root $root -RelativePath '.github/agents/squad.agent.md' -Content "# Squad Agent`n"
            Set-FixtureFile -Root $root -RelativePath '.squad/identity/now.md' -Content ("---`nschema: v1`nsession_state_active: true`nsession_state_boundary: specify`nsession_state_feature: (none)`nsession_state_feature_path: {0}`nsession_state_iteration: (none)`nsession_state_task: (none)`nsession_state_auth_commit: (none)`nsession_state_recorded_at: 2026-11-15T10:00:00Z`n---`n`n# What We're Focused On`n" -f (Join-Path $outside 'specs\001-demo'))
            Save-FixtureCommit -Root $root -Message 'governed project with no feature'

            $result = Invoke-FixtureStart -Root $root
            $result.ExitCode | Should -Be 0 -Because $result.Text
            Get-Content -LiteralPath (Join-Path $root '.specrew\last-start-prompt.md') -Raw | Should -Not -Match ([regex]::Escape($outside))
            $contextPath = Join-Path $root '.specrew\start-context.json'
            if (Test-Path -LiteralPath $contextPath) { Get-Content -LiteralPath $contextPath -Raw | Should -Not -Match ([regex]::Escape(($outside -replace '\\', '\\'))) }
            @(& git -C $outside status --porcelain=v1 --untracked-files=all).Count | Should -Be 0
        }
        finally {
            Remove-Item -LiteralPath $env:SPECREW_USER_PROFILE_PATH -Force -ErrorAction SilentlyContinue
            $env:SPECREW_USER_PROFILE_PATH = $previous
        }
    }
}

Describe 'The identity file records the feature path relative to the project (item 23)' {
    It 'the reader resolves a relative feature path against the project root' {
        $root = New-GovernedProject -Name 'reader' -IdentityFeaturePath 'specs/001-demo'
        $state = Get-SpecrewIdentitySessionState -ProjectRoot $root
        $state.feature_path | Should -Be ([IO.Path]::GetFullPath((Join-Path $root 'specs\001-demo')))
    }

    It 'the writer turns a feature path inside the project into a relative one, and drops one outside' {
        $root = New-TempFolder -Name 'writer'
        ConvertTo-SpecrewIdentityFeaturePath -ProjectRoot $root -FeaturePath (Join-Path $root 'specs\001-demo') | Should -Be 'specs/001-demo'
        ConvertTo-SpecrewIdentityFeaturePath -ProjectRoot $root -FeaturePath ($root + '-sibling\specs\001-demo') | Should -Be '(none)'
        ConvertTo-SpecrewIdentityFeaturePath -ProjectRoot $root -FeaturePath '' | Should -Be '(none)'
    }

    It 'a real boundary sync writes the identity file''s feature path relative (round 1, F7)' {
        # Round 1 F7: this case read sync-boundary-state.ps1 as text, so a comment or a dead line could keep it green while
        # the identity file was written with the absolute path again. It now runs the boundary sync itself, through the
        # extension's wrapper, on a temp project, and reads the identity file the sync wrote.
        $root = New-TempFolder -Name 'f7-sync'
        & git -C $root init --quiet --initial-branch=main
        & git -C $root config user.email 'resume-inside-fixture@example.invalid'
        & git -C $root config user.name 'Resume Inside Fixture'
        Set-FixtureFile -Root $root -RelativePath '.specrew/config.yml' -Content "project_name: sample`nspecrew_version: `"0.0.0`"`nbootstrap_date: `"2026-01-01`"`n"
        Set-FixtureFile -Root $root -RelativePath '.specify/feature.json' -Content "{`n  `"feature_directory`": `"specs/022-identity-relative`"`n}"
        Set-FixtureFile -Root $root -RelativePath '.squad/team.md' -Content "# Team`n"
        Set-FixtureFile -Root $root -RelativePath '.squad/config.json' -Content "{}`n"
        Set-FixtureFile -Root $root -RelativePath '.squad/decisions.md' -Content "# Decisions`n"
        Set-FixtureFile -Root $root -RelativePath '.github/agents/squad.agent.md' -Content "# Squad Agent`n"
        Set-FixtureFile -Root $root -RelativePath 'specs/022-identity-relative/spec.md' -Content "# Spec`n"
        $null = New-Item -ItemType Directory -Path (Join-Path $root 'specs\022-identity-relative\iterations\001') -Force
        Set-FixtureFile -Root $root -RelativePath 'README.md' -Content "# Test Repo`n"
        Save-FixtureCommit -Root $root -Message 'seed'
        & git -C $root checkout --quiet -b 022-identity-relative

        $syncScript = Join-Path $script:RepoRoot 'extensions\specrew-speckit\scripts\sync-boundary-state.ps1'
        $output = @(& pwsh -NoProfile -ExecutionPolicy Bypass -File $syncScript -ProjectPath $root -BoundaryType specify -FeatureRef 022-identity-relative -IterationNumber 001 2>&1)
        $LASTEXITCODE | Should -Be 0 -Because ($output -join "`n")
        $identity = Get-Content -LiteralPath (Join-Path $root '.squad\identity\now.md') -Raw
        $identity | Should -Match '(?m)^session_state_feature_path:\s*specs/022-identity-relative\s*$'
        $identity | Should -Not -Match ([regex]::Escape($root))
    }
}

Describe 'A path that one OS calls absolute and another does not (Specrew CI on Linux, 2026-11-16)' {
    # Specrew CI's Linux runner (run 43851050990) met this repository's tracked identity file carrying a Windows
    # path: [IO.Path]::IsPathRooted('C:\...') is false on Linux, so the reader joined it under the project root and
    # start refused with stale session state. A Windows clone in another folder meets the same refusal for a path
    # that does not exist there. Every case below holds on Windows and on Linux.
    BeforeAll {
        $script:ForeignWindows = 'C:\Dev\other-machine-' + [guid]::NewGuid().ToString('N').Substring(0, 8) + '\specs\001-demo'
    }

    It 'one helper names what kind of path it is: <Path> is <Kind>' -ForEach @(
        @{ Path = 'C:\x\specs'; Kind = 'absolute' }
        @{ Path = 'C:/x/specs'; Kind = 'absolute' }
        @{ Path = '\\server\share\specs'; Kind = 'absolute' }
        @{ Path = '//server/share/specs'; Kind = 'absolute' }
        @{ Path = '/home/runner/specs'; Kind = 'absolute' }
        @{ Path = 'C:specs\001-demo'; Kind = 'drive-relative' }
        @{ Path = 'specs/001-demo'; Kind = 'relative' }
        @{ Path = 'specs/odd:name'; Kind = 'relative' }
    ) {
        Get-SpecrewPathRootKind -Path $Path | Should -Be $Kind
    }

    It 'another OS''s absolute path, a UNC path and a drive-relative path are outside the project; a colon in a relative path is not' {
        $root = New-TempFolder -Name 'kinds'
        foreach ($outside in @($script:ForeignWindows, ($script:ForeignWindows -replace '\\', '/'), '\\server\share\specs\001-demo', '//server/share/specs/001-demo', '/elsewhere/specs/001-demo', 'C:specs\001-demo')) {
            Test-SpecrewPathInsideProject -ProjectRoot $root -Path $outside | Should -BeFalse -Because $outside
            ConvertTo-SpecrewIdentityFeaturePath -ProjectRoot $root -FeaturePath $outside | Should -Be '(none)' -Because $outside
        }
        Test-SpecrewPathInsideProject -ProjectRoot $root -Path 'specs/odd:name' | Should -BeTrue
        ConvertTo-SpecrewIdentityFeaturePath -ProjectRoot $root -FeaturePath 'specs/001-demo' | Should -Be 'specs/001-demo'
    }

    It 'the identity reader does not use <Name>, and warns naming the file and why' -ForEach @(
        @{ Name = 'another machine''s absolute path'; Value = 'FOREIGN' }
        @{ Name = 'a drive-relative path'; Value = 'C:specs\001-demo' }
        @{ Name = 'a UNC path'; Value = '\\server\share\specs\001-demo' }
        @{ Name = 'a relative path that climbs out of the project (iteration 002 round 2, finding 4)'; Value = '../other-checkout/specs/001-demo' }
    ) {
        $value = if ($Value -eq 'FOREIGN') { $script:ForeignWindows } else { $Value }
        $root = New-GovernedProject -Name 'reader-foreign' -IdentityFeaturePath $value
        $before = Get-Content -LiteralPath (Join-Path $root '.squad\identity\now.md') -Raw
        $state = Get-SpecrewIdentitySessionState -ProjectRoot $root -WarningVariable warned -WarningAction SilentlyContinue
        $state | Should -Not -BeNullOrEmpty
        $state.feature_path | Should -BeNullOrEmpty
        $state.feature_ref | Should -Be '001-demo'
        ($warned -join "`n") | Should -Match ([regex]::Escape('.squad/identity/now.md'))
        ($warned -join "`n") | Should -Match 'not changed'
        Get-Content -LiteralPath (Join-Path $root '.squad\identity\now.md') -Raw | Should -BeExactly $before
    }

    It 'specrew start on a clone whose tracked identity file holds another machine''s path starts, warns, and leaves the file as committed' {
        $previous = $env:SPECREW_USER_PROFILE_PATH
        $env:SPECREW_USER_PROFILE_PATH = Join-Path ([IO.Path]::GetTempPath()) ('specrew-test-profile-' + [guid]::NewGuid().ToString('N') + '.yml')
        try {
            $root = New-GovernedProject -Name 'clone-foreign' -IdentityFeaturePath $script:ForeignWindows
            $result = Invoke-FixtureStart -Root $root
            $result.ExitCode | Should -Be 0 -Because $result.Text
            $result.Text | Should -Not -Match 'stale session state'
            $result.Text | Should -Match ([regex]::Escape('.squad/identity/now.md'))
            Get-Content -LiteralPath (Join-Path $root '.specrew\last-start-prompt.md') -Raw | Should -Not -Match ([regex]::Escape('other-machine'))
            & git -C $root diff --quiet -- .squad/identity/now.md
            $LASTEXITCODE | Should -Be 0 -Because 'start does not rewrite the tracked identity file'
        }
        finally {
            Remove-Item -LiteralPath $env:SPECREW_USER_PROFILE_PATH -Force -ErrorAction SilentlyContinue
            $env:SPECREW_USER_PROFILE_PATH = $previous
        }
    }

    It 'each entry point reaches the helper when loaded on its own: <Entry>' -ForEach @(
        @{ Entry = 'scripts/internal/sync-boundary-state.ps1'; Call = 'Test-SpecrewPathInsideProject -ProjectRoot ([IO.Path]::GetTempPath()) -Path ''C:specs\x''' }
        @{ Entry = 'scripts/internal/session-recovery.ps1'; Call = 'Get-SpecrewPathRootKind -Path ''C:/x''' }
    ) {
        $script = ". '{0}'; {1}" -f (Join-Path $script:RepoRoot $Entry), $Call
        $out = @(& pwsh -NoProfile -NonInteractive -Command $script 2>&1)
        $LASTEXITCODE | Should -Be 0 -Because ($out -join "`n")
        ($out -join "`n") | Should -Not -Match 'is not recognized'
        ($out | Select-Object -Last 1).ToString() | Should -BeIn @('False', 'absolute')
    }
}
