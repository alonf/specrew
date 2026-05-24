# Shared utilities for specrew-init.ps1 (extracted via Proposal 108 Slice 1)
#
# Pure leaf — no dependencies on other init/ files. Behavior identical to the
# original inline definitions in scripts/specrew-init.ps1 (extracted unchanged).
#
# Functions exported (all internal-only; called by specrew-init.ps1 and other init/*.ps1):
#   - Get-NativeExitCode                 read $LASTEXITCODE safely
#   - ConvertTo-YamlBoolean              render bool as YAML "true"/"false"
#   - Test-ConsoleInputRedirected        detect stdin redirection
#   - Write-Step                         cyan "==> ..." step header
#   - Invoke-NativeCommand               run native exe; throw on non-zero
#   - Invoke-NativeCommandForOutput      run native exe; capture stdout + exit code
#   - Invoke-WithNativeCommandEncoding   force UTF-8 for specify on Windows
#   - Add-Action                         append @{Step,Outcome} to action list
#   - Ensure-DirectoryExists             mkdir -p with PreviewOnly support
#   - Get-SpecrewExecutionLayout         resolve module-vs-clone mode + TemplateRoot
#   - Write-MissingUtf8File              idempotent UTF-8-no-BOM file write

Set-StrictMode -Version Latest

function Get-NativeExitCode {
    if (Get-Variable -Name LASTEXITCODE -Scope Global -ErrorAction SilentlyContinue) {
        return $global:LASTEXITCODE
    }

    return 0
}

function ConvertTo-YamlBoolean {
    param(
        [Parameter(Mandatory = $true)]
        [bool]$Value
    )

    if ($Value) {
        return 'true'
    }

    return 'false'
}

function Test-ConsoleInputRedirected {
    try {
        return [Console]::IsInputRedirected
    }
    catch {
        return $true
    }
}

function Write-Step {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message
    )

    Write-Host ("==> {0}" -f $Message) -ForegroundColor Cyan
}

function Invoke-NativeCommand {
    param(
        [Parameter(Mandatory = $true)]
        [string]$FilePath,

        [Parameter(Mandatory = $true)]
        [string[]]$ArgumentList,

        [Parameter(Mandatory = $true)]
        [string]$WorkingDirectory
    )

    Push-Location $WorkingDirectory
    try {
        Invoke-WithNativeCommandEncoding -FilePath $FilePath -ScriptBlock {
            & $FilePath @ArgumentList
            if ((Get-NativeExitCode) -ne 0) {
                throw ("Command failed: {0} {1}" -f $FilePath, ($ArgumentList -join ' '))
            }
        }
    }
    finally {
        Pop-Location
    }
}

function Invoke-NativeCommandForOutput {
    param(
        [Parameter(Mandatory = $true)]
        [string]$FilePath,

        [Parameter(Mandatory = $true)]
        [string[]]$ArgumentList,

        [Parameter(Mandatory = $true)]
        [string]$WorkingDirectory
    )

    Push-Location $WorkingDirectory
    try {
        $output = Invoke-WithNativeCommandEncoding -FilePath $FilePath -ScriptBlock {
            @(& $FilePath @ArgumentList 2>&1)
        }
        return [pscustomobject]@{
            ExitCode = Get-NativeExitCode
            Output   = @($output | ForEach-Object { [string]$_ })
        }
    }
    finally {
        Pop-Location
    }
}

function Invoke-WithNativeCommandEncoding {
    param(
        [Parameter(Mandatory = $true)]
        [string]$FilePath,

        [Parameter(Mandatory = $true)]
        [scriptblock]$ScriptBlock
    )

    $shouldForceUtf8 = $IsWindows -and $FilePath -eq 'specify'
    if (-not $shouldForceUtf8) {
        return & $ScriptBlock
    }

    $utf8 = [System.Text.UTF8Encoding]::new($false)
    $previousOutputEncoding = $null
    $previousInputEncoding = $null
    $previousPipelineEncoding = $OutputEncoding
    $previousPythonUtf8 = [Environment]::GetEnvironmentVariable('PYTHONUTF8', 'Process')
    $previousPythonIoEncoding = [Environment]::GetEnvironmentVariable('PYTHONIOENCODING', 'Process')

    try {
        $previousOutputEncoding = [Console]::OutputEncoding
        $previousInputEncoding = [Console]::InputEncoding
    }
    catch {
        $shouldForceUtf8 = $false
    }

    if (-not $shouldForceUtf8) {
        return & $ScriptBlock
    }

    try {
        [Console]::OutputEncoding = $utf8
        [Console]::InputEncoding = $utf8
        $script:OutputEncoding = $utf8
        [Environment]::SetEnvironmentVariable('PYTHONUTF8', '1', 'Process')
        [Environment]::SetEnvironmentVariable('PYTHONIOENCODING', 'utf-8', 'Process')
        return & $ScriptBlock
    }
    finally {
        [Console]::OutputEncoding = $previousOutputEncoding
        [Console]::InputEncoding = $previousInputEncoding
        $script:OutputEncoding = $previousPipelineEncoding
        [Environment]::SetEnvironmentVariable('PYTHONUTF8', $previousPythonUtf8, 'Process')
        [Environment]::SetEnvironmentVariable('PYTHONIOENCODING', $previousPythonIoEncoding, 'Process')
    }
}

function Add-Action {
    param(
        [AllowEmptyCollection()]
        [Parameter(Mandatory = $true)]
        [System.Collections.ArrayList]$Actions,

        [Parameter(Mandatory = $true)]
        [string]$Step,

        [Parameter(Mandatory = $true)]
        [string]$Outcome
    )

    $null = $Actions.Add([pscustomobject]@{
            Step    = $Step
            Outcome = $Outcome
        })
}

function Ensure-DirectoryExists {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $true)]
        [switch]$PreviewOnly
    )

    if (Test-Path -LiteralPath $Path) {
        return
    }

    if ($PreviewOnly) {
        return
    }

    New-Item -ItemType Directory -Path $Path -Force | Out-Null
}

function Get-SpecrewExecutionLayout {
    # Walk up from this file's location until we find the Specrew distribution root
    # (marked by Specrew.psd1). This is robust against file relocation — when this
    # function lived in scripts/specrew-init.ps1 the root was 1 level up; after the
    # Proposal 108 Slice 1 extraction to scripts/init/_utilities.ps1 the root is
    # 2 levels up. The marker-file walk works in both cases + any future relocation.
    $distributionRoot = $PSScriptRoot
    for ($i = 0; $i -lt 5; $i++) {
        if (Test-Path -LiteralPath (Join-Path $distributionRoot 'Specrew.psd1') -PathType Leaf) {
            break
        }
        $parent = Split-Path -Parent $distributionRoot
        if ([string]::IsNullOrWhiteSpace($parent) -or $parent -eq $distributionRoot) {
            # Reached filesystem root without finding the marker — fall back to legacy 1-up resolution
            $distributionRoot = Split-Path -Parent $PSScriptRoot
            break
        }
        $distributionRoot = $parent
    }

    $templateRoot = Join-Path -Path $distributionRoot -ChildPath 'templates'
    $isModuleLayout = $env:SPECREW_INVOKED_FROM_MODULE -eq '1'

    return [pscustomobject]@{
        RootPath     = $distributionRoot
        Mode         = $(if ($isModuleLayout) { 'module' } else { 'clone' })
        TemplateRoot = $(if (Test-Path -LiteralPath $templateRoot -PathType Container) { $templateRoot } else { $null })
    }
}

function Write-MissingUtf8File {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [AllowEmptyString()]
        [Parameter(Mandatory = $true)]
        [string]$Content,

        [Parameter(Mandatory = $true)]
        [switch]$PreviewOnly
    )

    if (Test-Path -LiteralPath $Path) {
        return
    }

    if ($PreviewOnly) {
        return
    }

    $parent = Split-Path -Parent $Path
    if (-not [string]::IsNullOrWhiteSpace($parent) -and -not (Test-Path -LiteralPath $parent)) {
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
    }

    [System.IO.File]::WriteAllText($Path, $Content, [System.Text.UTF8Encoding]::new($false))
}

