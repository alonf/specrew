# Feature 203, B5F-039 and the B5F-042 follow-up (maintainer ruling 2026-11-11): A TEST THAT CAN WRITE HOME HOOK FILES
# GIVES ITSELF A PRIVATE HOME, AND RESTORES WHAT WAS THERE.
#
# The hook deployer (scripts/internal/deploy-refocus-hooks.ps1) writes the home named by -UserHomeOverride, else by
# SPECREW_USER_HOME_OVERRIDE, else [Environment]::GetFolderPath('UserProfile'), which ignores HOME and USERPROFILE on
# Windows. specrew init, specrew update and the hooks command reach it with no parameter, so the variable is the seam: a
# suite that runs them without it rewrites the real ~/.codex, ~/.cursor, ~/.copilot and ~/.specrew hook files, and on a
# shared runner it changes the home every other suite's review preflight checks.
#
# Enter-SpecrewPrivateTestHome makes a fresh folder under the system temp folder and points the variable at it, whatever
# the caller's environment held (a sweep's shared redirect included: private beats shared). Exit-SpecrewPrivateTestHome
# puts the caller's value back, or removes the variable when there was none, and deletes the folder. Call Exit from a
# finally block (a script) or an AfterAll (a Pester file), so it runs on success, failure and exit.
# tests/unit/test-home-isolation.Tests.ps1 holds every such test to it.

function Enter-SpecrewPrivateTestHome {
    [CmdletBinding()]
    param([string]$Label = 'test')
    $prior = [Environment]::GetEnvironmentVariable('SPECREW_USER_HOME_OVERRIDE')
    $safeLabel = ($Label -replace '[^A-Za-z0-9-]', '-')
    $path = [IO.Path]::GetFullPath((Join-Path ([IO.Path]::GetTempPath()) ('specrew-test-home-{0}-{1}' -f $safeLabel, [guid]::NewGuid().ToString('N').Substring(0, 12))))
    [void][IO.Directory]::CreateDirectory($path)
    $env:SPECREW_USER_HOME_OVERRIDE = $path
    return [pscustomobject]@{ Path = $path; Prior = $prior; HadPrior = ($null -ne $prior) }
}

function Exit-SpecrewPrivateTestHome {
    [CmdletBinding()]
    param([AllowNull()]$State)
    if ($null -eq $State) { return }
    if ([bool]$State.HadPrior) { $env:SPECREW_USER_HOME_OVERRIDE = [string]$State.Prior }
    else { Remove-Item Env:SPECREW_USER_HOME_OVERRIDE -ErrorAction SilentlyContinue }
    try { if ([IO.Directory]::Exists([string]$State.Path)) { [IO.Directory]::Delete([string]$State.Path, $true) } }
    catch { Write-Warning ("private test home not removed: {0}: {1}" -f $State.Path, $_.Exception.Message) }
}
