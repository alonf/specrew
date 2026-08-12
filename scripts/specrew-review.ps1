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
    # T014. APPROVING A ROUND IS A DECISION, NOT AN IDENTIFIER.
    #
    # --authorization-ref accepts any non-empty string, nothing validates it, and its one real property
    # - reuse the same string and no new approval is spent - was never explained anywhere a consumer
    # reads. So there was nothing to know AND no way to discover there was nothing to know. The
    # maintainer, holding full context, could not work out what to type. The system was asking a human
    # to produce an identifier when what it needed was approval.
    #
    # This takes no value. The human's input is the APPROVAL; the identifier is filing, and filing is
    # the system's job. --authorization-ref stays for scripts and for anyone who wants to name their
    # own: a working interface is not removed to add a friendlier one.
    [Alias('approve-round')]
    [switch]$ApproveRound,
    # FR-003/FR-005. The human's numbered reply to a paused round, as the ONLY way a further round is
    # authorized. Accepts the number shown on the surface or the choice name behind it, because the
    # surface shows numbers and a consumer reading a transcript later has only the words.
    [Alias('pause-choice')]
    [ValidateSet('1', '2', '3', 'fix-and-continue', 'stop-here', 'abandon')]
    [string]$PauseChoice,
    [Alias('pause-rationale')]
    [string]$PauseRationale,
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
  specrew review --reconcile-run <run-id> [--feature <id>] [--iteration <NNN>] [--json]

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
  --approve-round        Approve one review round. Specrew records your approval and mints the
                         reference itself - there is no value to invent
  --pause-choice <1|2|3> Answer a review round that is waiting for your decision:
                         1 run another round, 2 stop here and complete sign-off, 3 abandon
  --pause-rationale      Optional note recorded with a stop-here answer
  --authorization-ref    Your own approval label, for scripts or an approval recorded elsewhere.
                         Requires --ack-reason saying where that approval came from
  --code-writer-host     Host that produced the implementation, used to prefer an independent reviewer
  --design-context-ref   Design/spec artifact to include in the request bundle; repeatable
  --allowed-path         Path scope the reviewer may inspect; repeatable
  --forbidden-path       Path scope the reviewer must not inspect; repeatable
  --exclude-path         Diff path pattern to exclude; repeatable
  --reviewer-config      JSON host catalog override for live review
  --schema-root          Reviewer contract schema directory override
  --run-root             External temporary workspace-root override (campaign snapshots must stay outside the repository)
  --timeout-seconds      Reviewer host timeout in seconds. Default: resolved per run -
                         co_review_timeout_seconds in .specrew\config.yml, else the
                         reviewer host's catalog default (codex/antigravity 900,
                         claude 600, copilot 300), else a 600-second floor
  --preserve-debug       Keep temporary request-bundle workspaces after live review
  --reconcile-run        Resume one interrupted campaign run without invoking a provider
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
        # Declared here, not only assigned when supplied. Reading an undeclared key off this object
        # under Set-StrictMode throws, and the throw surfaces as a generic renderer error that masks
        # whatever the command was actually reporting - which is exactly how three unrelated public
        # command tests went red on a pause field they never use.
        PauseChoice     = $null
        PauseRationale  = $null
        ApproveRound    = $false
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
        ReconcileRunId = $null
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
            '^--(?<name>baseline-ref|trunk|checkpoint-id|run-id|reconcile-run|host|model|effort|authorization-ref|code-writer-host|fallback-policy|reviewer-config|schema-root|run-root|timeout-seconds|design-context-ref|allowed-path|forbidden-path|exclude-path|remediate|scope|fix-evidence-ref)(?:=(?<value>.+))?$' {
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
                    'reconcile-run' { $result.ReconcileRunId = $value }
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
            '^--approve-round$' { $result.ApproveRound = $true }
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
function Set-ReviewerHostRowField {
    # Assign one field of one reviewer-host row. Adds the property when the existing document predates
    # it, because a bare `$row.name = value` throws on a PSCustomObject that lacks the property and the
    # surrounding catch would then fall back to rewriting the whole file - reintroducing exactly the
    # clobber this is here to prevent (DRIFT-198-I009-028).
    param(
        [Parameter(Mandatory = $true)]$Row,
        [Parameter(Mandatory = $true)][string]$Name,
        [Parameter(Mandatory = $true)][AllowNull()]$Value
    )
    if ($Row.PSObject.Properties[$Name]) { $Row.$Name = $Value }
    else { $Row | Add-Member -NotePropertyName $Name -NotePropertyValue $Value -Force }
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
            # Update ONE FIELD of ONE ROW, and leave the rest of the file exactly as it was.
            #
            # The earlier implementation serialized a FRESH DEFAULT catalog and copied only `allowed` /
            # `authorization_ref` / `model` back from prior rows that were BOTH allowed and authorized.
            # Three things followed. (1) Re-authorizing a host RESET its pinned model whenever --model
            # was omitted, destroying the reviewer-of-record provenance that review evidence cites.
            # (2) Every other field of every row - adapter_id, review_class_rank, model_source,
            # cost_class, installed, fallback_allowed, timeout_seconds - reverted to its default.
            # (3) Worst: a SUSPENDED row is `allowed:false`, so it was not preserved at all, and a
            # deliberate reviewer-INDEPENDENCE suspension recorded in its authorization_ref was
            # silently nulled - which could make a suspended host selectable again, the exact
            # violation the suspension existed to prevent. That is DRIFT-198-I009-028; it happened on
            # 2026-07-27, had to be repaired by hand, and made this very re-certification's
            # authorization reference unsafe to record through this path.
            #
            # Correct scope: start from the EXISTING document, set the addressed row's
            # authorization_ref, set its model ONLY when one was explicitly supplied, and touch
            # nothing else. Fail-safe unchanged: with no prior file (or an unreadable one) the fresh
            # catalog is the right content.
            $rhWroteInPlace = $false
            if (Test-Path -LiteralPath $reviewerHostsPath -PathType Leaf) {
                try {
                    $existingRh = Get-Content -LiteralPath $reviewerHostsPath -Raw -Encoding UTF8 | ConvertFrom-Json -Depth 100
                    $targetRow = $null
                    foreach ($eh in @($existingRh.hosts)) {
                        if ([string]$eh.host -ceq [string]$authHostName) { $targetRow = $eh; break }
                    }
                    if ($null -eq $targetRow) {
                        foreach ($eh in @($existingRh.hosts)) {
                            if ([string]::Equals([string]$eh.host, [string]$authHostName, [System.StringComparison]::OrdinalIgnoreCase)) { $targetRow = $eh; break }
                        }
                    }

                    if ($null -ne $targetRow) {
                        Set-ReviewerHostRowField -Row $targetRow -Name 'authorization_ref' -Value ([string]$authRefValue)
                        Set-ReviewerHostRowField -Row $targetRow -Name 'allowed' -Value $true
                        if (-not [string]::IsNullOrWhiteSpace($authModelValue)) {
                            Set-ReviewerHostRowField -Row $targetRow -Name 'model' -Value ([string]$authModelValue)
                        }
                        ($existingRh | ConvertTo-Json -Depth 100) | Set-Content -LiteralPath $reviewerHostsPath -Encoding UTF8
                        $rhWroteInPlace = $true
                    }
                    else {
                        # The addressed host has no row yet. APPEND the fresh catalog's row for it and
                        # keep every existing row as-is - never rebuild the file around it.
                        $freshRow = $null
                        foreach ($nh in @($authConfig.hosts)) {
                            if ([string]::Equals([string]$nh.host, [string]$authHostName, [System.StringComparison]::OrdinalIgnoreCase)) { $freshRow = $nh; break }
                        }
                        if ($null -ne $freshRow) {
                            $existingRh.hosts = @(@($existingRh.hosts) + @($freshRow))
                            ($existingRh | ConvertTo-Json -Depth 100) | Set-Content -LiteralPath $reviewerHostsPath -Encoding UTF8
                            $rhWroteInPlace = $true
                        }
                    }
                }
                catch { $rhWroteInPlace = $false }
            }
            if (-not $rhWroteInPlace) {
                ($authConfig | ConvertTo-Json -Depth 100) | Set-Content -LiteralPath $reviewerHostsPath -Encoding UTF8
            }
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
if ($ApproveRound.IsPresent) { $parsedArgs.ApproveRound = $true }
if (-not [string]::IsNullOrWhiteSpace($PauseChoice)) { $parsedArgs.PauseChoice = $PauseChoice }
if (-not [string]::IsNullOrWhiteSpace($PauseRationale)) { $parsedArgs.PauseRationale = $PauseRationale }
if (-not [string]::IsNullOrWhiteSpace($CodeWriterHost)) { $parsedArgs.CodeWriterHost = $CodeWriterHost }
if (-not [string]::IsNullOrWhiteSpace($FallbackPolicy)) { $parsedArgs.FallbackPolicy = $FallbackPolicy }
if (-not [string]::IsNullOrWhiteSpace($ReviewerConfigPath)) { $parsedArgs.ReviewerConfigPath = $ReviewerConfigPath }
if (-not [string]::IsNullOrWhiteSpace($SchemaRoot)) { $parsedArgs.SchemaRoot = $SchemaRoot }
if (-not [string]::IsNullOrWhiteSpace($RunRoot)) { $parsedArgs.RunRoot = $RunRoot }
if ($TimeoutSeconds -gt 0) { $parsedArgs.TimeoutSeconds = $TimeoutSeconds }
$boundDesignContextRefs = @($DesignContextRef | Where-Object { -not [string]::IsNullOrWhiteSpace([string]$_) })
$boundAllowedPaths = @($AllowedPath | Where-Object { -not [string]::IsNullOrWhiteSpace([string]$_) })
$boundForbiddenPaths = @($ForbiddenPath | Where-Object { -not [string]::IsNullOrWhiteSpace([string]$_) })
$boundExcludedPaths = @($ExcludePath | Where-Object { -not [string]::IsNullOrWhiteSpace([string]$_) })
if ($boundDesignContextRefs.Count -gt 0) { $parsedArgs.DesignContextRefs = @($parsedArgs.DesignContextRefs) + $boundDesignContextRefs }
if ($boundAllowedPaths.Count -gt 0) { $parsedArgs.AllowedPaths = @($parsedArgs.AllowedPaths) + $boundAllowedPaths }
if ($boundForbiddenPaths.Count -gt 0) { $parsedArgs.ForbiddenPaths = @($parsedArgs.ForbiddenPaths) + $boundForbiddenPaths }
if ($boundExcludedPaths.Count -gt 0) { $parsedArgs.ExcludedPathPatterns = @($parsedArgs.ExcludedPathPatterns) + $boundExcludedPaths }
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
$installedReviewEngineRoot = Join-Path $PSScriptRoot 'internal/continuous-co-review'
$reviewEngineRoot = $installedReviewEngineRoot
$requiresReviewEngine = $Live -or
    (-not [string]::IsNullOrWhiteSpace([string]$parsedArgs.ReconcileRunId)) -or
    (-not [string]::IsNullOrWhiteSpace([string]$parsedArgs.AckDegradedRunId)) -or
    (-not [string]::IsNullOrWhiteSpace([string]$parsedArgs.Remediate))
if ($requiresReviewEngine) {
    $engineResolverPath = Join-Path $PSScriptRoot 'internal/review-engine-resolution.ps1'
    if (-not (Test-Path -LiteralPath $engineResolverPath -PathType Leaf)) {
        Write-Error "Review engine resolver is missing: $engineResolverPath"
        exit 1
    }
    . $engineResolverPath
    try {
        $reviewEngineSelection = Resolve-SpecrewReviewEngineRoot -ProjectRoot $resolvedProjectPath -InstalledRuntimeRoot $installedReviewEngineRoot
        $reviewEngineRoot = [string]$reviewEngineSelection.runtime_root
    }
    catch {
        Write-Error $_.Exception.Message
        exit 1
    }
}

# FR-062: restart reconciliation is a first-class public operation. It never grants or
# invokes a provider; it only executes the immutable plan for one already-recorded run.
if (-not [string]::IsNullOrWhiteSpace([string]$parsedArgs.ReconcileRunId)) {
    try {
        . (Join-Path $reviewEngineRoot '_load.ps1')
        $authority = Get-ContinuousCoReviewAuthorityDecision
        if (-not $authority.valid -or -not [bool]$authority.campaign_authority_enabled) { throw ('review-reconciliation-requires-campaign-authority:' + $authority.reason) }
        $identity = Resolve-ReviewCampaignPublicIdentity -RepoRoot $resolvedProjectPath -FeatureId ([string]$FeatureId) -IterationNumber ([string]$IterationNumber) -RunId ([string]$parsedArgs.ReconcileRunId)
        $timeout = if ([int]$parsedArgs.TimeoutSeconds -gt 0) { [int]$parsedArgs.TimeoutSeconds } else { 900 }
        $store = Join-Path $resolvedProjectPath '.specrew/review/authority'
        $target = New-ReviewCampaignTargetPort -RepoRoot $resolvedProjectPath -RequestedRoot ([string]$parsedArgs.RunRoot)
        $runtime = New-ReviewProductionRuntimePort -TimeoutSeconds $timeout
        $reconciled = Invoke-ReviewRunReconciliation -StoreRoot $store -CampaignId $identity.campaign_id -RunId $identity.run_id `
            -TargetLineage $identity.target_lineage -TargetPort $target -RuntimePort $runtime -ClockPort (New-ReviewSystemClockPort)
        if ($Json) { $reconciled | ConvertTo-Json -Depth 30 }
        else {
            Write-Host ("review-reconciliation campaign={0} run_id={1} status={2} reason={3}" -f $identity.campaign_id, $identity.run_id, $reconciled.status, $reconciled.reason)
            if ($null -ne $reconciled.result) { Write-Host ("verdict={0} completion={1} runtime_outcome={2}" -f $reconciled.result.verdict, $reconciled.result.completion, $reconciled.result.runtime_outcome) }
        }
        if ([string]$reconciled.status -notin @('complete', 'terminal')) { exit 1 }
        exit 0
    }
    catch { Write-Error $_.Exception.Message; exit 1 }
}

# T094/FR-036: record the FIRST-CLASS human acknowledgement of degraded review evidence, then exit
# (a standalone op, like authorize). This human-typed command IS the trust boundary the gate's ack
# reader relies on - the recorded verdict lets a partial/same-host review satisfy signoff consciously.
if (-not [string]::IsNullOrWhiteSpace([string]$parsedArgs.AckDegradedRunId)) {
    try {
        . (Join-Path $reviewEngineRoot '_load.ps1')
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
        . (Join-Path $reviewEngineRoot '_load.ps1')
        $remediationAuthority = Get-ContinuousCoReviewAuthorityDecision
        if (-not $remediationAuthority.valid -or [string]$remediationAuthority.mode -eq 'disabled') {
            throw ("Review authority is unavailable ({0}); neither legacy nor campaign remediation may mutate review state." -f $remediationAuthority.reason)
        }
        if ([bool]$remediationAuthority.campaign_authority_enabled) {
            # ALLOWANCE-RESET IS THE CEILING'S OWN ADVERTISED WAY OUT, and campaign authority used to
            # reject it - so the exhausted-budget message named a command that could not run, and a
            # consumer who reached the ceiling was permanently wedged. Round 4 found this by RUNNING
            # into the ceiling rather than around it.
            #
            # It does NOT create signoff authority, which is why the old blanket refusal existed and why
            # that reasoning was right about override-block. It creates ROUND allowance: permission to
            # run more reviews, not permission to skip one. Those are different powers and only one of
            # them is being granted here.
            #
            # It still demands explicit human evidence - a reason, in the human's own words - because
            # lifting a spend limit is exactly the act that must never be implicit.
            if ([string]$parsedArgs.Remediate -ceq 'allowance-reset') {
                if ([string]::IsNullOrWhiteSpace([string]$parsedArgs.AckReason)) {
                    Write-Host 'Topping up the review rounds needs a reason recorded with it.' -ForegroundColor Yellow
                    Write-Host ''
                    Write-Host 'Run:  specrew review --remediate allowance-reset --ack-reason "why this review needs more rounds"' -ForegroundColor Cyan
                    exit 1
                }
                $resetIdentity = Resolve-ReviewCampaignPublicIdentity -RepoRoot $resolvedProjectPath -FeatureId ([string]$FeatureId) -IterationNumber ([string]$IterationNumber) -RunId ([string]$parsedArgs.RunId)
                $resetActor = (& git -C $resolvedProjectPath config user.name 2>$null)
                if ([string]::IsNullOrWhiteSpace([string]$resetActor)) { $resetActor = [string]$env:USERNAME }
                if ([string]::IsNullOrWhiteSpace([string]$resetActor)) { $resetActor = 'human' }
                $resetFact = New-ReviewCampaignBudgetResetFact -CampaignId $resetIdentity.campaign_id `
                    -AuthorizedBy ([string]$resetActor) -Reason ([string]$parsedArgs.AckReason) `
                    -ObservedAt ([DateTimeOffset]::UtcNow.ToString('o'))
                Write-ReviewCampaignBudgetResetFact -StoreRoot (Join-Path $resolvedProjectPath '.specrew/review/authority') -Fact $resetFact | Out-Null
                # THE RESET MUST ALSO UNWEDGE THE ROUND IT WAS CALLED FOR. Round 5, blocking: recording
                # the fact alone left the exhausted round's pause UNANSWERED, so the very next command -
                # the one this message names - was refused with `pause-decision-pending`, and the
                # resumed surface still omitted option 1 because its immutable pause fact says 4 of 4.
                # The advertised recovery stayed wedged unless the consumer guessed an extra step nobody
                # offered. Topping up the allowance IS the choice to continue, so the outstanding pause
                # is answered as `fix-and-continue` in the same act.
                $resetStore = Join-Path $resolvedProjectPath '.specrew/review/authority'
                $outstandingAtReset = Get-ReviewCampaignPendingPause -StoreRoot $resetStore -CampaignId $resetIdentity.campaign_id
                if ($null -ne $outstandingAtReset) {
                    Write-ReviewCampaignPauseDecisionFact -StoreRoot $resetStore -Fact (
                        New-ReviewCampaignPauseDecisionFact -CampaignId $resetIdentity.campaign_id `
                            -RunId ([string](Get-ReviewAuthorityProperty -Object $outstandingAtReset -Name 'run_id')) `
                            -Choice 'fix-and-continue' -ObservedAt ([DateTimeOffset]::UtcNow.ToString('o'))) | Out-Null
                }
                if ($Json) { $resetFact | ConvertTo-Json -Depth 10; exit 0 }
                Write-Host 'Your review rounds are topped up. The rounds already run stay on the record; they no longer count against your allowance.' -ForegroundColor Green
                Write-Host ''
                Write-Host 'Run the next review with:  specrew review --live --approve-round' -ForegroundColor Cyan
                exit 0
            }
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
        . (Join-Path $reviewEngineRoot 'worktree-review-orchestrator.ps1')
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
    . (Join-Path $reviewEngineRoot 'review-authority-cutover.ps1')
    $authorityDecision = Get-ContinuousCoReviewAuthorityDecision
    if (-not $authorityDecision.valid -or [string]$authorityDecision.mode -eq 'disabled') {
        Write-Error ("Review authority is unavailable ({0}); neither legacy nor campaign review may run." -f $authorityDecision.reason)
        exit 1
    }

    # T051 / FR-057 / FR-065: the existing public surface delegates to exactly one authority path.
    # Campaign failure never falls back to the historical service, and the historical service never
    # promotes after campaign cutover. T060 persisted the disabled barrier and then activated the
    # checked-in campaign mode; the legacy branch below remains only for historical configurations.
    if ([bool]$authorityDecision.campaign_authority_enabled) {
        try {
            . (Join-Path $reviewEngineRoot '_load.ps1')
            # A project-level `specrew review --host ... --authorization-ref ...` records the
            # human grant in reviewer-hosts.json. Normal campaign runs must reload that exact
            # selected entry; otherwise the public command drops the reference and reaches the
            # authority store with no allowance. An explicit per-run reference remains highest
            # precedence. Reusing a persisted reference is safe: campaign authority derives one
            # immutable one-slot grant id from it and never mints another slot for a later run.
            $campaignHost = [string]$parsedArgs.Host
            $campaignModel = [string]$parsedArgs.Model
            $campaignGrantAuthorizationRef = [string]$parsedArgs.AuthorizationRef

            # AN AUTHORIZATION THE HUMAN DID NOT GIVE FOR *THIS* ACT MUST NOT LOOK LIKE ONE THEY DID.
            #
            # Measured on both dogfood runs. Each agent passed the reviewer-HOST authorization reference
            # minted during the design workshop as the campaign GRANT reference:
            #
            #   mdlink           workshop-001-md-link-checker        -> slots=1 kind=human
            #   mdlinkValidator  workshop-001-markdown-link-checker  -> slots=1 kind=human
            #
            # The human approved WHICH HOST MAY REVIEW. The ledger then recorded that a human authorized
            # THIS SPEND against THIS CODE. Any string reaching --authorization-ref became a kind=human
            # grant and nothing checked what it had been minted for.
            #
            # Same rule as the authorization writer, one layer over: --approve-round is the sanctioned
            # path and needs no declaration, because the human performed the approving act at the moment
            # of the run. A hand-supplied reference is out-of-band by definition - the human may well
            # have approved something, but not necessarily THIS round - so it must be declared, exactly
            # as an agent-invoked boundary authorization must.
            # VALIDATION BEFORE AUTHORIZATION (maintainer ruling 2026-08-12). When a request is BOTH
            # malformed and unauthorized, report the MALFORMATION first: it is the thing the human can
            # fix in the next keystroke, while getting authorization may involve another person, another
            # session, or a decision they have to think about. Reporting the permission failure first
            # sends them off to obtain approval and then straight into the validation error they could
            # have fixed immediately - the same cost as naming the wrong one of three host conditions.
            #
            # The usual counter-argument (do not reveal request shape to an unauthorized caller) is a
            # network-service concern; this is a local CLI whose caller already holds the filesystem.
            #
            # So the declaration refusal is SKIPPED when the request will not survive its own validation:
            # the command below reports the malformation, and the human meets the authorization question
            # only once the request is well-formed.
            $requestWellFormed = $true
            try {
                $designPrecheck = Resolve-ContinuousCoReviewDesignContextSelection -RepoRoot $resolvedProjectPath `
                    -DesignContextFiles @($parsedArgs.DesignContextRefs) -FeatureId ([string]$FeatureId)
                $requestWellFormed = [bool]$designPrecheck.valid
            }
            catch { $requestWellFormed = $true }

            if ($requestWellFormed -and
                -not [string]::IsNullOrWhiteSpace($campaignGrantAuthorizationRef) -and
                [string]::IsNullOrWhiteSpace([string]$parsedArgs.AckReason)) {
                Write-Host 'That authorization reference was not created by approving this review round.' -ForegroundColor Yellow
                Write-Host ''
                Write-Host 'If you want to approve a round now, use:  specrew review --live --approve-round' -ForegroundColor Cyan
                Write-Host ''
                Write-Host 'If you are deliberately supplying your own label - a scripted run, or an approval you recorded elsewhere -'
                Write-Host 'say what it is, and Specrew will record it as such rather than as a round you approved here:'
                Write-Host '  specrew review --live --authorization-ref <label> --ack-reason "where this approval came from"' -ForegroundColor Cyan
                exit 1
            }
            # PRECEDENCE: an explicit --authorization-ref wins, then --approve-round, then whatever the
            # project has on file.
            #
            # The config fallback must NOT pre-empt --approve-round, and the first version of T014 let
            # it: the engine writes the last used reference back into .specrew/reviewer-hosts.json, so
            # after a round that row holds a SPENT reference. Reusing it mints no new slot, and
            # --approve-round - an explicit human act, performed deliberately - would have silently done
            # nothing. Found by preparing to run the next round in this very repo, where the row already
            # read `beta3-i001-signoff-round-3`.
            #
            # A RECORDED VALUE MUST NEVER OUTRANK AN ACT PERFORMED NOW. That is the same shape as the
            # consent gate: what is on file describes the past, and the human is deciding in the present.
            if ([string]::IsNullOrWhiteSpace($campaignGrantAuthorizationRef) -and -not [bool]$parsedArgs.ApproveRound) {
                $configuredReviewer = Resolve-ContinuousCoReviewConfiguredReviewerCandidate -RepoRoot $resolvedProjectPath `
                    -ReviewerConfigPath ([string]$parsedArgs.ReviewerConfigPath) -RequestedHost $campaignHost `
                    -RequestedModel $campaignModel -CodeWriterHost ([string]$parsedArgs.CodeWriterHost)
                if ($null -ne $configuredReviewer) {
                    if ([string]::IsNullOrWhiteSpace($campaignHost)) { $campaignHost = [string]$configuredReviewer.host }
                    # The catalog/config `model` is a DECLARATION of what the selected host runs
                    # (rows legitimately read 'configured-by-user' or 'gpt-5.5-or-claude-4.8'), never a
                    # per-run CLI override. Promoting it into the harness override made every host whose
                    # file-primary constructor takes no -Model fail at preflight with
                    # production-harness-model-override-unsupported, so a project that recorded a
                    # reviewer model - the state `--host X --authorization-ref Y` itself writes - could
                    # not run a campaign review at all. Only an explicit --model request is an override.
                    $campaignGrantAuthorizationRef = [string]$configuredReviewer.authorization_ref
                }
            }

            # T014: --approve-round MINTS THE REFERENCE. The human supplied the decision; the string is
            # filing, and filing is the system's job.
            #
            # Derived from the campaign and the round position rather than from a clock or a random
            # value, so it is STABLE for one round: re-running the same approved round reuses the same
            # one-slot grant instead of minting a second. That is the property --authorization-ref
            # always had and never explained - here it is a consequence of how the string is built,
            # which nobody has to be told.
            #
            # An explicit --authorization-ref still wins, untouched.
            $approvalMinted = $false
            if ([string]::IsNullOrWhiteSpace($campaignGrantAuthorizationRef) -and [bool]$parsedArgs.ApproveRound) {
                $approvalIdentity = Resolve-ReviewCampaignPublicIdentity -RepoRoot $resolvedProjectPath `
                    -FeatureId ([string]$FeatureId) -IterationNumber ([string]$IterationNumber) -RunId ([string]$parsedArgs.RunId)
                # THE ROUND NUMBER IS ROUNDS ALREADY RUN, NOT APPROVALS ALREADY MINTED.
                #
                # The first version counted grants, so approving the same round twice minted a SECOND
                # approval - destroying the very property this was meant to make automatic. Counting
                # INVOKED rounds keeps the reference stable until a round actually runs, so re-approving
                # before running reuses the one already recorded. Caught by the fixture that asserts
                # approving twice leaves one grant.
                #
                # The invoked filter is FR-014's, reused so a round that never reached a reviewer does
                # not advance the number - the same discriminator the continuation counter uses.
                $roundsRun = 0
                try {
                    $roundsRun = @(Get-ReviewAuthorityCampaignRunResults -StoreRoot (Join-Path $resolvedProjectPath '.specrew/review/authority') `
                            -CampaignId $approvalIdentity.campaign_id |
                            Where-Object { [string](Get-ReviewAuthorityProperty -Object $_ -Name 'runtime_outcome') -notin @('preflight-failed', 'claim-contended', 'launch-failed') }).Count
                }
                catch { $roundsRun = 0 }
                $campaignGrantAuthorizationRef = '{0}-round-{1}' -f $approvalIdentity.campaign_id, ($roundsRun + 1)
                $approvalMinted = $true
            }

            # NEITHER GIVEN, AND A ROUND NEEDS ONE: say THAT, and name the command. This is the sentence
            # whose absence sent the maintainer looking for a value to invent.
            # ANSWERING A PAUSE IS NOT RUNNING A ROUND. Found by the end-to-end walk on a fresh install,
            # after every fixture passed: `--pause-choice 2` - stop here - was refused for lack of
            # APPROVAL, so a human declining to spend was asked to authorize the spend they were
            # declining. Same for 3, abandon. Only option 1 leads to a round, and it falls through to the
            # approval check below on its own.
            #
            # This is the ordering half of round 4's "the rendered pause reply command does not enter the
            # reply handler". I fixed the wiring and left the order, and no fixture could see it: each
            # entered with an approval already in hand, because that is what a fixture naturally supplies.
            $answeringPause = -not [string]::IsNullOrWhiteSpace([string]$parsedArgs.PauseChoice)
            if ([string]::IsNullOrWhiteSpace($campaignGrantAuthorizationRef) -and -not $answeringPause) {
                Write-Host 'This review round needs your approval before it can run.' -ForegroundColor Yellow
                Write-Host ''
                Write-Host 'Approve it with:  specrew review --live --approve-round' -ForegroundColor Cyan
                Write-Host ''
                Write-Host 'Approving one round runs one review. Nothing is spent until you do, and Specrew records that you approved it.'
                Write-Host 'If you keep your own approval records, you can supply your own label instead with --authorization-ref <label>.'
                exit 1
            }
            if ($approvalMinted -and -not $Json -and -not $Quiet) {
                Write-Host ('Round approved. Specrew recorded your approval as {0}.' -f $campaignGrantAuthorizationRef) -ForegroundColor Cyan
            }
            $resolvedBudget = if (Get-Command -Name 'Get-ContinuousCoReviewNavigatorTimeoutSeconds' -ErrorAction SilentlyContinue) { [int](Get-ContinuousCoReviewNavigatorTimeoutSeconds -RepoRoot $resolvedProjectPath -HostName $campaignHost) } else { 600 }
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
            # FR-003/FR-005: THE HUMAN'S REPLY, on the command they are already standing in.
            #
            # Answering happens BEFORE any run, and two of the three answers end the invocation without
            # spending anything. Only 'fix-and-continue' falls through to a round, which is what makes
            # one answer authorize exactly one round rather than a mode the campaign stays in.
            $pauseAnswer = [string]$parsedArgs.PauseChoice
            if (-not [string]::IsNullOrWhiteSpace($pauseAnswer)) {
                # CHECKED BEFORE IDENTITY RESOLUTION, or the resolver throws first and the human is told
                # to run --approve-round when they were ANSWERING a pause. Found by the end-to-end walk:
                # the text was correct and the next step it named was for a different act.
                if ([string]::IsNullOrWhiteSpace([string]$FeatureId)) {
                    Write-Host 'Specrew does not know which feature you are answering for, so it cannot find the round waiting for you.' -ForegroundColor Yellow
                    Write-Host ''
                    Write-Host ('Tell it which one:  specrew review --live --feature <feature-id> --pause-choice {0}' -f $pauseAnswer) -ForegroundColor Cyan
                    exit 1
                }
                $campaignStoreRoot = Join-Path $resolvedProjectPath '.specrew/review/authority'
                $answerIdentity = Resolve-ReviewCampaignPublicIdentity -RepoRoot $resolvedProjectPath -FeatureId ([string]$FeatureId) -IterationNumber ([string]$IterationNumber) -RunId ([string]$parsedArgs.RunId)
                $outstanding = Get-ReviewCampaignPendingPause -StoreRoot $campaignStoreRoot -CampaignId $answerIdentity.campaign_id
                # A SILENT FAILURE INVITES THE WORST AVAILABLE DIAGNOSIS.
                #
                # Measured: an agent ran --pause-choice without --feature, resolved no campaign, found no
                # pause, and got nothing back. It then checked --help, where the flag was not listed, and
                # concluded "the CLI is telling you to run a flag its own parser doesn't implement" - and
                # proposed bypassing the campaign gate as the remedy. A defensible inference from two
                # signals that both said ABSENT. Three individually-minor defects - an undocumented flag,
                # an unresolved feature id, and a no-op instead of a refusal - chained into an agent
                # proposing to route around governance.
                #
                # So the two causes are told apart. "I do not know which feature" is a different problem
                # from "there is nothing waiting", and only one of them is fixed by naming --feature.
                if ($null -eq $outstanding) {
                    Write-Host ('No review round is waiting for your answer on {0}, so there is nothing to reply to.' -f $answerIdentity.campaign_id) -ForegroundColor Yellow
                    Write-Host ''
                    Write-Host 'Start one with:  specrew review --live --approve-round' -ForegroundColor Cyan
                    exit 1
                }
                $choice = switch ($pauseAnswer) {
                    '1' { 'fix-and-continue' }
                    '2' { 'stop-here' }
                    '3' { 'abandon' }
                    default { $pauseAnswer }
                }
                $answeredRunId = [string](Get-ReviewAuthorityProperty -Object $outstanding -Name 'run_id')
                $decisionFact = New-ReviewCampaignPauseDecisionFact -CampaignId $answerIdentity.campaign_id -RunId $answeredRunId `
                    -Choice $choice -ObservedAt ([DateTimeOffset]::UtcNow.ToString('o'))

                # A REFUSED ATTEMPT MUST NOT CONSUME THE ANSWER.
                #
                # The decision fact is IMMUTABLE, and an answered pause is excluded from
                # Get-ReviewCampaignPendingPause - so recording it before attempting the landing meant a
                # failed landing left the human holding a spent answer: the command would report no
                # round waiting, while the recorded choice also refused any further round. Wedged, with
                # the landing's own message telling them to choose "stop here" again, which could no
                # longer be submitted.
                #
                # The gating precondition ruled in this morning made that reachable rather than
                # theoretical: it adds refusal arms, and the mismatch arm fires on the pause sitting in
                # the live store right now.
                #
                # So for stop-here the write moves AFTER a successful landing. The other two choices are
                # terminal in themselves - there is no attempt that can fail - so they record
                # immediately, as before.
                if ($choice -ceq 'stop-here') {
                    $rationale = if (-not [string]::IsNullOrWhiteSpace([string]$parsedArgs.PauseRationale)) { [string]$parsedArgs.PauseRationale }
                    else { 'Remaining findings accepted as follow-ups at the review pause.' }
                    $landingRef = if (-not [string]::IsNullOrWhiteSpace($campaignGrantAuthorizationRef)) { $campaignGrantAuthorizationRef } else { "pause-stop-here:$answeredRunId" }
                    $landing = Invoke-ReviewCampaignStopHereLanding -ProjectRoot $resolvedProjectPath -StoreRoot $campaignStoreRoot `
                        -CampaignId $answerIdentity.campaign_id -RunId $answeredRunId -AuthorizedBy 'human' `
                        -AuthorizationRef $landingRef -Rationale $rationale
                    if ([bool]$landing.landed) {
                        # Recorded only now that it has actually landed. Ordering, not bookkeeping: this
                        # is the line that decides whether a failure is recoverable.
                        Write-ReviewCampaignPauseDecisionFact -StoreRoot $campaignStoreRoot -Fact $decisionFact | Out-Null
                    }
                    if ($Json) { $landing | ConvertTo-Json -Depth 30; exit $(if ([bool]$landing.landed) { 0 } else { 1 }) }
                    if ([bool]$landing.landed) {
                        Write-Host 'Your files were checked exactly as they are now, the remaining findings were saved as follow-ups, and review sign-off is complete.' -ForegroundColor Green
                        exit 0
                    }
                    Write-Host ([string]$landing.message) -ForegroundColor Yellow
                    Write-Host 'Your answer has NOT been used up - once the problem above is resolved you can choose an option again.' -ForegroundColor Cyan
                    exit 1
                }

                Write-ReviewCampaignPauseDecisionFact -StoreRoot $campaignStoreRoot -Fact $decisionFact | Out-Null

                if ($choice -ceq 'abandon') {
                    Write-Host 'This review campaign is closed. Nothing further will run.' -ForegroundColor Cyan
                    exit 0
                }
                # fix-and-continue falls through: the answer authorizes the round that follows.
                # (stop-here returned above, before its decision could be recorded on a failed landing;
                # `landed`, not `ok` - the per-STEP outcomes carry `ok`, the composition does not.)
            }
            $campaignRun = Invoke-ReviewCampaignCommand -RepoRoot $resolvedProjectPath -FeatureId ([string]$FeatureId) -IterationNumber ([string]$IterationNumber) `
                -RunId ([string]$parsedArgs.RunId) -ReviewerHost $campaignHost -GrantAuthorizationRef $campaignGrantAuthorizationRef `
                -ReviewerHostExplicit:(-not [string]::IsNullOrWhiteSpace([string]$parsedArgs.Host)) `
                -DesignContextRefs @($parsedArgs.DesignContextRefs) -ExcludedPathPatterns @($parsedArgs.ExcludedPathPatterns) `
                -Model $campaignModel -TargetRoot ([string]$parsedArgs.RunRoot) -TimeoutSeconds $tos -ProgressSink $progressSink
            if ($Json) { $campaignRun | ConvertTo-Json -Depth 30 }
            elseif ($Quiet) {
                $verdict = if ($null -ne $campaignRun.result) { [string]$campaignRun.result.verdict } else { 'none' }
                Write-Host ("review-run campaign={0} run_id={1} status={2} verdict={3} invoked={4} elapsed_ms={5} usage={6}" -f $campaignRun.campaign_id, $campaignRun.run_id, $campaignRun.status, $verdict, ([bool]$campaignRun.invoked).ToString().ToLowerInvariant(), $campaignRun.diagnostics.elapsed_ms, $campaignRun.diagnostics.usage.status)
            }
            else {
                $border = ('=' * 60)
                $color = if ($null -ne $campaignRun.result -and [bool]$campaignRun.result.can_approve_current) { 'Green' } else { 'Yellow' }
                Write-Host $border -ForegroundColor $color
                $campaignHeading = if (-not [bool]$campaignRun.invoked -and [string]$campaignRun.status -cne 'terminal') { 'SPECREW CO-REVIEW DID NOT RUN' } else { 'SPECREW CAMPAIGN REVIEW' }
                Write-Host $campaignHeading -ForegroundColor $color
                Write-Host $border -ForegroundColor $color
                Write-Host ("Campaign: {0}" -f $campaignRun.campaign_id)
                Write-Host ("Run: {0}  Status: {1}  Invoked: {2}" -f $campaignRun.run_id, $campaignRun.status, $campaignRun.invoked)
                if ($null -ne $campaignRun.result) {
                    Write-Host ("Verdict: {0}  Completion: {1}  Currentness: {2}  Can approve current: {3}" -f $campaignRun.result.verdict, $campaignRun.result.completion, $campaignRun.result.currentness, $campaignRun.result.can_approve_current)
                    if (-not [string]::IsNullOrWhiteSpace([string]$campaignRun.result.failure_reason)) {
                        Write-Host ("Failure: {0}" -f $campaignRun.result.failure_reason) -ForegroundColor Yellow
                        # NO REVIEWER CHOSEN IS NOT A BROKEN TOOL, and it read like one.
                        #
                        # Measured at C:\Devraces: three runs failed with `preflight-failed:harness`,
                        # harness_id `unselected-harness`, and the project had NO reviewer-hosts.json at
                        # all - no reviewer had ever been authorized. The agent read the token as an
                        # ENVIRONMENTAL blocker, decided the co-review was unavailable, and wrote the
                        # review artifact itself. The word "harness" is machinery for "the reviewer you
                        # never picked", and it cost that project its entire review.
                        if ([string]$campaignRun.result.failure_reason -match 'unselected-harness|reviewer-host-required|preflight-failed:harness') {
                            Write-Host ''
                            Write-Host 'No reviewer has been chosen for this project yet, so there was nothing to run the review with. This is a setup step, not a broken tool.' -ForegroundColor Cyan
                            Write-Host 'Pick one you have installed, and approve it once:  specrew review --live --host <claude|codex|copilot|cursor-agent|antigravity> --approve-round' -ForegroundColor Cyan
                            Write-Host 'Choose a different one from the tool that wrote the code where you can - a second opinion is the point.'
                        }
                    }
                    # FR-018 (round-1 finding): a consumer losing a review to the budget must be told
                    # which setting to change ON THE PATH THEY ACTUALLY RAN. The signoff-gate route
                    # carries this text for the boundary surface; the public CLI needs it too, or the
                    # timeout stays sealed exactly where the consumer is standing.
                    # F4 (T067), same argument as the timeout text below and the same reason it lives
                    # HERE: measured in the T067 timeline, a pre-invocation failure released the slot,
                    # nothing offered it back, and the human minted a fresh authorization three minutes
                    # later that they did not need. The engine knew the slot had returned and told
                    # nobody. This is where the consumer is standing when they decide.
                    if ([bool](Get-ReviewAuthorityProperty -Object $campaignRun -Name 'slot_restored')) {
                        $restoredNote = [string](Get-ReviewAuthorityProperty -Object $campaignRun -Name 'slot_restored_note')
                        if (-not [string]::IsNullOrWhiteSpace($restoredNote)) { Write-Host $restoredNote -ForegroundColor Cyan }
                    }
                    if ([string]$campaignRun.result.runtime_outcome -ceq 'timed-out') {
                        $windowText = if ($campaignRun.PSObject.Properties['resolved_timeout_seconds']) { [string]$campaignRun.resolved_timeout_seconds } else { [string]$tos }
                        Write-Host ("The review ran out of time after {0} seconds, so it produced no usable result. Reviews of this size often need a longer window: raise co_review_timeout_seconds in .specrew/config.yml, or pass --timeout-seconds on the next run, then run the review again." -f $windowText) -ForegroundColor Yellow
                    }
                    foreach ($finding in @($campaignRun.result.findings)) { Write-Host ("  [{0}] {1}: {2}" -f $finding.severity, $finding.title, $finding.description) }
                }
                else { Write-Host ("Reason: {0}" -f $campaignRun.reason) -ForegroundColor Yellow }
                # FR-002/FR-003/FR-015: THE DECISION SURFACE, rendered where the human is standing.
                #
                # Format-ReviewCampaignPauseSurface has existed since T001 and nothing on the shipped
                # path ever called it, so every round ended with a generic result dump and no question.
                # This renders the same surface for BOTH shapes: the pause a round just produced, and
                # the outstanding pause a later invocation refused to spend past. A consumer must not
                # have to tell those apart - it is the same unanswered question either way.
                # The surface is rendered UPSTREAM in both shapes and carried here as lines, never
                # re-derived. A round that just ended carries pause.surface (built from the full
                # decision, findings and options in hand); a round walked back into later carries
                # pause_surface (built from the recorded fact, which knows less). Rendering here from
                # whichever object happened to arrive is how the two would drift apart.
                $pauseObject = Get-ReviewAuthorityProperty -Object $campaignRun -Name 'pause'
                $pauseLines = @()
                if ($null -ne $pauseObject) {
                    $embedded = Get-ReviewAuthorityProperty -Object $pauseObject -Name 'surface'
                    if ($null -ne $embedded) { $pauseLines = @($embedded) }
                }
                if ($pauseLines.Count -eq 0) {
                    $carried = Get-ReviewAuthorityProperty -Object $campaignRun -Name 'pause_surface'
                    if ($null -ne $carried) { $pauseLines = @($carried) }
                }
                if ($pauseLines.Count -gt 0) {
                    Write-Host ''
                    foreach ($pauseLine in $pauseLines) { Write-Host $pauseLine }
                    # The RESUMED surface carries its own reply line (it must, so the surface is
                    # complete wherever it is rendered); the live round's surface does not. Printing
                    # unconditionally showed it twice on the resumed path - measured on a real stop, not
                    # in a fixture, because no assertion counts how many times a correct line appears.
                    $alreadyTold = (($pauseLines -join "`n") -match '--pause-choice')
                    # The surface states the choices; this states HOW to send one, which is the half a
                    # numbered list cannot carry on a command line.
                    $answerRunId = [string](Get-ReviewAuthorityProperty -Object $campaignRun -Name 'pause_run_id')
                    if ([string]::IsNullOrWhiteSpace($answerRunId) -and $null -ne $pauseObject) {
                        $answerFact = Get-ReviewAuthorityProperty -Object $pauseObject -Name 'fact'
                        if ($null -ne $answerFact) { $answerRunId = [string](Get-ReviewAuthorityProperty -Object $answerFact -Name 'run_id') }
                    }
                    if (-not $alreadyTold) {
                        Write-Host ''
                        Write-Host ("Reply with:  specrew review --pause-choice <1|2|3>{0}" -f $(if ([string]::IsNullOrWhiteSpace($answerRunId)) { '' } else { "   (answering round $answerRunId)" })) -ForegroundColor Cyan
                    }
                }
                if ($campaignRun.PSObject.Properties['resolved_timeout_seconds']) {
                    Write-Host ("Resolved timeout: {0} seconds" -f $campaignRun.resolved_timeout_seconds)
                }
                $usage = $campaignRun.diagnostics.usage
                Write-Host ("Observed elapsed: {0:n1}s  Heartbeats: {1}  Usage: {2}" -f ([long]$campaignRun.diagnostics.elapsed_ms / 1000), $campaignRun.diagnostics.heartbeat_count, $usage.status)
                if ([string]$usage.status -ceq 'available') {
                    Write-Host ("Usage detail: input={0} output={1} total={2} cost_usd={3}" -f $usage.input_tokens, $usage.output_tokens, $usage.total_tokens, $usage.cost_usd)
                }
                $authorityStoreText = if ($campaignRun.PSObject.Properties['store_root'] -and -not [string]::IsNullOrWhiteSpace([string]$campaignRun.store_root)) {
                    [string]$campaignRun.store_root
                }
                else { 'unavailable (run ended before authority-store creation)' }
                Write-Host ("Authority store: {0}" -f $authorityStoreText)
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
            . (Join-Path $reviewEngineRoot 'co-review-service.ps1')
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
                        Write-Host '    specrew review --live --host <claude|codex|...> --approve-round'
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
