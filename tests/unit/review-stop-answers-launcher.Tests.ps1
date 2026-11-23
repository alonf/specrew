# Feature 203 iteration 002, round 4's stop (the maintainer's "land it with a preloaded launch, fix the loader in 203",
# 2026-11-23 22:52 local): THE TYPED STOP LINES LAND THROUGH THE REAL LAUNCHER. The maintainer's typed
# `defer finding finding-9cc1155f2c83f5f7 to bug bash 2` was captured bound to the open stop, and the next plain
# `specrew review --live` did not apply it and said nothing: the landing returned an empty result when the store's reader
# was not loaded, and the launcher's live path never loaded it. Every case in review-stop-answers.Tests.ps1 called the
# landing in a process that had already loaded the store, so none of them could see it (DRIFT-055's lesson: a path is
# proven through its real entry point).
#
# R1: the real scripts/specrew-review.ps1 --live in a child process, with nothing preloaded, lands the typed line.
# R2: a store that cannot be loaded is a named warning and a plain-words line, never silence.
# R3: the stop text says when a typed line is waiting for the next launch, or was recorded but not applied.

BeforeAll {
    $script:RepoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    . (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/_load.ps1')
    foreach ($dependency in @('HumanAuthorityStore', 'ConversationCaptureAccessor', 'ClassificationEngine', 'ProjectMetadataAccessor', 'HandoverStore')) {
        . (Join-Path $script:RepoRoot ('scripts/internal/bootstrap/' + $dependency + '.ps1'))
    }
    . (Join-Path $script:RepoRoot 'tests/support/cited-typed-turn.ps1')
    $script:CampaignId = Get-ReviewCampaignIdForIteration -FeatureId '001-fixture' -IterationNumber '001'
    $script:Utf8 = [Text.UTF8Encoding]::new($false)
    $script:SessionSignals = @(Get-SpecrewAgentSessionSignalNames)
    $script:FindingA = 'finding-0123456789abcdef'
    $script:FindingB = 'finding-fedcba9876543210'

    $script:CaptureRunner = Join-Path $TestDrive 'capture-runner.ps1'
    [IO.File]::WriteAllText($script:CaptureRunner, @'
param([string]$RepoRoot, [string]$Root, [string]$Text, [string]$HostKind, [string]$MessageId, [string]$TranscriptPath)
$ErrorActionPreference = 'Stop'
foreach ($dependency in @('HumanAuthorityStore', 'ConversationCaptureAccessor', 'ClassificationEngine', 'ProjectMetadataAccessor', 'HandoverStore')) {
    . (Join-Path $RepoRoot ('scripts/internal/bootstrap/' + $dependency + '.ps1'))
}
Invoke-SpecrewTypedAuthorityCapture -ProjectRoot $Root -Response $Text -HostKind $HostKind -SourceEvent 'UserPromptSubmit' `
    -MessageId $MessageId -SessionId 's1' -TurnOrigin 'typed-user' -TranscriptPath $TranscriptPath | Out-Null
'@, $script:Utf8)

    function script:Invoke-LauncherGit([string]$Root, [string[]]$Arguments) {
        $null = & git -C $Root -c user.name=t -c user.email=t@example.invalid @Arguments 2>&1
        if ($LASTEXITCODE -ne 0) { throw ('fixture-git-failed:' + ($Arguments -join ' ')) }
    }

    function script:New-LauncherFinding([string]$Id, [string]$Title) {
        return [pscustomobject][ordered]@{ finding_id = $Id; source_local_id = 'l-' + $Id.Substring(8, 4); lineage_id = 'lin-' + $Id.Substring(8); severity = 'major'; title = $Title; description = 'Failure scenario: it breaks.'; location = 'src/app.ps1:1'; relevance = 'current'; resolution = 'open'; demoted = $false; demoted_from = '' }
    }

    # A project on its feature branch in the implement window, with a budget grant, two open findings and an open stop (a)
    # the engine wrote. -WithStopD adds a later stop (d) naming copilot, so stop (a) is still open once (d) is answered.
    function script:New-LauncherProject([string]$Name, [switch]$WithStopD, [switch]$NoStop) {
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
        script:Invoke-LauncherGit $root @('init', '-q', '-b', '001-fixture')
        script:Invoke-LauncherGit $root @('add', '-A')
        script:Invoke-LauncherGit $root @('commit', '-qm', 'initial')
        $store = Join-Path $root '.specrew/review/authority'
        $resolution = [pscustomobject]@{ budget_total = 2; host_order = @(); host_order_stated = $false; infra_failure_cap = 2; budget_source = 'plan'; ceiling = 10; plan_path = 'specs/001-fixture/plan.md'; plan_hash = ('a' * 64) }
        $null = Add-ReviewCampaignBudgetGrantFact -StoreRoot $store -Fact (New-ReviewBudgetGrantFact -CampaignId $script:CampaignId -Resolution $resolution -VerdictEntry 'auth-0123456789abcdef' -ObservedAt '2026-11-08T08:00:00.0000000+00:00')
        $partial = [pscustomobject][ordered]@{
            schema_version = '1.0'; campaign_id = $script:CampaignId; run_id = 'run-launcher-partial'; target_digest = ('a' * 40); harness_id = 'fixture'
            completion = 'partial'; verdict = 'incomplete'; runtime_outcome = 'timed-out'; termination_verified = $true; containment = 'verified'
            currentness = 'current'; validation = 'valid'; can_approve_current = $false; summary = 'half'
            findings = @((script:New-LauncherFinding -Id $script:FindingA -Title 'Empty store'), (script:New-LauncherFinding -Id $script:FindingB -Title 'Retry never backs off'))
            started_at = '2026-11-09T08:00:00Z'; ended_at = '2026-11-09T08:01:00Z'; duration_ms = 60000; examined_paths = @('src/app.ps1'); review_collected = $false
        }
        Request-ReviewAuthorityClaim -StoreRoot $store -CampaignId $script:CampaignId -RunId 'run-launcher-partial' -TargetLineage 'lin-001-fixture' -ObservedAt '2026-11-09T08:00:00Z' | Out-Null
        Publish-ReviewRunResultFact -StoreRoot $store -CampaignId $script:CampaignId -RunId 'run-launcher-partial' -Fact $partial | Out-Null
        Complete-ReviewAuthorityClaim -StoreRoot $store -CampaignId $script:CampaignId -RunId 'run-launcher-partial' -TargetLineage 'lin-001-fixture' -Disposition released -ObservedAt '2026-11-09T08:01:00Z' | Out-Null
        $decision = Resolve-ReviewCampaignPauseDecision -Findings @() -RoundsUsed 2 -BudgetTotal 2
        $stopA = New-ReviewCampaignPendingPauseFact -CampaignId $script:CampaignId -RunId 'run-launcher-stop-a' -TargetDigest ('a' * 40) -Decision $decision `
            -ObservedAt ([DateTimeOffset]::UtcNow.AddSeconds(-10).ToString('o')) -StopKind 'a-budget-spent' -StopReason 'budget-spent'
        if (-not $NoStop) { $null = Write-ReviewCampaignPendingPauseFact -StoreRoot $store -Fact $stopA }
        if ($WithStopD) {
            $stopD = New-ReviewCampaignPendingPauseFact -CampaignId $script:CampaignId -RunId 'run-launcher-stop-d' -TargetDigest ('a' * 40) -Decision $decision `
                -ObservedAt ([DateTimeOffset]::UtcNow.AddSeconds(-5).ToString('o')) -StopKind 'd-host-outside-order' -StopReason 'host-order-exhausted' -NextHost 'copilot'
            $null = Write-ReviewCampaignPendingPauseFact -StoreRoot $store -Fact $stopD
        }
        return [pscustomobject]@{ root = $root; store = $store }
    }

    # The typed line as the host and the prompt hook leave it (T013, B5F-066): Claude's transcript record of the typed
    # message, and the hook's capture given that message's id and transcript, in its own process as the hooks run it.
    function script:Invoke-LauncherTyped([pscustomobject]$Project, [string]$Text) {
        $record = Add-SpecrewTestTypedTranscriptRecord -Text $Text -MessageId ('msg-' + [guid]::NewGuid().ToString('N').Substring(0, 8))
        $null = & pwsh -NoProfile -NonInteractive -File $script:CaptureRunner -RepoRoot $script:RepoRoot -Root $Project.root -Text $Text -HostKind 'claude' `
            -MessageId $record.MessageId -TranscriptPath $record.TranscriptPath 2>&1
    }

    function script:Get-LauncherCaptures([pscustomobject]$Project) {
        $root = Join-Path $Project.root '.specrew/review/stop-answer'
        if (-not (Test-Path -LiteralPath $root)) { return @() }
        return @(Get-ChildItem -LiteralPath $root -Recurse -File -Filter '*.json' | ForEach-Object { Get-Content -LiteralPath $_.FullName -Raw | ConvertFrom-Json })
    }

    # The real review command, `--live --host codex`, in its own process with stdin closed, no session signals and a home
    # folder of its own. Nothing is loaded into it beforehand. -EngineRoot runs a copied engine instead of this checkout's.
    # A stub codex comes first on its PATH, so the host check passes on a machine with no codex (CI) and no real reviewer can
    # start; a launch that runs it fails the case.
    function script:Invoke-LauncherCli([pscustomobject]$Project, [string]$EngineRoot = $script:RepoRoot) {
        $saved = @{}
        $names = @($script:SessionSignals) + @('HOME', 'USERPROFILE', 'PATH')
        foreach ($name in $names) { $saved[$name] = [Environment]::GetEnvironmentVariable($name) }
        foreach ($name in $script:SessionSignals) { [Environment]::SetEnvironmentVariable($name, $null) }
        $fixtureHome = Join-Path $TestDrive ('home-' + [guid]::NewGuid().ToString('N').Substring(0, 8))
        New-Item -ItemType Directory -Path $fixtureHome -Force | Out-Null
        [Environment]::SetEnvironmentVariable('HOME', $fixtureHome)
        [Environment]::SetEnvironmentVariable('USERPROFILE', $fixtureHome)
        $stubDir = Join-Path $fixtureHome 'stub-bin'
        New-Item -ItemType Directory -Path $stubDir -Force | Out-Null
        $marker = Join-Path $fixtureHome 'reviewer-started.txt'
        if ($IsWindows) { [IO.File]::WriteAllLines((Join-Path $stubDir 'codex.cmd'), [string[]]@(('@echo started>> "{0}"' -f $marker), '@exit /b 3'), $script:Utf8) }
        else {
            $stub = Join-Path $stubDir 'codex'
            [IO.File]::WriteAllText($stub, (@('#!/bin/sh', ("echo started >> '{0}'" -f $marker), 'exit 3', '') -join "`n"), $script:Utf8)
            $null = & chmod +x $stub
        }
        [Environment]::SetEnvironmentVariable('PATH', ($stubDir + [IO.Path]::PathSeparator + $saved['PATH']))
        try {
            $out = Join-Path $TestDrive ('cli-' + [guid]::NewGuid().ToString('N'))
            [IO.File]::WriteAllText("$out.in", '')
            $argumentList = @('-NoProfile', '-NonInteractive', '-File', (Join-Path $EngineRoot 'scripts/specrew-review.ps1'), '-ProjectPath', $Project.root, '--live', '--host', 'codex')
            $process = Start-Process -FilePath 'pwsh' -ArgumentList $argumentList -RedirectStandardInput "$out.in" -RedirectStandardOutput "$out.out" -RedirectStandardError "$out.err" -NoNewWindow -PassThru -Wait
            $stdout = [string](Get-Content -LiteralPath "$out.out" -Raw -ErrorAction SilentlyContinue)
            $stderr = [string](Get-Content -LiteralPath "$out.err" -Raw -ErrorAction SilentlyContinue)
            if (Test-Path -LiteralPath $marker) { throw 'the launch started a reviewer' }
            $flat = { param([string]$t) ((($t -replace "`e\[[0-9;]*m", '') -replace '\s*\|\s+', ' ') -replace '\s+', ' ') }
            return [pscustomobject]@{ ExitCode = $process.ExitCode; Out = (& $flat $stdout); Err = (& $flat $stderr); Text = (& $flat ($stdout + ' ' + $stderr)) }
        }
        finally { foreach ($name in $names) { [Environment]::SetEnvironmentVariable($name, $saved[$name]) } }
    }
}

Describe 'R1: a typed stop line lands through the real launcher, with nothing preloaded (203 iteration 002, round 4''s stop)' {
    It '<Line>: recorded as the campaign''s fact, the capture spent, the launch says so, and stop (a) still refuses with nothing spent' -ForEach @(
        @{ Line = 'defer finding finding-0123456789abcdef to B5F-099'; Answer = 'defer'; Argument = 'B5F-099' }
        @{ Line = 'drop finding finding-0123456789abcdef'; Answer = 'drop'; Argument = '' }
    ) {
        $project = script:New-LauncherProject -Name ('r1-' + $Answer)
        script:Invoke-LauncherTyped -Project $project -Text $Line
        @(script:Get-LauncherCaptures -Project $project).Count | Should -Be 1 -Because 'the hook captured the line bound to the open stop'
        $run = script:Invoke-LauncherCli -Project $project
        $dispositions = @((Get-ReviewCampaignFindingDispositions -StoreRoot $project.store -CampaignId $script:CampaignId).Values)
        $dispositions.Count | Should -Be 1 -Because 'the typed line lands as the finding''s disposition'
        [string]$dispositions[0].answer | Should -BeExactly $Answer
        [string](Get-ReviewAuthorityProperty -Object $dispositions[0] -Name 'argument') | Should -BeExactly $Argument
        [string]$dispositions[0].finding_key | Should -BeExactly $script:FindingA
        $capture = @(script:Get-LauncherCaptures -Project $project)[0]
        [string]$capture.spent_at | Should -Not -BeNullOrEmpty -Because 'a landed line is spent once'
        [string]$capture.authorization_ref | Should -Match '^typed-stop-answer:'
        $run.Out | Should -Match ([regex]::Escape('Your answer to the review stop was recorded: ' + $Line))
        $run.Text | Should -Match 'review-stop-open:a-budget-spent' -Because 'one finding is still open, so stop (a) still refuses, with nothing spent'
        $run.Out | Should -Match '1 finding open' -Because 'the stop text lists one finding fewer'
        $run.Out | Should -Not -Match ('- ' + [regex]::Escape($script:FindingA) + ' \(major\)') -Because 'the answered finding is no longer listed as open'
        $run.Out | Should -Match ('- ' + [regex]::Escape($script:FindingB) + ' \(major\)')
        @(Get-ReviewCampaignOpenFindings -StoreRoot $project.store -CampaignId $script:CampaignId).Count | Should -Be 1
    }

    It 'allow reviewer copilot: recorded as the allowed reviewer, closing stop (d); stop (a) still refuses' {
        $project = script:New-LauncherProject -Name 'r1-allow' -WithStopD
        script:Invoke-LauncherTyped -Project $project -Text 'allow reviewer copilot'
        @(script:Get-LauncherCaptures -Project $project).Count | Should -Be 1
        $run = script:Invoke-LauncherCli -Project $project
        @(Get-ReviewCampaignAllowedReviewers -StoreRoot $project.store -CampaignId $script:CampaignId) | Should -Contain 'copilot'
        [string](@(script:Get-LauncherCaptures -Project $project)[0].spent_at) | Should -Not -BeNullOrEmpty
        $run.Out | Should -Match ([regex]::Escape('Your answer to the review stop was recorded: allow reviewer copilot'))
        $run.Text | Should -Match 'review-stop-open:a-budget-spent'
    }
}

Describe 'R2: a store that cannot be loaded is named, never silent' {
    It 'with the store unloadable in a copied engine, the launch names the failure and says the typed line was not applied' {
        $engine = Join-Path $TestDrive 'engine-copy'
        New-Item -ItemType Directory -Path (Join-Path $engine 'extensions/specrew-speckit') -Force | Out-Null
        Copy-Item -LiteralPath (Join-Path $script:RepoRoot 'scripts') -Destination $engine -Recurse
        Copy-Item -LiteralPath (Join-Path $script:RepoRoot 'extensions/specrew-speckit/scripts') -Destination (Join-Path $engine 'extensions/specrew-speckit') -Recurse
        [IO.File]::WriteAllText((Join-Path $engine 'scripts/internal/bootstrap/HumanAuthorityStore.ps1'), "throw 'fixture: this copy of the store cannot be loaded'`n", $script:Utf8)
        $project = script:New-LauncherProject -Name 'r2-unloadable'
        script:Invoke-LauncherTyped -Project $project -Text 'defer finding finding-0123456789abcdef to B5F-099'
        $run = script:Invoke-LauncherCli -Project $project -EngineRoot $engine
        $run.Err | Should -Match 'STOP_ANSWER_LANDING_FAILED stop-answer-reader-unavailable'
        $run.Out | Should -Match 'could not read the lines you typed at the review stop'
        [string](@(script:Get-LauncherCaptures -Project $project)[0].spent_at) | Should -BeNullOrEmpty -Because 'a line that was not applied stays for the next launch'
        @((Get-ReviewCampaignFindingDispositions -StoreRoot $project.store -CampaignId $script:CampaignId).Values).Count | Should -Be 0
    }
}

Describe 'R3: the stop text names a typed line that waits, or was recorded but not applied' {
    It 'before the next launch, the stop text says the typed line is recorded and is applied at the next review launch' {
        $project = script:New-LauncherProject -Name 'r3-waiting'
        script:Invoke-LauncherTyped -Project $project -Text 'defer finding finding-0123456789abcdef to B5F-099'
        $stop = Get-ReviewCampaignOpenStop -StoreRoot $project.store -CampaignId $script:CampaignId
        $open = @(Get-ReviewCampaignOpenFindings -StoreRoot $project.store -CampaignId $script:CampaignId)
        $lines = @(Get-ReviewCampaignStopStoredAnswerLines -ProjectRoot $project.root -StoreRoot $project.store -CampaignId $script:CampaignId -Stop $stop -OpenFindings $open)
        $text = (@(Format-ReviewCampaignStopSurface -Stop $stop -OpenFindings $open -StoredAnswerLines $lines) -join "`n")
        $text | Should -Match ([regex]::Escape('Your line "defer finding finding-0123456789abcdef to B5F-099" is recorded and is applied at the next review launch.'))
    }

    It 'the navigator''s stop block, which the hook shows, names the waiting line (203 iteration 002, round 4''s stop)' {
        # The stop text the human reads between launches comes from the navigator, not from the launcher's refusal.
        $project = script:New-LauncherProject -Name 'r3-navigator'
        script:Invoke-LauncherTyped -Project $project -Text 'defer finding finding-0123456789abcdef to B5F-099'
        . (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/continuous-co-review-navigator.ps1')
        . (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/worktree-navigator.ps1')
        New-Item -ItemType Directory -Path (Join-Path $project.root '.specify') -Force | Out-Null
        [IO.File]::WriteAllText((Join-Path $project.root '.specify/feature.json'), '{ "feature_directory": "specs/001-fixture" }', $script:Utf8)
        Mock -CommandName Get-ContinuousCoReviewAuthorityDecision -MockWith {
            [pscustomobject]@{ mode = 'campaign'; valid = $true; legacy_promotion_enabled = $false; campaign_authority_enabled = $true; reason = 'authority-mode-campaign' }
        }
        Mock -CommandName Get-ReviewCampaignVerdictPacketDecision -MockWith { throw 'packet-gate-must-not-run' }
        $decision = Invoke-ContinuousCoReviewWorktreeNavigator -RepoRoot $project.root
        $decision.reason | Should -Be 'review-stop-open:a-budget-spent'
        $decision.stop_block | Should -Match ([regex]::Escape('Your line "defer finding finding-0123456789abcdef to B5F-099" is recorded and is applied at the next review launch.'))
    }
    It 'after a launch, a line that could not be applied is named in the refusal, with its reason' {
        $project = script:New-LauncherProject -Name 'r3-not-applied'
        script:Invoke-LauncherTyped -Project $project -Text 'drop finding finding-00000000000000ff'
        $run = script:Invoke-LauncherCli -Project $project
        $run.Out | Should -Match ([regex]::Escape('Your line "drop finding finding-00000000000000ff" was recorded but is not applied: the finding it names is not open.'))
        $run.Text | Should -Match 'review-stop-open:a-budget-spent'
    }
}

Describe 'R4: a typed `stop the review here` with no stop open halts the review through the real launcher (maintainer ruling 2026-11-09)' {
    It 'is recorded and spent, and the launch is refused naming what remains uncovered; no reviewer starts' {
        # The in-process twin is in review-stop-here.Tests.ps1. Since the landing loads its own store (203 iteration 002,
        # fix 4) a plain launch reaches the halt landing, which before was dead on the real path: the same loader gap.
        $project = script:New-LauncherProject -Name 'r4-halt' -NoStop
        script:Invoke-LauncherTyped -Project $project -Text 'stop the review here'
        $captured = Join-Path $project.root '.specrew/review/pause-decision/stop-here.json'
        Test-Path -LiteralPath $captured | Should -BeTrue -Because 'the hook captured the typed line with no stop open'
        [string](Get-Content -LiteralPath $captured -Raw | ConvertFrom-Json).run_id | Should -BeNullOrEmpty -Because 'it is bound to no run'
        $run = script:Invoke-LauncherCli -Project $project
        [string](Get-Content -LiteralPath $captured -Raw | ConvertFrom-Json).spent_at | Should -Not -BeNullOrEmpty -Because 'the halt landing spends the capture'
        $run.Text | Should -Match 'review-stopped-here'
        $run.Text | Should -Match ([regex]::Escape($script:FindingA))
        (Get-ReviewCampaignLoopState -StoreRoot $project.store -CampaignId $script:CampaignId).stopped_here | Should -BeTrue
    }
}
