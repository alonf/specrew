# Feature 206, round 1 F2 (SC-001): SC-001's script copies this repository's tracked .squad/identity/now.md into its
# fixture. Until its next boundary sync that file holds this machine's absolute feature path, which exists only here:
# on CI or another machine the start case would read it as stale state and refuse with no console. The fixture now
# writes the copied path relative to the project, as T023 makes the boundary sync write it, or (none) when the path is
# outside the repository the fixture was copied from.
#
# The conversion is a function of the SC-001 script, lifted out and run on a temp identity file this suite creates.

BeforeAll {
    $script:RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
    . (Join-Path $script:RepoRoot 'scripts\internal\sync-boundary-state.ps1')
    $source = Get-Content -LiteralPath (Join-Path $script:RepoRoot 'tests\integration\project-path-resolution-regression.ps1') -Raw
    $script:Function = [regex]::Match($source, '(?s)function Set-Sc001FixtureIdentityRelative \{.*?\r?\n\}\r?\n').Value
    $script:Work = Join-Path ([IO.Path]::GetTempPath()) ('sc001-identity-' + [guid]::NewGuid().ToString('N').Substring(0, 10))
    $null = New-Item -ItemType Directory -Path (Join-Path $script:Work 'fixture\.squad\identity') -Force

    function Write-Identity {
        param([string]$FeaturePath)
        $path = Join-Path $script:Work 'fixture\.squad\identity\now.md'
        [IO.File]::WriteAllText($path, ("---`nschema: v1`nsession_state_active: true`nsession_state_boundary: plan`nsession_state_feature: 206-bug-bash`nsession_state_feature_path: {0}`nsession_state_iteration: 002`n---`n`n# What We're Focused On`n" -f $FeaturePath), [Text.UTF8Encoding]::new($false))
        return $path
    }
}

AfterAll {
    if ((Split-Path -Leaf $script:Work) -like 'sc001-identity-*') { Remove-Item -LiteralPath $script:Work -Recurse -Force -ErrorAction SilentlyContinue }
}

Describe 'SC-001''s fixture carries the identity path relative (round 1, F2)' {
    It 'the script defines the conversion' {
        $script:Function | Should -Not -BeNullOrEmpty
    }

    It 'rewrites an absolute path inside the source repository as the relative one' {
        . ([scriptblock]::Create($script:Function))
        $sourceRoot = Join-Path $script:Work 'source-repo'
        $identity = Write-Identity -FeaturePath ('"{0}"' -f (Join-Path $sourceRoot 'specs\206-bug-bash'))
        Set-Sc001FixtureIdentityRelative -IdentityPath $identity -SourceRoot $sourceRoot
        $text = Get-Content -LiteralPath $identity -Raw
        $text | Should -Match '(?m)^session_state_feature_path: specs/206-bug-bash\s*$'
        $text | Should -Not -Match ([regex]::Escape($sourceRoot))
        $text | Should -Match '(?m)^session_state_feature: 206-bug-bash\s*$'
    }

    It 'writes (none) for a path outside the source repository' {
        . ([scriptblock]::Create($script:Function))
        $sourceRoot = Join-Path $script:Work 'source-repo'
        $identity = Write-Identity -FeaturePath ('"{0}"' -f (Join-Path ($sourceRoot + '-elsewhere') 'specs\206-bug-bash'))
        Set-Sc001FixtureIdentityRelative -IdentityPath $identity -SourceRoot $sourceRoot
        Get-Content -LiteralPath $identity -Raw | Should -Match '(?m)^session_state_feature_path: \(none\)\s*$'
    }

    It 'leaves a path that is already relative as it is' {
        . ([scriptblock]::Create($script:Function))
        $identity = Write-Identity -FeaturePath 'specs/206-bug-bash'
        Set-Sc001FixtureIdentityRelative -IdentityPath $identity -SourceRoot (Join-Path $script:Work 'source-repo')
        Get-Content -LiteralPath $identity -Raw | Should -Match '(?m)^session_state_feature_path: specs/206-bug-bash\s*$'
    }

    It 'the script applies it to the fixture''s copied identity file before the fixture is committed' {
        # Feature 203, iteration 002 (the maintainer's ruling at 01:50 local on 2026-11-22, relayed): every fixture is
        # built by New-Sc001Fixture, so the order is read in that function's body, not anywhere in the file (the
        # reviewer session's ruling (a), condition 3).
        $source = Get-Content -LiteralPath (Join-Path $script:RepoRoot 'tests\integration\project-path-resolution-regression.ps1') -Raw
        $body = [regex]::Match($source, '(?s)function New-Sc001Fixture \{.*?\r?\n\}\r?\n').Value
        $body | Should -Not -BeNullOrEmpty
        $call = [regex]::Match($body, '(?m)^\s*Set-Sc001FixtureIdentityRelative\s+-IdentityPath\s+\$identityPath\s+-SourceRoot\s+\$repoRoot\s*$')
        $commit = [regex]::Match($body, '(?m)^\s*\$null = & git -C \$Root -c user\.name=')
        $call.Success | Should -BeTrue
        $commit.Success | Should -BeTrue
        $call.Index | Should -BeLessThan $commit.Index
    }
}
