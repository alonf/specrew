Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Invoke-WithFileLock {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $true)]
        [scriptblock]$ScriptBlock,

        [int]$RetryCount = 50,
        [int]$RetryDelayMilliseconds = 100
    )

    $directory = Split-Path -Parent $Path
    if (-not [string]::IsNullOrWhiteSpace($directory) -and -not (Test-Path -LiteralPath $directory -PathType Container)) {
        $null = New-Item -ItemType Directory -Path $directory -Force
    }

    $lockPath = "$Path.lock"
    $lockStream = $null
    for ($attempt = 0; $attempt -lt $RetryCount; $attempt++) {
        try {
            $lockStream = [System.IO.File]::Open($lockPath, [System.IO.FileMode]::OpenOrCreate, [System.IO.FileAccess]::ReadWrite, [System.IO.FileShare]::None)
            break
        }
        catch [System.IO.IOException] {
            if ($attempt -ge ($RetryCount - 1)) {
                throw "Could not acquire file lock for '$Path'."
            }

            Start-Sleep -Milliseconds $RetryDelayMilliseconds
        }
    }

    try {
        & $ScriptBlock
    }
    finally {
        if ($null -ne $lockStream) {
            $lockStream.Dispose()
        }

        if (Test-Path -LiteralPath $lockPath -PathType Leaf) {
            Remove-Item -LiteralPath $lockPath -Force -ErrorAction SilentlyContinue
        }
    }
}

function Write-Utf8FileAtomic {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string]$Content
    )

    $directory = Split-Path -Parent $Path
    if (-not [string]::IsNullOrWhiteSpace($directory) -and -not (Test-Path -LiteralPath $directory -PathType Container)) {
        $null = New-Item -ItemType Directory -Path $directory -Force
    }

    $tempPath = '{0}.{1}.tmp' -f $Path, ([guid]::NewGuid().ToString('N'))
    try {
        [System.IO.File]::WriteAllText($tempPath, $Content, [System.Text.UTF8Encoding]::new($false))
        Move-Item -LiteralPath $tempPath -Destination $Path -Force
    }
    finally {
        if (Test-Path -LiteralPath $tempPath -PathType Leaf) {
            Remove-Item -LiteralPath $tempPath -Force -ErrorAction SilentlyContinue
        }
    }
}

function Update-LockedFileContent {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $true)]
        [scriptblock]$Transform
    )

    Invoke-WithFileLock -Path $Path -ScriptBlock {
        $currentContent = if (Test-Path -LiteralPath $Path -PathType Leaf) {
            Get-Content -LiteralPath $Path -Raw -Encoding UTF8
        }
        else {
            ''
        }

        $updatedContent = & $Transform $currentContent
        if ($null -eq $updatedContent) {
            throw "Transform for '$Path' returned null."
        }

        Write-Utf8FileAtomic -Path $Path -Content $updatedContent
        return $updatedContent
    }
}

function Get-DecisionsLedgerPath {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectRoot
    )

    return Join-Path $ProjectRoot '.squad\decisions.md'
}

function Add-DecisionsLedgerEntry {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectRoot,

        [Parameter(Mandatory = $true)]
        [string]$Title,

        [Parameter(Mandatory = $true)]
        [string[]]$Lines
    )

    $ledgerPath = Get-DecisionsLedgerPath -ProjectRoot $ProjectRoot
    $timestamp = (Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ')
    $entryBody = @(
        "## $timestamp — $Title"
        ''
    ) + @($Lines | Where-Object { $null -ne $_ }) + @('')
    $entryText = ($entryBody -join [Environment]::NewLine).TrimEnd() + [Environment]::NewLine

    Invoke-WithFileLock -Path $ledgerPath -ScriptBlock {
        $existingContent = if (Test-Path -LiteralPath $ledgerPath -PathType Leaf) {
            Get-Content -LiteralPath $ledgerPath -Raw -Encoding UTF8
        }
        else {
            "# Decisions Ledger{0}{0}" -f [Environment]::NewLine
        }

        $updatedContent = $existingContent.TrimEnd()
        if (-not [string]::IsNullOrWhiteSpace($updatedContent)) {
            $updatedContent += [Environment]::NewLine + [Environment]::NewLine
        }

        $updatedContent += $entryText
        Write-Utf8FileAtomic -Path $ledgerPath -Content $updatedContent
    } | Out-Null

    return $ledgerPath
}
