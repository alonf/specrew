# F-174 host-delivery policy (banner + codex pointer + real version), 2026-06-10.
# Locks in the three fixes the three-way dogfood drove:
#   - the orientation BANNER leads every directive (was skipped on claude when it sat after the 45KB inline);
#   - codex gets a LEAN POINTER, not the ~50KB inline (codex silently drops the oversized SessionStart
#     additionalContext - rollout-proven - and reads files), while claude/copilot stay INLINE;
#   - the contract renders a REAL Specrew version, not "Specrew: unknown".
$ErrorActionPreference = 'Stop'

$provider = (Resolve-Path "$PSScriptRoot/../../scripts/internal/specrew-bootstrap-provider.ps1").Path

function Assert-True {
    param([bool]$Condition, [string]$Message)
    if (-not $Condition) { throw "FAIL: $Message" }
    Write-Host "PASS: $Message" -ForegroundColor Green
}

function Invoke-Provider {
    param([string]$HostKind, [string]$Root)
    $pf = Join-Path $Root '.specrew/last-start-prompt.md'
    if (Test-Path -LiteralPath $pf) { Remove-Item -LiteralPath $pf -Force }
    $out = & pwsh -NoProfile -File $provider --event-json '{"source":"startup","session_id":"s1"}' --host-kind $HostKind --project-root $Root
    return (($out -join "`n"))
}

$tmp = Join-Path ([System.IO.Path]::GetTempPath()) ("specrew-hostdelivery-" + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path (Join-Path $tmp '.specrew') -Force | Out-Null
$promptFile = Join-Path $tmp '.specrew/last-start-prompt.md'
try {
    # CLAUDE: inline the full contract (claude skips file pointers - the iter-6 disproof).
    $claude = Invoke-Provider -HostKind 'claude' -Root $tmp
    Assert-True ($claude -match 'BEGIN SPECREW LAUNCH CONTRACT') 'claude INLINES the full contract'
    Assert-True ($claude -match 'MANDATORY FIRST ACTION') 'claude directive LEADS with the mandatory orientation banner'
    Assert-True (Test-Path -LiteralPath $promptFile) 'claude path writes last-start-prompt.md'
    $contract = Get-Content -LiteralPath $promptFile -Raw
    Assert-True ($contract -notmatch 'Specrew: unknown') 'contract renders a REAL Specrew version (not unknown)'
    Assert-True ($contract -match 'Specrew: \d') 'contract version line carries a numeric version'

    # CODEX: lean pointer - codex drops the oversized additionalContext and reads files.
    $codex = Invoke-Provider -HostKind 'codex' -Root $tmp
    Assert-True ($codex -notmatch 'BEGIN SPECREW LAUNCH CONTRACT') 'codex does NOT inline the ~50KB contract'
    Assert-True ($codex -match 'MANDATORY FIRST ACTION') 'codex directive STILL leads with the mandatory banner'
    Assert-True ($codex -match 'READ .*last-start-prompt') 'codex directive POINTS at the contract file'
    Assert-True (Test-Path -LiteralPath $promptFile) 'codex path STILL writes last-start-prompt.md (the pointer is alive)'
    Assert-True ($codex.Length -lt ($claude.Length / 2)) 'codex directive is dramatically smaller than claude inline'

    # COPILOT: left native (inline) pending its own empirical test - only codex is a pointer today.
    $copilot = Invoke-Provider -HostKind 'copilot' -Root $tmp
    Assert-True ($copilot -match 'BEGIN SPECREW LAUNCH CONTRACT') 'copilot remains INLINE (only codex is a pointer today)'
}
finally {
    Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue
}
Write-Host 'HostDeliveryPolicy: all tests passed.' -ForegroundColor Green
