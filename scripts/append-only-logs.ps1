<#
.SYNOPSIS
    JSON Lines append-only log primitives for Specrew lifecycle events (F-051 Iteration 2b).
#>

Set-StrictMode -Version Latest

function Add-SpecrewJsonLine {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][hashtable]$Record
    )

    $directory = Split-Path -Parent $Path
    if (-not [string]::IsNullOrWhiteSpace($directory) -and -not (Test-Path -LiteralPath $directory -PathType Container)) {
        New-Item -ItemType Directory -Path $directory -Force | Out-Null
    }

    $json = ($Record | ConvertTo-Json -Depth 20 -Compress)
    $line = $json + [Environment]::NewLine
    $utf8NoBom = [System.Text.UTF8Encoding]::new($false)
    $stream = [System.IO.File]::Open($Path, [System.IO.FileMode]::Append, [System.IO.FileAccess]::Write, [System.IO.FileShare]::Read)
    try {
        $bytes = $utf8NoBom.GetBytes($line)
        $stream.Write($bytes, 0, $bytes.Length)
        $stream.Flush()
    }
    finally {
        $stream.Dispose()
    }
}

function Read-SpecrewJsonLines {
    param([Parameter(Mandatory = $true)][string]$Path)

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { return @() }

    $records = New-Object System.Collections.Generic.List[object]
    foreach ($line in Get-Content -LiteralPath $Path -Encoding UTF8) {
        if ([string]::IsNullOrWhiteSpace($line)) { continue }
        try {
            $records.Add(($line | ConvertFrom-Json -AsHashtable -Depth 20)) | Out-Null
        }
        catch {
            Write-Warning ("Specrew: skipped invalid JSON Lines record in '{0}': {1}" -f $Path, $_.Exception.Message)
        }
    }

    return $records.ToArray()
}

function Get-SpecrewLifecycleEventsPath {
    param([Parameter(Mandatory = $true)][string]$ProjectRoot)
    return (Join-Path $ProjectRoot '.squad/events/lifecycle-events.jsonl')
}

function Add-SpecrewLifecycleEvent {
    param(
        [Parameter(Mandatory = $true)][string]$ProjectRoot,
        [Parameter(Mandatory = $true)][string]$EventType,
        [Parameter(Mandatory = $true)][hashtable]$Payload,
        [AllowNull()][string]$NowUtc
    )

    if ([string]::IsNullOrWhiteSpace($NowUtc)) {
        $NowUtc = (Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ')
    }

    $record = [ordered]@{
        schema     = 'v1'
        recorded_at = $NowUtc
        event_type = $EventType
        payload    = $Payload
    }
    Add-SpecrewJsonLine -Path (Get-SpecrewLifecycleEventsPath -ProjectRoot $ProjectRoot) -Record $record
}
