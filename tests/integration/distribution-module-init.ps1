[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Write-Pass {
    param([string]$Message)
    Write-Host "PASS: $Message" -ForegroundColor Green
}

function Write-Fail {
    param([string]$Message)
    Write-Host "FAIL: $Message" -ForegroundColor Red
}

function Write-Skip {
    param([string]$Message)
    Write-Host "SKIP: $Message" -ForegroundColor Yellow
}

function Copy-DistributionSurface {
    param(
        [Parameter(Mandatory = $true)]
        [string]$SourcePath,

        [Parameter(Mandatory = $true)]
        [string]$DestinationPath
    )

    if (-not (Test-Path -LiteralPath $SourcePath)) {
        throw "Missing distribution surface '$SourcePath'."
    }

    $item = Get-Item -LiteralPath $SourcePath
    if ($item.PSIsContainer) {
        Copy-Item -LiteralPath $SourcePath -Destination $DestinationPath -Recurse -Force
        return
    }

    $parent = Split-Path -Parent $DestinationPath
    if (-not [string]::IsNullOrWhiteSpace($parent) -and -not (Test-Path -LiteralPath $parent)) {
        New-Item -Path $parent -ItemType Directory -Force | Out-Null
    }

    Copy-Item -LiteralPath $SourcePath -Destination $DestinationPath -Force
}

function Invoke-ModuleBootstrap {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ModuleManifestPath,

        [Parameter(Mandatory = $true)]
        [string]$ProjectPath,

        [AllowEmptyCollection()]
        [Parameter(Mandatory = $true)]
        [string[]]$ArgumentList
    )

    $escapedManifest = $ModuleManifestPath.Replace("'", "''")
    $escapedProject = $ProjectPath.Replace("'", "''")
    $argumentExpression = ($ArgumentList | ForEach-Object { "'{0}'" -f $_.Replace("'", "''") }) -join ', '
    $command = @"
`$ErrorActionPreference = 'Stop'
Import-Module '$escapedManifest' -Force
`$arguments = @($argumentExpression)
specrew-init -ProjectPath '$escapedProject' @arguments
"@

    $output = @(& pwsh -NoProfile -ExecutionPolicy Bypass -Command $command 2>&1)
    return [pscustomobject]@{
        ExitCode = $LASTEXITCODE
        Output   = @($output | ForEach-Object { [string]$_ })
    }
}

$repoRoot = (Resolve-Path (Join-Path -Path $PSScriptRoot -ChildPath '..\..')).Path
$scratchRoot = Join-Path -Path $repoRoot -ChildPath '.scratch\distribution-module-init'
$moduleRoot = Join-Path -Path $scratchRoot -ChildPath 'module\Specrew'
$projectRoot = Join-Path -Path $scratchRoot -ChildPath 'project'
$moduleManifestPath = Join-Path -Path $moduleRoot -ChildPath 'Specrew.psd1'

if (Test-Path -LiteralPath $scratchRoot) {
    Remove-Item -LiteralPath $scratchRoot -Recurse -Force
}

$null = New-Item -Path $moduleRoot -ItemType Directory -Force
$null = New-Item -Path $projectRoot -ItemType Directory -Force

$missingTools = @()
if (-not (Get-Command -Name 'specify' -ErrorAction SilentlyContinue)) {
    $missingTools += 'specify'
}
if (-not (Get-Command -Name 'squad' -ErrorAction SilentlyContinue)) {
    $missingTools += 'squad'
}

if ($missingTools.Count -gt 0) {
    Write-Skip ("Distribution-module bootstrap test requires tools not available in this environment: {0}" -f ($missingTools -join ', '))
    exit 0
}

Copy-DistributionSurface -SourcePath (Join-Path -Path $repoRoot -ChildPath 'Specrew.psd1') -DestinationPath (Join-Path -Path $moduleRoot -ChildPath 'Specrew.psd1')
Copy-DistributionSurface -SourcePath (Join-Path -Path $repoRoot -ChildPath 'Specrew.psm1') -DestinationPath (Join-Path -Path $moduleRoot -ChildPath 'Specrew.psm1')
Copy-DistributionSurface -SourcePath (Join-Path -Path $repoRoot -ChildPath 'scripts') -DestinationPath (Join-Path -Path $moduleRoot -ChildPath 'scripts')
Copy-DistributionSurface -SourcePath (Join-Path -Path $repoRoot -ChildPath 'extensions') -DestinationPath (Join-Path -Path $moduleRoot -ChildPath 'extensions')
Copy-DistributionSurface -SourcePath (Join-Path -Path $repoRoot -ChildPath 'templates') -DestinationPath (Join-Path -Path $moduleRoot -ChildPath 'templates')
Copy-DistributionSurface -SourcePath (Join-Path -Path $repoRoot -ChildPath 'docs') -DestinationPath (Join-Path -Path $moduleRoot -ChildPath 'docs')

$firstRun = Invoke-ModuleBootstrap -ModuleManifestPath $moduleManifestPath -ProjectPath $projectRoot -ArgumentList @('-Force')
if ($firstRun.ExitCode -ne 0) {
    Write-Fail ("Initial module bootstrap failed with exit code {0}. Output:`n{1}" -f $firstRun.ExitCode, ($firstRun.Output -join [Environment]::NewLine))
    exit 1
}

$requiredPaths = @(
    '.specify\templates\spec-template.md',
    '.specify\templates\plan-template.md',
    '.squad\agents\implementer\charter.md',
    '.squad\decisions.md',
    '.squad\identity\now.md',
    '.github\workflows\specrew-ci.yml',
    '.specrew\config.yml'
)

$missingPaths = @()
foreach ($relativePath in $requiredPaths) {
    $fullPath = Join-Path -Path $projectRoot -ChildPath $relativePath
    if (-not (Test-Path -LiteralPath $fullPath)) {
        $missingPaths += $relativePath
    }
}

if ($missingPaths.Count -gt 0) {
    Write-Fail ("Distribution bootstrap missed required artifacts: {0}" -f ($missingPaths -join ', '))
    exit 1
}

$workflowRoot = Join-Path -Path $projectRoot -ChildPath '.github\workflows'
$workflowCount = @(Get-ChildItem -LiteralPath $workflowRoot -File -ErrorAction SilentlyContinue).Count
if ($workflowCount -lt 1) {
    Write-Fail 'Distribution bootstrap did not install any GitHub workflows.'
    exit 1
}

$trackedFiles = @(
    (Join-Path -Path $projectRoot -ChildPath '.specify\templates\spec-template.md'),
    (Join-Path -Path $projectRoot -ChildPath '.squad\identity\now.md'),
    (Join-Path -Path $projectRoot -ChildPath '.github\workflows\specrew-ci.yml')
)
$baselineHashes = @{}
foreach ($trackedFile in $trackedFiles) {
    $baselineHashes[$trackedFile] = (Get-FileHash -LiteralPath $trackedFile -Algorithm SHA256).Hash
}

Write-Pass 'Module bootstrap copied bundled templates and preserved per-project artifacts.'

$secondRun = Invoke-ModuleBootstrap -ModuleManifestPath $moduleManifestPath -ProjectPath $projectRoot -ArgumentList @()
if ($secondRun.ExitCode -ne 0) {
    Write-Fail ("Idempotency rerun failed with exit code {0}. Output:`n{1}" -f $secondRun.ExitCode, ($secondRun.Output -join [Environment]::NewLine))
    exit 1
}

$secondRunOutput = $secondRun.Output -join [Environment]::NewLine
foreach ($pattern in @(
        'preserved existing \.specify',
        'preserved existing \.squad',
        'preserved existing \.github'
    )) {
    if ($secondRunOutput -notmatch $pattern) {
        Write-Fail ("Idempotency rerun did not report expected overwrite guard '{0}'. Output:`n{1}" -f $pattern, $secondRunOutput)
        exit 1
    }
}

foreach ($trackedFile in $trackedFiles) {
    $currentHash = (Get-FileHash -LiteralPath $trackedFile -Algorithm SHA256).Hash
    if ($currentHash -ne $baselineHashes[$trackedFile]) {
        Write-Fail ("Idempotency rerun unexpectedly changed '$trackedFile'.")
        exit 1
    }
}

Write-Pass 'Module bootstrap rerun preserved existing template surfaces without overwriting files.'
Write-Pass 'Distribution-module bootstrap validation passed.'
exit 0
