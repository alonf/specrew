# Feature 203 T025 (DRIFT-073): the hook run's one git snapshot is read on two sides - the extension side
# (conformance-turn-delta.ps1, which the conformance provider loads) and the bootstrap side (ProjectMetadataAccessor.ps1,
# which the handover's stores load) - because the dispatcher that writes it loads no shared code. One reader, two
# copies, kept identical here. And a snapshot is only ever an answer about the project it was taken in: about another
# root, of another schema, or unreadable, it is not used and the caller asks git itself.

BeforeAll {
    $script:RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
    $script:ExtensionCopy = Join-Path $script:RepoRoot 'extensions/specrew-speckit/scripts/conformance-turn-delta.ps1'
    $script:BootstrapCopy = Join-Path $script:RepoRoot 'scripts/internal/bootstrap/ProjectMetadataAccessor.ps1'
    . $script:ExtensionCopy
    $script:Work = Join-Path ([IO.Path]::GetTempPath()) ('hook-git-reader-' + [guid]::NewGuid().ToString('N').Substring(0, 10))
    $null = New-Item -ItemType Directory -Path $script:Work -Force

    function script:Get-ReaderText([string]$Path) {
        $text = [IO.File]::ReadAllText($Path) -replace "`r`n", "`n"
        return [regex]::Match($text, '(?s)function Get-SpecrewHookGitSnapshot \{.*?\n\}\n').Value
    }

    function script:New-SnapshotProject([string]$Name) {
        $root = Join-Path $script:Work $Name
        $null = New-Item -ItemType Directory -Path $root -Force
        $null = & git -C $root init -q 2>&1
        Set-Content -LiteralPath (Join-Path $root 'live.txt') -Value 'live' -Encoding utf8NoBOM
        return $root
    }

    function script:Set-Snapshot([string]$Root, [string]$Schema = '1', [string[]]$StatusLines = @('?? from-snapshot.txt')) {
        $script:SpecrewHookGitSnapshotCache = $null
        $path = Join-Path $script:Work ('git-' + [guid]::NewGuid().ToString('N').Substring(0, 8) + '.json')
        [ordered]@{
            schema = $Schema; project_root = [IO.Path]::GetFullPath($Root).TrimEnd([char]'\', [char]'/'); taken_at = '2026-11-18T00:00:00Z'
            rev_parse_ok = $true; inside = 'true'; prefix = ''; branch = 'main'
            head_ok = $false; head = ''; head_short = ''; subject = ''; status_ok = $true; status_lines = @($StatusLines)
        } | ConvertTo-Json -Depth 4 -Compress | Set-Content -LiteralPath $path -Encoding utf8NoBOM
        $env:SPECREW_HOOK_GIT_SNAPSHOT = $path
    }
}

AfterAll {
    Remove-Item Env:\SPECREW_HOOK_GIT_SNAPSHOT -ErrorAction SilentlyContinue
    if ((Split-Path -Leaf $script:Work) -like 'hook-git-reader-*') { Remove-Item -LiteralPath $script:Work -Recurse -Force -ErrorAction SilentlyContinue }
}

Describe 'T025: one reader of the hook run''s git snapshot' {
    It 'the extension-side and bootstrap-side copies are identical' {
        $extension = script:Get-ReaderText $script:ExtensionCopy
        $bootstrap = script:Get-ReaderText $script:BootstrapCopy
        $extension | Should -Not -BeNullOrEmpty
        $bootstrap | Should -BeExactly $extension
    }

    It 'the transcript-tail reader''s two copies are identical too' {
        $read = { param([string]$Path) [regex]::Match(([IO.File]::ReadAllText($Path) -replace "`r`n", "`n"), '(?s)function Get-SpecrewHookTranscriptTailLines \{.*?\n\}\n').Value }
        $extension = & $read $script:ExtensionCopy
        $bootstrap = & $read (Join-Path $script:RepoRoot 'scripts/internal/bootstrap/ConversationCaptureAccessor.ps1')
        $extension | Should -Not -BeNullOrEmpty
        $bootstrap | Should -BeExactly $extension
    }
}

Describe 'T025: a snapshot answers only for the project it was taken in' {
    AfterEach { Remove-Item Env:\SPECREW_HOOK_GIT_SNAPSHOT -ErrorAction SilentlyContinue; $script:SpecrewHookGitSnapshotCache = $null }

    It 'with no snapshot, the turn snapshot comes from git itself' {
        $root = script:New-SnapshotProject -Name 'none'
        $turn = Get-SpecrewTurnSnapshot -ProjectRoot $root
        $turn.available | Should -BeTrue
        @($turn.entries | ForEach-Object { $_.path }) | Should -Contain 'live.txt'
    }

    It 'with a snapshot of this project, the turn snapshot uses its listing' {
        $root = script:New-SnapshotProject -Name 'same'
        script:Set-Snapshot -Root $root
        $turn = Get-SpecrewTurnSnapshot -ProjectRoot $root
        @($turn.entries | ForEach-Object { $_.path }) | Should -Contain 'from-snapshot.txt'
        @($turn.entries | ForEach-Object { $_.path }) | Should -Not -Contain 'live.txt'
    }

    It 'a snapshot of another project is never used' {
        $root = script:New-SnapshotProject -Name 'mine'
        $other = script:New-SnapshotProject -Name 'other'
        script:Set-Snapshot -Root $other
        Get-SpecrewHookGitSnapshot -ProjectRoot $root | Should -BeNullOrEmpty
        @((Get-SpecrewTurnSnapshot -ProjectRoot $root).entries | ForEach-Object { $_.path }) | Should -Contain 'live.txt'
    }

    It 'a snapshot of an unknown schema, or an unreadable one, is never used' {
        $root = script:New-SnapshotProject -Name 'schema'
        script:Set-Snapshot -Root $root -Schema '2'
        Get-SpecrewHookGitSnapshot -ProjectRoot $root | Should -BeNullOrEmpty
        $script:SpecrewHookGitSnapshotCache = $null
        Set-Content -LiteralPath $env:SPECREW_HOOK_GIT_SNAPSHOT -Value '{ not json' -Encoding utf8NoBOM
        Get-SpecrewHookGitSnapshot -ProjectRoot $root | Should -BeNullOrEmpty
    }
}
