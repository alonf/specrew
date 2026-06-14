# F-174 host-delivery policy (banner + per-host pointer/inline + real version).
# Locks in the delivery seam Get-SpecrewContractDeliveryMode:
#   - the orientation BANNER leads every directive on every host (it must never sit after the 45KB inline);
#   - claude + codex get a LEAN POINTER, not the ~45KB inline. codex silently drops the oversized SessionStart
#     additionalContext (rollout-proven); claude's hook STDOUT is capped at 10,000 chars on Claude Code v2.1.177
#     (iter-11 real-host: the inline directive was dropped to a file, the banner never rendered) - DISPROVING the
#     earlier "claude stdout has no cap" premise. Both read files, so both point at the on-disk contract.
#   - copilot + cursor stay INLINE (oversized-drop SUSPECTED, same envelope, but UNVERIFIED; they rendered in-band
#     in the dogfoods - flipping on suspicion would regress a working host). The flip is a one-line change in the
#     seam; this test LOCKS the policy so any change is deliberate, never accidental.
#   - the contract file renders a REAL Specrew version, not "Specrew: unknown" (written in BOTH modes).
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
    # DISTINCT session_id per host: these calls share one $Root, and the F-174 double-render dedupe keys on
    # (session_id, source). A single reused session_id across host calls would (correctly) make calls 2..N
    # dedupe to silence - so give each host its own session id. This is also the REAL shape: one session id
    # belongs to exactly one host/session, never four.
    $evt = '{"source":"startup","session_id":"s1-' + $HostKind + '"}'
    $out = & pwsh -NoProfile -File $provider --event-json $evt --host-kind $HostKind --project-root $Root
    return (($out -join "`n"))
}

$tmp = Join-Path ([System.IO.Path]::GetTempPath()) ("specrew-hostdelivery-" + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path (Join-Path $tmp '.specrew') -Force | Out-Null
$promptFile = Join-Path $tmp '.specrew/last-start-prompt.md'
try {
    # CLAUDE: POINTER (iter-11: hook stdout is capped at 10K too, so the inline directive was dropped). claude
    # does NOT inline the contract; it leads with the banner and points at the on-disk file (the file is the
    # durable reference; the lean directive + bounded resume context fit under the cap).
    $claude = Invoke-Provider -HostKind 'claude' -Root $tmp
    Assert-True ($claude -notmatch 'BEGIN SPECREW LAUNCH CONTRACT') 'claude does NOT inline the ~45KB contract (10K stdout cap disproved the inline premise)'
    Assert-True ($claude -match 'MANDATORY FIRST ACTION') 'claude directive LEADS with the mandatory orientation banner'
    Assert-True ($claude -match 'READ .*last-start-prompt') 'claude directive POINTS at the contract file'
    Assert-True (Test-Path -LiteralPath $promptFile) 'claude path writes last-start-prompt.md (the pointer is alive)'
    $contract = Get-Content -LiteralPath $promptFile -Raw
    Assert-True ($contract -notmatch 'Specrew: unknown') 'contract renders a REAL Specrew version (not unknown)'
    Assert-True ($contract -match 'Specrew: \d') 'contract version line carries a numeric version'

    # CODEX: lean pointer - codex drops the oversized additionalContext and reads files.
    $codex = Invoke-Provider -HostKind 'codex' -Root $tmp
    Assert-True ($codex -notmatch 'BEGIN SPECREW LAUNCH CONTRACT') 'codex does NOT inline the ~45KB contract'
    Assert-True ($codex -match 'MANDATORY FIRST ACTION') 'codex directive STILL leads with the mandatory banner'
    Assert-True ($codex -match 'READ .*last-start-prompt') 'codex directive POINTS at the contract file'
    Assert-True (Test-Path -LiteralPath $promptFile) 'codex path STILL writes last-start-prompt.md (the pointer is alive)'

    # COPILOT + CURSOR: behavior-preserving INLINE (T007/M1). Both deliver SessionStart via additionalContext /
    # additional_context (the SAME envelope codex drops), but the host research matrix documents a size cap ONLY
    # for claude's additionalContext - NONE for copilot/cursor - so an oversized drop is SUSPECTED but UNVERIFIED;
    # both rendered in-band in the dogfoods. The seam keeps them inline; the flip is a one-line change there once
    # confirmed on-host. This test LOCKS the current policy so a flip is deliberate, never accidental.
    $copilot = Invoke-Provider -HostKind 'copilot' -Root $tmp
    Assert-True ($copilot -match 'BEGIN SPECREW LAUNCH CONTRACT') 'copilot remains INLINE (oversized-drop UNVERIFIED; only claude+codex are proven pointers)'
    $cursor = Invoke-Provider -HostKind 'cursor' -Root $tmp
    Assert-True ($cursor -match 'BEGIN SPECREW LAUNCH CONTRACT') 'cursor remains INLINE (oversized-drop UNVERIFIED; only claude+codex are proven pointers)'
    Assert-True ($cursor -match 'MANDATORY FIRST ACTION') 'cursor directive still leads with the mandatory banner'

    # The pointer hosts (claude + codex) must be dramatically smaller than an inline host (copilot) - that size
    # gap IS the cap fix (the ~45KB contract is what overran the 10K hook-output cap).
    Assert-True ($claude.Length -lt ($copilot.Length / 2)) 'claude pointer directive is dramatically smaller than the copilot inline directive'
    Assert-True ($codex.Length -lt ($copilot.Length / 2)) 'codex pointer directive is dramatically smaller than the copilot inline directive'
}
finally {
    Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue
}
Write-Host 'HostDeliveryPolicy: all tests passed.' -ForegroundColor Green
