# Feature 206, T009 (FR-008; maintainer rulings 2026-11-11 and 2026-11-12, option 1):
#   - The dashboard check declares `since: 2026-05-26` and judges a closed iteration only when its
#     .specrew/closed-iterations.yml entry carries `closed_at_source: closeout` with closed_at on or after
#     that date. An entry without the stamp (the 2026-08-06 rebuild and every older one), or no entry at
#     all, has no trusted closure date and is not judged. The date replaces the feature-number cut-off.
#   - Iteration closeout writes the stamp (Add-SpecrewClosedIterationEntry), and the index reader returns it.
#   - A recorded ruling is a `## Disposition` section in state.md naming a maintainer ruling or decision
#     with its date. The tests pin 174/007 (2026-06-14), 197/006 and 198/011 (2026-11-10) and 198/010
#     (2026-11-11); the four group B iterations record none.
#   - An iteration whose state.md says `abandoned` with a recorded ruling is not held to the plan-status
#     rule (retro.md exists) or the review-verdict rule; `abandoned` with no recorded ruling still gets both.
#   - Not here (iteration 002, maintainer 2026-11-12): "abandoned is closed only with a recorded ruling".
#
# The fixture tests run the validator on a temp-folder project; the last test runs it read-only on this
# repository's 198/011 (its memoization cache is under .specrew/.cache, gitignored).
# No specrew start, update or init; no hooks; nothing written to the home folder.

BeforeAll {
    $script:RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
    $script:SharedGovernance = Join-Path $script:RepoRoot 'extensions\specrew-speckit\scripts\shared-governance.ps1'
    $script:Validator = Join-Path $script:RepoRoot 'extensions\specrew-speckit\scripts\validate-governance.ps1'
    . $script:SharedGovernance

    $script:Root = Join-Path ([System.IO.Path]::GetTempPath()) ('since-' + [guid]::NewGuid().ToString('N').Substring(0, 10))
    $null = New-Item -ItemType Directory -Path (Join-Path $script:Root '.specrew') -Force
    # The dev-tree renderer and its shared library, so the dashboard check reads this tree's code and never
    # falls back to an installed Specrew module.
    $null = New-Item -ItemType Directory -Path (Join-Path $script:Root 'scripts\internal') -Force
    $null = New-Item -ItemType Directory -Path (Join-Path $script:Root 'extensions\specrew-speckit\scripts') -Force
    Copy-Item -LiteralPath (Join-Path $script:RepoRoot 'scripts\internal\dashboard-renderer.ps1') -Destination (Join-Path $script:Root 'scripts\internal\dashboard-renderer.ps1')
    Copy-Item -LiteralPath $script:SharedGovernance -Destination (Join-Path $script:Root 'extensions\specrew-speckit\scripts\shared-governance.ps1')
    # This repository's team file, so the validator passes its team check and reaches the dashboard check.
    $null = New-Item -ItemType Directory -Path (Join-Path $script:Root '.squad') -Force
    Copy-Item -LiteralPath (Join-Path $script:RepoRoot '.squad\team.md') -Destination (Join-Path $script:Root '.squad\team.md')

    function New-FixtureIteration {
        param(
            [string]$Feature,
            [string]$Iteration,
            [string]$PlanStatus,
            [string]$IterationStatus,
            [string]$StateBody = '',
            [string]$ReviewVerdict = '',
            [switch]$Retro
        )
        $featureDir = Join-Path $script:Root ('specs\{0}' -f $Feature)
        $dir = Join-Path $featureDir (Join-Path 'iterations' $Iteration)
        $null = New-Item -ItemType Directory -Path $dir -Force
        $spec = Join-Path $featureDir 'spec.md'
        if (-not (Test-Path -LiteralPath $spec)) { Set-Content -LiteralPath $spec -Value "# Feature Specification: $Feature" -Encoding UTF8 }
        Set-Content -LiteralPath (Join-Path $dir 'plan.md') -Value ("# Plan`n`n**Status**: $PlanStatus`n") -Encoding UTF8
        Set-Content -LiteralPath (Join-Path $dir 'state.md') -Value ("# Iteration State: $Iteration`n`n**Schema**: v2`n**Iteration Status**: $IterationStatus`n`n$StateBody") -Encoding UTF8
        Set-Content -LiteralPath (Join-Path $dir 'drift-log.md') -Value "# Drift Log`n" -Encoding UTF8
        if ($Retro) { Set-Content -LiteralPath (Join-Path $dir 'retro.md') -Value "# Retro`n" -Encoding UTF8 }
        if ($ReviewVerdict) { Set-Content -LiteralPath (Join-Path $dir 'review.md') -Value ("# Review`n`n**Overall Verdict**: $ReviewVerdict`n") -Encoding UTF8 }
        return $dir
    }

    # Dashboard fixture: every iteration is complete, has a retro.md and no dashboard.md.
    $null = New-FixtureIteration -Feature '901-fixture' -Iteration '001' -PlanStatus 'complete' -IterationStatus 'complete' -Retro
    $null = New-FixtureIteration -Feature '901-fixture' -Iteration '002' -PlanStatus 'complete' -IterationStatus 'complete' -Retro
    $null = New-FixtureIteration -Feature '901-fixture' -Iteration '003' -PlanStatus 'complete' -IterationStatus 'complete' -Retro
    $null = New-FixtureIteration -Feature '901-fixture' -Iteration '004' -PlanStatus 'complete' -IterationStatus 'complete' -Retro
    $null = New-FixtureIteration -Feature '005-early' -Iteration '001' -PlanStatus 'complete' -IterationStatus 'complete' -Retro

    Set-Content -LiteralPath (Join-Path $script:Root '.specrew\closed-iterations.yml') -Encoding UTF8 -Value @'
closed:
  - feature: 901-fixture
    iteration: 001
    closed_at: 2026-11-01T10:00:00Z
    closed_at_source: closeout
  - feature: 901-fixture
    iteration: 002
    closed_at: 2026-08-06T00:00:00Z
  - feature: 901-fixture
    iteration: 003
    closed_at: 2026-05-01T10:00:00Z
    closed_at_source: closeout
  - feature: 005-early
    iteration: 001
    closed_at: 2026-11-01T10:00:00Z
    closed_at_source: closeout
'@

    # Exemption fixture: abandoned iterations with a retro.md, with and without a recorded ruling.
    $script:RulingText = @'
## Disposition (2026-11-11, fixture)

**Abandoned, by the maintainer's ruling of 2026-11-10.** Closed as abandoned; review.md unchanged.
'@
    $script:RulingRetroDir = New-FixtureIteration -Feature '902-exempt' -Iteration '001' -PlanStatus 'retro' -IterationStatus 'abandoned' -StateBody $script:RulingText -ReviewVerdict 'needs-rework' -Retro
    $script:RulingAbandonedDir = New-FixtureIteration -Feature '902-exempt' -Iteration '002' -PlanStatus 'abandoned' -IterationStatus 'abandoned' -StateBody $script:RulingText -Retro
    $script:BareRetroDir = New-FixtureIteration -Feature '902-exempt' -Iteration '003' -PlanStatus 'retro' -IterationStatus 'abandoned' -ReviewVerdict 'needs-rework' -Retro
    $script:BareAbandonedDir = New-FixtureIteration -Feature '902-exempt' -Iteration '004' -PlanStatus 'abandoned' -IterationStatus 'abandoned' -Retro

    function Invoke-FixtureValidator {
        param([string[]]$Arguments)
        return (@(& pwsh -NoProfile -File $script:Validator -ProjectPath $script:Root @Arguments 2>&1 | ForEach-Object { [string]$_ }) -join "`n")
    }

    $script:StaleRetroPattern = "is stale: retro\.md exists"
    $script:ReviewVerdictPattern = "require review\.md overall verdict 'accepted'"
}

AfterAll {
    if ($script:Root -and (Test-Path -LiteralPath $script:Root)) {
        Remove-Item -LiteralPath $script:Root -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Describe 'T009: the dashboard check judges only iterations closed by closeout on or after 2026-05-26' {
    BeforeAll {
        $script:DashboardOutput = Invoke-FixtureValidator -Arguments @()
    }

    It 'judges an iteration stamped closed_at_source: closeout after the since date' {
        $script:DashboardOutput | Should -Match "missing-dashboard[^`n]*901-fixture 001"
    }

    It 'does not judge an index entry without the closeout stamp' {
        $script:DashboardOutput | Should -Not -Match "missing-dashboard[^`n]*901-fixture 002" -Because 'an unstamped entry has no trusted closure date'
    }

    It 'does not judge an iteration stamped by closeout before the since date' {
        $script:DashboardOutput | Should -Not -Match "missing-dashboard[^`n]*901-fixture 003" -Because 'it closed before the check shipped (2026-05-26)'
    }

    It 'does not judge an iteration closed by its status alone, with no index entry' {
        $script:DashboardOutput | Should -Not -Match "missing-dashboard[^`n]*901-fixture 004" -Because 'no closeout stamp, no trusted closure date'
    }

    It 'judges by date, not by feature number: a feature before 017 closed by closeout after the date is judged' {
        $script:DashboardOutput | Should -Match "missing-dashboard[^`n]*005-early 001" -Because 'the since date replaces the feature-number cut-off'
    }
}

Describe 'T009: iteration closeout writes the closure stamp, and the index reader returns it' {
    BeforeAll {
        $script:IndexRoot = Join-Path ([System.IO.Path]::GetTempPath()) ('stamp-' + [guid]::NewGuid().ToString('N').Substring(0, 10))
        $null = New-Item -ItemType Directory -Path (Join-Path $script:IndexRoot '.specrew') -Force
        Set-Content -LiteralPath (Join-Path $script:IndexRoot '.specrew\closed-iterations.yml') -Encoding UTF8 -Value @'
closed:
  - feature: 034-old
    iteration: 001
    closed_at: 2026-08-06T00:00:00Z
'@
        Add-SpecrewClosedIterationEntry -ProjectRoot $script:IndexRoot -Feature '206-sample' -Iteration '1' -ClosedAt '2026-11-12T10:04:00Z'
        $script:IndexText = Get-Content -LiteralPath (Join-Path $script:IndexRoot '.specrew\closed-iterations.yml') -Raw -Encoding UTF8
        $script:Index = Get-SpecrewClosedIterationIndex -ProjectRoot $script:IndexRoot
    }

    AfterAll {
        if ($script:IndexRoot -and (Test-Path -LiteralPath $script:IndexRoot)) {
            Remove-Item -LiteralPath $script:IndexRoot -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    It 'the new entry carries closed_at_source: closeout' {
        $script:IndexText | Should -Match "(?m)^\s*iteration: 001\s*\r?\n\s*closed_at: 2026-11-12T10:04:00Z\s*\r?\n\s*closed_at_source: closeout\s*$"
    }

    It 'the reader returns the stamp for the new entry and none for the old one' {
        $script:Index['206-sample/001'].closed_at_source | Should -Be 'closeout'
        $script:Index['034-old/001'].closed_at_source | Should -BeNullOrEmpty
        $script:Index['034-old/001'].closed_at | Should -Be '2026-08-06T00:00:00Z'
    }
}

Describe 'T009: a recorded ruling is read from the Disposition section of state.md' {
    It 'finds the recorded ruling of <Key>' -ForEach @(
        @{ Key = '174-hook-driven-session-bootstrap/007' }
        @{ Key = '197-continuous-co-review/006' }
        @{ Key = '198-beta2-hardening/010' }
        @{ Key = '198-beta2-hardening/011' }
    ) {
        $parts = $Key -split '/'
        $statePath = Join-Path $script:RepoRoot ('specs\{0}\iterations\{1}\state.md' -f $parts[0], $parts[1])
        Test-SpecrewIterationRulingRecorded -StatePath $statePath | Should -BeTrue
    }

    It 'finds no recorded ruling for group B iteration <Key>' -ForEach @(
        @{ Key = '197-continuous-co-review/002' }
        @{ Key = '197-continuous-co-review/007' }
        @{ Key = '197-continuous-co-review/008' }
        @{ Key = '198-beta2-hardening/005' }
    ) {
        $parts = $Key -split '/'
        $statePath = Join-Path $script:RepoRoot ('specs\{0}\iterations\{1}\state.md' -f $parts[0], $parts[1])
        Test-SpecrewIterationRulingRecorded -StatePath $statePath | Should -BeFalse
    }
}

Describe 'T009: abandoned by recorded ruling is exempt from the plan-status and review-verdict rules' {
    It 'abandoned with a ruling, plan at retro, review not accepted: no review-verdict finding' {
        $output = Invoke-FixtureValidator -Arguments @('-IterationPath', $script:RulingRetroDir)
        $output | Should -Not -Match $script:ReviewVerdictPattern
    }

    It 'abandoned with a ruling, plan at abandoned, retro.md present: no stale-status finding' {
        $output = Invoke-FixtureValidator -Arguments @('-IterationPath', $script:RulingAbandonedDir)
        $output | Should -Not -Match $script:StaleRetroPattern
    }

    It 'abandoned with no ruling, plan at retro, review not accepted: the review-verdict finding stays' {
        $output = Invoke-FixtureValidator -Arguments @('-IterationPath', $script:BareRetroDir)
        $output | Should -Match $script:ReviewVerdictPattern
    }

    It 'abandoned with no ruling, plan at abandoned, retro.md present: the stale-status finding stays' {
        $output = Invoke-FixtureValidator -Arguments @('-IterationPath', $script:BareAbandonedDir)
        $output | Should -Match $script:StaleRetroPattern
    }
}

Describe 'T009: the stamp is read with the validator''s own index reader, whatever renderer is loaded' {
    BeforeAll {
        # A renderer from an older installed Specrew module dot-sources its own shared-governance.ps1, whose
        # Get-SpecrewClosedIterationIndex returns entries with no closed_at_source key. The validator runs
        # under strict mode, where reading a missing key throws.
        $script:OldRoot = Join-Path ([System.IO.Path]::GetTempPath()) ('oldreader-' + [guid]::NewGuid().ToString('N').Substring(0, 10))
        $null = New-Item -ItemType Directory -Path (Join-Path $script:OldRoot '.specrew') -Force
        $null = New-Item -ItemType Directory -Path (Join-Path $script:OldRoot 'scripts\internal') -Force
        $null = New-Item -ItemType Directory -Path (Join-Path $script:OldRoot '.squad') -Force
        Copy-Item -LiteralPath (Join-Path $script:RepoRoot '.squad\team.md') -Destination (Join-Path $script:OldRoot '.squad\team.md')
        $oldDir = Join-Path $script:OldRoot 'specs\903-old-reader\iterations\001'
        $null = New-Item -ItemType Directory -Path $oldDir -Force
        Set-Content -LiteralPath (Join-Path $script:OldRoot 'specs\903-old-reader\spec.md') -Value '# Feature Specification: 903-old-reader' -Encoding UTF8
        Set-Content -LiteralPath (Join-Path $oldDir 'plan.md') -Value "# Plan`n`n**Status**: complete`n" -Encoding UTF8
        Set-Content -LiteralPath (Join-Path $oldDir 'state.md') -Value "# Iteration State: 001`n`n**Schema**: v2`n**Iteration Status**: complete`n" -Encoding UTF8
        Set-Content -LiteralPath (Join-Path $script:OldRoot '.specrew\closed-iterations.yml') -Encoding UTF8 -Value @'
closed:
  - feature: 903-old-reader
    iteration: 001
    closed_at: 2026-11-01T10:00:00Z
    closed_at_source: closeout
'@
        @"
function Get-SpecrewFeatureRecords {
    param([string]`$ProjectRoot)
    @([pscustomobject]@{
        feature_ref = '903-old-reader'; feature_status = 'active'; has_feature_closeout = `$false; closeout_dashboard_path = ''
        closed_iterations = @([pscustomobject]@{ iteration_ref = '001'; iteration_directory = '$($oldDir -replace "'", "''")' })
    })
}
function Read-SpecrewRoadmapDefinition { param([string]`$ProjectRoot) [pscustomobject]@{ exists = `$false; warnings = @() } }
function Get-SpecrewRoadmapProgress { param([object]`$RoadmapDefinition, [object[]]`$FeatureRecords) [pscustomobject]@{ warnings = @() } }
# The older reader: entries carry closed_at only.
function Get-SpecrewClosedIterationIndex {
    param([string]`$ProjectRoot)
    return @{ '903-old-reader/001' = @{ closed_at = '2026-11-01T10:00:00Z' } }
}
"@ | Set-Content -LiteralPath (Join-Path $script:OldRoot 'scripts\internal\dashboard-renderer.ps1') -Encoding UTF8
        $script:OldReaderOutput = (@(& pwsh -NoProfile -File $script:Validator -ProjectPath $script:OldRoot 2>&1 | ForEach-Object { [string]$_ }) -join "`n")
    }

    AfterAll {
        if ($script:OldRoot -and (Test-Path -LiteralPath $script:OldRoot)) {
            Remove-Item -LiteralPath $script:OldRoot -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    It 'the validator does not fail on an index entry with no closed_at_source key' {
        $script:OldReaderOutput | Should -Not -Match 'unexpected-validator-error'
        $script:OldReaderOutput | Should -Not -Match "closed_at_source' cannot be found"
    }

    It 'the dashboard check still sees the stamp in .specrew/closed-iterations.yml' {
        $script:OldReaderOutput | Should -Match "missing-dashboard[^`n]*903-old-reader 001"
    }

    It 'Test-SpecrewClosedCheckApplies under strict mode treats an entry with no stamp key as unstamped' {
        Set-StrictMode -Version Latest
        $index = @{ '903-old-reader/001' = @{ closed_at = '2026-11-01T10:00:00Z' } }
        Test-SpecrewClosedCheckApplies -ClosedIndex $index -Feature '903-old-reader' -Iteration '001' -Since ([datetime]::new(2026, 5, 26)) | Should -BeFalse
    }
}

Describe 'T009 acceptance: 198/011 in this repository' {
    It 'the validator on 198/011 reports neither the review-verdict nor the stale-status finding' {
        $iterationDir = Join-Path $script:RepoRoot 'specs\198-beta2-hardening\iterations\011'
        $output = (@(& pwsh -NoProfile -File $script:Validator -ProjectPath $script:RepoRoot -IterationPath $iterationDir 2>&1 | ForEach-Object { [string]$_ }) -join "`n")
        $output | Should -Not -Match $script:ReviewVerdictPattern
        $output | Should -Not -Match $script:StaleRetroPattern
    }
}
