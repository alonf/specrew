<#
.SYNOPSIS
  Read the standard turn record the hook dispatcher hands the bootstrap, and keep session ids path-safe.
.DESCRIPTION
  Feature 202 T002 (FR-006, DA-1 option B): the hook dispatcher is the ONLY component that reads a host
  payload. It builds the standard turn record from the host's declared binding (hosts/<host>/host.psd1) and
  passes it to the bootstrap provider as --turn-record. This adapter only decodes and validates that record;
  it never normalizes a raw host payload. (Before 202 it did, with its own key list that accepted an `id` key
  the dispatcher ignored, so the two disagreed about the session.) Pure transform - no filesystem or git access.
.OUTPUTS
  [pscustomobject] the turn record, or $null when the argument is absent or not a valid record.
#>

function New-SpecrewPerLaunchSessionToken {
    return ('launch-{0}' -f ([guid]::NewGuid().ToString('N')))
}

function ConvertTo-SpecrewFilesystemSafeSessionId {
    param([AllowNull()][string]$RawSessionId)

    if ([string]::IsNullOrWhiteSpace($RawSessionId)) {
        return (New-SpecrewPerLaunchSessionToken)
    }

    $clean = ([string]$RawSessionId) -replace '[^a-zA-Z0-9-]+', '-'
    $clean = $clean.Trim('-')
    if ([string]::IsNullOrWhiteSpace($clean)) {
        return (New-SpecrewPerLaunchSessionToken)
    }
    return $clean
}

function ConvertFrom-SpecrewTurnRecordArgument {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        # The dispatcher's --turn-record value: base64 of the record's UTF-8 JSON. Empty or garbage yields $null.
        [Parameter(Mandatory)][AllowEmptyString()][string] $Encoded
    )

    if ([string]::IsNullOrWhiteSpace($Encoded)) { return $null }
    try {
        $json = [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($Encoded.Trim()))
        $record = $json | ConvertFrom-Json -ErrorAction Stop
    }
    catch { return $null }
    if ($null -eq $record -or $record -isnot [psobject]) { return $null }
    $schema = $record.PSObject.Properties['schema']
    if (-not $schema -or [string]$schema.Value -cne 'specrew-turn-record/v1') { return $null }
    # The safe id is re-derived here rather than trusted: it becomes part of a filename.
    $rawIdProperty = $record.PSObject.Properties['session_id']
    $safeProperty = $record.PSObject.Properties['safe_session_id']
    $rawId = if ($rawIdProperty) { [string]$rawIdProperty.Value } else { '' }
    $safe = if ($safeProperty) { [string]$safeProperty.Value } else { '' }
    if ([string]::IsNullOrWhiteSpace($rawId)) {
        if ([string]::IsNullOrWhiteSpace($safe) -or $safe -notmatch '^launch-[0-9a-f]{32}$') { $safe = New-SpecrewPerLaunchSessionToken }
    }
    else {
        $safe = ConvertTo-SpecrewFilesystemSafeSessionId -RawSessionId $rawId
    }
    $record | Add-Member -NotePropertyName safe_session_id -NotePropertyValue $safe -Force
    return $record
}
