[CmdletBinding()]
param()

# F-044 iter-003 regression test for Bug 5 — bootstrap message must use Crew-neutral language
# (no Squad-hardcoded references on Claude/Codex/Antigravity hosts).

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Write-Pass { param([string]$Message) Write-Host "PASS: $Message" -ForegroundColor Green }
function Write-Fail { param([string]$Message) Write-Host "FAIL: $Message" -ForegroundColor Red; exit 1 }

$repoRoot = (Resolve-Path (Join-Path -Path $PSScriptRoot -ChildPath '..\..')).Path
$postBootstrapScript = Join-Path $repoRoot 'scripts\init\post-bootstrap-output.ps1'

if (-not (Test-Path -LiteralPath $postBootstrapScript -PathType Leaf)) {
    Write-Fail "Missing post-bootstrap-output.ps1 at expected path"
}

$content = Get-Content -LiteralPath $postBootstrapScript -Raw -Encoding UTF8

# Test 1: No "Squad drives" — iter-003 Bug 5 explicit fix
if ($content -match 'Squad drives') {
    Write-Fail "post-bootstrap-output.ps1 still contains 'Squad drives' — should be 'the Crew drives' (iter-003 Bug 5 regression)."
}
Write-Pass "Bootstrap message uses Crew-neutral verb 'the Crew drives' (not 'Squad drives')"

# Test 2: No "Squad agent" — iter-003 Bug 5 explicit fix
if ($content -match 'Squad agent with lifecycle') {
    Write-Fail "post-bootstrap-output.ps1 still contains 'Squad agent with lifecycle' (iter-003 Bug 5 regression)."
}
Write-Pass "Bootstrap message doesn't reference 'Squad agent with lifecycle'"

# Test 3: Canonical team path surfaced — iter-003 Bug 5 enhancement
if ($content -notmatch '\.specrew\\team\\agents\\' -and $content -notmatch '\.specrew/team/agents/') {
    Write-Fail "post-bootstrap-output.ps1 must mention the canonical team path '.specrew/team/agents/' (iter-003 Bug 5)."
}
Write-Pass "Bootstrap message surfaces canonical team path (.specrew/team/agents/)"

# Test 4: Antigravity is in the --host list (iter-003 + iter-004 added it)
if ($content -notmatch '`--host antigravity`') {
    Write-Fail "post-bootstrap-output.ps1 must list --host antigravity as an available option."
}
Write-Pass "Bootstrap message lists --host antigravity"

# Test 5: Translation flow explained (iter-003 enhancement)
if ($content -notmatch 're-translated to each host' -and $content -notmatch 're-synced' -and $content -notmatch 'per-host translation') {
    Write-Fail "post-bootstrap-output.ps1 should explain canonical-to-host translation flow."
}
Write-Pass "Bootstrap message explains canonical-to-host translation flow"

# Test 6: The bootstrap guidance must agree with the installed SessionStart hooks and public docs.
# A direct host launch from the project root is the primary path; specrew start remains the explicit
# host-selection and recovery path. Contradicting that contract here sends a manual tester down the
# wrong entry point even though the deployed hooks are healthy.
if ($content -match 'Do not run the host CLI directly') {
    Write-Fail "post-bootstrap-output.ps1 must not prohibit the direct host launch that its installed SessionStart hooks support."
}
if ($content -notmatch 'launch (?:your|the) host directly' -and $content -notmatch 'run (?:copilot|claude|codex|cursor-agent|agy) directly') {
    Write-Fail "post-bootstrap-output.ps1 must name direct host launch from the project root as a supported path."
}
if ($content -notmatch 'specrew start.*(?:optional|select|switch|recover|recovery)') {
    Write-Fail "post-bootstrap-output.ps1 must explain specrew start as the optional host-selection or recovery path."
}
Write-Pass "Bootstrap message agrees with the hook-first direct-launch contract"

Write-Host "`nPost-bootstrap output content: all assertions pass" -ForegroundColor Green
