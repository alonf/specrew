# Feature 202, iteration 001: the 32 co-review findings, graded by consequence (retro input)

Read-only analysis. Sources: `specs/202-beta4-1-ux-stabilization/iterations/001/retro-inputs/findings-classification.md` (IDs, descriptions, test-miss class, demoted flag) and `iterations/001/drift-log.md` entries DRIFT-014 (round 1), DRIFT-015 (round 2), DRIFT-024 (round 3), DRIFT-031 (round 4) and DRIFT-032 (rounds 5 and 6) for each failure scenario.

The maintainer's scale:

- **critical**: a false authorization, data loss, or writes outside the project;
- **major**: recoverable, but it blocks or misleads the human or the agent;
- **minor**: everything else.

Each finding is graded by the worst outcome its drift entry states, not by how likely it is and not by the engine's major/minor label. Where likelihood is low, that is noted in section 5.

How the critical grades were applied:

- **False authorization** covers a recorded human decision the human did not give: a host-injected text recorded as a typed workshop answer, a decline or a conditional reply taken as yes, a stale or never-shown question approved by a later unrelated "yes", another session's "yes", and one feature's reply recorded for another feature.
- **Data loss** covers journal lines or buffered records that were deleted or never written. These are governance records, not the human's project files (see section 5).
- No finding wrote outside the project. That kind of defect in this iteration (B4F-120/122, DRIFT-027) came from the design work, not from a co-review finding.

## 1. All 32 findings

| ID | One-line description | Grade | Evidence | Test-miss class | Engine demoted |
| --- | --- | --- | --- | --- | --- |
| R1-1 | A Copilot "User skipped question" still produced a workshop receipt, because the new origin value stopped at the handover provider | **critical** | DRIFT-014 #1: a host-injected dismissed-question prompt "still produced a receipt", against FR-006 "only typed-user can produce a receipt", so a non-answer was recorded as the human's answer. | D (wiring) | yes |
| R1-2 | The buffer flush ignored read errors and deleted every buffer file, read or not | **critical** | DRIFT-014 #2: the flush "deleted every listed file", and the failing test showed a buffer that was unreadable but deletable "lost its hash". | B | yes |
| R1-3 | One malformed journal line threw, silenced that turn and refused every later reply | major | DRIFT-014 #3: the turn "went silent" and, because the line stays, "it also refused every later reply", a lasting block that a fix to the line clears. | C | yes |
| R1-4 | Recovery approval read "okay, do not clear it" as yes | **critical** | DRIFT-014 #4: a decline was read as approval, so the journal could be set aside on a "no". | A | yes |
| R1-5 | A recovery question outlived its outage, so a later unrelated "yes" could set the journal aside | **critical** | DRIFT-014 #5: the question survived automatic recovery, "so a later unrelated 'yes' could move the record". | B | yes |
| R1-6 | Recovery acted before recording the approval and still said "your approval was recorded" when that write failed | major | DRIFT-014 #6: the human did approve, but the action ran without its record and the turn told them it was recorded, which misleads (see section 5). | C | yes |
| R1-7 | A degraded state was not disclosed in the turn the human typed into | major | DRIFT-014 #7: the affected turn did not say the system was degraded or whether the reply was used (FR-007), so the human was misled about their reply. | C | yes |
| R1-8 | On Linux and macOS the journal append was not atomic | **critical** | DRIFT-014 #8: the 3-OS CI run measured Linux losing 58 of 2,000 lines and tearing 1, and macOS losing 32. | B | yes |
| R2-1 | The dispatcher's own origin check still refused every reply after one malformed line | major | DRIFT-015 #1: every later typed prompt got origin `unknown` "and the receipt writer refused it", a lasting block. | C | yes |
| R2-2 | A flush could remove a buffer file a Unix writer still held open, losing a hash while the output was still shown | **critical** | DRIFT-015 #2: "a hash written after the flush removed the file was lost while the output was still shown". | B | yes |
| R2-3 | Recovery was recorded while a kept buffer was still unreadable | major | DRIFT-015 #3: it "hid the degraded disclosure and closed the recovery question, while prompts were still being refused", so the human was blocked and told nothing. | B | yes |
| R2-4 | Another session's "yes" could approve a recovery only one session was asked about | **critical** | DRIFT-015 #4: "a session that was never asked could have its answer consumed as the approval". | B | yes |
| R2-5 | An unreadable record check was disclosed as "added by the assistant's host" | major | DRIFT-015 #5: the store told the human their typed reply "was added by the assistant's host", a false cause shown to the human. | A | no (reported minor) |
| R3-1 | A question that quoted the approval phrase read as a missed approval, so the packet was repainted | major | DRIFT-024 #1: a question or a refusal left the boundary pending and Stop "repainted the packet and told the agent to say the approval had not registered". | A | yes |
| R3-2 | Markdown review links passed the packet check but were invisible to the reply check and the reviewed-file memory | major | DRIFT-024 #2: "such a link could be dropped from the reply unnoticed, and a change to its file never lifted suppression", so the human was not shown a changed file. | A | yes |
| R3-3 | A journal line that was valid JSON but not a record (`{}`) threw and refused every later workshop reply | major | DRIFT-024 #3: "every later workshop reply failed", and in the health reader "every later append withh[eld] its output". | C | yes |
| R3-4 | A degraded state that began at the dispatcher's final append went undisclosed, and fully silent when buffering also failed | major | DRIFT-024 #4: "the payload went out unchanged and only stderr knew", and when buffering failed "the turn said nothing". | C | yes |
| R4-1 | `specrew start` resumed a different feature than status and orientation showed | major | DRIFT-031 #1: after a branch switch "the resume block described the pointer's feature", not the one status and orientation showed. | B | no |
| R4-2 | Resume progress always read iteration 1's task list, so a later iteration was told a stale task was "starting now" | major | DRIFT-031 #2: "for a later iteration it named a stale task as 'starting now'"; feature 197 would have named T091 from 56 stale boxes. | B | no |
| R4-3 | The Stop-block path lacked round 3's disclosure, and an unrecordable stop block emitted `{}` with no word | major | DRIFT-031 #3: a degraded state "went out undisclosed", and the `{}` output allowed "the stop with no word". | C | no |
| R4-4 | The orientation was stamped as supplied before delivery, so one withheld turn suppressed it for the session | major | DRIFT-031 #4: "every later prompt skipped the orientation and its dials fallback", so the human never saw it. | C | no |
| R4-5 | A recovery question asked in a session that then ended could be answered by no one | major | DRIFT-031 #5: "only the asked session's yes counts, and the open question kept every other session from being asked". | B | no |
| R5-1 | Two features at the same boundary and tree shared one boundary-step identity | **critical** | DRIFT-032 #1: "a reply to A's [packet] could be recorded as B's authorization (FR-026)". | B | yes |
| R5-2 | A conditional "yes, after I finish the other session" approved the recovery | **critical** | DRIFT-032 #2: conditional replies "returned approval, and the record was set aside before the condition held". | A | yes |
| R5-3 | A declined recovery question stayed open, so a later unrelated "yes" approved it and the "no" was taken as a workshop answer | **critical** | DRIFT-032 #3: "a later unrelated 'yes' approved the recovery (confirmed by probe)", and the "no" was recorded as a workshop answer. | B | yes |
| R5-4 | A recovery question recorded during a withheld fire survived, so a later "yes" approved a question never shown | **critical** | DRIFT-032 #4: the question was recorded as open before the payload that asked it, and the withheld payload left it standing for a later "yes". | C | yes |
| R5-5 | The recording disclosure could report another session's outcome | major | DRIFT-032 #5: "session A could be told 'your reply was used as your workshop answer' from session B's row". | B | no (reported minor) |
| R5-6 | An approval phrase inside a fenced or indented code example read as a missed approval | major | DRIFT-032 #6: it "made the next Stop say the approval did not register and repaint" (FR-011), the same outcome as R3-1. | A | no (reported minor) |
| R6-1 | A health line with a state but no class or first-seen time made the dispatcher drop its output until the file was fixed by hand | major | DRIFT-032 round 6 #1: the dispatcher failed open, "dropping that fire's output (a Stop's packet included), until the file was fixed by hand". | C | yes |
| R6-2 | Verdict options written as bullets or inline code were not checked, so a reply could drop "changes needed" and pass | major | DRIFT-032 round 6 #2: "a reply that dropped `changes needed` and `discuss prompt` passed the Stop", so the human could be shown fewer choices than they have. | A | yes |
| R6-3 | A review link with parentheses in its path was cut at the first ')' | major | DRIFT-032 round 6 #3: "app (draft)" was fingerprinted as a missing folder, "so an edit to the real file never lifted suppression". | A | yes |
| R6-4 | Two links differing only by case were merged, hiding the second file's changes on Linux | major | DRIFT-032 round 6 #4: "on a case-sensitive filesystem the second file's changes were invisible" (the entry adds "low likelihood"). | A | no (reported minor) |

## 2. Counts per grade per round

| Round | Critical | Major | Minor | Total |
| --- | --- | --- | --- | --- |
| 1 | 5 | 3 | 0 | 8 |
| 2 | 2 | 3 | 0 | 5 |
| 3 | 0 | 4 | 0 | 4 |
| 4 | 0 | 5 | 0 | 5 |
| 5 | 4 | 2 | 0 | 6 |
| 6 | 0 | 4 | 0 | 4 |
| **All** | **11** | **21** | **0** | **32** |

The 11 critical findings fall into two groups:

- **False authorization (8)**: R1-1, R1-4, R1-5, R2-4, R5-1, R5-2, R5-3, R5-4. Seven of these are in the recovery-question machinery; R1-1 is the workshop receipt and R5-1 is the boundary-step identity.
- **Data loss (3)**: R1-2, R1-8, R2-2. All three lose hook-output journal records or buffered records.

Critical findings came in rounds 1, 2 and 5. Rounds 3, 4 and 6 found only major ones.

## 3. Share of findings that mattered

Critical plus major: **32 of 32 (100%)**. By the record, no finding was cosmetic. Each one either produced a false authorization or lost data, or it blocked or misled the human or the agent.

If the low-likelihood or borderline findings in section 5 are moved down one grade (R2-5, R6-2, R6-4 to minor), the share is 29 of 32 (91%). It is not lower than that under any reading of the record.

## 4. Critical or major findings the engine demoted

**23 of the 23 demoted findings are critical or major.** The engine did not demote a single finding that grades minor.

- **All 11 critical findings were demoted**: R1-1, R1-2, R1-4, R1-5, R1-8, R2-2, R2-4, R5-1, R5-2, R5-3, R5-4. Every critical finding this review found reached the human labelled minor.
- **12 of the 21 major findings were demoted**: R1-3, R1-6, R1-7, R2-1, R2-3, R3-1 to R3-4, R6-1 to R6-3.
- The other 9 were not demoted:
  - the 5 round-4 findings, reported major and kept major;
  - 4 the reviewer itself reported minor (R2-5, R5-5, R5-6, R6-4), which grade major here.

So 27 of the 32 findings carried a final minor label (23 demoted plus 4 reported minor), and every one of the 27 grades major or critical by consequence. Only the 5 round-4 findings reached the human with a label that matched their consequence. Round 5's summary, "Nothing found that needs your attention", covered 4 critical findings.

## 5. Findings not graded with full confidence

- **R1-2, R1-8, R2-2 (critical, data loss)**: the lost data is journal lines and buffered output records, not the human's project files. The record says they were lost but does not say what follows downstream. They are graded critical under the plain words "data loss". If the maintainer meant the loss of the human's work only, these three become **major**: the critical count drops to 8 and the major count rises to 24.
- **R1-6 (major)**: the human really did say yes, so this is not an authorization they did not give. But the action ran with no recorded approval (FR-009), and the turn claimed it was recorded. If "an action without a recorded authorization" counts as a false authorization, this one is **critical**.
- **R5-1 and R5-4 (critical)**: both are critical on consequence, but each needs a narrow setup. R5-1 needs feature B's stage evidence already in the same committed tree. R5-4 needs two failures, though the entry notes the question is asked only when recording is already degraded. The grade stands on consequence. Their likelihood is low.
- **R4-3 (major)**: an unrecordable stop block let the stop through with no word. The record does not say which check the block was enforcing. If it was a boundary approval check, the outcome is closer to an unchecked boundary than to a misleading message. Major is the floor.
- **R6-1 (major)**: the consequence is a block until a hand fix, but the entry says "only a hand edit or another schema version writes such a line". Likelihood is very low, and the grade is on consequence.
- **R6-4 (major, could be minor)**: the consequence matches R3-2 and R6-3 (a changed file not shown to the human), but it needs a case-sensitive filesystem and two paths that differ only by case. The entry says "low likelihood". It is **minor** if likelihood is weighed.
- **R2-5 (major, could be minor)**: the refusal itself was correct, and only the stated cause was wrong. It tells the human their typed reply came from the host, which misleads them about their own input. That is why it grades major. Under a narrower reading of "misleads", it is minor.
- **R6-2 (major, could be minor)**: a packet that drops "changes needed" passes the check. Whether a human actually misses an option they were not shown depends on the human. The grade assumes a human who takes the shown options as the full set.
