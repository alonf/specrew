# Feature 203 T023 (i) (B5F-083; Gap Ledger): the governance check refused an iteration folder with no plan.md
# ("Missing required artifact: plan.md") even while that iteration's plan crossing was the next one waiting for the
# human, so scaffolding an iteration folder and pushing it before the plan verdict turned Specrew CI's Lint red. A folder
# whose plan crossing is the NEXT one pending is a normal state and is accepted with a warning; once the plan crossing
# is behind, a missing plan.md fails as before. Read through the same enforcement-state reader as feature 206's T034
# (3a3ba803), and written to that function's round-2 rule from the start (the reviewer session's terms, 2026-11-16): only
# the crossing that comes next counts as pending - not merely a later one - and the iteration is compared even when the
# session names none (then only the feature's newest iteration folder can be pending). Where .specrew/start-context.json
# is absent (it is ignored by git, so CI and a fresh clone have none) the folder is accepted with a warning naming the
# file - the blind spot 206 recorded as its item 53 - so the refusing half holds locally only.
#
# Each case runs the validator on a temp fixture and looks only for the missing-plan message and the warning: a fixture
# this small may fail other checks, which are not this suite's subject.

BeforeAll {
    $script:RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
    $script:Validator = Join-Path $script:RepoRoot 'extensions\specrew-speckit\scripts\validate-governance.ps1'
    $script:Work = Join-Path ([IO.Path]::GetTempPath()) ('plan-crossing-pending-' + [guid]::NewGuid().ToString('N').Substring(0, 10))
    $null = New-Item -ItemType Directory -Path $script:Work -Force
    $script:MissingPlan = 'Missing required artifact: plan.md'

    # A feature whose iteration 001 is planned; the iteration under test ($Iteration) is scaffolded with no plan.md.
    function New-PlanFixture {
        param([string]$Name, [string]$Iteration = '002', [AllowNull()][string]$LastAuthorized, [string]$SessionIteration = '002',
            [string]$SessionFeature = '909-plans', [switch]$NewerIteration)
        $root = Join-Path $script:Work $Name
        $null = New-Item -ItemType Directory -Path (Join-Path $root '.specrew') -Force
        $null = New-Item -ItemType Directory -Path (Join-Path $root 'scripts\internal') -Force
        $null = New-Item -ItemType Directory -Path (Join-Path $root 'extensions\specrew-speckit\scripts') -Force
        Copy-Item -LiteralPath (Join-Path $script:RepoRoot 'scripts\internal\dashboard-renderer.ps1') -Destination (Join-Path $root 'scripts\internal\dashboard-renderer.ps1')
        Copy-Item -LiteralPath (Join-Path $script:RepoRoot 'extensions\specrew-speckit\scripts\shared-governance.ps1') -Destination (Join-Path $root 'extensions\specrew-speckit\scripts\shared-governance.ps1')
        $null = New-Item -ItemType Directory -Path (Join-Path $root '.squad') -Force
        Copy-Item -LiteralPath (Join-Path $script:RepoRoot '.squad\team.md') -Destination (Join-Path $root '.squad\team.md')
        Set-Content -LiteralPath (Join-Path (New-Item -ItemType Directory -Path (Join-Path $root 'specs\909-plans') -Force) 'spec.md') -Value '# Feature Specification: 909-plans' -Encoding UTF8
        if ($Iteration -ne '001') {
            $planned = Join-Path $root 'specs\909-plans\iterations\001'
            $null = New-Item -ItemType Directory -Path $planned -Force
            Set-Content -LiteralPath (Join-Path $planned 'plan.md') -Value "# Plan`n`n**Status**: complete`n" -Encoding UTF8
            Set-Content -LiteralPath (Join-Path $planned 'state.md') -Value "# Iteration State: 001`n`n**Schema**: v2`n**Iteration Status**: complete`n" -Encoding UTF8
        }
        $dir = Join-Path $root "specs\909-plans\iterations\$Iteration"
        $null = New-Item -ItemType Directory -Path $dir -Force
        Set-Content -LiteralPath (Join-Path $dir 'state.md') -Value "# Iteration State: $Iteration`n`n**Schema**: v2`n**Iteration Status**: planning`n" -Encoding UTF8
        Set-Content -LiteralPath (Join-Path $dir 'drift-log.md') -Value "# Drift Log`n" -Encoding UTF8
        if ($NewerIteration) {
            $newer = Join-Path $root ('specs\909-plans\iterations\{0:D3}' -f ([int]$Iteration + 1))
            $null = New-Item -ItemType Directory -Path $newer -Force
            Set-Content -LiteralPath (Join-Path $newer 'state.md') -Value "# Iteration State`n`n**Schema**: v2`n**Iteration Status**: planning`n" -Encoding UTF8
        }
        if (-not [string]::IsNullOrWhiteSpace($LastAuthorized)) {
            $context = [ordered]@{
                schema_version       = '1.0'
                session_state        = [ordered]@{ active = $true; boundary_type = $LastAuthorized; feature_ref = $SessionFeature; iteration_number = $SessionIteration }
                boundary_enforcement = [ordered]@{
                    enabled = $true; last_authorized_boundary = $LastAuthorized; pending_next_boundary = $null; pending_crossing = $null
                    policy_classes = @{}; verdict_history = @(); correction_history = @(); bypass_history = @()
                }
            }
            Set-Content -LiteralPath (Join-Path $root '.specrew\start-context.json') -Value ($context | ConvertTo-Json -Depth 6) -Encoding UTF8
        }
        return [pscustomobject]@{ Root = $root; Iteration = $dir }
    }

    function Invoke-PlanValidator {
        param($Fixture)
        return (@(& pwsh -NoProfile -File $script:Validator -ProjectPath $Fixture.Root -IterationPath $Fixture.Iteration 2>&1 | ForEach-Object { [string]$_ }) -join "`n")
    }
}

AfterAll {
    if ((Split-Path -Leaf $script:Work) -like 'plan-crossing-pending-*') { Remove-Item -LiteralPath $script:Work -Recurse -Force -ErrorAction SilentlyContinue }
}

Describe 'An iteration folder waiting for its plan verdict is not missing its plan (B5F-083)' {
    It 'accepts a new iteration''s folder with no plan.md after iteration-closeout, with a warning' {
        $output = Invoke-PlanValidator -Fixture (New-PlanFixture -Name 'after-closeout' -LastAuthorized 'iteration-closeout')
        $output | Should -Not -Match ([regex]::Escape($script:MissingPlan))
        $output | Should -Match 'WARN .*plan\.md'
    }

    It 'accepts the first iteration''s folder with no plan.md after clarify, with a warning' {
        $output = Invoke-PlanValidator -Fixture (New-PlanFixture -Name 'after-clarify' -Iteration '001' -SessionIteration '001' -LastAuthorized 'clarify')
        $output | Should -Not -Match ([regex]::Escape($script:MissingPlan))
        $output | Should -Match 'WARN .*plan\.md'
    }

    It 'accepts the folder with a warning naming start-context.json when that file is absent (CI)' {
        $output = Invoke-PlanValidator -Fixture (New-PlanFixture -Name 'no-context')
        $output | Should -Not -Match ([regex]::Escape($script:MissingPlan))
        $output | Should -Match 'WARN .*start-context\.json'
    }

    It 'accepts the newest iteration''s folder when the session names no iteration' {
        $output = Invoke-PlanValidator -Fixture (New-PlanFixture -Name 'blank-newest' -LastAuthorized 'iteration-closeout' -SessionIteration '')
        $output | Should -Not -Match ([regex]::Escape($script:MissingPlan))
    }
}

Describe 'Only the plan crossing that comes next is pending (pinned: these fail today and keep failing)' {
    It 'fails once the plan crossing is behind (plan is the last authorized boundary)' {
        Invoke-PlanValidator -Fixture (New-PlanFixture -Name 'plan-behind' -LastAuthorized 'plan') | Should -Match ([regex]::Escape($script:MissingPlan))
    }

    It 'fails when a later boundary is authorized (before-implement)' {
        Invoke-PlanValidator -Fixture (New-PlanFixture -Name 'later-behind' -LastAuthorized 'before-implement') | Should -Match ([regex]::Escape($script:MissingPlan))
    }

    It 'fails when the plan crossing is not the next one (specify, with clarify still to come)' {
        Invoke-PlanValidator -Fixture (New-PlanFixture -Name 'specify-only' -Iteration '001' -SessionIteration '001' -LastAuthorized 'specify') | Should -Match ([regex]::Escape($script:MissingPlan))
    }

    It 'fails when the session names another iteration' {
        Invoke-PlanValidator -Fixture (New-PlanFixture -Name 'other-iteration' -LastAuthorized 'iteration-closeout' -SessionIteration '003') | Should -Match ([regex]::Escape($script:MissingPlan))
    }

    It 'fails when the session names no iteration and this folder is not the newest' {
        Invoke-PlanValidator -Fixture (New-PlanFixture -Name 'blank-older' -LastAuthorized 'iteration-closeout' -SessionIteration '' -NewerIteration) | Should -Match ([regex]::Escape($script:MissingPlan))
    }

    It 'fails when the session is about another feature' {
        Invoke-PlanValidator -Fixture (New-PlanFixture -Name 'other-feature' -LastAuthorized 'iteration-closeout' -SessionFeature '908-records') | Should -Match ([regex]::Escape($script:MissingPlan))
    }
}
