[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Write-Pass { param([string]$Message) Write-Host "PASS: $Message" -ForegroundColor Green }
function Write-Fail { param([string]$Message) Write-Host "FAIL: $Message" -ForegroundColor Red; exit 1 }

$repoRoot = (Resolve-Path (Join-Path -Path $PSScriptRoot -ChildPath '..\..')).Path
$syncBoundaryScript = Join-Path -Path $repoRoot -ChildPath 'scripts\internal\sync-boundary-state.ps1'

# Structural tests

# Test 1: Invoke-PreFeatureCloseoutWorkingTreeGate function exists
$syncBoundaryContent = Get-Content -LiteralPath $syncBoundaryScript -Raw -Encoding UTF8
if ($syncBoundaryContent -notmatch 'function Invoke-PreFeatureCloseoutWorkingTreeGate\b') {
    Write-Fail 'Invoke-PreFeatureCloseoutWorkingTreeGate function not found in sync-boundary-state.ps1'
}
Write-Pass 'Invoke-PreFeatureCloseoutWorkingTreeGate helper present in sync-boundary-state.ps1'

# Test 2: Gate is wired into Invoke-SpecrewBoundaryStateSync
if ($syncBoundaryContent -notmatch 'Invoke-PreFeatureCloseoutWorkingTreeGate -ProjectPath \$ProjectPath -BoundaryType \$BoundaryType') {
    Write-Fail 'Invoke-PreFeatureCloseoutWorkingTreeGate is not invoked from Invoke-SpecrewBoundaryStateSync'
}
Write-Pass 'Gate is wired into the boundary-sync flow'

# Test 3: Gate is gated by feature-closeout boundary check
if ($syncBoundaryContent -notmatch "if \(\`$BoundaryType -ne 'feature-closeout'\) \{ return \}") {
    Write-Fail 'Gate does not have the feature-closeout boundary type check'
}
Write-Pass 'Gate fires only at feature-closeout boundary (not earlier boundaries)'

# Test 4: Excludes session-state paths
foreach ($pattern in @('last-validator-summary', 'start-context', 'now\\.md', 'feature\\.json', 'closeout-dashboard')) {
    if ($syncBoundaryContent -notmatch $pattern) {
        Write-Fail "Gate exclusion pattern '$pattern' not found"
    }
}
Write-Pass 'Gate exclusion patterns cover session-state churn'

# Test 5: Includes feature-implementation paths
foreach ($pattern in @("\^scripts/", "\^extensions/", "\^\\.specify/", "\^tests/", "\^README", "\^CHANGELOG")) {
    if ($syncBoundaryContent -notmatch $pattern) {
        Write-Fail "Gate relevance pattern '$pattern' not found"
    }
}
Write-Pass 'Gate relevance patterns cover feature-implementation surfaces'

# Functional tests via scratch git repo

# Test 6: Gate passes when working tree is clean
$scratchDir = Join-Path -Path $repoRoot -ChildPath '.scratch\working-tree-gate-clean'
if (Test-Path -LiteralPath $scratchDir) { Remove-Item -Recurse -Force -LiteralPath $scratchDir }
$null = New-Item -ItemType Directory -Path $scratchDir -Force
$cleanTest = @"
Set-StrictMode -Version Latest
`$ErrorActionPreference = 'Stop'
Set-Location -LiteralPath '$scratchDir'
git init 2>&1 | Out-Null
git config user.email 'test@specrew.local' 2>&1 | Out-Null
git config user.name 'Test' 2>&1 | Out-Null
git commit --allow-empty -m 'initial' 2>&1 | Out-Null
. '$syncBoundaryScript'
try {
    Invoke-PreFeatureCloseoutWorkingTreeGate -ProjectPath '$scratchDir' -BoundaryType 'feature-closeout'
    Write-Host 'CLEAN_GATE_PASSED'
}
catch {
    Write-Host "CLEAN_GATE_THREW: `$(`$_.Exception.Message)"
}
"@
$cleanResult = pwsh -NoProfile -Command $cleanTest 2>&1 | Out-String
if ($cleanResult -notmatch 'CLEAN_GATE_PASSED') {
    Write-Fail "Gate threw on a clean working tree. Result:`n$cleanResult"
}
Remove-Item -Recurse -Force -LiteralPath $scratchDir -ErrorAction SilentlyContinue
Write-Pass 'Gate passes when working tree is clean at feature-closeout'

# Test 7: Gate throws when feature-implementation file is unstaged
$scratchDir = Join-Path -Path $repoRoot -ChildPath '.scratch\working-tree-gate-dirty'
if (Test-Path -LiteralPath $scratchDir) { Remove-Item -Recurse -Force -LiteralPath $scratchDir }
$null = New-Item -ItemType Directory -Path $scratchDir -Force
$null = New-Item -ItemType Directory -Path (Join-Path $scratchDir 'scripts') -Force
$dirtyTest = @"
Set-StrictMode -Version Latest
`$ErrorActionPreference = 'Stop'
Set-Location -LiteralPath '$scratchDir'
git init 2>&1 | Out-Null
git config user.email 'test@specrew.local' 2>&1 | Out-Null
git config user.name 'Test' 2>&1 | Out-Null
git commit --allow-empty -m 'initial' 2>&1 | Out-Null
Set-Content -LiteralPath 'scripts/dirty-impl.ps1' -Value 'Write-Host hi' -Encoding UTF8
. '$syncBoundaryScript'
try {
    Invoke-PreFeatureCloseoutWorkingTreeGate -ProjectPath '$scratchDir' -BoundaryType 'feature-closeout'
    Write-Host 'DIRTY_GATE_DID_NOT_THROW'
}
catch {
    if (`$_.Exception.Message -match 'feature-closeout-working-tree-gate' -and `$_.Exception.Message -match 'scripts') {
        Write-Host 'DIRTY_GATE_THREW_AS_EXPECTED'
    } else {
        Write-Host "DIRTY_GATE_THREW_UNEXPECTED: `$(`$_.Exception.Message)"
    }
}
"@
$dirtyResult = pwsh -NoProfile -Command $dirtyTest 2>&1 | Out-String
if ($dirtyResult -notmatch 'DIRTY_GATE_THREW_AS_EXPECTED') {
    Write-Fail "Gate did not throw on a dirty working tree. Result:`n$dirtyResult"
}
Remove-Item -Recurse -Force -LiteralPath $scratchDir -ErrorAction SilentlyContinue
Write-Pass 'Gate throws at feature-closeout when scripts/dirty-impl.ps1 is unstaged'

# Test 8: Gate is no-op at non-feature-closeout boundaries even with dirty tree
$scratchDir = Join-Path -Path $repoRoot -ChildPath '.scratch\working-tree-gate-non-closeout'
if (Test-Path -LiteralPath $scratchDir) { Remove-Item -Recurse -Force -LiteralPath $scratchDir }
$null = New-Item -ItemType Directory -Path $scratchDir -Force
$null = New-Item -ItemType Directory -Path (Join-Path $scratchDir 'scripts') -Force
$noopTest = @"
Set-StrictMode -Version Latest
`$ErrorActionPreference = 'Stop'
Set-Location -LiteralPath '$scratchDir'
git init 2>&1 | Out-Null
git config user.email 'test@specrew.local' 2>&1 | Out-Null
git config user.name 'Test' 2>&1 | Out-Null
git commit --allow-empty -m 'initial' 2>&1 | Out-Null
Set-Content -LiteralPath 'scripts/dirty-impl.ps1' -Value 'Write-Host hi' -Encoding UTF8
. '$syncBoundaryScript'
try {
    Invoke-PreFeatureCloseoutWorkingTreeGate -ProjectPath '$scratchDir' -BoundaryType 'plan'
    Write-Host 'NOOP_GATE_PASSED'
}
catch {
    Write-Host "NOOP_GATE_THREW: `$(`$_.Exception.Message)"
}
"@
$noopResult = pwsh -NoProfile -Command $noopTest 2>&1 | Out-String
if ($noopResult -notmatch 'NOOP_GATE_PASSED') {
    Write-Fail "Gate fired at non-feature-closeout boundary. Result:`n$noopResult"
}
Remove-Item -Recurse -Force -LiteralPath $scratchDir -ErrorAction SilentlyContinue
Write-Pass 'Gate is no-op at non-feature-closeout boundaries even with dirty tree'

# Test 9: Gate ignores session-state file churn
$scratchDir = Join-Path -Path $repoRoot -ChildPath '.scratch\working-tree-gate-session-state'
if (Test-Path -LiteralPath $scratchDir) { Remove-Item -Recurse -Force -LiteralPath $scratchDir }
$null = New-Item -ItemType Directory -Path $scratchDir -Force
$null = New-Item -ItemType Directory -Path (Join-Path $scratchDir '.specrew') -Force
$null = New-Item -ItemType Directory -Path (Join-Path $scratchDir '.squad\identity') -Force
$sessionTest = @"
Set-StrictMode -Version Latest
`$ErrorActionPreference = 'Stop'
Set-Location -LiteralPath '$scratchDir'
git init 2>&1 | Out-Null
git config user.email 'test@specrew.local' 2>&1 | Out-Null
git config user.name 'Test' 2>&1 | Out-Null
git commit --allow-empty -m 'initial' 2>&1 | Out-Null
Set-Content -LiteralPath '.specrew/start-context.json' -Value '{}' -Encoding UTF8
Set-Content -LiteralPath '.squad/identity/now.md' -Value 'session state' -Encoding UTF8
. '$syncBoundaryScript'
try {
    Invoke-PreFeatureCloseoutWorkingTreeGate -ProjectPath '$scratchDir' -BoundaryType 'feature-closeout'
    Write-Host 'SESSION_STATE_GATE_PASSED'
}
catch {
    Write-Host "SESSION_STATE_GATE_THREW: `$(`$_.Exception.Message)"
}
"@
$sessionResult = pwsh -NoProfile -Command $sessionTest 2>&1 | Out-String
if ($sessionResult -notmatch 'SESSION_STATE_GATE_PASSED') {
    Write-Fail "Gate fired on session-state-only churn. Result:`n$sessionResult"
}
Remove-Item -Recurse -Force -LiteralPath $scratchDir -ErrorAction SilentlyContinue
Write-Pass 'Gate ignores session-state file churn (.specrew/, .squad/) at feature-closeout'

# Test 10: Gate excludes the scaffold-generated specs/<feature>/closeout-dashboard.md (#1761 red 2).
# The dashboard is produced AT the feature-closeout boundary by scaffold-feature-closeout-dashboard.ps1,
# which then calls this sync, so it cannot be committed before the gate runs.
$scratchDir = Join-Path -Path $repoRoot -ChildPath '.scratch\working-tree-gate-closeout-dashboard'
if (Test-Path -LiteralPath $scratchDir) { Remove-Item -Recurse -Force -LiteralPath $scratchDir }
$null = New-Item -ItemType Directory -Path (Join-Path $scratchDir 'specs\900-fixture') -Force
$dashboardTest = @"
Set-StrictMode -Version Latest
`$ErrorActionPreference = 'Stop'
Set-Location -LiteralPath '$scratchDir'
git init 2>&1 | Out-Null
git config user.email 'test@specrew.local' 2>&1 | Out-Null
git config user.name 'Test' 2>&1 | Out-Null
git commit --allow-empty -m 'initial' 2>&1 | Out-Null
Set-Content -LiteralPath 'specs/900-fixture/README.md' -Value '# Fixture' -Encoding UTF8
git add . 2>&1 | Out-Null
git commit -m 'baseline specs tree' 2>&1 | Out-Null
Set-Content -LiteralPath 'specs/900-fixture/closeout-dashboard.md' -Value '# Closeout Dashboard' -Encoding UTF8
. '$syncBoundaryScript'
try {
    Invoke-PreFeatureCloseoutWorkingTreeGate -ProjectPath '$scratchDir' -BoundaryType 'feature-closeout'
    Write-Host 'DASHBOARD_GATE_PASSED'
}
catch {
    Write-Host "DASHBOARD_GATE_THREW: `$(`$_.Exception.Message)"
}
"@
$dashboardResult = pwsh -NoProfile -Command $dashboardTest 2>&1 | Out-String
if ($dashboardResult -notmatch 'DASHBOARD_GATE_PASSED') {
    Write-Fail "Gate fired on the scaffold-generated closeout-dashboard.md. Result:`n$dashboardResult"
}
Remove-Item -Recurse -Force -LiteralPath $scratchDir -ErrorAction SilentlyContinue
Write-Pass 'Gate excludes the boundary-generated specs/<feature>/closeout-dashboard.md at feature-closeout'

# Test 11: Gate STILL fires on a non-dashboard specs/ file (narrow-exclusion guard) -- the
# closeout-dashboard exclusion must not silently exempt other uncommitted specs/ surfaces.
$scratchDir = Join-Path -Path $repoRoot -ChildPath '.scratch\working-tree-gate-specs-fires'
if (Test-Path -LiteralPath $scratchDir) { Remove-Item -Recurse -Force -LiteralPath $scratchDir }
$null = New-Item -ItemType Directory -Path (Join-Path $scratchDir 'specs\900-fixture') -Force
$specsTest = @"
Set-StrictMode -Version Latest
`$ErrorActionPreference = 'Stop'
Set-Location -LiteralPath '$scratchDir'
git init 2>&1 | Out-Null
git config user.email 'test@specrew.local' 2>&1 | Out-Null
git config user.name 'Test' 2>&1 | Out-Null
git commit --allow-empty -m 'initial' 2>&1 | Out-Null
Set-Content -LiteralPath 'specs/900-fixture/README.md' -Value '# Fixture' -Encoding UTF8
git add . 2>&1 | Out-Null
git commit -m 'baseline specs tree' 2>&1 | Out-Null
Set-Content -LiteralPath 'specs/900-fixture/spec.md' -Value '# Spec' -Encoding UTF8
. '$syncBoundaryScript'
try {
    Invoke-PreFeatureCloseoutWorkingTreeGate -ProjectPath '$scratchDir' -BoundaryType 'feature-closeout'
    Write-Host 'SPECS_GATE_DID_NOT_THROW'
}
catch {
    if (`$_.Exception.Message -match 'feature-closeout-working-tree-gate' -and `$_.Exception.Message -match 'spec\.md') {
        Write-Host 'SPECS_GATE_THREW_AS_EXPECTED'
    } else {
        Write-Host "SPECS_GATE_THREW_UNEXPECTED: `$(`$_.Exception.Message)"
    }
}
"@
$specsResult = pwsh -NoProfile -Command $specsTest 2>&1 | Out-String
if ($specsResult -notmatch 'SPECS_GATE_THREW_AS_EXPECTED') {
    Write-Fail "Gate did not fire on an uncommitted non-dashboard specs/ file (exclusion too broad). Result:`n$specsResult"
}
Remove-Item -Recurse -Force -LiteralPath $scratchDir -ErrorAction SilentlyContinue
Write-Pass 'Gate still fires on a non-dashboard uncommitted specs/ file (closeout-dashboard exclusion is narrow)'

# Test 12: end-anchor guard (Codex C1 / Copilot P2, #1761). The exclusion is anchored to '\.md$',
# so a closeout-dashboard.md.bak / .tmp sibling is NOT exempt and still fires.
$scratchDir = Join-Path -Path $repoRoot -ChildPath '.scratch\working-tree-gate-dashboard-bak'
if (Test-Path -LiteralPath $scratchDir) { Remove-Item -Recurse -Force -LiteralPath $scratchDir }
$null = New-Item -ItemType Directory -Path (Join-Path $scratchDir 'specs\900-fixture') -Force
$bakTest = @"
Set-StrictMode -Version Latest
`$ErrorActionPreference = 'Stop'
Set-Location -LiteralPath '$scratchDir'
git init 2>&1 | Out-Null
git config user.email 'test@specrew.local' 2>&1 | Out-Null
git config user.name 'Test' 2>&1 | Out-Null
git commit --allow-empty -m 'initial' 2>&1 | Out-Null
Set-Content -LiteralPath 'specs/900-fixture/README.md' -Value '# Fixture' -Encoding UTF8
git add . 2>&1 | Out-Null
git commit -m 'baseline specs tree' 2>&1 | Out-Null
Set-Content -LiteralPath 'specs/900-fixture/closeout-dashboard.md.bak' -Value '# Backup' -Encoding UTF8
. '$syncBoundaryScript'
try {
    Invoke-PreFeatureCloseoutWorkingTreeGate -ProjectPath '$scratchDir' -BoundaryType 'feature-closeout'
    Write-Host 'BAK_GATE_DID_NOT_THROW'
}
catch {
    if (`$_.Exception.Message -match 'closeout-dashboard\.md\.bak') {
        Write-Host 'BAK_GATE_THREW_AS_EXPECTED'
    } else {
        Write-Host "BAK_GATE_THREW_UNEXPECTED: `$(`$_.Exception.Message)"
    }
}
"@
$bakResult = pwsh -NoProfile -Command $bakTest 2>&1 | Out-String
if ($bakResult -notmatch 'BAK_GATE_THREW_AS_EXPECTED') {
    Write-Fail "Gate did not fire on closeout-dashboard.md.bak (exclusion not end-anchored). Result:`n$bakResult"
}
Remove-Item -Recurse -Force -LiteralPath $scratchDir -ErrorAction SilentlyContinue
Write-Pass 'Gate still fires on closeout-dashboard.md.bak (exclusion is end-anchored)'

# Test 13: start-anchor guard (Codex C1, #1761). The exclusion is anchored to '^specs/', so a
# docs/specs/.../closeout-dashboard.md (which only CONTAINS the specs/.../dashboard substring) is
# NOT exempt and still fires under the ^docs/ relevance pattern.
$scratchDir = Join-Path -Path $repoRoot -ChildPath '.scratch\working-tree-gate-docs-specs'
if (Test-Path -LiteralPath $scratchDir) { Remove-Item -Recurse -Force -LiteralPath $scratchDir }
$null = New-Item -ItemType Directory -Path (Join-Path $scratchDir 'docs\specs\900-fixture') -Force
$docsTest = @"
Set-StrictMode -Version Latest
`$ErrorActionPreference = 'Stop'
Set-Location -LiteralPath '$scratchDir'
git init 2>&1 | Out-Null
git config user.email 'test@specrew.local' 2>&1 | Out-Null
git config user.name 'Test' 2>&1 | Out-Null
git commit --allow-empty -m 'initial' 2>&1 | Out-Null
Set-Content -LiteralPath 'docs/specs/900-fixture/README.md' -Value '# Fixture' -Encoding UTF8
git add . 2>&1 | Out-Null
git commit -m 'baseline docs tree' 2>&1 | Out-Null
Set-Content -LiteralPath 'docs/specs/900-fixture/closeout-dashboard.md' -Value '# Not the boundary dashboard' -Encoding UTF8
. '$syncBoundaryScript'
try {
    Invoke-PreFeatureCloseoutWorkingTreeGate -ProjectPath '$scratchDir' -BoundaryType 'feature-closeout'
    Write-Host 'DOCS_GATE_DID_NOT_THROW'
}
catch {
    if (`$_.Exception.Message -match 'docs/specs/900-fixture/closeout-dashboard\.md') {
        Write-Host 'DOCS_GATE_THREW_AS_EXPECTED'
    } else {
        Write-Host "DOCS_GATE_THREW_UNEXPECTED: `$(`$_.Exception.Message)"
    }
}
"@
$docsResult = pwsh -NoProfile -Command $docsTest 2>&1 | Out-String
if ($docsResult -notmatch 'DOCS_GATE_THREW_AS_EXPECTED') {
    Write-Fail "Gate did not fire on docs/specs/.../closeout-dashboard.md (exclusion not start-anchored). Result:`n$docsResult"
}
Remove-Item -Recurse -Force -LiteralPath $scratchDir -ErrorAction SilentlyContinue
Write-Pass 'Gate still fires on docs/specs/.../closeout-dashboard.md (exclusion is start-anchored)'

# Test 14: `.specify/extensions/` and companion `.specify` files are classified as one
# implementation surface, excluding only session-state churn such as `.specify/feature.json`.
$scratchDir = Join-Path -Path $repoRoot -ChildPath '.scratch\working-tree-gate-specify-companions'
if (Test-Path -LiteralPath $scratchDir) { Remove-Item -Recurse -Force -LiteralPath $scratchDir }
$null = New-Item -ItemType Directory -Path (Join-Path $scratchDir '.specify\extensions\specrew-speckit') -Force
$null = New-Item -ItemType Directory -Path (Join-Path $scratchDir '.specify\templates') -Force
$specifyCompanionTest = @"
Set-StrictMode -Version Latest
`$ErrorActionPreference = 'Stop'
Set-Location -LiteralPath '$scratchDir'
git init 2>&1 | Out-Null
git config user.email 'test@specrew.local' 2>&1 | Out-Null
git config user.name 'Test' 2>&1 | Out-Null
Set-Content -LiteralPath '.specify/extensions/specrew-speckit/README.md' -Value '# Extension' -Encoding UTF8
Set-Content -LiteralPath '.specify/extensions.yml' -Value 'installed: []' -Encoding UTF8
Set-Content -LiteralPath '.specify/templates/plan-template.md' -Value '# Plan' -Encoding UTF8
git add . 2>&1 | Out-Null
git commit -m 'baseline specify surfaces' 2>&1 | Out-Null
Set-Content -LiteralPath '.specify/extensions/specrew-speckit/README.md' -Value '# Extension changed' -Encoding UTF8
Set-Content -LiteralPath '.specify/extensions.yml' -Value 'installed:`n  - specrew-speckit' -Encoding UTF8
Set-Content -LiteralPath '.specify/templates/plan-template.md' -Value '# Plan changed' -Encoding UTF8
. '$syncBoundaryScript'
try {
    Invoke-PreFeatureCloseoutWorkingTreeGate -ProjectPath '$scratchDir' -BoundaryType 'feature-closeout'
    Write-Host 'SPECIFY_COMPANION_GATE_DID_NOT_THROW'
}
catch {
    `$message = `$_.Exception.Message
    if (
        `$message -match '\.specify/extensions/specrew-speckit/README\.md' -and
        `$message -match '\.specify/extensions\.yml' -and
        `$message -match '\.specify/templates/plan-template\.md'
    ) {
        Write-Host 'SPECIFY_COMPANION_GATE_THREW_AS_EXPECTED'
    } else {
        Write-Host "SPECIFY_COMPANION_GATE_THREW_UNEXPECTED: `$message"
    }
}
"@
$specifyCompanionResult = pwsh -NoProfile -Command $specifyCompanionTest 2>&1 | Out-String
if ($specifyCompanionResult -notmatch 'SPECIFY_COMPANION_GATE_THREW_AS_EXPECTED') {
    Write-Fail "Gate did not classify .specify extension companions coherently. Result:`n$specifyCompanionResult"
}
Remove-Item -Recurse -Force -LiteralPath $scratchDir -ErrorAction SilentlyContinue
Write-Pass 'Gate classifies .specify/extensions and companion .specify files together'

# Test 15: no-upstream branches must not be told their commit "must be pushed".
$scratchDir = Join-Path -Path $repoRoot -ChildPath '.scratch\working-tree-gate-no-upstream'
if (Test-Path -LiteralPath $scratchDir) { Remove-Item -Recurse -Force -LiteralPath $scratchDir }
$null = New-Item -ItemType Directory -Path (Join-Path $scratchDir 'scripts') -Force
$noUpstreamTest = @"
Set-StrictMode -Version Latest
`$ErrorActionPreference = 'Stop'
Set-Location -LiteralPath '$scratchDir'
git init 2>&1 | Out-Null
git config user.email 'test@specrew.local' 2>&1 | Out-Null
git config user.name 'Test' 2>&1 | Out-Null
git commit --allow-empty -m 'initial' 2>&1 | Out-Null
Set-Content -LiteralPath 'scripts/dirty-impl.ps1' -Value 'Write-Host hi' -Encoding UTF8
. '$syncBoundaryScript'
try {
    Invoke-PreFeatureCloseoutWorkingTreeGate -ProjectPath '$scratchDir' -BoundaryType 'feature-closeout'
    Write-Host 'NO_UPSTREAM_GATE_DID_NOT_THROW'
}
catch {
    `$message = `$_.Exception.Message
    if (`$message -match 'must be pushed|committed AND pushed|Push: git push') {
        Write-Host "NO_UPSTREAM_PUSH_WORDING_FOUND: `$message"
    } elseif (`$message -match 'No upstream is configured') {
        Write-Host 'NO_UPSTREAM_WORDING_OK'
    } else {
        Write-Host "NO_UPSTREAM_WORDING_UNEXPECTED: `$message"
    }
}
"@
$noUpstreamResult = pwsh -NoProfile -Command $noUpstreamTest 2>&1 | Out-String
if ($noUpstreamResult -notmatch 'NO_UPSTREAM_WORDING_OK') {
    Write-Fail "Gate used incorrect no-upstream wording. Result:`n$noUpstreamResult"
}
Remove-Item -Recurse -Force -LiteralPath $scratchDir -ErrorAction SilentlyContinue
Write-Pass 'Gate omits mandatory push wording when the branch has no upstream'

# Test 16: auto-render closeout refreshes stale dashboard artifacts instead of preserving them.
$autoRenderRoot = Join-Path -Path $repoRoot -ChildPath '.scratch\working-tree-gate-auto-dashboard-refresh'
if (Test-Path -LiteralPath $autoRenderRoot) { Remove-Item -Recurse -Force -LiteralPath $autoRenderRoot }
$fakeScriptsRoot = Join-Path $autoRenderRoot 'scripts'
$fakeInternalRoot = Join-Path $fakeScriptsRoot 'internal'
$fakeProjectRoot = Join-Path $autoRenderRoot 'project'
$fakeDashboardDirectory = Join-Path $fakeProjectRoot 'specs\900-fixture'
$null = New-Item -ItemType Directory -Path $fakeInternalRoot -Force
$null = New-Item -ItemType Directory -Path $fakeDashboardDirectory -Force
$fakeWhereScript = Join-Path $fakeScriptsRoot 'specrew-where.ps1'
[System.IO.File]::WriteAllText($fakeWhereScript, @'
param(
    [string]$ProjectPath,
    [string]$OutputPath,
    [string]$CaptureKind,
    [switch]$NoColor,
    [switch]$PreserveExistingArtifact,
    [string]$FeatureId,
    [string]$IterationNumber
)

$argPath = Join-Path $ProjectPath 'where-args.json'
[pscustomobject]@{
    preserve_existing_artifact = $PreserveExistingArtifact.IsPresent
    capture_kind               = $CaptureKind
    feature_id                 = $FeatureId
    iteration_number           = $IterationNumber
} | ConvertTo-Json -Compress | Set-Content -LiteralPath $argPath -Encoding UTF8

if ($PreserveExistingArtifact.IsPresent -and (Test-Path -LiteralPath $OutputPath -PathType Leaf)) {
    exit 0
}

Set-Content -LiteralPath $OutputPath -Value ("fresh:{0}:{1}" -f $FeatureId, $CaptureKind) -Encoding UTF8
exit 0
'@, [System.Text.UTF8Encoding]::new($false))

$autoRenderFunctionMatch = [regex]::Match($syncBoundaryContent, '(?s)function Invoke-SpecrewAutoRenderDashboard \{.*?(?=\r?\nfunction Invoke-SpecrewBoundaryStateSync)')
if (-not $autoRenderFunctionMatch.Success) {
    Write-Fail 'Could not extract Invoke-SpecrewAutoRenderDashboard from sync-boundary-state.ps1'
}

$fakeDashboardPath = Join-Path $fakeDashboardDirectory 'closeout-dashboard.md'
Set-Content -LiteralPath $fakeDashboardPath -Value 'stale-dashboard' -Encoding UTF8
$harnessPath = Join-Path $fakeInternalRoot 'auto-render-harness.ps1'
$harnessContent = @"
Set-StrictMode -Version Latest
`$ErrorActionPreference = 'Stop'
function Normalize-SpecrewIterationNumber {
    param([AllowNull()][string]`$IterationNumber)
    return `$IterationNumber
}
$($autoRenderFunctionMatch.Value)
Invoke-SpecrewAutoRenderDashboard -ProjectRoot '$fakeProjectRoot' -OutputPath '$fakeDashboardPath' -CaptureKind 'feature-closeout' -FeatureRef '900-fixture' -IterationNumber `$null
"@
[System.IO.File]::WriteAllText($harnessPath, $harnessContent, [System.Text.UTF8Encoding]::new($false))
$autoRenderResult = pwsh -NoProfile -ExecutionPolicy Bypass -File $harnessPath 2>&1 | Out-String
if ($LASTEXITCODE -ne 0) {
    Write-Fail "Auto-render harness failed:`n$autoRenderResult"
}

$dashboardText = (Get-Content -LiteralPath $fakeDashboardPath -Raw -Encoding UTF8).Trim()
$whereArgs = Get-Content -LiteralPath (Join-Path $fakeProjectRoot 'where-args.json') -Raw -Encoding UTF8 | ConvertFrom-Json
if ($dashboardText -ne 'fresh:900-fixture:feature-closeout' -or $whereArgs.preserve_existing_artifact) {
    Write-Fail ("Auto-render did not refresh the stale closeout dashboard. preserve_existing_artifact={0}; dashboard='{1}'; output:`n{2}" -f $whereArgs.preserve_existing_artifact, $dashboardText, $autoRenderResult)
}
Remove-Item -Recurse -Force -LiteralPath $autoRenderRoot -ErrorAction SilentlyContinue
Write-Pass 'Auto-render refreshes stale feature closeout dashboards from current artifacts'

Write-Host ''
Write-Host 'Feature-closeout working-tree gate: all assertions pass'
exit 0
