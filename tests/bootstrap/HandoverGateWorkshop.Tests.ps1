$ErrorActionPreference = 'Stop'

# F-174 iteration 010 (T003). Floor for the AUTHORIZED-gate + workshop-phase handover frontmatter (FR-022).
# Pins four behaviors of Write-SpecrewRollingHandoverContent / ConvertFrom-SpecrewHandoverFile: write+read
# round-trip, conditional emission (quiet when absent), the agent-author PRESERVE (unbound -> inherit), and
# the hook CLEAR (bound-but-empty -> remove). Hermetic: HandoverStore I/O + temp files only (no git/provider).

. "$PSScriptRoot/../../scripts/internal/bootstrap/HandoverStore.ps1"
function Assert-True { param([bool]$Condition, [string]$Message) if (-not $Condition) { throw "FAIL: $Message" } ; Write-Host "PASS: $Message" -ForegroundColor Green }

$tmp = Join-Path ([System.IO.Path]::GetTempPath()) ("t003-" + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $tmp -Force | Out-Null
$path = Join-Path $tmp 'session-handover.md'
try {
    # 1. WRITE + READ round-trip: the gate (distinct from the working position) + workshop phase.
    Write-SpecrewRollingHandoverContent -Path $path -Source 'Stop' -FromHost 'claude' -RecordedAt '2026-06-12T00:00:00Z' `
        -ActiveBoundary 'implement' -ActiveFeature 'feat-x' `
        -LastAuthorizedBoundary 'plan' -LastVerdict 'approved for plan by Alon Fliess @abc1234' `
        -WorkshopDone 'product-domain' -WorkshopRemaining 'security-compliance, integration-api' -Sections @{} | Out-Null
    $p = ConvertFrom-SpecrewHandoverFile -Path $path
    Assert-True ($p.active_boundary -eq 'implement') 'round-trip: active_boundary = the WORKING position'
    Assert-True ($p.last_authorized_boundary -eq 'plan') 'round-trip: last_authorized_boundary = the AUTHORIZED gate (distinct)'
    Assert-True ($p.last_verdict -eq 'approved for plan by Alon Fliess @abc1234') 'round-trip: last_verdict (text + human + commit)'
    Assert-True ($p.workshop_done -eq 'product-domain') 'round-trip: workshop_done'
    Assert-True ($p.workshop_remaining -eq 'security-compliance, integration-api') 'round-trip: workshop_remaining (comma value survives)'

    # 2. CONDITIONAL emission: absent fields produce NO frontmatter line (quiet outside the intake window).
    $bare = Join-Path $tmp 'bare.md'
    Write-SpecrewRollingHandoverContent -Path $bare -Source 'Stop' -FromHost 'claude' -RecordedAt 't' -ActiveBoundary 'implement' -Sections @{} | Out-Null
    $bareText = Get-Content -LiteralPath $bare -Raw
    Assert-True (-not ($bareText -match 'last_authorized_boundary:')) 'conditional: no gate line when not supplied'
    Assert-True (-not ($bareText -match 'workshop_done:')) 'conditional: no workshop line when not supplied'

    # 3. PRESERVE: a re-write that does NOT supply the T003 params (the agent body-author) inherits them.
    Write-SpecrewRollingHandoverContent -Path $path -Source 'agent' -FromHost 'claude' -RecordedAt '2026-06-12T01:00:00Z' `
        -ActiveBoundary 'implement' -ActiveFeature 'feat-x' -Sections @{ 'Open questions / pending clarifications' = 'an agent question' } | Out-Null
    $p3 = ConvertFrom-SpecrewHandoverFile -Path $path
    Assert-True ($p3.last_authorized_boundary -eq 'plan') 'preserve: unbound gate inherited from the existing file'
    Assert-True ($p3.workshop_remaining -eq 'security-compliance, integration-api') 'preserve: unbound workshop inherited'
    Assert-True ($p3.sections['Open questions / pending clarifications'] -eq 'an agent question') 'preserve: the agent body still wrote'

    # 4. CLEAR: a re-write that supplies EMPTY T003 params (bound) removes them (the workshop-complete case).
    Write-SpecrewRollingHandoverContent -Path $path -Source 'Stop' -FromHost 'claude' -RecordedAt '2026-06-12T02:00:00Z' `
        -ActiveBoundary 'specify' -ActiveFeature 'feat-x' `
        -LastAuthorizedBoundary '' -LastVerdict '' -WorkshopDone '' -WorkshopRemaining '' -Sections @{} | Out-Null
    $clearText = Get-Content -LiteralPath $path -Raw
    Assert-True (-not ($clearText -match 'last_authorized_boundary:')) 'clear: bound-empty removes the gate line'
    Assert-True (-not ($clearText -match 'workshop_remaining:')) 'clear: bound-empty removes the workshop line'

    Write-Host "`n=== HandoverGateWorkshop.Tests.ps1: all assertions passed ===" -ForegroundColor Green
}
finally { Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue }
