#requires -Version 7.0
# Feature 202 T009 (FR-016, SC-005; B4F-107): one adaptation sentence on every host.
#
# The adaptation text is the prose sentence user-profile.ps1 renders, identical on every validated host apart from
# the correction reference the host adapter supplies. The numeric renderer ("software_architecture=10, ...") that
# reached Codex is gone.
#
# Cases:
#   1. The sentence for claude, codex and copilot is byte-identical once the correction reference is removed.
#   2. No key=number text on any host.
#   3. The reference follows the host manifest: a slash command where the host has one, a plain request where not.
#   4. Through the delivery surfaces: the conformance turn-start supply and the bootstrap's first-prompt orientation
#      carry the same sentence on each host, with no key=number text.
#   5. The numeric renderer no longer exists.
#
# RED: run with SPECREW_T009_SCRIPTS_ROOT pointing at the pre-T009 scripts; the conformance supply carries
# "software_architecture=9" there.
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$scriptsRoot = if (-not [string]::IsNullOrWhiteSpace($env:SPECREW_T009_SCRIPTS_ROOT)) { $env:SPECREW_T009_SCRIPTS_ROOT } else { Join-Path $repoRoot 'extensions\specrew-speckit\scripts' }
$provider = Join-Path $scriptsRoot 'specrew-conformance-provider.ps1'
$bootstrap = Join-Path $scriptsRoot 'specrew-bootstrap-provider.ps1'
. (Join-Path $repoRoot 'extensions\specrew-speckit\scripts\turn-end-store.ps1')
. (Join-Path $repoRoot 'scripts\internal\user-profile.ps1')
$savedModulePath = $env:SPECREW_MODULE_PATH
$savedProfilePath = $env:SPECREW_USER_PROFILE_PATH
$env:SPECREW_MODULE_PATH = $repoRoot
$script:failCount = 0
$hosts = @('claude', 'codex', 'copilot')
$numeric = '\b[a-z_]+=\d'

function Write-Pass { param([string]$Message) Write-Host "PASS: $Message" -ForegroundColor Green }
function Write-Fail { param([string]$Message) Write-Host "FAIL: $Message" -ForegroundColor Red; $script:failCount++ }
function Assert-True { param([bool]$Condition, [string]$Message) if ($Condition) { Write-Pass $Message } else { Write-Fail $Message } }

function Remove-Reference {
    # The sentence with its correction reference taken out, which is the part that must not differ by host.
    param([string]$Line, [string]$HostKind)
    return $Line.Replace((Get-SpecrewProfileCorrectionReference -HostKind $HostKind), '<reference>')
}

$root = [System.IO.Path]::GetFullPath((Join-Path ([System.IO.Path]::GetTempPath()) ("t009-{0}" -f [guid]::NewGuid().ToString('N').Substring(0, 10))))
try {
    New-Item -ItemType Directory -Force -Path (Join-Path $root '.specrew/runtime') | Out-Null
    & git -C $root init -q -b main
    $profilePath = Join-Path $root 'user-profile.yml'
    [System.IO.File]::WriteAllText($profilePath, "expertise:`n  software_architecture: 9`n  ui_ux: 10`n  product_management: 7`n  ai_research_project_management: 2`n", [System.Text.UTF8Encoding]::new($false))
    $env:SPECREW_USER_PROFILE_PATH = $profilePath
    $expectedCore = "What I know about you: I'll treat you as mid-level on Product Strategy, expert on UX/UI Design, expert on Software Architecture, learning on AI Delivery Planning — correct me if that's off (<reference>), and I'll match how much I ask and explain to it."

    # -----------------------------------------------------------------------------------------------
    Write-Host 'Cases 1-3: the shared sentence per host'
    $lines = @{}
    foreach ($h in $hosts) { $lines[$h] = Get-SpecrewOrientationAdaptationLine -HostKind $h -ProjectRoot $root }
    foreach ($h in $hosts) {
        Assert-True ((Remove-Reference -Line $lines[$h] -HostKind $h) -ceq $expectedCore) ("{0}: the shared sentence, byte-identical apart from the reference" -f $h)
        Assert-True ($lines[$h] -notmatch $numeric) ("{0}: no key=number text" -f $h)
    }
    Assert-True ($lines['claude'].Contains('(`/specrew-user-profile edit`)') -and $lines['copilot'].Contains('(`/specrew-user-profile edit`)')) 'hosts with a slash-command surface name the command'
    Assert-True ($lines['codex'].Contains('(ask me to update your profile)')) 'Codex, which has no slash-command surface, names the plain request'

    # -----------------------------------------------------------------------------------------------
    Write-Host 'Case 4: the delivery surfaces carry the same sentence'
    foreach ($h in $hosts) {
        Push-Location -LiteralPath $root
        try {
            $supply = (@(& pwsh -NoProfile -NonInteractive -File $provider --host-kind $h --source-event UserPromptSubmit --session-id ("dp-c-{0}" -f $h) --last-user-message 'Hi.' --turn-origin typed-user 2>&1) -join "`n")
            $record = [ordered]@{ schema = 'specrew-turn-record/v1'; event = 'UserPromptSubmit'; host = $h; session_id = ("dp-b-{0}" -f $h); safe_session_id = ("dp-b-{0}" -f $h); source = $null }
            $encoded = [Convert]::ToBase64String([Text.UTF8Encoding]::new($false).GetBytes(($record | ConvertTo-Json -Compress)))
            $orientation = (@(& pwsh -NoProfile -NonInteractive -File $bootstrap --turn-record $encoded --host-kind $h --source-event UserPromptSubmit --project-root $root 2>&1) -join "`n")
        }
        finally { Pop-Location }
        Assert-True ($supply.Contains($lines[$h]) -and $supply -notmatch $numeric) ("{0}: the conformance turn-start supply carries the shared sentence, no key=number text" -f $h)
        Assert-True ($orientation.Contains($lines[$h]) -and $orientation -notmatch $numeric) ("{0}: the first-prompt orientation carries the shared sentence, no key=number text" -f $h)
    }

    # -----------------------------------------------------------------------------------------------
    Write-Host 'Case 5: the numeric renderer is gone'
    $storeText = Get-Content -LiteralPath (Join-Path $scriptsRoot 'turn-end-store.ps1') -Raw
    Assert-True ($storeText -notmatch 'function Get-SpecrewOrientationDialsLine') 'Get-SpecrewOrientationDialsLine no longer exists'
}
finally {
    Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue
    $env:SPECREW_MODULE_PATH = $savedModulePath
    $env:SPECREW_USER_PROFILE_PATH = $savedProfilePath
}
if ($script:failCount -gt 0) { throw ("dials-parity: {0} assertion(s) failed" -f $script:failCount) }
Write-Host 'dials-parity: all assertions passed' -ForegroundColor Green
