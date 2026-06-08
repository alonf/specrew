Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

. "$PSScriptRoot/../../scripts/internal/bootstrap/DirectiveEngine.ps1"

function Assert-Equal {
    param([AllowNull()]$Actual, [AllowNull()]$Expected, [string]$Message)
    if ($Actual -ne $Expected) { throw "FAIL: $Message (expected '$Expected', got '$Actual')" }
    Write-Host "PASS: $Message" -ForegroundColor Green
}
function Assert-True {
    param([bool]$Condition, [string]$Message)
    if (-not $Condition) { throw "FAIL: $Message" }
    Write-Host "PASS: $Message" -ForegroundColor Green
}

# render_first is always true (FR-004/FR-020 contract).
$d = New-SpecrewBootstrapDirective -Mode full -DedupeKey 's1'
Assert-True $d.render_first 'render_first is always true'
Assert-Equal $d.mode 'full' 'mode set'
Assert-Equal $d.menu_intent 'resume-new-pick' 'menu intent set'
Assert-Equal $d.dedupe_key 's1' 'dedupe key carried'

# Findings and required reads are carried as arrays.
$d2 = New-SpecrewBootstrapDirective -Mode cleared-anchor -DedupeKey 's2' `
    -ValidationFindings @('cleared: merged') -RequiredReads @('handover.md')
Assert-True ($d2.validation_findings -contains 'cleared: merged') 'validation findings carried'
Assert-True ($d2.required_reads -contains 'handover.md') 'required reads carried'

# An invalid mode is rejected by the ValidateSet.
$threw = $false
try { New-SpecrewBootstrapDirective -Mode bogus -DedupeKey 's3' } catch { $threw = $true }
Assert-True $threw 'invalid mode rejected'

Write-Host 'DirectiveEngine: all tests passed.' -ForegroundColor Green
