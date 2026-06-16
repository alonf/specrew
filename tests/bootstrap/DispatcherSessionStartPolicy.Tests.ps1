$ErrorActionPreference = 'Stop'

# F-183 T001: the dispatcher is the only layer that sees the assembled
# SessionStart payload. These tests drive the real dispatcher with stub providers
# and assert bootstrap outranks refocus under cap pressure, and provider failure
# degrades to a governed fallback on stdout with exit 0.

function Assert-True {
    param([bool]$Condition, [string]$Message)
    if (-not $Condition) { throw "FAIL: $Message" }
    Write-Host "PASS: $Message" -ForegroundColor Green
}

$dispatcher = (Resolve-Path "$PSScriptRoot/../../scripts/internal/specrew-hook-dispatcher.ps1").Path

function Invoke-SessionStartDispatcherScenario {
    param(
        [Parameter(Mandatory = $true)][object[]]$Providers,
        [string]$SessionId = 'sess-183',
        [string]$HostKind = 'claude',
        [string]$EventName = 'SessionStart',
        [AllowNull()][string]$EventJson = $null
    )
    $proj = Join-Path ([System.IO.Path]::GetTempPath()) ("sspolicy-" + [guid]::NewGuid().ToString('N'))
    $scriptsDir = Join-Path $proj '.specify/extensions/specrew-speckit/scripts'
    New-Item -ItemType Directory -Path (Join-Path $proj '.specrew/runtime') -Force | Out-Null
    New-Item -ItemType Directory -Path $scriptsDir -Force | Out-Null

    $catalog = @{
        schema_version = '1'
        providers      = @($Providers | ForEach-Object {
                $events = if ($_ -is [hashtable] -and $_.ContainsKey('events')) { @($_.events) }
                elseif ($_.PSObject.Properties['events']) { @($_.events) }
                else { @($EventName) }
                @{ id = $_.id; kind = 'inject'; events = $events; order = $_.order; budget_share = 1.0; command = $_.command }
            })
    } | ConvertTo-Json -Depth 6
    Set-Content -LiteralPath (Join-Path $proj '.specify/extensions/specrew-speckit/refocus-scopes.json') -Value $catalog -Encoding UTF8
    foreach ($p in $Providers) {
        Set-Content -LiteralPath (Join-Path $scriptsDir $p.command) -Value $p.body -Encoding UTF8
    }

    $event = if ($null -ne $EventJson) { $EventJson } else { @{ session_id = $SessionId; source = 'startup'; hook_event_name = $EventName } | ConvertTo-Json -Compress }
    $eventFile = Join-Path $proj 'event.json'
    Set-Content -LiteralPath $eventFile -Value $event -Encoding UTF8 -NoNewline
    $outFile = Join-Path $proj 'd.out'
    $errFile = Join-Path $proj 'd.err'

    $pr = Start-Process -FilePath 'pwsh' `
        -ArgumentList @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $dispatcher, '-Event', $EventName, '-HostKind', $HostKind) `
        -WorkingDirectory $proj -NoNewWindow -PassThru -Wait `
        -RedirectStandardInput $eventFile -RedirectStandardOutput $outFile -RedirectStandardError $errFile

    return [pscustomobject]@{
        Project  = $proj
        ExitCode = $pr.ExitCode
        StdOut   = ((Get-Content -LiteralPath $outFile -Raw -Encoding UTF8 -ErrorAction SilentlyContinue) ?? '')
        StdErr   = ((Get-Content -LiteralPath $errFile -Raw -Encoding UTF8 -ErrorAction SilentlyContinue) ?? '')
    }
}

$bootstrapStub = @'
try { [Console]::OutputEncoding = [System.Text.UTF8Encoding]::new($false) } catch { $null = $_ }
[Console]::Out.Write("[specrew-bootstrap] BOOTSTRAP-CANARY`nMANDATORY FIRST ACTION`n" + ('B' * 1500))
exit 0
'@

$largeRefocusStub = @'
try { [Console]::OutputEncoding = [System.Text.UTF8Encoding]::new($false) } catch { $null = $_ }
[Console]::Out.Write("[specrew-refocus] REF-START`n" + ('R' * 12000) + "`nREF-END")
exit 0
'@

$cap = Invoke-SessionStartDispatcherScenario -Providers @(
    @{ id = 'refocus'; order = 10; command = 'refocus-stub.ps1'; body = $largeRefocusStub }
    @{ id = 'bootstrap'; order = 20; command = 'bootstrap-stub.ps1'; body = $bootstrapStub }
) -SessionId 'cap-policy'
try {
    Assert-True ($cap.ExitCode -eq 0) 'over-cap SessionStart dispatcher exits 0'
    Assert-True ($cap.StdOut.Length -gt 0) 'over-cap SessionStart still emits host-facing output'
    Assert-True ($cap.StdOut.Length -le 10000) ("over-cap SessionStart output is bounded under the host cap (got {0})" -f $cap.StdOut.Length)
    Assert-True ($cap.StdOut.Contains('[specrew-bootstrap] BOOTSTRAP-CANARY')) 'bootstrap fragment survives cap handling intact'
    Assert-True ($cap.StdOut.Contains('MANDATORY FIRST ACTION')) 'bootstrap banner instruction survives cap handling'
    $bootstrapIndex = $cap.StdOut.IndexOf('[specrew-bootstrap] BOOTSTRAP-CANARY')
    $refocusIndex = $cap.StdOut.IndexOf('[specrew-refocus] REF-START')
    Assert-True ($bootstrapIndex -ge 0 -and $refocusIndex -gt $bootstrapIndex) 'bootstrap is composed ahead of lower-priority refocus'
    Assert-True (-not $cap.StdOut.Contains('REF-END')) 'lower-priority refocus is truncated before the tail can overrun the cap'
    Assert-True ($cap.StdErr -match 'PAYLOAD_CLIPPED') 'cap handling is observable on stderr'
}
finally {
    Remove-Item -LiteralPath $cap.Project -Recurse -Force -ErrorAction SilentlyContinue
}

$failingBootstrapStub = @'
[Console]::Error.WriteLine('[specrew-bootstrap] WARN PROVIDER_FAILED intentional bootstrap failure')
exit 0
'@

$fallback = Invoke-SessionStartDispatcherScenario -Providers @(
    @{ id = 'bootstrap'; order = 20; command = 'bootstrap-fails.ps1'; body = $failingBootstrapStub }
) -SessionId 'fallback-policy'
try {
    Assert-True ($fallback.ExitCode -eq 0) 'provider failure dispatcher exits 0'
    Assert-True ($fallback.StdOut.Length -gt 0 -and $fallback.StdOut.Length -lt 10000) 'provider failure emits a non-empty under-cap fallback directive'
    Assert-True ($fallback.StdOut -match 'degraded governed fallback') 'fallback identifies degraded governed mode'
    Assert-True ($fallback.StdOut -match 'Specrew governance is still active') 'fallback states governance remains active'
    Assert-True ($fallback.StdOut -match 'specrew where') 'fallback tells the agent to recover with specrew where'
    Assert-True ($fallback.StdOut -match '/specrew-refocus') 'fallback tells the agent to recover with /specrew-refocus'
    Assert-True ($fallback.StdErr -match 'PROVIDER_FAILED') 'provider failure is observable on stderr'
    Assert-True (-not ($fallback.StdOut -match 'Exception|StackTrace|at line')) 'fallback stdout does not expose raw exception text'
}
finally {
    Remove-Item -LiteralPath $fallback.Project -Recurse -Force -ErrorAction SilentlyContinue
}

$antigravityFallback = Invoke-SessionStartDispatcherScenario -Providers @(
    @{ id = 'bootstrap'; events = @('PreInvocation'); order = 20; command = 'bootstrap-fails.ps1'; body = $failingBootstrapStub }
) -HostKind 'antigravity' -EventName 'PreInvocation' -SessionId 'anti-fallback' -EventJson '{"conversationId":"anti-fallback","workspacePaths":["C:/anti/project"],"hookEventName":"PreInvocation"}'
try {
    Assert-True ($antigravityFallback.ExitCode -eq 0) 'antigravity PreInvocation provider failure dispatcher exits 0'
    $antiJson = $antigravityFallback.StdOut | ConvertFrom-Json
    Assert-True ($null -ne $antiJson.injectSteps -and @($antiJson.injectSteps).Count -eq 1) 'antigravity PreInvocation returns injectSteps JSON'
    $antiMessage = [string]$antiJson.injectSteps[0].ephemeralMessage
    Assert-True ($antiMessage -match 'degraded governed fallback') 'antigravity fallback identifies degraded governed mode'
    Assert-True ($antiMessage -match 'specrew start --host antigravity') 'antigravity fallback tells the agent to recover with specrew start --host antigravity'
    Assert-True ($antigravityFallback.StdErr -match 'PROVIDER_FAILED') 'antigravity provider failure is observable on stderr'
}
finally {
    Remove-Item -LiteralPath $antigravityFallback.Project -Recurse -Force -ErrorAction SilentlyContinue
}

Write-Host "`n=== DispatcherSessionStartPolicy.Tests.ps1: all assertions passed ===" -ForegroundColor Green
