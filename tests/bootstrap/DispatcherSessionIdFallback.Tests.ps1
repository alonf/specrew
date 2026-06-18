$ErrorActionPreference = 'Stop'

$dispatcher = (Resolve-Path "$PSScriptRoot/../../scripts/internal/specrew-hook-dispatcher.ps1").Path

function Assert-True {
    param([bool]$Condition, [string]$Message)
    if (-not $Condition) { throw "FAIL: $Message" }
    Write-Host "PASS: $Message" -ForegroundColor Green
}

function Assert-Equal {
    param([AllowNull()]$Actual, [AllowNull()]$Expected, [string]$Message)
    if ($Actual -ne $Expected) { throw "FAIL: $Message (expected '$Expected', got '$Actual')" }
    Write-Host "PASS: $Message" -ForegroundColor Green
}

function New-DispatcherFixture {
    $root = Join-Path ([System.IO.Path]::GetTempPath()) ("specrew-sessionid-" + [guid]::NewGuid().ToString('N'))
    $scripts = Join-Path $root '.specify/extensions/specrew-speckit/scripts'
    New-Item -ItemType Directory -Path (Join-Path $root '.specrew/runtime') -Force | Out-Null
    New-Item -ItemType Directory -Path $scripts -Force | Out-Null

    $catalog = [pscustomobject]@{
        providers = @(
            [pscustomobject]@{
                id      = 'refocus'
                kind    = 'inject'
                events  = @('SessionStart')
                order   = 10
                command = 'fake-refocus.ps1'
            }
        )
    }
    $catalog | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath (Join-Path $root '.specify/extensions/specrew-speckit/refocus-scopes.json') -Encoding UTF8

    @'
param([string[]]$Arguments)
[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new($false)
Write-Output "[specrew-refocus] trigger=b2 scope=test sources=1 tokens~4"
Write-Output ""
Write-Output "fake payload"
'@ | Set-Content -LiteralPath (Join-Path $scripts 'fake-refocus.ps1') -Encoding UTF8

    return $root
}

function Invoke-SessionStart {
    param([string]$ProjectRoot, [string]$EventJson)
    Push-Location $ProjectRoot
    try {
        $before = @(Get-ChildItem -LiteralPath (Join-Path $ProjectRoot '.specrew/runtime') -Filter 'refocus-state-*.json' -File -ErrorAction SilentlyContinue | ForEach-Object { $_.FullName })
        $out = & pwsh -NoProfile -ExecutionPolicy Bypass -File $dispatcher -Event SessionStart -EventJson $EventJson -HostKind claude 2>&1
        Assert-Equal $LASTEXITCODE 0 'dispatcher exits 0'
        Assert-True (($out -join "`n") -match 'fake payload') 'dispatcher injected provider payload'
        $after = @(Get-ChildItem -LiteralPath (Join-Path $ProjectRoot '.specrew/runtime') -Filter 'refocus-state-*.json' -File -ErrorAction Stop)
        $newFiles = @($after | Where-Object { $before -notcontains $_.FullName })
        Assert-Equal $newFiles.Count 1 'one new per-launch refocus state file written'
        return $newFiles[0]
    }
    finally {
        Pop-Location
    }
}

$root = New-DispatcherFixture
try {
    $missing = Invoke-SessionStart -ProjectRoot $root -EventJson '{"source":"startup"}'
    $blank = Invoke-SessionStart -ProjectRoot $root -EventJson '{"session_id":"   ","source":"startup"}'
    $malformed = Invoke-SessionStart -ProjectRoot $root -EventJson '{"session_id":"!!!","source":"startup"}'

    $files = @($missing, $blank, $malformed)
    $tokens = @()
    foreach ($file in $files) {
        Assert-True ($file.Name -match '^refocus-state-launch-[a-f0-9]{32}\.json$') "state file '$($file.Name)' uses a per-launch fallback token"
        $state = Get-Content -LiteralPath $file.FullName -Raw -Encoding UTF8 | ConvertFrom-Json
        Assert-True ([string]$state.session_id -match '^launch-[a-f0-9]{32}$') 'state session_id uses per-launch token'
        Assert-True ([string]$state.session_id -ne 'unknown' -and [string]$state.session_id -ne 'no-session') 'state session_id avoids global fallback buckets'
        $entry = @($state.journal) | Select-Object -Last 1
        Assert-Equal ([string]$entry.outcome) 'injected' 'fallback-token session still journals injection outcome'
        Assert-Equal ([string]$entry.trigger) 'b2' 'fallback-token session still keys breaker/journal trigger'
        $tokens += [string]$state.session_id
    }

    Assert-Equal (@($tokens | Sort-Object -Unique).Count) 3 'missing, blank, and malformed IDs get distinct per-launch tokens'
    Assert-True (-not (Test-Path -LiteralPath (Join-Path $root '.specrew/runtime/refocus-state-unknown.json'))) 'no global refocus-state-unknown.json is written'
    Assert-True (-not (Test-Path -LiteralPath (Join-Path $root '.specrew/runtime/refocus-state-no-session.json'))) 'no global refocus-state-no-session.json is written'
}
finally {
    Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue
}

Write-Host 'DispatcherSessionIdFallback: all tests passed.' -ForegroundColor Green
