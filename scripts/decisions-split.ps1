<#
.SYNOPSIS
    Split the legacy Squad decisions ledger into per-iteration ledgers (F-051 Iteration 2b).

.DESCRIPTION
    Multi-session mode keeps `.squad/decisions.md` readable for backwards compatibility,
    but mirrors iteration-scoped entries into `.squad/decisions/iteration-NNN/decisions.md`
    so concurrently active iterations have a smaller merge-conflict surface.
#>

Set-StrictMode -Version Latest

. (Join-Path $PSScriptRoot 'internal\atomic-write.ps1')

function Get-SpecrewDecisionsLedgerPath {
    param([Parameter(Mandatory = $true)][string]$ProjectRoot)
    return (Join-Path $ProjectRoot '.squad/decisions.md')
}

function Get-SpecrewIterationDecisionsPath {
    param(
        [Parameter(Mandatory = $true)][string]$ProjectRoot,
        [Parameter(Mandatory = $true)][string]$IterationNumber
    )

    $normalized = Normalize-SpecrewDecisionIterationNumber -IterationNumber $IterationNumber
    return (Join-Path $ProjectRoot ('.squad/decisions/iteration-{0}/decisions.md' -f $normalized))
}

function Normalize-SpecrewDecisionIterationNumber {
    param([Parameter(Mandatory = $true)][string]$IterationNumber)

    $trimmed = $IterationNumber.Trim()
    if ($trimmed -match '^\d+$') {
        return ([int]$trimmed).ToString('000')
    }

    return $trimmed
}

function Get-SpecrewDecisionEntries {
    param([Parameter(Mandatory = $true)][AllowEmptyString()][string]$Content)

    if ([string]::IsNullOrWhiteSpace($Content)) { return @() }

    $matches = [regex]::Matches($Content, '(?ms)^##\s+.+?(?=^##\s+|\z)')
    $entries = New-Object System.Collections.Generic.List[string]
    foreach ($match in $matches) {
        $text = $match.Value.Trim()
        if (-not [string]::IsNullOrWhiteSpace($text)) {
            $entries.Add($text) | Out-Null
        }
    }

    return $entries.ToArray()
}

function Get-SpecrewDecisionEntryIterationNumber {
    param([Parameter(Mandatory = $true)][string]$Entry)

    $patterns = @(
        '(?im)^\s*-\s+\*\*Iteration Number\*\*:\s*(?<iteration>[A-Za-z0-9_-]+)\s*$',
        '(?im)^\s*-\s+\*\*Affected Iteration\*\*:\s*(?<iteration>[A-Za-z0-9_-]+)\s*$',
        '(?im)^\s*-\s+\*\*Iteration\*\*:\s*(?<iteration>[A-Za-z0-9_-]+)\s*$'
    )

    foreach ($pattern in $patterns) {
        if ($Entry -match $pattern) {
            $raw = $Matches['iteration'].Trim()
            if ($raw -notin @('', '(none)', 'none', 'n/a')) {
                return (Normalize-SpecrewDecisionIterationNumber -IterationNumber $raw)
            }
        }
    }

    return $null
}

function ConvertTo-SpecrewDecisionFileContent {
    param(
        [Parameter(Mandatory = $true)][string]$IterationNumber,
        [AllowEmptyCollection()][AllowNull()][string[]]$Entries
    )

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add(('# Decisions: Iteration {0}' -f $IterationNumber)) | Out-Null
    $lines.Add('') | Out-Null
    $lines.Add('Mirrored from `.squad/decisions.md` for F-051 multi-session conflict reduction.') | Out-Null
    $lines.Add('') | Out-Null

    foreach ($entry in @($Entries | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | Select-Object -Unique)) {
        $lines.Add($entry.Trim()) | Out-Null
        $lines.Add('') | Out-Null
    }

    return (($lines -join [Environment]::NewLine).TrimEnd() + [Environment]::NewLine)
}

function Split-SpecrewDecisionsByIteration {
    param(
        [Parameter(Mandatory = $true)][string]$ProjectRoot,
        [switch]$PassThru
    )

    $ledgerPath = Get-SpecrewDecisionsLedgerPath -ProjectRoot $ProjectRoot
    if (-not (Test-Path -LiteralPath $ledgerPath -PathType Leaf)) {
        if ($PassThru) {
            return [pscustomobject]@{ written_count = 0; iteration_numbers = @(); source_path = $ledgerPath }
        }
        return
    }

    $content = Get-Content -LiteralPath $ledgerPath -Raw -Encoding UTF8
    $groups = [ordered]@{}
    foreach ($entry in Get-SpecrewDecisionEntries -Content $content) {
        $iteration = Get-SpecrewDecisionEntryIterationNumber -Entry $entry
        if ([string]::IsNullOrWhiteSpace($iteration)) { continue }
        if (-not $groups.Contains($iteration)) {
            $groups[$iteration] = New-Object System.Collections.Generic.List[string]
        }
        $groups[$iteration].Add($entry) | Out-Null
    }

    $written = 0
    foreach ($iteration in $groups.Keys) {
        $targetPath = Get-SpecrewIterationDecisionsPath -ProjectRoot $ProjectRoot -IterationNumber $iteration
        $targetDir = Split-Path -Parent $targetPath
        if (-not (Test-Path -LiteralPath $targetDir -PathType Container)) {
            New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
        }

        $nextContent = ConvertTo-SpecrewDecisionFileContent -IterationNumber $iteration -Entries $groups[$iteration].ToArray()
        $currentContent = if (Test-Path -LiteralPath $targetPath -PathType Leaf) { Get-Content -LiteralPath $targetPath -Raw -Encoding UTF8 } else { $null }
        if ($currentContent -ne $nextContent) {
            Write-SpecrewFileAtomic -Path $targetPath -Content $nextContent
            $written++
        }
    }

    if ($PassThru) {
        return [pscustomobject]@{
            written_count     = $written
            iteration_numbers = @($groups.Keys)
            source_path       = $ledgerPath
        }
    }
}

if ($MyInvocation.InvocationName -ne '.') {
    $projectRoot = if ($args.Count -gt 0 -and -not [string]::IsNullOrWhiteSpace([string]$args[0])) { [string]$args[0] } else { (Get-Location).Path }
    Split-SpecrewDecisionsByIteration -ProjectRoot $projectRoot -PassThru | ConvertTo-Json -Depth 5
}
