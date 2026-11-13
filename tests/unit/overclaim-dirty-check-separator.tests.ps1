# Feature 206, T002 (FR-002, bug list item 2a): the over-claim dirty-tree check must see an uncommitted edit to a
# closed iteration's canonical artifact. It compared git's forward-slash paths, turned into backslashes, with a
# canonical list in forward slashes, so nothing ever matched and the check was inert on every platform.
#
# This suite exercises the same fixture as assertions 1 and 2 of tests/integration/validator-hardening-iteration2.ps1
# through validate-governance.ps1 only: no specrew start, no update, no hooks. Each workspace is a temp-folder copy
# of the files git tracks under the repository's .specrew, .squad and .github, and the feature-013 specs; the validator runs against it in a
# child pwsh. Nothing outside the temp folder is written.

BeforeAll {
    $script:RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
    $script:Validator = Join-Path $script:RepoRoot 'extensions\specrew-speckit\scripts\validate-governance.ps1'
    $script:FeatureSource = Join-Path $script:RepoRoot 'specs\013-validator-hardening'
    $script:PwshPath = (Get-Process -Id $PID).Path
    $script:Workspaces = New-Object System.Collections.Generic.List[string]

    function New-OverclaimWorkspace {
        $root = Join-Path ([System.IO.Path]::GetTempPath()) ('overclaim-sep-' + [guid]::NewGuid().ToString('N').Substring(0, 10))
        $null = New-Item -ItemType Directory -Path $root -Force
        $script:Workspaces.Add($root)
        # Only the files git tracks: the whole folder brought the git-ignored local review store and session state,
        # so a review result recorded on this machine changed the validator's answer here and not on CI.
        foreach ($trackedPath in @(& git -C $script:RepoRoot -c core.quotepath=off ls-files -- '.specrew' '.squad' '.github')) {
            $trackedSource = Join-Path $script:RepoRoot $trackedPath
            if (-not (Test-Path -LiteralPath $trackedSource -PathType Leaf)) { continue }
            $trackedTarget = Join-Path $root $trackedPath
            $null = New-Item -Path (Split-Path -Parent $trackedTarget) -ItemType Directory -Force
            Copy-Item -LiteralPath $trackedSource -Destination $trackedTarget -Force
        }
        $specs = Join-Path $root 'specs'
        $null = New-Item -ItemType Directory -Path $specs -Force
        Copy-Item -LiteralPath $script:FeatureSource -Destination $specs -Recurse -Force

        foreach ($gitArgs in @(
                @('init', '--quiet'),
                @('config', 'user.email', 'test@specrew.local'),
                @('config', 'user.name', 'Test User'),
                @('config', 'commit.gpgsign', 'false'),
                @('config', 'core.autocrlf', 'false'),
                @('add', '-A'),
                @('commit', '--quiet', '-m', 'Seed overclaim fixture'))) {
            $null = & git -C $root @gitArgs 2>&1
            if ($LASTEXITCODE -ne 0) { throw "git $($gitArgs -join ' ') failed in $root" }
        }
        return $root
    }

    function Invoke-FixtureValidator {
        param([Parameter(Mandatory = $true)][string]$Root)
        $iteration = Join-Path $Root (Join-Path 'specs' (Join-Path '013-validator-hardening' (Join-Path 'iterations' '001')))
        $command = "& '{0}' -ProjectPath '{1}' -IterationPath @('{2}')" -f $script:Validator.Replace("'", "''"), $Root.Replace("'", "''"), $iteration.Replace("'", "''")
        $output = @(& $script:PwshPath -NoProfile -ExecutionPolicy Bypass -Command $command 2>&1)
        [pscustomobject]@{ ExitCode = $LASTEXITCODE; Text = ($output -join "`n") }
    }
}

AfterAll {
    foreach ($root in $script:Workspaces) {
        if (Test-Path -LiteralPath $root) { Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue }
    }
}

Describe 'Over-claim dirty-tree check on a closed iteration (FR-002)' {
    It 'passes a closed iteration whose canonical artifacts are committed' {
        $root = New-OverclaimWorkspace
        $result = Invoke-FixtureValidator -Root $root
        $result.Text | Should -Not -Match 'uncommitted changes'
        $result.ExitCode | Should -Be 0 -Because $result.Text
    }

    It 'fails when a canonical artifact has an uncommitted edit, naming it with forward slashes' {
        $root = New-OverclaimWorkspace
        $plan = Join-Path $root (Join-Path 'specs' (Join-Path '013-validator-hardening' (Join-Path 'iterations' (Join-Path '001' 'plan.md'))))
        Add-Content -LiteralPath $plan -Value "`nDirty change" -Encoding UTF8
        $result = Invoke-FixtureValidator -Root $root
        $result.ExitCode | Should -Not -Be 0 -Because 'a dirty canonical artifact must not let the iteration claim closure'
        $result.Text | Should -Match 'category=over-claim'
        $result.Text | Should -Match 'uncommitted changes: specs/013-validator-hardening/iterations/001/plan\.md'
    }

    It 'ignores an uncommitted file in the iteration folder that is not a canonical artifact' {
        $root = New-OverclaimWorkspace
        $note = Join-Path $root (Join-Path 'specs' (Join-Path '013-validator-hardening' (Join-Path 'iterations' (Join-Path '001' 'scratch-note.txt'))))
        Set-Content -LiteralPath $note -Value 'not canonical' -Encoding UTF8
        $result = Invoke-FixtureValidator -Root $root
        $result.Text | Should -Not -Match 'uncommitted changes'
        $result.ExitCode | Should -Be 0 -Because $result.Text
    }
}

Describe 'The fixture takes every file git does not ignore under .specrew, .squad and .github (FR-002; bug list item 29)' {
    # A review round's preflight runs this suite in a verification copy: a git worktree of the frozen tree, which
    # leaves .specrew and .squad out, with those files restored into it UNTRACKED. A tracked-only copy therefore
    # built a fixture with no .squad and no .specrew there, and the round's preflight failed. The fixture takes
    # tracked and untracked files alike, and leaves out only what git ignores (the local review store).
    BeforeAll {
        $script:SnapshotLike = Join-Path ([System.IO.Path]::GetTempPath()) ('overclaim-snapshot-' + [guid]::NewGuid().ToString('N').Substring(0, 10))
        $script:Workspaces.Add($script:SnapshotLike)
        foreach ($dir in @('.github', '.squad', '.specrew\review\authority')) { $null = New-Item -ItemType Directory -Path (Join-Path $script:SnapshotLike $dir) -Force }
        Set-Content -LiteralPath (Join-Path $script:SnapshotLike '.gitignore') -Value '.specrew/review/authority/' -Encoding UTF8
        Set-Content -LiteralPath (Join-Path $script:SnapshotLike '.github\tracked.md') -Value 'tracked' -Encoding UTF8
        $null = & git -C $script:SnapshotLike init --quiet 2>&1
        $null = & git -C $script:SnapshotLike add -A 2>&1
        $null = & git -C $script:SnapshotLike -c user.name='Snapshot Fixture' -c user.email='snapshot-fixture@example.invalid' commit --quiet -m 'frozen tree without .specrew and .squad' 2>&1
        # Restored after the commit, as the preflight restores its support files: present, untracked, not ignored.
        Copy-Item -LiteralPath (Join-Path $script:RepoRoot '.squad\team.md') -Destination (Join-Path $script:SnapshotLike '.squad\team.md')
        Set-Content -LiteralPath (Join-Path $script:SnapshotLike '.specrew\legacy-frozen.yml') -Value "schema: v1`nentries: []" -Encoding UTF8
        Set-Content -LiteralPath (Join-Path $script:SnapshotLike '.specrew\review\authority\local-result.json') -Value '{}' -Encoding UTF8

        $realRoot = $script:RepoRoot
        try {
            $script:RepoRoot = $script:SnapshotLike
            $script:SnapshotWorkspace = New-OverclaimWorkspace
        }
        finally {
            $script:RepoRoot = $realRoot
        }
    }

    It 'copies a tracked file' {
        Test-Path -LiteralPath (Join-Path $script:SnapshotWorkspace '.github\tracked.md') | Should -BeTrue
    }

    It 'copies untracked files that git does not ignore, as the preflight''s restored support files are' {
        Test-Path -LiteralPath (Join-Path $script:SnapshotWorkspace '.squad\team.md') | Should -BeTrue
        Test-Path -LiteralPath (Join-Path $script:SnapshotWorkspace '.specrew\legacy-frozen.yml') | Should -BeTrue
    }

    It 'leaves out what git ignores: the local review store' {
        Test-Path -LiteralPath (Join-Path $script:SnapshotWorkspace '.specrew\review\authority\local-result.json') | Should -BeFalse
    }
}
