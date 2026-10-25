# Lens: requirements-nfr (medium)

**Feature**: 202-beta4-1-ux-stabilization
**Confirmation**: human-confirmed / lens-question, closed with a typed `move on` on Claude, 2026-10-13. Receipt `be6d74dfa9c1235f4e8fdc3d0542ffcad0d2bc441ea8002ad765ea39597da691`.
**Question**: what evidence proves Tier 1, and at which stop the maintainer accepts it.

## Quality-attribute priority (agreed, with diagnosability raised above friction)

A higher row wins any conflict with a lower one.

```
 rank | attribute               | what it means for 202                         | threshold
 -----+-------------------------+-----------------------------------------------+----------------------------
  1   | authority integrity     | hook output never counts as a human reply;    | 0 regressions; fault
      |                         | no receipt without a typed reply              | injection proves it
  2   | cross-host parity       | same flow -> same receipts, same reply count  | equal counts on Claude,
      |                         | on Claude, Codex, Copilot                     | Codex, Copilot
  3   | diagnosability          | refusals name the actual cause + one action   | every Tier 1 refusal path
  4   | friction                | stops/replies that carry no real decision     | 0 corrective exchanges per
      |                         |                                               | Tier 1 scenario after fix
  5   | latency                 | hook time per turn                            | not a driver; recorded only
```

Why diagnosability ranks above friction: today's real cost was a refusal that named the wrong cause, not the extra replies themselves. Integrity outranks both, so a B4F-108 recovery that has to choose between disclosing and asking, or silently accepting a reply, chooses to disclose and ask.

## Friction protocol

There are three kinds of exchange:

- A **real decision** is a human reply that answers, authorizes or changes something, such as a scope answer, a lens answer or a verdict.
- A **corrective exchange** is a reply or stop that exists only because the system demanded a repair: a missing line, a re-render, a misdiagnosis, or the same question asked again.
- An **extra stop** is a Stop block or forced continuation that is not tied to a real decision.

For each scenario, record the before and after counts of each kind. Record elapsed time split into mechanical, agent and human time where it can be observed. Where it cannot, record null, never zero. After-fix numbers come only from real runs.

Baselines:

- **B4F-106:** 1 corrective cycle.
- **B4F-096:** 1 corrective exchange and 1 extra stop. These counts come from a controlled replay.
- **B4F-108, Codex, 2026-10-13:** several corrective rounds, and the product-domain checkpoint never closed.
- **B4F-108, Claude, 2026-10-13:** one corrective round, a `move on` consumed without a receipt. The checkpoint closed only after the marker was moved.
- **B4F-108, silent outage from 2026-09-09T07:28:50Z to 2026-10-13:** recorded as not captured. It is not zero.

## Per-finding thresholds

Each finding's "required behavior" in docs/beta4-findings.md is its acceptance test. On top of that, every Tier 1 scenario must reach a common bar after the fix: 0 corrective exchanges and 0 extra stops, with no change in the number of real decisions.

- **B4F-104:** an unchanged crossing is presented once per session. After that there are 0 repaints and 0 `Stop hook error` lines, across all three recorded triggers.
- **B4F-107:** the adaptation text is byte-identical across hosts.
- **B4F-108:**
  - The flow of product-domain, then agenda, then one lens produces 3 receipts and needs 1 reply per checkpoint, on Claude, Codex and Copilot.
  - The fault-injection test passes. Under the injected fault, the degraded state is disclosed in the same turn, and 0 turns are silently consumed.
- **B4F-105:** status and the lifecycle state name the same feature.

## Tier 1 acceptance stop

The verdict at the iteration-1 closeout is the Tier 1 acceptance. Tier 2 planning starts only after the maintainer explicitly approves there. The evidence presented at that stop:

- the test suite, including cross-host tests through each real adapter and the B4F-108 fault injection
- a live installed walk of the B4F-108 flow on Claude, Codex and Copilot, with Codex run on a healthy worktree
- the before/after friction table
- a validator run compared against the known baseline (review-evidence, defer-provenance, 198/011), showing no new failures in those categories

## Resolved open question: hook payload fixtures

No recorded hook-event payloads exist. The tests have only conversation transcripts, in tests/bootstrap/fixtures/conversation/codex.jsonl and copilot.jsonl. Capturing real hook payloads from Claude, Codex and Copilot is therefore a **Tier 1 task**. It is done in scratch directories and never in a governed worktree.

## Bindings

- `quality-priority`: `integrity-parity-diagnosability-friction-latency`
- `tier1-acceptance-stop`: `iteration-1-closeout`
- `payload-fixture-capture`: `tier1-task-scratch-dirs-only`
- `b4f108-fault-disclosure`: `same-turn-zero-silent-consumption`
- `missing-measurement`: `null-not-zero`
