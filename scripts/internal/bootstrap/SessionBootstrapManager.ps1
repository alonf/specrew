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
