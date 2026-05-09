[CmdletBinding()]
param(
    [string]$ProjectPath = (Get-Location).Path,
    [string]$FeaturePath,
    [string]$IterationPath,
    [string]$SpecPath,
    [string]$DispositionPath,
    [ValidateSet('Object', 'Json')]
    [string]$OutputFormat = 'Object'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$sharedGovernancePath = Join-Path $PSScriptRoot 'shared-governance.ps1'
if (-not (Test-Path -LiteralPath $sharedGovernancePath -PathType Leaf)) {
    throw "Shared governance helper not found at '$sharedGovernancePath'."
}
. $sharedGovernancePath

function Convert-ToRepoRelativePath {
    param(
        [Parameter(Mandatory = $true)]
        [string]$BasePath,

        [Parameter(Mandatory = $true)]
        [string]$TargetPath
    )

    $baseUri = [System.Uri]([System.IO.Path]::GetFullPath($BasePath).TrimEnd('\') + '\')
    $targetUri = [System.Uri][System.IO.Path]::GetFullPath($TargetPath)
    $relativeUri = $baseUri.MakeRelativeUri($targetUri)
    return [System.Uri]::UnescapeDataString($relativeUri.ToString()).Replace('\', '/')
}

function Get-MarkdownSectionTable {
    param(
        [AllowEmptyString()]
        [string[]]$Lines,
        [string]$Heading
    )

    $headingPattern = '^#{2,3}\s+' + [regex]::Escape($Heading) + '\b'
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
        if ($currentLine -match '^#{2,3}\s+') {
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
            $value = if ($cellIndex -lt $cells.Count) { $cells[$cellIndex] } else { '' }
            $row[$headers[$cellIndex]] = $value
        }

        $rows.Add([pscustomobject]$row)
    }

    return $rows.ToArray()
}

function Get-MarkdownMetadataValue {
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

function Normalize-MarkdownCell {
    param([AllowNull()][string]$Value)

    if ($null -eq $Value) {
        return ''
    }

    return $Value.Trim().Trim('`')
}

function Get-DefaultRequirementRefsForGate {
    param(
        [Parameter(Mandatory = $true)]
        [string]$GateId
    )

    switch ($GateId) {
        'dead-field' { return @('FR-011', 'FR-027', 'FR-030') }
        'anti-pattern' { return @('FR-011', 'FR-028', 'FR-030') }
        'test-integrity' { return @('FR-011', 'FR-029', 'FR-030') }
        'stack-tooling-evidence' { return @('FR-011') }
        'quality-lens-review' { return @('FR-011', 'FR-012') }
        'concurrency-correctness-review' { return @('FR-011', 'FR-012', 'FR-015') }
        'resiliency-semantics-review' { return @('FR-011', 'FR-012', 'FR-015') }
        'retry-idempotency-review' { return @('FR-011', 'FR-012', 'FR-015') }
        default { return @('FR-011') }
    }
}

function Resolve-QualityEvidenceSource {
    param(
        [AllowNull()][string]$Value,
        [Parameter(Mandatory = $true)]
        [string]$FeatureId,
        [Parameter(Mandatory = $true)]
        [string]$IterationNumber,
        [Parameter(Mandatory = $true)]
        [string]$FindingsRef,
        [Parameter(Mandatory = $true)]
        [string]$EvidenceRef
    )

    $normalized = Normalize-MarkdownCell $Value
    if ([string]::IsNullOrWhiteSpace($normalized)) {
        return $EvidenceRef
    }

    $resolved = $normalized.Replace('specs/<feature>/iterations/<NNN>/quality/mechanical-findings.json', $FindingsRef)
    $resolved = $resolved.Replace('specs/<feature>/iterations/<NNN>/quality/quality-evidence.md', $EvidenceRef)
    $resolved = $resolved.Replace('<feature>', $FeatureId)
    $resolved = $resolved.Replace('<NNN>', $IterationNumber)
    return $resolved
}

function Get-DefaultQualityGateRows {
    return @(
        [pscustomobject]@{ 'Required Quality Gate' = 'dead-field'; Category = 'mechanical'; 'Evidence Source' = 'specs/<feature>/iterations/<NNN>/quality/mechanical-findings.json' }
        [pscustomobject]@{ 'Required Quality Gate' = 'anti-pattern'; Category = 'mechanical'; 'Evidence Source' = 'specs/<feature>/iterations/<NNN>/quality/mechanical-findings.json' }
        [pscustomobject]@{ 'Required Quality Gate' = 'test-integrity'; Category = 'mechanical'; 'Evidence Source' = 'specs/<feature>/iterations/<NNN>/quality/mechanical-findings.json' }
        [pscustomobject]@{ 'Required Quality Gate' = 'stack-tooling-evidence'; Category = 'tooling'; 'Evidence Source' = 'specs/<feature>/iterations/<NNN>/quality/quality-evidence.md' }
        [pscustomobject]@{ 'Required Quality Gate' = 'quality-lens-review'; Category = 'manual-evidence'; 'Evidence Source' = 'specs/<feature>/iterations/<NNN>/quality/quality-evidence.md' }
    )
}

function Get-ExistingQualityEvidenceState {
    param([string]$QualityEvidencePath)

    $rowsByGate = @{}
    $reviewedBy = $null
    $reviewedAt = $null

    if (Test-Path -LiteralPath $QualityEvidencePath -PathType Leaf) {
        $evidenceLines = @(Get-Content -LiteralPath $QualityEvidencePath -Encoding UTF8)
        $reviewedBy = Get-MarkdownMetadataValue -Lines $evidenceLines -Label 'Reviewed By'
        $reviewedAt = Get-MarkdownMetadataValue -Lines $evidenceLines -Label 'Reviewed At'

        foreach ($row in @(Get-MarkdownSectionTable -Lines $evidenceLines -Heading 'Gate Matrix')) {
            $gateId = Normalize-MarkdownCell ([string]$row.Gate)
            if ([string]::IsNullOrWhiteSpace($gateId)) {
                continue
            }

            $rowsByGate[$gateId] = [pscustomobject]@{
                Requirement   = Normalize-MarkdownCell ([string]$row.Requirement)
                EvidenceSource = Normalize-MarkdownCell ([string]$row.'Evidence Source')
                Status        = Normalize-MarkdownCell ([string]$row.Status)
                Exception     = Normalize-MarkdownCell ([string]$row.Exception)
            }
        }
    }

    return [pscustomobject]@{
        RowsByGate = $rowsByGate
        ReviewedBy = $reviewedBy
        ReviewedAt = $reviewedAt
    }
}

function Get-MechanicalGateOverrides {
    param(
        [AllowEmptyCollection()]
        [Parameter(Mandatory = $true)]
        [object[]]$Findings,
        [Parameter(Mandatory = $true)]
        [string]$FindingsRef
    )

    $overrides = @{}
    foreach ($gateId in @('dead-field', 'anti-pattern', 'test-integrity')) {
        $gateFindings = @($Findings | Where-Object { [string]$_.gateId -eq $gateId })
        $status = 'passed'
        $exception = '—'

        if ($gateFindings.Count -gt 0) {
            $demotedRefs = @(
                $gateFindings |
                    Where-Object { $_.demoted -and -not [string]::IsNullOrWhiteSpace([string]$_.dispositionRef) } |
                    ForEach-Object { [string]$_.dispositionRef } |
                    Select-Object -Unique
            )

            if ($gateFindings.Count -eq $demotedRefs.Count -and $demotedRefs.Count -gt 0) {
                $status = 'excepted'
                $exception = $demotedRefs -join ', '
            }
            else {
                $status = 'failed'
            }
        }

        $overrides[$gateId] = [pscustomobject]@{
            Requirement   = (Get-DefaultRequirementRefsForGate -GateId $gateId) -join ', '
            EvidenceSource = $FindingsRef
            Status        = $status
            Exception     = $exception
        }
    }

    return $overrides
}

function Get-QualityEvidenceContent {
    param(
        [AllowEmptyString()]
        [AllowEmptyCollection()]
        [Parameter(Mandatory = $true)]
        [string[]]$PlanLines,
        [Parameter(Mandatory = $true)]
        [string]$FeatureId,
        [Parameter(Mandatory = $true)]
        [string]$IterationNumber,
        [Parameter(Mandatory = $true)]
        [string]$FindingsRef,
        [Parameter(Mandatory = $true)]
        [string]$EvidenceRef,
        [Parameter(Mandatory = $true)]
        [hashtable]$ExistingRows,
        [Parameter(Mandatory = $true)]
        [hashtable]$Overrides,
        [Parameter(Mandatory = $true)]
        [string]$ReviewedBy,
        [Parameter(Mandatory = $true)]
        [string]$ReviewedAt
    )

    $profileRef = Normalize-MarkdownCell (Get-MarkdownMetadataValue -Lines $PlanLines -Label 'Inferred Quality Profile')
    if ([string]::IsNullOrWhiteSpace($profileRef)) {
        $profileRef = 'quality-profile.pending'
    }

    $presetRefs = Normalize-MarkdownCell (Get-MarkdownMetadataValue -Lines $PlanLines -Label 'Selected preset ref or explicit custom composition')
    if ([string]::IsNullOrWhiteSpace($presetRefs)) {
        $presetRefs = '(pending preset selection)'
    }

    $gateRows = @(Get-MarkdownSectionTable -Lines $PlanLines -Heading 'Required Quality Gates')
    if ($gateRows.Count -eq 0) {
        $gateRows = @(Get-DefaultQualityGateRows)
    }
    $lines = [System.Collections.Generic.List[string]]::new()
    $null = $lines.Add("# Quality Evidence: Iteration $IterationNumber")
    $null = $lines.Add('')
    $null = $lines.Add(('**Profile Ref**: `' + $profileRef + '`'))
    $null = $lines.Add(('**Preset Refs**: ' + $presetRefs))
    $null = $lines.Add(('**Findings Ref**: `' + $FindingsRef + '`'))
    $null = $lines.Add(('**Reviewed By**: ' + $ReviewedBy))
    $null = $lines.Add(('**Reviewed At**: ' + $ReviewedAt))
    $null = $lines.Add('')
    $null = $lines.Add('## Gate Matrix')
    $null = $lines.Add('')
    $null = $lines.Add('| Gate | Requirement | Evidence Source | Status | Exception |')
    $null = $lines.Add('| --- | --- | --- | --- | --- |')

    foreach ($gateRow in $gateRows) {
        $gateId = Normalize-MarkdownCell ([string]$gateRow.'Required Quality Gate')
        if ([string]::IsNullOrWhiteSpace($gateId)) {
            continue
        }

        $requirement = (Get-DefaultRequirementRefsForGate -GateId $gateId) -join ', '
        $evidenceSource = Resolve-QualityEvidenceSource `
            -Value ([string]$gateRow.'Evidence Source') `
            -FeatureId $FeatureId `
            -IterationNumber $IterationNumber `
            -FindingsRef $FindingsRef `
            -EvidenceRef $EvidenceRef
        $status = 'planned'
        $exception = '—'

        if ($ExistingRows.ContainsKey($gateId)) {
            $existingRow = $ExistingRows[$gateId]
            if (-not [string]::IsNullOrWhiteSpace($existingRow.Requirement)) {
                $requirement = $existingRow.Requirement
            }
            if (-not [string]::IsNullOrWhiteSpace($existingRow.EvidenceSource)) {
                $evidenceSource = $existingRow.EvidenceSource
            }
            if (-not [string]::IsNullOrWhiteSpace($existingRow.Status)) {
                $status = $existingRow.Status
            }
            if (-not [string]::IsNullOrWhiteSpace($existingRow.Exception)) {
                $exception = $existingRow.Exception
            }
        }

        if ($Overrides.ContainsKey($gateId)) {
            $override = $Overrides[$gateId]
            if ($override.Requirement) {
                $requirement = $override.Requirement
            }
            if ($override.EvidenceSource) {
                $evidenceSource = $override.EvidenceSource
            }
            if ($override.Status) {
                $status = $override.Status
            }
            if ($override.Exception) {
                $exception = $override.Exception
            }
        }

        $null = $lines.Add(('| `{0}` | {1} | `{2}` | `{3}` | `{4}` |' -f $gateId, $requirement, $evidenceSource, $status, $exception))
    }

    return ($lines -join [Environment]::NewLine) + [Environment]::NewLine
}

function Get-ExtensionVersion {
    $extensionPath = Join-Path $PSScriptRoot '..\extension.yml'
    $extensionPath = [System.IO.Path]::GetFullPath($extensionPath)
    if (-not (Test-Path -LiteralPath $extensionPath -PathType Leaf)) {
        return '0.0.0'
    }

    foreach ($line in Get-Content -LiteralPath $extensionPath -Encoding UTF8) {
        if ($line -match '^\s+version:\s*"?(?<version>[^"#]+?)"?\s*$') {
            return $Matches.version.Trim()
        }
    }

    return '0.0.0'
}

function Get-DependencyNames {
    param(
        [Parameter(Mandatory = $true)]
        [string]$PackageJsonPath
    )

    if (-not (Test-Path -LiteralPath $PackageJsonPath -PathType Leaf)) {
        return @()
    }

    try {
        $packageJson = Get-Content -LiteralPath $PackageJsonPath -Raw -Encoding UTF8 | ConvertFrom-Json -AsHashtable
    }
    catch {
        return @()
    }

    $dependencies = [System.Collections.Generic.List[string]]::new()
    foreach ($propertyName in @('dependencies', 'devDependencies', 'peerDependencies', 'optionalDependencies')) {
        if (-not $packageJson.ContainsKey($propertyName)) {
            continue
        }

        $propertyValue = $packageJson[$propertyName]
        if ($propertyValue -isnot [System.Collections.IDictionary]) {
            continue
        }

        foreach ($dependencyName in $propertyValue.Keys) {
            $dependency = [string]$dependencyName
            if (-not [string]::IsNullOrWhiteSpace($dependency) -and -not $dependencies.Contains($dependency.ToLowerInvariant())) {
                $null = $dependencies.Add($dependency.ToLowerInvariant())
            }
        }
    }

    return $dependencies.ToArray()
}

function Resolve-MechanicalContext {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectRoot,
        [string]$FeaturePath,
        [string]$IterationPath,
        [string]$SpecPath
    )

    $resolvedFeaturePath = $null
    if (-not [string]::IsNullOrWhiteSpace($FeaturePath)) {
        $resolvedFeaturePath = Resolve-ProjectPath -Path $FeaturePath
    }
    elseif (-not [string]::IsNullOrWhiteSpace($SpecPath)) {
        $resolvedFeaturePath = Split-Path -Parent (Resolve-ProjectPath -Path $SpecPath)
    }

    $resolvedIterationPath = $null
    if (-not [string]::IsNullOrWhiteSpace($IterationPath)) {
        $resolvedIterationPath = Resolve-ProjectPath -Path $IterationPath
        if ([string]::IsNullOrWhiteSpace($resolvedFeaturePath)) {
            $resolvedFeaturePath = Split-Path -Parent (Split-Path -Parent $resolvedIterationPath)
        }
    }

    if ([string]::IsNullOrWhiteSpace($resolvedFeaturePath)) {
        $specsRoot = Join-Path $ProjectRoot 'specs'
        if (Test-Path -LiteralPath $specsRoot -PathType Container) {
            $featureCandidates = @(Get-ChildItem -LiteralPath $specsRoot -Directory | Where-Object {
                    Test-Path -LiteralPath (Join-Path $_.FullName 'spec.md') -PathType Leaf
                } | Sort-Object Name)

            if ($featureCandidates.Count -eq 1) {
                $resolvedFeaturePath = $featureCandidates[0].FullName
            }
            elseif ($featureCandidates.Count -gt 1) {
                $iterationCandidates = foreach ($featureCandidate in $featureCandidates) {
                    $iterationsRoot = Join-Path $featureCandidate.FullName 'iterations'
                    if (-not (Test-Path -LiteralPath $iterationsRoot -PathType Container)) {
                        continue
                    }

                    foreach ($directory in Get-ChildItem -LiteralPath $iterationsRoot -Directory | Sort-Object Name) {
                        $numericValue = 0
                        if ([int]::TryParse($directory.Name, [ref]$numericValue)) {
                            [pscustomobject]@{
                                FeaturePath = $featureCandidate.FullName
                                IterationPath = $directory.FullName
                                IterationNumber = $numericValue
                            }
                        }
                    }
                }

                $selectedCandidate = @($iterationCandidates | Sort-Object IterationNumber -Descending | Select-Object -First 1)[0]
                if ($null -ne $selectedCandidate) {
                    $resolvedFeaturePath = $selectedCandidate.FeaturePath
                    if ([string]::IsNullOrWhiteSpace($resolvedIterationPath)) {
                        $resolvedIterationPath = $selectedCandidate.IterationPath
                    }
                }
            }
        }
    }

    if ([string]::IsNullOrWhiteSpace($resolvedFeaturePath)) {
        throw 'Unable to resolve a feature path for mechanical checks. Provide -FeaturePath, -SpecPath, or -IterationPath.'
    }

    if ([string]::IsNullOrWhiteSpace($resolvedIterationPath)) {
        $iterationsRoot = Join-Path $resolvedFeaturePath 'iterations'
        if (Test-Path -LiteralPath $iterationsRoot -PathType Container) {
            $iterationDirectories = foreach ($directory in Get-ChildItem -LiteralPath $iterationsRoot -Directory | Sort-Object Name) {
                $numericValue = 0
                if ([int]::TryParse($directory.Name, [ref]$numericValue)) {
                    [pscustomobject]@{
                        FullName = $directory.FullName
                        IterationNumber = $numericValue
                    }
                }
            }

            $resolvedIterationPath = @($iterationDirectories | Sort-Object IterationNumber -Descending | Select-Object -First 1 | ForEach-Object { $_.FullName })[0]
        }
    }

    if ([string]::IsNullOrWhiteSpace($resolvedIterationPath)) {
        throw "Unable to resolve an iteration path under '$resolvedFeaturePath'."
    }

    $resolvedSpecPath = if (-not [string]::IsNullOrWhiteSpace($SpecPath)) {
        Resolve-ProjectPath -Path $SpecPath
    }
    else {
        Join-Path $resolvedFeaturePath 'spec.md'
    }

    $schemaPath = Join-Path $resolvedFeaturePath 'contracts\mechanical-findings.schema.json'
    if (-not (Test-Path -LiteralPath $schemaPath -PathType Leaf)) {
        throw "Mechanical findings schema not found at '$schemaPath'."
    }

    $packageJsonPath = Join-Path $ProjectRoot 'package.json'
    $dependencies = @(Get-DependencyNames -PackageJsonPath $packageJsonPath)
    $surfaceId = 'project-default-surface'
    if (($dependencies -contains 'ws' -or $dependencies -contains 'socket.io') -and ($dependencies -contains 'express' -or $dependencies -contains 'fastify')) {
        $surfaceId = 'node-public-ws-service'
    }
    elseif (($dependencies -contains 'express' -or $dependencies -contains '@nestjs/core') -and $dependencies -contains 'pg') {
        $surfaceId = 'node-rest-with-postgres'
    }
    elseif ($dependencies -contains 'react') {
        $surfaceId = 'react-spa-public'
    }

    return [pscustomobject]@{
        ProjectRoot = $ProjectRoot
        FeaturePath = $resolvedFeaturePath
        IterationPath = $resolvedIterationPath
        SpecPath = $resolvedSpecPath
        SchemaPath = $schemaPath
        FeatureRef = Convert-ToRepoRelativePath -BasePath $ProjectRoot -TargetPath $resolvedSpecPath
        IterationRef = Convert-ToRepoRelativePath -BasePath $ProjectRoot -TargetPath $resolvedIterationPath
        SurfaceId = $surfaceId
    }
}

function Get-CandidateCodeFiles {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectRoot
    )

    $allowedExtensions = @('.ts', '.tsx', '.js', '.jsx', '.mjs', '.cjs', '.ps1', '.py', '.cs', '.go', '.java', '.kt')
    $excludedPattern = '(^|[\\/])(\.git|\.specify|\.squad|\.scratch|node_modules|dist|build|coverage|docs|evaluation|specs)([\\/]|$)'
    $preferredRoots = @('src', 'server', 'app', 'lib', 'client', 'tests', 'test')
    $searchRoots = [System.Collections.Generic.List[string]]::new()

    foreach ($preferredRoot in $preferredRoots) {
        $candidatePath = Join-Path $ProjectRoot $preferredRoot
        if (Test-Path -LiteralPath $candidatePath -PathType Container) {
            $null = $searchRoots.Add($candidatePath)
        }
    }

    if ($searchRoots.Count -eq 0) {
        $null = $searchRoots.Add($ProjectRoot)
    }

    $results = [System.Collections.Generic.List[System.IO.FileInfo]]::new()
    foreach ($searchRoot in $searchRoots) {
        foreach ($file in Get-ChildItem -LiteralPath $searchRoot -Recurse -File) {
            if (($allowedExtensions -contains $file.Extension.ToLowerInvariant()) -and ($file.FullName -notmatch $excludedPattern)) {
                $null = $results.Add($file)
            }
        }
    }

    return $results.ToArray()
}

function Get-CandidateTestFiles {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectRoot
    )

    $testPattern = '(^|[\\/])(test|tests|__tests__)([\\/]|$)|\.(spec|test)\.[^.]+$'
    return @(Get-CandidateCodeFiles -ProjectRoot $ProjectRoot | Where-Object { $_.FullName -match $testPattern })
}

function Read-TextLines {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    return @(Get-Content -LiteralPath $Path -Encoding UTF8)
}

function Get-RuleDispositions {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectRoot,

        [Parameter(Mandatory = $true)]
        [string]$IterationPath,

        [string]$DispositionPath
    )

    $dispositions = @{}
    $candidatePaths = [System.Collections.Generic.List[string]]::new()

    if (-not [string]::IsNullOrWhiteSpace($DispositionPath)) {
        $null = $candidatePaths.Add((Resolve-ProjectPath -Path $DispositionPath))
    }

    $dispositionDirectory = Join-Path $IterationPath 'quality\dispositions'
    if (Test-Path -LiteralPath $dispositionDirectory -PathType Container) {
        foreach ($file in Get-ChildItem -LiteralPath $dispositionDirectory -File) {
            $null = $candidatePaths.Add($file.FullName)
        }
    }

    foreach ($candidatePath in $candidatePaths) {
        if (-not (Test-Path -LiteralPath $candidatePath -PathType Leaf)) {
            continue
        }

        if ($candidatePath -match '\.json$') {
            try {
                $payload = Get-Content -LiteralPath $candidatePath -Raw -Encoding UTF8 | ConvertFrom-Json -Depth 32
            }
            catch {
                continue
            }

            $hasRulesProperty = $false
            if ($payload -isnot [System.Collections.IEnumerable] -or $payload -is [string]) {
                $hasRulesProperty = ($null -ne ($payload.PSObject.Properties['rules']))
            }

            $records = if ($payload -is [System.Collections.IEnumerable] -and $payload -isnot [string]) {
                @($payload)
            }
            elseif ($hasRulesProperty -and $null -ne $payload.rules) {
                @($payload.rules)
            }
            else {
                @($payload)
            }

            foreach ($record in $records) {
                $ruleId = [string]$record.ruleId
                if ([string]::IsNullOrWhiteSpace($ruleId)) {
                    continue
                }

                $severity = [string]$record.severity
                $dispositionRef = [string]$record.dispositionRef
                if ([string]::IsNullOrWhiteSpace($dispositionRef)) {
                    $dispositionRef = Convert-ToRepoRelativePath -BasePath $ProjectRoot -TargetPath $candidatePath
                }

                $dispositions[$ruleId.ToLowerInvariant()] = [pscustomobject]@{
                    ruleId = $ruleId
                    severity = $severity
                    dispositionRef = $dispositionRef
                }
            }

            continue
        }

        $content = Get-Content -LiteralPath $candidatePath -Raw -Encoding UTF8
        $ruleId = $null
        $severity = $null

        foreach ($pattern in @(
                '(?im)^\s*rule[_-]?id\s*:\s*["'']?(?<value>[^"'']+)["'']?\s*$',
                '(?im)^\s*\*\*Rule ID\*\*\s*:\s*`?(?<value>[^`\r\n]+)`?\s*$'
            )) {
            $match = [regex]::Match($content, $pattern)
            if ($match.Success) {
                $ruleId = $match.Groups['value'].Value.Trim()
                break
            }
        }

        foreach ($pattern in @(
                '(?im)^\s*new[_-]?behavior\s*:\s*["'']?(?<value>[^"'']+)["'']?\s*$',
                '(?im)^\s*\*\*New Behavior\*\*\s*:\s*`?(?<value>[^`\r\n]+)`?\s*$'
            )) {
            $match = [regex]::Match($content, $pattern)
            if ($match.Success) {
                $severity = switch -Regex ($match.Groups['value'].Value.Trim().ToLowerInvariant()) {
                    'advisory|warning' { 'warning' }
                    'info|informational' { 'info' }
                    default { '' }
                }
                break
            }
        }

        if (-not [string]::IsNullOrWhiteSpace($ruleId)) {
            $dispositions[$ruleId.ToLowerInvariant()] = [pscustomobject]@{
                ruleId = $ruleId
                severity = $severity
                dispositionRef = Convert-ToRepoRelativePath -BasePath $ProjectRoot -TargetPath $candidatePath
            }
        }
    }

    return $dispositions
}

function New-MechanicalFinding {
    param(
        [Parameter(Mandatory = $true)]
        [string]$GateId,

        [Parameter(Mandatory = $true)]
        [string]$RuleId,

        [Parameter(Mandatory = $true)]
        [string]$SurfaceId,

        [Parameter(Mandatory = $true)]
        [string]$Severity,

        [Parameter(Mandatory = $true)]
        [string]$Message,

        [Parameter(Mandatory = $true)]
        [string]$Remediation,

        [Parameter(Mandatory = $true)]
        [string]$SourcePath,

        [Parameter(Mandatory = $true)]
        [int]$SourceLine,

        [int]$SourceColumn,

        [Parameter(Mandatory = $true)]
        [string[]]$RequirementRefs,

        [Parameter(Mandatory = $true)]
        [hashtable]$RuleDispositions
    )

    $effectiveRequirementRefs = [System.Collections.Generic.List[string]]::new()
    foreach ($requirementRef in $RequirementRefs) {
        if (-not [string]::IsNullOrWhiteSpace($requirementRef) -and -not $effectiveRequirementRefs.Contains($requirementRef)) {
            $null = $effectiveRequirementRefs.Add($requirementRef)
        }
    }

    $effectiveSeverity = $Severity
    $demoted = $false
    $dispositionRef = $null
    $disposition = $RuleDispositions[$RuleId.ToLowerInvariant()]
    if ($null -ne $disposition) {
        $demoted = $true
        $dispositionRef = [string]$disposition.dispositionRef
        if (-not [string]::IsNullOrWhiteSpace([string]$disposition.severity)) {
            $effectiveSeverity = [string]$disposition.severity
        }
        elseif ($effectiveSeverity -eq 'error') {
            $effectiveSeverity = 'warning'
        }

        if (-not $effectiveRequirementRefs.Contains('FR-030a')) {
            $null = $effectiveRequirementRefs.Add('FR-030a')
        }
    }

    $source = [ordered]@{
        path = $SourcePath
        line = $SourceLine
    }

    if ($PSBoundParameters.ContainsKey('SourceColumn') -and $SourceColumn -gt 0) {
        $source.column = $SourceColumn
    }

    $finding = [ordered]@{
        gateId = $GateId
        ruleId = $RuleId
        surfaceId = $SurfaceId
        severity = $effectiveSeverity
        message = $Message
        remediation = $Remediation
        source = [pscustomobject]$source
        requirementRefs = $effectiveRequirementRefs.ToArray()
        demoted = $demoted
    }

    if ($demoted) {
        $finding.dispositionRef = $dispositionRef
    }

    return [pscustomobject]$finding
}

function Get-DeadFieldFindings {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectRoot,

        [Parameter(Mandatory = $true)]
        [System.IO.FileInfo[]]$SourceFiles,

        [Parameter(Mandatory = $true)]
        [string]$SurfaceId,

        [Parameter(Mandatory = $true)]
        [hashtable]$RuleDispositions
    )

    $findings = [System.Collections.Generic.List[object]]::new()
    $seen = New-Object System.Collections.Generic.HashSet[string] ([System.StringComparer]::OrdinalIgnoreCase)

    foreach ($file in $SourceFiles) {
        $relativePath = Convert-ToRepoRelativePath -BasePath $ProjectRoot -TargetPath $file.FullName
        if ($relativePath -notmatch '(payload|message|dto|context|subscription|socket|websocket)') {
            continue
        }

        $content = Get-Content -LiteralPath $file.FullName -Raw -Encoding UTF8
        $lines = @(Read-TextLines -Path $file.FullName)
        if ([string]::IsNullOrWhiteSpace($content) -or $lines.Count -eq 0) {
            continue
        }

        for ($index = 0; $index -lt $lines.Count; $index++) {
            $line = $lines[$index]
            $match = [regex]::Match($line, '^\s*(?:readonly\s+)?(?<name>[A-Za-z_][A-Za-z0-9_]*)\??\s*:\s*[^=][^;]*[;,]?\s*(?://.*)?$')
            if (-not $match.Success) {
                continue
            }

            $fieldName = $match.Groups['name'].Value
            if ([string]::IsNullOrWhiteSpace($fieldName)) {
                continue
            }

            $occurrenceCount = ([regex]::Matches($content, ('(?<![A-Za-z0-9_]){0}(?![A-Za-z0-9_])' -f [regex]::Escape($fieldName)))).Count
            if ($occurrenceCount -gt 1) {
                continue
            }

            $findingKey = '{0}|{1}|{2}' -f $relativePath, $fieldName, 'dead-field.websocket-payload-unused'
            if (-not $seen.Add($findingKey)) {
                continue
            }

            $column = [int]$match.Groups['name'].Index + 1
            $null = $findings.Add((New-MechanicalFinding `
                        -GateId 'dead-field' `
                        -RuleId 'dead-field.websocket-payload-unused' `
                        -SurfaceId $SurfaceId `
                        -Severity 'error' `
                        -Message ("Websocket payload field '{0}' is declared but never read." -f $fieldName) `
                        -Remediation "Remove the dead payload field or document a reviewed rationale before it drifts further." `
                        -SourcePath $relativePath `
                        -SourceLine ($index + 1) `
                        -SourceColumn $column `
                        -RequirementRefs @('FR-027', 'FR-030') `
                        -RuleDispositions $RuleDispositions))
        }
    }

    return $findings.ToArray()
}

function Get-AntiPatternFindings {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectRoot,

        [Parameter(Mandatory = $true)]
        [System.IO.FileInfo[]]$SourceFiles,

        [Parameter(Mandatory = $true)]
        [string]$SurfaceId,

        [Parameter(Mandatory = $true)]
        [hashtable]$RuleDispositions
    )

    $findings = [System.Collections.Generic.List[object]]::new()
    $seen = New-Object System.Collections.Generic.HashSet[string] ([System.StringComparer]::OrdinalIgnoreCase)

    foreach ($file in $SourceFiles) {
        $relativePath = Convert-ToRepoRelativePath -BasePath $ProjectRoot -TargetPath $file.FullName
        if ($relativePath -notmatch '(broadcast|handler|socket|websocket|message)') {
            continue
        }

        $lines = @(Read-TextLines -Path $file.FullName)
        for ($index = 0; $index -lt $lines.Count; $index++) {
            $line = $lines[$index]
            $match = [regex]::Match($line, '^(?!\s*(?:await|return)\b)\s*(?:void\s+)?(?<call>[A-Za-z_][A-Za-z0-9_\.]*)\s*\(')
            if (-not $match.Success) {
                continue
            }

            if ($match.Groups['call'].Value -notmatch 'broadcast') {
                continue
            }

            $findingKey = '{0}|{1}|{2}' -f $relativePath, ($index + 1), 'anti-pattern.fire-and-forget-broadcast'
            if (-not $seen.Add($findingKey)) {
                continue
            }

            $column = [int]$match.Groups['call'].Index + 1
            $null = $findings.Add((New-MechanicalFinding `
                        -GateId 'anti-pattern' `
                        -RuleId 'anti-pattern.fire-and-forget-broadcast' `
                        -SurfaceId $SurfaceId `
                        -Severity 'error' `
                        -Message 'Broadcast handler starts fire-and-forget work that can hide failures from the caller.' `
                        -Remediation 'Await the broadcast path or capture failures explicitly so the handler keeps observable failure semantics.' `
                        -SourcePath $relativePath `
                        -SourceLine ($index + 1) `
                        -SourceColumn $column `
                        -RequirementRefs @('FR-028', 'FR-030') `
                        -RuleDispositions $RuleDispositions))
        }
    }

    return $findings.ToArray()
}

function Get-TestIntegrityFindings {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectRoot,

        [Parameter(Mandatory = $true)]
        [System.IO.FileInfo[]]$TestFiles,

        [Parameter(Mandatory = $true)]
        [string]$SurfaceId,

        [Parameter(Mandatory = $true)]
        [hashtable]$RuleDispositions
    )

    $findings = [System.Collections.Generic.List[object]]::new()
    $seen = New-Object System.Collections.Generic.HashSet[string] ([System.StringComparer]::OrdinalIgnoreCase)

    foreach ($file in $TestFiles) {
        $relativePath = Convert-ToRepoRelativePath -BasePath $ProjectRoot -TargetPath $file.FullName
        $content = Get-Content -LiteralPath $file.FullName -Raw -Encoding UTF8
        if ($relativePath -notmatch '(handshake|socket|websocket)' -and $content -notmatch '(handshake|socket|websocket)') {
            continue
        }

        $lines = @(Read-TextLines -Path $file.FullName)
        $hasNegativePathCoverage = $content -match '(reject|unauthori[sz]ed|denied|disconnect|cleanup|close|teardown|forbidden)'

        for ($index = 0; $index -lt $lines.Count; $index++) {
            $line = $lines[$index]
            $match = [regex]::Match($line, 'expect\s*\(.+?\)\s*\.\s*(?<assertion>toBeTruthy|toBeDefined|toBe\s*\(\s*true\s*\)|toEqual\s*\(\s*true\s*\))\s*\(')
            if (-not $match.Success) {
                continue
            }

            if ($hasNegativePathCoverage) {
                continue
            }

            $findingKey = '{0}|{1}|{2}' -f $relativePath, ($index + 1), 'test-integrity.smoke-only-handshake'
            if (-not $seen.Add($findingKey)) {
                continue
            }

            $column = [int]$match.Index + 1
            $null = $findings.Add((New-MechanicalFinding `
                        -GateId 'test-integrity' `
                        -RuleId 'test-integrity.smoke-only-handshake' `
                        -SurfaceId $SurfaceId `
                        -Severity 'warning' `
                        -Message 'Handshake test opens a socket but does not assert the rejected-auth path or disconnect cleanup.' `
                        -Remediation 'Add positive and negative assertions so the websocket suite proves meaningful lifecycle behavior.' `
                        -SourcePath $relativePath `
                        -SourceLine ($index + 1) `
                        -SourceColumn $column `
                        -RequirementRefs @('FR-029', 'FR-030') `
                        -RuleDispositions $RuleDispositions))
        }
    }

    return $findings.ToArray()
}

function Convert-ToValidatedPayload {
    param(
        [Parameter(Mandatory = $true)]
        [pscustomobject]$Context,

        [Parameter(Mandatory = $true)]
        [string]$GeneratorVersion,

        [AllowEmptyCollection()]
        [Parameter(Mandatory = $true)]
        [object[]]$Findings
    )

    $gateOrder = @{
        'dead-field' = 1
        'anti-pattern' = 2
        'test-integrity' = 3
    }

    $sortedFindings = @($Findings | Sort-Object `
            @{ Expression = { $gateOrder[[string]$_.gateId] } }, `
            @{ Expression = { [string]$_.source.path } }, `
            @{ Expression = { [int]$_.source.line } }, `
            @{ Expression = { [string]$_.ruleId } })

    $materializedFindings = [System.Collections.Generic.List[object]]::new()
    for ($index = 0; $index -lt $sortedFindings.Count; $index++) {
        $finding = $sortedFindings[$index]
        $source = [ordered]@{
            path = [string]$finding.source.path
            line = [int]$finding.source.line
        }

        if ($null -ne $finding.source.column) {
            $source.column = [int]$finding.source.column
        }

        $serializedFinding = [ordered]@{
            findingId = ('mf-{0:D3}' -f ($index + 1))
            gateId = [string]$finding.gateId
            ruleId = [string]$finding.ruleId
            surfaceId = [string]$finding.surfaceId
            severity = [string]$finding.severity
            message = [string]$finding.message
            remediation = [string]$finding.remediation
            source = [pscustomobject]$source
            requirementRefs = @([string[]]$finding.requirementRefs)
            demoted = [bool]$finding.demoted
        }

        if ($finding.demoted) {
            $serializedFinding.dispositionRef = [string]$finding.dispositionRef
        }

        $null = $materializedFindings.Add([pscustomobject]$serializedFinding)
    }

    $payload = [pscustomobject][ordered]@{
        schemaVersion = 'v1'
        featureRef = [string]$Context.FeatureRef
        iterationRef = [string]$Context.IterationRef
        generatedAt = (Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ')
        generator = [pscustomobject][ordered]@{
            name = 'specrew-mechanical-checks'
            version = $GeneratorVersion
        }
        findings = $materializedFindings.ToArray()
    }

    $json = $payload | ConvertTo-Json -Depth 16
    if (-not (Test-Json -Json $json -SchemaFile $Context.SchemaPath -WarningAction SilentlyContinue)) {
        throw 'Generated mechanical findings payload does not satisfy the v1 schema.'
    }

    return $payload
}

$resolvedProjectPath = Resolve-ProjectPath -Path $ProjectPath
if (-not (Test-Path -LiteralPath $resolvedProjectPath -PathType Container)) {
    throw "Project path '$resolvedProjectPath' does not exist."
}

$context = Resolve-MechanicalContext -ProjectRoot $resolvedProjectPath -FeaturePath $FeaturePath -IterationPath $IterationPath -SpecPath $SpecPath
$generatorVersion = Get-ExtensionVersion
$sourceFiles = @(Get-CandidateCodeFiles -ProjectRoot $resolvedProjectPath)
$testFiles = @(Get-CandidateTestFiles -ProjectRoot $resolvedProjectPath)
$ruleDispositions = Get-RuleDispositions -ProjectRoot $resolvedProjectPath -IterationPath $context.IterationPath -DispositionPath $DispositionPath

$findings = [System.Collections.Generic.List[object]]::new()
foreach ($finding in @(Get-DeadFieldFindings -ProjectRoot $resolvedProjectPath -SourceFiles $sourceFiles -SurfaceId $context.SurfaceId -RuleDispositions $ruleDispositions)) {
    $null = $findings.Add($finding)
}
foreach ($finding in @(Get-AntiPatternFindings -ProjectRoot $resolvedProjectPath -SourceFiles $sourceFiles -SurfaceId $context.SurfaceId -RuleDispositions $ruleDispositions)) {
    $null = $findings.Add($finding)
}
foreach ($finding in @(Get-TestIntegrityFindings -ProjectRoot $resolvedProjectPath -TestFiles $testFiles -SurfaceId $context.SurfaceId -RuleDispositions $ruleDispositions)) {
    $null = $findings.Add($finding)
}

$payload = Convert-ToValidatedPayload -Context $context -GeneratorVersion $generatorVersion -Findings $findings.ToArray()
$planPath = Join-Path $context.IterationPath 'plan.md'
$planLines = if (Test-Path -LiteralPath $planPath -PathType Leaf) {
    @(Get-Content -LiteralPath $planPath -Encoding UTF8)
}
else {
    @()
}

$qualityDirectory = Join-Path $context.IterationPath 'quality'
$mechanicalFindingsPath = Join-Path $qualityDirectory 'mechanical-findings.json'
$qualityEvidencePath = Join-Path $qualityDirectory 'quality-evidence.md'

if (-not (Test-Path -LiteralPath $qualityDirectory -PathType Container)) {
    $null = New-Item -ItemType Directory -Path $qualityDirectory -Force
}

$mechanicalFindingsJson = $payload | ConvertTo-Json -Depth 16
[System.IO.File]::WriteAllText($mechanicalFindingsPath, $mechanicalFindingsJson, [System.Text.UTF8Encoding]::new($false))

$qualityGateRows = @(Get-MarkdownSectionTable -Lines $planLines -Heading 'Required Quality Gates')
$qualityContractPath = Join-Path $context.FeaturePath 'contracts\quality-governance-artifacts.md'
if ($qualityGateRows.Count -eq 0 -and (Test-Path -LiteralPath $qualityContractPath -PathType Leaf)) {
    $qualityGateRows = @(Get-DefaultQualityGateRows)
}
if ($qualityGateRows.Count -gt 0) {
    $featureId = Split-Path -Leaf $context.FeaturePath
    $iterationNumber = Split-Path -Leaf $context.IterationPath
    $findingsRef = Convert-ToRepoRelativePath -BasePath $resolvedProjectPath -TargetPath $mechanicalFindingsPath
    $evidenceRef = Convert-ToRepoRelativePath -BasePath $resolvedProjectPath -TargetPath $qualityEvidencePath
    $existingEvidenceState = Get-ExistingQualityEvidenceState -QualityEvidencePath $qualityEvidencePath
    $qualityEvidenceOverrides = Get-MechanicalGateOverrides -Findings $payload.findings -FindingsRef $findingsRef
    $reviewedBy = if ([string]::IsNullOrWhiteSpace($existingEvidenceState.ReviewedBy)) { 'Mechanical checks (automated)' } else { $existingEvidenceState.ReviewedBy }
    $reviewedAt = if ([string]::IsNullOrWhiteSpace($existingEvidenceState.ReviewedAt)) { (Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ') } else { $existingEvidenceState.ReviewedAt }
    $qualityEvidenceContent = Get-QualityEvidenceContent `
        -PlanLines $planLines `
        -FeatureId $featureId `
        -IterationNumber $iterationNumber `
        -FindingsRef $findingsRef `
        -EvidenceRef $evidenceRef `
        -ExistingRows $existingEvidenceState.RowsByGate `
        -Overrides $qualityEvidenceOverrides `
        -ReviewedBy $reviewedBy `
        -ReviewedAt $reviewedAt
    [System.IO.File]::WriteAllText($qualityEvidencePath, $qualityEvidenceContent, [System.Text.UTF8Encoding]::new($false))
}

switch ($OutputFormat) {
    'Json' {
        $mechanicalFindingsJson
    }
    default {
        $payload
    }
}
