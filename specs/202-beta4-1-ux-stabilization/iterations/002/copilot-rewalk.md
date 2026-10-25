# Copilot re-walk: one host, two hook sets (SC-011)

The maintainer walks this once, on Copilot, after iteration 002's review. It checks the one result the tests cannot:
on a real Copilot install, in a project that also holds Claude's hook settings, nothing is written under `claude`
(B4F-129), and every receipt is written once. It also re-counts Copilot's friction against the iteration-1 walk,
where Copilot had 9 extra stops and 5 corrective exchanges.

Budget: about 5 minutes of setup and about 10 minutes of walk. Everything runs under `C:\scratch\rewalk-202`. Nothing
runs in the 202 worktree or in any other repository. A value that was not observed is `null`, never `0`.

## Setup

1. **Build.** Follow `live-walk.md` (iteration 001) setup steps 1 to 4, with `C:\scratch\rewalk-202` in place of
   `C:\scratch\walk-202`. The clone takes the branch as it is when you clone it, so clone after the iteration-002
   review fixes are pushed. Note the commit the clone prints.
2. **Project.** In a new PowerShell 7 window:

   ```powershell
   $p = 'C:\scratch\rewalk-202\copilot'
   New-Item -ItemType Directory -Force $p | Out-Null
   git -C $p init -q
   Set-Location $p
   specrew init
   Test-Path .claude\settings.local.json
   ```

   The last line must print `True`: `specrew init` writes Claude's hook settings into every project, and that file is
   what made Copilot run every Specrew hook twice in the iteration-1 walk. If it prints `False`, the walk cannot test
   SC-011: stop, and write `null` with the reason.
3. Record `copilot --version`.
4. **Capture hook** (added for the second walk, T030). It keeps every payload Copilot sends during the walk, on both
   channels, so a shape no test has can become a test. From the clone you made in step 1:

   ```powershell
   pwsh -File <clone>\tests\host-probes\walk-capture-hook.ps1 -Install -Project $p -OutDir C:\scratch\rewalk-202\capture
   ```

   It adds one file, `specrew-walk-capture.json`, to `~\.copilot\hooks`, beside Specrew's, and a capture entry per
   event to the project's `.claude\settings.local.json`. It changes nothing else. Cleanup takes both out again.

## The walk

Launch `copilot --allow-all` in the project folder. Send M1 to M8 from `live-walk.md` ("The script"), each on its own,
verbatim, through the "Approve" step (step 7). Keep the same tally: real decisions, corrective exchanges, extra stops.

What should be different from the iteration-1 walk:

| Step | Iteration 1 on Copilot | Expected now |
| --- | --- | --- |
| Every turn | each hook ran twice, once as `copilot` and once as `claude`; hidden and visible stop blocks from the `claude` one | each hook acts once, as `copilot` (T016) |
| Lens questions | asked through Copilot's question box; box answers recorded nothing | asked as prose; you type the answer (T021) |
| M6 `you decide the remaining lenses` | recorded for one lens; the next lenses asked again | one record per remaining lens, and the crew names them (T020) |
| M8 `approved for specify` | the packet shown twice after a hook message | one short acknowledgement and the next stage starting |

If a question box appears anyway, do not press Ctrl+O. Type the answer in chat and note the box.

## Disk checks, split by host

Run these from a second PowerShell window in `C:\scratch\rewalk-202\copilot`. They only read files.

### Receipts (after M6)

```powershell
$f = '.specrew\runtime\workshop-authority.jsonl'
$r = @(if (Test-Path $f) { Get-Content $f | Where-Object { $_.Trim() } | ForEach-Object { $_ | ConvertFrom-Json } })
$r | Group-Object host_kind | Format-Table Name, Count -AutoSize
"receipts under claude: $(@($r | Where-Object host_kind -eq 'claude').Count)"
"receipt IDs written more than once: $(@($r | Group-Object receipt_id | Where-Object Count -gt 1).Count)"
$r | Format-Table recorded_at, host_kind, phase, lens, confirmation, delegation_breadth -AutoSize
```

SC-011 expects `receipts under claude: 0` and `receipt IDs written more than once: 0`. After M6, each lens still open
should show one `human-delegated` row with `delegation_breadth: remaining-lenses`.

### Stop blocks (any time)

```powershell
$j = @(Get-Content .specrew\runtime\conformance-journal.jsonl | Where-Object { $_.Trim() } |
    ForEach-Object { $_ | ConvertFrom-Json } | Where-Object event -like 'stop-block*')
$j | Group-Object host | Format-Table Name, Count -AutoSize
"stop-block rows under claude: $(@($j | Where-Object host -eq 'claude').Count)"
```

SC-011 expects `stop-block rows under claude: 0`. In the iteration-1 walk this was 8. Rows under `copilot` are turn
ends Copilot's own hook sent back for more work; count an extra stop only for what you saw on screen.

### Hook rows under claude (any time)

This is the check the first walk failed at M1.

```powershell
$h = @(Get-Content .specrew\runtime\hook-output-authority.jsonl | Where-Object { $_.Trim() } | ForEach-Object { $_ | ConvertFrom-Json })
$h | Group-Object host | Format-Table Name, Count -AutoSize
"hook rows under claude: $(@($h | Where-Object host -eq 'claude').Count)"
"conformance sessions: $(@(Get-ChildItem .specrew\runtime\conformance-sessions -Directory -ErrorAction SilentlyContinue).Count)"
```

SC-011 expects `hook rows under claude: 0`. In the first walk, M1 and M2 left 3, and two conformance sessions, one per
host.

### Payloads not recognized (any time)

```powershell
$u = @(Get-ChildItem .specrew\runtime\hook-health -Filter 'unrecognized-payload-*.json' -ErrorAction SilentlyContinue)
"unrecognized-payload records: $($u.Count)"
$u | ForEach-Object { Get-Content $_.FullName -Raw | ConvertFrom-Json } | Format-Table host, event, field_names -AutoSize -Wrap
```

Expected: `unrecognized-payload records: 0`. Each record is a payload shape no host binding knew; the first walk left
4 (T027).

### Replies not recorded

Each session keeps its own reply outcome now (T022); the shared outcomes file is gone.

```powershell
Get-ChildItem .specrew\runtime\conformance-sessions -Recurse -Filter workshop-receipt-outcome.json |
    ForEach-Object { (Get-Content $_.FullName -Raw | ConvertFrom-Json).last } |
    Format-Table recorded_at, status, reason, phase -AutoSize
```

Expected: no `refused` or `degraded` row.

### The approval (after M8)

```powershell
$be = (Get-Content .specrew\start-context.json -Raw | ConvertFrom-Json).boundary_enforcement
$be.verdict_history | Format-Table to_boundary, verdict_text, evidence_source, recorded_at -AutoSize
```

Expected: exactly one `specify` row, `evidence_source: hook-captured-user-prompt`.

### Captured payloads (after the walk)

```powershell
pwsh -File <clone>\tests\host-probes\walk-capture-hook.ps1 -Summary -OutDir C:\scratch\rewalk-202\capture
```

It lists each payload shape seen, per channel and event, with its field names. Keep the folder: the crew replays the
captures through the deployed hooks and adds any new shape to the fixtures.

## Record

Fill one row, and add it to `acceptance-evidence.md` (iteration 002, SC-011).

| Copilot version | Date | Commit | Receipts under claude | Receipt IDs written twice | Stop-block rows under claude | Real decisions | Corrective exchanges | Extra stops | Notes |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 1.0.98 | 2026-10-20 | `7ebd9dba` | 0 | 0 | 8 (5 boundary not-presented, 2 material, 1 cap announce), plus 5 workshop-intermediate material rows | 6 | 1 | 2 | **Failed at M1** (B4F-144). T020 delegation: 5 of 5 lenses human-delegated. Specify verdict: 1 row, hook-captured-user-prompt. 4 unrecognized-payload records, two of them from a sub-agent (B4F-147). Corrective exchange: M2 typed again after the question box (B4F-131). Extra stops: the specify packet shown again after M6, by the `claude` boundary block replayed as a message; and the full packet rendered again at M7, which Copilot's own hook recorded as presented-unchanged (B4F-134, independent of B4F-144) |

In Notes, give the hook rows under `claude`, the unrecognized-payload records and the number of captured payloads.
For every non-zero count, write down what you typed and what came back, word for word. If Copilot no longer runs
Claude's hooks at all, the zeros still hold but do not show the hook standing down; say so in Notes
(`host-binding-match.tests.ps1` shows the stand-down with recorded payloads).

## Cleanup

First take the capture hook out. It moves its Copilot file into the capture folder and removes its entries from the
project's Claude settings:

```powershell
pwsh -File <clone>\tests\host-probes\walk-capture-hook.ps1 -Remove -Project C:\scratch\rewalk-202\copilot -OutDir C:\scratch\rewalk-202\capture
```

Copy `C:\scratch\rewalk-202\capture` out, or tell the crew where it is, before the folder goes.

Then as in `live-walk.md` (iteration 001), with `C:\scratch\rewalk-202` as the folder to remove. Copy
`workshop-authority.jsonl`, `conformance-journal.jsonl` and `start-context.json` out first if you want to keep them.
