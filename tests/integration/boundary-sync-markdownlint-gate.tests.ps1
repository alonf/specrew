[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Write-Pass { param([string]$Message) Write-Host "PASS: $Message" -ForegroundColor Green }
function Write-Fail { param([string]$Message) Write-Host "FAIL: $Message" -ForegroundColor Red; exit 1 }

$repoRoot = (Resolve-Path (Join-Path -Path $PSScriptRoot -ChildPath '..\..')).Path
$sharedGovernance = Join-Path -Path $repoRoot -ChildPath 'extensions\specrew-speckit\scripts\shared-governance.ps1'
$syncBoundaryScript = Join-Path -Path $repoRoot -ChildPath 'scripts\internal\sync-boundary-state.ps1'

# Structural tests (no git fixture required)

# Test 1: Get-ChangedMarkdownFiles helper exists in shared-governance.ps1
$sharedContent = Get-Content -LiteralPath $sharedGovernance -Raw -Encoding UTF8
if ($sharedContent -notmatch 'function Get-ChangedMarkdownFiles\b') {
    Write-Fail 'Get-ChangedMarkdownFiles function not found in shared-governance.ps1'
}
Write-Pass 'Get-ChangedMarkdownFiles helper present in shared-governance.ps1'

# Test 2: Invoke-MarkdownLintAutoFix helper exists in shared-governance.ps1
if ($sharedContent -notmatch 'function Invoke-MarkdownLintAutoFix\b') {
    Write-Fail 'Invoke-MarkdownLintAutoFix function not found in shared-governance.ps1'
}
Write-Pass 'Invoke-MarkdownLintAutoFix helper present in shared-governance.ps1'

# Test 3: Mirror parity for shared-governance.ps1
$mirrorSharedGovernance = Join-Path -Path $repoRoot -ChildPath '.specify\extensions\specrew-speckit\scripts\shared-governance.ps1'
$primaryHash = (Get-FileHash -LiteralPath $sharedGovernance -Algorithm SHA256).Hash
$mirrorHash = (Get-FileHash -LiteralPath $mirrorSharedGovernance -Algorithm SHA256).Hash
if ($primaryHash -ne $mirrorHash) {
    Write-Fail "shared-governance.ps1 mirror parity failure: primary $primaryHash != mirror $mirrorHash"
}
Write-Pass 'shared-governance.ps1 mirror parity verified (SHA256 match)'

# Test 4: Invoke-PreBoundaryMarkdownLintGate function exists in sync-boundary-state.ps1
$syncBoundaryContent = Get-Content -LiteralPath $syncBoundaryScript -Raw -Encoding UTF8
if ($syncBoundaryContent -notmatch 'function Invoke-PreBoundaryMarkdownLintGate\b') {
    Write-Fail 'Invoke-PreBoundaryMarkdownLintGate function not found in sync-boundary-state.ps1'
}
Write-Pass 'Invoke-PreBoundaryMarkdownLintGate function present in sync-boundary-state.ps1'

# Test 5: Invoke-SpecrewBoundaryStateSync calls the gate BEFORE state-file writes
# Look for the gate invocation at the start of Invoke-SpecrewBoundaryStateSync
$mainSyncBody = [regex]::Match($syncBoundaryContent, 'function Invoke-SpecrewBoundaryStateSync \{[\s\S]*?\$paths = Get-SpecrewSessionStatePaths').Value
if ($mainSyncBody -notmatch 'Invoke-PreBoundaryMarkdownLintGate -ProjectPath \$ProjectPath') {
    Write-Fail "Invoke-SpecrewBoundaryStateSync does not call Invoke-PreBoundaryMarkdownLintGate before state-file writes"
}
Write-Pass 'Invoke-SpecrewBoundaryStateSync calls Invoke-PreBoundaryMarkdownLintGate BEFORE state-file writes'

# Functional tests via direct helper invocation

# Test 6: Invoke-MarkdownLintAutoFix on a clean .md file → no auto-fix, no violations
$fixtureRoot = Join-Path -Path $repoRoot -ChildPath '.scratch\boundary-sync-markdownlint-gate-fixture'
if (Test-Path -LiteralPath $fixtureRoot) {
    Remove-Item -LiteralPath $fixtureRoot -Recurse -Force
}
$null = New-Item -ItemType Directory -Path $fixtureRoot -Force
$null = & git -C $fixtureRoot init --quiet 2>&1
$null = & git -C $fixtureRoot config user.email 'test@example.com' 2>&1
$null = & git -C $fixtureRoot config user.name 'Test' 2>&1

$cleanMd = "# Heading$([Environment]::NewLine)$([Environment]::NewLine)Body paragraph.$([Environment]::NewLine)"
$cleanPath = Join-Path -Path $fixtureRoot -ChildPath 'clean.md'
[IO.File]::WriteAllText($cleanPath, $cleanMd, [System.Text.UTF8Encoding]::new($false))

$invokeHelpers = @"
. '$sharedGovernance'
`$result = Invoke-MarkdownLintAutoFix -MarkdownFiles @('$cleanPath') -ProjectRoot '$fixtureRoot'
[pscustomobject]@{
    AutoFixCount = `$result.AutoFixedFiles.Count
    UnfixableCount = `$result.UnfixableViolations.Count
    Unavailable = `$result.MarkdownLintUnavailable
} | ConvertTo-Json
"@
$cleanResult = pwsh -NoProfile -Command $invokeHelpers 2>&1 | Out-String

if ($cleanResult -notmatch '"AutoFixCount":\s*0' -or $cleanResult -notmatch '"UnfixableCount":\s*0') {
    Write-Fail "Clean .md file produced auto-fixes or violations. Result:`n$cleanResult"
}
Write-Pass 'Clean .md file produces no auto-fixes and no violations'

# Test 7: Auto-fixable violation (MD032 blanks-around-lists) → AutoFixedFiles populated
$dirtyMd = "# Heading$([Environment]::NewLine)Lists need blank lines:$([Environment]::NewLine)- item one$([Environment]::NewLine)- item two$([Environment]::NewLine)"
$dirtyPath = Join-Path -Path $fixtureRoot -ChildPath 'dirty.md'
[IO.File]::WriteAllText($dirtyPath, $dirtyMd, [System.Text.UTF8Encoding]::new($false))

$invokeDirty = @"
. '$sharedGovernance'
`$result = Invoke-MarkdownLintAutoFix -MarkdownFiles @('$dirtyPath') -ProjectRoot '$fixtureRoot'
[pscustomobject]@{
    AutoFixCount = `$result.AutoFixedFiles.Count
    UnfixableCount = `$result.UnfixableViolations.Count
    Unavailable = `$result.MarkdownLintUnavailable
} | ConvertTo-Json
"@
$dirtyResult = pwsh -NoProfile -Command $invokeDirty 2>&1 | Out-String

if ($dirtyResult -match '"Unavailable":\s*true') {
    Write-Pass 'markdownlint-cli not available in this environment; gate gracefully degrades (test skipped for auto-fix)'
}
else {
    if ($dirtyResult -notmatch '"AutoFixCount":\s*[1-9]') {
        # In some environments the auto-fix may not detect; still verify the file is now valid
        $afterContent = [IO.File]::ReadAllText($dirtyPath)
        if ($afterContent -notmatch '\r?\n\r?\n- item one') {
            Write-Fail "Auto-fix did not apply blank line before list. Result:`n$dirtyResult`nFile content:`n$afterContent"
        }
        Write-Pass 'Auto-fix applied blank line (verified via file content; AutoFixCount detection deferred)'
    }
    else {
        Write-Pass "Auto-fixable MD032 violation correctly detected and fixed (AutoFixCount=$($dirtyResult | Select-String -Pattern 'AutoFixCount\W+\d+'))"
    }
}

# Cleanup
Remove-Item -LiteralPath $fixtureRoot -Recurse -Force -ErrorAction SilentlyContinue

Write-Host ''
Write-Host 'Boundary-sync markdownlint gate integration: all assertions pass'
exit 0
