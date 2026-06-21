[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Write-Pass { param([string]$Message) Write-Host "PASS: $Message" -ForegroundColor Green }
function Write-Fail { param([string]$Message) Write-Host "FAIL: $Message" -ForegroundColor Red; exit 1 }

# Feature 185 iteration 1: the all-host refocus digests must be harness-free (no host-specific imperative
# or Claude-only skill/tool name) and must instruct EVERY host to emit the verdict marker, while Claude
# keeps its dedicated boundary-stop surface. Guards the #2884 fix against regression.

$repoRoot = (Resolve-Path (Join-Path -Path $PSScriptRoot -ChildPath '..\..')).Path

# SC-002 / FR-002: no host-specific imperative or Claude-only skill/tool name in any all-host digest.
$allHostDigests = @(
    'extensions/specrew-speckit/refocus/general.md',
    'extensions/specrew-speckit/refocus/specify.md',
    '.specify/extensions/specrew-speckit/refocus/general.md',
    '.specify/extensions/specrew-speckit/refocus/specify.md'
)
$leakPattern = 'specrew-gate-stop|AskUserQuestion|on the Claude host|on non-Claude host|Claude host'
foreach ($d in $allHostDigests) {
    $path = Join-Path -Path $repoRoot -ChildPath $d
    if (-not (Test-Path -LiteralPath $path)) { Write-Fail "all-host digest missing: $d" }
    $hits = @(Select-String -Path $path -Pattern $leakPattern)
    if ($hits.Count -gt 0) { Write-Fail "host-specific imperative leaked into all-host digest '$d': $($hits[0].Line.Trim())" }
}
Write-Pass 'SC-002/FR-002: all-host refocus digests are harness-free (no host-specific imperative or Claude-only skill/tool name)'

# FR-006: the cleaned digests instruct EVERY host to emit the SPECREW-VERDICT-BOUNDARY marker, so non-Claude
# (transcript) hosts get their verdicts captured by the existing transcript-gated capture.
$general = Get-Content -LiteralPath (Join-Path $repoRoot 'extensions/specrew-speckit/refocus/general.md') -Raw
$specify = Get-Content -LiteralPath (Join-Path $repoRoot 'extensions/specrew-speckit/refocus/specify.md') -Raw
if ($general -notmatch 'SPECREW-VERDICT-BOUNDARY') { Write-Fail 'general.md rule-9 must instruct emitting the SPECREW-VERDICT-BOUNDARY marker (FR-006)' }
if ($specify -notmatch 'SPECREW-VERDICT-BOUNDARY') { Write-Fail 'specify.md step-6 must instruct emitting the SPECREW-VERDICT-BOUNDARY marker (FR-006)' }
if ($specify -notmatch 'SPECREW-VERDICT-BOUNDARY:\s*intake\s*->\s*specify') { Write-Fail 'specify.md step-6 must use the first-boundary marker intake -> specify so the specify verdict captures (FR-006 / dogfood D-015)' }
Write-Pass 'FR-006: cleaned digests instruct every host to emit the verdict marker'

# Regression guard: Claude keeps its dedicated boundary-stop surface (the gate-stop skill stays host-scoped to claude).
# The host-neutral rule-9 says "use your host's dedicated boundary-stop surface if it has one" - Claude's is this skill.
$gateStop = Join-Path $repoRoot 'extensions/specrew-speckit/squad-templates/skills/gate-stop.md'
if (-not (Test-Path -LiteralPath $gateStop)) { Write-Fail 'Claude gate-stop skill source missing (regression: Claude lost its dedicated boundary-stop surface)' }
$gs = Get-Content -LiteralPath $gateStop -Raw
if ($gs -notmatch '(?m)^host-scope:\s*claude') { Write-Fail 'gate-stop skill must remain host-scope: claude' }
if ($gs -notmatch 'SPECREW-VERDICT-BOUNDARY') { Write-Fail 'gate-stop skill must still emit the verdict marker' }
Write-Pass 'Regression: Claude gate-stop skill remains (host-scope: claude, emits the marker) - its dedicated boundary-stop surface under the host-neutral rule'

# Source <-> .specify mirror parity for the cleaned digests.
foreach ($f in @('refocus/general.md', 'refocus/specify.md')) {
    $s = (Get-FileHash -LiteralPath (Join-Path $repoRoot "extensions/specrew-speckit/$f")).Hash
    $m = (Get-FileHash -LiteralPath (Join-Path $repoRoot ".specify/extensions/specrew-speckit/$f")).Hash
    if ($s -ne $m) { Write-Fail "source/.specify mirror drift for $f" }
}
Write-Pass 'Source <-> .specify mirror parity holds for the cleaned digests'

Write-Host ''
Write-Host 'Host-neutral gate digest cleaning (feature 185 iteration 1): all assertions pass'
exit 0
