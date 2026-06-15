$ErrorActionPreference = 'Stop'

# F-174 iteration 007 (T046): the AUTOMATABLE half of the side-by-side acceptance gate (Ruling d).
#
# It asserts the HOOK's written contract is byte-identical to what `specrew start`'s GENERATION PATH produces
# - i.e. the hook delivers the SAME `Get-StartPrompt` + `Invoke-SpecrewCoordinatorPromptSurgery` contract the
# launcher does (`scripts/specrew-start.ps1` L3332-3356), carrying the user-profile/expertise adaptation +
# coordinator framing that iter-6 DROPPED. The reference here encodes the launcher's generation pattern
# independently of the hook, so if the hook path drifts from it (the iter-6 no-surgery regression), this FAILS.
#
# SCOPE HONESTY (Ruling Prompt 3): this is NECESSARY but NOT SUFFICIENT. It proves the CONTRACT is equivalent;
# it CANNOT prove the agent READS + FOLLOWS it - that is the MANUAL DOGFOOD (T047), the gate's disqualifier.
# Per Ruling b the side-by-side is the arbiter; a diff surfaced here is a real parity gap, not noise.
# (Genuinely launcher-only inputs - casting roster/routing/projectstate - are passed identically on both
# sides here, so they cannot mask a parity drift; the launcher's REAL casting differs only in those blocks,
# which Ruling d explicitly excludes from the parity comparison.)

$repoRoot = (Resolve-Path "$PSScriptRoot/../..").Path
foreach ($f in 'scripts/internal/bootstrap/SessionStateAccessor.ps1', 'scripts/internal/launch-contract.ps1',
    'scripts/internal/coordinator-resume.ps1', 'scripts/internal/coordinator-prompt-surgery.ps1',
    'scripts/internal/user-profile.ps1', 'extensions/specrew-speckit/scripts/shared-governance.ps1',
    'scripts/internal/bootstrap/SessionBootstrapManager.ps1') {
    . (Join-Path $repoRoot $f)
}

function Assert-True {
    param([bool]$Condition, [string]$Message)
    if (-not $Condition) { throw "FAIL: $Message" }
    Write-Host "PASS: $Message" -ForegroundColor Green
}

$root = Join-Path ([System.IO.Path]::GetTempPath()) ("specrew-t046-" + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path (Join-Path $root '.specrew') -Force | Out-Null
New-Item -ItemType Directory -Path (Join-Path $root 'specs/demo-feature') -Force | Out-Null
Set-Content -LiteralPath (Join-Path $root '.specrew/config.yml') -Value "specrew_version: 0.33.0`n" -Encoding UTF8
Set-Content -LiteralPath (Join-Path $root 'specs/demo-feature/spec.md') -Value "# demo-feature`n" -Encoding UTF8

$mode = 'resume-feature'
$anchor = [pscustomobject]@{
    active = $true; feature_ref = 'demo-feature'; feature_path = (Join-Path $root 'specs/demo-feature')
    boundary = 'plan'; iteration = '001'; task_id = $null; auth_commit_hash = 'x'; recorded_at = 't'
}

# (1) The HOOK contract - the real hook path (the manager writes last-start-prompt.md).
$hookPath = Write-SpecrewLaunchContractArtifact -ProjectRoot $root -Mode $mode -SessionState $anchor
$hookContract = Get-Content -LiteralPath $hookPath -Raw -Encoding UTF8

# (2) `specrew start`'s GENERATION path, reconstructed from specrew-start.ps1 L3332-3356: Get-StartPrompt then
#     the SAME coordinator surgery (with the session-available -ExpertiseLine the launcher threads). Launcher-
#     only inputs (roster/routing/projectstate) are passed identically here so they cannot mask a parity drift.
$genAnchor = [pscustomobject]@{
    feature_ref = $anchor.feature_ref; feature_path = $anchor.feature_path
    boundary_type = $anchor.boundary; iteration_number = $anchor.iteration; task_id = $anchor.task_id
}
$ref = Get-StartPrompt -ResolvedProjectPath $root -Mode $mode -FeatureRequest '' `
    -ResolvedFeaturePath ([string]$anchor.feature_path) `
    -TeamRoster ([pscustomobject]@{ mode = 'none' }) `
    -RoutingPlan ([pscustomobject]@{ enabled_agents = @(); roles = @{}; fallback_events = @() }) `
    -ProjectState ([pscustomobject]@{ state = 'active'; spec_directories = @(); detected_entries = @() }) `
    -BrownfieldDiscovery $null -DeliveryGuidance $null -SessionState $genAnchor -RecoverySession $null
$ref = Invoke-SpecrewCoordinatorPromptSurgery -Prompt $ref -HostKind 'claude' -LifecycleMode $mode `
    -FeatureRef 'demo-feature' -BoundaryType 'plan' `
    -ExpertiseLine (Get-SpecrewProfileOrientationLine -Profile (Get-UserProfile))
$ref = $ref + [Environment]::NewLine   # the manager appends a trailing newline (Write-Utf8FileAtomic)

# (3) The side-by-side: byte-identical -> the hook delivers EXACTLY specrew start's generation.
if ($hookContract -ne $ref) {
    $hl = @($hookContract -split "`n"); $rl = @($ref -split "`n")
    $max = [Math]::Max($hl.Count, $rl.Count)
    for ($i = 0; $i -lt $max; $i++) {
        if (($hl[$i]) -ne ($rl[$i])) {
            Write-Host ("  first diff at line {0}:`n    hook: {1}`n    ref : {2}" -f ($i + 1), $hl[$i], $rl[$i]) -ForegroundColor Yellow
            break
        }
    }
}
Assert-True ($hookContract -eq $ref) 'SIDE-BY-SIDE: the hook contract is byte-identical to specrew start''s Get-StartPrompt+surgery generation (no drift, no dropped content - the iter-6 regression guard)'

# (4) Defense-in-depth: the parity content iter-6 dropped is actually present.
Assert-True ($hookContract -match 'What I know about you') 'parity content present: the user-profile/expertise adaptation line'
Assert-True ($hookContract -match 'You are the Crew team coordinator') 'parity content present: the coordinator framing'
foreach ($m in '## Lifecycle Quick Reference', 'HUMAN APPROVAL GATE', 'boundary_enforcement.policy_classes') {
    Assert-True ($hookContract -like "*$m*") "parity content present: invariant contract marker '$m'"
}

Write-Host "`n=== contract-parity-side-by-side.tests.ps1: hook contract == specrew start generation (automatable half; the manual dogfood is the gate) ===" -ForegroundColor Green
