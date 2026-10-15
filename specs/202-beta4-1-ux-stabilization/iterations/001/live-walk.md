# Live walk: Tier 1 acceptance (SC-001, SC-003)

The maintainer walks this at the iteration-1 closeout, once per validated host: Claude, Codex and Copilot. Cursor and
Antigravity are experimental and are not walked (spec, Host support tiers).

The walk counts what the tests cannot: real decisions, corrective exchanges and extra stops on a real installed host.
A value that was not observed is written as `null`, never `0`.

## Before the walk

1. Install the build under test into a **scratch project outside any repository you care about**, one folder per host:
   `specrew init <scratch>/walk-<host>`, then `specrew start --host <host>` from that folder.
2. For Codex, use a healthy worktree: a fresh scratch project, not a worktree that has run earlier reviews (the spec
   records Codex parity as unproven, not broken).
3. Note the host version and the date in the table below.

## The walk (each host)

| Step | You do | Expected |
| --- | --- | --- |
| 1. Open | Start the session and send a first message that is a concrete request ("I want a small CLI that ...") | The orientation comes first, before any question: Specrew active, version and host, where the project stands, what boundaries will ask of you, and your dials sentence (FR-014, FR-016). |
| 2. Product-domain | Answer the product-domain question in one typed reply | One receipt. No repaint, no "your answer did not register" (SC-001). |
| 3. Agenda | Confirm the agenda with a natural reply ("yes, looks right") | One receipt. The agenda you confirmed is the one on screen. |
| 4. One lens | Answer the first lens's question in one typed reply | One receipt. |
| 5. Question about a boundary | At the next boundary packet, type a question that quotes the approval phrase ("what does 'approved for specify' mean?") | The question is answered. The packet is not repainted and nothing is approved (round 3, finding 1). |
| 6. Approve | Type the approval phrase | The boundary advances once. No repaint and no `Stop hook error` line on any host (SC-004). |
| 7. Resume | Close the session and start it again | The resume opens with where you are, read from disk: the pending decision, commits since the last notes, task progress (FR-019). |

Checkpoints: steps 2, 3 and 4 should yield **3 receipts and exactly 1 typed reply each** (SC-001). Receipts are the
lines of `.specrew/runtime/workshop-authority.jsonl` in the scratch project; count them after step 4.

## Friction record (fill per host)

| Host | Version | Date | Real decisions | Corrective exchanges | Extra stops | Receipts after step 4 | Replies per checkpoint | Notes |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Claude | | | null | null | null | null | null | |
| Codex (healthy worktree) | | | null | null | null | null | null | |
| Copilot | | | null | null | null | null | null | |

A **corrective exchange** is any message where you had to repeat, re-type or explain something the system should have
taken the first time. An **extra stop** is a stop that asked for no decision of yours (the governing principle: a stop
is justified only when a human decision is needed).

## After the walk

Copy the filled table into `acceptance-evidence.md`, section "Friction after the fix". Any non-zero corrective exchange
or extra stop is a Tier 1 regression, recorded with what you typed and what came back.
