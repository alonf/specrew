<#
.SYNOPSIS
    Shared UTC timestamp helpers for Specrew multi-session state (F-051).

.DESCRIPTION
    `Get-SpecrewUtcNow` returns the current time as an ISO-8601 UTC string; `ConvertTo-SpecrewUtc`
    parses such a string to a [DateTimeOffset] (or $null on failure). Shared by
    session-management.ps1 (stale-lock age) and feature-claims.ps1 (monotonic refresh) so the
    parse/format convention exists once. Dot-source to use.
#>

Set-StrictMode -Version Latest

function Get-SpecrewUtcNow {
    return ((Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ'))
}

function ConvertTo-SpecrewUtc {
    param([Parameter(Mandatory = $true)][AllowEmptyString()][AllowNull()][string]$Value)
    if ([string]::IsNullOrWhiteSpace($Value)) { return $null }
    try {
        $styles = [System.Globalization.DateTimeStyles]::AssumeUniversal -bor [System.Globalization.DateTimeStyles]::AdjustToUniversal
        return [System.DateTimeOffset]::Parse($Value, [System.Globalization.CultureInfo]::InvariantCulture, $styles)
    }
    catch { return $null }
}
