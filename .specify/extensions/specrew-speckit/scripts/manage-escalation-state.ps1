[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$IterationDirectory,

    [ValidateSet('get', 'activate', 'resolve', 'clear')]
    [string]$Mode = 'get',

    [string]$Artifact,
    [string]$Gate,
    [string]$Owner,
    [string[]]$LockedOutAgents,
    [int]$FailureCount,

    [ValidateSet('efficiency', 'balanced', 'deep')]
    [string]$Tier,

    [string]$Notes,
    [switch]$DryRun,
    [switch]$PassThru
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$sharedGovernancePath = Join-Path $PSScriptRoot 'shared-governance.ps1'
if (-not (Test-Path -LiteralPath $sharedGovernancePath -PathType Leaf)) {
    throw "Missing shared governance helper '$sharedGovernancePath'."
}
. $sharedGovernancePath

function Resolve-ProjectRoot {
    param([string]$StartPath)

    $current = [System.IO.DirectoryInfo]::new([System.IO.Path]::GetFullPath($StartPath))
    while ($null -ne $current) {
        if ((Test-Path -LiteralPath (Join-Path $current.FullName '.squad') -PathType Container) -or
            (Test-Path -LiteralPath (Join-Path $current.FullName '.specrew') -PathType Container)) {
            return $current.FullName
        }

        $current = $current.Parent
    }

    throw "Could not resolve project root from '$StartPath'."
}

function Test-IsNullish {
    param([AllowNull()][string]$Value)

    if ([string]::IsNullOrWhiteSpace($Value)) {
        return $true
    }

    return $Value.Trim() -match '^(?:—|-|none|null|n/a|\(none\)|blank)$'
}

function Get-DefaultEscalationState {
    return [pscustomobject]@{
        status            = 'inactive'
        artifact          = $null
        gate              = $null
        failure_count     = 0
        current_tier      = 'efficiency'
        current_owner     = $null
        locked_out_agents = @()
        last_escalated    = $null
        resolved_at       = $null
        notes             = $null
    }
}

function Get-ManagedBlockContent {
    param(
        [string]$Content,
        [string]$BlockName
    )

    $startMarker = "<!-- >>> specrew-managed $BlockName >>> -->"
    $endMarker = "<!-- <<< specrew-managed $BlockName <<< -->"
    $pattern = '(?ms)' + [regex]::Escape($startMarker) + '\s*(.*?)\s*' + [regex]::Escape($endMarker)
    $match = [regex]::Match($Content, $pattern)
    if (-not $match.Success) {
        return $null
    }

    return $match.Groups[1].Value.Trim()
}

function Set-ManagedBlock {
    param(
        [string]$Content,
        [string]$BlockName,
        [string]$BlockContent
    )

    $startMarker = "<!-- >>> specrew-managed $BlockName >>> -->"
    $endMarker = "<!-- <<< specrew-managed $BlockName <<< -->"
    $managedBlock = @(
        $startMarker
        $BlockContent.Trim()
        $endMarker
    ) -join [Environment]::NewLine
    $pattern = '(?ms)\s*' + [regex]::Escape($startMarker) + '.*?' + [regex]::Escape($endMarker) + '\s*'

    if ($Content -match $pattern) {
        $updated = [regex]::Replace($Content, $pattern, ([Environment]::NewLine + [Environment]::NewLine + $managedBlock + [Environment]::NewLine + [Environment]::NewLine))
        return $updated.TrimEnd() + [Environment]::NewLine
    }

    if ([string]::IsNullOrWhiteSpace($Content)) {
        return $managedBlock + [Environment]::NewLine
    }

    return $Content.TrimEnd() + [Environment]::NewLine + [Environment]::NewLine + $managedBlock + [Environment]::NewLine
}

function Get-BulletMetadataValue {
    param(
        [string[]]$Lines,
        [string]$Label
    )

    $pattern = '^\s*-\s*\*\*' + [regex]::Escape($Label) + '\*\*:\s*(.+?)\s*$'
    foreach ($line in $Lines) {
        if ($line -match $pattern) {
            return $Matches[1].Trim()
        }
    }

    return $null
}

function Get-TierForFailureCount {
    param([int]$Count)

    if ($Count -ge 2) {
        return 'deep'
    }

    if ($Count -ge 1) {
        return 'balanced'
    }

    return 'efficiency'
}

function Get-EscalationState {
    param([string]$StateContent)

    $defaultState = Get-DefaultEscalationState
    $blockContent = Get-ManagedBlockContent -Content $StateContent -BlockName 'escalation-state'
    if ([string]::IsNullOrWhiteSpace($blockContent)) {
        return $defaultState
    }

    $lines = @($blockContent -split "`r?`n")
    $status = Get-BulletMetadataValue -Lines $lines -Label 'Status'
    $artifact = Get-BulletMetadataValue -Lines $lines -Label 'Artifact'
    $gate = Get-BulletMetadataValue -Lines $lines -Label 'Gate'
    $failureCount = Get-BulletMetadataValue -Lines $lines -Label 'Failure Count'
    $currentTier = Get-BulletMetadataValue -Lines $lines -Label 'Current Tier'
    $currentOwner = Get-BulletMetadataValue -Lines $lines -Label 'Current Owner'
    $lockedOutAgents = Get-BulletMetadataValue -Lines $lines -Label 'Locked Out Agents'
    $lastEscalated = Get-BulletMetadataValue -Lines $lines -Label 'Last Escalated'
    $resolvedAt = Get-BulletMetadataValue -Lines $lines -Label 'Resolved At'
    $notes = Get-BulletMetadataValue -Lines $lines -Label 'Notes'

    $parsedFailureCount = 0
    if (-not [string]::IsNullOrWhiteSpace($failureCount)) {
        [void][int]::TryParse($failureCount.Trim(), [ref]$parsedFailureCount)
    }

    $lockedOut = @()
    if (-not (Test-IsNullish $lockedOutAgents)) {
        $lockedOut = @(
            $lockedOutAgents -split ',' |
                ForEach-Object { $_.Trim() } |
                Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
        )
    }

    return [pscustomobject]@{
        status            = if (Test-IsNullish $status) { $defaultState.status } else { $status.Trim().ToLowerInvariant() }
        artifact          = if (Test-IsNullish $artifact) { $null } else { $artifact.Trim() }
        gate              = if (Test-IsNullish $gate) { $null } else { $gate.Trim() }
        failure_count     = $parsedFailureCount
        current_tier      = if (Test-IsNullish $currentTier) { $defaultState.current_tier } else { $currentTier.Trim().ToLowerInvariant() }
        current_owner     = if (Test-IsNullish $currentOwner) { $null } else { $currentOwner.Trim() }
        locked_out_agents = @($lockedOut)
        last_escalated    = if (Test-IsNullish $lastEscalated) { $null } else { $lastEscalated.Trim() }
        resolved_at       = if (Test-IsNullish $resolvedAt) { $null } else { $resolvedAt.Trim() }
        notes             = if (Test-IsNullish $notes) { $null } else { $notes.Trim() }
    }
}

function Format-EscalationStateBlock {
    param([pscustomobject]$State)

    return @"
## Repair Escalation

- **Status**: $(if (Test-IsNullish $State.status) { 'inactive' } else { $State.status })
- **Artifact**: $(if (Test-IsNullish $State.artifact) { '(none)' } else { $State.artifact })
- **Gate**: $(if (Test-IsNullish $State.gate) { '(none)' } else { $State.gate })
- **Failure Count**: $([int]$State.failure_count)
- **Current Tier**: $(if (Test-IsNullish $State.current_tier) { 'efficiency' } else { $State.current_tier })
- **Current Owner**: $(if (Test-IsNullish $State.current_owner) { '(none)' } else { $State.current_owner })
- **Locked Out Agents**: $(if ($null -ne $State.locked_out_agents -and $State.locked_out_agents.Count -gt 0) { $State.locked_out_agents -join ', ' } else { '(none)' })
- **Last Escalated**: $(if (Test-IsNullish $State.last_escalated) { '(none)' } else { $State.last_escalated })
- **Resolved At**: $(if (Test-IsNullish $State.resolved_at) { '(none)' } else { $State.resolved_at })
- **Notes**: $(if (Test-IsNullish $State.notes) { '(none)' } else { $State.notes })
"@
}

$resolvedIterationDirectory = [System.IO.Path]::GetFullPath($IterationDirectory)
$statePath = Join-Path -Path $resolvedIterationDirectory -ChildPath 'state.md'
if (-not (Test-Path -LiteralPath $statePath -PathType Leaf)) {
    throw "Iteration state '$statePath' does not exist."
}

$projectRoot = Resolve-ProjectRoot -StartPath $resolvedIterationDirectory
$nextState = $null
$stateContent = $null
$currentState = $null
$timestamp = (Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ')

if ($Mode -eq 'get') {
    $stateContent = Get-Content -LiteralPath $statePath -Raw -Encoding UTF8
    $currentState = Get-EscalationState -StateContent $stateContent
    $nextState = $currentState
}
else {
    $hasFailureCount = $PSBoundParameters.ContainsKey('FailureCount')
    $hasTier = $PSBoundParameters.ContainsKey('Tier')
    $hasNotes = $PSBoundParameters.ContainsKey('Notes')
    $updateEscalation = {
        param([string]$CurrentContent)

        $script:stateContent = $CurrentContent
        $script:currentState = Get-EscalationState -StateContent $CurrentContent

        switch ($Mode) {
            'activate' {
                if ([string]::IsNullOrWhiteSpace($Artifact)) {
                    throw 'Mode activate requires -Artifact.'
                }

                if ([string]::IsNullOrWhiteSpace($Gate)) {
                    throw 'Mode activate requires -Gate.'
                }

                if ([string]::IsNullOrWhiteSpace($Owner)) {
                    throw 'Mode activate requires -Owner.'
                }

                $sameEscalation = $script:currentState.status -eq 'active' -and $script:currentState.artifact -eq $Artifact -and $script:currentState.gate -eq $Gate
                $resolvedFailureCount = if ($hasFailureCount) {
                    $FailureCount
                }
                elseif ($sameEscalation) {
                    $script:currentState.failure_count + 1
                }
                else {
                    1
                }

                $resolvedTier = if ($hasTier) { $Tier } else { Get-TierForFailureCount -Count $resolvedFailureCount }
                $lockoutSet = New-Object System.Collections.Generic.HashSet[string] ([System.StringComparer]::OrdinalIgnoreCase)
                foreach ($agentName in @($script:currentState.locked_out_agents + $LockedOutAgents)) {
                    if (-not [string]::IsNullOrWhiteSpace($agentName)) {
                        $null = $lockoutSet.Add($agentName.Trim())
                    }
                }

                if ($sameEscalation -and -not [string]::IsNullOrWhiteSpace($script:currentState.current_owner)) {
                    $null = $lockoutSet.Add($script:currentState.current_owner.Trim())
                }

                if ($lockoutSet.Contains($Owner.Trim())) {
                    $null = $lockoutSet.Remove($Owner.Trim())
                }

                $noteValue = if ($hasNotes) {
                    $Notes
                }
                elseif ($sameEscalation) {
                    $script:currentState.notes
                }
                else {
                    $null
                }

                $script:nextState = [pscustomobject]@{
                    status            = 'active'
                    artifact          = $Artifact.Trim()
                    gate              = $Gate.Trim()
                    failure_count     = $resolvedFailureCount
                    current_tier      = $resolvedTier
                    current_owner     = $Owner.Trim()
                    locked_out_agents = @($lockoutSet | Sort-Object)
                    last_escalated    = $timestamp
                    resolved_at       = $null
                    notes             = if (Test-IsNullish $noteValue) { $null } else { $noteValue.Trim() }
                }
            }
            'resolve' {
                $script:nextState = [pscustomobject]@{
                    status            = 'inactive'
                    artifact          = $null
                    gate              = $null
                    failure_count     = 0
                    current_tier      = 'efficiency'
                    current_owner     = $null
                    locked_out_agents = @()
                    last_escalated    = $null
                    resolved_at       = $timestamp
                    notes             = if (Test-IsNullish $Notes) { 'Resolved after governance gate passed.' } else { $Notes.Trim() }
                }
            }
            'clear' {
                $script:nextState = Get-DefaultEscalationState
            }
        }

        $blockContent = Format-EscalationStateBlock -State $script:nextState
        return Set-ManagedBlock -Content $CurrentContent -BlockName 'escalation-state' -BlockContent $blockContent
    }

    if ($DryRun) {
        $stateContent = Get-Content -LiteralPath $statePath -Raw -Encoding UTF8
        $null = & $updateEscalation $stateContent
    }
    else {
        $null = Update-LockedFileContent -Path $statePath -Transform $updateEscalation
    }
}

if (-not $DryRun -and $Mode -ne 'get') {
    $entryTitle = switch ($Mode) {
        'activate' { 'Repair escalation activated' }
        'resolve' { 'Repair escalation resolved' }
        'clear' { 'Repair escalation cleared' }
        default { 'Repair escalation updated' }
    }

    $lockedOutDisplay = if ($nextState.locked_out_agents.Count -gt 0) { $nextState.locked_out_agents -join ', ' } else { '(none)' }
    $notesDisplay = if (Test-IsNullish $nextState.notes) { '(none)' } else { $nextState.notes }
    $relativeIterationDirectory = [System.IO.Path]::GetRelativePath($projectRoot, $resolvedIterationDirectory) -replace '/', '\'
    Add-StructuredDecisionsLedgerEntry -ProjectRoot $projectRoot -Title $entryTitle -Type 'escalation' -AffectedRequirement 'FR-027' -AffectedIteration $relativeIterationDirectory -NextAction 'none' -Rationale ("Repair escalation state changed to '{0}' for artifact '{1}'." -f $nextState.status, $(if (Test-IsNullish $nextState.artifact) { '(none)' } else { $nextState.artifact })) -DetailLines @(
        "- **Iteration**: $resolvedIterationDirectory"
        "- **Artifact**: $(if (Test-IsNullish $nextState.artifact) { '(none)' } else { $nextState.artifact })"
        "- **Gate**: $(if (Test-IsNullish $nextState.gate) { '(none)' } else { $nextState.gate })"
        "- **Status**: $($nextState.status)"
        "- **Owner**: $(if (Test-IsNullish $nextState.current_owner) { '(none)' } else { $nextState.current_owner })"
        "- **Tier**: $($nextState.current_tier)"
        "- **Failure Count**: $([int]$nextState.failure_count)"
        "- **Locked Out Agents**: $lockedOutDisplay"
        "- **Notes**: $notesDisplay"
    ) | Out-Null
}

if ($PassThru) {
    $nextState
    return
}

$nextState | ConvertTo-Json -Depth 5
exit 0
