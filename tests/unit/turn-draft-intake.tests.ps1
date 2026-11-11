# Feature 202 T014 (FR-021; US6; DA-4) brought turn drafts in over stdin; feature 203 T011's follow-up (FR-046; maintainer
# ruling 2026-11-11, item 1) removed the draft. The Stop reads the packet from the reply itself, so declare-turn-end.ps1
# reads nothing from stdin or a draft file, stores no message, and no skill asks for a draft.
#
# What this suite proved for the draft it now proves for its absence: (1) a draft piped on stdin is not read or stored;
# (2) two sessions declaring at once each get their own record; (3) a host with no session id declares as before; (4) a
# -MessagePath draft is not read; (5) an open, silent stdin does not hang the declaration; (6) bytes that are not UTF-8
# on stdin no longer matter; (7) the turn record is git-ignored; (8) no skill asks for a piped draft or a draft file;
# (9) no shipped file names the old draft copy.
#
# RED before the T011 follow-up: the script read stdin and -MessagePath and kept the message in the record.
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$scriptsDir = Join-Path $repoRoot 'extensions/specrew-speckit/scripts'
$declare = Join-Path $scriptsDir 'declare-turn-end.ps1'
. (Join-Path $scriptsDir 'turn-end-store.ps1')
. (Join-Path $repoRoot 'scripts/internal/file-classification.ps1')
$script:failCount = 0
$platform = if ($IsWindows) { 'windows' } elseif ($IsMacOS) { 'macos' } else { 'linux' }
function Write-Pass { param([string]$Message) Write-Host "PASS: $Message" -ForegroundColor Green }
function Write-Fail { param([string]$Message) Write-Host "FAIL: $Message" -ForegroundColor Red; $script:failCount++ }
function Assert-True { param([bool]$Condition, [string]$Message) if ($Condition) { Write-Pass $Message } else { Write-Fail $Message } }

function Start-Declare {
    # Runs the script the way an agent's shell does: a separate pwsh whose stdin is a pipe. The draft is written as
    # raw bytes, so what arrives is exactly what an agent's shell sends, whatever the child's console encoding is.
    param([string]$Root, [string]$Token, [string]$Kind = 'conversational', [byte[]]$Bytes, [switch]$LeaveStdinOpen, [string[]]$Extra = @())
    $psi = [Diagnostics.ProcessStartInfo]::new('pwsh')
    foreach ($a in @('-NoProfile', '-NonInteractive', '-File', $declare, '-Kind', $Kind, '-ProjectRoot', $Root, '-AsJson') + $(if ($Token) { @('-Token', $Token) } else { @() }) + $Extra) { $psi.ArgumentList.Add($a) }
    $psi.UseShellExecute = $false; $psi.CreateNoWindow = $true
    $psi.RedirectStandardInput = $true; $psi.RedirectStandardOutput = $true; $psi.RedirectStandardError = $true
    $p = [Diagnostics.Process]::Start($psi)
    $out = $p.StandardOutput.ReadToEndAsync(); $err = $p.StandardError.ReadToEndAsync()
    if ($null -ne $Bytes) { $p.StandardInput.BaseStream.Write($Bytes, 0, $Bytes.Length); $p.StandardInput.BaseStream.Flush() }
    if (-not $LeaveStdinOpen) { $p.StandardInput.Close() }
    return [pscustomobject]@{ Process = $p; Out = $out; Err = $err; Stdin = $p.StandardInput }
}

function Complete-Declare {
    param($Run, [int]$TimeoutMs = 60000)
    $finished = $Run.Process.WaitForExit($TimeoutMs)
    if (-not $finished) { $Run.Process.Kill($true) }
    $json = $null
    try { $json = $Run.Out.Result | ConvertFrom-Json -ErrorAction Stop } catch { $json = $null }
    return [pscustomobject]@{ Finished = $finished; ExitCode = $(if ($finished) { $Run.Process.ExitCode } else { -1 }); Json = $json; StdErr = $Run.Err.Result; StdOut = $Run.Out.Result }
}

function New-SessionRoot {
    param([string]$Root, [string]$HostKind, [string]$SessionId)
    $hash = Get-SpecrewTurnEndOwnerHash -HostKind $HostKind -SessionId $SessionId
    $stateRoot = Join-Path (Join-Path $Root '.specrew/runtime/conformance-sessions') $hash
    $token = Write-SpecrewTurnToken -StateRoot $stateRoot -TurnId 'turn-1'
    return [pscustomobject]@{ Hash = $hash; Token = $token }
}

function Get-DraftCopies {
    # Any draft copy, under any name the old store used: per session, per token or shared.
    param([string]$Root)
    $turnEnd = [IO.Path]::Combine($Root, '.specrew', 'runtime', 'turn-end')
    if (-not (Test-Path -LiteralPath $turnEnd)) { return @() }
    return @(Get-ChildItem -LiteralPath $turnEnd -Recurse -File -Filter 'turn-message.md' | ForEach-Object { $_.FullName })
}

function Get-RecordMessage {
    param($Result)
    if ($null -eq $Result.Json) { return $null }
    $record = Read-SpecrewTurnEndRecord -Path ([string]$Result.Json.record_path)
    if ($null -eq $record) { return $null }
    return $(if ($record.PSObject.Properties['message']) { [string]$record.message } else { '' })
}

function Test-NoDraftFields {
    param($Result)
    if ($null -eq $Result.Json) { return $false }
    $names = @($Result.Json.PSObject.Properties.Name)
    $record = Read-SpecrewTurnEndRecord -Path ([string]$Result.Json.record_path)
    $recordNames = if ($null -ne $record) { @($record.PSObject.Properties.Name) } else { @() }
    return (@($names + $recordNames | Where-Object { $_ -in 'draft_path', 'draft_scope', 'draft_disclosure' }).Count -eq 0)
}

$root = [IO.Path]::GetFullPath([IO.Path]::Combine([IO.Path]::GetTempPath(), 'tdi-' + [guid]::NewGuid().ToString('N').Substring(0, 8)))
[IO.Directory]::CreateDirectory([IO.Path]::Combine($root, '.specrew', 'runtime')) | Out-Null
try {
    $hebrew = "שלום עולם — the human's question, in Hebrew and English.`r`nשורה שנייה: האם להמשיך? ✅ 🚀 Ünïcödé`r`n"
    $hebrewBytes = [Text.UTF8Encoding]::new($false).GetBytes($hebrew)

    # 1. A draft piped on stdin is not read: nothing of it reaches the record, and no copy is written.
    $a = New-SessionRoot -Root $root -HostKind 'claude' -SessionId 'session-a'
    $r = Complete-Declare (Start-Declare -Root $root -Token $a.Token -Bytes $hebrewBytes)
    Assert-True ($r.ExitCode -eq 0) "[$platform] (1) the declaration with a piped draft succeeds (exit $($r.ExitCode); $($r.StdErr.Trim()))"
    Assert-True ([string]::IsNullOrEmpty((Get-RecordMessage $r)) -and [string]$r.Json.draft_source -eq 'none') "[$platform] (1) the piped draft is not read or stored (draft_source '$([string]$r.Json.draft_source)')"
    Assert-True (@(Get-DraftCopies $root).Count -eq 0) "[$platform] (1) no draft copy is written ($((Get-DraftCopies $root) -join ', '))"
    Assert-True (Test-NoDraftFields $r) "[$platform] (1) neither the record nor the script's report names a draft copy"

    # 2. Two sessions declaring at the same moment each get their own record.
    $b = New-SessionRoot -Root $root -HostKind 'claude' -SessionId 'session-b'
    $c = New-SessionRoot -Root $root -HostKind 'codex' -SessionId 'session-c'
    $runB = Start-Declare -Root $root -Token $b.Token
    $runC = Start-Declare -Root $root -Token $c.Token
    $rB = Complete-Declare $runB; $rC = Complete-Declare $runC
    Assert-True ($rB.ExitCode -eq 0 -and $rC.ExitCode -eq 0) "[$platform] (2) two concurrent declarations both succeed"
    Assert-True ([string]$rB.Json.record_path -ne [string]$rC.Json.record_path) "[$platform] (2) the two sessions' records are separate files"

    # 3. A host that passes no session id still declares, and nothing is said about a draft.
    $legacy = [IO.Path]::GetFullPath([IO.Path]::Combine([IO.Path]::GetTempPath(), 'tdi-l-' + [guid]::NewGuid().ToString('N').Substring(0, 8)))
    [IO.Directory]::CreateDirectory([IO.Path]::Combine($legacy, '.specrew', 'runtime')) | Out-Null
    try {
        $legacyToken = Write-SpecrewTurnToken -StateRoot ([IO.Path]::Combine($legacy, '.specrew', 'runtime')) -TurnId 'turn-1'
        $r = Complete-Declare (Start-Declare -Root $legacy -Token $legacyToken -Bytes ([Text.Encoding]::UTF8.GetBytes("no session id`n")))
        Assert-True ($r.ExitCode -eq 0 -and [string]::IsNullOrEmpty((Get-RecordMessage $r))) "[$platform] (3) without a session id the turn is declared, and no message is stored"
        Assert-True (@(Get-DraftCopies $legacy).Count -eq 0 -and (Test-NoDraftFields $r)) "[$platform] (3) no draft copy is written or reported"
        Assert-True ($r.StdErr -notmatch 'draft') "[$platform] (3) nothing is said about a draft"
    }
    finally { Remove-Item -LiteralPath $legacy -Recurse -Force -ErrorAction SilentlyContinue }

    # 4. A -MessagePath draft is accepted and not read.
    $d = New-SessionRoot -Root $root -HostKind 'copilot' -SessionId 'session-d'
    $file = Join-Path $root 'legacy-draft.md'
    [IO.File]::WriteAllBytes($file, $hebrewBytes)
    $r = Complete-Declare (Start-Declare -Root $root -Token $d.Token -Extra @('-MessagePath', $file))
    Assert-True ($r.ExitCode -eq 0 -and [string]::IsNullOrEmpty((Get-RecordMessage $r)) -and [string]$r.Json.draft_source -eq 'none') "[$platform] (4) -MessagePath is accepted and not read"
    Assert-True (@(Get-DraftCopies $root).Count -eq 0) "[$platform] (4) a -MessagePath draft is not copied"
    # Maintainer ruling 2026-11-11: an old caller learns, once, that its draft is not read.
    $notice = @(($r.StdErr -split '\r?\n') | Where-Object { $_ -like '*-MessagePath is no longer read*' })
    Assert-True ($notice.Count -eq 1) "[$platform] (4) stderr says once that -MessagePath is not read ($($r.StdErr.Trim()))"
    $rNo = Complete-Declare (Start-Declare -Root $root -Token $d.Token)
    Assert-True ($rNo.StdErr -notmatch 'MessagePath') "[$platform] (4) without -MessagePath nothing is said about it"

    # 5. A shell that leaves stdin open and sends nothing must not hang the turn end.
    $e = New-SessionRoot -Root $root -HostKind 'claude' -SessionId 'session-e'
    $sw = [Diagnostics.Stopwatch]::StartNew()
    $run = Start-Declare -Root $root -Token $e.Token -LeaveStdinOpen
    $r = Complete-Declare $run -TimeoutMs 30000
    try { $run.Stdin.Close() } catch { $null = $_ }
    Assert-True ($r.Finished -and $r.ExitCode -eq 0) ("[$platform] (5) an open, silent stdin does not hang the declaration ({0:N1} s)" -f $sw.Elapsed.TotalSeconds)

    # 6. Bytes that are not UTF-8 on stdin are not read, so they no longer refuse the declaration.
    $f = New-SessionRoot -Root $root -HostKind 'claude' -SessionId 'session-f'
    $r = Complete-Declare (Start-Declare -Root $root -Token $f.Token -Bytes ([byte[]](0x53, 0x68, 0xE9, 0x6C, 0x6F, 0x6D, 0xFF, 0x0A)))
    Assert-True ($r.ExitCode -eq 0) "[$platform] (6) bytes on stdin that are not UTF-8 do not refuse the declaration (exit $($r.ExitCode))"
    Assert-True (@(Get-DraftCopies $root).Count -eq 0) "[$platform] (6) nothing is saved for them"

    # 7. The turn record is ignored by git: init writes '.specrew/runtime/' as a per-session pattern.
    $patterns = @(Get-SpecrewPerSessionPattern)
    Assert-True ($patterns -contains '.specrew/runtime/') "[$platform] (7) init's per-session ignore patterns cover .specrew/runtime/"
    $repo = [IO.Path]::GetFullPath([IO.Path]::Combine([IO.Path]::GetTempPath(), 'tdi-g-' + [guid]::NewGuid().ToString('N').Substring(0, 8)))
    try {
        [IO.Directory]::CreateDirectory($repo) | Out-Null
        $null = & git -C $repo init --quiet 2>&1
        [IO.File]::WriteAllText((Join-Path $repo '.gitignore'), (($patterns -join "`n") + "`n"))
        $recordRel = '.specrew/runtime/turn-end/' + $a.Hash + '/turn-1.json'
        $null = & git -C $repo check-ignore -q -- $recordRel 2>$null
        Assert-True ($LASTEXITCODE -eq 0) "[$platform] (7) git ignores a turn record in a project init set up"
    }
    finally { Remove-Item -LiteralPath $repo -Recurse -Force -ErrorAction SilentlyContinue }

    # 8. No skill asks for a piped draft or a draft file; each names the script with no draft. The launch contract too.
    foreach ($skill in 'turn-end.md', 'gate-stop.md', 'design-workshop.md') {
        $text = [IO.File]::ReadAllText((Join-Path $repoRoot "extensions/specrew-speckit/squad-templates/skills/$skill"))
        Assert-True ($text -match 'pwsh -File \.specify/extensions/specrew-speckit/scripts/declare-turn-end\.ps1') "[$platform] (8) $skill names the script"
        Assert-True ($text -notmatch '\|\s*pwsh -File \.specify/extensions/specrew-speckit/scripts/declare-turn-end\.ps1' -and $text -notmatch '(?i)\bon \*{0,2}stdin|<<.DRAFT.') "[$platform] (8) $skill does not ask for a piped draft"
        Assert-True ($text -notmatch '-MessagePath') "[$platform] (8) $skill does not ask for a draft file"
        Assert-True ($text -notmatch 'turn-message\.md|saves (?:it|the draft) in') "[$platform] (8) $skill does not say a draft copy is saved"
    }
    $contract = [IO.File]::ReadAllText((Join-Path $repoRoot 'scripts/internal/launch-contract.ps1'))
    Assert-True ($contract -notmatch '(?i)draft on stdin|on stdin into|question on stdin') "[$platform] (8) the launch contract does not ask for a piped draft"

    # 9. No shipped file writes or names the copy.
    $shipped = @('extensions', 'scripts', 'hosts') | ForEach-Object { Join-Path $repoRoot $_ } | Where-Object { Test-Path -LiteralPath $_ } |
        ForEach-Object { Get-ChildItem -LiteralPath $_ -Recurse -File -Include '*.ps1', '*.psm1', '*.md', '*.json' }
    $naming = @($shipped | Where-Object { [IO.File]::ReadAllText($_.FullName).Contains('turn-message.md') } | ForEach-Object { $_.FullName.Substring($repoRoot.Length + 1) })
    Assert-True ($naming.Count -eq 0) "[$platform] (9) no shipped file names turn-message.md ($($naming -join ', '))"
    $launch = [IO.File]::ReadAllText((Join-Path $repoRoot 'scripts/internal/launch-contract.ps1'))
    Assert-True ($launch -notmatch 'saves the draft in') "[$platform] (9) the launch contract does not say a draft copy is saved"
}
finally { Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue }

if ($script:failCount -gt 0) { Write-Host "turn-draft-intake: $($script:failCount) failure(s)" -ForegroundColor Red; exit 1 }
Write-Host "turn-draft-intake: all passed ($platform)" -ForegroundColor Green
