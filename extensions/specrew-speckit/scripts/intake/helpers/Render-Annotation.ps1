<#
.SYNOPSIS
Render transparency annotations for auto-decided items.

.DESCRIPTION
Implements Proposal 053 transparency pattern for low-expertise auto-decisions.
Returns formatted annotation strings for each auto-decision, showing what the system chose
and why, so users can escalate to clarification if needed.

Implements FR-027, FR-028, TG-011 for Feature 049 Iteration 003.

.PARAMETER LensResult
Lens result object containing persona_id, lens_mode, and questions.

.PARAMETER AutoDecisions
Auto-decision defaults hashtable loaded for the current stack.

.EXAMPLE
$annotations = Render-Annotation -LensResult $result -AutoDecisions $defaults

.NOTES
Mirror parity: This file must remain functionally identical to:
  .specify/extensions/specrew-speckit/scripts/intake/helpers/Render-Annotation.ps1
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Render-Annotation {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [object]$LensResult,

        [Parameter(Mandatory = $false)]
        [hashtable]$AutoDecisions = @{}
    )

    $annotations = @()
    if ($LensResult.lens_mode -ne 'C' -or $LensResult.expertise_dial -gt 3) {
        return $annotations
    }

    foreach ($category in $AutoDecisions.Keys) {
        $decision = $AutoDecisions[$category]
        $annotation = "[AUTO-DECIDED: $category → $decision]"
        $annotations += $annotation
    }

    Write-Verbose "Rendered $($annotations.Count) transparency annotations for persona: $($LensResult.persona_id)"
    return $annotations
}
