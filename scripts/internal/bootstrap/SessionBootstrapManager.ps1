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
        [Parameter(Mandatory)][ValidatePattern('^[A-Za-z0-9_.-]+$')][string] $HostName,
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
    $dedupeKey = if ($normalizedEvent.safe_session_id) { $normalizedEvent.safe_session_id } else { New-SpecrewPerLaunchSessionToken }
    $resolvedStatePath = if ($StatePath) { $StatePath } else { Join-Path $ProjectRoot '.specrew/start-context.json' }

    $validity = Test-SpecrewAnchorValidity -StatePath $resolvedStatePath -ProjectRoot $ProjectRoot -BaseBranch $BaseBranch

    # Handover-first (architecture-core d2): a validated handover from a prior SessionEnd is the
    # primary resume signal, read + validated before the anchor decides the mode.
    $handoverValid = $false
    $handover = $null
    $handoverInvalidFindings = @()
    try {
        $handover = Get-SpecrewRollingHandover -HandoverDir (Join-Path $ProjectRoot '.specrew/handover') -NowUtc $NowUtc
        if ($null -ne $handover) {
            $expectedHandoverFeature = $null
            if ($null -ne $validity.anchor -and -not [string]::IsNullOrWhiteSpace([string]$validity.anchor.feature_ref)) {
                $expectedHandoverFeature = [string]$validity.anchor.feature_ref
            }
            if ([string]::IsNullOrWhiteSpace($expectedHandoverFeature)) {
                $expectedHandoverFeature = Resolve-SpecrewBranchFeatureRef -ProjectRoot $ProjectRoot
            }
            $hv = Test-SpecrewHandoverValidity -Handover $handover -ProjectRoot $ProjectRoot -BaseBranch $BaseBranch -ExpectedFeatureRef $expectedHandoverFeature
            $handoverValid = [bool]$hv.valid
            # Prop-145 round-6 (MEDIUM): a present-but-INVALID handover (stale / wrong-branch / malformed) is
            # NOT authoritative resume truth - capture WHY so the directive surfaces it (and so the stale
            # snapshot below is never passed to reconciliation). The findings name the reason (e.g. "handover
            # older than the freshness window: ...").
            if (-not $handoverValid) {
                $handoverInvalidFindings = @(@($hv.findings) | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
                if ($handoverInvalidFindings.Count -eq 0) {
                    $r = if ($hv.reason) { [string]$hv.reason } else { 'invalid' }
                    $handoverInvalidFindings = @("ignored a present-but-invalid handover ($r); resuming from anchor/current state, not the stale snapshot")
                }
            }
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

    # F-174 iter-10 (T001): re-compute the CURRENT delta on resume so the agent gets the ACTUAL tree (not the
    # stale snapshot) + a directive to read what changed since the last stop. SHARED with `specrew start` (T008).
    # Prop-145 round-6 (MEDIUM): pass the handover ONLY when it is VALID - an invalid (stale/wrong-branch)
    # handover must not seed "Last captured stop: <old timestamp>" into the resume directive (the current git
    # delta is still computed from $null, so the agent gets the REAL tree without a stale-snapshot anchor).
    $reconciliationHandover = if ($handoverValid) { $handover } else { $null }
    $reconciliation = $null
    try { $reconciliation = Get-SpecrewResumeReconciliation -ProjectRoot $ProjectRoot -Handover $reconciliationHandover } catch { $reconciliation = $null }

    $mode = Resolve-SpecrewBootstrapMode -AnchorValid $validity.valid -AnchorClearedReason $validity.cleared_reason -HandoverValid $handoverValid

    # Advisory SessionStart marker + same-worktree concurrency (US-4, FR-018/019). Never blocks; the
    # marker is local-only. We read the prior marker, classify concurrency, then stamp our own.
    $concurrent = $false
    $concurrencyReason = 'none'
    try {
        $markerPath = Join-Path $ProjectRoot '.specrew/runtime/session-marker.json'
        $cc = Test-SpecrewConcurrentSession -Marker (Get-SpecrewSessionMarker -MarkerPath $markerPath) -ProjectRoot $ProjectRoot -NowUtc $NowUtc -CurrentSessionId $dedupeKey
        $concurrent = [bool]$cc.concurrent
        $concurrencyReason = $cc.reason
        $branch = ''; $head = ''
        try { $branch = (& git -C $ProjectRoot rev-parse --abbrev-ref HEAD 2>$null) } catch { $null = $_ }
        try { $head = (& git -C $ProjectRoot rev-parse --short HEAD 2>$null) } catch { $null = $_ }
        Write-SpecrewSessionMarker -MarkerPath $markerPath -HostName $HostName -ProjectRoot $ProjectRoot -Branch $branch -HeadCommit $head -SessionId $dedupeKey -StartedAt $NowUtc | Out-Null
    }
    catch { $null = $_ }

    $allFindings = @($validity.findings)
    if ($handoverInvalidFindings.Count -gt 0) { $allFindings += $handoverInvalidFindings }
    if ($concurrent) { $allFindings += 'advisory: another session may be active in this worktree (marker within 1h)' }

    $directive = New-SpecrewBootstrapDirective `
        -Mode $mode.mode `
        -DedupeKey $dedupeKey `
        -ValidationFindings $allFindings `
        -RequiredReads @('.specrew/last-start-prompt.md', '.specrew/start-context.json') `
        -Handover $handoverDirective `
        -Reconciliation $reconciliation `
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
        # F-174 iter-10: the launch source (startup|resume|clear) on this fire. Free observability for the
        # double-render dedupe: a host that re-fires SessionStart writes TWO journal rows; if both carry the
        # SAME source, the (dedupe_key, source)-keyed render dedupe is correct to suppress the second. NOT
        # consumed by the dedupe itself (the provider keys off its own parse) - this row is the diagnostic.
        source             = $normalizedEvent.source
        findings           = $allFindings
    }

    if ($JournalPath) {
        # Advisory and fail-open, but not best-effort under ordinary concurrent provider fires: the accessor
        # serializes one JSONL append within a short bound so both forensic records survive.
        $null = Add-SpecrewBootstrapJournalRecord -JournalPath $JournalPath -Record $record
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
        [string] $HostKind = '',
        [AllowNull()][string] $SpecrewVersion = $null
    )

    # Feature 185: resolve the real host. Callers normally pass the per-host-baked $HostKind; when one omits
    # it, detect from the live environment (CLAUDECODE / ANTIGRAVITY_SESSION_ID / CURSOR_AGENT / CODEX_SESSION_ID
    # / COPILOT_CLI) BEFORE the 'claude' last resort. The prior bare `= 'claude'` default is what mislabeled
    # every direct non-claude launch. Mirrors the explicit -> env -> sentinel precedence Update-SpecrewRollingHandover uses.
    if ([string]::IsNullOrWhiteSpace($HostKind)) {
        try { $HostKind = [string](Get-SpecrewRuntimeHostFromEnv) } catch { $HostKind = $null }
        if ([string]::IsNullOrWhiteSpace($HostKind)) { $HostKind = 'claude' }
    }

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
    # $null when none is set. CrewRuntimeStatus stays at its AllowNull default (the hook makes no crew-runtime
    # scan); SpecrewVersion is threaded from the provider (resolved from the module manifest) so the mandatory
    # orientation banner renders the REAL version instead of "Specrew: unknown" (the banner-fix follow-on).
    $expertiseLine = $null
    try { $expertiseLine = Get-SpecrewProfileOrientationLine -Profile (Get-UserProfile) } catch { $expertiseLine = $null }
    $featureRefValue = [string](Get-SpecrewProp $generatorSessionState 'feature_ref')
    if ([string]::IsNullOrWhiteSpace($featureRefValue) -and $featurePath) { $featureRefValue = Split-Path -Leaf $featurePath }
    $contract = Invoke-SpecrewCoordinatorPromptSurgery `
        -Prompt $contract `
        -HostKind $HostKind `
        -SpecrewVersion $SpecrewVersion `
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
