$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$proposal197ReviewerModules = @(
    'reviewer-contracts.ps1'
)

foreach ($moduleName in $proposal197ReviewerModules) {
    $modulePath = Join-Path $PSScriptRoot $moduleName
    if (-not (Test-Path -LiteralPath $modulePath -PathType Leaf)) {
        continue
    }

    . $modulePath
}
