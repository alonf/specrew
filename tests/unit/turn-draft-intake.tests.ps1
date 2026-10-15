# Feature 202 T014 (FR-021; US6; DA-4): turn drafts arrive over stdin and are saved where the script decides.
#
# B4F-101: agents saved their turn drafts wherever they chose, in the repository too, and drafts rode into commits;
# two sessions in one project wrote the same draft file. B4F-065: a draft passed through a console decoder lost its
# non-ASCII text. Now the agent pipes the draft into declare-turn-end.ps1, which reads the raw bytes (the child's
# console input encoding is ibm437 under some agent shells, research.md DA-4), decodes them as strict UTF-8, and
# saves them byte-exact to the session's own ignored folder: .specrew/runtime/turn-end/<ownerHash>/turn-message.md.
# A host that passes no session id gets a per-token folder, and the script says so.
#
# RED before T014: stdin is ignored (no draft file, empty message); two sessions have no per-session draft; nothing
# is disclosed for a host without a session id; the skills name only -MessagePath.
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
    return [pscustomobject]@{ Hash = $hash; Token = $token; Draft = [IO.Path]::Combine($Root, '.specrew', 'runtime', 'turn-end', $hash, 'turn-message.md') }
}

function Test-BytesEqual { param([byte[]]$A, [byte[]]$B) return ($A.Length -eq $B.Length) -and [Linq.Enumerable]::SequenceEqual($A, $B) }

$root = [IO.Path]::GetFullPath([IO.Path]::Combine([IO.Path]::GetTempPath(), 'tdi-' + [guid]::NewGuid().ToString('N').Substring(0, 8)))
[IO.Directory]::CreateDirectory([IO.Path]::Combine($root, '.specrew', 'runtime')) | Out-Null
try {
    $hebrew = "שלום עולם — the human's question, in Hebrew and English.`r`nשורה שנייה: האם להמשיך? ✅ 🚀 Ünïcödé`r`n"
    $hebrewBytes = [Text.UTF8Encoding]::new($false).GetBytes($hebrew)

    # 1. A non-ASCII draft over stdin round-trips byte-exact into the session's own folder.
    $a = New-SessionRoot -Root $root -HostKind 'claude' -SessionId 'session-a'
    $r = Complete-Declare (Start-Declare -Root $root -Token $a.Token -Bytes $hebrewBytes)
    Assert-True ($r.ExitCode -eq 0) "[$platform] (1) the declaration with a stdin draft succeeds (exit $($r.ExitCode); $($r.StdErr.Trim()))"
    Assert-True (Test-Path -LiteralPath $a.Draft -PathType Leaf) "[$platform] (1) the draft is saved at turn-end/<ownerHash>/turn-message.md"
    if (Test-Path -LiteralPath $a.Draft -PathType Leaf) {
        Assert-True (Test-BytesEqual ([IO.File]::ReadAllBytes($a.Draft)) $hebrewBytes) "[$platform] (1) Hebrew, emoji and CRLF round-trip byte-exact"
    }
    $recordA = if ($null -ne $r.Json) { Read-SpecrewTurnEndRecord -Path ([string]$r.Json.record_path) } else { $null }
    Assert-True ($null -ne $recordA -and [string]$recordA.message -ceq $hebrew) "[$platform] (1) the recorded message is the decoded draft, character for character"
    Assert-True ($null -ne $r.Json -and [string]$r.Json.draft_scope -eq 'session' -and [string]$r.Json.draft_path -eq $a.Draft) "[$platform] (1) the script reports the draft's per-session path"

    # 2. Two sessions declaring at the same moment never touch each other's draft.
    $b = New-SessionRoot -Root $root -HostKind 'claude' -SessionId 'session-b'
    $a2 = New-SessionRoot -Root $root -HostKind 'codex' -SessionId 'session-c'
    $textB = "Session B's packet: אישור לשלב הבא?`n"
    $textC = "Session C's question: מה הגבולות?`n"
    $runB = Start-Declare -Root $root -Token $b.Token -Bytes ([Text.Encoding]::UTF8.GetBytes($textB))
    $runC = Start-Declare -Root $root -Token $a2.Token -Bytes ([Text.Encoding]::UTF8.GetBytes($textC))
    $rB = Complete-Declare $runB; $rC = Complete-Declare $runC
    Assert-True ($rB.ExitCode -eq 0 -and $rC.ExitCode -eq 0) "[$platform] (2) two concurrent declarations both succeed"
    $draftB = if (Test-Path -LiteralPath $b.Draft) { [IO.File]::ReadAllText($b.Draft) } else { '' }
    $draftC = if (Test-Path -LiteralPath $a2.Draft) { [IO.File]::ReadAllText($a2.Draft) } else { '' }
    Assert-True ($draftB -ceq $textB -and $draftC -ceq $textC) "[$platform] (2) each session's draft holds its own text"
    Assert-True ($b.Draft -ne $a2.Draft -and $b.Draft -ne $a.Draft) "[$platform] (2) the two sessions' draft paths differ"
    Assert-True ((Test-Path -LiteralPath $a.Draft) -and (Test-BytesEqual ([IO.File]::ReadAllBytes($a.Draft)) $hebrewBytes)) "[$platform] (2) the first session's draft is untouched"

    # 3. A host that passes no session id keeps its token at the runtime root: the draft goes to a per-token folder,
    #    and the script says so.
    $legacy = [IO.Path]::GetFullPath([IO.Path]::Combine([IO.Path]::GetTempPath(), 'tdi-l-' + [guid]::NewGuid().ToString('N').Substring(0, 8)))
    [IO.Directory]::CreateDirectory([IO.Path]::Combine($legacy, '.specrew', 'runtime')) | Out-Null
    try {
        $legacyToken = Write-SpecrewTurnToken -StateRoot ([IO.Path]::Combine($legacy, '.specrew', 'runtime')) -TurnId 'turn-1'
        $r = Complete-Declare (Start-Declare -Root $legacy -Token $legacyToken -Bytes ([Text.Encoding]::UTF8.GetBytes("no session id`n")))
        $expected = [IO.Path]::Combine($legacy, '.specrew', 'runtime', 'turn-end', ('token-' + $legacyToken), 'turn-message.md')
        Assert-True ($r.ExitCode -eq 0 -and (Test-Path -LiteralPath $expected -PathType Leaf)) "[$platform] (3) without a session id the draft goes to a per-token folder"
        Assert-True ($null -ne $r.Json -and [string]$r.Json.draft_scope -eq 'token' -and [string]$r.Json.draft_disclosure -match 'no session id') "[$platform] (3) the per-token path is disclosed ('$(if ($r.Json) { $r.Json.draft_disclosure })')"
    }
    finally { Remove-Item -LiteralPath $legacy -Recurse -Force -ErrorAction SilentlyContinue }

    # 4. -MessagePath still works for a caller that has not moved to stdin, and its draft is also kept per session.
    $d = New-SessionRoot -Root $root -HostKind 'copilot' -SessionId 'session-d'
    $file = Join-Path $root 'legacy-draft.md'
    [IO.File]::WriteAllBytes($file, $hebrewBytes)
    $r = Complete-Declare (Start-Declare -Root $root -Token $d.Token -Extra @('-MessagePath', $file))
    $recordD = if ($null -ne $r.Json) { Read-SpecrewTurnEndRecord -Path ([string]$r.Json.record_path) } else { $null }
    Assert-True ($r.ExitCode -eq 0 -and $null -ne $recordD -and [string]$recordD.message -ceq $hebrew) "[$platform] (4) -MessagePath is still accepted and decoded as UTF-8"
    Assert-True ((Test-Path -LiteralPath $d.Draft) -and (Test-BytesEqual ([IO.File]::ReadAllBytes($d.Draft)) $hebrewBytes)) "[$platform] (4) a -MessagePath draft is also kept in the session's folder"

    # 5. A shell that leaves stdin open and sends nothing must not hang the turn end.
    $e = New-SessionRoot -Root $root -HostKind 'claude' -SessionId 'session-e'
    $sw = [Diagnostics.Stopwatch]::StartNew()
    $run = Start-Declare -Root $root -Token $e.Token -LeaveStdinOpen
    $r = Complete-Declare $run -TimeoutMs 30000
    try { $run.Stdin.Close() } catch { $null = $_ }
    Assert-True ($r.Finished -and $r.ExitCode -eq 0) ("[$platform] (5) an open, silent stdin does not hang the declaration ({0:N1} s)" -f $sw.Elapsed.TotalSeconds)
    Assert-True (-not (Test-Path -LiteralPath $e.Draft)) "[$platform] (5) no draft is invented when none was sent"

    # 6. Bytes that are not UTF-8 are refused with a plain reason, never saved as mojibake.
    $f = New-SessionRoot -Root $root -HostKind 'claude' -SessionId 'session-f'
    $r = Complete-Declare (Start-Declare -Root $root -Token $f.Token -Bytes ([byte[]](0x53, 0x68, 0xE9, 0x6C, 0x6F, 0x6D, 0xFF, 0x0A)))
    Assert-True ($r.ExitCode -ne 0 -and $r.StdErr -match 'not valid UTF-8') "[$platform] (6) a draft that is not UTF-8 is refused with a plain reason"
    Assert-True (-not (Test-Path -LiteralPath $f.Draft)) "[$platform] (6) the refused draft is not saved"

    # 7. Drafts are ignored by git: init writes '.specrew/runtime/' as a per-session pattern.
    $patterns = @(Get-SpecrewPerSessionPattern)
    Assert-True ($patterns -contains '.specrew/runtime/') "[$platform] (7) init's per-session ignore patterns cover .specrew/runtime/"
    $repo = [IO.Path]::GetFullPath([IO.Path]::Combine([IO.Path]::GetTempPath(), 'tdi-g-' + [guid]::NewGuid().ToString('N').Substring(0, 8)))
    try {
        [IO.Directory]::CreateDirectory($repo) | Out-Null
        $null = & git -C $repo init --quiet 2>&1
        [IO.File]::WriteAllText((Join-Path $repo '.gitignore'), (($patterns -join "`n") + "`n"))
        $draftRel = '.specrew/runtime/turn-end/' + $a.Hash + '/turn-message.md'
        $null = & git -C $repo check-ignore -q -- $draftRel 2>$null
        Assert-True ($LASTEXITCODE -eq 0) "[$platform] (7) git ignores a saved draft in a project init set up"
    }
    finally { Remove-Item -LiteralPath $repo -Recurse -Force -ErrorAction SilentlyContinue }

    # 8. The three skills name the stdin form, and none asks for a draft file.
    foreach ($skill in 'turn-end.md', 'gate-stop.md', 'design-workshop.md') {
        $text = [IO.File]::ReadAllText((Join-Path $repoRoot "extensions/specrew-speckit/squad-templates/skills/$skill"))
        Assert-True ($text -match '\|\s*pwsh -File \.specify/extensions/specrew-speckit/scripts/declare-turn-end\.ps1' -and $text -match 'stdin') "[$platform] (8) $skill names the stdin form"
        Assert-True ($text -notmatch '-MessagePath <') "[$platform] (8) $skill no longer asks for a draft file"
    }
}
finally { Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue }

if ($script:failCount -gt 0) { Write-Host "turn-draft-intake: $($script:failCount) failure(s)" -ForegroundColor Red; exit 1 }
Write-Host "turn-draft-intake: all passed ($platform)" -ForegroundColor Green
