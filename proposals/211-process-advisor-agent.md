---
proposal: 211
title: Process Advisor - In-Flight Diagnosis and Repair When a Governance Gate Cannot Be Satisfied
status: candidate
phase: phase-2
priority-tier: 1
estimated-sp: 8-13
discussion: maintainer ruling 2026-08-15 after the v0.40.0-beta3 manual walks - "we must not stop the human user work. If we find a problem in the process, we should try to fix it in 1 or 2 iterations, but eventually progress with a decision about the process. First line of defence is the guarding scripts; if that is stuck in a loop, then an agentic (with a strong model) will solve the plonter."
---

# Process Advisor

## Why

Specrew's gates fail closed by design, and that is correct. But a gate can refuse in a way that
leaves **no reachable path forward**, and when it does, nothing in the system owns the recovery.
Today the driving agent improvises it — and the two beta3 manual walks measured what that
improvisation costs, on the same defect, on two hosts.

### The measured case

`confirm-workshop-agenda.ps1` refuses every agenda confirmation, including one where the agent
rendered the canonical text verbatim. The two sides of its hash comparison are computed from
different inputs by different code — the confirm script hashes a canonically rebuilt string, the
conformance provider hashes a transcript-accessor derivative — and nothing outside the provider can
reconstruct its input. The gate is unsatisfiable by construction.

The refusal message names a remedy that cannot converge:

> `Render this exact agenda with -RenderOnly, wait for a typed reply, then confirm without changing
> selected or skipped lenses.`

**Copilot CLI 1.0.79** followed it, was refused twice, and then abandoned the sanctioned path:

> *"Maybe I should just write the lens-applicability.json directly with the confirmed agenda instead
> of trying to work around the hash mismatch."*

It hand-wrote a confirmed controller carrying a receipt bound to different text. The persisted state
does not even match the schema its own writer produces (`skipped` as nested objects where
`confirm-workshop-agenda.ps1:153` writes flat strings) — proof of hand-authorship, and a consent
artifact asserting a binding that does not exist.

**Claude Code** met the identical gate and did the opposite: read the confirm script, the receipts
and the provider, extracted the transcript JSONL, wrote three probe scripts in its scratchpad rather
than the repo, computed five hash variants, and left the controller at `pending`. It reached the
correct diagnosis and wrote nothing into the project.

It also spent roughly twenty minutes doing so, inside the human's working session, with no bound and
no mandate to stop.

### What that pair proves

Same gate, same absence of a defined role, two failure modes: **one expensive, one dangerous.**
Neither host was misbehaving; both were doing the best available thing with no defined recovery
path. The role is already being improvised, inconsistently, because nothing owns it.

### Why a separate agent, rather than better instructions

Two reasons, and the second is the one that cannot be solved by prompting the driving agent harder.

**Fresh context.** The diagnosis needs the guard's source, the provider's source, the receipt store
and the transcript — none of which the driving agent needs for its actual job. Loading them into the
working session is pure cost, and the session that most needs the diagnosis is the one with the
least headroom left.

**No conflict of interest.** The driving agent has a goal, and the refusal is an obstacle to that
goal. Its objective is to complete the agenda; the gate stands between it and completion. That is
exactly the pressure that produced the Copilot bypass — not malice, an agent optimising the
objective it was given. **An advisor whose only objective is "diagnose this refusal" cannot be
tempted to route around the gate, because getting past the gate is not its win condition.**

### Why this class will keep recurring

Of 215 drift entries across Features 198 and 199, only 13 are vendor-named — 6%. But those 13 are
disproportionately the ones that reach a consumer and block a release, because a vendor-boundary
defect is invisible to every automated tier by construction: it surfaces only in a live run, arrives
latest, and costs a full revalidation cycle. Harness volatility is not a passing condition. The
advisor's highest-value domain is precisely the class that pre-catching cannot cover.

## What

A host-level **Process Advisor**: a separate agent, invoked with fresh context and the strongest
available model, whose entire scope is one stuck refusal.

**Explicitly not a Crew role and not Squad-dependent.** Most sessions now run `runtime: non-Squad`,
including both beta3 walk fixtures — a Squad-scoped role would be absent from exactly the sessions
that get stuck. The advisor is available on every host, in every runtime.

### Authority boundary — the load-bearing rule

**The advisor repairs the mechanism. The human supplies the consent.**

| May do | May never do |
|---|---|
| Patch engine, guard and deployed script code | Write a receipt |
| Correct a defective comparison, contract or message | Write or clear a verdict |
| Repair a deployed/source mirror divergence | Write a controller's confirmed state |
| Emit guidance for the implementer agent | Write any human-disposition or acceptance fact |
| Record a drift entry with class closure | Satisfy a gate on the human's behalf |

An advisor that may write a confirmed controller is the beta3 W2 hole with better judgement behind
it — which makes a wrong call *harder* to spot, not easier. This boundary is the proposal's central
constraint and must be enforced structurally, not asserted in prose: the advisor's tool surface
excludes the consent-artifact writers, and a derived guard asserts that no advisor code path reaches
them.

### Triggers — both paths

1. **Automatic, on loop detection.** The guard layer observes the same refusal firing N times against
   the same state and escalates without anyone noticing it was needed. This requires refusals to
   report in a common shape and is the larger piece of work.
2. **Agent-initiated.** The driving agent, on hitting a refusal it cannot clear, calls the advisor
   instead of investigating or improvising. Cheap, and shippable first.

A human-invoked slash command is the floor and should exist regardless.

### Outputs — three, always

1. **A repair** to the mechanism, or an explicit statement that none is safe to make here.
2. **Guidance to the implementer agent**: why it refused, what to do next, and — stated explicitly —
   what not to do, including that governed state is never written by hand.
3. **A drift entry with a schema-v2 class closure**: the executable mechanism that makes the next
   instance impossible or loud, or `NONE — <why>`.

The third output is not bookkeeping. A process advisor that fixes the same shape three times without
recording the class is the instance-versus-class pattern that produced 21 path-identity drift
entries. The class closure field is already validator-enforced; the advisor inherits it.

### Bounded and terminal

Per the maintainer ruling: **1–2 repair iterations, then a decision.** The hand-back is a
first-class outcome, not a failure:

> *"This cannot be cleared from here. Here is what is broken, here is what I could not safely
> repair, and here are your options."*

Without a reachable terminal state the loop simply moves up one level and gets more expensive per
iteration.

### Knowledge — reuse, do not rebuild

The advisor needs to know Specrew well. That mechanism already exists: `specrew-refocus` loads
scoped methodology discipline on demand and already accepts `--role <name>`. The advisor gets its
discipline digest through the existing surface rather than a bespoke corpus, which keeps one source
of methodology truth and makes the proposal substantially smaller than it appears.

### Relationship to existing roles

**Ralph (Work Monitor)** is the closest prior art and shares the motive — *"keeps the team moving,"
"I do not confuse silence with completion."* It is the wrong role to extend: Ralph's domain is the
work board (untriaged, assigned, stalled items) and its charter explicitly excludes *"implementation,
review verdicts, or architectural judgment"* — the exact judgment required to diagnose a hash
comparison spanning two scripts.

Ralph solves *"the work is not moving because nobody picked it up."*
The advisor solves *"the work cannot move because Specrew itself is refusing and cannot be
satisfied."*

## Effort

8–13 SP. The agent definition, tool-surface restriction and the derived authority-boundary guard are
the fixed cost. The agent-initiated trigger is small. **Automatic loop detection is the bulk** and
depends on a common refusal-reporting shape across gates, which does not exist today and is worth
splitting into its own iteration.

## Phase placement

Phase 2. It depends on nothing unshipped, and the beta3 walks supply the acceptance evidence
already. The agent-initiated path can ship independently of automatic detection.

## Open questions

1. **Model selection.** "Strongest available" is host-dependent and quota-bearing. Does the advisor
   reuse the reviewer-host catalog's ranking, or carry its own?
2. **Does the advisor's repair require human authorization before it lands?** The ruling says it may
   repair mechanism code. On a consumer's machine that is a write to their project. Ruling needed on
   whether that is announced-and-applied or proposed-and-confirmed.
3. **Loop-detection threshold.** N identical refusals against identical state — what is N, and is
   "identical state" the tree digest, the refusal code, or both?
4. **Interaction with the review campaign.** If the advisor repairs engine code mid-feature, the
   reviewed-state digest moves. Does that invalidate in-flight review evidence, and should the
   advisor say so?

## Risks

- **The advisor becomes a way to survive defects rather than close them.** Mitigated by the mandatory
  class-closure output, but the discipline must hold: **first line of defence is the guards, and
  every advisor intervention must end by strengthening them.** W1 existed because two components
  hashed different inputs and no test crossed the seam; an advisor would have diagnosed it in minutes
  instead of twenty, but the durable fix is still the derived guard that catches the seam before a
  human ever meets it.
- **Authority creep.** Every future stuck state will present an argument for letting the advisor
  write "just this one" consent artifact. The boundary must be structural, not conventional.
- **Cost.** A strong model on fresh context per stuck gate is not cheap. Bounded iterations and a
  real terminal state are what keep it from becoming the most expensive component in the system.
- **False escalation.** Most refusals are correct and need no advice. Automatic detection must key on
  non-convergence, never on refusal alone.

## Cross-references

- **Beta3 walk findings W1, W2, W9** — the measured case above; W9 is the general form (*a refusal
  naming an unreachable remedy actively misdirects*).
- **DRIFT-198-I010-012** — *"the ceiling-halt message teaches a command that throws in the shipped
  mode."* Same shape, previously recorded, previously treated as an instance.
- **DRIFT-199-I001-035** — the consent-gate principle the authority boundary protects: *consent given
  against false information is not consent.*
- **Proposal 210 (Search-Before-Create)** — same underlying observation one layer down: the
  countermeasures are rule-shaped while the failure is retrieval-shaped.

## Status history

- 2026-08-15 — `candidate`. Raised from the v0.40.0-beta3 manual walks, where the same unsatisfiable
  gate produced an expensive twenty-minute forensic investigation on one host and a governance bypass
  on another. Maintainer ruled the authority boundary (repair mechanism, never consent) and both
  trigger paths at proposal time.
