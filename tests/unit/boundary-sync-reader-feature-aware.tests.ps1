# Feature 203 T031 (B5F-093; the maintainer's "203 add task: feature-aware boundary sync reader, about 1 SP", 20:08 local
# on 2026-11-18, relayed; iteration 002 DRIFT-044): after a feature takes main in, .squad/decisions.md holds another
# feature's later "Boundary sync:" entries (206's feature-closeout after 203's before-implement), and every reader that
# took "the latest" by position read the other feature's state: the stale-session check (a fresh clone's start refused),
# the boundary sync's previous commit, the review command's sync warning, and the resume snapshot.
# Get-LatestSpecrewBoundarySyncState now takes -FeatureRef and returns that feature's own last entry; without it the
# by-position answer is unchanged, and a caller that cannot tell the session's feature keeps it.
#
# Everything runs in temp folders this suite creates. Nothing is deployed and no home is read or written.

BeforeAll {
    $script:RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
    . (Join-Path $script:RepoRoot 'scripts\internal\session-recovery.ps1')
    . (Join-Path $script:RepoRoot 'scripts\internal\sync-boundary-state.ps1')
    $script:TempRoots = New-Object System.Collections.Generic.List[string]

    function script:Get-ScriptFunctionText([string]$RelativePath, [string]$Name) {
        $ast = [System.Management.Automation.Language.Parser]::ParseFile((Join-Path $script:RepoRoot $RelativePath), [ref]$null, [ref]$null)
        $fn = $ast.Find({ param($n) $n -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $n.Name -eq $Name }, $true)
        if ($null -eq $fn) { throw "fixture: $Name not found in $RelativePath" }
        return $fn
    }

    function script:New-SyncEntry([string]$At, [string]$Boundary, [string]$Feature, [string]$Iteration = '002', [string]$Commit = ('0' * 40)) {
        return ("## {0} — Boundary sync: {1}`n`n- **Boundary Type**: {1}`n- **Feature Ref**: {2}`n- **Iteration Number**: {3}`n- **Task ID**: (none)`n- **Auth Commit Hash**: {4}`n- **Recorded At**: {0}`n" -f $At, $Boundary, $Feature, $Iteration, $Commit)
    }

    # The shape a merge of main leaves: this feature's syncs, then another feature's later ones, ending in its closeout.
    function script:New-MergedProject([string]$NowFeature = '203-demo', [string]$NowBoundary = 'before-implement', [string]$OwnFeatureRefText = '203-demo', [switch]$WithWarning) {
        $root = Join-Path ([IO.Path]::GetTempPath()) ('sync-reader-' + [guid]::NewGuid().ToString('N').Substring(0, 10))
        $null = New-Item -ItemType Directory -Path (Join-Path $root '.squad/identity'), (Join-Path $root '.specrew'), (Join-Path $root 'specs/203-demo/iterations/002'), (Join-Path $root 'specs/206-other/iterations/002') -Force
        $script:TempRoots.Add($root) | Out-Null
        $entries = @(
            '# Decisions'
            ''
            (script:New-SyncEntry -At '2026-11-16T14:44:58Z' -Boundary 'tasks' -Feature $OwnFeatureRefText -Commit ('a' * 40))
            (script:New-SyncEntry -At '2026-11-16T17:23:42Z' -Boundary 'before-implement' -Feature $OwnFeatureRefText -Commit ('b' * 40))
            (script:New-SyncEntry -At '2026-11-17T20:16:46Z' -Boundary 'review-signoff' -Feature '206-other' -Commit ('c' * 40))
        )
        if ($WithWarning) {
            $entries += "## 2026-11-17T23:49:27Z — Boundary sync warning: iteration-closeout`n`n- **Boundary Type**: iteration-closeout`n- **Latest Recorded Boundary**: iteration-closeout`n- **Recorded At**: 2026-11-17T23:49:27Z`n- **Warning**: Expected next boundary 'feature-closeout' but received 'iteration-closeout'.`n"
        }
        $entries += (script:New-SyncEntry -At '2026-11-18T01:14:12Z' -Boundary 'feature-closeout' -Feature '206-other' -Commit ('d' * 40))
        [IO.File]::WriteAllText((Join-Path $root '.squad/decisions.md'), ($entries -join "`n"), [Text.UTF8Encoding]::new($false))
        $now = "---`nfocus_area: `"Demo`"`nschema: v1`nupdated_at: 2026-11-16T17:23:33Z`nsession_state_active: true`nsession_state_boundary: $NowBoundary`nsession_state_feature: $NowFeature`nsession_state_feature_path: specs/$NowFeature`nsession_state_iteration: 002`nsession_state_task: `"(none)`"`nsession_state_auth_commit: $('b' * 40)`nsession_state_recorded_at: 2026-11-16T17:23:33Z`n---`n`n# What We're Focused On`n"
        [IO.File]::WriteAllText((Join-Path $root '.squad/identity/now.md'), $now, [Text.UTF8Encoding]::new($false))
        return $root
    }
}

AfterAll {
    foreach ($root in $script:TempRoots) {
        if ((Split-Path -Leaf $root) -like 'sync-reader-*') { Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue }
    }
}

Describe 'T031: the boundary sync reader answers for the session''s own feature' {
    It 'a feature resolves its own last sync, not another feature''s later closeout' {
        $root = script:New-MergedProject
        $own = Get-LatestSpecrewBoundarySyncState -ProjectRoot $root -FeatureRef '203-demo'
        $own.boundary_type | Should -Be 'before-implement'
        $own.feature_ref | Should -Be '203-demo'
        $own.auth_commit_hash | Should -Be ('b' * 40)
    }

    It 'with no feature given, the last entry by position, unchanged (pinned)' {
        $root = script:New-MergedProject
        $latest = Get-LatestSpecrewBoundarySyncState -ProjectRoot $root
        $latest.boundary_type | Should -Be 'feature-closeout'
        $latest.feature_ref | Should -Be '206-other'
        $latest.auth_commit_hash | Should -Be ('d' * 40)
    }

    It 'a feature with no entry gets what no entry gives today, never another feature''s entry (pinned)' {
        $root = script:New-MergedProject
        Get-LatestSpecrewBoundarySyncState -ProjectRoot $root -FeatureRef '999-absent' | Should -BeNullOrEmpty
    }

    It 'a "Boundary sync warning:" entry stays skipped (pinned)' {
        $root = script:New-MergedProject -WithWarning
        (Get-LatestSpecrewBoundarySyncState -ProjectRoot $root -FeatureRef '206-other').boundary_type | Should -Be 'feature-closeout'
        (Get-LatestSpecrewBoundarySyncState -ProjectRoot $root).boundary_type | Should -Be 'feature-closeout'
    }

    It 'a Feature Ref written as a path and one written as a leaf both match (pinned)' {
        $asPath = script:New-MergedProject -OwnFeatureRefText 'specs/203-demo'
        (Get-LatestSpecrewBoundarySyncState -ProjectRoot $asPath -FeatureRef '203-demo').boundary_type | Should -Be 'before-implement'
        $asLeaf = script:New-MergedProject
        (Get-LatestSpecrewBoundarySyncState -ProjectRoot $asLeaf -FeatureRef 'C:\work\proj\specs\203-demo').boundary_type | Should -Be 'before-implement'
    }
}

Describe 'T031: a feature''s first sync after another feature''s closeout' {
    # The sync's "Expected next boundary" check reads the same latest entry. Before T031 it read the other feature's
    # feature-closeout and expected nothing; now a feature with no sync of its own expects the first boundary (specify),
    # and a first recorded sync at another boundary writes the warning entry and still syncs (a warning, not a refusal).
    It 'expects specify: a first sync at <Boundary> writes the warning entry <Warns> and is not refused' -ForEach @(
        @{ Boundary = 'clarify'; Warns = $true }
        @{ Boundary = 'specify'; Warns = $false }
    ) {
        $root = Join-Path ([IO.Path]::GetTempPath()) ('sync-reader-' + [guid]::NewGuid().ToString('N').Substring(0, 10))
        $script:TempRoots.Add($root) | Out-Null
        $null = New-Item -ItemType Directory -Path (Join-Path $root '.squad'), (Join-Path $root 'specs/207-new/iterations/001') -Force
        & git -C $root init --quiet
        & git -C $root config user.email 'sync-reader@example.invalid'
        & git -C $root config user.name 'Sync Reader Fixture'
        [IO.File]::WriteAllText((Join-Path $root '.squad/decisions.md'), ("# Decisions`n`n" + (script:New-SyncEntry -At '2026-11-18T01:14:12Z' -Boundary 'feature-closeout' -Feature '206-other' -Commit ('d' * 40))), [Text.UTF8Encoding]::new($false))
        [IO.File]::WriteAllText((Join-Path $root 'README.md'), "# Fixture`n", [Text.UTF8Encoding]::new($false))
        & git -C $root add -A
        & git -C $root commit --quiet -m 'seed'
        & git -C $root checkout --quiet -b 207-new
        $sync = Join-Path $script:RepoRoot 'extensions\specrew-speckit\scripts\sync-boundary-state.ps1'
        $output = @(& pwsh -NoProfile -ExecutionPolicy Bypass -File $sync -ProjectPath $root -BoundaryType $Boundary -FeatureRef 207-new -IterationNumber 001 2>&1)
        $LASTEXITCODE | Should -Be 0 -Because ($output -join "`n")
        $headings = @(Get-Content -LiteralPath (Join-Path $root '.squad/decisions.md') | Where-Object { $_ -match '^## ' })
        @($headings | Where-Object { $_ -match "— Boundary sync: $Boundary$" }).Count | Should -Be 1
        $warning = @($headings | Where-Object { $_ -match "— Boundary sync warning: $Boundary$" })
        if ($Warns) { $warning.Count | Should -Be 1 -Because "a first sync at $Boundary is not the expected specify" }
        else { $warning.Count | Should -Be 0 }
    }
}

Describe 'T031: the four callers read the session''s own feature' {
    It 'session recovery: a fresh clone whose own last sync agrees with now.md is not stale' {
        $root = script:New-MergedProject
        $issues = @(Test-SpecrewSessionStateConsistency -Snapshot (Get-SpecrewSessionStateSnapshot -ProjectRoot $root))
        ($issues -join "`n") | Should -Not -Match 'feature mismatch|boundary mismatch'
    }

    It 'session recovery: the session''s own records that disagree are still reported (pinned)' {
        $root = script:New-MergedProject -NowBoundary 'review-signoff'
        $issues = @(Test-SpecrewSessionStateConsistency -Snapshot (Get-SpecrewSessionStateSnapshot -ProjectRoot $root))
        ($issues -join "`n") | Should -Match 'boundary mismatch detected: review-signoff, before-implement'
    }

    It 'the boundary sync takes its previous commit from the feature''s own last sync' {
        $sync = script:Get-ScriptFunctionText -RelativePath 'scripts\internal\sync-boundary-state.ps1' -Name 'Invoke-SpecrewBoundaryStateSync'
        $calls = @($sync.FindAll({ param($n) $n -is [System.Management.Automation.Language.CommandAst] -and $n.GetCommandName() -eq 'Get-LatestSpecrewBoundarySyncState' }, $true))
        $calls.Count | Should -BeGreaterThan 0
        foreach ($call in $calls) { $call.Extent.Text | Should -Match '-FeatureRef\s+\$effectiveFeatureRef\b' }
    }

    It 'the review command: the sync warning and the state-file rule return for the session''s feature' {
        $fn = script:Get-ScriptFunctionText -RelativePath 'scripts\specrew-review.ps1' -Name 'Get-ReviewBoundarySyncWarning'
        . ([scriptblock]::Create($fn.Extent.Text))
        $meta = script:Get-ScriptFunctionText -RelativePath 'scripts\specrew-review.ps1' -Name 'Get-MetadataValue'
        . ([scriptblock]::Create($meta.Extent.Text))
        $script:RequireStateFileSeen = $null
        function Get-SpecrewIterationStateTruthIssues { param($ProjectRoot, $FeaturePath, $IterationNumber, [switch]$RequireStateFile) $script:RequireStateFileSeen = [bool]$RequireStateFile; @() }
        $root = script:New-MergedProject
        $review = Join-Path $root 'specs/203-demo/iterations/002/review.md'
        [IO.File]::WriteAllText($review, "# Review`n`n**Overall Verdict**: accepted`n", [Text.UTF8Encoding]::new($false))
        $warning = Get-ReviewBoundarySyncWarning -ProjectRoot $root -ReviewPath $review
        ($warning | Out-String) | Should -Match 'not synced to review-signoff' -Because "203's own last sync is before-implement, not 206's feature-closeout"
        $script:RequireStateFileSeen | Should -BeTrue
    }

    It 'the resume snapshot shows the session feature''s own last sync' {
        # Run in a child process: coordinator-resume.ps1 loads its own helpers when dot-sourced.
        $root = script:New-MergedProject
        $probe = @"
`$ErrorActionPreference = 'Stop'
. '$($script:RepoRoot)\scripts\internal\coordinator-resume.ps1'
`$s = Get-CoordinatorResumeSnapshot -ProjectRoot '$root' -ResolvedFeaturePath '$root\specs\203-demo' -SessionState ([pscustomobject]@{ feature_ref = '203-demo'; iteration_number = '002'; boundary_type = 'before-implement' })
[string]`$s.last_boundary_commit
"@
        $out = @(& pwsh -NoProfile -NonInteractive -Command $probe 2>&1)
        ([string]$out[-1]).Trim() | Should -Be ('b' * 40) -Because "203's own last sync, not 206's closeout ($($out -join ' | '))"
    }
}
