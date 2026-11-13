# Feature 203 T008 step (iii) (FR-006, FR-011; DRIFT-052 item 5): the human's typed stop lines reach the fact writers.
# The hook captures the line from the typed turn (T004's writer, in its own process, as the hooks run it) bound to the
# open stop; the next review launch lands it as the campaign fact: `allow reviewer <host>` as the allowed-reviewer fact
# that closes stop (d), `defer finding <id> to <destination>` and `drop finding <id>` as the finding's disposition, and
# free text at stop (c) as that stop's answer. A landed line is spent once.

BeforeAll {
    $script:RepoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    . (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/_load.ps1')
    foreach ($dependency in @('HumanAuthorityStore', 'ConversationCaptureAccessor', 'ClassificationEngine', 'ProjectMetadataAccessor', 'HandoverStore')) {
        . (Join-Path $script:RepoRoot ('scripts/internal/bootstrap/' + $dependency + '.ps1'))
    }
    . (Join-Path $script:RepoRoot 'tests/support/cited-typed-turn.ps1')
    $script:CampaignId = Get-ReviewCampaignIdForIteration -FeatureId '001-fixture' -IterationNumber '001'
    $script:Utf8 = [Text.UTF8Encoding]::new($false)

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

    # A project on its feature branch with one open stop of $Kind, written by the engine's own fact writer.
    function script:New-AnswerProject([string]$Name, [string]$Kind, [string]$NextHost = '', [string]$Reason = '') {
        $root = Join-Path $TestDrive $Name
        New-Item -ItemType Directory -Path (Join-Path $root '.specrew'), (Join-Path $root 'specs/001-fixture/iterations/001') -Force | Out-Null
        Set-Content -LiteralPath (Join-Path $root '.specrew/config.yml') -Value "specrew_version: `"0.40.0`"`nbootstrap_mode: `"fixture`"" -Encoding UTF8
        $null = & git init -q -b 001-fixture $root 2>&1
        $store = Join-Path $root '.specrew/review/authority'
        $decision = Resolve-ReviewCampaignPauseDecision -Findings @() -RoundsUsed 2 -BudgetTotal 2
        $fact = New-ReviewCampaignPendingPauseFact -CampaignId $script:CampaignId -RunId 'run-answer-stop-1' -TargetDigest ('a' * 40) -Decision $decision `
            -ObservedAt ([DateTimeOffset]::UtcNow.AddSeconds(-5).ToString('o')) -StopKind $Kind -StopReason $Reason -NextHost $NextHost
        $null = Write-ReviewCampaignPendingPauseFact -StoreRoot $store -Fact $fact
        return [pscustomobject]@{ root = $root; store = $store }
    }

    # One open finding, from a run that brought back only part of a review.
    function script:Add-AnswerOpenFinding([pscustomobject]$Project) {
        $result = [pscustomobject][ordered]@{
            schema_version = '1.0'; campaign_id = $script:CampaignId; run_id = 'run-answer-partial'; target_digest = ('a' * 40); harness_id = 'fixture'
            completion = 'partial'; verdict = 'incomplete'; runtime_outcome = 'timed-out'; termination_verified = $true; containment = 'verified'
            currentness = 'current'; validation = 'valid'; can_approve_current = $false; summary = 'half'
            findings = @([pscustomobject][ordered]@{ finding_id = 'finding-0123456789abcdef'; source_local_id = 'l1'; lineage_id = 'lin-0123456789abcdef'; severity = 'major'; title = 'Empty store'; description = 'Failure scenario: an empty store throws.'; location = 'src/app.ps1:1'; relevance = 'current'; resolution = 'open'; demoted = $false; demoted_from = '' })
            started_at = '2026-11-09T08:00:00Z'; ended_at = '2026-11-09T08:01:00Z'; duration_ms = 60000; examined_paths = @('src/app.ps1'); review_collected = $false
        }
        Request-ReviewAuthorityClaim -StoreRoot $Project.store -CampaignId $script:CampaignId -RunId 'run-answer-partial' -TargetLineage 'lin-001-fixture' -ObservedAt '2026-11-09T08:00:00Z' | Out-Null
        Publish-ReviewRunResultFact -StoreRoot $Project.store -CampaignId $script:CampaignId -RunId 'run-answer-partial' -Fact $result | Out-Null
        Complete-ReviewAuthorityClaim -StoreRoot $Project.store -CampaignId $script:CampaignId -RunId 'run-answer-partial' -TargetLineage 'lin-001-fixture' -Disposition released -ObservedAt '2026-11-09T08:01:00Z' | Out-Null
    }

    # Feature 203 T013 (B5F-066): the typed line as the host and the prompt hook leave it - Claude's transcript record of the
    # typed message, and the hook's capture given that message's id and transcript, so the line is used when it lands.
    function script:Invoke-Typed([pscustomobject]$Project, [string]$Text) {
        $record = Add-SpecrewTestTypedTranscriptRecord -Text $Text -MessageId ('msg-' + [guid]::NewGuid().ToString('N').Substring(0, 8))
        $null = & pwsh -NoProfile -NonInteractive -File $script:CaptureRunner -RepoRoot $script:RepoRoot -Root $Project.root -Text $Text -HostKind 'claude' `
            -MessageId $record.MessageId -TranscriptPath $record.TranscriptPath 2>&1
    }

    # What the review command does before a launch: land the typed lines bound to the open stop.
    function script:Invoke-Landing([pscustomobject]$Project) {
        return Invoke-ReviewCampaignStopAnswerLanding -ProjectRoot $Project.root -StoreRoot $Project.store -CampaignId $script:CampaignId
    }
}

Describe 'the typed stop lines reach the fact writers (FR-006, FR-011)' {
    It 'allow reviewer: the hook captures it bound to stop (d), and the next launch records the reviewer, closing the stop' {
        $project = script:New-AnswerProject -Name 'allow' -Kind 'd-host-outside-order' -NextHost 'copilot' -Reason 'host-order-exhausted'
        script:Invoke-Typed -Project $project -Text 'allow reviewer copilot'
        $landed = script:Invoke-Landing -Project $project
        @($landed.landed).Count | Should -Be 1
        @(Get-ReviewCampaignAllowedReviewers -StoreRoot $project.store -CampaignId $script:CampaignId) | Should -Contain 'copilot'
        Get-ReviewCampaignOpenStop -StoreRoot $project.store -CampaignId $script:CampaignId | Should -BeNullOrEmpty
        @((script:Invoke-Landing -Project $project).landed).Count | Should -Be 0 -Because 'a landed line is spent once'
    }

    It 'drop finding: closes the open finding at stop (a), and with nothing left open the stop closes' {
        $project = script:New-AnswerProject -Name 'drop' -Kind 'a-budget-spent' -Reason 'budget-spent'
        script:Add-AnswerOpenFinding -Project $project
        script:Invoke-Typed -Project $project -Text 'drop finding finding-0123456789abcdef'
        $null = script:Invoke-Landing -Project $project
        @(Get-ReviewCampaignOpenFindings -StoreRoot $project.store -CampaignId $script:CampaignId).Count | Should -Be 0
        Get-ReviewCampaignOpenStop -StoreRoot $project.store -CampaignId $script:CampaignId | Should -BeNullOrEmpty
    }

    It 'defer finding with a destination: recorded with it, and the finding closes' {
        $project = script:New-AnswerProject -Name 'defer' -Kind 'a-budget-spent' -Reason 'budget-spent'
        script:Add-AnswerOpenFinding -Project $project
        script:Invoke-Typed -Project $project -Text 'defer finding finding-0123456789abcdef to B5F-099'
        $null = script:Invoke-Landing -Project $project
        $disposition = (Get-ReviewCampaignFindingDispositions -StoreRoot $project.store -CampaignId $script:CampaignId).Values | Select-Object -First 1
        [string]$disposition.answer | Should -BeExactly 'defer'
        [string]$disposition.argument | Should -BeExactly 'B5F-099'
        @(Get-ReviewCampaignOpenFindings -StoreRoot $project.store -CampaignId $script:CampaignId).Count | Should -Be 0
    }

    It 'free text at stop (c) is its answer: the stop closes' {
        $project = script:New-AnswerProject -Name 'judgment' -Kind 'c-judgment' -Reason 'containment-violated'
        script:Invoke-Typed -Project $project -Text 'Run it again on copilot and tell me if it writes again.'
        $null = script:Invoke-Landing -Project $project
        Get-ReviewCampaignOpenStop -StoreRoot $project.store -CampaignId $script:CampaignId | Should -BeNullOrEmpty
    }

    # Iteration review round A finding 2 (run-20261113-102531165-8671e9be; FR-021): two lines for one finding before the next
    # launch - the newest is the human's instruction. The older is not applied; it is stamped superseded, naming the newer.
    It 'the newest line for a finding wins: drop, then fix, lands fix and records the drop as superseded' {
        $project = script:New-AnswerProject -Name 'supersede' -Kind 'a-budget-spent' -Reason 'budget-spent'
        script:Add-AnswerOpenFinding -Project $project
        script:Invoke-Typed -Project $project -Text 'drop finding finding-0123456789abcdef'
        Start-Sleep -Milliseconds 20
        script:Invoke-Typed -Project $project -Text 'fix finding finding-0123456789abcdef'
        $result = script:Invoke-Landing -Project $project
        $disposition = (Get-ReviewCampaignFindingDispositions -StoreRoot $project.store -CampaignId $script:CampaignId).Values | Select-Object -First 1
        [string]$disposition.answer | Should -BeExactly 'fix' -Because 'the human typed fix after drop'
        @($result.landed).Count | Should -Be 1
        @($result.skipped | Where-Object { [string]$_.reason -ceq 'superseded-by-newer-answer' }).Count | Should -Be 1
        $drop = Get-ChildItem -LiteralPath (Join-Path $project.root '.specrew/review/stop-answer/run-answer-stop-1') -Filter 'drop-*.json' | Select-Object -First 1 | Get-Content -Raw | ConvertFrom-Json
        [string]$drop.spent_at | Should -Not -BeNullOrEmpty -Because 'a superseded line is spent, so it cannot land later'
        [string]$drop.authorization_ref | Should -BeLike 'superseded-by:typed-stop-answer:*'
    }

    # Iteration review round A finding 2, second defect: the capture returned the earlier record for the same text whatever
    # it was, so a line first sent by a scheduled prompt (refused when used) could never be typed again by the human.
    It 'a line refused because a scheduled prompt sent it is recorded again when the human types it, and lands' {
        $project = script:New-AnswerProject -Name 'retype' -Kind 'a-budget-spent' -Reason 'budget-spent'
        script:Add-AnswerOpenFinding -Project $project
        $text = 'drop finding finding-0123456789abcdef'
        $shapes = @((Get-Content -LiteralPath (Join-Path $script:RepoRoot 'tests/fixtures/hook-payloads/claude/transcript-origins/record-shapes.json') -Raw | ConvertFrom-Json).shapes)
        $scheduled = $shapes | Where-Object kind -eq 'scheduled'
        $transcript = Join-Path $TestDrive ('scheduled-' + [guid]::NewGuid().ToString('N').Substring(0, 6) + '.jsonl')
        $messageId = 'msg-' + [guid]::NewGuid().ToString('N').Substring(0, 8)
        $record = [ordered]@{ type = 'user'; uuid = [guid]::NewGuid().ToString(); promptId = $messageId; sessionId = 's1'; timestamp = '2026-11-13T09:00:00.000Z'; message = [ordered]@{ role = 'user'; content = $text } }
        if ($scheduled.turnOrigin) { $record.turnOrigin = [string]$scheduled.turnOrigin }
        if ($scheduled.promptSource) { $record.promptSource = [string]$scheduled.promptSource }
        if ($scheduled.isMeta -eq $true) { $record.isMeta = $true }
        if ($scheduled.origin_kind) { $record.origin = [ordered]@{ kind = [string]$scheduled.origin_kind } }
        [IO.File]::WriteAllText($transcript, (($record | ConvertTo-Json -Depth 6 -Compress) + "`n"), $script:Utf8)
        $null = & pwsh -NoProfile -NonInteractive -File $script:CaptureRunner -RepoRoot $script:RepoRoot -Root $project.root -Text $text -HostKind 'claude' -MessageId $messageId -TranscriptPath $transcript 2>&1
        @((script:Invoke-Landing -Project $project).landed).Count | Should -Be 0 -Because 'the scheduled prompt''s line is refused when used'
        script:Invoke-Typed -Project $project -Text $text
        @((script:Invoke-Landing -Project $project).landed).Count | Should -Be 1 -Because 'the human typed the same line, from a new turn'
        @(Get-ReviewCampaignOpenFindings -StoreRoot $project.store -CampaignId $script:CampaignId).Count | Should -Be 0
    }

    It 'a line typed with no stop open records nothing' {
        $project = script:New-AnswerProject -Name 'none' -Kind 'd-host-outside-order' -NextHost 'copilot' -Reason 'host-order-exhausted'
        $null = Add-ReviewCampaignAllowedReviewerFact -StoreRoot $project.store -CampaignId $script:CampaignId -HostName 'codex' -AuthorizationRef 'typed' -ObservedAt ([DateTimeOffset]::UtcNow.ToString('o'))
        script:Invoke-Typed -Project $project -Text 'allow reviewer copilot'
        Test-Path -LiteralPath (Join-Path $project.root '.specrew/review/stop-answer') | Should -BeFalse
    }
}
