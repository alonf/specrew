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
foreach ($pattern in @("\^scripts/", "\^extensions/", "\^tests/", "\^README", "\^CHANGELOG")) {
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

Write-Host ''
Write-Host 'Feature-closeout working-tree gate: all assertions pass'
exit 0
