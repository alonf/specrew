# Feature 203 iteration 001, T003 (FR-014 to FR-023; DA-1 option B, DA-2, DA-3): one classifier, one act per typed turn.
#
# Resolve-SpecrewTypedAct takes a turn record and the pending state and returns exactly one act, or none with a reason
# and whether the human must be told. Every case below is a turn this project met, built from a recorded fixture where
# one exists:
#   - a queued typed approval counts as typed (DRIFT-006, DRIFT-012). Claude hands a queued message's prompt hook the
#     RUNNING turn's prompt_id (tests/fixtures/hook-payloads/claude/queued); keyed on that id alone it was the previous
#     turn, already recorded, and it was dropped without a word;
#   - a compaction summary quoting "approved for review round" is not a typed turn (research.md R4;
#     tests/fixtures/hook-payloads/claude/compaction);
#   - a pasted transcript that begins with the phrase is not typed (DRIFT-023, the 14:39 paste;
#     tests/fixtures/hook-payloads/claude/pasted-transcript);
#   - quoted, backticked and multi-line phrases, non-approval phrases, a verdict for another boundary, and
#     "approved for review round" never read as a verdict for the 'review' boundary (B4F-116/150).
#
# Kept out on purpose: a re-typed approval dropped while an older one is unspent (02:44 and 14:45 local, 2026-11-02) is
# T004's supersession case (FR-021), and the notice the human gets for it is T006's.
#
# RED before T003: Resolve-SpecrewTypedAct and Get-SpecrewTypedActIdentity do not exist.
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$fixtures = Join-Path $repoRoot 'tests\fixtures\hook-payloads'
. (Join-Path $repoRoot 'scripts\internal\bootstrap\HumanAuthorityStore.ps1')
. (Join-Path $repoRoot 'scripts\internal\bootstrap\ConversationCaptureAccessor.ps1')
$script:failCount = 0
function Write-Pass { param([string]$Message) Write-Host "PASS: $Message" -ForegroundColor Green }
function Write-Fail { param([string]$Message) Write-Host "FAIL: $Message" -ForegroundColor Red; $script:failCount++ }
function Assert-True { param([bool]$Condition, [string]$Message) if ($Condition) { Write-Pass $Message } else { Write-Fail $Message } }

foreach ($fn in 'Resolve-SpecrewTypedAct', 'Get-SpecrewTypedActIdentity') {
    Assert-True ($null -ne (Get-Command $fn -ErrorAction SilentlyContinue)) "$fn exists"
}
if ($script:failCount -gt 0) { Write-Host "typed-act-classifier: $($script:failCount) failure(s)" -ForegroundColor Red; exit 1 }

function New-Turn {
    param([string]$Text, [string]$HostKind = 'claude', [string]$Id = 'p-1', [string]$Origin = 'typed-user', [string]$Identity = 'declared', [switch]$Compact)
    $t = [pscustomobject]@{ host = $HostKind; message_id = $Id; message_identity = $Identity; origin = $Origin; text = $Text }
    if ($Compact) { $t | Add-Member -NotePropertyName is_compact_summary -NotePropertyValue $true }
    return $t
}
function New-Pending {
    param([string]$From, [string]$To, [string]$PauseKind, [string]$Question, [switch]$EvidenceAbsent)
    [pscustomobject]@{
        Crossing         = if ($To) { [pscustomobject]@{ From = $From; To = $To; StageEvidenceAbsent = [bool]$EvidenceAbsent } } else { $null }
        Pause            = if ($PauseKind) { [pscustomobject]@{ Kind = $PauseKind; Id = 'pause-1' } } else { $null }
        WorkshopQuestion = if ($Question) { [pscustomobject]@{ Id = $Question } } else { $null }
    }
}
function Assert-Act {
    param($Act, [string]$Kind, [string]$Reason = '', [Nullable[bool]]$Report = $null, [string]$Label)
    $ok = ([string]$Act.Kind -ceq $Kind) -and ([string]::IsNullOrEmpty($Reason) -or [string]$Act.Reason -ceq $Reason) -and ($null -eq $Report -or [bool]$Act.Report -eq [bool]$Report)
    Assert-True $ok ("{0} (got {1}/{2}/report={3})" -f $Label, $Act.Kind, $Act.Reason, $Act.Report)
}
$nothing = New-Pending

Write-Host '--- a queued typed approval counts as typed (DRIFT-006, DRIFT-012) ---'
$queuedDir = Join-Path $fixtures 'claude\queued'
$running = Get-Content -LiteralPath (Join-Path $queuedDir 'print-userpromptsubmit-running-turn.json') -Raw | ConvertFrom-Json
$queued = Get-Content -LiteralPath (Join-Path $queuedDir 'print-userpromptsubmit-queued.json') -Raw | ConvertFrom-Json
Assert-True ([string]$running.prompt_id -ceq [string]$queued.prompt_id) 'host fact: the queued message reaches the hook with the running turn''s prompt_id'
$entry = @(Get-Content -LiteralPath (Join-Path $queuedDir 'tui-transcript-queued-approval.jsonl') | ForEach-Object { $_ | ConvertFrom-Json } | Where-Object { $_.type -eq 'user' })[0]
Assert-True ([string]$entry.promptSource -ceq 'queued' -and [string]$entry.origin.kind -ceq 'human') 'host fact: the TUI stores the queued approval as human, promptSource queued'
$runningTurn = New-Turn -Text ([string]$running.prompt) -Id ([string]$running.prompt_id)
$queuedTurn = New-Turn -Text ([string]$entry.message.content) -Id ([string]$queued.prompt_id)
$runningId = (Get-SpecrewTypedActIdentity -Turn $runningTurn).Identity
$queuedId = (Get-SpecrewTypedActIdentity -Turn $queuedTurn).Identity
Assert-True (-not [string]::IsNullOrWhiteSpace($queuedId) -and $queuedId -cne $runningId) 'a queued message sharing the running turn''s prompt_id has its own identity'
$act = Resolve-SpecrewTypedAct -Turn $queuedTurn -Pending $nothing -RecordedIdentities @($runningId)
Assert-Act $act 'round-approval' '' $false 'the queued approval is an act although the running turn is recorded'
$again = Resolve-SpecrewTypedAct -Turn $queuedTurn -Pending $nothing -RecordedIdentities @($runningId, $queuedId)
Assert-Act $again 'none' 'already-recorded' $false 'the same queued approval seen again is already recorded, silently'

Write-Host '--- a compaction summary is not a typed turn (R4) ---'
$compactLines = @(Get-Content -LiteralPath (Join-Path $fixtures 'claude\compaction\tui-compaction-transcript-excerpt.jsonl') | ForEach-Object { $_ | ConvertFrom-Json })
$summary = @($compactLines | Where-Object { $_.PSObject.Properties['isCompactSummary'] -and $_.isCompactSummary })[0]
Assert-True ([string]$summary.message.content -match 'approved for review round') 'the recorded summary quotes the phrase'
$summaryTurn = New-Turn -Text ([string]$summary.message.content) -Id ([string]$summary.promptId) -Compact
Assert-Act (Resolve-SpecrewTypedAct -Turn $summaryTurn -Pending (New-Pending -PauseKind 'a-budget-spent')) 'none' 'not-human' $false 'a compaction summary yields no act and no report'
$bareSummary = New-Turn -Text 'approved for review round' -Id ([string]$summary.promptId) -Compact
Assert-Act (Resolve-SpecrewTypedAct -Turn $bareSummary -Pending $nothing) 'none' 'not-human' $false 'even a summary that is only the phrase yields no act'

Write-Host '--- a pasted transcript beginning with the phrase is not typed (DRIFT-023) ---'
$pasteTurn = Get-Content -LiteralPath (Join-Path $fixtures 'claude\pasted-transcript\tui-paste-begins-with-phrase.turn.json') -Raw | ConvertFrom-Json
Assert-Act (Resolve-SpecrewTypedAct -Turn $pasteTurn -Pending $nothing) 'none' 'not-standalone' $false 'the 14:39 paste yields no act and no report'
Assert-Act (Resolve-SpecrewTypedAct -Turn $pasteTurn -Pending (New-Pending -From 'implement' -To 'review')) 'none' 'not-standalone' $false 'the same paste with a crossing waiting yields no act'
$typedBelow = New-Turn -Text ([string]$pasteTurn.text + "`napproved for allowance reset")
Assert-Act (Resolve-SpecrewTypedAct -Turn $typedBelow -Pending (New-Pending -PauseKind 'a-budget-spent')) 'top-up' '' $false 'a phrase typed on its own line below a Claude paste is the act (B4F-125)'
$copilotPaste = New-Turn -HostKind 'copilot' -Identity 'stand-in' -Text ("approved for review round`n" + (@(3..10 | ForEach-Object { "line $_ of a pasted block" }) -join "`n"))
Assert-Act (Resolve-SpecrewTypedAct -Turn $copilotPaste -Pending $nothing) 'none' 'not-standalone' $true 'on Copilot a multi-line message under the phrase is refused and the human told to retype one line'

Write-Host '--- quoted, backticked and non-approval phrases ---'
foreach ($t in '`approved for review round`', '"approved for tasks"', 'you said `approved for allowance reset` earlier') {
    Assert-Act (Resolve-SpecrewTypedAct -Turn (New-Turn -Text $t) -Pending (New-Pending -From 'plan' -To 'tasks' -PauseKind 'a-budget-spent')) 'none' '' $false "not an act: $t"
}
foreach ($t in 'can you explain the plan?', 'I approved for tasks yesterday', 'the reviewer approved for review round 3', 'approved for review round?') {
    Assert-Act (Resolve-SpecrewTypedAct -Turn (New-Turn -Text $t) -Pending (New-Pending -From 'plan' -To 'tasks')) 'none' '' $false "not an act: $t"
}
$menu = New-Turn -Text "approved for tasks`nchanges needed: shorter tasks`ndiscuss prompt 1"
$menuAct = Resolve-SpecrewTypedAct -Turn $menu -Pending (New-Pending -From 'plan' -To 'tasks')
Assert-Act $menuAct 'none' 'not-standalone' $null 'a quoted menu of options is one turn and no act'

Write-Host '--- boundary verdicts pair with the pending crossing (FR-019, FR-020) ---'
$planTasks = New-Pending -From 'plan' -To 'tasks'
$v = Resolve-SpecrewTypedAct -Turn (New-Turn -Text 'approved for tasks') -Pending $planTasks
Assert-Act $v 'boundary-verdict' '' $false 'approved for tasks with plan -> tasks waiting'
Assert-True ([string]$v.Target -ceq 'plan->tasks') "the verdict names the waiting crossing (got '$($v.Target)')"
Assert-Act (Resolve-SpecrewTypedAct -Turn (New-Turn -Text 'approved for tasks - keep T005 small') -Pending $planTasks) 'boundary-verdict' '' $false 'a verdict with a same-line instruction'
Assert-Act (Resolve-SpecrewTypedAct -Turn (New-Turn -Text 'approved for implement') -Pending $planTasks) 'none' 'boundary-mismatch' $true 'a verdict for another boundary records nothing and is reported'
Assert-Act (Resolve-SpecrewTypedAct -Turn (New-Turn -Text 'approved for tasks') -Pending $nothing) 'none' 'no-pending-crossing' $true 'a verdict with no crossing waiting is reported'
Assert-Act (Resolve-SpecrewTypedAct -Turn (New-Turn -Text 'approved for tasks') -Pending (New-Pending -From 'plan' -To 'tasks' -EvidenceAbsent)) 'none' 'stage-evidence-absent' $true 'a verdict for a stage that owes its artifacts is reported'
$reviewWaiting = New-Pending -From 'implement' -To 'review'
Assert-Act (Resolve-SpecrewTypedAct -Turn (New-Turn -Text 'approved for review round') -Pending $reviewWaiting) 'round-approval' '' $false 'approved for review round is never a verdict for the review boundary (B4F-116/150)'
Assert-Act (Resolve-SpecrewTypedAct -Turn (New-Turn -Text 'approved for review') -Pending $reviewWaiting) 'boundary-verdict' '' $false 'approved for review is the verdict when implement -> review waits'

Write-Host '--- top-up and stop answers (FR-007, FR-011) ---'
Assert-Act (Resolve-SpecrewTypedAct -Turn (New-Turn -Text 'approved for allowance reset') -Pending (New-Pending -PauseKind 'a-budget-spent')) 'top-up' '' $false 'approved for allowance reset at a spent budget is the top-up'
Assert-Act (Resolve-SpecrewTypedAct -Turn (New-Turn -Text 'approved for allowance reset') -Pending $nothing) 'none' 'no-pending-crossing' $true 'a top-up with no spent budget waiting is reported'
$dispute = New-Pending -PauseKind 'b-dispute-or-defer'
$s = Resolve-SpecrewTypedAct -Turn (New-Turn -Text 'stop the review here') -Pending $dispute
Assert-Act $s 'stop-answer' '' $false 'stop the review here at a review stop'
Assert-True ([string]$s.Answer -ceq 'stop-review') "the answer is stop-review (got '$($s.Answer)')"
$d = Resolve-SpecrewTypedAct -Turn (New-Turn -Text 'defer finding F2 to B5F-030') -Pending $dispute
Assert-True ([string]$d.Kind -ceq 'stop-answer' -and [string]$d.Answer -ceq 'defer' -and [string]$d.Argument -ceq 'B5F-030') "a deferral keeps its destination as the only text argument (got $($d.Kind)/$($d.Answer)/$($d.Argument))"
Assert-Act (Resolve-SpecrewTypedAct -Turn (New-Turn -Text 'defer finding F2') -Pending $dispute) 'none' 'missing-destination' $true 'a deferral without a destination is reported'
$dr = Resolve-SpecrewTypedAct -Turn (New-Turn -Text 'drop finding F1') -Pending $dispute
Assert-True ([string]$dr.Kind -ceq 'stop-answer' -and [string]$dr.Answer -ceq 'drop') 'drop finding F1'
$al = Resolve-SpecrewTypedAct -Turn (New-Turn -Text 'allow reviewer Claude') -Pending (New-Pending -PauseKind 'd-host-outside-order')
Assert-True ([string]$al.Kind -ceq 'stop-answer' -and [string]$al.Answer -ceq 'allow-reviewer' -and [string]$al.Argument -ceq 'claude') 'allow reviewer names the host'
Assert-Act (Resolve-SpecrewTypedAct -Turn (New-Turn -Text 'drop finding F1') -Pending $nothing) 'none' 'no-pending-crossing' $true 'a stop answer with no stop waiting is reported'
$j = Resolve-SpecrewTypedAct -Turn (New-Turn -Text 'keep the stricter check; the reviewer is right') -Pending (New-Pending -PauseKind 'c-judgment')
Assert-True ([string]$j.Kind -ceq 'stop-answer' -and [string]$j.Answer -ceq 'judgment' -and [string]::IsNullOrEmpty([string]$j.Argument)) 'free text at a judgment stop is the answer, and its text is not kept (FR-023)'

Write-Host '--- workshop replies ---'
Assert-Act (Resolve-SpecrewTypedAct -Turn (New-Turn -Text 'two kinds of user: admins and guests') -Pending (New-Pending -Question 'pd-users')) 'workshop-reply' '' $false 'any typed reply answers the open workshop question'
Assert-Act (Resolve-SpecrewTypedAct -Turn (New-Turn -Text 'two kinds of user: admins and guests') -Pending $nothing) 'none' 'not-an-act' $false 'with nothing waiting a reply is no act'

Write-Host '--- who typed it, and its identity (FR-015) ---'
Assert-Act (Resolve-SpecrewTypedAct -Turn (New-Turn -Text 'approved for review round' -Origin 'host-injected') -Pending $nothing) 'none' 'not-human' $false 'host-injected text yields no act and no report'
Assert-Act (Resolve-SpecrewTypedAct -Turn (New-Turn -Text 'approved for review round' -Origin 'unknown') -Pending $nothing) 'none' 'origin-unconfirmed' $true 'an unconfirmed origin with an act shape is reported'
Assert-Act (Resolve-SpecrewTypedAct -Turn (New-Turn -Text 'thanks' -Origin 'unknown') -Pending $nothing) 'none' 'not-an-act' $false 'an unconfirmed origin without one is not'
Assert-Act (Resolve-SpecrewTypedAct -Turn (New-Turn -Text 'approved for review round' -Id '' -Identity 'none') -Pending $nothing) 'none' 'no-identity' $true 'a turn with no identity mints nothing and is reported'
$copilotTurn = New-Turn -HostKind 'copilot' -Identity 'stand-in' -Id ('0' * 64) -Text 'approved for review round'
$ci = Get-SpecrewTypedActIdentity -Turn $copilotTurn
Assert-True ([string]$ci.Kind -ceq 'stand-in') 'a Copilot turn carries the declared stand-in identity'
Assert-Act (Resolve-SpecrewTypedAct -Turn (New-Turn -Text 'withdraw the approval') -Pending $nothing) 'withdrawal' '' $false 'a withdrawal is its own act'

if ($script:failCount -gt 0) { Write-Host "typed-act-classifier: $($script:failCount) failure(s)" -ForegroundColor Red; exit 1 }
Write-Host 'typed-act-classifier: all passed' -ForegroundColor Green
exit 0
