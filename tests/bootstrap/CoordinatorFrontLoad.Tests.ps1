$ErrorActionPreference = 'Stop'

# F-184 iteration 002 (T004; FR-013/FR-014/FR-018; SC-013/SC-015): the bootstrap directive FRONT-LOADS the
# coordinator posture + the exact anti-specify.exe guard, sourced from the SINGLE packaged fragment
# (Get-SpecrewCoordinatorFragment), ABOVE the banner mandate + the contract body - so a weak model attends to
# the immediate action + guard first, and the bootstrap guard cannot drift from the instruction-file guard.

function Assert-True { param([bool]$Condition, [string]$Message) if (-not $Condition) { throw "FAIL: $Message" } ; Write-Host "PASS: $Message" -ForegroundColor Green }

$repoRoot = (Resolve-Path "$PSScriptRoot/../..").Path
$provider = (Resolve-Path "$repoRoot/scripts/internal/specrew-bootstrap-provider.ps1").Path
$guard = 'Do NOT run the raw specify.exe workflow / bundled SDD engine - it bypasses the governed boundary gates.'

# 1/3: extract Format-BootstrapDirective (its body must NOT run) + read the REAL single-source fragment.
$provSrc = Get-Content -LiteralPath $provider -Raw
$fnMatch = [regex]::Match($provSrc, "(?s)^function Format-BootstrapDirective \{.*?\n\}", [System.Text.RegularExpressions.RegexOptions]::Multiline)
if (-not $fnMatch.Success) { throw 'FAIL: could not extract Format-BootstrapDirective' }
. ([scriptblock]::Create($fnMatch.Value))
. (Join-Path $repoRoot 'scripts/internal/instruction-file-merge.ps1')
$fragment = Get-SpecrewCoordinatorFragment
Assert-True ($fragment -match [regex]::Escape($guard)) '0: the single-source fragment carries the exact FR-013 guard'

$result = [pscustomobject]@{ directive = [pscustomobject]@{ mode = 'full'; required_reads = @('.specrew/last-start-prompt.md', '.specrew/start-context.json'); validation_findings = @() } }
$out = Format-BootstrapDirective -Result $result -ContractBody 'CONTRACT-BODY-MARKER' -InFlight $null -PendingVerdict $null -CoordinatorFragment $fragment

Assert-True ($out -match [regex]::Escape($guard)) '1: the exact FR-013 guard is present in the bootstrap directive (SC-013)'
$coordIdx = $out.IndexOf('SPECREW COORDINATOR (front-loaded')
$bannerIdx = $out.IndexOf('MANDATORY FIRST ACTION')
$contractIdx = $out.IndexOf('CONTRACT-BODY-MARKER')
Assert-True ($coordIdx -ge 0) '1: the front-loaded coordinator block is present'
Assert-True ($coordIdx -lt $bannerIdx) '2: coordinator posture+guard is front-loaded ABOVE the banner mandate (SC-015)'
Assert-True ($coordIdx -lt $contractIdx) '2: coordinator posture+guard is front-loaded ABOVE the contract body (SC-015)'

# 3: omitted when no fragment is supplied (fail-soft / backward-compatible - keeps DirectiveVersionBranch green).
$noFrag = Format-BootstrapDirective -Result $result -ContractBody 'X' -InFlight $null -PendingVerdict $null
Assert-True ($noFrag -notmatch 'SPECREW COORDINATOR \(front-loaded') '3: the coordinator block is omitted when no fragment supplied (fail-soft)'

# 4: the REAL invoked provider front-loads the guard end-to-end (single-source resolution works when invoked).
$tmp = Join-Path ([System.IO.Path]::GetTempPath()) ("specrew-t004-" + [guid]::NewGuid().ToString('N'))
$proj = Join-Path $tmp 'proj'
New-Item -ItemType Directory -Path (Join-Path $proj '.specrew') -Force | Out-Null
try {
    git -C $proj init -q -b main 2>$null; git -C $proj config user.email 't@t' 2>$null; git -C $proj config user.name 't' 2>$null
    Set-Content -LiteralPath (Join-Path $proj 'readme.md') -Value 'x' -Encoding UTF8
    git -C $proj add -A 2>$null; git -C $proj commit -q -m init 2>$null
    $real = (& pwsh -NoProfile -File $provider --event-json '{"source":"startup","session_id":"t004"}' --project-root $proj 2>$null) -join "`n"
    Assert-True ($real -match [regex]::Escape($guard)) '4: the REAL invoked provider front-loads the guard from the single source (FR-018 end-to-end)'
}
finally { Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue }

Write-Host "`n=== CoordinatorFrontLoad.Tests.ps1: all assertions passed ===" -ForegroundColor Green
exit 0
