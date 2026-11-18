# Feature 206, T025 (SC-001, SC-007, bug list item 25): `specrew init` ran its Squad capability probe in the Specrew
# install root, dry run or not: `Get-SquadInitPlan -ProbeRoot $repoRoot` made `.specrew-squad-probe-<guid>` there and
# ran a real `squad init --non-interactive` in it, and a dev checkout's install root is this repository. Its cleanup
# was `Remove-Item -ErrorAction SilentlyContinue`, so a folder it could not remove stayed without a word (SC-001's
# supervised run 4 left one here). The probe now runs in a temp folder of its own, and a failed cleanup is reported.
#
# No real `squad` runs: a fake one, a script in a temp folder this suite creates, records the folder it ran in.

BeforeAll {
    $script:RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
    . (Join-Path $script:RepoRoot 'scripts\init\_utilities.ps1')
    . (Join-Path $script:RepoRoot 'scripts\init\squad-deploy.ps1')
    $script:InitSource = Get-Content -LiteralPath (Join-Path $script:RepoRoot 'scripts\specrew-init.ps1') -Raw

    $script:Work = Join-Path ([IO.Path]::GetTempPath()) ('squad-probe-test-' + [guid]::NewGuid().ToString('N').Substring(0, 10))
    $null = New-Item -ItemType Directory -Path $script:Work -Force
    $script:Record = Join-Path $script:Work 'ran-in.txt'
    $script:FakeSquad = Join-Path $script:Work 'fake-squad.ps1'
    $fake = @'
param([Parameter(ValueFromRemainingArguments = $true)][string[]]$Rest)
[IO.File]::WriteAllText($env:F206_FAKE_SQUAD_RECORD, (Get-Location).Path)
$null = New-Item -ItemType Directory -Path (Join-Path (Get-Location).Path '.squad') -Force
exit 0
'@
    [IO.File]::WriteAllText($script:FakeSquad, $fake, [Text.UTF8Encoding]::new($false))
    $script:PreviousRecordVariable = $env:F206_FAKE_SQUAD_RECORD
    $env:F206_FAKE_SQUAD_RECORD = $script:Record
}

AfterAll {
    $env:F206_FAKE_SQUAD_RECORD = $script:PreviousRecordVariable
    if ((Split-Path -Leaf $script:Work) -like 'squad-probe-test-*') {
        Remove-Item -LiteralPath $script:Work -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Describe 'The Squad probe runs in a temp folder of its own (item 25)' {
    It 'Get-SquadInitPlan probes in a folder under the temp folder and removes it' {
        Remove-Item -LiteralPath $script:Record -Force -ErrorAction SilentlyContinue
        $plan = Get-SquadInitPlan -SquadCommand $script:FakeSquad
        $plan.SupportsNonInteractive | Should -BeTrue
        $ranIn = Get-Content -LiteralPath $script:Record -Raw
        $ranIn | Should -BeLike ((Join-Path ([IO.Path]::GetTempPath()).TrimEnd('\', '/') '*'))
        $ranIn | Should -Not -BeLike ($script:RepoRoot + '*')
        Test-Path -LiteralPath $ranIn | Should -BeFalse
    }

    It 'specrew init does not hand the install root to the probe' {
        $call = [regex]::Match($script:InitSource, '(?m)^.*Get-SquadInitPlan\b.*$').Value
        $call | Should -Not -BeNullOrEmpty
        $call | Should -Not -Match '\$repoRoot'
        $call | Should -Not -Match '-ProbeRoot'
    }
}

Describe 'A probe folder the cleanup cannot remove is reported (item 25)' {
    It 'warns, naming the folder, when the probe folder is still there after its cleanup' {
        $probeParent = Join-Path $script:Work 'probe-parent'
        $null = New-Item -ItemType Directory -Path $probeParent -Force
        Mock Remove-Item { } -ParameterFilter { [string]$LiteralPath -like '*.specrew-squad-probe-*' }
        $warnings = @()
        $null = Test-SquadInitSupportsNonInteractive -ProbeRoot $probeParent -SquadCommand $script:FakeSquad -WarningVariable +warnings -WarningAction SilentlyContinue
        $left = @(Get-ChildItem -LiteralPath $probeParent -Directory -Filter '.specrew-squad-probe-*')
        $left.Count | Should -Be 1
        ($warnings -join "`n") | Should -Match ([regex]::Escape($left[0].FullName))
        ($warnings -join "`n") | Should -Match 'could not remove'
    }

    It 'says nothing when the cleanup removes the folder' {
        $probeParent = Join-Path $script:Work 'probe-clean'
        $null = New-Item -ItemType Directory -Path $probeParent -Force
        $warnings = @()
        $null = Test-SquadInitSupportsNonInteractive -ProbeRoot $probeParent -SquadCommand $script:FakeSquad -WarningVariable +warnings -WarningAction SilentlyContinue
        @(Get-ChildItem -LiteralPath $probeParent -Directory -Force).Count | Should -Be 0
        @($warnings).Count | Should -Be 0
    }
}
