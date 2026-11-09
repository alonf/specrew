# Feature 203 T008 step (iii) (FR-010, FR-011, FR-025; maintainer rulings 2026-11-09 on the numbered pause answers):
# `stop the review here` is the only pause answer left. `--pause-choice stop-here` only relays a captured, unspent typed
# `stop the review here`; without one it refuses in plain words and writes nothing, in a session or not. The numbered
# answers and `fix-and-continue` are removed and `abandon` is retired: each is refused in plain words, and the typed
# `abandon this review campaign` records nothing and says to type `stop the review here` instead. Typed during implement
# with no stop open, `stop the review here` binds to the active campaign: no further round launches until an allowance
# reset reopens it, and what remains uncovered is named.

BeforeAll {
    $script:RepoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    . (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/_load.ps1')
    foreach ($dependency in @('HumanAuthorityStore', 'ConversationCaptureAccessor', 'ClassificationEngine', 'ProjectMetadataAccessor', 'HandoverStore')) {
        . (Join-Path $script:RepoRoot ('scripts/internal/bootstrap/' + $dependency + '.ps1'))
    }
    $script:CampaignId = Get-ReviewCampaignIdForIteration -FeatureId '001-fixture' -IterationNumber '001'
    $script:Utf8 = [Text.UTF8Encoding]::new($false)
    $script:SessionSignals = @(Get-SpecrewAgentSessionSignalNames)

    $script:CaptureRunner = Join-Path $TestDrive 'capture-runner.ps1'
    [IO.File]::WriteAllText($script:CaptureRunner, @'
param([string]$RepoRoot, [string]$Root, [string]$Text, [string]$HostKind)
$ErrorActionPreference = 'Stop'
foreach ($dependency in @('HumanAuthorityStore', 'ConversationCaptureAccessor', 'ClassificationEngine', 'ProjectMetadataAccessor', 'HandoverStore')) {
    . (Join-Path $RepoRoot ('scripts/internal/bootstrap/' + $dependency + '.ps1'))
}
Invoke-SpecrewTypedAuthorityCapture -ProjectRoot $Root -Response $Text -HostKind $HostKind -SourceEvent 'UserPromptSubmit' `
    -MessageId ('msg-' + [guid]::NewGuid().ToString('N').Substring(0, 8)) -SessionId 's1' -TurnOrigin 'typed-user' | Out-Null
'DISCLOSURE:' + [string](Get-SpecrewAuthorityNotRecordedDisclosure -ProjectRoot $Root -HostKind $HostKind -SessionId 's1')
'@, $script:Utf8)

    function script:Invoke-HereGit([string]$Root, [string[]]$Arguments) {
        $null = & git -C $Root -c user.name=t -c user.email=t@example.invalid @Arguments 2>&1
        if ($LASTEXITCODE -ne 0) { throw ('fixture-git-failed:' + ($Arguments -join ' ')) }
    }

    # A project on its feature branch, in the implement window, with a budget grant, one open finding (from a run that
    # brought back part of a review) and, unless -NoStop, an open stop (a) the engine wrote.
    function script:New-HereProject([string]$Name, [switch]$NoStop) {
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
        script:Invoke-HereGit $root @('init', '-q', '-b', '001-fixture')
        script:Invoke-HereGit $root @('add', '-A')
        script:Invoke-HereGit $root @('commit', '-qm', 'initial')
        $config = Join-Path $root 'authority.json'
        [IO.File]::WriteAllText($config, '{"schema_version":"1.0","mode":"campaign"}', $script:Utf8)
        $store = Join-Path $root '.specrew/review/authority'
        $resolution = [pscustomobject]@{ budget_total = 2; host_order = @(); host_order_stated = $false; infra_failure_cap = 2; budget_source = 'plan'; ceiling = 10; plan_path = 'specs/001-fixture/plan.md'; plan_hash = ('a' * 64) }
        $null = Add-ReviewCampaignBudgetGrantFact -StoreRoot $store -Fact (New-ReviewBudgetGrantFact -CampaignId $script:CampaignId -Resolution $resolution -VerdictEntry 'auth-here' -ObservedAt '2026-11-08T08:00:00.0000000+00:00')
        $partial = [pscustomobject][ordered]@{
            schema_version = '1.0'; campaign_id = $script:CampaignId; run_id = 'run-here-partial'; target_digest = ('a' * 40); harness_id = 'fixture'
            completion = 'partial'; verdict = 'incomplete'; runtime_outcome = 'timed-out'; termination_verified = $true; containment = 'verified'
            currentness = 'current'; validation = 'valid'; can_approve_current = $false; summary = 'half'
            findings = @([pscustomobject][ordered]@{ finding_id = 'finding-0123456789abcdef'; source_local_id = 'l1'; lineage_id = 'lin-0123456789abcdef'; severity = 'major'; title = 'Empty store'; description = 'Failure scenario: an empty store throws.'; location = 'src/app.ps1:1'; relevance = 'current'; resolution = 'open'; demoted = $false; demoted_from = '' })
            started_at = '2026-11-09T08:00:00Z'; ended_at = '2026-11-09T08:01:00Z'; duration_ms = 60000; examined_paths = @('src/app.ps1'); review_collected = $false
        }
        Request-ReviewAuthorityClaim -StoreRoot $store -CampaignId $script:CampaignId -RunId 'run-here-partial' -TargetLineage 'lin-001-fixture' -ObservedAt '2026-11-09T08:00:00Z' | Out-Null
        Publish-ReviewRunResultFact -StoreRoot $store -CampaignId $script:CampaignId -RunId 'run-here-partial' -Fact $partial | Out-Null
        Complete-ReviewAuthorityClaim -StoreRoot $store -CampaignId $script:CampaignId -RunId 'run-here-partial' -TargetLineage 'lin-001-fixture' -Disposition released -ObservedAt '2026-11-09T08:01:00Z' | Out-Null
        if (-not $NoStop) {
            $decision = Resolve-ReviewCampaignPauseDecision -Findings @() -RoundsUsed 2 -BudgetTotal 2
            $fact = New-ReviewCampaignPendingPauseFact -CampaignId $script:CampaignId -RunId 'run-here-stop-1' -TargetDigest ('a' * 40) -Decision $decision `
                -ObservedAt ([DateTimeOffset]::UtcNow.AddSeconds(-5).ToString('o')) -StopKind 'a-budget-spent' -StopReason 'budget-spent'
            $null = Write-ReviewCampaignPendingPauseFact -StoreRoot $store -Fact $fact
        }
        return [pscustomobject]@{ root = $root; store = $store; config = $config; external = ($root + '-ext') }
    }

    function script:Invoke-Typed([pscustomobject]$Project, [string]$Text) {
        $output = @(& pwsh -NoProfile -NonInteractive -File $script:CaptureRunner -RepoRoot $script:RepoRoot -Root $Project.root -Text $Text -HostKind 'claude' 2>&1 | ForEach-Object { [string]$_ })
        $disclosure = (@($output | Where-Object { $_ -like 'DISCLOSURE:*' }) | Select-Object -Last 1)
        return $(if ($disclosure) { $disclosure.Substring('DISCLOSURE:'.Length) } else { '' })
    }

    # The review command, in its own process with stdin closed, with the host session signals present or absent.
    function script:Invoke-HereCli([pscustomobject]$Project, [string[]]$Arguments, [switch]$InSession) {
        $saved = @{}
        foreach ($name in $script:SessionSignals) { $saved[$name] = [Environment]::GetEnvironmentVariable($name); [Environment]::SetEnvironmentVariable($name, $null) }
        if ($InSession) { [Environment]::SetEnvironmentVariable('CLAUDECODE', '1') }
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

    function script:Get-HereDecisionFacts([pscustomobject]$Project) {
        return @(Get-ReviewCampaignPauseRecords -StoreRoot $Project.store -CampaignId $script:CampaignId | Where-Object { $_.answered })
    }
}

Describe '--pause-choice stop-here only relays a captured, unspent typed line (FR-025)' {
    It '<Where>: with no captured stop the review here, it refuses in plain words and writes nothing' -ForEach @(
        @{ Where = 'in a session'; InSession = $true }
        @{ Where = 'outside a session'; InSession = $false }
    ) {
        $project = script:New-HereProject -Name ('relay-' + ($Where -replace '\s', '-'))
        $result = script:Invoke-HereCli -Project $project -InSession:$InSession -Arguments @('--live', '--feature', '001-fixture', '--iteration', '001', '--pause-choice', 'stop-here')
        $result.ExitCode | Should -Not -Be 0
        $result.Text | Should -Match 'stop the review here'
        $result.Text | Should -Match 'nothing was (recorded|written)'
        @(script:Get-HereDecisionFacts -Project $project).Count | Should -Be 0
        Get-ReviewCampaignFinalizationFact -StoreRoot $project.store -CampaignId $script:CampaignId | Should -BeNullOrEmpty
    }
}

Describe 'the numbered answers, fix-and-continue and abandon are gone, and say so (FR-010, FR-011)' {
    It '--pause-choice <Choice> is refused in plain words, naming stop the review here, and writes nothing' -ForEach @(
        @{ Choice = '1' }, @{ Choice = '2' }, @{ Choice = '3' }, @{ Choice = 'fix-and-continue' }, @{ Choice = 'abandon' }
    ) {
        $project = script:New-HereProject -Name ('retired-' + $Choice)
        $result = script:Invoke-HereCli -Project $project -Arguments @('--live', '--feature', '001-fixture', '--iteration', '001', '--pause-choice', $Choice)
        $result.ExitCode | Should -Not -Be 0
        $result.Text | Should -Match 'stop the review here'
        $result.Text | Should -Not -Match 'Cannot validate argument'
        @(script:Get-HereDecisionFacts -Project $project).Count | Should -Be 0
    }

    It 'the typed abandon this review campaign records nothing, and says to type stop the review here instead' {
        $project = script:New-HereProject -Name 'typed-abandon'
        $disclosure = script:Invoke-Typed -Project $project -Text 'abandon this review campaign'
        Test-Path -LiteralPath (Join-Path $project.root '.specrew/review/pause-decision/abandon.json') | Should -BeFalse
        $disclosure | Should -Match 'changed nothing'
        $disclosure | Should -Match 'stop the review here'
    }
}

Describe 'stop the review here with no stop open halts the loop for the active campaign (maintainer ruling 2026-11-09)' {
    It 'is recorded, bound to the active campaign; the next launch is refused, naming what remains uncovered; an allowance reset reopens it' {
        $project = script:New-HereProject -Name 'halt' -NoStop
        $null = script:Invoke-Typed -Project $project -Text 'stop the review here'
        $null = Invoke-ReviewCampaignStopAnswerLanding -ProjectRoot $project.root -StoreRoot $project.store -CampaignId $script:CampaignId
        $refused = Invoke-ReviewCampaignCommand -RepoRoot $project.root -FeatureId '001-fixture' -IterationNumber '001' -RunId 'run-here-after-halt' `
            -AuthorityConfigPath $project.config -Ports ([pscustomobject]@{ target = $null; harness = $null; runtime = $null; verification = $null; clock = (New-ReviewSystemClockPort); prompt_path = '' })
        $refused.invoked | Should -BeFalse
        [string]$refused.reason | Should -BeExactly 'review-stopped-here'
        [string]$refused.reason_detail | Should -Match 'finding-0123456789abcdef'
        Start-Sleep -Milliseconds 20
        $reset = [pscustomobject][ordered]@{
            schema_version = '1.0'; fact_type = 'round-budget-reset'; campaign_id = $script:CampaignId; reset_id = 'reset-here-0001'
            authority_kind = 'human'; authorized_by = 'maintainer'; reason = ''; observed_at = [DateTimeOffset]::UtcNow.ToString('o')
        }
        $null = Write-ReviewCampaignBudgetResetFact -StoreRoot $project.store -Fact $reset
        (Get-ReviewCampaignLoopState -StoreRoot $project.store -CampaignId $script:CampaignId).stopped_here | Should -BeFalse -Because 'the reset reopens the review'
    }
}
