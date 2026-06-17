$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

function Get-ContinuousCoReviewReviewerHostAdapterFunctionName {
    param(
        [Parameter(Mandatory)]
        [string] $AdapterId
    )

    switch ($AdapterId) {
        'reviewer-host-adapter-claude-prompt' { return 'Invoke-ContinuousCoReviewReviewerHostAdapterClaudePrompt' }
        'reviewer-host-adapter-codex-exec' { return 'Invoke-ContinuousCoReviewReviewerHostAdapterCodexExec' }
        'reviewer-host-adapter-copilot-prompt' { return 'Invoke-ContinuousCoReviewReviewerHostAdapterCopilotPrompt' }
        'reviewer-host-adapter-cursor-agent-prompt' { return 'Invoke-ContinuousCoReviewReviewerHostAdapterCursorAgentPrompt' }
        'reviewer-host-adapter-antigravity-prompt' { return 'Invoke-ContinuousCoReviewReviewerHostAdapterAntigravityPrompt' }
        'reviewer-host-adapter-fixture' { return 'Invoke-ContinuousCoReviewFixtureReviewerPath' }
        default { return $null }
    }
}

function Get-ContinuousCoReviewReviewerHostAdapterRegistry {
    param(
        [string] $AdapterRoot
    )

    $resolvedRoot = if ([string]::IsNullOrWhiteSpace($AdapterRoot)) {
        $PSScriptRoot
    }
    else {
        (Resolve-Path -LiteralPath $AdapterRoot).Path
    }

    $adapters = @(
        Get-ChildItem -LiteralPath $resolvedRoot -File -Filter 'reviewer-host-adapter-*.ps1' |
            Sort-Object -Property Name |
            ForEach-Object {
                $adapterId = [System.IO.Path]::GetFileNameWithoutExtension($_.Name)
                [pscustomobject][ordered]@{
                    adapter_id    = $adapterId
                    path          = $_.FullName
                    function_name = Get-ContinuousCoReviewReviewerHostAdapterFunctionName -AdapterId $adapterId
                }
            }
    )

    return [pscustomobject][ordered]@{
        schema_version = '1.0'
        adapter_root   = $resolvedRoot
        adapters       = @($adapters)
    }
}
