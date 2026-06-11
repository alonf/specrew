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
                               validation_findings, dedupe_key, handover }
#>
function New-SpecrewBootstrapDirective {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Justification = 'Pure factory: builds and returns a PSCustomObject; performs no external state change.')]
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
        [Parameter(Mandatory)][string] $DedupeKey,
        # F-174 iter-5: the rolling-handover body surfaced on resume - a {present, placeholder,
        # recorded_at, active_boundary, sections} object, or null when there is no valid handover.
        [Parameter()][AllowNull()][object] $Handover = $null,
        # F-174 iter-10 (T001): the cheap resume reconciliation - {last_stop_recorded_at, last_boundary,
        # changed_user_files, directive_text, ...} re-computed on resume, or null. Tells the agent to read
        # what changed since the last stop and continue from the real state.
        [Parameter()][AllowNull()][object] $Reconciliation = $null
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
        handover            = $Handover
        reconciliation      = $Reconciliation
    }
}
