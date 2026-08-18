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

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$provider = Join-Path $repoRoot 'extensions\specrew-speckit\scripts\specrew-conformance-provider.ps1'
$mirror = Join-Path $repoRoot '.specify\extensions\specrew-speckit\scripts\specrew-conformance-provider.ps1'
Assert-True ((Get-Content -LiteralPath $provider -Raw -Encoding UTF8) -eq (Get-Content -LiteralPath $mirror -Raw -Encoding UTF8)) 'conformance provider source and deployed mirror are byte-identical'

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

    $workFirst = 'Feature 001-keycontext-ai is scaffolded on branch 001-keycontext-ai. Opening the design workshop now.'

    # No bootstrap was delivered to this session -> nothing was handed over to show -> nothing owed.
    $noClaim = Invoke-Stop -AssistantText $workFirst -SessionId 'w25-noclaim-session'
    Assert-True ($noClaim -notmatch 'orientation was handed to you') 'with no delivered bootstrap, no orientation is demanded'

    # A delivered bootstrap (the render claim the hook writes) puts the obligation in force.
    Set-Content -LiteralPath (Join-Path $scratch '.specrew\runtime\hook-bootstrap-render-w25-startup.json') -Value '{"dedupe_key":"w25","source":"startup"}' -Encoding UTF8

    $blocked = Invoke-Stop -AssistantText $workFirst
    Assert-True ($blocked -match 'SPECREW-STOP-BLOCK') 'a first reply that goes straight to work is stopped'
    Assert-True ($blocked -match '(?i)orientation was handed to you and the human never saw it') 'the correction says the orientation was delivered and not shown'
    Assert-True ($blocked -match '(?i)what you believe about them so they can correct it') 'the correction requires what the crew believes about the human'
    Assert-True ($blocked -match '(?i)Reading it to orient yourself is not rendering it') 'the correction names the exact failure two walks produced'
    Assert-True ($blocked -notmatch 'SPECREW-VERDICT-BOUNDARY: ') 'the orientation stop emits no boundary verdict marker'

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

    # A DIFFERENT session owes its own orientation - the receipt is per session, not per project.
    $otherSession = Invoke-Stop -AssistantText $workFirst -SessionId 'w25-other-session'
    Assert-True ($otherSession -match '(?i)orientation was handed to you') 'a different session owes its own orientation'

    # RIDE-ALONG: when a higher-priority demand already blocks, the orientation must not be dropped -
    # it is added to that same message rather than displacing it or waiting for a quieter turn.
    New-Item -ItemType Directory -Path (Join-Path $scratch 'src') -Force | Out-Null
    Set-Content -LiteralPath (Join-Path $scratch 'src\thing.txt') -Value 'material work this turn' -Encoding UTF8
    $material = Invoke-Stop -AssistantText 'I refactored the module and tidied the helpers.' -SessionId 'w25-material-session'
    Assert-True ($material -match '(?i)this Stop followed material work') 'the material demand still fires and is not displaced'
    Assert-True ($material -match "(?i)Also: this session's orientation was never shown") 'the orientation rides along on a higher-priority block instead of being lost'
    Remove-Item -LiteralPath (Join-Path $scratch 'src') -Recurse -Force
}
finally { Remove-Item -LiteralPath $scratch -Recurse -Force -ErrorAction SilentlyContinue }

Write-Host 'session orientation is rendered: all assertions pass' -ForegroundColor Green
