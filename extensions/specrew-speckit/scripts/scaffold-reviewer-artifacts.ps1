[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$IterationDirectory,

    [switch]$DryRun,
    [switch]$PassThru,
    [switch]$SummaryOnly
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Add-ScaffoldAction {
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

function Write-ScaffoldFile {
    param(
        [Parameter(Mandatory = $true)]
        [string]$TargetPath,

        [Parameter(Mandatory = $true)]
        [string]$Content,

        [AllowEmptyCollection()]
        [Parameter(Mandatory = $true)]
        [System.Collections.ArrayList]$Actions
    )

    Add-ScaffoldAction -Actions $Actions -Action $(if (Test-Path -LiteralPath $TargetPath) {
            if ($DryRun) { 'would-update' } else { 'updated' }
        }
        else {
            if ($DryRun) { 'would-create' } else { 'created' }
        }) -Path $TargetPath

    if ($DryRun) {
        return
    }

    $parent = Split-Path -Parent $TargetPath
    if (-not (Test-Path -LiteralPath $parent)) {
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
    }

    [System.IO.File]::WriteAllText($TargetPath, $Content, [System.Text.UTF8Encoding]::new($false))
}

function Get-MarkdownContent {
    param([string]$Path)

    return @(Get-Content -LiteralPath $Path -Encoding UTF8)
}

function Get-MarkdownSectionTable {
    param(
        [AllowEmptyString()]
        [string[]]$Lines,
        [string]$Heading
    )

    $headingPattern = '^##\s+' + [regex]::Escape($Heading) + '\b'
    $startIndex = -1
    for ($index = 0; $index -lt $Lines.Count; $index++) {
        if ($Lines[$index] -match $headingPattern) {
            $startIndex = $index
            break
        }
    }

    if ($startIndex -lt 0) {
        return @()
    }

    $tableLines = New-Object System.Collections.Generic.List[string]
    for ($index = $startIndex + 1; $index -lt $Lines.Count; $index++) {
        $currentLine = $Lines[$index]
        if ($currentLine -match '^##\s+') {
            break
        }

        if ($currentLine.Trim().StartsWith('|')) {
            $null = $tableLines.Add($currentLine)
        }
    }

    if ($tableLines.Count -lt 2) {
        return @()
    }

    $headers = ($tableLines[0].Trim('|') -split '\|') | ForEach-Object { $_.Trim() }
    $rows = New-Object System.Collections.Generic.List[object]

    for ($rowIndex = 1; $rowIndex -lt $tableLines.Count; $rowIndex++) {
        $cells = ($tableLines[$rowIndex].Trim('|') -split '\|') | ForEach-Object { $_.Trim() }
        $isSeparator = $true
        foreach ($cell in $cells) {
            if ($cell -notmatch '^:?-{3,}:?$') {
                $isSeparator = $false
                break
            }
        }

        if ($isSeparator) {
            continue
        }

        $row = [ordered]@{}
        for ($cellIndex = 0; $cellIndex -lt $headers.Count; $cellIndex++) {
            $row[$headers[$cellIndex]] = if ($cellIndex -lt $cells.Count) { $cells[$cellIndex] } else { '' }
        }

        $rows.Add([pscustomobject]$row)
    }

    return $rows.ToArray()
}

function Get-MarkdownSectionLines {
    param(
        [AllowEmptyString()]
        [string[]]$Lines,
        [string]$Heading
    )

    $headingPattern = '^##\s+' + [regex]::Escape($Heading) + '\b'
    $startIndex = -1
    for ($index = 0; $index -lt $Lines.Count; $index++) {
        if ($Lines[$index] -match $headingPattern) {
            $startIndex = $index
            break
        }
    }

    if ($startIndex -lt 0) {
        return @()
    }

    $sectionLines = New-Object System.Collections.Generic.List[string]
    for ($index = $startIndex + 1; $index -lt $Lines.Count; $index++) {
        $currentLine = $Lines[$index]
        if ($currentLine -match '^##\s+') {
            break
        }

        $null = $sectionLines.Add($currentLine)
    }

    return $sectionLines.ToArray()
}

function Get-IterationLabel {
    param(
        [AllowEmptyString()]
        [string[]]$PlanLines,
        [string]$Fallback
    )

    $titleLine = @($PlanLines | Select-Object -First 1)[0]
    if (-not [string]::IsNullOrWhiteSpace($titleLine) -and $titleLine -match '^#\s+Iteration Plan:\s+(.+?)(?:\s+\(stub\))?\s*$') {
        return $Matches[1].Trim()
    }

    return $Fallback
}

function Get-MetadataValue {
    param(
        [string[]]$Lines,
        [string]$Label
    )

    $pattern = '^\*\*' + [regex]::Escape($Label) + '\*\*:\s*(.+?)\s*$'
    foreach ($line in $Lines) {
        if ($line -match $pattern) {
            return $Matches[1].Trim()
        }
    }

    return $null
}

function Test-IsNullish {
    param([AllowNull()][string]$Value)

    if ([string]::IsNullOrWhiteSpace($Value)) {
        return $true
    }

    return $Value.Trim() -match '^(?:—|-|none|null|n/a|\(none\)|blank|tbd|unknown)$'
}

function Get-RelativePath {
    param(
        [Parameter(Mandatory = $true)]
        [string]$FromDirectory,

        [Parameter(Mandatory = $true)]
        [string]$ToPath
    )

    $fromUri = [System.Uri]([System.IO.Path]::GetFullPath($FromDirectory).TrimEnd('\') + '\')
    $toUri = [System.Uri]([System.IO.Path]::GetFullPath($ToPath))
    return [System.Uri]::UnescapeDataString($fromUri.MakeRelativeUri($toUri).ToString()) -replace '/', '\'
}

function Get-DriftSummary {
    param([string[]]$Lines)

    $result = [ordered]@{
        Total                = 0
        Resolved             = 0
        SpecUpdated          = 0
        ImplementationRevert = 0
        Deferred             = 0
        HumanDecision        = 0
    }

    foreach ($line in $Lines) {
        if ($line -match '(?:\*\*)?Total drift events(?:\*\*)?:\s*(\d+)') {
            $result.Total = [int]$Matches[1]
        }
        elseif ($line -match '(?:\*\*)?Resolution rate(?:\*\*)?:.*\((\d+)/(\d+)\s+resolved\)') {
            $result.Resolved = [int]$Matches[1]
        }
        elseif ($line -match 'Resolved via spec update:\s*(\d+)') {
            $result.SpecUpdated = [int]$Matches[1]
        }
        elseif ($line -match 'Resolved via revert:\s*(\d+)') {
            $result.ImplementationRevert = [int]$Matches[1]
        }
        elseif ($line -match 'Deferred:\s*(\d+)') {
            $result.Deferred = [int]$Matches[1]
        }
        elseif ($line -match 'Escalated to human decision:\s*(\d+)') {
            $result.HumanDecision = [int]$Matches[1]
        }
    }

    if ($result.Resolved -eq 0 -and $result.Total -eq 0) {
        $result.Resolved = 0
    }

    return [pscustomobject]$result
}

function Get-ReviewerConfig {
    param([string]$ProjectRoot)

    $config = [ordered]@{
        reviewer = [ordered]@{
            test_path_globs             = @('**\tests\**', '**\test\**', '**\*test*.*', '**\*spec*.*')
            sensitive_data_patterns     = @('auth*', 'secret*', 'credential*', 'token*', 'key*', 'crypto*')
            test_commands               = @()
            skip_test_execution_at_close = $false
            baseline_ref                = 'iteration-baseline'
            diagram_format              = 'mermaid'
            coverage                    = [ordered]@{
                tool = ''
                kind = 'qualitative'
            }
            vulnerability_scanner       = [ordered]@{
                auto_detect = $true
                command     = ''
                candidates  = @('npm audit --json', 'dotnet list package --vulnerable', 'pip-audit --format json', 'cargo audit --json', 'govulncheck -json ./...')
            }
            hotspot_thresholds          = [ordered]@{
                file_changed_lines     = 250
                function_changed_lines = 100
            }
            diagram_thresholds          = [ordered]@{
                structure = [ordered]@{
                    min_modules_touched   = 3
                    min_inter_module_edges = 2
                }
                flow      = [ordered]@{
                    min_entrypoints_changed = 1
                    min_modules_in_flow     = 2
                }
            }
        }
    }

    $configPath = Join-Path $ProjectRoot '.specrew\iteration-config.yml'
    if (-not (Test-Path -LiteralPath $configPath -PathType Leaf)) {
        return [pscustomobject]$config
    }

    $context = ''
    $listTarget = $null
    foreach ($rawLine in Get-Content -LiteralPath $configPath -Encoding UTF8) {
        $line = [string]$rawLine

        if ($line -match '^\s*reviewer:\s*$') {
            $context = 'reviewer'
            $listTarget = $null
            continue
        }
        if ($line -match '^\s{2}coverage:\s*$') {
            $context = 'reviewer.coverage'
            $listTarget = $null
            continue
        }
        if ($line -match '^\s{2}vulnerability_scanner:\s*$') {
            $context = 'reviewer.vulnerability_scanner'
            $listTarget = $null
            continue
        }
        if ($line -match '^\s{2}hotspot_thresholds:\s*$') {
            $context = 'reviewer.hotspot_thresholds'
            $listTarget = $null
            continue
        }
        if ($line -match '^\s{2}diagram_thresholds:\s*$') {
            $context = 'reviewer.diagram_thresholds'
            $listTarget = $null
            continue
        }
        if ($line -match '^\s{4}structure:\s*$') {
            $context = 'reviewer.diagram_thresholds.structure'
            $listTarget = $null
            continue
        }
        if ($line -match '^\s{4}flow:\s*$') {
            $context = 'reviewer.diagram_thresholds.flow'
            $listTarget = $null
            continue
        }

        if ($line -match '^\s{2}(test_path_globs|sensitive_data_patterns|test_commands):\s*\[\s*\]\s*$') {
            $config.reviewer[$Matches[1]] = @()
            $listTarget = $Matches[1]
            $context = 'reviewer'
            continue
        }
        if ($line -match '^\s{2}(test_path_globs|sensitive_data_patterns|test_commands):\s*$') {
            $config.reviewer[$Matches[1]] = @()
            $listTarget = $Matches[1]
            $context = 'reviewer'
            continue
        }
        if ($line -match '^\s{4}candidates:\s*$') {
            $config.reviewer.vulnerability_scanner.candidates = @()
            $listTarget = 'candidates'
            $context = 'reviewer.vulnerability_scanner'
            continue
        }

        if ($listTarget -and $context -eq 'reviewer' -and $line -match '^\s{4}-\s*"?(.*?)"?\s*$') {
            $config.reviewer[$listTarget] += $Matches[1]
            continue
        }
        if ($listTarget -eq 'candidates' -and $context -eq 'reviewer.vulnerability_scanner' -and $line -match '^\s{6}-\s*"?(.*?)"?\s*$') {
            $config.reviewer.vulnerability_scanner.candidates += $Matches[1]
            continue
        }
        $listTarget = $null

        switch -Regex ($line) {
            '^\s{2}skip_test_execution_at_close:\s*(true|false)\s*$' {
                $config.reviewer.skip_test_execution_at_close = $Matches[1].ToLowerInvariant() -eq 'true'
                continue
            }
            '^\s{2}baseline_ref:\s*"?([^"#]+?)"?\s*$' {
                $config.reviewer.baseline_ref = $Matches[1].Trim()
                continue
            }
            '^\s{2}diagram_format:\s*"?([^"#]+?)"?\s*$' {
                $config.reviewer.diagram_format = $Matches[1].Trim()
                continue
            }
            '^\s{4}tool:\s*"?([^"#]*)"?\s*$' {
                if ($context -eq 'reviewer.coverage') {
                    $config.reviewer.coverage.tool = $Matches[1].Trim()
                }
                continue
            }
            '^\s{4}kind:\s*"?([^"#]+?)"?\s*$' {
                if ($context -eq 'reviewer.coverage') {
                    $config.reviewer.coverage.kind = $Matches[1].Trim()
                }
                continue
            }
            '^\s{4}auto_detect:\s*(true|false)\s*$' {
                if ($context -eq 'reviewer.vulnerability_scanner') {
                    $config.reviewer.vulnerability_scanner.auto_detect = $Matches[1].ToLowerInvariant() -eq 'true'
                }
                continue
            }
            '^\s{4}command:\s*"?([^"#]*)"?\s*$' {
                if ($context -eq 'reviewer.vulnerability_scanner') {
                    $config.reviewer.vulnerability_scanner.command = $Matches[1].Trim()
                }
                continue
            }
            '^\s{4}file_changed_lines:\s*(\d+)\s*$' {
                if ($context -eq 'reviewer.hotspot_thresholds') {
                    $config.reviewer.hotspot_thresholds.file_changed_lines = [int]$Matches[1]
                }
                continue
            }
            '^\s{4}function_changed_lines:\s*(\d+)\s*$' {
                if ($context -eq 'reviewer.hotspot_thresholds') {
                    $config.reviewer.hotspot_thresholds.function_changed_lines = [int]$Matches[1]
                }
                continue
            }
            '^\s{6}min_modules_touched:\s*(\d+)\s*$' {
                if ($context -eq 'reviewer.diagram_thresholds.structure') {
                    $config.reviewer.diagram_thresholds.structure.min_modules_touched = [int]$Matches[1]
                }
                continue
            }
            '^\s{6}min_inter_module_edges:\s*(\d+)\s*$' {
                if ($context -eq 'reviewer.diagram_thresholds.structure') {
                    $config.reviewer.diagram_thresholds.structure.min_inter_module_edges = [int]$Matches[1]
                }
                continue
            }
            '^\s{6}min_entrypoints_changed:\s*(\d+)\s*$' {
                if ($context -eq 'reviewer.diagram_thresholds.flow') {
                    $config.reviewer.diagram_thresholds.flow.min_entrypoints_changed = [int]$Matches[1]
                }
                continue
            }
            '^\s{6}min_modules_in_flow:\s*(\d+)\s*$' {
                if ($context -eq 'reviewer.diagram_thresholds.flow') {
                    $config.reviewer.diagram_thresholds.flow.min_modules_in_flow = [int]$Matches[1]
                }
                continue
            }
        }
    }

    return [pscustomobject]$config
}

function Test-IsManifestPath {
    param([string]$Path)

    return $Path -match '(?:^|\\)(package\.json|package-lock\.json|pnpm-lock\.yaml|yarn\.lock|requirements(?:-dev)?\.txt|pyproject\.toml|Cargo\.toml|Cargo\.lock|go\.mod|go\.sum|pom\.xml|packages\.lock\.json|global\.json|.*\.csproj)$'
}

function Test-IsTestPath {
    param(
        [string]$Path,
        [string[]]$TestPathGlobs
    )

    $normalized = $Path.Replace('/', '\').ToLowerInvariant()
    if ($normalized -match '(?:^|\\)(tests?|specs?)\\' -or $normalized -match '(?:^|\\)[^\\]*(?:test|spec)[^\\]*\.[^\\]+$') {
        return $true
    }

    foreach ($glob in $TestPathGlobs) {
        $token = $glob.Replace('/', '\').Replace('**', '').Replace('*', '').ToLowerInvariant()
        if (-not [string]::IsNullOrWhiteSpace($token) -and $normalized.Contains($token)) {
            return $true
        }
    }

    return $false
}

function Convert-WildcardToRegex {
    param([string]$Pattern)

    return '^' + ([regex]::Escape($Pattern).Replace('\*', '.*').Replace('\?', '.')) + '$'
}

function Get-ChangedCodeFiles {
    param(
        [object[]]$ChangedFiles,
        [string[]]$TestPathGlobs
    )

    return @($ChangedFiles | Where-Object {
            $path = [string]$_.Path
            $extension = [System.IO.Path]::GetExtension($path).ToLowerInvariant()
            (-not $_.IsManifest) -and
            (-not (Test-IsTestPath -Path $path -TestPathGlobs $TestPathGlobs)) -and
            ($extension -in @('.ps1', '.psm1', '.js', '.jsx', '.ts', '.tsx', '.py', '.go', '.cs', '.java', '.rb', '.php', '.rs', '.kt', '.swift', '.c', '.cc', '.cpp', '.h', '.hpp'))
        })
}

function Get-ModuleIdFromPath {
    param([string]$Path)

    $normalized = ($Path -replace '/', '\').Trim()
    $withoutExtension = [System.IO.Path]::ChangeExtension($normalized, $null)
    if ([string]::IsNullOrWhiteSpace($withoutExtension)) {
        return $normalized.Replace('\', '/')
    }

    return $withoutExtension.TrimEnd('.').Replace('\', '/')
}

function Get-ModuleLabel {
    param([string]$ModuleId)

    return ($ModuleId -replace '[^A-Za-z0-9_]', '_')
}

function Resolve-ModuleReference {
    param(
        [string]$FromPath,
        [string]$Target,
        [hashtable]$ModuleLookup
    )

    if ([string]::IsNullOrWhiteSpace($Target)) {
        return $null
    }

    $baseDirectory = Split-Path -Parent ($FromPath -replace '/', '\')
    $combinedPath = if ([string]::IsNullOrWhiteSpace($baseDirectory)) {
        $Target
    }
    else {
        Join-Path $baseDirectory $Target
    }

    $candidatePath = [System.IO.Path]::GetFullPath((Join-Path 'C:\' $combinedPath)).Substring(3)
    $candidateKey = $candidatePath.Replace('/', '\')
    $candidateModuleId = Get-ModuleIdFromPath -Path $candidateKey

    if ($ModuleLookup.ContainsKey($candidateModuleId)) {
        return $ModuleLookup[$candidateModuleId]
    }

    foreach ($extension in @('.ps1', '.psm1', '.js', '.ts', '.tsx', '.jsx', '.py', '.go', '.cs')) {
        $withExtension = Get-ModuleIdFromPath -Path ($candidateKey + $extension)
        if ($ModuleLookup.ContainsKey($withExtension)) {
            return $ModuleLookup[$withExtension]
        }
    }

    return $null
}

function Get-ModuleGraphEvidence {
    param(
        [string]$ProjectRoot,
        [object[]]$ChangedFiles,
        [string[]]$TestPathGlobs
    )

    $codeFiles = @(Get-ChangedCodeFiles -ChangedFiles $ChangedFiles -TestPathGlobs $TestPathGlobs)
    $modules = New-Object System.Collections.Generic.List[object]
    $moduleLookup = @{}

    foreach ($file in $codeFiles) {
        $moduleId = Get-ModuleIdFromPath -Path ([string]$file.Path)
        $module = [pscustomobject]@{
            ModuleId = $moduleId
            Label    = Get-ModuleLabel -ModuleId $moduleId
            Path     = [string]$file.Path
        }
        $null = $modules.Add($module)
        $moduleLookup[$moduleId] = $module
    }

    $edges = New-Object System.Collections.Generic.List[object]
    $edgeKeys = New-Object System.Collections.Generic.HashSet[string] ([System.StringComparer]::OrdinalIgnoreCase)
    $entrypoints = New-Object System.Collections.Generic.List[object]

    foreach ($module in $modules) {
        $leafName = [System.IO.Path]::GetFileNameWithoutExtension($module.Path)
        if ($leafName -match '(?i)(api|app|main|index|start|cli|command|handler|controller|route)') {
            $null = $entrypoints.Add($module)
        }

        $absolutePath = Join-Path $ProjectRoot $module.Path
        if (-not (Test-Path -LiteralPath $absolutePath -PathType Leaf)) {
            continue
        }

        $text = Get-Content -LiteralPath $absolutePath -Raw -Encoding UTF8
        foreach ($pattern in @(
                '(?im)^\s*import\s+.+?\s+from\s+["''](?<target>\.[^"'']+)["'']'
                '(?im)require\(\s*["''](?<target>\.[^"'']+)["'']\s*\)'
                '(?im)^\s*(?:using\s+module|Import-Module)\s+["'']?(?<target>\.[^"'']+)'
                '(?im)^\s*\.\s+["'']?(?<target>\.[^"'']+)'
            )) {
            foreach ($match in [regex]::Matches($text, $pattern)) {
                $targetModule = Resolve-ModuleReference -FromPath $module.Path -Target $match.Groups['target'].Value -ModuleLookup $moduleLookup
                if ($null -eq $targetModule -or $targetModule.ModuleId -eq $module.ModuleId) {
                    continue
                }

                $edgeKey = '{0}->{1}' -f $module.ModuleId, $targetModule.ModuleId
                if ($edgeKeys.Add($edgeKey)) {
                    $null = $edges.Add([pscustomobject]@{
                            From = $module
                            To   = $targetModule
                        })
                }
            }
        }
    }

    return [pscustomobject]@{
        Modules    = $modules.ToArray()
        Edges      = $edges.ToArray()
        Entrypoints = $entrypoints.ToArray()
    }
}

function Get-SecurityRoles {
    param([string]$ProjectRoot)

    $teamPath = Join-Path $ProjectRoot '.squad\team.md'
    if (-not (Test-Path -LiteralPath $teamPath -PathType Leaf)) {
        return @()
    }

    $roles = New-Object System.Collections.Generic.List[string]
    foreach ($line in Get-Content -LiteralPath $teamPath -Encoding UTF8) {
        if ($line -match '^\|[^|]+\|\s*([^|]*security[^|]*)\|') {
            $role = $Matches[1].Trim()
            if (-not [string]::IsNullOrWhiteSpace($role) -and -not $roles.Contains($role)) {
                $null = $roles.Add($role)
            }
        }
        elseif ($line -match '^\|\s*(Security[^|]*)\|') {
            $role = $Matches[1].Trim()
            if (-not [string]::IsNullOrWhiteSpace($role) -and -not $roles.Contains($role)) {
                $null = $roles.Add($role)
            }
        }
    }

    return $roles.ToArray()
}

function Get-SecurityTriggerContext {
    param(
        [string]$ProjectRoot,
        [string[]]$PlanLines
    )

    $securityRoles = @(Get-SecurityRoles -ProjectRoot $ProjectRoot)
    $planTaskRows = @(Get-MarkdownSectionTable -Lines $PlanLines -Heading 'Tasks')
    $taskTriggered = @($planTaskRows | Where-Object { ([string]$_.Requirement) -match '\bFR-048\b' -or ([string]$_.Title) -match '(?i)\bsecurity\b' }).Count -gt 0

    return [pscustomobject]@{
        Enabled       = ($securityRoles.Count -gt 0) -or $taskTriggered
        Reason        = if ($securityRoles.Count -gt 0) { 'Security-focused team role present.' } elseif ($taskTriggered) { 'Iteration plan scopes security work.' } else { 'No security-focused role and no FR-048/security-scoped plan task were found.' }
        SecurityRoles = $securityRoles
    }
}

function Get-SensitiveTouchpoints {
    param(
        [string]$ProjectRoot,
        [object[]]$ChangedFiles,
        [string[]]$Patterns
    )

    $touchpoints = New-Object System.Collections.Generic.List[string]
    foreach ($file in $ChangedFiles) {
        if ($file.IsManifest) {
            continue
        }

        $matches = New-Object System.Collections.Generic.List[string]
        $pathText = ([string]$file.Path).ToLowerInvariant()
        $contentText = ''
        $absolutePath = Join-Path $ProjectRoot $file.Path
        if (Test-Path -LiteralPath $absolutePath -PathType Leaf) {
            $contentText = (Get-Content -LiteralPath $absolutePath -Raw -Encoding UTF8).ToLowerInvariant()
        }

        foreach ($pattern in $Patterns) {
            $regex = Convert-WildcardToRegex -Pattern $pattern.ToLowerInvariant()
            if ($pathText -match $regex -or $contentText -match $regex) {
                if (-not $matches.Contains($pattern)) {
                    $null = $matches.Add($pattern)
                }
            }
        }

        if ($matches.Count -gt 0) {
            $null = $touchpoints.Add(('{0} (matched: {1})' -f $file.Path, ($matches -join ', ')))
        }
    }

    return $touchpoints.ToArray()
}

function Get-VulnerabilityHighlights {
    param([object]$VulnerabilityScan)

    if ($VulnerabilityScan.Status -ne 'scanned') {
        return @('- none | ' + $VulnerabilityScan.Reason)
    }

    $highlights = New-Object System.Collections.Generic.List[string]
    foreach ($line in $VulnerabilityScan.Output) {
        $lineText = [string]$line
        if ($lineText -match '\b(HIGH|CRITICAL)\b') {
            $null = $highlights.Add($lineText.Trim())
        }
    }

    if ($highlights.Count -eq 0) {
        $null = $highlights.Add('- none | No HIGH/CRITICAL findings were reported.')
    }

    return $highlights.ToArray()
}

function Get-DiagramEvidence {
    param(
        [string]$ProjectRoot,
        [object[]]$ChangedFiles,
        [object]$ReviewerConfig
    )

    $graph = Get-ModuleGraphEvidence -ProjectRoot $ProjectRoot -ChangedFiles $ChangedFiles -TestPathGlobs $ReviewerConfig.test_path_globs
    $omissions = New-Object System.Collections.Generic.List[string]
    $structureDiagram = $null
    $flowDiagram = $null

    if ($graph.Modules.Count -lt [int]$ReviewerConfig.diagram_thresholds.structure.min_modules_touched) {
        $null = $omissions.Add(('Structure diagram omitted: modules touched ({0}) below threshold ({1}).' -f $graph.Modules.Count, $ReviewerConfig.diagram_thresholds.structure.min_modules_touched))
    }
    elseif ($graph.Edges.Count -lt [int]$ReviewerConfig.diagram_thresholds.structure.min_inter_module_edges) {
        $null = $omissions.Add(('Structure diagram omitted: inter-module edges ({0}) below threshold ({1}).' -f $graph.Edges.Count, $ReviewerConfig.diagram_thresholds.structure.min_inter_module_edges))
    }
    else {
        $structureLines = New-Object System.Collections.Generic.List[string]
        $null = $structureLines.Add('```mermaid')
        $null = $structureLines.Add('flowchart LR')
        foreach ($module in $graph.Modules) {
            $null = $structureLines.Add(('  {0}["{1}"]' -f $module.Label, $module.ModuleId))
        }
        foreach ($edge in $graph.Edges) {
            $null = $structureLines.Add(('  {0} --> {1}' -f $edge.From.Label, $edge.To.Label))
        }
        $null = $structureLines.Add('```')
        $structureDiagram = $structureLines -join [Environment]::NewLine
    }

    if ($graph.Entrypoints.Count -lt [int]$ReviewerConfig.diagram_thresholds.flow.min_entrypoints_changed) {
        $null = $omissions.Add(('Flow diagram omitted: entrypoints changed ({0}) below threshold ({1}).' -f $graph.Entrypoints.Count, $ReviewerConfig.diagram_thresholds.flow.min_entrypoints_changed))
    }
    elseif ($graph.Modules.Count -lt [int]$ReviewerConfig.diagram_thresholds.flow.min_modules_in_flow) {
        $null = $omissions.Add(('Flow diagram omitted: modules in flow ({0}) below threshold ({1}).' -f $graph.Modules.Count, $ReviewerConfig.diagram_thresholds.flow.min_modules_in_flow))
    }
    else {
        $flowLines = New-Object System.Collections.Generic.List[string]
        $null = $flowLines.Add('```mermaid')
        $null = $flowLines.Add('flowchart TD')
        foreach ($entrypoint in $graph.Entrypoints) {
            $null = $flowLines.Add(('  {0}["{1}"]' -f $entrypoint.Label, $entrypoint.ModuleId))
            $outgoing = @($graph.Edges | Where-Object { $_.From.ModuleId -eq $entrypoint.ModuleId })
            if ($outgoing.Count -eq 0) {
                continue
            }

            foreach ($edge in $outgoing) {
                $null = $flowLines.Add(('  {0} --> {1}' -f $edge.From.Label, $edge.To.Label))
            }
        }
        $null = $flowLines.Add('```')
        $flowDiagram = $flowLines -join [Environment]::NewLine
    }

    return [pscustomobject]@{
        Graph           = $graph
        StructureDiagram = $structureDiagram
        FlowDiagram     = $flowDiagram
        Omissions       = $omissions.ToArray()
    }
}

function Get-DiffArtifacts {
    param(
        [string]$ProjectRoot,
        [AllowNull()][string]$BaselineRef
    )

    $result = [ordered]@{
        BaselineResolved = $false
        HeadResolved     = $false
        HeadRef          = ''
        Files            = @()
    }

    $gitCommand = Get-Command -Name 'git' -ErrorAction SilentlyContinue
    if ($null -eq $gitCommand) {
        return [pscustomobject]$result
    }

    $headRef = @(& git -C $ProjectRoot rev-parse HEAD 2>$null)
    if ($LASTEXITCODE -eq 0 -and $headRef.Count -gt 0) {
        $result.HeadResolved = $true
        $result.HeadRef = [string]$headRef[0]
    }

    if ([string]::IsNullOrWhiteSpace($BaselineRef)) {
        return [pscustomobject]$result
    }

    $revParseOutput = @(& git -C $ProjectRoot rev-parse --verify $BaselineRef 2>$null)
    if ($LASTEXITCODE -ne 0) {
        return [pscustomobject]$result
    }

    $result.BaselineResolved = $true
    $numstatLines = @(& git -C $ProjectRoot diff --numstat $BaselineRef -- 2>$null)
    if ($LASTEXITCODE -ne 0) {
        return [pscustomobject]$result
    }

    $nameStatusLookup = @{}
    foreach ($line in @(& git -C $ProjectRoot diff --name-status $BaselineRef -- 2>$null)) {
        $match = [regex]::Match([string]$line, '^(?<status>[A-Z][0-9]?)\s+(?<path>.+)$')
        if ($match.Success) {
            $nameStatusLookup[$match.Groups['path'].Value.Trim()] = $match.Groups['status'].Value.Trim()
        }
    }

    foreach ($line in $numstatLines) {
        $match = [regex]::Match([string]$line, '^(?<added>\d+|-)\s+(?<removed>\d+|-)\s+(?<path>.+)$')
        if (-not $match.Success) {
            continue
        }

        $path = $match.Groups['path'].Value.Trim()
        $result.Files += [pscustomobject]@{
            Path      = $path
            Added     = $match.Groups['added'].Value
            Removed   = $match.Groups['removed'].Value
            Status    = if ($nameStatusLookup.ContainsKey($path)) { $nameStatusLookup[$path] } else { 'M' }
            IsManifest = Test-IsManifestPath -Path $path
        }
    }

    return [pscustomobject]$result
}

function Get-DiffPatchLines {
    param(
        [string]$ProjectRoot,
        [string]$BaselineRef,
        [string]$Path
    )

    if ([string]::IsNullOrWhiteSpace($BaselineRef)) {
        return @()
    }

    return @(& git -C $ProjectRoot diff --unified=0 $BaselineRef -- $Path 2>$null)
}

function Get-FileTextAtBaseline {
    param(
        [string]$ProjectRoot,
        [string]$BaselineRef,
        [string]$Path
    )

    if ([string]::IsNullOrWhiteSpace($BaselineRef)) {
        return $null
    }

    $showRef = '{0}:{1}' -f $BaselineRef, ($Path -replace '\\','/')
    $showOutput = @(& git -C $ProjectRoot show $showRef 2>$null)
    if ($LASTEXITCODE -ne 0) {
        return $null
    }

    return ($showOutput -join [Environment]::NewLine)
}

function Get-PublicApiSymbolsFromText {
    param(
        [AllowNull()][string]$Text,
        [string]$Path
    )

    $symbols = New-Object System.Collections.Generic.List[string]
    if ([string]::IsNullOrWhiteSpace($Text)) {
        return $symbols.ToArray()
    }

    $patterns = @(
        '^\s*function\s+([A-Za-z_][\w-]*)\b'
        '^\s*class\s+([A-Za-z_][\w-]*)\b'
        '^\s*def\s+([A-Za-z_][\w-]*)\('
        '^\s*export\s+(?:async\s+)?function\s+([A-Za-z_][\w-]*)\b'
        '^\s*export\s+(?:const|let|var|class)\s+([A-Za-z_][\w-]*)\b'
        '^\s*module\.exports\.([A-Za-z_][\w-]*)\s*='
        '^\s*exports\.([A-Za-z_][\w-]*)\s*='
    )

    foreach ($line in ($Text -split "`r?`n")) {
        foreach ($pattern in $patterns) {
            if ($line -match $pattern) {
                $token = ('{0} ({1})' -f $Matches[1], $Path)
                if (-not $symbols.Contains($token)) {
                    $null = $symbols.Add($token)
                }
            }
        }
    }

    return $symbols.ToArray()
}

function Get-PublicApiDelta {
    param(
        [string]$ProjectRoot,
        [string]$BaselineRef,
        [object[]]$Files
    )

    $added = New-Object System.Collections.Generic.List[string]
    $removed = New-Object System.Collections.Generic.List[string]

    foreach ($file in $Files) {
        if (Test-IsManifestPath -Path ([string]$file.Path)) {
            continue
        }

        $currentPath = Join-Path $ProjectRoot $file.Path
        $currentText = if (Test-Path -LiteralPath $currentPath -PathType Leaf) { Get-Content -LiteralPath $currentPath -Raw -Encoding UTF8 } else { $null }
        $previousText = Get-FileTextAtBaseline -ProjectRoot $ProjectRoot -BaselineRef $BaselineRef -Path ([string]$file.Path)
        $currentSymbols = @(Get-PublicApiSymbolsFromText -Text $currentText -Path ([string]$file.Path))
        $previousSymbols = @(Get-PublicApiSymbolsFromText -Text $previousText -Path ([string]$file.Path))

        foreach ($symbol in $currentSymbols) {
            if ($previousSymbols -notcontains $symbol -and -not $added.Contains($symbol)) {
                $null = $added.Add($symbol)
            }
        }

        foreach ($symbol in $previousSymbols) {
            if ($currentSymbols -notcontains $symbol -and -not $removed.Contains($symbol)) {
                $null = $removed.Add($symbol)
            }
        }
    }

    return [pscustomobject]@{
        Added   = $added.ToArray()
        Removed = $removed.ToArray()
    }
}

function Get-PackageJsonDependencies {
    param([AllowNull()][string]$JsonText)

    $dependencies = @{}
    if ([string]::IsNullOrWhiteSpace($JsonText)) {
        return $dependencies
    }

    try {
        $parsed = $JsonText | ConvertFrom-Json -AsHashtable -ErrorAction Stop
    }
    catch {
        return $dependencies
    }

    foreach ($section in @('dependencies', 'devDependencies', 'peerDependencies', 'optionalDependencies')) {
        if (-not $parsed.ContainsKey($section)) {
            continue
        }

        foreach ($property in $parsed[$section].GetEnumerator()) {
            $dependencies[[string]$property.Key] = [pscustomobject]@{
                Version = [string]$property.Value
                Section = $section
            }
        }
    }

    return $dependencies
}

function Get-ManifestDiffRows {
    param(
        [string]$ProjectRoot,
        [string]$BaselineRef,
        [object[]]$ManifestFiles,
        [object[]]$PlanTasks
    )

    $rows = New-Object System.Collections.Generic.List[object]
    $newToProject = New-Object System.Collections.Generic.List[string]
    $unknownLicenses = New-Object System.Collections.Generic.List[string]

    foreach ($manifestFile in $ManifestFiles) {
        if ($manifestFile.Path -notmatch '(?:^|\\)package\.json$') {
            continue
        }

        $currentPath = Join-Path $ProjectRoot $manifestFile.Path
        $currentText = if (Test-Path -LiteralPath $currentPath -PathType Leaf) { Get-Content -LiteralPath $currentPath -Raw -Encoding UTF8 } else { $null }
        $previousText = $null
        if (-not [string]::IsNullOrWhiteSpace($BaselineRef)) {
            $showRef = '{0}:{1}' -f $BaselineRef, ($manifestFile.Path -replace '\\','/')
            $showOutput = @(& git -C $ProjectRoot show $showRef 2>$null)
            if ($LASTEXITCODE -eq 0) {
                $previousText = $showOutput -join [Environment]::NewLine
            }
        }

        $currentDependencies = Get-PackageJsonDependencies -JsonText $currentText
        $previousDependencies = Get-PackageJsonDependencies -JsonText $previousText
        $packageNames = New-Object System.Collections.Generic.HashSet[string] ([System.StringComparer]::OrdinalIgnoreCase)
        foreach ($name in $currentDependencies.Keys) { $null = $packageNames.Add($name) }
        foreach ($name in $previousDependencies.Keys) { $null = $packageNames.Add($name) }

        foreach ($packageName in $packageNames) {
            $before = if ($previousDependencies.ContainsKey($packageName)) { $previousDependencies[$packageName] } else { $null }
            $after = if ($currentDependencies.ContainsKey($packageName)) { $currentDependencies[$packageName] } else { $null }
            if ($null -eq $before -and $null -eq $after) {
                continue
            }

            $changeType = if ($null -eq $before) {
                'added'
            }
            elseif ($null -eq $after) {
                'removed'
            }
            elseif ([string]$before.Version -eq [string]$after.Version) {
                continue
            }
            else {
                'upgraded'
            }

            $owningTask = @($PlanTasks | Where-Object { ([string]$_.Title) -match 'depend|package|upgrade|manifest' } | Select-Object -First 1)
            $taskId = if ($owningTask.Count -gt 0) { [string]$owningTask[0].Task } else { '(unknown)' }
            $license = 'unknown'
            if ($license -eq 'unknown' -and -not $unknownLicenses.Contains($packageName)) {
                $null = $unknownLicenses.Add($packageName)
            }
            if ($changeType -eq 'added' -and -not $newToProject.Contains($packageName)) {
                $null = $newToProject.Add($packageName)
            }

            $rows.Add([pscustomobject]@{
                    Ecosystem  = 'npm'
                    Package    = $packageName
                    From       = if ($null -ne $before) { [string]$before.Version } else { 'none' }
                    To         = if ($null -ne $after) { [string]$after.Version } else { 'none' }
                    ChangeType = $changeType
                    License    = $license
                    OwningTask = $taskId
                })
        }
    }

    return [pscustomobject]@{
        Rows            = $rows.ToArray()
        NewToProject    = $newToProject.ToArray()
        UnknownLicenses = $unknownLicenses.ToArray()
    }
}

function Get-VulnerabilityScanResult {
    param(
        [string]$ProjectRoot,
        [object]$ReviewerConfig,
        [bool]$ManifestChanged
    )

    if (-not $ManifestChanged) {
        return [pscustomobject]@{
            Status     = 'unscanned'
            Count      = 'unscanned'
            Reason     = 'No manifest files changed in this iteration.'
            Tool       = ''
            Version    = ''
            ExitCode   = ''
            Output     = @()
        }
    }

    if (-not $ReviewerConfig.vulnerability_scanner.auto_detect -and [string]::IsNullOrWhiteSpace($ReviewerConfig.vulnerability_scanner.command)) {
        return [pscustomobject]@{
            Status     = 'unscanned'
            Count      = 'unscanned'
            Reason     = 'Auto-detected vulnerability scanning is disabled and no explicit scanner command is configured.'
            Tool       = ''
            Version    = ''
            ExitCode   = ''
            Output     = @()
        }
    }

    $candidateCommands = New-Object System.Collections.Generic.List[string]
    if (-not [string]::IsNullOrWhiteSpace($ReviewerConfig.vulnerability_scanner.command)) {
        $null = $candidateCommands.Add($ReviewerConfig.vulnerability_scanner.command)
    }
    foreach ($candidate in $ReviewerConfig.vulnerability_scanner.candidates) {
        if (-not [string]::IsNullOrWhiteSpace([string]$candidate) -and -not $candidateCommands.Contains([string]$candidate)) {
            $null = $candidateCommands.Add([string]$candidate)
        }
    }

    foreach ($candidate in $candidateCommands) {
        $baseCommand = (($candidate -split '\s+')[0]).Trim()
        if (-not (Get-Command -Name $baseCommand -ErrorAction SilentlyContinue)) {
            continue
        }

        $versionText = @(& $baseCommand '--version' 2>$null)
        if ($LASTEXITCODE -ne 0 -or $versionText.Count -eq 0) {
            $versionText = @(& $baseCommand '-version' 2>$null)
        }

        Push-Location $ProjectRoot
        try {
            $scanOutput = @(& pwsh -NoProfile -Command $candidate 2>&1)
            $exitCode = $LASTEXITCODE
        }
        finally {
            Pop-Location
        }

        $highCriticalCount = 0
        foreach ($line in $scanOutput) {
            $lineText = [string]$line
            if ($lineText -match '\b(HIGH|CRITICAL)\b') {
                $highCriticalCount++
            }
        }

        return [pscustomobject]@{
            Status   = 'scanned'
            Count    = [string]$highCriticalCount
            Reason   = ''
            Tool     = $baseCommand
            Version  = if ($versionText.Count -gt 0) { [string]$versionText[0] } else { 'unknown' }
            ExitCode = [string]$exitCode
            Output   = @($scanOutput | ForEach-Object { [string]$_ })
        }
    }

    return [pscustomobject]@{
        Status     = 'unscanned'
        Count      = 'unscanned'
        Reason     = 'No recognized vulnerability scanner command was available on PATH.'
        Tool       = ''
        Version    = ''
        ExitCode   = ''
        Output     = @()
    }
}

function Get-ImplementationBriefingPath {
    param([string]$IterationDirectory)

    foreach ($candidate in @('execution-summary.md', 'implementation-briefing.md')) {
        $path = Join-Path $IterationDirectory $candidate
        if (Test-Path -LiteralPath $path -PathType Leaf) {
            return $path
        }
    }

    return $null
}

function Get-EscalationCount {
    param([string[]]$StateLines)

    $status = Get-MetadataValue -Lines $StateLines -Label 'Status'
    if ($status) {
        return 1
    }

    foreach ($line in $StateLines) {
        if ($line -match 'Failure Count:\s*(\d+)') {
            return [int]$Matches[1]
        }
    }

    return 0
}

function Get-OwningTaskInfo {
    param(
        [string]$Path,
        [object[]]$PlanTasks,
        [string[]]$TestPathGlobs
    )

    $candidates = @()
    if (Test-IsTestPath -Path $Path -TestPathGlobs $TestPathGlobs) {
        $candidates = @($PlanTasks | Where-Object { ([string]$_.Owner) -match 'Reviewer' -or ([string]$_.Title) -match 'test|coverage|review' })
    }
    elseif (Test-IsManifestPath -Path $Path) {
        $candidates = @($PlanTasks | Where-Object { ([string]$_.Title) -match 'depend|package|manifest|upgrade' })
    }
    else {
        $candidates = @($PlanTasks | Where-Object { ([string]$_.Owner) -match 'Implementer|Planner' })
    }

    if ($candidates.Count -eq 0) {
        $candidates = @($PlanTasks | Select-Object -First 1)
    }

    $taskIds = @($candidates | ForEach-Object { ([string]$_.Task).Trim() } | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | Select-Object -Unique)
    $owningRole = if ($candidates.Count -gt 0) { ([string]$candidates[0].Owner).Trim() } else { 'Unknown' }

    return [pscustomobject]@{
        TaskIds = if ($taskIds.Count -gt 0) { $taskIds -join ', ' } else { '(unknown)' }
        Role    = if ([string]::IsNullOrWhiteSpace($owningRole)) { 'Unknown' } else { $owningRole }
    }
}

function Get-TestExecutionRows {
    param(
        [string]$ProjectRoot,
        [object]$ReviewerConfig
    )

    $rows = New-Object System.Collections.Generic.List[object]

    if ($ReviewerConfig.skip_test_execution_at_close) {
        $commands = if ($ReviewerConfig.test_commands.Count -gt 0) { $ReviewerConfig.test_commands } else { @('(no test commands configured)') }
        foreach ($command in $commands) {
            $rows.Add([pscustomobject]@{
                    Command   = $command
                    Result    = 'not_executed'
                    PassCount = '0'
                    FailCount = '0'
                    Duration  = 'n/a'
                    ExitCode  = 'n/a'
                    Notes     = 'reviewer.skip_test_execution_at_close is enabled.'
                })
        }

        return $rows.ToArray()
    }

    if ($ReviewerConfig.test_commands.Count -eq 0) {
        $rows.Add([pscustomobject]@{
                Command   = '(none configured)'
                Result    = 'not_executed'
                PassCount = '0'
                FailCount = '0'
                Duration  = 'n/a'
                ExitCode  = 'n/a'
                Notes     = 'No reviewer.test_commands were configured in iteration-config.yml.'
            })
        return $rows.ToArray()
    }

    foreach ($command in $ReviewerConfig.test_commands) {
        $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
        Push-Location $ProjectRoot
        try {
            $output = @(& pwsh -NoProfile -Command $command 2>&1)
            $exitCode = $LASTEXITCODE
        }
        finally {
            Pop-Location
            $stopwatch.Stop()
        }

        $rows.Add([pscustomobject]@{
                Command   = $command
                Result    = if ($exitCode -eq 0) { 'pass' } else { 'fail' }
                PassCount = if ($exitCode -eq 0) { '1' } else { '0' }
                FailCount = if ($exitCode -eq 0) { '0' } else { '1' }
                Duration  = $stopwatch.Elapsed.ToString()
                ExitCode  = [string]$exitCode
                Notes     = if ($output.Count -gt 0) { ([string]$output[-1]).Trim() } else { '(no output)' }
            })
    }

    return $rows.ToArray()
}

function Get-RequirementCoverageRows {
    param(
        [string[]]$RequirementRefs,
        [object[]]$ChangedFiles,
        [string[]]$TestPathGlobs,
        [object[]]$TestExecutionRows
    )

    $changedTestFiles = @($ChangedFiles | Where-Object { Test-IsTestPath -Path ([string]$_.Path) -TestPathGlobs $TestPathGlobs } | ForEach-Object { [string]$_.Path } | Select-Object -Unique)
    $executedCommands = @($TestExecutionRows | Where-Object { ([string]$_.Result) -eq 'pass' } | ForEach-Object { [string]$_.Command } | Select-Object -Unique)

    $rows = New-Object System.Collections.Generic.List[object]
    foreach ($requirementRef in $RequirementRefs) {
        $evidence = New-Object System.Collections.Generic.List[string]
        foreach ($path in $changedTestFiles) { $null = $evidence.Add($path) }
        foreach ($command in $executedCommands) { $null = $evidence.Add("cmd:$command") }

        if ($evidence.Count -eq 0) {
            $null = $evidence.Add('not_executed')
        }

        $rows.Add([pscustomobject]@{
                RequirementRef = $requirementRef
                Evidence       = $evidence.ToArray()
            })
    }

    return $rows.ToArray()
}

function Get-ReviewerGapHints {
    param(
        [string[]]$ReviewLines,
        [string[]]$Hotspots,
        [string[]]$UnknownLicenses,
        [object]$VulnerabilityScan,
        [string]$CoverageSignal,
        [int]$Escalations,
        [int]$RoutingFallbacks,
        [object]$DriftSummary
    )

    $hints = New-Object System.Collections.Generic.List[string]
    foreach ($hotspot in $Hotspots) {
        $null = $hints.Add("Hotspot: $hotspot")
    }
    foreach ($packageName in $UnknownLicenses) {
        $null = $hints.Add("Unknown license: $packageName")
    }
    if ($VulnerabilityScan.Status -eq 'unscanned') {
        $null = $hints.Add("Vulnerability scan: unscanned ($($VulnerabilityScan.Reason))")
    }
    if ($CoverageSignal -eq 'not_executed') {
        $null = $hints.Add('Coverage execution: not_executed')
    }
    if ($Escalations -gt 0) {
        $null = $hints.Add("Escalations recorded: $Escalations")
    }
    if ($RoutingFallbacks -gt 0) {
        $null = $hints.Add("Routing fallbacks recorded: $RoutingFallbacks")
    }
    if ($DriftSummary.Total -gt $DriftSummary.Resolved) {
        $null = $hints.Add("Unresolved drift remains: $($DriftSummary.Total - $DriftSummary.Resolved)")
    }

    $gapLedgerLines = @(Get-MarkdownSectionLines -Lines $ReviewLines -Heading 'Gap Ledger')
    $meaningfulGapLedger = @($gapLedgerLines | Where-Object { -not [string]::IsNullOrWhiteSpace($_) -and $_ -notmatch 'No known gaps remain\.' })
    if ($meaningfulGapLedger.Count -gt 0) {
        $null = $hints.Add('Gap Ledger contains active concerns; review review.md before sign-off.')
    }

    if ($hints.Count -eq 0) {
        $null = $hints.Add('No hotspot, vulnerability, coverage, or drift triage hints remain active.')
    }

    return $hints.ToArray()
}

function Format-ReviewerSummaryLines {
    param([object]$Summary)

    return @(
        ('Header: feature={0} | iteration={1} | branch={2} | commit_range={3}' -f $Summary.Feature, $Summary.Iteration, $Summary.Branch, $Summary.CommitRange)
        ('Verdict: {0}' -f $Summary.Verdict)
        ('Requirements: covered={0} | not_covered={1}' -f $Summary.RequirementsCovered, $Summary.RequirementsNotCovered)
        ('Code Surface: files={0} | hotspots={1} | test_to_code={2}' -f $Summary.FilesTouched, $Summary.HotspotCount, $Summary.TestToCodeRatio)
        ('Dependencies: changed={0} | new_to_project={1} | vulnerability={2}' -f $Summary.DependencyChanges, $Summary.NewDependencies, $Summary.VulnerabilitySignal)
        ('Coverage: kind={0} | signal={1}' -f $Summary.CoverageKind, $Summary.CoverageSignal)
        ('Operational Signals: escalations={0} | routing_fallbacks={1}' -f $Summary.Escalations, $Summary.RoutingFallbacks)
        ('Drift: {0}/{1} resolved' -f $Summary.DriftTotal, $Summary.DriftResolved)
        ('Reviewer Index: {0}' -f $Summary.IndexRelativePath)
        ('Implementation Briefing: {0}' -f $Summary.ImplementationBriefing)
        ('Local Open Hints: {0}' -f ($Summary.LocalOpenHints -join '; '))
    )
}

function Write-ReviewerSummary {
    param([object]$Summary)

    $summaryLines = Format-ReviewerSummaryLines -Summary $Summary
    $border = ('=' * 60)
    Write-Host $border -ForegroundColor Green
    Write-Host 'SPECREW REVIEWER SUMMARY' -ForegroundColor Green
    Write-Host $border -ForegroundColor Green
    foreach ($line in $summaryLines) {
        Write-Host $line
    }
}

$resolvedIterationDirectory = [System.IO.Path]::GetFullPath($IterationDirectory)
$planPath = Join-Path $resolvedIterationDirectory 'plan.md'
$reviewPath = Join-Path $resolvedIterationDirectory 'review.md'
$statePath = Join-Path $resolvedIterationDirectory 'state.md'
$driftPath = Join-Path $resolvedIterationDirectory 'drift-log.md'
$codeMapPath = Join-Path $resolvedIterationDirectory 'code-map.md'
$dependencyReportPath = Join-Path $resolvedIterationDirectory 'dependency-report.md'
$coverageEvidencePath = Join-Path $resolvedIterationDirectory 'coverage-evidence.md'
$securitySurfacePath = Join-Path $resolvedIterationDirectory 'security-surface.md'
$reviewerIndexPath = Join-Path $resolvedIterationDirectory 'reviewer-index.md'
$reviewDiagramsPath = Join-Path $resolvedIterationDirectory 'review-diagrams.md'
$actions = [System.Collections.ArrayList]::new()

foreach ($requiredPath in @($planPath, $reviewPath, $statePath, $driftPath)) {
    if (-not (Test-Path -LiteralPath $requiredPath -PathType Leaf)) {
        throw "Required iteration artifact is missing: $requiredPath"
    }
}

$planLines = @(Get-MarkdownContent -Path $planPath)
$reviewLines = @(Get-MarkdownContent -Path $reviewPath)
$stateLines = @(Get-MarkdownContent -Path $statePath)
$driftLines = @(Get-MarkdownContent -Path $driftPath)
$planTasks = @(Get-MarkdownSectionTable -Lines $planLines -Heading 'Tasks')
$reviewTasks = @(Get-MarkdownSectionTable -Lines $reviewLines -Heading 'Task Verdicts')
if ($planTasks.Count -eq 0) {
    throw "Plan '$planPath' does not contain a populated Tasks table."
}

$iterationLabel = Get-IterationLabel -PlanLines $planLines -Fallback (Split-Path -Leaf $resolvedIterationDirectory)
$reviewedDate = Get-MetadataValue -Lines $reviewLines -Label 'Reviewed'
$overallVerdict = Get-MetadataValue -Lines $reviewLines -Label 'Overall Verdict'
$baselineRef = Get-MetadataValue -Lines $stateLines -Label 'Baseline Ref'
$driftSummary = Get-DriftSummary -Lines $driftLines
$specDirectory = Split-Path -Parent (Split-Path -Parent $resolvedIterationDirectory)
$projectRoot = Split-Path -Parent (Split-Path -Parent $specDirectory)
$featureId = Split-Path -Leaf $specDirectory
$currentArchitecturePath = Join-Path $specDirectory 'current-architecture.md'
$reviewerConfig = (Get-ReviewerConfig -ProjectRoot $projectRoot).reviewer
$diffArtifacts = Get-DiffArtifacts -ProjectRoot $projectRoot -BaselineRef $baselineRef
$implementationBriefingPath = Get-ImplementationBriefingPath -IterationDirectory $resolvedIterationDirectory
$implementationBriefingRelative = if ($implementationBriefingPath) { Get-RelativePath -FromDirectory $projectRoot -ToPath $implementationBriefingPath } else { '(unavailable)' }
$decisionsPath = Join-Path $projectRoot '.squad\decisions.md'
$decisionsRelativePath = '.squad\decisions.md'
$securityContext = Get-SecurityTriggerContext -ProjectRoot $projectRoot -PlanLines $planLines

$verdictByTask = @{}
foreach ($reviewTask in $reviewTasks) {
    $taskId = [string]$reviewTask.Task
    if (-not [string]::IsNullOrWhiteSpace($taskId)) {
        $verdictByTask[$taskId.Trim()] = $reviewTask
    }
}

$requirementRefs = New-Object System.Collections.Generic.List[string]
foreach ($task in $planTasks) {
    foreach ($requirementRef in @(([string]$task.Requirement) -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ -match '^FR-\d+$' })) {
        if (-not $requirementRefs.Contains($requirementRef)) {
            $null = $requirementRefs.Add($requirementRef)
        }
    }
}

$passCount = @($reviewTasks | Where-Object { ([string]$_.Verdict).Trim().ToLowerInvariant() -eq 'pass' }).Count
$taskTotal = $planTasks.Count
$requirementsCovered = if ($requirementRefs.Count -gt 0) { $requirementRefs -join ', ' } else { '(none)' }
$requirementsNotCovered = '(none)'

$changedFiles = @($diffArtifacts.Files)
$manifestFiles = @($changedFiles | Where-Object { $_.IsManifest })
$changedCodeFiles = @(Get-ChangedCodeFiles -ChangedFiles $changedFiles -TestPathGlobs $reviewerConfig.test_path_globs)
$publicApiDelta = Get-PublicApiDelta -ProjectRoot $projectRoot -BaselineRef $baselineRef -Files $changedFiles
$dependencyAnalysis = Get-ManifestDiffRows -ProjectRoot $projectRoot -BaselineRef $baselineRef -ManifestFiles $manifestFiles -PlanTasks $planTasks
$vulnerabilityScan = Get-VulnerabilityScanResult -ProjectRoot $projectRoot -ReviewerConfig $reviewerConfig -ManifestChanged:($manifestFiles.Count -gt 0)
$testExecutionRows = @(Get-TestExecutionRows -ProjectRoot $projectRoot -ReviewerConfig $reviewerConfig)
$coverageRows = @(Get-RequirementCoverageRows -RequirementRefs $requirementRefs.ToArray() -ChangedFiles $changedFiles -TestPathGlobs $reviewerConfig.test_path_globs -TestExecutionRows $testExecutionRows)
$escalationCount = Get-EscalationCount -StateLines $stateLines
$routingFallbackCount = 0
$sensitiveTouchpoints = @(Get-SensitiveTouchpoints -ProjectRoot $projectRoot -ChangedFiles $changedFiles -Patterns $reviewerConfig.sensitive_data_patterns)
$diagramEvidence = Get-DiagramEvidence -ProjectRoot $projectRoot -ChangedFiles $changedFiles -ReviewerConfig $reviewerConfig

$codeMapRows = @(
    '| Path | Lines Added | Lines Removed | Owning Task ID(s) | Owning Role |'
    '| ---- | ----------- | ------------- | ----------------- | ----------- |'
)
$hotspots = New-Object System.Collections.Generic.List[string]
$testFileCount = 0
$codeFileCount = 0
foreach ($file in $changedFiles) {
    $ownership = Get-OwningTaskInfo -Path ([string]$file.Path) -PlanTasks $planTasks -TestPathGlobs $reviewerConfig.test_path_globs
    $codeMapRows += ('| {0} | {1} | {2} | {3} | {4} |' -f $file.Path, $file.Added, $file.Removed, $ownership.TaskIds, $ownership.Role)

    $deltaTotal = 0
    if ($file.Added -match '^\d+$') { $deltaTotal += [int]$file.Added }
    if ($file.Removed -match '^\d+$') { $deltaTotal += [int]$file.Removed }
    if ($deltaTotal -ge [int]$reviewerConfig.hotspot_thresholds.file_changed_lines) {
        $null = $hotspots.Add(('{0} ({1} changed lines)' -f $file.Path, $deltaTotal))
    }

    if (Test-IsTestPath -Path ([string]$file.Path) -TestPathGlobs $reviewerConfig.test_path_globs) {
        $testFileCount++
    }
    elseif (-not $file.IsManifest) {
        $codeFileCount++
    }
}
if ($changedFiles.Count -eq 0) {
    $codeMapRows += '| (none) | 0 | 0 | (none) | (none) |'
}

$publicApiSection = @(
    '## Public-API Delta'
    ''
    '### Added'
    ''
)
if ($publicApiDelta.Added.Count -gt 0) {
    $publicApiSection += @($publicApiDelta.Added | ForEach-Object { "- $_" })
}
else {
    $publicApiSection += '- none'
}
$publicApiSection += @('', '### Removed', '')
if ($publicApiDelta.Removed.Count -gt 0) {
    $publicApiSection += @($publicApiDelta.Removed | ForEach-Object { "- $_" })
}
else {
    $publicApiSection += '- none'
}

$hotspotSection = @(
    '## Module Hotspots'
    ''
    ('- Threshold: {0} changed lines per file' -f $reviewerConfig.hotspot_thresholds.file_changed_lines)
)
if ($hotspots.Count -gt 0) {
    $hotspotSection += @($hotspots | ForEach-Object { "- $_" })
}
else {
    $hotspotSection += '- none'
}

$testToCodeRatio = if ($codeFileCount -eq 0) {
    ('{0}:0' -f $testFileCount)
}
else {
    ('{0}:{1}' -f $testFileCount, $codeFileCount)
}

$dependencyRows = @(
    '| Ecosystem | Package | Prior Version | New Version | Change Type | License | Owning Task |'
    '| --------- | ------- | ------------- | ----------- | ----------- | ------- | ----------- |'
)
if ($dependencyAnalysis.Rows.Count -gt 0) {
    foreach ($row in $dependencyAnalysis.Rows) {
        $dependencyRows += ('| {0} | {1} | {2} | {3} | {4} | {5} | {6} |' -f $row.Ecosystem, $row.Package, $row.From, $row.To, $row.ChangeType, $row.License, $row.OwningTask)
    }
}
else {
    $dependencyRows += '| (none) | (none) | none | none | none | unknown | (none) |'
}

$testsRunRows = @(
    '| Command | Result | Pass Count | Fail Count | Duration | Exit Code | Notes |'
    '| ------- | ------ | ---------- | ---------- | -------- | --------- | ----- |'
)
foreach ($row in $testExecutionRows) {
    $testsRunRows += ('| {0} | {1} | {2} | {3} | {4} | {5} | {6} |' -f $row.Command, $row.Result, $row.PassCount, $row.FailCount, $row.Duration, $row.ExitCode, (($row.Notes -replace '\|', '\|')))
}

$coverageMapRows = @(
    '| Requirement | Test Files / Commands |'
    '| ----------- | --------------------- |'
)
foreach ($row in $coverageRows) {
    $coverageMapRows += ('| {0} | {1} |' -f $row.RequirementRef, (($row.Evidence -join ', ') -replace '\|', '\|'))
}

$coverageSignal = if (@($testExecutionRows | Where-Object { ([string]$_.Result) -eq 'not_executed' }).Count -gt 0) {
    'not_executed'
}
elseif ($reviewerConfig.coverage.kind -eq 'measured' -and -not [string]::IsNullOrWhiteSpace($reviewerConfig.coverage.tool)) {
    'unknown'
}
else {
    'focused_regression'
}

$coverageEstimateSection = @(
    '## Coverage Estimate'
    ''
    ('- Kind: {0}' -f $(if ($reviewerConfig.coverage.kind -eq 'measured' -and $coverageSignal -ne 'not_executed') { 'measured' } else { 'qualitative' }))
    ('- Label: {0}' -f $coverageSignal)
    ('- Tool: {0}' -f $(if ([string]::IsNullOrWhiteSpace($reviewerConfig.coverage.tool)) { 'unknown' } else { $reviewerConfig.coverage.tool }))
)

$codeMapContent = @"
# Code Map: Iteration $iterationLabel

**Schema**: v1
**Reviewed**: $reviewedDate
**Baseline Ref**: $(if ($diffArtifacts.BaselineResolved) { $baselineRef } elseif ($baselineRef) { "$baselineRef (unresolved)" } else { 'unknown' })
**Test-to-Code Ratio**: $testToCodeRatio

## Files Touched

$($codeMapRows -join [Environment]::NewLine)

$($publicApiSection -join [Environment]::NewLine)

$($hotspotSection -join [Environment]::NewLine)
"@

$dependencyReportContent = @"
# Dependency Report: Iteration $iterationLabel

**Schema**: v1
**Reviewed**: $reviewedDate
**Baseline Ref**: $(if ($diffArtifacts.BaselineResolved) { $baselineRef } elseif ($baselineRef) { "$baselineRef (unresolved)" } else { 'unknown' })

## Dependency Delta

$($dependencyRows -join [Environment]::NewLine)

## New-to-Project

$(if ($dependencyAnalysis.NewToProject.Count -gt 0) { ($dependencyAnalysis.NewToProject | ForEach-Object { "- $_" }) -join [Environment]::NewLine } else { '- none' })

## Vulnerability Scan

$(
    $vulnerabilitySection = New-Object System.Collections.Generic.List[string]
    if ($vulnerabilityScan.Status -eq 'scanned') {
        $null = $vulnerabilitySection.Add('- status: scanned')
        $null = $vulnerabilitySection.Add(('- tool: {0}' -f $vulnerabilityScan.Tool))
        $null = $vulnerabilitySection.Add(('- version: {0}' -f $vulnerabilityScan.Version))
        $null = $vulnerabilitySection.Add(('- exit_code: {0}' -f $vulnerabilityScan.ExitCode))
        $null = $vulnerabilitySection.Add(('- high_critical_findings: {0}' -f $vulnerabilityScan.Count))
        if ($vulnerabilityScan.Output.Count -gt 0) {
            $null = $vulnerabilitySection.Add('')
            $null = $vulnerabilitySection.Add('```text')
            foreach ($line in $vulnerabilityScan.Output) {
                $null = $vulnerabilitySection.Add([string]$line)
            }
            $null = $vulnerabilitySection.Add('```')
        }
    }
    else {
        $null = $vulnerabilitySection.Add('- status: unscanned')
        $null = $vulnerabilitySection.Add(('- reason: {0}' -f $vulnerabilityScan.Reason))
    }
    $vulnerabilitySection -join [Environment]::NewLine
)

## Transitive Surface

- $(if ($manifestFiles.Count -gt 0) { 'unresolved | No lockfile- or tool-backed transitive resolution signal was captured in v1.' } else { 'none | No manifest changes were detected.' })
"@

$coverageEvidenceContent = @"
# Coverage Evidence: Iteration $iterationLabel

**Schema**: v1
**Reviewed**: $reviewedDate
**Overall Verdict**: $overallVerdict

## Test Strategy

- Implementation briefing: $implementationBriefingRelative
- Review-time strategy: use `reviewer.test_commands` when configured; otherwise record `not_executed` explicitly and keep the signal visible in closeout output.

## Tests Run

$($testsRunRows -join [Environment]::NewLine)

$($coverageEstimateSection -join [Environment]::NewLine)

## Coverage-to-Requirements

$($coverageMapRows -join [Environment]::NewLine)
"@

$indexRelativePath = Get-RelativePath -FromDirectory $projectRoot -ToPath $reviewerIndexPath
$securitySurfaceReason = $securityContext.Reason
$securitySurfaceRelative = Get-RelativePath -FromDirectory $projectRoot -ToPath $securitySurfacePath
$reviewDiagramsRelative = Get-RelativePath -FromDirectory $projectRoot -ToPath $reviewDiagramsPath
$currentArchitectureRelative = Get-RelativePath -FromDirectory $projectRoot -ToPath $currentArchitecturePath
$currentArchitectureFromIterationRelative = Get-RelativePath -FromDirectory $resolvedIterationDirectory -ToPath $currentArchitecturePath
$currentArchitectureDiagramRelative = Get-RelativePath -FromDirectory (Split-Path -Parent $currentArchitecturePath) -ToPath $reviewDiagramsPath

$securitySurfaceContent = @"
# Security Surface: Iteration $iterationLabel

**Schema**: v1
**Reviewed**: $reviewedDate

## Trust Boundaries Touched

$(if ($changedCodeFiles.Count -gt 0) { ($changedCodeFiles | ForEach-Object { '- ' + $_.Path }) -join [Environment]::NewLine } else { '- none' })

## Sensitive Data Touchpoints

$(if ($sensitiveTouchpoints.Count -gt 0) { ($sensitiveTouchpoints | ForEach-Object { '- ' + $_ }) -join [Environment]::NewLine } else { '- none | No changed files matched reviewer.sensitive_data_patterns.' })

## Security Specialist Findings

$(if ($securityContext.SecurityRoles.Count -gt 0) { '- Roles present: ' + ($securityContext.SecurityRoles -join ', ') + [Environment]::NewLine + '- No explicit specialist findings were recorded in review artifacts for this iteration.' } else { '- No security specialist was present for this iteration.' })

## Vulnerability Highlights

$(Get-VulnerabilityHighlights -VulnerabilityScan $vulnerabilityScan -join [Environment]::NewLine)
"@

$reviewDiagramsContent = @"
# Review Diagrams: Iteration $iterationLabel

**Schema**: v1
**Diagram Format**: $($reviewerConfig.diagram_format)

## Structure Diagram

$(if ($diagramEvidence.StructureDiagram) { $diagramEvidence.StructureDiagram } else { '_omitted_' })

## Flow Diagram

$(if ($diagramEvidence.FlowDiagram) { $diagramEvidence.FlowDiagram } else { '_omitted_' })

## Omissions

$(if ($diagramEvidence.Omissions.Count -gt 0) { ($diagramEvidence.Omissions | ForEach-Object { '- ' + $_ }) -join [Environment]::NewLine } else { '- none' })

## Local View Hints

- $reviewDiagramsRelative
"@

$currentArchitectureContent = @"
# Current Architecture: $featureId

**Source Iteration Ref**: $iterationLabel
**Last Updated**: $(Get-Date -Format 'yyyy-MM-ddTHH:mm:ssK')

## Summary

- Latest reviewer snapshot: `iterations/$iterationLabel/`
- Current reviewer index: $indexRelativePath
- Security surface: $(if ($securityContext.Enabled) { $securitySurfaceRelative } else { 'not generated for this iteration (' + $securitySurfaceReason + ')' })
- Review diagrams: $reviewDiagramsRelative

## Linked Current Diagrams

- $currentArchitectureDiagramRelative
"@

$branchName = @(& git -C $projectRoot branch --show-current 2>$null)
$branchName = if ($LASTEXITCODE -eq 0 -and $branchName.Count -gt 0 -and -not [string]::IsNullOrWhiteSpace($branchName[0])) { [string]$branchName[0] } else { '(unknown)' }
$commitRange = if ($diffArtifacts.BaselineResolved -and $diffArtifacts.HeadResolved) { "$baselineRef..$($diffArtifacts.HeadRef)" } elseif ($diffArtifacts.BaselineResolved) { "$baselineRef..working-tree" } else { 'unknown' }
$localOpenHints = New-Object System.Collections.Generic.List[string]
$null = $localOpenHints.Add($indexRelativePath)
$null = $localOpenHints.Add($reviewDiagramsRelative)
$null = $localOpenHints.Add($currentArchitectureRelative)

$summaryObject = [pscustomobject]@{
    Feature                 = $featureId
    Iteration               = $iterationLabel
    Branch                  = $branchName
    CommitRange             = $commitRange
    Verdict                 = $overallVerdict
    RequirementsCovered     = $requirementsCovered
    RequirementsNotCovered  = $requirementsNotCovered
    FilesTouched            = $changedFiles.Count
    HotspotCount            = $hotspots.Count
    TestToCodeRatio         = $testToCodeRatio
    DependencyChanges       = $dependencyAnalysis.Rows.Count
    NewDependencies         = $dependencyAnalysis.NewToProject.Count
    VulnerabilitySignal     = $vulnerabilityScan.Count
    CoverageKind            = if ($coverageSignal -eq 'not_executed') { 'qualitative' } else { $reviewerConfig.coverage.kind }
    CoverageSignal          = $coverageSignal
    Escalations             = $escalationCount
    RoutingFallbacks        = $routingFallbackCount
    DriftTotal              = $driftSummary.Total
    DriftResolved           = $driftSummary.Resolved
    IndexRelativePath       = $indexRelativePath
    ImplementationBriefing  = $implementationBriefingRelative
    LocalOpenHints          = $localOpenHints.ToArray()
}

$summaryLines = Format-ReviewerSummaryLines -Summary $summaryObject
$digestLine = ('SPECREW_REVIEW schema=v1 iter={0} feature={1} verdict={2} tasks={3}/{4} reqs={5} files={6} new_deps={7} vuln={8} cov={9} escalations={10} drift={11}/{12} index={13}' -f $iterationLabel, $featureId, $overallVerdict, $passCount, $taskTotal, $reviewTasks.Count, $changedFiles.Count, $dependencyAnalysis.NewToProject.Count, $vulnerabilityScan.Count, $coverageSignal, $escalationCount, $driftSummary.Total, $driftSummary.Resolved, $indexRelativePath)
$triageHints = Get-ReviewerGapHints -ReviewLines $reviewLines -Hotspots $hotspots.ToArray() -UnknownLicenses $dependencyAnalysis.UnknownLicenses -VulnerabilityScan $vulnerabilityScan -CoverageSignal $coverageSignal -Escalations $escalationCount -RoutingFallbacks $routingFallbackCount -DriftSummary $driftSummary

$reviewerIndexContent = @"
# Reviewer Index: Iteration $iterationLabel

**Schema**: v1
**Reviewed**: $reviewedDate
**Overall Verdict**: $overallVerdict

## Summary

$(($summaryLines | ForEach-Object { "- $_" }) -join [Environment]::NewLine)

## Read Order

1. [review.md](review.md)
2. [code-map.md](code-map.md)
3. [dependency-report.md](dependency-report.md)
4. [coverage-evidence.md](coverage-evidence.md)
5. $(if ($securityContext.Enabled) { '[security-surface.md](security-surface.md)' } else { 'security-surface.md omitted: ' + $securitySurfaceReason })
6. [review-diagrams.md](review-diagrams.md)
7. [$currentArchitectureFromIterationRelative]($currentArchitectureFromIterationRelative)
8. $(if ($implementationBriefingPath) { '[' + (Split-Path -Leaf $implementationBriefingPath) + '](' + (Split-Path -Leaf $implementationBriefingPath) + ')' } else { 'Implementation briefing unavailable for this iteration' })

## Artifact Links

- [review.md](review.md)
- [code-map.md](code-map.md)
- [dependency-report.md](dependency-report.md)
- [coverage-evidence.md](coverage-evidence.md)
- $(if ($securityContext.Enabled) { '[security-surface.md](security-surface.md)' } else { 'security-surface.md omitted: ' + $securitySurfaceReason })
- [review-diagrams.md](review-diagrams.md)
- [$currentArchitectureFromIterationRelative]($currentArchitectureFromIterationRelative) *(mutable current view)*
- $(if ($implementationBriefingPath) { '[' + (Split-Path -Leaf $implementationBriefingPath) + '](' + (Split-Path -Leaf $implementationBriefingPath) + ')' } else { 'Implementation briefing unavailable' })
- $(if (Test-Path -LiteralPath $decisionsPath -PathType Leaf) { '[' + $decisionsRelativePath + '](' + $decisionsRelativePath + ')' } else { $decisionsRelativePath + ' (unavailable)' })

## Triage Hints

$(($triageHints | ForEach-Object { "- $_" }) -join [Environment]::NewLine)

## Replay Digest

$digestLine
"@

if (-not $SummaryOnly) {
    Write-ScaffoldFile -TargetPath $codeMapPath -Content $codeMapContent -Actions $actions
    Write-ScaffoldFile -TargetPath $dependencyReportPath -Content $dependencyReportContent -Actions $actions
    Write-ScaffoldFile -TargetPath $coverageEvidencePath -Content $coverageEvidenceContent -Actions $actions
    if ($securityContext.Enabled) {
        Write-ScaffoldFile -TargetPath $securitySurfacePath -Content $securitySurfaceContent -Actions $actions
    }
    Write-ScaffoldFile -TargetPath $reviewerIndexPath -Content $reviewerIndexContent -Actions $actions
    Write-ScaffoldFile -TargetPath $reviewDiagramsPath -Content $reviewDiagramsContent -Actions $actions
    Write-ScaffoldFile -TargetPath $currentArchitecturePath -Content $currentArchitectureContent -Actions $actions
}

if ($PassThru) {
    $actions
    return
}

if (-not $SummaryOnly) {
    $actions | Select-Object Action, Path | Format-Table -AutoSize
}

$nonInteractive = $env:CI -or [Console]::IsOutputRedirected
if ($nonInteractive) {
    Write-Host $digestLine
}
else {
    Write-ReviewerSummary -Summary $summaryObject
}

exit 0
