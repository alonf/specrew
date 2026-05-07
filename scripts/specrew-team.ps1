[CmdletBinding(DefaultParameterSetName = 'List')]
param(
    [Parameter(Mandatory = $true, Position = 0)]
    [ValidateSet('add', 'update', 'remove', 'list')]
    [string]$Command,

    [Parameter(Mandatory = $false, Position = 1)]
    [string]$MemberName,

    [Parameter(Mandatory = $false)]
    [string]$Role,

    [Parameter(Mandatory = $false)]
    [string]$Charter,

    [Parameter(Mandatory = $false)]
    [string]$ProjectPath = '.'
)

# Handle Unix-style --flag arguments: Check $MyInvocation.UnboundArguments or re-parse $args
# If invoked with --role or --charter, they won't be bound to parameters
# Check for unbound arguments and re-invoke if needed
$unboundArgs = $MyInvocation.UnboundArguments
if ($unboundArgs -and ($unboundArgs -contains '--role' -or $unboundArgs -contains '--charter')) {
    # Reconstruct argument list with PowerShell-style parameters
    $newArgs = @($Command)
    if ($MemberName) { $newArgs += $MemberName }
    
    $skipNext = $false
    for ($i = 0; $i -lt $unboundArgs.Count; $i++) {
        if ($skipNext) {
            $skipNext = $false
            continue
        }
        
        $arg = $unboundArgs[$i]
        if ($arg -eq '--role') {
            $newArgs += '-Role'
            if ($i + 1 -lt $unboundArgs.Count) {
                $newArgs += $unboundArgs[$i + 1]
                $skipNext = $true
            }
        } elseif ($arg -eq '--charter') {
            $newArgs += '-Charter'
            if ($i + 1 -lt $unboundArgs.Count) {
                $newArgs += $unboundArgs[$i + 1]
                $skipNext = $true
            }
        } else {
            $newArgs += $arg
        }
    }
    
    if ($ProjectPath -ne '.') {
        $newArgs += '-ProjectPath'
        $newArgs += $ProjectPath
    }
    
    # Re-invoke with corrected arguments
    & $PSCommandPath @newArgs
    exit $LASTEXITCODE
}

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$BASELINE_ROLES = @(
    'spec-steward',
    'planner',
    'implementer',
    'reviewer',
    'retro-facilitator'
)

$BASELINE_ROLE_NAMES = @(
    'Spec Steward',
    'Planner',
    'Implementer',
    'Reviewer',
    'Retro Facilitator'
)

function Write-Success {
    param([string]$Message)
    Write-Host $Message -ForegroundColor Green
}

function Write-Error-Message {
    param([string]$Message)
    Write-Host "ERROR: $Message" -ForegroundColor Red
}

function Write-Info {
    param([string]$Message)
    Write-Host $Message -ForegroundColor Cyan
}

function Test-IsBaselineRole {
    param([string]$Name)
    
    $normalizedName = $Name.ToLower().Trim() -replace '\s+', '-'
    return $BASELINE_ROLES -contains $normalizedName
}

function Get-NormalizedMemberName {
    param([string]$Name)
    
    return $Name.ToLower().Trim() -replace '\s+', '-'
}

function Get-TeamFilePath {
    param([string]$Root)
    
    return Join-Path $Root '.squad\team.md'
}

function Get-AgentDirectory {
    param(
        [string]$Root,
        [string]$Name
    )
    
    $normalized = Get-NormalizedMemberName -Name $Name
    return Join-Path $Root ".squad\agents\$normalized"
}

function Test-SquadInitialized {
    param([string]$Root)
    
    $squadRoot = Join-Path $Root '.squad'
    if (-not (Test-Path -LiteralPath $squadRoot)) {
        Write-Error-Message "Squad has not been initialized. Missing '$squadRoot'."
        Write-Error-Message "Run 'specrew init' first to bootstrap the project."
        return $false
    }
    
    return $true
}

function Get-TeamContent {
    param([string]$TeamPath)
    
    if (-not (Test-Path -LiteralPath $TeamPath)) {
        return $null
    }
    
    return Get-Content -LiteralPath $TeamPath -Raw
}

function Test-MemberExists {
    param(
        [string]$TeamPath,
        [string]$MemberName
    )
    
    $content = Get-TeamContent -TeamPath $TeamPath
    if ($null -eq $content) {
        return $false
    }
    
    # Try exact role name match
    $escapedName = [regex]::Escape($MemberName)
    if ($content -match "(?m)^\|\s*$escapedName\s*\|") {
        return $true
    }
    
    # Try normalized directory name match
    $normalized = Get-NormalizedMemberName -Name $MemberName
    $escapedNormalized = [regex]::Escape($normalized)
    return $content -match "\.squad/agents/$escapedNormalized/"
}

function Test-MemberInManagedBlock {
    param(
        [string]$TeamPath,
        [string]$MemberName
    )
    
    $content = Get-TeamContent -TeamPath $TeamPath
    if ($null -eq $content) {
        return $false
    }
    
    $startMarker = '<!-- >>> specrew-managed baseline-roles >>> -->'
    $endMarker = '<!-- <<< specrew-managed baseline-roles <<< -->'
    
    if ($content -notmatch [regex]::Escape($startMarker)) {
        return $false
    }
    
    $pattern = "(?ms)$([regex]::Escape($startMarker)).*?$([regex]::Escape($endMarker))"
    if ($content -match $pattern) {
        $managedBlock = $matches[0]
        $escapedName = [regex]::Escape($MemberName)
        return $managedBlock -match "(?m)^\|\s*$escapedName\s*\|"
    }
    
    return $false
}

function Add-TeamMember {
    param(
        [string]$ProjectPath,
        [string]$MemberName,
        [string]$Role,
        [string]$Charter
    )
    
    $resolvedProjectPath = [System.IO.Path]::GetFullPath($ProjectPath)
    
    if (-not (Test-SquadInitialized -Root $resolvedProjectPath)) {
        return $false
    }
    
    $normalized = Get-NormalizedMemberName -Name $MemberName
    if (Test-IsBaselineRole -Name $normalized) {
        Write-Error-Message "Cannot add baseline role '$MemberName'. Baseline roles are protected."
        return $false
    }
    
    $teamPath = Get-TeamFilePath -Root $resolvedProjectPath
    if (Test-MemberExists -TeamPath $teamPath -MemberName $Role) {
        Write-Error-Message "Team member '$Role' already exists in .squad\team.md."
        return $false
    }
    
    $agentDir = Get-AgentDirectory -Root $resolvedProjectPath -Name $normalized
    if (Test-Path -LiteralPath $agentDir) {
        Write-Error-Message "Agent directory already exists: $agentDir"
        return $false
    }
    
    try {
        $null = New-Item -ItemType Directory -Path $agentDir -Force
        
        $charterPath = Join-Path $agentDir 'charter.md'
        $charterContent = @"
# $Role Charter

$Charter
"@
        [System.IO.File]::WriteAllText($charterPath, $charterContent, [System.Text.UTF8Encoding]::new($false))
        
        $historyPath = Join-Path $agentDir 'history.md'
        $historyContent = @"
# $Role History

Session notes and learnings for $Role.
"@
        [System.IO.File]::WriteAllText($historyPath, $historyContent, [System.Text.UTF8Encoding]::new($false))
        
        $teamContent = Get-TeamContent -TeamPath $teamPath
        if ($null -eq $teamContent) {
            $teamContent = "# Squad Team`n`n"
        }
        
        $teamEntry = "| $Role | ``.squad/agents/$normalized/charter.md`` | active |"
        
        $endMarker = '<!-- <<< specrew-managed baseline-roles <<< -->'
        
        # Always add domain-specific members AFTER the managed block
        if ($teamContent -match [regex]::Escape($endMarker)) {
            # Check if Domain-Specific Members section exists after the managed block
            $afterManagedPattern = "(?ms)$([regex]::Escape($endMarker))(.*)"
            if ($teamContent -match $afterManagedPattern) {
                $afterManaged = $matches[1]
                
                if ($afterManaged -match '## Domain-Specific Members') {
                    # Section exists, add to it
                    $sectionPattern = '(?ms)(## Domain-Specific Members.*?\| ---- \| ------- \| ------ \|\r?\n)'
                    $updatedContent = [regex]::Replace($teamContent, $sectionPattern, "`${1}$teamEntry`n", 1)
                } else {
                    # Section doesn't exist, create it after the managed block
                    $updatedContent = [regex]::Replace($teamContent, [regex]::Escape($endMarker), "$endMarker`n`n## Domain-Specific Members`n`n| Role | Charter | Status |`n| ---- | ------- | ------ |`n$teamEntry", 1)
                }
            } else {
                $updatedContent = $teamContent.TrimEnd() + "`n`n## Domain-Specific Members`n`n| Role | Charter | Status |`n| ---- | ------- | ------ |`n$teamEntry`n"
            }
        } else {
            $updatedContent = $teamContent.TrimEnd() + "`n`n## Domain-Specific Members`n`n| Role | Charter | Status |`n| ---- | ------- | ------ |`n$teamEntry`n"
        }
        
        [System.IO.File]::WriteAllText($teamPath, $updatedContent, [System.Text.UTF8Encoding]::new($false))
        
        Write-Success "✓ Added team member '$Role'"
        Write-Info "  Charter: $charterPath"
        Write-Info "  History: $historyPath"
        Write-Info "  Team entry: $teamPath"
        
        return $true
    }
    catch {
        Write-Error-Message "Failed to add team member: $_"
        return $false
    }
}

function Update-TeamMember {
    param(
        [string]$ProjectPath,
        [string]$MemberName,
        [string]$Role,
        [string]$Charter
    )
    
    $resolvedProjectPath = [System.IO.Path]::GetFullPath($ProjectPath)
    
    if (-not (Test-SquadInitialized -Root $resolvedProjectPath)) {
        return $false
    }
    
    $normalized = Get-NormalizedMemberName -Name $MemberName
    if (Test-IsBaselineRole -Name $normalized) {
        Write-Error-Message "Cannot update baseline role '$MemberName'. Baseline roles are protected."
        return $false
    }
    
    $teamPath = Get-TeamFilePath -Root $resolvedProjectPath
    if (-not (Test-MemberExists -TeamPath $teamPath -MemberName $MemberName)) {
        Write-Error-Message "Team member '$MemberName' does not exist."
        return $false
    }
    
    if (Test-MemberInManagedBlock -TeamPath $teamPath -MemberName $MemberName) {
        Write-Error-Message "Cannot update baseline role '$MemberName'. Baseline roles are protected."
        return $false
    }
    
    $agentDir = Get-AgentDirectory -Root $resolvedProjectPath -Name $normalized
    if (-not (Test-Path -LiteralPath $agentDir)) {
        Write-Error-Message "Agent directory not found: $agentDir"
        return $false
    }
    
    try {
        $updated = $false
        
        if ($Charter) {
            $charterPath = Join-Path $agentDir 'charter.md'
            $existingContent = Get-Content -LiteralPath $charterPath -Raw -ErrorAction SilentlyContinue
            
            $roleTitle = if ($Role) { $Role } else {
                if ($existingContent -match '(?m)^# (.+) Charter') {
                    $matches[1]
                } else {
                    $MemberName
                }
            }
            
            $charterContent = @"
# $roleTitle Charter

$Charter
"@
            [System.IO.File]::WriteAllText($charterPath, $charterContent, [System.Text.UTF8Encoding]::new($false))
            Write-Info "  Updated charter: $charterPath"
            $updated = $true
        }
        
        if ($Role -and -not $Charter) {
            $teamContent = Get-TeamContent -TeamPath $teamPath
            $escapedOldName = [regex]::Escape($MemberName)
            $pattern = "(?m)^(\|\s*)$escapedOldName(\s*\|.+)$"
            $replacement = "`${1}$Role`${2}"
            $updatedContent = [regex]::Replace($teamContent, $pattern, $replacement)
            
            if ($updatedContent -ne $teamContent) {
                [System.IO.File]::WriteAllText($teamPath, $updatedContent, [System.Text.UTF8Encoding]::new($false))
                Write-Info "  Updated role name in team.md"
                $updated = $true
            }
        }
        
        if ($updated) {
            Write-Success "✓ Updated team member '$MemberName'"
            return $true
        } else {
            Write-Error-Message "No updates specified. Use -Role or -Charter to update member."
            return $false
        }
    }
    catch {
        Write-Error-Message "Failed to update team member: $_"
        return $false
    }
}

function Remove-TeamMember {
    param(
        [string]$ProjectPath,
        [string]$MemberName
    )
    
    $resolvedProjectPath = [System.IO.Path]::GetFullPath($ProjectPath)
    
    if (-not (Test-SquadInitialized -Root $resolvedProjectPath)) {
        return $false
    }
    
    $normalized = Get-NormalizedMemberName -Name $MemberName
    if (Test-IsBaselineRole -Name $normalized) {
        Write-Error-Message "Cannot remove baseline role '$MemberName'. Baseline roles are protected."
        return $false
    }
    
    $teamPath = Get-TeamFilePath -Root $resolvedProjectPath
    if (-not (Test-MemberExists -TeamPath $teamPath -MemberName $MemberName)) {
        Write-Error-Message "Team member '$MemberName' does not exist."
        return $false
    }
    
    if (Test-MemberInManagedBlock -TeamPath $teamPath -MemberName $MemberName) {
        Write-Error-Message "Cannot remove baseline role '$MemberName'. Baseline roles are protected."
        return $false
    }
    
    try {
        $agentDir = Get-AgentDirectory -Root $resolvedProjectPath -Name $normalized
        if (Test-Path -LiteralPath $agentDir) {
            Remove-Item -Path $agentDir -Recurse -Force
            Write-Info "  Removed agent directory: $agentDir"
        }
        
        $teamContent = Get-TeamContent -TeamPath $teamPath
        
        # Remove by directory path match - backticks need proper escaping
        # Match: | Role Name | `.squad/agents/normalized/charter.md` | status |
        $pattern = "(?m)^\|[^|]+\|\s*``\.squad/agents/$normalized/[^``]+``\s*\|[^|]+\|\r?\n"
        $updatedContent = [regex]::Replace($teamContent, $pattern, '')
        
        [System.IO.File]::WriteAllText($teamPath, $updatedContent, [System.Text.UTF8Encoding]::new($false))
        
        Write-Success "✓ Removed team member '$MemberName'"
        return $true
    }
    catch {
        Write-Error-Message "Failed to remove team member: $_"
        return $false
    }
}

function Get-TeamMembers {
    param([string]$ProjectPath)
    
    $resolvedProjectPath = [System.IO.Path]::GetFullPath($ProjectPath)
    
    if (-not (Test-SquadInitialized -Root $resolvedProjectPath)) {
        return $false
    }
    
    $teamPath = Get-TeamFilePath -Root $resolvedProjectPath
    $content = Get-TeamContent -TeamPath $teamPath
    
    if ($null -eq $content) {
        Write-Info "No team members found."
        return $true
    }
    
    Write-Host "`nSquad Team Members:`n" -ForegroundColor Cyan
    
    $startMarker = '<!-- >>> specrew-managed baseline-roles >>> -->'
    $endMarker = '<!-- <<< specrew-managed baseline-roles <<< -->'
    
    if ($content -match "(?ms)$([regex]::Escape($startMarker))(.*?)$([regex]::Escape($endMarker))") {
        $baselineBlock = $matches[1]
        Write-Host "Baseline Roles (protected):" -ForegroundColor Yellow
        $baselineBlock -split '\r?\n' | Where-Object { $_ -match '^\|' -and $_ -notmatch '^\| Role \|' -and $_ -notmatch '^\| ---- \|' } | ForEach-Object {
            Write-Host "  $_" -ForegroundColor White
        }
        Write-Host ""
    }
    
    if ($content -match '## Domain-Specific Members') {
        Write-Host "Domain-Specific Members:" -ForegroundColor Green
        
        $domainPattern = '(?ms)## Domain-Specific Members.*?\| ---- \| ------- \| ------ \|(.*?)(?=\r?\n##|\r?\n<!--|\z)'
        if ($content -match $domainPattern) {
            $domainBlock = $matches[1]
            $domainBlock -split '\r?\n' | Where-Object { $_ -match '^\|' } | ForEach-Object {
                Write-Host "  $_" -ForegroundColor White
            }
        }
    }
    
    return $true
}

$resolvedProjectPath = [System.IO.Path]::GetFullPath($ProjectPath)

switch ($Command) {
    'add' {
        if (-not $MemberName) {
            Write-Error-Message "Member name is required for 'add' command."
            Write-Host "Usage: specrew team add <member-name> --role <role> --charter <charter-text>"
            exit 1
        }
        
        if (-not $Role) {
            Write-Error-Message "Role is required for 'add' command."
            Write-Host "Usage: specrew team add <member-name> --role <role> --charter <charter-text>"
            exit 1
        }
        
        if (-not $Charter) {
            Write-Error-Message "Charter is required for 'add' command."
            Write-Host "Usage: specrew team add <member-name> --role <role> --charter <charter-text>"
            exit 1
        }
        
        $success = Add-TeamMember -ProjectPath $resolvedProjectPath -MemberName $MemberName -Role $Role -Charter $Charter
        exit $(if ($success) { 0 } else { 1 })
    }
    
    'update' {
        if (-not $MemberName) {
            Write-Error-Message "Member name is required for 'update' command."
            Write-Host "Usage: specrew team update <member-name> [--role <role>] [--charter <charter-text>]"
            exit 1
        }
        
        if (-not $Role -and -not $Charter) {
            Write-Error-Message "At least one of --role or --charter is required for 'update' command."
            Write-Host "Usage: specrew team update <member-name> [--role <role>] [--charter <charter-text>]"
            exit 1
        }
        
        $success = Update-TeamMember -ProjectPath $resolvedProjectPath -MemberName $MemberName -Role $Role -Charter $Charter
        exit $(if ($success) { 0 } else { 1 })
    }
    
    'remove' {
        if (-not $MemberName) {
            Write-Error-Message "Member name is required for 'remove' command."
            Write-Host "Usage: specrew team remove <member-name>"
            exit 1
        }
        
        $success = Remove-TeamMember -ProjectPath $resolvedProjectPath -MemberName $MemberName
        exit $(if ($success) { 0 } else { 1 })
    }
    
    'list' {
        $success = Get-TeamMembers -ProjectPath $resolvedProjectPath
        exit $(if ($success) { 0 } else { 1 })
    }
}
