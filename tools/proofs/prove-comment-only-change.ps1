<#
.SYNOPSIS
    Proves that a change to a PowerShell file altered COMMENTS ONLY, by comparing executable token streams.

.DESCRIPTION
    A diff that "looks like comments" is a reading, not a proof. This parses both versions with the
    PowerShell AST parser, drops Comment tokens, and compares what remains token-by-token including text.

    Runs of NewLine are collapsed to a single separator. Newlines are NOT noise in PowerShell - they
    separate statements - but removing a comment LINE removes the newline that ended it, which is not an
    executable change. Collapsing tolerates that while still catching a genuine statement join or split.

    Each file asserts its own precondition: the two versions must actually DIFFER. A proof that silently
    compares a file to itself proves nothing.

    Exit code 0 = every file is executable-identical. 1 = executable code changed.
#>
[CmdletBinding()]
param(
    [string]$RepoRoot,
    [string]$BaseRef = '4f4dce52',
    [string[]]$Files = @(
        'extensions/specrew-speckit/scripts/shared-governance.ps1',
        'extensions/specrew-speckit/scripts/workshop-authority-store.ps1',
        'extensions/specrew-speckit/scripts/confirm-workshop-lens.ps1',
        'extensions/specrew-speckit/scripts/specrew-conformance-provider.ps1'
    )
)

$ErrorActionPreference = 'Stop'
if ([string]::IsNullOrWhiteSpace($RepoRoot)) { $RepoRoot = (& git rev-parse --show-toplevel) }

function Get-ExecutableStream {
    param([string]$Text, [string]$Label)
    $tokens = $null; $errors = $null
    $null = [System.Management.Automation.Language.Parser]::ParseInput($Text, [ref]$tokens, [ref]$errors)
    if ($errors -and $errors.Count -gt 0) { throw "PARSE ERRORS in ${Label}: $($errors.Count)" }
    $noComment = @($tokens | Where-Object { $_.Kind -ne 'Comment' })
    $collapsed = [System.Collections.Generic.List[string]]::new()
    $previousWasNewLine = $false
    foreach ($token in $noComment) {
        if ($token.Kind -eq 'NewLine') {
            if (-not $previousWasNewLine) { [void]$collapsed.Add('NewLine') }
            $previousWasNewLine = $true
            continue
        }
        $previousWasNewLine = $false
        [void]$collapsed.Add(('{0}|{1}' -f $token.Kind, $token.Text))
    }
    return [pscustomobject]@{ Raw = @($noComment).Count; Exec = @($collapsed) }
}

"{0,-38} {1,9} {2,9} {3,9} {4,9}  {5}" -f 'file', 'raw base', 'raw cand', 'exec base', 'exec cand', 'executable token stream'
('-' * 118)

$allInert = $true
foreach ($file in $Files) {
    $baseText = (& git -C $RepoRoot show "${BaseRef}:$file" | Out-String)
    $candText = (& git -C $RepoRoot show "HEAD:$file" | Out-String)
    if ($baseText -ceq $candText) { throw "PRECONDITION FAILED: $file is identical between $BaseRef and HEAD - it must be part of the delta being proven" }

    $baseStream = Get-ExecutableStream -Text $baseText -Label "$file@$BaseRef"
    $candStream = Get-ExecutableStream -Text $candText -Label "$file@HEAD"

    $identical = ($baseStream.Exec.Count -eq $candStream.Exec.Count)
    if ($identical) {
        for ($i = 0; $i -lt $baseStream.Exec.Count; $i++) {
            if ($baseStream.Exec[$i] -cne $candStream.Exec[$i]) { $identical = $false; break }
        }
    }
    if (-not $identical) { $allInert = $false }

    "{0,-38} {1,9} {2,9} {3,9} {4,9}  {5}" -f (Split-Path $file -Leaf), $baseStream.Raw, $candStream.Raw, $baseStream.Exec.Count, $candStream.Exec.Count, $(if ($identical) { 'IDENTICAL - inert' } else { 'DIFFERS - NOT inert' })
}

('-' * 118)
if ($allInert) {
    "RESULT: all $(@($Files).Count) files are EXECUTABLE-IDENTICAL between $BaseRef and the candidate."
    'The only differences are comment text and the newlines that comment lines carry.'
    exit 0
}
"RESULT: executable code changed."
exit 1
