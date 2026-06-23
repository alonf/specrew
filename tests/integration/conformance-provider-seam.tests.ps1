[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Write-Pass { param([string]$Message) Write-Host "PASS: $Message" -ForegroundColor Green }
function Write-Fail { param([string]$Message) Write-Host "FAIL: $Message" -ForegroundColor Red; exit 1 }

# Feature 185 FR-011 seam: the conformance detection rides the EXISTING hook dispatcher + provider catalog
# (refocus-scopes.json) as a Stop provider - NOT a new seam, NOT a HandoverStore edit. (Maintainer
# correction: the dispatcher + catalog already ARE the multi-consumer Stop-hook seat; the handover provider
# already runs on Stop.) This file guards the SEAM contract: registration, the double-dash arg-binding (B1),
# isolation (read-only consumer), and source/.specify mirror parity. The DETECTION behaviour (fires on the
# #2884 silent advance, suppresses on a rendered packet, #1/#3 redirects, idempotence, runtime isolation) is
# proven against realistic fixtures in conformance-detection.tests.ps1 (SC-008 / SC-011).

$repoRoot = (Resolve-Path (Join-Path -Path $PSScriptRoot -ChildPath '..\..')).Path

$catalog = Get-Content -LiteralPath (Join-Path $repoRoot 'extensions/specrew-speckit/refocus-scopes.json') -Raw | ConvertFrom-Json
$conf = @($catalog.providers) | Where-Object { $_.id -eq 'conformance' }
if (-not $conf) { Write-Fail 'refocus-scopes.json must register the conformance provider (FR-011 reuses the existing dispatcher seam)' }
if ($conf.kind -ne 'inject') { Write-Fail 'conformance provider must be kind=inject (rides the existing inject dispatch path)' }
if (@($conf.events) -notcontains 'Stop') { Write-Fail 'conformance provider must run on the Stop event' }

$cmd = Join-Path $repoRoot ('extensions/specrew-speckit/scripts/' + [string]$conf.command)
if (-not (Test-Path -LiteralPath $cmd)) { Write-Fail "conformance provider command ($($conf.command)) must exist" }
$errs = $null; $null = [System.Management.Automation.Language.Parser]::ParseFile($cmd, [ref]$null, [ref]$errs)
if ($errs) { Write-Fail "conformance provider must parse clean ($($errs.Count) errors)" }

# C1 (145 review): DISPATCH the provider the way the dispatcher does - DOUBLE-dash flags - and prove it binds
# them, exits 0, emits nothing, and warns nothing. Run from a NON-governed temp dir (no .specrew) so the
# provider early-returns at the governance-root check -> a GUARANTEED silent no-op, decoupled from this repo's
# own lifecycle state (not coupled to whatever boundary the worktree happens to be at). A param()/[CmdletBinding()]
# block would bind `--host-kind` as `-host-kind` and exit 1 on EVERY Stop (B1) while ParseFile stays green;
# "parses clean" is therefore NOT sufficient.
$tmp = Join-Path ([System.IO.Path]::GetTempPath()) ('specrew-conf-seam-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $tmp -Force | Out-Null
try {
    $dispatchCmd = "Set-Location -LiteralPath '$tmp'; & '$cmd' --host-kind claude --source-event Stop --transcript-path 'x'"
    $provOut = (& pwsh -NoProfile -ExecutionPolicy Bypass -Command $dispatchCmd 2>&1)
    $provCode = $LASTEXITCODE
}
finally { Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue }
if ($provCode -ne 0) { Write-Fail "conformance provider must exit 0 when dispatched with double-dash args (B1: a param() block exits 1); got exit $provCode" }
if (@($provOut | Where-Object { $_ -match 'PROVIDER_FAILED|cannot be found that matches parameter|ParameterBinding' }).Count -gt 0) { Write-Fail 'conformance provider must NOT emit a binding / PROVIDER_FAILED error on dispatch (B1)' }
if (@($provOut | Where-Object { $_ -match '\S' }).Count -gt 0) { Write-Fail 'conformance provider must be a SILENT no-op outside a governed root (emit nothing); it produced output' }

# Isolation: it is a READ-ONLY consumer - it must NEVER call the verdict-authority write path (M2: anchor
# [\s(;] so a `;`- or `(`-form call is caught too, not only the space-separated idiom).
$body = Get-Content -LiteralPath $cmd -Raw
if ($body -match 'Add-SpecrewBoundaryAuthorization[\s(;]|Write-SpecrewRollingHandover[\s(;]') { Write-Fail 'conformance provider must NOT call the verdict-authority write path - it is a read-only consumer (FR-011 isolation)' }

# Source/.specify mirror parity (catalog + provider).
foreach ($pair in @(
        @('extensions/specrew-speckit/refocus-scopes.json', '.specify/extensions/specrew-speckit/refocus-scopes.json'),
        @('extensions/specrew-speckit/scripts/specrew-conformance-provider.ps1', '.specify/extensions/specrew-speckit/scripts/specrew-conformance-provider.ps1'))) {
    $s = Join-Path $repoRoot $pair[0]; $m = Join-Path $repoRoot $pair[1]
    if ((Test-Path -LiteralPath $m) -and ((Get-FileHash -LiteralPath $s).Hash -ne (Get-FileHash -LiteralPath $m).Hash)) { Write-Fail "source/.specify mirror drift: $($pair[0])" }
}

Write-Pass 'FR-011 seam: conformance detection registered as a Stop provider on the EXISTING dispatcher (kind=inject, isolated read-only consumer, binds double-dash args, silent no-op outside a governed root); source/mirror parity'

Write-Host ''
Write-Host 'Conformance provider seam (feature 185 FR-011): all assertions pass'
exit 0
