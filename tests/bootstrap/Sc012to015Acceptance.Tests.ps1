$ErrorActionPreference = 'Stop'

# F-174 iteration 011 (T007, SC-012/013/014/015): the DETERMINISTIC SC-ACCEPTANCE CONSOLIDATION.
#
# Each of the four iteration-011 success criteria already has its authoritative deterministic proof in a
# component suite (written alongside T001-T006). This binds them into ONE auditable, runnable acceptance:
# for every SC it asserts the proof FILE(s) EXIST, RUNS each unique proof, and asserts it is GREEN — so
# "every iteration-011 SC has a present + passing deterministic proof" becomes a single command, and
# deleting or breaking any SC's proof fails loudly HERE. It deliberately does NOT re-assert the component
# behaviors (that would duplicate the suites it orchestrates); it is the traceability + green-together gate
# that complements the real-host re-dogfood (the falsification lesson: deterministic green is necessary,
# not sufficient — the re-dogfood remains the acceptance gate; this is its deterministic floor).

function Assert-True { param([bool]$Condition, [string]$Message) if (-not $Condition) { throw "FAIL: $Message" } ; Write-Host "PASS: $Message" -ForegroundColor Green }

$root = (Resolve-Path "$PSScriptRoot/../..").Path

# SC -> { Why; Proofs[] }. Each proof is a deterministic test file (repo-relative). A proof may cover more
# than one SC (e.g. HookPacketCapture/HandoverAuthorCommand prove BOTH the SC-012 round-trip and the SC-015
# clobber guard); the unique set is run once.
$matrix = @(
    [pscustomobject]@{ Sc = 'SC-012'; Why = 'a boundary handover carries the agent-rendered packet + active_boundary; a resume inherits the AUTHORED packet (not placeholders)';
        Proofs = @('tests/bootstrap/HookPacketCapture.Tests.ps1', 'tests/bootstrap/HandoverAuthorCommand.Tests.ps1') }
    [pscustomobject]@{ Sc = 'SC-013'; Why = 'no captured human verdict -> un-authorized (never approved-attributed-to-committer); a captured verdict -> unattributed unless a host surface proves identity (never fabricated)';
        Proofs = @('tests/bootstrap/HookVerdictCapture.Tests.ps1', 'tests/integration/verdict-capture-blocks.tests.ps1', 'tests/integration/boundary-sync-atomic.tests.ps1') }
    [pscustomobject]@{ Sc = 'SC-014'; Why = 'a committed-but-unverdicted boundary surfaces "AWAITING YOUR VERDICT" on resume + specrew where; never auto-advances on a bare "continue"';
        Proofs = @('tests/integration/pending-verdict-surface.tests.ps1') }
    [pscustomobject]@{ Sc = 'SC-015'; Why = 'the Stop-hook mechanical capture MUST NOT overwrite an authored, richer body with a placeholder/stale one, and MUST set active_boundary';
        Proofs = @('tests/bootstrap/HookPacketCapture.Tests.ps1', 'tests/bootstrap/HandoverAuthorCommand.Tests.ps1') }
)

# 1. Every SC's proof file(s) EXIST — the proof is present, not just promised.
foreach ($row in $matrix) {
    foreach ($p in $row.Proofs) {
        Assert-True (Test-Path -LiteralPath (Join-Path $root $p)) ("{0}: proof present -> {1}" -f $row.Sc, $p)
    }
}

# 2. Run each UNIQUE proof file once; assert GREEN (the whole SC set passes TOGETHER, not just in isolation).
$unique = @($matrix | ForEach-Object { $_.Proofs } | Select-Object -Unique)
foreach ($p in $unique) {
    $full = Join-Path $root $p
    & pwsh -NoProfile -ExecutionPolicy Bypass -File $full *> $null
    Assert-True ($LASTEXITCODE -eq 0) ("proof GREEN -> {0}" -f $p)
}

# 3. Emit the SC -> proof matrix (the auditable acceptance record).
Write-Host "`nIteration-011 SC-012..015 deterministic acceptance matrix:" -ForegroundColor Cyan
foreach ($row in $matrix) {
    Write-Host ("  {0}  [{1}]" -f $row.Sc, (($row.Proofs | ForEach-Object { Split-Path -Leaf $_ }) -join ', ')) -ForegroundColor Green
    Write-Host ("        {0}" -f $row.Why) -ForegroundColor DarkGray
}

Write-Host "`n=== Sc012to015Acceptance.Tests.ps1: every iteration-011 SC has a present + GREEN deterministic proof ===" -ForegroundColor Green
exit 0
