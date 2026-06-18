[CmdletBinding()]
param()

# Crew-bootstrap E2E: deploy + verify all 5 per-host Crew runtimes from a single
# canonical .specrew/team/agents/ source. Promoted from .scratch/crew-bootstrap-e2e.ps1
# during deep-analysis cleanup (Proposal 108 follow-up).

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Write-Pass { param([string]$Message) Write-Host "PASS: $Message" -ForegroundColor Green }
function Write-Fail { param([string]$Message) Write-Host "FAIL: $Message" -ForegroundColor Red; exit 1 }

$repoRoot = (Resolve-Path (Join-Path -Path $PSScriptRoot -ChildPath '..\..')).Path
$scratchDir = Join-Path $repoRoot '.scratch\crew-bootstrap-contract-test'

if (Test-Path -LiteralPath $scratchDir) {
    Remove-Item -LiteralPath $scratchDir -Recurse -Force
}
New-Item -ItemType Directory -Path $scratchDir -Force | Out-Null

# Dot-source the registry (eager-loads handlers + canonical-team helpers)
. (Join-Path $repoRoot 'hosts\_registry.ps1')

# Test 1: Initialize-SpecrewTeamCanonical seeds canonical from shipped baseline
$seedResult = Initialize-SpecrewTeamCanonical -ProjectPath $scratchDir
$canonicalAgents = Join-Path $scratchDir '.specrew\team\agents'
$canonicalFiles = Get-ChildItem -Path $canonicalAgents -Filter '*.md' -ErrorAction SilentlyContinue
if ($canonicalFiles.Count -lt 5) {
    Write-Fail "Canonical seeding produced fewer than 5 agent files (got $($canonicalFiles.Count))"
}
Write-Pass "Initialize-SpecrewTeamCanonical seeds 5 baseline charters under .specrew/team/agents/"

# Test 2: Get-SpecrewHostAgentRoot resolves from manifest AgentDir for every supported host
$expectedAgentRoots = @{
    'copilot'     = (Join-Path $scratchDir '.squad\agents')
    'claude'      = (Join-Path $scratchDir '.claude\agents')
    'cursor'      = (Join-Path $scratchDir '.cursor\rules')
    'codex'       = (Join-Path $scratchDir '.codex\agents')
    'antigravity' = (Join-Path $scratchDir '.agents\agents')
}
foreach ($kv in $expectedAgentRoots.GetEnumerator()) {
    $actual = Get-SpecrewHostAgentRoot -HostKind $kv.Key -ProjectPath $scratchDir
    if ($actual -ne $kv.Value) {
        Write-Fail "Get-SpecrewHostAgentRoot drift for '$($kv.Key)': got '$actual', expected '$($kv.Value)'"
    }
}
Write-Pass "Get-SpecrewHostAgentRoot resolves manifest AgentDir for all 5 hosts"

# Test 3: Each Install-<Kind>CrewRuntime deploys to its manifest-declared AgentDir
foreach ($kind in @('copilot', 'claude', 'cursor', 'codex', 'antigravity')) {
    $result = Invoke-HostHandler -Kind $kind -ContractFunction InstallCrewRuntime -Arguments @{ ProjectPath = $scratchDir }
    $written = @($result.Actions | Where-Object { $_.Action -eq 'written' })
    if ($written.Count -lt 5) {
        Write-Fail "Host '$kind' wrote only $($written.Count) charter file(s); expected at least 5"
    }
    if (-not (Test-Path -LiteralPath $result.CrewRuntimePath -PathType Container)) {
        Write-Fail "Host '$kind' returned CrewRuntimePath='$($result.CrewRuntimePath)' but the directory does not exist"
    }
}
Write-Pass "Install-<Kind>CrewRuntime deploys 5 charters per host to manifest-declared AgentDir"

# Test 4: Copilot CrewRuntimePath points at the agents dir (NOT its parent .squad)
$copilotResult = Invoke-HostHandler -Kind 'copilot' -ContractFunction InstallCrewRuntime -Arguments @{ ProjectPath = $scratchDir }
if (-not ($copilotResult.CrewRuntimePath -match '\.squad[\\/]agents$')) {
    Write-Fail "Copilot CrewRuntimePath should end in .squad/agents (B-1 regression check); got '$($copilotResult.CrewRuntimePath)'"
}
Write-Pass "Copilot CrewRuntimePath ends in .squad/agents (B-1 regression check)"

# Test 5: Claude YAML frontmatter present + correctly formed
$claudeRoot = Join-Path $scratchDir '.claude\agents'
$sampleClaude = Get-Content -LiteralPath (Join-Path $claudeRoot 'reviewer.md') -Raw -Encoding UTF8
if ($sampleClaude -notmatch '(?ms)^---\s*$.+?^name:\s.+?^description:\s.+?^---\s*$') {
    Write-Fail "Claude subagent file missing YAML frontmatter"
}
Write-Pass "Claude subagent file ships valid YAML frontmatter"

# Test 6: Codex TOML has required fields
$codexRoot = Join-Path $scratchDir '.codex\agents'
$sampleCodex = Get-Content -LiteralPath (Join-Path $codexRoot 'reviewer.toml') -Raw -Encoding UTF8
foreach ($field in @('name', 'description', 'developer_instructions')) {
    if ($sampleCodex -notmatch ('(?m)^{0}\s*=' -f $field)) {
        Write-Fail "Codex subagent TOML missing required field '$field'"
    }
}
Write-Pass "Codex subagent TOML ships required fields (name + description + developer_instructions)"

# Test 7: Cursor MDC frontmatter present
$cursorRoot = Join-Path $scratchDir '.cursor\rules'
$sampleCursor = Get-Content -LiteralPath (Join-Path $cursorRoot 'reviewer.mdc') -Raw -Encoding UTF8
if ($sampleCursor -notmatch '(?ms)^---\s*$.+?^description:\s.+?^alwaysApply:\s.+?^---\s*$') {
    Write-Fail "Cursor rule file missing MDC frontmatter"
}
Write-Pass "Cursor rule file ships valid MDC frontmatter"

# Test 8: Antigravity YAML frontmatter present
$antigravityRoot = Join-Path $scratchDir '.agents\agents'
$sampleAnti = Get-Content -LiteralPath (Join-Path $antigravityRoot 'reviewer.md') -Raw -Encoding UTF8
if ($sampleAnti -notmatch '(?ms)^---\s*$.+?^name:\s.+?^description:\s.+?^---\s*$') {
    Write-Fail "Antigravity subagent file missing YAML frontmatter"
}
Write-Pass "Antigravity subagent file ships valid YAML frontmatter"

# Test 9: Specrew-managed sentinel preserves user edits (W-4 enforcement)
$userEditedTarget = Join-Path $claudeRoot 'reviewer.md'
$userBody = "# my custom reviewer charter (no Specrew-managed marker)`nThis is user content; the next deploy MUST NOT overwrite it.`n"
[System.IO.File]::WriteAllText($userEditedTarget, $userBody, [System.Text.UTF8Encoding]::new($false))

$reDeploy = Invoke-HostHandler -Kind 'claude' -ContractFunction InstallCrewRuntime -Arguments @{ ProjectPath = $scratchDir }
$preserved = @($reDeploy.Actions | Where-Object { $_.Action -eq 'preserved' })
if ($preserved.Count -lt 1) {
    Write-Fail "Sentinel enforcement: expected at least 1 preserved file when reviewer.md was user-edited; got $($preserved.Count)"
}
$afterContent = Get-Content -LiteralPath $userEditedTarget -Raw -Encoding UTF8
if ($afterContent -notmatch 'my custom reviewer charter') {
    Write-Fail "Sentinel enforcement: user edit was clobbered on re-deploy"
}
Write-Pass "Sentinel enforcement preserves user-edited files without the Specrew-managed marker"

# Test 10: Re-deploying still overwrites files that DO carry the marker
$secondRedeploy = Invoke-HostHandler -Kind 'claude' -ContractFunction InstallCrewRuntime -Arguments @{ ProjectPath = $scratchDir }
$writtenAgain = @($secondRedeploy.Actions | Where-Object { $_.Action -eq 'written' })
if ($writtenAgain.Count -lt 4) {
    Write-Fail "Sentinel enforcement: expected at least 4 files re-written on second deploy (only reviewer.md preserved); got $($writtenAgain.Count)"
}
Write-Pass "Sentinel enforcement still re-writes Specrew-managed files (only user-edited files preserved)"

# Cleanup
Remove-Item -LiteralPath $scratchDir -Recurse -Force -ErrorAction SilentlyContinue

Write-Host "`nCrew-bootstrap contract: all assertions pass" -ForegroundColor Green
