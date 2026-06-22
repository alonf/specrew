$ErrorActionPreference = 'Stop'

# Feature 185 FR-004 / FR-005 / FR-015: the dispatcher's STOP-BLOCK delivery. A Stop-class consumer emits the
# `<<<SPECREW-STOP-BLOCK>>>` sentinel; the dispatcher translates it into the HOST's stop-block envelope (the
# verified capability matrix, research/stop-block-capability-matrix.md) so the agent force-continues and renders
# the re-entry packet AT the stop. This runs the REAL dispatcher per host with a STUB provider that emits the
# sentinel (isolating the dispatcher's per-host delivery from the real conformance provider's detection), and
# asserts the envelope, the stop_hook_active loop-guard (allow when already continuing), and the cursor degrade.

function Assert-True { param([bool]$Condition, [string]$Message) if (-not $Condition) { throw "FAIL: $Message" } ; Write-Host "PASS: $Message" -ForegroundColor Green }

$dispatcher = (Resolve-Path "$PSScriptRoot/../../scripts/internal/specrew-hook-dispatcher.ps1").Path

function Invoke-Dispatcher {
    param(
        [string]$HostKind,
        [string]$Event,
        [hashtable]$EventExtra = @{},
        [ValidateSet('block', 'nudge')]
        [string]$StubKind = 'block'
    )
    $proj = Join-Path ([System.IO.Path]::GetTempPath()) ("sb-" + [guid]::NewGuid().ToString('N'))
    $scriptsDir = Join-Path $proj '.specify/extensions/specrew-speckit/scripts'
    New-Item -ItemType Directory -Path (Join-Path $proj '.specrew/runtime') -Force | Out-Null
    New-Item -ItemType Directory -Path $scriptsDir -Force | Out-Null
    try {
        # ONE stub provider on every stop-class event. Most cases emit the stop-block sentinel; the Codex
        # regression emits an ordinary nudge, which must be suppressed to no-op JSON on Stop.
        $catalog = @{ schema_version = '1'; providers = @(@{ id = 'stub-block'; kind = 'inject'; events = @('Stop', 'agentStop', 'stop'); order = 40; budget_share = 1.0; command = 'stub-block.ps1' }) } | ConvertTo-Json -Depth 6
        Set-Content -LiteralPath (Join-Path $proj '.specify/extensions/specrew-speckit/refocus-scopes.json') -Value $catalog -Encoding UTF8
        $stub = if ($StubKind -eq 'block') {
            "Write-Output `"<<<SPECREW-STOP-BLOCK>>>`nRENDER THE PACKET NOW`"; exit 0"
        }
        else {
            "Write-Output `"RAW SPEC KIT invocation detected`"; exit 0"
        }
        Set-Content -LiteralPath (Join-Path $scriptsDir 'stub-block.ps1') -Value $stub -Encoding UTF8

        $evt = @{ session_id = 'sb1'; source = $Event }
        foreach ($k in $EventExtra.Keys) { $evt[$k] = $EventExtra[$k] }
        $eventFile = Join-Path $proj 'event.json'
        Set-Content -LiteralPath $eventFile -Value ($evt | ConvertTo-Json -Compress) -Encoding UTF8 -NoNewline

        $outFile = Join-Path $proj 'd.out'; $errFile = Join-Path $proj 'd.err'
        $p = Start-Process -FilePath 'pwsh' `
            -ArgumentList @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $dispatcher, '-Event', $Event, '-HostKind', $HostKind) `
            -WorkingDirectory $proj -NoNewWindow -PassThru -Wait `
            -RedirectStandardInput $eventFile -RedirectStandardOutput $outFile -RedirectStandardError $errFile
        return [pscustomobject]@{ ExitCode = $p.ExitCode; Out = (Get-Content -LiteralPath $outFile -Raw -ErrorAction SilentlyContinue) }
    }
    finally { Remove-Item -LiteralPath $proj -Recurse -Force -ErrorAction SilentlyContinue }
}

# Per-host: the stop event name + the expected envelope shape.
$hosts = @(
    @{ Kind = 'claude'; Event = 'Stop'; ExpectField = '"decision":"block"' },
    @{ Kind = 'codex'; Event = 'Stop'; ExpectField = '"decision":"block"' },
    @{ Kind = 'copilot'; Event = 'agentStop'; ExpectField = '"decision":"block"' },
    @{ Kind = 'antigravity'; Event = 'Stop'; ExpectField = '"decision":"continue"' },
    @{ Kind = 'cursor'; Event = 'stop'; ExpectField = '"followup_message"' }
)

foreach ($h in $hosts) {
    $r = Invoke-Dispatcher -HostKind $h.Kind -Event $h.Event
    Assert-True ($r.ExitCode -eq 0) "$($h.Kind): dispatcher exits 0 (fail-open holds)"
    $compact = ($r.Out -replace '\s', '')
    Assert-True ($compact -match [regex]::Escape($h.ExpectField)) "$($h.Kind): the block sentinel becomes the host envelope ($($h.ExpectField))"
    Assert-True ($r.Out -match 'RENDER THE PACKET NOW') "$($h.Kind): the packet directive is carried as the envelope reason"
}

# Loop-guard: stop_hook_active=true (claude/codex built-in) -> the dispatcher does NOT block (allow), so the
# host's own continuation cap is respected and the turn can never hang.
$rActive = Invoke-Dispatcher -HostKind 'claude' -Event 'Stop' -EventExtra @{ stop_hook_active = $true }
Assert-True ($rActive.ExitCode -eq 0) 'stop_hook_active: dispatcher exits 0'
Assert-True (-not (($rActive.Out -replace '\s', '') -match '"decision":"block"')) 'stop_hook_active=true: the dispatcher does NOT re-block (respects the host continuation cap; never hangs)'

# A host whose Stop is NOT decision-bearing still must not crash; cursor's followup_message is the declared degrade
# (already asserted above) - confirm the cursor path produced a NON-decision envelope (no decision:block).
$rCursor = Invoke-Dispatcher -HostKind 'cursor' -Event 'stop'
Assert-True (-not (($rCursor.Out -replace '\s', '') -match '"decision":"block"')) 'cursor: degrades to followup_message, NOT a hard decision:block (declared best-effort)'

# Codex Stop accepts JSON but only permits decision:"block"; decision:"allow" is invalid. A non-blocking
# provider nudge must be emitted as `{}` rather than hookSpecificOutput.additionalContext.
$rCodexNudge = Invoke-Dispatcher -HostKind 'codex' -Event 'Stop' -StubKind 'nudge'
$codexNudgeJson = $rCodexNudge.Out | ConvertFrom-Json -ErrorAction Stop
Assert-True (-not ($codexNudgeJson.PSObject.Properties.Name -contains 'decision')) 'codex Stop nudge: dispatcher returns valid no-op JSON, not invalid decision:allow'
Assert-True (-not ($rCodexNudge.Out -match 'hookSpecificOutput|RAW SPEC KIT')) 'codex Stop nudge: dispatcher suppresses non-blocking injection payload on decision-only Stop'

Write-Host "`n=== dispatcher-stop-block.tests.ps1: all assertions passed ===" -ForegroundColor Green
