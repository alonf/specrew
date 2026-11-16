# Feature 206, T028 (FR-012, SC-007, bug list item 17, high): tests/integration/distribution-module-publish.ps1 runs
# scripts/internal/invoke-module-release.ps1 in publish-stable mode on the version's own tag and expects it to fail
# because PSGALLERY_API_KEY is unset. The release script reads the key from the environment, so on a machine or runner
# where the key is set, that case is a live publish of the module to the PowerShell Gallery.
#
# Two fixes: the release script refuses a live publish nobody asked for (-ConfirmLivePublish, which only the publish
# workflow passes), and the suite clears the key itself. These cases run the release script in-process on a temp copy
# of the module's files, with Publish-Module replaced by a function that only counts calls: nothing is published and
# no network call is made.

BeforeAll {
    $script:RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
    $script:Workspace = Join-Path ([IO.Path]::GetTempPath()) ('release-refusal-' + [guid]::NewGuid().ToString('N').Substring(0, 10))
    $null = New-Item -ItemType Directory -Path $script:Workspace
    $manifest = Import-PowerShellDataFile -Path (Join-Path $script:RepoRoot 'Specrew.psd1')
    $relativePaths = @($manifest.FileList) + @('Specrew.psd1', '.specrew/config.yml', 'scripts/internal/invoke-module-release.ps1', 'scripts/internal/module-packaging.ps1', 'README.md', 'CHANGELOG.md', 'LICENSE', 'NOTICE.md')
    foreach ($rel in ($relativePaths | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | Sort-Object -Unique)) {
        $src = Join-Path $script:RepoRoot $rel
        if (-not (Test-Path -LiteralPath $src -PathType Leaf)) { continue }
        $dst = Join-Path $script:Workspace $rel
        $null = New-Item -ItemType Directory -Path (Split-Path -Parent $dst) -Force
        Copy-Item -LiteralPath $src -Destination $dst -Force
    }
    $script:ReleaseScript = Join-Path $script:Workspace 'scripts/internal/invoke-module-release.ps1'
    $script:Tag = 'v{0}' -f [string]$manifest.ModuleVersion
    $script:SavedKey = $env:PSGALLERY_API_KEY
    $script:SavedCommit = $env:SPECREW_BUILD_COMMIT
    $env:SPECREW_BUILD_COMMIT = 'abcdef12'

    function Invoke-Release {
        param([string]$Key, [switch]$Confirm)
        $global:SpecrewT028PublishCalls = 0
        function Publish-Module { param([Parameter(ValueFromRemainingArguments = $true)]$Rest) $global:SpecrewT028PublishCalls++ }
        $releaseArgs = @{ RepositoryRoot = $script:Workspace; ReleaseMode = 'publish-stable'; GitRefType = 'tag'; GitRefName = $script:Tag; PSGalleryApiKey = $Key }
        if ($Confirm) { $releaseArgs['ConfirmLivePublish'] = $true }
        $message = $null
        try { $null = & $script:ReleaseScript @releaseArgs 6>&1 2>&1 }
        catch { $message = $_.Exception.Message }
        return [pscustomobject]@{ PublishCalls = $global:SpecrewT028PublishCalls; Message = $message }
    }
}

AfterAll {
    $env:PSGALLERY_API_KEY = $script:SavedKey
    $env:SPECREW_BUILD_COMMIT = $script:SavedCommit
    Remove-Variable -Name SpecrewT028PublishCalls -Scope Global -ErrorAction SilentlyContinue
    if ((Split-Path -Leaf $script:Workspace) -like 'release-refusal-*') { Remove-Item -LiteralPath $script:Workspace -Recurse -Force -ErrorAction SilentlyContinue }
}

Describe 'The release script refuses a live publish nobody asked for (FR-012, SC-007)' {
    It 'does not reach Publish-Module with the key set and no confirmation' {
        $r = Invoke-Release -Key 'fixture-not-a-real-key'
        $r.PublishCalls | Should -Be 0
        $r.Message | Should -Match 'ConfirmLivePublish'
    }

    It 'still fails with no key, naming PSGALLERY_API_KEY, when the publish is confirmed' {
        $r = Invoke-Release -Key '' -Confirm
        $r.PublishCalls | Should -Be 0
        $r.Message | Should -Match 'PSGALLERY_API_KEY'
    }

    It 'publishes once when the publish is confirmed and the key is set (the publish workflow''s call)' {
        $r = Invoke-Release -Key 'fixture-not-a-real-key' -Confirm
        $r.Message | Should -BeNullOrEmpty
        $r.PublishCalls | Should -Be 1
    }

    It 'the publish workflow passes the confirmation on its publish step' {
        $workflow = Get-Content -LiteralPath (Join-Path $script:RepoRoot '.github/workflows/publish-module.yml') -Raw
        $workflow | Should -Match '(?s)invoke-module-release\.ps1.{0,600}-ConfirmLivePublish'
    }
}

Describe 'The publish suite clears the key itself (FR-012)' {
    It 'removes PSGALLERY_API_KEY before its first release call and restores it at the end' {
        $suite = Get-Content -LiteralPath (Join-Path $script:RepoRoot 'tests/integration/distribution-module-publish.ps1') -Raw
        $clear = [regex]::Match($suite, 'Remove-Item\s+-LiteralPath\s+''?Env:PSGALLERY_API_KEY')
        $clear.Success | Should -BeTrue
        $firstCall = $suite.IndexOf('$releaseScript `')
        $clear.Index | Should -BeLessThan $firstCall
        $suite | Should -Match '\$env:PSGALLERY_API_KEY\s*=\s*\$savedPsGalleryApiKey'
    }

    It 'restores SPECREW_BUILD_COMMIT in the same finally, so a caller running it in-process does not inherit it' {
        $suite = Get-Content -LiteralPath (Join-Path $script:RepoRoot 'tests/integration/distribution-module-publish.ps1') -Raw
        $save = [regex]::Match($suite, '\$savedBuildCommit\s*=\s*\$env:SPECREW_BUILD_COMMIT')
        $save.Success | Should -BeTrue
        $save.Index | Should -BeLessThan $suite.IndexOf('$env:SPECREW_BUILD_COMMIT = $expectedBuildId')
        $finally = $suite.Substring($suite.LastIndexOf('finally {'))
        $finally | Should -Match '\$env:SPECREW_BUILD_COMMIT\s*=\s*\$savedBuildCommit'
        $finally | Should -Match 'Env:SPECREW_BUILD_COMMIT'
    }
}

Describe 'The publish suite copies hidden release files on every OS (FR-012; CI on Linux, 2026-11-16)' {
    It 'copies a dot-file the module FileList names, hidden on Linux and here marked hidden as well' {
        # Specrew CI's Linux runner failed the suite at its first copy: extensions/specrew-speckit/hooks/.gitkeep is a
        # dot-file, hidden on Unix, and Get-Item without -Force does not find a hidden item. Marking the file hidden here
        # gives Windows the same state, so this case fails on both systems while the helper omits -Force.
        $suitePath = Join-Path $script:RepoRoot 'tests/integration/distribution-module-publish.ps1'
        $ast = [System.Management.Automation.Language.Parser]::ParseFile($suitePath, [ref]$null, [ref]$null)
        $helper = $ast.Find({ param($n) $n -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $n.Name -eq 'Copy-ReleaseSurface' }, $true)
        $helper | Should -Not -BeNullOrEmpty
        . ([scriptblock]::Create($helper.Extent.Text))
        $src = Join-Path $script:Workspace 'hidden-src'
        $null = New-Item -ItemType Directory -Path $src -Force
        $file = Join-Path $src '.gitkeep'
        [IO.File]::WriteAllText($file, '')
        if ($IsWindows) { (Get-Item -LiteralPath $file -Force).Attributes = 'Hidden' }
        $dst = Join-Path $script:Workspace 'hidden-dst/hooks/.gitkeep'
        $ErrorActionPreference = 'Stop'   # as the suite runs it
        { Copy-ReleaseSurface -SourcePath $file -DestinationPath $dst } | Should -Not -Throw
        Test-Path -LiteralPath $dst | Should -BeTrue
    }
}

Describe 'The publish suite runs per push on Windows, in a job that sees no secret (FR-012; maintainer 2026-11-16 14:38)' {
    BeforeAll {
        $script:CiText = Get-Content -LiteralPath (Join-Path $script:RepoRoot '.github/workflows/specrew-ci.yml') -Raw
        $script:CiCode = (($script:CiText -split "`r?`n") | Where-Object { $_ -notmatch '^\s*#' }) -join "`n"
        $script:Job = [regex]::Match($script:CiCode, '(?ms)^  publish-suite-windows:\n(?<body>.*?)(?=^  [A-Za-z0-9_-]+:\s*$|\z)').Groups['body'].Value
    }

    It 'Specrew CI maps no secret anywhere, so no job of it can see PSGALLERY_API_KEY' {
        $script:CiCode | Should -Not -Match 'secrets\.'
        $script:CiCode | Should -Not -Match 'PSGALLERY_API_KEY\s*:'
    }

    It 'a windows-latest job with its own timeout runs the publish suite, and nothing lets it fail quietly' {
        $script:Job | Should -Not -BeNullOrEmpty
        $script:Job | Should -Match '(?m)^    runs-on:\s*windows-latest\s*$'
        $script:Job | Should -Match '(?m)^    timeout-minutes:\s*\d+\s*$'
        $script:Job | Should -Match '(?m)^\s+run:\s*pwsh -NoProfile -NonInteractive -File \./tests/integration/distribution-module-publish\.ps1\s*$'
        $script:Job | Should -Not -Match 'continue-on-error'
        $script:Job | Should -Not -Match '(?m)^\s+if:'
    }

    It 'the Linux deterministic gate no longer lists the publish suite' {
        $gate = [regex]::Match($script:CiCode, '(?ms)^  deterministic-gate:\n(?<body>.*?)(?=^  [A-Za-z0-9_-]+:\s*$|\z)').Groups['body'].Value
        $gate | Should -Not -BeNullOrEmpty
        $gate | Should -Not -Match 'distribution-module-publish\.ps1'
    }
}
