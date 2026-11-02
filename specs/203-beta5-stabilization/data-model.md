# Data Model: 203 beta5 stabilization (iteration 001)

All records are immutable facts in the existing stores, written with `FileMode.CreateNew`; an identical existing
fact is idempotent success, a conflicting one fails closed. Records keep ids and hashes, not raw prompts.

## Turn record (input, not stored)

| Field | Meaning |
| --- | --- |
| `identity` | Claude `prompt_id`, Codex `turn_id`, Copilot stand-in hash (DA-2) |
| `identity_kind` | `host-message-id` or `stand-in` |
| `origin` | `typed-user`, `host-injected`, `unknown` |
| `host` | `claude`, `codex`, `copilot` |
| `text` | the typed text, used in memory only |
| `text_hash` | sha256 of the text |

## Typed act (classifier output)

| Field | Meaning |
| --- | --- |
| `kind` | `boundary-verdict`, `top-up`, `stop-answer`, `workshop-reply`, or `none` |
| `reason` | for `none`: `not-standalone`, `no-identity`, `not-human`, `no-pending-crossing`, `boundary-mismatch`, `form-unreadable`, `stage-evidence-absent`, `already-recorded` |
| `turn_identity` | the turn it came from |
| `target` | the crossing, pause or workshop question it answers |
| `argument` | only for a stop answer that needs one (a deferral's destination) |

Rule: one turn yields exactly one act or `none`. Only `none` reasons other than `already-recorded` and
`not-standalone` produce a not-recorded report.

**As built in T003 (2026-11-02), `Resolve-SpecrewTypedAct`:** the act carries `Report` (whether the human must be
told), so the rule above is computed once, by the classifier. Reasons added: `not-an-act` (no act shape and nothing
waiting; not reported), `origin-unconfirmed` (FR-026; reported), `missing-destination` (a deferral without its
destination, FR-011; reported). `not-human` (host-injected text or a compaction summary) is not reported, because the
human did not type it. `not-standalone` is reported only when the human's own text carries the phrase and goes on or
qualifies it (the retype-one-line case); a phrase quoted, in backticks or inside a paste is silent. Kinds added so
T004's rewiring loses no act today's router writes: `withdrawal`, `partial-signoff`, `workshop-repair`,
`coverage-deferral`, and `round-approval`, which T004 removes (FR-010). `identity` is
`sha256(typed-act | host | message id | sha256(text))`: Claude reuses the running turn's `prompt_id` for a queued
message (research.md R1), so the id alone is not one key per message.

## Review grant (campaign fact)

| Field | Meaning |
| --- | --- |
| `campaign_id` | the review campaign |
| `budget_total` | the plan's rounds, snapshotted |
| `host_order` | the plan's reviewer order |
| `infra_failure_cap` | consecutive infrastructure failures before the next host |
| `verdict_entry` | the before-implement verdict ledger entry it cites |
| `plan_hash` | hash of the plan's budget block at snapshot |

## Round reservation (campaign fact)

`campaign_id`, `run_id`, `host`, `grant_ref`, `reset_ref` (the reset that opened the current window, or none),
`scope` (`full` or `scoped` with its path list), `reserved_at`. Spent on invocation; released before invocation.

## Budget reset (existing fact, top-up)

`campaign_id`, `turn_identity`, `reason` (the human's own text or empty), `observed_at`. Moves the counting origin.

## Pause (campaign fact)

`campaign_id`, `kind` (`a-budget-spent`, `b-dispute-or-defer`, `c-judgment`, `d-host-outside-order`), `finding_ref`
where it applies, `opened_at`. Closed by a stop answer or a top-up.

## Stop answer (fact)

`campaign_id`, `pause_ref`, `turn_identity`, `answer` (`stop-review`, `defer`, `drop`, `fix`, `allow-reviewer`,
`judgment`), `argument` (deferral destination or host).

## Supersession (fact)

`kind`, `superseded_ref`, `superseding_ref`. The superseded act is never reused.

## State transitions (review loop)

```text
grant --> [reserve] --> invoke --> clean ------------------> sign-off packet
             ^                  \-> fix-needed --> fix --> [reserve] (next round, or scoped after a clean round)
             |                  \-> infra failure x cap --> next host in order --> [reserve]
             |  rounds_used = budget_total --> pause (a) --> top-up --> [reserve]
             |  host order exhausted -------> pause (d) --> allow reviewer <host> --> [reserve]
             '-- dispute/defer --> pause (b); judgment --> pause (c) --> stop answer
```
