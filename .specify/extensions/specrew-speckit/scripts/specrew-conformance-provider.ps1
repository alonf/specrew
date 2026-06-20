# Feature 185 FR-011 - the conformance Stop-provider.
#
# This is a CONSUMER of the EXISTING hook dispatcher + provider catalog (refocus-scopes.json), registered
# as kind=inject events=[Stop] order=40 - it runs AFTER the handover provider (order 30) has done the
# verdict capture. It is an isolated script the dispatcher invokes; it does NOT edit HandoverStore.ps1
# (the verdict authority) - so it physically cannot break what keeps the lifecycle state honest.
#
# ARG CONTRACT: the dispatcher invokes inject providers with DOUBLE-dash flags (--host-kind, --source-event,
# --transcript-path) via ProcessStartInfo.ArgumentList. PowerShell's single-dash `param()` binding REJECTS
# a `--flag` token (it reads as `-flag`), so a `param()`/[CmdletBinding()] block makes the script exit 1 at
# the binding boundary BEFORE its body runs - a per-stop PROVIDER_FAILED WARN, not a no-op. So parse $args
# MANUALLY, the in-repo convention the handover provider uses (specrew-handover-provider.ps1:50-58). NO param().
#
# Responsibility (the detection logic lands in the next increment - this scaffold is deliberately a
# fail-open no-op so it can be registered + dispatched safely first):
#   1. read last_authorized_boundary + the on-disk artifacts (the boundary state)
#   2. read the transcript ($transcriptPathArg) for the verdict-stop marker rendered THIS turn
#   3. if a next-phase artifact advanced past last_authorized_boundary with NO marker rendered -> a SILENT
#      advance (the #2884 gate-skip) -> emit a correction for the next turn; if the marker WAS rendered ->
#      a legitimate awaiting-verdict stop -> no-op (this is the false-positive guard)
#   4. FR-015 every-stop: a decision-yield stop that owed the packet but did not render it -> nudge
#
# Fully FAIL-OPEN: any error degrades to no-correction and NEVER blocks the stop. An inject provider that
# emits nothing on stdout is a silent no-op (the dispatcher treats empty output as "nothing to inject").

$ErrorActionPreference = 'Stop'

try {
    $hostKindArg = $null
    $sourceEventArg = $null
    $transcriptPathArg = $null
    for ($i = 0; $i -lt $args.Count; $i++) {
        if ($args[$i] -eq '--host-kind' -and ($i + 1) -lt $args.Count) { $hostKindArg = [string]$args[$i + 1] }
        elseif ($args[$i] -eq '--source-event' -and ($i + 1) -lt $args.Count) { $sourceEventArg = [string]$args[$i + 1] }
        elseif ($args[$i] -eq '--transcript-path' -and ($i + 1) -lt $args.Count) { $transcriptPathArg = [string]$args[$i + 1] }
    }

    $projectRoot = (Get-Location).Path
    if ([string]::IsNullOrWhiteSpace($projectRoot) -or -not (Test-Path -LiteralPath (Join-Path $projectRoot '.specrew'))) {
        # Not a governed project root (or run outside one) - nothing to check.
        return
    }

    # --- detection logic: deferred to the next increment (kept a no-op so registration + dispatch are
    # --- proven safe first). When it lands it READS state + $transcriptPathArg, and only on a real silent
    # --- advance writes a correction; it never throws into the stop and never touches the verdict-capture path.
    $detectionImplemented = $false
    if (-not $detectionImplemented) { return }
}
catch {
    [Console]::Error.WriteLine("[specrew-conformance] WARN CONFORMANCE_PROVIDER_FAILED $($_.Exception.Message)")
    return
}
