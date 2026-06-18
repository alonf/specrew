<#
.SYNOPSIS
  Normalize a host SessionStart/SessionEnd hook event into a Specrew-internal shape.
.DESCRIPTION
  Volatile adapter (IDesign): isolates per-host hook payload differences behind a stable
  PSCustomObject contract consumed by SessionBootstrapManager. Pure transform - no
  filesystem or git access. Feature 174 (FR-001, FR-005). Iteration 001 targets the Claude
  payload; other hosts are added in iteration 003 (T016).
.OUTPUTS
  [pscustomobject] { host, event_name, source, session_id, safe_session_id, project_root, parsed }
#>

function Get-SpecrewEventField {
    # Defensive multi-key read: hosts vary in casing/naming (snake_case vs camelCase), so try each
    # candidate key in priority order and return the first non-empty. This normalizes the common
    # variants WITHOUT hardcoding unverified per-host schemas - an unknown field simply yields $null
    # and the bootstrap degrades to full mode (fail-open). FR-005.
    param([AllowNull()]$Payload, [Parameter(Mandatory)][string[]] $Names)
    if ($null -eq $Payload) { return $null }
    foreach ($n in $Names) {
        $p = $Payload.PSObject.Properties[$n]
        if (-not $p -or $null -eq $p.Value) { continue }
        if ($p.Value -is [System.Array]) {
            foreach ($item in @($p.Value)) {
                if (-not [string]::IsNullOrWhiteSpace([string]$item)) { return [string]$item }
            }
            continue
        }
        if (-not [string]::IsNullOrWhiteSpace([string]$p.Value)) { return $p.Value }
    }
    return $null
}

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

function ConvertFrom-SpecrewHostHookEvent {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        # Raw hook event payload as the host emits it (JSON text). Empty/garbage is tolerated.
        [Parameter(Mandatory)][AllowEmptyString()][string] $RawEvent,
        # The launching host. ('Host' is a PowerShell automatic variable, so this is HostName.)
        [Parameter(Mandatory)][ValidatePattern('^[A-Za-z0-9_.-]+$')][string] $HostName,
        # Optional explicit project root; falls back to the event's cwd.
        [Parameter()][string] $ProjectRoot
    )

    $payload = $null
    if (-not [string]::IsNullOrWhiteSpace($RawEvent)) {
        try { $payload = $RawEvent | ConvertFrom-Json -ErrorAction Stop } catch { $payload = $null }
    }

    # Per-host field normalization (FR-005): try snake_case + camelCase variants across hosts.
    $sessionId = Get-SpecrewEventField $payload @('session_id', 'sessionId', 'conversation_id', 'conversationId', 'id')
    $source    = Get-SpecrewEventField $payload @('source', 'trigger', 'reason')
    $eventName = Get-SpecrewEventField $payload @('hook_event_name', 'hookEventName', 'event_name')
    $cwd       = Get-SpecrewEventField $payload @('cwd', 'workspace_root', 'workspaceRoot', 'workspacePaths', 'project_root', 'projectRoot', 'workingDirectory')

    # Sanitize the session id before it is ever used in a path. Missing or malformed ids get a
    # per-launch token, never a global "unknown" bucket.
    $safeSessionId = ConvertTo-SpecrewFilesystemSafeSessionId -RawSessionId $sessionId
    $resolvedRoot = if ($ProjectRoot) { $ProjectRoot } elseif ($cwd) { $cwd } else { $null }

    [pscustomobject]@{
        host            = $HostName
        event_name      = $eventName
        source          = $source
        session_id      = $sessionId
        safe_session_id = $safeSessionId
        project_root    = $resolvedRoot
        parsed          = ($null -ne $payload)
    }
}
