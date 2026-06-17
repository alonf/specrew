$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

function New-ContinuousCoReviewVisibilityPolicy {
    param(
        [string[]] $AllowedDesignContextPatterns = @(
            'spec.md',
            'workshop/*.md',
            'iterations/001/design-analysis.md',
            'implementation-rules.yml'
        )
    )

    return [pscustomobject][ordered]@{
        schema_version                  = '1.0'
        allowed_design_context_patterns = @($AllowedDesignContextPatterns)
        redaction_policy                = [pscustomobject][ordered]@{
            omits_raw_prompts            = $true
            omits_raw_transcripts        = $true
            omits_environment_variables  = $true
            omits_token_stores           = $true
            omits_unrelated_temp_files   = $true
            omits_ambient_machine_state  = $true
            persists_structured_refs_only = $true
        }
    }
}
