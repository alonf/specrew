Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$sharedGovernancePath = Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) 'extensions\specrew-speckit\scripts\shared-governance.ps1'
if (-not (Test-Path -LiteralPath $sharedGovernancePath -PathType Leaf)) {
    throw "Missing shared governance helper '$sharedGovernancePath'."
}
. $sharedGovernancePath

function Get-SpecrewSessionStatePaths {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectRoot
    )

    $resolvedProjectRoot = Resolve-ProjectPath -Path $ProjectRoot
    return [pscustomobject]@{
        ProjectRoot = $resolvedProjectRoot
        PromptPath  = Join-Path $resolvedProjectRoot '.specrew\last-start-prompt.md'
        ContextPath = Join-Path $resolvedProjectRoot '.specrew\start-context.json'
        IdentityPath = Join-Path $resolvedProjectRoot '.squad\identity\now.md'
        DecisionsPath = Join-Path $resolvedProjectRoot '.squad\decisions.md'
        FeatureJsonPath = Join-Path $resolvedProjectRoot '.specify\feature.json'
    }
}

function ConvertTo-SpecrewFrontmatterValue {
    param([AllowNull()][object]$Value)

    if ($null -eq $Value) {
        return '(none)'
    }

    $stringValue = [string]$Value
    if ([string]::IsNullOrWhiteSpace($stringValue)) {
        return '(none)'
    }

    if ($stringValue -match '^[A-Za-z0-9_\-./:]+$') {
        return $stringValue
    }

    return '"' + ($stringValue.Replace('"', '\"')) + '"'
}

function ConvertFrom-SpecrewFrontmatter {
    param([AllowNull()][string]$Content)

    $frontmatter = [ordered]@{}
    $body = if ($null -eq $Content) { '' } else { $Content }
    if ([string]::IsNullOrWhiteSpace($Content) -or $Content -notmatch '(?ms)^---\s*\r?\n(.*?)\r?\n---\s*\r?\n?(.*)$') {
        return [pscustomobject]@{
            Frontmatter = $frontmatter
            Body        = $body
        }
    }

    foreach ($line in ($Matches[1] -split '\r?\n')) {
        if ($line -notmatch '^\s*([^:]+):\s*(.*?)\s*$') {
            continue
        }

        $key = $Matches[1].Trim()
        $value = $Matches[2].Trim()
        if ($value.StartsWith('"') -and $value.EndsWith('"') -and $value.Length -ge 2) {
            $value = $value.Substring(1, $value.Length - 2).Replace('\"', '"')
        }

        $frontmatter[$key] = $value
    }

    return [pscustomobject]@{
        Frontmatter = $frontmatter
        Body        = $Matches[2]
    }
}

function New-SpecrewMarkdownContent {
    param(
        [Parameter(Mandatory = $true)]
        [System.Collections.Specialized.OrderedDictionary]$Frontmatter,

        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string]$Body
    )

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add('---') | Out-Null
    foreach ($entry in $Frontmatter.GetEnumerator()) {
        $lines.Add(('{0}: {1}' -f $entry.Key, (ConvertTo-SpecrewFrontmatterValue -Value $entry.Value))) | Out-Null
    }
    $lines.Add('---') | Out-Null
    $lines.Add('') | Out-Null

    $trimmedBody = $Body.Trim()
    if (-not [string]::IsNullOrWhiteSpace($trimmedBody)) {
        $lines.Add($trimmedBody) | Out-Null
        $lines.Add('') | Out-Null
    }

    return ($lines -join [Environment]::NewLine)
}

function Get-SpecrewSessionStateFromFrontmatter {
    param(
        [Parameter(Mandatory = $true)]
        [System.Collections.IDictionary]$Frontmatter
    )

    $featureRef = if ($Frontmatter.Contains('session_state_feature')) { [string]$Frontmatter['session_state_feature'] } else { $null }
    $boundaryType = if ($Frontmatter.Contains('session_state_boundary')) { [string]$Frontmatter['session_state_boundary'] } else { $null }
    if ([string]::IsNullOrWhiteSpace($featureRef) -and [string]::IsNullOrWhiteSpace($boundaryType)) {
        return $null
    }

    return [pscustomobject]@{
        feature_ref      = if ([string]::IsNullOrWhiteSpace($featureRef) -or $featureRef -eq '(none)') { $null } else { $featureRef }
        boundary_type    = if ([string]::IsNullOrWhiteSpace($boundaryType) -or $boundaryType -eq '(none)') { $null } else { $boundaryType }
        iteration_number = if ($Frontmatter.Contains('session_state_iteration') -and $Frontmatter['session_state_iteration'] -ne '(none)') { [string]$Frontmatter['session_state_iteration'] } else { $null }
        task_id          = if ($Frontmatter.Contains('session_state_task') -and $Frontmatter['session_state_task'] -ne '(none)') { [string]$Frontmatter['session_state_task'] } else { $null }
        auth_commit_hash = if ($Frontmatter.Contains('session_state_auth_commit') -and $Frontmatter['session_state_auth_commit'] -ne '(none)') { [string]$Frontmatter['session_state_auth_commit'] } else { $null }
        recorded_at      = if ($Frontmatter.Contains('session_state_recorded_at') -and $Frontmatter['session_state_recorded_at'] -ne '(none)') { [string]$Frontmatter['session_state_recorded_at'] } else { $null }
        feature_path     = if ($Frontmatter.Contains('session_state_feature_path') -and $Frontmatter['session_state_feature_path'] -ne '(none)') { [string]$Frontmatter['session_state_feature_path'] } else { $null }
        active           = if ($Frontmatter.Contains('session_state_active')) { [string]$Frontmatter['session_state_active'] } else { 'true' }
    }
}

function Resolve-SpecrewFeatureRef {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectRoot,

        [AllowNull()]
        [string]$FeatureRef
    )

    if ([string]::IsNullOrWhiteSpace($FeatureRef)) {
        return $null
    }

    $trimmedFeatureRef = $FeatureRef.Trim()
    if ($trimmedFeatureRef -match '^[A-Za-z]:\\' -or $trimmedFeatureRef.StartsWith('\\')) {
        return Split-Path -Leaf $trimmedFeatureRef
    }

    if ($trimmedFeatureRef -match '^specs[\\/]') {
        return Split-Path -Leaf $trimmedFeatureRef
    }

    return $trimmedFeatureRef
}

function Resolve-SpecrewFeatureDirectory {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectRoot,

        [AllowNull()]
        [string]$FeatureRef
    )

    $resolvedFeatureRef = Resolve-SpecrewFeatureRef -ProjectRoot $ProjectRoot -FeatureRef $FeatureRef
    if ([string]::IsNullOrWhiteSpace($resolvedFeatureRef)) {
        return $null
    }

    return Join-Path (Resolve-ProjectPath -Path $ProjectRoot) ('specs\' + $resolvedFeatureRef)
}

function Get-SpecrewFeatureNumber {
    param([AllowNull()][string]$FeatureRef)

    if ([string]::IsNullOrWhiteSpace($FeatureRef)) {
        return $null
    }

    if ($FeatureRef -match '^(?<number>\d{3})[-_]') {
        return $Matches['number']
    }

    return $null
}

function Get-SpecrewBoundaryOrder {
    return @('specify', 'clarify', 'plan', 'tasks', 'review-signoff', 'iteration-closeout', 'feature-closeout')
}

function Resolve-SpecrewBoundaryAuthCommitHash {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectRoot,

        [AllowNull()]
        [string]$AuthCommitHash
    )

    if (-not [string]::IsNullOrWhiteSpace($AuthCommitHash) -and $AuthCommitHash -ne 'HEAD') {
        return $AuthCommitHash.Trim()
    }

    $resolvedHead = @(& git -C $ProjectRoot rev-parse --verify HEAD 2>$null)
    if ($LASTEXITCODE -eq 0 -and $resolvedHead.Count -gt 0) {
        $candidateHead = $resolvedHead[0].ToString().Trim()
        if ($candidateHead -match '^[0-9a-f]{40}$') {
            return $candidateHead
        }
    }

    if ($AuthCommitHash -eq 'HEAD') {
        throw "Failed to resolve literal HEAD to a concrete commit hash."
    }

    return $null
}

function New-SpecrewSessionState {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('specify', 'clarify', 'plan', 'tasks', 'review-signoff', 'iteration-closeout', 'feature-closeout')]
        [string]$BoundaryType,

        [Parameter(Mandatory = $true)]
        [string]$ProjectRoot,

        [AllowNull()]
        [string]$FeatureRef,

        [AllowNull()]
        [string]$IterationNumber,

        [AllowNull()]
        [string]$TaskId,

        [AllowNull()]
        [string]$AuthCommitHash
    )

    $resolvedFeatureRef = Resolve-SpecrewFeatureRef -ProjectRoot $ProjectRoot -FeatureRef $FeatureRef
    $featurePath = Resolve-SpecrewFeatureDirectory -ProjectRoot $ProjectRoot -FeatureRef $resolvedFeatureRef
    $recordedAt = (Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ')
    return [pscustomobject]@{
        boundary_type    = $BoundaryType
        feature_ref      = $resolvedFeatureRef
        feature_number   = Get-SpecrewFeatureNumber -FeatureRef $resolvedFeatureRef
        feature_path     = $featurePath
        iteration_number = if ([string]::IsNullOrWhiteSpace($IterationNumber)) { $null } else { $IterationNumber.Trim() }
        task_id          = if ([string]::IsNullOrWhiteSpace($TaskId)) { $null } else { $TaskId.Trim() }
        auth_commit_hash = if ([string]::IsNullOrWhiteSpace($AuthCommitHash)) { $null } else { $AuthCommitHash.Trim() }
        recorded_at      = $recordedAt
        active           = if ($BoundaryType -eq 'feature-closeout') { 'false' } else { 'true' }
    }
}

function Get-SpecrewPromptBody {
    param([pscustomobject]$SessionState)

    if ($SessionState.active -eq 'false') {
        return @"
# Specrew Session State

- No active feature.
- Last feature: $(if ($SessionState.feature_ref) { $SessionState.feature_ref } else { '(none)' })
- Last boundary: $($SessionState.boundary_type)
- Recorded at: $($SessionState.recorded_at)
- Authorization commit: $(if ($SessionState.auth_commit_hash) { $SessionState.auth_commit_hash } else { '(none)' })
"@
    }

    return @"
# Specrew Session State

- Active feature: $($SessionState.feature_ref)
- Current boundary: $($SessionState.boundary_type)
- Iteration: $(if ($SessionState.iteration_number) { $SessionState.iteration_number } else { '(none)' })
- Task: $(if ($SessionState.task_id) { $SessionState.task_id } else { '(none)' })
- Recorded at: $($SessionState.recorded_at)
- Authorization commit: $(if ($SessionState.auth_commit_hash) { $SessionState.auth_commit_hash } else { '(none)' })
"@
}

function Get-SpecrewIdentityBody {
    param([pscustomobject]$SessionState)

    if ($SessionState.active -eq 'false') {
        return @"
# What We're Focused On

No active feature. Last completed feature: $(if ($SessionState.feature_ref) { $SessionState.feature_ref } else { '(none)' }) at the $($SessionState.boundary_type) boundary ($($SessionState.recorded_at)).
"@
    }

    return @"
# What We're Focused On

Feature $($SessionState.feature_ref) is active at the $($SessionState.boundary_type) boundary.

- Iteration: $(if ($SessionState.iteration_number) { $SessionState.iteration_number } else { '(none)' })
- Task: $(if ($SessionState.task_id) { $SessionState.task_id } else { '(none)' })
- Recorded at: $($SessionState.recorded_at)
"@
}

function Update-SpecrewMarkdownStateFile {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $true)]
        [pscustomobject]$SessionState,

        [Parameter(Mandatory = $true)]
        [string]$DefaultBody,

        [AllowNull()]
        [System.Collections.IDictionary]$AdditionalFrontmatter,

        [AllowNull()]
        [string]$PreferredBody,

        [switch]$UsePreferredBody
    )

    $existingContent = if (Test-Path -LiteralPath $Path -PathType Leaf) {
        Get-Content -LiteralPath $Path -Raw -Encoding UTF8
    }
    else {
        ''
    }

    $parsed = ConvertFrom-SpecrewFrontmatter -Content $existingContent
    $frontmatter = [ordered]@{}
    foreach ($entry in $parsed.Frontmatter.GetEnumerator()) {
        if ($entry.Key -like 'session_state_*') {
            continue
        }

        if ($entry.Key -eq 'updated_at') {
            continue
        }

        $frontmatter[$entry.Key] = $entry.Value
    }

    if ($null -ne $AdditionalFrontmatter) {
        foreach ($entry in $AdditionalFrontmatter.GetEnumerator()) {
            $frontmatter[[string]$entry.Key] = $entry.Value
        }
    }

    $frontmatter['updated_at'] = $SessionState.recorded_at
    $frontmatter['session_state_active'] = $SessionState.active
    $frontmatter['session_state_boundary'] = $SessionState.boundary_type
    $frontmatter['session_state_feature'] = if ($SessionState.feature_ref) { $SessionState.feature_ref } else { '(none)' }
    $frontmatter['session_state_feature_path'] = if ($SessionState.feature_path) { $SessionState.feature_path } else { '(none)' }
    $frontmatter['session_state_iteration'] = if ($SessionState.iteration_number) { $SessionState.iteration_number } else { '(none)' }
    $frontmatter['session_state_task'] = if ($SessionState.task_id) { $SessionState.task_id } else { '(none)' }
    $frontmatter['session_state_auth_commit'] = if ($SessionState.auth_commit_hash) { $SessionState.auth_commit_hash } else { '(none)' }
    $frontmatter['session_state_recorded_at'] = $SessionState.recorded_at

    $body = if ($UsePreferredBody) {
        if ([string]::IsNullOrWhiteSpace($PreferredBody)) { $DefaultBody } else { $PreferredBody.Trim() }
    }
    elseif ([string]::IsNullOrWhiteSpace($parsed.Body)) {
        $DefaultBody
    }
    else {
        $parsed.Body.Trim()
    }
    $content = New-SpecrewMarkdownContent -Frontmatter $frontmatter -Body $body
    Write-FileAtomically -Path $Path -Content ($content.TrimEnd() + [Environment]::NewLine)
}

function Write-FileAtomically {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string]$Content
    )

    $resolvedPath = Resolve-ProjectPath -Path $Path
    $directory = Split-Path -Parent $resolvedPath
    if (-not [string]::IsNullOrWhiteSpace($directory) -and -not (Test-Path -LiteralPath $directory -PathType Container)) {
        $null = New-Item -ItemType Directory -Path $directory -Force
    }

    $tempPath = '{0}.{1}.tmp' -f $resolvedPath, ([guid]::NewGuid().ToString('N'))
    try {
        [System.IO.File]::WriteAllText($tempPath, $Content, [System.Text.UTF8Encoding]::new($false))
        if (-not (Test-Path -LiteralPath $tempPath -PathType Leaf)) {
            throw "Atomic write did not create '$tempPath'."
        }

        Move-Item -LiteralPath $tempPath -Destination $resolvedPath -Force -ErrorAction Stop
    }
    catch {
        Remove-OrphanedAtomicWriteArtifacts -Path $resolvedPath -TempPath $tempPath
        throw "Atomic write to '$resolvedPath' failed: $($_.Exception.Message)"
    }
    finally {
        if (Test-Path -LiteralPath $tempPath -PathType Leaf) {
            Remove-Item -LiteralPath $tempPath -Force -ErrorAction SilentlyContinue
        }
    }
}

function Update-SpecrewStartContext {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $true)]
        [pscustomobject]$SessionState
    )

    $context = [ordered]@{}
    if (Test-Path -LiteralPath $Path -PathType Leaf) {
        try {
            $existing = Get-Content -LiteralPath $Path -Raw -Encoding UTF8 | ConvertFrom-Json -Depth 12
            foreach ($property in $existing.PSObject.Properties) {
                $context[$property.Name] = $property.Value
            }
        }
        catch {
            $context = [ordered]@{}
        }
    }

    $context['feature_path'] = if ($SessionState.feature_path) { $SessionState.feature_path } else { $null }
    $context['generated_at_utc'] = $SessionState.recorded_at
    $context['session_state'] = [ordered]@{
        active           = ($SessionState.active -eq 'true')
        boundary_type    = $SessionState.boundary_type
        feature_ref      = $SessionState.feature_ref
        feature_path     = $SessionState.feature_path
        iteration_number = $SessionState.iteration_number
        task_id          = $SessionState.task_id
        auth_commit_hash = $SessionState.auth_commit_hash
        recorded_at      = $SessionState.recorded_at
    }

    Write-FileAtomically -Path $Path -Content (([pscustomobject]$context | ConvertTo-Json -Depth 12) + [Environment]::NewLine)
}

function Clear-SpecrewActiveFeature {
    param(
        [Parameter(Mandatory = $true)]
        [string]$FeatureJsonPath
    )

    $featureJson = [ordered]@{
        feature_directory = ''
    }

    if (Test-Path -LiteralPath $FeatureJsonPath -PathType Leaf) {
        try {
            $existing = Get-Content -LiteralPath $FeatureJsonPath -Raw -Encoding UTF8 | ConvertFrom-Json -Depth 10
            foreach ($property in $existing.PSObject.Properties) {
                if ($property.Name -eq 'feature_directory') {
                    continue
                }

                $featureJson[$property.Name] = $property.Value
            }
        }
        catch {
        }
    }

    Write-FileAtomically -Path $FeatureJsonPath -Content (([pscustomobject]$featureJson | ConvertTo-Json -Depth 10) + [Environment]::NewLine)
}

function Add-SpecrewBoundarySyncLedgerEntry {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectRoot,

        [Parameter(Mandatory = $true)]
        [pscustomobject]$SessionState
    )

    $lines = @(
        ('- **Boundary Type**: {0}' -f $SessionState.boundary_type)
        ('- **Feature Ref**: {0}' -f $(if ($SessionState.feature_ref) { $SessionState.feature_ref } else { '(none)' }))
        ('- **Iteration Number**: {0}' -f $(if ($SessionState.iteration_number) { $SessionState.iteration_number } else { '(none)' }))
        ('- **Task ID**: {0}' -f $(if ($SessionState.task_id) { $SessionState.task_id } else { '(none)' }))
        ('- **Auth Commit Hash**: {0}' -f $(if ($SessionState.auth_commit_hash) { $SessionState.auth_commit_hash } else { '(none)' }))
        ('- **Recorded At**: {0}' -f $SessionState.recorded_at)
    )

    Add-DecisionsLedgerEntry -ProjectRoot $ProjectRoot -Title ('Boundary sync: {0}' -f $SessionState.boundary_type) -Lines $lines | Out-Null
}

function Add-SpecrewBoundarySyncWarningLedgerEntry {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectRoot,

        [Parameter(Mandatory = $true)]
        [string]$BoundaryType,

        [AllowNull()]
        [pscustomobject]$LatestBoundary,

        [Parameter(Mandatory = $true)]
        [string]$Message
    )

    $lines = @(
        ('- **Boundary Type**: {0}' -f $BoundaryType)
        ('- **Latest Recorded Boundary**: {0}' -f $(if ($null -ne $LatestBoundary -and $LatestBoundary.boundary_type) { $LatestBoundary.boundary_type } else { '(none)' }))
        ('- **Recorded At**: {0}' -f ((Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ')))
        ('- **Warning**: {0}' -f $Message)
    )

    Add-DecisionsLedgerEntry -ProjectRoot $ProjectRoot -Title ('Boundary sync warning: {0}' -f $BoundaryType) -Lines $lines | Out-Null
}

function Get-LatestSpecrewBoundarySyncState {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectRoot
    )

    $paths = Get-SpecrewSessionStatePaths -ProjectRoot $ProjectRoot
    if (-not (Test-Path -LiteralPath $paths.DecisionsPath -PathType Leaf)) {
        return $null
    }

    $lines = @(Get-Content -LiteralPath $paths.DecisionsPath -Encoding UTF8)
    $startIndex = -1
    for ($index = $lines.Count - 1; $index -ge 0; $index--) {
        if ($lines[$index] -match '^## .* — Boundary sync: ') {
            $startIndex = $index
            break
        }
    }

    if ($startIndex -lt 0) {
        return $null
    }

    $entryLines = New-Object System.Collections.Generic.List[string]
    for ($index = $startIndex + 1; $index -lt $lines.Count; $index++) {
        if ($lines[$index] -match '^## ') {
            break
        }

        $entryLines.Add($lines[$index]) | Out-Null
    }

    $values = @{}
    foreach ($line in $entryLines) {
        if ($line -match '^- \*\*(.+?)\*\*:\s*(.+?)\s*$') {
            $values[$Matches[1]] = $Matches[2]
        }
    }

    if (-not $values.ContainsKey('Boundary Type')) {
        return $null
    }

    return [pscustomobject]@{
        boundary_type    = [string]$values['Boundary Type']
        feature_ref      = if ($values['Feature Ref'] -and $values['Feature Ref'] -ne '(none)') { [string]$values['Feature Ref'] } else { $null }
        iteration_number = if ($values['Iteration Number'] -and $values['Iteration Number'] -ne '(none)') { [string]$values['Iteration Number'] } else { $null }
        task_id          = if ($values['Task ID'] -and $values['Task ID'] -ne '(none)') { [string]$values['Task ID'] } else { $null }
        auth_commit_hash = if ($values['Auth Commit Hash'] -and $values['Auth Commit Hash'] -ne '(none)') { [string]$values['Auth Commit Hash'] } else { $null }
        recorded_at      = if ($values['Recorded At']) { [string]$values['Recorded At'] } else { $null }
        active           = if ([string]::IsNullOrWhiteSpace([string]$values['Feature Ref']) -or $values['Feature Ref'] -eq '(none)') { 'false' } else { 'true' }
    }
}

function Invoke-SpecrewBoundaryStateSync {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectPath,

        [Parameter(Mandatory = $true)]
        [ValidateSet('specify', 'clarify', 'plan', 'tasks', 'review-signoff', 'iteration-closeout', 'feature-closeout')]
        [string]$BoundaryType,

        [AllowNull()]
        [string]$FeatureRef,

        [AllowNull()]
        [string]$IterationNumber,

        [AllowNull()]
        [string]$TaskId,

        [AllowNull()]
        [string]$AuthCommitHash,

        [AllowNull()]
        [string]$IdentityFocusArea,

        [AllowNull()]
        [string]$IdentityActiveIssues,

        [AllowNull()]
        [string]$IdentityBody
    )

    $paths = Get-SpecrewSessionStatePaths -ProjectRoot $ProjectPath
    $effectiveFeatureRef = $FeatureRef
    if ([string]::IsNullOrWhiteSpace($effectiveFeatureRef) -and (Test-Path -LiteralPath $paths.FeatureJsonPath -PathType Leaf)) {
        try {
            $featureJson = Get-Content -LiteralPath $paths.FeatureJsonPath -Raw -Encoding UTF8 | ConvertFrom-Json
            if (-not [string]::IsNullOrWhiteSpace([string]$featureJson.feature_directory)) {
                $effectiveFeatureRef = Split-Path -Leaf ([string]$featureJson.feature_directory)
            }
        }
        catch {
        }
    }

    $latestBoundary = Get-LatestSpecrewBoundarySyncState -ProjectRoot $paths.ProjectRoot
    $boundaryOrder = @(Get-SpecrewBoundaryOrder)
    $expectedBoundaryType = if ($null -eq $latestBoundary) {
        $boundaryOrder[0]
    }
    else {
        $latestBoundaryIndex = [Array]::IndexOf($boundaryOrder, [string]$latestBoundary.boundary_type)
        if ($latestBoundaryIndex -ge 0 -and $latestBoundaryIndex -lt ($boundaryOrder.Count - 1)) {
            $boundaryOrder[$latestBoundaryIndex + 1]
        }
        else {
            $null
        }
    }

    if (-not [string]::IsNullOrWhiteSpace($expectedBoundaryType) -and $expectedBoundaryType -ne $BoundaryType) {
        Add-SpecrewBoundarySyncWarningLedgerEntry -ProjectRoot $paths.ProjectRoot -BoundaryType $BoundaryType -LatestBoundary $latestBoundary -Message ("Expected next boundary '{0}' but received '{1}'." -f $expectedBoundaryType, $BoundaryType)
    }

    $effectiveAuthCommitHash = Resolve-SpecrewBoundaryAuthCommitHash -ProjectRoot $paths.ProjectRoot -AuthCommitHash $AuthCommitHash
    $sessionState = New-SpecrewSessionState `
        -BoundaryType $BoundaryType `
        -ProjectRoot $paths.ProjectRoot `
        -FeatureRef $effectiveFeatureRef `
        -IterationNumber $IterationNumber `
        -TaskId $TaskId `
        -AuthCommitHash $effectiveAuthCommitHash

    $identityAdditionalFrontmatter = $null
    if (-not [string]::IsNullOrWhiteSpace($IdentityFocusArea) -or -not [string]::IsNullOrWhiteSpace($IdentityActiveIssues)) {
        $identityAdditionalFrontmatter = [ordered]@{}
        if (-not [string]::IsNullOrWhiteSpace($IdentityFocusArea)) {
            $identityAdditionalFrontmatter['focus_area'] = $IdentityFocusArea.Trim()
        }
        if (-not [string]::IsNullOrWhiteSpace($IdentityActiveIssues)) {
            $identityAdditionalFrontmatter['active_issues'] = $IdentityActiveIssues.Trim()
        }
    }

    Update-SpecrewMarkdownStateFile -Path $paths.PromptPath -SessionState $sessionState -DefaultBody (Get-SpecrewPromptBody -SessionState $sessionState)
    Update-SpecrewStartContext -Path $paths.ContextPath -SessionState $sessionState
    Update-SpecrewMarkdownStateFile -Path $paths.IdentityPath -SessionState $sessionState -DefaultBody (Get-SpecrewIdentityBody -SessionState $sessionState) -AdditionalFrontmatter $identityAdditionalFrontmatter -PreferredBody $IdentityBody -UsePreferredBody:(-not [string]::IsNullOrWhiteSpace($IdentityBody))

    Add-SpecrewBoundarySyncLedgerEntry -ProjectRoot $paths.ProjectRoot -SessionState $sessionState

    if ($BoundaryType -eq 'feature-closeout') {
        Clear-SpecrewActiveFeature -FeatureJsonPath $paths.FeatureJsonPath
    }

    return [pscustomobject]@{
        success          = $true
        boundary_type    = $sessionState.boundary_type
        feature_ref      = $sessionState.feature_ref
        iteration_number = $sessionState.iteration_number
        task_id          = $sessionState.task_id
        recorded_at      = $sessionState.recorded_at
        prompt_path      = $paths.PromptPath
        context_path     = $paths.ContextPath
        identity_path    = $paths.IdentityPath
        decisions_path   = $paths.DecisionsPath
        auth_commit_hash = $sessionState.auth_commit_hash
    }
}
