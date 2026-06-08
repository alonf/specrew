<#
.SYNOPSIS
  Orchestrate SessionEnd: write the Proposal 130 handover (write-only by default).
.DESCRIPTION
  Manager (IDesign): on SessionEnd it normalizes the event (HostEventAdapter), applies Proposal
  130 source-discrimination (compact -> best-effort; clear/exit -> full; startup/resume -> minimal),
  and writes the handover via HandoverStore. WRITE-ONLY by default (no `git add`, commit, or push) -
  we can exit mid-gate, so a blanket add is never used (data-storage d1, FR-021). An opt-in flag may
  perform a SCOPED local commit of the handover file ONLY (never `-A`, never push). The
  commit/push-to-continue-elsewhere choice belongs to the next bootstrap, not here. Feature 174
  (FR-009, FR-021). Depends on HostEventAdapter + HandoverStore (co-loaded by the module).
.OUTPUTS
  [pscustomobject] { path, source, detail, committed, write_only }
#>

function Invoke-SpecrewSessionEndHandover {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)][AllowEmptyString()][string] $RawEvent,
        [Parameter(Mandatory)][ValidateSet('claude', 'codex', 'copilot', 'cursor')][string] $HostName,
        [Parameter(Mandatory)][string] $ProjectRoot,
        [Parameter(Mandatory)][string] $RecordedAt,        # ISO-8601 (caller-supplied; deterministic)
        [Parameter()][hashtable] $Sections = @{},
        [Parameter()][string] $FromCommit,
        [Parameter()][string] $ActiveFeature,
        [Parameter()][string] $ActiveBoundary,
        [Parameter()][bool] $CommitOnExit = $false         # opt-in; OFF by default (FR-021)
    )

    $evt = ConvertFrom-SpecrewHostHookEvent -RawEvent $RawEvent -HostName $HostName -ProjectRoot $ProjectRoot
    $source = if (-not [string]::IsNullOrWhiteSpace($evt.source)) { $evt.source } else { 'exit' }

    # Proposal 130 source-discrimination: detail tier (the section CONTENT is the caller's).
    $detail = switch ($source) {
        'compact' { 'best-effort' }
        'startup' { 'minimal' }
        'resume' { 'minimal' }
        default { 'full' }   # clear | exit
    }
    # Compaction drops the transcript before the hook fires - never imply false context (130).
    if ($source -eq 'compact' -and -not $Sections.ContainsKey('What I just did (last 3-5 turns or last boundary work)')) {
        $Sections['What I just did (last 3-5 turns or last boundary work)'] =
        '(transcript dropped by compaction; reconstruct from artifacts + git status + start-context.json)'
    }

    $handoverDir = Join-Path $ProjectRoot '.specrew/handover'
    $path = Write-SpecrewHandover -HandoverDir $handoverDir -Source $source -FromHost $HostName `
        -RecordedAt $RecordedAt -FromCommit $FromCommit -ActiveFeature $ActiveFeature `
        -ActiveBoundary $ActiveBoundary -Sections $Sections

    $committed = $false
    if ($CommitOnExit) {
        # SCOPED commit of the handover file ONLY - never `git add -A`, never push.
        try {
            $rel = [System.IO.Path]::GetRelativePath($ProjectRoot, $path)
            & git -C $ProjectRoot add -- $rel 2>$null
            & git -C $ProjectRoot commit -q -m "handover: session-end $source" -- $rel 2>$null
            $committed = ($LASTEXITCODE -eq 0)
        }
        catch { $committed = $false }
    }

    [pscustomobject]@{
        path       = $path
        source     = $source
        detail     = $detail
        committed  = $committed
        write_only = (-not $CommitOnExit)
    }
}
