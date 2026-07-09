$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# INT-006 discover-and-present (iteration 007): render the available reviewer-host CHOICES for the human.
#
# The code-implementation lens asks "which co-review host should review the code" but never showed the
# list, so the human chose blind (the iter-007 dogfood: Copilot skipped the question entirely; Codex asked
# but presented no options or default). INT-006 mandates: "discover installed supported headless hosts ...
# and PRESENT available authorized choices when selection is missing." This renders that list deterministically
# so the agent presents real options, not its memory.
#
# HONESTY (dogfood guardrails): detection is `Get-Command` on PATH and is therefore BEST-EFFORT and
# PATH-dependent - the reviewer fires in the navigator's spawn env, whose PATH can differ from the shell
# this runs in, so the output says so. A host that isn't resolvable on PATH is shown WITH A REASON (e.g. a
# desktop-only install exposes no headless CLI), never silently dropped - the human may own that host.

function Format-ContinuousCoReviewReviewerHostChoices {
    param(
        [string] $CodeWriterHost,

        [scriptblock] $CommandResolver
    )

    $config = New-ContinuousCoReviewDefaultReviewerHostConfig -CommandResolver $CommandResolver
    $rows = @($config.hosts) | Sort-Object review_class_rank -Descending
    $cw = if ([string]::IsNullOrWhiteSpace($CodeWriterHost)) { $null } else { $CodeWriterHost.Trim().ToLowerInvariant() }

    $installed = @($rows | Where-Object { $_.installed })
    $recommended = @($installed | Where-Object { $null -eq $cw -or $_.host -ne $cw })   # independent of the code-writer
    $codeWriterRow = @($installed | Where-Object { $cw -and $_.host -eq $cw })           # the code-writer itself - selectable, not recommended
    $unavailable = @($rows | Where-Object { -not $_.installed })
    # Default = strongest INDEPENDENT installed; fall back to the code-writer only if nothing independent exists.
    $default = if ($recommended.Count -gt 0) { $recommended[0].host } elseif ($codeWriterRow.Count -gt 0) { $codeWriterRow[0].host } else { $null }

    $sb = [System.Text.StringBuilder]::new()
    [void]$sb.AppendLine('=== Continuous co-review: reviewer-host choices ===')
    [void]$sb.AppendLine('(best-effort detection - reflects THIS shell''s PATH; the reviewer ultimately spawns in the')
    [void]$sb.AppendLine(' navigator''s environment, whose PATH may differ.)')
    [void]$sb.AppendLine('')
    [void]$sb.AppendLine('RECOMMENDED (independent of your code-writer - a fresh second opinion), strongest first:')
    if ($recommended.Count -eq 0) {
        [void]$sb.AppendLine('  (none independent resolvable on this PATH)')
    }
    else {
        foreach ($h in $recommended) {
            $tag = if ($h.host -eq $default) { '[DEFAULT] ' } else { '          ' }
            [void]$sb.AppendLine(("  {0}{1}  (review-class rank {2})" -f $tag, $h.host, $h.review_class_rank))
        }
    }
    if ($codeWriterRow.Count -gt 0) {
        [void]$sb.AppendLine('')
        [void]$sb.AppendLine('ALSO SELECTABLE - your current code-writer (NOT independent; pick only if quota/availability')
        [void]$sb.AppendLine('forces it - a same-host fresh-context review is still valid, just a weaker check):')
        foreach ($h in $codeWriterRow) {
            [void]$sb.AppendLine(("            {0}  (review-class rank {1})" -f $h.host, $h.review_class_rank))
        }
    }
    if ($unavailable.Count -gt 0) {
        [void]$sb.AppendLine('')
        [void]$sb.AppendLine('NOT AVAILABLE here (no headless CLI on PATH - shown, not dropped):')
        foreach ($h in $unavailable) {
            [void]$sb.AppendLine(("  {0}  -  no '{0}' command resolved on PATH (best-effort; a desktop-only install exposes no headless CLI)" -f $h.host))
        }
    }
    [void]$sb.AppendLine('')
    [void]$sb.AppendLine('You may pick ANY listed host - INCLUDING your own code-writer. Independence is the RECOMMENDATION,')
    [void]$sb.AppendLine('not a rule: only you know each host''s quota/token status, and you may have to reuse your own.')
    if ($default) { [void]$sb.AppendLine(("DEFAULT if you make no choice: {0} (the strongest independent host)." -f $default)) }
    [void]$sb.AppendLine('Record your pick in reviewer_preference as mode=human-selected with the chosen host.')
    [void]$sb.AppendLine('(Model: Specrew uses each host''s OWN default model - it does not yet discover or pin a specific')
    [void]$sb.AppendLine(' model, so none is shown here.)')

    return [pscustomobject]@{
        text              = $sb.ToString()
        recommended_hosts = @($recommended | ForEach-Object { $_.host })
        selectable_hosts  = @($installed | ForEach-Object { $_.host })   # ALL installed, including the code-writer
        default_host      = $default
        code_writer_host  = $cw
    }
}
