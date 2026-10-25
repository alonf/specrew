$ErrorActionPreference = 'Stop'

# F-184 iteration 002 (T004; FR-013/FR-014/FR-018; SC-013/SC-015), amended by beta3's measured register fix:
# the bootstrap directive front-loads the project-rules register + its anti-specify.exe guard, sourced from the
# single packaged fragment (Get-SpecrewCoordinatorFragment), above the session-state orientation + contract body.
# This deliberately proves the non-persona, non-mandate register that reasoning-capable hosts accept as project
# context; restoring the former coordinator identity / loud mandate would restore the measured injection shape.

function Assert-True { param([bool]$Condition, [string]$Message) if (-not $Condition) { throw "FAIL: $Message" } ; Write-Host "PASS: $Message" -ForegroundColor Green }

$repoRoot = (Resolve-Path "$PSScriptRoot/../..").Path
$provider = (Resolve-Path "$repoRoot/scripts/internal/specrew-bootstrap-provider.ps1").Path
$guardPattern = 'The raw, un-governed\s+`specify\.exe workflow` and the bundled SDD automation bypass the boundary gates and are not used here\s+—\s+the Specrew-governed scripts above are not that\.'

# 1/3: extract Format-BootstrapDirective (its body must NOT run) + read the REAL single-source fragment.
$provSrc = Get-Content -LiteralPath $provider -Raw
$fnMatch = [regex]::Match($provSrc, "(?s)^function Format-BootstrapDirective \{.*?\n\}", [System.Text.RegularExpressions.RegexOptions]::Multiline)
if (-not $fnMatch.Success) { throw 'FAIL: could not extract Format-BootstrapDirective' }
. ([scriptblock]::Create($fnMatch.Value))
. (Join-Path $repoRoot 'scripts/internal/instruction-file-merge.ps1')
$fragment = Get-SpecrewCoordinatorFragment
Assert-True ($fragment -match $guardPattern) '0: the single-source project-rules fragment carries the FR-013 guard'

$result = [pscustomobject]@{ directive = [pscustomobject]@{ mode = 'full'; required_reads = @('.specrew/last-start-prompt.md', '.specrew/start-context.json'); validation_findings = @() } }
$out = Format-BootstrapDirective -Result $result -ContractBody 'CONTRACT-BODY-MARKER' -InFlight $null -PendingVerdict $null -CoordinatorFragment $fragment

Assert-True ($out -match $guardPattern) '1: the FR-013 guard is present in the bootstrap directive (SC-013)'
$coordIdx = $out.IndexOf('=== HOW THIS PROJECT WORKS')
$bannerIdx = $out.IndexOf('=== SESSION STATE, AND WHAT THIS PROJECT OPENS A SESSION WITH ===')
$contractIdx = $out.IndexOf('CONTRACT-BODY-MARKER')
Assert-True ($coordIdx -ge 0) '1: the front-loaded project-rules block is present'
Assert-True ($bannerIdx -gt $coordIdx) '2: project rules + guard are front-loaded above session-state orientation (SC-015)'
Assert-True ($contractIdx -gt $coordIdx) '2: project rules + guard are front-loaded above the contract body (SC-015)'

# 3: omitted when no fragment is supplied (fail-soft / backward-compatible - keeps DirectiveVersionBranch green).
$noFrag = Format-BootstrapDirective -Result $result -ContractBody 'X' -InFlight $null -PendingVerdict $null
Assert-True ($noFrag -notmatch '=== HOW THIS PROJECT WORKS') '3: the project-rules block is omitted when no fragment supplied (fail-soft)'

# 4: the REAL invoked provider front-loads the guard end-to-end (single-source resolution works when invoked).
$tmp = Join-Path ([System.IO.Path]::GetTempPath()) ("specrew-t004-" + [guid]::NewGuid().ToString('N'))
$proj = Join-Path $tmp 'proj'
New-Item -ItemType Directory -Path (Join-Path $proj '.specrew') -Force | Out-Null
try {
    git -C $proj init -q -b main 2>$null; git -C $proj config user.email 't@t' 2>$null; git -C $proj config user.name 't' 2>$null
    Set-Content -LiteralPath (Join-Path $proj 'readme.md') -Value 'x' -Encoding UTF8
    git -C $proj add -A 2>$null; git -C $proj commit -q -m init 2>$null
    $real = (& pwsh -NoProfile -File $provider --event-json '{"source":"startup","session_id":"t004"}' --project-root $proj 2>$null) -join "`n"
    Assert-True ($real -match $guardPattern) '4: the REAL invoked provider front-loads the guard from the single source (FR-018 end-to-end)'
}
finally { Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue }

Write-Host "`n=== CoordinatorFrontLoad.Tests.ps1: all assertions passed ===" -ForegroundColor Green
exit 0
