# FR-025 (iter-8 T049): intake-at-init guard.
# The interactivity guard in Invoke-SpecrewInitProfileCapture is LOAD-BEARING - a wrong guard would hang
# every scripted `specrew init` on Read-Host. This proves the SKIP paths never prompt and never write a
# profile, and the PRESERVE path is detected without clobbering - using the SPECREW_USER_PROFILE_PATH seam
# so the real ~/.specrew/user-profile.yml is never touched.
$ErrorActionPreference = 'Stop'

. (Resolve-Path "$PSScriptRoot/../../scripts/internal/user-profile.ps1").Path

function Assert-True {
    param([bool]$Condition, [string]$Message)
    if (-not $Condition) { throw "FAIL: $Message" }
    Write-Host "PASS: $Message" -ForegroundColor Green
}

$tmp = Join-Path ([System.IO.Path]::GetTempPath()) ("specrew-profilecap-" + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $tmp | Out-Null
$seam = Join-Path $tmp 'user-profile.yml'   # absent to start
try {
    $env:SPECREW_USER_PROFILE_PATH = $seam

    # 1. absent + -Force -> skipped, no prompt, no profile written
    $r1 = Invoke-SpecrewInitProfileCapture -Force
    Assert-True ($r1 -eq 'skipped') 'absent + -Force -> skipped (never prompts)'
    Assert-True (-not (Test-Path -LiteralPath $seam)) 'skip path writes no profile'

    # 2. absent + non-interactive -> skipped (the load-bearing automation guard)
    $r2 = Invoke-SpecrewInitProfileCapture -ForceNonInteractive
    Assert-True ($r2 -eq 'skipped') 'absent + non-interactive -> skipped (no Read-Host hang in automation)'
    Assert-True (-not (Test-Path -LiteralPath $seam)) 'skip path still writes no profile'

    # 3. profile EXISTS -> preserved (never prompts, never clobbers)
    Save-UserProfile -ExpertiseDials @{ 'architect' = '8'; 'ux-ui-specialist' = 'auto'; 'product-manager' = 'auto'; 'ai-researcher-project-manager' = 'auto' } -ProfilePath $seam
    Assert-True (Test-UserProfileExists) 'seam profile now exists'
    $r3 = Invoke-SpecrewInitProfileCapture -Force
    Assert-True ($r3 -eq 'preserved') 'existing profile -> preserved (no prompt, no clobber)'
    $after = Get-UserProfile
    Assert-True ($after.expertise.software_architecture -eq 8) 'preserve path leaves the existing dials intact'
}
finally {
    Remove-Item Env:\SPECREW_USER_PROFILE_PATH -ErrorAction SilentlyContinue
    Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue
}
Write-Host 'UserProfileInitCapture: all tests passed.' -ForegroundColor Green
