# Lens: security-compliance (medium)

**Feature**: 203-beta5-stabilization
**Confirmation**: human-confirmed / lens-question, closed with a typed `move on` on Claude, 2026-10-31,
receipt `cf803a2c2439163be746656270ee0de32070398442670f66b026ca9df6cacf3e`.
**Question**: how measure (b), no approval recorded that the human did not give, is enforced, and what
the autonomous review cycle may spend without asking.

## Trust boundaries for authority

```text
  HUMAN -- types --> host UI -- user-prompt event --> hook --> [classifier] --> authority stores
                                  (the one mint origin)           |
                                                                  | one act per typed turn,
  ====================== trust boundary =======================   | bound to the turn identity;
                                                                  | phrase must stand alone
  AGENT output, tool results,          turn-end path ---+         v
  compaction summary (shows as         transcript ------+-->  recovery only (four conditions),
  a user-role entry, B4F-112),         backstop         |     never a second mint
  pasted text, quoted phrases          writer CLI ------+
                                       (re-derives the act from the cited turn)
```

## Decisions

1. **One mint origin, one standalone rule on every path.** Only the typed turn delivered by the host's
   user-prompt event mints authority. The four conditions apply to the primary hook path as well as to
   recovery, because a quoted, backticked or pasted phrase arrives through the user-prompt event inside
   the human's own typed turn:
   - the turn carries an identity (the host's message id, or the explicit substitute below);
   - it is human-authored (not a compaction summary, tool result or agent text);
   - the approval phrase stands alone (not quoted, not in backticks, not inside pasted content);
   - no record exists yet for that identity.

   The turn-end path, the transcript backstop and any writer CLI never mint; they may only recover a
   missed hook event under the same four conditions.

   **Verify per host before the spec fixes the mechanism** (`research-needed`, load-bearing):
   - (a) whether the user-prompt event carries a per-message id. The maintainer's reading is that
     Claude's payload has the session id, transcript path and prompt but no per-message id. (The
     workshop receipt store does record a `message_id` on Claude today; whether it comes from the
     payload or is derived afterwards is part of this check.) Where a host lacks one, the substitute
     identity is defined explicitly in the spec, per host, not left implicit.
   - (b) how pasted content reaches the hook on each host: marked, replaced by a placeholder, or
     inlined as plain text. Where it is inlined without a marker, the spec states how the standalone
     rule is still applied.
2. **Unspent-record folding (B4F-137/140).** The newest typed act of a kind supersedes an older unspent
   one through an immutable supersession fact; the older one is never reused. The top-up has no unspent
   state (a reset moves the counting origin), so the rule mainly serves stop answers.
3. **What the cycle may spend without asking.** Rounds up to `budget_total`, on hosts in the approved
   order, fixes within the feature's approved tasks. It may not raise or reset the budget, use a host
   outside the order, defer or drop a finding, change scope, or edit the plan's budget: each is a human
   stop.
4. **Audit trail.** Every round reservation cites the grant (the before-implement verdict entry) and the
   reset that opened the current budget window. Every stop answer cites its typed turn's identity. This
   is what the measure (b) audit joins against.
5. **Writers re-derive, never accept a claimed act.** Citing a real typed turn is not enough: an agent
   could cite the human's real `confirm` turn and mint a verdict from it. A writer given a turn identity
   re-reads that turn, mints only the act the classifier derives from it, and only if that act is
   unrecorded. The per-round `--approve-round` CLI goes with the round approval. No script or `!` command
   is ever offered as the way to approve.
6. **Stored content.** Records keep turn identities and hashes, not raw prompts (202's rule). The typed
   phrase text is kept only where a stop answer needs its argument, such as a deferral's destination.
7. **The top-up is hook-minted; its reason is the human's.** In this session the allowance reset was run
   by the agent with an agent-written reason after the maintainer's typed reply. Under decision 1 the
   hook mints the top-up from the typed turn, and the reason recorded is the human's own text or none,
   never agent-authored.

## Rejected alternatives

- Standalone rule on recovery paths only: a quoted or pasted phrase in the human's own turn reaches the
  hook first and would mint there.
- Accepting any existing typed turn identity at a writer: lets an agent mint a different act from a real
  human turn.
- An agent-written reason on a human act: the record would carry words the human did not give.

## Bindings

- `mint-origin`: `typed-turn-user-prompt-event`
- `standalone-phrase-rule`: `all-paths-including-hook`
- `turn-identity`: `host-message-id-or-explicit-per-host-substitute`
- `pasted-content-handling`: `verify-per-host`
- `recovery-paths`: `recover-only-under-four-conditions`
- `unspent-supersession`: `newest-supersedes-immutable-fact`
- `cycle-autonomy`: `rounds-within-budget-approved-hosts-approved-tasks`
- `authority-audit`: `reservation-cites-grant-and-reset-stop-answer-cites-turn`
- `writer-acceptance`: `rederive-act-from-cited-turn-mint-if-unrecorded`
- `approve-round-cli`: `removed`
- `top-up-mint`: `hook-minted-reason-human-text-or-none`
- `record-content`: `ids-and-hashes-phrase-argument-only`
