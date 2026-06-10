<#
.SYNOPSIS
  Orchestrate the SessionStart B2 bootstrap: event -> validate -> classify -> directive -> journal.
.DESCRIPTION
  Manager (IDesign): orchestrates one use case by calling the engines + accessors; it holds no
  business rules of its own and is NON-INTERACTIVE (FR-003) - it only produces the directive the
  agent renders, never asks questions or branches on a menu response. Reads the anchor via the
  ValidationEngine (which owns its accessor reads), decides the mode via the pure
  ClassificationEngine, and builds the directive via the pure DirectiveEngine. Writes a basic
  classification record when a journal path is supplied (the full F-171 journal envelope is
  iteration 003, T018). Feature 174 (FR-001, FR-002, FR-003, FR-016, FR-020).
  Depends on the other bootstrap component files (co-loaded by the module).
.OUTPUTS
  [pscustomobject] { directive, mode, record, validity }
#>

function Invoke-SpecrewSessionBootstrap {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)][AllowEmptyString()][string] $RawEvent,
        [Parameter(Mandatory)][ValidateSet('claude', 'codex', 'copilot', 'cursor')][string] $HostName,
        [Parameter(Mandatory)][string] $ProjectRoot,
        # Defaults to the project-local session-state file.
        [Parameter()][string] $StatePath,
        [Parameter()][string] $BaseBranch = 'main',
        # ISO-8601 'now' for handover-freshness (deterministic for tests; live default below).
        [Parameter()][string] $NowUtc = ((Get-Date).ToUniversalTime().ToString('o')),
        # When supplied, a one-line classification record is appended (advisory journal).
        [Parameter()][string] $JournalPath
    )

    $normalizedEvent = ConvertFrom-SpecrewHostHookEvent -RawEvent $RawEvent -HostName $HostName -ProjectRoot $ProjectRoot
    $dedupeKey = if ($normalizedEvent.safe_session_id) { $normalizedEvent.safe_session_id } else { 'no-session' }
    $resolvedStatePath = if ($StatePath) { $StatePath } else { Join-Path $ProjectRoot '.specrew/start-context.json' }

    $validity = Test-SpecrewAnchorValidity -StatePath $resolvedStatePath -ProjectRoot $ProjectRoot -BaseBranch $BaseBranch

    # Handover-first (architecture-core d2): a validated handover from a prior SessionEnd is the
    # primary resume signal, read + validated before the anchor decides the mode.
    $handoverValid = $false
    $handover = $null
    try {
        $handover = Get-SpecrewRollingHandover -HandoverDir (Join-Path $ProjectRoot '.specrew/handover') -NowUtc $NowUtc
        if ($null -ne $handover) {
            $handoverValid = [bool](Test-SpecrewHandoverValidity -Handover $handover -ProjectRoot $ProjectRoot -BaseBranch $BaseBranch).valid
        }
    }
    catch { $handoverValid = $false }

    # F-174 iter-5: surface the agent-authored body on resume; flag a placeholder (hollow) body so the
    # bootstrap renders the prominent backstop warn (carry #3). Only a VALID handover is surfaced.
    $handoverDirective = $null
    if ($null -ne $handover -and $handoverValid) {
        $bp = Test-SpecrewHandoverBodyPlaceholder -Sections $handover.sections
        $handoverDirective = [pscustomobject]@{
            present         = $true
            placeholder     = [bool]$bp.placeholder
            recorded_at     = $handover.recorded_at
            active_boundary = $handover.active_boundary
            sections        = $handover.sections
        }
    }

    $mode = Resolve-SpecrewBootstrapMode -AnchorValid $validity.valid -AnchorClearedReason $validity.cleared_reason -HandoverValid $handoverValid

    # Advisory SessionStart marker + same-worktree concurrency (US-4, FR-018/019). Never blocks; the
    # marker is local-only. We read the prior marker, classify concurrency, then stamp our own.
    $concurrent = $false
    $concurrencyReason = 'none'
    try {
        $markerPath = Join-Path $ProjectRoot '.specrew/runtime/session-marker.json'
        $cc = Test-SpecrewConcurrentSession -Marker (Get-SpecrewSessionMarker -MarkerPath $markerPath) -ProjectRoot $ProjectRoot -NowUtc $NowUtc
        $concurrent = [bool]$cc.concurrent
        $concurrencyReason = $cc.reason
        $branch = ''; $head = ''
        try { $branch = (& git -C $ProjectRoot rev-parse --abbrev-ref HEAD 2>$null) } catch { $null = $_ }
        try { $head = (& git -C $ProjectRoot rev-parse --short HEAD 2>$null) } catch { $null = $_ }
        Write-SpecrewSessionMarker -MarkerPath $markerPath -HostName $HostName -ProjectRoot $ProjectRoot -Branch $branch -HeadCommit $head -StartedAt $NowUtc | Out-Null
    }
    catch { $null = $_ }

    $allFindings = @($validity.findings)
    if ($concurrent) { $allFindings += 'advisory: another session may be active in this worktree (marker within 1h)' }

    $directive = New-SpecrewBootstrapDirective `
        -Mode $mode.mode `
        -DedupeKey $dedupeKey `
        -ValidationFindings $allFindings `
        -RequiredReads @('.specrew/last-start-prompt.md', '.specrew/start-context.json') `
        -Handover $handoverDirective `
        -Sources ([pscustomobject]@{ anchor_present = ($null -ne $validity.anchor); handover_valid = $handoverValid; concurrent_session = $concurrent })

    $record = [pscustomobject]@{
        host               = $HostName
        mode               = $mode.mode
        anchor_cleared     = $validity.cleared_reason
        handover_valid     = $handoverValid
        handover_placeholder = ($null -ne $handoverDirective -and $handoverDirective.placeholder)
        concurrent_session = $concurrent
        concurrency_reason = $concurrencyReason
        dedupe_key         = $dedupeKey
        findings           = $allFindings
    }

    if ($JournalPath) {
        $dir = Split-Path -Parent $JournalPath
        if ($dir -and -not (Test-Path -LiteralPath $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
        ($record | ConvertTo-Json -Compress) | Add-Content -LiteralPath $JournalPath -Encoding UTF8
    }

    [pscustomobject]@{
        directive = $directive
        mode      = $mode.mode
        record    = $record
        validity  = $validity
    }
}

function Write-SpecrewLaunchContractArtifact {
    <#
    .SYNOPSIS
      FR-023: hand the agent the SAME launch contract `specrew start` does, by REUSING its generator.
    .DESCRIPTION
      The hook DRIVES (not merely orients): it writes the full launch contract (Get-StartPrompt) to
      `.specrew/last-start-prompt.md` and ensures `boundary_enforcement` in `.specrew/start-context.json`,
      so a host launched WITHOUT `specrew start` inherits the same governed contract + state. NON-LAUNCHER:
      it writes ONLY those two artifacts via narrow atomic writes - never the git baseline, session
      frontmatter, host selection, or approval/launch mode that `Save-StartArtifacts` (a launcher monolith)
      owns. Launcher-only context the hook has no scan for (roster/routing/project state) is passed as
      EMPTY-SHAPED stubs - not null - so the SHARED generator stays byte-identical (no drift) on its
      null-safe paths; the invariant ~48-rule contract is unaffected. Depends on Get-StartPrompt
      (launch-contract.ps1), Get-/Initialize-SpecrewBoundaryEnforcementState + Write-Utf8FileAtomic
      (shared-governance.ps1), and the coordinator-resume blocks - all dot-sourced into scope by the
      provider alongside the bootstrap components. The provider's fail-open try/catch is the backstop: a
      broken deployed resolution surfaces as no-write (caught by the T038 deployed floor), never a hang.
    .OUTPUTS
      [string] the last-start-prompt.md path written.
    #>
    param(
        [Parameter(Mandatory)][string] $ProjectRoot,
        [Parameter(Mandatory)][string] $Mode,
        [AllowNull()][pscustomobject] $SessionState,
        [ValidateSet('copilot', 'claude', 'codex', 'antigravity', 'cursor')][string] $HostKind = 'claude'
    )

    # The hook's anchor (Get-SpecrewSessionAnchor) and the generator's resume block use DIFFERENT field
    # names: the anchor carries `boundary`/`iteration` (and no `task_id`), while Get-StartPrompt's resume
    # block reads `boundary_type`/`iteration_number`/`task_id` (+ feature_ref/feature_path). Map the anchor
    # into the SHAPE the generator reads so it never throws under StrictMode-Latest on an absent property
    # (a raw anchor would throw on three fields -> provider fail-open -> silent no-contract = the D-009
    # trap). Get-SpecrewProp returns $null for any absent field; the SHARED generator stays untouched.
    $generatorSessionState = $null
    if ($null -ne $SessionState) {
        $generatorSessionState = [pscustomobject]@{
            feature_ref      = Get-SpecrewProp $SessionState 'feature_ref'
            feature_path     = Get-SpecrewProp $SessionState 'feature_path'
            boundary_type    = Get-SpecrewProp $SessionState 'boundary'
            iteration_number = Get-SpecrewProp $SessionState 'iteration'
            task_id          = Get-SpecrewProp $SessionState 'task_id'
        }
    }
    $featurePath = [string](Get-SpecrewProp $generatorSessionState 'feature_path')
    $currentBoundary = $null
    $boundaryValue = Get-SpecrewProp $generatorSessionState 'boundary_type'
    if (-not [string]::IsNullOrWhiteSpace([string]$boundaryValue)) { $currentBoundary = [string]$boundaryValue }

    # Empty-shaped launcher-only context (the hook makes no casting/routing/project-scan decisions). NOT
    # null: Get-RoutingPlanPromptBlock calls $RoutingPlan.roles.GetEnumerator() which throws on a null
    # `.roles`, so a shaped-empty object keeps the SHARED generator on its self-contained path untouched.
    $contract = Get-StartPrompt `
        -ResolvedProjectPath $ProjectRoot `
        -Mode $Mode `
        -FeatureRequest '' `
        -ResolvedFeaturePath $featurePath `
        -TeamRoster ([pscustomobject]@{ mode = 'none' }) `
        -RoutingPlan ([pscustomobject]@{ enabled_agents = @(); roles = @{}; fallback_events = @() }) `
        -ProjectState ([pscustomobject]@{ state = 'active'; spec_directories = @(); detected_entries = @() }) `
        -BrownfieldDiscovery $null `
        -DeliveryGuidance $null `
        -SessionState $generatorSessionState `
        -RecoverySession $null

    # T043 (FR-023, iter-7 Ruling a): apply the SAME coordinator-prompt surgery `specrew start` does
    # (specrew-start.ps1 ~L3348) so the hook's contract reaches CONTENT PARITY. The user-profile/expertise
    # adaptation (the ExpertiseLine) + the per-host coordinator framing live in THIS step, NOT in
    # Get-StartPrompt - iter-6 skipped it, producing the thin contract the side-by-side disproved.
    # Get-SpecrewProfileOrientationLine reads the session-available user-profile (~/.specrew/user-profile.yml);
    # $null when none is set. SpecrewVersion/CrewRuntimeStatus stay at AllowNull defaults - the load-bearing
    # parity content is the ExpertiseLine + the coordinator header; the side-by-side (T046) is the arbiter for
    # any residual gap (Ruling b).
    $expertiseLine = $null
    try { $expertiseLine = Get-SpecrewProfileOrientationLine -Profile (Get-UserProfile) } catch { $expertiseLine = $null }
    $featureRefValue = [string](Get-SpecrewProp $generatorSessionState 'feature_ref')
    if ([string]::IsNullOrWhiteSpace($featureRefValue) -and $featurePath) { $featureRefValue = Split-Path -Leaf $featurePath }
    $contract = Invoke-SpecrewCoordinatorPromptSurgery `
        -Prompt $contract `
        -HostKind $HostKind `
        -LifecycleMode $Mode `
        -FeatureRef $featureRefValue `
        -BoundaryType $currentBoundary `
        -ExpertiseLine $expertiseLine

    $promptPath = Join-Path $ProjectRoot '.specrew/last-start-prompt.md'
    $specrewDir = Split-Path -Parent $promptPath
    if ($specrewDir -and -not (Test-Path -LiteralPath $specrewDir)) {
        New-Item -ItemType Directory -Path $specrewDir -Force | Out-Null
    }
    Write-Utf8FileAtomic -Path $promptPath -Content ($contract + [Environment]::NewLine)

    # Preserve-merge: initialize boundary_enforcement ONLY when absent; never clobber an existing block (a
    # prior `specrew start` / session). Get-/Initialize- own start-context.json I/O + key preservation.
    $beState = Get-SpecrewBoundaryEnforcementState -ProjectRoot $ProjectRoot
    if ($null -eq $beState.State) {
        Initialize-SpecrewBoundaryEnforcementState -ProjectRoot $ProjectRoot -CurrentBoundary $currentBoundary | Out-Null
    }

    return $promptPath
}
