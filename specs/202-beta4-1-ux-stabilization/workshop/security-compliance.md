# Lens: security-compliance (light)

**Feature**: 202-beta4-1-ux-stabilization
**Confirmation**: human-confirmed / lens-question, closed with a typed `move on` on Claude, 2026-10-13. Receipt `e62eb47f9f9a891147cbef0ed8116a6b2ee48fb9cfdeb1436c0f2f0842149104`.
**Question**: how hook output is kept from counting as human authority while capture is degraded, without blocking every typed reply (the trust rule behind the B4F-108 marker).

## Trust boundary (agreed, with origin corrected to three values)

```
   host                        adapter                       shared path
 ---------           ----------------------------      -------------------------------
 user-prompt  ---->  turn record                 ----> receipt writer
 event               {event, text, host,               mints ONLY when:
                      ORIGIN = typed-user |              origin = typed-user
                               host-injected |           AND text not in hook output
                               unknown}                  (journal + outage buffer,
                                                          checked for EVERY reply)
 host-injected/                                         host-injected | unknown
 replayed hook ---->  (some hosts, e.g. Copilot   ----> never mints
 text                  1.0.79, replay hook text
                       as a plain user-prompt
                       event: no reliable field)
                                                       hook output  --> journal (hashes)
 system-filled text (dials, orientation) -----------> marked system output, journaled
                                                       journal busy --> outage buffer
                                                        (per-process unique files,
                                                         read before the next
                                                         prompt-submit decision)
                                                         --> flushed to journal on
                                                             recovery, files removed
```

## Decisions

1. **Trust rule while degraded: precise fail-closed through a buffer (option b).** When hook output cannot be journaled, its hashes go to a per-process outage buffer, with a unique file per process so writers never collide. The integrity check reads the journal and the buffer. On recovery the buffer is flushed into the journal. A typed reply is refused only when it actually matches hook output. If even the buffer write fails, only that one turn fails closed, and the same turn discloses it along with whether the turn was consumed. Blanket fail-closed (today's deadlock) and fail-open are both rejected. **Plan details:**
   - The integrity check reads the outage-buffer files before the next prompt-submit decision, so there is no unchecked window.
   - Buffer files are removed once flushed.
2. **Origin in the standard turn record: a second line of defense (corrected).** Origin cannot be determined reliably from the host event. Some hosts replay hook text as a plain user-prompt event with no distinguishing field; the code already notes that Copilot 1.0.79 does this. Origin therefore takes one of three values: **typed-user**, **host-injected** or **unknown**. Only typed-user can mint a receipt. The journal-and-buffer match still applies to **every** reply. Origin adds a check on top of the journal; it does not replace it.
3. **No sensitive content in the integrity stores.** The journal, outage buffer and health journal hold only hashes, event names and timestamps, never prompt or reply text. Receipts keep their hash-only shape.
4. **Audit of recovery actions.** Every recovery action that needs a human decision, such as moving a marker aside, records the receipt of the reply that approved it alongside the action. No recovery step runs on assumed authority.

## Note carried to the plan (not a reopened decision)

Each adapter's rule for when it emits `unknown` has to be checked against the real captured payloads, which are a Tier 1 task. On a host where typed prompts and replayed hook text arrive as identical events, labelling all of them `unknown` would block every reply on that host and break B4F-108 parity. The journal match is the defense there. The B4F-108 cross-host test settles this.

## Bindings

- `degraded-trust-rule`: `precise-fail-closed-outage-buffer`
- `outage-buffer-read`: `before-next-prompt-decision`
- `outage-buffer-flush`: `flush-then-remove`
- `turn-origin`: `typed-user-host-injected-unknown`
- `mint-requires`: `typed-user-and-no-hook-output-match`
- `integrity-store-content`: `hashes-only`
- `recovery-audit`: `approving-receipt-recorded`
