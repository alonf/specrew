# Tier 1 acceptance evidence: iteration 001 (T015)

The evidence for the iteration-1 closeout, where the maintainer's verdict is the Tier 1 acceptance. Each success
criterion maps to the tests or records that show it. Values that need a live run on a real host come only from the
live walk (`live-walk.md`), and until then they are `null`, never `0`.

## Host tiers

| Tier | Hosts | Evidence |
| --- | --- | --- |
| **Validated** | Claude, Codex, Copilot | Real hook payloads recorded in scratch folders (T001) under `tests/fixtures/hook-payloads/{claude,codex,copilot}/`. `cross-host-workshop` and `turn-record-contract` drive each host's real adapter with them. The live walk at closeout is still to run. |
| **Experimental** | Cursor, Antigravity | No recorded hook payloads, so they are **unvalidated** in 202. They keep working through the shared path, with no live walk and no added scope. |

## Success criteria

| SC | What it asks | Evidence | Status |
| --- | --- | --- | --- |
| SC-001 | Product-domain, agenda, one lens: 3 receipts, 1 typed reply per checkpoint, on all three validated hosts | `cross-host-workshop.tests.ps1` (T005), through each host's real adapter with recorded payloads; `turn-record-contract.tests.ps1` (T002). Live walk: `live-walk.md` | Tests green. Live walk: **null** (not yet run) |
| SC-002 | Under every injected journal fault, 0 hook outputs count as a reply, and 0 turns are consumed without disclosure | `hook-output-journal.tests.ps1` cases (a) to (d) and the round-3 cases (T003); `journal-fault-injection.tests.ps1` case (e) and the lock-wait budget (T005, DRIFT-023); `receipt-disclosure.tests.ps1` (T004). Case (e) runs on Windows, Linux and macOS in every push (3-OS workflow) | Green on 3 OS (see CI below) |
| SC-003 | 0 corrective exchanges and 0 extra stops per Tier 1 scenario, real decisions unchanged | The friction table below. Before-values are the spec's baselines; after-values come only from the live walk | After-values: **null** (not yet run) |
| SC-004 | After the first presentation, each of B4F-104's three triggers produces 0 repaints and 0 `Stop hook error` lines | `crossing-presentation.tests.ps1` (T006), including round 3's question and refusal cases | Green |
| SC-005 | The adaptation text is byte-identical across hosts, apart from the correction command | `dials-parity.tests.ps1` (T009) | Green |
| SC-006 | Status, orientation and resume name the same feature in every constructed state; a second feature's specify opens a decision captured with 0 out-of-band authorizations | `feature-resolver.tests.ps1` (T010), `new-feature-reset.tests.ps1` (T011), `resume-from-disk.tests.ps1` (T012) | Green |
| SC-007 | Every Tier 1 refusal names its actual cause and one recovery action | `receipt-disclosure.tests.ps1` (T004, the cause named); `design-analysis-gate-refusal.tests.ps1` (T013, the producer and every gap); `turn-draft-intake.tests.ps1` case 6 (T014); the f199 class guard `refusal-names-what-failed` | Green |
| SC-008 | The validator at closeout shows no new failures in the known-baseline categories | The validator run below | Holds: every failure is in a baseline category |
| SC-009 | A new feature's boundary stops show 0 references to a closed feature's review campaign | `new-feature-reset.tests.ps1` (T011) | Green |

## Friction: before and after

| Scenario | Real decisions | Corrective exchanges (before → after) | Extra stops (before → after) | Source |
| --- | --- | --- | --- | --- |
| B4F-106 | unchanged | 1 corrective cycle → null | null → null | spec SC-003 baseline |
| B4F-096 | unchanged | 1 → null | 1 → null | spec SC-003 baseline |
| B4F-108, Codex | unchanged | the checkpoint never closed → null | null → null | spec SC-003 baseline |
| B4F-108, Claude | unchanged | 1 corrective round → null | null → null | spec SC-003 baseline |
| 2026-09-09 to 10-13 outage | null | null → null | null → null | not captured |

"null" means not captured. After-values are filled from the live walk only.

### The measure: stops against the beta4 baseline

Whether 202 worked is decided here, not by the defect count (maintainer ruling, 2026-10-16). The baseline is the
maintainer's UX ruling of 2026-08-28: in one beta4 session, work stopped 8 times, and none of the stops was about the
code. The walk columns are filled from `live-walk.md`. The stages differ (the beta4 session was at review; the walk
runs intake to the specify approval), and the quantity compared is the same: stops that asked for no decision. SC-003
targets 0 on each host.

| Measure | beta4 baseline (one session, 2026-08) | 202 walk: Claude | 202 walk: Codex | 202 walk: Copilot |
| --- | --- | --- | --- | --- |
| Stops that asked for no decision (extra stops) | 8 | null | null | null |
| Stops about the work (real decisions) | null (not counted) | null | null | null |
| Corrective exchanges | null (not counted) | null | null | null |
| Refusals that did not name their cause | null (not counted) | null | null | null |

### Friction observed during 202's own run

| Date | Event | Real decisions | Corrective exchanges | Extra stops | Disposition |
| --- | --- | --- | --- | --- | --- |
| 2026-10-15 | The first live turn through T014's stdin route was blocked by the Stop: two headings differed from the draft by function words ("now as one budget" / "now one budget"; "stdin, stored" / "stdin and are stored"), and the whole reply was rendered again. The B4F-104 repaint class (FR-012). | 0 | 0 | 1 | Fixed in 202 (DRIFT-030, `dc5a4fb8`): a heading counts as present when its meaning matches. `presented-check` case 8 holds the exact lines. |
| 2026-10-15 | The prompt hook answered the typed round approval with "reads as a verdict for 'review' ... nothing was recorded" (B4F-116, third time); the round approval itself was captured. | 0 | 0 | 0 | Beta5 (B4F-116). The dangerous direction is settled: see below. |
| 2026-10-15 | The Stop review check asked for a fresh round approval while the approved round 4 was starting (B4F-121, second time). | 0 | 0 | 1 | Beta5 (B4F-121). |
| 2026-10-16 | Review stage, before round 5. The maintainer's `approved for allowance reset`, typed on its own line below their pasted round-5 rules, was refused by position, and the refusal did not say why. After the bare phrase, the reset was applied but the round needed a second approval, `approved for review round`. The crew had also offered a `!` script as the way to approve. One decision, three messages. | 1 | 2 | 2 | Tier 2, iteration 002, first item (B4F-125; maintainer ruling). The exact messages are in `b4f-125-live-messages.json`. |
| 2026-10-16 | Review stage, after round 5. The crew offered `stop the review here`, and the maintainer typed it; the stop was refused after the final check because a crew commit had moved round 5's snapshot mid-run. Round 6 had to run, against the maintainer's "no round 6" rule. | 1 | 1 | 1 | Beta5 (B4F-126). Crew rule: no commit while a round runs. |
| 2026-10-16 | Review stage, after round 6. The crew offered `stop the review here` again, and the maintainer typed it; the stop was refused because round 6's fixes postdate the round. Sign-off closed through `approved for partial review signoff - <reason>`. | 1 | 1 | 1 | Beta5 (B4F-126, second instance). DRIFT-033. |
| 2026-10-16 | While the two stops ran, the Stop review check told the crew seven times to ask the maintainer for a fresh round approval, for files the running stop already covered. | 0 | 0 | 7 | Beta5 (B4F-121, third instance). |
| 2026-10-16 | The prompt hook answered the typed partial sign-off reply with "reads as a verdict for 'review' ... nothing was recorded"; the engine had captured it. | 0 | 0 | 0 | Beta5 (B4F-116, fourth time; a fifth on the re-typed reply). |
| 2026-10-16 | After the engine's sign-off, the crew committed the records the maintainer had asked for (docs only). The partial sign-off reply was tied to the earlier files, so the review sign-off stage refused to open, and the maintainer had to give the partial sign-off again. | 1 | 1 | 1 | Crew error (DRIFT-035): records belong before the sign-off step, not between it and the stage. |
| 2026-10-16 | A Git for Windows update emptied `C:\Program Files\Git` for about 12 minutes during the sign-off attempt, and the Stop hook failed with ENOENT on `bash.exe`. Hooks that depend on Git Bash have no fallback when it is briefly absent. The re-typed partial sign-off reply, sent in that window, was never recorded, and was typed a third time. | 0 | 1 | 1 | Retro friction (maintainer's line). DRIFT-035. |
| 2026-10-16 | The review sign-off packet was rendered again in full because the Stop counted a reworded discussion question as missing. DRIFT-030's meaning-match covers headings and round 6's covers options, but not question lines. | 0 | 0 | 1 | Iteration 002, beside B4F-125 (B4F-128; maintainer ruling). |
| 2026-10-16 | The maintainer found from the journals that one typed `approved for review round` had been recorded twice, by the prompt hook and again by the turn-end check, leaving an unspent approval for about ten and a half hours that a round could have used. | 0 | 0 | 0 | Critical. Iteration 002, first item (B4F-127, DRIFT-034). Open at 202's close. |

## A round approval is never a boundary verdict (B4F-116)

With the review decision pending (`before-implement -> review-signoff`, the decision at sign-off), the typed round approval `approved for review round` is never captured as a boundary verdict, in six shapes, through the real prompt-time capture. The ledger and the pending decision are unchanged, and a control shows the real phrase is captured in the same setup. Test: `tests/unit/round-phrase-never-boundary-verdict.tests.ps1`, in `f199-class-guards-b`.

## Validator against the known baseline (SC-008)

`validate-governance.ps1 -ProjectPath .` (full repository, unscoped), on 2026-10-15 at `f91fc20d`:

| Run | Iterations validated | Failures | Categories |
| --- | --- | --- | --- |
| 202's baseline ref `2572f020`, clean worktree | 22 | 2 | defer-provenance (001/011), needs-rework (198/011) |
| Current code, clean worktree | 23 | 2 | the same two |
| Current code, this worktree | 23 | 17 | the same two, plus 15 review-evidence |

Every failure is in a known-baseline category, and 202's own iteration passes, so **SC-008 holds**. The 15 review-evidence
failures depend on state, not code. Review-campaign state is git-ignored, so a clean worktree has none. In this worktree,
202's campaign is open, and the validator judges every historical review record against the active campaign. The
baseline names this category ("accepted review records lack a completed valid authoritative campaign result in
historical iterations"). How many records it catches moves with unrelated state, recorded as B4F-124 for beta5.

## Verification lanes before the signoff round

Re-timed cold on 2026-10-15, each lane run exactly as the plan states it, with only its `env_refs` (DRIFT-029). The two f199 lanes that were parked during the checkpoint rounds are back in the plan, split to keep the 2.4x floor:

| Lane | Elapsed | Timeout | Headroom |
| --- | --- | --- | --- |
| `iteration-001-governance-202` | 22.3 s | 180 s | 8.07x |
| `f202-slice-suites-a` | 193.9 s | 600 s | 3.09x |
| `f202-slice-suites-b` | 240.9 s; 180.9 s after case 8 | 600 s | 2.49x on the slower run |
| `f199-class-guards-a` (was 164.6 s, 1.64x, as one lane) | 78.6 s | 270 s | 3.44x |
| `f199-class-guards-b` | 62.1 s; 71.3 s with the B4F-116 suite | 270 s | 3.79x |
| `f199-slice-suites-a` (was 298.8 s, 1.61x, as one lane) | 181.1 s | 480 s | 2.65x |
| `f199-slice-suites-b` | 112.9 s | 480 s | 4.25x |

All seven lanes passed.

## CI

- `cb0f98b2` (lane split): Specrew CI 38622434097, Test 38622434219 and Cross-Platform Validation 38622434114 all succeeded.
- `e81f0dde` (round-3 fixes, T012, T013): Specrew CI 38618352768, Test 38618352825 and Cross-Platform Validation 38618352828 all succeeded. Case (e) logged 4,000 of 4,000 lines on Windows, Ubuntu and macOS.
- `bf94e30a` (round 6's four fixes, DRIFT-032): Specrew CI 38848274478 (Lint, Deterministic gate, Contract lane), Test 38848274583 and Cross-Platform Validation 38848274457 all succeeded.
- `8a8138ab` (round 5's six fixes, DRIFT-032): Specrew CI 38837544705 (Lint, Deterministic gate, Contract lane), Test 38837544630 and Cross-Platform Validation 38837544629 all succeeded. Lint had failed at `0d1b2514` and `ab0dfc9e` on a findings-file list (MD032), which skipped the gate until `8a8138ab`.
- `64c1fcab` (the heading-meaning fix, the B4F-116 test, round 4's five fixes): Specrew CI 38740610813 (Lint, Deterministic gate, Contract lane), Test 38740610669 and Cross-Platform Validation 38740610965 all succeeded. The 3-OS run's Windows review-runtime job failed once, in two process-tree timeout cases nothing in 202 touches, and passed on re-run. Before this, CI's deterministic gate at `d5408782` (38737954286) caught a stop-gate regression lifting only `Write-StopBlockOutput`, fixed in `64c1fcab` (DRIFT-031).
- `6a52497c` (B4F-120/122, the lock budget, T014, T015): Specrew CI 38715877994 (Lint, Deterministic gate, Contract lane), Test 38715878050 and Cross-Platform Validation 38715878027 all succeeded. On Windows, Ubuntu and macOS, `turn-draft-intake` passed, three waits on a held lock took 1,024 to 1,047 ms, and case (e) logged 4,000 of 4,000 lines (the 3-OS checks are from 38714994966 at `62b95304`; the next commit changed one Markdown line). The run at `62b95304` failed only Lint (MD032 in the findings file), which `6a52497c` fixed.

## Records

- Drift: `drift-log.md`, DRIFT-001 to DRIFT-035.
- Findings raised during 202: `docs/beta4-findings.md`, B4F-109 and B4F-111 to B4F-128 (B4F-110 records the host-tier decision).
- Co-review: six rounds found 32 defects (8, 5, 4, 5, 6 and 4), and all 32 were real (B4F-055); the engine demoted 23 of them (8, 4, 4, 0, 4 and 3; first recorded as 24, DRIFT-033). Round 5 (`run-20261016-002823641-f5fc77f3`, after the maintainer's allowance reset) reviewed round 4's fixes, but its result moved mid-run because of a crew commit, so it could not carry a sign-off (B4F-126). Round 6 (`run-20261016-031317319-8c4537dd`) reviewed the current tree, including round 5's fixes. All 32 are fixed behind failing tests. **Round 6's four fixes (DRIFT-032) go to sign-off without a further review round, by the maintainer's rule set before round 5 and accepted by them in advance.** The stop after round 6 was refused because those fixes postdate the round, and sign-off closed through the maintainer's typed `approved for partial review signoff - <reason>` (DRIFT-033).
- Known open defect at sign-off: one typed approval can be recorded twice, once when the message arrives and again by the turn-end check, leaving a spare approval the maintainer never gave (B4F-127, critical, predates 202; iteration 002, first item; DRIFT-034).
