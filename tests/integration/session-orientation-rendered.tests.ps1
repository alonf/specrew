[CmdletBinding()]
param()
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
function Assert-True { param([bool]$Condition,[string]$Message) if (-not $Condition) { throw "FAIL: $Message" }; Write-Host "PASS: $Message" -ForegroundColor Green }

# W25 (2026-08-18): W23 put the orientation obligation in both always-in-context channels - the session
# directive and the host-materialized project instructions - and the very next controlled walk
# (C:\Dev\KeyContextAI, deployed build 4b929764, SessionStart delivered in `full` mode) still opened with
# work instead of the orientation. The recorded ruling named that outcome as the trigger to build the
# mechanical check rather than sharpen the wording a second time.
#
# The check is scoped so it is not a per-stop cost: it evaluates only while the session has no
# orientation receipt, only when a bootstrap was actually delivered, never displaces a higher-priority
# block, and fails open.
#
# FEATURE 202 T008 (FR-014, DA-3, B4F-096) RETIRED THE STOP-TIME DEMAND this suite was built for. A Stop that
# asks for the orientation after the first question has already been asked cannot put it first, and it cost
# the human a corrective cycle (B4F-096, reproduced on installed beta4). The finished orientation is now
# supplied with the session's first prompt (tests/unit/orientation-order.tests.ps1). What this suite still
# pins: the check reads the OPENING message (W35), it is per session - keyed on THIS session's render claim -
# and a shown orientation earns a receipt. What it now pins the other way: no Stop demands the orientation,
# alone or riding along on another block.

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$provider = Join-Path $repoRoot 'extensions\specrew-speckit\scripts\specrew-conformance-provider.ps1'
$mirror = Join-Path $repoRoot '.specify\extensions\specrew-speckit\scripts\specrew-conformance-provider.ps1'
if (Test-Path -LiteralPath $mirror -PathType Leaf) {
    Assert-True ((Get-Content -LiteralPath $provider -Raw -Encoding UTF8) -eq (Get-Content -LiteralPath $mirror -Raw -Encoding UTF8)) 'conformance provider source and deployed mirror are byte-identical'
}
else {
    # W52 aftermath: the deployed .specify mirror is machinery the review digest strips, so it is absent by design in a frozen review tree; its integrity there is the W43 marker check's jurisdiction, not this suite's.
    Write-Host 'SKIP: deployed mirror absent (frozen review tree); mirror integrity is the W43 marker check' -ForegroundColor Yellow
}

. (Join-Path $repoRoot 'extensions\specrew-speckit\scripts\turn-end-store.ps1')
function Get-SpecrewTurnEndPathsForTest {
    # This session's orientation receipt, through the one resolver both the hook and the declarer use.
    param([Parameter(Mandatory)][string]$SessionId)
    return [string](Get-SpecrewTurnEndPaths -ProjectRoot $scratch -HostKind 'claude' -SessionId $SessionId).OrientationPath
}

$scratch = Join-Path ([IO.Path]::GetTempPath()) ('specrew-w25-' + [guid]::NewGuid().ToString('N'))
try {
    New-Item -ItemType Directory -Path (Join-Path $scratch '.specrew\runtime') -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $scratch 'scripts\internal\bootstrap') -Force | Out-Null
    Set-Content -LiteralPath (Join-Path $scratch '.specrew\config.yml') -Value 'version: 1' -Encoding UTF8
    Copy-Item -LiteralPath (Join-Path $repoRoot 'scripts\internal\bootstrap\ConversationCaptureAccessor.ps1') -Destination (Join-Path $scratch 'scripts\internal\bootstrap\') -Force
    Copy-Item -LiteralPath (Join-Path $repoRoot 'scripts\internal\bootstrap\ProjectMetadataAccessor.ps1') -Destination (Join-Path $scratch 'scripts\internal\bootstrap\') -Force
    Push-Location $scratch
    try { & git init --quiet 2>&1 | Out-Null; & git add -A 2>&1 | Out-Null; & git -c user.email='t@t' -c user.name='t' commit -m init --quiet 2>&1 | Out-Null }
    finally { Pop-Location }

    function Invoke-Stop {
        param([Parameter(Mandatory)][string]$AssistantText,[string]$SessionId = 'w25-session')
        $transcript = Join-Path $scratch ('.specrew\runtime\t-' + [guid]::NewGuid().ToString('N') + '.jsonl')
        $line = [pscustomobject]@{ type='assistant'; message=[pscustomobject]@{ content=@([pscustomobject]@{ type='text'; text=$AssistantText }) } } | ConvertTo-Json -Depth 8 -Compress
        [IO.File]::WriteAllText($transcript, $line + [Environment]::NewLine, [Text.UTF8Encoding]::new($false))
        $prior = $env:SPECREW_MODULE_PATH; $env:SPECREW_MODULE_PATH = $repoRoot
        try { Push-Location $scratch; try { $out = @(& pwsh -NoProfile -ExecutionPolicy Bypass -File $provider --host-kind claude --source-event Stop --transcript-path $transcript --session-id $SessionId 2>&1) } finally { Pop-Location } }
        finally { $env:SPECREW_MODULE_PATH = $prior }
        return ($out -join "`n")
    }

    function Invoke-StopWithTranscript {
        # W35: the single-message helper above cannot express the shape that mattered - an orientation
        # rendered in the OPENING message with ordinary work after it. This writes several assistant
        # turns in order.
        param([Parameter(Mandatory)][string[]]$AssistantTexts,[string]$SessionId = 'w35-session')
        $transcript = Join-Path $scratch (Join-Path (Join-Path '.specrew' 'runtime') ('t-' + [guid]::NewGuid().ToString('N') + '.jsonl'))
        $lines = foreach ($text in $AssistantTexts) {
            [pscustomobject]@{ type='assistant'; message=[pscustomobject]@{ content=@([pscustomobject]@{ type='text'; text=$text }) } } | ConvertTo-Json -Depth 8 -Compress
        }
        [IO.File]::WriteAllText($transcript, (($lines -join [Environment]::NewLine) + [Environment]::NewLine), [Text.UTF8Encoding]::new($false))
        $prior = $env:SPECREW_MODULE_PATH; $env:SPECREW_MODULE_PATH = $repoRoot
        try { Push-Location $scratch; try { $out = @(& pwsh -NoProfile -ExecutionPolicy Bypass -File $provider --host-kind claude --source-event Stop --transcript-path $transcript --session-id $SessionId 2>&1) } finally { Pop-Location } }
        finally { $env:SPECREW_MODULE_PATH = $prior }
        return ($out -join "`n")
    }

    $workFirst = 'Feature 001-keycontext-ai is scaffolded on branch 001-keycontext-ai. Opening the design workshop now.'

    # No bootstrap was delivered to this session -> nothing was handed over to show -> nothing owed.
    $noClaim = Invoke-Stop -AssistantText $workFirst -SessionId 'w25-noclaim-session'
    Assert-True ($noClaim -notmatch 'orientation was handed to you') 'with no delivered bootstrap, no orientation is demanded'

    # A delivered bootstrap: THIS session's render claim, named as the hook names it (<session>-<source>).
    foreach ($claimSession in 'w25-session', 'w25-other-session', 'w25-material-session', 'w35-oriented-then-worked', 'w35-never-oriented') {
        Set-Content -LiteralPath (Join-Path $scratch ('.specrew\runtime\hook-bootstrap-render-{0}-startup.json' -f $claimSession)) -Value ('{{"dedupe_key":"{0}","source":"startup"}}' -f $claimSession) -Encoding UTF8
    }

    # 202 T008: the orientation is supplied with the first prompt, so a first reply that goes straight to work
    # is not stopped for it (B4F-096: the demand came after the question and cost a corrective cycle).
    $workFirstStop = Invoke-Stop -AssistantText $workFirst
    Assert-True ($workFirstStop -notmatch 'SPECREW-STOP-BLOCK') 'a first reply that goes straight to work is not stopped for the orientation'
    Assert-True ($workFirstStop -notmatch '(?i)orientation') 'and no orientation demand is composed'

    # A genuine banner clears it. Deliberately paraphrased: the check must not demand set wording.
    $banner = @'
Welcome - Specrew is active in this project (version 0.40.0-beta3, host claude).
Lifecycle: new feature intake. Your artifacts will live under specs/.
What I know about you: I will treat you as expert on Software Architecture - correct me if that is off.
At each boundary I will stop and ask for your approval.
Now starting the design workshop.
'@
    $rendered = Invoke-Stop -AssistantText $banner
    Assert-True ($rendered -notmatch 'orientation was handed to you') 'a genuine banner, in the agent''s own words, satisfies the check'

    $receipt = Join-Path $scratch '.specrew\runtime\conformance-sessions'
    $receiptFiles = @(Get-ChildItem -LiteralPath $receipt -Recurse -Filter 'orientation-rendered.json' -File -ErrorAction SilentlyContinue)
    Assert-True (@($receiptFiles).Count -eq 1) 'satisfying the check writes a per-session receipt'

    # THE COST OBJECTION: once satisfied, later stops must not re-demand it, whatever they contain.
    $after = Invoke-Stop -AssistantText $workFirst
    Assert-True ($after -notmatch 'orientation was handed to you') 'once the human has seen it, no later stop demands it again'

    # The receipt is per session, not per project: a different session's work-first stop earns none from the
    # first session's banner, and is not stopped either.
    $otherSession = Invoke-Stop -AssistantText $workFirst -SessionId 'w25-other-session'
    Assert-True ($otherSession -notmatch '(?i)orientation was handed to you') 'a different session is not stopped for the orientation'
    $otherReceipt = (Get-SpecrewTurnEndPathsForTest -SessionId 'w25-other-session')
    Assert-True (-not (Test-Path -LiteralPath $otherReceipt -PathType Leaf)) 'and the first session''s receipt is not credited to it'

    # NO RIDE-ALONG (202 T008): a higher-priority demand still fires, and the orientation does not ride along on
    # it - the orientation was supplied with the first prompt, and asking for it here is the same late demand.
    New-Item -ItemType Directory -Path (Join-Path $scratch 'src') -Force | Out-Null
    Set-Content -LiteralPath (Join-Path $scratch 'src\thing.txt') -Value 'material work this turn' -Encoding UTF8
    $material = Invoke-Stop -AssistantText 'I refactored the module and tidied the helpers.' -SessionId 'w25-material-session'
    # The material refusal's text changed with fix 2: it says what the hook can honestly know - changes were
    # observed and no declaration was recorded - and names the script, rather than "this Stop followed
    # material work" (attribution the hook no longer claims). The subject here is unchanged: it FIRES.
    Assert-True ($material -match '(?i)changes were observed in the worktree since this turn began and no turn-end declaration was recorded') 'the material demand still fires and is not displaced'
    Assert-True ($material -notmatch "(?i)Also: this session's orientation was never shown") 'the orientation does not ride along on a higher-priority block'
    Remove-Item -LiteralPath (Join-Path $scratch 'src') -Recurse -Force

# W35: THE ORIENTATION IS IN THE OPENING MESSAGE, AND THE CHECK READ THE LAST ONE.
#
# Measured 2026-08-20 (KeyContextAI session e9c42e87): the opening message is a full banner and clears
# this bar; only 2 of that session's 190 assistant messages do. Every stop whose last message was one of
# the other 188 told a compliant session "your orientation was handed to you and the human never saw
# it". Third detector to punish compliant output, after W16's bullet glyphs and W35's prose scan.
$orientationBanner = 'Welcome - here is where this project stands. Specrew 0.40.0-beta3 is active on this project, and here is what I know about you: you prefer bare-number verdicts.'
$orientedThenWorked = Invoke-StopWithTranscript -AssistantTexts @(
    $orientationBanner,
    'Creating the governed feature now.',
    'Running the workshop lenses.',
    $workFirst) -SessionId 'w35-oriented-then-worked'
Assert-True ($orientedThenWorked -notmatch '(?i)orientation was handed to you and the human never saw it') 'an orientation rendered in the OPENING message is not demanded again after later work'
Assert-True (Test-Path -LiteralPath (Get-SpecrewTurnEndPathsForTest -SessionId 'w35-oriented-then-worked') -PathType Leaf) 'and the OPENING message earns that session its receipt (W35)'

# 202 T008: a session that never showed it is journaled, not stopped - however many messages it has produced.
$neverOriented = Invoke-StopWithTranscript -AssistantTexts @(
    'Creating the governed feature now.',
    'Running the workshop lenses.',
    $workFirst) -SessionId 'w35-never-oriented'
Assert-True ($neverOriented -notmatch 'SPECREW-STOP-BLOCK') 'a session that never oriented is not stopped for it'
Assert-True (-not (Test-Path -LiteralPath (Get-SpecrewTurnEndPathsForTest -SessionId 'w35-never-oriented') -PathType Leaf)) 'and earns no receipt'

}
finally { Remove-Item -LiteralPath $scratch -Recurse -Force -ErrorAction SilentlyContinue }

Write-Host 'session orientation is rendered: all assertions pass' -ForegroundColor Green
