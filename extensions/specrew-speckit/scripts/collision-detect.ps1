# collision-detect.ps1
# Detects naming collisions between Specrew and other extensions

<#
.SYNOPSIS
    Detects extension collision risks in a Specrew project.

.DESCRIPTION
    Scans for naming collisions between Specrew and other installed extensions:
    - Hook names
    - Role names (MVP scope)
    - Command names (full detector - Iteration 3)
    - Artifact paths (full detector - Iteration 3)
    - Ceremony names (full detector - Iteration 3)
    
    MVP bootstrap checks hook and role collisions only (FR-002).
    Full collision detector deferred to Iteration 3 (FR-012).

.PARAMETER ProjectPath
    Path to the target project directory

.EXAMPLE
    .\collision-detect.ps1 -ProjectPath "C:\Projects\MyApp"
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$ProjectPath
)

Write-Host "collision-detect.ps1: Placeholder script" -ForegroundColor Yellow
Write-Host "MVP: Hook and role collision checks (FR-002) - Iteration 1" -ForegroundColor Yellow
Write-Host "Full detector deferred to Iteration 3 (FR-012)" -ForegroundColor Yellow
Write-Host "Target path: $ProjectPath"

# TODO: Implement collision detection
# MVP (Iteration 1):
#   - Check hook name collisions
#   - Check role name collisions
# Full detector (Iteration 3):
#   - Check command name collisions
#   - Check artifact path collisions
#   - Check ceremony name collisions

exit 0
