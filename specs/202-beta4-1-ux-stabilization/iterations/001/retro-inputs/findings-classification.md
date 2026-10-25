# Feature 202, iteration 001: the 32 co-review findings, classified (retro input)

Read-only research. Sources: `specs/202-beta4-1-ux-stabilization/iterations/001/drift-log.md` (DRIFT-014 round 1, DRIFT-015 round 2, DRIFT-024 round 3, DRIFT-031 round 4, DRIFT-032 rounds 5 and 6); `docs/beta4-findings.md` B4F-055; each round's `result.json` under `.specrew/review/authority/campaigns/cmp-202-beta4-1-ux-stabilization-i001/runs/`; `git log` / `git show` / `git blame` (blame run on the parent of each fix commit, over the lines that fix changed).

All 32 findings were located. None is missing.

| Round | Run | Findings | Fix commit(s) |
| --- | --- | --- | --- |
| 1 | run-20261013-234651770-ac649a7e (on c26b1d42) | 8 | 34af7076 |
| 2 | run-20261014-102731596-597f9ec9 | 5 | 0b62bf9b (same commit as T006) |
| 3 | run-20261014-173122349-f5d4f978 | 4 | 1dd20060, e206d1b7, d0d41902, fdf9972f (one per finding) |
| 4 | run-20261015-110313119-da115ef4 | 5 | 61714dbd |
| 5 | run-20261016-002823641-f5fc77f3 | 6 | 5c56dbed |
| 6 | run-20261016-031317319-8c4537dd | 4 | 0e6a8a01 |

## One correction to the stated figures: 23 were demoted, not 24

The result files show **23** demoted findings: 8, 4, 4, 0, 4, 3. Round 2's finding 5 ("Unknown origin is disclosed as proof that the host supplied the reply") has `demoted: false` and was reported `minor` by the reviewer itself. DRIFT-015 says "the engine demoted all 5", and B4F-055 carries that forward ("all 13" for rounds 1 and 2, "24 of 32" overall). Both are off by one. The other five rounds match the records.

## Classes

- **A**: a case the test author did not think of (input shape or edge case).
- **B**: state shared across sessions or turns (persisted stores, journals, per-session records, ordering, staleness, identity, concurrent writers).
- **C**: a withheld or partial delivery (hook output withheld, a partial or failed write, a torn or incomplete record line).
- **D**: something else, named.

Each finding gets exactly one class. Where two classes fit, the class is the condition the test would have had to build to show the defect.

## 1. All 32 findings

| ID | Plain description | File / area | Demoted | Fix | Class | Evidence for the class |
| --- | --- | --- | --- | --- | --- | --- |
| R1-1 | The new "who typed this" origin reached the handover provider and was dropped there, so a Copilot "User skipped question" still produced a workshop receipt | handover provider, `workshop-authority-store.ps1` | yes | 34af7076 | D: wiring. A new value never reached its real consumer | The reviewer: "the current contract test uses probe providers and checks argument delivery without checking this behavior". |
| R1-2 | The buffer flush ignored read errors and deleted every buffer file, including unread ones and ones another writer was still adding to | `specrew-hook-dispatcher.ps1` (outage buffer flush) | yes | 34af7076 | B | Data was lost only when another dispatcher process appended to its buffer between this one's read and its delete. |
| R1-3 | One malformed journal line threw, so that turn went silent and every later reply was refused, because the line stays | `workshop-authority-store.ps1` (hook-output check) | yes | 34af7076 | C | The trigger is "a torn or truncated integrity record" in the journal. |
| R1-4 | Recovery approval read "okay, do not clear it" as yes | `workshop-authority-store.ps1` (recovery approval) | yes | 34af7076 | A | The test did not cover a reply wording that starts with yes and then declines. |
| R1-5 | A recovery question outlived its outage, so a later unrelated "yes" could set the journal aside | `workshop-authority-store.ps1` (recovery request file) | yes | 34af7076 | B | The request file persisted after automatic recovery and was matched on a later turn. |
| R1-6 | Recovery acted before recording the approval, and still said "your approval was recorded" when that write failed | `workshop-authority-store.ps1` (recovery action) | yes | 34af7076 | C | The defect shows only when the approval write fails after the action has happened. |
| R1-7 | A degraded state was not disclosed in the turn the human typed into | dispatcher output writers, T004 disclosure helpers | yes | 34af7076 | C | The degradation starts at the dispatcher's final append, after the providers composed the turn's text. |
| R1-8 | On Linux and macOS the journal append was not atomic: CI lost 58 of 2,000 lines on Linux | `specrew-hook-dispatcher.ps1` (non-Windows append) | yes | 34af7076 | B | Concurrent writers to one shared journal chose the same offset. |
| R2-1 | The dispatcher's own origin check still refused every reply after one malformed line | `specrew-hook-dispatcher.ps1` (journal check) | yes | 0b62bf9b | C | The trigger is a malformed line, and the reviewer notes that "case 10 misses it by invoking the provider with an explicitly supplied typed-user origin". |
| R2-2 | A flush could remove a buffer file that a Unix writer still held open, so a hash was lost while the output was still shown | `specrew-hook-dispatcher.ps1` (flush) | yes | 0b62bf9b | B | A two-process interleaving on a shared file, which "the existing case (h) … do[es] not exercise". |
| R2-3 | Recovery was recorded while a kept buffer was still unreadable, which hid the disclosure and closed the recovery question | `specrew-hook-dispatcher.ps1` (recovery record) | yes | 0b62bf9b | B | The persisted episode state was closed while other persisted state, the kept buffer, still said degraded. |
| R2-4 | Another session's "yes" could approve a recovery that only one session was asked about | `workshop-authority-store.ps1` (recovery request) | yes | 0b62bf9b | B | The request was project-wide, with no session identity. |
| R2-5 | An unreadable record check was disclosed as "added by the assistant's host" | `workshop-authority-store.ps1` (refusal cause) | **no** (reported minor) | 0b62bf9b | A | The "unknown" origin value was treated like host-injected, and "case 3 currently bypasses the normalizer". |
| R3-1 | A question that quoted the approval phrase read as a missed approval, so the packet was repainted | `turn-end-store.ps1` (approval-phrase check) | yes | e206d1b7 | A | The reviewer's input: "What does 'approved for before-implement' mean?". |
| R3-2 | Markdown review links passed the packet check but were invisible to the reply check and to the reviewed-file memory | `turn-end-store.ps1` (three link parsers) | yes | d0d41902 | A | The tests used `file:///` links only, and the validator also accepted `[spec](C:\...)`. |
| R3-3 | A journal line that was valid JSON but not a record (`{}`) threw, and refused every later workshop reply | `workshop-authority-store.ps1`, dispatcher health reader, outcome reader | yes | 1dd20060 | C | The trigger is an incomplete record line that passes the JSON parse. |
| R3-4 | A degraded state that began at the dispatcher's final append went undisclosed, and was fully silent when buffering also failed | `specrew-hook-dispatcher.ps1` (final append) | yes | fdf9972f | C | The reviewer: "the existing disclosure tests preseed an already-degraded health record and miss this ordering". |
| R4-1 | `specrew start` resumed a different feature than status and orientation showed after a branch switch | `scripts/specrew-start.ps1` | no | 61714dbd | B | The feature pointer file was stale relative to the branch, and the feature-resolver tests "checked only status and orientation". |
| R4-2 | Resume progress always read iteration 1's root `tasks.md`, so a later iteration was told a stale task was "starting now" | `HandoverStore.ps1` (T012 resume) | no | 61714dbd | B | It read the wrong persisted progress record, and the fixtures "had assumed the root list for iteration 003, which is the defect itself". |
| R4-3 | The Stop-block path did not get round 3's disclosure, and a Stop block that could not be recorded emitted `{}` with no word | `specrew-hook-dispatcher.ps1` (Stop-block output) | no | 61714dbd | C | Withheld or degraded delivery on the second output path. |
| R4-4 | The orientation was stamped as supplied before delivery, so one withheld turn suppressed it for the rest of the session | `specrew-bootstrap-provider.ps1` (T008) | no | 61714dbd | C | The stamp survived a fire whose output was withheld. |
| R4-5 | A recovery question asked in a session that then ended could be answered by no one | `workshop-authority-store.ps1` (recovery request) | no | 61714dbd | B | A per-session record outlived its session. |
| R5-1 | Two features at the same boundary and tree shared one boundary-step identity, so a reply to A's packet could be recorded for B | `shared-governance.ps1` (pending boundary-step identity) | yes | 5c56dbed | B | Identity: the hash left out the feature. |
| R5-2 | A conditional "yes, after I finish the other session" approved the recovery | `workshop-authority-store.ps1` (recovery approval) | yes | 5c56dbed | A | The test did not cover a reply wording with a condition attached. |
| R5-3 | A declined recovery question stayed open, so a later unrelated "yes" approved it, and the "no" was taken as a workshop answer | `workshop-authority-store.ps1`, `HandoverStore.ps1` | yes | 5c56dbed | B | A persisted request stayed armed across later turns. |
| R5-4 | A recovery question recorded during a withheld fire survived, so a later "yes" approved a question never shown | `specrew-hook-dispatcher.ps1`, `workshop-authority-store.ps1` | yes | 5c56dbed | C | The state was written before a delivery that was then withheld. |
| R5-5 | The recording disclosure could report another session's outcome ("your reply was used") | `workshop-authority-store.ps1` (outcome lookup), dispatcher | no (reported minor) | 5c56dbed | B | The lookup filtered on time only, over a journal every session shares. |
| R5-6 | An approval phrase inside a fenced or indented code example read as a missed approval | `turn-end-store.ps1` (approval-phrase check) | no (reported minor) | 5c56dbed | A | The input shape: the phrase inside a code block. |
| R6-1 | A health line with a state but no class or first-seen time threw after every good append, so the dispatcher dropped its output until the file was hand-fixed | `specrew-hook-dispatcher.ps1` (health/recovery reader) | yes | 0e6a8a01 | C | An incomplete record line. Round 3's guard checked only `state`. |
| R6-2 | Verdict options written as bullets or inline code were not meaning lines, so a reply could drop "changes needed" and pass | `turn-end-store.ps1` (meaning lines) | yes | 0e6a8a01 | A | The input shape: Markdown wrapping. |
| R6-3 | A review link with parentheses in its path ("app (draft)") was cut at the first ')' | `turn-end-store.ps1` (link parser) | yes | 0e6a8a01 | A | The input shape: a path with parentheses. |
| R6-4 | Two links differing only by case were merged, so the second file's changes were invisible on Linux | `turn-end-store.ps1` (reviewed-file memory) | no (reported minor) | 0e6a8a01 | A | The input shape: two paths that differ only by case. |

Demoted per round, from the result files: 8, 4, 4, 0, 4, 3, which is **23**.

### Why the tests did not fail: the reviewer named the gap 8 times

For 8 of the 32 findings, the reviewer or the drift entry says why the existing test passed. In every case the test either went around the real path or contained the same assumption as the code:

- R1-1: probe providers.
- R1-8: the platform test was still pending.
- R2-1: the test supplied the origin itself.
- R2-2: the case did not exercise the interleaving.
- R2-5: the test bypassed the normalizer.
- R3-4: the test preseeded the degraded state.
- R4-1: the test checked only two of the three consumers.
- R4-2: the fixture contained the defect.

A test written to fail first proves the fix for the case its author pictured. It cannot catch a case the author never pictured, or a path the test goes around.

## 2. Where each defect came from

Two terms are used in the "Fix-related" column:

- **Introduced**: the defective lines were written by an earlier round's fix, or that fix created the state that exposed them.
- **Incomplete**: an earlier fix repaired one path or one reader and left a sibling, or the same function, with the same class of defect.

Commit attribution comes from `git blame` on each fix commit's parent, plus the drift entries' own carry-in notes.

| ID | Defective code: new in 202 or pre-202 (introducing commit) | Fix-related |
| --- | --- | --- |
| R1-1 | 202, T002 `7bb8028f` (the new origin argument). It never reached pre-202 consumers: handover provider `a3e6d0a8`/`a41c4f2c`, receipt writer `5bb77132` | no (first round) |
| R1-2 | 202, T003 `aa2ffb7b` | no |
| R1-3 | 202, T003 `aa2ffb7b` | no |
| R1-4 | 202, T004 `0edfb321` | no |
| R1-5 | 202, T004 `0edfb321` | no |
| R1-6 | 202, T004 `0edfb321` | no |
| R1-7 | 202, T003 `aa2ffb7b` + T004 `0edfb321`, over pre-202 output writers (`d22125eb`, `79d98d52`) | no |
| R1-8 | 202, T003 `aa2ffb7b` | no |
| R2-1 | 202, T003 `aa2ffb7b` / T002 `7bb8028f` | **incomplete**: round 1's fix 3 repaired the store's reader, not the dispatcher's |
| R2-2 | 202, round-1 fix `34af7076` (the rename-then-read flush; blame: lines 263-268) | **introduced** (round 1) |
| R2-3 | 202, T003 `aa2ffb7b` recovery rule + round-1 fix `34af7076` (which began keeping unreadable buffers) | **introduced** (round 1 created the state) |
| R2-4 | 202, T004 `0edfb321`. Round 1's fix 5 rebound the request to the outage but not to a session | **incomplete** (round 1) |
| R2-5 | 202, round-1 fix `34af7076` (the new "not typed by human" refusal treated unknown as host) | **introduced** (round 1) |
| R3-1 | 202, T006 `0b62bf9b` | no |
| R3-2 | 202, T006 `0b62bf9b` / T007 `8904b71f` readers, out of step with the pre-202 validator `97e03c80` | no |
| R3-3 | 202, T003 `aa2ffb7b` / T004 `0edfb321` field reads. Round 1's parse guard caught bad JSON only | **incomplete** (round 1) |
| R3-4 | 202, T003/T004. Round 1's fix 7 covered only turns already degraded | **incomplete** (round 1) |
| R4-1 | **pre-202**, `scripts/specrew-start.ps1` `3816929c` (2026-05). T010 did not route it through the new resolver | no |
| R4-2 | 202, T012 `488468fe` | no |
| R4-3 | pre-202 Stop-block writer (`79d98d52`, `12e49c04`) + 202 journal. Round 3's fix 4 (`fdf9972f`) covered the injection path only | **incomplete** (round 3) |
| R4-4 | 202, T008 `aac6a3fa` | no |
| R4-5 | 202, round-2 fix `0b62bf9b` (`asked_session` binding), with round 1's per-outage suppression | **introduced** (round 2) |
| R5-1 | **pre-202** identity tuple `4e38c55d` (2026-07) + T011's feature field `f46c9fb1` | no |
| R5-2 | 202, round-1 fix `34af7076` (the approval check's refusal list; the conditional was missed) | **incomplete** (round 1) |
| R5-3 | 202, T004 `0edfb321` + `34af7076`. Round 4's re-ask (`61714dbd`) left the same-session request armed indefinitely | **worsened** by round 4 |
| R5-4 | 202, T004 `0edfb321`. Round 4's rollback (`61714dbd`) covered only the orientation stamp, and its re-ask branch added a second write before delivery | **incomplete** (round 4) |
| R5-5 | 202, round-3 fix `fdf9972f` (the outcome lookup). Round 4 `61714dbd` added its callers | **introduced** (round 3, widened by round 4) |
| R5-6 | 202, T006 `0b62bf9b`. Round 3's fix 1 (`e206d1b7`) rewrote the line scan without fences | **incomplete** (round 3) |
| R6-1 | 202, T003 `aa2ffb7b`. Round 3's shape guard (`1dd20060`) checked only `state` | **incomplete** (round 3) |
| R6-2 | 202, T007 `8904b71f` | no |
| R6-3 | 202. The file-URL form dates from T006 `0b62bf9b`. The Markdown-target regex was written by round-3 fix `d0d41902`, which copied the pre-202 validator's stop-at-')' | **introduced** (round 3, Markdown form) |
| R6-4 | 202, T006 `0b62bf9b` | no |

Code origin: 30 of 32 sit in code written during 202, by a task or a fix. Two sit mainly in pre-202 code, R4-1 and R5-1, and each became reachable because a 202 task changed what that code had to handle (T010's resolver, T011's per-feature records).

## 3. Totals

**Per class**: A = 9, B = 12, C = 10, D = 1. B and C together are 22 of 32.

| Round | A | B | C | D | Total | Introduced by a fix | Incomplete fix | Worsened by a fix | Fix-related total |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | 1 | 3 | 3 | 1 | 8 | 0 | 0 | 0 | 0 of 8 |
| 2 | 1 | 3 | 1 | 0 | 5 | 3 | 2 | 0 | 5 of 5 |
| 3 | 2 | 0 | 2 | 0 | 4 | 0 | 2 | 0 | 2 of 4 |
| 4 | 0 | 3 | 2 | 0 | 5 | 1 | 1 | 0 | 2 of 5 |
| 5 | 2 | 3 | 1 | 0 | 6 | 1 | 3 | 1 | 5 of 6 |
| 6 | 3 | 0 | 1 | 0 | 4 | 1 | 1 | 0 | 2 of 4 |
| **All** | **9** | **12** | **10** | **1** | **32** | **6** | **9** | **1** | **16 of 32** |

**By area**:

- The outage and recovery machinery (T003/T004, the hook-output journal, the buffer, the recovery question, and their fixes) holds **22 of 32**: all 8 of round 1, all 5 of round 2, R3-3, R3-4, R4-3, R4-5, R5-2 to R5-5, and R6-1. All 16 fix-related findings except R5-6 and R6-3 are in this area.
- Reply parsing in `turn-end-store.ps1` (T006/T007) holds 6: R3-1, R3-2, R5-6, R6-2, R6-3, R6-4.
- The other 4 are R4-1, R4-2, R4-4 and R5-1.

**Did round 6 touch round 5's fixes?** No, and the claim holds. `git blame` of every line that round-6 fix `0e6a8a01` changed, taken on its parent, attributes them to `aa2ffb7b` (T003), `0b62bf9b` (T006), `8904b71f` (T007) and `d0d41902` (round 3). None of them comes from `5c56dbed` (round 5). Round 6's findings are in functions round 5 did not change: the health reader, the meaning lines, the link parser and the reviewed-file set. Round 5 changed the approval-phrase scan, the recovery approval, the outcome lookup and the boundary-step identity. Round 6 is the one round after round 1 whose findings came from round 3 and from first-pass task code, not from the round just before it.

## 4. Too large for the allowance, or a loop that keeps adding defects?

The evidence supports both, split roughly in half, and it points at a third cause underneath them.

**The case for size.** 16 of 32 findings are in first-pass task code: round 1's 8, then R3-1, R3-2, R4-1, R4-2, R4-4, R5-1, R6-2 and R6-4. A 25.5 SP iteration reviewed in checkpoints keeps putting new task code in front of the reviewer through round 4. R6-2 and R6-4 show that even code round 3 had already read still had first-pass defects in round 6.

**The case for the loop.** The other 16 are fix-related: 6 introduced by a fix, 9 incomplete fixes, and 1 worsened. They did not fade (5, 2, 2, 5, 2 per round from round 2 on), and 14 of the 16 are in one area, the outage and recovery machinery. In that area each fix added a state the tests did not model:

- keeping unreadable buffers (round 1) led to an outage closed too early (R2-3);
- binding the question to a session (round 2) led to a question no live session could answer (R4-5);
- the re-ask (round 4) led to a question that stayed armed (R5-3);
- the outcome lookup (round 3) led to another session's outcome being reported (R5-5).

**The underlying cause.** 22 of 32 findings are class B or C: state shared across sessions and turns, or a withheld or partial delivery. Each fix's failing-first test pictured one turn, one session and one successful delivery. In the 8 cases where the gap is named, the test went around the real path (a supplied origin, a preseeded degraded state, probe providers) or encoded the same assumption as the code.

**What the round-6 evidence adds.** In rounds 5 and 6, 9 of 10 findings are older than the code each round was scoped to: five of six in round 5, all four in round 6. Each round also returned a similar number of findings (4 to 8). That fits a reviewer that samples a large surface a few findings at a time more than it fits a loop that grows defects. So the flat count is weak evidence for either explanation on its own.

The stronger reading:

- The iteration was too large for four rounds.
- One subsystem with a large state space (concurrent writers, per-session records that persist, withheld delivery) was fixed one instance at a time. Its fixes kept adding new states that no test modelled.
