---
proposal: 197
title: Continuous Co-Review (Host-Neutral Inline Editor↔Reviewer Pairing)
status: candidate
phase: phase-2
estimated-sp: 13-21
priority-tier: 2
discussion: surfaced 2026-06-17 in a design conversation about catching design-drift — abstraction leaks, and bypassing the interface/polymorphism the design mandated (e.g. reaching a component through a condition "even though the design dictates otherwise"), and code smells — AS edits happen, rather than only at the late review-signoff boundary (Proposal 145). The maintainer's constraints were explicit: do NOT let one host's capabilities drive the solution (same reason as removing Squad) — abstract it and let each host satisfy it best-effort; the reviewer is read-only (no worktree); and rely on Proposal 145 as the guaranteed end backstop.
composes-with:
  - 139  # Multi-Agent Subagent Orchestration (uses its host-neutral spawn CONTRACT, not its heavy foundation)
  - 145  # Structured Multi-Phase Reviewer (the end backstop; this shifts it LEFT)
  - 102  # Cross-Model Independent Reviewer (the cross-model upgrade)
  - 156  # Workshop-Decisions manifest (the reviewer's design-conformance rubric)
  - 196  # Event-Backed Workshop Provenance (makes that rubric trustworthy)
  - 174  # Boundary Variance Disclosure (the editor's "reject + rationale" path)
  - 195  # Quality & Testability Design Lens (the testability/convention rubric)
  - 146  # /specrew.refocus (re-inject the design contract at the edit boundary — rung 2a)
  - 105  # Host-Native Hook Deployment (the PostToolUse trigger surface)
---

# Continuous Co-Review (Host-Neutral Inline Editor↔Reviewer Pairing)

## Why

Specrew's structured review (Proposal 145) runs at `review-signoff` — the END. By then the design
is cemented, so the cheapest moment to catch design-drift has already passed: an **abstraction
leak**, **bypassing the interface/polymorphism the design mandated** (reaching a component through
a condition "even though the design dictates otherwise"), or a **code smell** is far cheaper to
fix at the edit boundary than after the implementation is built around it. Late review can only
file a finding against a decision already made.

The AI-authored era sharpens this. When an agent writes the code, the review *is* the primary
trust mechanism, and the dominant failure mode is not "the agent disagrees with the design rule"
— it is "the agent **forgot or deprioritized** the rule mid-flow." That failure is curable by
re-grounding the work against the design contract **at the edit boundary**, continuously, instead
of once at the end.

This is **shift-left review**, built on two established patterns: **generator–critic** (an
editor "actor" + a reviewer "critic"; the Reflexion loop) and the **blackboard architecture**
(the two agents coordinate through a shared workspace rather than talking directly). It does NOT
replace Proposal 145 — 145 remains the guaranteed signoff backstop; this reduces what reaches it.

## What

The design separates three concerns that the word "reviewer" usually conflates — each has a
different right mechanism:

### 1. Trigger (deterministic)

"An edit happened — review now." Agents are turn-based and cannot self-watch, so the trigger is
deterministic, not an instruction:

- **Hook where available** — a `PostToolUse` hook on `Edit`/`Write` fires after the editor
  changes code (the host-native trigger; Proposal 105 surface).
- **Orchestrator git-diff loop where not** — recall `codex exec` fires no hooks; there the
  orchestrator computes the change-set at each checkpoint and invokes the reviewer directly. The
  reviewer is **spawned**, so it never depends on hooks itself.
- **Change-set = `git diff` against a checkpoint baseline**, not a live OS file-watcher. Git
  catches *every* change including out-of-band edits (hand-edits, formatters, codegen, merges)
  that a tool-call hook cannot see.
- **Granularity = checkpoint, not per-patch** — fire per completed file/component, debounce, and
  scope the review to the diff + only the design rules touching the changed files (per-micro-edit
  review is expensive and causes thrash; concurrent review reads half-written files).

### 2. Judgment (agent + skills)

A **read-only reviewer agent**, host-neutral by construction (the anti-Squad principle: define
the contract, let each host satisfy it best-effort):

- **Contract:** `review(diff, designContext) -> findings[]`, with a forced findings **JSON
  schema** so parsing is deterministic.
- **Spawn:** a **headless-mode floor on every host** (`claude -p`, `codex exec`, `copilot -p`,
  `cursor-agent -p`, antigravity `-p`) guarantees it works everywhere; a **best-effort adapter**
  uses a host's richer in-session subagent surface where one exists. No host capability drives the
  design.
- **Read-only:** least-privilege read-only-on-source permission (it physically cannot edit code);
  its only write is its findings. Therefore **no worktree** and **no cgroup/Job-Object
  no-orphan rigor** — a **timeout + best-effort process-tree kill** suffices (it cannot corrupt
  the working tree). This is the cheap slice of Proposal 139, not its heavy foundation.
- **Rubric = the design contract:** the reviewer is fed the diff **plus** the workshop decisions
  (Proposal 156), the design/convention skills (the design-lens knowledge — `architecture-core`,
  `component-design`, `code-implementation`/code-rules, and the Proposal 195 testability lens),
  and the spec. This is what lets it catch "you bypassed the interface the design mandated" rather
  than only generic smells — the violation is not in the code, it is in the design decision the
  reviewer must hold.

### 3. Comms — stdio for the result, files for the record

- **Result back from the reviewer:** structured JSON on **stdout** (every headless mode emits
  stdout; the orchestrator controls the parse — more portable and reliable than depending on the
  sub-agent to write a file).
- **Durable discussion record:** a **blackboard** review-thread file written by the *orchestrator*
  (e.g. `.specrew/review/inline/<file-or-component>.review.md`). The sub-agent emits findings; the
  orchestrator owns the file.

### 4. Discussion protocol (the editor↔reviewer thread)

- Reviewer appends a finding: `id`, `file:line`, `severity` (blocking | advisory | nit), `kind`
  (design-conformance | smell | abstraction-leak), `design_ref` (which decision it violates),
  comment.
- Editor responds per finding: **accept** → fix → mark `resolved` (+ patch ref); or **reject** →
  record a **rationale** — which is a Proposal 174 **boundary-variance** record (a justified
  deviation captured, not silently done).
- Unresolved **blocking** findings gate the next checkpoint; non-convergence escalates to the human.

### 5. Enforcement (deterministic — the one thing no host provides)

Hosts donate the loop (watch, spawn, LLM); they do not donate the *methodology verdict*. So the
**gate is Specrew's deterministic validator**: a checkpoint may not advance while the blackboard
has an unresolved `blocking` finding; the validator checks schema validity and disposition state.
This is the Proposal 145 doctrine — *instructions/skills/hooks accelerate; the validator is the
authority* — applied inline.

### 6. Adoption ladder (one contract, three rungs)

The blackboard + git-diff change-set + gate are the **stable contract**; the reviewer
implementation graduates without rework:

| Rung | Reviewer | Independence | Cost | Hosts |
| --- | --- | --- | --- | --- |
| **2a** | same agent, hook-triggered **self-refocus** (re-injects the design contract, Proposal 146 machinery) | weak (self-preference) | ~free | hook-capable |
| **2b** | **fresh-context** reviewer sub-agent (recommended start) | context-independent | cheap (host spawn) | headless floor everywhere |
| **1** | cross-host + **cross-model** reviewer (Proposal 102) on the Proposal 139 contract | full | heavy | all five |

### Functional requirements

- **FR-001** — Host-neutral `review(diff, designContext) -> findings[]` contract with a forced
  findings JSON schema (stdout transport).
- **FR-002** — Read-only reviewer: least-privilege read-only-on-source; no worktree; timeout +
  best-effort process-tree kill.
- **FR-003** — Per-host best-effort spawn adapter: headless `-p`/`exec` floor (universal) + native
  in-session subagent where richer.
- **FR-004** — Deterministic change-set via `git diff` against a checkpoint baseline (captures
  out-of-band edits).
- **FR-005** — Deterministic trigger: `PostToolUse` hook where available; orchestrator checkpoint
  loop fallback; checkpoint granularity + debounce; review scoped to diff + relevant rules.
- **FR-006** — Blackboard review-thread artifact + protocol (findings schema; editor dispositions
  accept/reject; reject → Proposal 174 variance record), orchestrator-owned.
- **FR-007** — Deterministic gate: no unresolved blocking finding advances a checkpoint; round cap;
  dedup vs resolved; severity policy; human escalation on non-convergence.
- **FR-008** — Reviewer rubric assembled from Proposal 156 workshop decisions + design/convention
  skills (Proposal 195 + 163 + architecture-core/component-design lenses) + spec; integrity of
  that rubric backed by Proposal 196.
- **FR-009** — Cross-model option (Proposal 102) for the judgment (different provider → fewer
  shared blind spots than a same-model critic).
- **FR-010** — Adoption ladder 2a → 2b → 1 over the one stable contract.

### Out of scope

- The **heavy Proposal 139 foundation** (cost-routing, dispatch-kinds, worktree isolation,
  cgroup/Job-Object rigor) — a read-only one-shot reviewer does not need it and can ship ahead of
  it, graduating onto its spawn contract for rung 1.
- **Replacing Proposal 145** — 145 at review-signoff stays the guaranteed backstop verifying the
  *aggregate* diff vs spec; this shifts review left, it does not remove the gate.
- **Mutating / parallel sub-agents** (where worktrees + the 139 foundation are required) — separate.
- **Live OS file-watcher / periodic polling** as the primary trigger — fallback only; the
  hook-or-orchestrator-loop + git-diff is the mechanism.

## Effort

- **Iteration 1 (~6-9 SP, rungs 2a/2b)**: the contract + read-only spawn (headless floor) + the
  git-diff change-set + blackboard protocol + the deterministic gate, on hook-capable hosts +
  orchestrator-loop fallback.
- **Iteration 2 (~7-12 SP, rung 1)**: cross-host best-effort adapters + cross-model (Proposal 102),
  graduating onto the Proposal 139 spawn contract.
- **Total**: ~13-21 SP.

## Phase placement

Phase-2, review/quality track — after/with Proposal 145 + 156. Rungs 2a/2b can ship independently;
**rung 1 is gated behind the Proposal 139 foundation**, which is itself gated behind the in-flight
host-runtime reshape (host-detection/adapter/journal) — so sequence rung 1 after that settles.

## Open questions

1. Default rung — 2b (fresh-context) recommended; ship 2a as a cheaper first increment too?
2. Checkpoint granularity (per file / per component / per task) + debounce policy.
3. Blackboard location + schema (`.specrew/review/inline/…`) and its relation to Proposal 145's
   review artifacts (augment vs separate).
4. Gate severity policy (block vs advisory) + max rounds before human escalation.
5. Reviewer model default: same-model fresh-context (cheap) vs cross-model (Proposal 102).
6. Does the trigger reuse Proposal 146 refocus machinery (rung 2a) or a new `PostToolUse` binding?

## Risks

- **Token cost** of continuous review — mitigate via checkpoint granularity + diff-scoping + dedup.
- **Thrash / non-convergence** (editor↔reviewer ping-pong) — cap rounds; only re-review changed regions.
- **Same-model rubber-stamping** (self-preference bias) — default to fresh-context (2b); cross-model (2a→102) where it matters.
- **The polling gap** — the trigger must *re-inject* findings into the editor's next turn; a passive blackboard file does nothing on its own.
- **Host unevenness** — the headless-mode floor guarantees the reviewer runs everywhere; native-subagent is only optimization, so no host capability gates the feature.

## Cross-references

- **Proposal 139** (Multi-Agent Subagent Orchestration) — provides the host-neutral spawn contract;
  this is the read-only one-shot consumer that can ship ahead of 139's heavy foundation and
  graduate onto it for rung 1.
- **Proposal 145** (Structured Multi-Phase Reviewer) — the review dimensions run continuously here;
  145 is the guaranteed end backstop. This proposal is "shift-left 145."
- **Proposal 102** (Cross-Model Independent Reviewer) — the cross-model independence upgrade.
- **Proposal 156** (Design-Analysis Lens Knowledge Catalog / workshop-decisions) — the reviewer's
  design-conformance rubric; **Proposal 196** (Event-Backed Workshop Provenance) makes that rubric
  trustworthy (no fabricated decisions to review against).
- **Proposal 174** (Boundary Variance Disclosure) — the editor's "reject + rationale" deviation path.
- **Proposal 195** (Quality & Testability Design Lens) — sibling; the testability/convention rubric.
- **Proposal 146** (/specrew.refocus) — re-inject the design contract at the edit boundary (rung 2a).
- **Proposal 105** (Host-Native Hook Deployment) — the `PostToolUse` trigger surface; siblings
  **165 / 180** are the same PreToolUse/PostToolUse hook-gate family.

## Status history

- 2026-06-17: candidate drafted from a design conversation on shift-left review; scoped host-neutral
  (headless floor + best-effort adapters), read-only (no worktree), stdio-result/file-record comms,
  hook-or-loop trigger, deterministic gate, with a 2a→2b→1 adoption ladder over one contract.
