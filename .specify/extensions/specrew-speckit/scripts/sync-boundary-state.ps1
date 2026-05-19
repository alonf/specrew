[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$ProjectPath = '.',

    [Parameter(Mandatory = $true)]
    [ValidateSet('specify', 'clarify', 'plan', 'tasks', 'review-signoff', 'iteration-closeout', 'feature-closeout')]
    [string]$BoundaryType,

    [string]$FeatureRef,
    [string]$IterationNumber,
    [string]$TaskId,
    [string]$AuthCommitHash,
    [string]$IdentityFocusArea,
    [string]$IdentityActiveIssues,
    [string]$IdentityBody,
    [switch]$PassThru
)

$internalScriptPath = Join-Path (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)))) 'scripts\internal\sync-boundary-state.ps1'
if (-not (Test-Path -LiteralPath $internalScriptPath -PathType Leaf)) {
    throw "Missing internal session-state helper '$internalScriptPath'."
}
. $internalScriptPath

$effectiveAuthCommitHash = $AuthCommitHash
if ($effectiveAuthCommitHash -eq 'HEAD') {
    $resolvedHead = @(& git -C $ProjectPath rev-parse --verify HEAD 2>$null)
    if ($LASTEXITCODE -ne 0 -or $resolvedHead.Count -eq 0 -or $resolvedHead[0].ToString().Trim() -notmatch '^[0-9a-f]{40}$') {
        throw "Failed to resolve literal HEAD to a concrete commit hash."
    }

    $effectiveAuthCommitHash = $resolvedHead[0].ToString().Trim()
}

$result = Invoke-SpecrewBoundaryStateSync `
    -ProjectPath $ProjectPath `
    -BoundaryType $BoundaryType `
    -FeatureRef $FeatureRef `
    -IterationNumber $IterationNumber `
    -TaskId $TaskId `
    -AuthCommitHash $effectiveAuthCommitHash `
    -IdentityFocusArea $IdentityFocusArea `
    -IdentityActiveIssues $IdentityActiveIssues `
    -IdentityBody $IdentityBody

if ($PassThru) {
    $result
}
else {
    Write-Output ("Boundary sync complete: {0}" -f $BoundaryType)
    Write-Output ("Prompt: {0}" -f $result.prompt_path)
    Write-Output ("Context: {0}" -f $result.context_path)
    Write-Output ("Identity: {0}" -f $result.identity_path)
    Write-Output ("Decisions: {0}" -f $result.decisions_path)
}
