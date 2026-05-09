[CmdletBinding()]
param(
    [string]$ProjectPath = (Get-Location).Path,
    [string]$FeaturePath,
    [string]$SpecPath,
    [ValidateSet('Object', 'Json', 'Markdown')]
    [string]$OutputFormat = 'Object'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Test-AnyPattern {
    param(
        [AllowEmptyString()]
        [string]$Text,

        [string[]]$Patterns
    )

    if ([string]::IsNullOrWhiteSpace($Text)) {
        return $false
    }

    foreach ($pattern in $Patterns) {
        if ($Text -match $pattern) {
            return $true
        }
    }

    return $false
}

function Add-UniqueItem {
    param(
        [System.Collections.Generic.List[string]]$List,
        [AllowEmptyString()]
        [string]$Value
    )

    if ([string]::IsNullOrWhiteSpace($Value)) {
        return
    }

    if (-not $List.Contains($Value)) {
        $null = $List.Add($Value)
    }
}

function Add-UniqueItems {
    param(
        [System.Collections.Generic.List[string]]$List,
        [string[]]$Values
    )

    foreach ($value in $Values) {
        Add-UniqueItem -List $List -Value $value
    }
}

function Get-DependencyNames {
    param([string]$PackageJsonPath)

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
        if ($propertyValue -is [System.Collections.IDictionary]) {
            foreach ($name in $propertyValue.Keys) {
                Add-UniqueItem -List $dependencies -Value ([string]$name).ToLowerInvariant()
            }
        }
    }

    return $dependencies.ToArray()
}

function Get-TextFileContent {
    param([string]$Path)

    if (-not [string]::IsNullOrWhiteSpace($Path) -and (Test-Path -LiteralPath $Path -PathType Leaf)) {
        return Get-Content -LiteralPath $Path -Raw -Encoding UTF8
    }

    return ''
}

function New-QualityGate {
    param(
        [string]$GateId,
        [string]$Category,
        [string[]]$RequirementRefs,
        [string]$EvidenceRef,
        [string]$Description
    )

    return [pscustomobject]@{
        gate_id          = $GateId
        category         = $Category
        requirement_refs = @($RequirementRefs)
        status           = 'planned'
        evidence_ref     = $EvidenceRef
        exception_ref    = $null
        description      = $Description
    }
}

function New-StackSurface {
    param(
        [string]$SurfaceId,
        [string[]]$PathGlobs,
        [string]$Language,
        [string]$RuntimeShape,
        [string]$RecognizedStack,
        [string[]]$MatchedSignals
    )

    return [pscustomobject]@{
        surface_id       = $SurfaceId
        path_globs       = @($PathGlobs)
        language         = $Language
        runtime_shape    = $RuntimeShape
        recognized_stack = $RecognizedStack
        matched_signals  = @($MatchedSignals)
    }
}

function New-RiskDimension {
    param(
        [string]$Id,
        [string]$Status,
        [string]$Rationale
    )

    return [pscustomobject]@{
        id        = $Id
        status    = $Status
        rationale = $Rationale
    }
}

function New-HardeningFocusArea {
    param(
        [string]$FocusArea,
        [string]$WhyItMatters,
        [string]$PlannedArtifactOrEvidence,
        [string]$Status
    )

    return [pscustomobject]@{
        focus_area                   = $FocusArea
        why_it_matters              = $WhyItMatters
        planned_artifact_or_evidence = $PlannedArtifactOrEvidence
        status                      = $Status
    }
}

function New-LensActivationPlanEntry {
    param(
        [string]$LensRef,
        [string]$Activation,
        [string]$Rationale,
        [string]$PlannedEvidencePath,
        [string]$RequestedReviewClass
    )

    return [pscustomobject]@{
        lens_ref               = $LensRef
        activation             = $Activation
        rationale              = $Rationale
        planned_evidence_path  = $PlannedEvidencePath
        requested_review_class = $RequestedReviewClass
    }
}

function New-RoutingPolicyEntry {
    param(
        [string]$LensScope,
        [string]$RequestedReviewClass,
        [string]$EffectiveClass,
        [string]$OverrideApprovalRecord,
        [string]$Notes
    )

    return [pscustomobject]@{
        lens_scope               = $LensScope
        requested_review_class   = $RequestedReviewClass
        effective_class          = $EffectiveClass
        override_approval_record = $OverrideApprovalRecord
        notes                    = $Notes
    }
}

function Get-BaselineRiskDimensions {
    return @(
        'code-quality',
        'design-quality-and-separation-of-concerns',
        'verification-confidence',
        'maintainability',
        'security',
        'robustness'
    )
}

function Get-DefaultLensRefs {
    return @(
        'security-baseline@v1.0.0',
        'robustness-baseline@v1.0.0',
        'test-integrity@v1.0.0'
    )
}

function Get-PhaseOneDeferrals {
    return @(
        'Pre-implementation hardening gate sign-off and blocking semantics remain deferred to Phase 2+.',
        'Dedicated bug-hunter lens execution and strongest-class routing remain deferred to Phase 2+.',
        'Quality-drift logic, mixed-stack override routing, and reference-implementation comparison remain deferred to Phase 2+.'
    )
}

function Convert-ToRepoMarkdownPath {
    param(
        [string]$ResolvedProjectPath,
        [string]$Path
    )

    if ([string]::IsNullOrWhiteSpace($Path)) {
        return $null
    }

    try {
        $relativePath = [System.IO.Path]::GetRelativePath($ResolvedProjectPath, $Path)
        return ($relativePath -replace '\\', '/')
    }
    catch {
        return ($Path -replace '\\', '/')
    }
}

function Get-QualityPlanningDefaults {
    param([string]$ResolvedProjectPath)

    $defaults = [ordered]@{
        known_traps_path          = '.specrew/quality/known-traps.md'
        routing_default_policy    = 'strongest-available'
        allow_lower_tier_override = $true
        approval_required         = $true
    }

    $configPath = Join-Path $ResolvedProjectPath '.specrew\config.yml'
    $configContent = Get-TextFileContent -Path $configPath
    if ([string]::IsNullOrWhiteSpace($configContent)) {
        return [pscustomobject]$defaults
    }

    $qualityBlockMatch = [regex]::Match($configContent, '(?ms)^\s*quality:\s*(?<body>(?:\r?\n\s+.+)+)')
    if (-not $qualityBlockMatch.Success) {
        return [pscustomobject]$defaults
    }

    $qualityBlock = $qualityBlockMatch.Groups['body'].Value
    $knownTrapsMatch = [regex]::Match($qualityBlock, '(?m)^\s*known_traps_path:\s*"?(?<value>[^"\r\n]+)"?\s*$')
    if ($knownTrapsMatch.Success) {
        $defaults.known_traps_path = ($knownTrapsMatch.Groups['value'].Value.Trim() -replace '\\', '/')
    }

    $routingBlockMatch = [regex]::Match($qualityBlock, '(?ms)^\s*routing:\s*(?<body>(?:\r?\n\s{4,}.+)+)')
    if ($routingBlockMatch.Success) {
        $routingBlock = $routingBlockMatch.Groups['body'].Value
        $defaultPolicyMatch = [regex]::Match($routingBlock, '(?m)^\s*default_policy:\s*"?(?<value>[^"\r\n]+)"?\s*$')
        if ($defaultPolicyMatch.Success) {
            $defaults.routing_default_policy = $defaultPolicyMatch.Groups['value'].Value.Trim()
        }

        $allowOverrideMatch = [regex]::Match($routingBlock, '(?m)^\s*allow_lower_tier_override:\s*(?<value>true|false)\s*$')
        if ($allowOverrideMatch.Success) {
            $defaults.allow_lower_tier_override = [System.Convert]::ToBoolean($allowOverrideMatch.Groups['value'].Value)
        }

        $approvalRequiredMatch = [regex]::Match($routingBlock, '(?m)^\s*approval_required:\s*(?<value>true|false)\s*$')
        if ($approvalRequiredMatch.Success) {
            $defaults.approval_required = [System.Convert]::ToBoolean($approvalRequiredMatch.Groups['value'].Value)
        }
    }

    return [pscustomobject]$defaults
}

function Get-PhaseTwoArtifactRefs {
    param(
        [string]$ResolvedProjectPath,
        [string]$ResolvedFeaturePath,
        [pscustomobject]$QualityDefaults
    )

    $featureRoot = if ([string]::IsNullOrWhiteSpace($ResolvedFeaturePath)) {
        'specs/<feature>'
    }
    else {
        Convert-ToRepoMarkdownPath -ResolvedProjectPath $ResolvedProjectPath -Path $ResolvedFeaturePath
    }

    $iterationQualityRoot = '{0}/iterations/<NNN>/quality' -f $featureRoot
    return [pscustomobject]@{
        hardening_gate_artifact      = '{0}/hardening-gate.md' -f $iterationQualityRoot
        known_traps_corpus_location  = [string]$QualityDefaults.known_traps_path
        trap_reapplication_artifact  = '{0}/trap-reapplication.md' -f $iterationQualityRoot
        lens_evidence_directory      = '{0}/lenses' -f $iterationQualityRoot
    }
}

function Get-PhaseTwoHardeningFocusAreas {
    param(
        [pscustomobject]$RiskResolution,
        [pscustomobject]$ArtifactRefs
    )

    $requiredDimensions = @($RiskResolution.required.id)
    $retryStatus = if ($requiredDimensions -contains 'retry-idempotency-and-recovery') { 'required' } else { 'not-applicable' }
    $retryRationale = if ($retryStatus -eq 'required') {
        'Retry, idempotency, or recovery behavior is materially relevant for this slice, so the hardening gate must capture the explicit guardrails before implementation starts.'
    }
    else {
        'The hardening gate still records why retry and idempotency do not materially apply in this slice so omissions stay reviewable before implementation begins.'
    }
    $qualityEvidencePath = '{0}/quality-evidence.md' -f (($ArtifactRefs.hardening_gate_artifact -replace '/hardening-gate\.md$', ''))

    return @(
        (New-HardeningFocusArea -FocusArea 'Security surface analysis' -WhyItMatters 'The hardening gate must capture planning-time security analysis, expected controls, and any explicit non-applicable reasoning before coding begins; runtime proof can remain pending only until later closure.' -PlannedArtifactOrEvidence $ArtifactRefs.hardening_gate_artifact -Status 'required'),
        (New-HardeningFocusArea -FocusArea 'Error handling and failure semantics' -WhyItMatters 'Silent failure paths, expected controls, and fallback expectations must be made explicit in the hardening gate so implementation does not invent them later or bypass runtime follow-through.' -PlannedArtifactOrEvidence $ArtifactRefs.hardening_gate_artifact -Status 'required'),
        (New-HardeningFocusArea -FocusArea 'Retry and idempotency expectations' -WhyItMatters $retryRationale -PlannedArtifactOrEvidence $ArtifactRefs.hardening_gate_artifact -Status $retryStatus),
        (New-HardeningFocusArea -FocusArea 'Test-integrity targets' -WhyItMatters 'The hardening gate must name the planned validation evidence and expected controls for this slice so implementation readiness does not rely on smoke-only success while runtime/test proof remains visibly pending until later closure.' -PlannedArtifactOrEvidence ('feature plan Phase 2 quality planning section plus {0}' -f $qualityEvidencePath) -Status 'required')
    )
}

function Get-LensIdFromRef {
    param([string]$LensRef)

    if ([string]::IsNullOrWhiteSpace($LensRef)) {
        return ''
    }

    return ($LensRef -split '@', 2)[0]
}

function Get-PhaseTwoLensActivationPlan {
    param(
        [pscustomobject]$Profile,
        [pscustomobject]$ArtifactRefs,
        [pscustomobject]$QualityDefaults
    )

    $lensRefs = [System.Collections.Generic.List[string]]::new()
    Add-UniqueItems -List $lensRefs -Values @($Profile.required_lens_refs)
    Add-UniqueItems -List $lensRefs -Values @($Profile.custom_lens_refs)

    $entries = [System.Collections.Generic.List[object]]::new()
    foreach ($lensRef in $lensRefs) {
        $lensId = Get-LensIdFromRef -LensRef $lensRef
        $evidencePath = '{0}/{1}.md' -f $ArtifactRefs.lens_evidence_directory, $lensId
        $activation = 'optional'
        $rationale = 'The lens remains available for later Phase 2 execution, but the current slice only publishes bounded planning metadata.'

        switch ($lensId) {
            'security-baseline' {
                $activation = 'required'
                $rationale = 'Security is always a materially reviewed baseline dimension, so the security lens stays pre-activated in planning even though row-level execution remains deferred.'
            }
            'robustness-baseline' {
                $activation = 'required'
                $rationale = 'Robustness, failure semantics, and retry-related concerns feed the hardening gate directly, so the robustness lens must be visible as required planning metadata.'
            }
            'test-integrity' {
                $activation = 'required'
                $rationale = 'Test-integrity targets are part of the pre-implementation hardening review, so this lens stays explicitly required in the bounded plan.'
            }
        }

        $null = $entries.Add((New-LensActivationPlanEntry -LensRef $lensRef -Activation $activation -Rationale $rationale -PlannedEvidencePath $evidencePath -RequestedReviewClass $QualityDefaults.routing_default_policy))
    }

    return @($entries)
}

function Get-PhaseTwoRoutingPolicy {
    param([pscustomobject]$QualityDefaults)

    $overrideRecord = if ($QualityDefaults.allow_lower_tier_override) {
        if ($QualityDefaults.approval_required) {
            'Explicit approved lower-tier override required before any downgrade takes effect.'
        }
        else {
            'Lower-tier overrides are allowed by config without a separate approval gate.'
        }
    }
    else {
        'No lower-tier override path is enabled for required hardening or specialist review work.'
    }

    return @(
        (New-RoutingPolicyEntry -LensScope 'Required hardening and bug-hunter lenses' -RequestedReviewClass $QualityDefaults.routing_default_policy -EffectiveClass 'Record when execution happens' -OverrideApprovalRecord $overrideRecord -Notes 'Planning publishes the requested routing baseline only; effective-class evidence stays deferred until the execution path exists.')
    )
}

function Get-PhaseTwoLaterDeferrals {
    return @(
        'Full line-by-line lens execution evidence remains deferred until the approved implementation/review slice authorizes it.',
        'Known-traps corpus seeding, approved additions, and trap reapplication remain deferred until the dedicated known-traps slice is in scope.',
        'Strongest-class routing enforcement details and requested-versus-effective execution evidence remain deferred until the routed lens execution path exists.',
        'Quality-drift comparison, mixed-stack override workflows, and reference-implementation checks remain deferred unless the approved slice explicitly includes them.'
    )
}

function Get-QualitySignals {
    param(
        [string]$ResolvedProjectPath,
        [string]$ResolvedFeaturePath,
        [string]$ResolvedSpecPath
    )

    $packageJsonPath = Join-Path $ResolvedProjectPath 'package.json'
    $pyprojectPath = Join-Path $ResolvedProjectPath 'pyproject.toml'
    $requirementsPath = Join-Path $ResolvedProjectPath 'requirements.txt'
    $projectFiles = Get-ChildItem -LiteralPath $ResolvedProjectPath -File -Recurse -ErrorAction SilentlyContinue
    $csprojFiles = @($projectFiles | Where-Object { $_.Extension -ieq '.csproj' })
    $slnFiles = @($projectFiles | Where-Object { $_.Extension -ieq '.sln' })

    $planPath = if ([string]::IsNullOrWhiteSpace($ResolvedFeaturePath)) { $null } else { Join-Path $ResolvedFeaturePath 'plan.md' }
    $tasksPath = if ([string]::IsNullOrWhiteSpace($ResolvedFeaturePath)) { $null } else { Join-Path $ResolvedFeaturePath 'tasks.md' }
    $quickstartPath = if ([string]::IsNullOrWhiteSpace($ResolvedFeaturePath)) { $null } else { Join-Path $ResolvedFeaturePath 'quickstart.md' }
    $contextText = @(
        Get-TextFileContent -Path $ResolvedSpecPath
        Get-TextFileContent -Path $planPath
        Get-TextFileContent -Path $tasksPath
        Get-TextFileContent -Path $quickstartPath
    ) -join "`n"
    $normalizedContext = $contextText.ToLowerInvariant()
    $dependencies = Get-DependencyNames -PackageJsonPath $packageJsonPath

    return [pscustomobject]@{
        package_json_path = $packageJsonPath
        has_package_json  = Test-Path -LiteralPath $packageJsonPath -PathType Leaf
        dependencies      = @($dependencies)
        has_pyproject     = Test-Path -LiteralPath $pyprojectPath -PathType Leaf
        has_requirements  = Test-Path -LiteralPath $requirementsPath -PathType Leaf
        csproj_files      = @($csprojFiles | Select-Object -ExpandProperty FullName)
        sln_files         = @($slnFiles | Select-Object -ExpandProperty FullName)
        context_text      = $contextText
        normalized_text   = $normalizedContext
    }
}

function Get-PresetCandidates {
    param([pscustomobject]$Signals)

    $candidates = [System.Collections.Generic.List[object]]::new()
    $dependencies = @($Signals.dependencies)
    $normalizedText = [string]$Signals.normalized_text

    $hasNodeApiDependency = [bool]($dependencies | Where-Object { $_ -in @('express', 'fastify', 'koa', 'hapi', '@nestjs/core', '@nestjs/platform-express') } | Select-Object -First 1)
    $hasWebsocketDependency = [bool]($dependencies | Where-Object { $_ -in @('ws', 'socket.io', 'socket.io-client', '@fastify/websocket', 'uwebsockets.js') } | Select-Object -First 1)
    $hasReactDependency = [bool]($dependencies | Where-Object { $_ -in @('react', 'react-dom', 'next') } | Select-Object -First 1)
    $hasPostgresDependency = [bool]($dependencies | Where-Object { $_ -in @('pg', 'postgres', 'knex', 'typeorm', 'sequelize', 'prisma') } | Select-Object -First 1)
    $hasFastApiSignal = $Signals.has_pyproject -or $Signals.has_requirements -or (Test-AnyPattern -Text $normalizedText -Patterns @('\bfastapi\b'))
    $hasAspNetSignal = ($Signals.csproj_files.Count -gt 0) -or ($Signals.sln_files.Count -gt 0) -or (Test-AnyPattern -Text $normalizedText -Patterns @('\basp\.net\b', '\baspnet\b', '\bcontroller\b', '\bminimal api\b'))

    $nodeWebsocketScore = 0
    $nodeWebsocketSignals = [System.Collections.Generic.List[string]]::new()
    if ($Signals.has_package_json) {
        $nodeWebsocketScore += 20
        Add-UniqueItem -List $nodeWebsocketSignals -Value 'package.json'
    }
    if ($hasWebsocketDependency) {
        $nodeWebsocketScore += 35
        Add-UniqueItem -List $nodeWebsocketSignals -Value 'websocket transport dependency'
    }
    if (Test-AnyPattern -Text $normalizedText -Patterns @('\bwebsocket\b', '\brealtime\b', 'socket', '/ws\b', 'long-lived connection')) {
        $nodeWebsocketScore += 35
        Add-UniqueItem -List $nodeWebsocketSignals -Value 'websocket feature scope'
    }
    if (Test-AnyPattern -Text $normalizedText -Patterns @('\bpublic\b', '\binternet-facing\b', '\bclient\b')) {
        $nodeWebsocketScore += 10
        Add-UniqueItem -List $nodeWebsocketSignals -Value 'public connection boundary'
    }
    if ($nodeWebsocketScore -ge 70) {
        $null = $candidates.Add([pscustomobject]@{
                preset_id       = 'node-public-ws-service'
                score           = $nodeWebsocketScore
                matched_signals = $nodeWebsocketSignals.ToArray()
            })
    }

    $reactScore = 0
    $reactSignals = [System.Collections.Generic.List[string]]::new()
    if ($Signals.has_package_json) {
        $reactScore += 20
        Add-UniqueItem -List $reactSignals -Value 'package.json'
    }
    if ($hasReactDependency) {
        $reactScore += 35
        Add-UniqueItem -List $reactSignals -Value 'react dependency'
    }
    if (Test-AnyPattern -Text $normalizedText -Patterns @('\breact\b', '\bspa\b', '\bfrontend\b', '\bbrowser\b', '\bcomponent\b', 'single-page')) {
        $reactScore += 25
        Add-UniqueItem -List $reactSignals -Value 'browser UI feature scope'
    }
    if (Test-Path -LiteralPath (Join-Path $ProjectPath 'src\components') -PathType Container -ErrorAction SilentlyContinue) {
        $reactScore += 10
        Add-UniqueItem -List $reactSignals -Value 'component-oriented source layout'
    }
    if ($reactScore -ge 70) {
        $null = $candidates.Add([pscustomobject]@{
                preset_id       = 'react-spa-public'
                score           = $reactScore
                matched_signals = $reactSignals.ToArray()
            })
    }

    $nodeRestScore = 0
    $nodeRestSignals = [System.Collections.Generic.List[string]]::new()
    if ($Signals.has_package_json) {
        $nodeRestScore += 20
        Add-UniqueItem -List $nodeRestSignals -Value 'package.json'
    }
    if ($hasNodeApiDependency) {
        $nodeRestScore += 20
        Add-UniqueItem -List $nodeRestSignals -Value 'node API dependency'
    }
    if ($hasPostgresDependency) {
        $nodeRestScore += 25
        Add-UniqueItem -List $nodeRestSignals -Value 'postgres dependency'
    }
    if (Test-AnyPattern -Text $normalizedText -Patterns @('\brest\b', '\bhttp\b', '\bapi\b', '\broute\b', '\bendpoint\b', '\bpostgres\b', '\bdatabase\b')) {
        $nodeRestScore += 25
        Add-UniqueItem -List $nodeRestSignals -Value 'API or persistence feature scope'
    }
    if ($nodeRestScore -ge 75) {
        $null = $candidates.Add([pscustomobject]@{
                preset_id       = 'node-rest-with-postgres'
                score           = $nodeRestScore
                matched_signals = $nodeRestSignals.ToArray()
            })
    }

    $fastApiScore = 0
    $fastApiSignals = [System.Collections.Generic.List[string]]::new()
    if ($Signals.has_pyproject -or $Signals.has_requirements) {
        $fastApiScore += 25
        Add-UniqueItem -List $fastApiSignals -Value 'python project manifest'
    }
    if (Test-AnyPattern -Text $normalizedText -Patterns @('\bfastapi\b', '\brouter\b', '\bendpoint\b', '\basync api\b')) {
        $fastApiScore += 35
        Add-UniqueItem -List $fastApiSignals -Value 'fastapi feature scope'
    }
    if (Test-AnyPattern -Text $normalizedText -Patterns @('\bservice\b', '\bhttp\b', '\bpublic\b')) {
        $fastApiScore += 15
        Add-UniqueItem -List $fastApiSignals -Value 'public service surface'
    }
    if ($fastApiScore -ge 70 -and $hasFastApiSignal) {
        $null = $candidates.Add([pscustomobject]@{
                preset_id       = 'python-fastapi-service'
                score           = $fastApiScore
                matched_signals = $fastApiSignals.ToArray()
            })
    }

    $aspNetScore = 0
    $aspNetSignals = [System.Collections.Generic.List[string]]::new()
    if ($Signals.csproj_files.Count -gt 0 -or $Signals.sln_files.Count -gt 0) {
        $aspNetScore += 25
        Add-UniqueItem -List $aspNetSignals -Value '*.csproj or solution file'
    }
    if (Test-AnyPattern -Text $normalizedText -Patterns @('\basp\.net\b', '\baspnet\b', '\bcontroller\b', '\bminimal api\b', '\bmiddleware\b')) {
        $aspNetScore += 35
        Add-UniqueItem -List $aspNetSignals -Value 'ASP.NET API surface'
    }
    if (Test-AnyPattern -Text $normalizedText -Patterns @('\bapi\b', '\bpublic\b', '\bservice\b')) {
        $aspNetScore += 15
        Add-UniqueItem -List $aspNetSignals -Value 'hosted .NET service scope'
    }
    if ($aspNetScore -ge 70 -and $hasAspNetSignal) {
        $null = $candidates.Add([pscustomobject]@{
                preset_id       = 'dotnet-aspnet-api'
                score           = $aspNetScore
                matched_signals = $aspNetSignals.ToArray()
            })
    }

    return @(
        $candidates |
            Sort-Object -Property @(
                @{ Expression = 'score'; Descending = $true }
                @{ Expression = 'preset_id'; Descending = $false }
            )
    )
}

function Get-PresetProfile {
    param(
        [string]$PresetId,
        [string[]]$MatchedSignals
    )

    switch ($PresetId) {
        'node-public-ws-service' {
            return [pscustomobject]@{
                preset_ref           = 'node-public-ws-service@v1.0.0'
                profile_id           = 'quality-profile.node-public-ws-service.v1'
                bundle_id            = 'node-websocket-phase1'
                stack_surfaces       = @(
                    (New-StackSurface -SurfaceId 'service-runtime' -PathGlobs @('package.json', 'src/**/*.js', 'src/**/*.ts') -Language 'Node.js' -RuntimeShape 'service-runtime' -RecognizedStack $PresetId -MatchedSignals $MatchedSignals),
                    (New-StackSurface -SurfaceId 'websocket-boundary' -PathGlobs @('src/**/*ws*', 'src/**/*socket*', 'src/**/*gateway*') -Language 'Node.js' -RuntimeShape 'websocket-boundary' -RecognizedStack $PresetId -MatchedSignals $MatchedSignals),
                    (New-StackSurface -SurfaceId 'session-state' -PathGlobs @('src/**/*session*', 'src/**/*connection*') -Language 'Node.js' -RuntimeShape 'session-state' -RecognizedStack $PresetId -MatchedSignals $MatchedSignals)
                )
                preset_dimensions    = @('verification-confidence', 'security', 'robustness', 'concurrency-correctness', 'resiliency')
                ecosystem_tools      = @('npm test', 'repo-standard Node lint/static-analysis command', 'deterministic websocket integration checks')
                mechanical_checks    = @('dead-field', 'anti-pattern', 'test-integrity')
                required_lens_refs   = Get-DefaultLensRefs
                custom_lens_refs     = @()
            }
        }
        'react-spa-public' {
            return [pscustomobject]@{
                preset_ref           = 'react-spa-public@v1.0.0'
                profile_id           = 'quality-profile.react-spa-public.v1'
                bundle_id            = 'react-spa-phase1'
                stack_surfaces       = @(
                    (New-StackSurface -SurfaceId 'browser-ui' -PathGlobs @('package.json', 'src/**/*.jsx', 'src/**/*.tsx') -Language 'TypeScript/JavaScript' -RuntimeShape 'browser-spa' -RecognizedStack $PresetId -MatchedSignals $MatchedSignals),
                    (New-StackSurface -SurfaceId 'component-state' -PathGlobs @('src/**/*component*', 'src/**/*hook*', 'src/**/*state*') -Language 'TypeScript/JavaScript' -RuntimeShape 'component-state' -RecognizedStack $PresetId -MatchedSignals $MatchedSignals)
                )
                preset_dimensions    = @('verification-confidence', 'maintainability', 'security')
                ecosystem_tools      = @('npm test', 'repo-standard frontend lint/static-analysis command', 'browser-oriented component/integration tests')
                mechanical_checks    = @('dead-field', 'anti-pattern', 'test-integrity')
                required_lens_refs   = Get-DefaultLensRefs
                custom_lens_refs     = @()
            }
        }
        'node-rest-with-postgres' {
            return [pscustomobject]@{
                preset_ref           = 'node-rest-with-postgres@v1.0.0'
                profile_id           = 'quality-profile.node-rest-with-postgres.v1'
                bundle_id            = 'node-rest-postgres-phase1'
                stack_surfaces       = @(
                    (New-StackSurface -SurfaceId 'api-runtime' -PathGlobs @('package.json', 'src/**/*.js', 'src/**/*.ts') -Language 'Node.js' -RuntimeShape 'http-api' -RecognizedStack $PresetId -MatchedSignals $MatchedSignals),
                    (New-StackSurface -SurfaceId 'persistence-boundary' -PathGlobs @('src/**/*repository*', 'src/**/*db*', 'src/**/*postgres*') -Language 'Node.js' -RuntimeShape 'postgres-persistence' -RecognizedStack $PresetId -MatchedSignals $MatchedSignals)
                )
                preset_dimensions    = @('maintainability', 'security', 'robustness', 'resiliency')
                ecosystem_tools      = @('npm test', 'repo-standard Node lint/static-analysis command', 'Postgres-backed integration coverage')
                mechanical_checks    = @('dead-field', 'anti-pattern', 'test-integrity')
                required_lens_refs   = Get-DefaultLensRefs
                custom_lens_refs     = @()
            }
        }
        'python-fastapi-service' {
            return [pscustomobject]@{
                preset_ref           = 'python-fastapi-service@v1.0.0'
                profile_id           = 'quality-profile.python-fastapi-service.v1'
                bundle_id            = 'python-fastapi-phase1'
                stack_surfaces       = @(
                    (New-StackSurface -SurfaceId 'api-runtime' -PathGlobs @('pyproject.toml', 'requirements.txt', '**/*.py') -Language 'Python' -RuntimeShape 'http-api' -RecognizedStack $PresetId -MatchedSignals $MatchedSignals),
                    (New-StackSurface -SurfaceId 'request-models' -PathGlobs @('**/*schema*.py', '**/*model*.py') -Language 'Python' -RuntimeShape 'typed-request-models' -RecognizedStack $PresetId -MatchedSignals $MatchedSignals)
                )
                preset_dimensions    = @('verification-confidence', 'security', 'robustness', 'resiliency')
                ecosystem_tools      = @('pytest', 'repo-standard Python lint/type-analysis command', 'FastAPI route/integration tests')
                mechanical_checks    = @('dead-field', 'anti-pattern', 'test-integrity')
                required_lens_refs   = Get-DefaultLensRefs
                custom_lens_refs     = @()
            }
        }
        'dotnet-aspnet-api' {
            return [pscustomobject]@{
                preset_ref           = 'dotnet-aspnet-api@v1.0.0'
                profile_id           = 'quality-profile.dotnet-aspnet-api.v1'
                bundle_id            = 'dotnet-aspnet-phase1'
                stack_surfaces       = @(
                    (New-StackSurface -SurfaceId 'api-runtime' -PathGlobs @('**/*.csproj', '**/*.cs', '**/*.sln') -Language '.NET / C#' -RuntimeShape 'http-api' -RecognizedStack $PresetId -MatchedSignals $MatchedSignals),
                    (New-StackSurface -SurfaceId 'request-pipeline' -PathGlobs @('**/*Controller.cs', '**/*Middleware*.cs', '**/Program.cs') -Language '.NET / C#' -RuntimeShape 'request-pipeline' -RecognizedStack $PresetId -MatchedSignals $MatchedSignals)
                )
                preset_dimensions    = @('verification-confidence', 'security', 'robustness', 'resiliency')
                ecosystem_tools      = @('dotnet test', 'repo-standard .NET analyzer/lint lane', 'integration or host-level API tests')
                mechanical_checks    = @('dead-field', 'anti-pattern', 'test-integrity')
                required_lens_refs   = Get-DefaultLensRefs
                custom_lens_refs     = @()
            }
        }
        default {
            throw "Unsupported preset '$PresetId'."
        }
    }
}

function Get-CustomCompositionProfile {
    param(
        [pscustomobject]$Signals,
        [object[]]$Candidates
    )

    $stackSurfaces = [System.Collections.Generic.List[object]]::new()
    foreach ($candidate in $Candidates | Select-Object -First 2) {
        $matchedSignals = @($candidate.matched_signals)
        switch ($candidate.preset_id) {
            'react-spa-public' {
                $null = $stackSurfaces.Add((New-StackSurface -SurfaceId 'browser-ui' -PathGlobs @('package.json', 'src/**/*.jsx', 'src/**/*.tsx') -Language 'TypeScript/JavaScript' -RuntimeShape 'browser-spa' -RecognizedStack 'custom' -MatchedSignals $matchedSignals))
            }
            'node-rest-with-postgres' {
                $null = $stackSurfaces.Add((New-StackSurface -SurfaceId 'api-runtime' -PathGlobs @('package.json', 'src/**/*.js', 'src/**/*.ts') -Language 'Node.js' -RuntimeShape 'http-api' -RecognizedStack 'custom' -MatchedSignals $matchedSignals))
            }
            'node-public-ws-service' {
                $null = $stackSurfaces.Add((New-StackSurface -SurfaceId 'realtime-runtime' -PathGlobs @('package.json', 'src/**/*ws*', 'src/**/*socket*') -Language 'Node.js' -RuntimeShape 'websocket-boundary' -RecognizedStack 'custom' -MatchedSignals $matchedSignals))
            }
            'python-fastapi-service' {
                $null = $stackSurfaces.Add((New-StackSurface -SurfaceId 'python-service' -PathGlobs @('pyproject.toml', 'requirements.txt', '**/*.py') -Language 'Python' -RuntimeShape 'http-api' -RecognizedStack 'custom' -MatchedSignals $matchedSignals))
            }
            'dotnet-aspnet-api' {
                $null = $stackSurfaces.Add((New-StackSurface -SurfaceId 'dotnet-service' -PathGlobs @('**/*.csproj', '**/*.cs', '**/*.sln') -Language '.NET / C#' -RuntimeShape 'http-api' -RecognizedStack 'custom' -MatchedSignals $matchedSignals))
            }
        }
    }

    if ($stackSurfaces.Count -eq 0) {
        $genericSignals = [System.Collections.Generic.List[string]]::new()
        if ($Signals.has_package_json) {
            Add-UniqueItem -List $genericSignals -Value 'package.json'
        }
        if ($Signals.has_pyproject -or $Signals.has_requirements) {
            Add-UniqueItem -List $genericSignals -Value 'python project manifest'
        }
        if ($Signals.csproj_files.Count -gt 0 -or $Signals.sln_files.Count -gt 0) {
            Add-UniqueItem -List $genericSignals -Value '.NET project file'
        }
        if ($genericSignals.Count -eq 0) {
            Add-UniqueItem -List $genericSignals -Value 'feature specification only'
        }

        $null = $stackSurfaces.Add((New-StackSurface -SurfaceId 'custom-phase1-surface' -PathGlobs @('**/*') -Language 'mixed-or-unknown' -RuntimeShape 'custom-surface' -RecognizedStack 'custom' -MatchedSignals $genericSignals.ToArray()))
    }

    $ecosystemTools = [System.Collections.Generic.List[string]]::new()
    if ($Signals.has_package_json) {
        Add-UniqueItems -List $ecosystemTools -Values @('repo-standard stack-specific lint/static-analysis command', 'repo-standard verification command')
    }
    if ($Signals.has_pyproject -or $Signals.has_requirements) {
        Add-UniqueItems -List $ecosystemTools -Values @('pytest', 'repo-standard Python lint/type-analysis command')
    }
    if ($Signals.csproj_files.Count -gt 0 -or $Signals.sln_files.Count -gt 0) {
        Add-UniqueItems -List $ecosystemTools -Values @('dotnet test', 'repo-standard .NET analyzer/lint lane')
    }
    if ($ecosystemTools.Count -eq 0) {
        Add-UniqueItems -List $ecosystemTools -Values @('repo-standard stack-specific lint/static-analysis command', 'manual review evidence recorded in quality-evidence.md')
    }

    $reason = if ($Candidates.Count -gt 1) {
        'Repository and feature signals map to more than one Phase 1 preset, so this slice stays bounded by composing from the approved baseline lenses and mechanical gates instead of claiming a single recognized preset.'
    }
    else {
        'Repository and feature signals are weak or unsupported for a confident Phase 1 preset match, so this slice falls back to a bounded custom composition with explicit manual review expectations.'
    }

    return [pscustomobject]@{
        preset_ref           = $null
        profile_id           = 'quality-profile.custom-composition.v1'
        bundle_id            = 'phase1-custom-quality-bundle'
        stack_surfaces       = @($stackSurfaces)
        preset_dimensions    = @('verification-confidence', 'security', 'robustness')
        ecosystem_tools      = $ecosystemTools.ToArray()
        mechanical_checks    = @('dead-field', 'anti-pattern', 'test-integrity')
        required_lens_refs   = @()
        custom_lens_refs     = Get-DefaultLensRefs
        custom_reason        = $reason
        unknowns             = @(
            'Confirm the stack-specific lint or analyzer command for the active surface.',
            'Confirm whether any additional stack-specific evidence source is needed beyond the Phase 1 baseline mechanical gates and checklist references.'
        )
    }
}

function Get-RiskResolution {
    param(
        [pscustomobject]$Profile,
        [pscustomobject]$Signals
    )

    $required = [System.Collections.Generic.List[object]]::new()
    $notApplicable = [System.Collections.Generic.List[object]]::new()
    $baselineDimensions = Get-BaselineRiskDimensions

    foreach ($dimension in $baselineDimensions) {
        $rationale = switch ($dimension) {
            'code-quality' { 'Phase 1 always evaluates code-quality expectations because the quality tool bundle must remain explicit and reviewable.' }
            'design-quality-and-separation-of-concerns' { 'Phase 1 always evaluates design quality and separation of concerns so the plan does not hide layering or coupling risks.' }
            'verification-confidence' { 'Phase 1 always requires verification confidence so tests and evidence prove observable behavior instead of smoke-only success.' }
            'maintainability' { 'Phase 1 always evaluates maintainability because the quality bar must remain stack-aware and reviewable for later iterations.' }
            'security' { 'Phase 1 always evaluates security because every active feature can expose boundary, configuration, or data-handling concerns.' }
            'robustness' { 'Phase 1 always evaluates robustness so degraded behavior and failure semantics are explicit before implementation continues.' }
            default { 'Phase 1 baseline quality dimension.' }
        }

        $null = $required.Add((New-RiskDimension -Id $dimension -Status 'required' -Rationale $rationale))
    }

    $normalizedText = [string]$Signals.normalized_text
    $surfaceRuntimeShapes = @($Profile.stack_surfaces | ForEach-Object { $_.runtime_shape })
    $isRecognizedPreset = -not [string]::IsNullOrWhiteSpace([string]$Profile.preset_ref)

    $requiresConcurrency = if ($isRecognizedPreset) {
        ($Profile.profile_id -eq 'quality-profile.node-public-ws-service.v1') -or
        (Test-AnyPattern -Text $normalizedText -Patterns @('\bconcurr', '\brace\b', '\bparallel\b', '\bshared state\b', '\bwebsocket\b', '\brealtime\b', '\bsession\b'))
    }
    else {
        $surfaceRuntimeShapes -contains 'websocket-boundary'
    }

    $requiresResiliency = if ($isRecognizedPreset) {
        ($Profile.profile_id -in @('quality-profile.node-public-ws-service.v1', 'quality-profile.node-rest-with-postgres.v1', 'quality-profile.python-fastapi-service.v1', 'quality-profile.dotnet-aspnet-api.v1')) -or
        (Test-AnyPattern -Text $normalizedText -Patterns @('\bretry\b', '\bidempot', '\brecover', '\btimeout\b', '\bbackoff\b', '\breconnect\b', '\bdegraded\b', '\bfailure\b'))
    }
    else {
        $surfaceRuntimeShapes -contains 'websocket-boundary'
    }

    if ($requiresConcurrency) {
        $null = $required.Add((New-RiskDimension -Id 'concurrency-correctness' -Status 'required' -Rationale 'The feature shape materially touches realtime, session, or shared-state behavior, so concurrency correctness must be planned explicitly in Phase 1.'))
    }
    else {
        $null = $notApplicable.Add([pscustomobject]@{
                id               = 'concurrency-correctness'
                rationale        = 'No repository or feature signal shows material shared-state, parallel, or realtime concurrency behavior for this Phase 1 slice.'
                omitted_gate_ids = @('concurrency-correctness-review')
            })
    }

    if ($requiresResiliency) {
        $null = $required.Add((New-RiskDimension -Id 'resiliency' -Status 'required' -Rationale 'The feature shape includes failure-handling, reconnect, async service, or persistence semantics that need an explicit resiliency expectation in Phase 1.'))
        $null = $required.Add((New-RiskDimension -Id 'retry-idempotency-and-recovery' -Status 'required' -Rationale 'Retry, idempotency, and recovery concerns are materially relevant for the active surface, so the plan must call them out even though later-phase hardening workflows stay deferred.'))
    }
    else {
        $null = $notApplicable.Add([pscustomobject]@{
                id               = 'resiliency'
                rationale        = 'The current Phase 1 slice does not materially depend on retries, reconnect, or degraded recovery behavior beyond the baseline robustness expectation.'
                omitted_gate_ids = @('resiliency-semantics-review')
            })
        $null = $notApplicable.Add([pscustomobject]@{
                id               = 'retry-idempotency-and-recovery'
                rationale        = 'Retry, idempotency, and recovery-specific gates are not required because the active feature shape does not present a material retry or recovery workflow in this slice.'
                omitted_gate_ids = @('retry-idempotency-review')
            })
    }

    return [pscustomobject]@{
        required       = @($required)
        not_applicable = @($notApplicable)
    }
}

function Get-RequiredQualityGates {
    param(
        [pscustomobject]$Profile,
        [pscustomobject]$RiskResolution
    )

    $gates = [System.Collections.Generic.List[object]]::new()
    $evidenceDirectory = 'specs/<feature>/iterations/<NNN>/quality/'
    $findingsPath = $evidenceDirectory + 'mechanical-findings.json'
    $evidencePath = $evidenceDirectory + 'quality-evidence.md'

    $null = $gates.Add((New-QualityGate -GateId 'dead-field' -Category 'mechanical' -RequirementRefs @('FR-004', 'FR-027', 'FR-030') -EvidenceRef $findingsPath -Description 'Inspect declared fields, DTOs, and config members for unused state.'))
    $null = $gates.Add((New-QualityGate -GateId 'anti-pattern' -Category 'mechanical' -RequirementRefs @('FR-004', 'FR-028', 'FR-030') -EvidenceRef $findingsPath -Description 'Flag deterministic anti-patterns before model-based review.'))
    $null = $gates.Add((New-QualityGate -GateId 'test-integrity' -Category 'mechanical' -RequirementRefs @('FR-004', 'FR-029', 'FR-030') -EvidenceRef $findingsPath -Description 'Require assertion-driven tests with meaningful negative-path evidence.'))
    $null = $gates.Add((New-QualityGate -GateId 'stack-tooling-evidence' -Category 'tooling' -RequirementRefs @('FR-004', 'FR-010', 'FR-011') -EvidenceRef $evidencePath -Description 'Record the stack-aware lint, static-analysis, and verification command(s) selected for the active surface.'))
    $null = $gates.Add((New-QualityGate -GateId 'quality-lens-review' -Category 'manual-evidence' -RequirementRefs @('FR-010', 'FR-011', 'FR-015') -EvidenceRef $evidencePath -Description 'Record checklist-backed quality reasoning for the selected preset or bounded custom composition.'))

    if ($RiskResolution.required.id -contains 'concurrency-correctness') {
        $null = $gates.Add((New-QualityGate -GateId 'concurrency-correctness-review' -Category 'manual-evidence' -RequirementRefs @('FR-003', 'FR-015') -EvidenceRef $evidencePath -Description 'Record how the plan addresses materially relevant concurrency-correctness concerns in Phase 1.'))
    }

    if ($RiskResolution.required.id -contains 'resiliency') {
        $null = $gates.Add((New-QualityGate -GateId 'resiliency-semantics-review' -Category 'manual-evidence' -RequirementRefs @('FR-003', 'FR-015') -EvidenceRef $evidencePath -Description 'Record how the plan addresses materially relevant resiliency and degraded-behavior concerns in Phase 1.'))
    }

    if ($RiskResolution.required.id -contains 'retry-idempotency-and-recovery') {
        $null = $gates.Add((New-QualityGate -GateId 'retry-idempotency-review' -Category 'manual-evidence' -RequirementRefs @('FR-015') -EvidenceRef $evidencePath -Description 'Record retry, idempotency, and recovery expectations only when they materially apply in this Phase 1 slice.'))
    }

    return @($gates)
}

function Convert-QualityProfileToMarkdown {
    param([pscustomobject]$Resolution)

    $lines = [System.Collections.Generic.List[string]]::new()
    $selectedPresetText = if ($Resolution.preset_refs.Count -gt 0) { $Resolution.preset_refs -join ', ' } else { 'None - using bounded custom composition' }
    $customCompositionText = if ($Resolution.custom_composition) { $Resolution.custom_composition.reason } else { 'Not required for this recognized stack.' }

    $null = $lines.Add('## Phase 1 Quality Planning')
    $null = $lines.Add('')
    $null = $lines.Add('**Phase Scope**: `phase-1-first-slice`')
    $null = $lines.Add(('**Inferred Quality Profile**: `{0}`' -f $Resolution.profile_id))
    $null = $lines.Add(('**Selected preset ref or explicit custom composition**: {0}' -f $selectedPresetText))
    $null = $lines.Add(('**Bounded custom composition**: {0}' -f $customCompositionText))
    $null = $lines.Add('')
    $null = $lines.Add('### Stack Surfaces in Scope')
    $null = $lines.Add('| Stack Surface | Recognized Stack | Path Globs | Matched Signals |')
    $null = $lines.Add('| --- | --- | --- | --- |')
    foreach ($surface in $Resolution.stack_surfaces) {
        $null = $lines.Add(('| `{0}` | `{1}` | `{2}` | {3} |' -f $surface.surface_id, $surface.recognized_stack, (($surface.path_globs -join ', ') -replace '\|', '\|'), ($surface.matched_signals -join '; ')))
    }
    $null = $lines.Add('')
    $null = $lines.Add('### Risk Dimensions')
    $null = $lines.Add('| Risk Dimension | Status | Rationale |')
    $null = $lines.Add('| --- | --- | --- |')
    foreach ($dimension in $Resolution.risk_dimensions) {
        $null = $lines.Add(('| `{0}` | `{1}` | {2} |' -f $dimension.id, $dimension.status, $dimension.rationale))
    }
    $null = $lines.Add('')
    $null = $lines.Add('### Quality Tool Bundle')
    $null = $lines.Add('| Area | Selection |')
    $null = $lines.Add('| --- | --- |')
    $null = $lines.Add(('| Bundle ID | `{0}` |' -f $Resolution.tool_bundle.bundle_id))
    $null = $lines.Add(('| Mechanical Checks | {0} |' -f ($Resolution.tool_bundle.mechanical_checks -join ', ')))
    $null = $lines.Add(('| Ecosystem Tools | {0} |' -f ($Resolution.tool_bundle.ecosystem_tools -join ', ')))
    $null = $lines.Add(('| Manual Evidence | {0} |' -f ($Resolution.tool_bundle.manual_evidence -join ', ')))
    $null = $lines.Add('')
    $null = $lines.Add('### Required Quality Gates')
    $null = $lines.Add('| Required Quality Gate | Category | Evidence Source |')
    $null = $lines.Add('| --- | --- | --- |')
    foreach ($gate in $Resolution.required_quality_gates) {
        $null = $lines.Add(('| `{0}` | `{1}` | `{2}` |' -f $gate.gate_id, $gate.category, $gate.evidence_ref))
    }
    $null = $lines.Add('')
    $null = $lines.Add('### Not-Applicable Dimensions and Rationale')
    $null = $lines.Add('| Dimension | Rationale | Omitted Gates |')
    $null = $lines.Add('| --- | --- | --- |')
    foreach ($dimension in $Resolution.not_applicable_dimensions) {
        $null = $lines.Add(('| `{0}` | {1} | `{2}` |' -f $dimension.id, $dimension.rationale, ($dimension.omitted_gate_ids -join ', ')))
    }
    $null = $lines.Add('')
    $null = $lines.Add('### Explicit Phase 2+ Deferrals')
    foreach ($deferral in $Resolution.phase2_deferrals) {
        $null = $lines.Add(("- {0}" -f $deferral))
    }
    $null = $lines.Add('')
    $null = $lines.Add('## Phase 2 Hardening and Specialist Review Planning')
    $null = $lines.Add('')
    $null = $lines.Add(('**Phase 2 Slice Scope**: `{0}`' -f $Resolution.phase2_slice_scope))
    $null = $lines.Add(('**Hardening Gate Artifact**: `{0}`' -f $Resolution.phase2_hardening_gate_artifact))
    $null = $lines.Add(('**Known-Traps Corpus Location**: `{0}`' -f $Resolution.phase2_known_traps_corpus_location))
    $null = $lines.Add(('**Trap Reapplication Artifact**: `{0}`' -f $Resolution.phase2_trap_reapplication_artifact))
    $null = $lines.Add('')
    $null = $lines.Add('### Hardening Focus Areas')
    $null = $lines.Add('| Focus Area | Why It Matters in This Slice | Planned Artifact / Evidence | Status |')
    $null = $lines.Add('| --- | --- | --- | --- |')
    foreach ($focusArea in $Resolution.phase2_hardening_focus_areas) {
        $null = $lines.Add(('| {0} | {1} | `{2}` | `{3}` |' -f $focusArea.focus_area, $focusArea.why_it_matters, $focusArea.planned_artifact_or_evidence, $focusArea.status))
    }
    $null = $lines.Add('')
    $null = $lines.Add('### Lens Activation Plan')
    $null = $lines.Add('| Lens / Checklist Ref | Activation | Why Activated or Omitted | Planned Evidence / Artifact Path |')
    $null = $lines.Add('| --- | --- | --- | --- |')
    foreach ($lensPlan in $Resolution.phase2_lens_activation_plan) {
        $null = $lines.Add(('| `{0}` | `{1}` | {2} | `{3}` |' -f $lensPlan.lens_ref, $lensPlan.activation, $lensPlan.rationale, $lensPlan.planned_evidence_path))
    }
    $null = $lines.Add('')
    $null = $lines.Add('### Routing Policy')
    $null = $lines.Add('| Lens Scope | Requested Reasoning / Review Class | Effective Class (when run) | Override / Approval Record | Notes |')
    $null = $lines.Add('| --- | --- | --- | --- | --- |')
    foreach ($routingRow in $Resolution.phase2_routing_policy) {
        $null = $lines.Add(('| {0} | `{1}` | {2} | {3} | {4} |' -f $routingRow.lens_scope, $routingRow.requested_review_class, $routingRow.effective_class, $routingRow.override_approval_record, $routingRow.notes))
    }
    $null = $lines.Add('')
    $null = $lines.Add('### Explicit Later Deferrals')
    foreach ($deferral in $Resolution.phase2_explicit_later_deferrals) {
        $null = $lines.Add(("- {0}" -f $deferral))
    }

    return $lines -join "`n"
}

$resolvedProjectPath = [System.IO.Path]::GetFullPath($ProjectPath)
if (-not (Test-Path -LiteralPath $resolvedProjectPath -PathType Container)) {
    throw "Project path '$resolvedProjectPath' does not exist."
}

$resolvedFeaturePath = $null
if (-not [string]::IsNullOrWhiteSpace($FeaturePath)) {
    $resolvedFeaturePath = [System.IO.Path]::GetFullPath($FeaturePath)
}
elseif (-not [string]::IsNullOrWhiteSpace($SpecPath)) {
    $resolvedFeaturePath = Split-Path -Parent ([System.IO.Path]::GetFullPath($SpecPath))
}

$resolvedSpecPath = $null
if (-not [string]::IsNullOrWhiteSpace($SpecPath)) {
    $resolvedSpecPath = [System.IO.Path]::GetFullPath($SpecPath)
}
elseif (-not [string]::IsNullOrWhiteSpace($resolvedFeaturePath)) {
    $candidateSpecPath = Join-Path $resolvedFeaturePath 'spec.md'
    if (Test-Path -LiteralPath $candidateSpecPath -PathType Leaf) {
        $resolvedSpecPath = $candidateSpecPath
    }
}

$signals = Get-QualitySignals -ResolvedProjectPath $resolvedProjectPath -ResolvedFeaturePath $resolvedFeaturePath -ResolvedSpecPath $resolvedSpecPath
$candidates = @(Get-PresetCandidates -Signals $signals)
$selectedCandidate = $null
if ($candidates.Count -gt 0) {
    $selectedCandidate = $candidates[0]
}

$useRecognizedPreset = $false
if ($candidates.Count -eq 1) {
    $useRecognizedPreset = $true
}
elseif ($candidates.Count -gt 1) {
    $scoreGap = [int]$candidates[0].score - [int]$candidates[1].score
    $useRecognizedPreset = ($candidates[0].score -ge 85) -and ($scoreGap -ge 15)
}

$profile = if ($useRecognizedPreset -and $null -ne $selectedCandidate) {
    Get-PresetProfile -PresetId $selectedCandidate.preset_id -MatchedSignals @($selectedCandidate.matched_signals)
}
else {
    Get-CustomCompositionProfile -Signals $signals -Candidates $candidates
}

$riskResolution = Get-RiskResolution -Profile $profile -Signals $signals
$requiredQualityGates = Get-RequiredQualityGates -Profile $profile -RiskResolution $riskResolution
$qualityPlanningDefaults = Get-QualityPlanningDefaults -ResolvedProjectPath $resolvedProjectPath
$phaseTwoArtifactRefs = Get-PhaseTwoArtifactRefs -ResolvedProjectPath $resolvedProjectPath -ResolvedFeaturePath $resolvedFeaturePath -QualityDefaults $qualityPlanningDefaults
$presetRefs = [System.Collections.Generic.List[string]]::new()
if ($profile.preset_ref) {
    Add-UniqueItem -List $presetRefs -Value $profile.preset_ref
}

$manualEvidence = [System.Collections.Generic.List[string]]::new()
Add-UniqueItem -List $manualEvidence -Value 'feature plan Phase 1 quality planning section'
Add-UniqueItem -List $manualEvidence -Value 'specs/<feature>/iterations/<NNN>/quality/quality-evidence.md'

$resolution = [pscustomobject]@{
    schema_version            = 'v1'
    phase_scope               = 'phase-1-first-slice'
    project_path              = $resolvedProjectPath
    feature_path              = $resolvedFeaturePath
    spec_path                 = $resolvedSpecPath
    profile_id                = $profile.profile_id
    resolution_mode           = $(if ($profile.preset_ref) { 'preset' } else { 'bounded-custom-composition' })
    preset_refs               = $presetRefs.ToArray()
    custom_composition        = $(if ($profile.preset_ref) { $null } else { [pscustomobject]@{
                reason        = $profile.custom_reason
                lens_refs     = @($profile.custom_lens_refs)
                unknowns      = @($profile.unknowns)
                phase_boundary = 'Phase 1 only; no hardening gate, bug-hunter execution, strongest-class routing, or quality-drift logic is implied.'
            } })
    stack_signals             = @($candidates | ForEach-Object {
            [pscustomobject]@{
                preset_id       = $_.preset_id
                score           = $_.score
                matched_signals = @($_.matched_signals)
            }
        })
    stack_surfaces            = @($profile.stack_surfaces)
    risk_dimensions           = @($riskResolution.required)
    not_applicable_dimensions = @($riskResolution.not_applicable)
    required_lens_refs        = @($profile.required_lens_refs)
    custom_lens_refs          = @($profile.custom_lens_refs)
    tool_bundle               = [pscustomobject]@{
        bundle_id         = $profile.bundle_id
        mechanical_checks = @($profile.mechanical_checks)
        ecosystem_tools   = @($profile.ecosystem_tools)
        manual_evidence   = $manualEvidence.ToArray()
    }
    required_quality_gates    = @($requiredQualityGates)
    phase2_slice_scope        = 'US-2 hardening-gate planning only; pre-implementation readiness must accept planning-time analysis, expected controls, rationale, and explicit non-applicable reasoning, while runtime-only final proof stays pending until later closure or approved runtime-only deferment.'
    phase2_hardening_gate_artifact = $phaseTwoArtifactRefs.hardening_gate_artifact
    phase2_known_traps_corpus_location = $phaseTwoArtifactRefs.known_traps_corpus_location
    phase2_trap_reapplication_artifact = $phaseTwoArtifactRefs.trap_reapplication_artifact
    phase2_hardening_focus_areas = @(Get-PhaseTwoHardeningFocusAreas -RiskResolution $riskResolution -ArtifactRefs $phaseTwoArtifactRefs)
    phase2_lens_activation_plan = @(Get-PhaseTwoLensActivationPlan -Profile $profile -ArtifactRefs $phaseTwoArtifactRefs -QualityDefaults $qualityPlanningDefaults)
    phase2_routing_policy     = @(Get-PhaseTwoRoutingPolicy -QualityDefaults $qualityPlanningDefaults)
    phase2_explicit_later_deferrals = @(Get-PhaseTwoLaterDeferrals)
    phase2_deferrals          = Get-PhaseOneDeferrals
}
$resolution | Add-Member -NotePropertyName markdown_summary -NotePropertyValue (Convert-QualityProfileToMarkdown -Resolution $resolution)

switch ($OutputFormat) {
    'Json' {
        $resolution | ConvertTo-Json -Depth 10
    }
    'Markdown' {
        $resolution.markdown_summary
    }
    default {
        $resolution
    }
}
