[CmdletBinding()]
param()

# F-050 Cursor host package — unit tests for the 5 contract functions.
# Convention: custom Write-Pass/Write-Fail (matches tests/integration/host-*.tests.ps1),
# not Pester. The Install deploy-loop across all hosts is covered by
# crew-bootstrap-contract.tests.ps1; this file asserts cursor-specific behavior.

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Write-Pass { param([string]$Message) Write-Host "PASS: $Message" -ForegroundColor Green }
function Write-Fail { param([string]$Message) Write-Host "FAIL: $Message" -ForegroundColor Red; exit 1 }

$repoRoot = (Resolve-Path (Join-Path -Path $PSScriptRoot -ChildPath '..\..')).Path
. (Join-Path $repoRoot 'hosts\_registry.ps1')   # dot-sources _team-canonical + all host handlers

# ---------------------------------------------------------------------------
# New-CursorLaunchInvocation
# ---------------------------------------------------------------------------
$base = New-CursorLaunchInvocation -ProjectPath 'C:\proj' -Prompt 'BOOT' -Agent 'Squad'
if ($base.HostKind -ne 'cursor') { Write-Fail "Launch HostKind expected 'cursor', got '$($base.HostKind)'" }
if ($base.Binary -notmatch 'cursor-agent') { Write-Fail "Launch Binary expected to resolve cursor-agent, got '$($base.Binary)'" }
$baseArgs = $base.Args -join '|'
if ($baseArgs -ne 'BOOT|--workspace|C:\proj') { Write-Fail "Default launch argv drift: '$baseArgs' (expected interactive 'BOOT|--workspace|C:\proj')" }
if ($base.Args -contains '--print') { Write-Fail "Default launch must be INTERACTIVE (no --print)" }
if ($base.Args -contains '--force') { Write-Fail "Default launch must NOT auto-approve (--force present without --allow-all)" }
Write-Pass "New-CursorLaunchInvocation builds interactive 'cursor-agent <prompt> --workspace <path>' with no auto-approve by default"

$allow = New-CursorLaunchInvocation -ProjectPath 'C:\proj' -Prompt 'BOOT' -Agent 'Squad' -AllowAll $true
if ($allow.Args -notcontains '--force') { Write-Fail "AllowAll launch must include --force; got '$($allow.Args -join '|')'" }
Write-Pass "New-CursorLaunchInvocation adds --force only under -AllowAll"

# ---------------------------------------------------------------------------
# ConvertTo-CursorFlag
# ---------------------------------------------------------------------------
$fAllow = ConvertTo-CursorFlag -SpecrewFlag '--allow-all'
if (($fAllow.Args -join '|') -ne '--force') { Write-Fail "--allow-all should map to --force; got '$($fAllow.Args -join '|')'" }
if (-not $fAllow.SuppressWarning) { Write-Fail "--allow-all translation should SuppressWarning" }
$fAuto = ConvertTo-CursorFlag -SpecrewFlag '--autopilot'
if ($fAuto.Args.Count -ne 0) { Write-Fail "--autopilot should emit no extra args (folds into --force); got '$($fAuto.Args -join '|')'" }
$fRemote = ConvertTo-CursorFlag -SpecrewFlag '--remote'
if ($fRemote.Args.Count -ne 0) { Write-Fail "--remote should emit no args (no Cursor equivalent)" }
if ($fRemote.SuppressWarning) { Write-Fail "--remote has no equivalent — should NOT SuppressWarning (user should see the notice)" }
Write-Pass "ConvertTo-CursorFlag maps --allow-all->--force, --autopilot->no-op, --remote->warn-and-drop"

# ---------------------------------------------------------------------------
# Test-CursorRuntimeInstalled
# ---------------------------------------------------------------------------
$tmp = Join-Path ([System.IO.Path]::GetTempPath()) ("specrew-cursor-test-" + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $tmp -Force | Out-Null
try {
    if (Test-CursorRuntimeInstalled -ProjectPath $tmp) { Write-Fail "Test-CursorRuntimeInstalled should be FALSE with no .cursor/rules" }
    $rules = Join-Path $tmp '.cursor\rules'
    New-Item -ItemType Directory -Path $rules -Force | Out-Null
    if (Test-CursorRuntimeInstalled -ProjectPath $tmp) { Write-Fail "Test-CursorRuntimeInstalled should be FALSE with empty .cursor/rules" }
    Set-Content -Path (Join-Path $rules 'probe.mdc') -Value '---' -Encoding utf8
    if (-not (Test-CursorRuntimeInstalled -ProjectPath $tmp)) { Write-Fail "Test-CursorRuntimeInstalled should be TRUE once an .mdc rule exists" }
    Write-Pass "Test-CursorRuntimeInstalled detects .cursor/rules/*.mdc presence (false->false->true)"

    # -----------------------------------------------------------------------
    # Install-CursorCrewRuntime — cursor-specific .mdc output + dry-run + idempotent preserve
    # -----------------------------------------------------------------------
    Remove-Item -Path (Join-Path $rules '*') -Force -ErrorAction SilentlyContinue  # clear the unmanaged probe
    Initialize-SpecrewTeamCanonical -ProjectPath $tmp | Out-Null

    $dry = Install-CursorCrewRuntime -ProjectPath $tmp -DryRun
    if ($dry.CrewRuntimePath -notmatch 'rules') { Write-Fail "Install CrewRuntimePath should target .cursor/rules; got '$($dry.CrewRuntimePath)'" }
    if (-not ($dry.Actions | Where-Object { $_.Action -eq 'would-write' })) { Write-Fail "DryRun should report would-write actions, not write files" }

    $real = Install-CursorCrewRuntime -ProjectPath $tmp
    $written = @($real.Actions | Where-Object { $_.Action -eq 'written' })
    if ($written.Count -lt 1) { Write-Fail "Install should write at least one .mdc rule file" }
    $plannerRule = Join-Path $tmp '.cursor\rules\planner.mdc'
    if (-not (Test-Path -LiteralPath $plannerRule)) { Write-Fail "Expected planner.mdc to be written" }
    $ruleText = Get-Content -LiteralPath $plannerRule -Raw
    if ($ruleText -notmatch '(?m)^description:') { Write-Fail "Generated .mdc must carry MDC front-matter 'description:'" }
    if ($ruleText -notmatch 'alwaysApply:') { Write-Fail "Generated .mdc must carry 'alwaysApply:' front-matter" }
    if ($ruleText -notmatch 'Specrew-managed') { Write-Fail "Generated .mdc must carry the Specrew-managed marker" }
    Write-Pass "Install-CursorCrewRuntime emits Specrew-managed .cursor/rules/<role>.mdc with MDC front-matter; -DryRun writes nothing"

    # Idempotent re-run preserves the now-managed file without duplication
    $again = Install-CursorCrewRuntime -ProjectPath $tmp
    $mdcCount = @(Get-ChildItem -Path (Join-Path $tmp '.cursor\rules') -Filter '*.mdc').Count
    $roleCount = @(Get-SpecrewCanonicalAgentRoles -ProjectPath $tmp).Count
    if ($mdcCount -ne $roleCount) { Write-Fail "Re-run duplicated rules: $mdcCount .mdc files for $roleCount roles" }
    Write-Pass "Install-CursorCrewRuntime is idempotent (no duplicate .mdc on re-run)"
}
finally {
    Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue
}

# ---------------------------------------------------------------------------
# Get-CursorSignals
# ---------------------------------------------------------------------------
$before = @(Get-CursorSignals)
if ($before -contains 'CURSOR_TRACE_ID') { Write-Fail "Pre-condition: CURSOR_TRACE_ID should not be set in test env" }
$env:CURSOR_TRACE_ID = 'test-trace'
try {
    $after = @(Get-CursorSignals)
    if ($after -notcontains 'CURSOR_TRACE_ID') { Write-Fail "Get-CursorSignals should detect CURSOR_TRACE_ID when set" }
}
finally {
    Remove-Item Env:\CURSOR_TRACE_ID -ErrorAction SilentlyContinue
}
Write-Pass "Get-CursorSignals returns set Cursor env-var names (detects CURSOR_TRACE_ID)"

Write-Host "`nCursor host package: all assertions pass" -ForegroundColor Green
