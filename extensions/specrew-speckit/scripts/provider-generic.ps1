#!/usr/bin/env pwsh
# Generic / unknown provider fallback (Feature 182).
#
# Always present. It makes NO forge API call and reports only what is true without one:
#   - if any CI configuration is detectable in the repo -> `ci-only` (the work-kind validator can
#     run as a CI check, but CI cannot prevent a direct push)
#   - otherwise -> `manual` (human-enforced; no automated gate)
# It NEVER promises branch protection it cannot apply. The read_pr_context fallback is the
# forge-neutral `git diff` in provider-adapter.ps1 (Get-SpecrewPrContext).

function Get-SpecrewGenericCapability {
    [CmdletBinding()]
    param(
        [string]$ProjectPath = '.',
        [string]$Provider = 'generic'
    )
    $ciSignals = @(
        '.github/workflows',
        '.gitlab-ci.yml',
        'azure-pipelines.yml',
        '.azuredevops',
        '.circleci',
        'Jenkinsfile',
        '.drone.yml',
        'bitbucket-pipelines.yml'
    )
    $hasCi = $false
    foreach ($s in $ciSignals) {
        if (Test-Path -LiteralPath (Join-Path $ProjectPath $s)) { $hasCi = $true; break }
    }
    $mechanism = if ($hasCi) { 'ci-only' } else { 'manual' }
    $constraints = [System.Collections.Generic.List[string]]::new()
    if ($hasCi) {
        $constraints.Add('CI detected: the work-kind validator can run as a CI check, but CI cannot prevent a direct push — branch protection is not enforced without a forge adapter') | Out-Null
    }
    else {
        $constraints.Add('no CI detected: enforcement is manual (human review); add the work-kind validator to your CI to get the ci-only semantic layer') | Out-Null
    }
    $constraints.Add('name your forge to synthesize a read-only adapter for automated capability detection (apply_protection stays human-approved)') | Out-Null
    return [ordered]@{
        provider    = $Provider
        mechanism   = $mechanism
        constraints = @($constraints.ToArray())
    }
}
