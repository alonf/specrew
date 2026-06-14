$ErrorActionPreference = 'Stop'

# F-174 iteration 011 (T009, DF-2, FR-002): the bootstrap directive carries the RESOLVED Specrew version +
# branch as LITERAL values, so a pointer-mode host (codex - it does NOT inline the contract) renders a complete
# orientation banner item 2 instead of "version/branch not resolved" (the iteration-010 codex pointer-banner
# gap). Proves: (1) Format-BootstrapDirective embeds the values when given + omits the line when not (and omits
# a single missing value); (2) the REAL provider resolves the manifest version + the git branch and emits them.

function Assert-True { param([bool]$Condition, [string]$Message) if (-not $Condition) { throw "FAIL: $Message" } ; Write-Host "PASS: $Message" -ForegroundColor Green }

$repoRoot = (Resolve-Path "$PSScriptRoot/../..").Path
$provider = (Resolve-Path "$repoRoot/scripts/internal/specrew-bootstrap-provider.ps1").Path
$manifestVersion = [string]((Import-PowerShellDataFile -Path (Join-Path $repoRoot 'Specrew.psd1')).ModuleVersion)

# --- 1/2: Format-BootstrapDirective embeds / omits the resolved-values line (extract it; its body must not run). ---
$provSrc = Get-Content -LiteralPath $provider -Raw
$fnMatch = [regex]::Match($provSrc, "(?s)^function Format-BootstrapDirective \{.*?\n\}", [System.Text.RegularExpressions.RegexOptions]::Multiline)
if (-not $fnMatch.Success) { throw 'FAIL: could not extract Format-BootstrapDirective' }
. ([scriptblock]::Create($fnMatch.Value))
$result = [pscustomobject]@{ directive = [pscustomobject]@{ mode = 'full'; required_reads = @('.specrew/last-start-prompt.md', '.specrew/start-context.json'); validation_findings = @() } }

$withVals = Format-BootstrapDirective -Result $result -ContractBody '' -InFlight $null -PendingVerdict $null -SpecrewVersion '0.99.0-test' -Branch '174-test-branch'
Assert-True ($withVals -match 'Resolved for THIS session') '1: the resolved-values line is present when version + branch are supplied'
Assert-True ($withVals -match 'Specrew version 0\.99\.0-test') '1: the literal version is embedded in the directive'
Assert-True ($withVals -match 'branch 174-test-branch') '1: the literal branch is embedded in the directive'

$noVals = Format-BootstrapDirective -Result $result -ContractBody '' -InFlight $null -PendingVerdict $null
Assert-True ($noVals -notmatch 'Resolved for THIS session') '2: no resolved-values line when version/branch are absent (backward-compatible)'

$onlyVer = Format-BootstrapDirective -Result $result -ContractBody '' -InFlight $null -PendingVerdict $null -SpecrewVersion '1.2.3'
$onlyVerLine = @(@($onlyVer -split "`n") | Where-Object { $_ -match 'Resolved for THIS session' })[0]
Assert-True ($onlyVerLine -match 'Specrew version 1\.2\.3') '2: a single resolved value (version only) is embedded'
Assert-True ($onlyVerLine -notmatch 'branch') '2: the unresolved value (branch) is omitted, not rendered blank'

# --- 3: the REAL provider resolves the manifest version + the git branch and emits them. ---
$tmp = Join-Path ([System.IO.Path]::GetTempPath()) ("specrew-t009-" + [guid]::NewGuid().ToString('N'))
$proj = Join-Path $tmp 'proj'
New-Item -ItemType Directory -Path (Join-Path $proj '.specrew') -Force | Out-Null
try {
    git -C $proj init -q -b main 2>$null; git -C $proj config user.email 't@t' 2>$null; git -C $proj config user.name 't' 2>$null
    Set-Content -LiteralPath (Join-Path $proj 'readme.md') -Value 'x' -Encoding UTF8
    git -C $proj add -A 2>$null; git -C $proj commit -q -m init 2>$null
    git -C $proj checkout -q -b '174-test-branch' 2>$null
    $out = & pwsh -NoProfile -File $provider --event-json '{"source":"startup","session_id":"t009"}' --project-root $proj 2>$null
    $text = ($out -join "`n")
    Assert-True ($text -match 'Resolved for THIS session') '3: the real provider emits the resolved-values line'
    Assert-True ($text -match ('Specrew version ' + [regex]::Escape($manifestVersion))) "3: the real provider resolves the manifest version ($manifestVersion)"
    Assert-True ($text -match 'branch 174-test-branch') '3: the real provider resolves the git branch and embeds it'
}
finally { Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue }

Write-Host "`n=== DirectiveVersionBranch.Tests.ps1: all assertions passed (resolved version + branch embedded for pointer-mode banners) ===" -ForegroundColor Green
exit 0
