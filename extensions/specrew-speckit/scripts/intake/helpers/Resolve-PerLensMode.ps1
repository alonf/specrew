<#
.SYNOPSIS
Resolve per-lens mode (Mode A/B/C) based on expertise dial and lens completeness.

.DESCRIPTION
Implements per-lens mode evaluation with most-conservative-wins conflict resolution.
Each persona lens is independently evaluated against its own expertise dial and content completeness.

Mode A (Sufficient): dial ≥7 AND ≥75% completeness → minimal questions
Mode B (Targeted): dial 4-6 OR 40-74% completeness → 2-3 targeted clarifications
Mode C (Full Interview): dial ≤3 OR <40% completeness → guided interview

Implements FR-010, FR-028 for Feature 049 Iteration 003.

.PARAMETER ExpertiseDial
User's expertise dial for this persona (1-10 scale).

.PARAMETER LensCompleteness
Percentage of substantive answers across this lens's 12 categories (0.0-1.0).

.PARAMETER DepthRules
Depth rules configuration loaded from depth-rules.yml.

.EXAMPLE
$mode = Resolve-PerLensMode -ExpertiseDial 8 -LensCompleteness 0.8 -DepthRules $rules

.NOTES
Mirror parity: This file must remain functionally identical to:
  .specify/extensions/specrew-speckit/scripts/intake/helpers/Resolve-PerLensMode.ps1
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateRange(1, 10)]
    [int]$ExpertiseDial,

    [Parameter(Mandatory = $true)]
    [ValidateRange(0.0, 1.0)]
    [double]$LensCompleteness,

    [Parameter(Mandatory = $false)]
    [object]$DepthRules
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Default thresholds (v1 starter rules)
$modeADialThreshold = 7
$modeACompletenessThreshold = 0.75
$modeBDialMin = 4
$modeBDialMax = 6
$modeBCompletenessMin = 0.40
$modeBCompletenessMax = 0.74

# Override with depth-rules.yml if provided
if ($DepthRules) {
    if ($DepthRules.mode_a_thresholds) {
        if ($DepthRules.mode_a_thresholds.min_expertise_dial) {
            $modeADialThreshold = $DepthRules.mode_a_thresholds.min_expertise_dial
        }
        if ($DepthRules.mode_a_thresholds.min_completeness) {
            $modeACompletenessThreshold = $DepthRules.mode_a_thresholds.min_completeness
        }
    }
}

# Mode A: High expertise AND high completeness
if ($ExpertiseDial -ge $modeADialThreshold -and $LensCompleteness -ge $modeACompletenessThreshold) {
    Write-Verbose "Resolved mode A (Sufficient): dial=$ExpertiseDial, completeness=$LensCompleteness"
    return 'A'
}

# Mode C: Low expertise OR low completeness
if ($ExpertiseDial -le 3 -or $LensCompleteness -lt $modeBCompletenessMin) {
    Write-Verbose "Resolved mode C (Full Interview): dial=$ExpertiseDial, completeness=$LensCompleteness"
    return 'C'
}

# Mode B: Everything else (mid-range)
Write-Verbose "Resolved mode B (Targeted Clarify): dial=$ExpertiseDial, completeness=$LensCompleteness"
return 'B'
