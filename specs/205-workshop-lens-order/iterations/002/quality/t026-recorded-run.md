# T026: Recorded Light workshop run (SC-012)

**Run**: 2026-11-14, 19:35 to 20:06 local, host session `specrew-205-t026-4a` (Claude Code, Specrew 0.40.0-beta41)
**Feature in the scratch project**: `001-nightly-appointment-export`
**Transcript**: [t026-transcript.md](t026-transcript.md) (visible turns)
**Workshop records**: [t026-records/](t026-records/) (the Markdown records, copied from the scratch project; the temp-folder prefix is written
as `%TEMP%`)

## Who answered

The replies were sent by the reviewer session `specrewreviewer-98`. Before each one went, the maintainer confirmed it:
the reviewer wrote its proposed reply and a short reason in its own session, and the maintainer said "send" or asked
for a change (the maintainer's decision of 2026-11-13 21:36, DRIFT-011). These are not the maintainer's typed turns in
the workshop session. The maintainer typed one turn there themselves: the 19:38 correction of the reviewer session's
name, which was not a workshop answer.

| Time | Workshop step | Reply sent after the maintainer's go-ahead | Hook receipt |
| --- | --- | --- | --- |
| 19:39 | product-domain | "Lets continue the workshop" (taken as send) | `5c94fb16`, lens-question |
| 19:45 | agenda | "OK, send it" | `78b77650`, lens-selection |
| 19:48 | requirements-nfr | "Ok to answer and move on" | `ee3ab3ba`, lens-question |
| 20:04 | security-compliance | "205: OK, send it" | `e046cf6e`, lens-question |

Times are when the workshop session received each reply; the go-ahead words are as the reviewer reported them. The
hook recorded all four as `human-confirmed` typed replies from `UserPromptSubmit`. On this engine the workshop hook
takes a relayed message as a typed reply (feature 203's B5F-064); this file is the true record of who answered. The
19:38 correction got no receipt, and the session did not take it as an answer.

## What SC-012 asks, and what the run shows

- **A lens shows its recommendations as one list, closed by one reply.** Yes, in all three lenses. product-domain
  showed its five areas (data residency, systems carried over, where it runs, who operates it, budget) as one block;
  requirements-nfr showed four lines and security-compliance four, each including the lines handed forward. Each list
  was shown once, never line by line, and each lens closed on one reply.
- **"accept" closes it.** Yes, in the sense the run could test. Each lens's one reply answered its numbered questions
  and accepted the list ("accept, with two changes"; "accept"; "accept, with one change"); the lens then closed and
  the next one opened. The run does not show a bare "accept" closing a lens on its own, because every lens in the pass
  also had must-answer questions.
- **product-domain asks the compliance question at Light.** Yes: question 5, "Which regulation or compliance regime
  applies ... by name, or "none"? I do not assume one and there is no default here." The answer (GDPR/DSGVO, BDSG,
  Article 9 health data, section 203 StGB) was handed forward into requirements-nfr and security-compliance, each line
  naming product-domain as its source, and was not asked again. Data residency, changed in product-domain's block to
  "the clinic's own network in Germany", was handed forward into security-compliance, and then into data-storage.

## Counts against the budget

The budget is the length test's Light figures for the lenses this pass covered.

| Lens | Must-answer: budget / shown | Typed replies: budget / sent | Recommendation lines: budget / shown |
| --- | --- | --- | --- |
| product-domain | 9 / 5 questions | 1 / 1 | 5 / 5 |
| agenda | 0 / 0 | 1 / 1 | 0 / 0 |
| requirements-nfr | 6 / 6 | 2 / 1 | 4 / 4 |
| security-compliance | 6 / 6 | 2 / 1 | 4 / 4 |
| **This pass** | **21 / 17** | **6 / 4** | **13 / 13** |

- **Must-answer**: product-domain's 5 questions cover the areas its own Light depth model names (users and
  stakeholders, pain and job, MVP and out of scope, key constraints, and the compliance regime), and ask for the depth
  to be confirmed. The length test counts all eight original areas as must-answer at every depth, so its 9 is an upper
  bound; outcomes were recorded as the session's labelled assumption, and alternatives and rollout are not asked at
  Light.
- **Typed replies**: each technical lens closed on one reply, not the two the budget allows, because the reply
  answered the questions, accepted the list and said "move on" at once. The maintainer's one correction turn is not
  counted.
- **Recommendation lines**: exactly as budgeted.

## What the run proves, and what it does not

It proves that, on the shipped lens files and skill, a lens shows its recommendations as one list; that one reply
accepting the list closes the lens; that product-domain asks the compliance question at Light with no default; that
answers are handed forward into later lenses naming their source; and that the maintainer read and agreed each answer
before it was sent.

It does not prove a person typing in the workshop session: the four replies came from the reviewer session.

## Setup, and the home folder

- Scratch project `%TEMP%\specrew-205-t026`, built by a script: `git init`, then
  `deploy-speckit-extension.ps1` and `deploy-squad-runtime.ps1` from the worktree source. Before them, empty `.specify`
  and `.squad` folders, which the two scripts require.
- Copied by hand, because neither script writes them:
  - Spec Kit's core `.specify/scripts` and `.specify/templates`, with the source spec template (`## Problem Context`);
  - `.specrew/config.yml` (marked greenfield);
  - `CLAUDE.md`;
  - `.claude/settings.local.json` with the hooks block only. Its hooks call the project's own dispatcher.
- No `specrew init`, `start` or `update`, and no hook deployer.
- Checked first in a throwaway copy, since deleted by its exact path: both deploys, a SessionStart hook call with a
  fake payload, and the feature scaffold.
- The project has its own `.specrew` folder. Without it, the session-start provider's walk upward would have found
  the home folder's `.specrew`.
- Home hook files: all ten matched the known-good set before the build, after it, and after the run.

## What the run found

Recorded in the drift log as DRIFT-015 (observations) and DRIFT-016 (the missing turn token, handed to 203 as H-021).

1. **A stale open point.** `product-domain.md` still ends with "How the external accountant reaches the shared folder
   ... is not yet stated", though security-compliance decision 2 answered it (VPN, personal account). The session
   updated product-domain's first-version list with the 30-day removal on its own initiative, but not that line. The
   skill does not ask for any write-back to an earlier lens's record today. The back-check is later work, held for
   after feature 203, and this is the gap it closes.
2. **An unlabelled inference.** `security-compliance.md` ends with "Controls that follow from the named threat actors
   (for plan)", which the session derived from the two threat actors the human named. Every decision row carries a
   Source; that section has none, so a reader cannot tell it is the session's inference and not a human decision.
3. **A hand-forward line outside the lens file.** data-storage opened with "Handed forward, security-compliance: files
   are removed 30 days after they are written". data-storage's lens file does not define that line, so the length
   test does not count it, and the source lens defines no key for it. The two lines the file does define (data
   residency, systems carried over) were shown as written.
4. **The agenda shows one flat list** with nothing marking the problem and solution parts (DRIFT-014, the
   maintainer's decision of 19:48).
5. **A turn got no turn token.** The 19:38 correction arrived 19 seconds after the previous turn ended. No fresh
   `[specrew-turn]` token came with it, so the session reused the last token, which Stop had already consumed, and
   `declare-turn-end.ps1` refused it ("matches no live session in this project (0 live tokens)"). The session recorded
   this as D-001 in the scratch feature's drift log, as the relayed reply asked, and reported it plainly. No workshop
   answer was affected.
