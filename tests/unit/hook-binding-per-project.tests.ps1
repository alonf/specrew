# Feature 203 T002, review rounds 4 and 5: an encoded launcher command keeps the launcher and the binding its own
# project was deployed with. Since 0999ff62 (DRIFT-016) the Antigravity command left the baked binding out, and every
# launcher command ran ~/.specrew/specrew-hook-launch.ps1, one file per machine: deploying project B from another
# engine changed project A's typed-approval and stop rules (round 4, finding 1), and an older engine's launcher
# without -BindingId broke A's commands outright (round 5, finding 1). Launchers and bindings now live in one
# content-addressed store, ~/.specrew/hooks, each file named by its content id and written once; a command names
# the exact launcher and binding it needs.
#
# Two projects share one home, in both deploy orders. A is deployed from this repository; B from an engine copy with
# a different launcher implementation (its decision no-op prints {"engine":"b"}) and a different Antigravity binding
# (PreInvocation is decision-only too). With the hooks switched off, the launcher prints its decision no-op only when
# the binding it loaded lists the event, so each command's output shows which launcher ran and which binding it read.
#
# Mutation that turns this file red: run one launcher path for every command, read a per-host binding file, drop
# -BindingId from the encoded command, skip the launcher's content check, run on an unverified named binding instead of
# refusing, or delete the old shared binding file that commands from 0999ff62..7abcd180 still read (round 6).
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$script:failCount = 0
function Write-Pass { param([string]$Message) Write-Host "PASS: $Message" -ForegroundColor Green }
function Write-Fail { param([string]$Message) Write-Host "FAIL: $Message" -ForegroundColor Red; $script:failCount++ }
function Assert-True { param([bool]$Condition, [string]$Message) if ($Condition) { Write-Pass $Message } else { Write-Fail $Message } }

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
$work = Join-Path ([IO.Path]::GetTempPath()) ('hook-binding-' + [guid]::NewGuid().ToString('N').Substring(0, 8))

function Get-CommandStrings {
    param($Node)
    if ($null -eq $Node) { return }
    if ($Node -is [System.Collections.IList]) { foreach ($item in $Node) { Get-CommandStrings -Node $item }; return }
    if ($Node -is [pscustomobject]) {
        foreach ($property in $Node.PSObject.Properties) {
            if ($property.Name -in @('command', 'bash', 'powershell') -and $property.Value -is [string]) { $property.Value }
            else { Get-CommandStrings -Node $property.Value }
        }
    }
}

function Deploy-Project {
    # Deploys Antigravity's hooks into a project and returns its commands by event, encoded and decoded.
    param([string]$Deployer, [string]$Project, [string]$HomeDir)
    New-Item -ItemType Directory -Path (Join-Path $Project '.specrew') -Force | Out-Null
    & pwsh -NoProfile -File $Deployer -ProjectPath $Project -HostKind antigravity -UserHomeOverride $HomeDir *> $null
    $commands = @{}
    foreach ($file in @(Get-ChildItem -LiteralPath $Project -Recurse -File -Force -Include *.json | Where-Object { $_.FullName -notmatch '[\\/]\.specrew[\\/]' })) {
        foreach ($command in @(Get-CommandStrings -Node (Get-Content -LiteralPath $file.FullName -Raw | ConvertFrom-Json))) {
            if ($command -notmatch '-EncodedCommand\s+(\S+)') { continue }
            $encoded = $Matches[1]
            $decoded = [Text.Encoding]::Unicode.GetString([Convert]::FromBase64String($encoded))
            if ($decoded -match "-Event '(\w+)'") { $commands[$Matches[1]] = [pscustomobject]@{ Encoded = $encoded; Decoded = $decoded } }
        }
    }
    return $commands
}

function Invoke-Switched-Off {
    # Runs an encoded command with the hooks switched off; the output is the launcher's decision no-op, or nothing.
    param([string]$Encoded, [string]$HomeDir)
    $psi = [Diagnostics.ProcessStartInfo]::new('pwsh')
    foreach ($a in @('-NoProfile', '-NonInteractive', '-EncodedCommand', $Encoded)) { $psi.ArgumentList.Add($a) }
    $psi.WorkingDirectory = $work
    $psi.UseShellExecute = $false; $psi.RedirectStandardOutput = $true; $psi.RedirectStandardError = $true; $psi.RedirectStandardInput = $true
    foreach ($pair in @{ USERPROFILE = $HomeDir; HOME = $HomeDir; SPECREW_REFOCUS_DISABLE = '1'; SPECREW_MODULE_PATH = '' }.GetEnumerator()) { $psi.Environment[$pair.Key] = $pair.Value }
    $p = [Diagnostics.Process]::Start($psi)
    $p.StandardInput.Close()
    $out = $p.StandardOutput.ReadToEndAsync(); $err = $p.StandardError.ReadToEndAsync()
    if (-not $p.WaitForExit(60000)) { $p.Kill(); return 'timeout' }
    $text = $out.Result.Trim()
    if ($p.ExitCode -ne 0) { $text = 'exit ' + $p.ExitCode + ': ' + $err.Result.Trim() }
    return $text
}

function Invoke-Launcher {
    # Runs an encoded command with the hooks on, from a folder that holds no project.
    param([string]$Encoded, [string]$HomeDir)
    $psi = [Diagnostics.ProcessStartInfo]::new('pwsh')
    foreach ($a in @('-NoProfile', '-NonInteractive', '-EncodedCommand', $Encoded)) { $psi.ArgumentList.Add($a) }
    $psi.WorkingDirectory = $work
    $psi.UseShellExecute = $false; $psi.RedirectStandardOutput = $true; $psi.RedirectStandardError = $true; $psi.RedirectStandardInput = $true
    foreach ($pair in @{ USERPROFILE = $HomeDir; HOME = $HomeDir; SPECREW_MODULE_PATH = '' }.GetEnumerator()) { $psi.Environment[$pair.Key] = $pair.Value }
    [void]$psi.Environment.Remove('SPECREW_REFOCUS_DISABLE')
    $p = [Diagnostics.Process]::Start($psi)
    $p.StandardInput.Close()
    $out = $p.StandardOutput.ReadToEndAsync(); $err = $p.StandardError.ReadToEndAsync()
    if (-not $p.WaitForExit(60000)) { $p.Kill(); return [pscustomobject]@{ Exit = 'timeout'; Err = '' } }
    return [pscustomobject]@{ Exit = $p.ExitCode; Err = $err.Result }
}

function Get-NamedId { param([string]$Decoded, [string]$Pattern) if ($Decoded -match $Pattern) { return $Matches[1] } return '' }

try {
    # Engine B: this repository's engine with a different launcher implementation and a different binding.
    $engineB = Join-Path $work 'engine-b'
    foreach ($rel in @('extensions', 'hosts', 'scripts/internal')) {
        New-Item -ItemType Directory -Path (Split-Path -Parent (Join-Path $engineB $rel)) -Force | Out-Null
        Copy-Item -LiteralPath (Join-Path $repoRoot $rel) -Destination (Join-Path $engineB $rel) -Recurse -Force
    }
    $manifestB = Join-Path $engineB 'hosts/antigravity/host.psd1'
    $manifestText = Get-Content -LiteralPath $manifestB -Raw
    $changed = $manifestText.Replace("DecisionOnlyEvents      = @('Stop')", "DecisionOnlyEvents      = @('Stop', 'PreInvocation')")
    Assert-True ($changed -ne $manifestText) "engine B: Antigravity's binding also lists PreInvocation as decision-only"
    Set-Content -LiteralPath $manifestB -Value $changed -NoNewline
    $deployerB = Join-Path $engineB 'extensions/specrew-speckit/scripts/deploy-refocus-hooks.ps1'
    $deployerText = Get-Content -LiteralPath $deployerB -Raw
    $noop = "    if (Test-LauncherDecisionOnlyEvent -EventName `$EventName -EncodedBinding `$EncodedBinding) {"
    $deployerChanged = $deployerText.Replace("$noop`r`n        @{} | ConvertTo-Json -Compress", "$noop`r`n        @{ engine = 'b' } | ConvertTo-Json -Compress").Replace("$noop`n        @{} | ConvertTo-Json -Compress", "$noop`n        @{ engine = 'b' } | ConvertTo-Json -Compress")
    Assert-True ($deployerChanged -ne $deployerText) 'engine B: its launcher implementation differs (its decision no-op names engine b)'
    Set-Content -LiteralPath $deployerB -Value $deployerChanged -NoNewline
    $deployerA = Join-Path $repoRoot 'extensions/specrew-speckit/scripts/deploy-refocus-hooks.ps1'

    foreach ($order in @('A then B', 'B then A')) {
        $homeDir = Join-Path $work ($order -replace ' ', '-') ; $store = Join-Path $homeDir '.specrew/hooks'
        $projectA = Join-Path $homeDir 'project-a'; $projectB = Join-Path $homeDir 'project-b'
        New-Item -ItemType Directory -Path (Join-Path $projectA '.specrew'), (Join-Path $projectB '.specrew') -Force | Out-Null

        # A machine upgraded from 0999ff62..7abcd180 still holds the shared per-host binding file; it is not read.
        $bindingB = (& pwsh -NoProfile -File $deployerB -ProjectPath $projectB -HostKind antigravity -EmitBindingOnly | Select-Object -Last 1).Trim()
        $bindingA = (& pwsh -NoProfile -File $deployerA -ProjectPath $projectA -HostKind antigravity -EmitBindingOnly | Select-Object -Last 1).Trim()
        New-Item -ItemType Directory -Path (Join-Path $homeDir '.specrew/hook-bindings') -Force | Out-Null
        Set-Content -LiteralPath (Join-Path $homeDir '.specrew/hook-bindings/antigravity.binding') -Value $bindingB -NoNewline

        if ($order -eq 'A then B') { $a = Deploy-Project -Deployer $deployerA -Project $projectA -HomeDir $homeDir; $b = Deploy-Project -Deployer $deployerB -Project $projectB -HomeDir $homeDir }
        else { $b = Deploy-Project -Deployer $deployerB -Project $projectB -HomeDir $homeDir; $a = Deploy-Project -Deployer $deployerA -Project $projectA -HomeDir $homeDir }
        # Commands deployed from those commits still read it through the old shared launcher (round 6, finding 1).
        $legacyFile = Join-Path $homeDir '.specrew/hook-bindings/antigravity.binding'
        Assert-True ((Test-Path -LiteralPath $legacyFile) -and [IO.File]::ReadAllText($legacyFile) -eq $bindingB) "${order}: deploy leaves the old shared per-host binding file as it was"

        $launcherPattern = '\.specrew/hooks/([0-9a-f]{32})/specrew-hook-launch\.ps1'
        $launcherA = Get-NamedId -Decoded $a['PreInvocation'].Decoded -Pattern $launcherPattern; $launcherB = Get-NamedId -Decoded $b['PreInvocation'].Decoded -Pattern $launcherPattern
        $idA = Get-NamedId -Decoded $a['PreInvocation'].Decoded -Pattern '-BindingId ([0-9a-f]{32})'; $idB = Get-NamedId -Decoded $b['PreInvocation'].Decoded -Pattern '-BindingId ([0-9a-f]{32})'
        Assert-True ($launcherA -ne '' -and $launcherB -ne '' -and $launcherA -ne $launcherB) ("${order}: each project's command names its own launcher (A {0}, B {1})" -f $launcherA, $launcherB)
        Assert-True ($idA -ne '' -and $idB -ne '' -and $idA -ne $idB) ("${order}: each project's command names its own binding (A {0}, B {1})" -f $idA, $idB)
        Assert-True ((Get-NamedId -Decoded $a['Stop'].Decoded -Pattern $launcherPattern) -eq $launcherA -and (Get-NamedId -Decoded $a['Stop'].Decoded -Pattern '-BindingId ([0-9a-f]{32})') -eq $idA) "${order}: every event of one project names the same launcher and binding"
        $launcherFileA = Join-Path $store "$launcherA/specrew-hook-launch.ps1"; $launcherFileB = Join-Path $store "$launcherB/specrew-hook-launch.ps1"
        $fileA = Join-Path $store "bindings/antigravity-$idA.binding"; $fileB = Join-Path $store "bindings/antigravity-$idB.binding"
        Assert-True ((Test-Path -LiteralPath $launcherFileA) -and (Test-Path -LiteralPath $launcherFileB)) "${order}: both launchers are in the store"
        Assert-True ((Test-Path -LiteralPath $fileA) -and [IO.File]::ReadAllText($fileA) -eq $bindingA -and (Test-Path -LiteralPath $fileB) -and [IO.File]::ReadAllText($fileB) -eq $bindingB) "${order}: each binding file holds its own project's binding"
        Assert-True (-not (Test-Path -LiteralPath (Join-Path $homeDir '.specrew/specrew-hook-launch.ps1'))) "${order}: no shared launcher file is written"

        # Which launcher ran and which binding it read.
        Assert-True ((Invoke-Switched-Off -Encoded $a['PreInvocation'].Encoded -HomeDir $homeDir) -eq '') "${order}: A's PreInvocation follows A's binding (no decision no-op)"
        Assert-True ((Invoke-Switched-Off -Encoded $a['Stop'].Encoded -HomeDir $homeDir) -eq '{}') "${order}: A's Stop runs A's launcher with A's binding ({})"
        Assert-True ((Invoke-Switched-Off -Encoded $b['PreInvocation'].Encoded -HomeDir $homeDir) -eq '{"engine":"b"}') "${order}: B's PreInvocation runs B's launcher with B's binding"
        Assert-True ((Invoke-Switched-Off -Encoded $b['Stop'].Encoded -HomeDir $homeDir) -eq '{"engine":"b"}') "${order}: B's Stop runs B's launcher"

        # Redeploying the first project changes neither store file the other project uses.
        $before = @([IO.File]::ReadAllText($launcherFileA), [IO.File]::ReadAllText($launcherFileB), [IO.File]::ReadAllText($fileA), [IO.File]::ReadAllText($fileB))
        if ($order -eq 'A then B') { $null = Deploy-Project -Deployer $deployerA -Project $projectA -HomeDir $homeDir } else { $null = Deploy-Project -Deployer $deployerB -Project $projectB -HomeDir $homeDir }
        $after = @([IO.File]::ReadAllText($launcherFileA), [IO.File]::ReadAllText($launcherFileB), [IO.File]::ReadAllText($fileA), [IO.File]::ReadAllText($fileB))
        Assert-True (($before -join '|') -ceq ($after -join '|')) "${order}: redeploying the first project leaves every store file unchanged"
        Assert-True ((Invoke-Switched-Off -Encoded $b['PreInvocation'].Encoded -HomeDir $homeDir) -eq '{"engine":"b"}' -and (Invoke-Switched-Off -Encoded $a['PreInvocation'].Encoded -HomeDir $homeDir) -eq '') "${order}: after the redeploy each project still runs its own launcher and binding"

        # A named binding that cannot be verified is not used, and with the hooks on the launcher refuses rather than
        # run on whatever rules a manifest elsewhere holds (round 6, finding 2). The scratch cwd holds no project, so
        # the control (a verified binding) exits 0 without running anything.
        $control = Invoke-Launcher -Encoded $a['Stop'].Encoded -HomeDir $homeDir
        Assert-True ($control.Exit -eq 0 -and $control.Err -notmatch 'could not load') ("${order}: control, A's verified binding with the hooks on: exit 0 (exit {0})" -f $control.Exit)
        Set-Content -LiteralPath $fileA -Value $bindingB -NoNewline
        Assert-True ((Invoke-Switched-Off -Encoded $a['Stop'].Encoded -HomeDir $homeDir) -eq '') "${order}: a binding file changed after deploy is ignored (A's Stop gets no binding, so no decision no-op)"
        $changedRun = Invoke-Launcher -Encoded $a['Stop'].Encoded -HomeDir $homeDir
        Assert-True ($changedRun.Exit -eq 1 -and ($changedRun.Err -replace '\s+', ' ') -match 'could not load the host settings this hook was set up with' -and $changedRun.Err -notmatch '\x1b|Exception|Line \|') ("${order}: with the hooks on, a changed binding file refuses in plain text (exit {0})" -f $changedRun.Exit)
        Remove-Item -LiteralPath $fileA -Force
        $missingRun = Invoke-Launcher -Encoded $a['Stop'].Encoded -HomeDir $homeDir
        Assert-True ($missingRun.Exit -eq 1 -and ($missingRun.Err -replace '\s+', ' ') -match 'could not load the host settings this hook was set up with') ("${order}: with the hooks on, a missing binding file refuses (exit {0})" -f $missingRun.Exit)
    }
}
finally {
    Remove-Item -LiteralPath $work -Recurse -Force -ErrorAction SilentlyContinue
}

if ($script:failCount -gt 0) { Write-Host "$script:failCount failure(s)" -ForegroundColor Red; exit 1 }
Write-Host 'All per-project hook launcher and binding checks passed.' -ForegroundColor Green
exit 0
