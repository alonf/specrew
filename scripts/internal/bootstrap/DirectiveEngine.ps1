<#
.SYNOPSIS
  Build the data-oriented bootstrap directive the agent consumes.
.DESCRIPTION
  Stable, PURE engine (IDesign): assembles the directive PSCustomObject from the decided mode,
  the evaluated sources, and the validation findings. `render_first` is ALWAYS true - the agent
  must render prose orientation + menu before any structured picker (FR-004/FR-020); mechanical
  enforcement is the disallowed-tools skill, this field is the contract the agent honors.
  Feature 174 (FR-002, FR-004).
.OUTPUTS
  [pscustomobject] directive { mode, render_first, menu_intent, sources, required_reads,
                               validation_findings, dedupe_key }
#>
function New-SpecrewBootstrapDirective {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)][ValidateSet('full', 'welcome-back', 'cleared-anchor')][string] $Mode,
        # Evaluated source presence/validity (handover/anchor/marker), free-form object.
        [Parameter()][object] $Sources,
        # Human-readable findings explaining why full-not-resume / what was cleared.
        [Parameter()][string[]] $ValidationFindings = @(),
        # Files the agent must read (e.g. the validated handover path).
        [Parameter()][string[]] $RequiredReads = @(),
        # One bootstrap per session.
        [Parameter(Mandatory)][string] $DedupeKey
    )

    # The menu is the same set regardless of mode; the mode + findings drive what the agent says.
    $menuIntent = 'resume-new-pick'

    [pscustomobject]@{
        mode                = $Mode
        render_first        = $true
        menu_intent         = $menuIntent
        sources             = $Sources
        required_reads      = @($RequiredReads)
        validation_findings = @($ValidationFindings)
        dedupe_key          = $DedupeKey
    }
}
