# Feature 206, T008 (FR-007, SC-005; design condition 2): a frozen legacy iteration is judged by nothing.
#   - .specrew/legacy-frozen.yml holds exactly the 18 entries the maintainer ruled on (closed_on 2026-11-10);
#     an added key fails the guard below.
#   - The validator skips a frozen entry in every mode: full-repo, -IncludeClosed and explicit targets.
#   - The dashboard check applies to complete iterations only: an abandoned iteration owes no dashboard
#     (maintainer, plan verdict).
#
# The fixture tests run the validator on a temp-folder project; the last test runs it read-only over this
# repository's 18 frozen entries (its memoization cache is under .specrew/.cache, gitignored).
# No specrew start, update or init; no hooks; nothing written to the home folder.

BeforeAll {
    $script:RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
    $script:SharedGovernance = Join-Path $script:RepoRoot 'extensions\specrew-speckit\scripts\shared-governance.ps1'
    $script:Validator = Join-Path $script:RepoRoot 'extensions\specrew-speckit\scripts\validate-governance.ps1'
    . $script:SharedGovernance

    $script:FrozenKeys = @(
        '048-beta-before-stable-sdlc/001',
        '197-continuous-co-review/001',
        '198-beta2-hardening/008',
        '141-design-gate-runtime-hardening/006',
        '141-design-gate-runtime-hardening/007',
        '141-design-gate-runtime-hardening/008',
        '174-hook-driven-session-bootstrap/006',
        '174-hook-driven-session-bootstrap/008',
        '174-hook-driven-session-bootstrap/009',
        '174-hook-driven-session-bootstrap/010',
        '174-hook-driven-session-bootstrap/011',
        '182-work-kind-branch-governance/002',
        '182-work-kind-branch-governance/003',
        '182-work-kind-branch-governance/004',
        '197-continuous-co-review/003',
        '197-continuous-co-review/004',
        '197-continuous-co-review/005',
        '198-beta2-hardening/003'
    )

    $script:Root = Join-Path ([System.IO.Path]::GetTempPath()) ('frozen-' + [guid]::NewGuid().ToString('N').Substring(0, 10))
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
        param([string]$Iteration, [string]$PlanStatus, [string]$IterationStatus)
        $featureDir = Join-Path $script:Root 'specs\901-fixture'
        $dir = Join-Path $featureDir (Join-Path 'iterations' $Iteration)
        $null = New-Item -ItemType Directory -Path $dir -Force
        $spec = Join-Path $featureDir 'spec.md'
        if (-not (Test-Path -LiteralPath $spec)) { Set-Content -LiteralPath $spec -Value '# Feature Specification: 901-fixture' -Encoding UTF8 }
        Set-Content -LiteralPath (Join-Path $dir 'plan.md') -Value ("# Plan`n`n**Status**: $PlanStatus`n") -Encoding UTF8
        Set-Content -LiteralPath (Join-Path $dir 'state.md') -Value ("# Iteration State: $Iteration`n`n**Schema**: v2`n**Iteration Status**: $IterationStatus`n") -Encoding UTF8
        Set-Content -LiteralPath (Join-Path $dir 'retro.md') -Value "# Retro`n" -Encoding UTF8
        return $dir
    }

    # 001: frozen. Its plan.md would FAIL live validation (an unknown Status), like the frozen entries here.
    $script:FrozenDir = New-FixtureIteration -Iteration '001' -PlanStatus 'bogus-enum' -IterationStatus 'retro'
    # 002: abandoned (closed), no dashboard.md. 003: complete (closed), no dashboard.md.
    $null = New-FixtureIteration -Iteration '002' -PlanStatus 'retro' -IterationStatus 'abandoned'
    $null = New-FixtureIteration -Iteration '003' -PlanStatus 'complete' -IterationStatus 'complete'

    Set-Content -LiteralPath (Join-Path $script:Root '.specrew\legacy-frozen.yml') -Encoding UTF8 -Value @'
schema: v1
closed_on: 2026-11-10
entries:
  - iteration: 901-fixture/001
    reason: fixture
'@

    function Invoke-FixtureValidator {
        param([string[]]$Arguments)
        return (@(& pwsh -NoProfile -File $script:Validator -ProjectPath $script:Root @Arguments 2>&1 | ForEach-Object { [string]$_ }) -join "`n")
    }
}

AfterAll {
    if ($script:Root -and (Test-Path -LiteralPath $script:Root)) {
        Remove-Item -LiteralPath $script:Root -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Describe 'T008 guard: the frozen list is closed at 18 entries' {
    It 'holds exactly the 18 ruled keys; an added or removed key fails here' {
        $actual = @(Get-SpecrewLegacyFrozenIterationKeys -ProjectRoot $script:RepoRoot | Sort-Object)
        $expected = @($script:FrozenKeys | Sort-Object)
        $actual.Count | Should -Be 18 -Because 'no entry may be added after closed_on 2026-11-10'
        ($actual -join "`n") | Should -Be ($expected -join "`n")
    }
}

Describe 'T008: the validator skips a frozen entry in every mode' {
    It 'a full-repo run does not validate the frozen entry and says why' {
        $output = Invoke-FixtureValidator -Arguments @()
        $output | Should -Not -Match '(PASS|FAIL) .*901-fixture[\\/]iterations[\\/]001'
        $output | Should -Match 'frozen filter: 1 frozen legacy iteration'
    }

    It '-IncludeClosed does not reach a frozen entry either: frozen is not closed history' {
        $output = Invoke-FixtureValidator -Arguments @('-IncludeClosed')
        $output | Should -Not -Match '(PASS|FAIL) .*901-fixture[\\/]iterations[\\/]001'
        $output | Should -Match 'frozen filter: 1 frozen legacy iteration'
    }

    It 'naming the frozen entry as an explicit target judges nothing' {
        $output = Invoke-FixtureValidator -Arguments @('-IterationPath', $script:FrozenDir)
        $output | Should -Not -Match '(PASS|FAIL) .*901-fixture[\\/]iterations[\\/]001'
        $output | Should -Match 'frozen filter: 1 frozen legacy iteration'
    }
}

Describe 'T008: the dashboard check applies to complete iterations only' {
    It 'an abandoned iteration owes no dashboard; a complete one still does' {
        $output = Invoke-FixtureValidator -Arguments @()
        $output | Should -Not -Match "missing-dashboard[^`n]*901-fixture 002" -Because 'an abandoned iteration was never closed out, so no dashboard was rendered'
        $output | Should -Match "missing-dashboard[^`n]*901-fixture 003" -Because 'the check still applies to complete iterations'
    }
}

Describe 'T008 acceptance: the 18 frozen entries in this repository' {
    It 'the validator over each frozen entry reports zero findings' {
        $paths = @($script:FrozenKeys | ForEach-Object {
                $parts = $_ -split '/'
                "'" + (Join-Path $script:RepoRoot ('specs\{0}\iterations\{1}' -f $parts[0], $parts[1])) + "'"
            }) -join ','
        $command = "& '$script:Validator' -ProjectPath '$script:RepoRoot' -IterationPath @($paths); exit `$LASTEXITCODE"
        $output = (@(& pwsh -NoProfile -Command $command 2>&1 | ForEach-Object { [string]$_ }) -join "`n")
        foreach ($key in $script:FrozenKeys) {
            $parts = $key -split '/'
            $pattern = '{0}[\\/]iterations[\\/]{1}\b' -f [regex]::Escape($parts[0]), $parts[1]
            $output | Should -Not -Match $pattern -Because "$key is frozen: judged by no check"
        }
        $output | Should -Match 'frozen filter: 18 frozen legacy iterations'
    }
}
