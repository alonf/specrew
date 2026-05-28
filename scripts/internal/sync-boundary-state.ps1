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

    $frontmatterBlock = [string]$Matches[1]
    $bodyContent = [string]$Matches[2]
    foreach ($line in ($frontmatterBlock -split '\r?\n')) {
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
        Body        = $bodyContent
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
    return @(Get-SpecrewCanonicalBoundaryTypes)
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

        [switch]$UsePreferredBody,

        [AllowNull()]
        [string]$SchemaVersion
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

    if (-not [string]::IsNullOrWhiteSpace($SchemaVersion)) {
        $frontmatter['schema'] = $SchemaVersion
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

function Get-SpecrewCurrentHeadCommitHash {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectRoot
    )

    $resolvedHead = @(& git -C $ProjectRoot rev-parse --verify HEAD 2>$null)
    if ($LASTEXITCODE -ne 0 -or $resolvedHead.Count -eq 0) {
        throw "Failed to resolve the current HEAD commit hash."
    }

    $candidateHead = $resolvedHead[0].ToString().Trim()
    if ($candidateHead -notmatch '^[0-9a-f]{40}$') {
        throw "Failed to resolve the current HEAD commit hash."
    }

    return $candidateHead
}

function Update-BaselineCommitHashInFrontmatter {
    param(
        [Parameter(Mandatory = $true)]
        [string]$PromptPath,

        [Parameter(Mandatory = $true)]
        [string]$NewBaselineHash
    )

    if ([string]::IsNullOrWhiteSpace($NewBaselineHash) -or $NewBaselineHash -notmatch '^[0-9a-f]{40}$') {
        throw "Baseline commit hash must be a full 40-character git commit hash."
    }

    $existingContent = if (Test-Path -LiteralPath $PromptPath -PathType Leaf) {
        Get-Content -LiteralPath $PromptPath -Raw -Encoding UTF8
    }
    else {
        ''
    }

    $parsed = ConvertFrom-SpecrewFrontmatter -Content $existingContent
    $frontmatter = [ordered]@{}
    $baselineUpdated = $false
    foreach ($entry in $parsed.Frontmatter.GetEnumerator()) {
        if ($entry.Key -eq 'baseline_commit_hash') {
            $frontmatter['baseline_commit_hash'] = $NewBaselineHash
            $baselineUpdated = $true
        }
        else {
            $frontmatter[[string]$entry.Key] = $entry.Value
        }
    }

    if (-not $baselineUpdated) {
        $updatedFrontmatter = [ordered]@{
            baseline_commit_hash = $NewBaselineHash
        }
        foreach ($entry in $frontmatter.GetEnumerator()) {
            $updatedFrontmatter[[string]$entry.Key] = $entry.Value
        }
        $frontmatter = $updatedFrontmatter
    }

    $lineEnding = if ($existingContent -match "`r`n") { "`r`n" } else { [Environment]::NewLine }
    $updatedContent = New-SpecrewMarkdownContent -Frontmatter $frontmatter -Body $parsed.Body
    Write-FileAtomically -Path $PromptPath -Content ($updatedContent.TrimEnd() + $lineEnding)
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
            $existing = Get-Content -LiteralPath $Path -Raw -Encoding UTF8 | ConvertFrom-Json -AsHashtable -Depth 12
            $schema = Get-SpecrewStateSchemaVersion -State $existing -Path $Path
            # v0/v1 behavior: preserve any unrelated properties before refreshing session_state payload
            foreach ($entry in $existing.GetEnumerator()) {
                $context[$entry.Key] = $entry.Value
            }
        }
        catch {
            if (Test-IsUnsupportedSpecrewSchemaError -ErrorRecord $_) {
                throw
            }
            $context = [ordered]@{}
        }
    }

    if ($context.Contains('boundary_enforcement') -and $null -ne $context['boundary_enforcement']) {
        $context['schema'] = 'v2'
    }
    else {
        $context['schema'] = 'v1'
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
            $existing = Get-Content -LiteralPath $FeatureJsonPath -Raw -Encoding UTF8 | ConvertFrom-Json -AsHashtable -Depth 10
            $schema = Get-SpecrewStateSchemaVersion -State $existing -Path $FeatureJsonPath
            foreach ($entry in $existing.GetEnumerator()) {
                if ($entry.Key -eq 'feature_directory') {
                    continue
                }

                $featureJson[$entry.Key] = $entry.Value
            }
        }
        catch {
            if (Test-IsUnsupportedSpecrewSchemaError -ErrorRecord $_) {
                throw
            }
        }
    }

    $featureJson['schema'] = 'v1'
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

function Invoke-PreBoundaryMarkdownLintGate {
    # Proposal 088: runs `markdownlint-cli --fix` on changed .md files BEFORE
    # boundary-sync writes any state. If auto-fixes were applied, throws with a
    # directive to commit the fixes and re-run sync. If unfixable violations
    # remain, throws with file:line messages. If markdownlint-cli is unavailable,
    # emits a warning and proceeds.
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectPath
    )

    $resolvedProjectRoot = Resolve-ProjectPath -Path $ProjectPath

    # Step 1: identify changed .md files via Proposal 083's base-ref helper
    $changedFiles = @(Get-ChangedMarkdownFiles -ProjectRoot $resolvedProjectRoot)
    if ($changedFiles.Count -eq 0) {
        # No .md files in diff — gate is a no-op
        return
    }

    # Step 2: invoke markdownlint --fix on the scoped files
    $result = Invoke-MarkdownLintAutoFix -MarkdownFiles $changedFiles -ProjectRoot $resolvedProjectRoot

    # Step 3: handle each outcome
    if ($result.MarkdownLintUnavailable) {
        Write-Warning '[markdownlint-gate] markdownlint-cli unavailable; skipping gate'
        return
    }

    # Surface both auto-fix and unfixable findings in a single halt message
    # (per Copilot review feedback) so the Crew sees the full picture and can
    # address both classes of issue before re-running, rather than discovering
    # the unfixable ones in a second pass after committing the auto-fixes.
    if ($result.AutoFixedFiles.Count -gt 0 -or $result.UnfixableViolations.Count -gt 0) {
        $messageLines = New-Object System.Collections.Generic.List[string]
        if ($result.AutoFixedFiles.Count -gt 0) {
            $fileList = ($result.AutoFixedFiles | ForEach-Object { "  - $_" }) -join "`n"
            $null = $messageLines.Add(("[markdownlint-gate] Auto-fixed markdownlint violations in {0} file(s):" -f $result.AutoFixedFiles.Count))
            $null = $messageLines.Add($fileList)
            $null = $messageLines.Add('')
            $null = $messageLines.Add('Please:')
            $null = $messageLines.Add('  1. Review the diff: git diff')
            $null = $messageLines.Add('  2. Stage the fixes: git add <files>')
            $null = $messageLines.Add("  3. Commit: git commit -m 'chore(lint): auto-fix markdownlint violations'")
            $null = $messageLines.Add('  4. Push: git push')
            $null = $messageLines.Add('')
        }

        if ($result.UnfixableViolations.Count -gt 0) {
            $violationList = ($result.UnfixableViolations | ForEach-Object { "  - $_" }) -join "`n"
            $null = $messageLines.Add(("[markdownlint-gate] Unfixable markdownlint violations remain in {0} location(s):" -f $result.UnfixableViolations.Count))
            $null = $messageLines.Add($violationList)
            $null = $messageLines.Add('')
            $null = $messageLines.Add('These violations are semantic (e.g., MD013 line-length, MD024 duplicate-heading)')
            $null = $messageLines.Add('and require manual editing. Edit those file:line locations.')
            $null = $messageLines.Add('')
        }

        $null = $messageLines.Add('Boundary-sync HALTED until the lint findings are resolved and committed. Re-run boundary-sync after committing the fixes.')

        throw ($messageLines -join "`n")
    }
}

function Invoke-PreFeatureCloseoutWorkingTreeGate {
    # Closes the Rule 14B / Proposal 099 gap exposed by F-039: at feature-closeout
    # boundary, the git working tree must NOT contain unstaged or untracked
    # feature-implementation files. The 2026-05-22 F-039 release shipped its
    # closeout declaration ("F-039 shipped as v0.25.0") while ~1900 lines of
    # implementation code (helpers, ValidateSet additions, bypass flag, gate
    # preambles, tests) sat uncommitted in the working tree. Closeout should
    # not have advanced. This gate prevents the same failure class.
    #
    # Triggered only at feature-closeout boundary (not earlier boundaries — those
    # are governed by Rule 14B at every-boundary cadence; feature-closeout is
    # the last enforcement point before the audit trail goes immutable).
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectPath,

        [Parameter(Mandatory = $true)]
        [string]$BoundaryType
    )

    if ($BoundaryType -ne 'feature-closeout') { return }

    $resolvedProjectRoot = Resolve-ProjectPath -Path $ProjectPath

    Push-Location -LiteralPath $resolvedProjectRoot
    try {
        $statusOutput = @(& git status --porcelain 2>&1)
        $statusExitCode = $LASTEXITCODE
    }
    catch {
        Write-Warning ("[feature-closeout-working-tree-gate] git status raised: {0}; skipping gate." -f $_.Exception.Message)
        return
    }
    finally {
        Pop-Location -ErrorAction SilentlyContinue
    }

    if ($statusExitCode -ne 0) {
        Write-Warning ("[feature-closeout-working-tree-gate] git status non-zero exit ({0}); skipping gate." -f $statusExitCode)
        return
    }

    if ($null -eq $statusOutput -or $statusOutput.Count -eq 0) { return }

    # Session-state paths that legitimately churn during boundary work.
    # These are written by canonical sync helpers and expected to be
    # mid-update at boundary-sync time. Excluded from the gate.
    $excludePathPatterns = @(
        '\.specrew/last-validator-summary\.json'
        '\.specrew/last-start-prompt\.md'
        '\.specrew/start-context\.json'
        '\.specrew/version-check-cache\.json'
        '\.specrew/\.cache/'
        '\.squad/identity/now\.md'
        '\.squad/decisions\.md'
        '\.specify/feature\.json'
    )

    # Feature-implementation surfaces that MUST be committed before closeout.
    $featureRelevantPathPatterns = @(
        '^scripts/'
        '^extensions/'
        '^\.specify/extensions/'
        '^tests/'
        '^docs/'
        '^proposals/'
        '^specs/'
        '^README'
        '^CHANGELOG'
        '^NOTICE'
        '^Specrew\.psd1'
    )

    $relevantUncommitted = New-Object System.Collections.Generic.List[string]
    foreach ($line in $statusOutput) {
        if ([string]::IsNullOrWhiteSpace($line)) { continue }
        # Status line format: 'XY path' where XY is the 2-char status code.
        # Strip the leading 3 chars (status + space) to get the path.
        $path = if ($line.Length -gt 3) { $line.Substring(3) } else { '' }
        if ([string]::IsNullOrWhiteSpace($path)) { continue }
        # Normalize path separators for pattern matching
        $normalizedPath = $path -replace '\\', '/'

        $isExcluded = $false
        foreach ($p in $excludePathPatterns) {
            if ($normalizedPath -match $p) { $isExcluded = $true; break }
        }
        if ($isExcluded) { continue }

        $isRelevant = $false
        foreach ($p in $featureRelevantPathPatterns) {
            if ($normalizedPath -match $p) { $isRelevant = $true; break }
        }
        if ($isRelevant) {
            $null = $relevantUncommitted.Add($line.Trim())
        }
    }

    if ($relevantUncommitted.Count -eq 0) { return }

    $fileList = ($relevantUncommitted | ForEach-Object { "  - $_" }) -join "`n"
    $messageLines = @(
        ("[feature-closeout-working-tree-gate] {0} feature-implementation file(s) are unstaged or uncommitted at feature-closeout boundary:" -f $relevantUncommitted.Count)
        $fileList
        ''
        'Feature-closeout requires ALL implementation work to be committed AND pushed.'
        'This gate exists because the F-039 / Proposal 065 closeout on 2026-05-22 declared'
        '"shipped as v0.25.0" while ~1900 lines of implementation code sat uncommitted in'
        'the working tree. The closeout boundary advanced under that hollow state.'
        ''
        'Per Coordinator governance Rule 14B + memory feedback-pr-at-feature-close-sdlc:'
        ''
        '  1. Review the unstaged surfaces: git status'
        '  2. Stage them: git add <files>'
        "  3. Commit: git commit -m 'feat(F-NNN): <description>'"
        '  4. Push: git push'
        '  5. Re-invoke /speckit.specrew-speckit.sync-feature-closeout'
        ''
        'Boundary-sync HALTED until the working tree contains no uncommitted feature-implementation surfaces.'
    )
    throw ($messageLines -join "`n")
}

function Invoke-SpecrewAutoRenderDashboard {
    # Proposal 046 (auto-render at iteration + feature closeout) — inlined as part of the
    # F-040 dogfooding fix bundle (2026-05-23). Shells out to specrew-where.ps1 with the
    # appropriate --capture-kind and --output-path so the per-iteration dashboard.md and
    # per-feature closeout-dashboard.md artifacts exist without manual invocation.
    #
    # Errors are caller-wrapped (try/catch with Write-Warning) so a renderer failure
    # never blocks the boundary-sync — boundary state writes already happened above.
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectRoot,

        [Parameter(Mandatory = $true)]
        [string]$OutputPath,

        [Parameter(Mandatory = $true)]
        [ValidateSet('iteration-closeout', 'feature-closeout')]
        [string]$CaptureKind,

        [AllowNull()]
        [string]$FeatureRef,

        [AllowNull()]
        [string]$IterationNumber
    )

    # Locate specrew-where.ps1 in the same scripts/ root that holds this file.
    $scriptsRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    $whereScript = Join-Path $scriptsRoot 'scripts\specrew-where.ps1'
    if (-not (Test-Path -LiteralPath $whereScript -PathType Leaf)) {
        # Module-installed layout: scripts/internal/sync-boundary-state.ps1 sits beside
        # scripts/specrew-where.ps1 at the module root.
        $whereScript = Join-Path (Split-Path -Parent $PSScriptRoot) 'specrew-where.ps1'
    }
    if (-not (Test-Path -LiteralPath $whereScript -PathType Leaf)) {
        Write-Warning "[auto-dashboard] specrew-where.ps1 not found near sync-boundary-state.ps1; skipping render."
        return
    }

    $whereArgs = @(
        '-ProjectPath', $ProjectRoot,
        '-OutputPath', $OutputPath,
        '-CaptureKind', $CaptureKind,
        '-NoColor',
        '-PreserveExistingArtifact'
    )
    if (-not [string]::IsNullOrWhiteSpace($FeatureRef)) {
        $whereArgs += @('-FeatureId', $FeatureRef)
    }
    if (-not [string]::IsNullOrWhiteSpace($IterationNumber)) {
        $whereArgs += @('-IterationNumber', $IterationNumber)
    }

    & pwsh -NoProfile -ExecutionPolicy Bypass -File $whereScript @whereArgs *>&1 | Out-Null
    $whereExit = $LASTEXITCODE
    $global:LASTEXITCODE = 0
    if ($whereExit -ne 0) {
        Write-Warning ("[auto-dashboard] specrew-where exited with code {0}; '{1}' may be missing or stale." -f $whereExit, $OutputPath)
    }
}

function Invoke-SpecrewBoundaryStateSync {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectPath,

        [Parameter(Mandatory = $true)]
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

    $aliasMap = @{
        'spec'               = 'specify'
        'specify'            = 'specify'
        'clarify'            = 'clarify'
        'plan'               = 'plan'
        'tasks'              = 'tasks'
        'before-implement'   = 'before-implement'
        'implement'          = 'review-signoff'
        'review'             = 'review-signoff'
        'review-signoff'     = 'review-signoff'
        'retro'              = 'retro'
        'iteration'          = 'iteration-closeout'
        'iteration-closeout' = 'iteration-closeout'
        'closeout'           = 'iteration-closeout'
        'feature'            = 'feature-closeout'
        'feature-closeout'   = 'feature-closeout'
    }

    $normalizedInput = if ($null -eq $BoundaryType) { '' } else { $BoundaryType.Trim().ToLowerInvariant() }
    if (-not $aliasMap.ContainsKey($normalizedInput)) {
        $suggestions = New-Object System.Collections.Generic.List[string]
        foreach ($key in $aliasMap.Keys) {
            if ($key -like "*$normalizedInput*" -or $normalizedInput -like "*$key*") {
                $suggestions.Add(("{0} -> {1}" -f $key, $aliasMap[$key])) | Out-Null
            }
        }
        $suggestionText = if ($suggestions.Count -gt 0) {
            " Did you mean one of: $($suggestions -join ', ')."
        } else {
            " Valid boundaries and aliases are: specify, clarify, plan, tasks, before-implement, review-signoff, retro, iteration-closeout, feature-closeout."
        }
        throw "Unrecognized boundary type or alias '$BoundaryType'.$suggestionText"
    }

    $BoundaryType = $aliasMap[$normalizedInput]

    # Proposal 088: pre-sync markdownlint gate. Catches lint violations at
    # boundary-time so they never reach PR-CI Lint and cause the catch-fix-retry
    # cycle. Runs BEFORE any state-file writes; if violations are found, throws
    # with a clear directive instead of half-syncing.
    Invoke-PreBoundaryMarkdownLintGate -ProjectPath $ProjectPath
    Invoke-PreFeatureCloseoutWorkingTreeGate -ProjectPath $ProjectPath -BoundaryType $BoundaryType

    $paths = Get-SpecrewSessionStatePaths -ProjectRoot $ProjectPath
    $effectiveFeatureRef = $FeatureRef
    if ([string]::IsNullOrWhiteSpace($effectiveFeatureRef) -and (Test-Path -LiteralPath $paths.FeatureJsonPath -PathType Leaf)) {
        try {
            $featureJson = Get-Content -LiteralPath $paths.FeatureJsonPath -Raw -Encoding UTF8 | ConvertFrom-Json -AsHashtable -Depth 12
            $schema = Get-SpecrewStateSchemaVersion -State $featureJson -Path $paths.FeatureJsonPath
            # v0/v1 behavior: feature_directory remains the feature-ref source of truth
            if (-not [string]::IsNullOrWhiteSpace([string]$featureJson['feature_directory'])) {
                $effectiveFeatureRef = Split-Path -Leaf ([string]$featureJson['feature_directory'])
            }
        }
        catch {
            if (Test-IsUnsupportedSpecrewSchemaError -ErrorRecord $_) {
                throw
            }
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

    # Post-F-029 corrigendum: at feature-closeout, force body refresh so the
    # resume directive does not persist into the next session and trick the Crew
    # into re-investigating the closed feature. Other boundaries preserve any
    # human-edited body via the existing "preserve existing body" path.
    $promptBody = Get-SpecrewPromptBody -SessionState $sessionState
    Update-SpecrewMarkdownStateFile `
        -Path $paths.PromptPath `
        -SessionState $sessionState `
        -DefaultBody $promptBody `
        -PreferredBody $promptBody `
        -UsePreferredBody:($BoundaryType -eq 'feature-closeout')
    try {
        $baselineCommitHash = Get-SpecrewCurrentHeadCommitHash -ProjectRoot $paths.ProjectRoot
        Update-BaselineCommitHashInFrontmatter -PromptPath $paths.PromptPath -NewBaselineHash $baselineCommitHash
    }
    catch {
        # Brittle coupling: keep this thrown-message literal aligned with the catch-condition match below.
        if ($_.Exception.Message -eq 'Failed to resolve the current HEAD commit hash.') {
            Write-Warning ("Boundary sync '{0}' could not refresh baseline_commit_hash because the current HEAD commit hash could not be resolved." -f $BoundaryType)
        }
        else {
            throw "Failed to refresh baseline_commit_hash in '$($paths.PromptPath)': $($_.Exception.Message)"
        }
    }
    # US2: Inline verdict writer. Update boundary enforcement and verdict history in the same sync pass.
    $enforcementState = Get-SpecrewBoundaryEnforcementState -ProjectRoot $paths.ProjectRoot
    if ($null -ne $enforcementState -and $null -ne $enforcementState.State -and $enforcementState.State.enabled) {
        $existingContext = $enforcementState.Context
        $boundaryOrder = @(Get-SpecrewBoundaryOrder)
        $targetCanonical = Resolve-SpecrewCanonicalBoundaryType -Boundary $BoundaryType -ParameterName 'BoundaryType'
        $currentLastAuthorized = [string]$enforcementState.State['last_authorized_boundary']
        
        $targetIndex = [Array]::IndexOf($boundaryOrder, $targetCanonical)
        $lastAuthIndex = if (-not [string]::IsNullOrWhiteSpace($currentLastAuthorized)) {
            [Array]::IndexOf($boundaryOrder, $currentLastAuthorized)
        } else {
            -1
        }
        
        # Pillar 4 / T005 (Proposal 120, FR-021): record the crossing for any boundary CHANGE, not
        # only forward advances. The previous `-lt` gate silently skipped the append (and the AC8
        # hard-block) whenever last_authorized was stale/ahead of the target — the exact F-049 i005
        # symptom, where a prior-iteration `iteration-closeout` cursor swallowed real before-implement/
        # review-signoff/retro crossings. Only an identical-boundary re-sync is a benign no-op.
        if ($lastAuthIndex -ne $targetIndex) {
            if ($lastAuthIndex -gt $targetIndex) {
                Write-Warning ("Boundary sync: last_authorized_boundary '{0}' is AHEAD of the boundary now being crossed '{1}'. Recording the real crossing to prevent silent state progression (Pillar 4 / FR-021). If this is not a new-iteration reset, audit .specrew/start-context.json boundary_enforcement.verdict_history." -f $currentLastAuthorized, $targetCanonical)
            }
            $authorizingHuman = 'Specrew Operator'
            try {
                $gitUser = @(& git -C $paths.ProjectRoot config user.name 2>$null)
                if ($LASTEXITCODE -eq 0 -and $gitUser.Count -gt 0 -and -not [string]::IsNullOrWhiteSpace($gitUser[0])) {
                    $authorizingHuman = $gitUser[0].Trim()
                }
            } catch {}
            
            $currentBoundary = 'specify'
            if ($null -ne $existingContext -and $null -ne $existingContext['session_state'] -and -not [string]::IsNullOrWhiteSpace($existingContext['session_state']['boundary_type'])) {
                $currentBoundary = [string]$existingContext['session_state']['boundary_type']
            }
            elseif ($null -ne $latestBoundary) {
                $currentBoundary = [string]$latestBoundary.boundary_type
            }
            # Add-SpecrewBoundaryAuthorization rejects a backward from->to. In the stale-ahead /
            # new-iteration-reset case the recorded boundary_type can be >= the target, so clamp the
            # from_boundary to the target's canonical predecessor; the crossing still records (no
            # silent skip) with a valid forward from->to.
            $currentBoundaryCanonical = Normalize-SpecrewCanonicalBoundaryType -Boundary $currentBoundary
            $currentBoundaryIndex = [Array]::IndexOf($boundaryOrder, $currentBoundaryCanonical)
            if ($currentBoundaryIndex -lt 0 -or $currentBoundaryIndex -ge $targetIndex) {
                $currentBoundary = $boundaryOrder[[Math]::Max(0, $targetIndex - 1)]
            }
            $verdictText = "approved for $targetCanonical"

            Add-SpecrewBoundaryAuthorization `
                -ProjectRoot $paths.ProjectRoot `
                -CurrentBoundary $currentBoundary `
                -AuthorizedBoundary $targetCanonical `
                -AuthorizingHuman $authorizingHuman `
                -VerdictText $verdictText `
                -AuthCommitHash $effectiveAuthCommitHash | Out-Null
        }
    }

    Update-SpecrewStartContext -Path $paths.ContextPath -SessionState $sessionState
    Update-SpecrewMarkdownStateFile -Path $paths.IdentityPath -SessionState $sessionState -DefaultBody (Get-SpecrewIdentityBody -SessionState $sessionState) -AdditionalFrontmatter $identityAdditionalFrontmatter -PreferredBody $IdentityBody -UsePreferredBody:(-not [string]::IsNullOrWhiteSpace($IdentityBody)) -SchemaVersion 'v1'

    Add-SpecrewBoundarySyncLedgerEntry -ProjectRoot $paths.ProjectRoot -SessionState $sessionState

    # Proposal 085: append to the closed-iteration index at iteration-closeout
    # boundary (idempotent on re-sync). Validator full-repo path uses this to
    # skip closed iterations unless -IncludeClosed is set.
    if ($BoundaryType -eq 'iteration-closeout' -and -not [string]::IsNullOrWhiteSpace($effectiveFeatureRef) -and -not [string]::IsNullOrWhiteSpace($IterationNumber)) {
        try {
            Add-SpecrewClosedIterationEntry -ProjectRoot $paths.ProjectRoot -Feature $effectiveFeatureRef -Iteration $IterationNumber
        }
        catch {
            Write-Warning ("Boundary sync 'iteration-closeout' could not append to closed-iteration index: {0}" -f $_.Exception.Message)
        }

        # Proposal 046 (inline-ship per F-040 dogfooding 2026-05-23): auto-render the iteration
        # dashboard snapshot to specs/<feature>/iterations/<NNN>/dashboard.md so the historical
        # velocity / boundary / verdict view exists without the human having to invoke
        # `specrew where --capture-kind iteration-closeout` manually. Calc-v2 closed iteration
        # 001 without ever producing dashboard.md, which is the empirical motivation.
        try {
            $iterationDashboardPath = Join-Path $paths.ProjectRoot ("specs\{0}\iterations\{1}\dashboard.md" -f $effectiveFeatureRef, $IterationNumber)
            Invoke-SpecrewAutoRenderDashboard -ProjectRoot $paths.ProjectRoot -OutputPath $iterationDashboardPath -CaptureKind 'iteration-closeout' -FeatureRef $effectiveFeatureRef -IterationNumber $IterationNumber
        }
        catch {
            Write-Warning ("Boundary sync 'iteration-closeout' could not auto-render iteration dashboard: {0}" -f $_.Exception.Message)
        }
    }

    if ($BoundaryType -eq 'feature-closeout') {
        Clear-SpecrewActiveFeature -FeatureJsonPath $paths.FeatureJsonPath

        # Proposal 046 feature-level companion: auto-render specs/<feature>/closeout-dashboard.md
        # so the feature-wide rollup exists at feature-closeout without manual invocation.
        if (-not [string]::IsNullOrWhiteSpace($effectiveFeatureRef)) {
            try {
                $featureDashboardPath = Join-Path $paths.ProjectRoot ("specs\{0}\closeout-dashboard.md" -f $effectiveFeatureRef)
                Invoke-SpecrewAutoRenderDashboard -ProjectRoot $paths.ProjectRoot -OutputPath $featureDashboardPath -CaptureKind 'feature-closeout' -FeatureRef $effectiveFeatureRef -IterationNumber $null
            }
            catch {
                Write-Warning ("Boundary sync 'feature-closeout' could not auto-render closeout dashboard: {0}" -f $_.Exception.Message)
            }
        }
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
