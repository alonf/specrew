# Feature 203 T025 (F3, the hook cost; DRIFT-073): a Stop run read the transcript's tail five times - three 2 MB windows
# in the handover's stores (Get-SpecrewTranscriptTailLines) and two Get-Content -Tail in the conformance provider, which
# is seconds-scale on a large transcript on Windows - in three separate processes. The design (iteration 002, Option A):
# the dispatcher reads the tail once per hook run and hands it to the providers; a reader uses it only while the
# transcript is exactly as long as it was then (a host still flushing the turn makes the file grow, and then the reader
# reads the file itself, as before), and only for a window the hand-over covers.

BeforeAll {
    $script:RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
    . (Join-Path $script:RepoRoot 'scripts/internal/bootstrap/ConversationCaptureAccessor.ps1')
    . (Join-Path $script:RepoRoot 'extensions/specrew-speckit/scripts/conformance-turn-delta.ps1')
    $script:Work = Join-Path ([IO.Path]::GetTempPath()) ('hook-tail-' + [guid]::NewGuid().ToString('N').Substring(0, 10))
    $null = New-Item -ItemType Directory -Path $script:Work -Force

    # The conformance provider's long-turn reader, taken from the provider file itself (the provider is a script).
    $provider = [IO.File]::ReadAllText((Join-Path $script:RepoRoot 'extensions/specrew-speckit/scripts/specrew-conformance-provider.ps1')) -replace "`r`n", "`n"
    $longTurn = [regex]::Match($provider, '(?s)function Get-SpecrewLongTurnSignal \{.*?\n\}\n').Value
    . ([scriptblock]::Create($longTurn))

    function script:New-Transcript([string]$Name, [string[]]$Lines) {
        $path = Join-Path $script:Work $Name
        [IO.File]::WriteAllText($path, (($Lines -join "`n") + "`n"), [Text.UTF8Encoding]::new($false))
        return $path
    }

    # A hand-over of the same LENGTH as the transcript but different words, so a reader that used it says so.
    function script:Set-TailHandover([string]$Transcript, [string[]]$Lines, [int]$WindowBytes = 2097152, [string]$Schema = '1') {
        $script:SpecrewHookTranscriptTailCache = $null
        $source = [IO.File]::ReadAllBytes($Transcript)
        $text = (($Lines -join "`n") + "`n")
        $bytes = [Text.Encoding]::UTF8.GetBytes($text)
        if ($bytes.Length -gt $source.Length) { throw 'fixture: the hand-over must not be longer than the transcript' }
        $padded = New-Object byte[] $source.Length
        for ($i = 0; $i -lt $padded.Length; $i++) { $padded[$i] = [byte][char]' ' }
        [Array]::Copy($bytes, 0, $padded, $source.Length - $bytes.Length, $bytes.Length)
        $tail = Join-Path $script:Work ('tail-' + [guid]::NewGuid().ToString('N').Substring(0, 8) + '.bin')
        [IO.File]::WriteAllBytes($tail, $padded)
        $meta = Join-Path $script:Work ('tail-' + [guid]::NewGuid().ToString('N').Substring(0, 8) + '.json')
        [ordered]@{ schema = $Schema; source_path = [IO.Path]::GetFullPath($Transcript); source_length = $source.Length; window_bytes = [Math]::Min($WindowBytes, $source.Length); tail_path = $tail } |
            ConvertTo-Json -Compress | Set-Content -LiteralPath $meta -Encoding utf8NoBOM
        $env:SPECREW_HOOK_TRANSCRIPT_TAIL = $meta
    }

    $script:Real = @('{"type":"user","uuid":"u1"}', '{"type":"assistant","message":{"id":"msg_real"}}')
    $script:Handed = @('{"type":"assistant","message":{"id":"msg_handed"}}')
}

AfterAll {
    Remove-Item Env:\SPECREW_HOOK_TRANSCRIPT_TAIL -ErrorAction SilentlyContinue
    if ((Split-Path -Leaf $script:Work) -like 'hook-tail-*') { Remove-Item -LiteralPath $script:Work -Recurse -Force -ErrorAction SilentlyContinue }
}

Describe 'T025: the providers read the tail the dispatcher read once' {
    AfterEach { Remove-Item Env:\SPECREW_HOOK_TRANSCRIPT_TAIL -ErrorAction SilentlyContinue; $script:SpecrewHookTranscriptTailCache = $null }

    It 'the handover''s tail reader uses the hand-over for an unchanged transcript' {
        $transcript = script:New-Transcript -Name 'same.jsonl' -Lines $script:Real
        script:Set-TailHandover -Transcript $transcript -Lines $script:Handed
        (@(Get-SpecrewTranscriptTailLines -Path $transcript) -join "`n") | Should -Match 'msg_handed'
    }

    It 'the conformance long-turn reader uses the hand-over for an unchanged transcript' {
        $transcript = script:New-Transcript -Name 'long.jsonl' -Lines (@(1..30 | ForEach-Object { '{"type":"user","uuid":"u' + $_ + '","pad":"................................"}' }))
        script:Set-TailHandover -Transcript $transcript -Lines (@(1..30 | ForEach-Object { '{"type":"assistant","message":{"id":"msg_h' + $_ + '"}}' }))
        (Get-SpecrewLongTurnSignal -TranscriptPath $transcript).assistant_entries | Should -BeGreaterThan 0 -Because 'only the hand-over has assistant lines'
    }

    It 'a transcript that grew since the hand-over is read from the file (pinned)' {
        $transcript = script:New-Transcript -Name 'grew.jsonl' -Lines $script:Real
        script:Set-TailHandover -Transcript $transcript -Lines $script:Handed
        Add-Content -LiteralPath $transcript -Value '{"type":"assistant","message":{"id":"msg_flushed"}}' -Encoding utf8NoBOM
        $lines = (@(Get-SpecrewTranscriptTailLines -Path $transcript) -join "`n")
        $lines | Should -Match 'msg_flushed'
        $lines | Should -Not -Match 'msg_handed'
    }

    It 'another transcript, a wider window than the hand-over, or an unknown schema is read from the file (pinned)' {
        $transcript = script:New-Transcript -Name 'mine.jsonl' -Lines $script:Real
        $other = script:New-Transcript -Name 'other.jsonl' -Lines $script:Real
        script:Set-TailHandover -Transcript $other -Lines $script:Handed
        (@(Get-SpecrewTranscriptTailLines -Path $transcript) -join "`n") | Should -Not -Match 'msg_handed'
        script:Set-TailHandover -Transcript $transcript -Lines $script:Handed -WindowBytes 10
        (@(Get-SpecrewTranscriptTailLines -Path $transcript -MaxBytes 8192) -join "`n") | Should -Not -Match 'msg_handed'
        script:Set-TailHandover -Transcript $transcript -Lines $script:Handed -Schema '2'
        (@(Get-SpecrewTranscriptTailLines -Path $transcript) -join "`n") | Should -Not -Match 'msg_handed'
    }

    It 'with no hand-over, both readers read the file (pinned)' {
        $transcript = script:New-Transcript -Name 'none.jsonl' -Lines $script:Real
        (@(Get-SpecrewTranscriptTailLines -Path $transcript) -join "`n") | Should -Match 'msg_real'
        (Get-SpecrewLongTurnSignal -TranscriptPath $transcript).assistant_entries | Should -Be 1
    }
}

Describe 'T025: the dispatcher reads the tail once and hands it to the providers' {
    It 'a Stop provider finds the hand-over of this turn''s transcript' {
        $proj = Join-Path $script:Work 'dispatch'
        $scripts = Join-Path $proj '.specify/extensions/specrew-speckit/scripts'
        $null = New-Item -ItemType Directory -Path (Join-Path $proj '.specrew/runtime'), $scripts -Force
        $catalog = @{ schema_version = '1'; providers = @(@{ id = 'handover'; kind = 'inject'; events = @('Stop'); order = 10; budget_share = 1.0; command = 'stub.ps1' }) }
        Set-Content -LiteralPath (Join-Path $proj '.specify/extensions/specrew-speckit/refocus-scopes.json') -Value ($catalog | ConvertTo-Json -Depth 6) -Encoding utf8NoBOM
        $saw = Join-Path $proj 'saw.json'
        Set-Content -LiteralPath (Join-Path $scripts 'stub.ps1') -Value ("`$m = [string]`$env:SPECREW_HOOK_TRANSCRIPT_TAIL; if (`$m -and (Test-Path -LiteralPath `$m)) { Copy-Item -LiteralPath `$m -Destination '$saw' }; exit 0") -Encoding utf8NoBOM
        $transcript = script:New-Transcript -Name 'turn.jsonl' -Lines $script:Real
        $payload = (@{ session_id = 'tail-1'; transcript_path = $transcript; hook_event_name = 'Stop'; stop_hook_active = $false } | ConvertTo-Json -Compress)
        $payloadFile = Join-Path $proj 'event.json'
        Set-Content -LiteralPath $payloadFile -Value $payload -Encoding utf8NoBOM -NoNewline
        $dispatcher = Join-Path $script:RepoRoot 'scripts/internal/specrew-hook-dispatcher.ps1'
        $null = Start-Process -FilePath 'pwsh' -ArgumentList @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $dispatcher, '-Event', 'Stop', '-HostKind', 'claude') `
            -WorkingDirectory $proj -NoNewWindow -PassThru -Wait -RedirectStandardInput $payloadFile -RedirectStandardOutput (Join-Path $proj 'd.out') -RedirectStandardError (Join-Path $proj 'd.err')
        Test-Path -LiteralPath $saw | Should -BeTrue -Because 'the provider process inherits the hand-over from the dispatcher'
        $meta = Get-Content -LiteralPath $saw -Raw | ConvertFrom-Json
        [string]$meta.source_path | Should -BeExactly ([IO.Path]::GetFullPath($transcript))
        [int64]$meta.source_length | Should -Be ([IO.FileInfo]::new($transcript)).Length
    }
}
