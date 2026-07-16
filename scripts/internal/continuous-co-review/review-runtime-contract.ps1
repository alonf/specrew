$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

function Test-ReviewRuntimeProcessSpec {
    param([Parameter(Mandatory)]$Spec, [Parameter(Mandatory)]$Invocation)
    $errors = [Collections.Generic.List[string]]::new()
    foreach ($name in @('schema_version', 'harness_id', 'command', 'argument_list', 'prompt_transport', 'working_directory', 'environment_delta', 'candidate_result_path', 'timeout_seconds', 'result_transport', 'stdout_authority')) {
        if (-not $Spec.PSObject.Properties[$name]) { $errors.Add("missing:$name") | Out-Null }
    }
    if ($errors.Count -eq 0) {
        if ([string]$Spec.schema_version -cne '1.0') { $errors.Add('unsupported-version') | Out-Null }
        if ([string]::IsNullOrWhiteSpace([string]$Spec.command)) { $errors.Add('command-empty') | Out-Null }
        if ([string]$Spec.prompt_transport -cnotin @('stdin', 'argument')) { $errors.Add('prompt-transport-invalid') | Out-Null }
        if ([string]$Spec.result_transport -cne 'file-primary' -or [bool]$Spec.stdout_authority) { $errors.Add('result-transport-invalid') | Out-Null }
        if (-not [IO.Directory]::Exists([string]$Spec.working_directory)) { $errors.Add('working-directory-missing') | Out-Null }
        elseif ([IO.Path]::GetFullPath([string]$Spec.working_directory) -cne [IO.Path]::GetFullPath([string]$Invocation.snapshot_path)) { $errors.Add('working-directory-mismatch') | Out-Null }
        if ([IO.Path]::GetFullPath([string]$Spec.candidate_result_path) -cne [IO.Path]::GetFullPath([string]$Invocation.candidate_result_path)) { $errors.Add('candidate-path-mismatch') | Out-Null }
        $timeout = 0
        if (-not [int]::TryParse([string]$Spec.timeout_seconds, [ref]$timeout) -or $timeout -lt 1 -or $timeout -gt 7200) { $errors.Add('timeout-invalid') | Out-Null }
        if ($Spec.argument_list -is [string] -or $Spec.argument_list -isnot [Collections.IEnumerable]) { $errors.Add('arguments-invalid') | Out-Null }
        if ($Spec.environment_delta -isnot [Collections.IDictionary]) { $errors.Add('environment-invalid') | Out-Null }
        else {
            foreach ($key in @($Spec.environment_delta.Keys)) {
                if ([string]$key -cnotin @('SPECREW_REFOCUS_DISABLE', 'SPECREW_DISABLE_EVENTS')) { $errors.Add("environment-key-invalid:$key") | Out-Null }
            }
        }
    }
    return [pscustomobject]@{ valid = ($errors.Count -eq 0); errors = @($errors) }
}
