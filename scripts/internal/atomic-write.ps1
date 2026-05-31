<#
.SYNOPSIS
    Shared atomic file-write primitive for Specrew multi-session state (F-051).

.DESCRIPTION
    `Write-SpecrewFileAtomic` writes text to a path atomically: write to a `.tmp`
    sibling, then `Move-Item -Force`. `Move-Item` is atomic on the same volume, so no
    reader ever observes a partial write - the race-safe pattern from the F-051 research
    (R3). This is the SINGLE source of the primitive; session-config, session-management,
    and feature-claims all dot-source this file rather than duplicating the body (extracted
    in Iteration 2a, T020).

    NOTE on the concurrency guarantee (do not overstate): atomicity gives torn-write
    safety (the file is always valid), NOT lost-update prevention. A whole-file
    read-modify-write is last-write-wins; no-permanent-loss is delivered at a higher layer
    by FR-014 boundary-refresh re-add + duplicate surfacing, not by this primitive.
#>

Set-StrictMode -Version Latest

function Write-SpecrewFileAtomic {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][AllowEmptyString()][string]$Content
    )

    $tempPath = '{0}.{1}.tmp' -f $Path, ([System.Guid]::NewGuid().ToString('N'))
    $utf8NoBom = [System.Text.UTF8Encoding]::new($false)
    [System.IO.File]::WriteAllText($tempPath, $Content, $utf8NoBom)
    Move-Item -LiteralPath $tempPath -Destination $Path -Force
}
