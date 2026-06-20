[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Write-Pass { param([string]$Message) Write-Host "PASS: $Message" -ForegroundColor Green }
function Write-Fail { param([string]$Message) Write-Host "FAIL: $Message" -ForegroundColor Red; exit 1 }

# Feature 185 FR-015 (F-197 coordination; maintainer rule 2026-06-20): the every-stop re-entry packet rule
# MUST be carried in the refocus CORE (general.md) on every host - it was encoded nowhere today, the drift
# that let within-phase checkpoints skip the packet. The rule extends to every decision-yield stop, NOT only
# formal boundaries, while preserving the clarify/workshop normal path (the F-165 feedback). This is the
# cooperative PREVENTION half of FR-015; the Stop-hook enforcement half rides FR-011 (deferred, verdict-authority).

$repoRoot = (Resolve-Path (Join-Path -Path $PSScriptRoot -ChildPath '..\..')).Path

foreach ($rel in @('extensions/specrew-speckit/refocus/general.md', '.specify/extensions/specrew-speckit/refocus/general.md')) {
    $f = Join-Path $repoRoot $rel
    if (Test-Path -LiteralPath $f) {
        $g = Get-Content -LiteralPath $f -Raw
        if ($g -notmatch '(?i)yield the turn to the human') { Write-Fail "general.md ($rel) must scope rule 9 to every decision-yield stop (FR-015)" }
        if ($g -notmatch '(?i)within-phase task checkpoint') { Write-Fail "general.md ($rel) must require the packet at within-phase checkpoints, not only boundaries (FR-015)" }
        if ($g -notmatch '(?i)clarify-stage ambiguity questions are NOT') { Write-Fail "general.md ($rel) must preserve the clarify/workshop normal path (FR-015 / F-165)" }
    }
}

$src = (Get-FileHash -LiteralPath (Join-Path $repoRoot 'extensions/specrew-speckit/refocus/general.md')).Hash
$mir = Join-Path $repoRoot '.specify/extensions/specrew-speckit/refocus/general.md'
if ((Test-Path -LiteralPath $mir) -and ($src -ne (Get-FileHash -LiteralPath $mir).Hash)) { Write-Fail 'general.md source/.specify mirror drift (FR-015)' }

Write-Pass 'FR-015: the every-stop re-entry packet rule is encoded in the refocus core (general.md), extends to within-phase checkpoints, and preserves the clarify/workshop normal path; source/mirror parity'

Write-Host ''
Write-Host 'Every-stop re-entry packet rule (feature 185 FR-015 prevention half): all assertions pass'
exit 0
