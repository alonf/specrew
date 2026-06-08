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
    try {
        $handover = Get-SpecrewHandover -HandoverDir (Join-Path $ProjectRoot '.specrew/handover') -NowUtc $NowUtc
        if ($null -ne $handover) {
            $handoverValid = [bool](Test-SpecrewHandoverValidity -Handover $handover -ProjectRoot $ProjectRoot -BaseBranch $BaseBranch).valid
        }
    }
    catch { $handoverValid = $false }

    $mode = Resolve-SpecrewBootstrapMode -AnchorValid $validity.valid -AnchorClearedReason $validity.cleared_reason -HandoverValid $handoverValid

    $directive = New-SpecrewBootstrapDirective `
        -Mode $mode.mode `
        -DedupeKey $dedupeKey `
        -ValidationFindings $validity.findings `
        -Sources ([pscustomobject]@{ anchor_present = ($null -ne $validity.anchor); handover_valid = $handoverValid })

    $record = [pscustomobject]@{
        host           = $HostName
        mode           = $mode.mode
        anchor_cleared = $validity.cleared_reason
        dedupe_key     = $dedupeKey
        findings       = $validity.findings
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
