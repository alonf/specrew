# Every Squad install Specrew runs or prints names the paired SDK beside the CLI.
#
# squad-cli 0.11.0 declares "@bradygaster/squad-sdk": "*". squad-sdk 2.0.0 (2026-11-19) dropped exports the 0.11.0
# CLI imports, so an install of the CLI alone gives a `squad` that fails at start. Before this fix, init's install
# (scripts/init/dependency-install.ps1), update's install (scripts/specrew-update.ps1) and the install and repair text
# validate-versions.ps1 prints all named the CLI alone.
#
# No home writes: this suite runs no npm, no specrew command, no init and no update. specrew-update.ps1 is never run
# or dot-sourced; its functions are lifted out of the file by the parser. npm is a fake function that records its
# arguments. validate-versions.ps1 is given every version it would otherwise probe. The only files written are inside
# a temp folder this suite creates and removes by its exact path.

$ErrorActionPreference = 'Stop'
$script:Failures = 0
function Assert-True { param([bool]$Condition, [string]$Message) if ($Condition) { Write-Host ('  PASS: ' + $Message) } else { Write-Host ('  FAIL: ' + $Message); $script:Failures++ } }

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$helperPath = Join-Path $repoRoot 'scripts/internal/squad-install.ps1'
$supportedPath = Join-Path $repoRoot 'scripts/internal/supported-versions.yml'
$dependencyInstallPath = Join-Path $repoRoot 'scripts/init/dependency-install.ps1'
$updatePath = Join-Path $repoRoot 'scripts/specrew-update.ps1'
$initPath = Join-Path $repoRoot 'scripts/specrew-init.ps1'
$validatePath = Join-Path $repoRoot 'extensions/specrew-speckit/scripts/validate-versions.ps1'
$deployedValidatePath = Join-Path $repoRoot '.specify/extensions/specrew-speckit/scripts/validate-versions.ps1'

function Get-SupportedSquadKey {
    # Independent of the helper: the squad section's key, read straight from the file.
    param([string]$Key)
    $inSquad = $false
    foreach ($line in (Get-Content -LiteralPath $supportedPath -Encoding UTF8)) {
        if ($line -match '^(?<section>[A-Za-z_][A-Za-z0-9_]*):') { $inSquad = ($Matches['section'] -ceq 'squad'); continue }
        if ($inSquad -and $line -match ('^\s+{0}:\s*"?(?<value>[^"#\r\n]*?)"?\s*(?:#.*)?$' -f [regex]::Escape($Key))) { return $Matches['value'].Trim() }
    }
    return $null
}

function Import-ScriptFunction {
    # Lift named functions out of a script by the parser and define them here, without running the script.
    param([string]$Path, [string[]]$Name)
    $tokens = $null; $errors = $null
    $ast = [System.Management.Automation.Language.Parser]::ParseFile($Path, [ref]$tokens, [ref]$errors)
    $found = @($ast.FindAll({ param($node) $node -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $Name -contains $node.Name }, $true))
    foreach ($definition in $found) { Set-Item -Path ("function:global:{0}" -f $definition.Name) -Value $definition.Body.GetScriptBlock() }
    return @($found | ForEach-Object Name)
}

$global:SquadPairNpmCalls = [System.Collections.Generic.List[object]]::new()
function global:npm { $global:SquadPairNpmCalls.Add(@($args)); $global:LASTEXITCODE = 0 }
function global:Get-NativeExitCode { if ($null -eq $global:LASTEXITCODE) { 0 } else { [int]$global:LASTEXITCODE } }

$temp = Join-Path ([IO.Path]::GetTempPath()) ('squad-pair-' + [guid]::NewGuid().ToString('N').Substring(0, 8))
New-Item -ItemType Directory -Path $temp | Out-Null

Write-Host 'squad-install-pair'
try {
    $maxTested = Get-SupportedSquadKey -Key 'max_tested'
    $sdk = Get-SupportedSquadKey -Key 'sdk'
    $other = '0.12.0'

    Write-Host '  --- case 1: one source - supported-versions.yml declares the paired SDK beside the CLI it was tested with ---'
    Assert-True (-not [string]::IsNullOrWhiteSpace($sdk)) ('squad.sdk is declared (found: {0})' -f $sdk)
    Assert-True ($maxTested -ne $other) ('the "other version" this suite uses ({0}) is not max_tested ({1})' -f $other, $maxTested)
    $squadBlock = ((Get-Content -LiteralPath $supportedPath -Raw -Encoding UTF8) -split '(?m)^squad:')[-1]
    Assert-True ($squadBlock -match '(?i)remove' -and $squadBlock -match '2\.0\.0') 'the squad block''s comment says why (2.0.0) and when to remove the key'

    Write-Host '  --- case 2: the helper builds the pair for max_tested and the CLI alone for any other version ---'
    $helperLoaded = Test-Path -LiteralPath $helperPath -PathType Leaf
    Assert-True $helperLoaded 'scripts/internal/squad-install.ps1 exists'
    if ($helperLoaded) {
        . $helperPath
        $pin = Get-SquadSdkPin
        Assert-True ($null -ne $pin -and $pin.CliVersion -eq $maxTested -and $pin.SdkVersion -eq $sdk) ('Get-SquadSdkPin reads squad-cli {0} with squad-sdk {1}' -f $maxTested, $sdk)
        Assert-True ((Get-SquadSdkVersionFor -CliVersion $maxTested) -eq $sdk) 'the SDK is named for max_tested'
        Assert-True ($null -eq (Get-SquadSdkVersionFor -CliVersion $other)) ('no SDK is named for {0}' -f $other)
        $pairArgs = @(Get-SquadInstallArguments -CliVersion $maxTested -SdkVersion $sdk)
        Assert-True (($pairArgs -join ' ') -ceq ('install -g @bradygaster/squad-cli@{0} @bradygaster/squad-sdk@{1}' -f $maxTested, $sdk)) ('the arguments name both packages: {0}' -f ($pairArgs -join ' '))
        $aloneArgs = @(Get-SquadInstallArguments -CliVersion $other -SdkVersion $null)
        Assert-True (($aloneArgs -join ' ') -ceq ('install -g @bradygaster/squad-cli@{0}' -f $other)) 'and only the CLI without an SDK'
        Assert-True ((Get-SquadInstallCommandText -CliVersion $maxTested -SdkVersion $sdk) -ceq ('npm install -g "@bradygaster/squad-cli@{0}" "@bradygaster/squad-sdk@{1}"' -f $maxTested, $sdk)) 'the command text names both packages'
        $noSdk = Join-Path $temp 'no-sdk.yml'
        [IO.File]::WriteAllText($noSdk, "schema: v1`nsquad:`n  min: `"0.11.0`"`n  max_tested: `"0.11.0`"`n", [Text.UTF8Encoding]::new($false))
        Assert-True ($null -eq (Get-SquadSdkPin -Path $noSdk) -and $null -eq (Get-SquadSdkVersionFor -CliVersion '0.11.0' -Path $noSdk)) 'a declaration without squad.sdk names no SDK'
    }

    Write-Host '  --- case 3: init - Install-MissingDependency installs and previews the pair ---'
    . $dependencyInstallPath
    $global:SquadPairNpmCalls.Clear()
    $global:LASTEXITCODE = 0
    try { Install-MissingDependency -Dependency ([pscustomobject]@{ Platform = 'Squad'; MinimumVersion = $maxTested }) -PreviewOnly:$false } catch { Write-Host ('  (init install threw: {0})' -f $_.Exception.Message) }
    $initCall = if ($global:SquadPairNpmCalls.Count -eq 1) { $global:SquadPairNpmCalls[0] -join ' ' } else { '<{0} npm calls>' -f $global:SquadPairNpmCalls.Count }
    Assert-True ($initCall -ceq ('install -g @bradygaster/squad-cli@{0} @bradygaster/squad-sdk@{1}' -f $maxTested, $sdk)) ('init runs: npm {0}' -f $initCall)
    $preview = @(try { Install-MissingDependency -Dependency ([pscustomobject]@{ Platform = 'Squad'; MinimumVersion = $maxTested }) -PreviewOnly 6>&1 } catch { $_.Exception.Message }) -join ' '
    Assert-True ($preview -match [regex]::Escape(('@bradygaster/squad-sdk@{0}' -f $sdk))) ('init''s dry-run line names the SDK: {0}' -f $preview)
    Assert-True ((Get-Content -LiteralPath $initPath -Raw) -match '(?m)^\s*\.\s+.*squad-install\.ps1' -or (Get-Content -LiteralPath $initPath -Raw) -match 'squad-install\.ps1') 'specrew-init.ps1 loads the helper'

    Write-Host '  --- case 4: update - Install-PlatformVersion installs the pair (lifted from the script, never run) ---'
    $lifted = @(Import-ScriptFunction -Path $updatePath -Name @('Install-PlatformVersion', 'Get-VersionValidationResults'))
    Assert-True ($lifted.Count -eq 2) ('both functions found in specrew-update.ps1 ({0})' -f ($lifted -join ', '))
    $global:SquadPairNpmCalls.Clear()
    try { Install-PlatformVersion -Platform 'Squad' -Version $maxTested } catch { Write-Host ('  (update install threw: {0})' -f $_.Exception.Message) }
    $updateCall = if ($global:SquadPairNpmCalls.Count -eq 1) { $global:SquadPairNpmCalls[0] -join ' ' } else { '<{0} npm calls>' -f $global:SquadPairNpmCalls.Count }
    Assert-True ($updateCall -ceq ('install -g @bradygaster/squad-cli@{0} @bradygaster/squad-sdk@{1}' -f $maxTested, $sdk)) ('update runs: npm {0}' -f $updateCall)
    $global:SquadPairNpmCalls.Clear()
    try { Install-PlatformVersion -Platform 'Squad' -Version $other } catch { Write-Host ('  (update install threw: {0})' -f $_.Exception.Message) }
    $otherCall = if ($global:SquadPairNpmCalls.Count -eq 1) { $global:SquadPairNpmCalls[0] -join ' ' } else { '<{0} npm calls>' -f $global:SquadPairNpmCalls.Count }
    Assert-True ($otherCall -ceq ('install -g @bradygaster/squad-cli@{0}' -f $other)) ('a CLI version other than max_tested installs alone: npm {0}' -f $otherCall)
    Assert-True ((Get-Content -LiteralPath $updatePath -Raw) -match 'squad-install\.ps1') 'specrew-update.ps1 loads the helper'

    Write-Host '  --- case 5: every module caller of validate-versions.ps1 that prints its text passes the SDK ---'
    $recorder = Join-Path $temp 'record-validate.ps1'
    [IO.File]::WriteAllText($recorder, "param([string]`$MinimumSpecKitVersion, [string]`$MinimumSquadVersion, [string]`$SquadSdkVersion, [switch]`$PassThru)`n[pscustomobject]@{ Squad = `$MinimumSquadVersion; Sdk = `$SquadSdkVersion }`n", [Text.UTF8Encoding]::new($false))
    $initSeen = @(Invoke-VersionValidation -ScriptPath $recorder -MinimumSpecKitVersion '0.12.9' -MinimumSquadVersion $maxTested)
    Assert-True ($initSeen.Count -eq 1 -and $initSeen[0].Sdk -eq $sdk) ('init''s Invoke-VersionValidation passes -SquadSdkVersion {0} (passed: "{1}")' -f $sdk, $(if ($initSeen.Count) { $initSeen[0].Sdk }))
    $updateSeen = @(Get-VersionValidationResults -ValidateScriptPath $recorder -MinimumSpecKitVersion '0.12.9' -MinimumSquadVersion $maxTested)
    Assert-True ($updateSeen.Count -eq 1 -and $updateSeen[0].Sdk -eq $sdk) ('update''s Get-VersionValidationResults passes -SquadSdkVersion {0} (passed: "{1}")' -f $sdk, $(if ($updateSeen.Count) { $updateSeen[0].Sdk }))
    # Text guard: any other product file that calls the validator with -MinimumSquadVersion must pass the SDK too.
    # test-publish-harness.ps1 is the one exemption: it reads IsOperational and Version and never prints the text.
    $exempt = @('scripts/internal/test-publish-harness.ps1')
    $callers = foreach ($file in @(Get-ChildItem -LiteralPath (Join-Path $repoRoot 'scripts'), (Join-Path $repoRoot 'extensions'), (Join-Path $repoRoot 'hosts') -Recurse -File -Filter '*.ps1' -ErrorAction SilentlyContinue)) {
        $relative = ([IO.Path]::GetRelativePath($repoRoot, $file.FullName)) -replace '\\', '/'
        $text = Get-Content -LiteralPath $file.FullName -Raw
        foreach ($m in [regex]::Matches($text, '&\s*\$\w+\s*`?\s*-MinimumSpecKitVersion[\s\S]{0,400}?-PassThru')) {
            [pscustomobject]@{ File = $relative; PassesSdk = ($m.Value -match '-SquadSdkVersion') }
        }
    }
    $missing = @($callers | Where-Object { -not $_.PassesSdk -and $exempt -notcontains $_.File } | ForEach-Object File | Sort-Object -Unique)
    Assert-True ($missing.Count -eq 0) ('every validate-versions.ps1 call passes -SquadSdkVersion (calls found: {0}; missing in: {1})' -f @($callers).Count, $(if ($missing.Count) { $missing -join ', ' } else { 'none' }))

    Write-Host '  --- case 6: validate-versions.ps1 prints the same pair the helper builds ---'
    $withSdk = @(try { & $validatePath -SpecKitVersion '0.12.9' -SquadVersion $maxTested -MinimumSpecKitVersion '0.12.9' -MinimumSquadVersion $maxTested -SquadSdkVersion $sdk -PassThru 2>$null | Where-Object { $_.Platform -eq 'Squad' } } catch { Write-Host ('  (validate-versions threw: {0})' -f $_.Exception.Message) })
    $expectedText = 'npm install -g "@bradygaster/squad-cli@{0}" "@bradygaster/squad-sdk@{1}"' -f $maxTested, $sdk
    Assert-True ($withSdk.Count -eq 1 -and $withSdk[0].SuggestedInstall -ceq $expectedText -and $withSdk[0].SuggestedRepair -ceq $expectedText) ('install and repair text: {0}' -f $(if ($withSdk.Count) { $withSdk[0].SuggestedRepair }))
    if ($helperLoaded) { Assert-True ($expectedText -ceq (Get-SquadInstallCommandText -CliVersion $maxTested -SdkVersion $sdk)) 'the validator''s text equals the helper''s' }
    $noSdkResult = @(try { & $validatePath -SpecKitVersion '0.12.9' -SquadVersion $maxTested -MinimumSpecKitVersion '0.12.9' -MinimumSquadVersion $maxTested -PassThru 2>$null | Where-Object { $_.Platform -eq 'Squad' } } catch { Write-Host ('  (validate-versions threw: {0})' -f $_.Exception.Message) })
    Assert-True ($noSdkResult.Count -eq 1 -and $noSdkResult[0].SuggestedRepair -ceq ('npm install -g "@bradygaster/squad-cli@{0}"' -f $maxTested)) 'without -SquadSdkVersion it prints the CLI alone, as before'

    Write-Host '  --- case 7: the deployed copy is the module''s, and its hash record matches (the product''s own integrity check) ---'
    $normal = { param($p) [Text.Encoding]::UTF8.GetString([IO.File]::ReadAllBytes($p)).Replace("`r`n", "`n") }
    Assert-True ((& $normal $validatePath) -ceq (& $normal $deployedValidatePath)) '.specify copy of validate-versions.ps1 equals extensions/ (line endings normalised)'
    . (Join-Path $repoRoot 'extensions/specrew-speckit/scripts/shared-governance.ps1')
    $integrity = Test-SpecrewDeployedExtensionIntegrity -ProjectRoot $repoRoot
    Assert-True ($integrity.checked -and @($integrity.drifted).Count -eq 0 -and @($integrity.missing).Count -eq 0) ('Test-SpecrewDeployedExtensionIntegrity: 0 drifted, 0 missing (drifted: {0})' -f (@($integrity.drifted) -join ', '))

    Write-Host '  --- case 8: no other product file builds a Squad install ---'
    $allowed = @('scripts/internal/squad-install.ps1', 'extensions/specrew-speckit/scripts/validate-versions.ps1', '.specify/extensions/specrew-speckit/scripts/validate-versions.ps1')
    $roots = @('scripts', 'extensions', 'hosts', '.specify/extensions') | ForEach-Object { Join-Path $repoRoot $_ } | Where-Object { Test-Path -LiteralPath $_ }
    $builders = @(foreach ($file in @(Get-ChildItem -LiteralPath $roots -Recurse -File -Include '*.ps1', '*.psm1', '*.sh' -ErrorAction SilentlyContinue)) {
            $relative = ([IO.Path]::GetRelativePath($repoRoot, $file.FullName)) -replace '\\', '/'
            if ($allowed -contains $relative) { continue }
            if ((Get-Content -LiteralPath $file.FullName -Raw) -match '@bradygaster/squad-cli@') { $relative }
        })
    Assert-True ($builders.Count -eq 0) ('"@bradygaster/squad-cli@" appears only in the helper and validate-versions.ps1 (also in: {0})' -f $(if ($builders.Count) { $builders -join ', ' } else { 'none' }))

    Write-Host '  --- case 9: the workflows pin the same pair as supported-versions.yml ---'
    foreach ($workflow in @('specrew-ci.yml', 'specrew-confidence-lane.yml', 'publish-module.yml', 'cross-platform-validation.yml')) {
        $text = Get-Content -LiteralPath (Join-Path $repoRoot ".github/workflows/$workflow") -Raw
        $cli = if ($text -match "(?m)^\s*SQUAD_VERSION:\s*'(?<v>[^']+)'") { $Matches['v'] } else { $null }
        $wsdk = if ($text -match "(?m)^\s*SQUAD_SDK_VERSION:\s*'(?<v>[^']+)'") { $Matches['v'] } else { $null }
        Assert-True ($cli -eq $maxTested -and $wsdk -eq $sdk) ('{0}: SQUAD_VERSION {1} = max_tested {2}, SQUAD_SDK_VERSION {3} = squad.sdk {4}' -f $workflow, $cli, $maxTested, $wsdk, $sdk)
    }

    Write-Host '  --- case 10: Cross-Platform Validation proves init''s own Squad install again ---'
    $cpv = Get-Content -LiteralPath (Join-Path $repoRoot '.github/workflows/cross-platform-validation.yml') -Raw
    $jobs = ($cpv -split '(?m)^jobs:\s*$', 2)[-1]
    $ubuntu = ($jobs -split '(?m)^  [a-z0-9-]+:\s*$')[1]
    Assert-True ($ubuntu -match 'name:\s*Ubuntu Validation') 'the first job is Ubuntu Validation'
    Assert-True ($ubuntu -notmatch 'name:\s*Install squad CLI' -and $ubuntu -notmatch 'own Squad install is bypassed') 'Ubuntu Validation no longer pre-installs Squad or prints the bypass warning'
    $initAt = $ubuntu.IndexOf('name: Test specrew init')
    $healthAt = $ubuntu.IndexOf('name: Check squad CLI health')
    Assert-True ($initAt -ge 0 -and $healthAt -gt $initAt) 'its squad health check runs after "Test specrew init"'

    # Update repair (the maintainer, 2026-11-23 02:32: "squad install fix: include the update repair"). Measured in a
    # sandbox before the fix: a broken 0.11.0 pair probes as installed, not operational, with version 24.15.0 (the
    # Node line of the crash output), so update read "ahead-of-supported" and ran nothing. With the project's recorded
    # squad_version as the fallback it reads "current" and runs nothing either.
    Write-Host '  --- case 11: update decides to repair a Squad that is installed but not working, and only that ---'
    $broken = [pscustomobject]@{ Platform = 'Squad'; IsInstalled = $true; IsOperational = $false; Version = '24.15.0'; ProbeError = 'file:///x/squad-cli/dist/cli/core/init.js:13' }
    $healthy = [pscustomobject]@{ Platform = 'Squad'; IsInstalled = $true; IsOperational = $true; Version = $maxTested; ProbeError = $null }
    $absent = [pscustomobject]@{ Platform = 'Squad'; IsInstalled = $false; IsOperational = $false; Version = $null; ProbeError = $null }
    $brokenKit = [pscustomobject]@{ Platform = 'Spec Kit'; IsInstalled = $true; IsOperational = $false; Version = $null; ProbeError = 'boom' }
    $repairLifted = @(Import-ScriptFunction -Path $updatePath -Name @('Test-SquadNeedsRepair'))
    Assert-True ($repairLifted.Count -eq 1) 'Test-SquadNeedsRepair is in specrew-update.ps1'
    if ($repairLifted.Count -eq 1) {
        Assert-True (Test-SquadNeedsRepair -Platform 'Squad' -Validation $broken) 'installed and not operational: repair'
        Assert-True (-not (Test-SquadNeedsRepair -Platform 'Squad' -Validation $healthy)) 'healthy: no repair'
        Assert-True (-not (Test-SquadNeedsRepair -Platform 'Squad' -Validation $absent)) 'not installed: no repair (the install path stays as it is)'
        Assert-True (-not (Test-SquadNeedsRepair -Platform 'Spec Kit' -Validation $brokenKit)) 'Spec Kit: never'
        Assert-True (-not (Test-SquadNeedsRepair -Platform 'Squad' -Validation $null)) 'no validation result: no repair'
    }

    Write-Host '  --- case 12: update''s install loop, lifted and run with a recording install ---'
    $tokens = $null; $errors = $null
    $updateAst = [System.Management.Automation.Language.Parser]::ParseFile($updatePath, [ref]$tokens, [ref]$errors)
    $loop = @($updateAst.EndBlock.Statements | Where-Object { $_ -is [System.Management.Automation.Language.ForEachStatementAst] -and $_.Condition.Extent.Text -match "'Spec Kit', 'Squad'" -and $_.Body.Extent.Text -match 'Install-PlatformVersion' })
    Assert-True ($loop.Count -eq 1) 'the platform install loop is found'
    $global:SquadPairInstalls = [System.Collections.Generic.List[string]]::new()
    function global:Install-PlatformVersion { param([string]$Platform, [string]$Version) $global:SquadPairInstalls.Add(('{0} {1}' -f $Platform, $Version)) }
    $runLoop = {
        param([string]$Scope, [object]$Validation, [string]$Status)
        $global:SquadPairInstalls.Clear()
        $scopes = @($Scope)
        $latestByPlatform = @{ 'Spec Kit' = [pscustomobject]@{ Known = $false; Version = $null }; 'Squad' = [pscustomobject]@{ Known = $true; Version = $maxTested } }
        $specKitMaxTested = '0.12.9'; $squadMaxTested = $maxTested
        $specKitStatus = $Status; $squadStatus = $Status
        $UpstreamLatest = $false
        $validationByPlatform = @{ $Validation.Platform = $Validation }
        $summary = [System.Collections.ArrayList]::new()
        $installFailureMessage = $null
        $hostLines = @(. ([scriptblock]::Create($loop[0].Extent.Text)) 6>&1 | ForEach-Object { [string]$_ })
        [pscustomobject]@{ Installs = @($global:SquadPairInstalls); Summary = @($summary); Host = ($hostLines -join ' ') }
    }
    if ($loop.Count -eq 1) {
        $pairText = 'npm install -g "@bradygaster/squad-cli@{0}" "@bradygaster/squad-sdk@{1}"' -f $maxTested, $sdk
        foreach ($status in @('ahead-of-supported', 'current')) {
            $r = & $runLoop -Scope 'Squad' -Validation $broken -Status $status
            $row = @($r.Summary | Where-Object Platform -eq 'Squad')
            Assert-True ($r.Installs.Count -eq 1 -and $r.Installs[0] -eq ('Squad {0}' -f $maxTested)) ('broken Squad reading "{0}": reinstalled once at {1} (installs: {2})' -f $status, $maxTested, ($r.Installs -join '; '))
            Assert-True ($row.Count -eq 1 -and $row[0].Action -eq 'repaired' -and $row[0].Detail -match 'not working' -and $row[0].Detail.Contains($pairText)) ('the summary says repaired, why, and with what: {0} | {1}' -f $(if ($row.Count) { $row[0].Action }), $(if ($row.Count) { $row[0].Detail }))
            Assert-True ($r.Host -match "installed but the 'squad' command does not work" -and $r.Host.Contains('init.js:13') -and $r.Host.Contains($pairText)) ('and prints it as it happens: {0}' -f $r.Host)
            Assert-True (-not $r.Host.Contains('24.15.0') -and -not (@($r.Summary | ForEach-Object { [string]$_.Detail }) -join ' ').Contains('24.15.0')) 'the repaired path never reports the version read from the crash output (24.15.0)'
        }
        $r = & $runLoop -Scope 'Squad' -Validation $healthy -Status 'current'
        Assert-True ($r.Installs.Count -eq 0 -and @($r.Summary)[0].Action -eq 'already-current') 'healthy and current: unchanged (already-current, nothing installed)'
        $r = & $runLoop -Scope 'Squad' -Validation ([pscustomobject]@{ Platform = 'Squad'; IsInstalled = $true; IsOperational = $true; Version = '0.12.0'; ProbeError = $null }) -Status 'ahead-of-supported'
        Assert-True ($r.Installs.Count -eq 0 -and @($r.Summary)[0].Action -eq 'ahead-of-supported') 'healthy and ahead: unchanged (ahead-of-supported, nothing installed)'
        $r = & $runLoop -Scope 'Squad' -Validation $absent -Status 'not-installed'
        Assert-True ($r.Installs.Count -eq 1 -and @($r.Summary)[0].Action -eq 'upgraded' -and $r.Host -notmatch 'does not work') 'not installed: unchanged (installed, summary "upgraded", no repair message)'
        $r = & $runLoop -Scope 'Spec Kit' -Validation $brokenKit -Status 'current'
        Assert-True ($r.Installs.Count -eq 0 -and @($r.Summary)[0].Action -eq 'already-current') 'Spec Kit not operational: unchanged (already-current)'
    }
    Remove-Item -Path function:global:Install-PlatformVersion -ErrorAction SilentlyContinue
}
finally {
    if (Test-Path -LiteralPath $temp) { Remove-Item -LiteralPath $temp -Recurse -Force -ErrorAction SilentlyContinue }
    Remove-Item -Path function:global:npm, function:global:Get-NativeExitCode, function:global:Install-PlatformVersion, function:global:Get-VersionValidationResults -ErrorAction SilentlyContinue
}

if ($script:Failures -gt 0) { Write-Host ("squad-install-pair: {0} FAILED" -f $script:Failures); exit 1 }
Write-Host 'squad-install-pair: all cases passed'
exit 0
