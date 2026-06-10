Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Session-state + recovery functions extracted from specrew-start.ps1 (Feature 141
# iteration 002, FR-024) so they are dot-sourceable and unit-testable. specrew-start.ps1
# dot-sources this helper as a compatibility wrapper; tests dot-source it standalone.
$srSharedGovernance = Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) 'extensions\specrew-speckit\scripts\shared-governance.ps1'
if (Test-Path -LiteralPath $srSharedGovernance -PathType Leaf) { . $srSharedGovernance }
$srSyncBoundary = Join-Path $PSScriptRoot 'sync-boundary-state.ps1'
if (Test-Path -LiteralPath $srSyncBoundary -PathType Leaf) { . $srSyncBoundary }

function Get-SpecrewConfigValue {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectRoot,

        [Parameter(Mandatory = $true)]
        [string]$Key
    )

    $configPath = Join-Path $ProjectRoot '.specrew\config.yml'
    if (-not (Test-Path -LiteralPath $configPath -PathType Leaf)) {
        return $null
    }

    foreach ($line in Get-Content -LiteralPath $configPath -Encoding UTF8) {
        if ($line -match ('^\s*{0}:\s*"?(?<value>[^"#]+?)"?\s*$' -f [regex]::Escape($Key))) {
            return $Matches['value'].Trim()
        }
    }

    return $null
}

function Get-SpecrewPromptSessionState {
    param([Parameter(Mandatory = $true)][string]$ProjectRoot)

    $paths = Get-SpecrewSessionStatePaths -ProjectRoot $ProjectRoot
    if (-not (Test-Path -LiteralPath $paths.PromptPath -PathType Leaf)) {
        return $null
    }

    $parsed = ConvertFrom-SpecrewFrontmatter -Content (Get-Content -LiteralPath $paths.PromptPath -Raw -Encoding UTF8)
    return Get-SpecrewSessionStateFromFrontmatter -Frontmatter $parsed.Frontmatter
}

function Get-SpecrewIdentitySessionState {
    param([Parameter(Mandatory = $true)][string]$ProjectRoot)

    $paths = Get-SpecrewSessionStatePaths -ProjectRoot $ProjectRoot
    if (-not (Test-Path -LiteralPath $paths.IdentityPath -PathType Leaf)) {
        return $null
    }

    $parsed = ConvertFrom-SpecrewFrontmatter -Content (Get-Content -LiteralPath $paths.IdentityPath -Raw -Encoding UTF8)
    return Get-SpecrewSessionStateFromFrontmatter -Frontmatter $parsed.Frontmatter
}

function Get-SpecrewStartContextSessionState {
    param([Parameter(Mandatory = $true)][string]$ProjectRoot)

    $paths = Get-SpecrewSessionStatePaths -ProjectRoot $ProjectRoot
    if (-not (Test-Path -LiteralPath $paths.ContextPath -PathType Leaf)) {
        return $null
    }

    # -AsHashtable is critical here: legacy start-context.json files from
    # pre-F-020 projects (initialized at 0.19.0 or earlier) do NOT have the
    # session_state field. With ConvertFrom-Json producing PSCustomObject,
    # Set-StrictMode -Version Latest throws on the missing-property access.
    # Hashtable indexer returns $null for missing keys without throwing,
    # which is the migration-tolerant semantics we want here.
    try {
        $context = Get-Content -LiteralPath $paths.ContextPath -Raw -Encoding UTF8 | ConvertFrom-Json -Depth 12 -AsHashtable
    }
    catch {
        if (Test-IsUnsupportedSpecrewSchemaError -ErrorRecord $_) {
            throw
        }
        return $null
    }

    $schema = Get-SpecrewStateSchemaVersion -State $context -Path $paths.ContextPath
    # v0/v1 behavior: session_state payload remains optional for legacy workspaces

    if ($null -eq $context -or $null -eq $context['session_state']) {
        return $null
    }

    $sessionState = $context['session_state']
    return [pscustomobject]@{
        active           = if ($sessionState['active']) { 'true' } else { 'false' }
        boundary_type    = [string]$sessionState['boundary_type']
        feature_ref      = [string]$sessionState['feature_ref']
        feature_path     = [string]$sessionState['feature_path']
        iteration_number = [string]$sessionState['iteration_number']
        task_id          = [string]$sessionState['task_id']
        auth_commit_hash = [string]$sessionState['auth_commit_hash']
        recorded_at      = [string]$sessionState['recorded_at']
    }
}

function Get-SpecrewSessionStateSnapshot {
    param([Parameter(Mandatory = $true)][string]$ProjectRoot)

    $promptState = Get-SpecrewPromptSessionState -ProjectRoot $ProjectRoot
    $contextState = Get-SpecrewStartContextSessionState -ProjectRoot $ProjectRoot
    $identityState = Get-SpecrewIdentitySessionState -ProjectRoot $ProjectRoot
    $decisionsState = Get-LatestSpecrewBoundarySyncState -ProjectRoot $ProjectRoot
    $states = @(
        foreach ($candidate in @($promptState, $contextState, $identityState, $decisionsState)) {
            if ($null -ne $candidate) {
                $candidate
            }
        }
    )

    # File paths surfaced so Test-SpecrewSessionStateConsistency can distinguish
    # "file absent on disk" from "file present but stale/unparseable" — fixes the
    # misleading "missing or unreadable" message from tip-calc-v2 dogfooding 2026-05-23.
    $resolvedProjectRoot = Resolve-ProjectPath -Path $ProjectRoot

    return [pscustomobject]@{
        prompt         = $promptState
        prompt_path    = Join-Path $resolvedProjectRoot '.specrew\last-start-prompt.md'
        context        = $contextState
        context_path   = Join-Path $resolvedProjectRoot '.specrew\start-context.json'
        identity       = $identityState
        identity_path  = Join-Path $resolvedProjectRoot '.squad\identity\now.md'
        decisions      = $decisionsState
        session_state  = if ($states.Count -gt 0) { $states[0] } else { $null }
    }
}

function Test-SpecrewFeatureMergedToMain {
    param(
        [Parameter(Mandatory = $true)][string]$ProjectRoot,
        [AllowNull()][string]$FeatureRef
    )

    # Strict merge detection (Feature 141 FR-024). Match the FULL feature ref slug
    # (e.g. "141-design-gate-runtime-hardening", which appears in PR-merge bodies as
    # "...from alonf/141-design-gate-runtime-hardening"), NEVER the bare numeric id.
    # Grepping the bare number falsely classified Feature 141 as merged because an
    # unrelated Feature 049 merge body said "Proposal 120 + 141" — proposal 141 is not
    # feature 141. --fixed-strings makes this an exact substring match (no regex), and
    # the Get-SpecrewFeatureNumber guard still rejects refs that lack the NNN- shape.
    $featureNumber = Get-SpecrewFeatureNumber -FeatureRef $FeatureRef
    if ([string]::IsNullOrWhiteSpace($featureNumber)) {
        return [pscustomobject]@{ IsMerged = $false; Detail = $null }
    }

    $bootstrapDate = Get-SpecrewConfigValue -ProjectRoot $ProjectRoot -Key 'bootstrap_date'
    if ([string]::IsNullOrWhiteSpace($bootstrapDate)) {
        $bootstrapDate = '90 days ago'
    }

    $logOutput = @(& git -C $ProjectRoot log main --since="$bootstrapDate" --merges --oneline --fixed-strings --grep="$FeatureRef" 2>&1)
    if ($LASTEXITCODE -ne 0) {
        return [pscustomobject]@{ IsMerged = $false; Detail = $null }
    }

    if ($logOutput.Count -gt 0) {
        return [pscustomobject]@{
            IsMerged = $true
            Detail   = ('Feature {0} appears in merge history on main: {1}' -f $FeatureRef, ($logOutput[0].ToString().Trim()))
        }
    }

    return [pscustomobject]@{ IsMerged = $false; Detail = $null }
}

function Test-SpecrewFeatureBranchExists {
    param(
        [Parameter(Mandatory = $true)][string]$ProjectRoot,
        [AllowNull()][string]$FeatureRef
    )

    if ([string]::IsNullOrWhiteSpace($FeatureRef)) {
        return $true
    }

    # 2>$null: in a non-repo (or when the ref is absent) git writes "fatal: not a git
    # repository" / "fatal: bad ref" to stderr. The decision is taken purely from
    # $LASTEXITCODE, so silence the stderr to keep test transcripts clean (it otherwise
    # leaks through to the FR-024 unit test's non-repo temp fixtures).
    & git -C $ProjectRoot show-ref --verify --quiet ("refs/heads/{0}" -f $FeatureRef) 2>$null
    if ($LASTEXITCODE -eq 0) {
        return $true
    }

    & git -C $ProjectRoot show-ref --verify --quiet ("refs/remotes/origin/{0}" -f $FeatureRef) 2>$null
    return ($LASTEXITCODE -eq 0)
}

function Test-SpecrewAuthorizationRecord {
    param(
        [Parameter(Mandatory = $true)][string]$ProjectRoot,
        [pscustomobject]$SessionState
    )

    if ($null -eq $SessionState -or [string]::IsNullOrWhiteSpace([string]$SessionState.feature_ref)) {
        return $true
    }

    $paths = Get-SpecrewSessionStatePaths -ProjectRoot $ProjectRoot
    if (-not (Test-Path -LiteralPath $paths.DecisionsPath -PathType Leaf)) {
        return $false
    }

    $content = Get-Content -LiteralPath $paths.DecisionsPath -Raw -Encoding UTF8
    if (-not [string]::IsNullOrWhiteSpace([string]$SessionState.auth_commit_hash) -and $content -match [regex]::Escape([string]$SessionState.auth_commit_hash)) {
        return $true
    }

    $featureNumber = Get-SpecrewFeatureNumber -FeatureRef $SessionState.feature_ref
    if ([string]::IsNullOrWhiteSpace($featureNumber)) {
        return $false
    }

    return ($content -match ('Feature\s+{0}' -f [regex]::Escape($featureNumber)) -and $content -match 'authorization')
}

function Test-SpecrewSessionStateConsistency {
    param([Parameter(Mandatory = $true)][pscustomobject]$Snapshot)

    $issues = New-Object System.Collections.Generic.List[string]
    # Each entry now optionally carries a Path so we can distinguish "file absent on disk"
    # from "file present but unparseable / stale frontmatter". Wording fix following
    # tip-calc-v2 dogfooding 2026-05-23/24: the prior "missing or unreadable" message
    # fired even when the file was present and readable, just stale relative to the git
    # log — that misled the human into thinking the file had been deleted.
    $namedStates = @(
        @{ Name = 'last-start-prompt.md'; State = $Snapshot.prompt;   Path = $Snapshot.prompt_path }
        @{ Name = 'start-context.json';   State = $Snapshot.context;  Path = $Snapshot.context_path }
        @{ Name = 'identity/now.md';      State = $Snapshot.identity; Path = $Snapshot.identity_path }
    )

    $existingCount = @($namedStates | Where-Object { $null -ne $_.State }).Count
    if ($existingCount -gt 0) {
        foreach ($entry in $namedStates) {
            if ($null -eq $entry.State) {
                $fileOnDisk = $false
                if (-not [string]::IsNullOrWhiteSpace([string]$entry.Path)) {
                    $fileOnDisk = Test-Path -LiteralPath ([string]$entry.Path) -PathType Leaf
                }
                if ($fileOnDisk) {
                    $issues.Add(("Session-state file is present but stale or unparseable: {0} (file is on disk but its frontmatter / JSON could not be loaded; re-anchor or recreate to refresh)" -f $entry.Name)) | Out-Null
                }
                else {
                    $issues.Add(("Session-state file missing on disk: {0} (re-anchor will recreate it from the current spec)" -f $entry.Name)) | Out-Null
                }
            }
        }
    }

    $activeStates = @(
        foreach ($entry in $namedStates) {
            if ($null -ne $entry.State) {
                $entry.State
            }
        }
        if ($null -ne $Snapshot.decisions) {
            $Snapshot.decisions
        }
    )
    $featureRefs = @($activeStates | ForEach-Object { [string]$_.feature_ref } | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | Select-Object -Unique)
    if ($featureRefs.Count -gt 1) {
        $issues.Add(("Session-state feature mismatch detected: {0}" -f ($featureRefs -join ', '))) | Out-Null
    }

    $boundaries = @($activeStates | ForEach-Object { [string]$_.boundary_type } | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | Select-Object -Unique)
    if ($boundaries.Count -gt 1) {
        $issues.Add(("Session-state boundary mismatch detected: {0}" -f ($boundaries -join ', '))) | Out-Null
    }

    return $issues.ToArray()
}

function Get-SpecrewLatestIterationDirectory {
    param(
        [Parameter(Mandatory = $true)][string]$FeaturePath
    )

    $iterationsRoot = Join-Path $FeaturePath 'iterations'
    if (-not (Test-Path -LiteralPath $iterationsRoot -PathType Container)) {
        return $null
    }

    return @(
        Get-ChildItem -LiteralPath $iterationsRoot -Directory |
            Sort-Object Name -Descending |
            Select-Object -First 1
    )[0]
}

function Get-SpecrewMetadataValueFromFile {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$Label
    )

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        return $null
    }

    $pattern = '(?m)^\*\*' + [regex]::Escape($Label) + '\*\*:\s*(?<value>.+?)\s*$'
    $match = [regex]::Match((Get-Content -LiteralPath $Path -Raw -Encoding UTF8), $pattern)
    if ($match.Success) {
        return $match.Groups['value'].Value.Trim()
    }

    return $null
}

function Get-SpecrewLateBoundaryIssues {
    param(
        [Parameter(Mandatory = $true)][string]$ProjectRoot,
        [AllowNull()][pscustomobject]$SessionState
    )

    if ($null -eq $SessionState) {
        return @()
    }

    $issues = New-Object System.Collections.Generic.List[string]
    $featurePath = if (-not [string]::IsNullOrWhiteSpace([string]$SessionState.feature_path)) {
        [string]$SessionState.feature_path
    }
    elseif (-not [string]::IsNullOrWhiteSpace([string]$SessionState.feature_ref)) {
        Join-Path $ProjectRoot ('specs\' + [string]$SessionState.feature_ref)
    }
    else {
        $null
    }

    if ([string]::IsNullOrWhiteSpace($featurePath) -or -not (Test-Path -LiteralPath $featurePath -PathType Container)) {
        return @()
    }

    $latestIterationDirectory = Get-SpecrewLatestIterationDirectory -FeaturePath $featurePath
    if ($null -ne $latestIterationDirectory) {
        $reviewPath = Join-Path $latestIterationDirectory.FullName 'review.md'
        $reviewVerdict = Get-SpecrewMetadataValueFromFile -Path $reviewPath -Label 'Overall Verdict'
        if ($reviewVerdict -match '^(?i)accepted$' -and [string]$SessionState.boundary_type -notin @('review-signoff', 'retro', 'iteration-closeout', 'feature-closeout')) {
            $issues.Add(("Late boundary sync mismatch: review.md is accepted in iteration {0}, but the recorded boundary is '{1}' instead of review-signoff or later." -f $latestIterationDirectory.Name, $SessionState.boundary_type)) | Out-Null
        }

        $requireStateFile = [string]$SessionState.boundary_type -notin @('retro', 'iteration-closeout', 'feature-closeout')
        foreach ($stateTruthIssue in @(Get-SpecrewIterationStateTruthIssues -ProjectRoot $ProjectRoot -FeaturePath $featurePath -IterationNumber $latestIterationDirectory.Name -RequireStateFile:$requireStateFile)) {
            $issues.Add($stateTruthIssue) | Out-Null
        }
    }

    $closeoutDashboardPath = Join-Path $featurePath 'closeout-dashboard.md'
    if ((Test-Path -LiteralPath $closeoutDashboardPath -PathType Leaf) -and [string]$SessionState.boundary_type -ne 'feature-closeout') {
        $issues.Add(("Late boundary sync mismatch: closeout-dashboard.md exists for '{0}', but the recorded boundary is '{1}' instead of feature-closeout." -f (Split-Path -Leaf $featurePath), $SessionState.boundary_type)) | Out-Null
    }

    return $issues.ToArray()
}

function Test-SpecrewStaleSessionState {
    param([Parameter(Mandatory = $true)][string]$ProjectRoot)

    $snapshot = Get-SpecrewSessionStateSnapshot -ProjectRoot $ProjectRoot
    $sessionState = $snapshot.session_state
    if ($null -eq $sessionState) {
        return [pscustomobject]@{
            IsStale = $false
            Issues = @()
            SessionState = $null
        }
    }

    $issues = New-Object System.Collections.Generic.List[string]
    foreach ($issue in (Test-SpecrewSessionStateConsistency -Snapshot $snapshot)) {
        $issues.Add($issue) | Out-Null
    }

    foreach ($issue in (Get-SpecrewLateBoundaryIssues -ProjectRoot $ProjectRoot -SessionState $sessionState)) {
        $issues.Add($issue) | Out-Null
    }

    if ([string]$sessionState.active -eq 'false') {
        return [pscustomobject]@{
            IsStale      = ($issues.Count -gt 0)
            Issues       = $issues.ToArray()
            SessionState = $sessionState
        }
    }

    $mergeCheck = Test-SpecrewFeatureMergedToMain -ProjectRoot $ProjectRoot -FeatureRef $sessionState.feature_ref
    if ($mergeCheck.IsMerged) {
        $issues.Add($mergeCheck.Detail) | Out-Null
    }

    if (-not (Test-SpecrewFeatureBranchExists -ProjectRoot $ProjectRoot -FeatureRef $sessionState.feature_ref)) {
        $issues.Add(("Feature branch is missing: {0}" -f $sessionState.feature_ref)) | Out-Null
    }

    # FR-024 (2026-06-02 Linux smoke): the saved session feature path no longer exists
    # on disk, or it points outside the current worktree to a deleted/external worktree
    # (e.g., a completed/merged feature whose old worktree was removed). This is stale
    # runtime state — recovery must NOT re-anchor to this deleted external path.
    $savedFeaturePath = [string]$sessionState.feature_path
    if (-not [string]::IsNullOrWhiteSpace($savedFeaturePath) -and -not (Test-Path -LiteralPath $savedFeaturePath -PathType Container)) {
        $resolvedRoot = Resolve-ProjectPath -Path $ProjectRoot
        $isOutsideWorktree = -not ($savedFeaturePath -like (Join-Path $resolvedRoot '*'))
        $detail = if ($isOutsideWorktree) {
            "Saved session feature path no longer exists and is outside the current worktree: {0} (stale runtime state; do not re-anchor to this deleted/external worktree — clear the stale session reference instead)." -f $savedFeaturePath
        }
        else {
            "Saved session feature path no longer exists: {0} (stale runtime state; do not re-anchor to a missing path — clear the stale session reference instead)." -f $savedFeaturePath
        }
        $issues.Add($detail) | Out-Null
    }

    if (-not (Test-SpecrewAuthorizationRecord -ProjectRoot $ProjectRoot -SessionState $sessionState)) {
        $issues.Add(("Authorization record missing for {0}." -f $sessionState.feature_ref)) | Out-Null
    }

    return [pscustomobject]@{
        IsStale = ($issues.Count -gt 0)
        Issues = $issues.ToArray()
        SessionState = $sessionState
    }
}

function Read-SpecrewRecoveryChoice {
    param([AllowNull()][string]$PreferredChoice)

    if (-not [string]::IsNullOrWhiteSpace($PreferredChoice)) {
        return $PreferredChoice.Trim().ToUpperInvariant()
    }

    while ($true) {
        $selection = Read-Host 'Choose recovery path [A/B/C]'
        if (-not [string]::IsNullOrWhiteSpace($selection)) {
            $normalizedSelection = $selection.Trim().ToUpperInvariant()
            if ($normalizedSelection -in @('A', 'B', 'C')) {
                return $normalizedSelection
            }
        }

        Write-Output "WARN: Invalid recovery choice. Enter A, B, or C." | Out-Host
    }
}

function New-SpecrewRecoverySession {
    param(
        [Parameter(Mandatory = $true)][string]$EntryMode,
        [Parameter(Mandatory = $true)][string[]]$StaleReasons,
        [Parameter(Mandatory = $true)][bool]$BypassGate,
        [AllowNull()][string]$SelectedChoice,
        [Parameter(Mandatory = $true)][string]$NextActionMessage
    )

    return [pscustomobject]@{
        entry_mode              = $EntryMode
        stale_reasons           = @($StaleReasons)
        choice_set              = if ($EntryMode -eq 'detected-stale-state') { @('A', 'B', 'C') } else { @('recover') }
        selected_choice         = $SelectedChoice
        bypass_gate             = $BypassGate
        approval_mode_changed   = $false
        next_action_message     = $NextActionMessage
    }
}

function Resolve-SpecrewRecoverySelection {
    param(
        [Parameter(Mandatory = $true)][string]$Choice,
        [AllowNull()][pscustomobject]$SessionState
    )

    $recoveryFeaturePath = if ($null -ne $SessionState -and -not [string]::IsNullOrWhiteSpace([string]$SessionState.feature_path)) {
        [string]$SessionState.feature_path
    }
    else {
        $null
    }

    switch ($Choice) {
        'A' {
            # FR-024 (2026-06-02 Linux smoke): never re-anchor to a saved feature path
            # that no longer exists (a deleted/external worktree such as C:\Dev\Specrew-051).
            # Route to confirm-gated safe cleanup of the stale runtime references instead.
            $featurePathMissing = (-not [string]::IsNullOrWhiteSpace($recoveryFeaturePath)) -and (-not (Test-Path -LiteralPath $recoveryFeaturePath -PathType Container))
            if ($featurePathMissing) {
                return [pscustomobject]@{
                    ResumeFeatureOverride            = $null
                    SkipAutoResume                   = $true
                    ForceNoLaunch                    = $false
                    NextActionMessage                = "Recovery will NOT re-anchor to '$recoveryFeaturePath' because that worktree no longer exists. With your confirmation it will clear only the stale active-session/start-context references — no feature artifacts are touched and no lifecycle commits are made."
                    Directive                        = "Recovery choice A on a missing feature path: do NOT re-anchor to the deleted/external worktree '$recoveryFeaturePath'. Report the current branch, the stale feature refs, and the selected active-feature candidate, then require explicit human confirmation before clearing the stale active-sessions/start-context references. Do not touch feature artifacts and do not make lifecycle commits."
                    RequiresStaleCleanupConfirmation = $true
                    StaleFeaturePath                 = $recoveryFeaturePath
                }
            }
            return [pscustomobject]@{
                ResumeFeatureOverride = if (-not [string]::IsNullOrWhiteSpace($recoveryFeaturePath)) { $recoveryFeaturePath } else { 'auto' }
                SkipAutoResume        = $false
                ForceNoLaunch         = $false
                NextActionMessage     = if (-not [string]::IsNullOrWhiteSpace($recoveryFeaturePath)) {
                    "Recovery will re-anchor to '$recoveryFeaturePath' so you can repair or continue the last known feature state."
                }
                else {
                    'Recovery will try to re-anchor to the last known feature automatically so you can repair or continue.'
                }
                Directive             = 'Recovery choice A selected: re-anchor to the last known feature, inspect the stale-state evidence, and continue with an explicit repair or resume plan.'
            }
        }
        'B' {
            return [pscustomobject]@{
                ResumeFeatureOverride = $null
                SkipAutoResume        = $true
                ForceNoLaunch         = $false
                NextActionMessage     = 'Recovery will bypass the stale feature state and return you to fresh feature intake.'
                Directive             = 'Recovery choice B selected: do not resume the stale feature automatically. Start fresh intake for a new feature after acknowledging the stale-state evidence.'
            }
        }
        default {
            return [pscustomobject]@{
                ResumeFeatureOverride = $null
                SkipAutoResume        = $true
                ForceNoLaunch         = $true
                NextActionMessage     = 'Recovery will stop after writing diagnostics so you can manually fix or document the stale state before restarting.'
                Directive             = 'Recovery choice C selected: do not launch the host CLI automatically. Review the recorded stale-state evidence, repair the session-state artifacts manually, then rerun specrew start.'
            }
        }
    }
}

function Clear-SpecrewStaleSessionReference {
    <#
    .SYNOPSIS
    FR-024 confirm-gated cleanup of stale runtime session references.

    .DESCRIPTION
    When a cross-worktree session resumes against a completed/merged/deleted feature
    whose feature_path no longer exists (see Test-SpecrewStaleSessionState and the
    Resolve-SpecrewRecoverySelection choice-A guard), the human is asked to confirm
    cleanup. On confirmation this function clears ONLY the runtime session references
    that would otherwise re-anchor the next start:
      - start-context.json -> session_state (active=false, feature_ref/feature_path/iteration/task cleared)
      - active-sessions.yml -> the matching feature's session entry (removed)
    It NEVER touches feature artifacts under specs/** and NEVER makes git/lifecycle
    commits. Without -Confirmed it is a no-op (returns Cleared=$false, Reason=confirmation-required).
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectRoot,

        [AllowNull()]
        [AllowEmptyString()]
        [string]$StaleFeatureRef,

        [switch]$Confirmed
    )

    if (-not $Confirmed) {
        return [pscustomobject]@{
            Cleared          = $false
            Reason           = 'confirmation-required'
            ClearedRefs      = @()
            TouchedArtifacts = $false
            MadeCommits      = $false
        }
    }

    if (Get-Command -Name 'Resolve-ProjectPath' -ErrorAction SilentlyContinue) {
        $resolvedRoot = Resolve-ProjectPath -Path $ProjectRoot
    } else {
        $resolvedRoot = (Resolve-Path -LiteralPath $ProjectRoot).Path
    }

    $clearedRefs = New-Object System.Collections.Generic.List[string]

    # 1. start-context.json: clear the stale session_state so the next start does not re-anchor.
    $contextPath = Join-Path $resolvedRoot '.specrew/start-context.json'
    if (Test-Path -LiteralPath $contextPath -PathType Leaf) {
        try {
            $context = Get-Content -LiteralPath $contextPath -Raw -Encoding UTF8 | ConvertFrom-Json -Depth 25 -AsHashtable
            if ($null -ne $context -and $context.ContainsKey('session_state') -and $null -ne $context['session_state']) {
                $context['session_state']['active'] = $false
                foreach ($key in 'feature_ref', 'feature_path', 'iteration_number', 'task_id') {
                    if ($context['session_state'].ContainsKey($key)) { $context['session_state'][$key] = '' }
                }
                $json = ConvertTo-Json -InputObject $context -Depth 25
                [System.IO.File]::WriteAllText($contextPath, $json + [Environment]::NewLine, [System.Text.UTF8Encoding]::new($false))
                $clearedRefs.Add('start-context.json:session_state') | Out-Null
            }
        } catch {
            # Leave start-context untouched on parse failure rather than corrupt it.
        }
    }

    # 2. active-sessions.yml: remove the stale feature's session entry (line-based block removal).
    $activePath = Join-Path $resolvedRoot '.specrew/active-sessions.yml'
    if ((Test-Path -LiteralPath $activePath -PathType Leaf) -and -not [string]::IsNullOrWhiteSpace($StaleFeatureRef)) {
        $sourceLines = @(Get-Content -LiteralPath $activePath -Encoding UTF8)
        $out = New-Object System.Collections.Generic.List[string]
        $removing = $false
        $entryIndent = -1
        $headerPattern = '^-\s+feature_id:\s*"?' + [regex]::Escape($StaleFeatureRef) + '"?\s*$'
        foreach ($line in $sourceLines) {
            $trimmed = $line.TrimStart()
            $indent = $line.Length - $trimmed.Length
            if ($removing) {
                $isSiblingDash = $trimmed.StartsWith('- ') -and $indent -le $entryIndent
                $isDedentKey = ($indent -le $entryIndent) -and ($trimmed.Length -gt 0) -and (-not $trimmed.StartsWith('-'))
                if ($isSiblingDash -or $isDedentKey) {
                    $removing = $false
                }
            }
            if (-not $removing -and $trimmed -match $headerPattern) {
                $removing = $true
                $entryIndent = $indent
                continue
            }
            if ($removing) { continue }
            $out.Add($line)
        }
        if ($out.Count -ne $sourceLines.Count) {
            [System.IO.File]::WriteAllText($activePath, ($out -join [Environment]::NewLine) + [Environment]::NewLine, [System.Text.UTF8Encoding]::new($false))
            $clearedRefs.Add('active-sessions.yml:' + $StaleFeatureRef) | Out-Null
        }
    }

    return [pscustomobject]@{
        Cleared          = ($clearedRefs.Count -gt 0)
        Reason           = if ($clearedRefs.Count -gt 0) { 'cleared' } else { 'no-matching-references' }
        ClearedRefs      = $clearedRefs.ToArray()
        TouchedArtifacts = $false
        MadeCommits      = $false
    }
}

function Invoke-SpecrewStaleSessionCleanupDecision {
    <#
    .SYNOPSIS
    FR-024 enforcement bridge: act on a recovery plan that requested confirm-gated cleanup.

    .DESCRIPTION
    Pure decision function (no I/O of its own) so the start flow's enforcement is unit-testable.
    Only acts when the recovery plan set RequiresStaleCleanupConfirmation. The caller is
    responsible for collecting the human confirmation (e.g. Read-SpecrewYesNo) and passing it
    as -Confirmed. When confirmed, delegates to Clear-SpecrewStaleSessionReference. Returns a
    record describing whether cleanup was attempted, confirmed, and the cleanup result.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [pscustomobject]$RecoveryPlan,

        [Parameter(Mandatory = $true)]
        [string]$ProjectRoot,

        [AllowNull()]
        [pscustomobject]$SessionState,

        [Parameter(Mandatory = $true)]
        [bool]$Confirmed
    )

    $requiresCleanup = ($RecoveryPlan.PSObject.Properties.Name -contains 'RequiresStaleCleanupConfirmation') -and `
        [bool]$RecoveryPlan.RequiresStaleCleanupConfirmation
    if (-not $requiresCleanup) {
        return [pscustomobject]@{ Attempted = $false; Confirmed = $false; Result = $null }
    }

    if (-not $Confirmed) {
        return [pscustomobject]@{ Attempted = $true; Confirmed = $false; Result = $null }
    }

    $staleRef = if ($null -ne $SessionState -and -not [string]::IsNullOrWhiteSpace([string]$SessionState.feature_ref)) {
        [string]$SessionState.feature_ref
    }
    else {
        $null
    }
    $result = Clear-SpecrewStaleSessionReference -ProjectRoot $ProjectRoot -StaleFeatureRef $staleRef -Confirmed
    return [pscustomobject]@{ Attempted = $true; Confirmed = $true; Result = $result }
}
