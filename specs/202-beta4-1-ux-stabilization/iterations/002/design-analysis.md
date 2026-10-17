# Design Analysis: 202-beta4-1-ux-stabilization, Iteration 002

**Feature**: 202-beta4-1-ux-stabilization
**Iteration**: 002 (B4F-127, B4F-129, B4F-125 with B4F-128, B4F-130, B4F-131, candidate 3, candidate 7)
**Date**: 2026-10-17
**Status**: presented for co-design, one decision at a time

## Problem framing

Iteration 002's items share one shape: a single human act is recorded zero times or more than once. One typed
approval is recorded by two paths (B4F-127). One hook event fires once per host whose settings the running host reads
(B4F-129). One delegation covers one lens instead of the remaining ones (B4F-130). One answer in Copilot's question box
is recorded nowhere (B4F-131). One approval line is refused because of what follows it (B4F-125). The fix is the same
rule in each place: one human act, one record, keyed by the identity of the act, not by the path that saw it.

## What the code map found (read-only, 2026-10-17)

Abbreviations: HS = `scripts/internal/bootstrap/HandoverStore.ps1`, HAS = `scripts/internal/bootstrap/HumanAuthorityStore.ps1`,
WAS = `extensions/specrew-speckit/scripts/workshop-authority-store.ps1`, SG = `shared-governance.ps1`, DISP = the hook
dispatcher (twin copies in `scripts/internal/` and `extensions/specrew-speckit/scripts/`, identical today).

- **B4F-127.** Both paths call one router, `Invoke-SpecrewTypedAuthorityCapture` (HS:1169-1318): the prompt hook at
  HS:1417-1426 and the Stop's transcript walk at HS:1745-1764. The turn identity (`Get-SpecrewTypedTurnIdentity`,
  HAS:710-741) hashes host, source event, position, arrival and text. The source event is in the hash, so the two paths
  can never produce the same identity, and the exhausted-turn check (HAS:748-825) cannot see the first recording.
  Claude payloads carry a `prompt_id` that is the same on the prompt and on that prompt's Stop; nothing reads it. After a
  host-injected prompt the Stop carries the injected prompt's id, so the Stop path needs the transcript entry's `uuid`,
  which the parser drops. Copilot's prompt payload has no prompt id. Boundary verdicts are already protected, because
  they bind to the one pending stop (HS:1045-1051).
- **B4F-129.** `Invoke-RefocusHookDeployment` (`refocus-deploy-integration.ps1:111-180`), called by init and update,
  writes hook settings for every hook-capable host whose folder exists, not only the chosen host. Claude's command is
  guarded: it exits silently when `CLAUDE_PROJECT_DIR` is empty (`deploy-refocus-hooks.ps1:247`; the manifest comment
  at `hosts/claude/host.psd1:51-52` already names the Copilot case). Copilot 1.0.98 evidently sets that variable, so the
  guard passes. The dispatcher takes the host only from `-HostKind` (DISP:27) and has no payload-shape check. The
  payloads differ cleanly: Claude always sends `hook_event_name` and snake_case `session_id`; Copilot sends camelCase
  `sessionId` and never `hook_event_name` or `session_id` (all 14 Copilot fixtures). The receipt writer
  (WAS:838-989) appends without checking whether the receipt ID is already present.
- **B4F-125.** The guard is a line-count rule: `Test-SpecrewAuthorityMessageContinues` (HAS:296-313) refuses any message
  with content after its first line. It is called by the round, pause and allowance checks (HAS:529, 1221, 1818), with a
  copy for coverage deferral (SG:7921). An allowance reset writes no round approval (HAS:1832-1876).
- **B4F-128.** A discussion question is kept as the whole raw line and must appear exactly (turn-end-store.ps1:1219,
  1304); headings have the DRIFT-030 meaning match (:1255-1268).
- **B4F-130.** A "you decide" reply is a delegation for the open lens only (WAS:10-34, 941, 948), and
  `confirm-workshop-lens.ps1` takes one lens. Nothing tells the human that "the remaining lenses" was narrowed.
- **B4F-131.** The workshop skill already tells every host not to use a question tool (`design-workshop.md:55-62`,
  258-260). Copilot registers no tool-use hook, so its question-box path is never observed, and a dismissal fires no
  hook event.
- **Candidate 3.** The receipt-outcomes journal has one writer (WAS:471-507) and two readers: the dispatcher's
  recording disclosure (DISP:1236) and the conformance provider's latest refusal (:1379-1380).
- **Candidate 7.** `turn-message.md` is written by `declare-turn-end.ps1` (:151/160) and read by nothing; the message
  is stored inline in the turn record.

## Key Design Decision Points

- **DA-1 Host binding (B4F-129).** How a hook knows the event belongs to the host it was installed for.
- **DA-2 Message identity (B4F-127).** What identifies one human message on each host, so a second path recognises it.
- **DA-3 Approval form (B4F-125, B4F-131).** Which typed messages carry an approval when the phrase is not alone.
- **DA-4 Delegation scope (B4F-130).** What "you decide the remaining lenses" records.
- **DA-5 Receipt outcomes (candidate 3).** What replaces the receipt-outcomes journal for its two readers.

B4F-128 follows DRIFT-030's rule (a question line counts as present when its meaning matches), and candidate 7 is a
deletion; neither needs a design decision.

## Finding: Claude Code does not tag every paste (settled for DA-3, 2026-10-17)

The maintainer asked whether every paste arrives tagged. It does not. Across the 123 user messages in this feature's
Claude transcripts, 26 carry a `<pasted_content id="N">` pair. Every tagged paste is either multi-line (the smallest is
673 characters over 8 lines) or a single line of at least 1,016 characters. Single-line messages of 439 to 715 characters
arrive untagged, among them verdicts with instructions (`approved for clarify - ...`, `approved for plan - ...`,
`approved for review-signoff - ...`), and the maintainer's notes from the retro verdict say pasted verdicts of about 600
to 800 characters were recorded as typed. So a short paste is indistinguishable from typing in the text the hook receives.
The retro approval that was refused was a tagged single-line paste of 1,163 characters.

Consequence: the tag rule protects only long pastes. For a short paste, **safeguard 2 is the protection**: a quoted menu
is never an approval. One residual case stays open and is accepted as such: a short paste of a single approval line, with
no second verdict option, still counts, exactly as typing it would. The tests carry the size boundary observed here, and
not a guessed threshold.

## Co-Design Record

| Point | Decision | Date |
| --- | --- | --- |
| DA-1 | **Option A, with the maintainer's change.** Each host binding declares the payload fields only its host sends. A hook stands down (does nothing, exits 0) only when the payload positively matches another known host's fields. A payload that matches no known host is handled as today and logged once, so a host changing its payload shape can never switch governance off without a trace. The receipt store refuses a receipt ID it already holds. Note from the fixtures: Codex also sends `hook_event_name` and snake_case `session_id`, so the declared fields must tell all three apart (Claude `prompt_id`, Codex `turn_id`, Copilot camelCase `sessionId`), per event, proven against every recorded fixture. | 2026-10-17 |
| DA-2 | **Option A, with the maintainer's two conditions.** One human message has one key, the host's own message ID; the first path to record wins and the second does nothing; a spent approval from the same message is final. (1) On Claude both paths produce the same key: the turn-end path reads the same message-ID field (`prompt_id`) that the message hook receives, from the human-typed transcript entry, never that entry's own `uuid` (in the walk transcript every typed entry carries the field, and its `uuid` is a different value). Injected entries are skipped; the compaction summary reuses the `/compact` entry's ID. (2) On Copilot the message hook is the only recording path, and an approval-shaped typed message that hook did not record is reported in the journal and in one visible line, never dropped without a trace. Proof: a per-host replay test from recorded payloads, where one approval through both paths gives exactly one row. | 2026-10-17 |
| DA-3 | **Option A, with the maintainer's two safeguards.** On Claude, nothing inside a paste is an approval, and a phrase leading its own line outside every paste is, whatever surrounds it. Other hosts keep "the phrase alone", with a refusal that names the reason, until a recorded payload shows how they mark a paste. (1) A paste is marked only by an opening and a closing tag carrying the same ID, so a closing tag quoted inside a paste cannot make what follows it count as typed. (2) A message that carries more than one verdict option (for example a quoted packet menu with an approval line and a changes-needed line) is never an approval, and the refusal names it as a quoted menu. | 2026-10-17 |
| DA-4 | pending | |
| DA-5 | pending | |
