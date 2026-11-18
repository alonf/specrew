# The Nightly Truth-Check's tracking issue (FR-009). Run by the nightly workflow's notify job after the
# full-repository validation, whatever its result.
#
#   red night, no open issue        -> open one issue labelled nightly-truth-check (finding table, fingerprint)
#   red night, same fingerprint     -> nothing
#   red night, different fingerprint-> comment with the new table; store the new fingerprint in the body
#   green night, open issue         -> close it with a comment naming the run
#   green night, no open issue      -> nothing
#   validator job cancelled/skipped -> nothing
#
# The issue carries iteration ids, rule names, severities, the run id and the commit only. A value that is
# not an iteration id or a rule name in the expected form is rendered as "(unrecognized)", so no path, user
# or machine name can reach the issue even if the findings file holds one.
#
# -Gh is the gh command, injectable for tests: a scriptblock taking one string array of arguments and
# returning gh's standard output. The default runs the real gh CLI (GH_TOKEN and GH_REPO from the job).
# Returns the action taken: opened | commented | closed | none.

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('success', 'failure', 'cancelled', 'skipped')]
    [string]$ValidatorOutcome,

    [string]$FindingsJsonPath,

    [string]$RunId = '',

    [string]$Commit = '',

    [scriptblock]$Gh
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$label = 'nightly-truth-check'
$fingerprintPattern = 'nightly-fingerprint: ([0-9a-f]{64})'

if ($null -eq $Gh) {
    $Gh = {
        param([string[]]$GhArgs)
        $out = & gh @GhArgs
        if ($LASTEXITCODE -ne 0) { throw ("gh {0} {1} failed with exit code {2}" -f $GhArgs[0], $GhArgs[1], $LASTEXITCODE) }
        return (@($out) -join "`n")
    }
}

function ConvertTo-SafeToken {
    # Iteration ids ("<feature>/<NNN>" or "(repository)"), rule names and severities only; anything else is
    # rendered as "(unrecognized)".
    param([AllowNull()][string]$Value, [ValidateSet('iteration', 'rule', 'severity', 'hash')][string]$Kind)
    $v = if ($null -eq $Value) { '' } else { $Value.Trim() }
    $ok = switch ($Kind) {
        'iteration' { $v -ceq '(repository)' -or $v -match '^[A-Za-z0-9][A-Za-z0-9._-]*/[0-9]{3}$' }
        'rule' { $v -match '^[a-z0-9][a-z0-9-]*$' }
        'severity' { $v -match '^(error|warning)$' }
        'hash' { $v -match '^[0-9a-f]{8,64}$' }
    }
    if ($ok) { return $v }
    return '(unrecognized)'
}

function Get-NightlyFindings {
    param([string]$Path)
    if ([string]::IsNullOrWhiteSpace($Path) -or -not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        return @([pscustomobject]@{ iteration = '(repository)'; rule = 'findings-file-missing'; severity = 'error'; message_hash = '' })
    }
    $doc = Get-Content -LiteralPath $Path -Raw -Encoding UTF8 | ConvertFrom-Json
    $items = New-Object System.Collections.Generic.List[object]
    foreach ($f in @($doc.findings)) {
        if ($null -eq $f) { continue }
        $hash = if ($f.PSObject.Properties['message_hash']) { ConvertTo-SafeToken -Value ([string]$f.message_hash) -Kind 'hash' } else { '' }
        if ($hash -eq '(unrecognized)') { $hash = '' }
        $items.Add([pscustomobject]@{
                iteration    = ConvertTo-SafeToken -Value ([string]$f.iteration) -Kind 'iteration'
                rule         = ConvertTo-SafeToken -Value ([string]$f.rule) -Kind 'rule'
                severity     = ConvertTo-SafeToken -Value ([string]$f.severity) -Kind 'severity'
                message_hash = $hash
            }) | Out-Null
    }
    return @($items.ToArray())
}

function Get-FindingLine {
    param($Finding)
    $line = '{0}|{1}|{2}' -f $Finding.iteration, $Finding.rule, $Finding.severity
    # Review round 2, finding 4: the message hash counts for every finding that has one, categorized or not.
    if (-not [string]::IsNullOrWhiteSpace($Finding.message_hash)) {
        $line += '|' + $Finding.message_hash
    }
    return $line
}

function Get-NightlyFingerprint {
    # SHA-256 over the sorted iteration|rule|severity lines (plus each finding's message hash when it has one).
    param([object[]]$Findings)
    $lines = @($Findings | ForEach-Object { Get-FindingLine $_ } | Sort-Object -Unique -CaseSensitive)
    $bytes = [System.Text.Encoding]::UTF8.GetBytes(($lines -join "`n"))
    return ([System.BitConverter]::ToString([System.Security.Cryptography.SHA256]::HashData($bytes)) -replace '-', '').ToLowerInvariant()
}

function Format-FindingTable {
    param([object[]]$Findings)
    $rows = New-Object System.Collections.Generic.List[string]
    $rows.Add('| Iteration | Rule | Severity |') | Out-Null
    $rows.Add('| --- | --- | --- |') | Out-Null
    foreach ($f in @($Findings | Sort-Object iteration, rule, severity, message_hash)) {
        $rule = if ($f.message_hash) { '{0} ({1})' -f $f.rule, $f.message_hash } else { $f.rule }
        $rows.Add(('| {0} | {1} | {2} |' -f $f.iteration, $rule, $f.severity)) | Out-Null
    }
    return ($rows -join "`n")
}

function Get-RunLabel {
    $run = ConvertTo-SafeToken -Value $RunId -Kind 'hash'
    if ($RunId -match '^[0-9]+$') { $run = $RunId }
    $commit = if ($Commit -match '^[0-9a-f]{7,40}$') { $Commit.Substring(0, [Math]::Min(12, $Commit.Length)) } else { '(unrecognized)' }
    return ('run {0}, commit {1}' -f $run, $commit)
}

function Format-IssueBody {
    param([object[]]$Findings, [string]$Fingerprint)
    return @(
        ('The Nightly Truth-Check is red ({0}). {1} finding(s):' -f (Get-RunLabel), @($Findings).Count),
        '',
        (Format-FindingTable -Findings $Findings),
        '',
        'This issue is updated when the failure set changes and closed by the next green night.',
        '',
        ('<!-- {0} -->' -f ('nightly-fingerprint: ' + $Fingerprint))
    ) -join "`n"
}

if ($ValidatorOutcome -in @('cancelled', 'skipped')) {
    return 'none'
}

$listJson = & $Gh -GhArgs @('issue', 'list', '--label', $label, '--state', 'open', '--json', 'number,body', '--limit', '20')
$openIssues = @()
if (-not [string]::IsNullOrWhiteSpace([string]$listJson)) {
    $openIssues = @(([string]$listJson | ConvertFrom-Json) | Where-Object { $null -ne $_ } | Sort-Object { [int]$_.number })
}
$issue = if ($openIssues.Count -gt 0) { $openIssues[0] } else { $null }

if ($ValidatorOutcome -eq 'success') {
    if ($null -eq $issue) { return 'none' }
    $null = & $Gh -GhArgs @('issue', 'close', ([string]$issue.number), '--comment', ('Green on {0}. Closing.' -f (Get-RunLabel)))
    return 'closed'
}

# failure
$findings = @(Get-NightlyFindings -Path $FindingsJsonPath)
if ($findings.Count -eq 0) {
    $findings = @([pscustomobject]@{ iteration = '(repository)'; rule = 'red-with-no-findings'; severity = 'error'; message_hash = '' })
}
$fingerprint = Get-NightlyFingerprint -Findings $findings
$body = Format-IssueBody -Findings $findings -Fingerprint $fingerprint

if ($null -eq $issue) {
    $null = & $Gh -GhArgs @('label', 'create', $label, '--force', '--color', 'B60205', '--description', 'Nightly Truth-Check failures')
    $null = & $Gh -GhArgs @('issue', 'create', '--title', 'Nightly Truth-Check is red', '--label', $label, '--body', $body)
    return 'opened'
}

$stored = [regex]::Match([string]$issue.body, $fingerprintPattern)
if ($stored.Success -and $stored.Groups[1].Value -eq $fingerprint) {
    return 'none'
}

$comment = @(
    ('The failure set changed ({0}). {1} finding(s):' -f (Get-RunLabel), $findings.Count),
    '',
    (Format-FindingTable -Findings $findings)
) -join "`n"
$null = & $Gh -GhArgs @('issue', 'comment', ([string]$issue.number), '--body', $comment)
$null = & $Gh -GhArgs @('issue', 'edit', ([string]$issue.number), '--body', $body)
return 'commented'
