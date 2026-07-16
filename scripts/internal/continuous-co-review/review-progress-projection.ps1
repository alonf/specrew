$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

function Get-ReviewSafeUsageProjection {
    param([AllowNull()]$Usage)
    $projection = [ordered]@{ status = 'unavailable'; input_tokens = $null; output_tokens = $null; total_tokens = $null; cost_usd = $null }
    if ($null -eq $Usage) { return [pscustomobject]$projection }
    $observed = 0
    $available = $false
    foreach ($name in @('input_tokens', 'output_tokens', 'total_tokens')) {
        $value = if (($Usage -is [Collections.IDictionary]) -and $Usage.Contains($name)) { $Usage[$name] } elseif ($Usage.PSObject.Properties[$name]) { $Usage.$name } else { $null }
        if ($null -ne $value -and [long]::TryParse([string]$value, [ref]$observed) -and $observed -ge 0) { $projection[$name] = $observed; $available = $true }
    }
    $cost = [decimal]0
    $costValue = if (($Usage -is [Collections.IDictionary]) -and $Usage.Contains('cost_usd')) { $Usage['cost_usd'] } elseif ($Usage.PSObject.Properties['cost_usd']) { $Usage.cost_usd } else { $null }
    if ($null -ne $costValue -and [decimal]::TryParse([string]$costValue, [Globalization.NumberStyles]::Number, [Globalization.CultureInfo]::InvariantCulture, [ref]$cost) -and $cost -ge 0) {
        $projection.cost_usd = $cost; $available = $true
    }
    if ($available) { $projection.status = 'available' }
    return [pscustomobject]$projection
}

function New-ReviewProgressEvent {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$CampaignId,
        [Parameter(Mandatory)][string]$RunId,
        [Parameter(Mandatory)][ValidateSet('requested', 'duplicate-warning', 'preflighted', 'running', 'terminalizing', 'terminal', 'failed')][string]$Stage,
        [Parameter(Mandatory)][string]$ObservedAt,
        [ValidateRange(0, 86400000)][long]$ElapsedMilliseconds,
        [ValidateRange(1, 7200)][int]$TimeoutSeconds = 900,
        [string]$Message,
        [AllowNull()]$ProcessTreeLive,
        [AllowNull()]$OutputActivity,
        [AllowNull()]$ValidatedFindingCount,
        [AllowNull()]$Usage
    )
    $boundedMessage = if ([string]::IsNullOrWhiteSpace($Message)) { '' } elseif ($Message.Length -le 500) { $Message } else { $Message.Substring(0, 500) }
    $findingCount = $null
    $parsedCount = 0
    if ($null -ne $ValidatedFindingCount -and [int]::TryParse([string]$ValidatedFindingCount, [ref]$parsedCount) -and $parsedCount -ge 0 -and $parsedCount -le 100) { $findingCount = $parsedCount }
    $remaining = [Math]::Max(0, ([long]$TimeoutSeconds * 1000) - $ElapsedMilliseconds)
    return [pscustomobject][ordered]@{
        schema_version = '1.0'; campaign_id = $CampaignId; run_id = $RunId; stage = $Stage; observed_at = $ObservedAt
        elapsed_ms = $ElapsedMilliseconds; remaining_ms = $remaining; message = $boundedMessage
        process_tree_live = $(if ($null -eq $ProcessTreeLive) { $null } else { [bool]$ProcessTreeLive })
        output_activity = $(if ($null -eq $OutputActivity) { $null } else { [bool]$OutputActivity })
        validated_finding_count = $findingCount; usage = Get-ReviewSafeUsageProjection -Usage $Usage; authority = $false
    }
}

function New-ReviewProgressCollector {
    param([AllowNull()][scriptblock]$ExternalSink, [ValidateRange(16, 4096)][int]$MaximumEvents = 2048)
    $events = [Collections.Generic.List[object]]::new()
    $safeUsageCommand = Get-Command -Name 'Get-ReviewSafeUsageProjection' -CommandType Function
    $sink = {
        param($event)
        try {
            # Store a controller-owned snapshot before an external renderer sees the original object.
            # Renderers may fail or mutate their argument; neither can rewrite collected diagnostics.
            $snapshot = [pscustomobject][ordered]@{
                schema_version = [string]$event.schema_version; campaign_id = [string]$event.campaign_id; run_id = [string]$event.run_id
                stage = [string]$event.stage; observed_at = [string]$event.observed_at; elapsed_ms = [long]$event.elapsed_ms
                remaining_ms = [long]$event.remaining_ms; message = [string]$event.message
                process_tree_live = $event.process_tree_live; output_activity = $event.output_activity
                validated_finding_count = $event.validated_finding_count; usage = & $safeUsageCommand -Usage $event.usage
                authority = $false
            }
            if ($events.Count -lt $MaximumEvents) { $events.Add($snapshot) | Out-Null }
            elseif ([string]$snapshot.stage -in @('terminal', 'failed')) {
                $replace = -1
                for ($i = 0; $i -lt $events.Count; $i++) { if ([string]$events[$i].stage -ceq 'running') { $replace = $i; break } }
                if ($replace -ge 0) { $events.RemoveAt($replace); $events.Add($snapshot) | Out-Null }
            }
            if ($null -ne $ExternalSink) { try { & $ExternalSink $event } catch { $null = $_ } }
        }
        catch { $null = $_ }
    }.GetNewClosure()
    return [pscustomobject]@{ sink = $sink; events = $events; max_events = $MaximumEvents }
}

function Get-ReviewProgressDiagnostics {
    param([object[]]$Events = @())
    $items = @($Events | Where-Object { $null -ne $_ })
    $phaseTotals = [ordered]@{}
    for ($i = 0; $i -lt ($items.Count - 1); $i++) {
        $stage = [string]$items[$i].stage
        $delta = [Math]::Max(0, [long]$items[$i + 1].elapsed_ms - [long]$items[$i].elapsed_ms)
        if (-not $phaseTotals.Contains($stage)) { $phaseTotals[$stage] = [long]0 }
        $phaseTotals[$stage] = [long]$phaseTotals[$stage] + $delta
    }
    $phases = @($phaseTotals.Keys | ForEach-Object { [pscustomobject][ordered]@{ stage = $_; duration_ms = [long]$phaseTotals[$_] } })
    $last = if ($items.Count -gt 0) { $items[-1] } else { $null }
    return [pscustomobject][ordered]@{
        schema_version = '1.0'; authority = $false; event_count = $items.Count
        elapsed_ms = $(if ($null -ne $last) { [long]$last.elapsed_ms } else { 0 })
        heartbeat_count = @($items | Where-Object { [string]$_.stage -ceq 'running' }).Count
        duplicate_warning = (@($items | Where-Object { [string]$_.stage -ceq 'duplicate-warning' }).Count -gt 0)
        phase_durations = $phases; usage = $(if ($null -ne $last) { $last.usage } else { Get-ReviewSafeUsageProjection -Usage $null })
        events = $items
    }
}

function Format-ReviewProgressEvent {
    param([Parameter(Mandatory)]$Event)
    $parts = [Collections.Generic.List[string]]::new()
    $parts.Add(('review {0}' -f [string]$Event.stage)) | Out-Null
    $parts.Add(('elapsed={0:n1}s' -f ([long]$Event.elapsed_ms / 1000))) | Out-Null
    $parts.Add(('remaining<={0:n1}s' -f ([long]$Event.remaining_ms / 1000))) | Out-Null
    if ($null -ne $Event.process_tree_live) { $parts.Add(('tree={0}' -f $(if ($Event.process_tree_live) { 'live' } else { 'dead' }))) | Out-Null }
    if ($null -ne $Event.output_activity) { $parts.Add(('output={0}' -f $(if ($Event.output_activity) { 'observed' } else { 'none' }))) | Out-Null }
    if ($null -ne $Event.validated_finding_count) { $parts.Add(('validated-findings={0}' -f $Event.validated_finding_count)) | Out-Null }
    if (-not [string]::IsNullOrWhiteSpace([string]$Event.message)) { $parts.Add(('- ' + [string]$Event.message)) | Out-Null }
    return $parts -join ' '
}
