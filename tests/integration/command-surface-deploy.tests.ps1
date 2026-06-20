[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Write-Pass { param([string]$Message) Write-Host "PASS: $Message" -ForegroundColor Green }
function Write-Fail { param([string]$Message) Write-Host "FAIL: $Message" -ForegroundColor Red; exit 1 }

# Feature 185 FR-013 part 2: specrew init must build the native Spec Kit command surface for the
# PALETTE hosts (Claude, Antigravity) via `specify integration install <host> --force`, not just
# Copilot. NOTE (145 review): this test STATICALLY guards that specrew-init.ps1 WIRES the integration
# installs; the 20+20 skill deploy (.claude + .agents) was confirmed in a one-time fresh-init dogfood, NOT
# by this test body, which does not run init. Guards the
# #2884 4th face: a palette-host (Claude) was told to use /speckit.* with nothing deployed.

$repoRoot = (Resolve-Path (Join-Path -Path $PSScriptRoot -ChildPath '..\..')).Path
$init = Get-Content -LiteralPath (Join-Path $repoRoot 'scripts/specrew-init.ps1') -Raw

if ($init -notmatch "'integration',\s*'install'") { Write-Fail 'specrew-init must run `specify integration install` to deploy per-host native commands (FR-013)' }
if ($init -notmatch '--force') { Write-Fail 'integration install must use --force (copilot is not multi-install-safe) (FR-013)' }
foreach ($h in @('claude', 'agy')) {
    if ($init -notmatch "'$h'") { Write-Fail "specrew-init must install the '$h' palette-host integration (FR-013)" }
}
# Must go through the encoding-safe wrapper (raw `specify` calls hit a UnicodeEncodeError on non-UTF8 consoles).
if ($init -notmatch 'Invoke-NativeCommandForOutput') { Write-Fail 'integration install must go through Invoke-NativeCommandForOutput (encoding-safe wrapper) (FR-013)' }
# Non-fatal: a failed install must NOT abort init (the host falls back to the governed scripts).
if ($init -notmatch 'non-fatal') { Write-Fail 'a failed integration install must be non-fatal (host falls back to governed scripts) (FR-013)' }
Write-Pass 'FR-013 part 2: specrew init installs the per-host native Spec Kit command surface for the palette-hosts (claude, agy) via integration install --force, through the encoding-safe wrapper, non-fatally'

Write-Host ''
Write-Host 'Per-host command-surface deploy (feature 185 FR-013 part 2): all assertions pass'
exit 0
