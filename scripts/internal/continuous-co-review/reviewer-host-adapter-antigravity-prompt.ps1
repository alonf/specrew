$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

function Invoke-ContinuousCoReviewReviewerHostAdapterAntigravityPrompt {
    param(
        [Parameter(Mandatory)]
        $Request,

        [Parameter(Mandatory)]
        [string] $RequestBundlePath,

        [string] $SchemaRoot,

        [scriptblock] $InvokeProcess,

        [AllowNull()]
        $Candidate,

        [int] $AttemptNumber = 1,

        [datetime] $CreatedAt = [datetime]::UtcNow
    )

    return Invoke-ContinuousCoReviewReviewerHostAdapterCommand -Request $Request -RequestBundlePath $RequestBundlePath -AdapterId 'reviewer-host-adapter-antigravity-prompt' -Executable 'antigravity' -ArgumentList @('-p') -SchemaRoot $SchemaRoot -InvokeProcess $InvokeProcess -Candidate $Candidate -AttemptNumber $AttemptNumber -CreatedAt $CreatedAt
}
