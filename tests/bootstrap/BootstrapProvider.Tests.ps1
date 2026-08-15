$ErrorActionPreference = 'Stop'

$provider = (Resolve-Path "$PSScriptRoot/../../scripts/internal/specrew-bootstrap-provider.ps1").Path

function Assert-True {
    param([bool]$Condition, [string]$Message)
    if (-not $Condition) { throw "FAIL: $Message" }
    Write-Host "PASS: $Message" -ForegroundColor Green
}

$tmp = Join-Path ([System.IO.Path]::GetTempPath()) ("specrew-prov-" + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path (Join-Path $tmp '.specrew') -Force | Out-Null
try {
    # B2 (startup) on a fresh project -> full-bootstrap directive as prose.
    $out = & pwsh -NoProfile -File $provider --event-json '{"source":"startup","session_id":"s1"}' --project-root $tmp
    $text = ($out -join "`n")
    Assert-True ($text -match '\[specrew-bootstrap\]') 'B2 emits the bootstrap banner'
    Assert-True ($text -match 'Bootstrap mode: full') 'fresh project resolves full mode'
    Assert-True ($text -match 'VISIBLE PROSE') 'directive carries the render-first instruction'
    Assert-True ($text -match '(?i)at least two executable actions') 'bootstrap only offers a menu when two real actions exist'
    Assert-True ($text -match '(?i)Pick-feature.*only.*feature') 'Pick-feature is conditional on an existing feature'
    Assert-True ($text -match '(?i)end the turn and wait') 'a rendered intake menu waits for a typed human reply'
    Assert-True ($text -match '(?i)only one executable action.*announce.*proceed') 'a single real intake action is an announcement, not a decorative menu'
    Assert-True ($text -match '(?i)concrete.*request.*no existing feature.*New') 'a concrete fresh-project request deterministically starts New without asking an impossible menu'

    # B1 (compact) -> silent so F-171 B1 is unchanged.
    $out2 = & pwsh -NoProfile -File $provider --event-json '{"source":"compact","session_id":"s1"}' --project-root $tmp
    Assert-True ([string]::IsNullOrWhiteSpace((($out2 -join '')).Trim())) 'compact (B1) produces no bootstrap output'
}
finally {
    Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue
}
Write-Host 'BootstrapProvider: all tests passed.' -ForegroundColor Green
