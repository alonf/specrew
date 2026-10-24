# Acceptance Evidence: Iteration 003

Feature 202, iteration 003. It holds the fixes for the failed SC-011 re-walk (T025 to T029, B4F-144), B4F-146 (T031,
T032) and the acceptance with the maintainer's second Copilot re-walk (T030). Scope: FR-027, FR-028 and FR-032 (US8);
SC-011.

## Tasks

| Task | What it fixes | Evidence | Status |
| --- | --- | --- | --- |
| T025 | Capture the real payloads (B4F-145) | `tests/host-probes/host-payload-capture-probe.ps1` on Copilot 1.0.101, Claude 2.1.303 and Codex 0.163.0, sub-agents included; fixtures in `tests/fixtures/hook-payloads/probe/`. The probe failed 14 checks on the old code, all on Claude's hooks under Copilot, and passes 108 of 108 after T026 | Green; live: 0 unrecognized-payload records in the re-walk |
| T026 | Copilot's second payload shape (B4F-144) | `host-binding-match.tests.ps1` part 1b: 32 failures on the old code, green after | Green; **held live**: 0 hook rows under `claude` (26 under `copilot`), with 323 of the walk's 641 payloads sent through Claude's settings |
| T027 | A reader for the unrecognized-payload record | `host-binding-match` parts 1 and 1b fail on any record; the walk counts them | Green; live: 0 records |
| T028 | A sub-agent's task text is never a human approval (B4F-147) | `subagent-prompt-authority.tests.ps1`: 23 failures on the old code, green after | Green; **held live**: the `speckit.specify` sub-agent's instructions were refused as not typed by the human, and nothing was stored. They still left a refused row and an extra session (B4F-155) |
| T029 | Product-domain questions in prose (B4F-131, FR-032) | `workshop-question-tool.tests.ps1` (122 shipped files): 11 failures on the old text, green after | Green on the text; **not held live**: Copilot asked the product-domain question through `ask_user` at M1, and again after M2 (B4F-131 seen again, B4F-153). Outside the beta4.1 gate by the maintainer's ruling of 2026-10-24 |
| T031 | An iteration closeout is recorded as closed only on its approval (B4F-146) | `closeout-records-on-approval.tests.ps1` cases 1 to 4: 2 failures on the old code, green after | Green; its live acceptance is iteration 003's own closeout, still to come |
| T032 | A feature closeout clears nothing before its approval | `closeout-records-on-approval.tests.ps1` cases 5 to 8: 5 failures on the old code, green after | Green; its live acceptance is 202's feature closeout, still to come |
| T030 | Acceptance and the re-walk with a capture hook | This file; `tests/host-probes/walk-capture-hook.ps1`; eight new payload shapes from the walk added to the probe fixtures (`1509b896`). `host-binding-match` and `subagent-prompt-authority` pass with them | Done |

## Success criteria

| SC | What it asks | Evidence | Status |
| --- | --- | --- | --- |
| SC-011 | In a live Copilot walk in a project that also holds Claude's hook settings, 0 receipts or stop-block rows under `claude`, and every receipt ID once | The maintainer's re-walk, run from `iterations/002/copilot-rewalk.md` with its disk checks split by host. Before (first re-walk, 2026-10-20, `7ebd9dba`): failed at M1, with 3 hook rows and 8 stop-block rows under `claude` | **Passed** (2026-10-23 to 2026-10-24, Copilot 1.0.101, `2ea34f92`). 0 receipts under `claude` (8 under `copilot`), no receipt ID written twice, 0 stop-block rows, 0 hook rows under `claude`. Copilot still runs Claude's hooks, so the zeros show those hooks standing down |

## The re-walk record

The walk script's Record row, kept here because iteration 002 is closed (DRIFT-002). The first re-walk's row stays in
`iterations/002/copilot-rewalk.md`.

| Copilot version | Date | Commit | Receipts under claude | Receipt IDs written twice | Stop-block rows under claude | Real decisions | Corrective exchanges | Extra stops | Notes |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 1.0.101 | 2026-10-23 to 2026-10-24 (UTC) | `2ea34f92` | 0 (8 under `copilot`) | 0 | 0 | 8 | 1 | 0 | **Passed SC-011.** Hook rows under `claude`: 0 (26 under `copilot`); one conformance session for the main agent. Unrecognized-payload records: 0. Captured payloads: 641, 318 on Copilot's own hooks and 323 through Claude's settings. T020 delegation: 4 of 4 remaining lenses human-delegated, `remaining-lenses`. M7: a short answer, no packet repeat. Specify verdict: 1 row, `hook-captured-user-prompt`; the clarify packet is pending, not approved. Corrective exchange: M2 typed again (miss 2). Misses: see below |

Friction across the walks on Copilot: iteration 1 had 9 extra stops and 5 corrective exchanges, the first re-walk 2
and 1, this one 0 and 1.

## Misses in the walk, and where they are logged

| # | What the maintainer saw | Logged as |
| --- | --- | --- |
| 1 | The product-domain question at M1 went through `ask_user` despite `product-domain.md` line 32; after M2 a second `ask_user` offered "governed workshop recovery" | B4F-131, seen again (T029 not held live) |
| 2 | Esc on the box folded M2 into the running turn; the user-message hook never fired, nothing was recorded, and M2 was typed again | B4F-153 |
| 3 | The first `move on`, closing product-domain, was refused as agenda-not-shown, and the refusal is stored with a +03:00 local time | B4F-154 |
| 4 | The `speckit.specify` sub-agent's instructions were refused as not typed by the human: safe, but a refused row and an extra conformance session, and one more session after the specify approval | B4F-155 |
| 5 | Both packets run the reply options together on one line, and the hidden boundary tag shows as visible text | B4F-156 |
| 6 | The turn after the product-domain record ended on "Next comes the short workshop agenda", with no direct ask | B5F-011 |
| 7 | The agenda question also asked for the reviewer choice | B4F-157 |

## Payload shapes captured in the walk

The capture hook kept 641 payloads in 22 shapes (channel, event and field names). 14 matched a probe fixture. The 8 new
shapes are fixtures now (`1509b896`), redacted with `ConvertTo-ProbeRedactedFixtureText`, with provenance naming the
walk:

- On both Copilot channels: a sub-agent's tool call before and after (`probe-pretooluse-subagent-1.json`,
  `probe-posttooluse-subagent-1.json`) and its stop (`probe-subagentstop-subagent-2.json`).
- On Claude's hooks as Copilot runs them: `SubagentStart` with camelCase session fields and no event name
  (`probe-subagentstart-subagent-2.json`), and `Notification` (`probe-notification-1.json`).

`host-binding-match` replays the stop and after-tool shapes through the deployed hooks of every host: every one is
recognized, the other hosts' hooks stand down, and Copilot's own hook stands down on the sub-agent's stop. The shapes
show the sub-agent's tool calls carrying its own agent ID as the session ID (B4F-155).

## The release gate

The beta4.1 gate is B4F-127 and B4F-129, and since 2026-10-21 it sits at 202's feature closeout, until this iteration's
Copilot re-walk passes. The re-walk passed: one specify approval was recorded, from the maintainer's own typed message,
and nothing was written under `claude`. Misses 1 and 2 recorded nothing false, are in the released beta4, and 202 does
not make them worse. The maintainer ruled them outside the gate on 2026-10-24 (`keep the gate as ruled`).

## Co-review

Four rounds on codex, each started by the maintainer's own typed `approved for review round`.

| Round | Run | Covered | Findings | Outcome |
| --- | --- | --- | --- | --- |
| 1 | `run-20261021-160210288-728ad1a0` | T025 to T032; partial, it could not run `git diff` | 1 minor | Fixed (T032, the consumer's module version, `0f04b5cd`) |
| 2 | `run-20261021-195823967-0de4a137` | T025 to T029 and round 1's fix, from a file list | 2 minor, 2 notes | All fixed on `fix the findings now` |
| 3 | `run-20261022-085836670-1423f459` | Round 8's fixes (`ac87d96c`) and round 2's | 1 minor | Fixed on `fix the finding now` |
| 4 | `run-20261022-211453497-9ebe9c9c` | Round 3's fix | 1 note | Carried as B4F-151 |

Review sign-off completed on 2026-10-22, on the maintainer's `stop the review here`, with the final check on
`f00da0f2`. The runtime refresh followed (`2ea34f92`).
