$ErrorActionPreference = 'Stop'

# Feature 185 FR-004 (145 F1/TI-1/F3 regression guard): the DEPLOYED path. The deployed hook bakes a -HostBinding
# (Get-HostRuntimeBindingEncoded) which the dispatcher decodes BEFORE the manifest fallback. If the encoder omits
# StopBlockShape, every deployed project resolves it to 'none' and the entire stop-block delivery is INERT in the
# field while the manifest-path tests (dispatcher-stop-block.tests.ps1) stay green. This test drives the REAL
# deployer, extracts the baked -HostBinding from the generated config, and asserts (a) the decoded binding carries
# StopBlockShape, and (b) feeding that exact baked binding to the REAL dispatcher STILL fires the block envelope.

function Assert-True { param([bool]$Condition, [string]$Message) if (-not $Condition) { throw "FAIL: $Message" } ; Write-Host "PASS: $Message" -ForegroundColor Green }

$repoRoot = (Resolve-Path "$PSScriptRoot/../..").Path
$deployer = Join-Path $repoRoot 'scripts/internal/deploy-refocus-hooks.ps1'
$dispatcher = Join-Path $repoRoot 'scripts/internal/specrew-hook-dispatcher.ps1'

$proj = Join-Path ([System.IO.Path]::GetTempPath()) ('sbdep-' + [guid]::NewGuid().ToString('N'))
$home2 = Join-Path ([System.IO.Path]::GetTempPath()) ('sbhome-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path (Join-Path $proj '.specrew/runtime') -Force | Out-Null
New-Item -ItemType Directory -Path $home2 -Force | Out-Null
try {
    # Run the REAL deployer for claude (project-placeholder mode bakes -HostBinding into .claude/settings.local.json).
    & pwsh -NoProfile -ExecutionPolicy Bypass -File $deployer -ProjectPath $proj -HostKind claude -UserHomeOverride $home2 *> (Join-Path $proj 'deploy.log')
    Assert-True ($LASTEXITCODE -eq 0) 'the real deployer runs clean for claude'

    $cfgPath = Join-Path $proj '.claude/settings.local.json'
    Assert-True (Test-Path -LiteralPath $cfgPath) 'deployer produced .claude/settings.local.json'
    $cfg = Get-Content -LiteralPath $cfgPath -Raw | ConvertFrom-Json
    $stopCmd = [string]$cfg.hooks.Stop[0].hooks[0].command

    # Extract the baked -HostBinding base64 the deployed hook actually passes the dispatcher.
    $m = [regex]::Match($stopCmd, '-HostBinding\s+(\S+)')
    Assert-True ($m.Success) 'the deployed Stop command bakes a -HostBinding'
    $encoded = $m.Groups[1].Value.Trim('"', "'")

    # (a) DECODE the baked binding and assert StopBlockShape is present + correct (the direct F1 catch).
    $decoded = [System.Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($encoded)) | ConvertFrom-Json
    Assert-True ($null -ne $decoded.PSObject.Properties['StopBlockShape']) 'the baked -HostBinding CARRIES StopBlockShape (145 F1: the encoder must not omit it)'
    Assert-True ([string]$decoded.StopBlockShape -eq 'decision-block') "the baked claude StopBlockShape is 'decision-block' (got '$($decoded.StopBlockShape)')"

    # (b) END-TO-END: feed the REAL baked binding to the REAL dispatcher with a stub provider that emits the
    # sentinel, and assert the host envelope STILL fires (the deployed path, not the manifest-fallback path).
    $scriptsDir = Join-Path $proj '.specify/extensions/specrew-speckit/scripts'
    New-Item -ItemType Directory -Path $scriptsDir -Force | Out-Null
    $catalog = @{ schema_version = '1'; providers = @(@{ id = 'stub-block'; kind = 'inject'; events = @('Stop'); order = 40; budget_share = 1.0; command = 'stub-block.ps1' }) } | ConvertTo-Json -Depth 6
    Set-Content -LiteralPath (Join-Path $proj '.specify/extensions/specrew-speckit/refocus-scopes.json') -Value $catalog -Encoding UTF8
    Set-Content -LiteralPath (Join-Path $scriptsDir 'stub-block.ps1') -Value "Write-Output `"<<<SPECREW-STOP-BLOCK>>>`nRENDER THE PACKET NOW`"; exit 0" -Encoding UTF8
    $eventFile = Join-Path $proj 'event.json'
    Set-Content -LiteralPath $eventFile -Value (@{ session_id = 'sbd'; source = 'Stop' } | ConvertTo-Json -Compress) -Encoding UTF8 -NoNewline
    $outFile = Join-Path $proj 'd.out'
    $p = Start-Process -FilePath 'pwsh' `
        -ArgumentList @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $dispatcher, '-Event', 'Stop', '-HostKind', 'claude', '-HostBinding', $encoded) `
        -WorkingDirectory $proj -NoNewWindow -PassThru -Wait `
        -RedirectStandardInput $eventFile -RedirectStandardOutput $outFile -RedirectStandardError (Join-Path $proj 'd.err')
    Assert-True ($p.ExitCode -eq 0) 'dispatcher exits 0 on the deployed-binding path'
    $out = (Get-Content -LiteralPath $outFile -Raw -ErrorAction SilentlyContinue) -replace '\s', ''
    Assert-True ($out -match '"decision":"block"') 'the DEPLOYED baked binding STILL fires the decision:block envelope (145 F1/TI-1 regression guard) - not inert'

    Write-Host "`n=== stopblock-deployed-binding.tests.ps1: all assertions passed ===" -ForegroundColor Green
}
finally {
    Remove-Item -LiteralPath $proj -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item -LiteralPath $home2 -Recurse -Force -ErrorAction SilentlyContinue
}
