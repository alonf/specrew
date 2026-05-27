<#
.SYNOPSIS
Traverse question bank for a persona based on resolved mode.

.DESCRIPTION
Loads and filters questions from persona-specific question bank YAML file.
Returns questions appropriate for the resolved mode (A/B/C).

Mode A: Minimal/confirmation questions only
Mode B: Targeted clarification questions (2-3)
Mode C: Full question set for guided interview

Implements FR-028 for Feature 049 Iteration 003.

.PARAMETER IntakeDataRoot
Root path for intake data catalogs. Defaults to .specify/intake/

.PARAMETER PersonaId
ID of the persona (e.g., 'product-manager', 'ux-ui-specialist').

.PARAMETER Mode
Resolved mode for this lens ('A', 'B', or 'C').

.EXAMPLE
$questions = Traverse-QuestionBank -PersonaId "architect" -Mode "B"

.NOTES
Mirror parity: This file must remain functionally identical to:
  .specify/extensions/specrew-speckit/scripts/intake/helpers/Traverse-QuestionBank.ps1
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$IntakeDataRoot,

    [Parameter(Mandatory = $true)]
    [string]$PersonaId,

    [Parameter(Mandatory = $true)]
    [ValidateSet('A', 'B', 'C')]
    [string]$Mode
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if ([string]::IsNullOrEmpty($IntakeDataRoot)) {
    $IntakeDataRoot = Join-Path (Get-Location) '.specify\intake'
}

$questionBankPath = Join-Path $IntakeDataRoot "questions\$PersonaId.yml"

if (-not (Test-Path $questionBankPath)) {
    Write-Warning "Question bank not found for persona '$PersonaId': $questionBankPath"
    return @()
}

try {
    $questionContent = Get-Content $questionBankPath -Raw
    
    # Use ConvertFrom-Yaml if available
    if (Get-Command ConvertFrom-Yaml -ErrorAction SilentlyContinue) {
        $questionData = $questionContent | ConvertFrom-Yaml
        $allQuestions = $questionData.questions
        
        if (-not $allQuestions) {
            return @()
        }
        
        # Filter questions by mode
        $filteredQuestions = switch ($Mode) {
            'A' {
                # Mode A: Minimal questions (priority='high' or tagged 'confirmation')
                $allQuestions | Where-Object {
                    $_.priority -eq 'high' -or $_.tags -contains 'confirmation'
                }
            }
            'B' {
                # Mode B: Targeted questions (priority='high' or 'medium'), limit to 2-3
                $targeted = $allQuestions | Where-Object {
                    $_.priority -eq 'high' -or $_.priority -eq 'medium'
                }
                $targeted | Select-Object -First 3
            }
            'C' {
                # Mode C: All questions (full interview)
                $allQuestions
            }
        }
        
        return $filteredQuestions
    } else {
        Write-Verbose "ConvertFrom-Yaml not available, returning empty question list"
        return @()
    }
} catch {
    Write-Error "Failed to traverse question bank for persona '$PersonaId': $_"
    return @()
}
