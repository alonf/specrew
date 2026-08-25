---
proposal: 213
title: Automated Walk Harness on ASSERT
status: candidate
phase: unphased
estimated-sp: 8-13
discussion: tbd
---

# Automated Walk Harness on ASSERT

## Why

The beta3 stabilization effort produced a hard number: manual dogfood walks ran at roughly
four hours per walk and surfaced roughly one governance defect each — and they were the
**only** mechanism that caught the model-judgment failure class. The deterministic half of
that cost was retired by the workshop state-transition table (walk 4's strategic item): state
× operation defects are now found in seconds without a model. The judgment half was never
retired, because it cannot be: whether a session misreads an approval, renders an orientation,
respects a dismissed question, or writes code on an inferred go-ahead is model behavior, and
only running a model exposes it.

The cost of sampling that behavior one manual walk at a time is now documented across two
weeks of findings. Three of the most serious defects of the cycle — the tasks-approval
misread that produced unauthorized product code, the dismissed-picker consent hazard, and
the mid-session model swap during a governed record edit — were each found by a human
walking a real project, hours in, on a host and model combination nobody had tried before.
Every one of them was reproducible after the fact from a scripted conversation. Nothing
generated those scripts in advance.

Microsoft's ASSERT (Adaptive Spec-driven Scoring for Evaluation and Regression Testing,
MIT-licensed, `github.com/responsibleai/ASSERT`) has matured past its Build-2026 announcement
into a usable substrate for exactly this shape: natural-language behavioral specs are turned
into generated single- and multi-turn scenarios, executed against a callable target, and
scored by LLM judges that must **cite evidence** for their verdicts, with local-first
JSON/JSONL artifacts, a run-comparison viewer, and a GitHub Actions regression gate. Its
judge-cites-trace doctrine is the same doctrine Specrew's own review hardening converged on
independently (declared coverage; a review must see what it claims to have reviewed). What
ASSERT does not provide — a way to drive an external CLI host, and a ground truth stronger
than a transcript — is precisely what Specrew already has.

## What

A walk harness that runs scripted and generated multi-turn governance scenarios against real
host CLIs driving disposable governed fixture projects, judging outcomes primarily against
the Specrew ledger and secondarily via ASSERT's transcript judges.

Three Specrew-owned components on top of ASSERT as a pinned dependency:

**1. The target adapter.** An ASSERT "callable" that provisions a downstream-shaped fixture
project (per the standing method rule: no `Specrew.psd1` in scope, deployed `.specify/`,
scratch-directory containment per the probe-hygiene rule), spawns a host CLI (`claude`,
`copilot`, `codex`) with a **pinned model**, feeds the scenario's scripted human turns, and
returns the transcript plus the fixture's post-run state. One adapter per host, one shared
fixture provisioner.

**2. The ledger oracle.** ASSERT's judges read transcripts; Specrew's ground truth is the
store. Deterministic assertions run against the fixture after each scenario — through the
real validators, not reimplementations: did unauthorized source land
(`Get-SpecrewUnauthorizedSourceDrift`), did a boundary advance without a verdict, did a
workshop record consent no typed turn minted, does governance validate. ASSERT's LLM judges
are scoped to the genuinely conversational qualities the ledger cannot see: was the
orientation rendered as visible prose, was a refusal calm and blame-free with one concrete
recovery action, were internal ids kept out of human-facing text, did the packet carry all
six sections. Judges must cite the transcript line or ledger fact behind each verdict —
ASSERT's grounding requirement, kept.

**3. The seed library.** The beta3 incident corpus is the initial behavior library: every
W-item and DRIFT entry with a conversational trigger becomes an atomic scenario preset —
ambiguous approval in context ("the crossing is authorized"), dismissed question UI at a
consent point, resume into a dirty tree, mid-walk model swap, a relayed instruction minus its
load-bearing word ("proceed with the before-implement ~~preparation~~"), stale advisory
pressure to run an unauthorized command. Each preset pairs a script with the known-correct
ledger outcome, because each one already happened and its correct outcome was adjudicated.
ASSERT's generator then mutates presets into variants — which is the half no human has
capacity to do.

### Functional requirements

High-level capabilities (candidate stage):

- Run a named scenario against a named host+model pair and produce a pass/fail verdict with
  cited evidence, locally, in minutes.
- Run the full seed library as a regression gate before a release tag, per supported host.
- Generate scenario variants from presets and spec text (the refocus rules, the launch
  contract, the workshop contract) and triage new failures into the drift workflow.
- Record every run as local ASSERT artifacts plus the fixture's Specrew ledger, so a failure
  is diagnosable from evidence rather than reproduction.
- Pin host CLI version and model per run; refuse to score runs whose model was switched
  mid-scenario by the host (record them as environment findings instead — that class is real
  and must not pollute behavioral scores).

### Out of scope

- **Runtime enforcement.** The harness finds defects; it blocks nothing in live sessions.
  Producer-level guards (W12, the unauthorized-source stop layer, a future PreToolUse hook)
  remain Specrew's hook layer and are not replaced by evaluation.
- **ACS runtime mediation.** ASSERT's tool-call interception requires wrappable callables and
  cannot reach a host CLI's internals. Not attempted.
- **Replacing manual walks entirely.** The harness retires the *regression* burden — re-proving
  known classes on every build — so human walks are spent only on genuinely new surfaces.
- **Non-CLI hosts** (IDE agent modes) in the first iteration.

## Effort

- **Iteration 1 (~5 SP)**: fixture provisioner + one host adapter (claude) + ledger oracle
  wired to the real validators + 10 seed scenarios from the incident corpus, runnable locally.
- **Iteration 2 (~4 SP)**: copilot and codex adapters, model pinning + mid-swap detection,
  the full seed library, CI regression gate on the release branch.
- **Iteration 3 (~2-4 SP)**: ASSERT-generated variants from spec text, triage-to-drift
  workflow, run-comparison reporting for host/model matrices.
- **Total**: ~11 SP (8-13 range; the generator integration carries the uncertainty).

## Phase placement

Unphased / queue position to be decided — but it composes directly with Proposal 211 (the
Process Advisor consumes the same incident corpus the harness replays, and harness failures
are the advisor's training material) and with the beta3 method notes (downstream-shaped
fixtures; a control is proven by exercising it). Natural earliest slot: immediately after
beta3 ships, while the incident corpus is fresh and the walk cost is vivid.

## Open questions

- **Scripted-turn fidelity per host.** Feeding human turns to a CLI host non-interactively
  differs per host (stdin, `-p` flags, resume semantics) and some hosts may not support it
  cleanly; the adapter layer absorbs this, but per-host feasibility needs a spike before
  iteration 1 is committed.
- **Judge model independence.** The judge should not share a model family with the host under
  test where avoidable — the reviewer-independence rule applied to evaluation.
- **Cost envelope.** A full-library run per host per release is a real token spend; needs a
  measured budget after iteration 1 before CI gating is committed.
- **ASSERT maturity.** ~230 stars, active maintenance, six worked examples: real but young.
  Pin the version; treat breaking upstream changes as a dependency risk in the usual way.
