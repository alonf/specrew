# UI-UX Lens Record: 199-beta3-stabilization

**Feature**: 199-beta3-stabilization
**Depth**: medium
**Captured**: 2026-08-10
**Confirmation**: human-confirmed (typed "all — U1 through U5 accepted" with three refinements, recorded below)

## U1 — The agreed decision-surface layout (pause after every round)

```text
──────────────────────────────────────────────────────────────────────
Review round 3 of linkcheck complete.

Findings that need your attention (2):
  BLOCKING  1  SQL injection in the export endpoint  (src/export.ps1:88)
  MAJOR     1  retry loop never backs off            (src/poll.ps1:41)
  Also recorded: 3 minor wording/style findings — saved as follow-ups,
  they never block your sign-off.

Cost so far: 3 rounds, 41 minutes. Default round budget: 3 of 4 used.

Recommendation: fix the blocking finding, then stop here.

What would you like to do?
  1. Fix these and run another review round
  2. Stop here — the remaining findings are saved as follow-ups, a final
     check runs on your files exactly as they are now, and review
     sign-off completes. One step; nothing left to untangle by hand.
  3. Abandon this review campaign (nothing further runs)

Reply with a number. Nothing runs and nothing is spent until you answer.
──────────────────────────────────────────────────────────────────────
```

Human refinement: the one-line recommendation IS included, derived from severity floor
ONLY (no trajectory/instrument inputs — those are beta4); the numbered options keep the
human in charge. Minors are visibly present but never gate. The "nothing is spent until
you answer" line is mandatory (held-console lesson).

## U2 — Consumer-language contract (ledger item 7, durable)

- **Register rule**: every human-visible sentence is about the user's project and the
  user's decision. Internal vocabulary appears only in committed records and diagnostics.
- **Human scoping**: the banned-token list covers MACHINERY NOUNS ONLY — crossing, mint,
  marker, digest, boundary sync, verdict capture, controller truth, ratchet,
  claim-ordered, terminalize. Lifecycle stage names (specify, clarify, plan, tasks,
  review) and the approval phrases ("approved for <boundary>") remain consumer-visible
  by design.
- **ID gloss rule (human addition)**: in human-visible prose (packets, decision surfaces,
  stop messages, briefings), every task/requirement/finding reference carries both the
  identifier and a short plain description — "task T007 — the external URL checker" —
  never the bare ID alone. Records (tasks.md, traceability tables, drift logs) keep bare
  IDs as the canonical cross-reference form.
- **Enforcement (both rules, RED-first)**: a banned-token check over rendered consumer
  surfaces (zero machinery nouns), and consumer-facing templates render IDs through a
  helper requiring id + title — an unglossed ID is a failing test, not a style note.
- Scope: packet templates, stop messages, skill instructions, orientation banner.
- Transformation example (T067 evidence): "The crossing is minted against a stale
  digest; the packet's marker is the one the verdict capture binds to" becomes
  "linkcheck is ready for your final approval — reply 'approved for review-signoff' to
  complete it."

## U3 — One-message decision stops (ledger item 8, durable)

Context packet and decision surface compose into ONE message at every decision stop; a
stop-hook bounce at a decision stop is an instruction defect, driven to zero via the
instruction layer (skills/templates), per the 208 rule.

## U4 — Failure-message shape (durable)

What happened -> what it means for YOUR project -> the exact next step. Timeout example:
"The codex review didn't finish within 5 minutes (the default window). Codex reviews of
a full plan typically need 15 — to allow that, set co_review_timeout_seconds: 900 in
.specrew/config.yml and rerun." Same shape for env_refs, plan-schema, and defer-record
failures. Exact defaults/numbers are requirements-nfr scope.

## U5 — Banner version (ledger item 10, durable)

Every version render shows the full prerelease string (0.40.0-beta3): fix the
ModuleVersion-only read at specrew-bootstrap-provider.ps1:438 plus its deployed mirror
and coordinator-prompt-surgery.ps1, using specrew-start.ps1's
Get-ManifestSpecrewVersionText as the reference composition.
