Set-StrictMode -Version Latest

# F-184 iteration 002 (T002; FR-012 / FR-013 / FR-015 / FR-018): the single packaged
# source for the Specrew coordinator instruction section, plus the delimited
# managed-section merge primitive.
#
# Host-neutral by construction (FR-015): nothing here knows about a specific host or
# `agy`/Antigravity literals; callers pass the manifest-declared InstructionsFile path.
# The merge replaces ONLY the delimited Specrew-owned section and preserves every other
# byte of the target file (FR-012 / SC-012).

# Size budget vs Codex's 32 KiB AGENTS.md concatenation cap (before-implement verdict
# carry, 2026-06-17): hold the packaged fragment lean so a Specrew section atop a large
# user AGENTS.md cannot push the root->cwd concatenation past the cap.
$script:SpecrewCoordinatorFragmentMaxBytes = 4096
$script:SpecrewCoordinatorSectionName = 'coordinator'

function Get-SpecrewInstructionBeginMarker {
    param([Parameter(Mandatory = $true)][string]$SectionName)
    return ('<!-- >>> specrew-managed {0} >>> -->' -f $SectionName)
}

function Get-SpecrewInstructionEndMarker {
    param([Parameter(Mandatory = $true)][string]$SectionName)
    return ('<!-- <<< specrew-managed {0} <<< -->' -f $SectionName)
}

function Get-SpecrewCoordinatorFragmentPath {
    # scripts/internal -> module root -> templates/coordinator-instructions.md
    $moduleRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    return (Join-Path $moduleRoot 'templates\coordinator-instructions.md')
}

function Get-SpecrewCoordinatorFragment {
    # FR-018 single source: the packaged coordinator fragment content (trimmed). Both the
    # instruction-file merge (T002/T003) and the bootstrap (T004) read THIS function, so
    # the coordinator contract + the FR-013 guard text cannot drift between the two surfaces.
    $path = Get-SpecrewCoordinatorFragmentPath
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        throw "Packaged coordinator fragment not found at '$path'."
    }
    $fragment = (Get-Content -LiteralPath $path -Raw -Encoding UTF8).Trim()
    # Enforce the size budget at READ time (not only in tests): a packaged fragment that grows past
    # the cap would push a Specrew section atop a large user AGENTS.md past Codex's 32 KiB root->cwd
    # concatenation limit and silently regress startup. Fail loudly on the packaging regression.
    $fragmentBytes = [System.Text.Encoding]::UTF8.GetByteCount($fragment)
    if ($fragmentBytes -gt $script:SpecrewCoordinatorFragmentMaxBytes) {
        throw ("Packaged coordinator fragment is $fragmentBytes bytes, over the $($script:SpecrewCoordinatorFragmentMaxBytes)-byte budget (Codex AGENTS.md cap). Trim '$path'.")
    }
    return $fragment
}

function Merge-SpecrewManagedInstructionSection {
    # Pure: return $ExistingContent with the delimited managed section inserted (when
    # absent) or refreshed in place (when present), preserving every byte outside the
    # marker block. String-slicing, not regex replacement, so the preserved prefix/suffix
    # are byte-exact and replacement text needs no escaping.
    param(
        [AllowNull()][AllowEmptyString()][string]$ExistingContent,
        [Parameter(Mandatory = $true)][string]$ManagedContent,
        [string]$SectionName = $script:SpecrewCoordinatorSectionName
    )

    $begin = Get-SpecrewInstructionBeginMarker -SectionName $SectionName
    $end = Get-SpecrewInstructionEndMarker -SectionName $SectionName
    $block = $begin + [Environment]::NewLine + $ManagedContent.Trim() + [Environment]::NewLine + $end
    $existing = if ($null -eq $ExistingContent) { '' } else { $ExistingContent }

    $beginIdx = $existing.IndexOf($begin, [System.StringComparison]::Ordinal)
    if ($beginIdx -ge 0) {
        $endIdx = $existing.IndexOf($end, $beginIdx, [System.StringComparison]::Ordinal)
        if ($endIdx -ge 0) {
            $endIdx += $end.Length
            $prefix = $existing.Substring(0, $beginIdx)
            $suffix = $existing.Substring($endIdx)
            return $prefix + $block + $suffix
        }
    }

    if ([string]::IsNullOrEmpty($existing)) {
        return $block + [Environment]::NewLine
    }

    # Append after preserved user content with a blank-line separator.
    $separator = if ($existing.EndsWith("`n")) { [Environment]::NewLine } else { [Environment]::NewLine + [Environment]::NewLine }
    return $existing + $separator + $block + [Environment]::NewLine
}

function Set-SpecrewInstructionFileSection {
    # Deploy/refresh the managed section into the InstructionsFile at $Path. Reads the
    # current file (or treats it as empty), merges, and writes atomically ONLY when the
    # content changed (idempotent: init/update/start-heal converge without rewriting an
    # already-current file). Returns { Path, Changed, Created }.
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$ManagedContent,
        [string]$SectionName = $script:SpecrewCoordinatorSectionName
    )

    $existed = Test-Path -LiteralPath $Path -PathType Leaf
    $existing = if ($existed) { Get-Content -LiteralPath $Path -Raw -Encoding UTF8 } else { '' }
    if ($null -eq $existing) { $existing = '' }
    $merged = Merge-SpecrewManagedInstructionSection -ExistingContent $existing -ManagedContent $ManagedContent -SectionName $SectionName

    $changed = ($merged -ne $existing)
    if ($changed) {
        $dir = Split-Path -Parent $Path
        if (-not [string]::IsNullOrWhiteSpace($dir) -and -not (Test-Path -LiteralPath $dir -PathType Container)) {
            $null = New-Item -ItemType Directory -Path $dir -Force
        }
        $tempPath = '{0}.{1}.tmp' -f $Path, ([guid]::NewGuid().ToString('N'))
        $backupPath = $null
        try {
            [System.IO.File]::WriteAllText($tempPath, $merged, [System.Text.UTF8Encoding]::new($false))
            if (Test-Path -LiteralPath $Path -PathType Leaf) {
                # Atomic in-place swap via the repo's established primitive (HandoverStore uses the same
                # [IO.File]::Replace = Win32 ReplaceFile): one call swaps in the new file and preserves the
                # destination's attributes. File.Replace REQUIRES a backup path (a bare $null marshals to an
                # empty string in PowerShell and throws), so use a transient backup and remove it below.
                $backupPath = '{0}.{1}.bak' -f $Path, ([guid]::NewGuid().ToString('N'))
                [System.IO.File]::Replace($tempPath, $Path, $backupPath)
            }
            else {
                [System.IO.File]::Move($tempPath, $Path)
            }
        }
        finally {
            foreach ($cleanup in @($tempPath, $backupPath)) {
                if ($cleanup -and (Test-Path -LiteralPath $cleanup -PathType Leaf)) {
                    Remove-Item -LiteralPath $cleanup -Force -ErrorAction SilentlyContinue
                }
            }
        }
    }

    return [pscustomobject]@{ Path = $Path; Changed = $changed; Created = (-not $existed) }
}
