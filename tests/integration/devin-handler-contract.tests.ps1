[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Feature 200 T010 (FR-007, FR-008): the five-handler contract for hosts/devin/handlers.ps1.
# This test PINS the Devin launch argv against the VERIFIED facts of the pinned CLI
# `devin 2026.7.23 (3bd47f77)` (`devin --help`), not against assumptions:
#   - Launch shape `devin [OPTIONS] [-- <PROMPT>...]`: the bootstrap prompt is POSITIONAL after a
#     `--` option-terminator (NOT a flag value, NOT headless `-p`).
#   - There is NO `--cwd` flag; the cwd comes from the spawned process working directory, so the
#     launch argv MUST NOT contain `--cwd` or the project path.
#   - `--permission-mode <auto|smart|dangerous>` maps normal->auto / autopilot->smart /
#     allow-all->dangerous, with dangerous PRECEDENCE over smart + an explicit notice.
# It also exercises ConvertTo-DevinFlag, Test-DevinRuntimeInstalled, Get-DevinSignals, and the
# nested-AGENT.md Crew-runtime shape of Install-DevinCrewRuntime (FR-008).

function Write-Pass { param([string]$Message) Write-Host "PASS: $Message" -ForegroundColor Green }
function Write-Fail { param([string]$Message) Write-Host "FAIL: $Message" -ForegroundColor Red; exit 1 }

$repoRoot = (Resolve-Path (Join-Path -Path $PSScriptRoot -ChildPath '..\..')).Path
$registryScript = Join-Path $repoRoot 'hosts\_registry.ps1'
$handlersScript = Join-Path $repoRoot 'hosts\devin\handlers.ps1'

foreach ($p in @($registryScript, $handlersScript)) {
    if (-not (Test-Path -LiteralPath $p -PathType Leaf)) { Write-Fail "Missing required file: $p" }
}

# The registry dot-sources _team-canonical.ps1 (canonical role helpers) used by Install-DevinCrewRuntime.
. $registryScript
. $handlersScript

# --- Test 0: all five contract functions are present after sourcing handlers.ps1. ---
foreach ($fn in 'New-DevinLaunchInvocation', 'ConvertTo-DevinFlag', 'Test-DevinRuntimeInstalled', 'Get-DevinSignals', 'Install-DevinCrewRuntime') {
    if (-not (Get-Command $fn -ErrorAction SilentlyContinue)) {
        Write-Fail "Expected contract function not found after sourcing handlers.ps1: $fn"
    }
}
Write-Pass 'All five Devin contract functions present (New-DevinLaunchInvocation, ConvertTo-DevinFlag, Test-DevinRuntimeInstalled, Get-DevinSignals, Install-DevinCrewRuntime)'

# --- Test 1: NORMAL launch argv golden — NO --cwd, normal->auto, prompt positional after `--`. ---
$normal = New-DevinLaunchInvocation -ProjectPath 'C:\proj' -Prompt 'BOOT' -Agent 'Crew'
$normalArgs = @($normal.Args)
$normalJoined = ($normalArgs -join '|')
$expectedNormal = '--permission-mode|auto|--|BOOT'
if ($normalJoined -ne $expectedNormal) {
    Write-Fail "Devin normal launch argv mismatch:`n  expected: $expectedNormal`n  got     : $normalJoined"
}
if ($normal.HostKind -ne 'devin') { Write-Fail "Devin launch HostKind should be 'devin'; got '$($normal.HostKind)'" }
Write-Pass 'Normal launch argv golden: --permission-mode auto -- BOOT (no --cwd, prompt positional after `--`)'

# --- Test 2: the launch argv NEVER contains a --cwd flag or the project path (verified: no --cwd). ---
foreach ($mode in @(
        @{ AllowAll = $false; UseAutopilot = $false; UseRemote = $false; Label = 'normal' },
        @{ AllowAll = $true; UseAutopilot = $false; UseRemote = $false; Label = 'allow-all' },
        @{ AllowAll = $false; UseAutopilot = $true; UseRemote = $false; Label = 'autopilot' },
        @{ AllowAll = $true; UseAutopilot = $true; UseRemote = $true; Label = 'all' }
    )) {
    $inv = New-DevinLaunchInvocation -ProjectPath 'C:\proj\with space' -Prompt 'BOOT' -Agent 'Crew' -AllowAll $mode.AllowAll -UseAutopilot $mode.UseAutopilot -UseRemote $mode.UseRemote
    $a = @($inv.Args)
    if ($a -contains '--cwd') {
        Write-Fail "Devin launch ($($mode.Label)) injected a --cwd flag; the verified CLI has NO --cwd (cwd is the process working dir)."
    }
    if ($a -contains 'C:\proj\with space') {
        Write-Fail "Devin launch ($($mode.Label)) injected the project path as an argument; cwd must come from the spawned process working directory only."
    }
}
Write-Pass 'No launch mode injects --cwd or the project path as an argument (cwd = process working dir, verified no --cwd flag)'

# --- Test 3: the prompt is the LAST token and is immediately preceded by the `--` terminator. ---
foreach ($mode in @(
        @{ AllowAll = $false; UseAutopilot = $false; Label = 'normal' },
        @{ AllowAll = $true; UseAutopilot = $false; Label = 'allow-all' },
        @{ AllowAll = $false; UseAutopilot = $true; Label = 'autopilot' }
    )) {
    $inv = New-DevinLaunchInvocation -ProjectPath 'C:\proj' -Prompt 'PROMPT-SENTINEL' -Agent 'Crew' -AllowAll $mode.AllowAll -UseAutopilot $mode.UseAutopilot
    $a = @($inv.Args)
    if ($a.Count -lt 2) { Write-Fail "Devin launch ($($mode.Label)) argv too short to hold `-- <prompt>`: $($a -join '|')" }
    if ($a[$a.Count - 1] -ne 'PROMPT-SENTINEL') {
        Write-Fail "Devin launch ($($mode.Label)) prompt is not the last token: $($a -join '|')"
    }
    if ($a[$a.Count - 2] -ne '--') {
        Write-Fail "Devin launch ($($mode.Label)) prompt is not immediately preceded by the `--` option-terminator: $($a -join '|')"
    }
    # `-p` / `--print` headless mode must never appear in the normal governed launch.
    if (($a -contains '-p') -or ($a -contains '--print')) {
        Write-Fail "Devin launch ($($mode.Label)) used headless -p/--print; that is canary-only, never the normal session."
    }
}
Write-Pass 'Prompt is always the last token, immediately after the `--` terminator; no -p/--print in the normal launch'

# --- Test 4: permission-mode mapping normal->auto / autopilot->smart / allow-all->dangerous. ---
$auto = New-DevinLaunchInvocation -ProjectPath 'C:\proj' -Prompt 'B' -Agent 'Crew'
if ((@($auto.Args) -join '|') -notmatch '(^|\|)--permission-mode\|auto(\||$)') {
    Write-Fail "normal mode must map to --permission-mode auto; got: $(@($auto.Args) -join '|')"
}
$smart = New-DevinLaunchInvocation -ProjectPath 'C:\proj' -Prompt 'B' -Agent 'Crew' -UseAutopilot $true
if ((@($smart.Args) -join '|') -notmatch '(^|\|)--permission-mode\|smart(\||$)') {
    Write-Fail "autopilot must map to --permission-mode smart; got: $(@($smart.Args) -join '|')"
}
$danger = New-DevinLaunchInvocation -ProjectPath 'C:\proj' -Prompt 'B' -Agent 'Crew' -AllowAll $true
if ((@($danger.Args) -join '|') -notmatch '(^|\|)--permission-mode\|dangerous(\||$)') {
    Write-Fail "allow-all must map to --permission-mode dangerous; got: $(@($danger.Args) -join '|')"
}
Write-Pass 'Permission-mode mapping correct: normal->auto, autopilot->smart, allow-all->dangerous'

# --- Test 5: dangerous PRECEDENCE — allow-all + autopilot together yields dangerous (not smart) + a notice. ---
$both = New-DevinLaunchInvocation -ProjectPath 'C:\proj' -Prompt 'B' -Agent 'Crew' -AllowAll $true -UseAutopilot $true
$bothJoined = (@($both.Args) -join '|')
if ($bothJoined -match '(^|\|)--permission-mode\|smart(\||$)') {
    Write-Fail "dangerous must take precedence over smart when both are requested; argv contains smart: $bothJoined"
}
if ($bothJoined -notmatch '(^|\|)--permission-mode\|dangerous(\||$)') {
    Write-Fail "dangerous must win when allow-all + autopilot are both requested; argv: $bothJoined"
}
$precedenceNotice = @($both.Notices) | Where-Object { $_ -match 'precedence' }
if (-not $precedenceNotice) {
    Write-Fail "dangerous-over-smart precedence must be surfaced as an explicit notice; notices: $(@($both.Notices) -join ' / ')"
}
Write-Pass 'dangerous precedence: allow-all + autopilot yields dangerous (never smart) plus an explicit precedence notice'

# --- Test 6: ConvertTo-DevinFlag mapping + SuppressWarning shape. ---
$cAllow = ConvertTo-DevinFlag -SpecrewFlag '--allow-all'
if ((@($cAllow.Args) -join '|') -ne '--permission-mode|dangerous') { Write-Fail "ConvertTo-DevinFlag --allow-all should map to (--permission-mode dangerous); got: $(@($cAllow.Args) -join '|')" }
$cAuto = ConvertTo-DevinFlag -SpecrewFlag '--autopilot'
if ((@($cAuto.Args) -join '|') -ne '--permission-mode|smart') { Write-Fail "ConvertTo-DevinFlag --autopilot should map to (--permission-mode smart); got: $(@($cAuto.Args) -join '|')" }
$cRemote = ConvertTo-DevinFlag -SpecrewFlag '--remote'
if (@($cRemote.Args).Count -ne 0) { Write-Fail "ConvertTo-DevinFlag --remote should inject no args (Devin has no remote-control flag); got: $(@($cRemote.Args) -join '|')" }
if ([string]::IsNullOrWhiteSpace($cRemote.Notice)) { Write-Fail 'ConvertTo-DevinFlag --remote should surface a warn-and-continue notice.' }
if ($cRemote.SuppressWarning -ne $false) { Write-Fail 'ConvertTo-DevinFlag --remote must NOT suppress the warning (warn-and-continue).' }
Write-Pass 'ConvertTo-DevinFlag maps --allow-all->dangerous, --autopilot->smart, --remote->no-op-with-warning'

# --- Test 7: --remote surfaces a notice in the launch invocation but injects no args. ---
$remoteInv = New-DevinLaunchInvocation -ProjectPath 'C:\proj' -Prompt 'B' -Agent 'Crew' -UseRemote $true
$remoteNotice = @($remoteInv.Notices) | Where-Object { $_ -match 'remote' }
if (-not $remoteNotice) { Write-Fail "Devin launch with --remote should surface a remote-not-supported notice; notices: $(@($remoteInv.Notices) -join ' / ')" }
Write-Pass '--remote surfaces a notice in the launch invocation (no remote-control args injected)'

# --- Test 8: routes correctly through the registry dispatcher (Invoke-HostHandler / Get-SpecrewHostLaunchInvocation path). ---
$dispatched = Invoke-HostHandler -Kind 'devin' -ContractFunction NewLaunchInvocation -Arguments @{
    ProjectPath = 'C:\proj'; Prompt = 'BOOT'; Agent = 'Crew'; AllowAll = $false; UseAutopilot = $false; UseRemote = $false
}
if ((@($dispatched.Args) -join '|') -ne '--permission-mode|auto|--|BOOT') {
    Write-Fail "Registry dispatch (Invoke-HostHandler) produced unexpected argv: $(@($dispatched.Args) -join '|')"
}
Write-Pass 'Registry dispatch (Invoke-HostHandler NewLaunchInvocation) routes to New-DevinLaunchInvocation with the expected argv'

# --- Test 9: Install-DevinCrewRuntime deploys NESTED .devin/agents/<role>/AGENT.md (FR-008), unlike claude's flat shape. ---
$proj = Join-Path ([System.IO.Path]::GetTempPath()) ("specrew-devin-crew-" + [System.IO.Path]::GetRandomFileName())
New-Item -ItemType Directory -Path $proj -Force | Out-Null
try {
    # Seed a canonical team so the runtime has roles to translate.
    $seed = Initialize-SpecrewTeamCanonical -ProjectPath $proj
    if (-not $seed) { Write-Fail 'Initialize-SpecrewTeamCanonical returned nothing.' }

    $result = Install-DevinCrewRuntime -ProjectPath $proj
    $crewRoot = $result.CrewRuntimePath
    if ($crewRoot.Replace('\', '/') -notlike '*/.devin/agents') {
        Write-Fail "Install-DevinCrewRuntime CrewRuntimePath should resolve to .devin/agents; got: $crewRoot"
    }

    $written = @($result.Actions | Where-Object { $_.Action -eq 'written' })
    if ($written.Count -lt 1) { Write-Fail "Install-DevinCrewRuntime wrote no agent files; actions: $($result.Actions | ForEach-Object { $_.Action } | Sort-Object -Unique)" }

    # Each written file MUST be nested per-agent: .devin/agents/<role>/AGENT.md (NOT a flat <role>.md).
    foreach ($act in $written) {
        $p = [string]$act.Path
        $norm = $p.Replace('\', '/')
        if ($norm -notmatch '/\.devin/agents/[^/]+/AGENT\.md$') {
            Write-Fail "Devin Crew agent file is not nested .devin/agents/<role>/AGENT.md: $p"
        }
        if (-not (Test-Path -LiteralPath $p -PathType Leaf)) { Write-Fail "Expected written Devin AGENT.md missing on disk: $p" }
        $body = Get-Content -LiteralPath $p -Raw -Encoding UTF8
        if ($body -notmatch 'Specrew-managed') { Write-Fail "Devin AGENT.md missing the Specrew-managed marker: $p" }
    }

    # The detector agrees the runtime is installed.
    if (-not (Test-DevinRuntimeInstalled -ProjectPath $proj)) {
        Write-Fail 'Test-DevinRuntimeInstalled returned $false after Install-DevinCrewRuntime deployed AGENT.md files.'
    }

    # Idempotence / user-preservation: a re-run preserves a user-edited (non-managed) file.
    $firstWritten = [string]$written[0].Path
    [System.IO.File]::WriteAllText($firstWritten, "USER HAND-EDIT, no marker.`n", [System.Text.UTF8Encoding]::new($false))
    $rerun = Install-DevinCrewRuntime -ProjectPath $proj
    $preserved = @($rerun.Actions | Where-Object { $_.Action -eq 'preserved' -and ([string]$_.Path) -eq $firstWritten })
    if ($preserved.Count -lt 1) {
        Write-Fail "Install-DevinCrewRuntime overwrote a user-edited (non-managed) AGENT.md instead of preserving it: $firstWritten"
    }
    $afterBody = Get-Content -LiteralPath $firstWritten -Raw -Encoding UTF8
    if ($afterBody -notmatch 'USER HAND-EDIT') { Write-Fail "User-edited AGENT.md content was not preserved: $firstWritten" }
}
finally {
    if (Test-Path -LiteralPath $proj) { Remove-Item -Recurse -Force -LiteralPath $proj -ErrorAction SilentlyContinue }
}
Write-Pass 'Install-DevinCrewRuntime deploys nested .devin/agents/<role>/AGENT.md with Specrew-managed marker; detector agrees; user-edited files preserved'

# --- Test 10: Get-DevinSignals reads only Devin env vars and returns names that are set. ---
$backup = @{}
foreach ($v in 'DEVIN_PROJECT_DIR', 'DEVIN_SESSION_ID', 'DEVIN_CLI') { $backup[$v] = [Environment]::GetEnvironmentVariable($v) }
try {
    foreach ($v in 'DEVIN_PROJECT_DIR', 'DEVIN_SESSION_ID', 'DEVIN_CLI') { [Environment]::SetEnvironmentVariable($v, $null) }
    $none = @(Get-DevinSignals)
    if ($none.Count -ne 0) { Write-Fail "Get-DevinSignals should return no signals when no Devin env vars are set; got: $($none -join ',')" }
    [Environment]::SetEnvironmentVariable('DEVIN_SESSION_ID', 'abc123')
    $one = @(Get-DevinSignals)
    if ($one -notcontains 'DEVIN_SESSION_ID') { Write-Fail "Get-DevinSignals should report DEVIN_SESSION_ID when it is set; got: $($one -join ',')" }
}
finally {
    foreach ($v in 'DEVIN_PROJECT_DIR', 'DEVIN_SESSION_ID', 'DEVIN_CLI') { [Environment]::SetEnvironmentVariable($v, $backup[$v]) }
}
Write-Pass 'Get-DevinSignals reports the set Devin env vars (DEVIN_SESSION_ID) and nothing when none are set'

Write-Host ''
Write-Host 'Devin handler contract (T010): all assertions pass' -ForegroundColor Green
exit 0
