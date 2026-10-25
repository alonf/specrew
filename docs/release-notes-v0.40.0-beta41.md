# Release notes - v0.40.0-beta41 (Beta4.1)

**Theme**: the experience at every turn. Beta4.1 is feature 202, a UX stabilization of Beta4. It changes what you
see and how often you are stopped, not what governance requires. Gallery prerelease labels may not contain a dot,
so Beta4.1 is published as `0.40.0-beta41`.

**Validated hosts**: Claude Code, Codex and Copilot CLI. Cursor and Antigravity are experimental and were not
validated in this release.

## What this release fixes

**Your approval is recorded once.** Both the message hook and the turn-end check could record the same typed
approval, which left a spare approval behind that a later step could use. Each approval is now recorded once, keyed
by the host's own message ID. On Copilot, an approval that was not recorded is reported to you, not dropped.

**Copilot no longer records everything twice.** Copilot CLI also runs Claude Code's hooks, so every Specrew hook ran
twice and Copilot's turns were blocked under Claude's name. Specrew now acts on each Copilot event once. Passed live
on Copilot CLI 1.0.101.

**A sub-agent's task text is never taken as your approval or your answer.**

**Codex workshop answers are recorded.** A brief lock on the workshop journal used to block every answer silently.
A short hold is now retried. A lasting failure is reported in the same turn, together with whether your reply was
used. While it lasts, `specrew status` and `specrew where` start with a health line. If Specrew cannot recover on its
own, it asks one plain question before it clears the stuck state, and it deletes nothing.

**The packet is shown once.** It used to be repainted on every turn. It now appears once per session, and again only
after a new session, a resume, a compaction, a long gap or a change to the artifact it shows. A side question gets an
answer, not the packet again.

**The Stop hook no longer blocks a turn over wording.** A reply that said the right thing in other words was blocked
and sent back. That no longer happens, and a missing profile line is filled in for you instead of costing a turn.

**The orientation comes first.** A session's first reply orients you before any question is asked.

**The same words on every host.** The sentence that says how Specrew adapts to you reads the same on every host. On
Codex it no longer shows raw settings such as `software_architecture=10`. On a host without slash commands it tells
you to ask for a profile update.

**One feature, named the same everywhere.** Status, orientation, resume and `specrew start` name the same active
feature and say which record decided it.

**A second feature in a worktree can reach specify.** The review-coverage line no longer names the closed feature's
review campaign, and readiness reports BLOCKED where it used to report a false READY.

**Resume reports from disk.** A resumed session states where the work stands from the records, and flags a stale
handover note with its age.

**Refusals name the step that fixes them.** The design-analysis refusal names the step that produces the missing
artifact and lists every gap at once. An empty file no longer throws.

**`specrew init` stays inside its own folder.** Run inside another repository's folder, it no longer commits to that
repository or writes `.github/` at its root.

**A closeout is recorded only on your approval.**

**Two sessions in one project no longer see each other's refusals.**

## What changed

**The approval form.** On Claude Code, an approval phrase on its own line counts even when the message also contains
a paste. Text inside a paste never counts. A message that quotes more than one of the offered replies is refused as a
quoted menu. Other hosts keep Beta4's rule that the approval is the whole message, and the refusal says why.

**Delegating the rest of a workshop.** Typing "the remaining lenses" or "all remaining lenses" delegates every open
lens. The reviewer is chosen once, when you confirm the agenda.

**`specrew update` removes one retired file.** It deletes `.specrew/runtime/workshop-receipt-outcomes.jsonl` and says
so. Each session now keeps its reply outcomes in its own folder.

## Known issues

**On Copilot, workshop questions can open Copilot's question box, and an answer typed into the box is not recorded
(B4F-131).** Copilot then asks again in chat. Specrew's Copilot instructions forbid the box for workshop questions,
and Copilot still used it in three walks in a row. Nothing false is recorded. **Answer in the chat as a normal
message.** If an answer goes into the box, type it again in the chat.

**On Copilot, pressing Esc on the question box can swallow your next message (B4F-153).** Copilot folds the message
you type after Esc into the turn that is still running. No hook sees it, so Specrew cannot record it or tell you it
was missed. Nothing false is recorded. **If Copilot carries on as if you had not answered, type the answer again.**

**After the review allowance is used up, a review-coverage block can stop every turn end, even during a retro or a
closeout (B5F-012).** It counts records, runtime copies and test data as source that changed after the last review.
It offers implementation choices (`hold implementation here`, `continue without coverage until the review phase`)
that do not apply outside implementation. Claude Code shows it as "Stop hook error", which looks like a crash but is
not one. Your work is safe, and the session goes on. Outside implementation there is nothing to decide. During
implementation, its three replies are real choices.

**Beta4's two known issues are unchanged:** lens confirmations bind the next typed reply, and a scaffolded feature
you never started keeps announcing its workshop. See
[the Beta4 release notes](release-notes-v0.40.0-beta4.md). Both are Beta5 work.

## How this release was validated

The changes from iterations 002 and 003 were walked live on Copilot CLI 1.0.101. On Claude Code and Codex they are
covered by replay tests. Iteration 001 was walked live on all three validated hosts.

CI on the merge into main: the deterministic gate and the contract lane passed on the branch push of the merged head.
Lint on the pull request failed on one record, the needs-rework retro of feature 198's iteration 011, which stays open
until the guard it waits for ships.

## Moved to Beta5

Review ordering (US7: B4F-054, B4F-056, B4F-058, B4F-061, B4F-093 and B4F-103) and the capture of a verdict typed
right after a compaction (B4F-112) move to Beta5, as do the findings recorded during 202 that the maintainer
deferred. They are listed in [docs/beta4-findings.md](beta4-findings.md) and
[docs/beta5-findings.md](beta5-findings.md).
