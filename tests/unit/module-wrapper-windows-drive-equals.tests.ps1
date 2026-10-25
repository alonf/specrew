[CmdletBinding()]
param()

# Beta3 installed-package regression: the PowerShell module wrapper launches
# command scripts through `pwsh -File`.  That binder splits a GNU-style
# `--project-path=C:\...` token at the drive colon unless the wrapper lowers it
# to the equivalent two-token form before launch.  Parser-only tests cannot see
# this defect, so this clean-room check drives the exported `specrew` alias.

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Write-Pass { param([string]$Message) Write-Host "PASS: $Message" -ForegroundColor Green }
function Write-Fail { param([string]$Message) Write-Host "FAIL: $Message" -ForegroundColor Red; throw $Message }

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$manifestPath = Join-Path $repoRoot 'Specrew.psd1'
$driverPath = Join-Path ([System.IO.Path]::GetTempPath()) ("specrew-module-wrapper-$([guid]::NewGuid().ToString('N')).ps1")
$syntheticWindowsPath = 'C:\Temp\specrew-module-wrapper-smoke'

$driver = @"
`$ErrorActionPreference = 'Stop'
Import-Module '$($manifestPath -replace "'", "''")' -Force
specrew init '--project-path=$syntheticWindowsPath' --help
if (`$LASTEXITCODE -ne 0) { exit `$LASTEXITCODE }
"@

try {
    Set-Content -LiteralPath $driverPath -Value $driver -Encoding UTF8
    $output = @(& (Get-Process -Id $PID).Path -NoProfile -NonInteractive -File $driverPath 2>&1)
    if ($LASTEXITCODE -ne 0) {
        Write-Fail ("module alias rejected a Windows drive path in --project-path=<value> form:`n{0}" -f ($output -join "`n"))
    }
    if (($output -join "`n") -notmatch 'specrew init \[options\]') {
        Write-Fail ("module alias did not reach the init help surface:`n{0}" -f ($output -join "`n"))
    }
    if (($output -join "`n") -match "Unknown option") {
        Write-Fail ("module alias leaked a split drive-path fragment to the parser:`n{0}" -f ($output -join "`n"))
    }
    Write-Pass 'installed-style module alias preserves --project-path=C:\\... across the child-process handoff'
}
finally {
    Remove-Item -LiteralPath $driverPath -Force -ErrorAction SilentlyContinue
}

Write-Host ''
Write-Host 'All module-wrapper Windows drive-path tests passed.' -ForegroundColor Green
