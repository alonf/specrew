#requires -Version 7.0
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Feature 203 T002 follow-up (B5F-033; DRIFT-047). The `.specify` mirror's install record is refreshed with the
# installer's writer only after every deployed file is confirmed byte-identical to its source in `extensions/`.
# A hand edit in `.specify` with its source unchanged is refused and the record left as it was, so W43 still catches
# it. The validator's own refusal of such an edit is proven end to end in validate-governance-changed-only.

BeforeAll {
    $script:RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
    $script:Refresh = Join-Path $script:RepoRoot 'tools\maintenance\refresh-specify-mirror-record.ps1'
    . (Join-Path $script:RepoRoot 'extensions\specrew-speckit\scripts\shared-governance.ps1')

    function script:New-MirrorProject {
        # A source tree and its exact mirror, with a record written before the last change to both: a stale record,
        # the state every 203 commit since 040fb169 left behind.
        $root = Join-Path ([IO.Path]::GetTempPath()) ('mirror-record-' + [guid]::NewGuid().ToString('N'))
        foreach ($side in @('extensions/specrew-speckit', '.specify/extensions/specrew-speckit')) {
            $dir = Join-Path $root $side
            New-Item -ItemType Directory -Path (Join-Path $dir 'scripts') -Force | Out-Null
            New-Item -ItemType Directory -Path (Join-Path $dir 'templates') -Force | Out-Null
            Set-Content -LiteralPath (Join-Path $dir 'scripts/validate-governance.ps1') -Value '# shipped validator' -Encoding UTF8
            Set-Content -LiteralPath (Join-Path $dir 'scripts/shared-governance.ps1') -Value '# shipped helpers' -Encoding UTF8
            Set-Content -LiteralPath (Join-Path $dir 'templates/plan.md') -Value '# plan template' -Encoding UTF8
        }
        $null = Write-SpecrewDeployedExtensionMarker -ProjectRoot $root -SpecrewVersion '0.40.0-beta4'
        foreach ($side in @('extensions/specrew-speckit', '.specify/extensions/specrew-speckit')) {
            Add-Content -LiteralPath (Join-Path $root "$side/scripts/shared-governance.ps1") -Value '# a reviewed change, synced' -Encoding UTF8
        }
        return $root
    }
    function script:Invoke-Refresh {
        param([Parameter(Mandatory)][string]$Root, [switch]$CheckOnly)
        $arguments = @('-NoProfile', '-NonInteractive', '-File', $script:Refresh, '-ProjectRoot', $Root)
        if ($CheckOnly) { $arguments += '-CheckOnly' }
        $out = @(& pwsh @arguments 2>&1 | ForEach-Object { [string]$_ })
        return [pscustomobject]@{ Exit = $LASTEXITCODE; Text = ($out -join "`n") }
    }
    function script:Get-MarkerBytes {
        param([Parameter(Mandatory)][string]$Root)
        return [IO.File]::ReadAllBytes((Get-SpecrewDeployedExtensionMarkerPath -ProjectRoot $Root))
    }
}

Describe 'the mirror record is refreshed only from an exact copy of extensions/' {
    It 'writes the record with the installer''s writer when every deployed file matches its source, keeping the version' {
        $root = New-MirrorProject
        try {
            @((Test-SpecrewDeployedExtensionIntegrity -ProjectRoot $root).drifted) | Should -Be @('scripts/shared-governance.ps1')
            $r = Invoke-Refresh -Root $root
            $r.Exit | Should -Be 0 -Because $r.Text
            $state = Test-SpecrewDeployedExtensionIntegrity -ProjectRoot $root
            $state.checked | Should -BeTrue
            @($state.drifted).Count | Should -Be 0
            @($state.missing).Count | Should -Be 0
            $marker = Get-Content -LiteralPath (Get-SpecrewDeployedExtensionMarkerPath -ProjectRoot $root) -Raw | ConvertFrom-Json
            $marker.specrew_version | Should -Be '0.40.0-beta4'
            $marker.source | Should -Be 'specrew-init-or-update'
            @($marker.managed_files).Count | Should -Be 3
            (Invoke-Refresh -Root $root -CheckOnly).Exit | Should -Be 0
        }
        finally { Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue }
    }

    It 'ACCEPTANCE: refuses a hand edit in .specify whose source is unchanged, leaves the record, and W43 still names the file' {
        $root = New-MirrorProject
        try {
            $null = Invoke-Refresh -Root $root
            $before = Get-MarkerBytes -Root $root
            Add-Content -LiteralPath (Join-Path $root '.specify/extensions/specrew-speckit/scripts/validate-governance.ps1') -Value '# hand-patched to clear a blocker' -Encoding UTF8
            $r = Invoke-Refresh -Root $root
            $r.Exit | Should -Be 1
            $r.Text | Should -Match 'differs from its source in extensions/: scripts/validate-governance\.ps1'
            $r.Text | Should -Match 'install record was left as it was'
            [System.Linq.Enumerable]::SequenceEqual([byte[]](Get-MarkerBytes -Root $root), [byte[]]$before) | Should -BeTrue
            @((Test-SpecrewDeployedExtensionIntegrity -ProjectRoot $root).drifted) | Should -Be @('scripts/validate-governance.ps1')
            (Invoke-Refresh -Root $root -CheckOnly).Exit | Should -Be 1
        }
        finally { Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue }
    }

    It 'refuses a line-ending-only edit, which the record''s own hash would not see' {
        $root = New-MirrorProject
        try {
            $null = Invoke-Refresh -Root $root
            $before = Get-MarkerBytes -Root $root
            $path = Join-Path $root '.specify/extensions/specrew-speckit/templates/plan.md'
            $text = [IO.File]::ReadAllText($path)
            $flipped = if ($text.Contains("`r`n")) { $text.Replace("`r`n", "`n") } else { $text.Replace("`n", "`r`n") }
            [IO.File]::WriteAllText($path, $flipped, [Text.UTF8Encoding]::new($false))
            $r = Invoke-Refresh -Root $root
            $r.Exit | Should -Be 1
            $r.Text | Should -Match 'differs from its source in extensions/: templates/plan\.md'
            [System.Linq.Enumerable]::SequenceEqual([byte[]](Get-MarkerBytes -Root $root), [byte[]]$before) | Should -BeTrue
        }
        finally { Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue }
    }

    It 'refuses a file only in .specify, and a source file not synced, without writing the record' {
        $root = New-MirrorProject
        try {
            $before = Get-MarkerBytes -Root $root
            Set-Content -LiteralPath (Join-Path $root '.specify/extensions/specrew-speckit/scripts/local-patch.ps1') -Value '# added by hand' -Encoding UTF8
            Set-Content -LiteralPath (Join-Path $root 'extensions/specrew-speckit/scripts/new-engine-file.ps1') -Value '# new, not synced' -Encoding UTF8
            $r = Invoke-Refresh -Root $root
            $r.Exit | Should -Be 1
            $r.Text | Should -Match 'only in \.specify, with no source in extensions/: scripts/local-patch\.ps1'
            $r.Text | Should -Match 'in extensions/ but not synced to \.specify: scripts/new-engine-file\.ps1'
            [System.Linq.Enumerable]::SequenceEqual([byte[]](Get-MarkerBytes -Root $root), [byte[]]$before) | Should -BeTrue
        }
        finally { Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue }
    }

    It '-CheckOnly refuses a stale record over an exact mirror, naming what the record gets wrong' {
        $root = New-MirrorProject
        try {
            Set-Content -LiteralPath (Join-Path $root 'extensions/specrew-speckit/scripts/new-engine-file.ps1') -Value '# new' -Encoding UTF8
            Copy-Item -LiteralPath (Join-Path $root 'extensions/specrew-speckit/scripts/new-engine-file.ps1') -Destination (Join-Path $root '.specify/extensions/specrew-speckit/scripts/new-engine-file.ps1')
            $r = Invoke-Refresh -Root $root -CheckOnly
            $r.Exit | Should -Be 1
            $r.Text | Should -Match 'recorded with another hash: scripts/shared-governance\.ps1'
            $r.Text | Should -Match 'deployed but not recorded: scripts/new-engine-file\.ps1'
        }
        finally { Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue }
    }
}

Describe 'this repository''s committed mirror' {
    It 'is an exact copy of extensions/ and its install record matches it (run the refresh in every commit that syncs the mirror)' {
        $r = Invoke-Refresh -Root $script:RepoRoot -CheckOnly
        $r.Exit | Should -Be 0 -Because $r.Text
    }
}
