[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Write-Pass { param([string]$Message) Write-Host "PASS: $Message" -ForegroundColor Green }
function Write-Fail { param([string]$Message) Write-Host "FAIL: $Message" -ForegroundColor Red; exit 1 }

# Feature 185 FR-014: the launch contract must render the REAL host on a DIRECT launch, not a hardcoded
# 'claude'. The host is baked per-host into the hook registration (-HostKind <host>) -> dispatcher -> the
# bootstrap provider's $hostKind. The provider must THREAD that into Write-SpecrewLaunchContractArtifact,
# and the writer must env-detect (reusing the tested Get-SpecrewRuntimeHostFromEnv) before the 'claude'
# last-resort. Dogfood (test-f185): agy / Gemini 3.5 Flash read "Host: claude" because the regeneration
# call dropped the host it already had in hand.

$repoRoot = (Resolve-Path (Join-Path -Path $PSScriptRoot -ChildPath '..\..')).Path

$prov = Get-Content -LiteralPath (Join-Path $repoRoot 'extensions/specrew-speckit/scripts/specrew-bootstrap-provider.ps1') -Raw
if ($prov -notmatch 'Write-SpecrewLaunchContractArtifact[^\r\n]*-HostKind \$hostKind') { Write-Fail 'provider must thread -HostKind $hostKind into Write-SpecrewLaunchContractArtifact (FR-014)' }
# B3 (145 review): the scripts/internal twin must ALSO carry the fix - BOTH copies ship and the dispatcher
# may resolve either. The first cut fixed only the extensions/ copy; the internal twin kept the old line.
$provTwin = Get-Content -LiteralPath (Join-Path $repoRoot 'scripts/internal/specrew-bootstrap-provider.ps1') -Raw
if ($provTwin -notmatch 'Write-SpecrewLaunchContractArtifact[^\r\n]*-HostKind \$hostKind') { Write-Fail 'the scripts/internal provider twin must ALSO thread -HostKind $hostKind (FR-014, B3 parity)' }

$wr = Get-Content -LiteralPath (Join-Path $repoRoot 'scripts/internal/bootstrap/SessionBootstrapManager.ps1') -Raw
if ($wr -notmatch 'Get-SpecrewRuntimeHostFromEnv') { Write-Fail 'the contract writer must env-detect the host before defaulting (FR-014)' }
# The old bare param default (ValidatePattern ... HostKind = 'claude') must be gone.
if ($wr -match "ValidatePattern\([^\r\n]*\]\[string\] \`$HostKind = 'claude'") { Write-Fail 'the contract writer must NOT bare-default HostKind to claude in the param block (FR-014)' }

# Provider source <-> .specify mirror parity (the deployed copy must match).
$provSrcHash = (Get-FileHash -LiteralPath (Join-Path $repoRoot 'extensions/specrew-speckit/scripts/specrew-bootstrap-provider.ps1')).Hash
$provMir = Join-Path $repoRoot '.specify/extensions/specrew-speckit/scripts/specrew-bootstrap-provider.ps1'
if ((Test-Path -LiteralPath $provMir) -and ($provSrcHash -ne (Get-FileHash -LiteralPath $provMir).Hash)) { Write-Fail 'provider source/.specify mirror drift (FR-014)' }

Write-Pass 'FR-014: provider threads the real host into the contract writer; writer env-detects before the claude last-resort; source/mirror parity'

Write-Host ''
Write-Host 'Host-identity runtime correctness (feature 185 FR-014): all assertions pass'
exit 0
