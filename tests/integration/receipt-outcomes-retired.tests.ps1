#requires -Version 7.0
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Feature 202 iteration 002, T022 (FR-033, DA-5; retro candidate 3).
#
# THE SHARED RECEIPT-OUTCOMES JOURNAL IS RETIRED, NOT LEFT BEHIND. Each session now keeps its reply outcome in its own
# folder (receipt-disclosure case 20 is the two-session regression). A journal left on disk would still be read: agents
# open runtime files directly, so a stale one reads as current. `specrew update` deletes it and says so, and no shipped
# code names it except the update step that removes it.

$script:Failures = 0
function Assert-True { param([bool]$Condition, [string]$Message) if ($Condition) { Write-Host ('  PASS: ' + $Message) } else { Write-Host ('  FAIL: ' + $Message); $script:Failures++ } }

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
Write-Host 'receipt-outcomes-retired'

# Shaped like a project that has been through init, as deployed-extension-marker-on-update builds it: update skips
# .specify entirely when it is absent.
$root = Join-Path ([IO.Path]::GetTempPath()) ('t022-' + [guid]::NewGuid().ToString('N'))
try {
    New-Item -ItemType Directory -Path (Join-Path $root '.specrew/runtime') -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $root '.specify/extensions/specrew-speckit/scripts') -Force | Out-Null
    Set-Content -LiteralPath (Join-Path $root '.specrew/config.yml') -Value "specrew_version: `"0.40.0`"`nbootstrap_mode: `"fixture`"" -Encoding UTF8
    Set-Content -LiteralPath (Join-Path $root '.specify/extensions/specrew-speckit/scripts/placeholder.ps1') -Value '# pre-existing deployment' -Encoding UTF8
    $journal = Join-Path $root '.specrew/runtime/workshop-receipt-outcomes.jsonl'
    Set-Content -LiteralPath $journal -Value '{"schema_version":"1.0","status":"refused","reason":"agenda-not-shown"}' -Encoding UTF8
    $out = (& pwsh -NoProfile -File (Join-Path $repoRoot 'scripts/specrew-update.ps1') -ProjectPath $root *>&1 | Out-String)
    Assert-True ($LASTEXITCODE -eq 0) 'specrew update succeeds'
    Assert-True (-not (Test-Path -LiteralPath $journal)) 'specrew update deletes the old journal'
    Assert-True ($out -match 'runtime-retired-removed') 'and says so in its summary'
}
finally { Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue }

$hits = @(foreach ($dir in 'scripts', 'extensions', 'hosts') {
        Get-ChildItem -LiteralPath (Join-Path $repoRoot $dir) -Recurse -File -Include '*.ps1', '*.psm1' |
            Where-Object { (Get-Content -LiteralPath $_.FullName -Raw) -match 'workshop-receipt-outcomes\.jsonl' } |
            ForEach-Object { [IO.Path]::GetRelativePath($repoRoot, $_.FullName).Replace('\', '/') }
    })
Assert-True ($hits.Count -eq 1 -and $hits[0] -eq 'scripts/specrew-update.ps1') ("no shipped code writes or reads the journal; only the update step names it, to remove it ({0})" -f ($hits -join ', '))

if ($script:Failures -gt 0) { Write-Host ("receipt-outcomes-retired: {0} FAILED" -f $script:Failures); exit 1 }
Write-Host 'receipt-outcomes-retired: all passed'
exit 0
