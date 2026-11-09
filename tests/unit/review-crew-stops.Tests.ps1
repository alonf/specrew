# Feature 203 T008 step (iii) (FR-006, FR-011; maintainer ruling 2026-11-09 on the old pause decision, condition 2): the crew's
# own entry points for review stops (b) and (c). `specrew review --dispute <id> --reason <text>` and
# `--propose-defer <id> --to <destination>` raise stop (b); `--ask <text>` raises stop (c). Each writer sets its own reason -
# a stop's reason is always its own writer's, never a sentence from the old menu - and a case renders both and finds none of
# the old sentences. Entered at the command a crew runs (the fifth method rule), on a real Git repository.

BeforeAll {
    $script:RepoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    . (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/_load.ps1')
    . (Join-Path $script:RepoRoot 'scripts/internal/bootstrap/HumanAuthorityStore.ps1')
    $script:CampaignId = Get-ReviewCampaignIdForIteration -FeatureId '001-fixture' -IterationNumber '001'
    $script:Utf8 = [Text.UTF8Encoding]::new($false)
    $script:SessionSignals = @(Get-SpecrewAgentSessionSignalNames)
    $script:OpenId = 'finding-0123456789abcdef'

    # Every sentence of the deleted pause decision and menu (review-authority-core.ps1 before a0ab0ca0).
    $script:OldSentences = @(
        'Fix the blocking findings before you sign off', 'Look at the major findings', 'Nothing here blocks you',
        'Nothing was reported as blocking', 'Nothing was found. Stopping here completes your sign-off', 'reset it explicitly or abandon',
        'another round is not on offer', 'run another round', 'abandon this review campaign', 'What would you like to do',
        'Nothing runs and nothing is spent until you answer', 'fix-and-continue')

    function script:Invoke-CrewGit([string]$Root, [string[]]$Arguments) {
        $null = & git -C $Root -c user.name=t -c user.email=t@example.invalid @Arguments 2>&1
        if ($LASTEXITCODE -ne 0) { throw ('fixture-git-failed:' + ($Arguments -join ' ')) }
    }

    # A project during implement whose last run brought back part of a review with one major finding, which stays open.
    function script:New-CrewProject([string]$Name) {
        $root = Join-Path $TestDrive $Name
        New-Item -ItemType Directory -Path (Join-Path $root '.specrew'), (Join-Path $root 'specs/001-fixture/iterations/001'), (Join-Path $root 'src') -Force | Out-Null
        [IO.File]::WriteAllText((Join-Path $root 'specs/001-fixture/spec.md'), '# Fixture design context', $script:Utf8)
        [IO.File]::WriteAllText((Join-Path $root 'src/app.ps1'), "function Get-Answer { 42 }`n", $script:Utf8)
        [IO.File]::WriteAllText((Join-Path $root '.gitignore'), ".specrew/review/`n", $script:Utf8)
        Set-Content -LiteralPath (Join-Path $root '.specrew/config.yml') -Value "specrew_version: `"0.40.0`"`nbootstrap_mode: `"fixture`"" -Encoding UTF8
        $context = [ordered]@{
            session_state = [ordered]@{ active = $true; boundary_type = 'before-implement'; feature_ref = '001-fixture'; iteration_number = '001' }
            boundary_enforcement = [ordered]@{ verdict_history = @([ordered]@{ from_boundary = 'tasks'; to_boundary = 'before-implement'; verdict_text = 'approved for before-implement'; feature_ref = '001-fixture'; recorded_at = '2026-11-01T10:00:00Z'; authorization_id = 'auth-0123456789abcdef' }) }
        }
        [IO.File]::WriteAllText((Join-Path $root '.specrew/start-context.json'), ($context | ConvertTo-Json -Depth 8), $script:Utf8)
        script:Invoke-CrewGit $root @('init', '-q', '-b', '001-fixture')
        script:Invoke-CrewGit $root @('add', '-A')
        script:Invoke-CrewGit $root @('commit', '-qm', 'initial')
        $store = Join-Path $root '.specrew/review/authority'
        $resolution = [pscustomobject]@{ budget_total = 2; host_order = @(); host_order_stated = $false; infra_failure_cap = 2; budget_source = 'plan'; ceiling = 10; plan_path = 'specs/001-fixture/plan.md'; plan_hash = ('a' * 64) }
        $null = Add-ReviewCampaignBudgetGrantFact -StoreRoot $store -Fact (New-ReviewBudgetGrantFact -CampaignId $script:CampaignId -Resolution $resolution -VerdictEntry 'auth-crew' -ObservedAt '2026-11-08T08:00:00.0000000+00:00')
        $partial = [pscustomobject][ordered]@{
            schema_version = '1.0'; campaign_id = $script:CampaignId; run_id = 'run-crew-partial'; target_digest = ('a' * 40); harness_id = 'fixture'
            completion = 'partial'; verdict = 'incomplete'; runtime_outcome = 'timed-out'; termination_verified = $true; containment = 'verified'
            currentness = 'current'; validation = 'valid'; can_approve_current = $false; summary = 'half'
            findings = @([pscustomobject][ordered]@{ finding_id = $script:OpenId; source_local_id = 'l1'; lineage_id = 'lin-0123456789abcdef'; severity = 'major'; title = 'Empty store'; description = 'Failure scenario: an empty store throws.'; location = 'src/app.ps1:1'; relevance = 'current'; resolution = 'open'; demoted = $false; demoted_from = '' })
            started_at = '2026-11-09T08:00:00Z'; ended_at = '2026-11-09T08:01:00Z'; duration_ms = 60000; examined_paths = @('src/app.ps1'); review_collected = $false
        }
        Request-ReviewAuthorityClaim -StoreRoot $store -CampaignId $script:CampaignId -RunId 'run-crew-partial' -TargetLineage 'lin-001-fixture' -ObservedAt '2026-11-09T08:00:00Z' | Out-Null
        Publish-ReviewRunResultFact -StoreRoot $store -CampaignId $script:CampaignId -RunId 'run-crew-partial' -Fact $partial | Out-Null
        Complete-ReviewAuthorityClaim -StoreRoot $store -CampaignId $script:CampaignId -RunId 'run-crew-partial' -TargetLineage 'lin-001-fixture' -Disposition released -ObservedAt '2026-11-09T08:01:00Z' | Out-Null
        return [pscustomobject]@{ root = $root; store = $store }
    }

    # The review command, in its own process with stdin closed and the host session signals present (the crew runs it).
    function script:Invoke-CrewCli([pscustomobject]$Project, [string[]]$Arguments) {
        $saved = @{}
        foreach ($name in $script:SessionSignals) { $saved[$name] = [Environment]::GetEnvironmentVariable($name); [Environment]::SetEnvironmentVariable($name, $null) }
        [Environment]::SetEnvironmentVariable('CLAUDECODE', '1')
        try {
            $out = Join-Path $TestDrive ('cli-' + [guid]::NewGuid().ToString('N'))
            [IO.File]::WriteAllText("$out.in", '')
            $argumentList = @('-NoProfile', '-NonInteractive', '-File', (Join-Path $script:RepoRoot 'scripts/specrew-review.ps1'), '-ProjectPath', $Project.root) + $Arguments
            $process = Start-Process -FilePath 'pwsh' -ArgumentList $argumentList -RedirectStandardInput "$out.in" -RedirectStandardOutput "$out.out" -RedirectStandardError "$out.err" -NoNewWindow -PassThru -Wait
            $text = (Get-Content -LiteralPath "$out.out" -Raw -ErrorAction SilentlyContinue) + (Get-Content -LiteralPath "$out.err" -Raw -ErrorAction SilentlyContinue)
            return [pscustomobject]@{ ExitCode = $process.ExitCode; Text = ((($text -replace "`e\[[0-9;]*m", '') -replace '\s*\|\s+', ' ') -replace '\s+', ' ') }
        }
        finally { foreach ($name in $script:SessionSignals) { [Environment]::SetEnvironmentVariable($name, $saved[$name]) } }
    }

    function script:Get-OpenStops([pscustomobject]$Project) {
        return @(Get-ReviewCampaignPauseRecords -StoreRoot $Project.store -CampaignId $script:CampaignId | Where-Object { -not $_.answered })
    }
}

Describe 'the crew raises stop (b) and stop (c) itself, each with its own reason (FR-006, FR-011)' {
    It '--dispute FINDING --reason TEXT raises stop (b), naming the finding and the crew''s reason' {
        $project = script:New-CrewProject -Name 'dispute'
        $result = script:Invoke-CrewCli -Project $project -Arguments @('--feature', '001-fixture', '--iteration', '001', '--dispute', $script:OpenId, '--reason', 'the store is never empty here: the constructor seeds it')
        $result.ExitCode | Should -Be 0 -Because $result.Text
        $stops = @(script:Get-OpenStops -Project $project)
        $stops.Count | Should -Be 1
        [string]$stops[0].pause.stop_kind | Should -BeExactly 'b-dispute-or-defer'
        [string]$stops[0].pause.stop_reason | Should -BeExactly 'dispute'
        $result.Text | Should -Match 'Specrew review stopped'
        $result.Text | Should -Match ('Why: the crew disputes ' + [regex]::Escape($script:OpenId) + ' \(Empty store\)')
        $result.Text | Should -Match 'the constructor seeds it'
        $result.Text | Should -Match 'drop finding <id>'
    }

    It '--propose-defer FINDING --to DESTINATION raises stop (b), naming where the crew would move it' {
        $project = script:New-CrewProject -Name 'propose-defer'
        $result = script:Invoke-CrewCli -Project $project -Arguments @('--feature', '001-fixture', '--iteration', '001', '--propose-defer', $script:OpenId, '--to', 'B5F-040')
        $result.ExitCode | Should -Be 0 -Because $result.Text
        $stops = @(script:Get-OpenStops -Project $project)
        [string]$stops[0].pause.stop_kind | Should -BeExactly 'b-dispute-or-defer'
        [string]$stops[0].pause.stop_reason | Should -BeExactly 'propose-defer'
        $result.Text | Should -Match ('Why: the crew proposes to defer ' + [regex]::Escape($script:OpenId) + ' \(Empty store\) to B5F-040')
    }

    It '--ask TEXT raises stop (c) carrying the crew''s question' {
        $project = script:New-CrewProject -Name 'ask'
        $result = script:Invoke-CrewCli -Project $project -Arguments @('--feature', '001-fixture', '--iteration', '001', '--ask', 'should the retry cap count per host or per campaign?')
        $result.ExitCode | Should -Be 0 -Because $result.Text
        $stops = @(script:Get-OpenStops -Project $project)
        [string]$stops[0].pause.stop_kind | Should -BeExactly 'c-judgment'
        [string]$stops[0].pause.stop_reason | Should -BeExactly 'ask'
        $result.Text | Should -Match 'Why: the crew needs your judgment: should the retry cap count per host or per campaign\?'
    }

    It 'rendering the (b) and (c)-ask stops finds none of the old menu sentences, and no command or flag' {
        $dispute = script:New-CrewProject -Name 'old-b'
        $ask = script:New-CrewProject -Name 'old-c'
        $null = script:Invoke-CrewCli -Project $dispute -Arguments @('--feature', '001-fixture', '--iteration', '001', '--dispute', $script:OpenId, '--reason', 'the constructor seeds it')
        $null = script:Invoke-CrewCli -Project $ask -Arguments @('--feature', '001-fixture', '--iteration', '001', '--ask', 'per host or per campaign?')
        foreach ($project in @($dispute, $ask)) {
            $stop = @(script:Get-OpenStops -Project $project)[0].pause
            $surface = @(Format-ReviewCampaignStopSurface -Stop $stop -OpenFindings @(Get-ReviewCampaignOpenFindings -StoreRoot $project.store -CampaignId $script:CampaignId)) -join "`n"
            foreach ($sentence in $script:OldSentences) { $surface | Should -Not -Match ([regex]::Escape($sentence)) -Because "the old menu's sentence never reaches a stop: $sentence" }
            $surface | Should -Not -Match 'specrew review --'
            $surface | Should -Not -Match '(?<![\w-])--[a-z]'
        }
    }
}

Describe 'the crew''s stop writers refuse in plain words and write nothing (FR-025)' {
    It 'a finding that is not open in this review is refused, named' {
        $project = script:New-CrewProject -Name 'unknown-finding'
        $result = script:Invoke-CrewCli -Project $project -Arguments @('--feature', '001-fixture', '--iteration', '001', '--dispute', 'finding-ffffffffffffffff', '--reason', 'x is fine')
        $result.ExitCode | Should -Not -Be 0
        $result.Text | Should -Match 'finding-ffffffffffffffff'
        $result.Text | Should -Match '(?i)nothing was recorded'
        @(script:Get-OpenStops -Project $project).Count | Should -Be 0
    }

    It '<Flag> without its <Missing> is refused' -ForEach @(
        @{ Flag = '--dispute'; Missing = '--reason'; Arguments = @('--dispute', 'finding-0123456789abcdef') }
        @{ Flag = '--propose-defer'; Missing = '--to'; Arguments = @('--propose-defer', 'finding-0123456789abcdef') }
    ) {
        $project = script:New-CrewProject -Name ('missing-' + $Missing.TrimStart('-'))
        $result = script:Invoke-CrewCli -Project $project -Arguments (@('--feature', '001-fixture', '--iteration', '001') + $Arguments)
        $result.ExitCode | Should -Not -Be 0
        $result.Text | Should -Match ([regex]::Escape($Missing))
        $result.Text | Should -Match '(?i)nothing was recorded'
        @(script:Get-OpenStops -Project $project).Count | Should -Be 0
    }

    It 'a stop already waiting for the human is answered first: a second one is refused' {
        $project = script:New-CrewProject -Name 'one-at-a-time'
        $null = script:Invoke-CrewCli -Project $project -Arguments @('--feature', '001-fixture', '--iteration', '001', '--ask', 'per host or per campaign?')
        $second = script:Invoke-CrewCli -Project $project -Arguments @('--feature', '001-fixture', '--iteration', '001', '--dispute', $script:OpenId, '--reason', 'seeded')
        $second.ExitCode | Should -Not -Be 0
        $second.Text | Should -Match '(?i)already waiting'
        @(script:Get-OpenStops -Project $project).Count | Should -Be 1
    }
}

Describe 'the review command teaches only what exists' {
    It 'its help names the crew''s stop flags and no retired pause answer' {
        $project = script:New-CrewProject -Name 'help'
        $help = script:Invoke-CrewCli -Project $project -Arguments @('--help')
        foreach ($flag in @('--dispute', '--reason', '--propose-defer', '--to', '--ask')) { $help.Text | Should -Match ([regex]::Escape($flag)) }
        $help.Text | Should -Not -Match '(?i)run another round|abandon this review campaign|<1\|2\|3>' -Because 'the numbered answers and abandon were retired (2026-11-09 mapping)'
    }

    It 'no reader-facing line of the review command offers a numbered pause answer' {
        $cli = Get-Content -LiteralPath (Join-Path $script:RepoRoot 'scripts/specrew-review.ps1') -Encoding UTF8
        $offers = @($cli | Where-Object { $_ -match 'Write-Host' -and $_ -match '(?i)1 = run another round|--pause-choice <1\|2\|3>' })
        $offers.Count | Should -Be 0 -Because ('a line teaching a refused answer: ' + ($offers -join ' / '))
    }
}
