# Live walk: Tier 1 acceptance (SC-001, SC-003)

The maintainer walks this at the iteration-1 closeout, once per validated host: Claude, Codex and Copilot. Cursor and
Antigravity are experimental and are not walked (spec, Host support tiers).

The walk counts what the tests cannot: real decisions, corrective exchanges and extra stops on a real installed host.
A value that was not observed is written as `null`, never `0`. A value you checked and found empty is an observed
`0` (for example, a receipts file you opened and found with no lines).

Budget: about 5 minutes of setup, then about 10 minutes per host, so about 35 minutes in all. Everything runs in
scratch folders under `C:\scratch\walk-202`. Nothing runs in the 202 worktree or in any other repository.

## What you count

- A **real decision** is a message where you decided something: a product answer, the agenda confirmation, a lens
  answer, `move on`, a delegation, an approval. The script below has **6** per host.
- A **corrective exchange** is any message where you had to repeat, re-type or explain something the system should
  have taken the first time.
- An **extra stop** is a stop that asked for no decision of yours (the governing principle: a stop is justified only
  when a human decision is needed). A reply that is rendered a second time counts as one extra stop.

Host prompts that are not Specrew (folder trust on first launch, sign-in) are not counted.

## Setup (once, about 5 minutes)

Use a PowerShell 7 window. The install route is the repo's own: `scripts/internal/install-local-build.ps1`, run from
a clean clone of the branch, so it packages a commit and never writes into the 202 worktree (it creates its stage
under the repository it runs from, and it refuses uncommitted changes to packaged files).

Two things to know before you install:

- The installer **replaces the installed Specrew module for your user** (the highest installed version). Every
  Specrew project on this machine, including the 202 worktree's own sessions, uses this build until you restore it
  (see Cleanup).
- It needs an installed Specrew module to replace. Without one it stops with
  `no installed Specrew module found; pass -InstallRoot explicitly`.

### 1. Make the walk root and check it is outside every repository

```powershell
$walk = 'C:\scratch\walk-202'
New-Item -ItemType Directory -Force $walk | Out-Null
git -C $walk rev-parse --show-toplevel
```

You should see `fatal: not a git repository`. If it prints a path instead, pick another root: a folder inside a
repository is treated as brownfield, and its first commit lands in that repository (B4F-120).

### 2. Take a clean copy of the branch

```powershell
git clone --branch 202-beta4-1-ux-stabilization --single-branch C:\Dev\specrew-beta3-stabilization "$walk\src"
git -C "$walk\src" log -1 --oneline
```

Note the commit it prints. That is the build under test. Uncommitted files in the worktree are not part of it.
If the clone from the worktree path is refused, clone from the main checkout instead; its path is the parent of
`git -C C:\Dev\specrew-beta3-stabilization rev-parse --git-common-dir` (verify).

### 3. Install that commit as the Specrew module

```powershell
pwsh -NoProfile -File "$walk\src\scripts\internal\install-local-build.ps1" -WhatIfOnly
pwsh -NoProfile -File "$walk\src\scripts\internal\install-local-build.ps1"
```

The first command installs nothing and reports the identity it would install. The second installs. You should see
these lines, among others:

```text
[install] packaged <N> files from <commit>
[install] version 0.40.0 prerelease 'beta4'
[install] byte verification: all <N> packaged files match
[install] stamp verified against installed contents
```

### 4. Open a new PowerShell 7 window and confirm the installed build

The old window still has the previous module loaded, so close it and open a new one.

```powershell
$walk = 'C:\scratch\walk-202'
$m = (Get-Module -ListAvailable Specrew | Sort-Object Version -Descending | Select-Object -First 1).ModuleBase
(Get-Content (Join-Path $m 'build-stamp.json') -Raw | ConvertFrom-Json) | Format-List commit, content_sha256
git -C "$walk\src" rev-parse --short=8 HEAD
specrew version
```

The stamp's `commit` and the `rev-parse` output must be the same 8 characters. `specrew version` should report
`0.40.0-beta4` as the installed version; whether it also prints the commit in brackets is (verify). If the two
commits differ, stop: the walk would test another build.

### 5. Make one scratch project per host

```powershell
foreach ($h in 'claude', 'codex', 'copilot') {
    $p = Join-Path $walk $h
    New-Item -ItemType Directory -Force $p | Out-Null
    git -C $p init -q
    Push-Location $p
    specrew init
    Pop-Location
}
```

Each `specrew init` should end without errors. It deploys the Specrew hooks, so launching a host in that folder is
enough to start Specrew. Your expertise profile is per user, so init keeps the one you already have. A fresh project
also meets the Codex condition: Codex runs in a healthy project that has run no earlier reviews (the spec records
Codex parity as unproven, not broken).

Record the host versions now, for the friction table: `claude --version`, `codex --version`, `copilot --version`.

## The script (type these verbatim, on every host)

Each message is sent on its own. Do not add text before or after it.

| Id | Message |
| --- | --- |
| M1 | `I want a small command-line tool that counts the words, lines and characters in one text file and prints them on one line.` |
| M2 | `Users: just me, a developer, running it locally. Pain: I check word counts of markdown drafts by hand. MVP: one file in, one line out with words, lines and characters. Non-goals: no folders, no config files, no UI. Constraints: Python 3.12, standard library only, must run on Windows and Linux.` |
| M3 | `yes, looks right` |
| M4 | `Keep it to one Python module: one function per count and a thin main. On a missing or unreadable file, print one line to stderr and exit with code 1.` |
| M5 | `move on` |
| M6 | `you decide the remaining lenses` |
| M7 | `what does 'approved for specify' mean?` |
| M8 | `approved for specify` |
| M9 | `where are we?` |
| M10 | `continue` |

M4 is written for an architecture or component question. If the first lens asks about something else, answer that
question in one short reply of your own and note it. M6 is an explicit delegation: the remaining lenses are recorded
as decided by the crew on your instruction, which is honest provenance, and it keeps the walk inside 10 minutes.

## Host commands

| Action | Claude | Codex | Copilot |
| --- | --- | --- | --- |
| Folder | `C:\scratch\walk-202\claude` | `C:\scratch\walk-202\codex` | `C:\scratch\walk-202\copilot` |
| Launch | `claude --dangerously-skip-permissions` | `codex --dangerously-bypass-approvals-and-sandbox` | `copilot --allow-all` |
| Compact | `/compact` | `/compact` (verify) | `/compact` (verify) |
| Exit | `/exit` | `/quit` or Ctrl+C twice (verify) | `/exit` or Ctrl+C twice (verify) |
| Resume | launch again, then M10 | launch again, then M10 | launch again, then M10 |
| Dials correction named in the orientation | `/specrew-user-profile edit` | `ask me to update your profile` | `/specrew-user-profile edit` |

The launch flags are the ones `specrew start --host <host>` adds by default for tool approvals (Specrew's host flag
table). They skip tool-call prompts only; lifecycle boundaries still stop for your typed approval. Launching the host
directly, rather than through `specrew start`, makes M1 the first message of the session, which is the B4F-096 case.

Run each host from its own folder: `Set-Location C:\scratch\walk-202\<host>`, then the launch command.

## The walk (each host, about 10 minutes)

Keep a tally beside you with three counters for this host: real decisions, corrective exchanges, extra stops.

| Step | You type | You should see | Tally |
| --- | --- | --- | --- |
| 1. Open | Launch, then M1 | Before any question: Specrew is active, its version and host, where the project stands (no feature yet), what boundaries will ask of you (a typed `approved for <boundary>`), and one sentence about how Specrew is adapting to you that ends with the correction from the host table (FR-014, FR-016). Then the first product question, as prose with no picker. | A question before the orientation: 1 extra stop (B4F-096). Having to ask for the orientation or the dials sentence: 1 corrective exchange (B4F-106). |
| 2. Product-domain | M2 | One acknowledgement, then the agenda of lenses rendered in full as prose, ending with a question asking you to confirm it. No repaint, no "your answer did not register" (SC-001). | 1 real decision. If the crew asks a further product question, answer it and count 1 more real decision; if it asks again for something M2 already said, that is a corrective exchange. |
| 3. Agenda | M3 | One acknowledgement. The agenda it acts on is the one on screen. The first lens opens with a short presentation and one open question. | 1 real decision |
| 4. One lens | M4 | A line like `Recorded: "...". This lens stays open until you type "move on"`, then follow-up or a summary. That line is designed behaviour (FR-028), not friction. | 1 real decision. **Check receipts now** (below): expect 3. |
| 5. Close and delegate | M5, then M6 when the next lens opens | M5 closes the lens and the next one opens. After M6 the crew records the rest as delegated, writes the spec, and presents the specify boundary packet: why it stopped, what was done, the decision, and the phrase to type. This is the slowest step; set up the next host's window while it works. | 2 real decisions |
| 6. Question about a boundary | M7 | The question is answered in prose. The packet is not shown again, at most mentioned in one line, and nothing is approved (round 3, finding 1). On disk, `verdict_history` has no `specify` row yet (check below). | Packet rendered again: 1 extra stop. Approval recorded: note it and stop this host's walk. |
| 7. Approve | M8 | The boundary advances once: one short acknowledgement and the next stage starting. No second copy of the reply, and no `Stop hook error` line on any host (SC-004). On disk, `verdict_history` ends with `to_boundary: specify`. | 1 real decision |
| 8. Compaction | Wait for the turn to end, then Compact, then M9 | The answer says specify is approved and names the current stage. The packet may be shown again once, sized to the gap: after compaction that is expected (spec, US2 scenario 2), not a repaint. `verdict_history` still ends with the `specify` row. | Asked to approve specify again, or told it is still pending: 1 corrective exchange (compaction lost the verdict). |
| 9. Close and resume | Exit, launch again in the same folder, then M10 | The resume opens with where you are, read from disk: the pending decision if any, commits since the last notes, task progress (none yet is a valid answer) (FR-019). The specify approval is not asked for again. | Asked again for an approval already recorded: 1 corrective exchange. |

Checkpoints: steps 2, 3 and 4 should yield **3 receipts and exactly 1 typed reply each** (SC-001).

### Host notes

- **Claude.** All steps apply. Compaction re-grounds the crew through the session-start hook. The workshop skill
  removes the question picker, so a picker appearing at all is worth a note.
- **Codex.** All steps apply, with two differences. Codex has no user-defined slash commands, so the dials sentence
  ends with `ask me to update your profile` instead of a command, and `/specrew-*` commands are not available; use the
  disk checks below from a second PowerShell window. Compaction re-grounds through the same session-start event as
  Claude (Specrew's Codex host manifest). Whether `/compact` and `/quit` are the exact Codex commands is (verify).
- **Copilot.** All steps apply. If a question picker appears, do not press Ctrl+O: Copilot reports that as
  `User skipped question`, which is an absence and not an answer. Type the message instead, and note the picker.
  Copilot has no compaction hook in Specrew's host manifest (it is listed as pending), so after Compact the crew is
  re-grounded only by your next message (M9). The verdict must still hold, because it lives on disk. Whether `/compact`
  exists in your Copilot version is (verify); if it does not, mark step 8 `null` and say why in Notes.

If the orientation does not appear at all on a host (the hook did not fire), exit, run
`specrew start --host <host> --skip-update-check` in the same folder, and continue from M1. Count 1 corrective exchange
and write what happened in Notes.

## Tier 1 frictions to watch for

| Friction | What it looks like on screen | How to count it | Scenario |
| --- | --- | --- | --- |
| A typed approval on its own line refused for position | M8, sent alone, is answered with a refusal or "not recognised", or nothing advances | 1 corrective exchange and 1 extra stop, plus the exact reply in Notes. The bare phrase alone is the supported route and must work in 202. The case of a phrase typed below other text is B4F-125, iteration 2. | B4F-125 (shape) |
| A compaction losing a verdict | After step 8, the crew asks for `approved for specify` again or says it is pending | 1 corrective exchange | US2 scenario 2 |
| A heading repaint | The same reply appears twice, the second copy with slightly reworded headings, often after a Stop hook message | 1 extra stop (as DRIFT-030 was counted) | B4F-104 class (FR-012) |
| A refused stop | The crew says it could not end its turn, or a Stop hook message appears and it carries on without asking you anything | 1 extra stop when you saw it; the disk check below shows how many happened | B4F-104 |
| A reply repainted over reworded headings | A whole reply rendered again because one heading was reworded from the saved draft | 1 extra stop; the DRIFT-030 fix (`dc5a4fb8`) should prevent it | B4F-104 class (FR-012) |
| A missing dials line costing a cycle | The crew stops or asks again because the adaptation sentence was missing | 1 corrective exchange | B4F-106 |
| A refusal that does not name its cause | Any refusal without what failed and one recovery action | Note it, with the exact text | SC-007 |

For every non-zero count, write down what you typed and what came back, word for word.

## Disk checks

Run these from a second PowerShell window in the host's folder (`Set-Location C:\scratch\walk-202\<host>`). They only
read files.

### Receipts (after step 4)

The receipts file is `.specrew/runtime/workshop-authority.jsonl` (written by
`extensions/specrew-speckit/scripts/workshop-authority-store.ps1`). One line per typed reply that was recorded.

```powershell
$f = '.specrew\runtime\workshop-authority.jsonl'
if (Test-Path $f) {
    $r = @(Get-Content $f | Where-Object { $_.Trim() } | ForEach-Object { $_ | ConvertFrom-Json })
    "receipts: $($r.Count)"
    $r | Format-Table recorded_at, host_kind, phase, lens, confirmation -AutoSize
} else { 'receipts: 0 (file absent)' }
```

Expected after step 4: `receipts: 3`, with phases `product-domain`, `agenda` and `lens`, and `host_kind` naming this
host. Write the count in "Receipts after step 4".

Replies that were not recorded, and why, are in `.specrew/runtime/workshop-receipt-outcomes.jsonl`:

```powershell
$o = '.specrew\runtime\workshop-receipt-outcomes.jsonl'
if (Test-Path $o) {
    Get-Content $o | Where-Object { $_.Trim() } | ForEach-Object { $_ | ConvertFrom-Json } |
        Where-Object status -ne 'recorded' | Format-Table recorded_at, status, reason, phase -AutoSize
} else { 'no refused or degraded replies (file absent)' }
```

Expected: no rows. A `refused` or `degraded` row during steps 2 to 4 is a Tier 1 regression; its `reason` names the
cause.

### Verdicts (steps 6, 7 and 8)

```powershell
$be = (Get-Content .specrew\start-context.json -Raw | ConvertFrom-Json).boundary_enforcement
$be | Format-List last_authorized_boundary, pending_next_boundary
$be.verdict_history | Format-Table to_boundary, verdict_text, evidence_source, recorded_at -AutoSize
```

After step 6: no `specify` row. After step 7: exactly one `specify` row. After step 8 and step 9: still exactly one.

### Refused stops (any time)

```powershell
Get-Content .specrew\runtime\conformance-journal.jsonl | ForEach-Object { $_ | ConvertFrom-Json } |
    Where-Object event -like 'stop-block*' | Format-Table recorded_at, host, event, block_kind -AutoSize
```

Each `stop-block` row is a turn end the hooks sent back for more work. Not every one reaches you as a stop: count an
extra stop only for what you saw on screen, and copy the row count into Notes as `stop-blocks: <n>`.

### Per-host friction counts

The three counts come from your tally, step by step. The disk checks back them up: receipts and outcomes for steps
2 to 4, verdicts for steps 6 to 9, stop-block rows for repaints and refused stops. Where your tally and the disk
disagree, write both in Notes.

## Friction record (fill per host)

| Host | Version | Date | Real decisions | Corrective exchanges | Extra stops | Receipts after step 4 | Replies per checkpoint | Notes |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Claude | 2.1.301 | 2026-10-16 | 7 | 1 | 4 | 3 | 1/1/1 | See "Walk notes: Claude". stop-blocks: 1 |
| Codex (healthy worktree) | | | null | null | null | null | null | |
| Copilot | | | null | null | null | null | null | |

Expected per host: 6 real decisions (7 or more only if the crew asked further real questions), 0 corrective
exchanges, 0 extra stops, 3 receipts after step 4, and 1 reply per checkpoint (write it as `1/1/1`).

### Walk notes: Claude (2026-10-16)

The maintainer's tally, checked against the disk in `C:\scratch\walk-202\claude`. The two agree.

1. M2 carried a stray sentence copied from this guide by mistake. Claude took it as "move on". Not counted.
2. M4 was replaced, because the first lens was `requirements-nfr`, not `architecture`.
3. The reviewer choice after M6 is a real decision, because it spends the maintainer's quota, so it counts as
   decision 7. Open question from the maintainer: could it be asked earlier?
4. 1 corrective exchange and 1 extra stop: "you decide the remaining lenses" was recorded for one lens only, and
   `code-implementation` then asked "confirm or you decide this lens". Disk: `architecture-core` is `human-delegated`,
   then `code-implementation` is `human-confirmed` and then `human-delegated`.
5. 1 extra stop: permission to create the branch and commit before the spec packet. Feature setup never created branch
   `001-word-count`, the pre-check refuses to show the packet while work is uncommitted, and Claude Code commits only
   when asked.
6. 1 extra stop: M7 was answered, then the full packet was shown again. The crew chose a boundary turn end for an
   answer to a question.
7. 1 extra stop: after the restart, the packet was sent back once for a missing recommendation. The maintainer saw
   one line about it ("The packet was missing a recommendation, so I'm adding one and verifying again.") and one copy
   of the packet. Disk: 1 `stop-block` row, `block_kind: presentation`.
8. Step 9 (M10) passed. After the restart Claude went straight back to the clarify approval, said "'Continue' isn't an
   approval", and did not ask for `approved for specify` again.
9. Not counted:
   - M9 was answered with a full packet (status after compaction, which the spec allows).
   - The approval row has `authorizing_human: unattributed` and an empty `from_boundary`.
   - The stop journal has no rows for turns 4 and 10.
   - On restart, the exited session was flagged as "another session may be active".
   - The NEL sentence came out garbled ("treat  break.").
   - The orientation says "no feature is in progress" twice.

Disk at the end of the walk: receipts 7, all `recorded` with no refused or degraded outcomes (3 by step 4: product-domain,
agenda, `requirements-nfr`). `verdict_history` has exactly one row, `to_boundary: specify`,
`evidence_source: hook-captured-from-transcript`. The last authorized stage is `specify`, and `clarify` is pending.

## After the walk

Fill the after-values in `acceptance-evidence.md`, section "Friction: before and after". Its table keeps its
columns; replace each `null` after the arrow with what the walk observed, per host where the row covers more than one.

| Scenario | Walk evidence | Where to read the after-value |
| --- | --- | --- |
| B4F-106 | Steps 1 to 9, dials sentence and orientation facts | Corrective exchanges and extra stops about the dials line, each host |
| B4F-096 | Step 1 | Whether the first question came before the orientation, each host |
| B4F-108, Codex | Steps 2 to 4 on Codex | Receipts after step 4 and replies per checkpoint (before: the checkpoint never closed) |
| B4F-108, Claude | Steps 2 to 4 on Claude | Receipts after step 4 and replies per checkpoint (before: 1 corrective round) |
| 2026-09-09 to 10-13 outage | Not walked | Leave `null` |

Skeleton for the filled table:

| Scenario | Real decisions | Corrective exchanges (before → after) | Extra stops (before → after) | Source |
| --- | --- | --- | --- | --- |
| B4F-106 | unchanged / changed | 1 corrective cycle → Claude ?, Codex ?, Copilot ? | null → Claude ?, Codex ?, Copilot ? | live walk, date |
| B4F-096 | unchanged / changed | 1 → Claude ?, Codex ?, Copilot ? | 1 → Claude ?, Codex ?, Copilot ? | live walk, date |
| B4F-108, Codex | unchanged / changed | the checkpoint never closed → ? (receipts ?, replies ?) | null → ? | live walk, date |
| B4F-108, Claude | unchanged / changed | 1 corrective round → ? (receipts ?, replies ?) | null → ? | live walk, date |
| B4F-108, Copilot (optional new row) | unchanged / changed | null → ? (receipts ?, replies ?) | null → ? | live walk, date |
| 2026-09-09 to 10-13 outage | null | null → null | null → null | not captured |

"Real decisions: unchanged" holds when each host needed the 6 scripted decisions and no more for the same work.

Then update the SC-001 and SC-003 rows of the "Success criteria" table from **null** to what the walk showed. Any
non-zero corrective exchange or extra stop is a Tier 1 regression, recorded with what you typed and what came back.

### The comparison that decides whether 202 worked

The measure is not the defect count. It is the number of stops that asked you for no decision about the work,
compared with beta4. The beta4 baseline comes from the maintainer's UX ruling of 2026-08-28: in one walk session,
work stopped **8 times and none of the stops was about the code** under review. The same table is in
`acceptance-evidence.md`, section "The measure: stops against the beta4 baseline"; fill the walk columns there.

| Measure | beta4 baseline (one walk session, 2026-08) | 202 walk: Claude | 202 walk: Codex | 202 walk: Copilot |
| --- | --- | --- | --- | --- |
| Stops that asked for no decision (extra stops) | 8 | | | |
| Stops about the work (real decisions) | null (not counted) | | | |
| Corrective exchanges | null (not counted) | | | |
| Refusals that did not name their cause | null (not counted) | | | |

Two honest limits on the comparison. The beta4 session was a review-stage walk, and this walk covers intake to the
specify approval, so the stages differ; what is compared is the same quantity, stops that asked for no decision. And
202 targets 0 extra stops per Tier 1 scenario (SC-003), so the result to look for is 0 on each host, not merely a
number below 8.

## Cleanup (the maintainer does this)

1. Copy anything you want to keep as evidence out of the three folders first: each folder's
   `.specrew\runtime\workshop-authority.jsonl`, `.specrew\runtime\workshop-receipt-outcomes.jsonl`,
   `.specrew\runtime\conformance-journal.jsonl` and `.specrew\start-context.json`.
2. Exit every host session that is open in a walk folder, so no file is held open.
3. Remove the walk root, including the clone:

   ```powershell
   Remove-Item -LiteralPath C:\scratch\walk-202 -Recurse -Force
   ```

4. Decide what module you want installed afterwards. To keep this build, do nothing. To go back to the released
   beta, `Install-Module Specrew -Scope CurrentUser -SkipPublisherCheck -AllowPrerelease -Force` (the README's
   prerelease install; whether it cleanly replaces a same-version local build is (verify)). Then check with
   `specrew version`.
5. The hosts may keep entries for the removed folders in their own settings, such as trusted-folder lists. They are
   harmless; where each host keeps them is (verify).
