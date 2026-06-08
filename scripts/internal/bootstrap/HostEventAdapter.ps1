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
function ConvertFrom-SpecrewHostHookEvent {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        # Raw hook event payload as the host emits it (JSON text). Empty/garbage is tolerated.
        [Parameter(Mandatory)][AllowEmptyString()][string] $RawEvent,
        # The launching host. ('Host' is a PowerShell automatic variable, so this is HostName.)
        [Parameter(Mandatory)][ValidateSet('claude', 'codex', 'copilot', 'cursor')][string] $HostName,
        # Optional explicit project root; falls back to the event's cwd.
        [Parameter()][string] $ProjectRoot
    )

    $payload = $null
    if (-not [string]::IsNullOrWhiteSpace($RawEvent)) {
        try { $payload = $RawEvent | ConvertFrom-Json -ErrorAction Stop } catch { $payload = $null }
    }

    $sessionId = $null; $source = $null; $eventName = $null; $cwd = $null
    if ($null -ne $payload) {
        $sessionId = $payload.session_id
        $source    = $payload.source
        $eventName = $payload.hook_event_name
        $cwd       = $payload.cwd
    }

    # Sanitize the session id to a filename-safe token before it is ever used in a path.
    $safeSessionId = if ($sessionId) { ([string]$sessionId) -replace '[^a-zA-Z0-9-]', '-' } else { $null }
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
