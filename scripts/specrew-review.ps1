[CmdletBinding()]
param(
    [string]$ProjectPath = '.',
    [string]$FeatureId,
    [string]$IterationNumber,
    [switch]$Quiet,
    [switch]$Json,
    [switch]$Open,
    [switch]$Live,
    [Alias('baseline-ref')]
    [string]$BaselineRef,
    [string]$Trunk,
    [Alias('checkpoint-id')]
    [string]$CheckpointId,
    [Alias('run-id')]
    [string]$RunId,
    [string]$HostName,
    [Alias('host')]
    [string]$ReviewerHost,
    [string]$Model,
    [Alias('authorization-ref')]
    [string]$AuthorizationRef,
    [Alias('code-writer-host')]
    [string]$CodeWriterHost,
    [Alias('fallback-policy')]
    [string]$FallbackPolicy,
    [Alias('reviewer-config')]
    [string]$ReviewerConfigPath,
    [Alias('schema-root')]
    [string]$SchemaRoot,
    [Alias('run-root')]
    [string]$RunRoot,
    [Alias('timeout-seconds')]
    [int]$TimeoutSeconds = 0,
    [Alias('design-context-ref')]
    [string[]]$DesignContextRef,
    [Alias('allowed-path')]
    [string[]]$AllowedPath,
    [Alias('forbidden-path')]
    [string[]]$ForbiddenPath,
    [Alias('exclude-path')]
    [string[]]$ExcludePath,
    [Alias('preserve-debug')]
    [switch]$PreserveDebug,
    [Alias('list-hosts')]
    [switch]$ListHosts,
    [switch]$Help,
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$CliArgs
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$sharedGovernancePath = Join-Path (Split-Path -Parent $PSScriptRoot) 'extensions\specrew-speckit\scripts\shared-governance.ps1'
if (-not (Test-Path -LiteralPath $sharedGovernancePath -PathType Leaf)) {
    throw "Missing shared governance helper '$sharedGovernancePath'."
}
. $sharedGovernancePath

$boundaryStateHelperPath = Join-Path $PSScriptRoot 'internal\sync-boundary-state.ps1'
if (-not (Test-Path -LiteralPath $boundaryStateHelperPath -PathType Leaf)) {
    throw "Missing boundary-state helper '$boundaryStateHelperPath'."
}
. $boundaryStateHelperPath

# INT-006 (iter-007): `specrew review --list-hosts` DISCOVERS + PRESENTS the available reviewer hosts (with
# the recommended independent default) and exits - lightweight, no review, no project-setup gate. This is
# the deterministic list the code-implementation lens renders so the human chooses from real options
# instead of being asked blind. Best-effort PATH detection; reflects this shell's env.
if ($ListHosts) {
    $ccrLoadPath = Join-Path $PSScriptRoot 'internal\continuous-co-review\_load.ps1'
    if (Test-Path -LiteralPath $ccrLoadPath -PathType Leaf) {
        . $ccrLoadPath
        $cwHostForList = if (-not [string]::IsNullOrWhiteSpace($CodeWriterHost)) { $CodeWriterHost } elseif (-not [string]::IsNullOrWhiteSpace($env:SPECREW_HOST)) { $env:SPECREW_HOST } else { $env:SPECREW_ACTIVE_HOST }
        Write-Host (Format-ContinuousCoReviewReviewerHostChoices -CodeWriterHost $cwHostForList).text
    }
    else {
        Write-Host 'Reviewer-host discovery is unavailable (continuous-co-review module not found under this Specrew install).'
    }
    return
}

function Show-Usage {
    @'
specrew review - run live continuous co-review or replay persisted reviewer evidence

Usage:
  specrew review [<iteration>] [--project-path <path>] [--feature <id>] [--quiet | --json] [--open]
  specrew review --live --baseline-ref <ref> [--checkpoint-id <id>] [--run-id <id>]
                 [--host <host>] [--model <model>] [--effort <effort>] [--authorization-ref <ref>]
                 [--code-writer-host <host>]
                 [--design-context-ref <path>] [--allowed-path <path>] [--forbidden-path <path>]
                 [--exclude-path <pattern>] [--reviewer-config <path>] [--schema-root <path>]
                 [--run-root <path>] [--timeout-seconds <seconds>] [--quiet | --json]

Options:
  --project-path <path>  Target Specrew project (default: current directory)
  --feature <id>         Restrict lookup to one feature directory under specs\
  --iteration <NNN>      Replay a specific iteration directory
  --live                 Run the continuous co-review runtime and write .specrew\review\inline evidence
  --baseline-ref <ref>   Optional git ref/SHA baseline. Omit for a signoff run (auto-anchors
                         to the last pass or the merge-base with the trunk); supplying it
                         makes the run exploratory (it does not auto-anchor).
  --trunk <name>         Trunk branch the coverage anchor is the merge-base of (default: main)
  --checkpoint-id <id>   Stable checkpoint id for live evidence (default: manual-live-review)
  --run-id <id>          Stable run id for live evidence (default: run-<checkpoint-id>)
  --host <host>          Requested reviewer host, such as claude, codex, copilot, cursor-agent, or antigravity
  --model <model>        Requested reviewer model id for the host
  --effort <effort>      Optional host-specific reviewer reasoning/effort setting to persist in evidence
  --authorization-ref    Human-approved authorization reference for the requested reviewer
  --code-writer-host     Host that produced the implementation, used to prefer an independent reviewer
  --design-context-ref   Design/spec artifact to include in the request bundle; repeatable
  --allowed-path         Path scope the reviewer may inspect; repeatable
  --forbidden-path       Path scope the reviewer must not inspect; repeatable
  --exclude-path         Diff path pattern to exclude; repeatable
  --reviewer-config      JSON host catalog override for live review
  --schema-root          Reviewer contract schema directory override
  --run-root             Temporary immutable request-bundle workspace root
  --timeout-seconds      Reviewer host timeout in seconds (default: 120)
  --preserve-debug       Keep temporary request-bundle workspaces after live review
  --quiet                Emit only the stable machine-parseable digest line
  --json                 Emit JSON summary instead of the visual reviewer summary
  --open                 Open reviewer-index.md and review-diagrams.md when present
  --help                 Show this help message
'@ | Write-Host
}

function Convert-UnixStyleArguments {
    param(
        [string]$ProjectPath,
        [string]$FeatureId,
        [string]$IterationNumber,
        [bool]$Quiet,
        [bool]$Json,
        [bool]$Open,
        [bool]$Help,
        [string[]]$CliArgs
    )

    $result = [ordered]@{
        ProjectPath     = $ProjectPath
        FeatureId       = $FeatureId
        IterationNumber = $IterationNumber
        Quiet           = $Quiet
        Json            = $Json
        Open            = $Open
        Live            = $Live
        Help            = $Help
        BaselineRef     = $null
        TrunkName       = 'main'
        CheckpointId    = 'manual-live-review'
        RunId           = $null
        Host            = $null
        Model           = $null
        Effort          = $null
        AuthorizationRef = $null
        CodeWriterHost  = $null
        TimeoutSeconds  = 120
        FallbackPolicy  = 'none'
        ReviewerConfigPath = $null
        SchemaRoot      = $null
        RunRoot         = $null
        PreserveDebug   = $false
        DesignContextRefs = @()
        AllowedPaths    = @()
        ForbiddenPaths  = @()
        ExcludedPathPatterns = @()
    }

    $CliArgs = @($CliArgs | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
    for ($index = 0; $index -lt $CliArgs.Count; $index++) {
        $argument = $CliArgs[$index]
        switch -Regex ($argument) {
            '^--(?<name>baseline-ref|trunk|checkpoint-id|run-id|host|model|effort|authorization-ref|code-writer-host|fallback-policy|reviewer-config|schema-root|run-root|timeout-seconds|design-context-ref|allowed-path|forbidden-path|exclude-path)(?:=(?<value>.+))?$' {
                $name = $Matches['name']
                $value = $Matches['value']
                if ([string]::IsNullOrWhiteSpace($value)) {
                    $index++
                    if ($index -ge $CliArgs.Count) { throw "--$name requires a value." }
                    $value = $CliArgs[$index]
                }

                switch ($name) {
                    'baseline-ref' { $result.BaselineRef = $value }
                    'trunk' { $result.TrunkName = $value }
                    'checkpoint-id' { $result.CheckpointId = $value }
                    'run-id' { $result.RunId = $value }
                    'host' { $result.Host = $value }
                    'model' { $result.Model = $value }
                    'effort' { $result.Effort = $value }
                    'authorization-ref' { $result.AuthorizationRef = $value }
                    'code-writer-host' { $result.CodeWriterHost = $value }
                    'fallback-policy' { $result.FallbackPolicy = $value }
                    'reviewer-config' { $result.ReviewerConfigPath = $value }
                    'schema-root' { $result.SchemaRoot = $value }
                    'run-root' { $result.RunRoot = $value }
                    'timeout-seconds' { $result.TimeoutSeconds = [int]$value }
                    'design-context-ref' { $result.DesignContextRefs = @($result.DesignContextRefs) + @($value) }
                    'allowed-path' { $result.AllowedPaths = @($result.AllowedPaths) + @($value) }
                    'forbidden-path' { $result.ForbiddenPaths = @($result.ForbiddenPaths) + @($value) }
                    'exclude-path' { $result.ExcludedPathPatterns = @($result.ExcludedPathPatterns) + @($value) }
                }
            }
            '^--project-path(?:=(.+))?$' {
                if ($Matches[1]) {
                    $result.ProjectPath = $Matches[1]
                }
                else {
                    $index++
                    if ($index -ge $CliArgs.Count) { throw '--project-path requires a value.' }
                    $result.ProjectPath = $CliArgs[$index]
                }
            }
            '^--feature(?:=(.+))?$' {
                if ($Matches[1]) {
                    $result.FeatureId = $Matches[1]
                }
                else {
                    $index++
                    if ($index -ge $CliArgs.Count) { throw '--feature requires a value.' }
                    $result.FeatureId = $CliArgs[$index]
                }
            }
            '^--iteration(?:=(.+))?$' {
                if ($Matches[1]) {
                    $result.IterationNumber = $Matches[1]
                }
                else {
                    $index++
                    if ($index -ge $CliArgs.Count) { throw '--iteration requires a value.' }
                    $result.IterationNumber = $CliArgs[$index]
                }
            }
            '^--quiet$' { $result.Quiet = $true }
            '^--json$' { $result.Json = $true }
            '^--open$' { $result.Open = $true }
            '^--live$' { $result.Live = $true }
            '^--preserve-debug$' { $result.PreserveDebug = $true }
            '^(?:-h|--help)$' { $result.Help = $true }
            '^\d{3,}$' {
                if ([string]::IsNullOrWhiteSpace($result.IterationNumber)) {
                    $result.IterationNumber = $argument
                }
                else {
                    throw ("Unknown argument for specrew review: {0}" -f $argument)
                }
            }
            default { throw ("Unknown argument for specrew review: {0}" -f $argument) }
        }
    }

    return [pscustomobject]$result
}

function Resolve-LiveReviewSchemaRoot {
    param(
        [AllowNull()][string]$SchemaRoot,
        [AllowNull()][string]$ProjectRoot
    )

    if (-not [string]::IsNullOrWhiteSpace($SchemaRoot)) {
        return (Resolve-Path -LiteralPath $SchemaRoot).Path
    }

    if (-not [string]::IsNullOrWhiteSpace($ProjectRoot)) {
        $deployedCandidate = Join-Path $ProjectRoot '.specrew\review\contracts'
        if (Test-Path -LiteralPath $deployedCandidate -PathType Container) {
            return (Resolve-Path -LiteralPath $deployedCandidate).Path
        }
    }

    $candidate = Join-Path (Split-Path -Parent $PSScriptRoot) 'specs\197-continuous-co-review\contracts'
    if (Test-Path -LiteralPath $candidate -PathType Container) {
        return (Resolve-Path -LiteralPath $candidate).Path
    }

    return $null
}

function Get-LiveReviewConfiguration {
    param(
        [AllowNull()][string]$ReviewerConfigPath,
        [AllowNull()][string]$HostName,
        [AllowNull()][string]$Model,
        [AllowNull()][string]$AuthorizationRef,
        [int]$TimeoutSeconds,
        [string]$FallbackPolicy
    )

    if (-not [string]::IsNullOrWhiteSpace($ReviewerConfigPath)) {
        $resolvedPath = (Resolve-Path -LiteralPath $ReviewerConfigPath).Path
        return (Get-Content -LiteralPath $resolvedPath -Raw -Encoding UTF8 | ConvertFrom-Json -Depth 100)
    }

    if ($HostName -eq 'fixture') {
        return [pscustomobject][ordered]@{
            schema_version = '1.0'
            hosts          = @(
                [pscustomobject][ordered]@{
                    host              = 'fixture'
                    model             = if ([string]::IsNullOrWhiteSpace($Model)) { 'fixture-reviewer' } else { $Model }
                    adapter_id        = 'reviewer-host-adapter-fixture'
                    allowed           = $true
                    installed         = $true
                    review_class_rank = 100
                    model_source      = 'fixture'
                    cost_class        = 'free-local-fixture'
                    authorization_ref = if ([string]::IsNullOrWhiteSpace($AuthorizationRef)) { 'local-fixture-reviewer' } else { $AuthorizationRef }
                    fallback_allowed  = $false
                    timeout_seconds   = $TimeoutSeconds
                }
            )
        }
    }

    if ([string]::IsNullOrWhiteSpace($HostName) -and [string]::IsNullOrWhiteSpace($AuthorizationRef) -and [string]::IsNullOrWhiteSpace($Model)) {
        return $null
    }

    $configuration = New-ContinuousCoReviewDefaultReviewerHostConfig
    $hosts = @(
        foreach ($entry in @($configuration.hosts)) {
            $hostMatches = [string]::IsNullOrWhiteSpace($HostName) -or $entry.host -eq $HostName
            [pscustomobject][ordered]@{
                host              = $entry.host
                model             = if ($hostMatches -and -not [string]::IsNullOrWhiteSpace($Model)) { $Model } else { $entry.model }
                adapter_id        = $entry.adapter_id
                allowed           = if ($hostMatches -and -not [string]::IsNullOrWhiteSpace($AuthorizationRef)) { $true } else { [bool]$entry.allowed }
                installed         = [bool]$entry.installed
                review_class_rank = [int]$entry.review_class_rank
                model_source      = $entry.model_source
                cost_class        = $entry.cost_class
                authorization_ref = if ($hostMatches -and -not [string]::IsNullOrWhiteSpace($AuthorizationRef)) { $AuthorizationRef } else { $entry.authorization_ref }
                fallback_allowed  = if ($hostMatches -and $FallbackPolicy -ne 'none') { $true } else { [bool]$entry.fallback_allowed }
                timeout_seconds   = $TimeoutSeconds
            }
        }
    )

    return [pscustomobject][ordered]@{
        schema_version = '1.0'
        hosts          = @($hosts)
    }
}

function New-LiveReviewFixtureAdapter {
    param(
        [Parameter(Mandatory = $true)][string]$SchemaRoot
    )

    return {
        param($Candidate, $Request, $RequestBundle, [int]$AttemptNumber)

        $findingsResult = [pscustomobject][ordered]@{
            schema_version = '1.0'
            run_id         = $Request.run_id
            status         = 'no_findings'
            reviewer       = [pscustomobject][ordered]@{
                host       = $Candidate.host
                model      = $Candidate.model
                adapter_id = $Candidate.adapter_id
            }
            findings       = @()
            created_at     = $Request.created_at
        }

        return [pscustomobject][ordered]@{
            kind                   = 'findings-result'
            provider_invocation    = [pscustomobject][ordered]@{
                schema_version         = '1.0'
                invocation_id          = "invocation-$($Request.run_id)-fixture-$AttemptNumber"
                run_id                 = $Request.run_id
                attempt_number         = $AttemptNumber
                adapter_id             = $Candidate.adapter_id
                requested_host         = $Request.provider_request.requested_host
                requested_model        = $Request.provider_request.requested_model
                actual_host            = $Candidate.host
                actual_model           = $Candidate.model
                argv_summary           = @('fixture-reviewer', '--stdin-request-json')
                working_directory_ref  = '.specrew/review/inline'
                timeout_seconds        = [int]$Request.provider_request.timeout_seconds
                stdout_capture_policy  = 'parse-json-only'
                stderr_capture_policy  = 'status-only'
                exit_code              = 0
                failure_category       = $null
                started_at             = $Request.created_at
                ended_at               = $Request.created_at
            }
            findings_result        = $findingsResult
            infrastructure_failure = $null
        }
    }.GetNewClosure()
}

function Get-ObjectPropertyValue {
    param(
        [AllowNull()]$Object,
        [Parameter(Mandatory = $true)][string]$Name
    )

    if ($null -eq $Object) {
        return $null
    }

    $property = $Object.PSObject.Properties[$Name]
    if ($null -eq $property) {
        return $null
    }

    return $property.Value
}

function Invoke-LiveReview {
    param(
        [Parameter(Mandatory = $true)][string]$ProjectRoot,
        [Parameter(Mandatory = $true)][object]$Arguments
    )

    $loaderPath = Join-Path $PSScriptRoot 'internal\continuous-co-review\_load.ps1'
    if (-not (Test-Path -LiteralPath $loaderPath -PathType Leaf)) {
        throw "Missing continuous co-review runtime loader '$loaderPath'."
    }
    . $loaderPath

    # T068 (HOLE B): a signoff-bearing run AUTO-ANCHORS - when --baseline-ref is omitted the
    # baseline is forced to the last passing reviewed point (or, for the first review, the
    # merge-base with the trunk), so the gate's coverage chain reaches the trunk anchor. An
    # explicit --baseline-ref is an EXPLORATORY run that does not auto-anchor; such a run is
    # recorded but cannot satisfy the gate unless its chain independently reaches the anchor.
    $trunkName = if ([string]::IsNullOrWhiteSpace([string]$Arguments.TrunkName)) { 'main' } else { [string]$Arguments.TrunkName }
    $autoAnchor = [string]::IsNullOrWhiteSpace([string]$Arguments.BaselineRef)
    $resolvedBaselineRef = if (-not $autoAnchor) {
        [string]$Arguments.BaselineRef
    }
    else {
        $anchor = Get-ContinuousCoReviewMergeBaseAnchor -RepoRoot $ProjectRoot -TrunkName $trunkName
        if ([string]::IsNullOrWhiteSpace([string]$anchor)) { 'HEAD' } else { [string]$anchor }
    }

    $schemaRoot = Resolve-LiveReviewSchemaRoot -SchemaRoot $Arguments.SchemaRoot -ProjectRoot $ProjectRoot
    $providerRequest = [pscustomobject][ordered]@{
        requested_host    = if ([string]::IsNullOrWhiteSpace([string]$Arguments.Host)) { $null } else { [string]$Arguments.Host }
        requested_model   = if ([string]::IsNullOrWhiteSpace([string]$Arguments.Model)) { $null } else { [string]$Arguments.Model }
        requested_effort  = if ([string]::IsNullOrWhiteSpace([string]$Arguments.Effort)) { $null } else { [string]$Arguments.Effort }
        code_writer_host  = if ([string]::IsNullOrWhiteSpace([string]$Arguments.CodeWriterHost)) { $null } else { [string]$Arguments.CodeWriterHost }
        authorization_ref = if ([string]::IsNullOrWhiteSpace([string]$Arguments.AuthorizationRef)) { $null } else { [string]$Arguments.AuthorizationRef }
        timeout_seconds   = [int]$Arguments.TimeoutSeconds
        fallback_policy   = [string]$Arguments.FallbackPolicy
    }
    $reviewerConfiguration = Get-LiveReviewConfiguration -ReviewerConfigPath $Arguments.ReviewerConfigPath -HostName $Arguments.Host -Model $Arguments.Model -AuthorizationRef $Arguments.AuthorizationRef -TimeoutSeconds ([int]$Arguments.TimeoutSeconds) -FallbackPolicy ([string]$Arguments.FallbackPolicy)

    # A live review needs a reviewer. Refuse before computing a change-set or writing any
    # evidence, so a bare `specrew review --live` is a clean error (not a silent auto-anchored
    # run that pollutes .specrew/review). This replaces the former --baseline-ref-required
    # guard (T068 made --baseline-ref optional / auto-anchoring).
    if ($null -eq $reviewerConfiguration) {
        throw '--host (or --reviewer-config) is required for live review: live co-review needs a reviewer host/model.'
    }

    # T086 (145 iter-006): PERSIST the HUMAN authorization so the async navigator (auto-fire, no human in
    # the loop) can later select this host. ONLY on an explicit --host + --authorization-ref (the
    # human-provenance anchor) - never auto-persist, never agent self-authorize (the Proposal 190 hole).
    # Writes the built catalog config to .specrew/reviewer-hosts.json; the navigator reads it READ-ONLY.
    if ((-not [string]::IsNullOrWhiteSpace([string]$Arguments.Host)) -and (-not [string]::IsNullOrWhiteSpace([string]$Arguments.AuthorizationRef))) {
        try {
            $reviewerHostsPath = Join-Path $ProjectRoot '.specrew\reviewer-hosts.json'
            $reviewerHostsDir = Split-Path -Parent $reviewerHostsPath
            if (-not (Test-Path -LiteralPath $reviewerHostsDir)) { New-Item -ItemType Directory -Path $reviewerHostsDir -Force | Out-Null }
            ($reviewerConfiguration | ConvertTo-Json -Depth 100) | Set-Content -LiteralPath $reviewerHostsPath -Encoding UTF8
        }
        catch { $null = $_ }   # best-effort persistence; the live review itself still proceeds.
    }
    $runRoot = if ([string]::IsNullOrWhiteSpace([string]$Arguments.RunRoot)) { Join-Path $ProjectRoot '.specrew\review\tmp' } else { [string]$Arguments.RunRoot }
    $adapter = if ([string]$Arguments.Host -eq 'fixture') { New-LiveReviewFixtureAdapter -SchemaRoot $schemaRoot } else { $null }

    $invokeArguments = @{
        RepoRoot              = $ProjectRoot
        CheckpointId          = [string]$Arguments.CheckpointId
        BaselineRef           = $resolvedBaselineRef
        TrunkName             = $trunkName
        RunId                 = [string]$Arguments.RunId
        ProviderRequest       = $providerRequest
        DesignContextRefs     = [string[]]@($Arguments.DesignContextRefs)
        ReviewerConfiguration = $reviewerConfiguration
        SchemaRoot            = $schemaRoot
        RunRoot               = $runRoot
        ExcludedPathPatterns  = [string[]]@($Arguments.ExcludedPathPatterns)
        AllowedPaths          = [string[]]@($Arguments.AllowedPaths)
        ForbiddenPaths        = [string[]]@($Arguments.ForbiddenPaths)
        PreserveDebug         = [bool]$Arguments.PreserveDebug
    }
    if ($autoAnchor) {
        $invokeArguments.RebaselineToLastPass = $true
    }
    if ($null -ne $adapter) {
        $invokeArguments.InvokeAdapter = $adapter
    }

    return Invoke-ContinuousCoReviewCheckpointReview @invokeArguments
}

function ConvertTo-LiveReviewSummary {
    param(
        [Parameter(Mandatory = $true)]$Result,
        [Parameter(Mandatory = $true)][string]$ProjectRoot
    )

    $inlinePath = Join-Path $ProjectRoot (Join-Path '.specrew\review\inline' ([string]$Result.run_id))
    $relativeInlinePath = if (Test-Path -LiteralPath $inlinePath) { Get-RelativePath -FromDirectory $ProjectRoot -ToPath $inlinePath } else { ".specrew\review\inline\$($Result.run_id)" }
    $request = Get-ObjectPropertyValue -Object $Result -Name 'request'
    $changeSet = Get-ObjectPropertyValue -Object $Result -Name 'change_set'
    $gateVerdict = Get-ObjectPropertyValue -Object $Result -Name 'gate_verdict'
    $execution = Get-ObjectPropertyValue -Object $Result -Name 'execution'
    $infrastructureFailure = Get-ObjectPropertyValue -Object $Result -Name 'infrastructure_failure'
    $executionInfrastructureFailure = Get-ObjectPropertyValue -Object $execution -Name 'infrastructure_failure'
    $providerInvocation = Get-ObjectPropertyValue -Object $execution -Name 'provider_invocation'
    return [pscustomobject][ordered]@{
        mode                    = 'live'
        run_id                  = $Result.run_id
        checkpoint_id           = if ($gateVerdict) { $gateVerdict.checkpoint_id } else { $null }
        status                  = $Result.status
        gate_state              = if ($gateVerdict) { $gateVerdict.state } else { $null }
        baseline_ref            = if ($request) { $request.baseline_ref } elseif ($changeSet) { $changeSet.baseline_ref } else { $null }
        evidence_directory      = $relativeInlinePath
        requested_host          = if ($request) { $request.provider_request.requested_host } else { $null }
        actual_host             = if ($providerInvocation) { $providerInvocation.actual_host } else { $null }
        infrastructure_failure  = if ($infrastructureFailure) { $infrastructureFailure.category } elseif ($executionInfrastructureFailure) { $executionInfrastructureFailure.category } else { $null }
        blocking_finding_count  = if ($gateVerdict) { $gateVerdict.unresolved_blocking_count } else { $null }
    }
}

function Get-MetadataValue {
    param(
        [string]$Path,
        [string]$Label
    )

    $pattern = '(?m)^\*\*' + [regex]::Escape($Label) + '\*\*:\s*(?<value>.+?)\s*$'
    $match = [regex]::Match((Get-Content -LiteralPath $Path -Raw -Encoding UTF8), $pattern)
    if ($match.Success) {
        return $match.Groups['value'].Value.Trim()
    }

    return $null
}

function Get-MarkdownContent {
    param([string]$Path)

    return @(Get-Content -LiteralPath $Path -Encoding UTF8)
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

function Resolve-IterationDirectory {
    param(
        [string]$ProjectRoot,
        [AllowNull()][string]$FeatureId,
        [AllowNull()][string]$IterationNumber
    )

    $specsRoot = Join-Path $ProjectRoot 'specs'
    if (-not (Test-Path -LiteralPath $specsRoot -PathType Container)) {
        throw "Project does not contain a specs directory: $specsRoot"
    }

    $featureDirectories = @(
        if ($FeatureId) {
            Get-ChildItem -LiteralPath $specsRoot -Directory | Where-Object { $_.Name -eq $FeatureId }
        }
        else {
            Get-ChildItem -LiteralPath $specsRoot -Directory
        }
    )

    if ($featureDirectories.Count -eq 0) {
        throw 'No matching feature directories were found.'
    }

    $candidateIterations = New-Object System.Collections.Generic.List[object]
    foreach ($featureDirectory in $featureDirectories) {
        $iterationsRoot = Join-Path $featureDirectory.FullName 'iterations'
        if (-not (Test-Path -LiteralPath $iterationsRoot -PathType Container)) {
            continue
        }

        foreach ($iterationDirectory in @(Get-ChildItem -LiteralPath $iterationsRoot -Directory)) {
            if ($IterationNumber -and $iterationDirectory.Name -ne $IterationNumber) {
                continue
            }

            $reviewerIndexPath = Join-Path $iterationDirectory.FullName 'reviewer-index.md'
            $reviewPath = Join-Path $iterationDirectory.FullName 'review.md'
            if (-not (Test-Path -LiteralPath $reviewerIndexPath -PathType Leaf) -or -not (Test-Path -LiteralPath $reviewPath -PathType Leaf)) {
                continue
            }

            $reviewed = Get-MetadataValue -Path $reviewPath -Label 'Reviewed'
            $candidateIterations.Add([pscustomobject]@{
                    Feature   = $featureDirectory.Name
                    Iteration = $iterationDirectory.Name
                    Path      = $iterationDirectory.FullName
                    Reviewed  = $reviewed
                })
        }
    }

    if ($candidateIterations.Count -eq 0) {
        throw 'No completed iteration with reviewer artifacts was found.'
    }

    return @(
        $candidateIterations |
            Sort-Object -Property @(
                @{ Expression = { if ([string]::IsNullOrWhiteSpace($_.Reviewed)) { '0000-00-00' } else { $_.Reviewed } }; Descending = $true },
                @{ Expression = { $_.Iteration }; Descending = $true }
            ) |
            Select-Object -First 1
    )[0]
}

function Get-RelativePath {
    param(
        [Parameter(Mandatory = $true)]
        [string]$FromDirectory,

        [Parameter(Mandatory = $true)]
        [string]$ToPath
    )

    # System.IO.Path.GetRelativePath is cross-platform safe and uses the platform's
    # native separator. The previous [System.Uri] MakeRelativeUri approach failed on
    # Linux because bare absolute paths like "/home/user/foo" are not auto-recognized
    # as absolute URIs without a "file://" scheme.
    $fromFull = [System.IO.Path]::GetFullPath($FromDirectory)
    $toFull = [System.IO.Path]::GetFullPath($ToPath)
    return [System.IO.Path]::GetRelativePath($fromFull, $toFull)
}

function Try-OpenPath {
    param([string]$Path)

    try {
        Start-Process -FilePath $Path | Out-Null
        return $true
    }
    catch {
        return $false
    }
}

function Get-ReviewBoundarySyncWarning {
    param(
        [Parameter(Mandatory = $true)][string]$ProjectRoot,
        [Parameter(Mandatory = $true)][string]$ReviewPath
    )

    $warnings = [System.Collections.Generic.List[string]]::new()
    $reviewVerdict = Get-MetadataValue -Path $ReviewPath -Label 'Overall Verdict'
    $latestBoundary = Get-LatestSpecrewBoundarySyncState -ProjectRoot $ProjectRoot
    if ($reviewVerdict -match '^(?i)accepted$') {
        if ($null -eq $latestBoundary -or [string]$latestBoundary.boundary_type -notin @('review-signoff', 'retro', 'iteration-closeout', 'feature-closeout')) {
            $warnings.Add('WARN: Accepted review artifacts exist, but lifecycle state is not synced to review-signoff or a later boundary.') | Out-Null
        }
    }
    $requireStateFile = $null -eq $latestBoundary -or [string]$latestBoundary.boundary_type -notin @('retro', 'iteration-closeout', 'feature-closeout')

    $iterationDirectory = Split-Path -Parent $ReviewPath
    $iterationNumber = Split-Path -Leaf $iterationDirectory
    $featurePath = Split-Path -Parent (Split-Path -Parent $iterationDirectory)
    foreach ($issue in @(Get-SpecrewIterationStateTruthIssues -ProjectRoot $ProjectRoot -FeaturePath $featurePath -IterationNumber $iterationNumber -RequireStateFile:$requireStateFile)) {
        $warnings.Add(("WARN: {0}" -f $issue)) | Out-Null
    }

    if ($warnings.Count -eq 0) {
        return $null
    }

    return ($warnings.ToArray() -join [Environment]::NewLine)
}

$parsedArgs = Convert-UnixStyleArguments `
    -ProjectPath $ProjectPath `
    -FeatureId $FeatureId `
    -IterationNumber $IterationNumber `
    -Quiet $Quiet.IsPresent `
    -Json $Json.IsPresent `
    -Open $Open.IsPresent `
    -Live $Live.IsPresent `
    -Help $Help.IsPresent `
    -CliArgs $CliArgs

if (-not [string]::IsNullOrWhiteSpace($BaselineRef)) { $parsedArgs.BaselineRef = $BaselineRef }
if (-not [string]::IsNullOrWhiteSpace($Trunk)) { $parsedArgs.TrunkName = $Trunk }
if (-not [string]::IsNullOrWhiteSpace($CheckpointId)) { $parsedArgs.CheckpointId = $CheckpointId }
if (-not [string]::IsNullOrWhiteSpace($RunId)) { $parsedArgs.RunId = $RunId }
$boundHost = if (-not [string]::IsNullOrWhiteSpace($ReviewerHost)) { $ReviewerHost } else { $HostName }
if (-not [string]::IsNullOrWhiteSpace($boundHost)) { $parsedArgs.Host = $boundHost }
if (-not [string]::IsNullOrWhiteSpace($Model)) { $parsedArgs.Model = $Model }
if (-not [string]::IsNullOrWhiteSpace($AuthorizationRef)) { $parsedArgs.AuthorizationRef = $AuthorizationRef }
if (-not [string]::IsNullOrWhiteSpace($CodeWriterHost)) { $parsedArgs.CodeWriterHost = $CodeWriterHost }
if (-not [string]::IsNullOrWhiteSpace($FallbackPolicy)) { $parsedArgs.FallbackPolicy = $FallbackPolicy }
if (-not [string]::IsNullOrWhiteSpace($ReviewerConfigPath)) { $parsedArgs.ReviewerConfigPath = $ReviewerConfigPath }
if (-not [string]::IsNullOrWhiteSpace($SchemaRoot)) { $parsedArgs.SchemaRoot = $SchemaRoot }
if (-not [string]::IsNullOrWhiteSpace($RunRoot)) { $parsedArgs.RunRoot = $RunRoot }
if ($TimeoutSeconds -gt 0) { $parsedArgs.TimeoutSeconds = $TimeoutSeconds }
if (@($DesignContextRef).Count -gt 0) { $parsedArgs.DesignContextRefs = @($parsedArgs.DesignContextRefs) + @($DesignContextRef) }
if (@($AllowedPath).Count -gt 0) { $parsedArgs.AllowedPaths = @($parsedArgs.AllowedPaths) + @($AllowedPath) }
if (@($ForbiddenPath).Count -gt 0) { $parsedArgs.ForbiddenPaths = @($parsedArgs.ForbiddenPaths) + @($ForbiddenPath) }
if (@($ExcludePath).Count -gt 0) { $parsedArgs.ExcludedPathPatterns = @($parsedArgs.ExcludedPathPatterns) + @($ExcludePath) }
if ($PreserveDebug.IsPresent) { $parsedArgs.PreserveDebug = $true }

$ProjectPath = $parsedArgs.ProjectPath
$FeatureId = $parsedArgs.FeatureId
$IterationNumber = $parsedArgs.IterationNumber
$Quiet = [bool]$parsedArgs.Quiet
$Json = [bool]$parsedArgs.Json
$Open = [bool]$parsedArgs.Open
$Live = [bool]$parsedArgs.Live
$Help = [bool]$parsedArgs.Help

if ($Help) {
    Show-Usage
    exit 0
}

if ($Quiet -and $Json) {
    Write-Error 'Choose either --quiet or --json, not both.'
    exit 1
}

$resolvedProjectPath = Resolve-ProjectPath -Path $ProjectPath
if (-not (Test-Path -LiteralPath $resolvedProjectPath -PathType Container)) {
    Write-Error ("Project path does not exist: {0}" -f $resolvedProjectPath)
    exit 1
}

if ($Live) {
    # iter-008 (G1/G2/G3/G4/G6): when co_review_engine=worktree, the MANUAL door drives the SAME pipeline as the
    # navigator via the host-neutral co-review SERVICE - it AUTO-RESOLVES baseline/design-context/host (no
    # required --host/--design-context-ref), runs in a read-only worktree (not in-place), and shares the
    # deploy-aware resolver. DEFAULT = worktree; co_review_engine=legacy is the explicit opt-OUT to the original.
    $coReviewEngine = 'worktree'
    try {
        $cfgPath = Join-Path $resolvedProjectPath '.specrew/config.yml'
        if (Test-Path -LiteralPath $cfgPath -PathType Leaf) {
            foreach ($line in (Get-Content -LiteralPath $cfgPath -Encoding UTF8)) {
                if ($line -match '^\s*co_review_engine\s*:\s*([^#\r\n]+)') { $coReviewEngine = ($Matches[1].Trim().Trim([char]34).Trim([char]39)).ToLowerInvariant(); break }
            }
        }
    }
    catch { $null = $_ }

    if ($coReviewEngine -eq 'worktree') {
        try {
            . (Join-Path $PSScriptRoot 'internal/continuous-co-review/co-review-service.ps1')
            $tos = if ([int]$parsedArgs.TimeoutSeconds -gt 0) { [int]$parsedArgs.TimeoutSeconds } else { 900 }
            $run = Start-ContinuousCoReviewServiceRun -RepoRoot $resolvedProjectPath -RunId ([string]$parsedArgs.RunId) -BaselineRef ([string]$parsedArgs.BaselineRef) -CodeWriterHost ([string]$parsedArgs.CodeWriterHost) -TimeoutSeconds $tos
            $findings = Get-ContinuousCoReviewServiceFindings -RepoRoot $resolvedProjectPath -RunId $run.run_id
            $fc = if ($findings) { @($findings.findings).Count } else { 0 }
            $fstatus = if ($findings) { [string]$findings.status } else { '' }
            if ($Json) {
                [pscustomobject]@{ run_id = $run.run_id; engine = 'worktree'; status = $run.status; findings_status = $fstatus; findings_count = $fc; run_dir = $run.run_dir } | ConvertTo-Json -Depth 8
            }
            elseif ($Quiet) {
                Write-Host ("review-run run_id={0} engine=worktree status={1} findings={2}" -f $run.run_id, $run.status, $fc)
            }
            else {
                $border = ('=' * 60)
                Write-Host $border -ForegroundColor Green
                Write-Host 'SPECREW LIVE REVIEW (worktree engine)' -ForegroundColor Green
                Write-Host $border -ForegroundColor Green
                Write-Host ("Run: {0}" -f $run.run_id)
                Write-Host ("Status: {0}  Findings: {1} ({2})" -f $run.status, $fc, $fstatus)
                if ($findings -and $fc -gt 0) { foreach ($f in @($findings.findings)) { Write-Host ("  [{0}] {1} - {2}" -f $f.severity, $f.location.path, ([string]$f.comment)) } }
            }
        }
        catch { Write-Error $_.Exception.Message; exit 1 }
        exit 0
    }

    try {
        $liveResult = Invoke-LiveReview -ProjectRoot $resolvedProjectPath -Arguments $parsedArgs
        $summary = ConvertTo-LiveReviewSummary -Result $liveResult -ProjectRoot $resolvedProjectPath
    }
    catch {
        Write-Error $_.Exception.Message
        exit 1
    }

    if ($Json) {
        $summary | ConvertTo-Json -Depth 8
    }
    elseif ($Quiet) {
        Write-Host ("review-run run_id={0} status={1} gate={2} evidence={3}" -f $summary.run_id, $summary.status, $summary.gate_state, $summary.evidence_directory)
    }
    else {
        $border = ('=' * 60)
        Write-Host $border -ForegroundColor Green
        Write-Host 'SPECREW LIVE REVIEW' -ForegroundColor Green
        Write-Host $border -ForegroundColor Green
        Write-Host ("Run: {0}" -f $summary.run_id)
        Write-Host ("Checkpoint: {0}" -f $summary.checkpoint_id)
        Write-Host ("Status: {0}" -f $summary.status)
        Write-Host ("Gate: {0}" -f $summary.gate_state)
        Write-Host ("Evidence: {0}" -f $summary.evidence_directory)
        if (-not [string]::IsNullOrWhiteSpace([string]$summary.infrastructure_failure)) {
            Write-Host ("Infrastructure failure: {0}" -f $summary.infrastructure_failure)
        }
    }

    if ($Open) {
        $evidencePath = Join-Path $resolvedProjectPath $summary.evidence_directory
        if (-not (Try-OpenPath -Path $evidencePath)) {
            Write-Host ("Open manually: {0}" -f $evidencePath)
        }
    }

    exit 0
}

try {
    $selection = Resolve-IterationDirectory -ProjectRoot $resolvedProjectPath -FeatureId $FeatureId -IterationNumber $IterationNumber
}
catch {
    Write-Error $_.Exception.Message
    exit 1
}

$iterationDirectory = $selection.Path
$reviewPath = Join-Path $iterationDirectory 'review.md'
$reviewerIndexPath = Join-Path $iterationDirectory 'reviewer-index.md'
$reviewDiagramsPath = Join-Path $iterationDirectory 'review-diagrams.md'
$indexLines = @(Get-MarkdownContent -Path $reviewerIndexPath)
$summaryLines = @(Get-MarkdownSectionLines -Lines $indexLines -Heading 'Summary' | Where-Object { $_.Trim().StartsWith('- ') } | ForEach-Object { $_.Trim().Substring(2) })
$digestLines = @(Get-MarkdownSectionLines -Lines $indexLines -Heading 'Replay Digest' | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
$digestLine = if ($digestLines.Count -gt 0) {
    ($digestLines[0] -replace '^`|`$', '').Trim()
}
else {
    ''
}

$summary = [pscustomobject]@{
    feature          = $selection.Feature
    iteration        = $selection.Iteration
    reviewed         = Get-MetadataValue -Path $reviewPath -Label 'Reviewed'
    overall_verdict  = Get-MetadataValue -Path $reviewPath -Label 'Overall Verdict'
    reviewer_index   = Get-RelativePath -FromDirectory $resolvedProjectPath -ToPath $reviewerIndexPath
    review_diagrams  = if (Test-Path -LiteralPath $reviewDiagramsPath -PathType Leaf) { Get-RelativePath -FromDirectory $resolvedProjectPath -ToPath $reviewDiagramsPath } else { $null }
    summary_lines    = $summaryLines
    digest           = $digestLine
    cap_active       = if ($digestLine -match 'cap=active') { $true } else { $false }
    cap_chain        = if ($digestLine -match 'cap_chain=(\d+)/(\d+)') { "$($Matches[1])/$($Matches[2])" } else { $null }
    boundary_sync_warning = Get-ReviewBoundarySyncWarning -ProjectRoot $resolvedProjectPath -ReviewPath $reviewPath
}

if ($Json) {
    $summary | ConvertTo-Json -Depth 4
}
elseif ($Quiet) {
    if ([string]::IsNullOrWhiteSpace($digestLine)) {
        Write-Error 'reviewer-index.md does not contain a replay digest.'
        exit 1
    }
    Write-Host $digestLine
}
else {
    $border = ('=' * 60)
    Write-Host $border -ForegroundColor Green
    Write-Host 'SPECREW REVIEWER SUMMARY' -ForegroundColor Green
    Write-Host $border -ForegroundColor Green
    foreach ($line in $summaryLines) {
        Write-Host $line
    }
    if (-not [string]::IsNullOrWhiteSpace($digestLine)) {
        Write-Host ''
        Write-Host $digestLine
    }
    if (-not [string]::IsNullOrWhiteSpace([string]$summary.boundary_sync_warning)) {
        Write-Output $summary.boundary_sync_warning
    }
}

if ($Open) {
    $openedAny = $false
    foreach ($path in @($reviewerIndexPath, $reviewDiagramsPath)) {
        if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
            continue
        }
        if (Try-OpenPath -Path $path) {
            $openedAny = $true
        }
        else {
            Write-Host ("Open manually: {0}" -f $path)
        }
    }

    if (-not $openedAny -and -not (Test-Path -LiteralPath $reviewerIndexPath -PathType Leaf)) {
        Write-Host ("Open manually: {0}" -f $reviewerIndexPath)
        if (Test-Path -LiteralPath $reviewDiagramsPath -PathType Leaf) {
            Write-Host ("Open manually: {0}" -f $reviewDiagramsPath)
        }
    }
}

exit 0
