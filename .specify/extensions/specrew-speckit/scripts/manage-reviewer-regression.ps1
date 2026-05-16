[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('report', 'resolve', 'withdraw', 'project', 'get')]
    [string]$Mode,

    [Parameter(Mandatory = $false)]
    [string]$ProjectRoot = '.',

    [Parameter(Mandatory = $false)]
    [string]$EventId,

    [Parameter(Mandatory = $false)]
    [string]$Feature,

    [Parameter(Mandatory = $false)]
    [string]$IterationDirectory,

    [Parameter(Mandatory = $false)]
    [string]$Slice,

    [Parameter(Mandatory = $false)]
    [string]$PriorReviewerVerdict,

    [Parameter(Mandatory = $false)]
    [string]$PriorReviewerClass,

    [Parameter(Mandatory = $false)]
    [string]$PriorReviewerOwner,

    [Parameter(Mandatory = $false)]
    [string]$DefectDescription,

    [Parameter(Mandatory = $false)]
    [string]$DefectSourceLocation,

    [Parameter(Mandatory = $false)]
    [string]$ImplementerOwner
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$scriptDir = Split-Path -Parent $PSCommandPath
. (Join-Path $scriptDir 'shared-governance.ps1')

$ProjectRoot = Resolve-ProjectPath -Path $ProjectRoot
if (-not [string]::IsNullOrWhiteSpace($IterationDirectory)) {
    $IterationDirectory = Resolve-ProjectPath -Path $IterationDirectory
}

function ConvertTo-BoolLike {
    param([AllowNull()]$Value)

    if ($null -eq $Value) {
        return $false
    }

    $text = ([string]$Value).Trim().Trim('"').Trim("'").ToLowerInvariant()
    return $text -in @('1', 'true', 'yes', 'on')
}

function Normalize-YamlValue {
    param([AllowNull()][string]$Value)

    if ($null -eq $Value) {
        return $null
    }

    $text = $Value.Trim()
    if ($text.Contains('#')) {
        $text = ($text -split '\s+#', 2)[0].Trim()
    }

    if (($text.StartsWith('"') -and $text.EndsWith('"')) -or ($text.StartsWith("'") -and $text.EndsWith("'"))) {
        $text = $text.Substring(1, $text.Length - 2)
    }

    if ($text -eq 'null') {
        return $null
    }

    return $text
}

function Get-IterationConfigPath {
    param([Parameter(Mandatory = $true)][string]$ProjectRoot)

    return Join-Path $ProjectRoot '.specrew\iteration-config.yml'
}

function Get-RoleAssignmentsPath {
    param([Parameter(Mandatory = $true)][string]$ProjectRoot)

    return Join-Path $ProjectRoot '.specrew\role-assignments.yml'
}

function Get-ReviewerRegressionSettings {
    param([Parameter(Mandatory = $true)][string]$ProjectRoot)

    $configPath = Get-IterationConfigPath -ProjectRoot $ProjectRoot
    $settings = [ordered]@{
        Enabled             = $true
        CleanPassesRequired = 1
        LockoutChainCap     = 2
        KnownTrapsEnabled   = $false
    }

    if (-not (Test-Path -LiteralPath $configPath -PathType Leaf)) {
        return [pscustomobject]$settings
    }

    $raw = Get-Content -LiteralPath $configPath -Raw -Encoding UTF8
    if ($raw -match '(?m)^\s*enabled:\s*(true|false)\s*$') {
        $settings.Enabled = ConvertTo-BoolLike $Matches[1]
    }
    if ($raw -match '(?m)^\s*clean_passes_required:\s*(\d+)\s*$') {
        $settings.CleanPassesRequired = [int]$Matches[1]
    }
    if ($raw -match '(?m)^\s*lockout_chain_cap:\s*(\d+)\s*$') {
        $settings.LockoutChainCap = [int]$Matches[1]
    }
    if ($raw -match '(?m)^\s*known_traps_integration:\s*(true|false)\s*$') {
        $settings.KnownTrapsEnabled = ConvertTo-BoolLike $Matches[1]
    }

    return [pscustomobject]$settings
}

function Get-ReviewerReasoningTiers {
    param([Parameter(Mandatory = $true)][string]$ProjectRoot)

    $configPath = Get-IterationConfigPath -ProjectRoot $ProjectRoot
    if (-not (Test-Path -LiteralPath $configPath -PathType Leaf)) {
        return @()
    }

    $lines = @(Get-Content -LiteralPath $configPath -Encoding UTF8)
    $tiers = New-Object System.Collections.Generic.List[object]
    $current = $null
    $section = $null
    $agentName = $null

    foreach ($line in $lines) {
        if ($line -match '^\s*reasoning_tiers:\s*$') {
            $section = 'reasoning_tiers'
            if ($null -ne $current) {
                $tiers.Add([pscustomobject]$current) | Out-Null
                $current = $null
            }
            continue
        }

        if ($line -match '^\s*agents:\s*$') {
            if ($null -ne $current -and $section -eq 'reasoning_tiers') {
                $tiers.Add([pscustomobject]$current) | Out-Null
            }
            $section = 'agents'
            $current = $null
            $agentName = $null
            continue
        }

        if ($section -eq 'reasoning_tiers') {
            if ($line -match '^\S' -and $line -notmatch '^\s*#') {
                if ($null -ne $current) {
                    $tiers.Add([pscustomobject]$current) | Out-Null
                }
                $current = $null
                $section = $null
            }
            elseif ($line -match '^\s*-\s+name:\s*(.+?)\s*$') {
                if ($null -ne $current) {
                    $tiers.Add([pscustomobject]$current) | Out-Null
                }
                $current = [ordered]@{
                    Name           = Normalize-YamlValue $Matches[1]
                    StrengthRank   = 0
                    ReviewerCapable = $true
                }
            }
            elseif ($null -ne $current -and $line -match '^\s+strength_rank:\s*(\d+)\s*$') {
                $current.StrengthRank = [int]$Matches[1]
            }
            elseif ($null -ne $current -and $line -match '^\s+reviewer_capable:\s*(true|false)\s*$') {
                $current.ReviewerCapable = ConvertTo-BoolLike $Matches[1]
            }
        }
        elseif ($section -eq 'agents') {
            if ($line -match '^\S' -and $line -notmatch '^\s*#') {
                if ($null -ne $current) {
                    $tiers.Add([pscustomobject]$current) | Out-Null
                }
                $current = $null
                $agentName = $null
                $section = $null
            }
            elseif ($line -match '^\s{2}([A-Za-z0-9_-]+):\s*$') {
                if ($null -ne $current) {
                    $tiers.Add([pscustomobject]$current) | Out-Null
                }
                $agentName = $Matches[1]
                $current = [ordered]@{
                    Name            = $agentName
                    StrengthRank    = 0
                    ReviewerCapable = $true
                    Enabled         = $false
                }
            }
            elseif ($null -ne $current -and $line -match '^\s{4}enabled:\s*(true|false)\s*$') {
                $current.Enabled = ConvertTo-BoolLike $Matches[1]
            }
            elseif ($null -ne $current -and $line -match '^\s{4}strength_rank:\s*(\d+)\s*$') {
                $current.StrengthRank = [int]$Matches[1]
            }
        }
    }

    if ($null -ne $current) {
        $tiers.Add([pscustomobject]$current) | Out-Null
    }

    $result = @($tiers.ToArray() | Where-Object {
            ($_ | Get-Member -Name Enabled -MemberType NoteProperty, AliasProperty, Property -ErrorAction SilentlyContinue) -eq $null -or
            $_.Enabled
        })
    return @($result | Sort-Object StrengthRank, Name)
}

function Get-ReviewerOwners {
    param([Parameter(Mandatory = $true)][string]$ProjectRoot)

    $assignmentsPath = Get-RoleAssignmentsPath -ProjectRoot $ProjectRoot
    if (-not (Test-Path -LiteralPath $assignmentsPath -PathType Leaf)) {
        return @()
    }

    $lines = @(Get-Content -LiteralPath $assignmentsPath -Encoding UTF8)
    $owners = New-Object System.Collections.Generic.List[object]
    $inRoles = $false
    $current = $null

    foreach ($line in $lines) {
        if ($line -match '^\s*roles:\s*$') {
            $inRoles = $true
            continue
        }

        if (-not $inRoles) {
            continue
        }

        if ($line -match '^\S' -and $line -notmatch '^\s*#') {
            if ($null -ne $current) {
                $owners.Add([pscustomobject]$current) | Out-Null
            }
            $current = $null
            $inRoles = $false
            continue
        }

        if ($line -match '^\s*-\s+(role|name):\s*(.+?)\s*$') {
            if ($null -ne $current) {
                $owners.Add([pscustomobject]$current) | Out-Null
            }
            $current = [ordered]@{
                RoleName       = Normalize-YamlValue $Matches[2]
                Owner          = $null
                ReasoningClass = $null
                Eligible       = $true
            }
            continue
        }

        if ($null -eq $current) {
            continue
        }

        if ($line -match '^\s+(role|name):\s*(.+?)\s*$') {
            $current.RoleName = Normalize-YamlValue $Matches[2]
        }
        elseif ($line -match '^\s+agent:\s*(.+?)\s*$') {
            $current.Owner = Normalize-YamlValue $Matches[1]
        }
        elseif ($line -match '^\s+assigned_to:\s*(.+?)\s*$') {
            $assignedTo = Normalize-YamlValue $Matches[1]
            if (-not [string]::IsNullOrWhiteSpace($assignedTo) -and $assignedTo -ne 'unassigned') {
                $current.Owner = $assignedTo
            }
        }
        elseif ($line -match '^\s+reasoning_class:\s*(.+?)\s*$') {
            $current.ReasoningClass = Normalize-YamlValue $Matches[1]
        }
        elseif ($line -match '^\s+preferred_agent:\s*(.+?)\s*$') {
            if ([string]::IsNullOrWhiteSpace($current.ReasoningClass)) {
                $current.ReasoningClass = Normalize-YamlValue $Matches[1]
            }
        }
        elseif ($line -match '^\s+eligible:\s*(true|false)\s*$') {
            $current.Eligible = ConvertTo-BoolLike $Matches[1]
        }
    }

    if ($null -ne $current) {
        $owners.Add([pscustomobject]$current) | Out-Null
    }

    return @($owners.ToArray() | Where-Object {
            $_.RoleName -eq 'Reviewer' -and
            $_.Eligible -and
            -not [string]::IsNullOrWhiteSpace($_.ReasoningClass)
        } | ForEach-Object {
            [pscustomobject]@{
                Owner          = if ([string]::IsNullOrWhiteSpace($_.Owner)) { $_.RoleName } else { $_.Owner }
                ReasoningClass = $_.ReasoningClass
            }
        })
}

function Get-ReviewerUsedOwners {
    param([Parameter(Mandatory = $true)][AllowEmptyCollection()][object[]]$Entries)

    $used = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
    foreach ($entry in @($Entries)) {
        $selectedReviewerOwner = $null
        if ($entry.RawText -match '(?m)^-\s+\*\*Selected Reviewer Owner\*\*:\s*`?(.+?)`?\s*$') {
            $selectedReviewerOwner = $Matches[1].Trim()
        }

        foreach ($value in @(
                $entry.PriorReviewerOwner,
                $entry.SameClassFallbackOwner,
                $entry.SelectedReviewerOwner,
                $selectedReviewerOwner
            )) {
            if (-not [string]::IsNullOrWhiteSpace([string]$value) -and $value -ne '(none)') {
                $null = $used.Add([string]$value)
            }
        }
    }

    return $used
}

function Get-TierRank {
    param(
        [Parameter(Mandatory = $true)][object[]]$Tiers,
        [Parameter(Mandatory = $true)][string]$TierName
    )

    $tier = @($Tiers | Where-Object { $_.Name -eq $TierName })[0]
    if ($null -eq $tier) {
        throw "Unknown reviewer reasoning class '$TierName'."
    }

    return [int]$tier.StrengthRank
}

function Select-ReviewerOwner {
    param(
        [Parameter(Mandatory = $true)][object[]]$Candidates,
        [Parameter(Mandatory = $true)][AllowEmptyCollection()][System.Collections.Generic.HashSet[string]]$UsedOwners,
        [string]$ExcludedOwner
    )

    $eligible = @($Candidates | Where-Object { $_.Owner -ne $ExcludedOwner })
    if ($eligible.Count -eq 0) {
        return $null
    }

    $unused = @($eligible | Where-Object { -not $UsedOwners.Contains($_.Owner) } | Sort-Object Owner)
    if ($unused.Count -gt 0) {
        return $unused[0]
    }

    return (@($eligible | Sort-Object Owner))[0]
}

function Resolve-ReviewerRouting {
    param(
        [Parameter(Mandatory = $true)][string]$ProjectRoot,
        [Parameter(Mandatory = $true)][string]$PriorReviewerClass,
        [Parameter(Mandatory = $true)][string]$PriorReviewerOwner,
        [Parameter(Mandatory = $true)][AllowEmptyCollection()][object[]]$ActiveEntries
    )

    $tiers = Get-ReviewerReasoningTiers -ProjectRoot $ProjectRoot
    $owners = Get-ReviewerOwners -ProjectRoot $ProjectRoot
    $usedOwners = Get-ReviewerUsedOwners -Entries $ActiveEntries
    if ($null -eq $usedOwners) {
        $usedOwners = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
    }
    $priorRank = Get-TierRank -Tiers $tiers -TierName $PriorReviewerClass

    $strongerTiers = @($tiers | Where-Object {
            $_.ReviewerCapable -and $_.StrengthRank -gt $priorRank
        } | Sort-Object StrengthRank, Name)

    foreach ($tier in $strongerTiers) {
        $candidates = @($owners | Where-Object { $_.ReasoningClass -eq $tier.Name })
        $selected = Select-ReviewerOwner -Candidates $candidates -UsedOwners $usedOwners -ExcludedOwner $PriorReviewerOwner
        if ($null -ne $selected) {
            return [pscustomobject]@{
                Status               = 'active'
                Action               = 'stronger-class'
                CurrentReviewerClass = $tier.Name
                CurrentReviewerOwner = $selected.Owner
                EscalatedToClass     = $tier.Name
                SameClassOwner       = $null
                Notes                = "Review rerouted to stronger reviewer class $($tier.Name) via $($selected.Owner)."
            }
        }
    }

    $sameClassCandidates = @($owners | Where-Object { $_.ReasoningClass -eq $PriorReviewerClass })
    $sameClassSelection = Select-ReviewerOwner -Candidates $sameClassCandidates -UsedOwners $usedOwners -ExcludedOwner $PriorReviewerOwner
    if ($null -ne $sameClassSelection) {
        return [pscustomobject]@{
            Status               = 'active'
            Action               = 'same-class-independent-owner'
            CurrentReviewerClass = $PriorReviewerClass
            CurrentReviewerOwner = $sameClassSelection.Owner
            EscalatedToClass     = $null
            SameClassOwner       = $sameClassSelection.Owner
            Notes                = "Review rerouted to independent reviewer owner $($sameClassSelection.Owner) at class $PriorReviewerClass."
        }
    }

    return [pscustomobject]@{
        Status               = 'held'
        Action               = 'human-direction-hold'
        CurrentReviewerClass = $PriorReviewerClass
        CurrentReviewerOwner = $null
        EscalatedToClass     = $PriorReviewerClass
        SameClassOwner       = $null
        Notes                = 'Awaiting explicit human direction before review continues.'
    }
}

function Get-NextReviewerRegressionEventId {
    param([Parameter(Mandatory = $true)][string]$ProjectRoot)

    $entries = Get-ReviewerRegressionLedgerEntries -ProjectRoot $ProjectRoot
    $nextNumber = 1
    if (@($entries).Count -gt 0) {
        $numbers = @($entries | ForEach-Object {
                if ($_.EventId -match '^RRE-(\d+)$') { [int]$Matches[1] }
            } | Where-Object { $null -ne $_ })
        if ($numbers.Count -gt 0) {
            $nextNumber = ($numbers | Measure-Object -Maximum).Maximum + 1
        }
    }

    return ('RRE-' + ([int]$nextNumber).ToString('000'))
}

function Initialize-ReviewerRegressionLedger {
    param([Parameter(Mandatory = $true)][string]$ProjectRoot)

    $ledgerPath = Get-ReviewerRegressionLedgerPath -ProjectRoot $ProjectRoot
    if (Test-Path -LiteralPath $ledgerPath -PathType Leaf) {
        return $ledgerPath
    }

    $now = (Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ')
    $content = @"
# Reviewer Regression Ledger

**Schema**: v1.0.0  
**Created**: $now  
**Source of Truth**: This append-only ledger is the authoritative record of all reviewer-regression events reported across all features and iterations in this repository.

## Purpose

This ledger records every concrete defect a human reports in a slice that a Squad reviewer previously approved or marked ready.

## Event Records

*No reviewer-regression events have been recorded yet.*

---

## Ledger Statistics

- **Total Events**: 0
- **Active Events**: 0
- **Resolved Events**: 0
- **Withdrawn Events**: 0
- **Strongest Escalation Ever Reached**: (none)
- **Last Updated**: $now
"@
    Write-Utf8FileAtomic -Path $ledgerPath -Content $content
    return $ledgerPath
}

function Update-ReviewerRegressionLedgerStatistics {
    param([Parameter(Mandatory = $true)][string]$ProjectRoot)

    $ledgerPath = Get-ReviewerRegressionLedgerPath -ProjectRoot $ProjectRoot
    if (-not (Test-Path -LiteralPath $ledgerPath -PathType Leaf)) {
        return
    }

    $entries = @(Get-ReviewerRegressionLedgerEntries -ProjectRoot $ProjectRoot)
    $lastUpdated = (Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ')
    $activeCount = @($entries | Where-Object { $_.EventStatus -eq 'active' }).Count
    $resolvedCount = @($entries | Where-Object { $_.EventStatus -eq 'resolved' }).Count
    $withdrawnCount = @($entries | Where-Object { $_.EventStatus -eq 'withdrawn' }).Count
    $priority = @{
        'none-yet'                    = 0
        'same-class-independent-owner' = 1
        'stronger-class'              = 2
        'human-direction-hold'        = 3
    }
    $strongest = '(none)'
    if ($entries.Count -gt 0) {
        $strongestEntry = @(
            $entries |
                Sort-Object `
                    @{ Expression = { $priority[[string]$_.EscalationAction] }; Descending = $true }, `
                    @{ Expression = { [string]$_.RecordedAt }; Descending = $true } |
                Select-Object -First 1
        )[0]
        $strongest = if ([string]::IsNullOrWhiteSpace([string]$strongestEntry.EscalationAction)) { '(none)' } else { $strongestEntry.EscalationAction }
    }

    Update-LockedFileContent -Path $ledgerPath -Transform {
        param($currentContent)

        $updated = $currentContent
        $replacements = [ordered]@{
            '(?m)^- \*\*Total Events\*\*: .+$'                     = "- **Total Events**: $($entries.Count)"
            '(?m)^- \*\*Active Events\*\*: .+$'                    = "- **Active Events**: $activeCount"
            '(?m)^- \*\*Resolved Events\*\*: .+$'                  = "- **Resolved Events**: $resolvedCount"
            '(?m)^- \*\*Withdrawn Events\*\*: .+$'                 = "- **Withdrawn Events**: $withdrawnCount"
            '(?m)^- \*\*Strongest Escalation Ever Reached\*\*: .+$' = "- **Strongest Escalation Ever Reached**: $strongest"
            '(?m)^- \*\*Last Updated\*\*: .+$'                     = "- **Last Updated**: $lastUpdated"
        }

        foreach ($pattern in $replacements.Keys) {
            if ($updated -match $pattern) {
                $updated = [regex]::Replace($updated, $pattern, $replacements[$pattern])
            }
        }

        return $updated
    } | Out-Null
}

function Add-ReviewerRegressionLedgerEntry {
    param(
        [Parameter(Mandatory = $true)][string]$ProjectRoot,
        [Parameter(Mandatory = $true)][hashtable]$Entry
    )

    $ledgerPath = Initialize-ReviewerRegressionLedger -ProjectRoot $ProjectRoot
    $markdownValue = {
        param([AllowNull()][string]$Value)

        if ([string]::IsNullOrWhiteSpace($Value)) {
            return '(none)'
        }

        return ('`{0}`' -f $Value)
    }

    $eventText = @(
        "### $($Entry.EventId)"
        ''
        "- **Feature**: $(& $markdownValue $Entry.Feature)"
        "- **Iteration**: $(& $markdownValue $Entry.Iteration)"
        "- **Slice**: $(& $markdownValue $Entry.Slice)"
        "- **Prior Reviewer Verdict**: $(& $markdownValue $Entry.PriorReviewerVerdict)"
        "- **Prior Reviewer Class**: $(& $markdownValue $Entry.PriorReviewerClass)"
        "- **Prior Reviewer Owner**: $(& $markdownValue $Entry.PriorReviewerOwner)"
        "- **Defect Description**: $(& $markdownValue $Entry.DefectDescription)"
        "- **Defect Source Location**: $(& $markdownValue $Entry.DefectSourceLocation)"
        "- **Event Status**: $(& $markdownValue $Entry.EventStatus)"
        "- **Severity**: $(& $markdownValue $Entry.Severity)"
        "- **Escalation Action**: $(& $markdownValue $Entry.EscalationAction)"
        "- **Escalated To Class**: $(& $markdownValue $Entry.EscalatedToClass)"
        "- **Selected Reviewer Owner**: $(& $markdownValue $Entry.SelectedReviewerOwner)"
        "- **Same-Class Fallback Owner**: $(& $markdownValue $Entry.SameClassFallbackOwner)"
        "- **Carry Forward Iteration**: $(& $markdownValue $Entry.CarryForwardIteration)"
        "- **Candidate Trap Status**: $(& $markdownValue $Entry.CandidateTrapStatus)"
        "- **Withdrawal Reference**: $(& $markdownValue $Entry.WithdrawalReference)"
        "- **De-Escalation Outcome**: $(& $markdownValue $Entry.DeEscalationOutcome)"
        "- **Recorded At**: $(& $markdownValue $Entry.RecordedAt)"
        ''
    ) -join [Environment]::NewLine

    Update-LockedFileContent -Path $ledgerPath -Transform {
        param($currentContent)

        $updated = $currentContent
        if ($updated -match '(?m)^\*No reviewer-regression events have been recorded yet\.\*$') {
            $updated = [regex]::Replace($updated, '(?m)^\*No reviewer-regression events have been recorded yet\.\*$', [System.Text.RegularExpressions.MatchEvaluator]{ param($m) $eventText.TrimEnd() })
        }
        elseif ($updated -match '(?m)^## Ledger Statistics\s*$') {
            $updated = [regex]::Replace($updated, '(?m)^## Ledger Statistics\s*$', [System.Text.RegularExpressions.MatchEvaluator]{ param($m) ($eventText + [Environment]::NewLine + '## Ledger Statistics') })
        }
        else {
            $updated = $updated.TrimEnd() + [Environment]::NewLine + [Environment]::NewLine + $eventText.TrimEnd() + [Environment]::NewLine
        }

        return $updated
    } | Out-Null

    Update-ReviewerRegressionLedgerStatistics -ProjectRoot $ProjectRoot
    return $ledgerPath
}

function Find-DuplicateReviewerRegressionEvent {
    param(
        [Parameter(Mandatory = $true)][string]$ProjectRoot,
        [Parameter(Mandatory = $true)][string]$Feature,
        [Parameter(Mandatory = $true)][string]$Slice,
        [Parameter(Mandatory = $true)][string]$DefectDescription,
        [Parameter(Mandatory = $true)][string]$DefectSourceLocation
    )

    return Get-ReviewerRegressionLedgerEntries -ProjectRoot $ProjectRoot |
        Where-Object {
            $_.Feature -eq $Feature -and
            $_.EventStatus -eq 'active' -and
            $_.Slice -eq $Slice -and
            $_.DefectDescription -eq $DefectDescription -and
            $_.DefectSourceLocation -eq $DefectSourceLocation
        } |
        Select-Object -First 1
}

function Get-ImplementerChainFromConfig {
    <#
    .SYNOPSIS
    Reads the implementer chain for a feature from .squad/config.json.
    #>
    param(
        [Parameter(Mandatory = $true)][string]$ProjectRoot,
        [Parameter(Mandatory = $true)][string]$Feature
    )

    $configPath = Join-Path $ProjectRoot '.squad\config.json'
    if (-not (Test-Path -LiteralPath $configPath -PathType Leaf)) {
        return @()
    }

    try {
        $config = Get-Content -LiteralPath $configPath -Raw -Encoding UTF8 | ConvertFrom-Json
        $featureKey = $Feature -replace '[/\\]', '_'
        
        if ($null -eq $config.reviewerRegressionState) {
            return @()
        }

        $featureState = $config.reviewerRegressionState.PSObject.Properties |
            Where-Object { $_.Name -eq $featureKey } |
            Select-Object -First 1

        if ($null -eq $featureState -or $null -eq $featureState.Value.implementerChain) {
            return @()
        }

        return @($featureState.Value.implementerChain)
    }
    catch {
        return @()
    }
}

function Update-ImplementerChainInConfig {
    <#
    .SYNOPSIS
    Updates the implementer chain for a feature in .squad/config.json.
    #>
    param(
        [Parameter(Mandatory = $true)][string]$ProjectRoot,
        [Parameter(Mandatory = $true)][string]$Feature,
        [Parameter(Mandatory = $true)][string]$ImplementerOwner
    )

    $configPath = Join-Path $ProjectRoot '.squad\config.json'
    $featureKey = $Feature -replace '[/\\]', '_'

    Update-LockedFileContent -Path $configPath -Transform {
        param($currentContent)

        $config = if ([string]::IsNullOrWhiteSpace($currentContent)) {
            [pscustomobject]@{
                version = '1.0'
                reviewerRegressionState = [pscustomobject]@{}
            }
        }
        else {
            $currentContent | ConvertFrom-Json
        }

        if ($null -eq $config.reviewerRegressionState) {
            $config | Add-Member -MemberType NoteProperty -Name 'reviewerRegressionState' -Value ([pscustomobject]@{})
        }

        $featureState = $config.reviewerRegressionState.PSObject.Properties |
            Where-Object { $_.Name -eq $featureKey } |
            Select-Object -First 1

        if ($null -eq $featureState) {
            $config.reviewerRegressionState | Add-Member -MemberType NoteProperty -Name $featureKey -Value ([pscustomobject]@{
                status = 'active'
                implementerChain = @($ImplementerOwner)
                lockoutChainLength = 1
                capActive = $false
            })
        }
        else {
            $chain = @($featureState.Value.implementerChain)
            if ($ImplementerOwner -notin $chain) {
                $chain += $ImplementerOwner
                $featureState.Value.implementerChain = $chain
                $featureState.Value.lockoutChainLength = $chain.Count
            }
        }

        return ($config | ConvertTo-Json -Depth 10)
    } | Out-Null
}

function Get-LockoutCapStatus {
    <#
    .SYNOPSIS
    Determines if the lockout-chain cap is active for a feature.
    #>
    param(
        [Parameter(Mandatory = $true)][string]$ProjectRoot,
        [Parameter(Mandatory = $true)][string]$Feature,
        [Parameter(Mandatory = $true)][int]$LockoutChainCap
    )

    $chain = @(Get-ImplementerChainFromConfig -ProjectRoot $ProjectRoot -Feature $Feature)
    $chainLength = $chain.Count
    $capThreshold = 1 + $LockoutChainCap  # original + cap rotations
    $capActive = $chainLength -ge $capThreshold

    return [pscustomobject]@{
        ImplementerChain = $chain
        ChainLength = $chainLength
        CapThreshold = $capThreshold
        CapActive = $capActive
    }
}

function Get-IterationReference {
    param([string]$IterationDirectory)

    if ([string]::IsNullOrWhiteSpace($IterationDirectory)) {
        return $null
    }

    return Split-Path -Leaf $IterationDirectory
}

function Get-FeatureReferenceFromIterationDirectory {
    param([string]$ProjectRoot, [string]$IterationDirectory)

    if ([string]::IsNullOrWhiteSpace($IterationDirectory)) {
        return $null
    }

    $normalizedProject = [System.IO.Path]::GetFullPath($ProjectRoot)
    $normalizedIteration = [System.IO.Path]::GetFullPath($IterationDirectory)
    $relative = [System.IO.Path]::GetRelativePath($normalizedProject, $normalizedIteration)
    $relative = $relative -replace '\\', '/'
    if ($relative -match '^(specs/[^/]+)/iterations/[^/]+$') {
        return $Matches[1]
    }

    return $null
}

function Get-ReviewerRegressionReadback {
    param(
        [Parameter(Mandatory = $true)][string]$ProjectRoot,
        [Parameter(Mandatory = $true)][string]$Feature
    )

    $settings = Get-ReviewerRegressionSettings -ProjectRoot $ProjectRoot
    $chain = Get-ActiveReviewerRegressionChain -ProjectRoot $ProjectRoot -Feature $Feature
    $entries = @(
        Get-ReviewerRegressionLedgerEntries -ProjectRoot $ProjectRoot |
            Where-Object { $_.Feature -eq $Feature -and $_.EventStatus -eq 'active' }
    )

    $currentOwner = $chain.CurrentReviewerOwner
    if ([string]::IsNullOrWhiteSpace([string]$currentOwner)) {
        $selectedOwner = $entries |
            Where-Object { -not [string]::IsNullOrWhiteSpace([string]$_.SelectedReviewerOwner) } |
            Select-Object -Last 1
        if ($null -ne $selectedOwner) {
            $currentOwner = $selectedOwner.SelectedReviewerOwner
        }
    }

    $notes = switch ([string]$chain.StrongestUnresolvedAction) {
        'human-direction-hold' { 'Awaiting explicit human direction before review continues.'; break }
        'same-class-independent-owner' {
            if ([string]::IsNullOrWhiteSpace([string]$currentOwner)) {
                "Review rerouted to an independent reviewer owner at class $($chain.CurrentReviewerClass)."
            }
            else {
                "Review rerouted to independent reviewer owner $currentOwner at class $($chain.CurrentReviewerClass)."
            }
            break
        }
        'stronger-class' {
            if ([string]::IsNullOrWhiteSpace([string]$currentOwner)) {
                "Review rerouted to stronger reviewer class $($chain.CurrentReviewerClass)."
            }
            else {
                "Review rerouted to stronger reviewer class $($chain.CurrentReviewerClass) via $currentOwner."
            }
            break
        }
        default { $null }
    }

    $lastEvent = $entries | Sort-Object RecordedAt | Select-Object -Last 1

    $capStatus = Get-LockoutCapStatus -ProjectRoot $ProjectRoot -Feature $Feature -LockoutChainCap $settings.LockoutChainCap
    $capNotes = if ($capStatus.CapActive) {
        "Lockout-chain cap active ($($capStatus.ChainLength) implementers = original + $($settings.LockoutChainCap) rotations). Further rotation blocked. Human-owned revision or approved alternate owner required per FR-010."
    }
    else {
        $null
    }

    $combinedNotes = if ($notes -and $capNotes) {
        "$notes $capNotes"
    }
    elseif ($capNotes) {
        $capNotes
    }
    else {
        $notes
    }

    $lockedOutAgents = if ($capStatus.CapActive) {
        @('Standard implementer rotation pool (original + 2 rotations exhausted)')
    }
    else {
        @()
    }

    $nextOwnerPath = if ($capStatus.CapActive) {
        'Awaiting human-owned revision or explicitly approved alternate owner recorded in `.squad/decisions.md`'
    }
    else {
        $null
    }

    $finalNotes = if ($combinedNotes -and $nextOwnerPath) {
        "$combinedNotes Next Owner Path: $nextOwnerPath"
    }
    elseif ($nextOwnerPath) {
        "Next Owner Path: $nextOwnerPath"
    }
    else {
        $combinedNotes
    }

    return [pscustomobject]@{
        Status                    = $chain.Status
        Feature                   = $Feature
        ActiveEventIds            = @($chain.ActiveEventIds)
        StrongestUnresolvedAction = $chain.StrongestUnresolvedAction
        CurrentReviewerClass      = $chain.CurrentReviewerClass
        PriorReviewerClass        = $chain.PriorReviewerClass
        CurrentReviewerOwner      = $currentOwner
        CleanPassesRequired       = $settings.CleanPassesRequired
        CleanPassesObserved       = $chain.CleanPassesObserved
        LockoutCap                = $settings.LockoutChainCap
        LockoutChainLength        = $capStatus.ChainLength
        ImplementerChain          = $capStatus.ImplementerChain
        CapActive                 = $capStatus.CapActive
        LockedOutAgents           = $lockedOutAgents
        NextOwnerPath             = $nextOwnerPath
        CarryForwardFromIteration = $chain.CarryForwardFromIteration
        LastEvent                 = if ($null -ne $lastEvent) { $lastEvent.RecordedAt } else { $null }
        Notes                     = $finalNotes
    }
}

function Set-ReviewerRegressionStateBlock {
    param(
        [Parameter(Mandatory = $true)][string]$IterationDirectory,
        [Parameter(Mandatory = $true)][object]$Chain
    )

    $statePath = Join-Path $IterationDirectory 'state.md'
    if (-not (Test-Path -LiteralPath $statePath -PathType Leaf)) {
        throw "Missing iteration state file: $statePath"
    }

    $blockLines = @(
        '<!-- >>> specrew-managed reviewer-regression-state >>> -->'
        '## Reviewer Regression State'
        ''
        "- **Status**: $(if ([string]::IsNullOrWhiteSpace([string]$Chain.Status)) { 'inactive' } else { $Chain.Status })"
        "- **Feature**: $(if ([string]::IsNullOrWhiteSpace([string]$Chain.Feature)) { '(none)' } else { $Chain.Feature })"
        "- **Active Event IDs**: $(if (@($Chain.ActiveEventIds).Count -gt 0) { (@($Chain.ActiveEventIds) -join ', ') } else { '(none)' })"
        "- **Prior Reviewer Class**: $(if ([string]::IsNullOrWhiteSpace([string]$Chain.PriorReviewerClass)) { '(none)' } else { $Chain.PriorReviewerClass })"
        "- **Current Reviewer Class**: $(if ([string]::IsNullOrWhiteSpace([string]$Chain.CurrentReviewerClass)) { '(none)' } else { $Chain.CurrentReviewerClass })"
        "- **Current Reviewer Owner**: $(if ([string]::IsNullOrWhiteSpace([string]$Chain.CurrentReviewerOwner)) { '(none)' } else { $Chain.CurrentReviewerOwner })"
        "- **Lockout Chain Length**: $([int]$Chain.LockoutChainLength)"
        "- **Lockout Cap**: $([int]$Chain.LockoutCap)"
        "- **Cap Active**: $([string]([bool]$Chain.CapActive).ToString().ToLowerInvariant())"
        "- **Locked Out Agents**: $(if (@($Chain.LockedOutAgents).Count -gt 0) { (@($Chain.LockedOutAgents) -join ', ') } else { '(none)' })"
        "- **Carry Forward From Iteration**: $(if ([string]::IsNullOrWhiteSpace([string]$Chain.CarryForwardFromIteration)) { '(none)' } else { $Chain.CarryForwardFromIteration })"
        "- **Last Event**: $(if ([string]::IsNullOrWhiteSpace([string]$Chain.LastEvent)) { '(none)' } else { $Chain.LastEvent })"
        "- **Notes**: $(if ([string]::IsNullOrWhiteSpace([string]$Chain.Notes)) { '(none)' } else { $Chain.Notes })"
        '<!-- <<< specrew-managed reviewer-regression-state <<< -->'
    )
    $blockText = $blockLines -join [Environment]::NewLine

    Update-LockedFileContent -Path $statePath -Transform {
        param($currentContent)

        if ($currentContent -match '(?s)<!-- >>> specrew-managed reviewer-regression-state >>> -->.*?<!-- <<< specrew-managed reviewer-regression-state <<< -->') {
            return [regex]::Replace(
                $currentContent,
                '(?s)<!-- >>> specrew-managed reviewer-regression-state >>> -->.*?<!-- <<< specrew-managed reviewer-regression-state <<< -->',
                [System.Text.RegularExpressions.MatchEvaluator]{ param($m) $blockText }
            )
        }

        if ($currentContent -match '(?m)^## Task Status\s*$') {
            return [regex]::Replace(
                $currentContent,
                '(?m)^## Task Status\s*$',
                [System.Text.RegularExpressions.MatchEvaluator]{ param($m) ($blockText + [Environment]::NewLine + [Environment]::NewLine + '## Task Status') }
            )
        }

        return $currentContent.TrimEnd() + [Environment]::NewLine + [Environment]::NewLine + $blockText + [Environment]::NewLine
    } | Out-Null

    return $statePath
}

function Require-ParameterValue {
    param(
        [Parameter(Mandatory = $true)][string]$Name,
        [AllowNull()][string]$Value
    )

    if ([string]::IsNullOrWhiteSpace($Value)) {
        throw "Parameter -$Name is required for '$Mode' mode."
    }
}

switch ($Mode) {
    'get' {
        if ([string]::IsNullOrWhiteSpace($Feature) -and -not [string]::IsNullOrWhiteSpace($IterationDirectory)) {
            $Feature = Get-FeatureReferenceFromIterationDirectory -ProjectRoot $ProjectRoot -IterationDirectory $IterationDirectory
        }
        Require-ParameterValue -Name 'Feature' -Value $Feature

        Get-ReviewerRegressionReadback -ProjectRoot $ProjectRoot -Feature $Feature | ConvertTo-Json -Depth 8
        break
    }
    'project' {
        if ([string]::IsNullOrWhiteSpace($Feature) -and -not [string]::IsNullOrWhiteSpace($IterationDirectory)) {
            $Feature = Get-FeatureReferenceFromIterationDirectory -ProjectRoot $ProjectRoot -IterationDirectory $IterationDirectory
        }
        Require-ParameterValue -Name 'Feature' -Value $Feature
        Require-ParameterValue -Name 'IterationDirectory' -Value $IterationDirectory

        $chain = Get-ReviewerRegressionReadback -ProjectRoot $ProjectRoot -Feature $Feature
        $null = Set-ReviewerRegressionStateBlock -IterationDirectory $IterationDirectory -Chain $chain
        $chain | ConvertTo-Json -Depth 8
        break
    }
    'report' {
        foreach ($required in @(
                'Feature',
                'IterationDirectory',
                'Slice',
                'PriorReviewerVerdict',
                'PriorReviewerClass',
                'PriorReviewerOwner',
                'DefectDescription',
                'DefectSourceLocation'
            )) {
            Require-ParameterValue -Name $required -Value (Get-Variable -Name $required -ValueOnly)
        }

        $existing = Find-DuplicateReviewerRegressionEvent -ProjectRoot $ProjectRoot -Feature $Feature -Slice $Slice -DefectDescription $DefectDescription -DefectSourceLocation $DefectSourceLocation
        if ($null -ne $existing) {
            $chain = Get-ReviewerRegressionReadback -ProjectRoot $ProjectRoot -Feature $Feature
            $null = Set-ReviewerRegressionStateBlock -IterationDirectory $IterationDirectory -Chain $chain
            [pscustomobject]@{
                EventId    = $existing.EventId
                Duplicate  = $true
                Routing    = [pscustomobject]@{
                    Status               = $chain.Status
                    Action               = $chain.StrongestUnresolvedAction
                    CurrentReviewerClass = $chain.CurrentReviewerClass
                    CurrentReviewerOwner = $chain.CurrentReviewerOwner
                    Notes                = $chain.Notes
                }
                Chain      = $chain
                LedgerPath = Get-ReviewerRegressionLedgerPath -ProjectRoot $ProjectRoot
            } | ConvertTo-Json -Depth 8
            break
        }

        $activeEntries = @(
            Get-ReviewerRegressionLedgerEntries -ProjectRoot $ProjectRoot |
                Where-Object { $_.Feature -eq $Feature -and $_.EventStatus -eq 'active' }
        )
        $routing = Resolve-ReviewerRouting -ProjectRoot $ProjectRoot -PriorReviewerClass $PriorReviewerClass -PriorReviewerOwner $PriorReviewerOwner -ActiveEntries $activeEntries
        $recordedAt = (Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ')
        $newEventId = Get-NextReviewerRegressionEventId -ProjectRoot $ProjectRoot
        $entry = [ordered]@{
            EventId                = $newEventId
            Feature                = $Feature
            Iteration              = Get-IterationReference -IterationDirectory $IterationDirectory
            Slice                  = $Slice
            PriorReviewerVerdict   = $PriorReviewerVerdict
            PriorReviewerClass     = $PriorReviewerClass
            PriorReviewerOwner     = $PriorReviewerOwner
            DefectDescription      = $DefectDescription
            DefectSourceLocation   = $DefectSourceLocation
            EventStatus            = 'active'
            Severity               = 'soft-warning'
            EscalationAction       = $routing.Action
            EscalatedToClass       = $routing.EscalatedToClass
            SelectedReviewerOwner  = $routing.CurrentReviewerOwner
            SameClassFallbackOwner = $routing.SameClassOwner
            CarryForwardIteration  = $null
            CandidateTrapStatus    = 'not-applicable'
            WithdrawalReference    = $null
            DeEscalationOutcome    = $null
            RecordedAt             = $recordedAt
        }

        # T026: FR-014 - Detect closed iterations and mark carry-forward
        $iterationStatePath = Join-Path $IterationDirectory 'state.md'
        if (Test-Path -LiteralPath $iterationStatePath -PathType Leaf) {
            $stateContent = Get-Content -LiteralPath $iterationStatePath -Raw -Encoding UTF8
            $isClosedPattern = '\*\*Status\*\*:\s+(complete|closed)'
            if ($stateContent -match $isClosedPattern) {
                # Iteration is closed; find next iteration number
                $currentIterNum = [regex]::Match((Get-IterationReference -IterationDirectory $IterationDirectory), '\d+').Value
                if (-not [string]::IsNullOrWhiteSpace($currentIterNum)) {
                    $nextIterNum = ([int]$currentIterNum + 1).ToString('000')
                    $entry.CarryForwardIteration = "iteration $nextIterNum"
                }
            }
        }

        # T025: FR-012 - Conditional candidate-trap proposal when corpus is enabled
        $settings = Get-ReviewerRegressionSettings -ProjectRoot $ProjectRoot
        $candidateTrapProposed = $false
        if ($settings.KnownTrapsEnabled) {
            $knownTrapsPath = Join-Path $ProjectRoot '.specrew\quality\known-traps.md'
            $knownTrapsDir = Split-Path -Parent $knownTrapsPath
            if (-not (Test-Path -LiteralPath $knownTrapsDir -PathType Container)) {
                $null = New-Item -ItemType Directory -Path $knownTrapsDir -Force
            }
            
            if (-not (Test-Path -LiteralPath $knownTrapsPath -PathType Leaf)) {
                # Initialize known-traps file if it doesn't exist
                [System.IO.File]::WriteAllText($knownTrapsPath, @"
# Known Traps

**Schema**: v1  
**Last Updated**: $(Get-Date -Format 'yyyy-MM-dd')

## Trap Catalog

<!-- Approved traps and candidate traps are recorded below -->

"@, [System.Text.UTF8Encoding]::new($false))
            }
            
            # Propose candidate trap
            $candidateTrapEntry = @"

<!-- candidate-trap-from-event: $newEventId -->
## Candidate Trap (unapproved): $newEventId

- **Source Event**: $newEventId
- **Feature**: $Feature
- **Defect Description**: $DefectDescription
- **Defect Source Location**: $DefectSourceLocation
- **Pattern**: _(Awaiting human review and pattern extraction)_
- **Detection**: _(Awaiting lens or mechanical check definition)_
- **Status**: candidate

**Review Notes**: This candidate trap was automatically proposed from reviewer-regression event $newEventId. A human reviewer should extract the defect pattern, define detection logic, and approve or reject this trap entry.

<!-- end-candidate-trap -->
"@
            
            Update-LockedFileContent -Path $knownTrapsPath -Transform {
                param($currentContent)
                
                # Append candidate trap before the final empty line or at end
                $updated = $currentContent.TrimEnd() + [Environment]::NewLine + $candidateTrapEntry.TrimEnd() + [Environment]::NewLine
                return $updated
            } | Out-Null
            
            $candidateTrapProposed = $true
            $entry.CandidateTrapStatus = 'proposed-awaiting-approval'
        }

        $ledgerPath = Add-ReviewerRegressionLedgerEntry -ProjectRoot $ProjectRoot -Entry $entry

        # Track implementer owner and check for cap activation (T017: FR-009, FR-010)
        $capActivatedNow = $false
        if (-not [string]::IsNullOrWhiteSpace($ImplementerOwner)) {
            $capStatusBefore = Get-LockoutCapStatus -ProjectRoot $ProjectRoot -Feature $Feature -LockoutChainCap (Get-ReviewerRegressionSettings -ProjectRoot $ProjectRoot).LockoutChainCap
            Update-ImplementerChainInConfig -ProjectRoot $ProjectRoot -Feature $Feature -ImplementerOwner $ImplementerOwner
            $capStatusAfter = Get-LockoutCapStatus -ProjectRoot $ProjectRoot -Feature $Feature -LockoutChainCap (Get-ReviewerRegressionSettings -ProjectRoot $ProjectRoot).LockoutChainCap
            
            if (-not $capStatusBefore.CapActive -and $capStatusAfter.CapActive) {
                $capActivatedNow = $true
            }
        }

        # Record cap activation decision (T018: FR-010, FR-011)
        $capDecisionPath = $null
        if ($capActivatedNow) {
            $capChain = @(Get-ImplementerChainFromConfig -ProjectRoot $ProjectRoot -Feature $Feature)
            $capDecisionPath = Add-StructuredDecisionsLedgerEntry -ProjectRoot $ProjectRoot -Title "Lockout-chain cap activated for $Feature" -Type 'lockout-cap' -AffectedRequirement 'FR-009, FR-010, FR-011' -AffectedIteration (Get-IterationReference -IterationDirectory $IterationDirectory) -NextAction 'awaiting-human-owned-revision-or-approved-alternate' -Rationale "Implementer lockout-chain reached the configured cap ($(Get-ReviewerRegressionSettings -ProjectRoot $ProjectRoot).LockoutChainCap rotations beyond original implementer). Cap is now active." -DetailLines @(
                "- **Feature**: $Feature"
                "- **Implementer Chain**: $($capChain -join ' → ')"
                "- **Chain Length**: $($capChain.Count)"
                "- **Cap Threshold**: $(1 + (Get-ReviewerRegressionSettings -ProjectRoot $ProjectRoot).LockoutChainCap) (original + cap rotations)"
                "- **Cap State**: active"
                "- **Next Owner Path**: Awaiting human-owned revision or approved alternate owner recorded in ``.squad/decisions.md``"
            )
        }

        $decisionPath = Add-StructuredDecisionsLedgerEntry -ProjectRoot $ProjectRoot -Title "Reviewer regression $newEventId" -Type 'reviewer-regression-escalation' -AffectedRequirement 'FR-001, FR-002, FR-003, FR-004, FR-015' -AffectedIteration (Get-IterationReference -IterationDirectory $IterationDirectory) -NextAction 'continue-review-routing' -Rationale $routing.Notes -DetailLines @(
            "- **Event ID**: $newEventId"
            "- **Feature**: $Feature"
            "- **Routing Outcome**: $($routing.Action)"
            "- **Selected Reviewer Class**: $(if ([string]::IsNullOrWhiteSpace([string]$routing.CurrentReviewerClass)) { '(none)' } else { $routing.CurrentReviewerClass })"
            "- **Selected Reviewer Owner**: $(if ([string]::IsNullOrWhiteSpace([string]$routing.CurrentReviewerOwner)) { '(none)' } else { $routing.CurrentReviewerOwner })"
            "- **Hold Active**: $([string]($routing.Status -eq 'held').ToString().ToLowerInvariant())"
        )

        $chain = Get-ReviewerRegressionReadback -ProjectRoot $ProjectRoot -Feature $Feature
        $null = Set-ReviewerRegressionStateBlock -IterationDirectory $IterationDirectory -Chain $chain

        [pscustomobject]@{
            EventId               = $newEventId
            Duplicate             = $false
            Routing               = [pscustomobject]@{
                Status               = $routing.Status
                Action               = $routing.Action
                CurrentReviewerClass = $routing.CurrentReviewerClass
                CurrentReviewerOwner = $routing.CurrentReviewerOwner
                Notes                = $routing.Notes
            }
            Chain                 = $chain
            LedgerPath            = $ledgerPath
            DecisionPath          = $decisionPath
            CapActivated          = $capActivatedNow
            CapDecisionPath       = $capDecisionPath
            CandidateTrapProposed = $candidateTrapProposed
            CarryForwardIteration = $entry.CarryForwardIteration
        } | ConvertTo-Json -Depth 8
        break
    }
    'resolve' {
        # T024: FR-005 clean-pass de-escalation
        if ([string]::IsNullOrWhiteSpace($Feature) -and -not [string]::IsNullOrWhiteSpace($IterationDirectory)) {
            $Feature = Get-FeatureReferenceFromIterationDirectory -ProjectRoot $ProjectRoot -IterationDirectory $IterationDirectory
        }
        Require-ParameterValue -Name 'Feature' -Value $Feature
        Require-ParameterValue -Name 'IterationDirectory' -Value $IterationDirectory

        $activeEntries = @(
            Get-ReviewerRegressionLedgerEntries -ProjectRoot $ProjectRoot |
                Where-Object { $_.Feature -eq $Feature -and $_.EventStatus -eq 'active' }
        )

        if ($activeEntries.Count -eq 0) {
            # No active events to resolve
            $chain = Get-ReviewerRegressionReadback -ProjectRoot $ProjectRoot -Feature $Feature
            [pscustomobject]@{
                Resolved     = $false
                EventIds     = @()
                Message      = "No active reviewer-regression events for feature $Feature"
                Chain        = $chain
            } | ConvertTo-Json -Depth 8
            break
        }

        # Mark all active events as resolved in ledger
        $ledgerPath = Get-ReviewerRegressionLedgerPath -ProjectRoot $ProjectRoot
        $resolvedAt = (Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ')
        
        Update-LockedFileContent -Path $ledgerPath -Transform {
            param($currentContent)
            
            $updated = $currentContent
            foreach ($entry in $activeEntries) {
                # Update EventStatus to resolved
                $pattern = "(?ms)(### $([regex]::Escape($entry.EventId)).*?-\s+\*\*Event Status\*\*:\s*`)active(`.*?)(###|\z)"
                $updated = [regex]::Replace($updated, $pattern, {
                    param($m)
                    $before = $m.Groups[1].Value
                    $after = $m.Groups[2].Value
                    $next = $m.Groups[3].Value
                    "$before`resolved$after$next"
                })
                
                # Update De-Escalation Outcome
                $pattern = "(?ms)(### $([regex]::Escape($entry.EventId)).*?-\s+\*\*De-Escalation Outcome\*\*:\s*`)\(none\)(`.*?)(###|\z)"
                $updated = [regex]::Replace($updated, $pattern, {
                    param($m)
                    $before = $m.Groups[1].Value
                    $after = $m.Groups[2].Value
                    $next = $m.Groups[3].Value
                    "$before`clean-pass at $resolvedAt$after$next"
                })
            }
            
            return $updated
        } | Out-Null

        # Clear runtime state for this feature
        $configPath = Join-Path $ProjectRoot '.squad\config.json'
        $featureKey = $Feature -replace '[/\\]', '_'
        
        Update-LockedFileContent -Path $configPath -Transform {
            param($currentContent)
            
            $config = if ([string]::IsNullOrWhiteSpace($currentContent)) {
                [pscustomobject]@{
                    version = '1.0'
                    reviewerRegressionState = [pscustomobject]@{}
                }
            }
            else {
                $currentContent | ConvertFrom-Json
            }
            
            if ($null -ne $config.reviewerRegressionState.PSObject.Properties[$featureKey]) {
                $config.reviewerRegressionState.PSObject.Properties.Remove($featureKey)
            }
            
            return ($config | ConvertTo-Json -Depth 10)
        } | Out-Null

        # Update state.md managed block
        $chain = Get-ReviewerRegressionReadback -ProjectRoot $ProjectRoot -Feature $Feature
        $null = Set-ReviewerRegressionStateBlock -IterationDirectory $IterationDirectory -Chain $chain

        [pscustomobject]@{
            Resolved     = $true
            EventIds     = @($activeEntries | ForEach-Object { $_.EventId })
            Message      = "Resolved $($activeEntries.Count) active event(s) via clean pass"
            Chain        = $chain
        } | ConvertTo-Json -Depth 8
        break
    }
    'withdraw' {
        # T024: FR-008 withdrawal reversal
        Require-ParameterValue -Name 'EventId' -Value $EventId
        if ([string]::IsNullOrWhiteSpace($Feature) -and -not [string]::IsNullOrWhiteSpace($IterationDirectory)) {
            $Feature = Get-FeatureReferenceFromIterationDirectory -ProjectRoot $ProjectRoot -IterationDirectory $IterationDirectory
        }
        Require-ParameterValue -Name 'Feature' -Value $Feature
        Require-ParameterValue -Name 'IterationDirectory' -Value $IterationDirectory

        $targetEvent = Get-ReviewerRegressionLedgerEntries -ProjectRoot $ProjectRoot |
            Where-Object { $_.EventId -eq $EventId } |
            Select-Object -First 1

        if ($null -eq $targetEvent) {
            throw "Event $EventId not found in reviewer-regression ledger."
        }

        if ($targetEvent.EventStatus -ne 'active') {
            # Already withdrawn or resolved - idempotent no-op
            $chain = Get-ReviewerRegressionReadback -ProjectRoot $ProjectRoot -Feature $Feature
            [pscustomobject]@{
                EventId    = $EventId
                Withdrawn  = $false
                Message    = "Event $EventId is not active (status: $($targetEvent.EventStatus)); no withdrawal needed"
                Chain      = $chain
            } | ConvertTo-Json -Depth 8
            break
        }

        # Mark event as withdrawn in ledger
        $ledgerPath = Get-ReviewerRegressionLedgerPath -ProjectRoot $ProjectRoot
        $withdrawnAt = (Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ')
        
        Update-LockedFileContent -Path $ledgerPath -Transform {
            param($currentContent)
            
            # Update EventStatus to withdrawn
            $pattern = "(?ms)(### $([regex]::Escape($EventId)).*?-\s+\*\*Event Status\*\*:\s*`)active(`.*?)(###|\z)"
            $updated = [regex]::Replace($currentContent, $pattern, {
                param($m)
                $before = $m.Groups[1].Value
                $after = $m.Groups[2].Value
                $next = $m.Groups[3].Value
                "$before`withdrawn$after$next"
            })
            
            # Update Withdrawal Reference
            $pattern = "(?ms)(### $([regex]::Escape($EventId)).*?-\s+\*\*Withdrawal Reference\*\*:\s*`)\(none\)(`.*?)(###|\z)"
            $updated = [regex]::Replace($updated, $pattern, {
                param($m)
                $before = $m.Groups[1].Value
                $after = $m.Groups[2].Value
                $next = $m.Groups[3].Value
                "$before`misreport-withdrawn at $withdrawnAt$after$next"
            })
            
            return $updated
        } | Out-Null

        # T025: Clean up unapproved candidate traps if corpus is enabled
        $settings = Get-ReviewerRegressionSettings -ProjectRoot $ProjectRoot
        if ($settings.KnownTrapsEnabled) {
            $knownTrapsPath = Join-Path $ProjectRoot '.specrew\quality\known-traps.md'
            if (Test-Path -LiteralPath $knownTrapsPath -PathType Leaf) {
                Update-LockedFileContent -Path $knownTrapsPath -Transform {
                    param($currentContent)
                    
                    # Remove any unapproved trap entries referencing this event
                    $pattern = "(?ms)<!-- candidate-trap-from-event: $([regex]::Escape($EventId)) -->.*?<!-- end-candidate-trap -->\s*"
                    $updated = [regex]::Replace($currentContent, $pattern, '')
                    
                    return $updated
                } | Out-Null
            }
        }

        # Check if there are remaining active events for this feature
        $remainingActive = @(
            Get-ReviewerRegressionLedgerEntries -ProjectRoot $ProjectRoot |
                Where-Object { $_.Feature -eq $Feature -and $_.EventStatus -eq 'active' -and $_.EventId -ne $EventId }
        )

        if ($remainingActive.Count -eq 0) {
            # No more active events - clear runtime state
            $configPath = Join-Path $ProjectRoot '.squad\config.json'
            $featureKey = $Feature -replace '[/\\]', '_'
            
            Update-LockedFileContent -Path $configPath -Transform {
                param($currentContent)
                
                $config = if ([string]::IsNullOrWhiteSpace($currentContent)) {
                    [pscustomobject]@{
                        version = '1.0'
                        reviewerRegressionState = [pscustomobject]@{}
                    }
                }
                else {
                    $currentContent | ConvertFrom-Json
                }
                
                if ($null -ne $config.reviewerRegressionState.PSObject.Properties[$featureKey]) {
                    $config.reviewerRegressionState.PSObject.Properties.Remove($featureKey)
                }
                
                return ($config | ConvertTo-Json -Depth 10)
            } | Out-Null
        }

        # Update state.md managed block
        $chain = Get-ReviewerRegressionReadback -ProjectRoot $ProjectRoot -Feature $Feature
        $null = Set-ReviewerRegressionStateBlock -IterationDirectory $IterationDirectory -Chain $chain

        [pscustomobject]@{
            EventId    = $EventId
            Withdrawn  = $true
            Message    = "Event $EventId withdrawn; state reverted"
            Chain      = $chain
        } | ConvertTo-Json -Depth 8
        break
    }
}
