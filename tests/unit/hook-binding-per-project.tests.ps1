# Feature 203 T002, review round 4 finding 1: an encoded launcher command keeps the binding its own project was
# deployed with. Since 0999ff62 (DRIFT-016) the Antigravity command leaves the baked binding out and the per-machine
# launcher read it from ~/.specrew/hook-bindings/<host>.binding, one file per machine: deploying project B from another
# engine changed project A's typed-approval and stop rules without touching A. The binding file is now named by its
# content id, written once, and the command names that id.
#
# Two projects share one home. A is deployed from this repository; B from an engine copy whose Antigravity binding
# also lists PreInvocation as decision-only. With the hooks switched off, the launcher prints the decision no-op ({})
# only when the binding it loaded lists the event, so each command's output shows which binding it read.
#
# Mutation that turns this file red: read hook-bindings/<host>.binding again, drop -BindingId from the encoded
# command, or skip the launcher's content check.
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$script:failCount = 0
function Write-Pass { param([string]$Message) Write-Host "PASS: $Message" -ForegroundColor Green }
function Write-Fail { param([string]$Message) Write-Host "FAIL: $Message" -ForegroundColor Red; $script:failCount++ }
function Assert-True { param([bool]$Condition, [string]$Message) if ($Condition) { Write-Pass $Message } else { Write-Fail $Message } }

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
$work = Join-Path ([IO.Path]::GetTempPath()) ('hook-binding-' + [guid]::NewGuid().ToString('N').Substring(0, 8))
$fakeHome = Join-Path $work 'home'
$bindingDir = Join-Path $fakeHome '.specrew/hook-bindings'

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
    # Deploys Antigravity's hooks into a project and returns its PreInvocation and Stop commands, decoded and raw.
    param([string]$Deployer, [string]$Project)
    New-Item -ItemType Directory -Path (Join-Path $Project '.specrew') -Force | Out-Null
    & pwsh -NoProfile -File $Deployer -ProjectPath $Project -HostKind antigravity -UserHomeOverride $fakeHome *> $null
    $commands = @{}
    foreach ($file in @(Get-ChildItem -LiteralPath $Project -Recurse -File -Force -Include *.json | Where-Object { $_.FullName -notmatch '[\\/]\.specrew[\\/]' })) {
        foreach ($command in @(Get-CommandStrings -Node (Get-Content -LiteralPath $file.FullName -Raw | ConvertFrom-Json))) {
            if ($command -notmatch '-EncodedCommand\s+(\S+)') { continue }
            $decoded = [Text.Encoding]::Unicode.GetString([Convert]::FromBase64String($Matches[1]))
            if ($decoded -match "-Event '(\w+)'") { $commands[$Matches[1]] = [pscustomobject]@{ Encoded = $command -replace '.*-EncodedCommand\s+(\S+).*', '$1'; Decoded = $decoded } }
        }
    }
    return $commands
}

function Invoke-Switched-Off {
    # Runs an encoded command with the hooks switched off; the output is the launcher's decision no-op, or nothing.
    param([string]$Encoded)
    $psi = [Diagnostics.ProcessStartInfo]::new('pwsh')
    foreach ($a in @('-NoProfile', '-NonInteractive', '-EncodedCommand', $Encoded)) { $psi.ArgumentList.Add($a) }
    $psi.WorkingDirectory = $work
    $psi.UseShellExecute = $false; $psi.RedirectStandardOutput = $true; $psi.RedirectStandardError = $true; $psi.RedirectStandardInput = $true
    foreach ($pair in @{ USERPROFILE = $fakeHome; HOME = $fakeHome; SPECREW_REFOCUS_DISABLE = '1'; SPECREW_MODULE_PATH = '' }.GetEnumerator()) { $psi.Environment[$pair.Key] = $pair.Value }
    $p = [Diagnostics.Process]::Start($psi)
    $p.StandardInput.Close()
    $out = $p.StandardOutput.ReadToEndAsync(); $null = $p.StandardError.ReadToEndAsync()
    if (-not $p.WaitForExit(60000)) { $p.Kill(); return 'timeout' }
    return $out.Result.Trim()
}

function Get-BindingId { param([string]$Decoded) if ($Decoded -match '-BindingId ([0-9a-f]{32})') { return $Matches[1] } return '' }

try {
    New-Item -ItemType Directory -Path $fakeHome -Force | Out-Null

    # Engine B: this repository's engine with one change to Antigravity's binding.
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

    $deployerA = Join-Path $repoRoot 'extensions/specrew-speckit/scripts/deploy-refocus-hooks.ps1'
    $deployerB = Join-Path $engineB 'extensions/specrew-speckit/scripts/deploy-refocus-hooks.ps1'
    $projectA = Join-Path $work 'project-a'; $projectB = Join-Path $work 'project-b'
    New-Item -ItemType Directory -Path (Join-Path $projectA '.specrew'), (Join-Path $projectB '.specrew') -Force | Out-Null

    # A machine upgraded from 0999ff62..7abcd180 still holds the shared per-host file; it must not be read.
    New-Item -ItemType Directory -Path $bindingDir -Force | Out-Null
    $bindingB = (& pwsh -NoProfile -File $deployerB -ProjectPath $projectB -HostKind antigravity -EmitBindingOnly | Select-Object -Last 1).Trim()
    Set-Content -LiteralPath (Join-Path $bindingDir 'antigravity.binding') -Value $bindingB -NoNewline

    $a = Deploy-Project -Deployer $deployerA -Project $projectA
    Assert-True (-not (Test-Path -LiteralPath (Join-Path $bindingDir 'antigravity.binding'))) 'deploy removes the shared per-host binding file the old launcher read'
    $b = Deploy-Project -Deployer $deployerB -Project $projectB
    $idA = Get-BindingId -Decoded $a['PreInvocation'].Decoded; $idB = Get-BindingId -Decoded $b['PreInvocation'].Decoded
    Assert-True ($idA -ne '' -and $idB -ne '' -and $idA -ne $idB) ("each project's command names its own binding id (A {0}, B {1})" -f $idA, $idB)
    Assert-True ((Get-BindingId -Decoded $a['Stop'].Decoded) -eq $idA) "every event of one project names the same binding id"
    $bindingA = (& pwsh -NoProfile -File $deployerA -ProjectPath $projectA -HostKind antigravity -EmitBindingOnly | Select-Object -Last 1).Trim()
    $fileA = Join-Path $bindingDir ("antigravity-{0}.binding" -f $idA); $fileB = Join-Path $bindingDir ("antigravity-{0}.binding" -f $idB)
    Assert-True ((Test-Path -LiteralPath $fileA) -and ([IO.File]::ReadAllText($fileA) -eq $bindingA)) "A's binding file holds A's binding after B's deploy"
    Assert-True ((Test-Path -LiteralPath $fileB) -and ([IO.File]::ReadAllText($fileB) -eq $bindingB)) "B's binding file holds B's binding"

    # Which binding each command's launcher loaded.
    Assert-True ((Invoke-Switched-Off -Encoded $a['PreInvocation'].Encoded) -eq '') "A's PreInvocation follows A's binding after B's deploy (no decision no-op)"
    Assert-True ((Invoke-Switched-Off -Encoded $b['PreInvocation'].Encoded) -eq '{}') "B's PreInvocation follows B's binding (decision no-op)"
    Assert-True ((Invoke-Switched-Off -Encoded $a['Stop'].Encoded) -eq '{}') "A's Stop answers with its binding's decision no-op"

    # Redeploying A after B changes neither file nor B's command.
    $bBefore = [IO.File]::ReadAllText($fileB)
    $a2 = Deploy-Project -Deployer $deployerA -Project $projectA
    Assert-True ((Get-BindingId -Decoded $a2['PreInvocation'].Decoded) -eq $idA -and [IO.File]::ReadAllText($fileB) -eq $bBefore) 'redeploying A leaves its id and B''s binding file unchanged'
    Assert-True ((Invoke-Switched-Off -Encoded $b['PreInvocation'].Encoded) -eq '{}') "B's PreInvocation still follows B's binding after A's redeploy"

    # A binding file whose content no longer matches its id is not used.
    Set-Content -LiteralPath $fileA -Value $bindingB -NoNewline
    Assert-True ((Invoke-Switched-Off -Encoded $a['Stop'].Encoded) -eq '') "a binding file changed after deploy is ignored (A's Stop gets no binding, so no decision no-op)"
}
finally {
    Remove-Item -LiteralPath $work -Recurse -Force -ErrorAction SilentlyContinue
}

if ($script:failCount -gt 0) { Write-Host "$script:failCount failure(s)" -ForegroundColor Red; exit 1 }
Write-Host 'All per-project hook binding checks passed.' -ForegroundColor Green
exit 0
