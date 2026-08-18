---
proposal: 212
title: Reading Validation at Human Gates - Opt-In Attention Proofs for Boundary Verdicts
status: candidate
phase: phase-2
priority-tier: 2
estimated-sp: 8-13
discussion: maintainer observation 2026-08-18 during the v0.40.0-beta3 walks - "I see people that use Specrew sometimes just accept the default in each gate. I mean they do not really look at the spec, tasks and code."
---

# Reading Validation at Human Gates

## Why

Specrew's guarantee is that a human authorizes every stage boundary. The mechanism assumes the human
read what they authorized. Nothing checks that assumption, and the current design actively selects
against it.

### What the system asks for today, measured

- **A one-word reply is a valid verdict at every gate.** The accepted vocabulary includes bare
  `approve`, `proceed`, and `yes`.
- **There are ~9 boundary stops per iteration** - `before-specify`, `specify`, `clarify`, `plan`,
  `tasks`, `before-implement`, `review-signoff`, `retro`, `iteration-closeout`, `feature-closeout` -
  plus workshop lens confirmations, agenda confirmation, and pause decisions on top.
- **Time-to-verdict is not recorded anywhere.** Nothing distinguishes a four-second reflex from a
  considered judgement, at the moment or afterwards in the record.
- Several surfaces attach **"(Recommended)"** to the proceed option.

Nine-plus gates, each satisfiable by typing `yes`, with the cheap path signposted. Clicking through is
the behaviour the design selects for.

### The asymmetry is backwards

Specrew already has a proven costly-approval pattern. It is applied to the rare acts and not the
routine ones:

| Approval | What it costs today |
| --- | --- |
| Signoff **override** (rare escape hatch) | a typed phrase plus a 10-2000 character rationale |
| Workshop **repair** (rare) | a typed authorization phrase |
| **review-signoff** - the gate that certifies what ships | `yes` |

The deliberate bypass costs a sentence. The gate that decides whether the work is done costs one word.

### The live case that motivated this

During beta3 stabilization, `review.md` was written by the implementing agent: 13 task verdicts marked
`pass`, an overall verdict of `accepted`, committed before the corroborating review round completed. A
human answering that gate with `yes` rubber-stamps a self-assessment, **and the ledger cannot tell that
apart from a considered approval.** The same signature was already recorded once as a show-stopper
(DRIFT-199-I001-037).

This is the sibling of the principle already ruled in DRIFT-199-I001-035:

> **A CONSENT GATE MUST VERIFY THAT WHAT THE HUMAN CONSENTED TO MATCHES WHAT IS TRUE.** Not merely
> *is this acceptable* but *did they see it.* Consent given against false information is not consent.

That ruling addressed consent given against *false* information. This proposal addresses consent given
without reading *true* information. Same gate, other failure.

### The framing that connects it to the rest of beta3

Beta3 spent its entire stabilization moving rules from prose into mechanisms: four silent guards taught
to speak at the producer, a lens boundary that did not bind, a picker prohibition a capable model
reasoned past. Every fix replaced *instruction* with *enforcement*.

Specrew currently does the opposite for humans. It instructs them to give a considered verdict and
enforces nothing. **Same gap, other side of the keyboard.**

## What

An **opt-in reading-validation layer**, configured at `specrew init` with an explicit update path,
selectable **per mechanism and per gate**. Default off.

### Mechanism 1 - Duration floor

The verdict option does not render until N seconds have elapsed since the packet was shown.

Deliberately framed as **absence, not rejection**: an early reply is never told its considered
judgement was invalid. It proves elapsed time, not attention, and is trivially defeated by walking
away - but it makes *reflexive* approval structurally impossible, which is the observed behaviour.

Weakest signal, cheapest to build, non-zero value.

### Mechanism 2 - Artifact render proof, not file access time

The originally proposed mechanism was filesystem last-access time on the artifact. **Recommend against
it**, on three grounds, one of them disqualifying:

- **Not portable.** Windows `DisableLastAccess` is system-managed and can flip; Linux `relatime` only
  updates atime when it is older than mtime or 24h stale. Consumer behaviour is not consistent.
- **Noisy.** Antivirus, the search indexer, backup agents, and the coding agent itself all open those
  files. An access event proves a file handle, not a person.
- **Disqualifying: a human reading in an already-open editor buffer generates zero filesystem access.**
  The editor holds the buffer and does not re-read. The most common reading pattern produces a false
  *did not read* - and failing a genuine reader is exactly how a feature gets switched off.

**The reliable substitute:** Specrew renders the content itself - the delta since the last verdict, the
findings, the changed requirement - and records **its own render event**. Did-they-see-it becomes a
Specrew fact rather than an OS inference.

This is the pattern already trusted in `Test-SpecrewWorkshopAgendaVisibleInText`, which proves agenda
visibility through Specrew's own channel instead of asking the filesystem. Same principle, one layer up.

It also composes with **Proposal 012 (Visual Artifact Extension)**: 012 makes the content readable, this
makes the reading visible. The delta-render is the natural place a diagram would land.

### Mechanism 3 - Comprehension quiz

Two to three questions at the gate, answered before the verdict option renders.

**The quiz is a commitment device, not a test.** Its primary value is *ex ante*: a human who knows they
will be asked reads differently. Consequences of taking that seriously:

- The **kind** of question must be predictable, so it guides what to attend to while reading.
- The **instance** must not be, or the human learns to check one field.
- **A 100% pass rate is success, not redundancy** - it means everyone is now reading. Stated explicitly
  so the first metrics review does not cut the feature for catching nothing.

**Questions are derived from structured facts, never model-generated.** Deterministic, gradeable,
free, and incapable of hallucinating. A model-generated quiz can be trivial, unanswerable, or - worst -
answerable by the agent sitting in the same context.

**One question dimension per stage, doubling as a reading guide:**

| Gate | The dimension the question asks about |
| --- | --- |
| specify | what is explicitly **out** of scope |
| clarify | which ambiguity was resolved, and which way |
| plan | what lands in iteration 1 versus later |
| tasks | which requirement has the thinnest task coverage |
| before-implement | what gets built first, and the acceptance bar |
| review-signoff | how many blocking findings, and what was deferred |
| retro | which defect class recurred |
| closeout | what shipped versus what deferred |

**Answer channel: typed digits, never a picker.** A picker response is a tool result - it does not fire
`UserPromptSubmit`, mints no receipt, and carries no authority. That is beta3 walk finding W17,
reproduced. Numbered options rendered as visible prose and answered by typing the number keep answering
effort near zero *and* keep the receipt, exactly as the pause surface already does.

**Distractors are drawn from sibling facts in the same record**, which makes them plausible without a
model:

```text
Q: How many blocking findings did this round report?
   1) 3   <- actual blocking count
   2) 2   <- the major count
   3) 1   <- the minor count
   4) 0   <- the demoted count
```

All four are real numbers from the same record. Someone who skimmed the summary line cannot tell them
apart.

**A wrong answer never blocks.** It re-renders the relevant artifact section, shows the correct answer
with its source, and asks a *different* instance from the same dimension. Educational rather than
punitive - and it costs more time than reading would have, which inverts the incentive properly:

> **Make reading the cheapest way to pass.** Not make not-reading impossible - make it slower.

## Sequencing - record before enforce

**Ship the measurement half first**, gating nothing:

```text
verdict_latency_seconds: 4     artifact_rendered: false     quiz: 2-of-3
```

Written as facts at every boundary. Cheap, zero abandonment risk, and it converts the founding
observation from anecdote into a retro line: *seven of nine verdicts under eight seconds, artifact
never rendered.*

Enforcement built before measurement lands in the wrong place. The facts tell you which two or three
gates actually need the friction.

## Effort

8-13 SP. The measurement half is small and independently shippable. The quiz question bank - one
derived generator per stage dimension, with sibling-fact distractors - is the bulk. The duration floor
is trivial. The delta-render depends on how much of Proposal 012 lands with it.

## Phase placement

Phase 2. The measurement half depends on nothing and can ship immediately.

## Open questions

1. **Which gates carry irreversible consequence?** The friction budget is only spendable once. Likely
   `before-implement` and `review-signoff`, but that is a maintainer ruling, not a derivation.
2. **Does the quiz apply to workshop lens confirmations**, or only to lifecycle boundaries? Lens
   confirmations are frequent and already typed-turn gated.
3. **What happens on repeated wrong answers?** Never block is the rule; but three wrong answers on the
   same dimension is a signal worth naming somewhere.
4. **Does the delta-render replace the packet or precede it?** A packet that already contains the delta
   may make mechanism 2 redundant.

## Risks

- **Abandonment.** The dominant risk, with precedent in this repository: the recorded rational response
  to the F8 review loop was *disabling the campaign*. Mitigated by default-off, opt-in per mechanism
  **and per gate**, never blocking on a soft signal, and shipping measurement before enforcement.
- **Goodhart.** A fixed question template becomes memorisable - *review-signoff always asks about
  blocking count* - and the human reads one number. Mitigated by fixing the **dimension** per stage
  while rotating the **instance** within it, which is a property the commitment-device framing needs
  anyway.
- **Guessability.** Three questions across four options is a 1-in-64 blind pass. Weak as proof, adequate
  as deterrence; the wrong-answer cost is what carries it.
- **Quiz fatigue.** Three questions across nine gates is 27 per iteration - a tax nobody pays twice.
  Scope to the heavy gates only.
- **Proxy honesty.** None of the three proves comprehension. Duration proves elapsed time; a render
  proves display; a quiz proves recall of specific facts. The proposal claims attention proxies and not
  more.

## Cross-references

- **Proposal 012 (Visual Artifact Extension)** - makes the content readable; this makes reading visible.
  The delta-render is where a diagram naturally lands.
- **Proposal 211 (Process Advisor)** - same underlying shape: the process assumes good behaviour where
  it could require evidence of it.
- **DRIFT-199-I001-035** - the consent principle this extends from *did they see false information* to
  *did they see it at all*.
- **DRIFT-199-I001-037** - implementer-authored `review.md`; the live case a one-word verdict would
  rubber-stamp.
- **Beta3 walk finding W17** - picker answers mint no receipt; the reason the quiz answer channel must
  be typed digits.

## Status history

- 2026-08-18 - `candidate`. Raised from a maintainer observation during the v0.40.0-beta3 manual walks,
  with the approval vocabulary, gate count, and absence of verdict-latency recording measured from the
  shipped tree at that time.
