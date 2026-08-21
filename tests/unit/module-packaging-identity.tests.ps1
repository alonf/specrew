#requires -Version 7.0
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# 2026-08-21: the local install path, and the identity a package carries.
#
# Two mechanisms everyone assumed existed and did not. There was no supported way to install your own
# build: invoke-module-release.ps1 deletes its stage in a `finally` - correct for a release tool - so a
# dry run proved packaging worked and left nothing installable, and every install this week was
# hand-assembled by extracting that script's functions via an AST parse. And the build stamp recorded
# only a commit id supplied at package time, so an install could claim 248dd0d2 while carrying entirely
# different code. It did, and was caught only because someone diffed 82 files by hand.
#
# Both pinned BEHAVIOURALLY. A string match over the source would pass on a file that merely mentions
# the mechanism - which is how the evidence-marker producer shipped inert one day earlier.

BeforeAll {
    $script:RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
    . (Join-Path $script:RepoRoot 'scripts/internal/module-packaging.ps1')
    $script:Installer = Join-Path $script:RepoRoot 'scripts/internal/install-local-build.ps1'

    function script:New-StageFixture {
        param([hashtable]$Files = @{ 'a.ps1' = 'one'; 'sub/b.ps1' = 'two' })
        $root = Join-Path ([IO.Path]::GetTempPath()) ('pkg-' + [guid]::NewGuid().ToString('N'))
        foreach ($relative in $Files.Keys) {
            $path = Join-Path $root $relative
            New-Item -ItemType Directory -Path (Split-Path -Parent $path) -Force | Out-Null
            Set-Content -LiteralPath $path -Value $Files[$relative] -Encoding UTF8 -NoNewline
        }
        return $root
    }
}

Describe 'the build stamp describes the package, not just the intent' {
    It 'derives a content hash from the packaged files' {
        $stage = New-StageFixture
        try {
            $hash = Get-SpecrewPackageContentSha256 -StageRoot $stage
            $hash | Should -Match '^[0-9a-f]{64}$'
        }
        finally { Remove-Item -LiteralPath $stage -Recurse -Force -ErrorAction SilentlyContinue }
    }

    It 'changes when any packaged file changes, which a commit id cannot' {
        # The whole point. The old stamp recorded only what the packager SAID; two different packages
        # could carry the same identity, and one did.
        $a = New-StageFixture
        $b = New-StageFixture -Files @{ 'a.ps1' = 'one-CHANGED'; 'sub/b.ps1' = 'two' }
        try {
            (Get-SpecrewPackageContentSha256 -StageRoot $a) |
                Should -Not -Be (Get-SpecrewPackageContentSha256 -StageRoot $b)
        }
        finally {
            Remove-Item -LiteralPath $a -Recurse -Force -ErrorAction SilentlyContinue
            Remove-Item -LiteralPath $b -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    It 'is stable for identical content, so it identifies rather than merely differs' {
        $a = New-StageFixture
        $b = New-StageFixture
        try {
            (Get-SpecrewPackageContentSha256 -StageRoot $a) |
                Should -Be (Get-SpecrewPackageContentSha256 -StageRoot $b)
        }
        finally {
            Remove-Item -LiteralPath $a -Recurse -Force -ErrorAction SilentlyContinue
            Remove-Item -LiteralPath $b -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    It 'notices a file that is only renamed, not edited' {
        # Path is part of the identity: a package that moved a file is a different package.
        $a = New-StageFixture
        $b = New-StageFixture -Files @{ 'a.ps1' = 'one'; 'sub/RENAMED.ps1' = 'two' }
        try {
            (Get-SpecrewPackageContentSha256 -StageRoot $a) |
                Should -Not -Be (Get-SpecrewPackageContentSha256 -StageRoot $b)
        }
        finally {
            Remove-Item -LiteralPath $a -Recurse -Force -ErrorAction SilentlyContinue
            Remove-Item -LiteralPath $b -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    It 'excludes the stamp itself, so writing it cannot invalidate it' {
        $stage = New-StageFixture
        try {
            $before = Get-SpecrewPackageContentSha256 -StageRoot $stage
            $null = Write-ReleaseBuildStamp -StageRoot $stage -Commit 'deadbeef'
            (Get-SpecrewPackageContentSha256 -StageRoot $stage) | Should -Be $before
            $stamp = Get-Content -LiteralPath (Join-Path $stage 'build-stamp.json') -Raw -Encoding UTF8 | ConvertFrom-Json
            $stamp.commit | Should -Be 'deadbeef'
            $stamp.content_sha256 | Should -Be $before
        }
        finally { Remove-Item -LiteralPath $stage -Recurse -Force -ErrorAction SilentlyContinue }
    }
}

Describe 'the local install path exists and is exercised' {
    It 'packages and reports an identity without installing anything' {
        # BEHAVIOURAL: runs the installer and reads what it produced. The prior week had this capability
        # only as a hand-run sequence, which is the same as not having it.
        $result = & pwsh -NoProfile -ExecutionPolicy Bypass -File $script:Installer -WhatIfOnly -AllowDirty 2>&1
        $text = ($result -join "`n")
        $text | Should -Match 'WhatIfOnly: nothing was installed'
        $text | Should -Match 'commit [0-9a-f]{8}\s+content [0-9a-f]{64}'
    }

    It 'refuses a dirty tree unless the caller says otherwise' {
        # A build whose files are in no commit, carrying a stamp that names one, is the exact defect
        # this path was added to stop.
        $probe = Join-Path ([IO.Path]::GetTempPath()) ('dirty-' + [guid]::NewGuid().ToString('N') + '.ps1')
        $packaged = Join-Path $script:RepoRoot 'scripts/internal/module-packaging.ps1'
        $original = Get-Content -LiteralPath $packaged -Raw -Encoding UTF8
        try {
            Add-Content -LiteralPath $packaged -Value '# dirty-probe' -Encoding UTF8
            $result = & pwsh -NoProfile -ExecutionPolicy Bypass -File $script:Installer -WhatIfOnly 2>&1
            (($result -join "`n")) | Should -Match 'refusing to package a dirty tree'
        }
        finally {
            Set-Content -LiteralPath $packaged -Value $original -Encoding UTF8 -NoNewline
            Remove-Item -LiteralPath $probe -Force -ErrorAction SilentlyContinue
        }
    }

    It 'shares its staging code with the release path rather than reimplementing it' {
        # Two copies is how a release build and a dev build start differing. The release script must be
        # a CONSUMER of the shared file, not a second implementation.
        $release = Get-Content -LiteralPath (Join-Path $script:RepoRoot 'scripts/internal/invoke-module-release.ps1') -Raw -Encoding UTF8
        $release | Should -Match "module-packaging\.ps1"
        $release | Should -Not -Match 'function New-ReleaseStageRoot'
        $installer = Get-Content -LiteralPath $script:Installer -Raw -Encoding UTF8
        $installer | Should -Not -Match 'function New-ReleaseStageRoot'
    }
}

Describe 'a shipped file may not depend on one that is not shipped' {
    It 'packages every file that a packaged script dot-sources from its own directory' {
        # Caught for real on 2026-08-21: extracting shared code into module-packaging.ps1 left the
        # PACKAGED invoke-module-release.ps1 dot-sourcing a file that was not in FileList, so the module
        # would have shipped a release script that cannot load. The FileList integrity check runs the
        # other direction - every listed file exists - and could never see this.
        $repoRoot = $script:RepoRoot
        $fileList = @((Import-PowerShellDataFile -LiteralPath (Join-Path $repoRoot 'Specrew.psd1')).FileList)
        # NO REGEX HERE ON PURPOSE. Every generated regex in this slice has had its escapes mangled in
        # transit at least once; plain string work has nothing to mangle and is easier to read anyway.
        $listed = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
        foreach ($entry in $fileList) { [void]$listed.Add(([string]$entry).Replace([char]92, [char]47)) }

        $missing = [System.Collections.Generic.List[string]]::new()
        foreach ($entry in $fileList) {
            if ($entry -notlike '*.ps1') { continue }
            $full = Join-Path $repoRoot $entry
            if (-not (Test-Path -LiteralPath $full -PathType Leaf)) { continue }
            $normalizedEntry = ([string]$entry).Replace([char]92, [char]47)
            $dir = if ($normalizedEntry.Contains('/')) { $normalizedEntry.Substring(0, $normalizedEntry.LastIndexOf('/')) } else { '' }
            foreach ($line in @(Get-Content -LiteralPath $full -Encoding UTF8)) {
                $trimmed = $line.TrimStart()
                if ($trimmed.StartsWith('#')) { continue }
                # Only dot-sources based on $PSScriptRoot ITSELF, which is what this guard's name claims.
                # Forms like `(Split-Path -Parent $PSScriptRoot)` resolve somewhere else entirely - two
                # co-review runtime files do exactly that - and treating their argument as a sibling
                # produced false offenders. Out of scope, stated rather than silently matched.
                if (-not $trimmed.StartsWith('. (Join-Path $PSScriptRoot ')) { continue }
                $first = $trimmed.IndexOf([char]39)
                $last = $trimmed.LastIndexOf([char]39)
                if ($first -lt 0 -or $last -le $first) { continue }
                # A dot-source may name a SUBDIRECTORY - 'internal\session-config.ps1' - so the separator
                # inside the quoted name needs normalizing too, or every such dependency reads as missing.
                $name = ($trimmed.Substring($first + 1, $last - $first - 1)).Replace([char]92, [char]47)
                if ($name -notlike '*.ps1') { continue }
                $dep = if ([string]::IsNullOrWhiteSpace($dir)) { $name } else { $dir + '/' + $name }
                if (-not $listed.Contains($dep)) { [void]$missing.Add("$entry -> $dep") }
            }
        }
        @($missing).Count | Should -Be 0 -Because "a packaged script that dot-sources an unpackaged file cannot load once installed (offenders: $($missing -join ', '))"
    }
}
