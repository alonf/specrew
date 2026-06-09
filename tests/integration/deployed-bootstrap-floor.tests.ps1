$ErrorActionPreference = 'Stop'

# F-174 iteration 006, T038 - the LOAD-BEARING DEPLOYED live-wiring floor (evidence_locus: DEPLOYED).
#
# The iter-5 D-009 lesson: a floor that runs only in the dev tree is NOT a live-wiring guarantee. The
# SessionStart bootstrap provider deploys to the downstream PROJECT while its components ship in the
# installed Specrew MODULE; in the host-spawned hook child, components are NOT co-located AND
# SPECREW_MODULE_PATH is unset, so resolution MUST succeed via tier-3 (`Get-Module -ListAvailable`).
# This floor reproduces exactly that condition and asserts the contract + state land ON DISK.
#
# SCOPE HONESTY (evidence_locus discipline, applied to this test's OWN claim): this floor exercises the
# PROVIDER DIRECTLY under the deployed tier-3 condition - the D-009 crux (component resolution + the on-disk
# writes). It does NOT drive the full host -> SpecrewHookDispatcher -> refocus-scopes.json -> provider
# routing; that routing is a separate path. Claim only what this asserts: "provider-direct under deployed
# tier-3 resolution," never "the full deployed hook chain."
#
# Version-collision DEFUSE (the trap that would invert the methodology): the packed dev module and the
# already-installed PUBLISHED module share ModuleVersion 0.33.0, so `Sort Version -Desc | Select -First 1`
# cannot discriminate. We ISOLATE the child's PSModulePath to ONLY the packed module + $PSHOME/Modules
# (built-ins), excluding the user/AllUsers scope where the published one lives, and the FIRST assertion is a
# discovery probe proving the resolved module IS the packed one. So a PROVIDER_FAILED is an unambiguous
# finding, never the stale-install trap.

$devTree = (Resolve-Path "$PSScriptRoot/../..").Path
$tmp = Join-Path ([System.IO.Path]::GetTempPath()) ("specrew-t038-" + [guid]::NewGuid().ToString('N'))
$modParent = Join-Path $tmp 'mods'
$modRoot = Join-Path $modParent 'Specrew/0.33.0'
$proj = Join-Path $tmp 'proj'
$deployed = Join-Path $tmp 'deployed-scripts'
$childScript = Join-Path $tmp 'child-floor.ps1'
$origPSModulePath = $env:PSModulePath
$origModuleOverride = $env:SPECREW_MODULE_PATH
$allPass = $true

function Write-Pass { param([string]$m) Write-Host "PASS: $m" -ForegroundColor Green }
function Write-Fail { param([string]$m) Write-Host "FAIL: $m" -ForegroundColor Red; $script:allPass = $false }

try {
    # 1. PACK the module FROM THE FILELIST (not a hand-copy): copy exactly what ships. A FileList omission
    #    therefore reproduces as a missing-from-deployed-module file -> the deployed provider fails to
    #    resolve it -> the finding. Copying the whole dev tree would MASK such an omission.
    New-Item -ItemType Directory -Path $modRoot -Force | Out-Null
    $manifest = Import-PowerShellDataFile -Path (Join-Path $devTree 'Specrew.psd1')
    $fileList = @($manifest.FileList)
    $missingSrc = New-Object System.Collections.Generic.List[string]
    $copied = 0
    foreach ($rel in $fileList) {
        $src = Join-Path $devTree $rel
        if (-not (Test-Path -LiteralPath $src)) { $missingSrc.Add($rel) | Out-Null; continue }
        $dst = Join-Path $modRoot $rel
        $dstDir = Split-Path -Parent $dst
        if (-not (Test-Path -LiteralPath $dstDir)) { New-Item -ItemType Directory -Path $dstDir -Force | Out-Null }
        Copy-Item -LiteralPath $src -Destination $dst -Force
        $copied++
    }
    if ($missingSrc.Count -gt 0) {
        Write-Fail ("FileList declares {0} file(s) absent from the dev tree (manifest lies): {1}" -f $missingSrc.Count, ($missingSrc -join ', '))
    }
    else { Write-Pass ("packed {0} FileList entries into the deployed module (FileList-faithful)" -f $copied) }

    # The launch-contract generator is the T036 linchpin - assert the FileList actually shipped it.
    if (-not (Test-Path -LiteralPath (Join-Path $modRoot 'scripts/internal/launch-contract.ps1'))) {
        Write-Fail 'launch-contract.ps1 is NOT in the packed module (FileList omission) - the deployed hook cannot reuse the generator'
    }
    else { Write-Pass 'launch-contract.ps1 shipped in the packed module' }

    # 2. The 'deployed' provider: copy ONLY the two provider scripts to a BARE dir (no bootstrap/ sibling),
    #    so $PSScriptRoot/bootstrap MISSES and resolution must fall through to tier-3 (the installed module).
    New-Item -ItemType Directory -Path $deployed -Force | Out-Null
    Copy-Item -LiteralPath (Join-Path $devTree 'scripts/internal/specrew-bootstrap-provider.ps1') -Destination $deployed -Force
    Copy-Item -LiteralPath (Join-Path $devTree 'scripts/internal/specrew-handover-provider.ps1') -Destination $deployed -Force

    # 3. The scratch project: a git repo on a FEATURE BRANCH (F carries a commit main lacks -> NOT merged ->
    #    the authored handover for F is resumable -> it surfaces on resume) + specs/<F> (present) + a
    #    .specrew/ root + config.yml. This is a real downstream-shaped project, not the dev tree.
    $featureRef = 'demo-feature'
    New-Item -ItemType Directory -Path $proj -Force | Out-Null
    git -C $proj init -q -b main 2>$null
    git -C $proj config user.email 'floor@test' 2>$null
    git -C $proj config user.name 'floor' 2>$null
    git -C $proj commit -q --allow-empty -m 'init' 2>$null
    git -C $proj checkout -q -b $featureRef 2>$null
    New-Item -ItemType Directory -Path (Join-Path $proj '.specrew') -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $proj "specs/$featureRef") -Force | Out-Null
    Set-Content -LiteralPath (Join-Path $proj '.specrew/config.yml') -Value "specrew_version: 0.33.0`n" -Encoding UTF8
    Set-Content -LiteralPath (Join-Path $proj "specs/$featureRef/spec.md") -Value "# $featureRef`n" -Encoding UTF8
    git -C $proj add -A 2>$null
    git -C $proj commit -q -m 'feature work' 2>$null
    $branchNow = (git -C $proj branch --show-current 2>$null)
    if ($branchNow -ne $featureRef) { Write-Fail "scratch git setup failed (branch '$branchNow' != '$featureRef')" }
    else { Write-Pass "scratch project ready: git repo on branch '$featureRef', specs/$featureRef present (not merged to main)" }

    # 4. The in-child floor runs under the ISOLATED PSModulePath the parent sets below (inherited), with
    #    SPECREW_MODULE_PATH unset - the deployed hook-child condition.
    $childBody = @'
param([string]$ExpectedModRoot, [string]$DeployedProvider, [string]$Proj, [string]$IsolatedModulePath, [string]$DeployedHandoverProvider, [string]$FeatureRef)
$ErrorActionPreference = 'Stop'
# pwsh RE-ADDS the user/all-users module scopes to an inherited PSModulePath AT STARTUP (that is how the
# published Specrew leaked back in). Set it HERE, post-startup, so it sticks; `& provider.ps1` runs in this
# same process, so the provider's Get-Module -ListAvailable inherits exactly this isolated path.
$env:PSModulePath = $IsolatedModulePath
$fail = 0
function Norm([string]$p) { return ([System.IO.Path]::GetFullPath($p)).TrimEnd('\','/') }

# Assertion 0a: the deployed condition - SPECREW_MODULE_PATH must be UNSET.
if (-not [string]::IsNullOrWhiteSpace($env:SPECREW_MODULE_PATH)) {
    Write-Output "FAIL discovery: SPECREW_MODULE_PATH is set ('$($env:SPECREW_MODULE_PATH)') - not the deployed condition (harness bug)"; exit 2
}
# Assertion 0b: discovery-first - Get-Module -ListAvailable resolves the PACKED module, not the published one.
$mod = Get-Module -ListAvailable Specrew | Sort-Object Version -Descending | Select-Object -First 1
if (-not $mod) { Write-Output 'FAIL discovery: Get-Module -ListAvailable Specrew found NOTHING (isolation excluded everything?)'; exit 2 }
if ((Norm $mod.ModuleBase) -ne (Norm $ExpectedModRoot)) {
    Write-Output "FAIL discovery: resolved Specrew at '$($mod.ModuleBase)' but expected the packed '$ExpectedModRoot' - isolation leaked / version collision (harness bug, NOT the finding)"; exit 2
}
Write-Output "PASS discovery: tier-3 resolves the PACKED module (Specrew $($mod.Version) @ $($mod.ModuleBase)); SPECREW_MODULE_PATH unset"

# PART 1: run the DEPLOYED (non-co-located) bootstrap provider on a B2 SessionStart -> tier-3 resolution.
$evt = '{"session_id":"t038","source":"startup","hook_event_name":"SessionStart"}'
$out = & $DeployedProvider --event-json $evt --project-root $Proj 2>&1 | Out-String
if ($out -match 'PROVIDER_FAILED') {
    Write-Output "FAIL Part1 (THE D-009 FINDING if real): provider failed-open under deployed tier-3 - the deployed hook does NOT resolve its components / write the contract.`n--- provider output ---`n$out"
    $fail = 1
}
$pp = Join-Path $Proj '.specrew/last-start-prompt.md'
$cp = Join-Path $Proj '.specrew/start-context.json'
if (-not (Test-Path -LiteralPath $pp)) { Write-Output 'FAIL Part1: last-start-prompt.md NOT written (deployed)'; $fail = 1 }
else {
    $body = Get-Content -LiteralPath $pp -Raw
    foreach ($m in '## Lifecycle Quick Reference', 'HUMAN APPROVAL GATE', 'Governance scripts', 'boundary_enforcement.policy_classes') {
        if ($body -notlike "*$m*") { Write-Output "FAIL Part1: deployed contract missing invariant marker '$m'"; $fail = 1 }
    }
}
if (-not (Test-Path -LiteralPath $cp)) { Write-Output 'FAIL Part1: start-context.json NOT written (deployed)'; $fail = 1 }
else {
    $ctx = Get-Content -LiteralPath $cp -Raw | ConvertFrom-Json
    if ($null -eq $ctx.boundary_enforcement) { Write-Output 'FAIL Part1: boundary_enforcement NOT on disk (deployed)'; $fail = 1 }
}
if ($fail -eq 0) { Write-Output 'PASS Part1: DEPLOYED SessionStart wrote the full contract + boundary_enforcement via tier-3 (evidence_locus: deployed)' }

# PART 2: the working turn + Stop captures the handover ON DISK (deployed, tier-3).
# 2a - the deployed Stop handover provider must RESOLVE (tier-3); its material-change gate may or may not
#      write, so we assert resolution (no PROVIDER_FAILED), not a specific write here.
$stopOut = & $DeployedHandoverProvider --event-json '{"session_id":"t038","hook_event_name":"Stop"}' --project-root $Proj 2>&1 | Out-String
if ($stopOut -match 'PROVIDER_FAILED') { Write-Output "FAIL Part2a (D-009 FINDING if real): deployed Stop handover provider failed-open under tier-3.`n--- output ---`n$stopOut"; $fail = 1 }
else { Write-Output 'PASS Part2a: deployed Stop handover provider resolved its components via tier-3 (no PROVIDER_FAILED)' }
# 2b - the working turn AUTHORS the rich handover body via the MODULE's Write-SpecrewHandoverContext (the
#      same agent-author path, resolved tier-3 from the installed module). This is the authored "handover on
#      disk" the user's floor names. recorded_at = now -> fresh; ActiveFeature = the resumable feature.
. (Join-Path $mod.ModuleBase 'scripts/internal/bootstrap/HandoverStore.ps1')
$nowUtc = (Get-Date).ToUniversalTime().ToString('o')
$authoredMarker = 'packed the module from the FileList and proved tier-3 resolution'
$sections = [ordered]@{
    'What I just did (last 3-5 turns or last boundary work)' = "Ran the deployed floor: $authoredMarker."
    'Recommended next-immediate-step'                        = "Resume feature $FeatureRef at the plan boundary."
}
$hoPath = Write-SpecrewHandoverContext -HandoverDir (Join-Path $Proj '.specrew/handover') -FromHost claude -RecordedAt $nowUtc -ActiveFeature $FeatureRef -ActiveBoundary 'plan' -Sections $sections
if (-not (Test-Path -LiteralPath $hoPath)) { Write-Output 'FAIL Part2b: agent-authored handover NOT written (deployed)'; $fail = 1 }
else {
    $hoRaw = Get-Content -LiteralPath $hoPath -Raw
    # AUTHORED == the rich content is present. UNFILLED sections legitimately keep the placeholder marker
    # (partial authoring is the design - the agent fills what is relevant), so do NOT reject on the mere
    # presence of a placeholder. Part 3 independently confirms the body-level detector treats this as
    # authored: it surfaces as a "Validated handover", never the hollow-handover warning.
    if ($hoRaw -notlike "*$authoredMarker*") { Write-Output 'FAIL Part2b: authored handover missing its rich content (the authored section did not land)'; $fail = 1 }
    else { Write-Output 'PASS Part2b: deployed agent-authored handover written ON DISK with the rich body (tier-3; unfilled sections keep placeholders by design)' }
}

# PART 3: a FRESH resume READS the handover back AND SURFACES it (deployed, tier-3).
$resumeOut = & $DeployedProvider --event-json '{"session_id":"t038-resume","source":"resume","hook_event_name":"SessionStart"}' --project-root $Proj 2>&1 | Out-String
if ($resumeOut -match 'PROVIDER_FAILED') { Write-Output "FAIL Part3 (D-009 FINDING if real): deployed resume bootstrap failed-open under tier-3.`n--- output ---`n$resumeOut"; $fail = 1 }
elseif ($resumeOut -notmatch 'Validated handover authored by the previous session') { Write-Output "FAIL Part3: resume did NOT surface the authored handover (validity/read failed in the deployed condition).`n--- directive ---`n$resumeOut"; $fail = 1 }
elseif ($resumeOut -notlike "*$authoredMarker*") { Write-Output "FAIL Part3: resume surfaced the handover header but NOT the rich body sections.`n--- directive ---`n$resumeOut"; $fail = 1 }
else { Write-Output 'PASS Part3: deployed resume READ + SURFACED the agent-authored handover - full 3-part round-trip GREEN (tier-3, evidence_locus: deployed)' }

exit $fail
'@
    Set-Content -LiteralPath $childScript -Value $childBody -Encoding UTF8

    # Parent sets the ISOLATED env (inherited) AND passes it for the child to re-assert post-startup (pwsh
    # re-adds the user/all-users scopes at startup, so inheritance alone leaks the published module back in).
    # The isolated path = ONLY the packed module + $PSHOME/Modules (built-ins); the user scope where the
    # published 0.33.0 lives is EXCLUDED. SPECREW_MODULE_PATH unset = the deployed hook-child condition.
    $isolated = $modParent + [System.IO.Path]::PathSeparator + (Join-Path $PSHOME 'Modules')
    $env:PSModulePath = $isolated
    if (Test-Path Env:SPECREW_MODULE_PATH) { Remove-Item Env:SPECREW_MODULE_PATH }

    $childOut = & pwsh -NoProfile -File $childScript -ExpectedModRoot $modRoot -DeployedProvider (Join-Path $deployed 'specrew-bootstrap-provider.ps1') -Proj $proj -IsolatedModulePath $isolated -DeployedHandoverProvider (Join-Path $deployed 'specrew-handover-provider.ps1') -FeatureRef $featureRef 2>&1 | Out-String
    $childCode = $LASTEXITCODE
    Write-Host "---- child floor output ----"
    Write-Host $childOut.TrimEnd()
    Write-Host "----------------------------"
    if ($childCode -eq 2) { Write-Fail 'HARNESS error (discovery/isolation) - fix the harness, NOT a finding' }
    elseif ($childCode -ne 0) { Write-Fail 'DEPLOYED floor RED - report as the D-009 finding (do NOT paper green)' }
    else { Write-Pass 'DEPLOYED floor GREEN: 3-part round-trip (SessionStart contract + Stop/authored handover + resume surface), provider-direct under tier-3, evidence_locus: deployed' }
}
finally {
    $env:PSModulePath = $origPSModulePath
    if ($null -ne $origModuleOverride) { $env:SPECREW_MODULE_PATH = $origModuleOverride }
    Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue
}

if (-not $allPass) { Write-Host "`n=== deployed-bootstrap-floor: FAILED ===" -ForegroundColor Red; exit 1 }
Write-Host "`n=== deployed-bootstrap-floor: 3-part round-trip PASSED (evidence_locus: deployed) ===" -ForegroundColor Green
