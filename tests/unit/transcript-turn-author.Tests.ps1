# Round 4 of 203 iteration 002's review, finding-d4b2f612fa8ffcf1 (major), and the reviewer session's ruling on it: ONE
# FUNCTION ANSWERS WHO COULD HAVE TYPED A TRANSCRIPT RECORD. Get-SpecrewTranscriptTurnAuthor reads a turn as the transcript
# reader built it (Read-SpecrewCitedTypedTurn) and returns its kind - human, unverified-typed, host-text, the sender its own
# fields name when they refuse it (peer, scheduled, task-notification, self-command, other), or unverified-host - and
# whether a person could have typed it. Ten places decided this before, each from its own subset of the signals, and they
# disagreed: the pending-claim order, the pick and the partial-window rule read only the two host flags, so an sdk program's
# record was "a person" there and took the real message's reservation.
#
# The guard: nothing outside the reader that sets the record's sender fields and host flags, and this one function, reads
# them. A new place that decides person or host from them fails here, by name.

BeforeAll {
    $script:RepoRoot = (Resolve-Path "$PSScriptRoot/../..").Path
    . (Join-Path $script:RepoRoot 'scripts/internal/bootstrap/HumanAuthorityStore.ps1')
    . (Join-Path $script:RepoRoot 'scripts/internal/bootstrap/ConversationCaptureAccessor.ps1')
}

Describe 'Get-SpecrewTranscriptTurnAuthor: one answer per record kind (round 4 finding 2)' {
    It '<Name> is <Kind>, could be typed <Typed>' -ForEach @(
        @{ Name = 'a typed record'; Kind = 'human'; Typed = $true; Sender = 'human'
            Turn = @{ origin = 'typed-user'; record_turn_origin = 'human'; record_prompt_source = 'typed'; record_origin_kind = 'human'; record_is_meta = $null } }
        @{ Name = 'a desktop typed record (sdk with origin.kind human)'; Kind = 'human'; Typed = $true; Sender = 'human'
            Turn = @{ origin = 'typed-user'; record_turn_origin = 'human'; record_prompt_source = 'sdk'; record_origin_kind = 'human'; record_is_meta = $null } }
        @{ Name = 'a message queued mid-turn'; Kind = 'human'; Typed = $true; Sender = 'human'
            Turn = @{ origin = 'typed-user'; record_kind = 'queued_command'; record_origin_kind = 'human'; record_human_turn = $true; record_command_mode = 'prompt'; record_turn_origin = ''; record_prompt_source = ''; record_is_meta = $null } }
        @{ Name = 'a queued task notification'; Kind = 'task-notification'; Typed = $false; Sender = 'task-notification'
            Turn = @{ origin = 'host-injected'; record_kind = 'queued_command'; record_origin_kind = 'task-notification'; record_human_turn = $false; record_command_mode = 'prompt'; record_turn_origin = ''; record_prompt_source = ''; record_is_meta = $null } }
        @{ Name = 'an sdk program''s record'; Kind = 'other'; Typed = $false; Sender = 'other'
            Turn = @{ origin = 'typed-user'; record_turn_origin = 'sdk'; record_prompt_source = 'sdk'; record_origin_kind = ''; record_is_meta = $null } }
        @{ Name = 'a task notification'; Kind = 'task-notification'; Typed = $false; Sender = 'task-notification'
            Turn = @{ origin = 'host-injected'; record_turn_origin = 'task_notification'; record_prompt_source = 'system'; record_origin_kind = 'task-notification'; record_is_meta = $null } }
        @{ Name = 'command output'; Kind = 'self-command'; Typed = $false; Sender = 'self-command'
            Turn = @{ origin = 'typed-user'; record_turn_origin = 'human'; record_prompt_source = ''; record_origin_kind = ''; record_is_meta = $null } }
        @{ Name = 'a peer message (meta-flagged)'; Kind = 'peer'; Typed = $false; Sender = 'peer'
            Turn = @{ origin = 'host-injected'; is_compact_summary = $true; record_turn_origin = 'peer'; record_prompt_source = 'system'; record_origin_kind = 'peer'; record_is_meta = $true; record_peer_name = 'reviewer' } }
        @{ Name = 'a scheduled prompt (meta-flagged)'; Kind = 'scheduled'; Typed = $false; Sender = 'scheduled'
            Turn = @{ origin = 'typed-user'; is_compact_summary = $true; record_turn_origin = 'scheduled'; record_prompt_source = 'system'; record_origin_kind = ''; record_is_meta = $true } }
        @{ Name = 'Stop feedback (meta-flagged, no named sender)'; Kind = 'other'; Typed = $false; Sender = 'other'
            Turn = @{ origin = 'typed-user'; is_compact_summary = $true; record_turn_origin = ''; record_prompt_source = ''; record_origin_kind = ''; record_is_meta = $true } }
        @{ Name = 'a compaction summary'; Kind = 'host-text'; Typed = $false; Sender = 'other'
            Turn = @{ origin = 'typed-user'; is_compact_summary = $true; record_turn_origin = ''; record_prompt_source = ''; record_origin_kind = ''; record_is_meta = $null } }
        @{ Name = 'a sub-agent''s record with human fields'; Kind = 'host-text'; Typed = $false; Sender = 'other'
            Turn = @{ origin = 'host-injected'; record_is_sidechain = $true; record_turn_origin = 'human'; record_prompt_source = 'typed'; record_origin_kind = 'human'; record_is_meta = $null } }
        @{ Name = 'a record with no sender fields the reader took as typed (an older host, Codex)'; Kind = 'unverified-typed'; Typed = $true; Sender = 'unverified'
            Turn = @{ origin = 'typed-user' } }
        @{ Name = 'a record with no sender fields the reader took as the host''s (an envelope)'; Kind = 'unverified-host'; Typed = $false; Sender = 'other'
            Turn = @{ origin = 'host-injected' } }
    ) {
        $author = Get-SpecrewTranscriptTurnAuthor -Turn ([pscustomobject]$Turn)
        [string]$author.kind | Should -BeExactly $Kind
        [bool]$author.could_be_typed | Should -Be $Typed
        [string]$author.sender | Should -BeExactly $Sender
    }

    It 'the host''s own text that names no sender is marked, so the lookup leaves it out of the candidates' {
        (Get-SpecrewTranscriptTurnAuthor -Turn ([pscustomobject]@{ origin = 'typed-user'; is_compact_summary = $true; record_turn_origin = ''; record_prompt_source = ''; record_origin_kind = ''; record_is_meta = $true })).unnamed_host_text | Should -BeTrue
        (Get-SpecrewTranscriptTurnAuthor -Turn ([pscustomobject]@{ origin = 'typed-user'; is_compact_summary = $true; record_turn_origin = 'scheduled'; record_prompt_source = 'system'; record_origin_kind = ''; record_is_meta = $true })).unnamed_host_text | Should -BeFalse -Because 'a record that names its sender stays a candidate, so it is refused with its own sentence'
        (Get-SpecrewTranscriptTurnAuthor -Turn ([pscustomobject]@{ origin = 'host-injected'; record_is_sidechain = $true })).unnamed_host_text | Should -BeFalse -Because 'only the meta-flagged host text is left out, as before'
    }
}

Describe 'the guard: one place reads who could have typed a record (round 4 finding 2)' {
    It 'no code under scripts/ or extensions/ reads the record''s sender fields or host flags outside the reader and Get-SpecrewTranscriptTurnAuthor' {
        $names = @('is_compact_summary', 'record_is_sidechain', 'record_turn_origin', 'record_prompt_source', 'record_origin_kind', 'record_is_meta')
        # The reader that builds the turn writes them (as -NotePropertyName arguments and hashtable keys); the raw-record
        # meta reader reads the host's own keys; the one function reads the turn's.
        $allowedReaders = @('Get-SpecrewTranscriptTurnAuthor', 'Test-SpecrewConversationMetaFlag')
        $offenders = [Collections.Generic.List[string]]::new()
        $files = @(Get-ChildItem -LiteralPath (Join-Path $script:RepoRoot 'scripts'), (Join-Path $script:RepoRoot 'extensions') -Recurse -File -Include '*.ps1', '*.psm1')
        foreach ($file in $files) {
            $tokens = $null; $errors = $null
            $ast = [System.Management.Automation.Language.Parser]::ParseFile($file.FullName, [ref]$tokens, [ref]$errors)
            $strings = $ast.FindAll({ param($n) $n -is [System.Management.Automation.Language.StringConstantExpressionAst] -and $names -ccontains $n.Value }, $true)
            foreach ($s in $strings) {
                $parent = $s.Parent
                # A hashtable key is a write (the queued attachment's turn).
                if ($parent -is [System.Management.Automation.Language.HashtableAst] -and @($parent.KeyValuePairs | Where-Object { [object]::ReferenceEquals($_.Item1, $s) }).Count -gt 0) { continue }
                # The argument of -NotePropertyName is a write (the transcript record's turn).
                if ($parent -is [System.Management.Automation.Language.CommandAst]) {
                    $elements = @($parent.CommandElements)
                    $index = [array]::IndexOf($elements, $s)
                    if ($index -gt 0 -and $elements[$index - 1] -is [System.Management.Automation.Language.CommandParameterAst] -and $elements[$index - 1].ParameterName -ieq 'NotePropertyName') { continue }
                }
                $function = $s.Parent
                while ($null -ne $function -and $function -isnot [System.Management.Automation.Language.FunctionDefinitionAst]) { $function = $function.Parent }
                if ($null -ne $function -and $allowedReaders -ccontains $function.Name) { continue }
                $where = if ($null -ne $function) { $function.Name } else { '<script>' }
                $offenders.Add(('{0}:{1} {2} reads {3}' -f $file.FullName.Substring($script:RepoRoot.Length + 1), $s.Extent.StartLineNumber, $where, $s.Value)) | Out-Null
            }
        }
        @($offenders) | Should -BeNullOrEmpty -Because ('person or host is decided in one place; these read the signals themselves: ' + ($offenders -join '; '))
    }
}
