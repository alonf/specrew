[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$ProjectPath,

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

function Add-DeploymentAction {
    param(
        [AllowEmptyCollection()]
        [Parameter(Mandatory = $true)]
        [System.Collections.ArrayList]$Actions,

        [Parameter(Mandatory = $true)]
        [string]$Action,

        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    $null = $Actions.Add([pscustomobject]@{
            Action = $Action
            Path   = $Path
        })
}

function Ensure-Directory {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [AllowEmptyCollection()]
        [Parameter(Mandatory = $true)]
        [System.Collections.ArrayList]$Actions
    )

    if (Test-Path -LiteralPath $Path) {
        Add-DeploymentAction -Actions $Actions -Action 'preserved-directory' -Path $Path
        return
    }

    Add-DeploymentAction -Actions $Actions -Action $(if ($DryRun) { 'would-create-directory' } else { 'created-directory' }) -Path $Path
    if (-not $DryRun) {
        New-Item -ItemType Directory -Path $Path -Force | Out-Null
    }
}

function Write-MissingFile {
    param(
        [Parameter(Mandatory = $true)]
        [string]$TargetPath,

        [Parameter(Mandatory = $true)]
        [string]$Content,

        [AllowEmptyCollection()]
        [Parameter(Mandatory = $true)]
        [System.Collections.ArrayList]$Actions
    )

    if (Test-Path -LiteralPath $TargetPath) {
        Add-DeploymentAction -Actions $Actions -Action 'preserved' -Path $TargetPath
        return
    }

    Add-DeploymentAction -Actions $Actions -Action $(if ($DryRun) { 'would-create' } else { 'created' }) -Path $TargetPath
    if (-not $DryRun) {
        $parent = Split-Path -Parent $TargetPath
        if (-not (Test-Path -LiteralPath $parent)) {
            New-Item -ItemType Directory -Path $parent -Force | Out-Null
        }

        [System.IO.File]::WriteAllText($TargetPath, $Content, [System.Text.UTF8Encoding]::new($false))
    }
}

function Assert-ManagedTargetContained {
    # Lexical containment is NOT containment. GetFullPath folds '..' and separators, but a path whose
    # ANCESTOR is a symlink/junction to an external directory still compares as under the root while
    # ReadAllText/WriteAllText follow that ancestor outside the project. Every managed file this
    # deployment writes goes through Set-ManagedFile, so a project-controlled junction - say at
    # `scripts/internal/continuous-co-review` - could redirect `specrew update` writes onto arbitrary
    # external files (co-review finding, run run-f198-i009-aab37c3b-codex-2). This is the same
    # containment class DRIFT-198-I009-011 closed for the RETIREMENT path; the WRITE path was never
    # covered. Reject a reparse point at the root and at EVERY existing component beneath it, then
    # re-verify containment before any read or write.
    param(
        [Parameter(Mandatory = $true)]
        [string]$TargetPath,

        [Parameter(Mandatory = $true)]
        [string]$Root
    )

    $rootFull = [System.IO.Path]::GetFullPath($Root).TrimEnd([System.IO.Path]::DirectorySeparatorChar, [System.IO.Path]::AltDirectorySeparatorChar)
    $pathFull = [System.IO.Path]::GetFullPath($TargetPath)
    $prefix = $rootFull + [System.IO.Path]::DirectorySeparatorChar
    # ORDINAL, unconditionally - and deliberately NOT an `$IsWindows` branch. This tree is deployed
    # into consumer projects where the continuous-co-review path-identity primitive is not present,
    # so the rule cannot be derived from the volume here. Ordinal is the FAIL-CLOSED direction for
    # THIS guard: its polarity is "must be INSIDE, else refuse", so folding case would accept a
    # case-aliased path as contained and let the write escape. Refusing a genuine case-variant instead
    # fails loudly and visibly. In practice both sides derive from the same resolved project path, so
    # their prefixes match exactly. (An OS-family branch here would be the DRIFT-198-I009-027 defect
    # class re-entering a tree the primitive cannot reach.)
    $comparison = [System.StringComparison]::Ordinal
    if (-not $pathFull.StartsWith($prefix, $comparison)) {
        throw "managed-deploy-path-escapes-project:$TargetPath"
    }

    $rootItem = Get-Item -LiteralPath $rootFull -Force -ErrorAction Stop
    if (($rootItem.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0) {
        throw "managed-deploy-root-link-unsupported:$Root"
    }

    $relative = $pathFull.Substring($rootFull.Length).Trim([System.IO.Path]::DirectorySeparatorChar, [System.IO.Path]::AltDirectorySeparatorChar)
    $current = $rootFull
    foreach ($segment in @($relative -split '[\\/]' | Where-Object { -not [string]::IsNullOrEmpty($_) })) {
        $current = Join-Path $current $segment
        if (-not (Test-Path -LiteralPath $current)) { continue }
        $item = Get-Item -LiteralPath $current -Force -ErrorAction Stop
        if (($item.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0) {
            throw "managed-deploy-path-link-unsupported:$TargetPath"
        }
    }
    return $pathFull
}

function Set-ManagedFile {
    param(
        [Parameter(Mandatory = $true)]
        [string]$TargetPath,

        [Parameter(Mandatory = $true)]
        [string]$Content,

        [AllowEmptyCollection()]
        [Parameter(Mandatory = $true)]
        [System.Collections.ArrayList]$Actions
    )

    # Containment BEFORE the first read or write - never after. Resolved via Get-Variable so this
    # stays safe under StrictMode when the helper is dot-sourced without the script body having run.
    $projectRootVariable = Get-Variable -Name 'resolvedProjectPath' -Scope Script -ErrorAction SilentlyContinue
    $projectRoot = if ($null -ne $projectRootVariable) { [string]$projectRootVariable.Value } else { '' }
    if (-not [string]::IsNullOrWhiteSpace($projectRoot)) {
        $null = Assert-ManagedTargetContained -TargetPath $TargetPath -Root $projectRoot
    }

    if (-not (Test-Path -LiteralPath $TargetPath)) {
        Add-DeploymentAction -Actions $Actions -Action $(if ($DryRun) { 'would-create' } else { 'created' }) -Path $TargetPath
        if (-not $DryRun) {
            $parent = Split-Path -Parent $TargetPath
            if (-not (Test-Path -LiteralPath $parent)) {
                New-Item -ItemType Directory -Path $parent -Force | Out-Null
            }

            [System.IO.File]::WriteAllText($TargetPath, $Content, [System.Text.UTF8Encoding]::new($false))
        }

        return
    }

    $existingContent = Get-Content -LiteralPath $TargetPath -Raw
    if ($existingContent -eq $Content) {
        Add-DeploymentAction -Actions $Actions -Action 'preserved' -Path $TargetPath
        return
    }

    Add-DeploymentAction -Actions $Actions -Action $(if ($DryRun) { 'would-update' } else { 'updated' }) -Path $TargetPath
    if (-not $DryRun) {
        [System.IO.File]::WriteAllText($TargetPath, $Content, [System.Text.UTF8Encoding]::new($false))
    }
}

function Copy-ManagedDirectory {
    param(
        [Parameter(Mandatory = $true)]
        [string]$SourcePath,

        [Parameter(Mandatory = $true)]
        [string]$TargetPath,

        [AllowEmptyCollection()]
        [Parameter(Mandatory = $true)]
        [System.Collections.ArrayList]$Actions
    )

    if (-not (Test-Path -LiteralPath $SourcePath -PathType Container)) {
        throw "Managed runtime source directory not found: $SourcePath"
    }

    Ensure-Directory -Path $TargetPath -Actions $Actions
    foreach ($sourceFile in @(Get-ChildItem -LiteralPath $SourcePath -File -Recurse | Sort-Object FullName)) {
        $relativePath = [System.IO.Path]::GetRelativePath((Resolve-Path -LiteralPath $SourcePath).Path, $sourceFile.FullName)
        $targetFile = Join-Path $TargetPath $relativePath
        Set-ManagedFile -TargetPath $targetFile -Content (Get-Content -LiteralPath $sourceFile.FullName -Raw -Encoding UTF8) -Actions $Actions
    }
}

function Remove-RetiredManagedRuntimeFiles {
    param(
        [Parameter(Mandatory = $true)][string]$TargetRoot,
        [AllowEmptyCollection()][Parameter(Mandatory = $true)][object[]]$PreviousManagedFiles,
        [AllowEmptyCollection()][Parameter(Mandatory = $true)][object[]]$CurrentManagedFiles,
        [AllowEmptyCollection()][Parameter(Mandatory = $true)][System.Collections.ArrayList]$Actions
    )

    $root = [IO.Path]::GetFullPath($TargetRoot)
    $currentPaths = [Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
    foreach ($entry in @($CurrentManagedFiles)) { $null = $currentPaths.Add([string]$entry.path) }

    foreach ($entry in @($PreviousManagedFiles)) {
        $relative = [string]$entry.path
        if ($currentPaths.Contains($relative)) { continue }
        $full = [IO.Path]::GetFullPath((Join-Path $root $relative))
        if (-not (Test-SpecrewReviewRuntimePathUnderRoot -Path $full -Root $root) -or $full -ceq $root) {
            throw "managed-runtime-retirement-path-unsafe:$relative"
        }
        if (-not (Test-Path -LiteralPath $full)) { continue }
        # Contain EVERY existing component before touching the file. A reparse-point ancestor passes
        # the lexical under-root test above while Get-Item/hash/Delete follow it outside the project,
        # and the marker supplying this path and hash is editable in the target project. Preserve
        # rather than delete when any component is a link.
        try { $full = Assert-SpecrewReviewRuntimePathContained -Path $full -Root $root }
        catch {
            Add-DeploymentAction -Actions $Actions -Action 'preserved-uncontained-retired-runtime-file' -Path $full
            continue
        }
        $item = Get-Item -LiteralPath $full -Force
        if ($item.PSIsContainer -or (($item.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0)) {
            Add-DeploymentAction -Actions $Actions -Action 'preserved-modified-retired-runtime-file' -Path $full
            continue
        }
        $actualHash = Get-SpecrewReviewRuntimeManagedTextSha256 -Path $full
        if ($actualHash -cne [string]$entry.sha256) {
            Add-DeploymentAction -Actions $Actions -Action 'preserved-modified-retired-runtime-file' -Path $full
            continue
        }
        Add-DeploymentAction -Actions $Actions -Action $(if ($DryRun) { 'would-remove-retired-runtime-file' } else { 'removed-retired-runtime-file' }) -Path $full
        if ($DryRun) { continue }
        [IO.File]::Delete($full)
        for ($parent = Split-Path -Parent $full;
            -not [string]::IsNullOrWhiteSpace($parent) -and
            (Test-SpecrewReviewRuntimePathUnderRoot -Path $parent -Root $root) -and
            $parent -cne $root;
            $parent = Split-Path -Parent $parent) {
            if (-not [IO.Directory]::Exists($parent) -or [IO.Directory]::GetFileSystemEntries($parent).Count -ne 0) { break }
            [IO.Directory]::Delete($parent, $false)
        }
    }
}

function Get-ManagedBlock {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,

        [Parameter(Mandatory = $true)]
        [string]$Content
    )

    return @(
        "<!-- >>> specrew-managed $Name >>> -->"
        $Content.Trim()
        "<!-- <<< specrew-managed $Name <<< -->"
    ) -join [Environment]::NewLine
}

function Remove-LegacyManagedContent {
    param(
        [Parameter(Mandatory = $true)]
        [string]$BlockName,

        [Parameter(Mandatory = $true)]
        [string]$ExistingContent
    )

    $updatedContent = $ExistingContent
    $migrated = $false

    switch ($BlockName) {
        'ceremonies' {
            $legacyPattern = '(?ms)\s*<!-- specrew:ceremony:[^>]+:start -->.*?<!-- specrew:ceremony:[^>]+:end -->\s*'
            $replacement = [regex]::Replace($updatedContent, $legacyPattern, [Environment]::NewLine + [Environment]::NewLine)
            if ($replacement -ne $updatedContent) {
                $updatedContent = $replacement
                $migrated = $true
            }
        }
        'directives' {
            $legacyPattern = '(?ms)\s*## Specrew Directives\s*(?:\r?\n)+(?:<!-- specrew:directive:[^>]+:start -->.*?<!-- specrew:directive:[^>]+:end -->\s*)+'
            $replacement = [regex]::Replace($updatedContent, $legacyPattern, [Environment]::NewLine + [Environment]::NewLine)
            if ($replacement -ne $updatedContent) {
                $updatedContent = $replacement
                $migrated = $true
            }
        }
        'baseline-roles' {
            $legacyRows = @(
                'Spec Steward',
                'Planner',
                'Implementer',
                'Reviewer',
                'Retro Facilitator'
            ) | ForEach-Object { [regex]::Escape($_) }
            $legacyRowPattern = '(?m)^\|\s*[^|]+\s*\|\s*(?:' + ($legacyRows -join '|') + ')\s*\|.*\r?\n?'
            $replacement = [regex]::Replace($updatedContent, $legacyRowPattern, '')
            if ($replacement -ne $updatedContent) {
                $updatedContent = $replacement
                $migrated = $true
            }
        }
    }

    if ($migrated) {
        $updatedContent = [regex]::Replace($updatedContent, '(?m)(\r?\n){3,}', [Environment]::NewLine + [Environment]::NewLine)
        $updatedContent = $updatedContent.TrimEnd()
        if (-not [string]::IsNullOrWhiteSpace($updatedContent)) {
            $updatedContent += [Environment]::NewLine
        }
    }

    return [pscustomobject]@{
        Migrated = $migrated
        Content  = $updatedContent
    }
}

function Set-ManagedBlock {
    param(
        [Parameter(Mandatory = $true)]
        [string]$TargetPath,

        [Parameter(Mandatory = $true)]
        [string]$BlockName,

        [Parameter(Mandatory = $true)]
        [string]$ManagedContent,

        [string]$BaseContentIfMissing = '',

        [AllowEmptyCollection()]
        [Parameter(Mandatory = $true)]
        [System.Collections.ArrayList]$Actions
    )

    $managedBlock = Get-ManagedBlock -Name $BlockName -Content $ManagedContent
    $startMarker = [regex]::Escape("<!-- >>> specrew-managed $BlockName >>> -->")
    $endMarker = [regex]::Escape("<!-- <<< specrew-managed $BlockName <<< -->")
    $managedPattern = "(?ms)\s*$startMarker.*?$endMarker\s*"

    if (-not (Test-Path -LiteralPath $TargetPath)) {
        Add-DeploymentAction -Actions $Actions -Action $(if ($DryRun) { 'would-create' } else { 'created' }) -Path $TargetPath
        if (-not $DryRun) {
            $parent = Split-Path -Parent $TargetPath
            if (-not (Test-Path -LiteralPath $parent)) {
                New-Item -ItemType Directory -Path $parent -Force | Out-Null
            }

            $parts = @()
            if (-not [string]::IsNullOrWhiteSpace($BaseContentIfMissing)) {
                $parts += $BaseContentIfMissing.TrimEnd()
            }

            $parts += $managedBlock
            $content = ($parts -join ([Environment]::NewLine + [Environment]::NewLine)) + [Environment]::NewLine
            [System.IO.File]::WriteAllText($TargetPath, $content, [System.Text.UTF8Encoding]::new($false))
        }

        return
    }

    $existingContent = Get-Content -LiteralPath $TargetPath -Raw
    $legacyMigration = Remove-LegacyManagedContent -BlockName $BlockName -ExistingContent $existingContent
    if ($legacyMigration.Migrated) {
        $existingContent = $legacyMigration.Content
    }

    if ($existingContent -match $managedPattern) {
        $updatedContent = [regex]::Replace($existingContent, $managedPattern, ([Environment]::NewLine + [Environment]::NewLine + $managedBlock + [Environment]::NewLine + [Environment]::NewLine))
    }
    else {
        $trimmedExistingContent = $existingContent.TrimEnd()
        if ([string]::IsNullOrWhiteSpace($trimmedExistingContent)) {
            $updatedContent = $managedBlock
        }
        else {
            $updatedContent = $trimmedExistingContent + [Environment]::NewLine + [Environment]::NewLine + $managedBlock
        }
    }

    $updatedContent = $updatedContent.TrimEnd() + [Environment]::NewLine
    if ($updatedContent -eq $existingContent) {
        Add-DeploymentAction -Actions $Actions -Action 'preserved' -Path $TargetPath
        return
    }

    Add-DeploymentAction -Actions $Actions -Action $(if ($DryRun) { 'would-update' } else { 'updated' }) -Path $TargetPath
    if (-not $DryRun) {
        [System.IO.File]::WriteAllText($TargetPath, $updatedContent, [System.Text.UTF8Encoding]::new($false))
    }
}

function Set-ManagedTableRows {
    param(
        [Parameter(Mandatory = $true)]
        [string]$TargetPath,

        [Parameter(Mandatory = $true)]
        [string]$TableSectionHeader,

        [Parameter(Mandatory = $true)]
        [string[]]$Rows,

        [AllowEmptyCollection()]
        [Parameter(Mandatory = $true)]
        [System.Collections.ArrayList]$Actions
    )

    if (-not (Test-Path -LiteralPath $TargetPath)) {
        return
    }

    $existingContent = Get-Content -LiteralPath $TargetPath -Raw
    
    $escapedHeader = [regex]::Escape($TableSectionHeader)
    $tablePattern = "($escapedHeader[^\r\n]*\r?\n(?:.*?\r?\n)*?\|[^\r\n]+\|\r?\n\|[\s\-|]+\|\r?\n)"
    
    if ($existingContent -match $tablePattern) {
        $headerAndSeparator = $Matches[1]
        
        $index = $existingContent.IndexOf($headerAndSeparator)
        if ($index -lt 0) { return }
        
        $postTableContent = $existingContent.Substring($index + $headerAndSeparator.Length)
        
        $existingBodyLines = [System.Collections.Generic.List[string]]::new()
        $lines = $postTableContent -split '\r?\n'
        $tableEndIndex = 0
        foreach ($line in $lines) {
            if ($line -match '^\s*\|') {
                $null = $existingBodyLines.Add($line)
                $tableEndIndex++
            }
            else {
                break
            }
        }
        
        $trailingLines = $lines[$tableEndIndex..($lines.Count - 1)]
        $trailingContent = $trailingLines -join [Environment]::NewLine
        
        $newKeys = @{}
        foreach ($newRow in $Rows) {
            $key = Get-TableRowKey -RowLine $newRow
            if ($key) {
                $newKeys[$key] = $newRow
            }
        }
        
        $mergedBodyLines = [System.Collections.Generic.List[string]]::new()
        foreach ($newRow in $Rows) {
            $null = $mergedBodyLines.Add($newRow)
        }
        
        foreach ($existingRow in $existingBodyLines) {
            $key = Get-TableRowKey -RowLine $existingRow
            if ($key -and -not $newKeys.ContainsKey($key)) {
                $null = $mergedBodyLines.Add($existingRow)
            }
        }
        
        $preContent = $existingContent.Substring(0, $index)
        $bodyContent = ($mergedBodyLines | ForEach-Object { $_ + [Environment]::NewLine }) -join ''
        
        $updatedContent = $preContent + $headerAndSeparator + $bodyContent
        if (-not [string]::IsNullOrWhiteSpace($trailingContent)) {
            $updatedContent += $trailingContent
        }
        
        if ($updatedContent -ne $existingContent) {
            Add-DeploymentAction -Actions $Actions -Action $(if ($DryRun) { 'would-update' } else { 'updated' }) -Path $TargetPath
            if (-not $DryRun) {
                [System.IO.File]::WriteAllText($TargetPath, $updatedContent, [System.Text.UTF8Encoding]::new($false))
            }
        }
        else {
            Add-DeploymentAction -Actions $Actions -Action 'preserved' -Path $TargetPath
        }
    }
    else {
        Add-DeploymentAction -Actions $Actions -Action 'preserved' -Path $TargetPath
    }
}

function Get-TableRowKey {
    param([string]$RowLine)
    $parts = $RowLine -split '\|'
    if ($parts.Count -gt 1) {
        return $parts[1].Trim()
    }
    return $null
}

function Get-DirectiveDeployment {
    param(
        [Parameter(Mandatory = $true)]
        [string]$DirectivePath
    )

    $content = Get-Content -LiteralPath $DirectivePath -Raw
    $directiveTitlePattern = [regex]::new('^\s*#\s*Directive:\s*', [System.Text.RegularExpressions.RegexOptions]::Multiline)
    $content = $directiveTitlePattern.Replace($content, '## ', 1)
    $content = [regex]::Replace($content, '(?ms)\r?\n---\r?\n\r?\n\*\*Deployment\*\*:.*$', '')
    return $content.Trim()
}

function Get-BaselineRoleDefinitions {
    return @(
        [pscustomobject]@{
            Name           = 'Spec Steward'
            AgentDirectory = 'spec-steward'
            TemplatePath   = 'agents/spec-steward/charter.md'
            DirectivePaths = @('directives/spec-authority.md')
        }
        [pscustomobject]@{
            Name           = 'Planner'
            AgentDirectory = 'planner'
            TemplatePath   = 'agents/planner/charter.md'
            DirectivePaths = @('directives/spec-authority.md', 'directives/traceability.md')
        }
        [pscustomobject]@{
            Name           = 'Implementer'
            AgentDirectory = 'implementer'
            TemplatePath   = 'agents/implementer/charter.md'
            DirectivePaths = @('directives/spec-authority.md', 'directives/drift-reporting.md')
        }
        [pscustomobject]@{
            Name           = 'Reviewer'
            AgentDirectory = 'reviewer'
            TemplatePath   = 'agents/reviewer/charter.md'
            DirectivePaths = @('directives/spec-authority.md', 'directives/drift-reporting.md')
        }
        [pscustomobject]@{
            Name           = 'Retro Facilitator'
            AgentDirectory = 'retro-facilitator'
            TemplatePath   = 'agents/retro-facilitator/charter.md'
            DirectivePaths = @('directives/spec-authority.md')
        }
    )
}

function Get-ActiveSkillRoots {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectPath
    )

    return @(
        [pscustomobject]@{ Name = 'claude'; Path = Join-Path $ProjectPath '.claude\skills' }
        [pscustomobject]@{ Name = 'cursor'; Path = Join-Path $ProjectPath '.cursor\rules' }
        [pscustomobject]@{ Name = 'github'; Path = Join-Path $ProjectPath '.github\skills' }
        [pscustomobject]@{ Name = 'agents'; Path = Join-Path $ProjectPath '.agents\skills' }
    )
}

function Get-SlashCommandSkillCatalog {
    return @(
        [pscustomobject]@{ Directory = 'specrew-help'; Name = 'help'; LegacySlashCommand = '/specrew.help' }
        [pscustomobject]@{ Directory = 'specrew-review'; Name = 'review'; LegacySlashCommand = '/specrew.review' }
        [pscustomobject]@{ Directory = 'specrew-status'; Name = 'status'; LegacySlashCommand = '/specrew.status' }
        [pscustomobject]@{ Directory = 'specrew-team'; Name = 'team'; LegacySlashCommand = '/specrew.team' }
        [pscustomobject]@{ Directory = 'specrew-update'; Name = 'update'; LegacySlashCommand = '/specrew.update' }
        [pscustomobject]@{ Directory = 'specrew-version'; Name = 'version'; LegacySlashCommand = '/specrew.version' }
        [pscustomobject]@{ Directory = 'specrew-where'; Name = 'where'; LegacySlashCommand = '/specrew.where' }
    )
}

function Get-ManagedSkillMarkerContent {
    param(
        [Parameter(Mandatory = $true)]
        [string]$SkillDirectory
    )

    return @(
        'schema: v1'
        'owner: specrew'
        'kind: project-skill'
        ('directory: {0}' -f $SkillDirectory)
    ) -join [Environment]::NewLine
}

function Get-SpecrewSkillHostScopes {
    param(
        [AllowEmptyString()]
        [Parameter(Mandatory = $true)]
        [string]$Content
    )

    $defaultScopes = @('all')
    if ([string]::IsNullOrWhiteSpace($Content)) {
        return $defaultScopes
    }

    $frontmatterMatch = [regex]::Match($Content, '(?s)^---\r?\n(?<frontmatter>.*?)\r?\n---')
    if (-not $frontmatterMatch.Success) {
        return $defaultScopes
    }

    $scopeMatch = [regex]::Match($frontmatterMatch.Groups['frontmatter'].Value, '(?m)^\s*host-scope\s*:\s*(?<value>.+?)\s*$')
    if (-not $scopeMatch.Success) {
        return $defaultScopes
    }

    $rawValue = $scopeMatch.Groups['value'].Value.Trim().Trim('[', ']')
    $scopes = @(
        $rawValue -split ',' |
            ForEach-Object { $_.Trim().Trim('"', "'").ToLowerInvariant() } |
            Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
    )

    if ($scopes.Count -eq 0 -or $scopes -contains 'all') {
        return $defaultScopes
    }

    return $scopes
}

function Get-SpecrewSkillContentForHost {
    param(
        [AllowEmptyString()]
        [Parameter(Mandatory = $true)]
        [string]$Content,

        [Parameter(Mandatory = $true)]
        [string]$HostName
    )

    # Some skill capabilities are host-specific even though the conduct itself is shared.
    # Keep the canonical metadata explicit, then materialize only the frontmatter understood
    # by that host. In particular, Claude's AskUserQuestion picker can replace the assistant
    # prose that precedes it, so the design-workshop skill removes that tool on Claude while
    # preserving structured-question UX on the other hosts.
    $claudeDisallowedToolsPattern = '(?m)^claude-disallowed-tools\s*:\s*(?<tools>[^\r\n]+)(?<newline>\r?\n)'
    if (-not [regex]::IsMatch($Content, $claudeDisallowedToolsPattern)) {
        return $Content
    }

    if ($HostName.Equals('claude', [System.StringComparison]::OrdinalIgnoreCase)) {
        return [regex]::Replace(
            $Content,
            $claudeDisallowedToolsPattern,
            'disallowed-tools: ${tools}${newline}'
        )
    }

    return [regex]::Replace($Content, $claudeDisallowedToolsPattern, '')
}

function Test-SpecrewSkillAppliesToHost {
    param(
        [Parameter(Mandatory = $true)]
        [psobject]$Definition,

        [Parameter(Mandatory = $true)]
        [string]$HostName
    )

    if ($Definition.PSObject.Properties.Name -notcontains 'HostScopes') {
        return $true
    }

    $hostScopes = @($Definition.HostScopes | ForEach-Object { ([string]$_).ToLowerInvariant() })
    if ($hostScopes.Count -eq 0 -or $hostScopes -contains 'all') {
        return $true
    }

    return ($hostScopes -contains $HostName.ToLowerInvariant())
}

function Get-LegacySpecrewSkillDefinitions {
    param(
        [Parameter(Mandatory = $true)]
        [string]$SkillsTemplateRoot
    )

    $definitions = New-Object System.Collections.Generic.List[object]

    $genericSkillFiles = @(Get-ChildItem -LiteralPath $SkillsTemplateRoot -Filter '*.md' | Where-Object { $_.Name -ne 'README.md' } | Sort-Object Name)
    foreach ($skillFile in $genericSkillFiles) {
        $content = Get-Content -LiteralPath $skillFile.FullName -Raw
        $definitions.Add([pscustomobject]@{
                Directory      = 'specrew-{0}' -f $skillFile.BaseName
                CurrentContent = $content
                Kind           = 'generic'
                LegacyContent  = $content
                HostScopes     = @(Get-SpecrewSkillHostScopes -Content $content)
            })
    }

    foreach ($slashSkill in Get-SlashCommandSkillCatalog) {
        $skillSourcePath = Join-Path (Join-Path $SkillsTemplateRoot $slashSkill.Directory) 'SKILL.md'
        if (-not (Test-Path -LiteralPath $skillSourcePath -PathType Leaf)) {
            continue
        }

        $content = Get-Content -LiteralPath $skillSourcePath -Raw
        $definitions.Add([pscustomobject]@{
                Directory          = $slashSkill.Directory
                CurrentContent     = $content
                Kind               = 'slash-command'
                LegacySlashCommand = $slashSkill.LegacySlashCommand
                HostScopes         = @(Get-SpecrewSkillHostScopes -Content $content)
            })
    }

    return $definitions.ToArray()
}

function Test-IsManagedLegacySkillDirectory {
    param(
        [Parameter(Mandatory = $true)]
        [string]$SkillDirectoryPath,

        [Parameter(Mandatory = $true)]
        [psobject]$Definition
    )

    $managedMarkerPath = Join-Path $SkillDirectoryPath '.specrew-managed'
    if (Test-Path -LiteralPath $managedMarkerPath -PathType Leaf) {
        return $true
    }

    $skillPath = Join-Path $SkillDirectoryPath 'SKILL.md'
    if (-not (Test-Path -LiteralPath $skillPath -PathType Leaf)) {
        return $false
    }

    $content = Get-Content -LiteralPath $skillPath -Raw
    if ([string]::IsNullOrWhiteSpace($content)) {
        return $false
    }

    # Feature 160 (Proposal 161): provenance-by-content. A dir whose SKILL.md
    # text equals this definition's canonical content — ordinal comparison of the
    # DECODED text (line endings are significant; file encoding/BOM is not part
    # of the contract) — is Specrew-managed even without a marker, including when
    # canonical content carries front matter, which the heuristic below would
    # otherwise classify as user-edited. An exact text match means there are no
    # user customizations, so recognizing it as managed cannot lose user data.
    # The marker (checked above) remains the primary signal; this recovers
    # marker-less legacy dirs that still hold our canonical content. Genuinely
    # user-edited content does not match and stays preserved.
    foreach ($propertyName in @('CurrentContent', 'LegacyContent')) {
        if ($Definition.PSObject.Properties.Name -contains $propertyName) {
            $canonical = [string]$Definition.$propertyName
            if (-not [string]::IsNullOrEmpty($canonical) -and [System.String]::Equals($content, $canonical, [System.StringComparison]::Ordinal)) {
                return $true
            }
        }
    }

    if ($content.TrimStart().StartsWith('---', [System.StringComparison]::Ordinal)) {
        return $false
    }

    if ($Definition.Kind -eq 'generic') {
        # Feature 161 (PR-review data-loss fix): a marker-less generic legacy skill is
        # Specrew-managed ONLY when its DECODED text exactly matches a known canonical
        # version (CurrentContent/LegacyContent, ordinal, checked above). A structural
        # signature (directory-name heading plus **Type**/**Schema** lines) cannot
        # distinguish Specrew's own drifted-legacy content from a user-edited copy that
        # kept the same shape, so using it to authorize deletion would destroy user work
        # — the exact outcome this feature exists to prevent (spec: "genuinely
        # user-authored skills must remain preserved"). Anything that does not exactly
        # match a known canonical version is preserved (favor preserve over delete): a
        # heavily-drifted marker-less legacy generic skill stays stale-but-safe in the
        # legacy root while active surfaces redeploy fresh; re-deploy or manual cleanup
        # recovers it without data-loss risk.
        return $false
    }

    $legacyNamespaceLine = '**Namespace**: ' + [char]96 + '/specrew' + [char]96
    $legacyCommandLine = '**Canonical command**: ' + [char]96 + $Definition.LegacySlashCommand + [char]96

    return (
        $content.StartsWith('# {0}' -f $Definition.Directory, [System.StringComparison]::Ordinal) -and
        $content.Contains($legacyNamespaceLine) -and
        $content.Contains($legacyCommandLine)
    )
}

$resolvedProjectPath = Resolve-ProjectPath -Path $ProjectPath
$extensionRoot = Split-Path -Parent $PSScriptRoot
$repositoryRoot = Split-Path -Parent (Split-Path -Parent $extensionRoot)
$templateRoot = Join-Path $extensionRoot 'squad-templates'
$legacySkillsRoot = Join-Path $resolvedProjectPath '.copilot\skills'
$squadRoot = Join-Path $resolvedProjectPath '.squad'
$squadAgentsRoot = Join-Path $squadRoot 'agents'
$coordinatorPromptPath = Join-Path $resolvedProjectPath '.github\agents\squad.agent.md'
$ceremoniesPath = Join-Path $squadRoot 'ceremonies.md'
$teamPath = Join-Path $squadRoot 'team.md'
$actions = [System.Collections.ArrayList]::new()

if (-not (Test-Path -LiteralPath $squadRoot) -and -not $DryRun) {
    throw "Squad must be initialized before deploying runtime surfaces. Missing '$squadRoot'."
}

if ($DryRun -and -not (Test-Path -LiteralPath $squadRoot)) {
    Add-DeploymentAction -Actions $actions -Action 'would-create-directory' -Path $squadRoot
}

Ensure-Directory -Path $squadAgentsRoot -Actions $actions
Ensure-Directory -Path (Join-Path $squadRoot 'casting') -Actions $actions

$skillsTemplateRoot = Join-Path $templateRoot 'skills'
$activeSkillRoots = @(Get-ActiveSkillRoots -ProjectPath $resolvedProjectPath)
$managedSkillDefinitions = @(Get-LegacySpecrewSkillDefinitions -SkillsTemplateRoot $skillsTemplateRoot)

if (Test-Path -LiteralPath $legacySkillsRoot -PathType Container) {
    $legacySkillDirectories = @(Get-ChildItem -LiteralPath $legacySkillsRoot -Directory | Where-Object { $_.Name -like 'specrew-*' } | Sort-Object Name)
    foreach ($legacySkillDirectory in $legacySkillDirectories) {
        $definition = $managedSkillDefinitions | Where-Object { $_.Directory -eq $legacySkillDirectory.Name } | Select-Object -First 1
        if ($null -eq $definition) {
            Add-DeploymentAction -Actions $actions -Action 'preserved-legacy-unmanaged-skill' -Path $legacySkillDirectory.FullName
            continue
        }

        if (Test-IsManagedLegacySkillDirectory -SkillDirectoryPath $legacySkillDirectory.FullName -Definition $definition) {
            Add-DeploymentAction -Actions $actions -Action $(if ($DryRun) { 'would-remove-legacy-managed-skill' } else { 'removed-legacy-managed-skill' }) -Path $legacySkillDirectory.FullName
            if (-not $DryRun) {
                Remove-Item -LiteralPath $legacySkillDirectory.FullName -Recurse -Force
            }
            continue
        }

        Add-DeploymentAction -Actions $actions -Action 'preserved-legacy-unmanaged-skill' -Path $legacySkillDirectory.FullName
    }
}

foreach ($activeSkillRoot in $activeSkillRoots) {
    Ensure-Directory -Path $activeSkillRoot.Path -Actions $actions

    foreach ($definition in $managedSkillDefinitions) {
        $skillDirectoryPath = Join-Path $activeSkillRoot.Path $definition.Directory
        if (-not (Test-SpecrewSkillAppliesToHost -Definition $definition -HostName $activeSkillRoot.Name)) {
            if (Test-Path -LiteralPath $skillDirectoryPath -PathType Container) {
                if (Test-IsManagedLegacySkillDirectory -SkillDirectoryPath $skillDirectoryPath -Definition $definition) {
                    Add-DeploymentAction -Actions $actions -Action $(if ($DryRun) { 'would-remove-host-scoped-managed-skill' } else { 'removed-host-scoped-managed-skill' }) -Path $skillDirectoryPath
                    if (-not $DryRun) {
                        Remove-Item -LiteralPath $skillDirectoryPath -Recurse -Force
                    }
                    continue
                }

                Add-DeploymentAction -Actions $actions -Action 'preserved-host-scoped-unmanaged-skill' -Path $skillDirectoryPath
                continue
            }

            Add-DeploymentAction -Actions $actions -Action 'skipped-host-scope' -Path $skillDirectoryPath
            continue
        }

        Ensure-Directory -Path $skillDirectoryPath -Actions $actions
        $hostContent = Get-SpecrewSkillContentForHost -Content $definition.CurrentContent -HostName $activeSkillRoot.Name
        Set-ManagedFile -TargetPath (Join-Path $skillDirectoryPath 'SKILL.md') -Content $hostContent -Actions $actions
        Set-ManagedFile -TargetPath (Join-Path $skillDirectoryPath '.specrew-managed') -Content (Get-ManagedSkillMarkerContent -SkillDirectory $definition.Directory) -Actions $actions
    }
}

$continuousReviewRuntimeSource = Join-Path $repositoryRoot 'scripts\internal\continuous-co-review'
$continuousReviewRuntimeTarget = Join-Path $resolvedProjectPath 'scripts\internal\continuous-co-review'
$reviewEngineResolutionPath = Join-Path $repositoryRoot 'scripts\internal\review-engine-resolution.ps1'
if (-not (Test-Path -LiteralPath $reviewEngineResolutionPath -PathType Leaf)) {
    throw "Missing review-engine resolution helper: $reviewEngineResolutionPath"
}
. $reviewEngineResolutionPath
$currentRuntimeManagedFiles = @(Get-SpecrewReviewRuntimeManagedFileManifest -RuntimeRoot $continuousReviewRuntimeSource)
$previousRuntimeManagedFiles = @()
$reviewRuntimeMarkerPath = Join-Path $continuousReviewRuntimeTarget '.specrew-runtime.json'
if (Test-Path -LiteralPath $reviewRuntimeMarkerPath -PathType Leaf) {
    try {
        $previousMarker = Get-Content -LiteralPath $reviewRuntimeMarkerPath -Raw -Encoding UTF8 | ConvertFrom-Json -Depth 12
        if ($previousMarker.PSObject.Properties['managed_files']) {
            $previousRuntimeManagedFiles = @(
                ConvertTo-SpecrewReviewRuntimeManagedFileManifest -RuntimeRoot $continuousReviewRuntimeTarget -ManagedFiles $previousMarker.managed_files
            )
        }
    }
    catch {
        # An old or damaged marker is not deletion authority. Preserve unknown files,
        # replace the marker with current provenance, and converge identity safely.
        Add-DeploymentAction -Actions $actions -Action 'preserved-untrusted-runtime-retirement-state' -Path $reviewRuntimeMarkerPath
        $previousRuntimeManagedFiles = @()
    }
}
Remove-RetiredManagedRuntimeFiles -TargetRoot $continuousReviewRuntimeTarget `
    -PreviousManagedFiles $previousRuntimeManagedFiles -CurrentManagedFiles $currentRuntimeManagedFiles -Actions $actions
Copy-ManagedDirectory -SourcePath $continuousReviewRuntimeSource -TargetPath $continuousReviewRuntimeTarget -Actions $actions
$sourceManifestPath = Join-Path $repositoryRoot 'Specrew.psd1'
$sourceVersion = 'unknown'
if (Test-Path -LiteralPath $sourceManifestPath -PathType Leaf) {
    $sourceManifest = Import-PowerShellDataFile -LiteralPath $sourceManifestPath
    $sourceVersion = [string]$sourceManifest.ModuleVersion
}
$reviewRuntimeMarker = [ordered]@{
    schema_version = '1.0'
    # Content identity is authoritative. Version is diagnostic and may be
    # unavailable in legacy/update fixture layouts that deploy supported
    # surfaces without copying the package manifest.
    specrew_version = $sourceVersion
    # Bind the marker to the files that were actually deployed. The logical hash
    # normalizes managed-text encoding and line endings, while still detecting any
    # executable content drift.
    runtime_bundle_sha256 = Get-SpecrewReviewRuntimeBundleSha256 `
        -RuntimeRoot $continuousReviewRuntimeSource -ManagedFiles $currentRuntimeManagedFiles
    managed_files = @($currentRuntimeManagedFiles)
    source = 'specrew-init-or-update'
} | ConvertTo-Json -Depth 12
if (-not $DryRun) {
    $deployedRuntimeHash = Get-SpecrewReviewRuntimeBundleSha256 `
        -RuntimeRoot $continuousReviewRuntimeTarget -ManagedFiles $currentRuntimeManagedFiles
    $expectedRuntimeHash = Get-SpecrewReviewRuntimeBundleSha256 `
        -RuntimeRoot $continuousReviewRuntimeSource -ManagedFiles $currentRuntimeManagedFiles
    if ($deployedRuntimeHash -cne $expectedRuntimeHash) { throw 'managed-runtime-deployment-identity-mismatch' }
}
Set-ManagedFile -TargetPath $reviewRuntimeMarkerPath -Content ($reviewRuntimeMarker + [Environment]::NewLine) -Actions $actions

$continuousReviewContractsSource = Join-Path $repositoryRoot 'specs\197-continuous-co-review\contracts'
$continuousReviewContractsTarget = Join-Path $resolvedProjectPath '.specrew\review\contracts'
Copy-ManagedDirectory -SourcePath $continuousReviewContractsSource -TargetPath $continuousReviewContractsTarget -Actions $actions

# The co-review FIRE path also needs the isolated-task launcher (Proposal 139 foundation) + its
# atomic-write dependency. The deploy shipped continuous-co-review/ + the contracts but NOT these, so on
# every deployed project the navigator reached fire and fail-opened to a SILENT no-op (launcher-unavailable
# / Write-SpecrewFileAtomic undefined) - the reason co-review was inert on real projects. (Tactical patch;
# the systemic fix is deriving the deployed runtime set from Specrew.psd1 FileList - which already lists all
# three - per Proposal 198.)
$agentTasksRuntimeSource = Join-Path $repositoryRoot 'scripts\internal\agent-tasks'
$agentTasksRuntimeTarget = Join-Path $resolvedProjectPath 'scripts\internal\agent-tasks'
Copy-ManagedDirectory -SourcePath $agentTasksRuntimeSource -TargetPath $agentTasksRuntimeTarget -Actions $actions

$atomicWriteRuntimeSource = Join-Path $repositoryRoot 'scripts\internal\atomic-write.ps1'
$atomicWriteRuntimeTarget = Join-Path $resolvedProjectPath 'scripts\internal\atomic-write.ps1'
Set-ManagedFile -TargetPath $atomicWriteRuntimeTarget -Content (Get-Content -LiteralPath $atomicWriteRuntimeSource -Raw -Encoding UTF8) -Actions $actions

$coordinatorGovernancePath = Join-Path $templateRoot 'coordinator\specrew-governance.md'
if (-not (Test-Path -LiteralPath $coordinatorGovernancePath -PathType Leaf)) {
    throw "Missing coordinator governance template: $coordinatorGovernancePath"
}

if (Test-Path -LiteralPath $coordinatorPromptPath -PathType Leaf) {
    $coordinatorGovernanceContent = Get-Content -LiteralPath $coordinatorGovernancePath -Raw
    Set-ManagedBlock -TargetPath $coordinatorPromptPath -BlockName 'specrew-governance' -ManagedContent $coordinatorGovernanceContent -Actions $actions
}
else {
    Add-DeploymentAction -Actions $actions -Action 'skipped' -Path $coordinatorPromptPath
}

$ceremonyContent = (@(
        foreach ($ceremonyPath in @(
                (Join-Path $templateRoot 'ceremonies\planning.md'),
                (Join-Path $templateRoot 'ceremonies\review-demo.md')
            )) {
            (Get-Content -LiteralPath $ceremonyPath -Raw).Trim()
        }
    ) -join ([Environment]::NewLine + [Environment]::NewLine + '---' + [Environment]::NewLine + [Environment]::NewLine))
Set-ManagedBlock -TargetPath $ceremoniesPath -BlockName 'ceremonies' -ManagedContent $ceremonyContent -BaseContentIfMissing '# Ceremonies' -Actions $actions

$baselineRoles = @(Get-BaselineRoleDefinitions)

# Add explicit team status metadata to signal Squad readiness
$teamStatusBlock = @"
**Team Status**: configured  
**Baseline Roles**: Spec Steward, Planner, Implementer, Reviewer, Retro Facilitator  
**Configuration**: Specrew-managed baseline
"@
Set-ManagedBlock -TargetPath $teamPath -BlockName 'team-status' -ManagedContent $teamStatusBlock -BaseContentIfMissing '# Squad Team' -Actions $actions

# Update team.md Members table with baseline roles
$membersTableRows = @()
foreach ($baselineRole in $baselineRoles) {
    $membersTableRows += ('| {0} | {1} | `.squad/agents/{2}/charter.md` | baseline |' -f $baselineRole.AgentDirectory, $baselineRole.Name, $baselineRole.AgentDirectory)
}
if ($membersTableRows.Count -gt 0) {
    Set-ManagedTableRows -TargetPath $teamPath -TableSectionHeader '## Members' -Rows $membersTableRows -Actions $actions
}

# Also maintain the Specrew Baseline Roles section for documentation
$teamContentLines = @(
    '## Specrew Baseline Roles'
    ''
    '| Role | Charter | Status |'
    '| ---- | ------- | ------ |'
)
foreach ($baselineRole in $baselineRoles) {
    $teamContentLines += ('| {0} | `.squad/agents/{1}/charter.md` | baseline |' -f $baselineRole.Name, $baselineRole.AgentDirectory)
}
Set-ManagedBlock -TargetPath $teamPath -BlockName 'baseline-roles' -ManagedContent ($teamContentLines -join [Environment]::NewLine) -BaseContentIfMissing '# Squad Team' -Actions $actions

# Update routing.md with baseline role routing
$routingPath = Join-Path $squadRoot 'routing.md'
$routingTableRows = @(
    '| Specification governance | spec-steward | Spec authoring, requirement authority, drift detection |'
    '| Planning & traceability | planner | Iteration planning, task breakdown, requirement tracing |'
    '| Implementation | implementer | Code changes, feature delivery, execution follow-through |'
    '| Code review | reviewer | PR review, quality checks, acceptance validation |'
    '| Retrospectives | retro-facilitator | Iteration retrospectives, process improvements |'
)
Set-ManagedTableRows -TargetPath $routingPath -TableSectionHeader '## Routing Table' -Rows $routingTableRows -Actions $actions

# Update casting/registry.json with baseline role entries
$registryPath = Join-Path $squadRoot 'casting\registry.json'
$registryAgents = [ordered]@{}
foreach ($baselineRole in $baselineRoles) {
    $registryAgents[$baselineRole.AgentDirectory] = @{
        name = $baselineRole.Name
        role = $baselineRole.Name
        status = 'baseline'
        charter = ".squad/agents/$($baselineRole.AgentDirectory)/charter.md"
    }
}
$registryContent = @{
    agents = $registryAgents
} | ConvertTo-Json -Depth 10
Set-ManagedFile -TargetPath $registryPath -Content $registryContent -Actions $actions

foreach ($baselineRole in $baselineRoles) {
    $agentDirectory = Join-Path $squadAgentsRoot $baselineRole.AgentDirectory
    Ensure-Directory -Path $agentDirectory -Actions $actions

    $charterTemplate = Get-Content -LiteralPath (Join-Path $templateRoot $baselineRole.TemplatePath) -Raw
    $directiveContent = @(
        foreach ($directivePath in $baselineRole.DirectivePaths) {
            Get-DirectiveDeployment -DirectivePath (Join-Path $templateRoot $directivePath)
        }
    ) -join ([Environment]::NewLine + [Environment]::NewLine)

    Set-ManagedBlock -TargetPath (Join-Path $agentDirectory 'charter.md') -BlockName 'directives' -ManagedContent $directiveContent -BaseContentIfMissing $charterTemplate -Actions $actions

    # Create history.md for each baseline role
    $historyPath = Join-Path $agentDirectory 'history.md'
    $historyContent = @"
# $($baselineRole.Name) History

Project-specific learnings and patterns discovered during work.

## Patterns

<!-- Append entries below. Format: **Pattern:** description. **Context:** when it applies. -->
"@
    Write-MissingFile -TargetPath $historyPath -Content $historyContent -Actions $actions
}

if ($PassThru) {
    $actions
    return
}

$actions | Select-Object Action, Path | Format-Table -AutoSize
Write-Host ("Squad runtime deployment {0} for {1}" -f ($(if ($DryRun) { 'previewed' } else { 'completed' }), $resolvedProjectPath)) -ForegroundColor Green
exit 0
