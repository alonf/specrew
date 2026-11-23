# Feature 203, iteration 002 (DRIFT-048): the review-link reader (T011, FR-046) reads a file URL as a local path.
#
# Specrew CI's Deterministic gate on Linux (run 44443396665, after the merge of main brought 205's named step for
# agent-led-workshop-replay) refused a complete boundary packet: "review link to a missing file: file:////tmp/...".
# On Linux and macOS a link written as 'file:///' plus an absolute path has four slashes. .NET reads that as a UNC
# path with host "tmp" (LocalPath "\\tmp\x\spec.md"), so a file that exists was reported missing. The engine itself
# writes that form there (refocus, design-analysis-gate, lens-applicability, validate-governance).
#
# The fix is one normalisation function, ConvertTo-SpecrewFileUrlLocalPath, tested directly with -Platform so that
# every case runs on every OS:
#   - Windows: today's reading, [System.Uri]::new($url).LocalPath, unchanged (file:///C:/..., UNC forms).
#   - Not Windows: "/" plus the URL's path with its leading slashes collapsed, then percent-decoded. An empty
#     authority and "localhost" (RFC 8089) are local; any other host has no local path ($null), as does an empty path.
#
# Everything runs in temp folders this suite creates. Nothing is deployed and no home is read or written.

BeforeAll {
    $script:RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
    . (Join-Path $script:RepoRoot 'extensions\specrew-speckit\scripts\turn-end-store.ps1')
    $script:TempRoots = New-Object System.Collections.Generic.List[string]
}

AfterAll {
    foreach ($root in $script:TempRoots) {
        if (Test-Path -LiteralPath $root) { Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue }
    }
}

Describe 'ConvertTo-SpecrewFileUrlLocalPath, not Windows' {
    It 'reads <Url> as <Expected>' -ForEach @(
        @{ Url = 'file:///tmp/x/spec.md'; Expected = '/tmp/x/spec.md' }
        @{ Url = 'file:////tmp/x/spec.md'; Expected = '/tmp/x/spec.md' }
        @{ Url = 'file://///tmp/x/spec.md'; Expected = '/tmp/x/spec.md' }
        @{ Url = 'file:///tmp/my%20dir/spec.md'; Expected = '/tmp/my dir/spec.md' }
        @{ Url = 'file:////tmp/my%20dir/spec.md'; Expected = '/tmp/my dir/spec.md' }
        @{ Url = 'file:///tmp/100%/spec.md'; Expected = '/tmp/100%/spec.md' }
        @{ Url = 'file:///tmp/a%25b/spec.md'; Expected = '/tmp/a%b/spec.md' }
        @{ Url = 'file://localhost/tmp/x/spec.md'; Expected = '/tmp/x/spec.md' }
        @{ Url = 'file://LOCALHOST/tmp/x/spec.md'; Expected = '/tmp/x/spec.md' }
        # Round 3 of 203 iteration 002's review (finding-266f3aac0b802944): as System.Uri.LocalPath does on Windows (pinned
        # there on 2026-11-23), the fragment and the query are cut before percent-decoding, so an encoded %23 or %3F in a
        # name survives as a literal '#' or '?'.
        @{ Url = 'file:///tmp/review.md#findings'; Expected = '/tmp/review.md' }
        @{ Url = 'file:////tmp/review.md#findings'; Expected = '/tmp/review.md' }
        @{ Url = 'file:///tmp/review.md?x=1'; Expected = '/tmp/review.md' }
        @{ Url = 'file:///tmp/review.md?x=1#f'; Expected = '/tmp/review.md' }
        @{ Url = 'file:///tmp/a%23b.md'; Expected = '/tmp/a#b.md' }
        @{ Url = 'file:///tmp/a%3Fb.md#f'; Expected = '/tmp/a?b.md' }
        @{ Url = 'file:///tmp/my%20dir/spec.md#top'; Expected = '/tmp/my dir/spec.md' }
    ) {
        ConvertTo-SpecrewFileUrlLocalPath -Url $Url -Platform Posix | Should -BeExactly $Expected
    }

    It 'has no local path for <Url>' -ForEach @(
        @{ Url = 'file:///' }
        @{ Url = 'file:////' }
        @{ Url = 'file://localhost/' }
        @{ Url = 'file://server/share/x/spec.md' }
        @{ Url = 'file://localhostile/x/spec.md' }
        @{ Url = 'https://example.invalid/x' }
    ) {
        ConvertTo-SpecrewFileUrlLocalPath -Url $Url -Platform Posix | Should -BeNullOrEmpty
    }
}

Describe 'ConvertTo-SpecrewFileUrlLocalPath, Windows' {
    It 'reads <Url> exactly as System.Uri does' -ForEach @(
        @{ Url = 'file:///C:/x/spec.md' }
        @{ Url = 'file:///C:/my%20dir/spec.md' }
        @{ Url = 'file:///c:/Dev/a%25b/spec.md' }
        @{ Url = 'file://server/share/x/spec.md' }
        @{ Url = 'file:////server/share/x/spec.md' }
    ) {
        ConvertTo-SpecrewFileUrlLocalPath -Url $Url -Platform Windows | Should -BeExactly ([System.Uri]::new($Url).LocalPath)
    }

    It 'gives a drive path on a Windows host' -Skip:([System.IO.Path]::DirectorySeparatorChar -ne '\') {
        ConvertTo-SpecrewFileUrlLocalPath -Url 'file:///C:/x/spec.md' -Platform Windows | Should -BeExactly 'C:\x\spec.md'
    }

    It 'defaults to the platform it runs on' {
        $expected = if ([System.IO.Path]::DirectorySeparatorChar -eq '\') { 'Windows' } else { 'Posix' }
        $url = 'file:///C:/x/spec.md'
        ConvertTo-SpecrewFileUrlLocalPath -Url $url | Should -BeExactly (ConvertTo-SpecrewFileUrlLocalPath -Url $url -Platform $expected)
    }
}

Describe 'The packet reader resolves a review link to an existing file' {
    BeforeAll {
        $script:Root = Join-Path ([IO.Path]::GetTempPath()) ('review-link-' + [guid]::NewGuid().ToString('N').Substring(0, 10))
        $script:TempRoots.Add($script:Root) | Out-Null
        $null = New-Item -ItemType Directory -Path (Join-Path $script:Root 'my dir')
        $script:Spec = Join-Path $script:Root 'my dir/spec.md'
        Set-Content -LiteralPath $script:Spec -Value '# spec' -Encoding utf8
        # The engine's own form: 'file:///' plus the path with forward slashes (four slashes on Linux and macOS).
        $script:EngineUrl = 'file:///' + (($script:Spec -replace '\\', '/') -replace ' ', '%20')
    }

    It 'reads the engine-written link to the file itself' {
        $links = @(Get-SpecrewReviewTargetLinks -Message ("Read {0} for the scope." -f $script:EngineUrl))
        $links.Count | Should -Be 1
        $links[0].path | Should -BeExactly ([System.IO.Path]::GetFullPath($script:Spec))
    }

    It 'reads an engine-written link with a fragment to the file itself (round 3 finding 3)' {
        $links = @(Get-SpecrewReviewTargetLinks -Message ("Read {0}#findings for the scope." -f $script:EngineUrl))
        $links.Count | Should -Be 1
        $links[0].path | Should -BeExactly ([System.IO.Path]::GetFullPath($script:Spec))
    }

    It 'raises no missing-file problem for that link in a packet' {
        $packet = @(
            '## What I Just Did', 'Wrote the spec.'
            '## Why I Stopped', 'Specify needs your verdict.'
            '## What Needs Your Review', ("Read {0} for the scope." -f $script:EngineUrl)
            '## What Happens Next', 'Clarify follows your approval.'
            '## Discussion Prompts', '1. Keep HTTP links out of scope.'
            '## What I Need From You', 'Approve the scope or name a correction.'
        ) -join "`n"
        $result = Test-SpecrewReplyPacket -Reply $packet
        @($result.problems | Where-Object { $_ -like 'review link*' -or $_ -like '*has no file link*' }) | Should -BeNullOrEmpty
    }

    It 'still reports a link to a file that does not exist' {
        $missing = 'file:///' + ((Join-Path $script:Root 'absent.md') -replace '\\', '/')
        $packet = @(
            '## What I Just Did', 'Wrote the spec.'
            '## Why I Stopped', 'Specify needs your verdict.'
            '## What Needs Your Review', ("Read {0} for the scope." -f $missing)
            '## What Happens Next', 'Clarify follows your approval.'
            '## Discussion Prompts', '1. Keep HTTP links out of scope.'
            '## What I Need From You', 'Approve the scope or name a correction.'
        ) -join "`n"
        $result = Test-SpecrewReplyPacket -Reply $packet
        @($result.problems) | Should -Contain ('review link to a missing file: {0}' -f $missing)
    }
}
