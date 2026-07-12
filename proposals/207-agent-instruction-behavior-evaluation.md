---
proposal: 207
title: Agent Instruction + Skill Behavioral Evaluation Harness
status: candidate
phase: phase-2
estimated-sp: 10-16
priority-tier: 1
discussion: surfaced 2026-07-12 from a deep comparative analysis of obra/superpowers. Specrew tests deployed instruction text and deterministic validators, but has no general host-neutral method for proving that an agent actually follows a skill, lifecycle prompt, stop-order rule, or verdict-capture instruction under realistic pressure. The missing layer is behavioral evaluation, not another instruction surface.
---

# Agent Instruction + Skill Behavioral Evaluation Harness

## Why

Specrew increasingly depends on instructions that sit before deterministic enforcement: skills,
reviewer prompts, lifecycle packets, stop-ordering rules, hook messages, verdict menus, and host adapters.
Current tests can prove that text is deployed and contains required phrases. They do not prove that a
fresh agent reads the full instruction, applies it under pressure, or behaves consistently across hosts.

The [`obra/superpowers`](../docs/methodology/superpowers-comparative-analysis.md) skill-authoring method
demonstrates a useful missing test shape: establish behavior without the skill, apply realistic pressure,
run fresh contexts repeatedly, capture rationalizations, then strengthen and re-test the instruction.
Specrew needs this as a host-neutral, evidence-producing harness while retaining validators as authority.

Observed Specrew classes suited to this harness include:

- rendering a human verdict packet before a required review becomes terminal;
- asking the user to nudge a running background review instead of waiting/polling it;
- treating stale review output as current;
- losing free-form approval instructions at verdict capture;
- accepting narrative test claims without digest-bound evidence;
- skipping a skill body because its description appears to summarize the workflow;
- relaxing boundary discipline after context compaction.

## What

### W1 - Scenario contract

Define a host-neutral scenario schema with setup artifacts, user message, available tools/skills,
pressure factors, prohibited actions, required observable actions, terminal condition, and scoring rules.
Scenarios must test externally visible behavior, not hidden chain-of-thought.

### W2 - Baseline and treatment runs

Each behavioral rule supports:

1. a no-guidance or prior-version baseline;
2. the candidate instruction/skill treatment;
3. repeated fresh-context samples with independent run IDs;
4. optional cross-host and cross-model cells.

The harness reports compliance rate and variance. A single passing sample is evidence, not proof of
reliability.

### W3 - Pressure catalog

Ship reusable pressure dimensions: urgency, sunk cost, user request to bypass, stale concurrent output,
context compaction, ambiguous authority, tool failure, long-running background work, conflicting
instructions, and review-budget pressure. Scenarios combine only the dimensions relevant to their rule.

### W4 - Rationalization capture without private reasoning

When an agent violates a rule, capture its visible action, emitted explanation, tool trace, and artifact
diff. Classify recurring bypass rationalizations as test data. Never require or store hidden reasoning.

### W5 - Skill discovery and loading tests

Test both explicit invocation and description-based discovery. Verify that:

- an explicit user request loads the named skill;
- applicability descriptions cause loading in representative tasks;
- descriptions state when to use the skill without replacing its body;
- loading the skill changes the target behavior relative to baseline;
- mirrored host copies remain semantically equivalent.

### W6 - Lifecycle behavior pack

Provide initial scenarios for stop ordering, boundary packet suppression, review terminal-state routing,
verdict text capture, stale-lineage handling, evidence honesty, and post-compaction reconstruction. These
compose with Proposals 145, 146, 151, 155, 157, 197, and 203.

### W7 - Evidence and CI policy

Emit a bounded result artifact containing scenario version, instruction digest, host/model identity,
run IDs, observable trace references, score, and variance. Use deterministic fixture tests on every PR;
run paid/model behavioral samples on a scheduled or release-candidate lane with explicit budgets. A
behavioral pass never overrides a deterministic validator failure.

## How

Deliver in two iterations. Iteration 1 defines the scenario schema, validator, deterministic fixture
runner, baseline/treatment result format, and the first stop-ordering and verdict-capture scenarios.
Iteration 2 adds headless host adapters, repeated live sampling, pressure composition, scheduled CI,
redaction, and skill discovery/body-execution scenarios. Reuse Proposal 139's process adapter where it
exists, but keep a sequential adapter so the harness can ship independently.

## Acceptance criteria

- **AC1:** A versioned scenario schema and validator reject missing authority, unobservable assertions,
  unconstrained success criteria, and hidden-reasoning requirements.
- **AC2:** The runner can compare baseline and treatment across at least two fresh samples and emits
  compliance rate plus variance with host/model/run attribution.
- **AC3:** A stop-ordering fixture proves an in-flight current-digest review suppresses the verdict
  packet, waits/polls without duplicate launch, and emits the packet only after a clean terminal result.
- **AC4:** A verdict-capture fixture proves free-form human instructions survive dispatch and persist in
  the authoritative artifact.
- **AC5:** A stale-lineage fixture proves an older result cannot authorize or block the current digest.
- **AC6:** Skill tests cover explicit invocation, description discovery, body execution, and mirror parity.
- **AC7:** Behavioral evidence is bounded, redacted, digest-bound, and contains no private reasoning.
- **AC8:** CI separates deterministic fixture coverage from budgeted live-agent evaluation and fails
  loudly when a required live lane cannot execute; absence never reads as a pass.
- **AC9:** At least Claude, Codex, and one other supported host can consume the same scenario contract,
  with unsupported capabilities reported as explicit `not_applicable` or `infrastructure_failed`.
- **AC10:** Documentation teaches RED/GREEN/REFACTOR for instructions: baseline failure, minimal
  instruction change, repeated behavioral confirmation, and rationalization-driven refinement.

## Composition

- **Proposal 140** owns the reviewer instruction surface; 207 tests its behavioral effect.
- **Proposal 145** owns structured review artifacts and rubrics; 207 pressure-tests reviewer behavior.
- **Proposals 151/155/157** own boundary and verdict packets; 207 tests capture and ordering behavior.
- **Proposals 197/203** own continuous review, lineage, containment, and round control; 207 supplies
  adversarial behavioral scenarios, not runtime enforcement.
- **Proposal 139** supplies fresh-context dispatch when available; 207 also supports sequential headless
  host runs so it is not blocked on native subagents.
- **Proposal 020** owns spec-scenario integration testing; 207 is specifically agent-instruction behavior.

## Out of scope

- Replacing deterministic validators, schemas, or boundary ratchets with probabilistic evaluation.
- Scoring hidden chain-of-thought or requiring models to reveal private reasoning.
- Building a general model benchmark or selecting the globally best model.
- Requiring live paid-agent samples on every documentation edit.
- Importing Superpowers' skill library wholesale.

## Risks

- **Nondeterminism:** require repeated samples and report variance instead of claiming certainty.
- **Cost:** keep PR fixtures deterministic; budget live matrices at scheduled/release gates.
- **Overfitting prompts to tests:** rotate pressure combinations and retain holdout scenarios.
- **Host drift:** keep one scenario schema and adapters; report capability differences explicitly.
- **False authority:** behavioral evidence is advisory/probabilistic unless a governing spec explicitly
  sets a threshold; deterministic gates remain fail-closed.

## Status history

- 2026-07-12: candidate created after searching existing proposals. Proposals 139, 140, 145, 197,
  203, and 020 own adjacent orchestration, instruction, review, and scenario surfaces, but none owns
  baseline-vs-treatment pressure testing of agent instructions as observable behavior.

## Cross-references

- [Superpowers comparative analysis](../docs/methodology/superpowers-comparative-analysis.md)
- [Proposal 139](139-multi-agent-subagent-orchestration.md)
- [Proposal 145](145-structured-multi-phase-reviewer.md)
- [Proposal 203](203-reviewer-containment-identity-hardening.md)
- [Proposal index](INDEX.md)
