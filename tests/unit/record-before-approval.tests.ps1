# Feature 206, T034 (FR-016, SC-009, bug list item 39, design D2-a): the validator called plan.md's status stale as soon
# as the next record existed (review.md beside `planning`/`executing`, retro.md beside anything but `retro`/`complete`),
# but the phase line moves only at the boundary sync, after the human's verdict, and the sync wants the record pushed
# first. Every review sign-off and every retro cost one red Lint push. A record whose boundary approval is still pending
# is a normal state; once that approval is recorded and the line has not moved, the check fails as today. Where
# .specrew/start-context.json is absent (it is ignored by git, so CI and a fresh clone have none), the record is
# accepted with a warning naming the file.
#
# Each case runs the validator on a temp fixture and looks only for the stale-status message: a fixture this small may
# fail other checks, which are not this suite's subject.

BeforeAll {
    $script:RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
    $script:Validator = Join-Path $script:RepoRoot 'extensions\specrew-speckit\scripts\validate-governance.ps1'
    $script:Work = Join-Path ([IO.Path]::GetTempPath()) ('record-before-approval-' + [guid]::NewGuid().ToString('N').Substring(0, 10))
    $null = New-Item -ItemType Directory -Path $script:Work -Force
    $script:ReviewStale = "plan.md status '{0}' is stale: review.md exists"
    $script:RetroStale = "plan.md status '{0}' is stale: retro.md exists"

    function New-RecordFixture {
        param([string]$Name, [string]$Status, [switch]$Review, [switch]$Retro, [AllowNull()][string]$LastAuthorized, [string]$PendingTo)
        $root = Join-Path $script:Work $Name
        $null = New-Item -ItemType Directory -Path (Join-Path $root '.specrew') -Force
        $null = New-Item -ItemType Directory -Path (Join-Path $root 'scripts\internal') -Force
        $null = New-Item -ItemType Directory -Path (Join-Path $root 'extensions\specrew-speckit\scripts') -Force
        Copy-Item -LiteralPath (Join-Path $script:RepoRoot 'scripts\internal\dashboard-renderer.ps1') -Destination (Join-Path $root 'scripts\internal\dashboard-renderer.ps1')
        Copy-Item -LiteralPath (Join-Path $script:RepoRoot 'extensions\specrew-speckit\scripts\shared-governance.ps1') -Destination (Join-Path $root 'extensions\specrew-speckit\scripts\shared-governance.ps1')
        $null = New-Item -ItemType Directory -Path (Join-Path $root '.squad') -Force
        Copy-Item -LiteralPath (Join-Path $script:RepoRoot '.squad\team.md') -Destination (Join-Path $root '.squad\team.md')
        $dir = Join-Path $root 'specs\908-records\iterations\001'
        $null = New-Item -ItemType Directory -Path $dir -Force
        Set-Content -LiteralPath (Join-Path $root 'specs\908-records\spec.md') -Value '# Feature Specification: 908-records' -Encoding UTF8
        Set-Content -LiteralPath (Join-Path $dir 'plan.md') -Value "# Plan`n`n**Status**: $Status`n" -Encoding UTF8
        Set-Content -LiteralPath (Join-Path $dir 'state.md') -Value "# Iteration State: 001`n`n**Schema**: v2`n**Iteration Status**: $Status`n" -Encoding UTF8
        Set-Content -LiteralPath (Join-Path $dir 'drift-log.md') -Value "# Drift Log`n" -Encoding UTF8
        if ($Review) { Set-Content -LiteralPath (Join-Path $dir 'review.md') -Value "# Review`n`n**Overall Verdict**: accepted`n" -Encoding UTF8 }
        if ($Retro) { Set-Content -LiteralPath (Join-Path $dir 'retro.md') -Value "# Retro`n" -Encoding UTF8 }
        if (-not [string]::IsNullOrWhiteSpace($LastAuthorized)) {
            $pending = if ($PendingTo) { @{ from = $LastAuthorized; to = $PendingTo; crossing_id = 'crossing-fixture' } } else { $null }
            $context = [ordered]@{
                schema_version       = '1.0'
                session_state        = [ordered]@{ active = $true; boundary_type = $LastAuthorized; feature_ref = '908-records'; iteration_number = '001' }
                boundary_enforcement = [ordered]@{
                    enabled = $true; last_authorized_boundary = $LastAuthorized; pending_next_boundary = $PendingTo; pending_crossing = $pending
                    policy_classes = @{}; verdict_history = @(); correction_history = @(); bypass_history = @()
                }
            }
            Set-Content -LiteralPath (Join-Path $root '.specrew\start-context.json') -Value ($context | ConvertTo-Json -Depth 6) -Encoding UTF8
        }
        return [pscustomobject]@{ Root = $root; Iteration = $dir }
    }

    function Invoke-FixtureValidator {
        param($Fixture)
        $output = @(& pwsh -NoProfile -File $script:Validator -ProjectPath $Fixture.Root -IterationPath $Fixture.Iteration 2>&1 | ForEach-Object { [string]$_ }) -join "`n"
        return $output
    }
}

AfterAll {
    if ((Split-Path -Leaf $script:Work) -like 'record-before-approval-*') { Remove-Item -LiteralPath $script:Work -Recurse -Force -ErrorAction SilentlyContinue }
}

Describe 'A review record waiting for its approval is not stale (FR-016, SC-009)' {
    It 'accepts review.md beside executing before the review-signoff crossing is reached' {
        $fixture = New-RecordFixture -Name 'before' -Status 'executing' -Review -LastAuthorized 'before-implement'
        Invoke-FixtureValidator -Fixture $fixture | Should -Not -Match ([regex]::Escape(($script:ReviewStale -f 'executing')))
    }

    It 'accepts review.md beside executing while the review-signoff crossing is pending (at the verdict)' {
        $fixture = New-RecordFixture -Name 'at' -Status 'executing' -Review -LastAuthorized 'before-implement' -PendingTo 'review-signoff'
        Invoke-FixtureValidator -Fixture $fixture | Should -Not -Match ([regex]::Escape(($script:ReviewStale -f 'executing')))
    }

    It 'accepts review.md once the line has moved to reviewing' {
        $fixture = New-RecordFixture -Name 'moved' -Status 'reviewing' -Review -LastAuthorized 'review-signoff'
        Invoke-FixtureValidator -Fixture $fixture | Should -Not -Match "is stale: review\.md exists"
    }

    It 'still fails when the review-signoff verdict is recorded and the line is behind' {
        $fixture = New-RecordFixture -Name 'behind' -Status 'executing' -Review -LastAuthorized 'review-signoff'
        Invoke-FixtureValidator -Fixture $fixture | Should -Match ([regex]::Escape(($script:ReviewStale -f 'executing')))
    }

    It 'accepts the record with a warning naming start-context.json when that file is absent (CI)' {
        $fixture = New-RecordFixture -Name 'no-context' -Status 'executing' -Review
        $output = Invoke-FixtureValidator -Fixture $fixture
        $output | Should -Not -Match ([regex]::Escape(($script:ReviewStale -f 'executing')))
        $output | Should -Match 'WARN .*start-context\.json'
    }
}

Describe 'A retro record waiting for its approval is not stale (FR-016, SC-009)' {
    It 'accepts retro.md beside reviewing before the retro crossing is approved' {
        $fixture = New-RecordFixture -Name 'retro-before' -Status 'reviewing' -Review -Retro -LastAuthorized 'review-signoff' -PendingTo 'retro'
        Invoke-FixtureValidator -Fixture $fixture | Should -Not -Match ([regex]::Escape(($script:RetroStale -f 'reviewing')))
    }

    It 'still fails when the retro verdict is recorded and the line is behind' {
        $fixture = New-RecordFixture -Name 'retro-behind' -Status 'reviewing' -Review -Retro -LastAuthorized 'retro'
        Invoke-FixtureValidator -Fixture $fixture | Should -Match ([regex]::Escape(($script:RetroStale -f 'reviewing')))
    }
}
