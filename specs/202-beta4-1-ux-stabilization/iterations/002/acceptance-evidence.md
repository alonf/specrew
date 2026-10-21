# Iteration 002 acceptance evidence (T024)

The evidence for iteration 002, "one human act, one record". Each requirement and success criterion maps to the
tests or records that show it. A value that needs a live run on a real host comes only from the Copilot re-walk
(`copilot-rewalk.md`), and until then it is `null`, never `0`.

## Release gate

beta4.1 does not ship until B4F-127 and B4F-129 are both fixed (maintainer ruling).

| Defect | Fixed by | Evidence | Status |
| --- | --- | --- | --- |
| B4F-127: one typed approval recorded twice, by the message hook and by the turn end | T017 (FR-027), with the round 1 to 5 fixes and B4F-137 | `message-identity.tests.ps1`: B4F-127's numbers (2 approvals per message, 5 in a long transcript) RED on the old code, 1 after | Fixed in code; reviewed through round 5 |
| B4F-129: Copilot runs Claude's hooks, so every receipt and stop block was written twice, once as `claude` | T016 (FR-028), with round 5 finding 4 | `host-binding-match.tests.ps1` (255 assertions): all 12 Copilot payloads in the Claude hook, RED on the old code (79 failures), green after | Fixed in code against Copilot's own-hook payloads only; **not fixed live**: the re-walk failed at M1 (SC-011, B4F-144) |

## Requirements

| FR | What it asks | Task | Evidence | Status |
| --- | --- | --- | --- | --- |
| FR-027 | One message, at most one recorded approval of each kind, keyed by the host's message identity; on Copilot a miss is reported | T017 | `message-identity.tests.ps1` (43 cases, among them every finding of rounds 1 to 4 and B4F-137 as its own replay); `turn-record-contract.tests.ps1` (the dispatcher forwards the message ID and identity) | Green |
| FR-028 | A hook stands down only on a positive foreign match; the receipt store refuses an ID it holds | T016 | `host-binding-match.tests.ps1`; `workshop-delegation.tests.ps1` case 9 (round 5: the same reply is refused, the same words in a new message are a new act, with and without message IDs) | Green |
| FR-029 | The approval form: pastes on Claude, quoted menus, the named reason elsewhere, a reset that authorizes its round, no command offered as the approval | T018 | `approval-form.tests.ps1` (51 cases: 17 from T018, among them the live B4F-125 message; 9 from round 5, a quoted menu reaching no writer and a host envelope never reduced; 19 from round 6, bulleted options, a condition on its own line, an envelope inside a paste, and a message the host added; 4 from round 7, a qualified partial sign-off and a conditional coverage deferral; 2 from round 8, the qualified partial sign-off on Codex and Copilot), and `verdict-capture-blocks` W45 (9), round 8: a boundary approval beside a paste | Green |
| FR-030 | A reworded discussion question counts as present | T019 | `presented-check.tests.ps1` case 9 (B4F-128's two exact lines) case 10 (round 5: a dotted identifier such as `1.2`) and case 11 (round 6: a reversed before or after) | Green |
| FR-031 | The wide delegation forms cover every remaining lens; a narrow one says so; the reviewer choice is asked once, outside delegation | T020 | `workshop-delegation.tests.ps1` cases 1 to 10 (case 8, round 5: a reply that names the remaining lenses to exclude them covers only the open lens; case 10, round 6: only a reviewer pick may follow a wide delegation; case 11, round 7: a short reply is a reviewer pick only as the answer to the reviewer question) | Green |
| FR-032 | No shipped instruction permits a question tool for workshop questions | T021 | `workshop-question-tool.tests.ps1` (47 shipped files) | Green |
| FR-033 | Each session keeps its own reply outcome; the shared outcomes journal is gone, and `specrew update` deletes it | T022 | `receipt-disclosure.tests.ps1` case 20 (R5-5, two sessions); `receipt-outcomes-retired.tests.ps1` (a real update deletes the journal; no shipped code names it but that step); `cross-host-workshop.tests.ps1` | Green |
| FR-034 | The turn-end script writes no draft copy; the message stays in the turn record | T023 | `turn-draft-intake.tests.ps1` (cases 1 to 6: no copy for stdin, `-MessagePath`, two sessions or no session ID; case 9: no shipped file names the copy). RED on the old code with 11 failures, green after | Green; reviewed in round 6 (no finding on it) |

## Success criteria

| SC | What it asks | Evidence | Status |
| --- | --- | --- | --- |
| SC-010 | On each validated host, one approval replayed from recorded payloads through every recording path gives exactly one approval row, and N later turns with no human message add none | `message-identity.tests.ps1`, "One typed approval, both recording paths, N turn ends: exactly one recorded approval (SC-010)": Claude and Codex with short and long transcripts, and Copilot, the message hook and 4 turn ends; spent before the first turn end, nothing spendable after 3 more; on Copilot the message hook is the only path and a miss is reported, never recorded by the turn end | Green on all three hosts |
| SC-011 | In a live Copilot walk in a project that also holds Claude's hook settings, 0 receipts or stop-block rows under `claude`, and every receipt ID once | `copilot-rewalk.md`, its disk checks split by host. Before: 16 receipts for 8 replies, each written as `copilot` and as `claude`; 8 stop-block rows, all `claude` (iteration-1 walk) | **Failed at M1** (2026-10-20, Copilot 1.0.98, build `7ebd9dba`): after M2, 2 UserPromptSubmit and 1 SessionStart rows under `claude` in `hook-output-authority.jsonl`, 1 material stop-block row under `claude`, two conformance sessions. Cause: B4F-144. The full M1-to-M8 tally is in `copilot-rewalk.md` (Record): 0 receipts under `claude` and none written twice; 8 stop-block rows under `claude`, plus 5 workshop-intermediate ones; 4 unrecognized-payload records |

## Co-review

Eight rounds on codex in iteration 002, each started by the maintainer's own typed `approved for review round` (rounds
5 to 8 after the allowance reset of 2026-10-17). Every finding was checked against the code and listed as real or not,
with the reason (`drift-log.md`, DRIFT-003).

| Round | Run | Covered | Findings | Real |
| --- | --- | --- | --- | --- |
| 1 | `run-20261017-093636207-bf1e4cc7` | T016, T017 | 6 | 6 |
| 2 | `run-20261017-134352532-0fb503db` | round-1 fixes | 4 | 4 |
| 3 | `run-20261017-152855473-5b668458` | round-2 fixes | 3 | 3 |
| 4 | `run-20261017-181522696-4d1fe121` | round-3 fixes | 3 | 3 |
| 5 | `run-20261018-075433218-7cbe648b` | round-4 fixes, B4F-137, T018 to T022 | 5 | 5 |
| 6 | `run-20261018-114927550-9d62a483` | round-5 fixes, T023, T024 | 6 | 6 |
| 7 | `run-20261018-125258950-98a6a63d` | round-6 fixes | 3 | 3 |
| 8 | `run-20261018-163747348-5da84de1` | round-7 fixes | 2 | 2 |

32 of 32 findings are real; across feature 202, 64 of 64 (B4F-055). The review engine demoted 28 of the 32 as having
"no concrete failure scenario", and each one states one. The round-8 fixes were not reviewed: the allowance was
spent, and the maintainer accepted them by a typed partial sign-off on 2026-10-18, with the reason recorded.

## Validator against the known baseline

`validate-governance.ps1 -ProjectPath .` (full repository, unscoped), on 2026-10-18 at `5c6ee894` plus T023 in the
working tree, in this worktree:

| Iterations validated | Failing iterations | Failure messages | Categories |
| --- | --- | --- | --- |
| 23 | 16 | 17 | review-evidence (15), defer-provenance (001/011), needs-rework (198/011) |

Every failure is in a known-baseline category (spec, "Known validator baseline"), and 202's iteration 002 passes. The
counts match the iteration-1 closeout run in this worktree (23, 17, the same three categories). The 15
review-evidence failures depend on state, not code (B4F-124).

## Verification lanes

All eight lanes, run in parallel on 2026-10-18 on the round-5 fixes:

| Lane | Elapsed | Timeout |
| --- | --- | --- |
| `iteration-002-governance-202` | 23.8 s | 180 s |
| `f199-class-guards-a` | 157.3 s | 270 s |
| `f199-class-guards-b` | 118.6 s | 270 s |
| `f199-slice-suites-a` | 215.7 s | 480 s |
| `f199-slice-suites-b` | 160.2 s | 480 s |
| `f202-slice-suites-a` | 228.6 s | 600 s |
| `f202-slice-suites-b` | 286.0 s | 600 s |
| `f202-i002-suites` | 389.7 s | 660 s |

All eight passed. The elapsed times are from the parallel run; the 2.4x headroom floor is measured on single-lane runs
(`f202-i002-suites`: 274 s alone after T018 to T021, so 660 s).
