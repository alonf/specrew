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
  --ack-degraded <run-id>  Record a first-class human ack of DEGRADED review evidence (with --ack-reason)
  --ack-reason <text>    Why the degraded assurance level (partial/same-host) is acceptable for signoff
  --remediate <choice>   Record a review-problem remediation: more-time | different-host | narrow-scope |
                         accept-partial | override-block | resolved-against-disk | allowance-reset
                         (resolved-against-disk clears a fixed finding but PRESERVES spent rounds;
                         allowance-reset is the separate human-approved replenish of the round allowance)
  --scope <spec>         Human-directed scope for narrow-scope: code | process | path:<p> | function:<name>
  --fix-evidence-ref <c> Commit that resolves the held finding (required by --remediate resolved-against-disk)
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
        TrunkName       = ''   # '' -> the shared trunk resolver auto-detects (config/origin-HEAD/upstream/conventional); --trunk overrides
        CheckpointId    = 'manual-live-review'
        RunId           = $null
        Host            = $null
        Model           = $null
        Effort          = $null
        AuthorizationRef = $null
        CodeWriterHost  = $null
        TimeoutSeconds  = 0
        FallbackPolicy  = 'none'
        ReviewerConfigPath = $null
        SchemaRoot      = $null
        RunRoot         = $null
        PreserveDebug   = $false
        DesignContextRefs = @()
        AllowedPaths    = @()
        ForbiddenPaths  = @()
        ExcludedPathPatterns = @()
        AckDegradedRunId = $null
        AckReason       = $null
        Remediate       = $null
        Scope           = $null
        FixEvidenceRef  = $null
        TimeoutSecondsExplicit = $false
    }

    $CliArgs = @($CliArgs | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
    for ($index = 0; $index -lt $CliArgs.Count; $index++) {
        $argument = $CliArgs[$index]
        switch -Regex ($argument) {
            '^--(?<name>baseline-ref|trunk|checkpoint-id|run-id|host|model|effort|authorization-ref|code-writer-host|fallback-policy|reviewer-config|schema-root|run-root|timeout-seconds|design-context-ref|allowed-path|forbidden-path|exclude-path|remediate|scope|fix-evidence-ref)(?:=(?<value>.+))?$' {
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
                    'timeout-seconds' { $result.TimeoutSeconds = [int]$value; $result.TimeoutSecondsExplicit = $true }
                    'remediate' { $result.Remediate = $value }
                    'scope' { $result.Scope = $value }
                    'fix-evidence-ref' { $result.FixEvidenceRef = $value }
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
            '^--ack-degraded$' {
                $index++
                if ($index -ge $CliArgs.Count) { throw '--ack-degraded requires a run-id value.' }
                # Downstream field bug (2026-07-09): `--ack-degraded --ack-reason "..."` bound the NEXT FLAG
                # as the run-id and the orphaned reason text then read as an unknown argument - the agent
                # concluded the flag was "unsupported by the binary". A flag-shaped run-id is always a
                # missing-value mistake: say so precisely.
                if (([string]$CliArgs[$index]).StartsWith('--')) { throw ('--ack-degraded requires a run-id BEFORE other flags (got ''{0}''). Usage: specrew review --ack-degraded <run-id> --ack-reason "<why>"' -f $CliArgs[$index]) }
                $result.AckDegradedRunId = $CliArgs[$index]
            }
            '^--ack-reason$' {
                $index++
                if ($index -ge $CliArgs.Count) { throw '--ack-reason requires a value.' }
                $result.AckReason = $CliArgs[$index]
            }
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

# iter-008: ENGINE- and FEATURE-independent host AUTHORIZATION. `specrew review --host X --authorization-ref Y`
# persists the HUMAN authorization to .specrew/reviewer-hosts.json as a PROJECT-level operation - authorizing a
# reviewer is setup (often before the first feature), so it must NOT require a resolvable feature/checkpoint, and
# it must run regardless of the review engine. Done HERE, before the review arg + feature resolution, so it
# survives both the worktree-engine cutover (the write used to live in the now-bypassed legacy --live) and a
# no-feature project. ONLY on explicit --host + --authorization-ref (the human-provenance anchor).
$authHostName = if (-not [string]::IsNullOrWhiteSpace($ReviewerHost)) { $ReviewerHost } elseif (-not [string]::IsNullOrWhiteSpace($HostName)) { $HostName } else { '' }
$authRefValue = $AuthorizationRef; $authModelValue = $Model
$cliArgList = @($CliArgs)
for ($ai = 0; $ai -lt $cliArgList.Count; $ai++) {
    switch ([string]$cliArgList[$ai]) {
        '--host' { if (($ai + 1) -lt $cliArgList.Count) { $authHostName = [string]$cliArgList[$ai + 1] } }
        '--authorization-ref' { if (($ai + 1) -lt $cliArgList.Count) { $authRefValue = [string]$cliArgList[$ai + 1] } }
        '--model' { if (($ai + 1) -lt $cliArgList.Count) { $authModelValue = [string]$cliArgList[$ai + 1] } }
    }
}
if ((-not [string]::IsNullOrWhiteSpace($authHostName)) -and (-not [string]::IsNullOrWhiteSpace($authRefValue))) {
    $authWritten = $false
    $authError = $null
    $reviewerHostsPath = $null
    try {
        $authProjectPath = if ([string]::IsNullOrWhiteSpace($ProjectPath)) { (Get-Location).Path } else { (Resolve-Path -LiteralPath $ProjectPath -ErrorAction Stop).Path }
        . (Join-Path $PSScriptRoot 'internal/continuous-co-review/_load.ps1')   # for New-ContinuousCoReviewDefaultReviewerHostConfig
        $authConfig = Get-LiveReviewConfiguration -HostName $authHostName -Model $authModelValue -AuthorizationRef $authRefValue -TimeoutSeconds 0 -FallbackPolicy 'none'
        if ($null -ne $authConfig) {
            $reviewerHostsPath = Join-Path $authProjectPath '.specrew/reviewer-hosts.json'
            $rhDir = Split-Path -Parent $reviewerHostsPath
            if (-not (Test-Path -LiteralPath $rhDir)) { New-Item -ItemType Directory -Path $rhDir -Force | Out-Null }
            # Preserve EXISTING human authorizations: a fresh --host authorize must NOT drop a previously-authorized
            # host/fallback (Codex review P2). Re-apply any prior allowed+authorization_ref onto the fresh catalog
            # (the newly-authorized host is already set in $authConfig). Fail-safe: an unreadable prior file just
            # writes the fresh catalog rather than blocking the authorize.
            if (Test-Path -LiteralPath $reviewerHostsPath -PathType Leaf) {
                try {
                    $existingRh = Get-Content -LiteralPath $reviewerHostsPath -Raw -Encoding UTF8 | ConvertFrom-Json -Depth 100
                    $priorAuth = @{}
                    foreach ($eh in @($existingRh.hosts)) {
                        if ([bool]$eh.allowed -and -not [string]::IsNullOrWhiteSpace([string]$eh.authorization_ref)) { $priorAuth[[string]$eh.host] = $eh }
                    }
                    foreach ($nh in @($authConfig.hosts)) {
                        $nhName = [string]$nh.host
                        if (($nhName -ne $authHostName) -and $priorAuth.ContainsKey($nhName)) {
                            $prev = $priorAuth[$nhName]
                            $nh.allowed = $true
                            $nh.authorization_ref = [string]$prev.authorization_ref
                            if (-not [string]::IsNullOrWhiteSpace([string]$prev.model)) { $nh.model = [string]$prev.model }
                        }
                    }
                }
                catch { $null = $_ }
            }
            ($authConfig | ConvertTo-Json -Depth 100) | Set-Content -LiteralPath $reviewerHostsPath -Encoding UTF8
            $authWritten = $true
        }
        else { $authError = "Get-LiveReviewConfiguration returned no config for host '$authHostName'." }
    }
    catch { $authError = $_.Exception.Message }
    # A PURE authorize (--host + --authorization-ref, no --live review) is a project-SETUP op (often pre-first-feature,
    # at the code-implementation lens). Report the outcome HONESTLY and EXIT here - do NOT fall through to the replay
    # path (Resolve-IterationDirectory below), which throws at workshop time when no iteration folder exists yet (the
    # "wrote the selection, then looked for the iteration folder" failure). Detect --live from BOTH the -Live switch
    # AND --live in $CliArgs (this block runs BEFORE arg-parse), so an authorize+review combo still runs the review.
    # Honest exit code: never report success on a write that did not happen (else a failed authorize reads as authorized
    # and the navigator silently finds no host).
    $liveRequested = $Live.IsPresent -or (@($cliArgList) -contains '--live')
    if (-not $liveRequested) {
        if ($authWritten) {
            Write-Host ("Authorized reviewer host '{0}' (ref: {1}) -> {2}" -f $authHostName, $authRefValue, $reviewerHostsPath)
            exit 0
        }
        $authReason = if ([string]::IsNullOrWhiteSpace($authError)) { 'unknown error' } else { $authError }
        Write-Error ("Reviewer host authorization FAILED for '{0}': {1}" -f $authHostName, $authReason)
        exit 1
    }
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

# T094/FR-036: record the FIRST-CLASS human acknowledgement of degraded review evidence, then exit
# (a standalone op, like authorize). This human-typed command IS the trust boundary the gate's ack
# reader relies on - the recorded verdict lets a partial/same-host review satisfy signoff consciously.
if (-not [string]::IsNullOrWhiteSpace([string]$parsedArgs.AckDegradedRunId)) {
    try {
        . (Join-Path $PSScriptRoot 'internal/continuous-co-review/_load.ps1')
        if ([string]::IsNullOrWhiteSpace([string]$parsedArgs.AckReason)) {
            throw '--ack-degraded needs --ack-reason "<why this assurance level is acceptable>" (an ack is never implicit).'
        }
        $ackBy = (& git -C $resolvedProjectPath config user.name 2>$null)
        if ([string]::IsNullOrWhiteSpace([string]$ackBy)) { $ackBy = [string]$env:USERNAME }
        if ([string]::IsNullOrWhiteSpace([string]$ackBy)) { $ackBy = 'human' }
        $ack = Add-ContinuousCoReviewDegradedAck -RepoRoot $resolvedProjectPath -RunId ([string]$parsedArgs.AckDegradedRunId) -AuthorizedBy ([string]$ackBy).Trim() -Rationale ([string]$parsedArgs.AckReason)
        if ($Json) { $ack | ConvertTo-Json -Depth 6 }
        else { Write-Host ("degraded-evidence acknowledgement recorded for run {0} by {1}" -f $ack.run_id, $ack.authorized_by) -ForegroundColor Green }
        exit 0
    }
    catch { Write-Error $_.Exception.Message; exit 1 }
}

# T096/FR-038: record the human's remediation choice (the menu's carrier), then exit. The choice
# rides co-review-round-state.json and shapes the NEXT run (more-time/different-host/narrow-scope);
# accept-partial/override-block act immediately. This human-typed command is the trust boundary.
if (-not [string]::IsNullOrWhiteSpace([string]$parsedArgs.Remediate)) {
    try {
        . (Join-Path $PSScriptRoot 'internal/continuous-co-review/_load.ps1')
        $remediationAuthority = Get-ContinuousCoReviewAuthorityDecision
        if (-not $remediationAuthority.valid -or [string]$remediationAuthority.mode -eq 'disabled') {
            throw ("Review authority is unavailable ({0}); neither legacy nor campaign remediation may mutate review state." -f $remediationAuthority.reason)
        }
        if ([bool]$remediationAuthority.campaign_authority_enabled) {
            if ([string]$parsedArgs.Remediate -cne 'override-block') { throw "Campaign remediation '$($parsedArgs.Remediate)' does not create signoff authority; use a new explicitly authorized run." }
            if ([string]::IsNullOrWhiteSpace([string]$parsedArgs.RunId) -or [string]::IsNullOrWhiteSpace([string]$parsedArgs.AckReason)) {
                throw 'Campaign override-block requires --run-id and --ack-reason; the disposition is never implicit.'
            }
            $identity = Resolve-ReviewCampaignPublicIdentity -RepoRoot $resolvedProjectPath -FeatureId ([string]$FeatureId) -IterationNumber ([string]$IterationNumber) -RunId ([string]$parsedArgs.RunId)
            $actor = (& git -C $resolvedProjectPath config user.name 2>$null)
            if ([string]::IsNullOrWhiteSpace([string]$actor)) { $actor = [string]$env:USERNAME }
            if ([string]::IsNullOrWhiteSpace([string]$actor)) { $actor = 'human' }
            $store = Join-Path $resolvedProjectPath '.specrew/review/authority'
            $disposition = Add-ReviewCampaignHumanDisposition -StoreRoot $store -CampaignId $identity.campaign_id -RunId ([string]$parsedArgs.RunId) -Decision accept-current -AuthorizedBy ([string]$actor).Trim() -AuthorizationRef ("public-cli:override-block:{0}" -f $parsedArgs.RunId) -Rationale ([string]$parsedArgs.AckReason)
            if ($Json) { $disposition | ConvertTo-Json -Depth 10 }
            else { Write-Host ("campaign finding disposition recorded for run {0} by {1}" -f $parsedArgs.RunId, $actor) -ForegroundColor Green }
            exit 0
        }
        if (-not [bool]$remediationAuthority.legacy_promotion_enabled) { throw 'Review authority is not available for legacy remediation.' }
        . (Join-Path $PSScriptRoot 'internal/continuous-co-review/worktree-review-orchestrator.ps1')
        $remParams = @{ RepoRoot = $resolvedProjectPath; Choice = [string]$parsedArgs.Remediate }
        if ($parsedArgs.TimeoutSecondsExplicit) { $remParams.TimeoutSeconds = [int]$parsedArgs.TimeoutSeconds }
        if (-not [string]::IsNullOrWhiteSpace([string]$parsedArgs.Host)) { $remParams.HostName = [string]$parsedArgs.Host }
        if (-not [string]::IsNullOrWhiteSpace([string]$parsedArgs.Scope)) { $remParams.Scope = [string]$parsedArgs.Scope }
        if (-not [string]::IsNullOrWhiteSpace([string]$parsedArgs.RunId)) { $remParams.RunId = [string]$parsedArgs.RunId }
        if (-not [string]::IsNullOrWhiteSpace([string]$parsedArgs.AckReason)) { $remParams.Reason = [string]$parsedArgs.AckReason }
        if (-not [string]::IsNullOrWhiteSpace([string]$parsedArgs.FixEvidenceRef)) { $remParams.FixEvidenceRef = [string]$parsedArgs.FixEvidenceRef }
        $rem = Set-ContinuousCoReviewRemediationChoice @remParams
        if ($Json) { $rem | ConvertTo-Json -Depth 6 }
        else {
            $applied = if ([string]$rem.choice -in @('accept-partial', 'override-block', 'resolved-against-disk', 'allowance-reset')) { 'recorded and applied immediately' } else { 'recorded - it shapes the NEXT review run' }
            Write-Host ("remediation '{0}' {1} (by {2})" -f $rem.choice, $applied, $rem.authorized_by) -ForegroundColor Green
        }
        exit 0
    }
    catch { Write-Error $_.Exception.Message; exit 1 }
}

if ($Live) {
    # Resolve the singular authority seam without loading campaign/runtime modules into the
    # legacy command scope. The legacy timeout resolver depends on its historical load order.
    . (Join-Path $PSScriptRoot 'internal/continuous-co-review/review-authority-cutover.ps1')
    $authorityDecision = Get-ContinuousCoReviewAuthorityDecision
    if (-not $authorityDecision.valid -or [string]$authorityDecision.mode -eq 'disabled') {
        Write-Error ("Review authority is unavailable ({0}); neither legacy nor campaign review may run." -f $authorityDecision.reason)
        exit 1
    }

    # T051 / FR-057 / FR-065: the existing public surface delegates to exactly one authority path.
    # Campaign failure never falls back to the historical service, and the historical service never
    # promotes after campaign cutover. The checked-in mode stays legacy until T060's proved cutover.
    if ([bool]$authorityDecision.campaign_authority_enabled) {
        try {
            . (Join-Path $PSScriptRoot 'internal/continuous-co-review/_load.ps1')
            $resolvedBudget = if (Get-Command -Name 'Get-ContinuousCoReviewNavigatorTimeoutSeconds' -ErrorAction SilentlyContinue) { [int](Get-ContinuousCoReviewNavigatorTimeoutSeconds -RepoRoot $resolvedProjectPath -HostName ([string]$parsedArgs.Host)) } else { 900 }
            $tos = if ([int]$parsedArgs.TimeoutSeconds -gt 0) { [int]$parsedArgs.TimeoutSeconds } else { $resolvedBudget }
            $progressSink = $null
            if (-not $Json -and -not $Quiet) {
                $formatProgressCommand = Get-Command -Name 'Format-ReviewProgressEvent' -CommandType Function
                $progressSink = {
                    param($event)
                    $color = if ([string]$event.stage -in @('duplicate-warning', 'failed')) { 'Yellow' } elseif ([string]$event.stage -ceq 'terminal') { 'Cyan' } else { 'DarkGray' }
                    Write-Host (& $formatProgressCommand -Event $event) -ForegroundColor $color
                }.GetNewClosure()
            }
            $campaignRun = Invoke-ReviewCampaignCommand -RepoRoot $resolvedProjectPath -FeatureId ([string]$FeatureId) -IterationNumber ([string]$IterationNumber) `
                -RunId ([string]$parsedArgs.RunId) -ReviewerHost ([string]$parsedArgs.Host) -GrantAuthorizationRef ([string]$parsedArgs.AuthorizationRef) `
                -DesignContextRefs @($parsedArgs.DesignContextRefs) -TimeoutSeconds $tos -ProgressSink $progressSink
            if ($Json) { $campaignRun | ConvertTo-Json -Depth 30 }
            elseif ($Quiet) {
                $verdict = if ($null -ne $campaignRun.result) { [string]$campaignRun.result.verdict } else { 'none' }
                Write-Host ("review-run campaign={0} run_id={1} status={2} verdict={3} invoked={4} elapsed_ms={5} usage={6}" -f $campaignRun.campaign_id, $campaignRun.run_id, $campaignRun.status, $verdict, ([bool]$campaignRun.invoked).ToString().ToLowerInvariant(), $campaignRun.diagnostics.elapsed_ms, $campaignRun.diagnostics.usage.status)
            }
            else {
                $border = ('=' * 60)
                $color = if ($null -ne $campaignRun.result -and [bool]$campaignRun.result.can_approve_current) { 'Green' } else { 'Yellow' }
                Write-Host $border -ForegroundColor $color
                Write-Host 'SPECREW CAMPAIGN REVIEW' -ForegroundColor $color
                Write-Host $border -ForegroundColor $color
                Write-Host ("Campaign: {0}" -f $campaignRun.campaign_id)
                Write-Host ("Run: {0}  Status: {1}  Invoked: {2}" -f $campaignRun.run_id, $campaignRun.status, $campaignRun.invoked)
                if ($null -ne $campaignRun.result) {
                    Write-Host ("Verdict: {0}  Completion: {1}  Currentness: {2}  Can approve current: {3}" -f $campaignRun.result.verdict, $campaignRun.result.completion, $campaignRun.result.currentness, $campaignRun.result.can_approve_current)
                    if (-not [string]::IsNullOrWhiteSpace([string]$campaignRun.result.failure_reason)) { Write-Host ("Failure: {0}" -f $campaignRun.result.failure_reason) -ForegroundColor Yellow }
                    foreach ($finding in @($campaignRun.result.findings)) { Write-Host ("  [{0}] {1}: {2}" -f $finding.severity, $finding.title, $finding.description) }
                }
                else { Write-Host ("Reason: {0}" -f $campaignRun.reason) -ForegroundColor Yellow }
                $usage = $campaignRun.diagnostics.usage
                Write-Host ("Observed elapsed: {0:n1}s  Heartbeats: {1}  Usage: {2}" -f ([long]$campaignRun.diagnostics.elapsed_ms / 1000), $campaignRun.diagnostics.heartbeat_count, $usage.status)
                if ([string]$usage.status -ceq 'available') {
                    Write-Host ("Usage detail: input={0} output={1} total={2} cost_usd={3}" -f $usage.input_tokens, $usage.output_tokens, $usage.total_tokens, $usage.cost_usd)
                }
                Write-Host ("Authority store: {0}" -f $campaignRun.store_root)
            }
            if ([string]$campaignRun.status -cne 'terminal') { exit 1 }
            exit 0
        }
        catch { Write-Error $_.Exception.Message; exit 1 }
    }

    # Legacy diagnostic path retained only while the singular cutover seam says mode=legacy.
    $coReviewEngine = 'worktree'

    if ($coReviewEngine -eq 'worktree') {
        try {
            . (Join-Path $PSScriptRoot 'internal/continuous-co-review/co-review-service.ps1')
            # Budget resolution (F-198 FR-021/FR-022, supersedes the D-197-I010-006 flat default):
            # explicit --timeout-seconds wins (explicit-beats-config) -> project config -> catalog
            # per-host default -> the 600-second floor. When an explicit value UNDERCUTS what the
            # chain would resolve, warn AT RESOLUTION TIME so the operator sees the downgrade
            # before losing a review cycle to it.
            $resolvedBudget = if (Get-Command -Name 'Get-ContinuousCoReviewNavigatorTimeoutSeconds' -ErrorAction SilentlyContinue) { [int](Get-ContinuousCoReviewNavigatorTimeoutSeconds -RepoRoot $resolvedProjectPath -HostName ([string]$parsedArgs.Host)) } else { 600 }
            $tos = if ([int]$parsedArgs.TimeoutSeconds -gt 0) { [int]$parsedArgs.TimeoutSeconds } else { $resolvedBudget }
            if ([int]$parsedArgs.TimeoutSeconds -gt 0 -and [int]$parsedArgs.TimeoutSeconds -lt $resolvedBudget) {
                Write-Host ("[co-review] NOTE: your explicit budget ({0}s) is below the resolved budget for this setup ({1}s). Reviews here typically need the larger budget - a too-small one can end the review before it produces anything. If it gets cut short, ask me and I'll request your approval to re-run with the larger budget." -f [int]$parsedArgs.TimeoutSeconds, $resolvedBudget) -ForegroundColor Yellow
            }
            # T093/FR-035: an explicit `--host X --live` is a reviewer-host REQUEST for this run -
            # honoured (even same-host, labelled) or surfaced, never silently substituted.
            $run = Start-ContinuousCoReviewServiceRun -RepoRoot $resolvedProjectPath -RunId ([string]$parsedArgs.RunId) -BaselineRef ([string]$parsedArgs.BaselineRef) -CodeWriterHost ([string]$parsedArgs.CodeWriterHost) -RequestedHost ([string]$parsedArgs.Host) -TimeoutSeconds $tos
            $findings = Get-ContinuousCoReviewServiceFindings -RepoRoot $resolvedProjectPath -RunId $run.run_id
            $fc = if ($findings) { @($findings.findings).Count } else { 0 }
            $fstatus = if ($findings) { [string]$findings.status } else { '' }
            # FAIL LOUD: the inline run returns status='done' ONLY when the co-review actually ran. Any other status
            # (notably 'failed' / no-authorized-reviewer-host) is NOT a clean review - surface the reason + remediation
            # and exit NON-ZERO, so a caller cannot read an empty result as "reviewed, no findings" and substitute its
            # own review (the failure mode that let an unauthorized run get accepted on the Copilot dogfood).
            if ([string]$run.status -ne 'done') {
                $reason = if (($run.PSObject.Properties['failure_reason']) -and (-not [string]::IsNullOrWhiteSpace([string]$run.failure_reason))) { [string]$run.failure_reason } else { [string]$run.status }
                if ($Json) {
                    [pscustomobject]@{ run_id = $run.run_id; engine = 'worktree'; status = $run.status; failure_reason = $reason; ok = $false; run_dir = $run.run_dir } | ConvertTo-Json -Depth 8
                }
                else {
                    $rb = ('=' * 60)
                    Write-Host $rb -ForegroundColor Red
                    Write-Host 'SPECREW CO-REVIEW DID NOT RUN' -ForegroundColor Red
                    Write-Host $rb -ForegroundColor Red
                    Write-Host ("Run: {0}   Reason: {1}" -f $run.run_id, $reason)
                    if ($reason -match 'no-authorized-reviewer-host') {
                        Write-Host 'No reviewer host is authorized. Authorize one (independent of the code-writer):'
                        Write-Host '    specrew review --host <claude|codex|...> --authorization-ref <ref>'
                    }
                    elseif ($reason -match 'timeout|budget') {
                        # F-198 FR-022 teaching (consumer-legible, amended approval UX): the sanctioned
                        # next step is a bigger budget approved by the human - the assistant asks, the
                        # human approves, the assistant re-runs. Never runtime-state surgery.
                        Write-Host ("Inspect: {0}" -f $run.run_dir)
                        Write-Host ("This looks like a review budget kill ({0}s was not enough). Ask your assistant to request your approval for a longer budget and re-run - or raise co_review_timeout_seconds in .specrew/config.yml yourself. A plain re-run with the same budget will likely die the same way." -f $tos) -ForegroundColor Yellow
                    }
                    else { Write-Host ("Inspect: {0}" -f $run.run_dir) }
                    Write-Host 'Do NOT substitute another review for this - the co-review must run to produce gate evidence.' -ForegroundColor Yellow
                }
                exit 1
            }
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
                if ($run.PSObject.Properties['elapsed_seconds'] -and $null -ne $run.elapsed_seconds) {
                    Write-Host ("Elapsed: {0}s  Timeout: {1}s" -f $run.elapsed_seconds, $run.timeout_seconds)
                }
                if ($findings -and $fc -gt 0) {
                    foreach ($f in @($findings.findings)) {
                        # location.path is OPTIONAL per the FindingsResult schema (a salvage/harvest
                        # finding may be path-less) - render null-safe (StrictMode).
                        $floc = if (($null -ne $f.PSObject.Properties['location']) -and $null -ne $f.location -and ($null -ne $f.location.PSObject.Properties['path']) -and -not [string]::IsNullOrWhiteSpace([string]$f.location.path)) { [string]$f.location.path } else { '(no path)' }
                        Write-Host ("  [{0}] {1} - {2}" -f $f.severity, $floc, ([string]$f.comment))
                    }
                }
            }
            # HOST-NEUTRAL gate evidence: the detached reap promotes on a host whose Stop hook fires, but a
            # straight-through host (Copilot) never fires it - so THIS inline door (the F3 checkpoint) promotes through
            # the SAME canonical producer (Add-...PassRunRecord with the DIGEST), gated on the SAME affirmative-pass
            # decision the reap uses. Idempotent + fail-open: a later reap promotion of the same run is a no-op, and any
            # failure leaves the gate to block safely. Advisory-only (no promotion) on a non-affirmative verdict.
            try {
                # P1 (Codex review): a SCOPED live review (explicit --baseline-ref) is exploratory and must NOT
                # auto-anchor signoff evidence - the --live help says an explicit baseline does not auto-anchor.
                # Promoting it records the merge-base digest as if the whole feature were reviewed, letting a narrow
                # `--baseline-ref HEAD~1` satisfy review-signoff for earlier changes that were never co-reviewed.
                # Promote ONLY a signoff run (baseline OMITTED -> auto-anchored to the feature merge-base).
                $scopedExploratoryReview = -not [string]::IsNullOrWhiteSpace([string]$parsedArgs.BaselineRef)
                $verdict = ConvertFrom-ContinuousCoReviewNavigatorVerdict -ResultPath (Join-Path $run.run_dir 'result.out')
                $isPromotablePass = Test-ContinuousCoReviewVerdictIsPromotablePass -Verdict $verdict
                if ($isPromotablePass -and (-not $scopedExploratoryReview)) {
                    $digestId = if ($run.PSObject.Properties['reviewed_digest_tree_id']) { [string]$run.reviewed_digest_tree_id } else { '' }
                    if (-not [string]::IsNullOrWhiteSpace($digestId)) {
                        # T094/FR-036: carry the run's 3-dimension evidence labels onto the promoted record.
                        $doorLabels = [pscustomobject]@{ completeness = 'full'; independence = 'unverified'; budget = 'normal' }
                        try {
                            $doorStatusPath = Join-Path $run.run_dir 'status.json'
                            if (Test-Path -LiteralPath $doorStatusPath -PathType Leaf) {
                                $doorStatus = Get-Content -LiteralPath $doorStatusPath -Raw -Encoding UTF8 | ConvertFrom-Json
                                if (($doorStatus.PSObject.Properties.Name -contains 'completeness') -and -not [string]::IsNullOrWhiteSpace([string]$doorStatus.completeness)) { $doorLabels.completeness = [string]$doorStatus.completeness }
                                if (($doorStatus.PSObject.Properties.Name -contains 'reviewer_independence') -and -not [string]::IsNullOrWhiteSpace([string]$doorStatus.reviewer_independence)) { $doorLabels.independence = [string]$doorStatus.reviewer_independence }
                                if (($doorStatus.PSObject.Properties.Name -contains 'budget_bumped')) { try { if ([bool]$doorStatus.budget_bumped) { $doorLabels.budget = 'time-extended' } } catch { $null = $_ } }
                            }
                        }
                        catch { $null = $_ }
                        $promoted = Add-ContinuousCoReviewNavigatorPassRunRecord -RepoRoot $resolvedProjectPath -RunId $run.run_id -TreeId $digestId -EvidenceLabels $doorLabels -Now ([datetime]::UtcNow)
                        if ((-not [string]::IsNullOrWhiteSpace([string]$promoted)) -and (-not $Quiet) -and (-not $Json)) { Write-Host ("  promoted as co-review gate evidence (run {0})" -f $run.run_id) -ForegroundColor Green }
                    }
                }
                elseif ($isPromotablePass -and $scopedExploratoryReview -and (-not $Quiet) -and (-not $Json)) {
                    Write-Host ("  scoped review (--baseline-ref {0}) is exploratory - NOT promoted as signoff gate evidence." -f $parsedArgs.BaselineRef) -ForegroundColor Yellow
                }
            }
            catch { $null = $_ }
        }
        catch { Write-Error $_.Exception.Message; exit 1 }
        exit 0
    }

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
